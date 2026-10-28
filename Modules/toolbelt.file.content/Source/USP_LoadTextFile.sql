-- ============================================================================
-- Objekt:          toolbelt_file.USP_LoadTextFile
-- Typ:             Stored Procedure
-- Zweck:           Liest eine Datei als nvarchar(max) mit Encoding-Erkennung.
-- Vertrag:         Documentation/Architecture/FILE_CONTENT_MODULE_DESIGN.md
-- Parameter:       @FilePath nvarchar(4000) = NULL (nur Help-Aufruf)
--                  @FallbackEncoding nvarchar(128) = 'Windows-1252'
--                  @MaxBytes bigint = NULL
--                  @Debug tinyint = 0
--                  @Hilfe bit = 0
--                  @ResultTable sysname = NULL
--                  @KeepData bit = 0
-- Resultset:       Genau eine Zeile mit Content, BytesRead, EncodingDetected,
--                  BomPresent, IsValid, ValidationCode, ValidationMessage.
-- Dependencies:    toolbelt_file.FileContentRootAllowlist
-- Rechte:          EXECUTE auf der Procedure;
--                  ADMINISTER BULK OPERATIONS oder ad hoc distributed queries;
--                  Lesezugriff auf den Dateipfad.
-- Versionen:       SQL Server 2019, 2022 und 2025.
-- Plattformen:     Windows und Linux.
-- Fehlerverhalten: Fachliche Fehler werden als Resultset-Zeile mit
--                  IsValid = 0 zurückgegeben. Unbehandelte Engine-Fehler
--                  propagieren als THROW.
-- Performance:     Ein SINGLE_BLOB-Snapshot für Größe, BOM und Text.
-- Einschränkungen:  Dateigröße ist durch nvarchar(max) auf ca. 2 GB begrenzt.
--                  Encoding-Erkennung erfolgt über BOM; Inhalt ohne BOM wird
--                  mit @FallbackEncoding als 8-Bit-Codepage gelesen.
-- ============================================================================

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_file].[USP_LoadTextFile]
(
      @FilePath          nvarchar(4000) = NULL
    , @FallbackEncoding  nvarchar(128) = N'Windows-1252'
    , @MaxBytes          bigint        = NULL
    , @ResultTable       sysname       = NULL
    , @KeepData          bit           = 0
    , @Debug             tinyint       = 0
    , @Hilfe             bit           = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @Hilfe            = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        DECLARE @Help TABLE
        (
              HelpContractVersion varchar(16)    NOT NULL
            , SchemaName          sysname        NOT NULL
            , ObjectName          sysname        NOT NULL
            , Section             varchar(32)    NOT NULL
            , Ordinal             int            NOT NULL
            , ItemName            sysname        NULL
            , SqlDataType         varchar(256)   NULL
            , IsRequired          bit            NULL
            , IsNullable          bit            NULL
            , DefaultValue        nvarchar(4000) NULL
            , Description         nvarchar(max)  NOT NULL
            , ExampleSql          nvarchar(max)  NULL
        );

        INSERT INTO @Help
        (
              HelpContractVersion
            , SchemaName
            , ObjectName
            , Section
            , Ordinal
            , ItemName
            , SqlDataType
            , IsRequired
            , IsNullable
            , DefaultValue
            , Description
            , ExampleSql
        )
        VALUES
          ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'DESCRIPTION', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Liest eine Textdatei als nvarchar(max) über OPENROWSET(BULK...). Erkennt BOM und decodiert entsprechend; Inhalt ohne BOM wird mit @FallbackEncoding gelesen.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'PARAMETER', 1
          , N'@FilePath', 'nvarchar(4000)', 1, 0, N'NULL'
          , N'Absoluter Pfad zur Datei. UNC-Pfade sind erlaubt. Relative Pfade, ..-Segmente und Pfade außerhalb der Allowlist werden abgelehnt.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'PARAMETER', 2
          , N'@FallbackEncoding', 'nvarchar(128)', 0, 1, N'Windows-1252'
          , N'Codepage für Dateien ohne BOM. Unterstützt werden Windows-1252 und SQL_Latin1_General_CP1_CI_AS äquivalente 8-Bit-Codepages.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'PARAMETER', 3
          , N'@MaxBytes', 'bigint', 0, 1, N'NULL'
          , N'Optionales Limit. Wenn die gelesene Datei mehr Bytes enthält, wird ein Validierungsfehler zurückgegeben, der Inhalt bleibt jedoch NULL.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'PARAMETER', 6
          , N'@Debug', 'tinyint', 0, 1, N'0'
          , N'Beim ResultTable-Routing Diagnosemeldungen des kanonischen Helpers; keine zusätzlichen fachlichen Resultsets. Im SELECT-Pfad keine Debug-Messages.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'PARAMETER', 7
          , N'@Hilfe', 'bit', 0, 1, N'0'
          , N'1 gibt ausschließlich dieses Help-Resultset aus und ignoriert alle anderen Parameter.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'PARAMETER', 4
          , N'@ResultTable', 'sysname', 0, 1, N'NULL'
          , N'Optionaler lokaler Temp-Tabellenname für das Ergebnis.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'PARAMETER', 5
          , N'@KeepData', 'bit', 0, 1, N'0'
          , N'Bei ResultTable-Routing bleiben vorhandene Zielzeilen erhalten, wenn 1.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'RESULT_COLUMN', 1
          , N'Content', 'nvarchar(max)', 0, 1, NULL
          , N'Der Text-Inhalt. Bei Validierungsfehlern NULL.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'RESULT_COLUMN', 2
          , N'BytesRead', 'bigint', 0, 0, NULL
          , N'Anzahl gelesener Bytes. Bei Validierungsfehlern vor dem Lesen 0.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'RESULT_COLUMN', 3
          , N'EncodingDetected', 'nvarchar(128)', 0, 1, NULL
          , N'Erkanntes Encoding: UTF-8, UTF-16-LE oder der Wert von @FallbackEncoding. UTF-16-BE und UTF-32 werden nicht unterstützt.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'RESULT_COLUMN', 4
          , N'BomPresent', 'bit', 0, 0, NULL
          , N'1, wenn ein Byte Order Mark vorhanden war; 0 sonst.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'RESULT_COLUMN', 5
          , N'IsValid', 'bit', 0, 0, NULL
          , N'1, wenn der Inhalt erfolgreich gelesen wurde; 0 bei fachlichem Fehler.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'RESULT_COLUMN', 6
          , N'ValidationCode', 'int', 0, 1, NULL
          , N'Fachlicher Fehlercode oder NULL bei Erfolg.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'RESULT_COLUMN', 7
          , N'ValidationMessage', 'nvarchar(4000)', 0, 1, NULL
          , N'Fachliche Fehlermeldung oder NULL bei Erfolg.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'ERROR', 1
          , N'51320', NULL, NULL, NULL, NULL
          , N'Ungültiger oder leerer Dateipfad.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'ERROR', 2
          , N'51321', NULL, NULL, NULL, NULL
          , N'Pfad liegt außerhalb der konfigurierten Root-Allowlist.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'ERROR', 3
          , N'51322', NULL, NULL, NULL, NULL
          , N'Pfad enthält verbotene relative Segmente oder Traversal.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'ERROR', 4
          , N'51323', NULL, NULL, NULL, NULL
          , N'Datei überschreitet @MaxBytes.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'ERROR', 5
          , N'51324', NULL, NULL, NULL, NULL
          , N'Fallback-Encoding wird nicht unterstützt.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'ERROR', 6
          , N'51325', NULL, NULL, NULL, NULL
          , N'Encoding wird nicht unterstützt (UTF-16-BE, UTF-32).'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'PERMISSION', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Erforderlich ist EXECUTE auf toolbelt_file.USP_LoadTextFile, Lesezugriff auf den Dateipfad sowie ADMINISTER BULK OPERATIONS oder ad hoc distributed queries für OPENROWSET(BULK...). Für @ResultTable zusätzlich EXECUTE auf toolbelt_core.USP_PrepareResultTable.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'LIMITATION', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Ein SINGLE_BLOB-Snapshot bindet Größe, BOM und Text. UTF-8 und Windows-1252 werden mit expliziten Collations, UTF-16-LE aus geraden Bytefolgen dekodiert. UTF-16-BE und UTF-32 bleiben ausgeschlossen. Die erste BLOB-Allokation ist kein Vorallokationsbudget. ResultTable-Änderung und Datei-I/O liegen in derselben Transaktion.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'EXAMPLE', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Liest eine Textdatei aus einem erlaubten Root.'
          , N'EXEC toolbelt_file.USP_LoadTextFile
      @FilePath = N''/var/opt/mssql/data/allowed/sample.txt'';' );

        SELECT
              HelpContractVersion
            , SchemaName
            , ObjectName
            , Section
            , Ordinal
            , ItemName
            , SqlDataType
            , IsRequired
            , IsNullable
            , DefaultValue
            , Description
            , ExampleSql
        FROM @Help
        ORDER BY
              CASE Section
                  WHEN 'DESCRIPTION'   THEN 1
                  WHEN 'PARAMETER'     THEN 2
                  WHEN 'RESULT_COLUMN' THEN 3
                  WHEN 'ERROR'         THEN 4
                  WHEN 'PERMISSION'    THEN 5
                  WHEN 'LIMITATION'    THEN 6
                  WHEN 'EXAMPLE'       THEN 7
              END
            , Ordinal;

        RETURN 0;
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
    CREATE TABLE #tbx_LoadTextFileResult
    (
          Content nvarchar(max) NULL
        , BytesRead bigint NOT NULL
        , EncodingDetected nvarchar(128) NULL
        , BomPresent bit NOT NULL
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
            , @LikeTable = N'#tbx_LoadTextFileResult'
            , @KeepData = @KeepData
            , @Debug = @Debug;
    END;

    SET @FilePath         = NULLIF(LTRIM(RTRIM(@FilePath)), N'');
    SET @FallbackEncoding = ISNULL(NULLIF(LTRIM(RTRIM(@FallbackEncoding)), N''), N'Windows-1252');
    SET @MaxBytes         = NULLIF(@MaxBytes, 0);
    SET @Debug            = ISNULL(@Debug, 0);
    IF @FilePath IS NULL
    BEGIN
        INSERT #tbx_LoadTextFileResult VALUES(NULL, 0, NULL, 0, 0, 51320, N'Ungültiger oder leerer Dateipfad.');
        GOTO EmitResult;
    END;

    IF @FallbackEncoding NOT IN (N'Windows-1252', N'SQL_Latin1_General_CP1_CI_AS')
    BEGIN
        INSERT #tbx_LoadTextFileResult VALUES(NULL, 0, NULL, 0, 0, 51324, N'Fallback-Encoding wird nicht unterstützt.');
        GOTO EmitResult;
    END;

    -- UTF-8 als Fallback-Encoding ist nicht sinnvoll, weil BOM-lose UTF-8-Dateien
    -- nicht von Windows-1252 unterschieden werden können. Wir erlauben daher nur
    -- Windows-1252 als expliziten Fallback.
    SET @FallbackEncoding = N'Windows-1252';

    DECLARE @NormalizedPath nvarchar(4000) = @FilePath;

    SET @NormalizedPath = REPLACE(@NormalizedPath, N'\\', N'/');
    SET @NormalizedPath = REPLACE(@NormalizedPath, N'\', N'/');

    IF @NormalizedPath LIKE N'%/../%' OR @NormalizedPath LIKE N'%/..'
       OR @NormalizedPath LIKE N'../%'
    BEGIN
        INSERT #tbx_LoadTextFileResult VALUES(NULL, 0, NULL, 0, 0, 51322, N'Pfad enthält verbotene relative Segmente oder Traversal.');
        GOTO EmitResult;
    END;

    IF @NormalizedPath NOT LIKE N'[A-Za-z]:/%'
       AND @NormalizedPath NOT LIKE N'//%'
       AND @NormalizedPath NOT LIKE N'/%'
    BEGIN
        INSERT #tbx_LoadTextFileResult VALUES(NULL, 0, NULL, 0, 0, 51320, N'Ungültiger oder leerer Dateipfad.');
        GOTO EmitResult;
    END;

    IF NOT EXISTS
       (
:r ../Source/FileContentRootPredicate.sql
       )
    BEGIN
        INSERT #tbx_LoadTextFileResult VALUES(NULL, 0, NULL, 0, 0, 51321, N'Pfad liegt außerhalb der konfigurierten Root-Allowlist.');
        GOTO EmitResult;
    END;

    DECLARE @Sql nvarchar(max)
          , @Snapshot varbinary(max)
          , @Header varbinary(4)
          , @EncodingDetected nvarchar(128)
          , @BomPresent bit = 0
          , @Content nvarchar(max)
          , @BytesRead bigint;

    -- BOM-Heuristik und exakte Dateigröße über denselben SINGLE_BLOB-Lesezugriff.
    SET @Sql = N'SELECT TOP (1)'
               + N' @Snapshot = BulkColumn, @Header = SUBSTRING(BulkColumn, 1, 4),'
               + N' @BytesRead = DATALENGTH(BulkColumn)'
               + N' FROM OPENROWSET(BULK '
               + QUOTENAME(@FilePath, N'''')
               + N', SINGLE_BLOB) AS x;';

    BEGIN TRY
        EXEC sys.sp_executesql
              @stmt = @Sql
            , @params = N'@Snapshot varbinary(max) OUTPUT, @Header varbinary(4) OUTPUT, @BytesRead bigint OUTPUT'
            , @Snapshot = @Snapshot OUTPUT
            , @Header = @Header OUTPUT
            , @BytesRead = @BytesRead OUTPUT;
    END TRY
    BEGIN CATCH
      DECLARE @HeaderProviderError nvarchar(2048) = N'Datei konnte nicht ueber OPENROWSET gelesen werden. Engine-Meldung: '
        + REPLACE(LEFT(ERROR_MESSAGE(), 1700), N'%', N'%%');
      THROW 51326, @HeaderProviderError, 1;
    END CATCH;

    IF @MaxBytes IS NOT NULL AND @BytesRead > @MaxBytes
    BEGIN
        INSERT #tbx_LoadTextFileResult VALUES(NULL, @BytesRead, NULL, 0, 0, 51323, N'Datei überschreitet @MaxBytes.');
        GOTO EmitResult;
    END;

    -- Vierbyteige BOMs müssen vor den zweibyteigen Präfixen geprüft werden.
    IF @Header = 0xFFFE0000 OR @Header = 0x0000FEFF
    BEGIN
        INSERT #tbx_LoadTextFileResult VALUES(NULL, @BytesRead, CASE @Header WHEN 0xFFFE0000 THEN N'UTF-32-LE' ELSE N'UTF-32-BE' END, 1, 0, 51325, N'UTF-32 wird nicht unterstützt.');
        GOTO EmitResult;
    END
    ELSE IF SUBSTRING(@Header, 1, 3) = 0xEFBBBF
    BEGIN
        SET @EncodingDetected = N'UTF-8';
        SET @BomPresent = 1;
    END
    ELSE IF SUBSTRING(@Header, 1, 2) = 0xFFFE
    BEGIN
        SET @EncodingDetected = N'UTF-16-LE';
        SET @BomPresent = 1;
    END
    ELSE IF SUBSTRING(@Header, 1, 2) = 0xFEFF
    BEGIN
        INSERT #tbx_LoadTextFileResult VALUES(NULL, @BytesRead, N'UTF-16-BE', 1, 0, 51325, N'UTF-16-BE wird nicht unterstützt.');
        GOTO EmitResult;
    END
    ELSE
    BEGIN
        SET @EncodingDetected = @FallbackEncoding;
        SET @BomPresent = 0;
    END;

    -- Genau ein Byte-Snapshot für Größe, BOM und Decoder. Keine zweite
    -- Pfadauflösung; OPENROWSET selbst besitzt keine Vorallokationsgarantie.
    DECLARE @Payload varbinary(max) = SUBSTRING(@Snapshot,
        CASE WHEN @BomPresent = 0 THEN 1 WHEN @EncodingDetected = N'UTF-8' THEN 4 ELSE 3 END,
        2147483647);
    BEGIN TRY
        IF @EncodingDetected = N'UTF-16-LE'
        BEGIN
            IF DATALENGTH(@Payload) % 2 <> 0
                THROW 51326, N'Ungültige UTF-16-LE-Bytelänge.', 1;
            SET @Content = CONVERT(nvarchar(max), @Payload);
        END
        ELSE IF @EncodingDetected = N'UTF-8'
        BEGIN
            DECLARE @Utf8Bytes TABLE(Value varchar(max) COLLATE Latin1_General_100_BIN2_UTF8);
            INSERT @Utf8Bytes(Value) VALUES(@Payload);
            SELECT @Content = CONVERT(nvarchar(max), Value) FROM @Utf8Bytes;
            DECLARE @Utf8Roundtrip varbinary(max) = CONVERT(varbinary(max),
                CONVERT(varchar(max), @Content COLLATE Latin1_General_100_BIN2_UTF8));
            IF DATALENGTH(@Utf8Roundtrip) <> DATALENGTH(@Payload) OR @Utf8Roundtrip <> @Payload
                THROW 51326, N'Ungültige UTF-8-Bytesequenz.', 1;
        END
        ELSE
        BEGIN
            DECLARE @Cp1252Bytes TABLE(Value varchar(max) COLLATE Latin1_General_100_BIN2);
            INSERT @Cp1252Bytes(Value) VALUES(@Payload);
            SELECT @Content = CONVERT(nvarchar(max), Value) FROM @Cp1252Bytes;
        END;

        INSERT #tbx_LoadTextFileResult VALUES(@Content, @BytesRead, @EncodingDetected, @BomPresent, 1, NULL, NULL);
        GOTO EmitResult;
    END TRY
    BEGIN CATCH
      DECLARE @ContentProviderError nvarchar(2048) = N'Datei konnte nicht ueber OPENROWSET gelesen werden. Engine-Meldung: '
        + REPLACE(LEFT(ERROR_MESSAGE(), 1700), N'%', N'%%');
      THROW 51326, @ContentProviderError, 1;
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
        SELECT Content,BytesRead,EncodingDetected,BomPresent,IsValid,ValidationCode,ValidationMessage
        FROM #tbx_LoadTextFileResult;
        RETURN 0;
    END;
    BEGIN TRY
        SET @InsertResultSql = N'INSERT INTO ' + QUOTENAME(@ResultTable)
            + N' (Content,BytesRead,EncodingDetected,BomPresent,IsValid,ValidationCode,ValidationMessage)'
            + N' SELECT Content,BytesRead,EncodingDetected,BomPresent,IsValid,ValidationCode,ValidationMessage FROM #tbx_LoadTextFileResult;';
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
