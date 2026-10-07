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
- Datum: `2026-09-11`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Lokales SQL_Server_Lab; SQL Server 2019, 2022 und 2025 unter Linux und Windows; öffentlicher Vertrag, Idempotenz, Transaktionsschutz, Parallelität, Lifecycle, Central und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
