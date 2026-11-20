---
name: "toolbelt-toolbelt-toolbelt-core-usp-registerworktype"
description: "Registriert ausschließlich eine vorhandene Stored Procedure als benannten Work Type. SQL-Text wird weder angenommen noch gespeichert."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-type"
schema_name: "toolbelt_core"
object_name: "USP_RegisterWorkType"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkTypeName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Erforderlicher kanonischer varchar(128)-Schlüssel: LEN 3..128, beginnt a-z, danach ausschließlich a-z/0-9/Punkt/Unterstrich/Bindestrich. Lowercase wird verlangt, nicht hergestellt; keine abschließenden oder doppelten Punkte. Z.B. app.import.rows. NULL/leer ungültig; bestehende Registrierung folgt AllowUpdate/Reactivate/RowVersion."}, {"name": "@HandlerSchema", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Einzelner unquotierter Schemaname als sysname in der aktuellen Datenbank, nicht mehrteilig und kein SQL-Ausdruck. NULL/leer oder Schema sys ist unzulässig. Mit HandlerProcedure muss eine vorhandene, nicht von Microsoft ausgelieferte T-SQL- oder CLR-Procedure entstehen; Caller benötigt EXECUTE."}, {"name": "@HandlerProcedure", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Einzelner unquotierter Procedurename als sysname in HandlerSchema; keine Argumentliste oder Datenbankqualifikation. NULL/leer/fehlende Procedure bzw. fehlende Metadatensicht/EXECUTE wird abgewiesen. Registrierung führt den Handler nicht aus; der Dispatcher prüft den zum ParameterMode gehörenden Aufrufvertrag."}, {"name": "@ParameterMode", "sql_type": "varchar(16)", "sql_default": "'NONE'", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ nach UPPER-Normalisierung: NONE = Handleraufruf ohne Payload, PayloadContractJson muss NULL sein (Default und NULL); JSON_PAYLOAD = JSON-Payload-Modus, PayloadContractJson muss ein JSON-Objekt sein. Keine weiteren Modi; SQL-Space-Padding gilt beim Vergleich."}, {"name": "@PayloadContractJson", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Bei NONE ausschließlich NULL. Bei JSON_PAYLOAD erforderlicher JSON-Objekttext als nvarchar(4000), z.B. N'{\"description\":\"synthetic payload\"}'; nach LTRIM normaler Spaces muss { folgen. Leer/Array/Scalar/ungültiges JSON ist ungültig. Die Felder sind deklarative Metadaten; diese Procedure führt weder SQL noch eine allgemeine JSON-Schema-Validierung daraus aus."}, {"name": "@DefaultTimeoutSeconds", "sql_type": "int", "sql_default": "300", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Ganzzahl 1..86400 Sekunden einschließlich; Default/NULL=300. Wird als Work-Type-Metadatum gespeichert, nicht als Garantie eines autonomen harten Serverabbruchs. Andere Werte ungültig."}, {"name": "@IsIdempotent", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 = Handler nicht als idempotent gekennzeichnet (Default/NULL); 1 = deklarativ idempotent gekennzeichnet. Das Flag implementiert selbst keine Idempotenz oder Exactly-once-Ausführung."}, {"name": "@Description", "sql_type": "nvarchar(1000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Freitext nvarchar(1000), NULL/leer erlaubt; keine besonderen Felder, keine Ausführung, keine automatische Redigierung."}, {"name": "@AllowUpdate", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 weist eine abweichende vorhandene Konfiguration ab (Default/NULL); 1 erlaubt deren Update. Ein identischer aktiver Eintrag bleibt auch mit 0 idempotent. Für die Reaktivierung eines deaktivierten Eintrags zusätzlich Reactivate beachten."}, {"name": "@Reactivate", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 lässt eine deaktivierte Registrierung nicht still reaktivieren (Default/NULL); 1 erlaubt ihre Reaktivierung. Bei gleichzeitig abweichender Konfiguration ist außerdem AllowUpdate=1 erforderlich."}, {"name": "@ExpectedRowVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Wird nur gegen einen vorhandenen Work Type geprüft; kein Eingabewert für die neue RowVersion."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.core.work-type/Source/USP_RegisterWorkType.sql"]
review_status: "draft"
source_module_version: "1.2.0"
---

# USP_RegisterWorkType

## Zweck und Einsatzfälle

Registriert ausschließlich eine vorhandene Stored Procedure als benannten Work Type. SQL-Text wird weder angenommen noch gespeichert.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Erforderlicher kanonischer varchar(128)-Schlüssel: LEN 3..128, beginnt a-z, danach ausschließlich a-z/0-9/Punkt/Unterstrich/Bindestrich. Lowercase wird verlangt, nicht hergestellt; keine abschließenden oder doppelten Punkte. Z.B. app.import.rows. NULL/leer ungültig; bestehende Registrierung folgt AllowUpdate/Reactivate/RowVersion. |
| `@HandlerSchema` | `sysname` | `NULL` | Input | Einzelner unquotierter Schemaname als sysname in der aktuellen Datenbank, nicht mehrteilig und kein SQL-Ausdruck. NULL/leer oder Schema sys ist unzulässig. Mit HandlerProcedure muss eine vorhandene, nicht von Microsoft ausgelieferte T-SQL- oder CLR-Procedure entstehen; Caller benötigt EXECUTE. |
| `@HandlerProcedure` | `sysname` | `NULL` | Input | Einzelner unquotierter Procedurename als sysname in HandlerSchema; keine Argumentliste oder Datenbankqualifikation. NULL/leer/fehlende Procedure bzw. fehlende Metadatensicht/EXECUTE wird abgewiesen. Registrierung führt den Handler nicht aus; der Dispatcher prüft den zum ParameterMode gehörenden Aufrufvertrag. |
| `@ParameterMode` | `varchar(16)` | `'NONE'` | Input | Taxativ nach UPPER-Normalisierung: NONE = Handleraufruf ohne Payload, PayloadContractJson muss NULL sein (Default und NULL); JSON_PAYLOAD = JSON-Payload-Modus, PayloadContractJson muss ein JSON-Objekt sein. Keine weiteren Modi; SQL-Space-Padding gilt beim Vergleich. |
| `@PayloadContractJson` | `nvarchar(4000)` | `NULL` | Input | Bei NONE ausschließlich NULL. Bei JSON_PAYLOAD erforderlicher JSON-Objekttext als nvarchar(4000), z.B. N'{"description":"synthetic payload"}'; nach LTRIM normaler Spaces muss { folgen. Leer/Array/Scalar/ungültiges JSON ist ungültig. Die Felder sind deklarative Metadaten; diese Procedure führt weder SQL noch eine allgemeine JSON-Schema-Validierung daraus aus. |
| `@DefaultTimeoutSeconds` | `int` | `300` | Input | Ganzzahl 1..86400 Sekunden einschließlich; Default/NULL=300. Wird als Work-Type-Metadatum gespeichert, nicht als Garantie eines autonomen harten Serverabbruchs. Andere Werte ungültig. |
| `@IsIdempotent` | `bit` | `0` | Input | Taxativ für bit: 0 = Handler nicht als idempotent gekennzeichnet (Default/NULL); 1 = deklarativ idempotent gekennzeichnet. Das Flag implementiert selbst keine Idempotenz oder Exactly-once-Ausführung. |
| `@Description` | `nvarchar(1000)` | `NULL` | Input | Optionaler Unicode-Freitext nvarchar(1000), NULL/leer erlaubt; keine besonderen Felder, keine Ausführung, keine automatische Redigierung. |
| `@AllowUpdate` | `bit` | `0` | Input | Taxativ für bit: 0 weist eine abweichende vorhandene Konfiguration ab (Default/NULL); 1 erlaubt deren Update. Ein identischer aktiver Eintrag bleibt auch mit 0 idempotent. Für die Reaktivierung eines deaktivierten Eintrags zusätzlich Reactivate beachten. |
| `@Reactivate` | `bit` | `0` | Input | Taxativ für bit: 0 lässt eine deaktivierte Registrierung nicht still reaktivieren (Default/NULL); 1 erlaubt ihre Reaktivierung. Bei gleichzeitig abweichender Konfiguration ist außerdem AllowUpdate=1 erforderlich. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Wird nur gegen einen vorhandenen Work Type geprüft; kein Eingabewert für die neue RowVersion. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

WorkTypeId.

WorkTypeName.

HandlerSchema.

HandlerProcedure.

HandlerQualifiedName.

ParameterMode.

PayloadContractJson.

DefaultTimeoutSeconds.

IsIdempotent.

IsEnabled.

Description.

CreatedAtUtc.

CreatedBy.

ModifiedAtUtc.

ModifiedBy.

DisabledAtUtc.

DisabledBy.

DisabledReason.

RowVersion.

HandlerExists.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='demo.noop', @HandlerSchema=N'dbo', @HandlerProcedure=N'USP_DemoNoop';
```

## Rechte

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Validierungs-, Berechtigungs-, Concurrency- und Dependencyfehler.

## Aussagegrenzen

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.core.work-type/Documentation/USP_RegisterWorkType.md`

Keine Installations-, Definitions- oder Rechteattestation.
