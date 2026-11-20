---
name: "toolbelt-fs-clr-write-text-file"
description: "Interner Windows-CLR-Provider zum gestreamten Encodieren und Schreiben einer Textdatei."
skill_format_version: "1.0"
module_id: "toolbelt.filesystem.windows"
schema_name: "toolbelt_filesystem"
object_name: "CLR_WriteTextFile"
object_type: "CLR_USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@RootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein."}, {"name": "@RelativePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich."}, {"name": "@Content", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Textinhalt als nvarchar(max), kein SQL-Default; syntaktisch erforderlich. SQL-NULL wird als ContentRequired abgewiesen, leerer Text ist zulässig. Explizites Encoding erforderlich."}, {"name": "@EncodingName", "sql_type": "nvarchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Expliziter von .NET Framework unterstützter Encodingname, zum Beispiel utf-8. NULL/leer/Whitespace oder unbekannter Name wird zurückgewiesen. Strikte Encoder-/Decoder-Fallbacks; keine stillschweigende Ersetzung ungültiger Zeichen."}, {"name": "@WriteBom", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "bit, Default 0: keine zusätzliche Präambel schreiben. 1 schreibt GetPreamble() des gewählten Ausgabeencodings, falls dieses eine besitzt. Keine Garantie einer BOM für jedes Encoding. NULL ist für CLR-bool nicht unterstützt."}, {"name": "@Overwrite", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "bit, Default 0: bestehendes Ziel nicht ersetzen. 1 erlaubt das Ersetzen durch den nativen Publishpfad; vorhandene Ziel-DACL wird übernommen. NULL ist für CLR-bool nicht unterstützt. Keine automatische Verzeichnisanlage."}, {"name": "@ExecutionIdentity", "sql_type": "nvarchar(16)", "sql_default": "N'Caller'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback."}]
source_paths: ["Modules/toolbelt.filesystem.windows/Source/Procedures.sql", "Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_filesystem.USP_WriteTextFile"]
---

# CLR_WriteTextFile

## Zweck und Einsatzfälle

Interner Windows-CLR-Provider zum gestreamten Encodieren und Schreiben einer Textdatei. Internes Implementierungsdetail. Regulär die öffentliche USP_WriteTextFile mit frühem Hilfe-, Validierungs- und ResultTable-Vertrag verwenden; keine Empfehlung, die Facade zu umgehen.

## Voraussetzungen

Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowWrite erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@RootAlias` | `sysname` | `NULL` | Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich. |
| `@Content` | `nvarchar(max)` | `kein Default` | Textinhalt als nvarchar(max), kein SQL-Default; syntaktisch erforderlich. SQL-NULL wird als ContentRequired abgewiesen, leerer Text ist zulässig. Explizites Encoding erforderlich. |
| `@EncodingName` | `nvarchar(128)` | `NULL` | Expliziter von .NET Framework unterstützter Encodingname, zum Beispiel utf-8. NULL/leer/Whitespace oder unbekannter Name wird zurückgewiesen. Strikte Encoder-/Decoder-Fallbacks; keine stillschweigende Ersetzung ungültiger Zeichen. |
| `@WriteBom` | `bit` | `0` | bit, Default 0: keine zusätzliche Präambel schreiben. 1 schreibt GetPreamble() des gewählten Ausgabeencodings, falls dieses eine besitzt. Keine Garantie einer BOM für jedes Encoding. NULL ist für CLR-bool nicht unterstützt. |
| `@Overwrite` | `bit` | `0` | bit, Default 0: bestehendes Ziel nicht ersetzen. 1 erlaubt das Ersetzen durch den nativen Publishpfad; vorhandene Ziel-DACL wird übernommen. NULL ist für CLR-bool nicht unterstützt. Keine automatische Verzeichnisanlage. |
| `@ExecutionIdentity` | `nvarchar(16)` | `N'Caller'` | Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback. |

## Ergebnisse

Eine Erfolgszeile: BytesWritten bigint einschließlich einer tatsächlich geschriebenen Präambel, RootAlias nvarchar(128), RelativePath nvarchar(4000), State varchar(16)=completed. Keine OUTPUT-Parameter. Aktueller raw CLR-Einstieg besitzt noch keinen @Hilfe-Parameter; seine Erweiterung ist eine getrennte offene Implementierung. Er bietet weder den zwölfspaltigen Facade-Hilfetext noch ResultTable/KeepData/Debug.

## Aufrufbeispiele

```sql
-- Synthetisches Beispiel: nur mit eigener passender Rootkonfiguration ausführen.
-- Regulärer öffentlicher Einstieg für diese Operation:
EXEC toolbelt_filesystem.USP_WriteTextFile @Hilfe=1;
-- Direkter interner Fachaufruf, nicht auf fremde Pfade anwenden:
EXEC toolbelt_filesystem.CLR_WriteTextFile @RootAlias=N'ContosoWrite',@RelativePath=N'sample.txt',@Content=N'Example',@EncodingName=N'utf-8';
```

## Rechte

Vorhandene EXECUTE-Rechte auf den internen Einstieg, CLR-Ausführungs-/Trustvoraussetzungen und SELECT auf toolbelt_filesystem.FileSystemRoot im tatsächlichen SQL-Kontext. Direkter Aufruf ist keine Rechteabkürzung. Caller: Windows-Authentifizierung und NTFS-Rechte der erfassten Windowsidentität. ServiceAccount: Mitgliedschaft in dbo-eigener Datenbankrolle toolbelt_filesystem_service_account, AllowServiceAccount am Root und NTFS-Rechte des SQL-Dienstkontos. Keine automatische Rechtevergabe oder Identitätsumschaltung.

## Ressourcenbedarf

32768-Zeichen-Puffer und Encoding-Ausgabepuffer; abschnittsweises SqlChars-Lesen, kein verpflichtendes vollständiges LOB-Materialisieren. Keine eigene kleine Gesamtdateiquote. Encoding.GetBytes wird je Chunk separat aufgerufen; keine Zusage beliebiger über Puffergrenzen verteilter Surrogatpaare oder zustandsbehafteter Encodings.

## Nebenwirkungen

Staging und nativer Publish wie WriteBinaryFile. WriteBom fügt gegebenenfalls die Encodingpräambel hinzu; keine automatische Entfernung einer bereits im Content enthaltenen Präambel. Dateiänderungen sind nicht SQL-transaktional.

## Fehlerbehandlung

Providerfehler werden als .NET-Ausnahmen mit TBXFS:-Codes beziehungsweise als SQL-CLR-Enginefehler sichtbar; unter anderem RootAliasRequired, RootNotAuthorized, InvalidExecutionIdentity, CallerWindowsAuthenticationRequired, ServiceAccountNotAuthorized, InvalidPath/PathOutsideRoot und native Handlefehler. Operationabhängig zusätzlich InvalidChunkRange, OffsetBeyondEnd, InvalidListLimit, EntryLimitExceeded, DepthLimitExceeded, EncodingRequired/UnsupportedEncoding, ContentRequired. Reparse Points und Hardlinks werden im nativen Prüfpfad abgewiesen; keine Fallbackoperation nach Fehler. Betriebssystem-/Encodingausnahmen können zusätzlich auftreten. Fehlertexte und Dateiresultate können vertrauliche Informationen enthalten und gehören nicht in öffentliche Logs.

## Aussagegrenzen

Quellgeprüfter Vertrag der aktuellen SQL-/C#-Implementierung, kein neuer nativer Funktions-, Rechte-, Race- oder Hilfe-Gesamtnachweis. Raw CLR hat keine vollständige Facadevalidierung und noch keine eigene Skillhilfe. Aus einer vorhandenen Skillzeile folgen weder Installation noch ausreichende Rechte. Dateiaktionen sind außerhalb SQL-Transaktionsrollback; keine automatische Infrastruktur-/Root-/Trustreparatur.
