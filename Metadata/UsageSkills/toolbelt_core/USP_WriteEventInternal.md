---
name: "toolbelt-event-log-internal-write"
description: "Interner JSON-Handler für den registrierten Second-Session-Eventschreibpfad."
skill_format_version: "1.0"
module_id: "toolbelt.core.event-log"
schema_name: "toolbelt_core"
object_name: "USP_WriteEventInternal"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@PayloadJson", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vertrauenswürdige gebundene JSON-Objektpayload der Fassade, nicht ein DTSX/XML-/Dateipfad oder beliebiger SQL-Text. Höchstens 131072 UTF-16-Bytes. NULL/leer/ungültig oder nach LTRIM normaler Spaces kein { ergibt 51720. Feldvertrag siehe Voraussetzungen; ID/Actor/Tenant stammen aus dem aktiven Remote-Kontext, nicht aus JSON. Technischer Default NULL dient Hilfe."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende Hilfe plus genau eine vollständige Skillzeile vor Payload-/Kontextprüfung/INSERT; 0 oder NULL: interner Fachpfad. Kein generischer öffentlicher Schreibzugriff."}]
source_paths: ["Modules/toolbelt.core.event-log/Source/USP_WriteEventInternal.sql", "Modules/toolbelt.core.event-log/Source/EventLog.sql"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_core.USP_WriteEvent"]
---

# USP_WriteEventInternal

## Zweck und Einsatzfälle

Schreibt genau einen validierten gebundenen Eventdatensatz in der aktuellen Handlersession; regulärer Consumer-Einstieg ausschließlich USP_WriteEvent.

## Voraussetzungen

SQL Server 2019/2022/2025 Windows/Linux, passende CL150/160/170, lokal/zentral. EventLog und execution-context installiert. Payloadfelder: eventName, eventLevel, category, message, data (JSON-Objekt oder NULL), occurredAtUtc (Stil127), sourceDatabaseName, sourceSchemaName, sourceObjectName, callerSessionId, callerXactState, callerTransactionCount sowie errorNumber/errorSeverity/errorState/errorProcedure/errorLine. Pflichtdaten: Name, Ereigniszeit, Quell-DB, Caller-SPID/-XactState/-TranCount und aktiver Kontext mit ExecutionId/CorrelationId. Actor/Tenant und IDs werden ausschließlich aus TVF_CurrentExecutionContext gelesen. JSON_VALUE/TRY_CONVERT/gebundene Ziellängen bilden den internen Transport; das ist kein vollständiger verlustfreier Validator beliebiger Fremdpayloads: lange/fehlende/unpassende Felder können konvertiert, gekürzt, zu NULL oder zu Tabellen-/Enginefehlern werden. Öffentliche Fassade für fachliche Eingaben nutzen.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | Vertrauenswürdige gebundene JSON-Objektpayload der Fassade, nicht ein DTSX/XML-/Dateipfad oder beliebiger SQL-Text. Höchstens 131072 UTF-16-Bytes. NULL/leer/ungültig oder nach LTRIM normaler Spaces kein { ergibt 51720. Feldvertrag siehe Voraussetzungen; ID/Actor/Tenant stammen aus dem aktiven Remote-Kontext, nicht aus JSON. Technischer Default NULL dient Hilfe. |
| `@Hilfe` | `bit` | `0` | Input | 1: bestehende Hilfe plus genau eine vollständige Skillzeile vor Payload-/Kontextprüfung/INSERT; 0 oder NULL: interner Fachpfad. Kein generischer öffentlicher Schreibzugriff. |

## Ergebnisse

Kein fachlicher oder infrastruktureller SELECT-Resultset und keine OUTPUT-Parameter; RETURN 0 bei Erfolg. @Hilfe=1 liefert zuerst die bestehende zwölfspaltige Standardhilfe und dann genau eine zusätzliche Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max). Anschließend RETURN 0 vor Fachvalidierung, Katalog-/Tabellenzugriff und Schreib-/Lösch-/Transportoperationen. SQL-Typbindung und die vor dem Hilfezweig ausdrücklich beschriebenen lokalen Initialisierungen bleiben wirksam. Der interne Handler startet/committet keine eigene Transaktion. Direkter Return 0 beweist nur erfolgreiches INSERT im aktuellen Scope; der Dispatcher verantwortet dessen Commit.

## Aufrufbeispiele

```sql
-- Interner Fachaufruf nur durch registrierten Dispatcher.
EXEC toolbelt_core.USP_WriteEvent @EventName='contoso.example',@EventLevel='INFO',@Message=N'Synthetic event',@DataJson=N'{"rows":1}';
-- Persistiert über den zuvor autorisierten/konfigurierten Provider.
EXEC toolbelt_core.USP_WriteEventInternal @Hilfe=1;
```

## Rechte

Nur vorhandene administrative Dispatch-/Handlerrechte im ausgewählten internen Pfad und gültige Objekt-/Ownershiprechte auf Kontextfunktion und EventLog. Kein empfohlener direkter Consumergrant auf diesen internen Kern. Keine neuen Rollen/Grants, kein automatisches Abschalten von Sicherheitsregeln. Quellnamen, Actor/Tenant und Context IDs verleihen keine Rechte.

## Ressourcenbedarf

Payload hart maximal 131072 UTF-16-Bytes, eingebettetes data maximal 65536 Bytes und Objektroot. JSON_VALUE-skalarer Feldzugriff ist kein nvarchar(max)-Textimport; Message-Ziel nvarchar(4000). Persistente Tabellen-/Indexkosten ohne globale Zeilenquote oder automatische Retention. Keine eigene Transport-Wartezeitregel im Handler.

## Nebenwirkungen

SET NOCOUNT ON und XACT_ABORT ON, keine eigene BEGIN/COMMIT/CATCH-Transaktion. INSERT nutzt aktuelle Transaktion; RecordedAtUtc vom Tabellendefault, RemoteSessionId=@@SPID. Die öffentlichen Auditfelder werden aus Payload und Remote-Kontext zusammengeführt. Keine Dispatch- oder Second-Session-Erzeugung durch direkten Handleraufruf. Gespeicherte Message/DataJson und Auditwerte werden nicht automatisch redigiert; keine Secrets oder vertraulichen Inhalte übergeben.

## Fehlerbehandlung

51720 Payload fehlt/zu groß/kein Objekt; 51721 unvollständige Pflichtdaten/Kontext; 51722 ungültiger Level; 51723 data zu groß/kein Objekt; 51724 Severity,51725 State,51726 positive ErrorLine. SQL-NULL-Dreierlogik bedeutet bei einzelnen fehlenden Feldern keinen garantierten 51721/51722: NOT-NULL/CHECK-/Konvertierungsfehler der Tabelle bleiben möglich. Nichtstring-/überlange JSON_VALUE-Felder sind kein freigegebener generischer Eingabeweg. Kein Catch oder pauschales Mapping technischer Fehler.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Skill-/Installer-/Minimalrechte-/Transportabnahme. Historische Belege bleiben an ihre ursprünglichen Bytes und ihren Scope gebunden. Kontext-, Actor-, Tenant- und Quellnamen sind callerbeeinflussbare Auditmetadaten, keine Authentifizierung oder Tenant-Isolation. Keine Installations- oder Rechteattestation; Beispiele ausschließlich in einem autorisierten synthetischen Scope ausführen.
