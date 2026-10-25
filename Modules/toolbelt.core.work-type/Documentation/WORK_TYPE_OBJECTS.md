# Öffentliche Work-Type-Objekte

## Direkte Callerrechte

Registrierung, Disable, Remove und Resolve benötigen EXECUTE auf ihre jeweilige
Procedure; die View benötigt SELECT. Registrierung verlangt zusätzlich
Handler-EXECUTE, Resolve mit unverändertem `RequireExecutableByCaller=1`
ebenfalls. Metadatensicht allein ersetzt dieses Recht nicht.
`USP_SetWorkTypePermission` benötigt EXECUTE und CONTROL auf
`toolbelt_core.WorkTypePermission`; ihre
[Detailseite](USP_SetWorkTypePermission.md) erklärt den administrativen Vertrag.
Der [abgegrenzte Rechtebeleg](../../../Releases/1.0.0/WORK-TYPE-RIGHTS-QUALIFICATION.md)
zeigt diese Profile mit Benutzern ohne Login. Direkte Rechte auf den internen
WorkType-Katalog gehören nicht zur normalen API-Nutzung.

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

## Resolver-Policy 1.2.0

USP_ResolveWorkType ergänzt vor den Standardparametern RequiredPermission
varchar(32)=NULL und SuppressResult bit=0. Die bisherigen benannten Aufrufe
behalten ihre Defaults; positionale Aufrufe müssen auf benannte Parameter
migriert werden. RequiredPermission prüft vor Metadatenausgabe dieselbe
Policy; ein fehlendes Allow ergibt 51596, ungültige Aktion 51595.
SuppressResult=1 liefert nach erfolgreicher Prüfung kein Fachresultset und
ist mit ResultTable unvereinbar (51597). Der Worker nutzt diesen Pfad direkt
vor Handlerausführung und benötigt dafür keine internen SELECT-Rechte.
In einer Callertransaktion hält die Policyprüfung die Work-Type-Zeile bis
zum Abschluss stabil. Help ignoriert beide neuen Argumente.
