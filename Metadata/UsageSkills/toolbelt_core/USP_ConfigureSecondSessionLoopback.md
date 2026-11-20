---
name: "toolbelt-toolbelt-toolbelt-core-usp-configuresecondsess-1d3283c6"
description: "Verknüpft das Modul mit einem bereits administrativ eingerichteten Loopback-Linked-Server. Das Modul legt weder Linked Server noch Login-Mappings oder Credentials an."
skill_format_version: "1.0"
module_id: "toolbelt.core.second-session"
schema_name: "toolbelt_core"
object_name: "USP_ConfigureSecondSessionLoopback"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@LinkedServerName", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher vorhandener Loopback-Linked-Server-Name als sysname, kein Connection String. Binärer Namensvergleich; rpc out muss an und remote proc transaction promotion aus sein. Der Probe muss dieselbe Datenbank mit anderer SPID erreichen, auch wenn Enabled=0 gesetzt wird. NULL/leer ist nur im Hilfemodus zulässig; die Procedure legt keine Infrastruktur an."}, {"name": "@Enabled", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 aktiviert die gespeicherte Loopbackkonfiguration (Default und NULL); 0 deaktiviert sie. Vorbedingungen und Probe gelten in beiden Fällen; 0 ist kein Bypass für einen fehlenden/ungeeigneten Linked Server."}, {"name": "@ExpectedRowVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Der Vergleich erfolgt nur, wenn eine Konfigurationszeile bereits existiert; er verhindert keine Erstregistrierung mit angegebenem Wert."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.core.second-session/Source/USP_ConfigureSecondSessionLoopback.sql"]
review_status: "draft"
source_module_version: "1.1.0"
---

# USP_ConfigureSecondSessionLoopback

## Zweck und Einsatzfälle

Verknüpft das Modul mit einem bereits administrativ eingerichteten Loopback-Linked-Server. Das Modul legt weder Linked Server noch Login-Mappings oder Credentials an.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Für Second-Session-Ausführung und rollback-unabhängiges Schreiben: administrativ angelegter Loopback-Linked-Server und konfigurierter Provider. Löschen von Events verändert persistente Daten.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LinkedServerName` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener Loopback-Linked-Server-Name als sysname, kein Connection String. Binärer Namensvergleich; rpc out muss an und remote proc transaction promotion aus sein. Der Probe muss dieselbe Datenbank mit anderer SPID erreichen, auch wenn Enabled=0 gesetzt wird. NULL/leer ist nur im Hilfemodus zulässig; die Procedure legt keine Infrastruktur an. |
| `@Enabled` | `bit` | `1` | Input | Taxativ für bit: 1 aktiviert die gespeicherte Loopbackkonfiguration (Default und NULL); 0 deaktiviert sie. Vorbedingungen und Probe gelten in beiden Fällen; 0 ist kein Bypass für einen fehlenden/ungeeigneten Linked Server. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Der Vergleich erfolgt nur, wenn eine Konfigurationszeile bereits existiert; er verhindert keine Erstregistrierung mit angegebenem Wert. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

ProviderName: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

LinkedServerName: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

IsEnabled: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

RowVersion: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

LinkedServerExists: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

RpcOutEnabled: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

RemoteProcTransactionPromotionEnabled: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

ProbeRemoteSessionId: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

ProbeDatabaseName: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @LinkedServerName=N'TBX_LOOPBACK';
```

## Rechte

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Konfigurations-, Probe-, Concurrency- und ResultTable-Fehler.

## Aussagegrenzen

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.core.second-session/Documentation/USP_ConfigureSecondSessionLoopback.md`

Keine Installations-, Definitions- oder Rechteattestation.
