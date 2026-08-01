# Öffentliche Work-Type-Objekte

## `VW_WorkTypes`

Read-only-Sicht auf registrierte Work Types. `HandlerExists` zeigt, ob die Zielprocedure aktuell vorhanden ist. Die View ist kein Ausführungsprovider.

## `USP_RegisterWorkType`

Registriert eine vorhandene Stored Procedure. Exakte Wiederholungen sind idempotent. Abweichende Konfigurationen benötigen `@AllowUpdate = 1`; deaktivierte Einträge benötigen zusätzlich `@Reactivate = 1`. `@ExpectedRowVersion` ermöglicht Optimistic Concurrency.

`ParameterMode` ist auf `NONE` und `JSON_PAYLOAD` begrenzt. `PayloadContractJson` ist deklarative Metadaten und wird nicht als SQL ausgeführt.

## `USP_DisableWorkType`

Deaktiviert einen Work Type, erhält aber die registrierte Konfiguration. Ein optionaler Grund wird gespeichert. Wiederholtes Disable ist idempotent.

## `USP_ResolveWorkType`

Löst genau einen Work Type auf. Standardmäßig müssen der Eintrag enabled, die Zielprocedure vorhanden und für den aktuellen Principal ausführbar sein.
