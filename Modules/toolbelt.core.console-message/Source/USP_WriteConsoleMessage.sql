-- ============================================================================
-- Objekt:          toolbelt_core.USP_WriteConsoleMessage
-- Typ:             Stored Procedure
-- Zweck:           Gibt lange Unicode-Texte vollständig und optional sofort
--                  im Messages-Kanal des Clients aus.
-- Vertrag:         Documentation/Architecture/CONSOLE_MESSAGE_MODULE_DESIGN.md
-- Parameter:       @Message nvarchar(max) = NULL
--                  @Immediate bit = 0
--                  @Debug tinyint = 0
--                  @Hilfe bit = 0
-- Resultset:       Kein fachliches Resultset; bei @Hilfe = 1 genau ein
--                  standardisiertes Help-Resultset.
-- Dependencies:    Keine weiteren Toolbelt-Module.
-- Rechte:          EXECUTE auf der Procedure.
-- Versionen:       SQL Server 2019, 2022 und 2025.
-- Plattformen:     Windows und Linux; Clientdarstellung separat bewerten.
-- Fehlerverhalten: Keine fachlichen Fehler. Engine- und Clientfehler werden
--                  nicht abgefangen oder umklassifiziert.
-- Performance:     Lineare Message-Ausgabe; nicht für Hot Paths bestimmt.
-- Einschränkungen: Client und Treiber bestimmen Pufferung und Darstellung der
--                  einzelnen Message-Frames. Keine Präfixe oder Zeitstempel.
-- ============================================================================

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_WriteConsoleMessage]
(
      @Message   nvarchar(max) = NULL
    , @Immediate bit           = 0
    , @Debug     tinyint       = 0
    , @Hilfe     bit           = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @Immediate = ISNULL(@Immediate, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    /*
     * Der Help-Pfad steht vor der fachlichen Ausgabe. Dadurch ignoriert ein
     * Hilfeaufruf Message, Immediate und Debug vollständig.
     */
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
          ( '1.0', N'toolbelt_core', N'USP_WriteConsoleMessage', 'DESCRIPTION', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Gibt einen langen Unicode-Text vollständig im Messages-Kanal aus. Gepufferte Ausgabe verwendet PRINT; unmittelbare Ausgabe verwendet RAISERROR mit Severity 0 und NOWAIT.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_WriteConsoleMessage', 'PARAMETER', 1
          , N'@Message', 'nvarchar(max)', 0, 1, N'NULL'
          , N'Auszugebender Text. NULL und Leertext erzeugen keine Ausgabe. Vorhandene Zeilenumbrüche bleiben innerhalb der Message-Frames erhalten.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_WriteConsoleMessage', 'PARAMETER', 2
          , N'@Immediate', 'bit', 0, 1, N'0'
          , N'0 verwendet PRINT in Chunks bis 4.000 UTF-16-Codeunits. 1 verwendet RAISERROR mit Severity 0, konservativen 2.000-Codeunit-Chunks und WITH NOWAIT.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_WriteConsoleMessage', 'PARAMETER', 3
          , N'@Debug', 'tinyint', 0, 1, N'0'
          , N'Standardparameter des USP-Vertrags. Version 1 erzeugt bewusst keine zusätzlichen Debug-Messages, damit der Payload unverändert bleibt.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_WriteConsoleMessage', 'PARAMETER', 4
          , N'@Hilfe', 'bit', 0, 1, N'0'
          , N'1 gibt ausschließlich dieses Help-Resultset aus und ignoriert alle anderen Parameter.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_WriteConsoleMessage', 'RESULT_COLUMN', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Die Procedure besitzt kein fachliches Resultset. Text wird ausschließlich als Messages ausgegeben.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_WriteConsoleMessage', 'PERMISSION', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Erforderlich ist EXECUTE auf toolbelt_core.USP_WriteConsoleMessage. Die Procedure erweitert keine Rechte.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_WriteConsoleMessage', 'LIMITATION', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Client und Treiber bestimmen Pufferung, Präfixe und Darstellung von Message-Frame-Grenzen. Die Procedure garantiert Reihenfolge und vollständige Payload-Chunks, aber keine byteidentische Clientformatierung.'
          , NULL )
        , ( '1.0', N'toolbelt_core', N'USP_WriteConsoleMessage', 'EXAMPLE', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Gibt einen synthetischen Fortschrittstext sofort aus.'
          , N'EXEC toolbelt_core.USP_WriteConsoleMessage
      @Message = N''Schritt 1 abgeschlossen.''
    , @Immediate = 1;' );

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
                  ELSE 8
              END
            , Ordinal;

        RETURN 0;
    END;

    IF @Message IS NULL OR DATALENGTH(@Message) = 0
        RETURN 0;

    DECLARE
          @Position      bigint = 1
        , @CodeUnitCount bigint
        , @ChunkSize     int
        , @ChunkLength   int
        , @Chunk         nvarchar(4000);

    /*
     * LEN ignoriert normalerweise nachgestellte Leerzeichen. Das angehängte
     * Nicht-Leerzeichen macht sie zählbar. Die explizite Nicht-SC-Collation
     * zählt UTF-16-Codeunits; damit stimmt die Positionsrechnung mit den
     * nvarchar- und Message-Grenzen überein.
     */
    SET @CodeUnitCount =
        LEN((@Message + NCHAR(1)) COLLATE Latin1_General_100_BIN2) - 1;
    SET @ChunkSize = CASE WHEN @Immediate = 1 THEN 2000 ELSE 4000 END;

    WHILE @Position <= @CodeUnitCount
    BEGIN
        SET @ChunkLength = CONVERT
        (
            int,
            CASE
                WHEN @CodeUnitCount - @Position + 1 < @ChunkSize
                THEN @CodeUnitCount - @Position + 1
                ELSE @ChunkSize
            END
        );

        SET @Chunk = SUBSTRING
        (
              @Message COLLATE Latin1_General_100_BIN2
            , @Position
            , @ChunkLength
        );

        /*
         * BIN2 zählt die beiden UTF-16-Codeunits eines Supplementary
         * Characters getrennt. Endet ein noch nicht letzter Chunk mit einem
         * High Surrogate und beginnt der nächste mit dem zugehörigen Low
         * Surrogate, bleibt das Paar vollständig im nächsten Chunk.
         */
        IF @Position + @ChunkLength - 1 < @CodeUnitCount
           AND UNICODE
               (
                   RIGHT(@Chunk COLLATE Latin1_General_100_BIN2, 1)
               ) BETWEEN 55296 AND 56319
           AND UNICODE
               (
                   SUBSTRING
                   (
                         @Message COLLATE Latin1_General_100_BIN2
                       , @Position + @ChunkLength
                       , 1
                   )
               ) BETWEEN 56320 AND 57343
        BEGIN
            SET @ChunkLength -= 1;
            SET @Chunk = SUBSTRING
            (
                  @Message COLLATE Latin1_General_100_BIN2
                , @Position
                , @ChunkLength
            );
        END;

        IF @Immediate = 1
        BEGIN
            /*
             * Das feste Format verhindert, dass Prozentzeichen des Payloads
             * als Format-Spezifikationen interpretiert werden. 2.000 Zeichen
             * lassen Reserve unterhalb des RAISERROR-Limits von 2.047.
             */
            RAISERROR (N'%s', 0, 1, @Chunk) WITH NOWAIT;
        END;
        ELSE
        BEGIN
            PRINT @Chunk;
        END;

        SET @Position += @ChunkLength;
    END;

    RETURN 0;
END;
GO
