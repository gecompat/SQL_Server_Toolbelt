# Cooperative Execution Cancellation

`toolbelt.core.execution-cancel` stellt einen persistenten, kooperativen
Abbruchindikator für eine `ExecutionId` bereit. Die Anforderung ist
idempotent und irreversibel. Sie beendet keine SQL-Session, verändert keine
Work-Queue-Zeile und hebt keine fachlichen Seiteneffekte auf.

Das Modul benötigt `toolbelt.core.execution-context` 1.0.0 oder höher. Der
anfragende Caller darf keine aktive Transaktion haben; damit wird die kurze
eigene Transaktion der Anforderung nicht durch einen späteren Caller-Rollback
zurückgenommen.

Worker prüfen den Status vor dem Start, zwischen begrenzten Arbeitsschritten
und vor ihrem eigenen Commit. Der Work-Type-Vertrag bestimmt die konkrete
Checkpoint-Frequenz. Nach einer Beobachtung entscheidet der Worker über seinen
kontrollierten Work-Queue-Ausgang.

Die Objekte, Berechtigungen, Fehler und Beispiele stehen in
[EXECUTION_CANCELLATION_OBJECTS.md](Documentation/EXECUTION_CANCELLATION_OBJECTS.md).

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-11`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Lokales SQL_Server_Lab; SQL Server 2019, 2022 und 2025 unter Linux und Windows; öffentlicher Vertrag, Idempotenz, Transaktionsschutz, Parallelität, Lifecycle, Central und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
