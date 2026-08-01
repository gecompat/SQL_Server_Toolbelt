# Work-Type-Contract-Testmatrix

- kanonischer Work-Type-Name und Ablehnung von SQL-Text-/Identifier-Missbrauch
- vorhandene Stored Procedure als einzig zulässiger Handlertyp
- Caller-`EXECUTE` bei Registrierung und optional bei Resolve
- ParameterMode `NONE` und `JSON_PAYLOAD`
- deklarativer JSON-Objektvertrag
- idempotente Wiederholungsregistrierung
- kontrolliertes Update mit `@AllowUpdate`
- Optimistic Concurrency über `rowversion`
- Disable, idempotentes Disable und explizite Reaktivierung
- direkte Ausgabe und ResultTable Replace/Append
- vier parallele Registrierungen desselben Work Types
- Redeploy erhält persistente Katalogdaten
- lokales und zentrales Deployment
- Uninstall verweigert stillen Datenverlust
- Windows und physische SQL-Server-2019-/2022-Läufe bleiben `not executed`

## Ausgeführte Evidenz

- SQL Server 2025 Linux, Compatibility Levels 150, 160 und 170: erfolgreich.
- Workflow: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30703294213
- Windows und physische SQL-Server-2019-/2022-Läufe: `not executed`.
