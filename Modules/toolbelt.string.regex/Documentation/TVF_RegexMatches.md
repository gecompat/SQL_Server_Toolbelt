# TVF_RegexMatches

Liefert alle nicht überlappenden **Gesamttreffer** des bestehenden Toolbelt-
Regexdialekts. R2b wurde am 2026-10-01 einzeln freigegeben; keine Captures,
Backreferences, Typwrapper oder native RE2-Paritätszusage.

## Signatur

`toolbelt_string.TVF_RegexMatches(@Input nvarchar(max), @Pattern nvarchar(max), @Start int = 1, @Flags nvarchar(max) = N'c', @Profile nvarchar(max) = N'standard', @MaxRows int = 10000)`

Inline-T-SQL-TVF vor intern markierter SAFE-CLR-TVF `TVF_RegexMatchesCore`.
Alle Unicodeargumente erhalten vor dem internen Aufruf dieselbe n-Collation-
Metadatenidentität; es findet keine varchar-Codepagekonvertierung statt.
varchar-Quellen sind **am Caller** verlustfrei nach nvarchar(max) zu dekodieren.
SELECT auf der öffentlichen TVF genügt bei gleicher Ownership; niedrig-
privilegierte Cross-DB-Nutzermappings sind ein eigener Prüfkontext.

## Ergebnis und Semantik

| Spalte | SQL-Typ | Bedeutung |
|---|---|---|
| Ordinal | bigint | 1-basierte Treffernummer |
| StartPosition | bigint | 1-basierte Position in der vollständigen Quelle |
| Length | bigint | Trefferlänge in UTF-16-Codeeinheiten |
| Value | nvarchar(max) | unveränderter Gesamttreffer |

Erfolgszeilen enthalten niemals NULL. SQL-CLR/inline-Metadaten weisen die
Spalten dennoch als nullable aus; dieser Metadatenvertrag wird separat geprüft.
Die Ergebnismenge besitzt ohne äußeres `ORDER BY Ordinal` keine physische
Sortiergarantie. Kein Treffer oder NULL-Input/Pattern ergibt **keine Zeilen**.
`OUTER APPLY` bewahrt bei Bedarf die Callerzeile; `CROSS APPLY` verwirft sie.

Leere Treffer sind gültig und liefern `Value=N''`, Length=0. Ausschließlich
die Suche rückt danach eine UTF-16-Codeeinheit weiter; am Ende gibt es höchstens
einen terminalen leeren Treffer. Surrogate Pairs zählen zwei Einheiten, nicht
ein Graphem. Start muss positiv sein; Start=InputLength+1 erlaubt den terminalen
Treffer, größere gültige Startwerte liefern nach vollständigem Preflight 0 Zeilen.

## Fehlerpriorität und Limits

1. NULL-Input oder NULL-Pattern: sofort 0 Zeilen, selbst bei sonst ungültigen Parametern.
2. Profile exakt `standard`/`large`; dann Start/MaxRows positiv und nicht NULL.
3. Flags: vorhandenes `c/i/m/s`, kulturinvariant, keine Konflikte/Duplikate.
4. Inputgröße, Patterngröße, strukturelle Komplexität und kanonische Dialektprüfung.
5. Suche, kumulative Zeilen-/Textlimits und kooperatives Restbudget.

MaxRows ist 1–100000, Default 10000. Standard begrenzt Quelle und Ergebnis-
textsumme jeweils auf 2 MiB UTF-16 (1048576 Einheiten), Large ausdrücklich auf
16 MiB (8388608 Einheiten); Pattern höchstens 8000 Einheiten. Vorhandene
Komplexitätsgrenzen (Tiefe64/Alternation1024/übersetzte Länge64000/Quantifier1000)
und Budgets 500/2000 ms mit höchstens 250-ms-Suchschritten bleiben erhalten.
Keine implizite Profilaufwertung, stille Truncation oder Unlimited-Einstellung.
Die MaxRows-Ceiling ist keine Durchsatzgarantie: auch eine größenkonforme
100000-Zeilen-Anfrage darf am Zeitbudget vollständig und atomar scheitern.

Fehler erscheinen wie R2a als SQL6522 mit `TBX_REGEX_*`-Präfix:
INVALID_ARGUMENT, INVALID_FLAGS, INPUT_TOO_LARGE, PATTERN_TOO_LARGE,
PATTERN_TOO_COMPLEX, INVALID_PATTERN, TIMEOUT; zusätzlich TOO_MANY_ROWS und
OUTPUT_TOO_LARGE. Dies ist kein neuer SQL-THROW-Nummernvertrag. Unerwartete
Engine-/Allokationsfehler werden nicht kaschiert. Das gesamte Resultat wird
**vor** Rückgabe des Enumerators geprüft und materialisiert, niemals Teiltreffer
oder eine Fehlerzeile als scheinbarer Erfolg. SQL-Planabbruch nach erfolgter
Materialisierung bleibt normale Engine-/Clientsemantik.

## Ressourcen und Verwendung

Quelle, Pattern, Regexobjekt, Ergebnisliste und einzelne Trefferstrings sind
gleichzeitig materialisiert. Die Textsumme ist kein Gesamt-RAM-Limit; MaxRows
begrenzt zusätzlich die Metadatenzahl. Keine Streaming-, MemoryGrant-,
Parallelitäts-, SARGability- oder harte Wallclockzusage. Es gibt keinen
Daten-/Datei-/Netzwerkzugriff und keinen global veränderlichen Cache.

```sql
SELECT m.Ordinal,m.StartPosition,m.Length,m.Value
FROM toolbelt_string.TVF_RegexMatches(N'a12 b3',N'[0-9]+',DEFAULT,DEFAULT,DEFAULT,DEFAULT) m
ORDER BY m.Ordinal;
```

Deployment 1.2.0 koppelt exakten Assemblyhash, interne/public Marker, die
vier neuen Plätze und Uninstall. Historische 1.0-/1.1-Upgrades sind getrennt
von Wiederdeployment zu prüfen. R1b-/R2a-Verträge bleiben unverändert.

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten in standard,8388608 in large. Keine automatische Kürzung. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens8000 UTF-16-Einheiten, nach Übersetzung64000; Gruppentiefe64,Alternationen1024. Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus. |
| `@Start` | `int` | `1` | Input | Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. R2 validiert Profil,Flags,Input/Pattern und gegebenenfalls Replacement auch vor dieser Leerausgabe. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. Als nvarchar(max) gebunden, im begrenzten Intake maximal4 UTF-16-Einheiten. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Exakt ordinal standard oder large, ohne Trim/Casefold. standard:1048576 UTF-16-Einheiten pro Input/Ersatz/Output und500ms kooperatives Budget; large:8388608 und2000ms. NULL/leer/andereWerte ungültig. Profilintake maximal8 Einheiten vor Start des gemeinsamen Kontexttimers. Früher Input/Pattern-NULL-Kurzschluss,beiReplace zusätzlichReplacementNULL, hat Vorrang. |
| `@MaxRows` | `int` | `10000` | Input | Ganzzahl1..100000, fachlich nichtNULL. Grenze der vollständig materialisierten Ausgabe, keine TOP-/Teilpräfixsemantik. Bei Überschreitung Fehler statt verwendbarer Teilzeilen. Zählt Gesamttreffer beziehungsweise sämtliche Splittokens einschließlich Leertokens. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#regex).

## Vollständiger Usage-Skill

Der [quellgeprüfte Skill](../../../Metadata/UsageSkills/toolbelt_string/TVF_RegexMatches.md) beschreibt sämtliche Argumente, Defaults, NULL-Pfade, Dialektgrenzen, Ergebnisse und Fehler. Er ist auch Bestandteil der ausgelieferten Funktions-DDL. Interne CLR-Kerne haben keine SQL-Defaults und verweisen auf die öffentlichen Fassaden; sie sind kein zusätzlicher Fachaufrufweg. Historische Nachweise und neue native Qualifikation bleiben getrennt.
