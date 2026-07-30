-- ============================================================================
-- Objekt:          toolbelt_file.USP_LoadBinaryFile
-- Typ:             Stored Procedure
-- Zweck:           Liest eine Datei als varbinary(max) über OPENROWSET(BULK...).
-- Vertrag:         Documentation/Architecture/FILE_CONTENT_MODULE_DESIGN.md
-- Parameter:       @FilePath nvarchar(4000)
--                  @MaxBytes bigint = NULL
--                  @Debug tinyint = 0
--                  @Hilfe bit = 0
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
      @FilePath  nvarchar(4000)
    , @MaxBytes  bigint       = NULL
    , @Debug     tinyint      = 0
    , @Hilfe     bit          = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @FilePath = NULLIF(LTRIM(RTRIM(@FilePath)), N'');
    SET @MaxBytes = NULLIF(@MaxBytes, 0);
    SET @Debug    = ISNULL(@Debug, 0);
    SET @Hilfe    = ISNULL(@Hilfe, 0);

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
          ( '1.0', N'toolbelt_file', N'USP_LoadBinaryFile', 'DESCRIPTION', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Liest eine Datei als varbinary(max) über OPENROWSET(BULK...). Der Pfad muss unter einem Eintrag der Root-Allowlist liegen.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadBinaryFile', 'PARAMETER', 1
          , N'@FilePath', 'nvarchar(4000)', 1, 0, NULL
          , N'Absoluter Pfad zur Datei. UNC-Pfade sind erlaubt. Relative Pfade, ..-Segmente und Pfade außerhalb der Allowlist werden abgelehnt.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadBinaryFile', 'PARAMETER', 2
          , N'@MaxBytes', 'bigint', 0, 1, N'NULL'
          , N'Optionales Limit. Wenn die gelesene Datei mehr Bytes enthält, wird ein Validierungsfehler zurückgegeben, der Inhalt bleibt jedoch NULL.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadBinaryFile', 'PARAMETER', 3
          , N'@Debug', 'tinyint', 0, 1, N'0'
          , N'Standardparameter des USP-Vertrags. Version 1 erzeugt keine Debug-Messages.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadBinaryFile', 'PARAMETER', 4
          , N'@Hilfe', 'bit', 0, 1, N'0'
          , N'1 gibt ausschließlich dieses Help-Resultset aus und ignoriert alle anderen Parameter.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadBinaryFile', 'RESULT_COLUMN', 1
          , N'Content', 'varbinary(max)', 0, 1, NULL
          , N'Der binäre Dateiinhalt. Bei Validierungsfehlern NULL.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadBinaryFile', 'RESULT_COLUMN', 2
          , N'BytesRead', 'bigint', 0, 0, NULL
          , N'Anzahl gelesener Bytes. Bei Validierungsfehlern vor dem Lesen 0.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadBinaryFile', 'RESULT_COLUMN', 3
          , N'IsValid', 'bit', 0, 0, NULL
          , N'1, wenn der Inhalt erfolgreich gelesen wurde; 0 bei fachlichem Fehler.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadBinaryFile', 'RESULT_COLUMN', 4
          , N'ValidationCode', 'int', 0, 1, NULL
          , N'Fachlicher Fehlercode oder NULL bei Erfolg.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadBinaryFile', 'RESULT_COLUMN', 5
          , N'ValidationMessage', 'nvarchar(4000)', 0, 1, NULL
          , N'Fachliche Fehlermeldung oder NULL bei Erfolg.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadBinaryFile', 'ERROR', 1
          , N'51320', NULL, NULL, NULL, NULL
          , N'Ungültiger oder leerer Dateipfad.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadBinaryFile', 'ERROR', 2
          , N'51321', NULL, NULL, NULL, NULL
          , N'Pfad liegt außerhalb der konfigurierten Root-Allowlist.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadBinaryFile', 'ERROR', 3
          , N'51322', NULL, NULL, NULL, NULL
          , N'Pfad enthält verbotene relative Segmente oder Traversal.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadBinaryFile', 'ERROR', 4
          , N'51323', NULL, NULL, NULL, NULL
          , N'Datei überschreitet @MaxBytes.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadBinaryFile', 'PERMISSION', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Erforderlich ist EXECUTE auf toolbelt_file.USP_LoadBinaryFile, Lesezugriff auf den Dateipfad sowie ADMINISTER BULK OPERATIONS oder ad hoc distributed queries für OPENROWSET(BULK...).'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadBinaryFile', 'LIMITATION', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Dateigröße ist durch varbinary(max) auf ca. 2 GB begrenzt. OPENROWSET(BULK...) liert die gesamte Datei; @MaxBytes prüft erst nach dem Lesen.'
          , NULL )
        , ( '1.0', N'toolbelt_file', N'USP_LoadBinaryFile', 'EXAMPLE', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Liest eine Datei aus einem erlaubten Root.'
          , N'EXEC toolbelt_file.USP_LoadBinaryFile
      @FilePath = N''/var/opt/mssql/data/allowed/sample.bin'';' );

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
              CAST(NULL AS varbinary(max)) AS Content
            , CAST(0 AS bigint)            AS BytesRead
            , CAST(0 AS bit)               AS IsValid
            , 51320                        AS ValidationCode
            , N'Ungültiger oder leerer Dateipfad.' AS ValidationMessage;
        RETURN 0;
    END;

    DECLARE @NormalizedPath nvarchar(4000) = @FilePath;

    -- Plattformunabhängige Normalisierung: Backslash -> Slash für Vergleich.
    SET @NormalizedPath = REPLACE(@NormalizedPath, N'\\', N'/');
    SET @NormalizedPath = REPLACE(@NormalizedPath, N'\', N'/');

    -- Traversal-Prüfung.
    IF @NormalizedPath LIKE N'%/../%' OR @NormalizedPath LIKE N'%/..'
       OR @NormalizedPath LIKE N'../%'
    BEGIN
        SELECT
              CAST(NULL AS varbinary(max)) AS Content
            , CAST(0 AS bigint)            AS BytesRead
            , CAST(0 AS bit)               AS IsValid
            , 51322                        AS ValidationCode
            , N'Pfad enthält verbotene relative Segmente oder Traversal.' AS ValidationMessage;
        RETURN 0;
    END;

    -- Pfad muss absolut sein: lokaler Buchstabe oder UNC.
    IF @NormalizedPath NOT LIKE N'[A-Za-z]:/%'
       AND @NormalizedPath NOT LIKE N'//%'
       AND @NormalizedPath NOT LIKE N'/%'
    BEGIN
        SELECT
              CAST(NULL AS varbinary(max)) AS Content
            , CAST(0 AS bigint)            AS BytesRead
            , CAST(0 AS bit)               AS IsValid
            , 51320                        AS ValidationCode
            , N'Ungültiger oder leerer Dateipfad.' AS ValidationMessage;
        RETURN 0;
    END;

    -- Allowlist-Prüfung (Latin1_General_100_BIN2 für byteidentischen Vergleich).
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
              CAST(NULL AS varbinary(max)) AS Content
            , CAST(0 AS bigint)            AS BytesRead
            , CAST(0 AS bit)               AS IsValid
            , 51321                        AS ValidationCode
            , N'Pfad liegt außerhalb der konfigurierten Root-Allowlist.' AS ValidationMessage;
        RETURN 0;
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
            SELECT
                  CAST(NULL AS varbinary(max)) AS Content
                , @BytesRead                   AS BytesRead
                , CAST(0 AS bit)               AS IsValid
                , 51323                        AS ValidationCode
                , N'Datei überschreitet @MaxBytes.' AS ValidationMessage;
            RETURN 0;
        END;

        SELECT
              @Content        AS Content
            , @BytesRead      AS BytesRead
            , CAST(1 AS bit)  AS IsValid
            , NULL            AS ValidationCode
            , NULL            AS ValidationMessage;

        RETURN 0;
    END TRY
    BEGIN CATCH
        -- Engine-Fehler aus OPENROWSET werden nicht umklassifiziert.
        THROW;
    END CATCH;
END;
GO
