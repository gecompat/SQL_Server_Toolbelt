-- ============================================================================
-- Objekt:          toolbelt_string.USP_SplitAdvanced
-- Typ:             Stored Procedure; Fassade des kanonischen S2-TVF-Kerns
-- Zweck:           Originaltokens als SELECT oder caller-lokale ResultTable liefern
-- Vertrag:         Documentation/USP_SplitAdvanced.md; USP_CONTRACT 1.0
-- Parameter:       Input/SeparatorsJson/Quote/Escape nvarchar(max), KeepEmpty bit
-- Standardparameter: ResultTable sysname, KeepData bit, Debug tinyint, Hilfe bit
-- Resultset:       Value nvarchar(max) NOT NULL, Ordinal bigint NOT NULL
-- Dependencies:    TVF_SplitAdvanced; toolbelt.core.result-table >=1.0.0 same_database
-- Rechte:          EXECUTE; für ResultTable Helper-EXECUTE und Temp-Metadatensicht
-- Versionen:       SQL Server 2019/2022/2025; Compatibility >=150
-- Plattformen:     Windows/Linux; neue Runtime-Evidenz separat nachzuweisen
-- Fehlerverhalten: 51680 Geschäftsfehler, 51681 Dependency; Enginefehler unverändert
-- Transaktion:     eigener Scope oder Savepoint; niemals Callertransaktion committen
-- Performance:     genau ein TVF-Snapshot, Materialisierung; kein Unquoting
-- Einschränkungen: NULL Input keine Zielmutation; doomed Caller benötigt Callerrollback
-- ============================================================================
CREATE OR ALTER PROCEDURE [toolbelt_string].[USP_SplitAdvanced]
(
      @Input nvarchar(max) = NULL
    , @SeparatorsJson nvarchar(max) = NULL
    , @Quote nvarchar(max) = N'"'
    , @Escape nvarchar(max) = N'\'
    , @KeepEmpty bit = 1
    , @ResultTable sysname = NULL
    , @KeepData bit = 0
    , @Debug tinyint = 0
    , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @KeepData=COALESCE(@KeepData,0),@Debug=COALESCE(@Debug,0),@Hilfe=COALESCE(@Hilfe,0);
    IF @Hilfe=1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_string' AS sysname) AS SchemaName,
            CAST(N'USP_SplitAdvanced' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Originaltokens aus kanonischer TVF; Geschäftsfehler vor Zielmutation, kein Unquoting.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'Value', N'nvarchar(max)', 1, 0, NULL, CAST(N'Originaltoken, Latin1_General_100_BIN2.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'Ordinal', N'bigint', 1, 0, NULL, CAST(N'1-basiert, nach Leerfilter lückenlos; Tabellen garantieren keine physische Reihenfolge.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51680', NULL, NULL, NULL, NULL, CAST(N'TVF-Geschäftscode und Originalposition ohne Inputinhalt; keine Teilausgabe.' AS nvarchar(max)), NULL),
        (N'ERROR', 2, N'51681', NULL, NULL, NULL, NULL, CAST(N'Registrierte same-database ResultTable-Dependency >=1.0.0 fehlt oder ist ungeeignet.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'NULL Input: leeres SELECT oder Ziel vollständig unverändert. Enginefehler bleiben Originalfehler; doomed Caller benötigt Callerrollback.' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'EXECUTE auf USP; ResultTable-Pfad benötigt Helper-EXECUTE und Sichtbarkeit der caller-lokalen Temp-Tabelle; keine Rechteausweitung.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Zwei Originaltokens als SELECT.' AS nvarchar(max)), CAST(N'EXEC toolbelt_string.USP_SplitAdvanced @Input=N''a;b'', @SeparatorsJson=N''[";"]'', @Quote=N'''', @Escape=N'''';' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@Input', N'nvarchar(max)', 0, 1, N'NULL', CAST(N'Text mit maximal 65536 UTF-16-Einheiten, NUL verboten; leer ist gültig. NULL ist ein früher No-op ohne Zeilen, selbst bei ungültiger Konfiguration. Tokens bleiben im Original einschließlich Quotes/Escapes; zum Entfernen TVF_UnquoteToken verwenden.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@SeparatorsJson', N'nvarchar(max)', 1, 0, N'NULL', CAST(N'JSON-Array aus 1..16 verschiedenen nicht leeren Strings, z.B. ["::",","]; kein Objekt, keine JSON-null-/Zahlen-/Boolean-Elemente. Je Separator 1..64 UTF-16-Einheiten, Gesamt-JSON höchstens 16384 Einheiten. Binäre Gleichheit einschließlich Spaces; NUL und die aktivierten Quote-/Escape-Zeichen verboten. Längster passender Separator gewinnt. NULL ist außerhalb des frühen Input-NULL-Pfads ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@Quote', N'nvarchar(max)', 0, 0, N'N''"''', CAST(N'Genau eine UTF-16-Einheit (Default Doppelquote) aktiviert Quotegruppen; leer deaktiviert sie. NULL, NUL und Surrogate ungültig. Muss sich vom aktiven Escape unterscheiden und darf in keinem Separator vorkommen; keine automatische mehrzeichige Quote-Syntax.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@Escape', N'nvarchar(max)', 0, 0, N'N''\''', CAST(N'Genau eine UTF-16-Einheit (Default Backslash) schützt das nächste Zeichen vor Parserwirkung; leer deaktiviert Escaping. NULL, NUL und Surrogate ungültig. Darf weder aktives Quote noch Bestandteil eines Separators sein. Ein finales Escape ohne Folgezeichen ist ein Parserfehler; Ausgabe bleibt unentschlüsselt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@KeepEmpty', N'bit', 0, 1, N'1', CAST(N'Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
    DECLARE @Success TABLE
    (Value nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL, Ordinal bigint NOT NULL);
    -- No-op darf selbst eine ungültige ResultTable/Dependency nicht prüfen.
    IF @Input IS NULL
    BEGIN
        IF @ResultTable IS NULL
            SELECT Value,Ordinal FROM @Success;
        RETURN;
    END;
    DECLARE @Snapshot TABLE
    (
        Value nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL, Ordinal bigint NULL,
        IsValid bit NOT NULL, ErrorCode varchar(64) NULL, ErrorPosition bigint NULL
    );
    INSERT @Snapshot SELECT Value,Ordinal,IsValid,ErrorCode,ErrorPosition
    FROM toolbelt_string.TVF_SplitAdvanced(@Input,@SeparatorsJson,@Quote,@Escape,@KeepEmpty);
    IF EXISTS(SELECT 1 FROM @Snapshot WHERE IsValid=0)
    BEGIN
        DECLARE @Message nvarchar(2048);
        SELECT @Message=N'SplitAdvanced: '+CONVERT(nvarchar(64),ErrorCode)
                       +CASE WHEN ErrorPosition IS NULL THEN N'' ELSE N'; Position '+CONVERT(nvarchar(32),ErrorPosition) END
        FROM @Snapshot WHERE IsValid=0;
        THROW 51680,@Message,1;
    END;
    INSERT @Success(Value,Ordinal) SELECT Value,Ordinal FROM @Snapshot;
    IF @Debug>0 RAISERROR(N'SplitAdvanced: validierter Snapshot bereit.',10,1) WITH NOWAIT;
    IF @ResultTable IS NULL
    BEGIN
        SELECT Value,Ordinal FROM @Success ORDER BY Ordinal;
        RETURN;
    END;
    DECLARE @DependencyVersion nvarchar(64),@DependencyId int=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P');
    SELECT @DependencyVersion=TRY_CONVERT(nvarchar(64),value)
    FROM sys.extended_properties
    WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.result-table.Version';
    DECLARE @Major int=TRY_CONVERT(int,PARSENAME(@DependencyVersion,3)),
            @Minor int=TRY_CONVERT(int,PARSENAME(@DependencyVersion,2)),
            @Patch int=TRY_CONVERT(int,PARSENAME(@DependencyVersion,1));
    IF @DependencyId IS NULL OR @Major IS NULL OR @Major<1
       OR @Minor IS NULL OR @Minor<0 OR @Patch IS NULL OR @Patch<0
       OR CONVERT(varbinary(max),@DependencyVersion)<>CONVERT(varbinary(max),
          CONCAT(@Major,N'.',@Minor,N'.',@Patch))
       OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@DependencyId
          AND minor_id=0 AND name=N'Toolbelt.ModuleId' AND TRY_CONVERT(nvarchar(128),value)=N'toolbelt.core.result-table')
       OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@DependencyId
          AND minor_id=0 AND name=N'Toolbelt.ModuleVersion'
          AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(64),value))=CONVERT(varbinary(max),@DependencyVersion))
        THROW 51681,N'ResultTable-Dependency toolbelt.core.result-table >=1.0.0 fehlt oder ist ungeeignet.',1;

    CREATE TABLE #tbx_SplitAdvanced_ResultSource
    (Value nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL, Ordinal bigint NOT NULL);
    INSERT #tbx_SplitAdvanced_ResultSource(Value,Ordinal) SELECT Value,Ordinal FROM @Success;
    DECLARE @OwnTransaction bit=CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END,
            @Savepoint varchar(32)=REPLACE(CONVERT(varchar(36),NEWID()),'-',''),
            @SavepointSet bit=0;
    BEGIN TRY
        IF @OwnTransaction=1 BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION @Savepoint;
            SET @SavepointSet=1;
        END;
        EXEC toolbelt_core.USP_PrepareResultTable
             @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_SplitAdvanced_ResultSource',
             @KeepData=@KeepData,@Debug=@Debug;
        DECLARE @InsertSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)
             +N' ([Value],[Ordinal]) SELECT [Value],[Ordinal] FROM #tbx_SplitAdvanced_ResultSource;';
        EXEC sys.sp_executesql @InsertSql;
        IF @OwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @OwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        ELSE IF @SavepointSet=1 AND XACT_STATE()=1 ROLLBACK TRANSACTION @Savepoint;
        THROW;
    END CATCH;
END;
GO
