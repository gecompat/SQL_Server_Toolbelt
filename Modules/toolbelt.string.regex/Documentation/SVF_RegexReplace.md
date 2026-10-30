# `toolbelt_string.SVF_RegexReplace`

R2a, Version `1.1.0`, ausdrücklich freigegeben am 2026-10-01. Die T-SQL-SVF mit SAFE-CLR-Kern
ersetzt nicht überlappende Gesamttreffer durch literal Unicode-Text.

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu durchsuchender Unicode-Text; leer ist gültig. Positionen zählen UTF-16-Einheiten, 1-basiert, ohne automatische Normalisierung. NULL ergibt NULL bei SVF bzw. keine Zeilen bei TVF vor weiterer Parameterprüfung. Maximum richtet sich nach Profile. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Begrenzter Toolbelt-Regexdialekt gemäß REGEX_FUNCTIONS.md, kein beliebiges .NET-Pattern: Literale/Escapes, Punkt, ^/$, Gruppen/Alternativen, Klassen und begrenzte Quantoren; ASCII-Definitionen für \d/\w/\s, Unicode-Kategorie nur \p{L}. Lookarounds und Pattern-Backreferences sind nicht erlaubt. Leer ist gültig, NULL propagiert NULL/keine Zeilen vor anderer Prüfung. Maximum 8000 UTF-16-Einheiten, übersetztes Pattern höchstens 64000, Gruppentiefe 64, Alternativen 1024 und Quantorobergrenze 1000. |
| `@Replacement` | `nvarchar(max)` | `kein Default` | Input | Ersetzungstext, leer löscht den Treffer; NULL ergibt NULL vor weiterer Prüfung. Wird wörtlich eingesetzt: $1, ${Name} und Backslashes lösen keine Gruppenreferenzen aus. Höchstens 1048576 UTF-16-Einheiten im Profil standard beziehungsweise 8388608 in large; auch die gesamte erzeugte Ausgabe bleibt auf dieses Profilbudget begrenzt. |
| `@Start` | `int` | `1` | Input | Ganzzahl 1..2147483647, Default 1: 1-basierter Suchbeginn in UTF-16-Einheiten. NULL/0/negativ ungültig. Länge+1 lässt einen terminalen Leertreffer zu; weiter dahinter gibt es keinen Treffer. |
| `@Occurrence` | `int` | `0` | Input | Ganzzahl 0..2147483647, Default 0: 0 ersetzt alle Treffer ab Start, positiv nur den n-ten Treffer ab Start. Negativ/NULL ungültig; vor Start bleibt der Text erhalten. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ sind die einzelnen Flags c = case-sensitiv (Default), i = case-insensitiv/CultureInvariant, m = ^/$ je Zeile, s = Punkt auch über Zeilenumbrüche. Leer ist ebenfalls gültig und case-sensitiv. Erlaubte Mengen: leer, c, i, m, s, cm, cs, im, is, ms, cms, ims; Reihenfolge beliebig, jedes Zeichen höchstens einmal. c+i, Großbuchstaben, Spaces, andere Zeichen und NULL sind ungültig. Ein früher NULL-Input/-Pattern-Pfad überspringt die Prüfung. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) erlaubt 1048576 Input-UTF-16-Einheiten und 500 ms kooperatives Gesamtbudget; large erlaubt 8388608 Einheiten und 2000 ms. Jede Engine-Suche bleibt auf höchstens 250 ms begrenzt. NULL/leer/andere Werte ungültig; NULL-Input/-Pattern (bei Replace auch NULL-Replacement) beendet vorher. |
<!-- API_PARAMETERS:END -->

Ergebnis: `nvarchar(max)`. Occurrence 0 ersetzt alle, ein positiver Wert nur
den n-ten Treffer ab der 1-basierten Startposition. Ohne Treffer bleibt die
Quelle unverändert. `$1` und `\1` im Ersatztext sind literal. NULL in Quelle,
Pattern oder Ersatztext liefert sofort NULL vor jeder weiteren Validierung.

Bei nicht-NULL-Eingaben sind NULL/negative Positionsparameter, ungültiges
Profil und NULL/ungültige Flags Fehler. Erst nach Vertragsprüfung liefert
Start größer als InputLength+1 die Quelle unverändert. Start am InputLength+1
kann einen terminalen leeren Treffer ersetzen. Leere Treffer rücken die Suche
um eine UTF-16-Codeeinheit vor; der terminale leere Treffer wird einmal ersetzt.

Die gemeinsamen [R2a-Grenzen und Betriebsregeln](./REGEX_FUNCTIONS.md#r2a-transformationsvertrag)
gelten. SQL-Fehler 6522 trägt `TBX_REGEX_*`, kein abgeschnittenes Teilergebnis.
EXECUTE auf der öffentlichen Funktion ist erforderlich; direkte Rechte auf
dem internen CLR-Kern werden dem Fachcaller nicht erteilt. Unterstützter Provider:
dieselbe SAFE-CLR-Assembly für SQL Server 2019/2022/2025 Windows/Linux.

Allgemeines Regex-Matching und Outputbau sind nicht als äquivalenter
relationaler Ausdruck belegt. Ein inline-TVF-Wrapper um die CLR-SVF wäre
kein relationaler Kern und kein Performancebeleg; deshalb wird keine solche
Scheinalternative bereitgestellt. Relationale Vorfilter werden bevorzugt.

Beispiel: `SVF_RegexReplace(N'a12b34', N'[0-9]+', N'X', 1, 0, N'c', N'standard')`
liefert `N'aXbX'`.

## Beispielaufruf

```sql
SELECT toolbelt_string.SVF_RegexReplace(N'abc123 def456', N'[0-9]+', N'X', 1, 1, N'c', N'standard') AS ResultValue;
```

Die Beispiele verwenden synthetische Werte. Vorlagen mit registrierten
Handlern, Tabellen oder Dateien setzen deren beschriebene Vorbereitung voraus.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#regex).
