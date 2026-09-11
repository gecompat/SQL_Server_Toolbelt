# Execution Cancellation Contract Test Matrix

| Bereich | Nachweis |
|---|---|
| Öffentlicher Vertrag | Parameter, Help, TVF- und SVF-Signatur, sichere Statusspalten |
| Persistenz | erste Anforderung, wiederholte Anforderung, monotone Speicherung |
| Context und Transaktion | implizite aktuelle ExecutionId, fehlender Context, aktive und uncommittable Caller-Transaktion |
| Konkurrenz | parallele Anforderungen derselben ExecutionId ergeben genau eine Statuszeile |
| Lifecycle | Dependency-, Kollisions-, Redeploy-, Local-, Central- und Uninstall-Vertrag |
| Plattformmatrix | SQL Server 2019, 2022 und 2025 auf Linux und Windows; CU nur bei patchabhängigem Test |

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-11`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Lokales SQL_Server_Lab; SQL Server 2019, 2022 und 2025 unter Linux und Windows; öffentlicher Vertrag, Idempotenz, Transaktionsschutz, Parallelität, Lifecycle, Central und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
