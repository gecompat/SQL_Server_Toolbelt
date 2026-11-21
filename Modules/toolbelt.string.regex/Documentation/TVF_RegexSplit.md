# TVF_RegexSplit

Zerlegt die **gesamte** Quelle an nicht überlappenden Regex-Gesamttreffern.
Einzeln freigegeben am 2026-10-01; Separatoren selbst werden nicht ausgegeben.
Keine Captures/Backreferences, kein automatisches Unquoting oder Typwrapper.

## Signatur und Ergebnisschema

`toolbelt_string.TVF_RegexSplit(@Input nvarchar(max), @Pattern nvarchar(max), @Flags nvarchar(max) = N'c', @Profile nvarchar(max) = N'standard', @MaxRows int = 10000)`

Kein Startparameter. Inline-TVF vor interner SAFE-CLR-TVF `TVF_RegexSplitCore`,
dieselbe Ownership-/Collationfassade wie [TVF_RegexMatches](TVF_RegexMatches.md).
Ergebnis: Ordinal bigint, StartPosition bigint, Length bigint, Value nvarchar(max).
Positionen und Längen zählen UTF-16; alle Erfolgswerte sind nicht NULL, die
vier SQL-Metadatenspalten bleiben nullable. Äußerer `ORDER BY Ordinal` legt die
physische Reihenfolge fest. SELECT-Rechte; kein ResultTable-/Help-USP-Vertrag.

## Empty- und Nullvertrag

NULL-Input oder NULL-Pattern ergibt vor jeder Parameterprüfung 0 Zeilen.
Ohne Separator-Treffer entsteht genau ein Originaltoken, bei leerer Quelle
ein leeres Token. Leere Rand- und Zwischentokens werden immer erhalten.

Ein leerer Separator konsumiert **keine** Codeeinheit: der Tokenanfang wird
auf den Matchindex gesetzt, nur der unabhängige Suchcursor rückt um eine
Codeeinheit weiter. Kein übersprungenes Zeichen wird vom Token abgeschnitten.
Ein terminaler Leertrenner wird höchstens einmal gesucht; danach bleibt
das abschließende leere Token. Beispiele:

| Quelle / Pattern | Tokenfolge | StartPosition |
|---|---|---|
| `abc` / leeres Pattern | leer, a, b, c, leer | 1, 1, 2, 3, 4 |
| leer / `Z` | leer | 1 |
| leer / leeres Pattern | leer, leer | 1, 1 |
| `a,,b,` / `,` | a, leer, b, leer | 1, 3, 4, 6 |
| `abc` / `$` | abc, leer | 1, 4 |

UTF-16-Codeeinheiten sind der bestehende Positionsvertrag: ein leeres Pattern
kann auch ein Surrogate Pair zwischen seinen beiden Einheiten teilen. Die
Einheiten bleiben unverändert; es gibt keine Graphem-/Unicode-Skalarzusage.

## Fehlerpriorität, Atomarität und Grenzen

NULL-Kurzschluss → Profile → MaxRows → Flags → Quelle/Pattern/Komplexität/
Dialekt → Suche und Ergebnislimits. Profile, Flags, Größen, kooperative
Budgets und stabile SQL6522/TBX_REGEX_*-Präfixe entsprechen
[Matches](TVF_RegexMatches.md#fehlerpriorität-und-limits). MaxRows zählt Tokens,
nicht Separatoren, einschließlich aller Leertokens; Default10000, Ceiling100000.
Ergebnistextsumme höchstens 2/16 MiB nach ausdrücklich gewähltem Profil.
Vertrags-/Timeoutfehler entstehen vor dem ersten Enumeratorresultat: keine
verwertbaren Teiltokens, kein stilles Abschneiden und keine Erfolg-Fehlerzeile.

Der bestehende R2a-Kontext und Dialektparser sind kanonisch; der CLR-Kern ist
datenzugriffsfrei (DataAccess/SystemDataAccess None), SAFE und ohne Dateizugriff.
Die Inline-Fassade ist kein zweiter Regexparser. Quelle und sämtliche Tokens
werden materialisiert; keine Streaming-/MemoryGrant-/Parallelitätsgarantie.

```sql
SELECT Ordinal,StartPosition,Length,Value
FROM toolbelt_string.TVF_RegexSplit(N'a,,b,',N',',DEFAULT,DEFAULT,DEFAULT)
ORDER BY Ordinal;
```

Neue Namen gehören ausschließlich Release1.2; Upgrade-/Uninstall-Tests müssen
fremde gleichnamige Plätze im tatsächlichen Vorgängerrelease bewahren.

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten in standard,8388608 in large. Keine automatische Kürzung. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens8000 UTF-16-Einheiten, nach Übersetzung64000; Gruppentiefe64,Alternationen1024. Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. Als nvarchar(max) gebunden, im begrenzten Intake maximal4 UTF-16-Einheiten. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Exakt ordinal standard oder large, ohne Trim/Casefold. standard:1048576 UTF-16-Einheiten pro Input/Ersatz/Output und500ms kooperatives Budget; large:8388608 und2000ms. NULL/leer/andereWerte ungültig. Profilintake maximal8 Einheiten vor Start des gemeinsamen Kontexttimers. Früher Input/Pattern-NULL-Kurzschluss,beiReplace zusätzlichReplacementNULL, hat Vorrang. |
| `@MaxRows` | `int` | `10000` | Input | Ganzzahl1..100000, fachlich nichtNULL. Grenze der vollständig materialisierten Ausgabe, keine TOP-/Teilpräfixsemantik. Bei Überschreitung Fehler statt verwendbarer Teilzeilen. Zählt Gesamttreffer beziehungsweise sämtliche Splittokens einschließlich Leertokens. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#regex).

## Vollständiger Usage-Skill

Der [quellgeprüfte Skill](../../../Metadata/UsageSkills/toolbelt_string/TVF_RegexSplit.md) beschreibt sämtliche Argumente, Defaults, NULL-Pfade, Dialektgrenzen, Ergebnisse und Fehler. Er ist auch Bestandteil der ausgelieferten Funktions-DDL. Interne CLR-Kerne haben keine SQL-Defaults und verweisen auf die öffentlichen Fassaden; sie sind kein zusätzlicher Fachaufrufweg. Historische Nachweise und neue native Qualifikation bleiben getrennt.
