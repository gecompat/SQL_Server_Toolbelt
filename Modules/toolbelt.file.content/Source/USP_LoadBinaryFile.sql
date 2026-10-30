-- ============================================================================
-- Objekt:          toolbelt_file.USP_LoadBinaryFile
-- Typ:             Stored Procedure
-- Zweck:           Liest eine Datei als varbinary(max) über OPENROWSET(BULK...).
-- Vertrag:         Documentation/Architecture/FILE_CONTENT_MODULE_DESIGN.md
-- Parameter:       @FilePath nvarchar(4000) = NULL (nur Help-Aufruf)
--                  @MaxBytes bigint = NULL
--                  @Debug tinyint = 0
--                  @Hilfe bit = 0
--                  @ResultTable sysname = NULL
--                  @KeepData bit = 0
-- Resultset:       Genau eine Zeile mit Content, BytesRead, IsValid,
--                  ValidationCode, ValidationMessage.
-- Dependencies:    toolbelt_file.FileContentRootAllowlist
-- Rechte:          EXECUTE auf der Procedure;
--                  ADMINISTER BULK OPERATIONS oder ad hoc distributed queries;
--                  Lesezugriff auf den Dateipfad.
-- Versionen:       SQL Server 2019, 2022 und 2025.
-- Plattformen:     Windows und Linux.
-- Fehlerverhalten: Fachliche Fehler werden als Resultset-Zeile mit
--                  IsValid = 0 zurückgegeben. Unbehandelte Engine-Fehler
--                  propagieren als THROW.
-- Performance:     Einzelner OPENROWSET(BULK...)-Aufruf; Limitierung durch
--                  @MaxBytes erfolgt nicht auf Byte-Ebene, sondern als
--                  Validierung nach dem Lesen.
-- Einschränkungen:  Dateigröße ist durch varbinary(max) auf ca. 2 GB begrenzt.
-- ============================================================================

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_file].[USP_LoadBinaryFile]
(
      @FilePath  nvarchar(4000) = NULL
    , @MaxBytes  bigint       = NULL
    , @ResultTable sysname    = NULL
    , @KeepData bit           = 0
    , @Debug     tinyint      = 0
    , @Hilfe     bit          = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @Hilfe    = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_file' AS sysname) AS SchemaName,
            CAST(N'USP_LoadBinaryFile' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Liest eine Datei als varbinary(max) über OPENROWSET(BULK...). Der Pfad muss unter einem Eintrag der Root-Allowlist liegen.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'Content', N'varbinary(max)', 0, 1, NULL, CAST(N'Der binäre Dateiinhalt. Bei Validierungsfehlern NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'BytesRead', N'bigint', 0, 0, NULL, CAST(N'Anzahl gelesener Bytes. Bei Validierungsfehlern vor dem Lesen 0.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'IsValid', N'bit', 0, 0, NULL, CAST(N'1, wenn der Inhalt erfolgreich gelesen wurde; 0 bei fachlichem Fehler.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'ValidationCode', N'int', 0, 1, NULL, CAST(N'Fachlicher Fehlercode oder NULL bei Erfolg.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'ValidationMessage', N'nvarchar(4000)', 0, 1, NULL, CAST(N'Fachliche Fehlermeldung oder NULL bei Erfolg.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51320', NULL, NULL, NULL, NULL, CAST(N'Ungültiger oder leerer Dateipfad.' AS nvarchar(max)), NULL),
        (N'ERROR', 2, N'51321', NULL, NULL, NULL, NULL, CAST(N'Pfad liegt außerhalb der konfigurierten Root-Allowlist.' AS nvarchar(max)), NULL),
        (N'ERROR', 3, N'51322', NULL, NULL, NULL, NULL, CAST(N'Pfad enthält verbotene relative Segmente oder Traversal.' AS nvarchar(max)), NULL),
        (N'ERROR', 4, N'51323', NULL, NULL, NULL, NULL, CAST(N'Datei überschreitet @MaxBytes.' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Erforderlich ist EXECUTE auf toolbelt_file.USP_LoadBinaryFile, Lesezugriff auf den Dateipfad sowie ADMINISTER BULK OPERATIONS oder ad hoc distributed queries für OPENROWSET(BULK...). Für @ResultTable zusätzlich EXECUTE auf toolbelt_core.USP_PrepareResultTable.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Dateigröße ist durch varbinary(max) auf ca. 2 GB begrenzt. OPENROWSET(BULK...) liest die gesamte Datei; @MaxBytes prüft erst nach dem Lesen. ResultTable-Änderung und Datei-I/O liegen in derselben Transaktion.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Liest eine Datei aus einem erlaubten Root.' AS nvarchar(max)), CAST(N'EXEC toolbelt_file.USP_LoadBinaryFile
      @FilePath = N''/var/opt/mssql/data/allowed/sample.bin'';' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@FilePath', N'nvarchar(4000)', 1, 0, N'NULL', CAST(N'Absoluter Dateipfad als einzelner Textwert, Windows-Laufwerk/UNC oder Unix-/Pfad; normale Randspaces werden getrimmt, leer/NULL (technischer Help-Default) ungültig. Muss literal und case-sensitiv an einer Verzeichnisgrenze unter einem aktiven FileContentRootAllowlist-Root liegen; Traversal nach außen abgewiesen. Kein RootAlias und keine SQL-Fragmente/Wildcardfreigabe. Aktuelle Implementierungsgrenze: das BULK-Pfadliteral wird mit QUOTENAME erzeugt, das über 128 Zeichen NULL liefert; die nvarchar(4000)-Signatur belegt daher keine Unterstützung längerer Pfade. Betriebssystem-/BULK-Rechte bleiben erforderlich; keine handlegebundene Sandbox.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@MaxBytes', N'bigint', 0, 1, N'NULL', CAST(N'Optionaler bigint-Bytegrenzwert: NULL (Default) oder 0 deaktiviert die eigene Größenprüfung; positiv 1..9223372036854775807 begrenzt die gelesenen Rohbytes. Prüfung erfolgt nach vollständigem SINGLE_BLOB-Lesen, kein I/O-/Speicher-Vorabcap. Negative Werte werden aktuell nicht als Argumentfehler validiert, sondern führen bei tatsächlich gelesenen nicht negativen Bytegrößen zur Überschreitungszeile 51323; für gültige Aufrufe NULL/0/positive Werte verwenden.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Das Ziel wird vor Datei-I/O vorbereitet; Provider-/Decoderfehler rollen den eigenen SQL-Ausgabescope zurück.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene Dateiinhaltsdiagnose; ausschließlich im ResultTable-Pfad an den kanonischen Helper weitergereicht.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    DECLARE @InitialTransactionCount int = @@TRANCOUNT
          , @StartedTransaction bit = 0
          , @SavepointCreated bit = 0
          , @SavepointName varchar(32) = CONVERT(varchar(32), 'tbx_file_' + LEFT(REPLACE(CONVERT(varchar(36), NEWID()), '-', ''), 23))
          , @InsertResultSql nvarchar(max);

    IF @ResultTable IS NOT NULL SET XACT_ABORT OFF;
    SET @KeepData = ISNULL(@KeepData, 0);
    SET @Debug = ISNULL(@Debug, 0);
    IF @ResultTable IS NOT NULL AND @InitialTransactionCount > 0 AND XACT_STATE() <> 1
        THROW 51028, N'Der Callertransaktionszustand erlaubt keinen kontrollierten ResultTable-Savepoint.', 1;
    CREATE TABLE #tbx_LoadBinaryFileResult
    (
          Content varbinary(max) NULL
        , BytesRead bigint NOT NULL
        , IsValid bit NOT NULL
        , ValidationCode int NULL
        , ValidationMessage nvarchar(4000) NULL
    );
    BEGIN TRY
    IF @ResultTable IS NOT NULL
    BEGIN
        IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
            THROW 51908, N'Für @ResultTable fehlt toolbelt.core.result-table.', 1;
        IF @InitialTransactionCount = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @StartedTransaction = 1;
        END
        ELSE
        BEGIN
            IF XACT_STATE() <> 1 THROW 51028, N'Der Callertransaktionszustand erlaubt keinen kontrollierten ResultTable-Savepoint.', 1;
            SAVE TRANSACTION @SavepointName;
            SET @SavepointCreated = 1;
        END;
        EXEC toolbelt_core.USP_PrepareResultTable
              @ResultTableToAlter = @ResultTable
            , @LikeTable = N'#tbx_LoadBinaryFileResult'
            , @KeepData = @KeepData
            , @Debug = @Debug;
    END;
    SET @FilePath = NULLIF(LTRIM(RTRIM(@FilePath)), N'');
    SET @MaxBytes = NULLIF(@MaxBytes, 0);
    SET @Debug    = ISNULL(@Debug, 0);
    SET @KeepData = ISNULL(@KeepData, 0);
    IF @FilePath IS NULL
    BEGIN
        INSERT #tbx_LoadBinaryFileResult VALUES(NULL, 0, 0, 51320, N'Ungültiger oder leerer Dateipfad.');
        GOTO EmitResult;
    END;

    DECLARE @NormalizedPath nvarchar(4000) = @FilePath;

    -- Plattformunabhängige Normalisierung: Backslash -> Slash für Vergleich.
    SET @NormalizedPath = REPLACE(@NormalizedPath, N'\\', N'/');
    SET @NormalizedPath = REPLACE(@NormalizedPath, N'\', N'/');

    -- Traversal-Prüfung.
    IF @NormalizedPath LIKE N'%/../%' OR @NormalizedPath LIKE N'%/..'
       OR @NormalizedPath LIKE N'../%'
    BEGIN
        INSERT #tbx_LoadBinaryFileResult VALUES(NULL, 0, 0, 51322, N'Pfad enthält verbotene relative Segmente oder Traversal.');
        GOTO EmitResult;
    END;

    -- Pfad muss absolut sein: lokaler Buchstabe oder UNC.
    IF @NormalizedPath NOT LIKE N'[A-Za-z]:/%'
       AND @NormalizedPath NOT LIKE N'//%'
       AND @NormalizedPath NOT LIKE N'/%'
    BEGIN
        INSERT #tbx_LoadBinaryFileResult VALUES(NULL, 0, 0, 51320, N'Ungültiger oder leerer Dateipfad.');
        GOTO EmitResult;
    END;

    -- Allowlist-Prüfung (Latin1_General_100_BIN2 für byteidentischen Vergleich).
    IF NOT EXISTS
       (
:r ../Source/FileContentRootPredicate.sql
       )
    BEGIN
        INSERT #tbx_LoadBinaryFileResult VALUES(NULL, 0, 0, 51321, N'Pfad liegt außerhalb der konfigurierten Root-Allowlist.');
        GOTO EmitResult;
    END;

    DECLARE @Sql nvarchar(max)
          , @Content varbinary(max)
          , @BytesRead bigint;

    SET @Sql = N'SET @Content = (SELECT BulkColumn FROM OPENROWSET(BULK '
               + QUOTENAME(@FilePath, N'''')
               + N', SINGLE_BLOB) AS x);';

    BEGIN TRY
        EXEC sys.sp_executesql
              @stmt = @Sql
            , @params = N'@Content varbinary(max) OUTPUT'
            , @Content = @Content OUTPUT;

        SET @BytesRead = DATALENGTH(@Content);

        IF @MaxBytes IS NOT NULL AND @BytesRead > @MaxBytes
        BEGIN
            INSERT #tbx_LoadBinaryFileResult VALUES(NULL, @BytesRead, 0, 51323, N'Datei überschreitet @MaxBytes.');
            GOTO EmitResult;
        END;

        INSERT #tbx_LoadBinaryFileResult VALUES(@Content, @BytesRead, 1, NULL, NULL);
        GOTO EmitResult;
    END TRY
    BEGIN CATCH
      DECLARE @ProviderError nvarchar(2048) = N'Datei konnte nicht ueber OPENROWSET gelesen werden. Engine-Meldung: '
        + REPLACE(LEFT(ERROR_MESSAGE(), 1700), N'%', N'%%');
      THROW 51326, @ProviderError, 1;
    END CATCH;
    END TRY
    BEGIN CATCH
        IF @StartedTransaction = 1 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @SavepointCreated = 1 AND XACT_STATE() = 1 ROLLBACK TRANSACTION @SavepointName;
        THROW;
    END CATCH;

EmitResult:
    IF @ResultTable IS NULL
    BEGIN
        SELECT Content, BytesRead, IsValid, ValidationCode, ValidationMessage
        FROM #tbx_LoadBinaryFileResult;
        RETURN 0;
    END;

    BEGIN TRY
        SET @InsertResultSql = N'INSERT INTO ' + QUOTENAME(@ResultTable)
            + N' (Content,BytesRead,IsValid,ValidationCode,ValidationMessage)'
            + N' SELECT Content,BytesRead,IsValid,ValidationCode,ValidationMessage FROM #tbx_LoadBinaryFileResult;';
        EXEC sys.sp_executesql @InsertResultSql;
        IF @StartedTransaction = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @StartedTransaction = 1 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @SavepointCreated = 1 AND XACT_STATE() = 1 ROLLBACK TRANSACTION @SavepointName;
        THROW;
    END CATCH;
    RETURN 0;
END;
GO
