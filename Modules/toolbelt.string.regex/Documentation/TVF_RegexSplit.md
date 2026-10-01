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
