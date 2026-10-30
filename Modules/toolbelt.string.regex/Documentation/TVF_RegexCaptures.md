# TVF_RegexCaptures

Liefert sämtliche erfolgreichen Capture-Wiederholungen des begrenzten
Capture-Dialekts. Einzelfreigabe 2026-10-01; Vertrag und Vor-Source-Qualifikation:
[Capture-/Replace-Vertrag](../../../Documentation/Architecture/REGEX_CAPTURE_REPLACE_CONTRACT.md).

`toolbelt_string.TVF_RegexCaptures(@Input nvarchar(max), @Pattern nvarchar(max), @Start int = 1, @Flags nvarchar(max) = N'c', @Profile nvarchar(max) = N'standard', @MaxRows int = 10000)`

Die Inline-TVF verwendet den internen SAFE-CLR-Kern `TVF_RegexCapturesCore`.
Unicodeargumente erhalten vor dem Kernaufruf dieselbe Collationidentität.
varchar-Quellen sind am Caller verlustfrei nach nvarchar(max) zu dekodieren.

| Spalte | Typ | Bedeutung |
|---|---|---|
| MatchOrdinal | bigint | 1-basierter nicht überlappender Gesamttreffer |
| GroupOrdinal | int | Öffnende Capture-Klammern von links nach rechts, ab 1 |
| CaptureOrdinal | bigint | Wiederholung innerhalb der Gruppe ab 1; Sentinel 0 |
| GroupName | nvarchar(128) | Deklarierter Name oder dezimaler GroupOrdinal |
| Matched | bit | 1 für Capture, 0 für nicht beteiligte Gruppe |
| StartPosition | bigint | 1-basierte UTF-16-Position; Sentinel NULL |
| Length | bigint | UTF-16-Länge; Sentinel NULL |
| Value | nvarchar(max) | Capturewert; Sentinel NULL |

SQL-Metadaten sind nullable. Tatsächlich leere Captures haben Matched=1,
Length=0 und Value=N''; nicht beteiligte Gruppen erhalten genau eine
Sentinelzeile je Treffer. Gruppe 0 wird nicht ausgegeben. Ein Pattern ohne
Capturegruppen liefert keine Zeilen. Explizites `ORDER BY MatchOrdinal,
GroupOrdinal,CaptureOrdinal` ist für eine definierte Ergebnisreihenfolge nötig.
NULL-Input/Pattern liefert vor übriger Validierung keine Zeilen.

Normalgruppen und `(?<Name>...)` sind erlaubt. Höchstens 64 Gruppen,
ASCII-Namen mit Buchstabe/Unterstrich am Anfang; doppelte Namen auch bei
unterschiedlicher Großschreibung sind ungültig. Keine Pattern-Rückreferenzen
oder weiteren Spezialgruppen. Alte Regex-APIs behalten ihren Dialekt.

Profile standard/large begrenzen Quelle und kumulativen Ergebnistext auf
1048576/8388608 UTF-16-Einheiten. Jede Zeile belastet das Ergebnislimit mit
GroupName.Length plus Value.Length; auch wiederholte Namen und Sentinels
zählen. MaxRows 1–100000, Default 10000. Pattern höchstens 8000 Einheiten,
Tiefe64, Alternation1024, übersetzte Länge64000, Quantifier1000.
Vor Enginekonstruktion begrenzt die konservative Strukturprüfung erfolgreiche
Capture-Historien auf 100000; nullable unbeschränkte Capture-Schleifen werden
abgewiesen. Dies begrenzt weder Backtracking noch den gesamten Heap.

Fehlerpriorität: NULL, Profile, Start/MaxRows, Flags, Größen, Pattern/Komplexität/
Capture-Historie, Suche/Output/Budget. SQL6522 mit stabilem TBX_REGEX_*-Präfix;
zusätzlich zu den bestehenden Fehlern CAPTURE_HISTORY_LIMIT. Das Resultat
wird vollständig vor Enumeratorrückgabe materialisiert; keine Teilzeilen.
500/2000-ms-Budgets sind kooperativ, keine Durchsatz-/Wallclockzusage.

```sql
SELECT c.*
FROM toolbelt_string.TVF_RegexCaptures(N'abb',N'(?<First>a)(b)+',DEFAULT,DEFAULT,DEFAULT,DEFAULT) c
ORDER BY c.MatchOrdinal,c.GroupOrdinal,c.CaptureOrdinal;
```

SELECT auf der öffentlichen TVF genügt bei gleicher Ownership. Lowpriv-
CrossDB-Mappings benötigen eigenen Nachweis. Deployment 1.3.0 gehört zum
bestehenden Modul; Trust ist ein separates exaktes administratives Opt-in.

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu durchsuchender Unicode-Text; leer ist gültig. Positionen zählen UTF-16-Einheiten, 1-basiert, ohne automatische Normalisierung. NULL ergibt NULL bei SVF bzw. keine Zeilen bei TVF vor weiterer Parameterprüfung. Maximum richtet sich nach Profile. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Begrenzter Toolbelt-Regexdialekt gemäß REGEX_FUNCTIONS.md, kein beliebiges .NET-Pattern: Literale/Escapes, Punkt, ^/$, Gruppen/Alternativen, Klassen und begrenzte Quantoren; ASCII-Definitionen für \d/\w/\s, Unicode-Kategorie nur \p{L}. Lookarounds und Pattern-Backreferences sind nicht erlaubt. Leer ist gültig, NULL propagiert NULL/keine Zeilen vor anderer Prüfung. Maximum 8000 UTF-16-Einheiten, übersetztes Pattern höchstens 64000, Gruppentiefe 64, Alternativen 1024 und Quantorobergrenze 1000. Capturegruppen können unbenannt oder (?&lt;Name&gt;...) sein; Namen 1..128 ASCII-Zeichen, Beginn Buchstabe/_ danach zusätzlich Ziffern, ohne case-insensitive Namensduplikate. Maximal 64 deklarierte Gruppen und konservative Capture-History 100000. |
| `@Start` | `int` | `1` | Input | Ganzzahl 1..2147483647, Default 1: 1-basierter Suchbeginn in UTF-16-Einheiten. NULL/0/negativ ungültig. Länge+1 lässt einen terminalen Leertreffer zu; weiter dahinter gibt es keinen Treffer. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ sind die einzelnen Flags c = case-sensitiv (Default), i = case-insensitiv/CultureInvariant, m = ^/$ je Zeile, s = Punkt auch über Zeilenumbrüche. Leer ist ebenfalls gültig und case-sensitiv. Erlaubte Mengen: leer, c, i, m, s, cm, cs, im, is, ms, cms, ims; Reihenfolge beliebig, jedes Zeichen höchstens einmal. c+i, Großbuchstaben, Spaces, andere Zeichen und NULL sind ungültig. Ein früher NULL-Input/-Pattern-Pfad überspringt die Prüfung. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) erlaubt 1048576 Input-UTF-16-Einheiten und 500 ms kooperatives Gesamtbudget; large erlaubt 8388608 Einheiten und 2000 ms. Jede Engine-Suche bleibt auf höchstens 250 ms begrenzt. NULL/leer/andere Werte ungültig; NULL-Input/-Pattern (bei Replace auch NULL-Replacement) beendet vorher. |
| `@MaxRows` | `int` | `10000` | Input | Ganzzahl 1..100000, Default 10000; NULL/0/negativ/größer ungültig. Begrenzt die vollständig materialisierte Ausgabe; Überschreitung verwirft den gesamten Aufruf ohne gültiges Teilpräfix. Zählt jede Capture und auch Kontrollzeilen nicht beteiligter deklarierter Gruppen, nicht bloß Matches. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#regex).
