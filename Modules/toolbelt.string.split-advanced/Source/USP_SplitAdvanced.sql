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
        DECLARE @Help TABLE
        (
            Section varchar(32) NOT NULL, Ordinal int NOT NULL, ItemName sysname NULL,
            SqlDataType varchar(256) NULL, IsRequired bit NULL, IsNullable bit NULL,
            DefaultValue nvarchar(4000) NULL, Description nvarchar(max) NOT NULL,
            ExampleSql nvarchar(max) NULL
        );
        INSERT @Help VALUES
        ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Originaltokens aus kanonischer TVF; Geschäftsfehler vor Zielmutation, kein Unquoting.',NULL),
        ('PARAMETER',1,N'@Input','nvarchar(max)',0,1,N'NULL',N'NULL ist früher No-op; sonst unveränderte S2-Tokenisierung.',NULL),
        ('PARAMETER',2,N'@SeparatorsJson','nvarchar(max)',1,0,N'NULL',N'Nichtleeres JSON-Array von Separatorstrings bei nicht-NULL Input.',NULL),
        ('PARAMETER',3,N'@Quote','nvarchar(max)',0,0,N'N''"''',N'Quote-Zeichen; leer deaktiviert, NULL ungültig.',NULL),
        ('PARAMETER',4,N'@Escape','nvarchar(max)',0,0,N'N''\''',N'Allgemeines S2-Escape; Originaltoken bleibt erhalten.',NULL),
        ('PARAMETER',5,N'@KeepEmpty','bit',0,1,N'1',N'NULL entspricht 1; nur leere Tokens filtern.',NULL),
        ('PARAMETER',6,N'@ResultTable','sysname',0,1,N'NULL',N'Vorhandene caller-lokale Temp-Tabelle; NULL liefert SELECT.',NULL),
        ('PARAMETER',7,N'@KeepData','bit',0,1,N'0',N'Replace=0, Append=1; NULL entspricht 0.',NULL),
        ('PARAMETER',8,N'@Debug','tinyint',0,1,N'0',N'Nur Messages ohne Input-/Tokeninhalte.',NULL),
        ('PARAMETER',9,N'@Hilfe','bit',0,1,N'0',N'1 liefert ausschließlich standardisiertes Help.',NULL),
        ('RESULT_COLUMN',1,N'Value','nvarchar(max)',1,0,NULL,N'Originaltoken, Latin1_General_100_BIN2.',NULL),
        ('RESULT_COLUMN',2,N'Ordinal','bigint',1,0,NULL,N'1-basiert, nach Leerfilter lückenlos; Tabellen garantieren keine physische Reihenfolge.',NULL),
        ('ERROR',1,N'51680',NULL,NULL,NULL,NULL,N'TVF-Geschäftscode und Originalposition ohne Inputinhalt; keine Teilausgabe.',NULL),
        ('ERROR',2,N'51681',NULL,NULL,NULL,NULL,N'Registrierte same-database ResultTable-Dependency >=1.0.0 fehlt oder ist ungeeignet.',NULL),
        ('LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'NULL Input: leeres SELECT oder Ziel vollständig unverändert. Enginefehler bleiben Originalfehler; doomed Caller benötigt Callerrollback.',NULL),
        ('PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'EXECUTE auf USP; ResultTable-Pfad benötigt Helper-EXECUTE und Sichtbarkeit der caller-lokalen Temp-Tabelle; keine Rechteausweitung.',NULL),
        ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Zwei Originaltokens als SELECT.',
         N'EXEC toolbelt_string.USP_SplitAdvanced @Input=N''a;b'', @SeparatorsJson=N''[";"]'', @Quote=N'''', @Escape=N'''';');
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
               CAST(N'toolbelt_string' AS sysname) AS SchemaName,
               CAST(N'USP_SplitAdvanced' AS sysname) AS ObjectName,
               Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql
        FROM @Help ORDER BY CASE Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2
                             WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4
                             WHEN 'PERMISSION' THEN 5 WHEN 'LIMITATION' THEN 6 ELSE 7 END,Ordinal;
        RETURN;
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
