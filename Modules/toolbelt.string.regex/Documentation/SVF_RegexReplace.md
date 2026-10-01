# `toolbelt_string.SVF_RegexReplace`

R2a, Version `1.1.0`, ausdrücklich freigegeben am 2026-10-01. Die T-SQL-SVF mit SAFE-CLR-Kern
ersetzt nicht überlappende Gesamttreffer durch literal Unicode-Text.

| Parameter | Typ | Default |
|---|---|---|
| `@Input`, `@Pattern`, `@Replacement` | `nvarchar(max)` | erforderlich |
| `@Start` | `int` | `1` |
| `@Occurrence` | `int` | `0` |
| `@Flags` | `nvarchar(max)` | `N'c'` |
| `@Profile` | `nvarchar(max)` | `N'standard'` |

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
SELECT/REFERENCES auf der Funktion ist erforderlich. Unterstützter Provider:
dieselbe SAFE-CLR-Assembly für SQL Server 2019/2022/2025 Windows/Linux.

Allgemeines Regex-Matching und Outputbau sind nicht als äquivalenter
relationaler Ausdruck belegt. Ein inline-TVF-Wrapper um die CLR-SVF wäre
kein relationaler Kern und kein Performancebeleg; deshalb wird keine solche
Scheinalternative bereitgestellt. Relationale Vorfilter werden bevorzugt.

Beispiel: `SVF_RegexReplace(N'a12b34', N'[0-9]+', N'X', 1, 0, N'c', N'standard')`
liefert `N'aXbX'`.
