-- ============================================================================
-- Objekt:          toolbelt_pseudonymization.USP_DeterministicLookup
-- Typ:             Stored Procedure
-- Vertrag:         Documentation/USP_DeterministicLookup.md; USP_CONTRACT 1.0.
-- Zweck:           Synthetischer, versionierter Ersatzwert aus geordnetem Pool.
-- Parameter:       Caller-#Temps InputTable/LookupTable; MappingVersion int,
--                  Seed bigint, LookupVersion bigint; positive Ressourcenlimits.
-- Standard:        ResultTable, KeepData, Debug, Hilfe gemäß USP_CONTRACT 1.0.
-- Resultset:       InputOrdinal bigint NOT NULL, LookupOrdinal bigint NULL,
--                  Value nvarchar(max) Latin1_General_100_BIN2 NULL.
-- Dependencies:    interner Range-Kern; core.result-table >=1.0.0 same_database.
-- Rechte:          EXECUTE; ResultTable-Pfad zusätzlich Helper-EXECUTE.
-- Versionen:       SQL Server 2019/2022/2025, Windows/Linux; CL >=150.
-- Plattformen:     Windows und Linux, portabler T-SQL-Kern.
-- Fehlerverhalten: 54000..54009; Enginefehler unverändert; keine Teilzeilen.
-- Performance:     begrenzter Key-/Pool-/Mapping-Snapshot vor Ergebnis-LOB-Kopie.
-- Einschränkungen: Keine 1:1-, Privacy- oder historische Pool-Drift-Garantie.
-- ============================================================================
CREATE OR ALTER PROCEDURE [toolbelt_pseudonymization].[USP_DeterministicLookup]
(
      @InputTable sysname = NULL
    , @LookupTable sysname = NULL
    , @MappingVersion int = NULL
    , @Seed bigint = 0
    , @LookupVersion bigint = NULL
    , @MaxInputRows int = 10000
    , @MaxLookupRows int = 10000
    , @MaxLookupTextBytes bigint = 2097152
    , @MaxResultBytes bigint = 16777216
    , @ResultTable sysname = NULL
    , @KeepData bit = 0
    , @Debug tinyint = 0
    , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @KeepData = COALESCE(@KeepData, 0), @Debug = COALESCE(@Debug, 0), @Hilfe = COALESCE(@Hilfe, 0);
    IF @Hilfe = 1
    BEGIN
        DECLARE @Help TABLE
        (
            HelpContractVersion varchar(16) NOT NULL DEFAULT('1.0'),
            SchemaName sysname NOT NULL DEFAULT(N'toolbelt_pseudonymization'),
            ObjectName sysname NOT NULL DEFAULT(N'USP_DeterministicLookup'),
            Section varchar(32) NOT NULL, Ordinal int NOT NULL, ItemName sysname NULL,
            SqlDataType varchar(256) NULL, IsRequired bit NULL, IsNullable bit NULL,
            DefaultValue nvarchar(4000) NULL, Description nvarchar(max) NOT NULL, ExampleSql nvarchar(max) NULL
        );
        INSERT @Help(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql) VALUES
        ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Deterministischer synthetischer Lookup; explizite Poolversion, kein Anonymisierungs- oder Eins-zu-eins-Schutz.',NULL),
        ('PARAMETER',1,N'@InputTable','sysname',1,0,N'NULL',N'Caller-lokale #Temp: Ordinal bigint, Key varbinary(max).',NULL),
        ('PARAMETER',2,N'@LookupTable','sysname',1,0,N'NULL',N'Caller-lokale #Temp: Ordinal bigint, Value nvarchar(max); Pool nach Ordinal.',NULL),
        ('PARAMETER',3,N'@MappingVersion','int',1,0,N'NULL',N'Positive Mapping-Kontextversion.',NULL),
        ('PARAMETER',4,N'@Seed','bigint',0,0,N'0',N'Öffentlicher Varianten-Seed, kein Secret.',NULL),
        ('PARAMETER',5,N'@LookupVersion','bigint',1,0,N'NULL',N'Positive, ausdrücklich gewählte Poolversion; bei Pooländerung ändern.',NULL),
        ('PARAMETER',6,N'@MaxInputRows','int',0,0,N'10000',N'Positive Grenze bis 100000 Eingaben.',NULL),
        ('PARAMETER',7,N'@MaxLookupRows','int',0,0,N'10000',N'Positive Grenze bis 100000 Poolzeilen.',NULL),
        ('PARAMETER',8,N'@MaxLookupTextBytes','bigint',0,0,N'2097152',N'Positive Gesamttextbytegrenze bis 16777216.',NULL),
        ('PARAMETER',9,N'@MaxResultBytes','bigint',0,0,N'16777216',N'Positive Gesamt-Ergebnistextbytegrenze bis 16777216.',NULL),
        ('PARAMETER',10,N'@ResultTable','sysname',0,1,N'NULL',N'NULL: genau ein SELECT; sonst vorhandene lokale ResultTable.',NULL),
        ('PARAMETER',11,N'@KeepData','bit',0,1,N'0',N'0 Replace, 1 Append; NULL wie 0.',NULL),
        ('PARAMETER',12,N'@Debug','tinyint',0,1,N'0',N'Nur Phasen-/Metadaten-Messages, keine Keys, Werte, Seeds oder Hashes.',NULL),
        ('PARAMETER',13,N'@Hilfe','bit',0,1,N'0',N'Help zuerst, ohne fachliche Prüfung/Mutation/Messages.',NULL),
        ('RESULT_COLUMN',1,N'InputOrdinal','bigint',1,0,NULL,N'Positiver Eingabeordinal; SELECT nach dieser Spalte sortiert.',NULL),
        ('RESULT_COLUMN',2,N'LookupOrdinal','bigint',1,1,NULL,N'Expliziter Poolordinal; bei NULL-Key NULL.',NULL),
        ('RESULT_COLUMN',3,N'Value','nvarchar(max)',1,1,NULL,N'Unveränderter Pooltext, Latin1_General_100_BIN2; NULL-Key ergibt NULL.',NULL),
        ('ERROR',1,N'54000-54009',NULL,NULL,NULL,NULL,N'Konfiguration, Ressourcen, Tabellen, Ordinals, Keys, leerer Pool, Budgets, Sampling, Dependency oder interne Namenskollision; kein Teilresultat.',NULL),
        ('PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'EXECUTE; ResultTable zusätzlich Helper-EXECUTE; keine automatische Rechteausweitung.',NULL),
        ('LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'Keine persistierte Überwachung alter Pools, keine Eins-zu-eins-Auswahl oder Privacy-Zusage. MARS-Änderungen gleicher Temps unsupported.',NULL),
        ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Nur synthetische Tabellen; fachliche Ordinals dürfen Lücken haben.',N'CREATE TABLE #Input(Ordinal bigint, [Key] varbinary(max)); CREATE TABLE #Pool(Ordinal bigint, [Value] nvarchar(max)); INSERT #Input VALUES(10,0x010203); INSERT #Pool VALUES(20,N''synthetic''); EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N''#Input'',@LookupTable=N''#Pool'',@MappingVersion=1,@LookupVersion=1;');
        SELECT HelpContractVersion, SchemaName, ObjectName,
            Section, Ordinal, ItemName, SqlDataType, IsRequired, IsNullable, DefaultValue, Description, ExampleSql
        FROM @Help ORDER BY CASE Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2
            WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4 WHEN 'PERMISSION' THEN 5 WHEN 'LIMITATION' THEN 6 ELSE 7 END, Ordinal;
        RETURN;
    END;

    IF @MappingVersion IS NULL OR @MappingVersion <= 0 OR @Seed IS NULL OR @LookupVersion IS NULL OR @LookupVersion <= 0
        THROW 54000, N'DeterministicLookup: MappingVersion/LookupVersion müssen positiv sein; Seed darf nicht NULL sein.', 1;
    IF @MaxInputRows IS NULL OR @MaxInputRows NOT BETWEEN 1 AND 100000
        OR @MaxLookupRows IS NULL OR @MaxLookupRows NOT BETWEEN 1 AND 100000
        OR @MaxLookupTextBytes IS NULL OR @MaxLookupTextBytes NOT BETWEEN 1 AND 16777216
        OR @MaxResultBytes IS NULL OR @MaxResultBytes NOT BETWEEN 1 AND 16777216
        THROW 54001, N'DeterministicLookup: ungültige positive Ressourcenlimits.', 1;

    DECLARE @InputId int, @LookupId int, @TableName sysname, @TableRole int = 0;
    WHILE @TableRole < 2
    BEGIN
        SET @TableName = CASE @TableRole WHEN 0 THEN @InputTable ELSE @LookupTable END;
        IF @TableName IS NULL OR DATALENGTH(@TableName) > 232
            OR LEFT(@TableName,1) COLLATE Latin1_General_100_BIN2 <> N'#'
            OR LEFT(@TableName,2) COLLATE Latin1_General_100_BIN2 = N'##'
            OR LEFT(LOWER(@TableName COLLATE Latin1_General_100_BIN2),5) COLLATE Latin1_General_100_BIN2 = N'#tbx_'
            OR QUOTENAME(@TableName) IS NULL
            THROW 54002, N'DeterministicLookup: caller-lokaler Temp-Tabellenname erforderlich.', 1;
        DECLARE @TableId int = OBJECT_ID(N'tempdb..' + QUOTENAME(@TableName), N'U');
        IF @TableId IS NULL THROW 54002, N'DeterministicLookup: Eingabetabelle fehlt oder ist nicht sichtbar.', 2;
        IF @TableRole = 0 SET @InputId = @TableId; ELSE SET @LookupId = @TableId;
        SET @TableRole += 1;
    END;
    IF @ResultTable IS NOT NULL AND OBJECT_ID(N'tempdb..' + QUOTENAME(@ResultTable),N'U') IN (@InputId,@LookupId)
        THROW 54002, N'DeterministicLookup: ResultTable darf keine Eingabetabelle sein.', 3;
    DECLARE @Required TABLE (ObjectId int, ColumnName sysname, TypeId int, MaxLength int);
    INSERT @Required VALUES (@InputId,N'Ordinal',127,8),(@InputId,N'Key',165,-1),
        (@LookupId,N'Ordinal',127,8),(@LookupId,N'Value',231,-1);
    IF EXISTS (SELECT 1 FROM @Required AS required WHERE NOT EXISTS
        (SELECT 1 FROM tempdb.sys.columns AS actual WHERE actual.object_id = required.ObjectId
            AND CONVERT(varbinary(256),actual.name) = CONVERT(varbinary(256),required.ColumnName)
            AND actual.system_type_id = required.TypeId AND actual.user_type_id = actual.system_type_id
            AND actual.max_length = required.MaxLength AND actual.is_computed = 0))
        THROW 54002, N'DeterministicLookup: Ordinal bigint, Key varbinary(max), Value nvarchar(max) erforderlich.', 4;
    IF OBJECT_ID(N'tempdb..#tbx_DeterministicLookup_Pool',N'U') IS NOT NULL
        OR OBJECT_ID(N'tempdb..#tbx_DeterministicLookup_Input',N'U') IS NOT NULL
        OR OBJECT_ID(N'tempdb..#tbx_DeterministicLookup_Map',N'U') IS NOT NULL
        OR OBJECT_ID(N'tempdb..#tbx_DeterministicLookup_ResultSource',N'U') IS NOT NULL
        THROW 54009, N'DeterministicLookup: reservierter interner Temp-Name bereits sichtbar.', 1;

    -- Separate Compilergrenze: bei sichtbaren fremden Shapes niemals den
    -- tempgebundenen Ausgabekern kompilieren oder ausführen. Hilfe lief zuvor.
    EXEC toolbelt_pseudonymization.USP_DeterministicLookupCore
        @InputTable=@InputTable,@LookupTable=@LookupTable,@MappingVersion=@MappingVersion,
        @Seed=@Seed,@LookupVersion=@LookupVersion,@MaxInputRows=@MaxInputRows,
        @MaxLookupRows=@MaxLookupRows,@MaxLookupTextBytes=@MaxLookupTextBytes,
        @MaxResultBytes=@MaxResultBytes,@InputObjectId=@InputId,@LookupObjectId=@LookupId,
        @ResultTable=@ResultTable,@KeepData=@KeepData,@Debug=@Debug,@Hilfe=0;
    RETURN 0;
END;
GO
