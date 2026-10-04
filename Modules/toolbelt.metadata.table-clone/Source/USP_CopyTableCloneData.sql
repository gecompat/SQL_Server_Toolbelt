-- ============================================================================
-- Objekt: toolbelt_metadata.USP_CopyTableCloneData; Stored Procedure
-- Zweck: Begrenzte SameDB-Datenkopie in leere formgleiche gemappte Targets.
-- Vertrag: USP_CONTRACT1.0; TABLE_CLONE_DATA_COPY_CONTRACT.md; Modul4.1.0.
-- Parameter: TableMap sysname=NULL; IdentityMode/ConsistencyMode varchar(16)=NULL;
--            RowLimit bigint=100000; PayloadByteLimit bigint=16777216; Standardtail.
-- Resultset: MappedTables int, CopiedRows/PayloadBytes bigint,
--            CreatedForeignKeys int, Status varchar(16)=COPIED; alle NOT NULL.
-- Dependencies: gemeinsamer SameDB-Core14 mit COPY_FK; ResultTable >=1.0.0.
-- Rechte: vorhandene DB-Vollsicht, Katalog-SELECT und Source-/Target-DML-Rechte;
--         nur fehlende FKs verlangen zusätzliche Server-DDL-Sicht/DDL-Rechte.
-- Versionen/Plattformen: SQL Server2019/2022/2025 CL150+, Windows/Linux.
-- Fehlerverhalten:53940..53946; Enginefehler unverändert; eigene SQL-Transaktion;
--                 aktive Caller-TX wird mit50000/1 ohne Doomen zurückgewiesen.
-- Performance:64 Maps,100000 globale Zeilen,16777216 globale Nutzdatenbytes;
--             vollständige Admission vor Inserts, keine Heap-/Wallclockgarantie.
-- Einschränkungen: keine Rechte-/Owner-/Configänderung, kein RESEED;
--                  Identity-Zähler können Rollback überleben; keine externe Atomik.
-- ============================================================================
CREATE OR ALTER PROCEDURE toolbelt_metadata.USP_CopyTableCloneData
    @TableMap sysname=NULL,
    @IdentityMode varchar(16)=NULL,
    @ConsistencyMode varchar(16)=NULL,
    @RowLimit bigint=100000,
    @PayloadByteLimit bigint=16777216,
    @ResultTable sysname=NULL,
    @KeepData bit=0,
    @Debug tinyint=0,
    @Hilfe bit=0
AS
BEGIN
    SET NOCOUNT ON;
    IF @Hilfe=1
    BEGIN
        SELECT CONVERT(varchar(16),'1.0') HelpContractVersion,
            CONVERT(sysname,N'toolbelt_metadata') SchemaName,
            CONVERT(sysname,N'USP_CopyTableCloneData') ObjectName,
            CONVERT(varchar(32),h.Section) Section,h.Ordinal,
            CONVERT(sysname,h.ItemName) ItemName,CONVERT(varchar(256),h.SqlDataType) SqlDataType,
            CONVERT(bit,h.IsRequired) IsRequired,CONVERT(bit,h.IsNullable) IsNullable,
            CONVERT(nvarchar(4000),h.DefaultValue) DefaultValue,
            CONVERT(nvarchar(max),h.Description) Description,
            CONVERT(nvarchar(max),h.ExampleSql) ExampleSql
        FROM(VALUES
          ('DESCRIPTION',0,NULL,NULL,NULL,NULL,NULL,N'Begrenzte SameDB-Kopie; leere formgleiche Targets und eigene Transaktion.',NULL),
          ('PARAMETER',1,N'@TableMap','sysname',1,0,N'NULL',N'Lokale fünfspaltige Map;1..64 eindeutige Ordinals.',NULL),
          ('PARAMETER',2,N'@IdentityMode','varchar(16)',1,0,N'NULL',N'Exakt KEEP oder REGENERATE.',NULL),
          ('PARAMETER',3,N'@ConsistencyMode','varchar(16)',1,0,N'NULL',N'Exakt SNAPSHOT oder SERIALIZABLE; keine Configänderung.',NULL),
          ('PARAMETER',4,N'@RowLimit','bigint',0,0,N'100000',N'Positiv, maximal100000 global; Caller darf absenken.',NULL),
          ('PARAMETER',5,N'@PayloadByteLimit','bigint',0,0,N'16777216',N'Positiv, maximal16MiB globale transportierte SQL-Nutzdaten.',NULL),
          ('PARAMETER',6,N'@ResultTable','sysname',0,1,N'NULL',N'Bestehende lokale ResultTable; alternativ ein Resultset.',NULL),
          ('PARAMETER',7,N'@KeepData','bit',0,1,N'0',N'Kanonische ResultTable-Replace/Append-Semantik.',NULL),
          ('PARAMETER',8,N'@Debug','tinyint',0,1,N'0',N'Messages, kein zusätzliches Resultset.',NULL),
          ('PARAMETER',9,N'@Hilfe','bit',0,1,N'0',N'Nur diese Hilfe; keine fachliche Arbeit.',NULL),
          ('RESULT_COLUMN',1,N'MappedTables','int',NULL,0,NULL,N'Anzahl validierter Maps.',NULL),
          ('RESULT_COLUMN',2,N'CopiedRows','bigint',NULL,0,NULL,N'Tatsächlich eingefügte Gesamtzeilen.',NULL),
          ('RESULT_COLUMN',3,N'PayloadBytes','bigint',NULL,0,NULL,N'Globale DATALENGTH-Summe tatsächlich transportierter Spalten; NULL0.',NULL),
          ('RESULT_COLUMN',4,N'CreatedForeignKeys','int',NULL,0,NULL,N'Tatsächlich neu angelegte fehlende FKs.',NULL),
          ('RESULT_COLUMN',5,N'Status','varchar(16)',NULL,0,NULL,N'Exakt COPIED.',NULL),
          ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Reiner Hilfeaufruf.',N'EXEC toolbelt_metadata.USP_CopyTableCloneData @Hilfe=1;'),
          ('PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'Vorhandene datenbankweite VIEW DEFINITION, Katalog-SELECT und Source-SELECT/Target-SELECT/INSERT; fehlende FK-DDL zusätzlich volle Server-DDL-Sicht und ALTER/REFERENCES. Keine Rechtevergabe.',NULL),
          ('ERROR',1,NULL,NULL,NULL,NULL,NULL,N'53940 Argumente/Map/Temp,53941 Rechte/Sicht/Form,53942 Seiteneffekte,53943 Row-/Nutzdatenbudget,53944 Shape/FKs/Admission/Drift,53945 reserviert,53946 Lifecycle-Lock; Caller-TX50000/1 mit TBX_TABLE_CLONE_COPY_CALLER_TRANSACTION; Enginefehler unverändert.',NULL),
          ('LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'Identity-Zähler können Rollback überleben; kein RESEED/Zuordnungsversprechen. Nur leere SameDB-Targets, keine aktiven Targettrigger/RLS/Sonderformen; XML/LOB innerhalb vorhandener Shapegrenze. Keine Config-/Owner-/Rechteänderung.',NULL)
        )h(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE h.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1 WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END,h.Ordinal;
        RETURN;
    END;
    IF @@TRANCOUNT<>0
    BEGIN
        SET XACT_ABORT OFF;
        RAISERROR(N'TBX_TABLE_CLONE_COPY_CALLER_TRANSACTION',16,1);
        RETURN;
    END;
    IF @IdentityMode IS NULL OR CONVERT(varbinary(max),@IdentityMode) NOT IN(CONVERT(varbinary(max),'KEEP'),CONVERT(varbinary(max),'REGENERATE'))
       OR @ConsistencyMode IS NULL OR CONVERT(varbinary(max),@ConsistencyMode) NOT IN(CONVERT(varbinary(max),'SNAPSHOT'),CONVERT(varbinary(max),'SERIALIZABLE'))
       OR @RowLimit IS NULL OR @RowLimit<1 OR @RowLimit>100000
       OR @PayloadByteLimit IS NULL OR @PayloadByteLimit<1 OR @PayloadByteLimit>16777216
        THROW 53940,N'TableClone Copy: ungültiger Modus oder Budget.',1;
    SELECT @KeepData=COALESCE(@KeepData,0),@Debug=COALESCE(@Debug,0);
    IF @TableMap IS NULL OR LEFT(@TableMap,1)<>N'#' OR LEFT(@TableMap,2)=N'##'
       OR LEFT(LOWER(@TableMap COLLATE Latin1_General_100_BIN2),5)=N'#tbx_'
       OR (@ResultTable IS NOT NULL AND (LEFT(@ResultTable,1)<>N'#' OR LEFT(@ResultTable,2)=N'##' OR LEFT(LOWER(@ResultTable COLLATE Latin1_General_100_BIN2),5)=N'#tbx_'))
        THROW 53940,N'TableClone Copy: lokale nichtinterne Tempnamen erforderlich.',2;
    DECLARE @MapId int=OBJECT_ID(N'tempdb..'+@TableMap,N'U'),@ResultId int=OBJECT_ID(N'tempdb..'+@ResultTable,N'U');
    IF @MapId IS NULL OR (@ResultTable IS NOT NULL AND @ResultId IS NULL) OR @MapId=@ResultId
        THROW 53940,N'TableClone Copy: fehlende oder überlappende Input-/Outputtemp.',3;
    -- Die eigene FK-Ausgabebrücke vermeidet den reservierten Helperpräfix; der Kollisionsguard schützt fremde Tabellen vor CREATE und Corekompilierung.
    IF OBJECT_ID(N'tempdb..#tbx_TableClone_CopyMapStage',N'U') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#Toolbelt_TableClone_CopyFkStage',N'U') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#tbx_TableClone_CopyWork',N'U') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#tbx_TableClone_CopyColumns',N'U') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#tbx_TableClone_CopyShape',N'U') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#tbx_TableClone_CopyResult',N'U') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#tbx_TableClone_Plan',N'U') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#tbx_TableClone_Map',N'U') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#tbx_TableClone_Order',N'U') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#tbx_TableClone_Names',N'U') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#tbx_TableClone_EpOwners',N'U') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#tbx_TableClone_AstNodes',N'U') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#tbx_TableClone_AstProperties',N'U') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#tbx_TableClone_AstTokens',N'U') IS NOT NULL
       OR OBJECT_ID(N'tempdb..#tbx_TableClone_AstErrors',N'U') IS NOT NULL
        THROW 53940,N'TableClone Copy: fremdes internes Tempobjekt.',4;
    DECLARE @MapShape TABLE(Ordinal int,Name sysname,TypeId int,Length smallint);
    INSERT @MapShape VALUES(1,N'MapOrdinal',56,4),(2,N'SourceSchema',231,-1),(3,N'SourceTable',231,-1),(4,N'TargetSchema',231,-1),(5,N'TargetTable',231,-1);
    IF (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=@MapId)<>5
       OR EXISTS(SELECT 1 FROM @MapShape s WHERE NOT EXISTS(SELECT 1 FROM tempdb.sys.columns c WHERE c.object_id=@MapId AND c.column_id=s.Ordinal
         AND CONVERT(varbinary(256),c.name)=CONVERT(varbinary(256),s.Name) AND c.system_type_id=s.TypeId AND c.user_type_id=c.system_type_id
         AND c.max_length=s.Length AND c.is_nullable=0 AND c.is_computed=0 AND c.is_identity=0))
        THROW 53940,N'TableClone Copy: Mapform stimmt nicht.',5;
    CREATE TABLE #tbx_TableClone_CopyMapStage(MapOrdinal int NOT NULL,SourceSchema nvarchar(max) COLLATE DATABASE_DEFAULT NOT NULL,SourceTable nvarchar(max) COLLATE DATABASE_DEFAULT NOT NULL,
        TargetSchema nvarchar(max) COLLATE DATABASE_DEFAULT NOT NULL,TargetTable nvarchar(max) COLLATE DATABASE_DEFAULT NOT NULL);
    -- Nur 65 Kandidaten und längengeprüfte Identifier gelangen in den privaten Snapshot.
    -- Die Core-Bridge behält ihre kanonische max-Form, aber nur validierte 128er Werte.
    DECLARE @Sql nvarchar(max)=N'DECLARE @Admitted TABLE(MapOrdinal int NOT NULL,SourceSchema nvarchar(128),SourceTable nvarchar(128),TargetSchema nvarchar(128),TargetTable nvarchar(128),Invalid bit NOT NULL);
INSERT @Admitted
SELECT TOP(65) MapOrdinal,
 CASE WHEN DATALENGTH(SourceSchema) BETWEEN 2 AND 256 THEN CONVERT(nvarchar(128),SourceSchema) END,
 CASE WHEN DATALENGTH(SourceTable) BETWEEN 2 AND 256 THEN CONVERT(nvarchar(128),SourceTable) END,
 CASE WHEN DATALENGTH(TargetSchema) BETWEEN 2 AND 256 THEN CONVERT(nvarchar(128),TargetSchema) END,
 CASE WHEN DATALENGTH(TargetTable) BETWEEN 2 AND 256 THEN CONVERT(nvarchar(128),TargetTable) END,
 CASE WHEN MapOrdinal<1 OR DATALENGTH(SourceSchema) NOT BETWEEN 2 AND 256 OR DATALENGTH(SourceTable) NOT BETWEEN 2 AND 256
 OR DATALENGTH(TargetSchema) NOT BETWEEN 2 AND 256 OR DATALENGTH(TargetTable) NOT BETWEEN 2 AND 256 THEN 1 ELSE 0 END
FROM '+QUOTENAME(@TableMap)+N';
IF (SELECT COUNT_BIG(*) FROM @Admitted) NOT BETWEEN 1 AND 64
 OR EXISTS(SELECT 1 FROM @Admitted WHERE Invalid=1 OR SourceSchema IS NULL OR SourceTable IS NULL OR TargetSchema IS NULL OR TargetTable IS NULL)
 OR EXISTS(SELECT 1 FROM @Admitted GROUP BY MapOrdinal HAVING COUNT_BIG(*)<>1)
 THROW 53940,N''TableClone Copy: Mapbudget oder Identifierform ungültig.'',6;
INSERT #tbx_TableClone_CopyMapStage SELECT MapOrdinal,SourceSchema,SourceTable,TargetSchema,TargetTable FROM @Admitted;';
    EXEC sys.sp_executesql @Sql;
    CREATE TABLE #tbx_TableClone_CopyWork(MapOrdinal int NOT NULL PRIMARY KEY,SourceId int NOT NULL,TargetId int NOT NULL,SourceName nvarchar(776) COLLATE DATABASE_DEFAULT NOT NULL,
        TargetName nvarchar(776) COLLATE DATABASE_DEFAULT NOT NULL,Rows bigint NULL,Bytes bigint NULL,Copied bit NOT NULL DEFAULT(0));
    IF EXISTS(SELECT 1 FROM #tbx_TableClone_CopyMapStage WHERE OBJECT_ID(QUOTENAME(SourceSchema)+N'.'+QUOTENAME(SourceTable),N'U') IS NULL OR OBJECT_ID(QUOTENAME(TargetSchema)+N'.'+QUOTENAME(TargetTable),N'U') IS NULL)
        THROW 53941,N'TableClone Copy: tatsächliche SameDB-Tabellen fehlen oder Sicht fehlt.',1;
    INSERT #tbx_TableClone_CopyWork(MapOrdinal,SourceId,TargetId,SourceName,TargetName)
      SELECT MapOrdinal,OBJECT_ID(QUOTENAME(SourceSchema)+N'.'+QUOTENAME(SourceTable),N'U'),OBJECT_ID(QUOTENAME(TargetSchema)+N'.'+QUOTENAME(TargetTable),N'U'),
          QUOTENAME(SourceSchema)+N'.'+QUOTENAME(SourceTable),QUOTENAME(TargetSchema)+N'.'+QUOTENAME(TargetTable) FROM #tbx_TableClone_CopyMapStage;
    IF EXISTS(SELECT 1 FROM #tbx_TableClone_CopyWork GROUP BY SourceId HAVING COUNT_BIG(*)>1)
       OR EXISTS(SELECT 1 FROM #tbx_TableClone_CopyWork GROUP BY TargetId HAVING COUNT_BIG(*)>1)
       OR EXISTS(SELECT 1 FROM #tbx_TableClone_CopyWork s JOIN #tbx_TableClone_CopyWork t ON s.SourceId=t.TargetId)
        THROW 53940,N'TableClone Copy: Map-ObjectIDs sind nicht eindeutig/disjunkt.',7;
    CREATE TABLE #tbx_TableClone_CopyShape(ObjectId int NOT NULL,Position int NOT NULL,NameBytes varbinary(256) NOT NULL,TypeId tinyint NOT NULL,UserTypeId int NOT NULL,Length smallint NOT NULL,
        Precision tinyint NOT NULL,Scale tinyint NOT NULL,Nullable bit NOT NULL,CollationBytes varbinary(256) NULL,IdentityFlag bit NOT NULL,ComputedFlag bit NOT NULL,
        DefinitionBytes varbinary(max) NULL,Persisted bit NULL,SeedBytes varbinary(max) NULL,IncrementBytes varbinary(max) NULL,AnsiPadded bit NOT NULL,IdentityNotForReplication bit NULL,XmlCollectionId int NOT NULL,XmlDocument bit NOT NULL,PRIMARY KEY(ObjectId,Position));
    CREATE TABLE #tbx_TableClone_CopyColumns(MapOrdinal int NOT NULL,Position int NOT NULL,Name sysname COLLATE DATABASE_DEFAULT NOT NULL,Transport bit NOT NULL,IdentityFlag bit NOT NULL,PRIMARY KEY(MapOrdinal,Position));
    CREATE TABLE #Toolbelt_TableClone_CopyFkStage(Ordinal int NOT NULL,ObjectKind varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,TargetName nvarchar(776) COLLATE Latin1_General_100_BIN2 NOT NULL,ScriptText nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL);
    CREATE TABLE #tbx_TableClone_CopyResult(MappedTables int NOT NULL,CopiedRows bigint NOT NULL,PayloadBytes bigint NOT NULL,CreatedForeignKeys int NOT NULL,Status varchar(16) NOT NULL);
    -- DB-/DML-Gates gelten immer; vollständige DDL-Gates nur bei tatsächlich fehlenden FKs.
    DECLARE @NeedsFkDdl bit=0;
    DECLARE @SafetySql nvarchar(max)=N'IF COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N''DATABASE'',N''VIEW DEFINITION''),0)<>1
 OR COALESCE(HAS_PERMS_BY_NAME(N''sys.sql_expression_dependencies'',N''OBJECT'',N''SELECT''),0)<>1
 OR COALESCE(HAS_PERMS_BY_NAME(N''sys.security_predicates'',N''OBJECT'',N''SELECT''),0)<>1
 OR COALESCE(HAS_PERMS_BY_NAME(N''sys.security_policies'',N''OBJECT'',N''SELECT''),0)<>1
 THROW 53941,N''TableClone Copy: vollständige vorhandene Metadatensicht fehlt.'',4;
IF @NeedsFkDdl=1
BEGIN
IF COALESCE(HAS_PERMS_BY_NAME(NULL,NULL,N''VIEW ANY DEFINITION''),0)<>1
 THROW 53941,N''TableClone Copy: vollständige vorhandene Server-DDL-Sicht fehlt.'',4;
DECLARE @Visible bigint;
SELECT @Visible=COUNT_BIG(*) FROM sys.triggers;
SELECT @Visible=COUNT_BIG(*) FROM sys.trigger_events;
SELECT @Visible=COUNT_BIG(*) FROM sys.events;
SELECT @Visible=COUNT_BIG(*) FROM sys.event_notifications;
SELECT @Visible=COUNT_BIG(*) FROM sys.server_triggers;
SELECT @Visible=COUNT_BIG(*) FROM sys.server_trigger_events;
SELECT @Visible=COUNT_BIG(*) FROM sys.server_events;
SELECT @Visible=COUNT_BIG(*) FROM sys.server_event_notifications;
IF EXISTS(SELECT 1 FROM sys.triggers t WHERE t.parent_class=0 AND t.is_disabled=0 AND
 (NOT EXISTS(SELECT 1 FROM sys.trigger_events e WHERE e.object_id=t.object_id)
 OR EXISTS(SELECT 1 FROM sys.trigger_events e WHERE e.object_id=t.object_id AND (e.type IS NULL OR e.type_desc IS NULL OR e.type_desc COLLATE DATABASE_DEFAULT=N''ALTER_TABLE''))))
 OR EXISTS(SELECT 1 FROM sys.server_triggers t WHERE t.is_disabled=0 AND
 (NOT EXISTS(SELECT 1 FROM sys.server_trigger_events e WHERE e.object_id=t.object_id)
 OR EXISTS(SELECT 1 FROM sys.server_trigger_events e WHERE e.object_id=t.object_id AND (e.type IS NULL OR e.type_desc IS NULL OR e.type_desc COLLATE DATABASE_DEFAULT=N''ALTER_TABLE''))))
 OR EXISTS(SELECT 1 FROM sys.event_notifications n WHERE n.parent_class=0 AND
 (NOT EXISTS(SELECT 1 FROM sys.events e WHERE e.object_id=n.object_id AND e.is_trigger_event=0)
 OR EXISTS(SELECT 1 FROM sys.events e WHERE e.object_id=n.object_id AND e.is_trigger_event=0 AND (e.type IS NULL OR e.type_desc IS NULL OR e.type_desc COLLATE DATABASE_DEFAULT=N''ALTER_TABLE''))))
 OR EXISTS(SELECT 1 FROM sys.server_event_notifications n WHERE
 NOT EXISTS(SELECT 1 FROM sys.server_events e WHERE e.object_id=n.object_id)
 OR EXISTS(SELECT 1 FROM sys.server_events e WHERE e.object_id=n.object_id AND (e.type IS NULL OR e.type_desc IS NULL OR e.type_desc COLLATE DATABASE_DEFAULT=N''ALTER_TABLE'')))
 THROW 53942,N''TableClone Copy: relevante oder unbekannte DDL-Seiteneffekte.'',1;
END;
IF EXISTS(SELECT 1 FROM #tbx_TableClone_CopyWork m WHERE
 COALESCE(HAS_PERMS_BY_NAME(m.SourceName,N''OBJECT'',N''SELECT''),0)<>1
 OR COALESCE(HAS_PERMS_BY_NAME(m.TargetName,N''OBJECT'',N''SELECT''),0)<>1
 OR COALESCE(HAS_PERMS_BY_NAME(m.TargetName,N''OBJECT'',N''INSERT''),0)<>1
 OR OBJECT_ID(m.SourceName,N''U'') IS NULL OR OBJECT_ID(m.SourceName,N''U'')<>m.SourceId
 OR OBJECT_ID(m.TargetName,N''U'') IS NULL OR OBJECT_ID(m.TargetName,N''U'')<>m.TargetId)
 THROW 53941,N''TableClone Copy: Sicht/Rechte/gebundene ObjectIDs fehlen oder driften.'',5;
IF EXISTS(SELECT 1 FROM sys.tables t WHERE t.object_id IN(SELECT SourceId FROM #tbx_TableClone_CopyWork UNION SELECT TargetId FROM #tbx_TableClone_CopyWork)
 AND (t.is_memory_optimized=1 OR t.temporal_type<>0 OR t.is_filetable=1 OR t.is_node=1 OR t.is_edge=1 OR t.is_external=1 OR t.is_ms_shipped=1 OR t.is_replicated=1 OR t.is_merge_published=1 OR t.is_tracked_by_cdc=1))
 OR EXISTS(SELECT 1 FROM sys.columns c JOIN sys.types u ON u.user_type_id=c.user_type_id
 WHERE c.object_id IN(SELECT SourceId FROM #tbx_TableClone_CopyWork UNION SELECT TargetId FROM #tbx_TableClone_CopyWork)
 AND (c.is_hidden=1 OR c.generated_always_type<>0 OR c.encryption_type IS NOT NULL OR c.is_filestream=1 OR u.is_assembly_type=1
 OR c.is_sparse=1 OR c.is_column_set=1 OR c.is_masked=1 OR c.is_rowguidcol=1 OR c.rule_object_id<>0 OR u.is_user_defined=1
 OR (c.default_object_id<>0 AND NOT EXISTS(SELECT 1 FROM sys.default_constraints dc
 WHERE dc.object_id=c.default_object_id AND dc.parent_object_id=c.object_id AND dc.parent_column_id=c.column_id))
 OR c.system_type_id NOT IN(34,35,36,40,41,42,43,48,52,56,58,59,60,61,62,98,99,104,106,108,122,127,165,167,173,175,189,231,239,241)))
 THROW 53941,N''TableClone Copy: nicht unterstützte Tabellen-/Spaltenform.'',6;
-- Ledger-Spalten werden erst im inneren Batch gebunden; SQL Server 2019 besitzt sie nicht.
IF COL_LENGTH(N''sys.tables'',N''ledger_type'') IS NOT NULL
 EXEC sys.sp_executesql N''IF EXISTS(SELECT 1 FROM sys.tables t
 WHERE t.object_id IN(SELECT SourceId FROM #tbx_TableClone_CopyWork UNION SELECT TargetId FROM #tbx_TableClone_CopyWork)
 AND t.ledger_type<>0) THROW 53941,N''''TableClone Copy: Ledger gehört nicht zur normalen Tabellenform.'''',6;'';
-- Vorhandene DB-Vollsicht und explizite Katalogleserechte wurden vor diesen Abfragen geprüft.
DECLARE @RlsVisible bigint;
SELECT @RlsVisible=COUNT_BIG(*) FROM sys.security_predicates;
SELECT @RlsVisible=COUNT_BIG(*) FROM sys.security_policies;
IF EXISTS(SELECT 1 FROM sys.security_predicates p
 WHERE p.target_object_id IN(SELECT SourceId FROM #tbx_TableClone_CopyWork UNION SELECT TargetId FROM #tbx_TableClone_CopyWork))
 THROW 53942,N''TableClone Copy: RLS gehört nicht zum normalen Kopierpfad.'',4;
IF EXISTS(SELECT 1 FROM sys.triggers t JOIN #tbx_TableClone_CopyWork m ON m.TargetId=t.parent_id WHERE t.is_disabled=0)
 THROW 53942,N''TableClone Copy: aktiver Targettrigger.'',2;
IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d
 JOIN #tbx_TableClone_CopyWork m ON m.TargetId=d.referencing_id
 JOIN sys.computed_columns c ON c.object_id=d.referencing_id AND c.column_id=d.referencing_minor_id
 WHERE d.referenced_class<>1 OR d.referenced_server_name IS NOT NULL OR d.referenced_database_name IS NOT NULL
 OR d.is_ambiguous=1 OR d.is_caller_dependent=1 OR d.referenced_id IS NULL OR d.referenced_id<>c.object_id)
 OR EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d JOIN sys.objects expression ON expression.object_id=d.referencing_id AND expression.type IN(''D'',''C'')
 JOIN #tbx_TableClone_CopyWork m ON m.TargetId=expression.parent_object_id
 WHERE d.referenced_class<>1 OR d.referenced_server_name IS NOT NULL OR d.referenced_database_name IS NOT NULL
 OR d.is_ambiguous=1 OR d.is_caller_dependent=1 OR d.referenced_id IS NULL OR d.referenced_id<>expression.parent_object_id)
 THROW 53942,N''TableClone Copy: DEFAULT/CHECK/Computed-Pfad nicht tabellenlokal.'',3;
IF EXISTS(SELECT 1 FROM #tbx_TableClone_CopyWork m WHERE NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id=m.SourceId)
 OR (SELECT COUNT(*) FROM sys.columns WHERE object_id=m.SourceId)>1024)
 THROW 53941,N''TableClone Copy: fehlende Columnsicht oder Columnbudget.'',7;
IF EXISTS(SELECT 1 FROM #tbx_TableClone_CopyShape) AND (EXISTS(SELECT c.object_id,CONVERT(int,ROW_NUMBER() OVER(PARTITION BY c.object_id ORDER BY c.column_id)),CONVERT(varbinary(256),c.name),c.system_type_id,c.user_type_id,c.max_length,c.precision,c.scale,c.is_nullable,
 CONVERT(varbinary(256),c.collation_name),c.is_identity,c.is_computed,CONVERT(varbinary(max),cc.definition),cc.is_persisted,
 CONVERT(varbinary(max),ic.seed_value),CONVERT(varbinary(max),ic.increment_value),c.is_ansi_padded,ic.is_not_for_replication,c.xml_collection_id,c.is_xml_document
FROM sys.columns c LEFT JOIN sys.computed_columns cc ON cc.object_id=c.object_id AND cc.column_id=c.column_id
 LEFT JOIN sys.identity_columns ic ON ic.object_id=c.object_id AND ic.column_id=c.column_id
WHERE c.object_id IN(SELECT SourceId FROM #tbx_TableClone_CopyWork UNION SELECT TargetId FROM #tbx_TableClone_CopyWork) EXCEPT SELECT ObjectId,Position,NameBytes,TypeId,UserTypeId,Length,Precision,Scale,Nullable,CollationBytes,IdentityFlag,ComputedFlag,DefinitionBytes,Persisted,SeedBytes,IncrementBytes,AnsiPadded,IdentityNotForReplication,XmlCollectionId,XmlDocument FROM #tbx_TableClone_CopyShape) OR EXISTS(SELECT ObjectId,Position,NameBytes,TypeId,UserTypeId,Length,Precision,Scale,Nullable,CollationBytes,IdentityFlag,ComputedFlag,DefinitionBytes,Persisted,SeedBytes,IncrementBytes,AnsiPadded,IdentityNotForReplication,XmlCollectionId,XmlDocument FROM #tbx_TableClone_CopyShape EXCEPT SELECT c.object_id,CONVERT(int,ROW_NUMBER() OVER(PARTITION BY c.object_id ORDER BY c.column_id)),CONVERT(varbinary(256),c.name),c.system_type_id,c.user_type_id,c.max_length,c.precision,c.scale,c.is_nullable,
 CONVERT(varbinary(256),c.collation_name),c.is_identity,c.is_computed,CONVERT(varbinary(max),cc.definition),cc.is_persisted,
 CONVERT(varbinary(max),ic.seed_value),CONVERT(varbinary(max),ic.increment_value),c.is_ansi_padded,ic.is_not_for_replication,c.xml_collection_id,c.is_xml_document
FROM sys.columns c LEFT JOIN sys.computed_columns cc ON cc.object_id=c.object_id AND cc.column_id=c.column_id
 LEFT JOIN sys.identity_columns ic ON ic.object_id=c.object_id AND ic.column_id=c.column_id
WHERE c.object_id IN(SELECT SourceId FROM #tbx_TableClone_CopyWork UNION SELECT TargetId FROM #tbx_TableClone_CopyWork))) THROW 53944,N''TableClone Copy: gebundene Columnform driftet.'',7;';
    EXEC sys.sp_executesql @SafetySql,N'@NeedsFkDdl bit',@NeedsFkDdl;
    IF @ConsistencyMode='SNAPSHOT' AND NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=DB_ID() AND snapshot_isolation_state=1)
        THROW 53941,N'TableClone Copy: vorhandenes SNAPSHOT nicht aktiv.',2;
    IF @ConsistencyMode='SNAPSHOT' SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
    ELSE SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    SET XACT_ABORT ON;
    DECLARE @Own bit=0,@Lock int,@Id int,@Role bit,@Name nvarchar(776),@Ordinal int,@Source nvarchar(776),@Target nvarchar(776),
        @Rows bigint,@Bytes bigint,@TotalRows bigint=0,@TotalBytes bigint=0,@CopiedRows bigint=0,@Inserted bigint,@Columns nvarchar(max),@BytesExpr nvarchar(max),@Identity bit,@CreatedFks int=0;
    BEGIN TRY
        BEGIN TRANSACTION;SET @Own=1;
        EXEC @Lock=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.metadata.table-clone',@LockMode=N'Shared',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
        IF COALESCE(@Lock,-999)<0 THROW 53946,N'TableClone Copy: Lifecycle-Lock nicht verfügbar.',1;
        -- Gemeinsame Reihenfolge aller Rollen verhindert wechselnde Source-/Target-Lockreihenfolgen.
        DECLARE CopyLocks CURSOR LOCAL FAST_FORWARD FOR
          SELECT SourceId,CONVERT(bit,0),SourceName FROM #tbx_TableClone_CopyWork UNION ALL SELECT TargetId,CONVERT(bit,1),TargetName FROM #tbx_TableClone_CopyWork ORDER BY 1;
        OPEN CopyLocks;FETCH NEXT FROM CopyLocks INTO @Id,@Role,@Name;
        WHILE @@FETCH_STATUS=0
        BEGIN
            IF @Role=1
            BEGIN
                SET @Sql=N'SELECT @n=COUNT_BIG(*) FROM '+@Name+N' WITH(TABLOCKX,UPDLOCK,HOLDLOCK);';
                EXEC sys.sp_executesql @Sql,N'@n bigint OUTPUT',@Rows OUTPUT;
                IF @Rows<>0 THROW 53944,N'TableClone Copy: Target nicht leer.',1;
            END
            ELSE IF @ConsistencyMode='SERIALIZABLE'
            BEGIN
                SET @Sql=N'SELECT @n=COUNT_BIG(*) FROM '+@Name+N' WITH(TABLOCK,HOLDLOCK);';
                EXEC sys.sp_executesql @Sql,N'@n bigint OUTPUT',@Rows OUTPUT;
            END;
            FETCH NEXT FROM CopyLocks INTO @Id,@Role,@Name;
        END;
        CLOSE CopyLocks;DEALLOCATE CopyLocks;
        EXEC sys.sp_executesql @SafetySql,N'@NeedsFkDdl bit',@NeedsFkDdl;
        INSERT #tbx_TableClone_CopyShape
          SELECT c.object_id,ROW_NUMBER() OVER(PARTITION BY c.object_id ORDER BY c.column_id),CONVERT(varbinary(256),c.name),c.system_type_id,c.user_type_id,c.max_length,c.precision,c.scale,c.is_nullable,
            CONVERT(varbinary(256),c.collation_name),c.is_identity,c.is_computed,CONVERT(varbinary(max),cc.definition),cc.is_persisted,
            CONVERT(varbinary(max),ic.seed_value),CONVERT(varbinary(max),ic.increment_value),c.is_ansi_padded,ic.is_not_for_replication,c.xml_collection_id,c.is_xml_document
          FROM sys.columns c LEFT JOIN sys.computed_columns cc ON cc.object_id=c.object_id AND cc.column_id=c.column_id
          LEFT JOIN sys.identity_columns ic ON ic.object_id=c.object_id AND ic.column_id=c.column_id
          WHERE c.object_id IN(SELECT SourceId FROM #tbx_TableClone_CopyWork UNION SELECT TargetId FROM #tbx_TableClone_CopyWork);
        IF EXISTS(SELECT 1 FROM #tbx_TableClone_CopyWork m WHERE
          EXISTS(SELECT Position,NameBytes,TypeId,UserTypeId,Length,Precision,Scale,Nullable,CollationBytes,IdentityFlag,ComputedFlag,DefinitionBytes,Persisted,SeedBytes,IncrementBytes,AnsiPadded,IdentityNotForReplication,XmlCollectionId,XmlDocument FROM #tbx_TableClone_CopyShape WHERE ObjectId=m.SourceId
            EXCEPT SELECT Position,NameBytes,TypeId,UserTypeId,Length,Precision,Scale,Nullable,CollationBytes,IdentityFlag,ComputedFlag,DefinitionBytes,Persisted,SeedBytes,IncrementBytes,AnsiPadded,IdentityNotForReplication,XmlCollectionId,XmlDocument FROM #tbx_TableClone_CopyShape WHERE ObjectId=m.TargetId)
          OR EXISTS(SELECT Position,NameBytes,TypeId,UserTypeId,Length,Precision,Scale,Nullable,CollationBytes,IdentityFlag,ComputedFlag,DefinitionBytes,Persisted,SeedBytes,IncrementBytes,AnsiPadded,IdentityNotForReplication,XmlCollectionId,XmlDocument FROM #tbx_TableClone_CopyShape WHERE ObjectId=m.TargetId
            EXCEPT SELECT Position,NameBytes,TypeId,UserTypeId,Length,Precision,Scale,Nullable,CollationBytes,IdentityFlag,ComputedFlag,DefinitionBytes,Persisted,SeedBytes,IncrementBytes,AnsiPadded,IdentityNotForReplication,XmlCollectionId,XmlDocument FROM #tbx_TableClone_CopyShape WHERE ObjectId=m.SourceId))
          THROW 53941,N'TableClone Copy: geordnete Columnform stimmt nicht.',3;
        INSERT #tbx_TableClone_CopyColumns
          SELECT m.MapOrdinal,ROW_NUMBER() OVER(PARTITION BY m.MapOrdinal ORDER BY c.column_id),c.name,
            CASE WHEN c.is_computed=1 OR c.system_type_id=189 OR (@IdentityMode='REGENERATE' AND c.is_identity=1) THEN 0 ELSE 1 END,c.is_identity
          FROM #tbx_TableClone_CopyWork m JOIN sys.columns c ON c.object_id=m.SourceId;
        IF @IdentityMode='KEEP' AND EXISTS(SELECT 1 FROM #tbx_TableClone_CopyWork m JOIN #tbx_TableClone_CopyColumns c ON c.MapOrdinal=m.MapOrdinal AND c.IdentityFlag=1
          WHERE COALESCE(HAS_PERMS_BY_NAME(m.TargetName,N'OBJECT',N'ALTER'),0)<>1)
          THROW 53941,N'TableClone Copy: vorhandenes Identity-ALTER-Recht fehlt.',9;
        -- Der künftige gemeinsame Core validiert Source-FK-Tupel und Existing-Target-FKs einmalig.
        EXEC toolbelt_metadata.USP_ScriptTableCloneInternal @IncludeIdentity=0,@IncludeExtendedProperties=0,@IncludeTriggers=0,
          @TableMap=N'#tbx_TableClone_CopyMapStage',@ExternalReferenceRule='REJECT',@InternalPurpose='COPY_FK',@ResultTable=N'#Toolbelt_TableClone_CopyFkStage',@KeepData=0;
        IF EXISTS(SELECT 1 FROM #Toolbelt_TableClone_CopyFkStage WHERE ObjectKind NOT IN('FOREIGN_KEY','FOREIGN_KEY_STATE') OR ScriptText IS NULL OR DATALENGTH(ScriptText)=0)
          THROW 53944,N'TableClone Copy: unerwartete kanonische FK-Planform.',2;
        SELECT @NeedsFkDdl=CONVERT(bit,CASE WHEN EXISTS(SELECT 1 FROM #Toolbelt_TableClone_CopyFkStage WHERE ObjectKind='FOREIGN_KEY') THEN 1 ELSE 0 END);
        EXEC sys.sp_executesql @SafetySql,N'@NeedsFkDdl bit',@NeedsFkDdl;
        IF @IdentityMode='REGENERATE' AND EXISTS(SELECT 1 FROM sys.foreign_key_columns f
          JOIN #tbx_TableClone_CopyWork p ON p.SourceId=f.parent_object_id JOIN #tbx_TableClone_CopyWork r ON r.SourceId=f.referenced_object_id
          JOIN sys.columns c ON (c.object_id=f.parent_object_id AND c.column_id=f.parent_column_id) OR (c.object_id=f.referenced_object_id AND c.column_id=f.referenced_column_id)
          WHERE c.is_identity=1)
          THROW 53944,N'TableClone Copy: REGENERATE bei identityabhängiger Beziehung.',3;
        DECLARE CopyAdmission CURSOR LOCAL FAST_FORWARD FOR SELECT MapOrdinal,SourceName FROM #tbx_TableClone_CopyWork ORDER BY MapOrdinal;
        OPEN CopyAdmission;FETCH NEXT FROM CopyAdmission INTO @Ordinal,@Source;
        WHILE @@FETCH_STATUS=0
        BEGIN
            SET @Sql=N'SELECT @n=COUNT_BIG(*) FROM '+@Source+N';';
            EXEC sys.sp_executesql @Sql,N'@n bigint OUTPUT',@Rows OUTPUT;
            IF @Rows IS NULL OR @Rows>@RowLimit-@TotalRows THROW 53943,N'TableClone Copy: globales Rowbudget überschritten.',1;
            SET @TotalRows+=@Rows;UPDATE #tbx_TableClone_CopyWork SET Rows=@Rows WHERE MapOrdinal=@Ordinal;
            FETCH NEXT FROM CopyAdmission INTO @Ordinal,@Source;
        END;
        CLOSE CopyAdmission;
        OPEN CopyAdmission;FETCH NEXT FROM CopyAdmission INTO @Ordinal,@Source;
        WHILE @@FETCH_STATUS=0
        BEGIN
            SELECT @BytesExpr=STRING_AGG(CONVERT(nvarchar(max),N'COALESCE(CONVERT(bigint,DATALENGTH('+QUOTENAME(Name)+N')),CONVERT(bigint,0))'),N'+') WITHIN GROUP(ORDER BY Position)
              FROM #tbx_TableClone_CopyColumns WHERE MapOrdinal=@Ordinal AND Transport=1;
            IF @BytesExpr IS NULL SET @Bytes=0;
            ELSE
            BEGIN
                SET @Sql=N'SELECT @b=COALESCE(SUM('+@BytesExpr+N'),CONVERT(bigint,0)) FROM '+@Source+N';';
                EXEC sys.sp_executesql @Sql,N'@b bigint OUTPUT',@Bytes OUTPUT;
            END;
            IF @Bytes IS NULL OR @Bytes>@PayloadByteLimit-@TotalBytes THROW 53943,N'TableClone Copy: globales Nutzdatenbudget überschritten.',2;
            SET @TotalBytes+=@Bytes;UPDATE #tbx_TableClone_CopyWork SET Bytes=@Bytes WHERE MapOrdinal=@Ordinal;
            FETCH NEXT FROM CopyAdmission INTO @Ordinal,@Source;
        END;
        CLOSE CopyAdmission;DEALLOCATE CopyAdmission;
        EXEC sys.sp_executesql @SafetySql,N'@NeedsFkDdl bit',@NeedsFkDdl;
        WHILE EXISTS(SELECT 1 FROM #tbx_TableClone_CopyWork WHERE Copied=0)
        BEGIN
            SET @Ordinal=NULL;
            SELECT TOP(1) @Ordinal=m.MapOrdinal,@Source=m.SourceName,@Target=m.TargetName,@Rows=m.Rows FROM #tbx_TableClone_CopyWork m WHERE m.Copied=0
              AND NOT EXISTS(SELECT 1 FROM sys.foreign_keys f JOIN #tbx_TableClone_CopyWork parent ON parent.TargetId=f.referenced_object_id
                WHERE f.parent_object_id=m.TargetId AND f.is_disabled=0 AND f.referenced_object_id<>f.parent_object_id AND parent.Copied=0)
              ORDER BY m.TargetId;
            IF @Ordinal IS NULL THROW 53944,N'TableClone Copy: bestehender aktiver Target-FK-Zyklus.',4;
            SELECT @Columns=STRING_AGG(CONVERT(nvarchar(max),QUOTENAME(Name)),N',') WITHIN GROUP(ORDER BY Position),@Identity=CONVERT(bit,MAX(CONVERT(int,IdentityFlag)))
              FROM #tbx_TableClone_CopyColumns WHERE MapOrdinal=@Ordinal AND Transport=1;
            IF @Columns IS NULL
              SET @Sql=N'DECLARE @i bigint=0;WHILE @i<@n BEGIN INSERT '+@Target+N' DEFAULT VALUES;SET @i+=1;END;SET @done=@i;';
            ELSE SET @Sql=CASE WHEN @Identity=1 THEN N'SET IDENTITY_INSERT '+@Target+N' ON;'+NCHAR(10) ELSE N'' END
              +N'INSERT '+@Target+N' ('+@Columns+N') SELECT '+@Columns+N' FROM '+@Source+N';SET @done=ROWCOUNT_BIG();'
              +CASE WHEN @Identity=1 THEN N'SET IDENTITY_INSERT '+@Target+N' OFF;SET @IdentityOwned=0;' ELSE N'' END;
            IF @Identity=1
              SET @Sql=N'DECLARE @IdentityOwned bit=0;BEGIN TRY '+REPLACE(@Sql,N' ON;'+NCHAR(10),N' ON;SET @IdentityOwned=1;'+NCHAR(10))
                +N' END TRY BEGIN CATCH BEGIN TRY IF @IdentityOwned=1 SET IDENTITY_INSERT '+@Target+N' OFF; END TRY BEGIN CATCH RAISERROR(N''TBX_TABLE_CLONE_COPY_SECONDARY_IDENTITY_OFF'',10,1) WITH NOWAIT;END CATCH;THROW;END CATCH;';
            -- ON/INSERT/OFF bleiben in genau einem dynamischen Batch innerhalb des eigenen USP-Scopes.
            EXEC sys.sp_executesql @Sql,N'@n bigint,@done bigint OUTPUT',@Rows,@Inserted OUTPUT;
            IF @Inserted IS NULL OR @Inserted<>@Rows THROW 53944,N'TableClone Copy: Insertcount stimmt nicht.',5;
            SET @CopiedRows+=@Inserted;UPDATE #tbx_TableClone_CopyWork SET Copied=1 WHERE MapOrdinal=@Ordinal;
        END;
        EXEC sys.sp_executesql @SafetySql,N'@NeedsFkDdl bit',@NeedsFkDdl;
        IF EXISTS(SELECT 1 FROM #Toolbelt_TableClone_CopyFkStage p JOIN #tbx_TableClone_CopyWork m ON p.TargetName=m.TargetName COLLATE Latin1_General_100_BIN2
          WHERE COALESCE(HAS_PERMS_BY_NAME(m.TargetName,N'OBJECT',N'ALTER'),0)<>1)
          OR EXISTS(SELECT 1 FROM sys.foreign_keys f JOIN #tbx_TableClone_CopyWork m ON m.SourceId=f.referenced_object_id
            JOIN #tbx_TableClone_CopyWork ownerMap ON ownerMap.SourceId=f.parent_object_id
            JOIN #Toolbelt_TableClone_CopyFkStage planRow ON planRow.ObjectKind='FOREIGN_KEY' AND planRow.TargetName=ownerMap.TargetName COLLATE Latin1_General_100_BIN2
            WHERE COALESCE(HAS_PERMS_BY_NAME(m.TargetName,N'OBJECT',N'REFERENCES'),0)<>1)
          THROW 53941,N'TableClone Copy: vorhandene FK-DDL-/REFERENCES-Rechte fehlen.',8;
        -- Core wird vor DDL erneut unter derselben TX geprüft; der fertige Plan muss gleich bleiben.
        DECLARE @ExpectedFkHash varbinary(32),@CurrentFkHash varbinary(32);
        SELECT @ExpectedFkHash=HASHBYTES('SHA2_256',CONVERT(varbinary(max),STRING_AGG(CONVERT(nvarchar(max),CONCAT(Ordinal,N':',ObjectKind,N':',DATALENGTH(TargetName),N':',TargetName,N':',DATALENGTH(ScriptText),N':',ScriptText)),N';') WITHIN GROUP(ORDER BY Ordinal))) FROM #Toolbelt_TableClone_CopyFkStage;
        EXEC toolbelt_metadata.USP_ScriptTableCloneInternal @IncludeIdentity=0,@IncludeExtendedProperties=0,@IncludeTriggers=0,
          @TableMap=N'#tbx_TableClone_CopyMapStage',@ExternalReferenceRule='REJECT',@InternalPurpose='COPY_FK',@ResultTable=N'#Toolbelt_TableClone_CopyFkStage',@KeepData=0;
        SELECT @CurrentFkHash=HASHBYTES('SHA2_256',CONVERT(varbinary(max),STRING_AGG(CONVERT(nvarchar(max),CONCAT(Ordinal,N':',ObjectKind,N':',DATALENGTH(TargetName),N':',TargetName,N':',DATALENGTH(ScriptText),N':',ScriptText)),N';') WITHIN GROUP(ORDER BY Ordinal))) FROM #Toolbelt_TableClone_CopyFkStage;
        IF (@ExpectedFkHash IS NULL AND @CurrentFkHash IS NOT NULL) OR (@ExpectedFkHash IS NOT NULL AND @CurrentFkHash IS NULL) OR @ExpectedFkHash<>@CurrentFkHash
          THROW 53944,N'TableClone Copy: kanonischer FK-Plan driftet.',6;
        -- Nach dem zweiten Corecall unmittelbar vor eigener FK-DDL erneut prüfen.
        EXEC sys.sp_executesql @SafetySql,N'@NeedsFkDdl bit',@NeedsFkDdl;
        DECLARE @Kind varchar(32),@Script nvarchar(max),@SetPrefix nvarchar(max)=N'SET ANSI_NULLS ON;SET ANSI_PADDING ON;SET ANSI_WARNINGS ON;SET ARITHABORT ON;SET CONCAT_NULL_YIELDS_NULL ON;SET QUOTED_IDENTIFIER ON;SET NUMERIC_ROUNDABORT OFF;'+NCHAR(10);
        DECLARE CopyFks CURSOR LOCAL FAST_FORWARD FOR SELECT ObjectKind,ScriptText FROM #Toolbelt_TableClone_CopyFkStage ORDER BY Ordinal;
        OPEN CopyFks;FETCH NEXT FROM CopyFks INTO @Kind,@Script;
        WHILE @@FETCH_STATUS=0
        BEGIN
            SET @Script=@SetPrefix+@Script;EXEC sys.sp_executesql @Script;
            IF @Kind='FOREIGN_KEY' SET @CreatedFks+=1;
            FETCH NEXT FROM CopyFks INTO @Kind,@Script;
        END;
        CLOSE CopyFks;DEALLOCATE CopyFks;
        INSERT #tbx_TableClone_CopyResult VALUES((SELECT COUNT(*) FROM #tbx_TableClone_CopyWork),@CopiedRows,@TotalBytes,@CreatedFks,'COPIED');
        IF @ResultTable IS NOT NULL
        BEGIN
            EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_TableClone_CopyResult',@KeepData=@KeepData,@Debug=@Debug;
            SET @Sql=N'INSERT '+QUOTENAME(@ResultTable)+N' (MappedTables,CopiedRows,PayloadBytes,CreatedForeignKeys,Status) SELECT MappedTables,CopiedRows,PayloadBytes,CreatedForeignKeys,Status FROM #tbx_TableClone_CopyResult;';
            EXEC sys.sp_executesql @Sql;
        END;
        COMMIT TRANSACTION;SET @Own=0;
    END TRY
    BEGIN CATCH
        BEGIN TRY
            IF @Own=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        END TRY
        BEGIN CATCH
            RAISERROR(N'TBX_TABLE_CLONE_COPY_SECONDARY_ROLLBACK',10,1) WITH NOWAIT;
        END CATCH;
        THROW;
    END CATCH;
    IF @ResultTable IS NULL SELECT MappedTables,CopiedRows,PayloadBytes,CreatedForeignKeys,Status FROM #tbx_TableClone_CopyResult;
END;
GO
