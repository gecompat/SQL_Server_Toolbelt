# toolbelt_core.USP_WriteEvent

## Zweck

Schreibt ein strukturiertes Event synchron über toolbelt.core.second-session. Der Remote-Commit ist unabhängig von Commit oder Rollback der Caller-Transaktion.

## Verhalten und Ergebnis

Schreibt genau ein Event über den konfigurierten Second-Session-Provider. Die Procedure gibt kein fachliches oder infrastrukturelles Resultset aus. ExecutionId, CorrelationId, Actor und Tenant werden aus expliziten Parametern oder dem aktiven Execution Context übernommen.

Die Procedure kann in einer regulären, zurückgerollten oder uncommittable Caller-Transaktion verwendet werden. Ein erfolgreicher Returncode bedeutet, dass der Remote-Handler synchron erfolgreich committed hat. Provider- oder Handlerfehler werden an den Caller weitergegeben.

Der interne `USP_WriteEventInternal`-Kern hat einen Help-Aufruf für seine
gebundene JSON-Payload und den fehlenden fachlichen Resultset-Vertrag. Direkte
Aufrufe bleiben auf die vorgesehene Event-Log-Fassade beschränkt; Hilfe
validiert oder speichert keine Payload.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [EVENT_LOG_OBJECTS](EVENT_LOG_OBJECTS.md).

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@EventName` | `varchar(128)` | `NULL` | Input | Kanonischer Eventname in lowercase ASCII. |
| `@EventLevel` | `varchar(16)` | `'INFO'` | Input | TRACE, DEBUG, INFO, WARNING, ERROR oder CRITICAL. |
| `@Category` | `varchar(128)` | `NULL` | Input | Optionale Eventkategorie. |
| `@Message` | `nvarchar(4000)` | `NULL` | Input | Begrenzte menschenlesbare Meldung; keine ungeprüften Secrets persistieren. |
| `@DataJson` | `nvarchar(max)` | `NULL` | Input | Begrenztes JSON-Objekt bis 32 KiB UTF-16-Speicher. |
| `@OccurredAtUtc` | `datetime2(7)` | `NULL` | Input | Fachlicher Ereigniszeitpunkt in UTC. |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | Execution-ID; NULL-Verhalten hängt vom konkreten Objektvertrag ab. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | Korrelations-ID für zusammengehörige Ausführungen/Events. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Actor-Kennung des Ausführungskontexts. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Tenant-Kennung des Ausführungskontexts. |
| `@SourceDatabaseName` | `sysname` | `NULL` | Input | Optionale Datenbankkennzeichnung des Events. |
| `@SourceSchemaName` | `sysname` | `NULL` | Input | Optionale Schemakennzeichnung des Events. |
| `@SourceObjectName` | `sysname` | `NULL` | Input | Optionale Objektkennzeichnung des Events. |
| `@ErrorNumber` | `int` | `NULL` | Input | Nummer des ursprünglichen SQL-Fehlers. |
| `@ErrorSeverity` | `int` | `NULL` | Input | Severity des ursprünglichen SQL-Fehlers. |
| `@ErrorState` | `int` | `NULL` | Input | State des ursprünglichen SQL-Fehlers. |
| `@ErrorProcedure` | `sysname` | `NULL` | Input | Procedure des ursprünglichen SQL-Fehlers. |
| `@ErrorLine` | `int` | `NULL` | Input | Zeilennummer des ursprünglichen SQL-Fehlers. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

## Voraussetzungen für den Aufruf

- Für Second-Session-Ausführung und rollback-unabhängiges Schreiben: administrativ angelegter Loopback-Linked-Server und konfigurierter Provider. Löschen von Events verändert persistente Daten.

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_WriteEvent @EventName='demo.completed', @Message=N'Synthetic example';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_WriteEvent @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#zweite-session).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_WriteEvent.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
