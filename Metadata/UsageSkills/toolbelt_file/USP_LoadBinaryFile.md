---
name: "toolbelt-toolbelt-toolbelt-file-usp-loadbinaryfile"
description: "Liest eine Datei als varbinary(max) über OPENROWSET(BULK...). Der Pfad muss unter einem Eintrag der Root-Allowlist liegen."
skill_format_version: "1.0"
module_id: "toolbelt.file.content"
schema_name: "toolbelt_file"
object_name: "USP_LoadBinaryFile"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@FilePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Absoluter Dateipfad als einzelner Textwert, Windows-Laufwerk/UNC oder Unix-/Pfad; normale Randspaces werden getrimmt, leer/NULL (technischer Help-Default) ungültig. Muss literal und case-sensitiv an einer Verzeichnisgrenze unter einem aktiven FileContentRootAllowlist-Root liegen; Traversal nach außen abgewiesen. Kein RootAlias und keine SQL-Fragmente/Wildcardfreigabe. Aktuelle Implementierungsgrenze: das BULK-Pfadliteral wird mit QUOTENAME erzeugt, das über 128 Zeichen NULL liefert; die nvarchar(4000)-Signatur belegt daher keine Unterstützung längerer Pfade. Betriebssystem-/BULK-Rechte bleiben erforderlich; keine handlegebundene Sandbox."}, {"name": "@MaxBytes", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler bigint-Bytegrenzwert: NULL (Default) oder 0 deaktiviert die eigene Größenprüfung; positiv 1..9223372036854775807 begrenzt die gelesenen Rohbytes. Prüfung erfolgt nach vollständigem SINGLE_BLOB-Lesen, kein I/O-/Speicher-Vorabcap. Negative Werte werden aktuell nicht als Argumentfehler validiert, sondern führen bei tatsächlich gelesenen nicht negativen Bytegrößen zur Überschreitungszeile 51323; für gültige Aufrufe NULL/0/positive Werte verwenden."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Das Ziel wird vor Datei-I/O vorbereitet; Provider-/Decoderfehler rollen den eigenen SQL-Ausgabescope zurück."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene Dateiinhaltsdiagnose; ausschließlich im ResultTable-Pfad an den kanonischen Helper weitergereicht."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.file.content/Source/USP_LoadBinaryFile.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# USP_LoadBinaryFile

## Zweck und Einsatzfälle

Liest eine Datei als varbinary(max) über OPENROWSET(BULK...). Der Pfad muss unter einem Eintrag der Root-Allowlist liegen.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Vorhandene Datei unter einem konfigurierten Allowlist-Root und passende SQL-/Dateirechte.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@FilePath` | `nvarchar(4000)` | `NULL` | Input | Absoluter Dateipfad als einzelner Textwert, Windows-Laufwerk/UNC oder Unix-/Pfad; normale Randspaces werden getrimmt, leer/NULL (technischer Help-Default) ungültig. Muss literal und case-sensitiv an einer Verzeichnisgrenze unter einem aktiven FileContentRootAllowlist-Root liegen; Traversal nach außen abgewiesen. Kein RootAlias und keine SQL-Fragmente/Wildcardfreigabe. Aktuelle Implementierungsgrenze: das BULK-Pfadliteral wird mit QUOTENAME erzeugt, das über 128 Zeichen NULL liefert; die nvarchar(4000)-Signatur belegt daher keine Unterstützung längerer Pfade. Betriebssystem-/BULK-Rechte bleiben erforderlich; keine handlegebundene Sandbox. |
| `@MaxBytes` | `bigint` | `NULL` | Input | Optionaler bigint-Bytegrenzwert: NULL (Default) oder 0 deaktiviert die eigene Größenprüfung; positiv 1..9223372036854775807 begrenzt die gelesenen Rohbytes. Prüfung erfolgt nach vollständigem SINGLE_BLOB-Lesen, kein I/O-/Speicher-Vorabcap. Negative Werte werden aktuell nicht als Argumentfehler validiert, sondern führen bei tatsächlich gelesenen nicht negativen Bytegrößen zur Überschreitungszeile 51323; für gültige Aufrufe NULL/0/positive Werte verwenden. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Das Ziel wird vor Datei-I/O vorbereitet; Provider-/Decoderfehler rollen den eigenen SQL-Ausgabescope zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene Dateiinhaltsdiagnose; ausschließlich im ResultTable-Pfad an den kanonischen Helper weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

Der binäre Dateiinhalt. Bei Validierungsfehlern NULL.

Anzahl gelesener Bytes. Bei Validierungsfehlern vor dem Lesen 0.

1, wenn der Inhalt erfolgreich gelesen wurde; 0 bei fachlichem Fehler.

Fachlicher Fehlercode oder NULL bei Erfolg.

Fachliche Fehlermeldung oder NULL bei Erfolg.

## Aufrufbeispiele

```sql
-- Voraussetzung: passende Allowlist und eigene synthetische Datei.
EXEC toolbelt_file.USP_LoadBinaryFile @FilePath=N'C:\ExampleRoot\sample.bin', @MaxBytes=1048576;
```

## Rechte

Erforderlich ist EXECUTE auf toolbelt_file.USP_LoadBinaryFile, Lesezugriff auf den Dateipfad sowie ADMINISTER BULK OPERATIONS oder ad hoc distributed queries für OPENROWSET(BULK...). Für @ResultTable zusätzlich EXECUTE auf toolbelt_core.USP_PrepareResultTable.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Ungültiger oder leerer Dateipfad.

Pfad liegt außerhalb der konfigurierten Root-Allowlist.

Pfad enthält verbotene relative Segmente oder Traversal.

Datei überschreitet @MaxBytes.

## Aussagegrenzen

Dateigröße ist durch varbinary(max) auf ca. 2 GB begrenzt. OPENROWSET(BULK...) liest die gesamte Datei; @MaxBytes prüft erst nach dem Lesen. ResultTable-Änderung und Datei-I/O liegen in derselben Transaktion.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.file.content/Documentation/USP_LoadBinaryFile.md`

Keine Installations-, Definitions- oder Rechteattestation.
