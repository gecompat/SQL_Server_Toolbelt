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
- Datum: `2026-10-07`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37690604199`
- Scope: Commit fac18e590f854a26364e5f498c6a2b5d330a95c2: zwei echte befüllte 1.0.0-Repeats lokal/zentral auf SQL Server 2019/150, 2022/160, 2025/170 Linux; alle fünf Spalten mit Rowversionbytes, synthetische Audit-/NULL-/Textwerte, ausgewählter Katalog und eigene typisierte Annotationen inklusive MS_Description erhalten. Vorhandene API-, Concurrency-, Consumer- und Uninstallfälle sowie eigene CI-Bereinigung bestanden. Keine neuen Windows-Repeats, weiteren Repeat-CLs, nichtleeren Benutzergrants, echten Minimalrechte oder historischen Schemaübergänge qualifiziert.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
