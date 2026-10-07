# Event-Log-Contract-Testmatrix

- kanonischer EventName und erlaubte Level
- begrenztes JSON-Objekt, Message- und Fehlerwerte
- resultsetfreier synchroner Write-Vertrag
- getrennte Remote-Session
- expliziter und aktiver Execution Context
- Remote-Commit überlebt Caller-Rollback
- Remote-Commit aus `XACT_STATE() = -1`
- Handler- und Providerfehler werden weitergegeben
- begrenzte Retention mit Savepoint-Vertrag
- vier parallele Caller-Sessions
- Redeploy erhält Events und Work-Type-Registrierung
- zusätzlicher befüllter `RepeatCurrent` mit zwei echten Deploys: Linux2019/150,2022/160,2025/170 lokal/zentral am Commit `6f51078cfa1f13ace32212f07d46de8d55d39ef0` bestanden; neue Windows-Repeats und weitere Repeat-CLs offen
- alle 24 Eventspalten einschließlich NULL/Leerstring, Unicode/Padding und 100-ns-Auditwerten
- gelöschter Identityhöchstwert und nächster regulärer Insert ohne Reseed
- EventLog ohne rowversion; fremde WorkType-Zeilen einschließlich Rowversion unverändert
- explizite öffentliche Register-/Disable-Fixture: erste kanonische Reaktivierung mit neuer Rowversion, zweiter exakter No-op
- stabile eigene WorkType-ID/Created-Audits, kanonische Konfiguration und erwartete Modified-/Disabled-Audits
- ausgewählte Katalog-/Definitions-/Parametermetadaten und vorhandene Permissions ohne neue Grants
- typisierte Tabellen-/Spaltenannotation und `MS_Description` unverändert, Cleanup nur eigener Fixtureartefakte
- lokale und zentrale Installation
- Uninstall verweigert stillen Datenverlust und entfernt den eigenen Work Type
- physische SQL-Server-2019-/2022-/2025-Ziele unter Windows base und Linux latest

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31018284410

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-07`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37692309192`
- Scope: Commit 6f51078cfa1f13ace32212f07d46de8d55d39ef0: zwei echte befüllte 1.0.0-Repeats lokal/zentral auf Linux2019/150,2022/160,2025/170; alle 24 Eventspalten mit NULL-/Text-/Auditbytes, verbrauchter Identityhöchstwert/Folgeinsert, ausgewählter Katalog und eigene typisierte Annotationen/MS_Description erhalten. Erster Deploy reaktiviert eigenen abweichend deaktivierten WorkType kanonisch, zweiter erhält vollständige aktive Zeile/Rowversion; andere Registrierungen unverändert. Bestehende API-/Rollback-/Parallelitäts-/Consumer-/Uninstallfälle und eigene CI-Bereinigung bestanden. Neue Windows-Repeats, weitere Repeat-CLs, nichtleere Benutzergrants, Minimalrechte, historische Migrationen und Hard-Interrupt-Recovery bleiben offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
