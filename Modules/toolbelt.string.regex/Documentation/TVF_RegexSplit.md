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
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu durchsuchender Unicode-Text; leer ist gültig. Positionen zählen UTF-16-Einheiten, 1-basiert, ohne automatische Normalisierung. NULL ergibt NULL bei SVF bzw. keine Zeilen bei TVF vor weiterer Parameterprüfung. Maximum richtet sich nach Profile. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Begrenzter Toolbelt-Regexdialekt gemäß REGEX_FUNCTIONS.md, kein beliebiges .NET-Pattern: Literale/Escapes, Punkt, ^/$, Gruppen/Alternativen, Klassen und begrenzte Quantoren; ASCII-Definitionen für \d/\w/\s, Unicode-Kategorie nur \p{L}. Lookarounds und Pattern-Backreferences sind nicht erlaubt. Leer ist gültig, NULL propagiert NULL/keine Zeilen vor anderer Prüfung. Maximum 8000 UTF-16-Einheiten, übersetztes Pattern höchstens 64000, Gruppentiefe 64, Alternativen 1024 und Quantorobergrenze 1000. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ sind die einzelnen Flags c = case-sensitiv (Default), i = case-insensitiv/CultureInvariant, m = ^/$ je Zeile, s = Punkt auch über Zeilenumbrüche. Leer ist ebenfalls gültig und case-sensitiv. Erlaubte Mengen: leer, c, i, m, s, cm, cs, im, is, ms, cms, ims; Reihenfolge beliebig, jedes Zeichen höchstens einmal. c+i, Großbuchstaben, Spaces, andere Zeichen und NULL sind ungültig. Ein früher NULL-Input/-Pattern-Pfad überspringt die Prüfung. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) erlaubt 1048576 Input-UTF-16-Einheiten und 500 ms kooperatives Gesamtbudget; large erlaubt 8388608 Einheiten und 2000 ms. Jede Engine-Suche bleibt auf höchstens 250 ms begrenzt. NULL/leer/andere Werte ungültig; NULL-Input/-Pattern (bei Replace auch NULL-Replacement) beendet vorher. |
| `@MaxRows` | `int` | `10000` | Input | Ganzzahl 1..100000, Default 10000; NULL/0/negativ/größer ungültig. Begrenzt die vollständig materialisierte Ausgabe; Überschreitung verwirft den gesamten Aufruf ohne gültiges Teilpräfix. Bei Split zählen auch leere Tokens. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#regex).
