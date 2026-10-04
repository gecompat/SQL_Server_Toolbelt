-- ============================================================================
-- Objekt: toolbelt_metadata.USP_ExecuteTableClone; Stored Procedure
-- Zweck: Hashgebundene Ausführung des vollständigen kanonischen V3-Plans.
-- Vertrag: USP_CONTRACT 1.0; TABLE_CLONE_EXECUTE_CONTRACT.md, Hashlayout v1.
-- Result: PlanHash varbinary(32), TablesCreated int, StatementsExecuted int;
--         alle NOT NULL; ResultTable alternativ, keine Datenkopie.
-- Dependencies: bestehender same-database Planner und Core ResultTable >=1.0.0.
-- Rechte: vorhandene DDL-/Metadatenrechte und Server VIEW ANY DEFINITION.
-- Fehler: 53930-53936; Engine-/Plannerfehler unverändert.
-- Grenzen: nur neue Ziele; keine Caller-TX, Rechte-/Owner-/Konfigurationsänderung.
-- Plattformen: SQL Server 2019/2022/2025 CL150+, Windows/Linux.
-- Performance: Map64, 1024 Spalten/128 Indizes je Quelle, global2048;
--              vollständiger Plan <=2097152 UTF16-Bytes, keine Wallclockgarantie.
-- ============================================================================
CREATE OR ALTER PROCEDURE toolbelt_metadata.USP_ExecuteTableClone
    @SourceSchema nvarchar(max)=NULL,
    @SourceTable nvarchar(max)=NULL,
    @TargetSchema nvarchar(max)=NULL,
    @TargetTable nvarchar(max)=NULL,
    @IncludeIdentity bit=0,
    @IncludeExtendedProperties bit=0,
    @TableMap sysname=NULL,
    @ExternalReferenceRule varchar(16)='REJECT',
    @ExpectedPlanHash varbinary(max)=NULL,
    @ForeignKeyMode varchar(16)='CREATE',
    @ResultTable sysname=NULL,
    @KeepData bit=0,
    @Debug tinyint=0,
    @Hilfe bit=0
AS
BEGIN
    SET NOCOUNT ON;
    IF @Hilfe=1
    BEGIN
        DECLARE @Help TABLE(Section varchar(32) NOT NULL,Ordinal int NOT NULL,
            ItemName sysname NULL,SqlDataType varchar(256) NULL,IsRequired bit NULL,
            IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,
            Description nvarchar(max) NOT NULL,ExampleSql nvarchar(max) NULL);
        INSERT @Help VALUES
        ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Erzeugt den V3-Plan neu und führt nur dessen hashgebundene DDL für neue same-database Ziele aus; keine Datenkopie.',NULL),
        ('PARAMETER',1,N'@SourceSchema','nvarchar(max)',1,0,N'NULL',N'V3-Einzelquelle; im Mapmodus NULL.',NULL),
        ('PARAMETER',2,N'@SourceTable','nvarchar(max)',1,0,N'NULL',N'V3-Einzelquelle; im Mapmodus NULL.',NULL),
        ('PARAMETER',3,N'@TargetSchema','nvarchar(max)',1,0,N'NULL',N'Bestehendes Installationsdatenbankschema; im Mapmodus NULL.',NULL),
        ('PARAMETER',4,N'@TargetTable','nvarchar(max)',1,0,N'NULL',N'Neuer Zielname; im Mapmodus NULL.',NULL),
        ('PARAMETER',5,N'@IncludeIdentity','bit',0,0,N'0',N'Unveränderte V3-Identityoption.',NULL),
        ('PARAMETER',6,N'@IncludeExtendedProperties','bit',0,0,N'0',N'Unveränderte V3-Propertyoption.',NULL),
        ('PARAMETER',7,N'@TableMap','sysname',0,1,N'NULL',N'NULL bewahrt Einzelmodus; sonst einmaliger Snapshot der fünfspaltigen V3-Map, 1..64 Zeilen.',NULL),
        ('PARAMETER',8,N'@ExternalReferenceRule','varchar(16)',0,0,N'REJECT',N'Byteexakt REJECT oder im Mapmodus KEEP.',NULL),
        ('PARAMETER',9,N'@ExpectedPlanHash','varbinary(max)',1,0,N'NULL',N'Exakt 32 Bytes des dokumentierten Hashlayouts v1, alle Planzeilen und Installationsdatenbank gebunden.',NULL),
        ('PARAMETER',10,N'@ForeignKeyMode','varchar(16)',0,0,N'CREATE',N'Byteexakt CREATE oder DEFER; DEFER lässt nur FOREIGN_KEY und FOREIGN_KEY_STATE aus, beide bleiben gehasht.',NULL),
        ('PARAMETER',11,N'@ResultTable','sysname',0,1,N'NULL',N'NULL liefert eine Erfolgszeile; sonst caller-lokale ResultTable.',NULL),
        ('PARAMETER',12,N'@KeepData','bit',0,1,N'0',N'0 Replace, 1 Append; NULL entspricht0.',NULL),
        ('PARAMETER',13,N'@Debug','tinyint',0,1,N'0',N'Nur Messages, keine Zusatzresultsets.',NULL),
        ('PARAMETER',14,N'@Hilfe','bit',0,1,N'0',N'Help vor sämtlichen Fachprüfungen.',NULL),
        ('RESULT_COLUMN',1,N'PlanHash','varbinary(32)',1,0,NULL,N'Vollständiger Hash, kein Rechte- oder Driftbeleg.',NULL),
        ('RESULT_COLUMN',2,N'TablesCreated','int',1,0,NULL,N'Tatsächlich neu angelegte Tabellen.',NULL),
        ('RESULT_COLUMN',3,N'StatementsExecuted','int',1,0,NULL,N'Fachliche DDL-Zeilen ohne SESSION_OPTION und bei DEFER ohne FK-Zeilen.',NULL),
        ('ERROR',1,NULL,NULL,NULL,NULL,NULL,N'53930 Argumente/Temps,53932 Sicht/Rechte,53933 DDL-Seiteneffekte,53934 Hash,53935 Plan/Ausführungspfade,53936 AppLock. Caller-TX: SQL50000/state1, Token TBX_TABLE_CLONE_EXECUTE_CALLER_TRANSACTION. Engine-/Plannerfehler unverändert.',NULL),
        ('PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'Vorhandene V3-/Core-/DDL-Rechte, Server VIEW ANY DEFINITION, lesbare Trigger-/Eventkataloge; keine Rechteerteilung.',NULL),
        ('LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'Nur neue Ziele, keine Datenkopie oder externe Atomik. Caller hält Quellen/Ziele/Serverbedingungen stabil. Map64 und vollständiger Plan2MiB; keine CPU/RAM/Wallclockgarantie.',NULL),
        ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Hash mit dokumentiertem v1-Layout aus eigener V3-Vorschau berechnen; keine freie SQL-Eingabe.',N'EXEC toolbelt_metadata.USP_ExecuteTableClone @Hilfe=1;');
        SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,
            CAST(N'toolbelt_metadata' AS sysname) SchemaName,
            CAST(N'USP_ExecuteTableClone' AS sysname) ObjectName,
            Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql
        FROM @Help ORDER BY CASE Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2
            WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4 WHEN 'PERMISSION' THEN 5
            WHEN 'LIMITATION' THEN 6 ELSE 7 END,Ordinal;
        RETURN;
    END;
    -- RAISERROR vor Facharbeit: XACT_ABORT des Callers darf dessen TX nicht doomen.
    IF @@TRANCOUNT>0
    BEGIN
        -- Nur prozeduraler Scope; XACT_ABORT wird beim Verlassen wiederhergestellt.
        SET XACT_ABORT OFF;
        RAISERROR(N'TBX_TABLE_CLONE_EXECUTE_CALLER_TRANSACTION: aktive Caller-Transaktion ist nicht unterstützt.',16,1);
        RETURN;
    END;
    IF @ExpectedPlanHash IS NULL OR DATALENGTH(@ExpectedPlanHash)<>32
        THROW 53930,N'TableClone Execute: ExpectedPlanHash verlangt genau32 Bytes.',1;
    IF @ForeignKeyMode IS NULL OR CONVERT(varbinary(max),@ForeignKeyMode) NOT IN(CONVERT(varbinary(max),'CREATE'),CONVERT(varbinary(max),'DEFER'))
        THROW 53930,N'TableClone Execute: ForeignKeyMode muss exakt CREATE oder DEFER sein.',2;
    IF @IncludeIdentity IS NULL OR @IncludeExtendedProperties IS NULL
        THROW 53930,N'TableClone Execute: Includeoptionen dürfen nicht NULL sein.',3;
    IF @ExternalReferenceRule IS NULL OR CONVERT(varbinary(max),@ExternalReferenceRule) NOT IN(CONVERT(varbinary(max),'REJECT'),CONVERT(varbinary(max),'KEEP'))
        THROW 53930,N'TableClone Execute: ExternalReferenceRule ungültig.',4;
    IF LOWER(LEFT(@TableMap,5)) COLLATE Latin1_General_100_BIN2=N'#tbx_' OR LOWER(LEFT(@ResultTable,5)) COLLATE Latin1_General_100_BIN2=N'#tbx_'
        THROW 53930,N'TableClone Execute: reservierter Caller-Tempnamespace.',5;
    IF EXISTS(SELECT 1 FROM (VALUES(N'#TableCloneExecute_MapStage'),(N'#TableCloneExecute_PlanStage'),
        (N'#tbx_TableCloneExecute_Result')) reserved(Name)
        WHERE OBJECT_ID(N'tempdb..'+Name) IS NOT NULL
           OR LOWER(@TableMap) COLLATE Latin1_General_100_BIN2=LOWER(Name) COLLATE Latin1_General_100_BIN2
           OR LOWER(@ResultTable) COLLATE Latin1_General_100_BIN2=LOWER(Name) COLLATE Latin1_General_100_BIN2)
        THROW 53930,N'TableClone Execute: reservierte Brücke ist belegt oder Callerziel.',6;
    DECLARE @MapId int=OBJECT_ID(N'tempdb..'+@TableMap,N'U'),@ResultId int=OBJECT_ID(N'tempdb..'+@ResultTable,N'U');
    IF @TableMap IS NOT NULL AND @MapId=@ResultId
        THROW 53930,N'TableClone Execute: Eingabe und Ausgabe dürfen nicht dasselbe Objekt sein.',7;

    CREATE TABLE #TableCloneExecute_MapStage(MapOrdinal int NOT NULL,
        SourceSchema nvarchar(max) COLLATE DATABASE_DEFAULT NOT NULL,
        SourceTable nvarchar(max) COLLATE DATABASE_DEFAULT NOT NULL,
        TargetSchema nvarchar(max) COLLATE DATABASE_DEFAULT NOT NULL,
        TargetTable nvarchar(max) COLLATE DATABASE_DEFAULT NOT NULL);
    DECLARE @MapMode bit=CASE WHEN @TableMap IS NULL THEN 0 ELSE 1 END;
    IF @MapMode=0
    BEGIN
        IF EXISTS(SELECT 1 FROM (VALUES(@SourceSchema),(@SourceTable),(@TargetSchema),(@TargetTable)) a(Name)
            WHERE Name IS NULL OR DATALENGTH(Name) NOT BETWEEN 2 AND 256)
            THROW 53930,N'TableClone Execute: Einzelidentifier ungültig.',8;
        INSERT #TableCloneExecute_MapStage VALUES(1,@SourceSchema,@SourceTable,@TargetSchema,@TargetTable);
    END
    ELSE
    BEGIN
        IF @SourceSchema IS NOT NULL OR @SourceTable IS NOT NULL OR @TargetSchema IS NOT NULL OR @TargetTable IS NOT NULL
            THROW 53930,N'TableClone Execute: Mapmodus verlangt vier NULL-Identifier.',9;
        IF LEFT(@TableMap,1)<>N'#' OR LEFT(@TableMap,2)=N'##' OR LEN(@TableMap)<2
            OR SUBSTRING(@TableMap,2,128) COLLATE Latin1_General_100_BIN2 LIKE N'%[^A-Za-z0-9_]%'
            THROW 53930,N'TableClone Execute: ungültiger lokaler Mapname.',10;
        IF @MapId IS NULL OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=@MapId)<>5
            OR EXISTS(SELECT 1 FROM tempdb.sys.columns WHERE object_id=@MapId AND
                (is_nullable<>0 OR is_computed<>0 OR user_type_id<>system_type_id OR
                 NOT ((CONVERT(varbinary(256),name)=CONVERT(varbinary(256),N'MapOrdinal') AND system_type_id=56 AND max_length=4)
                   OR (CONVERT(varbinary(256),name) IN(CONVERT(varbinary(256),N'SourceSchema'),CONVERT(varbinary(256),N'SourceTable'),CONVERT(varbinary(256),N'TargetSchema'),CONVERT(varbinary(256),N'TargetTable')) AND system_type_id=231 AND max_length=-1))))
            THROW 53930,N'TableClone Execute: Map verlangt fünf genaue NOT-NULL-Basistypen.',11;
        -- Einmaliger Caller-Snapshot; Admission und INSERT im selben kontrollierten Batch.
        DECLARE @SnapshotSql nvarchar(max)=N'IF NOT EXISTS(SELECT 1 FROM '+QUOTENAME(@TableMap)+N')
            OR (SELECT COUNT_BIG(*) FROM '+QUOTENAME(@TableMap)+N')>64
            OR EXISTS(SELECT 1 FROM '+QUOTENAME(@TableMap)+N' WHERE MapOrdinal<=0 OR DATALENGTH(SourceSchema) NOT BETWEEN 2 AND 256 OR DATALENGTH(SourceTable) NOT BETWEEN 2 AND 256 OR DATALENGTH(TargetSchema) NOT BETWEEN 2 AND 256 OR DATALENGTH(TargetTable) NOT BETWEEN 2 AND 256)
            OR EXISTS(SELECT 1 FROM '+QUOTENAME(@TableMap)+N' GROUP BY MapOrdinal HAVING COUNT_BIG(*)<>1)
            THROW 53930,N''TableClone Execute: ungültige Mapzeilen.'',12;
            INSERT #TableCloneExecute_MapStage(MapOrdinal,SourceSchema,SourceTable,TargetSchema,TargetTable)
            SELECT MapOrdinal,SourceSchema,SourceTable,TargetSchema,TargetTable FROM '+QUOTENAME(@TableMap)+N';';
        EXEC sys.sp_executesql @SnapshotSql;
    END;
    CREATE TABLE #TableCloneExecute_PlanStage(Ordinal int NOT NULL,
        ObjectKind varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,
        TargetName nvarchar(776) COLLATE Latin1_General_100_BIN2 NOT NULL,
        ScriptText nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL);
    -- Originalmodus erhalten: eine virtuelle Hashmap macht Single nicht zum Mapmodus.
    IF @MapMode=0
        EXEC toolbelt_metadata.USP_ScriptTableClone @SourceSchema=@SourceSchema,@SourceTable=@SourceTable,
            @TargetSchema=@TargetSchema,@TargetTable=@TargetTable,@IncludeIdentity=@IncludeIdentity,
            @IncludeExtendedProperties=@IncludeExtendedProperties,@ExternalReferenceRule=@ExternalReferenceRule,
            @TableMap=NULL,@ResultTable=N'#TableCloneExecute_PlanStage',@KeepData=0,@Debug=0,@Hilfe=0;
    ELSE
        EXEC toolbelt_metadata.USP_ScriptTableClone @IncludeIdentity=@IncludeIdentity,
            @IncludeExtendedProperties=@IncludeExtendedProperties,@ExternalReferenceRule=@ExternalReferenceRule,
            @TableMap=N'#TableCloneExecute_MapStage',@ResultTable=N'#TableCloneExecute_PlanStage',@KeepData=0,@Debug=0,@Hilfe=0;

    DECLARE @PlanCount int=(SELECT COUNT(*) FROM #TableCloneExecute_PlanStage);
    IF @PlanCount<8 OR (SELECT MIN(Ordinal) FROM #TableCloneExecute_PlanStage)<>1
        OR (SELECT MAX(Ordinal) FROM #TableCloneExecute_PlanStage)<>@PlanCount
        OR EXISTS(SELECT 1 FROM #TableCloneExecute_PlanStage GROUP BY Ordinal HAVING COUNT(*)<>1)
        OR EXISTS(SELECT 1 FROM #TableCloneExecute_PlanStage WHERE ObjectKind NOT IN('SESSION_OPTION','TABLE','DEFAULT','CHECK','PRIMARY_KEY','UNIQUE_CONSTRAINT','INDEX','EXTENDED_PROPERTY','FOREIGN_KEY','FOREIGN_KEY_STATE'))
        THROW 53935,N'TableClone Execute: kanonische Planform ungültig.',1;
    DECLARE @SetOptions TABLE(Ordinal int NOT NULL,Statement nvarchar(128) NOT NULL);
    INSERT @SetOptions VALUES(1,N'SET ANSI_NULLS ON;'),(2,N'SET ANSI_PADDING ON;'),(3,N'SET ANSI_WARNINGS ON;'),
        (4,N'SET ARITHABORT ON;'),(5,N'SET CONCAT_NULL_YIELDS_NULL ON;'),(6,N'SET QUOTED_IDENTIFIER ON;'),(7,N'SET NUMERIC_ROUNDABORT OFF;');
    IF EXISTS(SELECT 1 FROM @SetOptions s LEFT JOIN #TableCloneExecute_PlanStage p ON p.Ordinal=s.Ordinal
        WHERE CONVERT(varbinary(max),p.ObjectKind)<>CONVERT(varbinary(max),'SESSION_OPTION')
           OR CONVERT(varbinary(max),p.ScriptText)<>CONVERT(varbinary(max),s.Statement))
        OR EXISTS(SELECT 1 FROM #TableCloneExecute_PlanStage WHERE Ordinal>7 AND ObjectKind='SESSION_OPTION')
        THROW 53935,N'TableClone Execute: sieben kanonische SET-Zeilen fehlen.',2;

    -- Hashlayout v1: native binary(4) int / UTF16LE byte-framed, keine Textnormalisierung.
    DECLARE @Header varbinary(max)=0x,@Text nvarchar(max),@Ordinal int,@Kind varchar(32),@Target nvarchar(776),@Script nvarchar(max);
    SET @Text=N'Toolbelt.TableClone.Execute.Hash';
    SET @Header=@Header+CONVERT(binary(4),DATALENGTH(@Text))+CONVERT(varbinary(max),@Text)+CONVERT(binary(4),CONVERT(int,1));
    SET @Text=N'3.1.0'; SET @Header=@Header+CONVERT(binary(4),DATALENGTH(@Text))+CONVERT(varbinary(max),@Text)+CONVERT(binary(4),DB_ID());
    SET @Text=DB_NAME(); SET @Header=@Header+CONVERT(binary(4),DATALENGTH(@Text))+CONVERT(varbinary(max),@Text)
        +CONVERT(binary(1),@IncludeIdentity)+CONVERT(binary(1),@IncludeExtendedProperties)+CONVERT(binary(1),@MapMode);
    SET @Text=CONVERT(nvarchar(max),@ExternalReferenceRule); SET @Header=@Header+CONVERT(binary(4),DATALENGTH(@Text))+CONVERT(varbinary(max),@Text);
    SET @Text=CONVERT(nvarchar(max),@ForeignKeyMode); SET @Header=@Header+CONVERT(binary(4),DATALENGTH(@Text))+CONVERT(varbinary(max),@Text)
        +CONVERT(binary(4),(SELECT COUNT(*) FROM #TableCloneExecute_MapStage));
    DECLARE HashMap CURSOR LOCAL FAST_FORWARD FOR SELECT MapOrdinal,SourceSchema,SourceTable,TargetSchema,TargetTable FROM #TableCloneExecute_MapStage ORDER BY MapOrdinal;
    OPEN HashMap;
    FETCH NEXT FROM HashMap INTO @Ordinal,@SourceSchema,@SourceTable,@TargetSchema,@TargetTable;
    WHILE @@FETCH_STATUS=0
    BEGIN
        SET @Header=@Header+CONVERT(binary(4),@Ordinal)
            +CONVERT(binary(4),DATALENGTH(@SourceSchema))+CONVERT(varbinary(max),@SourceSchema)
            +CONVERT(binary(4),DATALENGTH(@SourceTable))+CONVERT(varbinary(max),@SourceTable)
            +CONVERT(binary(4),DATALENGTH(@TargetSchema))+CONVERT(varbinary(max),@TargetSchema)
            +CONVERT(binary(4),DATALENGTH(@TargetTable))+CONVERT(varbinary(max),@TargetTable);
        FETCH NEXT FROM HashMap INTO @Ordinal,@SourceSchema,@SourceTable,@TargetSchema,@TargetTable;
    END;
    CLOSE HashMap; DEALLOCATE HashMap;
    DECLARE @PlanHash varbinary(32)=HASHBYTES('SHA2_256',@Header);
    DECLARE HashPlan CURSOR LOCAL FAST_FORWARD FOR SELECT Ordinal,ObjectKind,TargetName,ScriptText FROM #TableCloneExecute_PlanStage ORDER BY Ordinal;
    OPEN HashPlan;
    FETCH NEXT FROM HashPlan INTO @Ordinal,@Kind,@Target,@Script;
    WHILE @@FETCH_STATUS=0
    BEGIN
        SET @Text=CONVERT(nvarchar(max),@Kind);
        SET @PlanHash=HASHBYTES('SHA2_256',CONVERT(varbinary(max),@PlanHash)+CONVERT(binary(4),@Ordinal)
            +CONVERT(binary(4),DATALENGTH(@Text))+CONVERT(varbinary(max),@Text)
            +CONVERT(binary(4),DATALENGTH(@Target))+CONVERT(varbinary(max),@Target)
            +CONVERT(binary(4),DATALENGTH(@Script))+CONVERT(varbinary(max),@Script));
        FETCH NEXT FROM HashPlan INTO @Ordinal,@Kind,@Target,@Script;
    END;
    CLOSE HashPlan; DEALLOCATE HashPlan;
    SET @Text=N'Toolbelt.TableClone.Execute.Final';
    SET @PlanHash=HASHBYTES('SHA2_256',CONVERT(varbinary(max),@PlanHash)+CONVERT(binary(4),@PlanCount)+CONVERT(binary(4),DATALENGTH(@Text))+CONVERT(varbinary(max),@Text));
    IF @PlanHash<>@ExpectedPlanHash THROW 53934,N'TableClone Execute: erwarteter Planhash stimmt nicht.',1;

    -- Fester Sicherheitsbatch, vor eigener TX und darin unmittelbar vor Ziel-DDL.
    -- SELECT über alle Kataloge beweist Lesbarkeit; leere gefilterte Sicht reicht nie.
    DECLARE @SafetySql nvarchar(max)=N'
        IF COALESCE(HAS_PERMS_BY_NAME(NULL,NULL,N''VIEW ANY DEFINITION''),0)<>1
          OR COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N''DATABASE'',N''VIEW DEFINITION''),0)<>1
          OR COALESCE(HAS_PERMS_BY_NAME(N''sys.sql_expression_dependencies'',N''OBJECT'',N''SELECT''),0)<>1
          THROW 53932,N''TableClone Execute: vollständige Server-/DB-Metadatensicht fehlt.'',1;
        DECLARE @Visible bigint;
        SELECT @Visible=COUNT_BIG(*) FROM sys.triggers;
        SELECT @Visible=COUNT_BIG(*) FROM sys.trigger_events;
        SELECT @Visible=COUNT_BIG(*) FROM sys.events;
        SELECT @Visible=COUNT_BIG(*) FROM sys.event_notifications;
        SELECT @Visible=COUNT_BIG(*) FROM sys.server_triggers;
        SELECT @Visible=COUNT_BIG(*) FROM sys.server_trigger_events;
        SELECT @Visible=COUNT_BIG(*) FROM sys.server_events;
        SELECT @Visible=COUNT_BIG(*) FROM sys.server_event_notifications;
        DECLARE @Relevant TABLE(Name nvarchar(60) NOT NULL);
        INSERT @Relevant VALUES(N''CREATE_TABLE''),(N''ALTER_TABLE''),(N''CREATE_INDEX''),(N''ADD_EXTENDED_PROPERTY'');
        IF EXISTS(SELECT 1 FROM sys.triggers t WHERE t.parent_class=0 AND t.is_disabled=0 AND
            (NOT EXISTS(SELECT 1 FROM sys.trigger_events e WHERE e.object_id=t.object_id)
             OR EXISTS(SELECT 1 FROM sys.trigger_events e WHERE e.object_id=t.object_id AND (e.type_desc IS NULL OR e.type IS NULL OR e.type_desc COLLATE DATABASE_DEFAULT IN(SELECT Name FROM @Relevant)))))
          OR EXISTS(SELECT 1 FROM sys.server_triggers t WHERE t.is_disabled=0 AND
            (NOT EXISTS(SELECT 1 FROM sys.server_trigger_events e WHERE e.object_id=t.object_id)
             OR EXISTS(SELECT 1 FROM sys.server_trigger_events e WHERE e.object_id=t.object_id AND (e.type_desc IS NULL OR e.type IS NULL OR e.type_desc COLLATE DATABASE_DEFAULT IN(SELECT Name FROM @Relevant)))))
          OR EXISTS(SELECT 1 FROM sys.event_notifications n WHERE n.parent_class=0 AND
            (NOT EXISTS(SELECT 1 FROM sys.events e WHERE e.object_id=n.object_id AND e.is_trigger_event=0)
             OR EXISTS(SELECT 1 FROM sys.events e WHERE e.object_id=n.object_id AND e.is_trigger_event=0 AND (e.type_desc IS NULL OR e.type IS NULL OR e.type_desc COLLATE DATABASE_DEFAULT IN(SELECT Name FROM @Relevant)))))
          OR EXISTS(SELECT 1 FROM sys.server_event_notifications n WHERE
            NOT EXISTS(SELECT 1 FROM sys.server_events e WHERE e.object_id=n.object_id)
             OR EXISTS(SELECT 1 FROM sys.server_events e WHERE e.object_id=n.object_id AND (e.type_desc IS NULL OR e.type IS NULL OR e.type_desc COLLATE DATABASE_DEFAULT IN(SELECT Name FROM @Relevant))))
          THROW 53933,N''TableClone Execute: relevante oder nicht klassifizierbare DDL-Seiteneffekte.'',1;
        IF COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N''DATABASE'',N''CREATE TABLE''),0)<>1
          OR EXISTS(SELECT 1 FROM #TableCloneExecute_MapStage m WHERE COALESCE(HAS_PERMS_BY_NAME(QUOTENAME(m.TargetSchema),N''SCHEMA'',N''ALTER''),0)<>1)
          THROW 53932,N''TableClone Execute: vorhandene Ziel-DDL-Rechte fehlen.'',2;
        IF EXISTS(SELECT 1 FROM #TableCloneExecute_MapStage m WHERE EXISTS(SELECT 1 FROM sys.objects o WHERE o.schema_id=SCHEMA_ID(m.TargetSchema) AND o.name=m.TargetTable COLLATE DATABASE_DEFAULT))
          THROW 53935,N''TableClone Execute: Ziel seit Planung belegt.'',3;
        IF @CreateForeignKeys=1 AND EXISTS(SELECT 1 FROM sys.foreign_keys f
          JOIN #TableCloneExecute_MapStage ownerMap ON f.parent_object_id=OBJECT_ID(QUOTENAME(ownerMap.SourceSchema)+N''.''+QUOTENAME(ownerMap.SourceTable),N''U'')
          LEFT JOIN #TableCloneExecute_MapStage refMap ON f.referenced_object_id=OBJECT_ID(QUOTENAME(refMap.SourceSchema)+N''.''+QUOTENAME(refMap.SourceTable),N''U'')
          WHERE (refMap.MapOrdinal IS NOT NULL AND COALESCE(HAS_PERMS_BY_NAME(QUOTENAME(refMap.TargetSchema),N''SCHEMA'',N''REFERENCES''),0)<>1)
             OR (refMap.MapOrdinal IS NULL AND COALESCE(HAS_PERMS_BY_NAME(QUOTENAME(OBJECT_SCHEMA_NAME(f.referenced_object_id))+N''.''+QUOTENAME(OBJECT_NAME(f.referenced_object_id)),N''OBJECT'',N''REFERENCES''),0)<>1))
          THROW 53932,N''TableClone Execute: vorhandene FK-REFERENCES-Rechte fehlen.'',3;
        IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d
           JOIN #TableCloneExecute_MapStage m ON d.referencing_id=OBJECT_ID(QUOTENAME(m.SourceSchema)+N''.''+QUOTENAME(m.SourceTable),N''U'')
           JOIN sys.computed_columns c ON c.object_id=d.referencing_id AND c.column_id=d.referencing_minor_id
           WHERE d.referenced_class<>1 OR d.referenced_server_name IS NOT NULL OR d.referenced_database_name IS NOT NULL
             OR d.is_ambiguous=1 OR d.is_caller_dependent=1 OR d.referenced_id IS NULL OR d.referenced_id<>c.object_id)
          OR EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d JOIN sys.objects expression ON expression.object_id=d.referencing_id AND expression.type IN(''D'',''C'')
           JOIN #TableCloneExecute_MapStage m ON expression.parent_object_id=OBJECT_ID(QUOTENAME(m.SourceSchema)+N''.''+QUOTENAME(m.SourceTable),N''U'')
           WHERE d.referenced_class<>1 OR d.referenced_server_name IS NOT NULL OR d.referenced_database_name IS NOT NULL
             OR d.is_ambiguous=1 OR d.is_caller_dependent=1 OR d.referenced_id IS NULL OR d.referenced_id<>expression.parent_object_id)
          THROW 53935,N''TableClone Execute: DEFAULT/CHECK/Computed-Ausführungspfad nicht tabellenlokal.'',4;';
    DECLARE @CreateForeignKeys bit=CASE WHEN @ForeignKeyMode='CREATE' THEN 1 ELSE 0 END;
    EXEC sys.sp_executesql @SafetySql,N'@CreateForeignKeys bit',@CreateForeignKeys;
    CREATE TABLE #tbx_TableCloneExecute_Result(PlanHash varbinary(32) NOT NULL,TablesCreated int NOT NULL,StatementsExecuted int NOT NULL);
    DECLARE @SetPrefix nvarchar(max)=N'SET ANSI_NULLS ON; SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET CONCAT_NULL_YIELDS_NULL ON; SET QUOTED_IDENTIFIER ON; SET NUMERIC_ROUNDABORT OFF;'+NCHAR(10),
        @TablesCreated int=0,@StatementsExecuted int=0,@LockResult int,@Own bit=0;
    BEGIN TRY
        BEGIN TRANSACTION; SET @Own=1;
        EXEC @LockResult=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.metadata.table-clone',
            @LockMode=N'Shared',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
        IF COALESCE(@LockResult,-999)<0 THROW 53936,N'TableClone Execute: Lifecycle-AppLock nicht verfügbar.',1;
        EXEC sys.sp_executesql @SafetySql,N'@CreateForeignKeys bit',@CreateForeignKeys;
        DECLARE ExecutePlan CURSOR LOCAL FAST_FORWARD FOR SELECT ObjectKind,ScriptText FROM #TableCloneExecute_PlanStage
            WHERE ObjectKind<>'SESSION_OPTION' AND (@ForeignKeyMode='CREATE' OR ObjectKind NOT IN('FOREIGN_KEY','FOREIGN_KEY_STATE')) ORDER BY Ordinal;
        OPEN ExecutePlan;
        FETCH NEXT FROM ExecutePlan INTO @Kind,@Script;
        WHILE @@FETCH_STATUS=0
        BEGIN
            SET @Script=@SetPrefix+@Script;
            EXEC sys.sp_executesql @Script;
            SET @StatementsExecuted+=1;
            IF @Kind='TABLE' SET @TablesCreated+=1;
            FETCH NEXT FROM ExecutePlan INTO @Kind,@Script;
        END;
        CLOSE ExecutePlan; DEALLOCATE ExecutePlan;
        INSERT #tbx_TableCloneExecute_Result VALUES(@PlanHash,@TablesCreated,@StatementsExecuted);
        IF @ResultTable IS NOT NULL
        BEGIN
            EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,
                @LikeTable=N'#tbx_TableCloneExecute_Result',@KeepData=@KeepData,@Debug=@Debug;
            DECLARE @OutputSql nvarchar(max)=N'INSERT '+QUOTENAME(@ResultTable)+N' (PlanHash,TablesCreated,StatementsExecuted) SELECT PlanHash,TablesCreated,StatementsExecuted FROM #tbx_TableCloneExecute_Result;';
            EXEC sys.sp_executesql @OutputSql;
        END;
        COMMIT TRANSACTION; SET @Own=0;
    END TRY
    BEGIN CATCH
        -- Nebenfehler nur als feste Information; nacktes THROW erhält den Primärfehler.
        BEGIN TRY
            IF @Own=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        END TRY
        BEGIN CATCH
            RAISERROR(N'TBX_TABLE_CLONE_EXECUTE_SECONDARY_ROLLBACK',10,1) WITH NOWAIT;
        END CATCH;
        THROW;
    END CATCH;
    IF @ResultTable IS NULL SELECT PlanHash,TablesCreated,StatementsExecuted FROM #tbx_TableCloneExecute_Result;
END;
GO
