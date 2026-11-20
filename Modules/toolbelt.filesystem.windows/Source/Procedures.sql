SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* Internal CLR entry points. The public T-SQL facade owns Help and ResultTable. */
CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[CLR_ReadBinaryFileChunk]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @ByteOffset bigint = 0
  , @MaxBytes int = 1048576
  , @ExecutionIdentity nvarchar(16) = N'Caller'
)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-fs-clr-read-binary-file-chunk"
-- description: "Interner Windows-CLR-Provider zum begrenzten Lesen eines binären Dateichunks."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.filesystem.windows"
-- schema_name: "toolbelt_filesystem"
-- object_name: "CLR_ReadBinaryFileChunk"
-- object_type: "CLR_USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@RootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein."}, {"name": "@RelativePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich."}, {"name": "@ByteOffset", "sql_type": "bigint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Byteposition ab Dateianfang, einschließlich bei Textdateien. Bereich 0 bis Dateilänge; größer als Dateilänge oder negativ wird zurückgewiesen. NULL ist für den primitiven CLR-long-Parameter nicht unterstützt."}, {"name": "@MaxBytes", "sql_type": "int", "sql_default": "1048576", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Maximale angeforderte Bytes pro Chunk: binär 1..16777216, Text 4..16777216. Default 1048576. Kein Zeichenlimit. NULL ist für CLR-int nicht unterstützt."}, {"name": "@ExecutionIdentity", "sql_type": "nvarchar(16)", "sql_default": "N'Caller'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback."}]
-- source_paths: ["Modules/toolbelt.filesystem.windows/Source/Procedures.sql", "Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_filesystem.USP_ReadBinaryFileChunk"]
-- ---
--
-- # CLR_ReadBinaryFileChunk
--
-- ## Zweck und Einsatzfälle
--
-- Interner Windows-CLR-Provider zum begrenzten Lesen eines binären Dateichunks. Internes Implementierungsdetail. Regulär die öffentliche USP_ReadBinaryFileChunk mit frühem Hilfe-, Validierungs- und ResultTable-Vertrag verwenden; keine Empfehlung, die Facade zu umgehen.
--
-- ## Voraussetzungen
--
-- Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowRead erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@RootAlias` | `sysname` | `NULL` | Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein. |
-- | `@RelativePath` | `nvarchar(4000)` | `NULL` | Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich. |
-- | `@ByteOffset` | `bigint` | `0` | Byteposition ab Dateianfang, einschließlich bei Textdateien. Bereich 0 bis Dateilänge; größer als Dateilänge oder negativ wird zurückgewiesen. NULL ist für den primitiven CLR-long-Parameter nicht unterstützt. |
-- | `@MaxBytes` | `int` | `1048576` | Maximale angeforderte Bytes pro Chunk: binär 1..16777216, Text 4..16777216. Default 1048576. Kein Zeichenlimit. NULL ist für CLR-int nicht unterstützt. |
-- | `@ExecutionIdentity` | `nvarchar(16)` | `N'Caller'` | Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback. |
--
-- ## Ergebnisse
--
-- Eine Zeile: Content varbinary(max), BytesRead int, NextByteOffset bigint, EndOfFile bit. BytesRead ist tatsächlich gelesen; NextByteOffset=ByteOffset+BytesRead. Am Dateiende sind leerer Inhalt und EndOfFile=1 möglich. Keine OUTPUT-Parameter, kein ResultTable-Routing. Aktueller raw CLR-Einstieg besitzt noch keinen @Hilfe-Parameter; seine Erweiterung ist eine getrennte offene Implementierung. Er bietet weder den zwölfspaltigen Facade-Hilfetext noch ResultTable/KeepData/Debug.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Synthetisches Beispiel: nur mit eigener passender Rootkonfiguration ausführen.
-- -- Regulärer öffentlicher Einstieg für diese Operation:
-- EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk @Hilfe=1;
-- -- Direkter interner Fachaufruf, nicht auf fremde Pfade anwenden:
-- EXEC toolbelt_filesystem.CLR_ReadBinaryFileChunk @RootAlias=N'ContosoRead',@RelativePath=N'sample.bin',@ByteOffset=0,@MaxBytes=1024;
-- ```
--
-- ## Rechte
--
-- Vorhandene EXECUTE-Rechte auf den internen Einstieg, CLR-Ausführungs-/Trustvoraussetzungen und SELECT auf toolbelt_filesystem.FileSystemRoot im tatsächlichen SQL-Kontext. Direkter Aufruf ist keine Rechteabkürzung. Caller: Windows-Authentifizierung und NTFS-Rechte der erfassten Windowsidentität. ServiceAccount: Mitgliedschaft in dbo-eigener Datenbankrolle toolbelt_filesystem_service_account, AllowServiceAccount am Root und NTFS-Rechte des SQL-Dienstkontos. Keine automatische Rechtevergabe oder Identitätsumschaltung.
--
-- ## Ressourcenbedarf
--
-- Ein Bytearray bis MaxBytes; begrenztes Lesen unter nativen Datei-/Parenthandles. Keine komplette Datei zwingend im Speicher.
--
-- ## Nebenwirkungen
--
-- Liest Dateidaten und Metadaten, erzeugt oder verändert keine Datei. Dateiinhalte können vertraulich sein; nicht als öffentliche Evidenz speichern.
--
-- ## Fehlerbehandlung
--
-- Providerfehler werden als .NET-Ausnahmen mit TBXFS:-Codes beziehungsweise als SQL-CLR-Enginefehler sichtbar; unter anderem RootAliasRequired, RootNotAuthorized, InvalidExecutionIdentity, CallerWindowsAuthenticationRequired, ServiceAccountNotAuthorized, InvalidPath/PathOutsideRoot und native Handlefehler. Operationabhängig zusätzlich InvalidChunkRange, OffsetBeyondEnd, InvalidListLimit, EntryLimitExceeded, DepthLimitExceeded, EncodingRequired/UnsupportedEncoding, ContentRequired. Reparse Points und Hardlinks werden im nativen Prüfpfad abgewiesen; keine Fallbackoperation nach Fehler. Betriebssystem-/Encodingausnahmen können zusätzlich auftreten. Fehlertexte und Dateiresultate können vertrauliche Informationen enthalten und gehören nicht in öffentliche Logs.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter Vertrag der aktuellen SQL-/C#-Implementierung, kein neuer nativer Funktions-, Rechte-, Race- oder Hilfe-Gesamtnachweis. Raw CLR hat keine vollständige Facadevalidierung und noch keine eigene Skillhilfe. Aus einer vorhandenen Skillzeile folgen weder Installation noch ausreichende Rechte. Dateiaktionen sind außerhalb SQL-Transaktionsrollback; keine automatische Infrastruktur-/Root-/Trustreparatur.
-- OBJECT_USAGE_SKILL:END
AS EXTERNAL NAME [tlblt_Filesystem_Windows].[Toolbelt.Filesystem.Windows.WindowsFilesystemProvider].[ReadBinaryFileChunk];
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[CLR_ReadTextFileChunk]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @ByteOffset bigint = 0
  , @MaxBytes int = 1048576
  , @EncodingName nvarchar(128) = NULL
  , @ExecutionIdentity nvarchar(16) = N'Caller'
)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-fs-clr-read-text-file-chunk"
-- description: "Interner Windows-CLR-Provider zum bytepositionierten Lesen und strikten Dekodieren eines Textchunks."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.filesystem.windows"
-- schema_name: "toolbelt_filesystem"
-- object_name: "CLR_ReadTextFileChunk"
-- object_type: "CLR_USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@RootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein."}, {"name": "@RelativePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich."}, {"name": "@ByteOffset", "sql_type": "bigint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Byteposition ab Dateianfang, einschließlich bei Textdateien. Bereich 0 bis Dateilänge; größer als Dateilänge oder negativ wird zurückgewiesen. NULL ist für den primitiven CLR-long-Parameter nicht unterstützt."}, {"name": "@MaxBytes", "sql_type": "int", "sql_default": "1048576", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Maximale angeforderte Bytes pro Chunk: binär 1..16777216, Text 4..16777216. Default 1048576. Kein Zeichenlimit. NULL ist für CLR-int nicht unterstützt."}, {"name": "@EncodingName", "sql_type": "nvarchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Expliziter von .NET Framework unterstützter Encodingname, zum Beispiel utf-8. NULL/leer/Whitespace oder unbekannter Name wird zurückgewiesen. Strikte Encoder-/Decoder-Fallbacks; keine stillschweigende Ersetzung ungültiger Zeichen."}, {"name": "@ExecutionIdentity", "sql_type": "nvarchar(16)", "sql_default": "N'Caller'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback."}]
-- source_paths: ["Modules/toolbelt.filesystem.windows/Source/Procedures.sql", "Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_filesystem.USP_ReadTextFileChunk"]
-- ---
--
-- # CLR_ReadTextFileChunk
--
-- ## Zweck und Einsatzfälle
--
-- Interner Windows-CLR-Provider zum bytepositionierten Lesen und strikten Dekodieren eines Textchunks. Internes Implementierungsdetail. Regulär die öffentliche USP_ReadTextFileChunk mit frühem Hilfe-, Validierungs- und ResultTable-Vertrag verwenden; keine Empfehlung, die Facade zu umgehen.
--
-- ## Voraussetzungen
--
-- Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowRead erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@RootAlias` | `sysname` | `NULL` | Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein. |
-- | `@RelativePath` | `nvarchar(4000)` | `NULL` | Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich. |
-- | `@ByteOffset` | `bigint` | `0` | Byteposition ab Dateianfang, einschließlich bei Textdateien. Bereich 0 bis Dateilänge; größer als Dateilänge oder negativ wird zurückgewiesen. NULL ist für den primitiven CLR-long-Parameter nicht unterstützt. |
-- | `@MaxBytes` | `int` | `1048576` | Maximale angeforderte Bytes pro Chunk: binär 1..16777216, Text 4..16777216. Default 1048576. Kein Zeichenlimit. NULL ist für CLR-int nicht unterstützt. |
-- | `@EncodingName` | `nvarchar(128)` | `NULL` | Expliziter von .NET Framework unterstützter Encodingname, zum Beispiel utf-8. NULL/leer/Whitespace oder unbekannter Name wird zurückgewiesen. Strikte Encoder-/Decoder-Fallbacks; keine stillschweigende Ersetzung ungültiger Zeichen. |
-- | `@ExecutionIdentity` | `nvarchar(16)` | `N'Caller'` | Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback. |
--
-- ## Ergebnisse
--
-- Eine Zeile: Content nvarchar(max), BytesRead int, NextByteOffset bigint, EndOfFile bit, EncodingName nvarchar(128) als .NET-WebName. Nur erfolgreich dekodierte Bytes zählen. Am Chunkende werden bis zur Decodergrenze Bytes zurückgenommen; der Aufrufer setzt bei NextByteOffset fort. Keine OUTPUT-Parameter. Aktueller raw CLR-Einstieg besitzt noch keinen @Hilfe-Parameter; seine Erweiterung ist eine getrennte offene Implementierung. Er bietet weder den zwölfspaltigen Facade-Hilfetext noch ResultTable/KeepData/Debug.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Synthetisches Beispiel: nur mit eigener passender Rootkonfiguration ausführen.
-- -- Regulärer öffentlicher Einstieg für diese Operation:
-- EXEC toolbelt_filesystem.USP_ReadTextFileChunk @Hilfe=1;
-- -- Direkter interner Fachaufruf, nicht auf fremde Pfade anwenden:
-- EXEC toolbelt_filesystem.CLR_ReadTextFileChunk @RootAlias=N'ContosoRead',@RelativePath=N'sample.txt',@EncodingName=N'utf-8';
-- ```
--
-- ## Rechte
--
-- Vorhandene EXECUTE-Rechte auf den internen Einstieg, CLR-Ausführungs-/Trustvoraussetzungen und SELECT auf toolbelt_filesystem.FileSystemRoot im tatsächlichen SQL-Kontext. Direkter Aufruf ist keine Rechteabkürzung. Caller: Windows-Authentifizierung und NTFS-Rechte der erfassten Windowsidentität. ServiceAccount: Mitgliedschaft in dbo-eigener Datenbankrolle toolbelt_filesystem_service_account, AllowServiceAccount am Root und NTFS-Rechte des SQL-Dienstkontos. Keine automatische Rechtevergabe oder Identitätsumschaltung.
--
-- ## Ressourcenbedarf
--
-- Bytearray bis MaxBytes und dekodierter Text; begrenzte Dekodier-Versuche am Ende. ByteOffset muss sinnvoll zu einer Zeichengrenze gewählt werden. Ein unpassender Offset kann Fehler oder einen leeren Chunk ohne Fortschritt ergeben; Caller muss Fortschritt prüfen.
--
-- ## Nebenwirkungen
--
-- Liest Text und Metadaten ohne Dateischreiben. Kein zugesichertes Entfernen einer Eingangs-BOM, keine Encoding-Autodetektion.
--
-- ## Fehlerbehandlung
--
-- Providerfehler werden als .NET-Ausnahmen mit TBXFS:-Codes beziehungsweise als SQL-CLR-Enginefehler sichtbar; unter anderem RootAliasRequired, RootNotAuthorized, InvalidExecutionIdentity, CallerWindowsAuthenticationRequired, ServiceAccountNotAuthorized, InvalidPath/PathOutsideRoot und native Handlefehler. Operationabhängig zusätzlich InvalidChunkRange, OffsetBeyondEnd, InvalidListLimit, EntryLimitExceeded, DepthLimitExceeded, EncodingRequired/UnsupportedEncoding, ContentRequired. Reparse Points und Hardlinks werden im nativen Prüfpfad abgewiesen; keine Fallbackoperation nach Fehler. Betriebssystem-/Encodingausnahmen können zusätzlich auftreten. Fehlertexte und Dateiresultate können vertrauliche Informationen enthalten und gehören nicht in öffentliche Logs.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter Vertrag der aktuellen SQL-/C#-Implementierung, kein neuer nativer Funktions-, Rechte-, Race- oder Hilfe-Gesamtnachweis. Raw CLR hat keine vollständige Facadevalidierung und noch keine eigene Skillhilfe. Aus einer vorhandenen Skillzeile folgen weder Installation noch ausreichende Rechte. Dateiaktionen sind außerhalb SQL-Transaktionsrollback; keine automatische Infrastruktur-/Root-/Trustreparatur.
-- OBJECT_USAGE_SKILL:END
AS EXTERNAL NAME [tlblt_Filesystem_Windows].[Toolbelt.Filesystem.Windows.WindowsFilesystemProvider].[ReadTextFileChunk];
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[CLR_WriteBinaryFile]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @Content varbinary(max)
  , @Overwrite bit = 0
  , @ExecutionIdentity nvarchar(16) = N'Caller'
)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-fs-clr-write-binary-file"
-- description: "Interner Windows-CLR-Provider zum gestreamten Schreiben einer Binärdatei über eine Stagingdatei."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.filesystem.windows"
-- schema_name: "toolbelt_filesystem"
-- object_name: "CLR_WriteBinaryFile"
-- object_type: "CLR_USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@RootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein."}, {"name": "@RelativePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich."}, {"name": "@Content", "sql_type": "varbinary(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Binärinhalt als varbinary(max), kein SQL-Default; syntaktisch erforderlich. SQL-NULL wird als ContentRequired abgewiesen, 0x ist ein zulässiger leerer Inhalt."}, {"name": "@Overwrite", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "bit, Default 0: bestehendes Ziel nicht ersetzen. 1 erlaubt das Ersetzen durch den nativen Publishpfad; vorhandene Ziel-DACL wird übernommen. NULL ist für CLR-bool nicht unterstützt. Keine automatische Verzeichnisanlage."}, {"name": "@ExecutionIdentity", "sql_type": "nvarchar(16)", "sql_default": "N'Caller'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback."}]
-- source_paths: ["Modules/toolbelt.filesystem.windows/Source/Procedures.sql", "Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_filesystem.USP_WriteBinaryFile"]
-- ---
--
-- # CLR_WriteBinaryFile
--
-- ## Zweck und Einsatzfälle
--
-- Interner Windows-CLR-Provider zum gestreamten Schreiben einer Binärdatei über eine Stagingdatei. Internes Implementierungsdetail. Regulär die öffentliche USP_WriteBinaryFile mit frühem Hilfe-, Validierungs- und ResultTable-Vertrag verwenden; keine Empfehlung, die Facade zu umgehen.
--
-- ## Voraussetzungen
--
-- Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowWrite erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@RootAlias` | `sysname` | `NULL` | Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein. |
-- | `@RelativePath` | `nvarchar(4000)` | `NULL` | Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich. |
-- | `@Content` | `varbinary(max)` | `kein Default` | Binärinhalt als varbinary(max), kein SQL-Default; syntaktisch erforderlich. SQL-NULL wird als ContentRequired abgewiesen, 0x ist ein zulässiger leerer Inhalt. |
-- | `@Overwrite` | `bit` | `0` | bit, Default 0: bestehendes Ziel nicht ersetzen. 1 erlaubt das Ersetzen durch den nativen Publishpfad; vorhandene Ziel-DACL wird übernommen. NULL ist für CLR-bool nicht unterstützt. Keine automatische Verzeichnisanlage. |
-- | `@ExecutionIdentity` | `nvarchar(16)` | `N'Caller'` | Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback. |
--
-- ## Ergebnisse
--
-- Nach erfolgreichem Publish eine Zeile: BytesWritten bigint, RootAlias nvarchar(128), RelativePath nvarchar(4000), State varchar(16)=completed. Keine OUTPUT-Parameter oder ResultTable-Verarbeitung. Aktueller raw CLR-Einstieg besitzt noch keinen @Hilfe-Parameter; seine Erweiterung ist eine getrennte offene Implementierung. Er bietet weder den zwölfspaltigen Facade-Hilfetext noch ResultTable/KeepData/Debug.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Synthetisches Beispiel: nur mit eigener passender Rootkonfiguration ausführen.
-- -- Regulärer öffentlicher Einstieg für diese Operation:
-- EXEC toolbelt_filesystem.USP_WriteBinaryFile @Hilfe=1;
-- -- Direkter interner Fachaufruf, nicht auf fremde Pfade anwenden:
-- EXEC toolbelt_filesystem.CLR_WriteBinaryFile @RootAlias=N'ContosoWrite',@RelativePath=N'sample.bin',@Content=0x0102;
-- ```
--
-- ## Rechte
--
-- Vorhandene EXECUTE-Rechte auf den internen Einstieg, CLR-Ausführungs-/Trustvoraussetzungen und SELECT auf toolbelt_filesystem.FileSystemRoot im tatsächlichen SQL-Kontext. Direkter Aufruf ist keine Rechteabkürzung. Caller: Windows-Authentifizierung und NTFS-Rechte der erfassten Windowsidentität. ServiceAccount: Mitgliedschaft in dbo-eigener Datenbankrolle toolbelt_filesystem_service_account, AllowServiceAccount am Root und NTFS-Rechte des SQL-Dienstkontos. Keine automatische Rechtevergabe oder Identitätsumschaltung.
--
-- ## Ressourcenbedarf
--
-- 1-MiB-Kopierpuffer; LOB wird abschnittsweise aus SqlBytes gelesen. Keine zusätzliche kleine Gesamtdateiquote im Provider; SQL-LOB-, Datenträger- und Betriebssystemgrenzen gelten.
--
-- ## Nebenwirkungen
--
-- Erzeugt eine eigene .part-Stagingdatei im konfigurierten WorkPath relativ zum Root oder im Zielverzeichnis, flusht und publiziert über einen gebundenen Handle. Overwrite=0 ersetzt kein bestehendes Ziel. Dateisystemänderungen werden nicht durch SQL-ROLLBACK rückgängig gemacht. Cleanupfehler können Stagingreste hinterlassen.
--
-- ## Fehlerbehandlung
--
-- Providerfehler werden als .NET-Ausnahmen mit TBXFS:-Codes beziehungsweise als SQL-CLR-Enginefehler sichtbar; unter anderem RootAliasRequired, RootNotAuthorized, InvalidExecutionIdentity, CallerWindowsAuthenticationRequired, ServiceAccountNotAuthorized, InvalidPath/PathOutsideRoot und native Handlefehler. Operationabhängig zusätzlich InvalidChunkRange, OffsetBeyondEnd, InvalidListLimit, EntryLimitExceeded, DepthLimitExceeded, EncodingRequired/UnsupportedEncoding, ContentRequired. Reparse Points und Hardlinks werden im nativen Prüfpfad abgewiesen; keine Fallbackoperation nach Fehler. Betriebssystem-/Encodingausnahmen können zusätzlich auftreten. Fehlertexte und Dateiresultate können vertrauliche Informationen enthalten und gehören nicht in öffentliche Logs.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter Vertrag der aktuellen SQL-/C#-Implementierung, kein neuer nativer Funktions-, Rechte-, Race- oder Hilfe-Gesamtnachweis. Raw CLR hat keine vollständige Facadevalidierung und noch keine eigene Skillhilfe. Aus einer vorhandenen Skillzeile folgen weder Installation noch ausreichende Rechte. Dateiaktionen sind außerhalb SQL-Transaktionsrollback; keine automatische Infrastruktur-/Root-/Trustreparatur.
-- OBJECT_USAGE_SKILL:END
AS EXTERNAL NAME [tlblt_Filesystem_Windows].[Toolbelt.Filesystem.Windows.WindowsFilesystemProvider].[WriteBinaryFile];
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[CLR_WriteTextFile]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @Content nvarchar(max)
  , @EncodingName nvarchar(128) = NULL
  , @WriteBom bit = 0
  , @Overwrite bit = 0
  , @ExecutionIdentity nvarchar(16) = N'Caller'
)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-fs-clr-write-text-file"
-- description: "Interner Windows-CLR-Provider zum gestreamten Encodieren und Schreiben einer Textdatei."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.filesystem.windows"
-- schema_name: "toolbelt_filesystem"
-- object_name: "CLR_WriteTextFile"
-- object_type: "CLR_USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@RootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein."}, {"name": "@RelativePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich."}, {"name": "@Content", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Textinhalt als nvarchar(max), kein SQL-Default; syntaktisch erforderlich. SQL-NULL wird als ContentRequired abgewiesen, leerer Text ist zulässig. Explizites Encoding erforderlich."}, {"name": "@EncodingName", "sql_type": "nvarchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Expliziter von .NET Framework unterstützter Encodingname, zum Beispiel utf-8. NULL/leer/Whitespace oder unbekannter Name wird zurückgewiesen. Strikte Encoder-/Decoder-Fallbacks; keine stillschweigende Ersetzung ungültiger Zeichen."}, {"name": "@WriteBom", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "bit, Default 0: keine zusätzliche Präambel schreiben. 1 schreibt GetPreamble() des gewählten Ausgabeencodings, falls dieses eine besitzt. Keine Garantie einer BOM für jedes Encoding. NULL ist für CLR-bool nicht unterstützt."}, {"name": "@Overwrite", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "bit, Default 0: bestehendes Ziel nicht ersetzen. 1 erlaubt das Ersetzen durch den nativen Publishpfad; vorhandene Ziel-DACL wird übernommen. NULL ist für CLR-bool nicht unterstützt. Keine automatische Verzeichnisanlage."}, {"name": "@ExecutionIdentity", "sql_type": "nvarchar(16)", "sql_default": "N'Caller'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback."}]
-- source_paths: ["Modules/toolbelt.filesystem.windows/Source/Procedures.sql", "Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_filesystem.USP_WriteTextFile"]
-- ---
--
-- # CLR_WriteTextFile
--
-- ## Zweck und Einsatzfälle
--
-- Interner Windows-CLR-Provider zum gestreamten Encodieren und Schreiben einer Textdatei. Internes Implementierungsdetail. Regulär die öffentliche USP_WriteTextFile mit frühem Hilfe-, Validierungs- und ResultTable-Vertrag verwenden; keine Empfehlung, die Facade zu umgehen.
--
-- ## Voraussetzungen
--
-- Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowWrite erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@RootAlias` | `sysname` | `NULL` | Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein. |
-- | `@RelativePath` | `nvarchar(4000)` | `NULL` | Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich. |
-- | `@Content` | `nvarchar(max)` | `kein Default` | Textinhalt als nvarchar(max), kein SQL-Default; syntaktisch erforderlich. SQL-NULL wird als ContentRequired abgewiesen, leerer Text ist zulässig. Explizites Encoding erforderlich. |
-- | `@EncodingName` | `nvarchar(128)` | `NULL` | Expliziter von .NET Framework unterstützter Encodingname, zum Beispiel utf-8. NULL/leer/Whitespace oder unbekannter Name wird zurückgewiesen. Strikte Encoder-/Decoder-Fallbacks; keine stillschweigende Ersetzung ungültiger Zeichen. |
-- | `@WriteBom` | `bit` | `0` | bit, Default 0: keine zusätzliche Präambel schreiben. 1 schreibt GetPreamble() des gewählten Ausgabeencodings, falls dieses eine besitzt. Keine Garantie einer BOM für jedes Encoding. NULL ist für CLR-bool nicht unterstützt. |
-- | `@Overwrite` | `bit` | `0` | bit, Default 0: bestehendes Ziel nicht ersetzen. 1 erlaubt das Ersetzen durch den nativen Publishpfad; vorhandene Ziel-DACL wird übernommen. NULL ist für CLR-bool nicht unterstützt. Keine automatische Verzeichnisanlage. |
-- | `@ExecutionIdentity` | `nvarchar(16)` | `N'Caller'` | Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback. |
--
-- ## Ergebnisse
--
-- Eine Erfolgszeile: BytesWritten bigint einschließlich einer tatsächlich geschriebenen Präambel, RootAlias nvarchar(128), RelativePath nvarchar(4000), State varchar(16)=completed. Keine OUTPUT-Parameter. Aktueller raw CLR-Einstieg besitzt noch keinen @Hilfe-Parameter; seine Erweiterung ist eine getrennte offene Implementierung. Er bietet weder den zwölfspaltigen Facade-Hilfetext noch ResultTable/KeepData/Debug.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Synthetisches Beispiel: nur mit eigener passender Rootkonfiguration ausführen.
-- -- Regulärer öffentlicher Einstieg für diese Operation:
-- EXEC toolbelt_filesystem.USP_WriteTextFile @Hilfe=1;
-- -- Direkter interner Fachaufruf, nicht auf fremde Pfade anwenden:
-- EXEC toolbelt_filesystem.CLR_WriteTextFile @RootAlias=N'ContosoWrite',@RelativePath=N'sample.txt',@Content=N'Example',@EncodingName=N'utf-8';
-- ```
--
-- ## Rechte
--
-- Vorhandene EXECUTE-Rechte auf den internen Einstieg, CLR-Ausführungs-/Trustvoraussetzungen und SELECT auf toolbelt_filesystem.FileSystemRoot im tatsächlichen SQL-Kontext. Direkter Aufruf ist keine Rechteabkürzung. Caller: Windows-Authentifizierung und NTFS-Rechte der erfassten Windowsidentität. ServiceAccount: Mitgliedschaft in dbo-eigener Datenbankrolle toolbelt_filesystem_service_account, AllowServiceAccount am Root und NTFS-Rechte des SQL-Dienstkontos. Keine automatische Rechtevergabe oder Identitätsumschaltung.
--
-- ## Ressourcenbedarf
--
-- 32768-Zeichen-Puffer und Encoding-Ausgabepuffer; abschnittsweises SqlChars-Lesen, kein verpflichtendes vollständiges LOB-Materialisieren. Keine eigene kleine Gesamtdateiquote. Encoding.GetBytes wird je Chunk separat aufgerufen; keine Zusage beliebiger über Puffergrenzen verteilter Surrogatpaare oder zustandsbehafteter Encodings.
--
-- ## Nebenwirkungen
--
-- Staging und nativer Publish wie WriteBinaryFile. WriteBom fügt gegebenenfalls die Encodingpräambel hinzu; keine automatische Entfernung einer bereits im Content enthaltenen Präambel. Dateiänderungen sind nicht SQL-transaktional.
--
-- ## Fehlerbehandlung
--
-- Providerfehler werden als .NET-Ausnahmen mit TBXFS:-Codes beziehungsweise als SQL-CLR-Enginefehler sichtbar; unter anderem RootAliasRequired, RootNotAuthorized, InvalidExecutionIdentity, CallerWindowsAuthenticationRequired, ServiceAccountNotAuthorized, InvalidPath/PathOutsideRoot und native Handlefehler. Operationabhängig zusätzlich InvalidChunkRange, OffsetBeyondEnd, InvalidListLimit, EntryLimitExceeded, DepthLimitExceeded, EncodingRequired/UnsupportedEncoding, ContentRequired. Reparse Points und Hardlinks werden im nativen Prüfpfad abgewiesen; keine Fallbackoperation nach Fehler. Betriebssystem-/Encodingausnahmen können zusätzlich auftreten. Fehlertexte und Dateiresultate können vertrauliche Informationen enthalten und gehören nicht in öffentliche Logs.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter Vertrag der aktuellen SQL-/C#-Implementierung, kein neuer nativer Funktions-, Rechte-, Race- oder Hilfe-Gesamtnachweis. Raw CLR hat keine vollständige Facadevalidierung und noch keine eigene Skillhilfe. Aus einer vorhandenen Skillzeile folgen weder Installation noch ausreichende Rechte. Dateiaktionen sind außerhalb SQL-Transaktionsrollback; keine automatische Infrastruktur-/Root-/Trustreparatur.
-- OBJECT_USAGE_SKILL:END
AS EXTERNAL NAME [tlblt_Filesystem_Windows].[Toolbelt.Filesystem.Windows.WindowsFilesystemProvider].[WriteTextFile];
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[CLR_TranscodeTextFile]
(
    @SourceRootAlias sysname = NULL
  , @SourceRelativePath nvarchar(4000) = NULL
  , @SourceEncodingName nvarchar(128) = NULL
  , @TargetRootAlias sysname = NULL
  , @TargetRelativePath nvarchar(4000) = NULL
  , @TargetEncodingName nvarchar(128) = NULL
  , @WriteBom bit = 0
  , @Overwrite bit = 0
  , @ExecutionIdentity nvarchar(16) = N'Caller'
)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-fs-clr-transcode-text-file"
-- description: "Interner Windows-CLR-Provider zum gestreamten Umcodieren zwischen zwei autorisierten Dateipfaden."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.filesystem.windows"
-- schema_name: "toolbelt_filesystem"
-- object_name: "CLR_TranscodeTextFile"
-- object_type: "CLR_USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@SourceRootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Aktiver Quell-Rootalias mit AllowRead; NULL/leer unzulässig. Kein physischer Pfad."}, {"name": "@SourceRelativePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Nichtleerer relativer Quelldateipfad innerhalb des Quellroots; NULL, absolute Pfade, Doppelpunkt und Rootausbruch unzulässig."}, {"name": "@SourceEncodingName", "sql_type": "nvarchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Expliziter unterstützter .NET-Quellencodingname. NULL/leer/unbekannt unzulässig. StreamReader verwendet detectEncodingFromByteOrderMarks=false; kein automatischer Encodingwechsel anhand der BOM."}, {"name": "@TargetRootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Aktiver Ziel-Rootalias mit AllowWrite; NULL/leer unzulässig. Kein physischer Pfad."}, {"name": "@TargetRelativePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Nichtleerer relativer Zieldateipfad innerhalb des Zielroots; NULL, absolute Pfade, Doppelpunkt und Rootausbruch unzulässig."}, {"name": "@TargetEncodingName", "sql_type": "nvarchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Expliziter unterstützter .NET-Zielencodingname. NULL/leer/unbekannt unzulässig. Strikte Encoderfehler statt Ersatzzeichen; WriteBom steuert die zusätzliche Präambel."}, {"name": "@WriteBom", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "bit, Default 0: keine zusätzliche Präambel schreiben. 1 schreibt GetPreamble() des gewählten Ausgabeencodings, falls dieses eine besitzt. Keine Garantie einer BOM für jedes Encoding. NULL ist für CLR-bool nicht unterstützt."}, {"name": "@Overwrite", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "bit, Default 0: bestehendes Ziel nicht ersetzen. 1 erlaubt das Ersetzen durch den nativen Publishpfad; vorhandene Ziel-DACL wird übernommen. NULL ist für CLR-bool nicht unterstützt. Keine automatische Verzeichnisanlage."}, {"name": "@ExecutionIdentity", "sql_type": "nvarchar(16)", "sql_default": "N'Caller'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback."}]
-- source_paths: ["Modules/toolbelt.filesystem.windows/Source/Procedures.sql", "Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_filesystem.USP_TranscodeTextFile"]
-- ---
--
-- # CLR_TranscodeTextFile
--
-- ## Zweck und Einsatzfälle
--
-- Interner Windows-CLR-Provider zum gestreamten Umcodieren zwischen zwei autorisierten Dateipfaden. Internes Implementierungsdetail. Regulär die öffentliche USP_TranscodeTextFile mit frühem Hilfe-, Validierungs- und ResultTable-Vertrag verwenden; keine Empfehlung, die Facade zu umgehen.
--
-- ## Voraussetzungen
--
-- Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowRead und AllowWrite erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@SourceRootAlias` | `sysname` | `NULL` | Aktiver Quell-Rootalias mit AllowRead; NULL/leer unzulässig. Kein physischer Pfad. |
-- | `@SourceRelativePath` | `nvarchar(4000)` | `NULL` | Nichtleerer relativer Quelldateipfad innerhalb des Quellroots; NULL, absolute Pfade, Doppelpunkt und Rootausbruch unzulässig. |
-- | `@SourceEncodingName` | `nvarchar(128)` | `NULL` | Expliziter unterstützter .NET-Quellencodingname. NULL/leer/unbekannt unzulässig. StreamReader verwendet detectEncodingFromByteOrderMarks=false; kein automatischer Encodingwechsel anhand der BOM. |
-- | `@TargetRootAlias` | `sysname` | `NULL` | Aktiver Ziel-Rootalias mit AllowWrite; NULL/leer unzulässig. Kein physischer Pfad. |
-- | `@TargetRelativePath` | `nvarchar(4000)` | `NULL` | Nichtleerer relativer Zieldateipfad innerhalb des Zielroots; NULL, absolute Pfade, Doppelpunkt und Rootausbruch unzulässig. |
-- | `@TargetEncodingName` | `nvarchar(128)` | `NULL` | Expliziter unterstützter .NET-Zielencodingname. NULL/leer/unbekannt unzulässig. Strikte Encoderfehler statt Ersatzzeichen; WriteBom steuert die zusätzliche Präambel. |
-- | `@WriteBom` | `bit` | `0` | bit, Default 0: keine zusätzliche Präambel schreiben. 1 schreibt GetPreamble() des gewählten Ausgabeencodings, falls dieses eine besitzt. Keine Garantie einer BOM für jedes Encoding. NULL ist für CLR-bool nicht unterstützt. |
-- | `@Overwrite` | `bit` | `0` | bit, Default 0: bestehendes Ziel nicht ersetzen. 1 erlaubt das Ersetzen durch den nativen Publishpfad; vorhandene Ziel-DACL wird übernommen. NULL ist für CLR-bool nicht unterstützt. Keine automatische Verzeichnisanlage. |
-- | `@ExecutionIdentity` | `nvarchar(16)` | `N'Caller'` | Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback. |
--
-- ## Ergebnisse
--
-- Eine Erfolgszeile: BytesWritten bigint, RootAlias nvarchar(128) und RelativePath nvarchar(4000) des Ziels, State varchar(16)=completed. BytesWritten zählt Ausgabepräambel und encodierte Daten. Keine OUTPUT-Parameter. Aktueller raw CLR-Einstieg besitzt noch keinen @Hilfe-Parameter; seine Erweiterung ist eine getrennte offene Implementierung. Er bietet weder den zwölfspaltigen Facade-Hilfetext noch ResultTable/KeepData/Debug.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Synthetisches Beispiel: nur mit eigener passender Rootkonfiguration ausführen.
-- -- Regulärer öffentlicher Einstieg für diese Operation:
-- EXEC toolbelt_filesystem.USP_TranscodeTextFile @Hilfe=1;
-- -- Direkter interner Fachaufruf, nicht auf fremde Pfade anwenden:
-- EXEC toolbelt_filesystem.CLR_TranscodeTextFile @SourceRootAlias=N'ContosoRead',@SourceRelativePath=N'input.txt',@SourceEncodingName=N'utf-8',@TargetRootAlias=N'ContosoWrite',@TargetRelativePath=N'output.txt',@TargetEncodingName=N'utf-16';
-- ```
--
-- ## Rechte
--
-- Vorhandene EXECUTE-Rechte auf den internen Einstieg, CLR-Ausführungs-/Trustvoraussetzungen und SELECT auf toolbelt_filesystem.FileSystemRoot im tatsächlichen SQL-Kontext. Direkter Aufruf ist keine Rechteabkürzung. Caller: Windows-Authentifizierung und NTFS-Rechte der erfassten Windowsidentität. ServiceAccount: Mitgliedschaft in dbo-eigener Datenbankrolle toolbelt_filesystem_service_account, AllowServiceAccount am Root und NTFS-Rechte des SQL-Dienstkontos. Keine automatische Rechtevergabe oder Identitätsumschaltung.
--
-- ## Ressourcenbedarf
--
-- StreamReader und 32768-Zeichen-Blöcke mit Encoding-Ausgabepuffer; keine feste kleine Gesamtdateiquote. Je Block getrennte GetBytes-Aufrufe, daher keine pauschale Zusage über zustandsbehaftete Encodings oder Surrogatpaare an Blockgrenzen.
--
-- ## Nebenwirkungen
--
-- Liest Quellfile und publiziert Ziel über Staging. Keine automatische Verzeichnisanlage oder SQL-Rollback-Garantie. Eingangs-BOM bewirkt keinen automatischen Encodingwechsel; WriteBom steuert nur die zusätzliche Ausgabepräambel.
--
-- ## Fehlerbehandlung
--
-- Providerfehler werden als .NET-Ausnahmen mit TBXFS:-Codes beziehungsweise als SQL-CLR-Enginefehler sichtbar; unter anderem RootAliasRequired, RootNotAuthorized, InvalidExecutionIdentity, CallerWindowsAuthenticationRequired, ServiceAccountNotAuthorized, InvalidPath/PathOutsideRoot und native Handlefehler. Operationabhängig zusätzlich InvalidChunkRange, OffsetBeyondEnd, InvalidListLimit, EntryLimitExceeded, DepthLimitExceeded, EncodingRequired/UnsupportedEncoding, ContentRequired. Reparse Points und Hardlinks werden im nativen Prüfpfad abgewiesen; keine Fallbackoperation nach Fehler. Betriebssystem-/Encodingausnahmen können zusätzlich auftreten. Fehlertexte und Dateiresultate können vertrauliche Informationen enthalten und gehören nicht in öffentliche Logs.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter Vertrag der aktuellen SQL-/C#-Implementierung, kein neuer nativer Funktions-, Rechte-, Race- oder Hilfe-Gesamtnachweis. Raw CLR hat keine vollständige Facadevalidierung und noch keine eigene Skillhilfe. Aus einer vorhandenen Skillzeile folgen weder Installation noch ausreichende Rechte. Dateiaktionen sind außerhalb SQL-Transaktionsrollback; keine automatische Infrastruktur-/Root-/Trustreparatur.
-- OBJECT_USAGE_SKILL:END
AS EXTERNAL NAME [tlblt_Filesystem_Windows].[Toolbelt.Filesystem.Windows.WindowsFilesystemProvider].[TranscodeTextFile];
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[CLR_ListDirectory]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = N''
  , @Recursive bit = 0
  , @MaxDepth int = 32
  , @MaxEntries int = 10000
  , @ExecutionIdentity nvarchar(16) = N'Caller'
)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-fs-clr-list-directory"
-- description: "Interner Windows-CLR-Provider zum begrenzten Auflisten von Dateien und Verzeichnissen."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.filesystem.windows"
-- schema_name: "toolbelt_filesystem"
-- object_name: "CLR_ListDirectory"
-- object_type: "CLR_USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@RootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein."}, {"name": "@RelativePath", "sql_type": "nvarchar(4000)", "sql_default": "N''", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich."}, {"name": "@Recursive", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "bit, Default 0: nur direktes Verzeichnis. 1 traversiert Unterverzeichnisse innerhalb der expliziten Grenzen. NULL ist für CLR-bool nicht unterstützt."}, {"name": "@MaxDepth", "sql_type": "int", "sql_default": "32", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Startverzeichnis hat Tiefe 0. Listing akzeptiert 0..64, Entfernung nur die Untergrenze 0 ohne eigene feste Obergrenze. Rekursiv nötiger Abstieg jenseits der Grenze ist ein Fehler, keine stille Kürzung. Default 32; NULL ist für CLR-int nicht unterstützt."}, {"name": "@MaxEntries", "sql_type": "int", "sql_default": "10000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Default 10000. Listing akzeptiert 1..10000; Entfernung prüft nur >=1 ohne eigene feste Obergrenze. Überschreitung ist ein Fehler, keine gekürzte Erfolgsmenge. NULL ist für CLR-int nicht unterstützt."}, {"name": "@ExecutionIdentity", "sql_type": "nvarchar(16)", "sql_default": "N'Caller'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback."}]
-- source_paths: ["Modules/toolbelt.filesystem.windows/Source/Procedures.sql", "Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_filesystem.USP_ListDirectory"]
-- ---
--
-- # CLR_ListDirectory
--
-- ## Zweck und Einsatzfälle
--
-- Interner Windows-CLR-Provider zum begrenzten Auflisten von Dateien und Verzeichnissen. Internes Implementierungsdetail. Regulär die öffentliche USP_ListDirectory mit frühem Hilfe-, Validierungs- und ResultTable-Vertrag verwenden; keine Empfehlung, die Facade zu umgehen.
--
-- ## Voraussetzungen
--
-- Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowList erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@RootAlias` | `sysname` | `NULL` | Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein. |
-- | `@RelativePath` | `nvarchar(4000)` | `N''` | Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich. |
-- | `@Recursive` | `bit` | `0` | bit, Default 0: nur direktes Verzeichnis. 1 traversiert Unterverzeichnisse innerhalb der expliziten Grenzen. NULL ist für CLR-bool nicht unterstützt. |
-- | `@MaxDepth` | `int` | `32` | Startverzeichnis hat Tiefe 0. Listing akzeptiert 0..64, Entfernung nur die Untergrenze 0 ohne eigene feste Obergrenze. Rekursiv nötiger Abstieg jenseits der Grenze ist ein Fehler, keine stille Kürzung. Default 32; NULL ist für CLR-int nicht unterstützt. |
-- | `@MaxEntries` | `int` | `10000` | Default 10000. Listing akzeptiert 1..10000; Entfernung prüft nur >=1 ohne eigene feste Obergrenze. Überschreitung ist ein Fehler, keine gekürzte Erfolgsmenge. NULL ist für CLR-int nicht unterstützt. |
-- | `@ExecutionIdentity` | `nvarchar(16)` | `N'Caller'` | Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback. |
--
-- ## Ergebnisse
--
-- Null bis MaxEntries Zeilen: EntryOrdinal bigint ab 1, RelativePath nvarchar(4000) relativ zum Root, EntryType varchar(16) file oder directory, SizeBytes bigint (Verzeichnis 0), LastWriteTimeUtc datetime2, IsReparsePoint bit. Keine zugesicherte alphabetische Sortierung oder stabile Reihenfolge zwischen Aufrufen. Keine OUTPUT-Parameter. Aktueller raw CLR-Einstieg besitzt noch keinen @Hilfe-Parameter; seine Erweiterung ist eine getrennte offene Implementierung. Er bietet weder den zwölfspaltigen Facade-Hilfetext noch ResultTable/KeepData/Debug.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Synthetisches Beispiel: nur mit eigener passender Rootkonfiguration ausführen.
-- -- Regulärer öffentlicher Einstieg für diese Operation:
-- EXEC toolbelt_filesystem.USP_ListDirectory @Hilfe=1;
-- -- Direkter interner Fachaufruf, nicht auf fremde Pfade anwenden:
-- EXEC toolbelt_filesystem.CLR_ListDirectory @RootAlias=N'ContosoRead',@RelativePath=N'',@Recursive=0,@MaxEntries=100;
-- ```
--
-- ## Rechte
--
-- Vorhandene EXECUTE-Rechte auf den internen Einstieg, CLR-Ausführungs-/Trustvoraussetzungen und SELECT auf toolbelt_filesystem.FileSystemRoot im tatsächlichen SQL-Kontext. Direkter Aufruf ist keine Rechteabkürzung. Caller: Windows-Authentifizierung und NTFS-Rechte der erfassten Windowsidentität. ServiceAccount: Mitgliedschaft in dbo-eigener Datenbankrolle toolbelt_filesystem_service_account, AllowServiceAccount am Root und NTFS-Rechte des SQL-Dienstkontos. Keine automatische Rechtevergabe oder Identitätsumschaltung.
--
-- ## Ressourcenbedarf
--
-- Sammelt die vollständige begrenzte Liste vor SendResultsStart. Höchstens 10000 Einträge und 16 MiB aufsummierter relativer UTF-16-Pfadtext. Rekursionsgrenze 64; Verzeichnisqueue und native Handles zusätzlich. Limitüberschreitung liefert keinen gekürzten Erfolg.
--
-- ## Nebenwirkungen
--
-- Nur lesende Verzeichnis-/Dateimetadatenabfragen. Kein Snapshot; parallele Dateisystemänderungen können Fehler oder abweichende Metadaten verursachen. Ausgabefehler nach SendResultsStart können bereits gesendete Zeilen nicht zurücknehmen.
--
-- ## Fehlerbehandlung
--
-- Providerfehler werden als .NET-Ausnahmen mit TBXFS:-Codes beziehungsweise als SQL-CLR-Enginefehler sichtbar; unter anderem RootAliasRequired, RootNotAuthorized, InvalidExecutionIdentity, CallerWindowsAuthenticationRequired, ServiceAccountNotAuthorized, InvalidPath/PathOutsideRoot und native Handlefehler. Operationabhängig zusätzlich InvalidChunkRange, OffsetBeyondEnd, InvalidListLimit, EntryLimitExceeded, DepthLimitExceeded, EncodingRequired/UnsupportedEncoding, ContentRequired. Reparse Points und Hardlinks werden im nativen Prüfpfad abgewiesen; keine Fallbackoperation nach Fehler. Betriebssystem-/Encodingausnahmen können zusätzlich auftreten. Fehlertexte und Dateiresultate können vertrauliche Informationen enthalten und gehören nicht in öffentliche Logs.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter Vertrag der aktuellen SQL-/C#-Implementierung, kein neuer nativer Funktions-, Rechte-, Race- oder Hilfe-Gesamtnachweis. Raw CLR hat keine vollständige Facadevalidierung und noch keine eigene Skillhilfe. Aus einer vorhandenen Skillzeile folgen weder Installation noch ausreichende Rechte. Dateiaktionen sind außerhalb SQL-Transaktionsrollback; keine automatische Infrastruktur-/Root-/Trustreparatur.
-- OBJECT_USAGE_SKILL:END
AS EXTERNAL NAME [tlblt_Filesystem_Windows].[Toolbelt.Filesystem.Windows.WindowsFilesystemProvider].[ListDirectory];
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[CLR_CreateDirectory]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @ExecutionIdentity nvarchar(16) = N'Caller'
)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-fs-clr-create-directory"
-- description: "Interner Windows-CLR-Provider zum Anlegen autorisierter relativer Verzeichnisse."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.filesystem.windows"
-- schema_name: "toolbelt_filesystem"
-- object_name: "CLR_CreateDirectory"
-- object_type: "CLR_USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@RootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein."}, {"name": "@RelativePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich."}, {"name": "@ExecutionIdentity", "sql_type": "nvarchar(16)", "sql_default": "N'Caller'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback."}]
-- source_paths: ["Modules/toolbelt.filesystem.windows/Source/Procedures.sql", "Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_filesystem.USP_CreateDirectory"]
-- ---
--
-- # CLR_CreateDirectory
--
-- ## Zweck und Einsatzfälle
--
-- Interner Windows-CLR-Provider zum Anlegen autorisierter relativer Verzeichnisse. Internes Implementierungsdetail. Regulär die öffentliche USP_CreateDirectory mit frühem Hilfe-, Validierungs- und ResultTable-Vertrag verwenden; keine Empfehlung, die Facade zu umgehen.
--
-- ## Voraussetzungen
--
-- Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowCreateDirectory erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@RootAlias` | `sysname` | `NULL` | Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein. |
-- | `@RelativePath` | `nvarchar(4000)` | `NULL` | Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich. |
-- | `@ExecutionIdentity` | `nvarchar(16)` | `N'Caller'` | Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback. |
--
-- ## Ergebnisse
--
-- Eine Zeile: RootAlias nvarchar(128), RelativePath nvarchar(4000), State varchar(16)=created. created unterscheidet nicht zwischen bereits vorhandenem und neu angelegtem Verzeichnis. Keine OUTPUT-Parameter. Aktueller raw CLR-Einstieg besitzt noch keinen @Hilfe-Parameter; seine Erweiterung ist eine getrennte offene Implementierung. Er bietet weder den zwölfspaltigen Facade-Hilfetext noch ResultTable/KeepData/Debug.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Synthetisches Beispiel: nur mit eigener passender Rootkonfiguration ausführen.
-- -- Regulärer öffentlicher Einstieg für diese Operation:
-- EXEC toolbelt_filesystem.USP_CreateDirectory @Hilfe=1;
-- -- Direkter interner Fachaufruf, nicht auf fremde Pfade anwenden:
-- EXEC toolbelt_filesystem.CLR_CreateDirectory @RootAlias=N'ContosoWrite',@RelativePath=N'output';
-- ```
--
-- ## Rechte
--
-- Vorhandene EXECUTE-Rechte auf den internen Einstieg, CLR-Ausführungs-/Trustvoraussetzungen und SELECT auf toolbelt_filesystem.FileSystemRoot im tatsächlichen SQL-Kontext. Direkter Aufruf ist keine Rechteabkürzung. Caller: Windows-Authentifizierung und NTFS-Rechte der erfassten Windowsidentität. ServiceAccount: Mitgliedschaft in dbo-eigener Datenbankrolle toolbelt_filesystem_service_account, AllowServiceAccount am Root und NTFS-Rechte des SQL-Dienstkontos. Keine automatische Rechtevergabe oder Identitätsumschaltung.
--
-- ## Ressourcenbedarf
--
-- Parenthandles proportional zur Anzahl der Pfadkomponenten. Keine eigene feste Komponentenquote; Pfad-/Betriebssystemgrenzen gelten.
--
-- ## Nebenwirkungen
--
-- Legt fehlende Komponenten des konfigurierten Zielpfads an. Die physische Rootkonfiguration muss deshalb von einer autorisierten Verwaltung stammen; sie wird hier nicht angelegt oder geändert. Leerer relativer Pfad wählt den Root; auch NativeParents(create=true) muss im vorgesehenen autorisierten Kontext laufen. Bei späterem Fehler können bereits angelegte Komponenten bestehen bleiben. Kein SQL-ROLLBACK für Dateioperationen.
--
-- ## Fehlerbehandlung
--
-- Providerfehler werden als .NET-Ausnahmen mit TBXFS:-Codes beziehungsweise als SQL-CLR-Enginefehler sichtbar; unter anderem RootAliasRequired, RootNotAuthorized, InvalidExecutionIdentity, CallerWindowsAuthenticationRequired, ServiceAccountNotAuthorized, InvalidPath/PathOutsideRoot und native Handlefehler. Operationabhängig zusätzlich InvalidChunkRange, OffsetBeyondEnd, InvalidListLimit, EntryLimitExceeded, DepthLimitExceeded, EncodingRequired/UnsupportedEncoding, ContentRequired. Reparse Points und Hardlinks werden im nativen Prüfpfad abgewiesen; keine Fallbackoperation nach Fehler. Betriebssystem-/Encodingausnahmen können zusätzlich auftreten. Fehlertexte und Dateiresultate können vertrauliche Informationen enthalten und gehören nicht in öffentliche Logs.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter Vertrag der aktuellen SQL-/C#-Implementierung, kein neuer nativer Funktions-, Rechte-, Race- oder Hilfe-Gesamtnachweis. Raw CLR hat keine vollständige Facadevalidierung und noch keine eigene Skillhilfe. Aus einer vorhandenen Skillzeile folgen weder Installation noch ausreichende Rechte. Dateiaktionen sind außerhalb SQL-Transaktionsrollback; keine automatische Infrastruktur-/Root-/Trustreparatur.
-- OBJECT_USAGE_SKILL:END
AS EXTERNAL NAME [tlblt_Filesystem_Windows].[Toolbelt.Filesystem.Windows.WindowsFilesystemProvider].[CreateDirectory];
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[CLR_RemoveFile]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @ExecutionIdentity nvarchar(16) = N'Caller'
)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-fs-clr-remove-file"
-- description: "Interner Windows-CLR-Provider zum Löschen einer autorisierten relativen Datei."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.filesystem.windows"
-- schema_name: "toolbelt_filesystem"
-- object_name: "CLR_RemoveFile"
-- object_type: "CLR_USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@RootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein."}, {"name": "@RelativePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich."}, {"name": "@ExecutionIdentity", "sql_type": "nvarchar(16)", "sql_default": "N'Caller'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback."}]
-- source_paths: ["Modules/toolbelt.filesystem.windows/Source/Procedures.sql", "Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_filesystem.USP_RemoveFile"]
-- ---
--
-- # CLR_RemoveFile
--
-- ## Zweck und Einsatzfälle
--
-- Interner Windows-CLR-Provider zum Löschen einer autorisierten relativen Datei. Internes Implementierungsdetail. Regulär die öffentliche USP_RemoveFile mit frühem Hilfe-, Validierungs- und ResultTable-Vertrag verwenden; keine Empfehlung, die Facade zu umgehen.
--
-- ## Voraussetzungen
--
-- Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowDelete erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@RootAlias` | `sysname` | `NULL` | Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein. |
-- | `@RelativePath` | `nvarchar(4000)` | `NULL` | Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich. |
-- | `@ExecutionIdentity` | `nvarchar(16)` | `N'Caller'` | Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback. |
--
-- ## Ergebnisse
--
-- Eine Zeile: RootAlias nvarchar(128), RelativePath nvarchar(4000), State varchar(16)=removed. Keine OUTPUT-Parameter. Fehlendes Ziel wird nicht als erfolgreicher No-op behandelt. Aktueller raw CLR-Einstieg besitzt noch keinen @Hilfe-Parameter; seine Erweiterung ist eine getrennte offene Implementierung. Er bietet weder den zwölfspaltigen Facade-Hilfetext noch ResultTable/KeepData/Debug.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Synthetisches Beispiel: nur mit eigener passender Rootkonfiguration ausführen.
-- -- Regulärer öffentlicher Einstieg für diese Operation:
-- EXEC toolbelt_filesystem.USP_RemoveFile @Hilfe=1;
-- -- Direkter interner Fachaufruf, nicht auf fremde Pfade anwenden:
-- EXEC toolbelt_filesystem.CLR_RemoveFile @RootAlias=N'ContosoWrite',@RelativePath=N'obsolete.bin';
-- ```
--
-- ## Rechte
--
-- Vorhandene EXECUTE-Rechte auf den internen Einstieg, CLR-Ausführungs-/Trustvoraussetzungen und SELECT auf toolbelt_filesystem.FileSystemRoot im tatsächlichen SQL-Kontext. Direkter Aufruf ist keine Rechteabkürzung. Caller: Windows-Authentifizierung und NTFS-Rechte der erfassten Windowsidentität. ServiceAccount: Mitgliedschaft in dbo-eigener Datenbankrolle toolbelt_filesystem_service_account, AllowServiceAccount am Root und NTFS-Rechte des SQL-Dienstkontos. Keine automatische Rechtevergabe oder Identitätsumschaltung.
--
-- ## Ressourcenbedarf
--
-- Native Parent-/Dateihandles; keine vollständige Dateiinhaltsmaterialisierung.
--
-- ## Nebenwirkungen
--
-- Markiert das exakt gebundene Dateiobjekt über einen nativen Handle zum Löschen. Kein Papierkorb und keine SQL-ROLLBACK-Wiederherstellung. Fehlende Datei oder ungeeigneter Dateityp führt zum Fehler.
--
-- ## Fehlerbehandlung
--
-- Providerfehler werden als .NET-Ausnahmen mit TBXFS:-Codes beziehungsweise als SQL-CLR-Enginefehler sichtbar; unter anderem RootAliasRequired, RootNotAuthorized, InvalidExecutionIdentity, CallerWindowsAuthenticationRequired, ServiceAccountNotAuthorized, InvalidPath/PathOutsideRoot und native Handlefehler. Operationabhängig zusätzlich InvalidChunkRange, OffsetBeyondEnd, InvalidListLimit, EntryLimitExceeded, DepthLimitExceeded, EncodingRequired/UnsupportedEncoding, ContentRequired. Reparse Points und Hardlinks werden im nativen Prüfpfad abgewiesen; keine Fallbackoperation nach Fehler. Betriebssystem-/Encodingausnahmen können zusätzlich auftreten. Fehlertexte und Dateiresultate können vertrauliche Informationen enthalten und gehören nicht in öffentliche Logs.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter Vertrag der aktuellen SQL-/C#-Implementierung, kein neuer nativer Funktions-, Rechte-, Race- oder Hilfe-Gesamtnachweis. Raw CLR hat keine vollständige Facadevalidierung und noch keine eigene Skillhilfe. Aus einer vorhandenen Skillzeile folgen weder Installation noch ausreichende Rechte. Dateiaktionen sind außerhalb SQL-Transaktionsrollback; keine automatische Infrastruktur-/Root-/Trustreparatur.
-- OBJECT_USAGE_SKILL:END
AS EXTERNAL NAME [tlblt_Filesystem_Windows].[Toolbelt.Filesystem.Windows.WindowsFilesystemProvider].[RemoveFile];
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[CLR_RemoveDirectory]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @Recursive bit = 0
  , @MaxDepth int = 32
  , @MaxEntries int = 10000
  , @ExecutionIdentity nvarchar(16) = N'Caller'
)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-fs-clr-remove-directory"
-- description: "Interner Windows-CLR-Provider zum geplanten begrenzten Löschen eines relativen Verzeichnisses."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.filesystem.windows"
-- schema_name: "toolbelt_filesystem"
-- object_name: "CLR_RemoveDirectory"
-- object_type: "CLR_USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@RootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein."}, {"name": "@RelativePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich."}, {"name": "@Recursive", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "bit, Default 0: nur direktes Verzeichnis. 1 traversiert Unterverzeichnisse innerhalb der expliziten Grenzen. NULL ist für CLR-bool nicht unterstützt."}, {"name": "@MaxDepth", "sql_type": "int", "sql_default": "32", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Startverzeichnis hat Tiefe 0. Listing akzeptiert 0..64, Entfernung nur die Untergrenze 0 ohne eigene feste Obergrenze. Rekursiv nötiger Abstieg jenseits der Grenze ist ein Fehler, keine stille Kürzung. Default 32; NULL ist für CLR-int nicht unterstützt."}, {"name": "@MaxEntries", "sql_type": "int", "sql_default": "10000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Default 10000. Listing akzeptiert 1..10000; Entfernung prüft nur >=1 ohne eigene feste Obergrenze. Überschreitung ist ein Fehler, keine gekürzte Erfolgsmenge. NULL ist für CLR-int nicht unterstützt."}, {"name": "@ExecutionIdentity", "sql_type": "nvarchar(16)", "sql_default": "N'Caller'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback."}]
-- source_paths: ["Modules/toolbelt.filesystem.windows/Source/Procedures.sql", "Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_filesystem.USP_RemoveDirectory"]
-- ---
--
-- # CLR_RemoveDirectory
--
-- ## Zweck und Einsatzfälle
--
-- Interner Windows-CLR-Provider zum geplanten begrenzten Löschen eines relativen Verzeichnisses. Internes Implementierungsdetail. Regulär die öffentliche USP_RemoveDirectory mit frühem Hilfe-, Validierungs- und ResultTable-Vertrag verwenden; keine Empfehlung, die Facade zu umgehen.
--
-- ## Voraussetzungen
--
-- Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowDelete erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@RootAlias` | `sysname` | `NULL` | Konfigurierter aktiver Rootalias, kein physischer Pfad. NULL/leer ist fachlich unzulässig; die benötigte Operationsfreigabe muss in FileSystemRoot gesetzt sein. |
-- | `@RelativePath` | `nvarchar(4000)` | `NULL` | Relativer Pfad innerhalb des ausgewählten Roots, kein absoluter Pfad, Doppelpunkt oder Rootausbruch. NULL ist unzulässig. Leerer String ist nur bei ListDirectory und CreateDirectory als Rootauswahl zulässig; RemoveDirectory verbietet die Rootlöschung zusätzlich. |
-- | `@Recursive` | `bit` | `0` | bit, Default 0: nur direktes Verzeichnis. 1 traversiert Unterverzeichnisse innerhalb der expliziten Grenzen. NULL ist für CLR-bool nicht unterstützt. |
-- | `@MaxDepth` | `int` | `32` | Startverzeichnis hat Tiefe 0. Listing akzeptiert 0..64, Entfernung nur die Untergrenze 0 ohne eigene feste Obergrenze. Rekursiv nötiger Abstieg jenseits der Grenze ist ein Fehler, keine stille Kürzung. Default 32; NULL ist für CLR-int nicht unterstützt. |
-- | `@MaxEntries` | `int` | `10000` | Default 10000. Listing akzeptiert 1..10000; Entfernung prüft nur >=1 ohne eigene feste Obergrenze. Überschreitung ist ein Fehler, keine gekürzte Erfolgsmenge. NULL ist für CLR-int nicht unterstützt. |
-- | `@ExecutionIdentity` | `nvarchar(16)` | `N'Caller'` | Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback. |
--
-- ## Ergebnisse
--
-- Eine Zeile nach erfolgreicher Entfernung: RootAlias nvarchar(128), RelativePath nvarchar(4000), State varchar(16)=removed. Keine OUTPUT-Parameter. Keine Ausgabe einer Löschliste. Aktueller raw CLR-Einstieg besitzt noch keinen @Hilfe-Parameter; seine Erweiterung ist eine getrennte offene Implementierung. Er bietet weder den zwölfspaltigen Facade-Hilfetext noch ResultTable/KeepData/Debug.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Synthetisches Beispiel: nur mit eigener passender Rootkonfiguration ausführen.
-- -- Regulärer öffentlicher Einstieg für diese Operation:
-- EXEC toolbelt_filesystem.USP_RemoveDirectory @Hilfe=1;
-- -- Direkter interner Fachaufruf, nicht auf fremde Pfade anwenden:
-- EXEC toolbelt_filesystem.CLR_RemoveDirectory @RootAlias=N'ContosoWrite',@RelativePath=N'obsolete',@Recursive=0;
-- ```
--
-- ## Rechte
--
-- Vorhandene EXECUTE-Rechte auf den internen Einstieg, CLR-Ausführungs-/Trustvoraussetzungen und SELECT auf toolbelt_filesystem.FileSystemRoot im tatsächlichen SQL-Kontext. Direkter Aufruf ist keine Rechteabkürzung. Caller: Windows-Authentifizierung und NTFS-Rechte der erfassten Windowsidentität. ServiceAccount: Mitgliedschaft in dbo-eigener Datenbankrolle toolbelt_filesystem_service_account, AllowServiceAccount am Root und NTFS-Rechte des SQL-Dienstkontos. Keine automatische Rechtevergabe oder Identitätsumschaltung.
--
-- ## Ressourcenbedarf
--
-- Vollständiger Löschplan mit offenen nativen Handles vor erster Löschung, proportional zur akzeptierten Eintragszahl. Der raw CLR-Einstieg prüft für MaxEntries nur >=1 und MaxDepth nur >=0; die Obergrenzen des Listingpfads gelten nicht für die Entfernung. Anzahlgrenze zählt Kinder, nicht das Startverzeichnis.
--
-- ## Nebenwirkungen
--
-- Recursive=0 verlangt ein leeres Verzeichnis; Recursive=1 entfernt geplante Kinder rückwärts und danach den Start. Rootlöschung ist verboten. Preflightfehler führen vor Mutation zum Abbruch; Fehler während nativer Löschung können eine Teilentfernung hinterlassen. Kein SQL-Rollback und keine pauschale Garantie gegen alle konkurrierenden Dateisystemänderungen.
--
-- ## Fehlerbehandlung
--
-- Providerfehler werden als .NET-Ausnahmen mit TBXFS:-Codes beziehungsweise als SQL-CLR-Enginefehler sichtbar; unter anderem RootAliasRequired, RootNotAuthorized, InvalidExecutionIdentity, CallerWindowsAuthenticationRequired, ServiceAccountNotAuthorized, InvalidPath/PathOutsideRoot und native Handlefehler. Operationabhängig zusätzlich InvalidChunkRange, OffsetBeyondEnd, InvalidListLimit, EntryLimitExceeded, DepthLimitExceeded, EncodingRequired/UnsupportedEncoding, ContentRequired. Reparse Points und Hardlinks werden im nativen Prüfpfad abgewiesen; keine Fallbackoperation nach Fehler. Betriebssystem-/Encodingausnahmen können zusätzlich auftreten. Fehlertexte und Dateiresultate können vertrauliche Informationen enthalten und gehören nicht in öffentliche Logs.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter Vertrag der aktuellen SQL-/C#-Implementierung, kein neuer nativer Funktions-, Rechte-, Race- oder Hilfe-Gesamtnachweis. Raw CLR hat keine vollständige Facadevalidierung und noch keine eigene Skillhilfe. Aus einer vorhandenen Skillzeile folgen weder Installation noch ausreichende Rechte. Dateiaktionen sind außerhalb SQL-Transaktionsrollback; keine automatische Infrastruktur-/Root-/Trustreparatur.
-- OBJECT_USAGE_SKILL:END
AS EXTERNAL NAME [tlblt_Filesystem_Windows].[Toolbelt.Filesystem.Windows.WindowsFilesystemProvider].[RemoveDirectory];
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_InternalEmitHelp]
      @ObjectName sysname
    , @Description nvarchar(max)
    , @ExampleSql nvarchar(max)
-- OBJECT_USAGE_SKILL_PARAMETER:BEGIN
    , @Hilfe bit = 0
-- OBJECT_USAGE_SKILL_PARAMETER:END
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-filesystem-internal-emit-help"
-- description: "Interner rein lesender Formatierer für die bisherige Dateisystem-Hilfe."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.filesystem.windows"
-- schema_name: "toolbelt_filesystem"
-- object_name: "USP_InternalEmitHelp"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@ObjectName", "sql_type": "sysname", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Bezeichnung des vom Caller beschriebenen Objekts als sysname; nur Ausgabedatum, keine Auflösung oder Ausführung. Kein SQL-Default; NULL wird nicht vorab zurückgewiesen."}, {"name": "@Description", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Vom Caller gelieferter Beschreibungstext als nvarchar(max), nur Ausgabe; kein SQL-Default. NULL ist möglich, kein fachlicher Default."}, {"name": "@ExampleSql", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Vom Caller gelieferter SQL-Beispieltext als nvarchar(max); wird nur als Datenfeld ausgegeben, niemals ausgeführt. Kein SQL-Default; NULL ist möglich."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler abschließender bit, Default 0. 1 liefert ausschließlich den eigenen vollständigen Skill und kehrt vor Tabellen-/Datei-/CLR-Zugriff zurück. 0 oder NULL führt den bisherigen Helferpfad aus. Bisherige Pflichtargumente bleiben auch beim Hilfeaufruf syntaktisch erforderlich."}]
-- source_paths: ["Modules/toolbelt.filesystem.windows/Source/Procedures.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_filesystem.USP_ReadBinaryFileChunk", "toolbelt_filesystem.USP_ListDirectory"]
-- ---
--
-- # USP_InternalEmitHelp
--
-- ## Zweck und Einsatzfälle
--
-- Interner rein lesender Formatierer für die bisherige Dateisystem-Hilfe. Internes Implementierungsdetail; Anwendungen verwenden die öffentlichen Dateisystem-Prozeduren mit deren vollständigem Autorisierungsvertrag.
--
-- ## Voraussetzungen
--
-- Dateisystem-Modul unterstützt Windows SQL Server 2019/2022/2025. Dieser Helfer ist reines T-SQL; sein eigener @Hilfe=1-Pfad benötigt weder eine Ergebnistabelle noch Rootkonfiguration, Windowsimpersonation oder einen CLR-/Dateiaufruf. Der Normalpfad formatiert nur vom Caller gelieferte Metadaten.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@ObjectName` | `sysname` | `kein Default` | Bezeichnung des vom Caller beschriebenen Objekts als sysname; nur Ausgabedatum, keine Auflösung oder Ausführung. Kein SQL-Default; NULL wird nicht vorab zurückgewiesen. |
-- | `@Description` | `nvarchar(max)` | `kein Default` | Vom Caller gelieferter Beschreibungstext als nvarchar(max), nur Ausgabe; kein SQL-Default. NULL ist möglich, kein fachlicher Default. |
-- | `@ExampleSql` | `nvarchar(max)` | `kein Default` | Vom Caller gelieferter SQL-Beispieltext als nvarchar(max); wird nur als Datenfeld ausgegeben, niemals ausgeführt. Kein SQL-Default; NULL ist möglich. |
-- | `@Hilfe` | `bit` | `0` | Optionaler abschließender bit, Default 0. 1 liefert ausschließlich den eigenen vollständigen Skill und kehrt vor Tabellen-/Datei-/CLR-Zugriff zurück. 0 oder NULL führt den bisherigen Helferpfad aus. Bisherige Pflichtargumente bleiben auch beim Hilfeaufruf syntaktisch erforderlich. |
--
-- ## Ergebnisse
--
-- Bei @Hilfe=1 genau eine konstante Skillzeile: SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max), RETURN 0. Normalpfad: bisheriges zwölfspaltiges Help-Resultset HelpContractVersion, SchemaName, ObjectName, Section, Ordinal, ItemName, SqlDataType, IsRequired, IsNullable, DefaultValue, Description, ExampleSql. Es enthält eine Beschreibung, fünf generische Steuerparameterzeilen und eine Einschränkungszeile; keine Behauptung vollständiger Parameterhilfe eines beliebigen Zielobjekts.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_filesystem.USP_InternalEmitHelp @ObjectName=NULL,@Description=NULL,@ExampleSql=NULL,@Hilfe=1;
-- -- Nur der eigene Skill; keine Dateisystemoperation.
-- ```
--
-- ## Rechte
--
-- Vorhandene EXECUTE-Rechte im autorisierten Modulpfad, keine automatische Rechtevergabe. Normale Routingoperationen benötigen vorhandene Temp-Tabellen und die Rechte des ResultTable-Vertrags. Hilfe vergibt keine Rechte und ersetzt keine Windows-/Root-/ServiceAccount-Freigabe öffentlicher Dateioperationen.
--
-- ## Ressourcenbedarf
--
-- Feste Anzahl von UNION-ALL-Hilfezeilen; Länge der Callerbeschreibung und des Beispieltexts ist nvarchar(max) und besitzt hier kein zusätzliches kleines Limit. Skillhilfe ist konstant, Unicode und ohne Runtime-Katalogabfrage.
--
-- ## Nebenwirkungen
--
-- Keine DML-/Datei-/Netzwerk-/Konfigurationsänderung; normales Hilfeformatieren gibt ausschließlich Daten aus. Neuer Hilfezweig führt nichts davon aus und verändert keine OUTPUT-Werte.
--
-- ## Fehlerbehandlung
--
-- Es gibt keine neuen fachlichen Fehlercodes. Fehlende Pflichtargumente, Objekt-/Ausführungsrechte, nicht vorhandene Caller-Temps und unerwartete Enginefehler bleiben Fehler. Beim Routing werden Fehler des ResultTable-Kerns unverändert weitergegeben; keine automatische Wiederholung oder Rechteausweitung.
--
-- ## Aussagegrenzen
--
-- Interner Helfer, keine öffentliche Datei- oder Berechtigungs-API. Frei gelieferter Beschreibungstext attestiert weder Existenz noch Rechte oder Sicherheit eines Zielobjekts. ExampleSql bleibt Daten, nicht ein auszuführender Auftrag. Native Akzeptanz des neuen Hilfezweigs ist separat offen; historische Fachbelege gelten nur für den unveränderten Normalpfad.
-- OBJECT_USAGE_SKILL:END
BEGIN
-- OBJECT_USAGE_SKILL_EARLY_HELP:BEGIN
    IF @Hilfe = 1
    BEGIN
        SET NOCOUNT ON;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_filesystem' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_InternalEmitHelp' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-filesystem-internal-emit-help"
description: "Interner rein lesender Formatierer für die bisherige Dateisystem-Hilfe."
skill_format_version: "1.0"
module_id: "toolbelt.filesystem.windows"
schema_name: "toolbelt_filesystem"
object_name: "USP_InternalEmitHelp"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@ObjectName", "sql_type": "sysname", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Bezeichnung des vom Caller beschriebenen Objekts als sysname; nur Ausgabedatum, keine Auflösung oder Ausführung. Kein SQL-Default; NULL wird nicht vorab zurückgewiesen."}, {"name": "@Description", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Vom Caller gelieferter Beschreibungstext als nvarchar(max), nur Ausgabe; kein SQL-Default. NULL ist möglich, kein fachlicher Default."}, {"name": "@ExampleSql", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Vom Caller gelieferter SQL-Beispieltext als nvarchar(max); wird nur als Datenfeld ausgegeben, niemals ausgeführt. Kein SQL-Default; NULL ist möglich."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler abschließender bit, Default 0. 1 liefert ausschließlich den eigenen vollständigen Skill und kehrt vor Tabellen-/Datei-/CLR-Zugriff zurück. 0 oder NULL führt den bisherigen Helferpfad aus. Bisherige Pflichtargumente bleiben auch beim Hilfeaufruf syntaktisch erforderlich."}]
source_paths: ["Modules/toolbelt.filesystem.windows/Source/Procedures.sql"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_filesystem.USP_ReadBina' AS nvarchar(max)) + N'ryFileChunk", "toolbelt_filesystem.USP_ListDirectory"]
---

# USP_InternalEmitHelp

## Zweck und Einsatzfälle

Interner rein lesender Formatierer für die bisherige Dateisystem-Hilfe. Internes Implementierungsdetail; Anwendungen verwenden die öffentlichen Dateisystem-Prozeduren mit deren vollständigem Autorisierungsvertrag.

## Voraussetzungen

Dateisystem-Modul unterstützt Windows SQL Server 2019/2022/2025. Dieser Helfer ist reines T-SQL; sein eigener @Hilfe=1-Pfad benötigt weder eine Ergebnistabelle noch Rootkonfiguration, Windowsimpersonation oder einen CLR-/Dateiaufruf. Der Normalpfad formatiert nur vom Caller gelieferte Metadaten.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@ObjectName` | `sysname` | `kein Default` | Bezeichnung des vom Caller beschriebenen Objekts als sysname; nur Ausgabedatum, keine Auflösung oder Ausführung. Kein SQL-Default; NULL wird nicht vorab zurückgewiesen. |
| `@Description` | `nvarchar(max)` | `kein Default` | Vom Caller gelieferter Beschreibungstext als nvarchar(max), nur Ausgabe; kein SQL-Default. NULL ist möglich, kein fachlicher Default. |
| `@ExampleSql` | `nvarchar(max)` | `kein Default` | Vom Caller gelieferter SQL-Beispieltext als nvarchar(max); wird nur als Datenfeld ausgegeben, niemals ausgeführt. Kein SQL-Default; NULL ist möglich. |
| `@Hilfe` | `bit` | `0` | Optionaler abschließender bit, Default 0. 1 liefert ausschließlich den eigenen vollständigen Skill und kehrt vor Tabellen-/Datei-/CLR-Zugriff zurück. 0 oder NULL führt den bisherigen Helferpfad aus. Bisherige Pflichtargumente bleiben auch beim Hilfeaufruf syntaktisch erforderlich. |

## Ergebnisse

Bei @Hilfe=1 genau eine konstante Skillzeile: SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max), RETURN 0. Normalpfad: bisheriges zwölfspaltiges Help-Resultset HelpContractVersion, SchemaName, ObjectName, Section, Ordinal, ItemName, SqlDataType, IsRequired, IsNullable, Defa' + N'ultValue, Description, ExampleSql. Es enthält eine Beschreibung, fünf generische Steuerparameterzeilen und eine Einschränkungszeile; keine Behauptung vollständiger Parameterhilfe eines beliebigen Zielobjekts.

## Aufrufbeispiele

```sql
EXEC toolbelt_filesystem.USP_InternalEmitHelp @ObjectName=NULL,@Description=NULL,@ExampleSql=NULL,@Hilfe=1;
-- Nur der eigene Skill; keine Dateisystemoperation.
```

## Rechte

Vorhandene EXECUTE-Rechte im autorisierten Modulpfad, keine automatische Rechtevergabe. Normale Routingoperationen benötigen vorhandene Temp-Tabellen und die Rechte des ResultTable-Vertrags. Hilfe vergibt keine Rechte und ersetzt keine Windows-/Root-/ServiceAccount-Freigabe öffentlicher Dateioperationen.

## Ressourcenbedarf

Feste Anzahl von UNION-ALL-Hilfezeilen; Länge der Callerbeschreibung und des Beispieltexts ist nvarchar(max) und besitzt hier kein zusätzliches kleines Limit. Skillhilfe ist konstant, Unicode und ohne Runtime-Katalogabfrage.

## Nebenwirkungen

Keine DML-/Datei-/Netzwerk-/Konfigurationsänderung; normales Hilfeformatieren gibt ausschließlich Daten aus. Neuer Hilfezweig führt nichts davon aus und verändert keine OUTPUT-Werte.

## Fehlerbehandlung

Es gibt keine neuen fachlichen Fehlercodes. Fehlende Pflichtargumente, Objekt-/Ausführungsrechte, nicht vorhandene Caller-Temps und unerwartete Enginefehler bleiben Fehler. Beim Routing werden Fehler des ResultTable-Kerns unverändert weitergegeben; keine automatische Wiederholung oder Rechteausweitung.

## Aussagegrenzen

Interner Helfer, keine öffentliche Datei- oder Berechtigungs-API. Frei gelieferter Beschreibungstext attestiert weder Existenz noch Rechte oder Sicherheit eines Zielobjekts. ExampleSql bleibt Daten, nicht ein auszuführender Auftrag. Native Akzeptanz des neuen Hilfezweigs ist separat offen; historische Fachbelege gelten nur für den unveränderten Normalpfad.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
    END;
-- OBJECT_USAGE_SKILL_EARLY_HELP:END
    SET NOCOUNT ON;
    SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion, CAST(N'toolbelt_filesystem' AS sysname) AS SchemaName, @ObjectName AS ObjectName, CAST('DESCRIPTION' AS varchar(32)) AS Section, 1 AS Ordinal, CAST(NULL AS sysname) AS ItemName, CAST(NULL AS varchar(256)) AS SqlDataType, CAST(NULL AS bit) AS IsRequired, CAST(NULL AS bit) AS IsNullable, CAST(NULL AS nvarchar(4000)) AS DefaultValue, @Description AS Description, @ExampleSql AS ExampleSql
    UNION ALL SELECT '1.0', N'toolbelt_filesystem', @ObjectName, 'PARAMETER', 1, N'@ExecutionIdentity', 'varchar(16)', CAST(0 AS bit), CAST(1 AS bit), N'''Caller''', N'Caller (Default) impersoniert den Windows-authentifizierten SQL-Caller; ServiceAccount verlangt die dbo-eigene Rolle toolbelt_filesystem_service_account und AllowServiceAccount=1 am Root, dann verwendet es das SQL-Server-Dienstkonto. Caller wird bei SQL Authentication abgelehnt.', NULL
    UNION ALL SELECT '1.0', N'toolbelt_filesystem', @ObjectName, 'PARAMETER', 2, N'@ResultTable', 'sysname', CAST(0 AS bit), CAST(1 AS bit), N'NULL', N'Optionale vorhandene lokale Temp-Tabelle für das fachliche Resultset.', NULL
    UNION ALL SELECT '1.0', N'toolbelt_filesystem', @ObjectName, 'PARAMETER', 3, N'@KeepData', 'bit', CAST(0 AS bit), CAST(1 AS bit), N'0', N'Gilt ausschließlich mit @ResultTable.', NULL
    UNION ALL SELECT '1.0', N'toolbelt_filesystem', @ObjectName, 'PARAMETER', 4, N'@Debug', 'tinyint', CAST(0 AS bit), CAST(1 AS bit), N'0', N'Steuert Debug-Messages; es wird kein zusätzliches Resultset erzeugt.', NULL
    UNION ALL SELECT '1.0', N'toolbelt_filesystem', @ObjectName, 'PARAMETER', 5, N'@Hilfe', 'bit', CAST(0 AS bit), CAST(1 AS bit), N'0', N'1 liefert ausschließlich dieses Help-Resultset.', NULL
    UNION ALL SELECT '1.0', N'toolbelt_filesystem', @ObjectName, 'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, N'Windows-only; Linux ist nicht anwendbar. Absolute Pfade, UNC, Reparse Points und Root-Löschung sind gesperrt.', NULL;
END;
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_InternalRouteResult]
      @ResultTable sysname = NULL
    , @KeepData bit = 0
-- OBJECT_USAGE_SKILL_PARAMETER:BEGIN
    , @Hilfe bit = 0
-- OBJECT_USAGE_SKILL_PARAMETER:END
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-filesystem-internal-route-result"
-- description: "Interner Router für eine bereits gefüllte caller-lokale Dateisystem-Ergebnistabelle."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.filesystem.windows"
-- schema_name: "toolbelt_filesystem"
-- object_name: "USP_InternalRouteResult"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler einzelner caller-lokaler Temp-Tabellenname als sysname. NULL liefert #tbx_fs_result direkt als Resultset. Nicht-NULL wird durch USP_PrepareResultTable geprüft und vorbereitet; keine permanente/globale Tabelle oder vierteiliger Name. Keine eigene Berechtigungs-/Identitätsausweitung."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "bit, Default 0; bei Nicht-NULL-ResultTable an USP_PrepareResultTable durchgereicht. 0 leert/ersetzt gemäß dessen Vertrag, 1 erhält Daten und lehnt nötigen Schemaumbau bei nicht leerem Ziel ab. NULL wird dort wie 0 behandelt. Bei direkter Resultsetausgabe ohne Bedeutung."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler abschließender bit, Default 0. 1 liefert ausschließlich den eigenen vollständigen Skill und kehrt vor Tabellen-/Datei-/CLR-Zugriff zurück. 0 oder NULL führt den bisherigen Helferpfad aus. Bisherige Pflichtargumente bleiben auch beim Hilfeaufruf syntaktisch erforderlich."}]
-- source_paths: ["Modules/toolbelt.filesystem.windows/Source/Procedures.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_filesystem.USP_ReadBinaryFileChunk", "toolbelt_filesystem.USP_ListDirectory"]
-- ---
--
-- # USP_InternalRouteResult
--
-- ## Zweck und Einsatzfälle
--
-- Interner Router für eine bereits gefüllte caller-lokale Dateisystem-Ergebnistabelle. Internes Implementierungsdetail; Anwendungen verwenden die öffentlichen Dateisystem-Prozeduren mit deren vollständigem Autorisierungsvertrag.
--
-- ## Voraussetzungen
--
-- Dateisystem-Modul unterstützt Windows SQL Server 2019/2022/2025. Dieser Helfer ist reines T-SQL; sein eigener @Hilfe=1-Pfad benötigt weder eine Ergebnistabelle noch Rootkonfiguration, Windowsimpersonation oder einen CLR-/Dateiaufruf. Im Normalpfad muss #tbx_fs_result bereits mit dem erwarteten Caller-Schema vorhanden sein. Für Tabellenrouting zusätzlich ResultTable-Modul und passende lokale Zieltable.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@ResultTable` | `sysname` | `NULL` | Optionaler einzelner caller-lokaler Temp-Tabellenname als sysname. NULL liefert #tbx_fs_result direkt als Resultset. Nicht-NULL wird durch USP_PrepareResultTable geprüft und vorbereitet; keine permanente/globale Tabelle oder vierteiliger Name. Keine eigene Berechtigungs-/Identitätsausweitung. |
-- | `@KeepData` | `bit` | `0` | bit, Default 0; bei Nicht-NULL-ResultTable an USP_PrepareResultTable durchgereicht. 0 leert/ersetzt gemäß dessen Vertrag, 1 erhält Daten und lehnt nötigen Schemaumbau bei nicht leerem Ziel ab. NULL wird dort wie 0 behandelt. Bei direkter Resultsetausgabe ohne Bedeutung. |
-- | `@Hilfe` | `bit` | `0` | Optionaler abschließender bit, Default 0. 1 liefert ausschließlich den eigenen vollständigen Skill und kehrt vor Tabellen-/Datei-/CLR-Zugriff zurück. 0 oder NULL führt den bisherigen Helferpfad aus. Bisherige Pflichtargumente bleiben auch beim Hilfeaufruf syntaktisch erforderlich. |
--
-- ## Ergebnisse
--
-- Bei @Hilfe=1 genau eine konstante Skillzeile: SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max), RETURN 0. Normalpfad ohne ResultTable: SELECT * aus #tbx_fs_result und RETURN 0, Schema stammt vom Caller. Mit ResultTable: keine eigene fachliche Resultsetausgabe, sondern vollständiges INSERT der vorhandenen Ergebnistokens in das vorbereitete Ziel. Keine OUTPUT-Parameter.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_filesystem.USP_InternalRouteResult @Hilfe=1;
-- -- Nur der eigene Skill; keine Dateisystemoperation.
-- ```
--
-- ## Rechte
--
-- Vorhandene EXECUTE-Rechte im autorisierten Modulpfad, keine automatische Rechtevergabe. Normale Routingoperationen benötigen vorhandene Temp-Tabellen und die Rechte des ResultTable-Vertrags. Hilfe vergibt keine Rechte und ersetzt keine Windows-/Root-/ServiceAccount-Freigabe öffentlicher Dateioperationen.
--
-- ## Ressourcenbedarf
--
-- Direkte Ausgabe bzw. INSERT proportional zur Zeilenzahl und Breite der caller-lokalen #tbx_fs_result. Shape wird mit SELECT TOP(0) in #tbx_fs_shape ermittelt. Keine eigene Row-/Bytequote; gültige Begrenzungen stammen vom öffentlichen Fachcaller. Skillhilfe ist konstant, Unicode und ohne Runtime-Katalogabfrage.
--
-- ## Nebenwirkungen
--
-- Mit ResultTable kann USP_PrepareResultTable das lokale Zielschema verändern oder vorhandene Zeilen gemäß KeepData entfernen; danach INSERT. #tbx_fs_shape ist eine lokale Temp-Tabelle des Helfers. Kein eigener Commit/Rollback und kein eigener Datei-/Netzwerk-/CLR-Aufruf. Neuer Hilfezweig führt nichts davon aus und verändert keine OUTPUT-Werte.
--
-- ## Fehlerbehandlung
--
-- Es gibt keine neuen fachlichen Fehlercodes. Fehlende Pflichtargumente, Objekt-/Ausführungsrechte, nicht vorhandene Caller-Temps und unerwartete Enginefehler bleiben Fehler. Beim Routing werden Fehler des ResultTable-Kerns unverändert weitergegeben; keine automatische Wiederholung oder Rechteausweitung.
--
-- ## Aussagegrenzen
--
-- Interner Helfer, keine öffentliche Datei- oder Berechtigungs-API. Ergebnistabelle und Schema werden vom aufrufenden Fachpfad bereitgestellt; dieser Helfer prüft keine Herkunft der Daten und besitzt keine eigene atomare Dateisystemoperation. ResultTable-Name wird als Identifier gequotet, nicht als SQL-Ausdruck interpretiert. Native Akzeptanz des neuen Hilfezweigs ist separat offen; historische Fachbelege gelten nur für den unveränderten Normalpfad.
-- OBJECT_USAGE_SKILL:END
BEGIN
-- OBJECT_USAGE_SKILL_EARLY_HELP:BEGIN
    IF @Hilfe = 1
    BEGIN
        SET NOCOUNT ON;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_filesystem' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_InternalRouteResult' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-filesystem-internal-route-result"
description: "Interner Router für eine bereits gefüllte caller-lokale Dateisystem-Ergebnistabelle."
skill_format_version: "1.0"
module_id: "toolbelt.filesystem.windows"
schema_name: "toolbelt_filesystem"
object_name: "USP_InternalRouteResult"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler einzelner caller-lokaler Temp-Tabellenname als sysname. NULL liefert #tbx_fs_result direkt als Resultset. Nicht-NULL wird durch USP_PrepareResultTable geprüft und vorbereitet; keine permanente/globale Tabelle oder vierteiliger Name. Keine eigene Berechtigungs-/Identitätsausweitung."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "bit, Default 0; bei Nicht-NULL-ResultTable an USP_PrepareResultTable durchgereicht. 0 leert/ersetzt gemäß dessen Vertrag, 1 erhält Daten und lehnt nötigen Schemaumbau bei nicht leerem Ziel ab. NULL wird dort wie 0 behandelt. Bei direkter Resultsetausgabe ohne Bedeutung."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler abschließender bit, Default 0. 1 liefert ausschließlich den eigenen vollständigen Skill und kehrt vor Tabellen-/Datei-/CLR-Zugriff zurück. 0 oder NULL führt den bisherigen Helferpfad aus. Bisherige Pflichtargumente bleiben auch beim Hilfeaufruf syntaktisch erforderlich."}]
source_paths: ["Modules/toolbelt.filesystem.windows/Source/Procedures.sql"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_filesystem.USP_ReadBinaryFileChunk", "toolbelt_filesystem.USP_ListDirectory"]
---

# US' AS nvarchar(max)) + N'P_InternalRouteResult

## Zweck und Einsatzfälle

Interner Router für eine bereits gefüllte caller-lokale Dateisystem-Ergebnistabelle. Internes Implementierungsdetail; Anwendungen verwenden die öffentlichen Dateisystem-Prozeduren mit deren vollständigem Autorisierungsvertrag.

## Voraussetzungen

Dateisystem-Modul unterstützt Windows SQL Server 2019/2022/2025. Dieser Helfer ist reines T-SQL; sein eigener @Hilfe=1-Pfad benötigt weder eine Ergebnistabelle noch Rootkonfiguration, Windowsimpersonation oder einen CLR-/Dateiaufruf. Im Normalpfad muss #tbx_fs_result bereits mit dem erwarteten Caller-Schema vorhanden sein. Für Tabellenrouting zusätzlich ResultTable-Modul und passende lokale Zieltable.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@ResultTable` | `sysname` | `NULL` | Optionaler einzelner caller-lokaler Temp-Tabellenname als sysname. NULL liefert #tbx_fs_result direkt als Resultset. Nicht-NULL wird durch USP_PrepareResultTable geprüft und vorbereitet; keine permanente/globale Tabelle oder vierteiliger Name. Keine eigene Berechtigungs-/Identitätsausweitung. |
| `@KeepData` | `bit` | `0` | bit, Default 0; bei Nicht-NULL-ResultTable an USP_PrepareResultTable durchgereicht. 0 leert/ersetzt gemäß dessen Vertrag, 1 erhält Daten und lehnt nötigen Schemaumbau bei nicht leerem Ziel ab. NULL wird dort wie 0 behandelt. Bei direkter Resultsetausgabe ohne Bedeutung. |
| `@Hilfe` | `bit` | `0` | Optionaler abschließender bit, Default 0. 1 liefert ausschließlich den eigenen vollständigen Skill und kehrt vor Tabellen-/Datei-/CLR-Zugriff zurück. 0 oder NULL führt den bisherigen Helferpfad aus. Bisherige Pflichtargumente bleiben auch beim Hilfeaufruf syntaktisch erforderlich. |

## Ergebnisse

Bei @Hilfe=1 genau eine konstante Skillzeile: SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max), RETURN 0. Normalpfad ohne ResultTable: SELECT * aus #tbx_fs_result und RETURN 0, Schema sta' + N'mmt vom Caller. Mit ResultTable: keine eigene fachliche Resultsetausgabe, sondern vollständiges INSERT der vorhandenen Ergebnistokens in das vorbereitete Ziel. Keine OUTPUT-Parameter.

## Aufrufbeispiele

```sql
EXEC toolbelt_filesystem.USP_InternalRouteResult @Hilfe=1;
-- Nur der eigene Skill; keine Dateisystemoperation.
```

## Rechte

Vorhandene EXECUTE-Rechte im autorisierten Modulpfad, keine automatische Rechtevergabe. Normale Routingoperationen benötigen vorhandene Temp-Tabellen und die Rechte des ResultTable-Vertrags. Hilfe vergibt keine Rechte und ersetzt keine Windows-/Root-/ServiceAccount-Freigabe öffentlicher Dateioperationen.

## Ressourcenbedarf

Direkte Ausgabe bzw. INSERT proportional zur Zeilenzahl und Breite der caller-lokalen #tbx_fs_result. Shape wird mit SELECT TOP(0) in #tbx_fs_shape ermittelt. Keine eigene Row-/Bytequote; gültige Begrenzungen stammen vom öffentlichen Fachcaller. Skillhilfe ist konstant, Unicode und ohne Runtime-Katalogabfrage.

## Nebenwirkungen

Mit ResultTable kann USP_PrepareResultTable das lokale Zielschema verändern oder vorhandene Zeilen gemäß KeepData entfernen; danach INSERT. #tbx_fs_shape ist eine lokale Temp-Tabelle des Helfers. Kein eigener Commit/Rollback und kein eigener Datei-/Netzwerk-/CLR-Aufruf. Neuer Hilfezweig führt nichts davon aus und verändert keine OUTPUT-Werte.

## Fehlerbehandlung

Es gibt keine neuen fachlichen Fehlercodes. Fehlende Pflichtargumente, Objekt-/Ausführungsrechte, nicht vorhandene Caller-Temps und unerwartete Enginefehler bleiben Fehler. Beim Routing werden Fehler des ResultTable-Kerns unverändert weitergegeben; keine automatische Wiederholung oder Rechteausweitung.

## Aussagegrenzen

Interner Helfer, keine öffentliche Datei- oder Berechtigungs-API. Ergebnistabelle und Schema werden vom aufrufenden Fachpfad bereitgestellt; dieser Helfer prüft keine Herkunft der Daten und besitzt keine eigene atomare Dateisystemoperation. ResultTable-Name wird als Identifier gequotet, nicht als SQL-Ausdruc' + N'k interpretiert. Native Akzeptanz des neuen Hilfezweigs ist separat offen; historische Fachbelege gelten nur für den unveränderten Normalpfad.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
    END;
-- OBJECT_USAGE_SKILL_EARLY_HELP:END
    SET NOCOUNT ON;
    IF @ResultTable IS NULL
    BEGIN
        SELECT * FROM #tbx_fs_result;
        RETURN 0;
    END;
    SELECT TOP (0) * INTO #tbx_fs_shape FROM #tbx_fs_result;
    EXEC [toolbelt_core].[USP_PrepareResultTable]
          @ResultTableToAlter = @ResultTable
        , @LikeTable = N'#tbx_fs_shape'
        , @KeepData = @KeepData;
    DECLARE @RouteSql nvarchar(max) = N'INSERT INTO ' + QUOTENAME(@ResultTable) + N' SELECT * FROM #tbx_fs_result;';
    EXEC sys.sp_executesql @RouteSql;
END;
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_ReadBinaryFileChunk]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @ByteOffset bigint = 0
  , @MaxBytes int = 1048576
  , @ExecutionIdentity varchar(16) = 'Caller'
  , @ResultTable sysname = NULL
  , @KeepData bit = 0
  , @Debug tinyint = 0
  , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@Hilfe, 0) = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_filesystem' AS sysname) AS SchemaName,
            CAST(N'USP_ReadBinaryFileChunk' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Liest einen begrenzten Binär-Chunk aus einer per RootAlias freigegebenen Datei.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk
 @RootAlias=N''ExampleRoot'', @RelativePath=N''example.bin'', @ByteOffset=0, @MaxBytes=1024, @ExecutionIdentity=N''Caller'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'Content', N'varbinary(max)', NULL, 1, NULL, CAST(N'Content.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'BytesRead', N'int', NULL, 0, NULL, CAST(N'BytesRead.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'NextByteOffset', N'bigint', NULL, 0, NULL, CAST(N'NextByteOffset.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'EndOfFile', N'bit', NULL, 0, NULL, CAST(N'EndOfFile.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Windows-Dateisystem; Rootfreigaben, ExecutionIdentity und Betriebssystemrechte bleiben erforderlich. Hilfe führt keine Dateioperation und keine Rootprüfung aus.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@RootAlias', N'sysname', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@RelativePath', N'nvarchar(4000)', 1, 0, N'NULL', CAST(N'Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N''inbox\sample.txt''; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leerer Pfad ist für eine Quelldatei ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@ByteOffset', N'bigint', 0, 0, N'0', CAST(N'Ganzzahl bigint 0..Dateilänge in Rohbytes, Default 0; kein Zeichenindex. Genau EOF liefert leeren Chunk/EndOfFile=1, größer EOF oder negativ ist ungültig. NULL wird nicht zu 0 normalisiert und ist für CLR-Int64 ungültig. Bei Text an einer Decodergrenze beginnen und für Folgeaufrufe NextByteOffset unverändert übernehmen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@MaxBytes', N'int', 0, 0, N'1048576', CAST(N'Ganzzahl 1..16777216 Rohbytes pro Chunk, Default 1048576. NULL/außerhalb ungültig. Tatsächlicher Chunk kann an EOF kürzer sein; kein Gesamtdateilimit.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@ExecutionIdentity', N'varchar(16)', 0, 0, N'''Caller''', CAST(N'Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
    CREATE TABLE #tbx_fs_result ([Content] varbinary(max) NULL, [BytesRead] int NOT NULL, [NextByteOffset] bigint NOT NULL, [EndOfFile] bit NOT NULL);
    DECLARE @ClrExecutionIdentity nvarchar(16) = CONVERT(nvarchar(16), @ExecutionIdentity);
    BEGIN TRY
        INSERT INTO #tbx_fs_result
        EXEC [toolbelt_filesystem].[CLR_ReadBinaryFileChunk]
              @RootAlias
          , @RelativePath
          , @ByteOffset
          , @MaxBytes
          , @ClrExecutionIdentity;
    END TRY
    BEGIN CATCH
      DECLARE @ProviderError nvarchar(2048) = N'Dateisystemprovider konnte den Binaer-Chunk nicht lesen. Ursache: ' + REPLACE(LEFT(ERROR_MESSAGE(), 1700), N'%', N'%%');
        THROW 51540, @ProviderError, 1;
    END CATCH;
    EXEC [toolbelt_filesystem].[USP_InternalRouteResult]
          @ResultTable = @ResultTable
        , @KeepData = @KeepData;
END;
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_ReadTextFileChunk]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @ByteOffset bigint = 0
  , @MaxBytes int = 1048576
  , @EncodingName nvarchar(128) = NULL
  , @ExecutionIdentity varchar(16) = 'Caller'
  , @ResultTable sysname = NULL
  , @KeepData bit = 0
  , @Debug tinyint = 0
  , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@Hilfe, 0) = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_filesystem' AS sysname) AS SchemaName,
            CAST(N'USP_ReadTextFileChunk' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Liest einen begrenzten Text-Chunk mit expliziter Codepage und liefert die nächste Byte-Position.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_ReadTextFileChunk
 @RootAlias=N''ExampleRoot'', @RelativePath=N''example.txt'', @ByteOffset=0, @MaxBytes=1024, @EncodingName=N''utf-8'', @ExecutionIdentity=N''Caller'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'Content', N'nvarchar(max)', NULL, 1, NULL, CAST(N'Content.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'BytesRead', N'int', NULL, 0, NULL, CAST(N'BytesRead.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'NextByteOffset', N'bigint', NULL, 0, NULL, CAST(N'NextByteOffset.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'EndOfFile', N'bit', NULL, 0, NULL, CAST(N'EndOfFile.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'EncodingName', N'nvarchar(128)', NULL, 0, NULL, CAST(N'EncodingName.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Windows-Dateisystem; Rootfreigaben, ExecutionIdentity und Betriebssystemrechte bleiben erforderlich. Hilfe führt keine Dateioperation und keine Rootprüfung aus.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@RootAlias', N'sysname', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@RelativePath', N'nvarchar(4000)', 1, 0, N'NULL', CAST(N'Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N''inbox\sample.txt''; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leerer Pfad ist für eine Quelldatei ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@ByteOffset', N'bigint', 0, 0, N'0', CAST(N'Ganzzahl bigint 0..Dateilänge in Rohbytes, Default 0; kein Zeichenindex. Genau EOF liefert leeren Chunk/EndOfFile=1, größer EOF oder negativ ist ungültig. NULL wird nicht zu 0 normalisiert und ist für CLR-Int64 ungültig. Bei Text an einer Decodergrenze beginnen und für Folgeaufrufe NextByteOffset unverändert übernehmen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@MaxBytes', N'int', 0, 0, N'1048576', CAST(N'Ganzzahl 4..16777216 Rohbytes pro Leseversuch, Default 1048576. NULL/außerhalb ungültig. Tatsächlicher Chunk kann an EOF oder zum Erhalt einer vollständigen Decodergrenze kürzer sein; kein Gesamtdateilimit.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@EncodingName', N'nvarchar(128)', 0, 0, N'NULL', CAST(N'Fachlich erforderlicher Encodingname nvarchar(128) für striktes .NET-Framework-Encoding.GetEncoding(name), z.B. utf-8, utf-16, utf-16BE oder windows-1252. Die Menge ist provider-/plattformabhängig und keine geschlossene Toolbelt-Enum; verfügbare Namen mit System.Text.Encoding.GetEncodings() in der passenden Frameworkumgebung ermitteln (Name/WebName), nicht aus einer anderen .NET-Laufzeit ableiten. NULL/leer/Whitespace-only/unbekannt ungültig. Decoder-/Encoderfehler werden nicht durch Ersatzzeichen verborgen; keine automatische BOM-/Codepageerkennung. BOM wird als Datenzeichen behandelt; Offset/NextByteOffset zählen weiterhin Bytes.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@ExecutionIdentity', N'varchar(16)', 0, 0, N'''Caller''', CAST(N'Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
    CREATE TABLE #tbx_fs_result ([Content] nvarchar(max) NULL, [BytesRead] int NOT NULL, [NextByteOffset] bigint NOT NULL, [EndOfFile] bit NOT NULL, [EncodingName] nvarchar(128) NOT NULL);
    DECLARE @ClrExecutionIdentity nvarchar(16) = CONVERT(nvarchar(16), @ExecutionIdentity);
    BEGIN TRY
        INSERT INTO #tbx_fs_result
        EXEC [toolbelt_filesystem].[CLR_ReadTextFileChunk]
              @RootAlias
          , @RelativePath
          , @ByteOffset
          , @MaxBytes
          , @EncodingName
          , @ClrExecutionIdentity;
    END TRY
    BEGIN CATCH
      DECLARE @ProviderError nvarchar(2048) = N'Dateisystemprovider konnte den Text-Chunk nicht lesen. Ursache: ' + REPLACE(LEFT(ERROR_MESSAGE(), 1700), N'%', N'%%');
        THROW 51540, @ProviderError, 1;
    END CATCH;
    EXEC [toolbelt_filesystem].[USP_InternalRouteResult]
          @ResultTable = @ResultTable
        , @KeepData = @KeepData;
END;
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_WriteBinaryFile]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @Content varbinary(max) = NULL
  , @Overwrite bit = 0
  , @ExecutionIdentity varchar(16) = 'Caller'
  , @ResultTable sysname = NULL
  , @KeepData bit = 0
  , @Debug tinyint = 0
  , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@Hilfe, 0) = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_filesystem' AS sysname) AS SchemaName,
            CAST(N'USP_WriteBinaryFile' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Schreibt Binärdaten gestreamt in eine atomar veröffentlichte Zieldatei.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_WriteBinaryFile
 @RootAlias=N''ExampleRoot'', @RelativePath=N''example.bin'', @Content=0x4869, @Overwrite=0, @ExecutionIdentity=N''Caller'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'BytesWritten', N'bigint', NULL, 0, NULL, CAST(N'BytesWritten.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'RootAlias', N'nvarchar(128)', NULL, 0, NULL, CAST(N'RootAlias.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'RelativePath', N'nvarchar(4000)', NULL, 0, NULL, CAST(N'RelativePath.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'State', N'varchar(16)', NULL, 0, NULL, CAST(N'State.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Windows-Dateisystem; Rootfreigaben, ExecutionIdentity und Betriebssystemrechte bleiben erforderlich. Hilfe führt keine Dateioperation und keine Rootprüfung aus.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@RootAlias', N'sysname', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@RelativePath', N'nvarchar(4000)', 1, 0, N'NULL', CAST(N'Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N''inbox\sample.txt''; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leerer Pfad ungültig; Zielverzeichnis muss bestehen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@Content', N'varbinary(max)', 1, 0, N'NULL', CAST(N'Binärer Bytepuffer varbinary(max), etwa 0x0102; keine Text-/Base64-Dekodierung. Leer 0x schreibt eine leere Datei. NULL (technischer Help-Default) ungültig. SQL-LOB wird in begrenzten Blöcken gelesen, kein zusätzliches öffentliches Gesamtbytebudget.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@Overwrite', N'bit', 0, 0, N'0', CAST(N'Taxativ im gebundenen bit: 0 lehnt ein vorhandenes Ziel ab (Default); 1 erlaubt dessen atomare Ersetzung durch den vollständig geschriebenen Staginginhalt. Kein Append. NULL ist für den nativen CLR-bool ungültig und wird nicht zu 0 normalisiert. Dateipublikation ist kein gemeinsam mit späterer SQL-Resultausgabe rückrollbarer Effekt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@ExecutionIdentity', N'varchar(16)', 0, 0, N'''Caller''', CAST(N'Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
    CREATE TABLE #tbx_fs_result ([BytesWritten] bigint NOT NULL, [RootAlias] nvarchar(128) NOT NULL, [RelativePath] nvarchar(4000) NOT NULL, [State] varchar(16) NOT NULL);
    DECLARE @ClrExecutionIdentity nvarchar(16) = CONVERT(nvarchar(16), @ExecutionIdentity);
    BEGIN TRY
        INSERT INTO #tbx_fs_result
        EXEC [toolbelt_filesystem].[CLR_WriteBinaryFile]
              @RootAlias
          , @RelativePath
          , @Content
          , @Overwrite
          , @ClrExecutionIdentity;
    END TRY
    BEGIN CATCH
      DECLARE @ProviderError nvarchar(2048) = N'Dateisystemprovider konnte die Binaerdatei nicht schreiben. Ursache: ' + REPLACE(LEFT(ERROR_MESSAGE(), 1700), N'%', N'%%');
        THROW 51540, @ProviderError, 1;
    END CATCH;
    EXEC [toolbelt_filesystem].[USP_InternalRouteResult]
          @ResultTable = @ResultTable
        , @KeepData = @KeepData;
END;
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_WriteTextFile]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @Content nvarchar(max) = NULL
  , @EncodingName nvarchar(128) = NULL
  , @WriteBom bit = 0
  , @Overwrite bit = 0
  , @ExecutionIdentity varchar(16) = 'Caller'
  , @ResultTable sysname = NULL
  , @KeepData bit = 0
  , @Debug tinyint = 0
  , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@Hilfe, 0) = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_filesystem' AS sysname) AS SchemaName,
            CAST(N'USP_WriteTextFile' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Schreibt Text gestreamt mit expliziter Codepage und optionalem BOM.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_WriteTextFile
 @RootAlias=N''ExampleRoot'', @RelativePath=N''example.txt'', @Content=N''Contoso'', @EncodingName=N''utf-8'', @WriteBom=0, @Overwrite=0, @ExecutionIdentity=N''Caller'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'BytesWritten', N'bigint', NULL, 0, NULL, CAST(N'BytesWritten.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'RootAlias', N'nvarchar(128)', NULL, 0, NULL, CAST(N'RootAlias.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'RelativePath', N'nvarchar(4000)', NULL, 0, NULL, CAST(N'RelativePath.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'State', N'varchar(16)', NULL, 0, NULL, CAST(N'State.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Windows-Dateisystem; Rootfreigaben, ExecutionIdentity und Betriebssystemrechte bleiben erforderlich. Hilfe führt keine Dateioperation und keine Rootprüfung aus.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@RootAlias', N'sysname', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@RelativePath', N'nvarchar(4000)', 1, 0, N'NULL', CAST(N'Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N''inbox\sample.txt''; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leerer Pfad ungültig; Zielverzeichnis muss bestehen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@Content', N'nvarchar(max)', 1, 0, N'NULL', CAST(N'Unicode-Text nvarchar(max), leer schreibt nur eine gegebenenfalls gewählte BOM. NULL (technischer Help-Default) ungültig. Zeichen werden mit explizitem Encoding strikt kodiert; unvertretbare Zeichen/ungültige Surrogate sind Fehler, kein stiller Ersatz. Kein Append oder zusätzliches Gesamttextbudget.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@EncodingName', N'nvarchar(128)', 0, 0, N'NULL', CAST(N'Fachlich erforderlicher Encodingname nvarchar(128) für striktes .NET-Framework-Encoding.GetEncoding(name), z.B. utf-8, utf-16, utf-16BE oder windows-1252. Die Menge ist provider-/plattformabhängig und keine geschlossene Toolbelt-Enum; verfügbare Namen mit System.Text.Encoding.GetEncodings() in der passenden Frameworkumgebung ermitteln (Name/WebName), nicht aus einer anderen .NET-Laufzeit ableiten. NULL/leer/Whitespace-only/unbekannt ungültig. Decoder-/Encoderfehler werden nicht durch Ersatzzeichen verborgen; keine automatische BOM-/Codepageerkennung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@WriteBom', N'bit', 0, 0, N'0', CAST(N'Taxativ im gebundenen bit: 0 schreibt keine zusätzliche Encodingpräambel (Default); 1 schreibt Encoding.GetPreamble() vor den Daten. Bei einer Codepage ohne Präambel bleiben auch bei 1 keine zusätzlichen Bytes. NULL ist für CLR-bool ungültig. Bereits im Content vorhandenes U+FEFF wird dadurch nicht entfernt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Overwrite', N'bit', 0, 0, N'0', CAST(N'Taxativ im gebundenen bit: 0 lehnt ein vorhandenes Ziel ab (Default); 1 erlaubt dessen atomare Ersetzung durch den vollständig geschriebenen Staginginhalt. Kein Append. NULL ist für den nativen CLR-bool ungültig und wird nicht zu 0 normalisiert. Dateipublikation ist kein gemeinsam mit späterer SQL-Resultausgabe rückrollbarer Effekt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@ExecutionIdentity', N'varchar(16)', 0, 0, N'''Caller''', CAST(N'Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
    CREATE TABLE #tbx_fs_result ([BytesWritten] bigint NOT NULL, [RootAlias] nvarchar(128) NOT NULL, [RelativePath] nvarchar(4000) NOT NULL, [State] varchar(16) NOT NULL);
    DECLARE @ClrExecutionIdentity nvarchar(16) = CONVERT(nvarchar(16), @ExecutionIdentity);
    BEGIN TRY
        INSERT INTO #tbx_fs_result
        EXEC [toolbelt_filesystem].[CLR_WriteTextFile]
              @RootAlias
          , @RelativePath
          , @Content
          , @EncodingName
          , @WriteBom
          , @Overwrite
          , @ClrExecutionIdentity;
    END TRY
    BEGIN CATCH
      DECLARE @ProviderError nvarchar(2048) = N'Dateisystemprovider konnte die Textdatei nicht schreiben. Ursache: ' + REPLACE(LEFT(ERROR_MESSAGE(), 1700), N'%', N'%%');
        THROW 51540, @ProviderError, 1;
    END CATCH;
    EXEC [toolbelt_filesystem].[USP_InternalRouteResult]
          @ResultTable = @ResultTable
        , @KeepData = @KeepData;
END;
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_TranscodeTextFile]
(
    @SourceRootAlias sysname = NULL
  , @SourceRelativePath nvarchar(4000) = NULL
  , @SourceEncodingName nvarchar(128) = NULL
  , @TargetRootAlias sysname = NULL
  , @TargetRelativePath nvarchar(4000) = NULL
  , @TargetEncodingName nvarchar(128) = NULL
  , @WriteBom bit = 0
  , @Overwrite bit = 0
  , @ExecutionIdentity varchar(16) = 'Caller'
  , @ResultTable sysname = NULL
  , @KeepData bit = 0
  , @Debug tinyint = 0
  , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@Hilfe, 0) = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_filesystem' AS sysname) AS SchemaName,
            CAST(N'USP_TranscodeTextFile' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Konvertiert eine Textdatei gestreamt zwischen zwei expliziten Codepages.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_TranscodeTextFile
 @SourceRootAlias=N''ExampleRoot'', @SourceRelativePath=N''input.txt'', @SourceEncodingName=N''utf-8'', @TargetRootAlias=N''ExampleRoot'', @TargetRelativePath=N''output.txt'', @TargetEncodingName=N''utf-16'', @Overwrite=0, @ExecutionIdentity=N''Caller'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'BytesWritten', N'bigint', NULL, 0, NULL, CAST(N'BytesWritten.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'RootAlias', N'nvarchar(128)', NULL, 0, NULL, CAST(N'RootAlias.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'RelativePath', N'nvarchar(4000)', NULL, 0, NULL, CAST(N'RelativePath.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'State', N'varchar(16)', NULL, 0, NULL, CAST(N'State.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Windows-Dateisystem; Rootfreigaben, ExecutionIdentity und Betriebssystemrechte bleiben erforderlich. Hilfe führt keine Dateioperation und keine Rootprüfung aus.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@SourceRootAlias', N'sysname', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. Quelle benötigt AllowRead.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@SourceRelativePath', N'nvarchar(4000)', 1, 0, N'NULL', CAST(N'Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N''inbox\sample.txt''; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Nicht leer; vorhandene Quelldatei.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@SourceEncodingName', N'nvarchar(128)', 0, 0, N'NULL', CAST(N'Fachlich erforderlicher Encodingname nvarchar(128) für striktes .NET-Framework-Encoding.GetEncoding(name), z.B. utf-8, utf-16, utf-16BE oder windows-1252. Die Menge ist provider-/plattformabhängig und keine geschlossene Toolbelt-Enum; verfügbare Namen mit System.Text.Encoding.GetEncodings() in der passenden Frameworkumgebung ermitteln (Name/WebName), nicht aus einer anderen .NET-Laufzeit ableiten. NULL/leer/Whitespace-only/unbekannt ungültig. Decoder-/Encoderfehler werden nicht durch Ersatzzeichen verborgen; keine automatische BOM-/Codepageerkennung. Explizites Sourceencoding; keine BOM-Autoerkennung. StreamReader entfernt gegebenenfalls eine zu diesem Encoding passende Präambel.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@TargetRootAlias', N'sysname', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. Ziel benötigt AllowWrite.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@TargetRelativePath', N'nvarchar(4000)', 1, 0, N'NULL', CAST(N'Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N''inbox\sample.txt''; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Nicht leer; Zielverzeichnis muss bestehen. Ausgabe erfolgt über Staging/Publish.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@TargetEncodingName', N'nvarchar(128)', 0, 0, N'NULL', CAST(N'Fachlich erforderlicher Encodingname nvarchar(128) für striktes .NET-Framework-Encoding.GetEncoding(name), z.B. utf-8, utf-16, utf-16BE oder windows-1252. Die Menge ist provider-/plattformabhängig und keine geschlossene Toolbelt-Enum; verfügbare Namen mit System.Text.Encoding.GetEncodings() in der passenden Frameworkumgebung ermitteln (Name/WebName), nicht aus einer anderen .NET-Laufzeit ableiten. NULL/leer/Whitespace-only/unbekannt ungültig. Decoder-/Encoderfehler werden nicht durch Ersatzzeichen verborgen; keine automatische BOM-/Codepageerkennung. Bestimmt ausschließlich die Ausgabeencoding.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@WriteBom', N'bit', 0, 0, N'0', CAST(N'Taxativ im gebundenen bit: 0 schreibt keine zusätzliche Encodingpräambel (Default); 1 schreibt Encoding.GetPreamble() vor den Daten. Bei einer Codepage ohne Präambel bleiben auch bei 1 keine zusätzlichen Bytes. NULL ist für CLR-bool ungültig. Bereits im Content vorhandenes U+FEFF wird dadurch nicht entfernt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@Overwrite', N'bit', 0, 0, N'0', CAST(N'Taxativ im gebundenen bit: 0 lehnt ein vorhandenes Ziel ab (Default); 1 erlaubt dessen atomare Ersetzung durch den vollständig geschriebenen Staginginhalt. Kein Append. NULL ist für den nativen CLR-bool ungültig und wird nicht zu 0 normalisiert. Dateipublikation ist kein gemeinsam mit späterer SQL-Resultausgabe rückrollbarer Effekt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@ExecutionIdentity', N'varchar(16)', 0, 0, N'''Caller''', CAST(N'Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 12, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 13, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
    CREATE TABLE #tbx_fs_result ([BytesWritten] bigint NOT NULL, [RootAlias] nvarchar(128) NOT NULL, [RelativePath] nvarchar(4000) NOT NULL, [State] varchar(16) NOT NULL);
    DECLARE @ClrExecutionIdentity nvarchar(16) = CONVERT(nvarchar(16), @ExecutionIdentity);
    BEGIN TRY
        INSERT INTO #tbx_fs_result
        EXEC [toolbelt_filesystem].[CLR_TranscodeTextFile]
              @SourceRootAlias
          , @SourceRelativePath
          , @SourceEncodingName
          , @TargetRootAlias
          , @TargetRelativePath
          , @TargetEncodingName
          , @WriteBom
          , @Overwrite
          , @ClrExecutionIdentity;
    END TRY
    BEGIN CATCH
      DECLARE @ProviderError nvarchar(2048) = N'Dateisystemprovider konnte die Textdatei nicht transkodieren. Ursache: ' + REPLACE(LEFT(ERROR_MESSAGE(), 1700), N'%', N'%%');
        THROW 51540, @ProviderError, 1;
    END CATCH;
    EXEC [toolbelt_filesystem].[USP_InternalRouteResult]
          @ResultTable = @ResultTable
        , @KeepData = @KeepData;
END;
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_ListDirectory]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = N''
  , @Recursive bit = 0
  , @MaxDepth int = 32
  , @MaxEntries int = 10000
  , @ExecutionIdentity varchar(16) = 'Caller'
  , @ResultTable sysname = NULL
  , @KeepData bit = 0
  , @Debug tinyint = 0
  , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@Hilfe, 0) = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_filesystem' AS sysname) AS SchemaName,
            CAST(N'USP_ListDirectory' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Listet Verzeichniseinträge unter einem freigegebenen Root mit harten Grenzen.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_ListDirectory
 @RootAlias=N''ExampleRoot'', @RelativePath=N'''', @Recursive=0, @MaxEntries=100, @ExecutionIdentity=N''Caller'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'EntryOrdinal', N'bigint', NULL, 0, NULL, CAST(N'EntryOrdinal.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'RelativePath', N'nvarchar(4000)', NULL, 0, NULL, CAST(N'RelativePath.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'EntryType', N'varchar(16)', NULL, 0, NULL, CAST(N'EntryType.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'SizeBytes', N'bigint', NULL, 0, NULL, CAST(N'SizeBytes.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'LastWriteTimeUtc', N'datetime2', NULL, 0, NULL, CAST(N'LastWriteTimeUtc.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 6, N'IsReparsePoint', N'bit', NULL, 0, NULL, CAST(N'IsReparsePoint.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Windows-Dateisystem; Rootfreigaben, ExecutionIdentity und Betriebssystemrechte bleiben erforderlich. Hilfe führt keine Dateioperation und keine Rootprüfung aus.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@RootAlias', N'sysname', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@RelativePath', N'nvarchar(4000)', 1, 0, N'N''''', CAST(N'Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N''inbox\sample.txt''; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leer (Default) wählt den Root selbst; NULL bleibt ungültig. Kein Suchmuster.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@Recursive', N'bit', 0, 0, N'0', CAST(N'Taxativ im gebundenen bit: 0 bearbeitet nur das explizite Verzeichnis ohne rekursiven Abstieg (Default); 1 erlaubt begrenzten Abstieg gemäß MaxDepth/MaxEntries. NULL ist für CLR-bool ungültig und kein Default.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@MaxDepth', N'int', 0, 0, N'32', CAST(N'Ganzzahl 0..64, Default 32; Startdirectory hat Tiefe 0. Bei Recursive=1 führt ein nötiger Abstieg über die Grenze zum Fehler, nicht zu einer still gekürzten Ausgabe; bei 0 ist bereits Abstieg in ein Unterverzeichnis verboten. Auch ohne Rekursion muss das Budget gültig sein. NULL/negativ/>64 ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@MaxEntries', N'int', 0, 0, N'10000', CAST(N'Ganzzahl 1..10000 Verzeichniseinträge (Dateien und Unterverzeichnisse), Default 10000. NULL/außerhalb ungültig; Überschreitung verwirft die vollständig gepufferte Ausgabe, kein TOP-Teilresultat. Zusätzlich gilt ein internes Pfadbytebudget.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@ExecutionIdentity', N'varchar(16)', 0, 0, N'''Caller''', CAST(N'Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
    CREATE TABLE #tbx_fs_result ([EntryOrdinal] bigint NOT NULL, [RelativePath] nvarchar(4000) NOT NULL, [EntryType] varchar(16) NOT NULL, [SizeBytes] bigint NOT NULL, [LastWriteTimeUtc] datetime2 NOT NULL, [IsReparsePoint] bit NOT NULL);
    DECLARE @ClrExecutionIdentity nvarchar(16) = CONVERT(nvarchar(16), @ExecutionIdentity);
    BEGIN TRY
        INSERT INTO #tbx_fs_result
        EXEC [toolbelt_filesystem].[CLR_ListDirectory]
              @RootAlias
          , @RelativePath
          , @Recursive
          , @MaxDepth
          , @MaxEntries
          , @ClrExecutionIdentity;
    END TRY
    BEGIN CATCH
      DECLARE @ProviderError nvarchar(2048) =
        CASE
          WHEN ERROR_MESSAGE() LIKE N'%TBXFS:EntryLimitExceeded%'
            THEN N'Die Verzeichnisausgabe ueberschreitet @MaxEntries = '
               + CONVERT(nvarchar(12), @MaxEntries)
              + N'. Erhoehen Sie @MaxEntries oder grenzen Sie @RelativePath weiter ein.'
          ELSE REPLACE(LEFT(ERROR_MESSAGE(), 1800), N'%', N'%%')
        END;
        THROW 51540, @ProviderError, 1;
    END CATCH;
    EXEC [toolbelt_filesystem].[USP_InternalRouteResult]
          @ResultTable = @ResultTable
        , @KeepData = @KeepData;
END;
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_CreateDirectory]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @ExecutionIdentity varchar(16) = 'Caller'
  , @ResultTable sysname = NULL
  , @KeepData bit = 0
  , @Debug tinyint = 0
  , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@Hilfe, 0) = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_filesystem' AS sysname) AS SchemaName,
            CAST(N'USP_CreateDirectory' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Erstellt ein Verzeichnis unter einem freigegebenen Root.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_CreateDirectory
 @RootAlias=N''ExampleRoot'', @RelativePath=N''example-dir'', @ExecutionIdentity=N''Caller'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'RootAlias', N'nvarchar(128)', NULL, 0, NULL, CAST(N'RootAlias.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'RelativePath', N'nvarchar(4000)', NULL, 0, NULL, CAST(N'RelativePath.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'State', N'varchar(16)', NULL, 0, NULL, CAST(N'State.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Windows-Dateisystem; Rootfreigaben, ExecutionIdentity und Betriebssystemrechte bleiben erforderlich. Hilfe führt keine Dateioperation und keine Rootprüfung aus.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@RootAlias', N'sysname', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@RelativePath', N'nvarchar(4000)', 1, 0, N'NULL', CAST(N'Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N''inbox\sample.txt''; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leer ist erlaubt und bezeichnet den Root; normale fehlende Unterverzeichnisse werden innerhalb der freigegebenen Rootkette angelegt. NULL ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@ExecutionIdentity', N'varchar(16)', 0, 0, N'''Caller''', CAST(N'Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
    CREATE TABLE #tbx_fs_result ([RootAlias] nvarchar(128) NOT NULL, [RelativePath] nvarchar(4000) NOT NULL, [State] varchar(16) NOT NULL);
    DECLARE @ClrExecutionIdentity nvarchar(16) = CONVERT(nvarchar(16), @ExecutionIdentity);
    BEGIN TRY
        INSERT INTO #tbx_fs_result
        EXEC [toolbelt_filesystem].[CLR_CreateDirectory]
              @RootAlias
          , @RelativePath
          , @ClrExecutionIdentity;
    END TRY
    BEGIN CATCH
      DECLARE @ProviderError nvarchar(2048) = N'Dateisystemprovider konnte das Verzeichnis nicht erstellen. Ursache: ' + REPLACE(LEFT(ERROR_MESSAGE(), 1700), N'%', N'%%');
        THROW 51540, @ProviderError, 1;
    END CATCH;
    EXEC [toolbelt_filesystem].[USP_InternalRouteResult]
          @ResultTable = @ResultTable
        , @KeepData = @KeepData;
END;
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_RemoveFile]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @ExecutionIdentity varchar(16) = 'Caller'
  , @ResultTable sysname = NULL
  , @KeepData bit = 0
  , @Debug tinyint = 0
  , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@Hilfe, 0) = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_filesystem' AS sysname) AS SchemaName,
            CAST(N'USP_RemoveFile' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Entfernt eine Datei unter einem freigegebenen Root.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_RemoveFile
 @RootAlias=N''ExampleRoot'', @RelativePath=N''own-example.bin'', @ExecutionIdentity=N''Caller'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'RootAlias', N'nvarchar(128)', NULL, 0, NULL, CAST(N'RootAlias.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'RelativePath', N'nvarchar(4000)', NULL, 0, NULL, CAST(N'RelativePath.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'State', N'varchar(16)', NULL, 0, NULL, CAST(N'State.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Windows-Dateisystem; Rootfreigaben, ExecutionIdentity und Betriebssystemrechte bleiben erforderlich. Hilfe führt keine Dateioperation und keine Rootprüfung aus.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@RootAlias', N'sysname', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@RelativePath', N'nvarchar(4000)', 1, 0, N'NULL', CAST(N'Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N''inbox\sample.txt''; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Nicht leer, muss eine vorhandene reguläre Datei adressieren, keine Verzeichnisse/Mehrfachauswahl. Löscht genau die handlegebundene Datei; kein Recycle-Bin-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@ExecutionIdentity', N'varchar(16)', 0, 0, N'''Caller''', CAST(N'Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
    CREATE TABLE #tbx_fs_result ([RootAlias] nvarchar(128) NOT NULL, [RelativePath] nvarchar(4000) NOT NULL, [State] varchar(16) NOT NULL);
    DECLARE @ClrExecutionIdentity nvarchar(16) = CONVERT(nvarchar(16), @ExecutionIdentity);
    BEGIN TRY
        INSERT INTO #tbx_fs_result
        EXEC [toolbelt_filesystem].[CLR_RemoveFile]
              @RootAlias
          , @RelativePath
          , @ClrExecutionIdentity;
    END TRY
    BEGIN CATCH
      DECLARE @ProviderError nvarchar(2048) = N'Dateisystemprovider konnte die Datei nicht entfernen. Ursache: ' + REPLACE(LEFT(ERROR_MESSAGE(), 1700), N'%', N'%%');
        THROW 51540, @ProviderError, 1;
    END CATCH;
    EXEC [toolbelt_filesystem].[USP_InternalRouteResult]
          @ResultTable = @ResultTable
        , @KeepData = @KeepData;
END;
GO

CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_RemoveDirectory]
(
    @RootAlias sysname = NULL
  , @RelativePath nvarchar(4000) = NULL
  , @Recursive bit = 0
  , @MaxDepth int = 32
  , @MaxEntries int = 10000
  , @ExecutionIdentity varchar(16) = 'Caller'
  , @ResultTable sysname = NULL
  , @KeepData bit = 0
  , @Debug tinyint = 0
  , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@Hilfe, 0) = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_filesystem' AS sysname) AS SchemaName,
            CAST(N'USP_RemoveDirectory' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Entfernt ein Verzeichnis; rekursives Entfernen ist explizit und begrenzt.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_RemoveDirectory
 @RootAlias=N''ExampleRoot'', @RelativePath=N''own-example-dir'', @Recursive=0, @ExecutionIdentity=N''Caller'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'RootAlias', N'nvarchar(128)', NULL, 0, NULL, CAST(N'RootAlias.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'RelativePath', N'nvarchar(4000)', NULL, 0, NULL, CAST(N'RelativePath.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'State', N'varchar(16)', NULL, 0, NULL, CAST(N'State.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Windows-Dateisystem; Rootfreigaben, ExecutionIdentity und Betriebssystemrechte bleiben erforderlich. Hilfe führt keine Dateioperation und keine Rootprüfung aus.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@RootAlias', N'sysname', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@RelativePath', N'nvarchar(4000)', 1, 0, N'NULL', CAST(N'Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N''inbox\sample.txt''; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Leer kann syntaktisch aufgelöst werden, aber der Root selbst darf niemals gelöscht werden. Muss ein vorhandenes Verzeichnis sein; keine Wildcard-/Mehrfachauswahl.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@Recursive', N'bit', 0, 0, N'0', CAST(N'Taxativ im gebundenen bit: 0 bearbeitet nur das explizite Verzeichnis ohne rekursiven Abstieg (Default); 1 erlaubt begrenzten Abstieg gemäß MaxDepth/MaxEntries. NULL ist für CLR-bool ungültig und kein Default. Bei 0 muss das Verzeichnis leer sein.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@MaxDepth', N'int', 0, 0, N'32', CAST(N'Ganzzahl 0..2147483647, Default 32; der Remove-Pfad besitzt anders als List keine zusätzliche 64er-Obergrenze. Startdirectory hat Tiefe 0. Bei Recursive=1 wird jeder nötige Abstieg über das Budget vor der ersten Löschmutation abgewiesen. NULL/negativ ungültig; nicht still trunciert.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@MaxEntries', N'int', 0, 0, N'10000', CAST(N'Ganzzahl 1..2147483647, Default 10000; der Remove-Pfad besitzt anders als List keine zusätzliche 10000er-Obergrenze. Zählt sämtliche Kinder im vollständigen Vorab-Löschplan, ohne das Startdirectory selbst. NULL/0/negativ ungültig; Überschreitung vor erster Mutation. Keine automatische unbegrenzte Löschung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@ExecutionIdentity', N'varchar(16)', 0, 0, N'''Caller''', CAST(N'Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
    CREATE TABLE #tbx_fs_result ([RootAlias] nvarchar(128) NOT NULL, [RelativePath] nvarchar(4000) NOT NULL, [State] varchar(16) NOT NULL);
    DECLARE @ClrExecutionIdentity nvarchar(16) = CONVERT(nvarchar(16), @ExecutionIdentity);
    BEGIN TRY
        INSERT INTO #tbx_fs_result
        EXEC [toolbelt_filesystem].[CLR_RemoveDirectory]
              @RootAlias
          , @RelativePath
          , @Recursive
          , @MaxDepth
          , @MaxEntries
          , @ClrExecutionIdentity;
    END TRY
    BEGIN CATCH
      DECLARE @ProviderError nvarchar(2048) = N'Dateisystemprovider konnte das Verzeichnis nicht entfernen. Ursache: ' + REPLACE(LEFT(ERROR_MESSAGE(), 1700), N'%', N'%%');
        THROW 51540, @ProviderError, 1;
    END CATCH;
    EXEC [toolbelt_filesystem].[USP_InternalRouteResult]
          @ResultTable = @ResultTable
        , @KeepData = @KeepData;
END;
GO
