-- ============================================================================
-- Objekt:          toolbelt_file.USP_LoadTextFile
-- Typ:             Stored Procedure
-- Zweck:           Liest eine Datei als nvarchar(max) mit Encoding-Erkennung.
-- Vertrag:         Documentation/Architecture/FILE_CONTENT_MODULE_DESIGN.md
-- Parameter:       @FilePath nvarchar(4000)
--                  @FallbackEncoding nvarchar(128) = 'Windows-1252'
--                  @MaxBytes bigint = NULL
--                  @Debug tinyint = 0
--                  @Hilfe bit = 0
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
-- Performance:     Zwei OPENROWSET(BULK...)-Aufrufe: SINGLE_BLOB für BOM-
--                  Heuristik, SINGLE_CLOB/SINGLE_NCLOB für Text.
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
      @FilePath          nvarchar(4000)
    , @FallbackEncoding  nvarchar(128) = N'Windows-1252'
    , @MaxBytes          bigint        = NULL
    , @Debug             tinyint       = 0
    , @Hilfe             bit           = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @FilePath         = NULLIF(LTRIM(RTRIM(@FilePath)), N'');
    SET @FallbackEncoding = ISNULL(NULLIF(LTRIM(RTRIM(@FallbackEncoding)), N''), N'Windows-1252');
    SET @MaxBytes         = NULLIF(@MaxBytes, 0);
    SET @Debug            = ISNULL(@Debug, 0);
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
          , N'@FilePath', 'nvarchar(4000)', 1, 0, NULL
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
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'PARAMETER', 4
          , N'@Debug', 'tinyint', 0, 1, N'0'
          , N'Standardparameter des USP-Vertrags. Version 1 erzeugt keine Debug-Messages.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'PARAMETER', 5
          , N'@Hilfe', 'bit', 0, 1, N'0'
          , N'1 gibt ausschließlich dieses Help-Resultset aus und ignoriert alle anderen Parameter.'
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
          , N'Erkanntes Encoding: UTF-8, UTF-16-LE, UTF-16-BE, UTF-32-LE, UTF-32-BE oder der Wert von @FallbackEncoding.'
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
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'PERMISSION', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Erforderlich ist EXECUTE auf toolbelt_file.USP_LoadTextFile, Lesezugriff auf den Dateipfad sowie ADMINISTER BULK OPERATIONS oder ad hoc distributed queries für OPENROWSET(BULK...).'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadTextFile', 'LIMITATION', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Dateigröße ist durch nvarchar(max) auf ca. 2 GB begrenzt. Encoding-Erkennung erfolgt über BOM; Inhalt ohne BOM wird mit @FallbackEncoding als 8-Bit-Codepage gelesen.'
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

    IF @FilePath IS NULL
    BEGIN
        SELECT
              CAST(NULL AS nvarchar(max)) AS Content
            , CAST(0 AS bigint)           AS BytesRead
            , NULL                        AS EncodingDetected
            , CAST(0 AS bit)              AS BomPresent
            , CAST(0 AS bit)              AS IsValid
            , 51320                       AS ValidationCode
            , N'Ungültiger oder leerer Dateipfad.' AS ValidationMessage;
        RETURN 0;
    END;

    IF @FallbackEncoding NOT IN (N'Windows-1252', N'SQL_Latin1_General_CP1_CI_AS')
    BEGIN
        SELECT
              CAST(NULL AS nvarchar(max)) AS Content
            , CAST(0 AS bigint)           AS BytesRead
            , NULL                        AS EncodingDetected
            , CAST(0 AS bit)              AS BomPresent
            , CAST(0 AS bit)              AS IsValid
            , 51324                       AS ValidationCode
            , N'Fallback-Encoding wird nicht unterstützt.' AS ValidationMessage;
        RETURN 0;
    END;

    DECLARE @NormalizedPath nvarchar(4000) = @FilePath;

    SET @NormalizedPath = REPLACE(@NormalizedPath, N'\\', N'/');
    SET @NormalizedPath = REPLACE(@NormalizedPath, N'\', N'/');

    IF @NormalizedPath LIKE N'%/../%' OR @NormalizedPath LIKE N'%/..'
       OR @NormalizedPath LIKE N'../%'
    BEGIN
        SELECT
              CAST(NULL AS nvarchar(max)) AS Content
            , CAST(0 AS bigint)           AS BytesRead
            , NULL                        AS EncodingDetected
            , CAST(0 AS bit)              AS BomPresent
            , CAST(0 AS bit)              AS IsValid
            , 51322                       AS ValidationCode
            , N'Pfad enthält verbotene relative Segmente oder Traversal.' AS ValidationMessage;
        RETURN 0;
    END;

    IF @NormalizedPath NOT LIKE N'[A-Za-z]:/%' AND @NormalizedPath NOT LIKE N'//%'
    BEGIN
        SELECT
              CAST(NULL AS nvarchar(max)) AS Content
            , CAST(0 AS bigint)           AS BytesRead
            , NULL                        AS EncodingDetected
            , CAST(0 AS bit)              AS BomPresent
            , CAST(0 AS bit)              AS IsValid
            , 51320                       AS ValidationCode
            , N'Ungültiger oder leerer Dateipfad.' AS ValidationMessage;
        RETURN 0;
    END;

    IF NOT EXISTS
       (
           SELECT 1
           FROM [toolbelt_file].[FileContentRootAllowlist]
           WHERE IsActive = 1
             AND @NormalizedPath COLLATE Latin1_General_100_BIN2
                 LIKE REPLACE(REPLACE(RootPath, N'\\', N'/'), N'\', N'/')
                     COLLATE Latin1_General_100_BIN2 + N'%'
       )
    BEGIN
        SELECT
              CAST(NULL AS nvarchar(max)) AS Content
            , CAST(0 AS bigint)           AS BytesRead
            , NULL                        AS EncodingDetected
            , CAST(0 AS bit)              AS BomPresent
            , CAST(0 AS bit)              AS IsValid
            , 51321                       AS ValidationCode
            , N'Pfad liegt außerhalb der konfigurierten Root-Allowlist.' AS ValidationMessage;
        RETURN 0;
    END;

    DECLARE @Sql nvarchar(max)
          , @Header varbinary(4)
          , @EncodingDetected nvarchar(128)
          , @BomPresent bit = 0
          , @Content nvarchar(max)
          , @BytesRead bigint
          , @FormatFile nvarchar(4000)
          , @CodePage int;

    -- BOM-Heuristik über die ersten 4 Bytes.
    SET @Sql = N'SET @Header = (SELECT TOP(1) SUBSTRING(BulkColumn, 1, 4) FROM OPENROWSET(BULK '
               + QUOTENAME(@FilePath, N'''')
               + N', SINGLE_BLOB) AS x);';

    BEGIN TRY
        EXEC sys.sp_executesql
              @stmt = @Sql
            , @params = N'@Header varbinary(4) OUTPUT'
            , @Header = @Header OUTPUT;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    IF @Header = 0xEFBBBF
    BEGIN
        SET @EncodingDetected = N'UTF-8';
        SET @BomPresent = 1;
        SET @CodePage = 65001;
    END
    ELSE IF @Header = 0xFFFE
    BEGIN
        SET @EncodingDetected = N'UTF-16-BE';
        SET @BomPresent = 1;
        SET @CodePage = 1201;
    END
    ELSE IF @Header = 0xFEFF
    BEGIN
        SET @EncodingDetected = N'UTF-16-LE';
        SET @BomPresent = 1;
        SET @CodePage = 1200;
    END
    ELSE IF @Header = 0x0000FEFF
    BEGIN
        SET @EncodingDetected = N'UTF-32-LE';
        SET @BomPresent = 1;
        SET @CodePage = 12000;
    END
    ELSE IF @Header = 0xFFFE0000
    BEGIN
        SET @EncodingDetected = N'UTF-32-BE';
        SET @BomPresent = 1;
        SET @CodePage = 12001;
    END
    ELSE
    BEGIN
        SET @EncodingDetected = @FallbackEncoding;
        SET @BomPresent = 0;
        SET @CodePage = CASE @FallbackEncoding
                            WHEN N'Windows-1252' THEN 1252
                            WHEN N'SQL_Latin1_General_CP1_CI_AS' THEN 1252
                            ELSE 1252
                        END;
    END;

    -- Text lesen mit passender Codepage.
    SET @Sql = N'SET @Content = (SELECT BulkColumn FROM OPENROWSET(BULK '
               + QUOTENAME(@FilePath, N'''')
               + N', CODEPAGE=''' + CAST(@CodePage AS nvarchar(16)) + N''', FORMATFILE=''' + @FormatFile + N''') AS x);';

    -- Für SINGLE_CLOB/SINGLE_NCLOB verwenden wir CODEPAGE im Formatfile-Pfad.
    -- Da OPENROWSET(BULK...) ohne Formatfile nur SINGLE_BLOB/CLOB/NCLOB erlaubt,
    -- nutzen wir SINGLE_CLOB mit expliziter CODEPAGE-Angabe im BULK-Optionen.
    SET @Sql = N'SET @Content = (SELECT BulkColumn FROM OPENROWSET(BULK '
               + QUOTENAME(@FilePath, N'''')
               + N', CODEPAGE=''' + CAST(@CodePage AS nvarchar(16)) + N''') AS x);';

    BEGIN TRY
        EXEC sys.sp_executesql
              @stmt = @Sql
            , @params = N'@Content nvarchar(max) OUTPUT'
            , @Content = @Content OUTPUT;

        SET @BytesRead = DATALENGTH(@Content) * 2; -- NCHAR = 2 Byte pro Codeunit

        IF @MaxBytes IS NOT NULL AND @BytesRead > @MaxBytes
        BEGIN
            SELECT
                  CAST(NULL AS nvarchar(max)) AS Content
                , @BytesRead                  AS BytesRead
                , @EncodingDetected           AS EncodingDetected
                , @BomPresent                 AS BomPresent
                , CAST(0 AS bit)              AS IsValid
                , 51323                       AS ValidationCode
                , N'Datei überschreitet @MaxBytes.' AS ValidationMessage;
            RETURN 0;
        END;

        SELECT
              @Content        AS Content
            , @BytesRead      AS BytesRead
            , @EncodingDetected AS EncodingDetected
            , @BomPresent     AS BomPresent
            , CAST(1 AS bit)  AS IsValid
            , NULL            AS ValidationCode
            , NULL            AS ValidationMessage;

        RETURN 0;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
