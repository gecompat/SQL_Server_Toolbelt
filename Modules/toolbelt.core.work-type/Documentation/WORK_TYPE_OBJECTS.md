# Öffentliche Work-Type-Objekte

## `VW_WorkTypes`

Read-only-Sicht auf registrierte Work Types. `HandlerExists` zeigt, ob die Zielprocedure aktuell vorhanden ist. Die View ist kein Ausführungsprovider.

## `USP_RegisterWorkType`

Registriert eine vorhandene Stored Procedure. Exakte Wiederholungen sind idempotent. Abweichende Konfigurationen benötigen `@AllowUpdate = 1`; deaktivierte Einträge benötigen zusätzlich `@Reactivate = 1`. `@ExpectedRowVersion` ermöglicht Optimistic Concurrency.

`ParameterMode` ist auf `NONE` und `JSON_PAYLOAD` begrenzt. `PayloadContractJson` ist deklarative Metadaten und wird nicht als SQL ausgeführt.

## `USP_DisableWorkType`

Deaktiviert einen Work Type, erhält aber die registrierte Konfiguration. Ein optionaler Grund wird gespeichert. Wiederholtes Disable ist idempotent.

## `USP_RemoveWorkType`

Entfernt genau einen bereits deaktivierten Work Type. Der irreversible Vorgang benötigt ausdrücklich `@AllowDelete = 1`; ein aktiver Eintrag wird mit Fehler `51526` abgelehnt. `@ExpectedRowVersion` schützt vor Lost Updates beziehungsweise dem Löschen einer inzwischen geänderten Registrierung.

Die Procedure verwendet bei vorhandener Caller-Transaktion einen Modul-Savepoint. Ein Fehler rollt nur die eigenen Änderungen zurück. Bei `XACT_STATE() = -1` ist eine Entfernung nicht möglich und wird vor der ersten Mutation abgelehnt. Die entfernte Katalogzeile wird direkt oder über `@ResultTable` zurückgegeben.

## `USP_ResolveWorkType`

Löst genau einen Work Type auf. Standardmäßig müssen der Eintrag enabled, die Zielprocedure vorhanden und für den aktuellen Principal ausführbar sein.
