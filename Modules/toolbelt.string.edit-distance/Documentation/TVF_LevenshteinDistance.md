# TVF_LevenshteinDistance

Öffentliche inline Fassade über den gemeinsamen SAFE-CLR-Editierdistanzkern.
Levenshtein zählt Einfügen, Löschen und Ersetzen jeweils mit 1.

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
