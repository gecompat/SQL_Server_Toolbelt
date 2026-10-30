# toolbelt_core.USP_RegisterWorkType

## Zweck

Registriert ausschließlich eine vorhandene Stored Procedure als benannten Work Type. SQL-Text wird weder angenommen noch gespeichert.

## Verhalten und Ergebnis

Registriert eine vorhandene Stored Procedure. Exakte Wiederholungen sind idempotent. Abweichende Konfigurationen benötigen `@AllowUpdate = 1`; deaktivierte Einträge benötigen zusätzlich `@Reactivate = 1`. `@ExpectedRowVersion` ermöglicht Optimistic Concurrency.

`ParameterMode` ist auf `NONE` und `JSON_PAYLOAD` begrenzt. `PayloadContractJson` ist deklarative Metadaten und wird nicht als SQL ausgeführt.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [WORK_TYPE_OBJECTS](WORK_TYPE_OBJECTS.md).

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer kleingeschriebener Work-Type-Name. |
| `@HandlerSchema` | `sysname` | `NULL` | Input | Schema der vorhandenen Zielprocedure in derselben Datenbank. |
| `@HandlerProcedure` | `sysname` | `NULL` | Input | Name der vorhandenen Zielprocedure. |
| `@ParameterMode` | `varchar(16)` | `'NONE'` | Input | NONE oder JSON_PAYLOAD. |
| `@PayloadContractJson` | `nvarchar(4000)` | `NULL` | Input | JSON-Objekt mit deklarativem Payloadvertrag; wird nicht als Code ausgeführt. |
| `@DefaultTimeoutSeconds` | `int` | `300` | Input | Standardtimeout des registrierten Work Types. |
| `@IsIdempotent` | `bit` | `0` | Input | Deklarative Handlerkennzeichnung; ersetzt keine fachliche Idempotenzimplementierung. |
| `@Description` | `nvarchar(1000)` | `NULL` | Input | Beschreibung des registrierten Work Types. |
| `@AllowUpdate` | `bit` | `0` | Input | Erlaubt eine Änderung einer vorhandenen Registrierung. |
| `@Reactivate` | `bit` | `0` | Input | Reaktiviert einen deaktivierten Work Type. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionale Optimistic-Concurrency-Prüfung. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale lokale Temp-Tabelle für die Ergebniszeile. |
| `@KeepData` | `bit` | `0` | Input | 0 = Ergebnis ersetzen, 1 = an vorhandene kompatible Ergebnisdaten anhängen. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

## Voraussetzungen für den Aufruf

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='demo.noop', @HandlerSchema=N'dbo', @HandlerProcedure=N'USP_DemoNoop';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_RegisterWorkType @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_RegisterWorkType.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
