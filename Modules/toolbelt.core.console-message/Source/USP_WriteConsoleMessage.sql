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
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_WriteConsoleMessage' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Gibt bis zu 1 MiB UTF-16 in höchstens 512 Frames vollständig im Messages-Kanal aus. Gepufferte Ausgabe verwendet PRINT; unmittelbare Ausgabe verwendet RAISERROR mit Severity 0 und NOWAIT.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Die Procedure besitzt kein fachliches Resultset. Text wird ausschließlich als Messages ausgegeben.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'52801-52802', NULL, NULL, NULL, NULL, CAST(N'52801: über 1 MiB UTF-16; 52802: über 512 Frames. Ablehnung vor erster Ausgabe, keine Kürzung.' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Erforderlich ist EXECUTE auf toolbelt_core.USP_WriteConsoleMessage. Die Procedure erweitert keine Rechte.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Client und Treiber bestimmen Pufferung, Präfixe und Darstellung von Message-Frame-Grenzen. Die Procedure garantiert Reihenfolge und vollständige Payload-Chunks, aber keine byteidentische Clientformatierung.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Gibt einen synthetischen Fortschrittstext sofort aus.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_WriteConsoleMessage
      @Message = N''Schritt 1 abgeschlossen.''
    , @Immediate = 1;' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@Message', N'nvarchar(max)', 0, 1, N'NULL', CAST(N'Auszugebender Unicode-Text als nvarchar(max), maximal 1048576 UTF-16-Bytes und höchstens 512 berechnete Frames. CR/LF und Prozentzeichen sind Inhalt, kein Formatstring. Default/NULL und leerer Text erzeugen keine Ausgabe; Überschreitung wird vor erster Ausgabe abgewiesen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@Immediate', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 puffert über PRINT mit bis 4000 Codeeinheiten je Frame (Default); 1 nutzt RAISERROR Severity 0 WITH NOWAIT mit bis 2000 Codeeinheiten je Frame. NULL entspricht 0; konkrete Clientpufferung bleibt vom Client abhängig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255 oder NULL, Default 0; in dieser Procedure haben alle diese Werte bewusst keine Wirkung und erzeugen keine zusätzliche Diagnose.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert ausschließlich Hilfe und ignoriert alle anderen Argumente; 0 führt die Messageausgabe aus (Default). NULL wird wie 0 behandelt.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    IF @Message IS NULL OR DATALENGTH(@Message) = 0
        RETURN 0;

    IF DATALENGTH(@Message)>1048576
        THROW 52801,N'Console-Nachrichten dürfen höchstens 1 MiB UTF-16 umfassen.',1;

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

    -- Höchstens ein Surrogate-Paar verschiebt eine Chunkgrenze um eine Einheit.
    -- Diese obere Framezahl wird vor der ersten Ausgabe geprüft.
    IF (@CodeUnitCount+@ChunkSize-2)/(@ChunkSize-1)>512
        THROW 52802,N'Console-Nachrichten dürfen höchstens 512 Frames erzeugen.',1;

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
