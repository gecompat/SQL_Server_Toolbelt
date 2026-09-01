# Work-Type-Contract-Testmatrix

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

- kanonischer Work-Type-Name und Ablehnung von SQL-Text-/Identifier-Missbrauch
- vorhandene Stored Procedure als einzig zulässiger Handlertyp
- Caller-`EXECUTE` bei Registrierung und optional bei Resolve
- ParameterMode `NONE` und `JSON_PAYLOAD`
- deklarativer JSON-Objektvertrag
- idempotente Wiederholungsregistrierung
- kontrolliertes Update mit `@AllowUpdate`
- Optimistic Concurrency über `rowversion`
- Disable, idempotentes Disable und explizite Reaktivierung
- Removal nur nach Disable und mit `@AllowDelete = 1`
- Removal mit optionaler `rowversion`-Prüfung gegen konkurrierende Änderungen
- Remove-Savepoint innerhalb einer Caller-Transaktion und Wiederherstellung durch Caller-Rollback
- Ablehnung der Removal-Mutation bei `XACT_STATE() = -1`
- direkte Ausgabe und ResultTable Replace/Append beziehungsweise Remove-Ausgabe
- vier parallele Registrierungen desselben Work Types
- Redeploy erhält persistente Katalogdaten
- lokales und zentrales Deployment
- Uninstall verweigert stillen Datenverlust
- Windows und physische SQL-Server-2019-/2022-Läufe bleiben `not executed`

## Ausgeführte Evidenz

- Basisvertrag Version `1.0.0`: SQL Server 2025 Linux, Compatibility Levels 150, 160 und 170 erfolgreich.
- Basis-Workflow: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30703339193
- Removal-Version `1.1.0`: SQL Server 2025 Linux CL150/160/170 erfolgreich; Evidenz https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31016136937
- Windows und physische SQL-Server-2019-/2022-Läufe: `not executed`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-08-29`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Lokales SQL_Server_Lab; physische SQL-Server-2019-, 2022- und 2025-Linux-Ziele; vollständiger W4-Moduladapter
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
