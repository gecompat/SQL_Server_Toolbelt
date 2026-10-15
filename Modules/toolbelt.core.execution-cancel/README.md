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

## Freigegebene Security-Härtung 2026-10-15

SC-015: Ohne Callertransaktion werden bestehende ExecutionIds weiterhin idempotent verarbeitet. Vor einem neuen Insert werden unter derselben transaktionsgebundenen Datenbanksperre100000 Zeilen insgesamt und10000 je tatsächlichem Datenbankprincipal (ID/SID/create_date) geprüft. Fehler52605/52606 verwerfen neue IDs atomar. Historische nicht eindeutig zuordenbare Rows zählen zur DBquote. Kein Purge, keine Rücknahme und keine automatische Rechtevergabe.

Details und abgegrenzte Nachweise: [Security-Härtung](../../Documentation/Architecture/SECURITY_HARDENING_2026_10.md).

Aktueller Securitystand: `partially validated`, `unreleased`. Die bisherigen
Matrixnachweise gelten historisch; die neuen Verträge sind gezielt auf Linux
SQL Server 2019 geprüft. Weitere Plattform-/CL-Nachweise bleiben offen.
