---
name: "toolbelt-fs-clr-read-binary-file-chunk"
description: "Interner Windows-CLR-Provider zum begrenzten Lesen eines binären Dateichunks."
skill_format_version: "1.0"
module_id: "toolbelt.filesystem.windows"
schema_name: "toolbelt_filesystem"
object_name: "CLR_ReadBinaryFileChunk"
object_type: "CLR_USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@RootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein."}, {"name": "@RelativePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich."}, {"name": "@ByteOffset", "sql_type": "bigint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Byteposition ab Dateianfang, einschließlich bei Textdateien. Bereich 0 bis Dateilänge; größer als Dateilänge oder negativ wird zurückgewiesen. NULL ist für den primitiven CLR-long-Parameter nicht unterstützt."}, {"name": "@MaxBytes", "sql_type": "int", "sql_default": "1048576", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Maximale angeforderte Bytes pro Chunk: binär 1..16777216, Text 4..16777216. Default 1048576. Kein Zeichenlimit. NULL ist für CLR-int nicht unterstützt."}, {"name": "@ExecutionIdentity", "sql_type": "nvarchar(16)", "sql_default": "N'Caller'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback."}]
source_paths: ["Modules/toolbelt.filesystem.windows/Source/Procedures.sql", "Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_filesystem.USP_ReadBinaryFileChunk"]
---

# CLR_ReadBinaryFileChunk

## Zweck und Einsatzfälle

Interner Windows-CLR-Provider zum begrenzten Lesen eines binären Dateichunks. Internes Implementierungsdetail. Regulär die öffentliche USP_ReadBinaryFileChunk mit frühem Hilfe-, Validierungs- und ResultTable-Vertrag verwenden; keine Empfehlung, die Facade zu umgehen.

## Voraussetzungen

Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowRead erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich. |
| `@ByteOffset` | `bigint` | `0` | Byteposition ab Dateianfang, einschließlich bei Textdateien. Bereich 0 bis Dateilänge; größer als Dateilänge oder negativ wird zurückgewiesen. NULL ist für den primitiven CLR-long-Parameter nicht unterstützt. |
| `@MaxBytes` | `int` | `1048576` | Maximale angeforderte Bytes pro Chunk: binär 1..16777216, Text 4..16777216. Default 1048576. Kein Zeichenlimit. NULL ist für CLR-int nicht unterstützt. |
| `@ExecutionIdentity` | `nvarchar(16)` | `N'Caller'` | Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback. |

## Ergebnisse

Eine Zeile: Content varbinary(max), BytesRead int, NextByteOffset bigint, EndOfFile bit. BytesRead ist tatsächlich gelesen; NextByteOffset=ByteOffset+BytesRead. Am Dateiende sind leerer Inhalt und EndOfFile=1 möglich. Keine OUTPUT-Parameter, kein ResultTable-Routing. Aktueller raw CLR-Einstieg besitzt noch keinen @Hilfe-Parameter; seine Erweiterung ist eine getrennte offene Implementierung. Er bietet weder den zwölfspaltigen Facade-Hilfetext noch ResultTable/KeepData/Debug.

## Aufrufbeispiele

```sql
-- Synthetisches Beispiel: nur mit eigener passender Rootkonfiguration ausführen.
-- Regulärer öffentlicher Einstieg für diese Operation:
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk @Hilfe=1;
-- Direkter interner Fachaufruf, nicht auf fremde Pfade anwenden:
EXEC toolbelt_filesystem.CLR_ReadBinaryFileChunk @RootAlias=N'ContosoRead',@RelativePath=N'sample.bin',@ByteOffset=0,@MaxBytes=1024;
```

## Rechte

Vorhandene EXECUTE-Rechte auf den internen Einstieg, CLR-Ausführungs-/Trustvoraussetzungen und SELECT auf toolbelt_filesystem.FileSystemRoot im tatsächlichen SQL-Kontext. Direkter Aufruf ist keine Rechteabkürzung. Caller: Windows-Authentifizierung und NTFS-Rechte der erfassten Windowsidentität. ServiceAccount: Mitgliedschaft in dbo-eigener Datenbankrolle toolbelt_filesystem_service_account, AllowServiceAccount am Root und NTFS-Rechte des SQL-Dienstkontos. Keine automatische Rechtevergabe oder Identitätsumschaltung.

## Ressourcenbedarf

Ein Bytearray bis MaxBytes; begrenztes Lesen unter nativen Datei-/Parenthandles. Keine komplette Datei zwingend im Speicher.

## Nebenwirkungen

Liest Dateidaten und Metadaten, erzeugt oder verändert keine Datei. Dateiinhalte können vertraulich sein; nicht als öffentliche Evidenz speichern.

## Fehlerbehandlung

Providerfehler werden als .NET-Ausnahmen mit TBXFS:-Codes beziehungsweise als SQL-CLR-Enginefehler sichtbar; unter anderem RootAliasRequired, RootNotAuthorized, InvalidExecutionIdentity, CallerWindowsAuthenticationRequired, ServiceAccountNotAuthorized, InvalidPath/PathOutsideRoot und native Handlefehler. Operationabhängig zusätzlich InvalidChunkRange, OffsetBeyondEnd, InvalidListLimit, EntryLimitExceeded, DepthLimitExceeded, EncodingRequired/UnsupportedEncoding, ContentRequired. Reparse Points und Hardlinks werden im nativen Prüfpfad abgewiesen; keine Fallbackoperation nach Fehler. Betriebssystem-/Encodingausnahmen können zusätzlich auftreten. Fehlertexte und Dateiresultate können vertrauliche Informationen enthalten und gehören nicht in öffentliche Logs.

## Aussagegrenzen

Quellgeprüfter Vertrag der aktuellen SQL-/C#-Implementierung, kein neuer nativer Funktions-, Rechte-, Race- oder Hilfe-Gesamtnachweis. Raw CLR hat keine vollständige Facadevalidierung und noch keine eigene Skillhilfe. Aus einer vorhandenen Skillzeile folgen weder Installation noch ausreichende Rechte. Dateiaktionen sind außerhalb SQL-Transaktionsrollback; keine automatische Infrastruktur-/Root-/Trustreparatur.
