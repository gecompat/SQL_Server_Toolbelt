# Execution Cancellation Contract Test Matrix

| Bereich | Nachweis |
|---|---|
| Öffentlicher Vertrag | Parameter, Help, TVF- und SVF-Signatur, sichere Statusspalten |
| Persistenz | erste Anforderung, wiederholte Anforderung, monotone Speicherung |
| Context und Transaktion | implizite aktuelle ExecutionId, fehlender Context, aktive und uncommittable Caller-Transaktion |
| Konkurrenz | parallele Anforderungen derselben ExecutionId ergeben genau eine Statuszeile |
| Lifecycle | Dependency-, Kollisions-, Redeploy-, Local-, Central- und Uninstall-Vertrag |
| Befüllter 1.0.0-Repeat | Zwei echte Deploys in Local/Central; alle fünf Spalten inklusive Rowversionbytes, UTC-Auditwerte, NULL/Leerstring/Unicode/Padding, Objekt-IDs und ausgewählte Katalogmetadaten einschließlich vorhandener Permissions, eigener Annotationen und nichtleerer Tabellen-/Spalten-MS_Description; Status-API danach read-only |
| Plattformmatrix | SQL Server 2019, 2022 und 2025 auf Linux und Windows; CU nur bei patchabhängigem Test |

Der neue befüllte Repeat ist unabhängig vom historischen Lifecycle zu
qualifizieren. Er verändert weder Source noch Deployment, erzeugt keine
Benutzergrants und belegt keine tatsächlichen Minimalrechte. Windows, weitere
Repeat-Compatibility-Levels und historische Versionsübergänge bleiben ohne
eigene erfolgreiche Evidenz `not executed`. Das Fixture benötigt eine eigene
leere Installationsdatenbank; sein Adapter verantwortet Cleanup auch nach
SQLCMD-Fehlerabbruch. Einzelheiten und Ausführungsgrenzen stehen in
[Tests/README](README.md#befüllter-versionsgleicher-repeat).

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-07`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37690604199`
- Scope: Commit fac18e590f854a26364e5f498c6a2b5d330a95c2: zwei echte befüllte 1.0.0-Repeats lokal/zentral auf SQL Server 2019/150, 2022/160, 2025/170 Linux; alle fünf Spalten mit Rowversionbytes, synthetische Audit-/NULL-/Textwerte, ausgewählter Katalog und eigene typisierte Annotationen inklusive MS_Description erhalten. Vorhandene API-, Concurrency-, Consumer- und Uninstallfälle sowie eigene CI-Bereinigung bestanden. Keine neuen Windows-Repeats, weiteren Repeat-CLs, nichtleeren Benutzergrants, echten Minimalrechte oder historischen Schemaübergänge qualifiziert.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
