# TVF_OsaDistance

Öffentliche inline Fassade über den gemeinsamen SAFE-CLR-Editierdistanzkern.
Optimal String Alignment ergänzt benachbarte Transposition für 1, eingeschränkt; CA→ABC ist 3. Kein uneingeschränktes Damerau-Levenshtein.

Signatur: LeftText nvarchar(max), RightText nvarchar(max), MaxDistance int=NULL,
Profile nvarchar(max)=N'standard'. In SQL-Funktionsaufrufen Defaults ausdrücklich
mit DEFAULT angeben. Genau eine Zeile: Distance int nullable,
ExceedsMaxDistance bit nullable, ErrorCode int logisch nicht NULL; nullable
SQL-Metadaten sind erlaubt. Native Metadatenqualifikation auf den ausgewählten Linux-2019-/Windows-2025-Zielen bestanden; übrige physische Ziele bleiben offen.

Unicode Scalars, ordinal und case-sensitive; keine Normalisierung/Trimmung.
NULL links oder rechts ergibt NULL/NULL/0 vor allen anderen Prüfungen.
Exakte Antwort ergibt Distanz/0/0; nachgewiesene Thresholdüberschreitung NULL/1/0.
MaxDistance kann INT_MAX sein. Fachfehler geben NULL/NULL/Code zurück:
1 Profil, 2 negative Grenze, 3 Rawlimit, 4 ungültiges UTF16, 5 Scalarlimit,
6 prognostiziertes DP-Budget. Fehlerpriorität ist genau diese Reihenfolge;
Thresholdbeweis liegt nach Scalarvalidierung und vor DP-Budget.

standard: 2048 UTF16-Einheiten/1024 Scalars je Text, 1048576 Zellen.
large: 65536 Einheiten/32768 Scalars je Text, 16777216 Zellen.
Kein Abschneiden. Mengenorientiert CROSS APPLY verwenden; die Fassade verspricht
keinen relationalen DP-Plan, Parallelitäts- oder Heapgewinn.

Recht: SELECT auf der öffentlichen TVF. Framework 4.8, SAFE, SQL Server
2019/2022/2025, Windows/Linux als Zielmatrix. Native Qualifikation auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 lokal/zentral bestanden; übrige physische Ziele und tatsächliche Minimalrechte nicht ausgeführt. Aktuelle CI ist ein separater PR-Mergegate.
[Vertrag](../../../Documentation/Architecture/EDIT_DISTANCE_CONTRACT.md),
[Modul](../README.md), [Tests](../Tests/README.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeftText` | `nvarchar(max)` | `kein Default` | Input | Unicode-Text als nvarchar(max), ohne Trimmen, Culture-/Casefolding oder Normalisierung. NUL und nachgestellte Spaces bleiben Daten. NULL auf mindestens einer Textseite liefert eine Zeile mit NULL-Fachwerten und ErrorCode=0 vor allen Profil-, Schwellen- und Längenprüfungen. Leerer Text ist von NULL verschieden. Verglichen werden strikte Unicode-Skalare, keine Graphemcluster. |
| `@RightText` | `nvarchar(max)` | `kein Default` | Input | Unicode-Text als nvarchar(max), ohne Trimmen, Culture-/Casefolding oder Normalisierung. NUL und nachgestellte Spaces bleiben Daten. NULL auf mindestens einer Textseite liefert eine Zeile mit NULL-Fachwerten und ErrorCode=0 vor allen Profil-, Schwellen- und Längenprüfungen. Leerer Text ist von NULL verschieden. Verglichen werden strikte Unicode-Skalare, keine Graphemcluster. |
| `@MaxDistance` | `int` | `NULL` | Input | int-Schwelle: NULL bedeutet vollständige Distanz, nichtnegativ bis 2147483647 begrenzt die gesuchte Distanz; negativ ergibt Code 2 nach Profilprüfung, außer beim frühen NULL-Textpfad. Überschreitung ist ExceedsMaxDistance=1 bei Distance=NULL und Code 0, kein exakter Abstand. Vor DP kann bereits die Skalarlängendifferenz die Überschreitung beweisen. Bei vorhandenem SQL-Default ausdrücklich DEFAULT oder NULL übergeben. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Exakt ordinal standard oder large, keine andere Schreibweise und kein Trim. standard: je Text maximal 2048 UTF-16-Codeunits und 1024 Skalare, maximal 1048576 geplante Arbeitseinheiten. large: 65536 Codeunits, 32768 Skalare, 16777216 Arbeitseinheiten. NULL/leer/unbekannt liefert Code 1, außer beim früheren NULL-Textpfad. Im SQL-Funktionsaufruf bei vorhandenem Default das Argument ausdrücklich als DEFAULT angeben statt seine Position wegzulassen. SQL-Default standard. |
<!-- API_PARAMETERS:END -->

## Beispielaufruf

```sql
SELECT * FROM toolbelt_string.TVF_OsaDistance(N'kitten', N'sitting', NULL, N'standard');
```

Bei einem Funktionsaufruf mit `SELECT` werden Argumente positionsbezogen übergeben. `DEFAULT` aktiviert einen deklarierten Default; `NULL` hat die im Vertrag beschriebene eigene Bedeutung.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#textdistanz).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/EditDistance.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
