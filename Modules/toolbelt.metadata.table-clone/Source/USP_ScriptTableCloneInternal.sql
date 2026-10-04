-- Kanonischer Catalog-/Scriptkern; keine Ausführung des erzeugten Scripttexts.
-- Interner Aufruf ausschließlich über öffentliche Namespace-/Helpgrenze.
-- Definitionen bleiben wörtlich; nur das explizite Trigger-Opt-in verwendet Parser 2.0.
CREATE OR ALTER PROCEDURE toolbelt_metadata.USP_ScriptTableCloneInternal
    @SourceSchema nvarchar(max)=NULL,@SourceTable nvarchar(max)=NULL,
    @TargetSchema nvarchar(max)=NULL,@TargetTable nvarchar(max)=NULL,
    @IncludeIdentity bit=0,@IncludeExtendedProperties bit=0,@TableMap sysname=NULL,@ExternalReferenceRule varchar(16)='REJECT',@IncludeTriggers bit=0,@InternalPurpose varchar(16)='PREVIEW',@ResultTable sysname=NULL,@KeepData bit=0,
    @Debug tinyint=0,@Hilfe bit=0
AS
BEGIN
    SET NOCOUNT ON;
    IF @Hilfe=1
    BEGIN
        -- Eigene vierzehn Parameter: die öffentliche Vorschau hat keinen internen Zweckparameter.
        DECLARE @Help TABLE(Section varchar(32) NOT NULL,Ordinal int NOT NULL,ItemName sysname NULL,
            SqlDataType varchar(256) NULL,IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,
            Description nvarchar(max) NOT NULL,ExampleSql nvarchar(max) NULL);
        INSERT @Help VALUES
        ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Kanonischer Metadaten-/Plan-Kern: PREVIEW plant neue Ziele; COPY_FK plant ausschließlich fehlende FKs/Zustände für bestehende formgleiche Copyziele. Keine Ausführung des Scripttexts.',NULL),
        ('PARAMETER',1,N'@SourceSchema','nvarchar(max)',1,0,N'NULL',N'Explizites Quellschema im Einzelmodus; im Mapmodus NULL.',NULL),
        ('PARAMETER',2,N'@SourceTable','nvarchar(max)',1,0,N'NULL',N'Sichtbare reguläre Quelltabelle im Einzelmodus; im Mapmodus NULL.',NULL),
        ('PARAMETER',3,N'@TargetSchema','nvarchar(max)',1,0,N'NULL',N'Bestehendes Zielschema derselben Installationsdatenbank; im Mapmodus NULL.',NULL),
        ('PARAMETER',4,N'@TargetTable','nvarchar(max)',1,0,N'NULL',N'Neuer Zielname bei PREVIEW; COPY_FK erfordert Mapmodus mit bestehenden Zielen.',NULL),
        ('PARAMETER',5,N'@IncludeIdentity','bit',0,0,N'0',N'PREVIEW übernimmt bei1 Seed/Increment; COPY_FK rendert keine Tabellen.',NULL),
        ('PARAMETER',6,N'@IncludeExtendedProperties','bit',0,0,N'0',N'PREVIEW übernimmt unterstützte Properties typgetreu; COPY_FK verlangt0.',NULL),
        ('PARAMETER',7,N'@TableMap','sysname',0,1,N'NULL',N'Caller-lokale Map mit fünf NOT NULL-Feldern und höchstens64 eindeutigen positiven Ordinals; COPY_FK verlangt die eigene Copybrücke.',NULL),
        ('PARAMETER',8,N'@ExternalReferenceRule','varchar(16)',0,0,N'REJECT',N'Byteexakt REJECT oder im PREVIEW-Mapmodus KEEP; COPY_FK verlangt REJECT.',NULL),
        ('PARAMETER',9,N'@IncludeTriggers','bit',0,0,N'0',N'PREVIEW-Opt-in für gewöhnliche gemappte Windows-DML-Trigger über exakt vorhandenen Parser2.0; COPY_FK verlangt0.',NULL),
        ('PARAMETER',10,N'@InternalPurpose','varchar(16)',0,0,N'PREVIEW',N'Byteexakt PREVIEW oder COPY_FK. COPY_FK nur aus Copy mit gesunder Callertransaktion, Map und ResultTable, ohne Trigger/Properties.',NULL),
        ('PARAMETER',11,N'@ResultTable','sysname',0,1,N'NULL',N'NULL liefert SELECT; sonst bestehende caller-lokale Temp-Tabelle. COPY_FK verlangt die eigene Copy-FK-Brücke.',NULL),
        ('PARAMETER',12,N'@KeepData','bit',0,1,N'0',N'Kanonisch0 Replace oder1 Append; NULL entspricht0.',NULL),
        ('PARAMETER',13,N'@Debug','tinyint',0,1,N'0',N'Nur Messages; keine zusätzliche fachliche Ausgabe.',NULL),
        ('PARAMETER',14,N'@Hilfe','bit',0,1,N'0',N'1 liefert nur Hilfe und umgeht alle fachlichen Prüfungen/Seiteneffekte.',NULL),
        ('RESULT_COLUMN',1,N'Ordinal','int',1,0,NULL,N'Lückenloser1-basierter Planordinal.',NULL),
        ('RESULT_COLUMN',2,N'ObjectKind','varchar(32)',1,0,NULL,N'PREVIEW: kanonische Planarten inklusive Trigger-Opt-in; COPY_FK ausschließlich FOREIGN_KEY und FOREIGN_KEY_STATE.',NULL),
        ('RESULT_COLUMN',3,N'TargetName','nvarchar(776)',1,0,NULL,N'Gequoteter Zielname, Latin1_General_100_BIN2.',NULL),
        ('RESULT_COLUMN',4,N'ScriptText','nvarchar(max)',1,0,NULL,N'Vollständig gebundener Scripttext, Latin1_General_100_BIN2; keine Ausführung im Core.',NULL),
        ('ERROR',1,NULL,NULL,NULL,NULL,NULL,N'53900 Argumente/Zweck,53901 Sicht,53902 Ziele,53903 Unsupported/FK-Abweichung,53904 Kollision,53905 Definitionen,53906 Budgets,53907 Dependency; Enginefehler unverändert.',NULL),
        ('PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'Vorhandene datenbankweite VIEW DEFINITION und erforderliche Katalog-/Helperrechte; Trigger-Opt-in zusätzlich vollständige exakt gepinnte Parserbindung. Keine Rechtevergabe.',NULL),
        ('LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'Interner Zweck ist kein zusätzlicher öffentlicher Planner-Modus. COPY_FK rendert gemeinsame FK-Logik; Copy prüft DML-Form/Admission separat. Map64, global2048 und2MiB Scriptbudget.',NULL),
        ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Seiteneffektfreier interner Hilfeaufruf.',N'EXEC toolbelt_metadata.USP_ScriptTableCloneInternal @Hilfe=1;');
        SELECT CONVERT(varchar(16),'1.0') HelpContractVersion,CONVERT(sysname,N'toolbelt_metadata') SchemaName,
            CONVERT(sysname,N'USP_ScriptTableCloneInternal') ObjectName,Section,Ordinal,ItemName,SqlDataType,
            IsRequired,IsNullable,DefaultValue,Description,ExampleSql FROM @Help
        ORDER BY CASE Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1 WHEN 'RESULT_COLUMN' THEN 2
            WHEN 'ERROR' THEN 3 WHEN 'PERMISSION' THEN 4 WHEN 'LIMITATION' THEN 5 ELSE 6 END,Ordinal;
        RETURN;
    END;
    SELECT @KeepData=COALESCE(@KeepData,0),@Debug=COALESCE(@Debug,0);
    IF @IncludeTriggers IS NULL THROW 53900,N'TableClone: IncludeTriggers darf nicht NULL sein.',10;
    IF @InternalPurpose IS NULL OR CONVERT(varbinary(max),@InternalPurpose) NOT IN(CONVERT(varbinary(max),'PREVIEW'),CONVERT(varbinary(max),'COPY_FK'))
        THROW 53900,N'TableClone: interner Zweck muss exakt PREVIEW oder COPY_FK sein.',11;
    DECLARE @CopyFk bit=CASE WHEN CONVERT(varbinary(max),@InternalPurpose)=CONVERT(varbinary(max),'COPY_FK') THEN 1 ELSE 0 END;
    IF @CopyFk=1 AND (@TableMap IS NULL OR @ResultTable IS NULL OR @IncludeTriggers<>0 OR @IncludeExtendedProperties<>0
        OR @IncludeTriggers IS NULL OR @IncludeExtendedProperties IS NULL OR @@TRANCOUNT=0 OR XACT_STATE()<>1
        OR @ExternalReferenceRule IS NULL OR CONVERT(varbinary(max),@ExternalReferenceRule)<>CONVERT(varbinary(max),'REJECT'))
        THROW 53900,N'TableClone: COPY_FK benötigt Map, Ausgabe, gesunde Callertransaktion und REJECT ohne Trigger/Properties.',12;
    -- Vollständige incoming-FK- und Kollisionssicht darf nicht aus gefilterten Katalogen behauptet werden.
    IF COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1
        THROW 53901,N'TableClone: datenbankweite VIEW DEFINITION für vollständige Struktursicht erforderlich.',2;

    IF @ExternalReferenceRule IS NULL OR CONVERT(varbinary(max),@ExternalReferenceRule) NOT IN(CONVERT(varbinary(max),'REJECT'),CONVERT(varbinary(max),'KEEP'))
       OR (@TableMap IS NULL AND CONVERT(varbinary(max),@ExternalReferenceRule)<>CONVERT(varbinary(max),'REJECT'))
        THROW 53900,N'TableClone: ExternalReferenceRule muss exakt REJECT oder im Mapmodus KEEP sein.',3;
    CREATE TABLE #tbx_TableClone_Map(MapOrdinal int NOT NULL PRIMARY KEY,
        SourceSchema nvarchar(128) COLLATE DATABASE_DEFAULT NOT NULL,SourceTable nvarchar(128) COLLATE DATABASE_DEFAULT NOT NULL,
        TargetSchema nvarchar(128) COLLATE DATABASE_DEFAULT NOT NULL,TargetTable nvarchar(128) COLLATE DATABASE_DEFAULT NOT NULL,
        SourceId int NULL,TargetSchemaId int NULL,TargetId int NULL);
    IF @TableMap IS NULL
    BEGIN
        IF @IncludeIdentity IS NULL OR @IncludeExtendedProperties IS NULL OR EXISTS
            (SELECT 1 FROM (VALUES(@SourceSchema),(@SourceTable),(@TargetSchema),(@TargetTable)) a(n)
             WHERE n IS NULL OR DATALENGTH(n)=0 OR DATALENGTH(n)>256)
            THROW 53900,N'TableClone: explizite Identifier mit 1-128 Codeeinheiten ohne NUL und IncludeIdentity erforderlich.',1;
        INSERT #tbx_TableClone_Map VALUES(1,@SourceSchema,@SourceTable,@TargetSchema,@TargetTable,NULL,NULL,NULL);
    END
    ELSE
    BEGIN
        IF @SourceSchema IS NOT NULL OR @SourceTable IS NOT NULL OR @TargetSchema IS NOT NULL OR @TargetTable IS NOT NULL
           OR @IncludeIdentity IS NULL OR @IncludeExtendedProperties IS NULL
            THROW 53900,N'TableClone: Mapmodus verlangt NULL für die vier einzelnen Identifier.',4;
        IF LEFT(@TableMap,1)<>N'#' OR LEFT(@TableMap,2)=N'##' OR LEN(@TableMap)<2
           OR SUBSTRING(@TableMap,2,128) COLLATE Latin1_General_100_BIN2 LIKE N'%[^A-Za-z0-9_]%'
            THROW 53900,N'TableClone: TableMap muss eine caller-lokale Temp-Tabelle sein.',5;
        DECLARE @MapId int=OBJECT_ID(N'tempdb..'+@TableMap,N'U'),@ResultId int=OBJECT_ID(N'tempdb..'+@ResultTable,N'U');
        IF @MapId IS NULL OR @MapId=@ResultId THROW 53900,N'TableClone: Map fehlt oder ist das Ausgabeobjekt.',6;
        IF (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=@MapId)<>5
           OR EXISTS(SELECT 1 FROM tempdb.sys.columns WHERE object_id=@MapId AND
              (is_nullable<>0 OR is_computed<>0 OR user_type_id<>system_type_id OR
               NOT ((CONVERT(varbinary(256),name)=CONVERT(varbinary(256),N'MapOrdinal') AND system_type_id=56 AND max_length=4)
                 OR (CONVERT(varbinary(256),name) IN(CONVERT(varbinary(256),N'SourceSchema'),CONVERT(varbinary(256),N'SourceTable'),CONVERT(varbinary(256),N'TargetSchema'),CONVERT(varbinary(256),N'TargetTable')) AND system_type_id=231 AND max_length=-1))))
            THROW 53900,N'TableClone: Map verlangt exakt fünf NOT-NULL-Spalten ohne Alias-/Computedtypen.',7;
        DECLARE @MapSql nvarchar(max)=N'IF NOT EXISTS(SELECT 1 FROM '+QUOTENAME(@TableMap)+N') OR (SELECT COUNT_BIG(*) FROM '+QUOTENAME(@TableMap)+N')>64
          OR EXISTS(SELECT 1 FROM '+QUOTENAME(@TableMap)+N' WHERE MapOrdinal<=0 OR DATALENGTH(SourceSchema) NOT BETWEEN 2 AND 256 OR DATALENGTH(SourceTable) NOT BETWEEN 2 AND 256 OR DATALENGTH(TargetSchema) NOT BETWEEN 2 AND 256 OR DATALENGTH(TargetTable) NOT BETWEEN 2 AND 256)
          OR EXISTS(SELECT 1 FROM '+QUOTENAME(@TableMap)+N' GROUP BY MapOrdinal HAVING COUNT_BIG(*)<>1)
          THROW 53900,N''TableClone: Mapzeilen, Identifier oder Ordinals ungültig.'',8;
          INSERT #tbx_TableClone_Map SELECT MapOrdinal,SourceSchema,SourceTable,TargetSchema,TargetTable,NULL,NULL,NULL FROM '+QUOTENAME(@TableMap)+N';';
        EXEC sys.sp_executesql @MapSql;
    END;
    DECLARE @MapOrdinal int,@SourceName nvarchar(776),@TargetName nvarchar(776),@SourceId int,@TargetSchemaId int;
    DECLARE ValidationCursor CURSOR LOCAL FAST_FORWARD FOR SELECT MapOrdinal,SourceSchema,SourceTable,TargetSchema,TargetTable FROM #tbx_TableClone_Map ORDER BY MapOrdinal;
    OPEN ValidationCursor;
    FETCH NEXT FROM ValidationCursor INTO @MapOrdinal,@SourceSchema,@SourceTable,@TargetSchema,@TargetTable;
    WHILE @@FETCH_STATUS=0
    BEGIN
        SET @Hilfe=0;
    IF @IncludeIdentity IS NULL OR @IncludeExtendedProperties IS NULL OR EXISTS
        (SELECT 1 FROM (VALUES(@SourceSchema),(@SourceTable),(@TargetSchema),(@TargetTable)) args(Name)
         WHERE Name IS NULL OR DATALENGTH(Name)=0 OR DATALENGTH(Name)>256
            OR DATALENGTH(Name)=2 AND UNICODE(Name)=0)
        THROW 53900,N'TableClone: explizite Identifier mit 1-128 Codeeinheiten ohne NUL und IncludeIdentity erforderlich.',1;
    ;WITH Digits(n) AS (SELECT n FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) d(n)),
    Units(n) AS (SELECT 1+a.n+10*b.n+100*c.n FROM Digits a CROSS JOIN Digits b CROSS JOIN Digits c)
    SELECT @Hilfe=1 FROM (VALUES(@SourceSchema),(@SourceTable),(@TargetSchema),(@TargetTable)) args(Name)
    CROSS JOIN Units WHERE n<=DATALENGTH(Name)/2 AND UNICODE(SUBSTRING(Name COLLATE Latin1_General_100_BIN2,n,1))=0;
    IF @Hilfe=1 THROW 53900,N'TableClone: Identifier enthält NUL.',2;
    SELECT @SourceName=QUOTENAME(@SourceSchema)+N'.'+QUOTENAME(@SourceTable),
        @TargetName=QUOTENAME(@TargetSchema)+N'.'+QUOTENAME(@TargetTable),
        @SourceId=NULL,@TargetSchemaId=SCHEMA_ID(@TargetSchema);
    SELECT @SourceId=t.object_id FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id
        WHERE s.name=@SourceSchema COLLATE DATABASE_DEFAULT AND t.name=@SourceTable COLLATE DATABASE_DEFAULT;
    IF @SourceId IS NULL OR HAS_PERMS_BY_NAME(@SourceName,N'OBJECT',N'VIEW DEFINITION')<>1
        THROW 53901,N'TableClone: Quelle fehlt, ist keine Tabelle oder vollständige Metadatensicht fehlt.',1;
    IF @TargetSchemaId IS NULL OR HAS_PERMS_BY_NAME(QUOTENAME(@TargetSchema),N'SCHEMA',N'VIEW DEFINITION')<>1
        THROW 53902,N'TableClone: Zielschema fehlt oder vollständige Kollisionssicht fehlt.',1;
    IF @CopyFk=0 AND EXISTS(SELECT 1 FROM sys.objects WHERE schema_id=@TargetSchemaId AND name=@TargetTable COLLATE DATABASE_DEFAULT)
        THROW 53902,N'TableClone: Zielname existiert bereits.',2;
    IF @CopyFk=1 AND (NOT EXISTS(SELECT 1 FROM sys.tables WHERE schema_id=@TargetSchemaId AND name=@TargetTable COLLATE DATABASE_DEFAULT)
        OR COALESCE(HAS_PERMS_BY_NAME(@TargetName,N'OBJECT',N'VIEW DEFINITION'),0)<>1)
        THROW 53902,N'TableClone: COPY_FK verlangt vorhandene vollständig sichtbare Zieltabellen.',3;
    IF @CopyFk=0
    BEGIN
    -- Zusatzrecht nur für Computed; ohne Nachweis keine Dependencyklassifikation.
    IF EXISTS(SELECT 1 FROM sys.computed_columns WHERE object_id=@SourceId)
       AND COALESCE(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1
        THROW 53901,N'TableClone: Computed-Dependency-Metadatensicht fehlt.',3;
    IF EXISTS(SELECT 1 FROM sys.computed_columns WHERE object_id=@SourceId)
    BEGIN
    IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d
        JOIN sys.computed_columns c ON c.object_id=d.referencing_id AND c.column_id=d.referencing_minor_id
        WHERE c.object_id=@SourceId AND (d.referenced_class<>1 OR d.referenced_server_name IS NOT NULL
          OR d.referenced_database_name IS NOT NULL OR d.is_ambiguous=1 OR d.is_caller_dependent=1
          OR d.referenced_id IS NULL OR d.referenced_id<>@SourceId))
        THROW 53903,N'TableClone: nicht tabellenlokale Computed-Dependency.',9;
    END;
    -- Versionierte Ledger-Metadaten dürfen SQL2019 nicht beim Kompilieren referenzieren.
    DECLARE @Ledger bit=0;
    IF COL_LENGTH(N'sys.tables',N'ledger_type') IS NOT NULL
        EXEC sys.sp_executesql N'SELECT @b=CASE WHEN ledger_type<>0 THEN 1 ELSE 0 END FROM sys.tables WHERE object_id=@id;',
            N'@id int,@b bit OUTPUT',@SourceId,@Ledger OUTPUT;
    IF @Ledger=1 OR EXISTS(SELECT 1 FROM sys.tables WHERE object_id=@SourceId
        AND (is_ms_shipped=1 OR is_memory_optimized=1 OR is_filetable=1 OR temporal_type<>0
            OR is_node=1 OR is_edge=1 OR is_replicated=1 OR is_merge_published=1 OR is_tracked_by_cdc=1
            OR large_value_types_out_of_row=1 OR text_in_row_limit<>0))
        THROW 53903,N'TableClone: Unsupported table feature (system, memory, FileTable, temporal, graph, ledger, replication or CDC).',1;
    IF EXISTS(SELECT 1 FROM sys.external_tables WHERE object_id=@SourceId)
        THROW 53903,N'TableClone: Unsupported external table.',2;
    IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id=@SourceId
        AND (is_sparse=1 OR is_column_set=1 OR is_rowguidcol=1 OR is_filestream=1
            OR generated_always_type<>0 OR is_hidden=1 OR encryption_type IS NOT NULL OR is_masked=1
            OR xml_collection_id<>0 OR rule_object_id<>0))
        THROW 53903,N'TableClone: Unsupported column feature (sparse/rowguid/FILESTREAM/generated/encrypted/masked/typedXML/rule).',3;
    IF (@IncludeTriggers=0 AND EXISTS(SELECT 1 FROM sys.triggers WHERE parent_id=@SourceId))
       OR (@TableMap IS NULL AND EXISTS(SELECT 1 FROM sys.foreign_keys WHERE parent_object_id=@SourceId OR referenced_object_id=@SourceId))
       OR (@IncludeExtendedProperties=0 AND EXISTS(SELECT 1 FROM sys.extended_properties WHERE
           (class=1 AND (major_id=@SourceId OR major_id IN(SELECT object_id FROM sys.objects WHERE parent_object_id=@SourceId)))
           OR (class=7 AND major_id=@SourceId)))
        THROW 53903,N'TableClone: Unsupported FK, trigger or Extended Property.',4;
    IF EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=@SourceId
        AND (type NOT IN(0,1,2) OR (has_filter=1 AND (type<>2 OR is_primary_key=1 OR is_unique_constraint=1)) OR is_disabled=1 OR is_hypothetical=1 OR optimize_for_sequential_key=1
            OR data_space_id IN(SELECT data_space_id FROM sys.data_spaces WHERE type<>'FG')))
       OR EXISTS(SELECT 1 FROM sys.partitions WHERE object_id=@SourceId AND (partition_number<>1 OR data_compression<>0))
       OR EXISTS(SELECT 1 FROM sys.fulltext_indexes WHERE object_id=@SourceId)
        THROW 53903,N'TableClone: Unsupported index, partition, compression or fulltext feature.',5;
    IF EXISTS(SELECT 1 FROM sys.check_constraints WHERE parent_object_id=@SourceId
        AND (is_disabled=1 OR is_not_trusted=1 OR is_not_for_replication=1))
       OR EXISTS(SELECT 1 FROM sys.identity_columns WHERE object_id=@SourceId AND is_not_for_replication=1)
        THROW 53903,N'TableClone: Unsupported disabled/untrusted/replication constraint.',6;
    IF EXISTS(SELECT 1 FROM sys.columns c JOIN sys.types t ON c.user_type_id=t.user_type_id
        WHERE c.object_id=@SourceId AND (t.is_assembly_type=1
        OR t.name NOT IN(N'tinyint',N'smallint',N'int',N'bigint',N'bit',N'decimal',N'numeric',N'money',N'smallmoney',
            N'float',N'real',N'date',N'time',N'datetime',N'smalldatetime',N'datetime2',N'datetimeoffset',
            N'char',N'nchar',N'varchar',N'nvarchar',N'binary',N'varbinary',N'uniqueidentifier',N'xml',N'timestamp',N'rowversion',N'sql_variant')
        OR t.is_user_defined=1 OR (c.default_object_id<>0 AND NOT EXISTS
            (SELECT 1 FROM sys.default_constraints d WHERE d.object_id=c.default_object_id))))
        THROW 53903,N'TableClone: Unsupported CLR/alias/legacy type or bound default.',7;
    IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id=@SourceId
        AND system_type_id IN(165,167,173,175) AND is_ansi_padded=0)
        THROW 53903,N'TableClone: Unsupported legacy ANSI_PADDING OFF column.',8;
    IF @IncludeExtendedProperties=1
    BEGIN
        -- Unsupported vor Definitions-/Namensfehlern; noch keine Wertkopien oder Textkonvertierung.
        IF EXISTS(SELECT 1 FROM sys.extended_properties e WHERE
            ((e.class=1 AND (e.major_id=@SourceId OR e.major_id IN(SELECT object_id FROM sys.objects WHERE parent_object_id=@SourceId))) OR(e.class=7 AND e.major_id=@SourceId))
            AND (TRANSLATE(LEFT(e.name,9) COLLATE Latin1_General_100_BIN2,N'TOBEL',N'tobel') COLLATE Latin1_General_100_BIN2=N'toolbelt.' OR
              (e.value IS NOT NULL AND (SQL_VARIANT_PROPERTY(e.value,'BaseType') IS NULL OR SQL_VARIANT_PROPERTY(e.value,'BaseType') NOT IN
               (N'bit',N'tinyint',N'smallint',N'int',N'bigint',N'decimal',N'numeric',N'money',N'smallmoney',N'float',N'real',N'date',N'time',N'datetime',N'smalldatetime',N'datetime2',N'datetimeoffset',N'char',N'varchar',N'nchar',N'nvarchar',N'binary',N'varbinary',N'uniqueidentifier') OR DATALENGTH(e.value)>7500 OR TRY_CONVERT(int,SQL_VARIANT_PROPERTY(e.value,'TotalBytes')) IS NULL OR TRY_CONVERT(int,SQL_VARIANT_PROPERTY(e.value,'TotalBytes'))<DATALENGTH(e.value) OR TRY_CONVERT(int,SQL_VARIANT_PROPERTY(e.value,'TotalBytes'))>8016))))
            THROW 53903,N'TableClone: Ownershipproperty oder nicht unterstützter Propertywert.',11;
        IF EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id IN(SELECT object_id FROM sys.objects WHERE parent_object_id=@SourceId)
            AND (e.minor_id<>0 OR NOT EXISTS(SELECT 1 FROM sys.objects o WHERE o.object_id=e.major_id AND o.type IN('D','C','PK','UQ'))))
            OR EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=7 AND e.major_id=@SourceId AND NOT EXISTS(SELECT 1 FROM sys.indexes i WHERE i.object_id=@SourceId AND i.index_id=e.minor_id AND i.type IN(1,2)))
            THROW 53903,N'TableClone: nicht unterstützter Propertyowner.',10;
    END;
    IF EXISTS(SELECT 1 FROM sys.default_constraints WHERE parent_object_id=@SourceId AND definition IS NULL)
       OR EXISTS(SELECT 1 FROM sys.check_constraints WHERE parent_object_id=@SourceId AND definition IS NULL)
       OR EXISTS(SELECT 1 FROM sys.computed_columns WHERE object_id=@SourceId AND definition IS NULL)
       OR EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=@SourceId AND has_filter=1 AND filter_definition IS NULL)
        THROW 53905,N'TableClone: nicht sichtbare Definition.',1;
    IF (SELECT SUM(CONVERT(bigint,DATALENGTH(definition))) FROM
         (SELECT definition FROM sys.default_constraints WHERE parent_object_id=@SourceId
          UNION ALL SELECT definition FROM sys.check_constraints WHERE parent_object_id=@SourceId
          UNION ALL SELECT definition FROM sys.computed_columns WHERE object_id=@SourceId
          UNION ALL SELECT filter_definition FROM sys.indexes WHERE object_id=@SourceId AND has_filter=1) definitions)>2097152
       OR (SELECT COUNT(*) FROM sys.columns WHERE object_id=@SourceId)>1024
       OR (SELECT COUNT(*) FROM sys.indexes WHERE object_id=@SourceId)>128
       OR (SELECT COUNT(*) FROM sys.objects WHERE parent_object_id=@SourceId)>2048       -- Die feste DECLARE/EXEC-Syntax hat bereits mehr als100 UTF16-Einheiten.
       -- 200Bytes pro EP ist deshalb nur ein beweisbarer unterer Outputwert, kein neuer Countcap.
       OR (@IncludeExtendedProperties=1 AND (SELECT COUNT_BIG(*)*200 FROM sys.extended_properties e WHERE
           (e.class=1 AND (e.major_id=@SourceId OR e.major_id IN(SELECT object_id FROM sys.objects WHERE parent_object_id=@SourceId)))
           OR (e.class=7 AND e.major_id=@SourceId))>2097152)
        THROW 53906,N'TableClone: Metadaten-Ressourcengrenze überschritten.',1;


    END;
        UPDATE #tbx_TableClone_Map SET SourceId=@SourceId,TargetSchemaId=@TargetSchemaId,
            TargetId=CASE WHEN @CopyFk=1 THEN OBJECT_ID(@TargetName,N'U') ELSE NULL END WHERE MapOrdinal=@MapOrdinal;
        FETCH NEXT FROM ValidationCursor INTO @MapOrdinal,@SourceSchema,@SourceTable,@TargetSchema,@TargetTable;
    END;
    CLOSE ValidationCursor; DEALLOCATE ValidationCursor;
    IF EXISTS(SELECT 1 FROM #tbx_TableClone_Map GROUP BY SourceId HAVING COUNT_BIG(*)>1)
       OR EXISTS(SELECT 1 FROM #tbx_TableClone_Map GROUP BY TargetSchemaId,TargetTable HAVING COUNT_BIG(*)>1)
        THROW 53900,N'TableClone: doppelte Quelle oder kataloggleiches Ziel in Map.',9;
    IF @CopyFk=1 AND (EXISTS(SELECT 1 FROM #tbx_TableClone_Map WHERE TargetId IS NULL)
        OR EXISTS(SELECT 1 FROM #tbx_TableClone_Map GROUP BY TargetId HAVING COUNT_BIG(*)<>1)
        OR EXISTS(SELECT 1 FROM #tbx_TableClone_Map s JOIN #tbx_TableClone_Map t ON t.TargetId=s.SourceId))
        THROW 53900,N'TableClone: COPY_FK verlangt eindeutige disjunkte Quell-/Zielobjekte.',13;
    -- Globale Countquote: jedes Childobjekt genau einmal plus jedes FK-Spaltentupel genau einmal.
    IF (SELECT COUNT_BIG(*) FROM sys.objects o JOIN #tbx_TableClone_Map m ON m.SourceId=o.parent_object_id)
       +(SELECT COUNT_BIG(*) FROM sys.foreign_key_columns c JOIN #tbx_TableClone_Map m ON m.SourceId=c.parent_object_id)>2048
        THROW 53906,N'TableClone: globale Objekt-/FK-Spaltentupelquote überschritten.',1;
    IF @CopyFk=0
    BEGIN
    DECLARE @MinimumPlanBytes bigint=COALESCE((SELECT SUM(CONVERT(bigint,DATALENGTH(definition))) FROM
        (SELECT d.definition FROM sys.default_constraints d JOIN #tbx_TableClone_Map m ON m.SourceId=d.parent_object_id
         UNION ALL SELECT d.definition FROM sys.check_constraints d JOIN #tbx_TableClone_Map m ON m.SourceId=d.parent_object_id
         UNION ALL SELECT d.definition FROM sys.computed_columns d JOIN #tbx_TableClone_Map m ON m.SourceId=d.object_id
         UNION ALL SELECT d.filter_definition FROM sys.indexes d JOIN #tbx_TableClone_Map m ON m.SourceId=d.object_id WHERE d.has_filter=1) definitions),0);
    IF @IncludeExtendedProperties=1
        SET @MinimumPlanBytes+=(SELECT COUNT_BIG(*)*200 FROM sys.extended_properties e WHERE
            (e.class=1 AND (e.major_id IN(SELECT SourceId FROM #tbx_TableClone_Map) OR e.major_id IN(SELECT o.object_id FROM sys.objects o JOIN #tbx_TableClone_Map m ON m.SourceId=o.parent_object_id)))
            OR (e.class=7 AND e.major_id IN(SELECT SourceId FROM #tbx_TableClone_Map)));
    SET @MinimumPlanBytes+=(SELECT COUNT_BIG(*)*2 FROM sys.foreign_keys f JOIN #tbx_TableClone_Map m ON m.SourceId=f.parent_object_id);
    IF @IncludeTriggers=1
        SET @MinimumPlanBytes+=COALESCE((SELECT SUM(CONVERT(bigint,DATALENGTH(s.definition))) FROM sys.triggers t
            JOIN #tbx_TableClone_Map m ON m.SourceId=t.parent_id LEFT JOIN sys.sql_modules s ON s.object_id=t.object_id),0);
    IF @MinimumPlanBytes>2097152 THROW 53906,N'TableClone: globale minimale Scriptbytes überschritten.',1;
    END;
    IF @TableMap IS NOT NULL
    BEGIN
        IF EXISTS(SELECT 1 FROM sys.foreign_keys f JOIN #tbx_TableClone_Map m ON m.SourceId=f.parent_object_id
           LEFT JOIN #tbx_TableClone_Map r ON r.SourceId=f.referenced_object_id WHERE r.SourceId IS NULL)
           AND @ExternalReferenceRule='REJECT'
            THROW 53903,N'TableClone: externe FK-Referenz bei REJECT.',13;
        IF EXISTS(SELECT 1 FROM sys.foreign_keys f JOIN #tbx_TableClone_Map m ON m.SourceId=f.parent_object_id
            WHERE (f.is_disabled=1 AND f.is_not_trusted=0) OR f.delete_referential_action NOT BETWEEN 0 AND 3 OR f.update_referential_action NOT BETWEEN 0 AND 3)
            THROW 53903,N'TableClone: nicht unterstützter FK-Zustand.',14;
        IF EXISTS(SELECT 1 FROM sys.foreign_keys f JOIN #tbx_TableClone_Map m ON m.SourceId=f.parent_object_id
            JOIN sys.extended_properties e ON e.class=1 AND e.major_id=f.object_id)
            THROW 53903,N'TableClone: Properties auf FK werden nicht unterstützt.',10;
        IF EXISTS(SELECT 1 FROM sys.foreign_keys f JOIN #tbx_TableClone_Map m ON m.SourceId=f.parent_object_id
            LEFT JOIN sys.tables t ON t.object_id=f.referenced_object_id
            LEFT JOIN sys.indexes i ON i.object_id=f.referenced_object_id AND i.index_id=f.key_index_id
            WHERE t.object_id IS NULL OR COALESCE(HAS_PERMS_BY_NAME(QUOTENAME(OBJECT_SCHEMA_NAME(t.object_id))+N'.'+QUOTENAME(t.name),N'OBJECT',N'VIEW DEFINITION'),0)<>1
             OR i.index_id IS NULL OR i.is_unique<>1 OR i.type NOT IN(1,2) OR i.is_disabled=1 OR i.is_hypothetical=1 OR i.has_filter=1
             OR NOT EXISTS(SELECT 1 FROM sys.foreign_key_columns c WHERE c.constraint_object_id=f.object_id)
             OR (SELECT MIN(c.constraint_column_id) FROM sys.foreign_key_columns c WHERE c.constraint_object_id=f.object_id)<>1
             OR (SELECT MAX(c.constraint_column_id) FROM sys.foreign_key_columns c WHERE c.constraint_object_id=f.object_id)<>(SELECT COUNT(*) FROM sys.foreign_key_columns c WHERE c.constraint_object_id=f.object_id)
             OR (SELECT COUNT(*) FROM sys.foreign_key_columns c WHERE c.constraint_object_id=f.object_id)<>(SELECT COUNT(*) FROM sys.index_columns c WHERE c.object_id=i.object_id AND c.index_id=i.index_id AND c.key_ordinal>0)
             OR EXISTS(SELECT 1 FROM sys.foreign_key_columns c LEFT JOIN sys.columns pc ON pc.object_id=c.parent_object_id AND pc.column_id=c.parent_column_id
                LEFT JOIN sys.columns rc ON rc.object_id=c.referenced_object_id AND rc.column_id=c.referenced_column_id
                WHERE c.constraint_object_id=f.object_id AND (pc.column_id IS NULL OR rc.column_id IS NULL OR NOT EXISTS(SELECT 1 FROM sys.index_columns k WHERE k.object_id=i.object_id AND k.index_id=i.index_id AND k.column_id=c.referenced_column_id AND k.key_ordinal>0))))
            THROW 53905,N'TableClone: unvollständige FK-/Referenzschlüsselmetadaten.',2;
    END;
    CREATE TABLE #tbx_TableClone_Plan(Ordinal int NOT NULL,ObjectKind varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,
        TargetName nvarchar(776) COLLATE Latin1_General_100_BIN2 NOT NULL,ScriptText nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL);
    CREATE TABLE #tbx_TableClone_Order(OriginalOrdinal int NOT NULL PRIMARY KEY,MapOrdinal int NOT NULL,Phase int NOT NULL);
    CREATE TABLE #tbx_TableClone_Names(SchemaId int NOT NULL,GeneratedName sysname COLLATE DATABASE_DEFAULT NOT NULL);
    CREATE TABLE #tbx_TableClone_EpOwners(MapOrdinal int NOT NULL,TargetSchema sysname NOT NULL,Class int NOT NULL,MajorId int NOT NULL,MinorId int NOT NULL,SortKind int NOT NULL,SourceOrdinal int NOT NULL,
        Level1Type nvarchar(16) NOT NULL,Level1Name sysname NOT NULL,Level2Type nvarchar(16) NULL,Level2Name sysname NULL,TargetName nvarchar(776) NOT NULL);
    IF @CopyFk=0
    BEGIN
    DECLARE @PlanStart int;
    DECLARE RenderCursor CURSOR LOCAL FAST_FORWARD FOR SELECT MapOrdinal,SourceSchema,SourceTable,TargetSchema,TargetTable,SourceId,TargetSchemaId FROM #tbx_TableClone_Map ORDER BY MapOrdinal;
    OPEN RenderCursor;
    FETCH NEXT FROM RenderCursor INTO @MapOrdinal,@SourceSchema,@SourceTable,@TargetSchema,@TargetTable,@SourceId,@TargetSchemaId;
    WHILE @@FETCH_STATUS=0
    BEGIN
        SET @TargetName=QUOTENAME(@TargetSchema)+N'.'+QUOTENAME(@TargetTable);
    DECLARE @ColumnDdl nvarchar(max),@TableDdl nvarchar(max),@Filegroup sysname,@LobFilegroup sysname;
    SELECT @ColumnDdl=NULL,@TableDdl=NULL,@Filegroup=NULL,@LobFilegroup=NULL;
    SELECT @ColumnDdl=STRING_AGG(CONVERT(nvarchar(max),N'    '+QUOTENAME(c.name)+CASE WHEN c.is_computed=1 THEN N' AS '+cc.definition
        +CASE WHEN cc.is_persisted=1 THEN N' PERSISTED'+CASE WHEN c.is_nullable=0 THEN N' NOT NULL' ELSE N'' END ELSE N'' END
        ELSE N' '+QUOTENAME(t.name)
        +CASE WHEN t.name IN(N'varchar',N'char',N'varbinary',N'binary',N'nvarchar',N'nchar')
            THEN N'('+CASE WHEN c.max_length=-1 THEN N'max' ELSE CONVERT(nvarchar(12),c.max_length/CASE WHEN t.name IN(N'nvarchar',N'nchar') THEN 2 ELSE 1 END) END+N')'
            WHEN t.name IN(N'decimal',N'numeric') THEN N'('+CONVERT(nvarchar(12),c.precision)+N','+CONVERT(nvarchar(12),c.scale)+N')'
            WHEN t.name IN(N'datetime2',N'datetimeoffset',N'time') THEN N'('+CONVERT(nvarchar(12),c.scale)+N')'
            WHEN t.name=N'float' THEN N'('+CONVERT(nvarchar(12),c.precision)+N')' ELSE N'' END
        -- COLLATE verlangt unquotierten Namen; Catalogwert stammt ausschließlich vom Engine-Collationkatalog.
        +CASE WHEN c.collation_name IS NULL THEN N'' ELSE N' COLLATE '+c.collation_name END
        +CASE WHEN @IncludeIdentity=1 AND ic.column_id IS NOT NULL THEN N' IDENTITY('
            +CONVERT(nvarchar(40),ic.seed_value)+N','+CONVERT(nvarchar(40),ic.increment_value)+N')' ELSE N'' END
        +CASE WHEN c.is_nullable=1 THEN N' NULL' ELSE N' NOT NULL' END END),N','+NCHAR(10)) WITHIN GROUP(ORDER BY c.column_id)
    FROM sys.columns c JOIN sys.types t ON t.user_type_id=c.user_type_id
    LEFT JOIN sys.computed_columns cc ON cc.object_id=c.object_id AND cc.column_id=c.column_id
    LEFT JOIN sys.identity_columns ic ON ic.object_id=c.object_id AND ic.column_id=c.column_id
    WHERE c.object_id=@SourceId;
    SELECT @Filegroup=d.name FROM sys.indexes i JOIN sys.data_spaces d ON d.data_space_id=i.data_space_id
        WHERE i.object_id=@SourceId AND i.index_id IN(0,1);
    SELECT @LobFilegroup=d.name FROM sys.tables t JOIN sys.data_spaces d ON t.lob_data_space_id=d.data_space_id WHERE t.object_id=@SourceId;
    SET @TableDdl=N'CREATE TABLE '+@TargetName+N' ('+NCHAR(10)+@ColumnDdl+NCHAR(10)+N')'
        +CASE WHEN @Filegroup IS NULL THEN N'' ELSE N' ON '+QUOTENAME(@Filegroup) END
        +CASE WHEN @LobFilegroup IS NULL THEN N'' ELSE N' TEXTIMAGE_ON '+QUOTENAME(@LobFilegroup) END+N';';
    IF @MapOrdinal=(SELECT MIN(MapOrdinal) FROM #tbx_TableClone_Map)
    INSERT #tbx_TableClone_Plan
    SELECT n,'SESSION_OPTION',@TargetName,Statement FROM (VALUES
       (1,N'SET ANSI_NULLS ON;'),(2,N'SET ANSI_PADDING ON;'),(3,N'SET ANSI_WARNINGS ON;'),
       (4,N'SET ARITHABORT ON;'),(5,N'SET CONCAT_NULL_YIELDS_NULL ON;'),
       (6,N'SET QUOTED_IDENTIFIER ON;'),(7,N'SET NUMERIC_ROUNDABORT OFF;')) options(n,Statement);
    SET @PlanStart=COALESCE((SELECT MAX(Ordinal) FROM #tbx_TableClone_Plan),0);
    INSERT #tbx_TableClone_Plan VALUES(@PlanStart+1,'TABLE',@TargetName,@TableDdl);
    DECLARE @Objects TABLE(SortKind int NOT NULL,SourceOrdinal int NOT NULL,ObjectKind varchar(32) NOT NULL,
        GeneratedName sysname NOT NULL,ScriptText nvarchar(max) NOT NULL,SourceObjectId int NULL,SourceIndexId int NULL);
    DELETE @Objects;
    -- Hash der length-framed Identifier: volle Namen fließen ein, kein Trunkieren/Casefold.
    DECLARE @NameContext nvarchar(max)=CONCAT(DATALENGTH(@TargetSchema),N':',@TargetSchema,N';',DATALENGTH(@TargetTable),N':',@TargetTable,N';');
    INSERT @Objects
    SELECT 1,d.parent_column_id,'DEFAULT',n.Name,
        N'ALTER TABLE '+@TargetName+N' ADD CONSTRAINT '+QUOTENAME(n.Name)+N' DEFAULT '+d.definition+N' FOR '+QUOTENAME(c.name)+N';',d.object_id,NULL
    FROM sys.default_constraints d JOIN sys.columns c ON c.object_id=d.parent_object_id AND c.column_id=d.parent_column_id
    CROSS APPLY(SELECT CONVERT(sysname,N'DF_'+CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@NameContext+N'DF;'+CONVERT(nvarchar(12),d.parent_column_id))),2)) Name) n
    WHERE d.parent_object_id=@SourceId;
    INSERT @Objects
    SELECT 2,ROW_NUMBER() OVER(ORDER BY CONVERT(varbinary(256),c.name)),'CHECK',n.Name,
        N'ALTER TABLE '+@TargetName+N' WITH CHECK ADD CONSTRAINT '+QUOTENAME(n.Name)+N' CHECK '+c.definition+N';',c.object_id,NULL
    FROM sys.check_constraints c
    CROSS APPLY(SELECT CONVERT(sysname,N'CK_'+CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@NameContext+N'CK;'+CONVERT(nvarchar(12),DATALENGTH(c.name))+N':'+c.name)),2)) Name) n
    WHERE c.parent_object_id=@SourceId;
    DECLARE @IndexId int,@IndexName sysname,@Type tinyint,@Unique bit,@Primary bit,@Constraint bit,
        @Keys nvarchar(max),@Includes nvarchar(max),@IndexDdl nvarchar(max),@Generated sysname,
        @Kind varchar(32),@Fill tinyint,@Pad bit,@Ignore bit,@RowLocks bit,@PageLocks bit,@NoRecompute bit,@Filter nvarchar(max),@ConstraintId int;
    -- Cursor ordnet bereits begrenzte Index-Metadaten; kein zeilenweiser Datenzugriff.
    DECLARE IndexCursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT i.index_id,i.name,i.type,i.is_unique,i.is_primary_key,i.is_unique_constraint,
            i.fill_factor,i.is_padded,i.ignore_dup_key,i.allow_row_locks,i.allow_page_locks,s.no_recompute,d.name,i.filter_definition,CASE WHEN i.is_primary_key=1 OR i.is_unique_constraint=1 THEN (SELECT object_id FROM sys.key_constraints WHERE parent_object_id=i.object_id AND unique_index_id=i.index_id) END
        FROM sys.indexes i JOIN sys.stats s ON s.object_id=i.object_id AND s.stats_id=i.index_id
        JOIN sys.data_spaces d ON d.data_space_id=i.data_space_id
        WHERE i.object_id=@SourceId AND i.index_id>0 ORDER BY CASE i.type WHEN 1 THEN 0 ELSE 1 END,i.index_id;
    OPEN IndexCursor;
    FETCH NEXT FROM IndexCursor INTO @IndexId,@IndexName,@Type,@Unique,@Primary,@Constraint,@Fill,@Pad,@Ignore,@RowLocks,@PageLocks,@NoRecompute,@Filegroup,@Filter,@ConstraintId;
    WHILE @@FETCH_STATUS=0
    BEGIN
        SELECT @Keys=STRING_AGG(CONVERT(nvarchar(max),QUOTENAME(c.name)+CASE ic.is_descending_key WHEN 1 THEN N' DESC' ELSE N' ASC' END),N',') WITHIN GROUP(ORDER BY ic.key_ordinal)
            FROM sys.index_columns ic JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
            WHERE ic.object_id=@SourceId AND ic.index_id=@IndexId AND ic.key_ordinal>0;
        SELECT @Includes=STRING_AGG(CONVERT(nvarchar(max),QUOTENAME(c.name)),N',') WITHIN GROUP(ORDER BY ic.index_column_id)
            FROM sys.index_columns ic JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
            WHERE ic.object_id=@SourceId AND ic.index_id=@IndexId AND ic.is_included_column=1;
        SELECT @Kind=CASE WHEN @Primary=1 THEN 'PRIMARY_KEY' WHEN @Constraint=1 THEN 'UNIQUE_CONSTRAINT' ELSE 'INDEX' END,
            @Generated=CONVERT(sysname,CASE WHEN @Primary=1 THEN N'PK_' WHEN @Constraint=1 THEN N'UQ_' ELSE N'IX_' END
              +CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@NameContext+N'IX;'+CONVERT(nvarchar(12),DATALENGTH(@IndexName))+N':'+@IndexName)),2));
        SET @IndexDdl=CASE WHEN @Primary=1 OR @Constraint=1 THEN N'ALTER TABLE '+@TargetName+N' ADD CONSTRAINT '+QUOTENAME(@Generated)+N' '
            +CASE @Primary WHEN 1 THEN N'PRIMARY KEY ' ELSE N'UNIQUE ' END
            ELSE N'CREATE '+CASE @Unique WHEN 1 THEN N'UNIQUE ' ELSE N'' END END
            +CASE @Type WHEN 1 THEN N'CLUSTERED ' ELSE N'NONCLUSTERED ' END
            +CASE WHEN @Primary=1 OR @Constraint=1 THEN N'' ELSE N'INDEX '+QUOTENAME(@Generated)+N' ON '+@TargetName+N' ' END
            +N'('+@Keys+N')'+CASE WHEN @Includes IS NULL THEN N'' ELSE N' INCLUDE ('+@Includes+N')' END
            -- Catalog0 entspricht100; DDL erlaubt explizit ausschließlich1-100.
            +CASE WHEN @Filter IS NULL THEN N'' ELSE N' WHERE '+@Filter END
            +N' WITH (FILLFACTOR='+CONVERT(nvarchar(3),CASE WHEN @Fill=0 THEN 100 ELSE @Fill END)+N',PAD_INDEX='+CASE @Pad WHEN 1 THEN N'ON' ELSE N'OFF' END
            +N',IGNORE_DUP_KEY='+CASE @Ignore WHEN 1 THEN N'ON' ELSE N'OFF' END
            +N',ALLOW_ROW_LOCKS='+CASE @RowLocks WHEN 1 THEN N'ON' ELSE N'OFF' END
            +N',ALLOW_PAGE_LOCKS='+CASE @PageLocks WHEN 1 THEN N'ON' ELSE N'OFF' END
            +N',STATISTICS_NORECOMPUTE='+CASE @NoRecompute WHEN 1 THEN N'ON' ELSE N'OFF' END+N') ON '+QUOTENAME(@Filegroup)+N';';
        INSERT @Objects VALUES(CASE @Type WHEN 1 THEN 3 ELSE 4 END,@IndexId,@Kind,@Generated,@IndexDdl,@ConstraintId,@IndexId);
        FETCH NEXT FROM IndexCursor INTO @IndexId,@IndexName,@Type,@Unique,@Primary,@Constraint,@Fill,@Pad,@Ignore,@RowLocks,@PageLocks,@NoRecompute,@Filegroup,@Filter,@ConstraintId;
    END;
    CLOSE IndexCursor; DEALLOCATE IndexCursor;
    IF EXISTS(SELECT 1 FROM @Objects GROUP BY GeneratedName COLLATE DATABASE_DEFAULT HAVING COUNT(*)>1)
       OR EXISTS(SELECT 1 FROM @Objects p JOIN sys.objects o ON o.schema_id=@TargetSchemaId
            AND o.name=p.GeneratedName COLLATE DATABASE_DEFAULT WHERE p.ObjectKind<>'INDEX')
        THROW 53904,N'TableClone: deterministischer Constraintname kollidiert.',1;
    INSERT #tbx_TableClone_Plan
        SELECT @PlanStart+1+ROW_NUMBER() OVER(ORDER BY SortKind,SourceOrdinal),ObjectKind,
            CASE WHEN ObjectKind='INDEX' THEN @TargetName+N'.'+QUOTENAME(GeneratedName)
                 ELSE QUOTENAME(@TargetSchema)+N'.'+QUOTENAME(GeneratedName) END,ScriptText FROM @Objects;
    INSERT #tbx_TableClone_Order(OriginalOrdinal,MapOrdinal,Phase)
        SELECT Ordinal,@MapOrdinal,CASE ObjectKind WHEN 'TABLE' THEN 1 ELSE 2 END
        FROM #tbx_TableClone_Plan WHERE Ordinal>@PlanStart;
    INSERT #tbx_TableClone_Names SELECT @TargetSchemaId,GeneratedName FROM @Objects WHERE ObjectKind<>'INDEX';
    IF @IncludeExtendedProperties=1
    BEGIN
        -- Ownerzuordnung verwendet dieselben erzeugten Namen wie der DDL-Plan.
        -- Explizite Nullability: Tabellenowner besitzen kein Level2, unabhängig von Caller-/DB-Defaults.
        DECLARE @Owners TABLE(Class int NOT NULL,MajorId int NOT NULL,MinorId int NOT NULL,SortKind int NOT NULL,SourceOrdinal int NOT NULL,
            Level1Type nvarchar(16) NOT NULL,Level1Name sysname NOT NULL,Level2Type nvarchar(16) NULL,Level2Name sysname NULL,TargetName nvarchar(776) NOT NULL);
        DELETE @Owners;
        INSERT @Owners VALUES(1,@SourceId,0,1,0,N'TABLE',CONVERT(sysname,@TargetTable),NULL,NULL,@TargetName);
        INSERT @Owners SELECT 1,@SourceId,column_id,2,column_id,N'TABLE',CONVERT(sysname,@TargetTable),N'COLUMN',name,
            @TargetName+N'.'+QUOTENAME(name) FROM sys.columns WHERE object_id=@SourceId;
        INSERT @Owners SELECT 1,SourceObjectId,0,CASE ObjectKind WHEN 'DEFAULT' THEN 3 WHEN 'CHECK' THEN 4 WHEN 'PRIMARY_KEY' THEN 5 ELSE 6 END,
            SourceOrdinal,N'TABLE',CONVERT(sysname,@TargetTable),N'CONSTRAINT',GeneratedName,
            QUOTENAME(@TargetSchema)+N'.'+QUOTENAME(GeneratedName) FROM @Objects WHERE SourceObjectId IS NOT NULL;
        INSERT @Owners SELECT 7,@SourceId,SourceIndexId,7,SourceOrdinal,N'TABLE',CONVERT(sysname,@TargetTable),N'INDEX',GeneratedName,
            @TargetName+N'.'+QUOTENAME(GeneratedName) FROM @Objects WHERE SourceIndexId IS NOT NULL;
        IF EXISTS(SELECT 1 FROM sys.extended_properties e WHERE
            ((e.class=1 AND (e.major_id=@SourceId OR e.major_id IN(SELECT object_id FROM sys.objects WHERE parent_object_id=@SourceId)))
                OR (e.class=7 AND e.major_id=@SourceId))
            AND NOT EXISTS(SELECT 1 FROM @Owners o WHERE o.Class=e.class AND o.MajorId=e.major_id AND o.MinorId=e.minor_id))
            THROW 53903,N'TableClone: nicht unterstützter Propertyowner.',10;
        IF EXISTS(SELECT 1 FROM @Owners o JOIN sys.extended_properties e ON e.class=o.Class AND e.major_id=o.MajorId AND e.minor_id=o.MinorId
            WHERE TRANSLATE(LEFT(e.name,9) COLLATE Latin1_General_100_BIN2,N'TOBEL',N'tobel') COLLATE Latin1_General_100_BIN2=N'toolbelt.')
            THROW 53903,N'TableClone: Ownershipproperty wird nicht kopiert.',11;
        IF EXISTS(SELECT 1 FROM @Owners o JOIN sys.extended_properties e ON e.class=o.Class AND e.major_id=o.MajorId AND e.minor_id=o.MinorId
            WHERE e.value IS NOT NULL AND (SQL_VARIANT_PROPERTY(e.value,'BaseType') NOT IN
                (N'bit',N'tinyint',N'smallint',N'int',N'bigint',N'decimal',N'numeric',N'money',N'smallmoney',N'float',N'real',
                 N'date',N'time',N'datetime',N'smalldatetime',N'datetime2',N'datetimeoffset',N'char',N'varchar',N'nchar',N'nvarchar',N'binary',N'varbinary',N'uniqueidentifier')
                OR SQL_VARIANT_PROPERTY(e.value,'BaseType') IS NULL OR DATALENGTH(e.value)>7500 OR TRY_CONVERT(int,SQL_VARIANT_PROPERTY(e.value,'TotalBytes')) IS NULL OR TRY_CONVERT(int,SQL_VARIANT_PROPERTY(e.value,'TotalBytes'))<DATALENGTH(e.value) OR TRY_CONVERT(int,SQL_VARIANT_PROPERTY(e.value,'TotalBytes'))>8016))
            THROW 53903,N'TableClone: nicht unterstützter Propertywert.',12;
        -- Mindestens eine UTF16-Einheit je späterer Zeile: kein engerer Propertycountvertrag.
        IF (SELECT COUNT_BIG(*)*2 FROM @Owners o JOIN sys.extended_properties e ON e.class=o.Class AND e.major_id=o.MajorId AND e.minor_id=o.MinorId)>2097152
            THROW 53906,N'TableClone: Property-Minimalbytes überschreiten die Scriptgrenze.',1;
        INSERT #tbx_TableClone_EpOwners
            SELECT @MapOrdinal,@TargetSchema,Class,MajorId,MinorId,SortKind,SourceOrdinal,Level1Type,Level1Name,Level2Type,Level2Name,TargetName FROM @Owners;
    END;

        IF (SELECT SUM(CONVERT(bigint,DATALENGTH(ScriptText))) FROM #tbx_TableClone_Plan)>2097152
            THROW 53906,N'TableClone: globale Scriptbytes überschritten.',2;
        FETCH NEXT FROM RenderCursor INTO @MapOrdinal,@SourceSchema,@SourceTable,@TargetSchema,@TargetTable,@SourceId,@TargetSchemaId;
    END;
    CLOSE RenderCursor; DEALLOCATE RenderCursor;
    IF EXISTS(SELECT 1 FROM #tbx_TableClone_Names GROUP BY SchemaId,GeneratedName HAVING COUNT_BIG(*)>1)
        THROW 53904,N'TableClone: globale Constraintnamenskollision.',1;
    ;WITH Ordered AS(SELECT OriginalOrdinal,7+ROW_NUMBER() OVER(ORDER BY Phase,MapOrdinal,OriginalOrdinal) NewOrdinal FROM #tbx_TableClone_Order)
    UPDATE p SET Ordinal=o.NewOrdinal FROM #tbx_TableClone_Plan p JOIN Ordered o ON o.OriginalOrdinal=p.Ordinal;
    IF @IncludeExtendedProperties=1
    BEGIN
        DECLARE @EpName sysname,@EpValue sql_variant,@EpBase sysname,@EpPrecision int,@EpScale int,@EpLength int,@EpCollation sysname,
            @EpL1Type nvarchar(16),@EpL1Name sysname,@EpL2Type nvarchar(16),@EpL2Name sysname,@EpTarget nvarchar(776),
            @EpTargetSchema sysname,@EpType nvarchar(512),@EpLiteral nvarchar(max),@EpExpression nvarchar(max),@EpDdl nvarchar(max),
            @EpOrdinal int=(SELECT MAX(Ordinal) FROM #tbx_TableClone_Plan),@PlanBytes bigint=(SELECT SUM(CONVERT(bigint,DATALENGTH(ScriptText))) FROM #tbx_TableClone_Plan);
        DECLARE PropertyCursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT e.name,e.value,o.Level1Type,o.Level1Name,o.Level2Type,o.Level2Name,o.TargetName,o.TargetSchema
            FROM #tbx_TableClone_EpOwners o JOIN sys.extended_properties e ON e.class=o.Class AND e.major_id=o.MajorId AND e.minor_id=o.MinorId
            ORDER BY o.MapOrdinal,o.SortKind,o.SourceOrdinal,e.name COLLATE Latin1_General_100_BIN2,CONVERT(varbinary(256),e.name);
        OPEN PropertyCursor;
        FETCH NEXT FROM PropertyCursor INTO @EpName,@EpValue,@EpL1Type,@EpL1Name,@EpL2Type,@EpL2Name,@EpTarget,@EpTargetSchema;
        WHILE @@FETCH_STATUS=0
        BEGIN
            SELECT @EpBase=CONVERT(sysname,SQL_VARIANT_PROPERTY(@EpValue,'BaseType')),
                @EpPrecision=CONVERT(int,SQL_VARIANT_PROPERTY(@EpValue,'Precision')),@EpScale=CONVERT(int,SQL_VARIANT_PROPERTY(@EpValue,'Scale')),
                @EpLength=CONVERT(int,SQL_VARIANT_PROPERTY(@EpValue,'MaxLength')),@EpCollation=CONVERT(sysname,SQL_VARIANT_PROPERTY(@EpValue,'Collation'));
            IF @EpBase IN(N'char',N'varchar',N'nchar',N'nvarchar') AND
                (@EpLength IS NULL OR @EpLength<=0 OR @EpCollation IS NULL OR NOT EXISTS(SELECT 1 FROM sys.fn_helpcollations() WHERE name=@EpCollation COLLATE DATABASE_DEFAULT))
                THROW 53903,N'TableClone: Property-Stringmetadaten nicht rekonstruierbar.',12;
            SET @EpType=QUOTENAME(@EpBase)+CASE
                WHEN @EpBase IN(N'decimal',N'numeric') THEN N'('+CONVERT(nvarchar(2),@EpPrecision)+N','+CONVERT(nvarchar(2),@EpScale)+N')'
                WHEN @EpBase IN(N'time',N'datetime2',N'datetimeoffset') THEN N'('+CONVERT(nvarchar(2),@EpScale)+N')'
                WHEN @EpBase IN(N'char',N'varchar',N'nchar',N'nvarchar',N'binary',N'varbinary') THEN N'('+CONVERT(nvarchar(5),@EpLength/CASE WHEN @EpBase IN(N'nchar',N'nvarchar') THEN 2 ELSE 1 END)+N')'
                WHEN @EpBase=N'float' THEN N'('+CONVERT(nvarchar(2),@EpPrecision)+N')' ELSE N'' END;
            SET @EpLiteral=CASE
                WHEN @EpBase IN(N'binary',N'varbinary') THEN N'0x'+CONVERT(nvarchar(max),CONVERT(varbinary(max),@EpValue),2)
                WHEN @EpBase=N'money' THEN N'N'''+CONVERT(nvarchar(128),CONVERT(money,@EpValue),2)+N''''
                WHEN @EpBase=N'smallmoney' THEN N'N'''+CONVERT(nvarchar(128),CONVERT(smallmoney,@EpValue),2)+N''''
                WHEN @EpBase=N'float' THEN N'N'''+CONVERT(nvarchar(128),CONVERT(float,@EpValue),3)+N''''
                WHEN @EpBase=N'real' THEN N'N'''+CONVERT(nvarchar(128),CONVERT(real,@EpValue),3)+N''''
                WHEN @EpBase=N'datetimeoffset' THEN N'N'''+CONVERT(nvarchar(128),CONVERT(datetimeoffset(7),@EpValue),121)+N''''
                WHEN @EpBase=N'datetime' THEN N'N'''+CONVERT(nvarchar(128),CONVERT(datetime,@EpValue),126)+N''''
                WHEN @EpBase IN(N'date',N'time',N'datetime',N'smalldatetime',N'datetime2') THEN N'N'''+
                    CASE WHEN @EpBase=N'time' THEN CONVERT(nvarchar(128),CONVERT(time(7),@EpValue),126)
                         ELSE CONVERT(nvarchar(128),CONVERT(datetime2(7),@EpValue),126) END+N''''
                ELSE N'N'''+REPLACE(CONVERT(nvarchar(max),@EpValue),N'''',N'''''')+N'''' END;
            SET @EpExpression=CASE WHEN @EpValue IS NULL THEN N'CONVERT(int,NULL)' ELSE N'CONVERT('+@EpType+N','+@EpLiteral+
                CASE WHEN @EpBase IN(N'char',N'varchar',N'nchar',N'nvarchar') THEN N' COLLATE '+@EpCollation ELSE N'' END+N')'+
                CASE WHEN @EpBase IN(N'char',N'varchar',N'nchar',N'nvarchar') THEN N' COLLATE '+@EpCollation ELSE N'' END END;
            SET @EpOrdinal+=1;
            SET @EpDdl=N'DECLARE @tbx_CloneEp'+CONVERT(nvarchar(12),@EpOrdinal)+N' sql_variant = '+@EpExpression+N';'+NCHAR(10)+
                N'EXEC sys.sp_addextendedproperty @name=N'''+REPLACE(@EpName,N'''',N'''''')+N''',@value=@tbx_CloneEp'+CONVERT(nvarchar(12),@EpOrdinal)+
                N',@level0type=N''SCHEMA'',@level0name=N'''+REPLACE(@EpTargetSchema,N'''',N'''''')+N''',@level1type=N'''+@EpL1Type+
                N''',@level1name=N'''+REPLACE(@EpL1Name,N'''',N'''''')+N''''+
                CASE WHEN @EpL2Type IS NULL THEN N'' ELSE N',@level2type=N'''+@EpL2Type+N''',@level2name=N'''+REPLACE(@EpL2Name,N'''',N'''''')+N'''' END+N';';
            SET @PlanBytes+=CONVERT(bigint,DATALENGTH(@EpDdl));
            IF @PlanBytes>2097152 THROW 53906,N'TableClone: Vorschau überschreitet2MiB Scripttext.',2;
            INSERT #tbx_TableClone_Plan VALUES(@EpOrdinal,'EXTENDED_PROPERTY',@EpTarget,@EpDdl);
            FETCH NEXT FROM PropertyCursor INTO @EpName,@EpValue,@EpL1Type,@EpL1Name,@EpL2Type,@EpL2Name,@EpTarget,@EpTargetSchema;
        END;
        CLOSE PropertyCursor; DEALLOCATE PropertyCursor;
    END;

    END;
    IF @TableMap IS NOT NULL
    BEGIN
        DECLARE @FkId int,@FkName sysname,@FkDisabled bit,@FkUntrusted bit,@FkNfr bit,@FkDelete tinyint,@FkUpdate tinyint,
            @FkOwner nvarchar(776),@FkReference nvarchar(776),@FkSchemaId int,@FkSchema sysname,@FkTable sysname,
            @FkColumns nvarchar(max),@FkReferenceColumns nvarchar(max),@FkGenerated sysname,@FkScript nvarchar(max),
            @FkExistingId int,
            @FkOrdinal int=COALESCE((SELECT MAX(Ordinal) FROM #tbx_TableClone_Plan),0);
        DECLARE @FkStates TABLE(MapOrdinal int NOT NULL,FkName sysname NOT NULL,OwnerName nvarchar(776) NOT NULL,GeneratedName sysname NOT NULL);
        -- Eine gemeinsame Erwartungsrelation hält Namen, Aktionen, Zustände und geordnete Spaltenpaare.
        DECLARE @FkExpected TABLE(SourceFkId int NOT NULL PRIMARY KEY,MapOrdinal int NOT NULL,OriginalName sysname NOT NULL,
            Disabled bit NOT NULL,Untrusted bit NOT NULL,Nfr bit NOT NULL,DeleteAction tinyint NOT NULL,UpdateAction tinyint NOT NULL,
            SchemaId int NOT NULL,SchemaName sysname NOT NULL,TableName sysname NOT NULL,ReferenceName nvarchar(776) NOT NULL,
            ParentTargetId int NULL,ReferenceTargetId int NULL,GeneratedName sysname NOT NULL,
            ColumnsText nvarchar(max) NULL,ReferenceColumnsText nvarchar(max) NULL,ExistingId int NULL);
        DECLARE @FkExpectedColumns TABLE(SourceFkId int NOT NULL,Ordinal int NOT NULL,
            ParentName sysname NOT NULL,ReferenceName sysname NOT NULL,PRIMARY KEY(SourceFkId,Ordinal));
        INSERT @FkExpectedColumns
            SELECT f.object_id,c.constraint_column_id,pc.name,rc.name FROM sys.foreign_keys f
            JOIN #tbx_TableClone_Map m ON m.SourceId=f.parent_object_id
            JOIN sys.foreign_key_columns c ON c.constraint_object_id=f.object_id
            JOIN sys.columns pc ON pc.object_id=c.parent_object_id AND pc.column_id=c.parent_column_id
            JOIN sys.columns rc ON rc.object_id=c.referenced_object_id AND rc.column_id=c.referenced_column_id;
        INSERT @FkExpected
            SELECT f.object_id,m.MapOrdinal,f.name,f.is_disabled,f.is_not_trusted,f.is_not_for_replication,
                f.delete_referential_action,f.update_referential_action,m.TargetSchemaId,m.TargetSchema,m.TargetTable,
                CASE WHEN r.SourceId IS NOT NULL THEN QUOTENAME(r.TargetSchema)+N'.'+QUOTENAME(r.TargetTable)
                    ELSE QUOTENAME(OBJECT_SCHEMA_NAME(f.referenced_object_id))+N'.'+QUOTENAME(OBJECT_NAME(f.referenced_object_id)) END,
                m.TargetId,r.TargetId,
                CONVERT(sysname,N'FK_'+CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),
                    CONVERT(nvarchar(12),DATALENGTH(m.TargetSchema))+N':'+m.TargetSchema+N';'+CONVERT(nvarchar(12),DATALENGTH(m.TargetTable))+N':'+m.TargetTable+N';'
                    +N'FK;'+CONVERT(nvarchar(12),DATALENGTH(f.name))+N':'+f.name)),2)),
                c.ColumnsText,c.ReferenceColumnsText,NULL
            FROM sys.foreign_keys f JOIN #tbx_TableClone_Map m ON m.SourceId=f.parent_object_id
            LEFT JOIN #tbx_TableClone_Map r ON r.SourceId=f.referenced_object_id
            CROSS APPLY(SELECT STRING_AGG(CONVERT(nvarchar(max),QUOTENAME(ParentName)),N',') WITHIN GROUP(ORDER BY Ordinal) ColumnsText,
                STRING_AGG(CONVERT(nvarchar(max),QUOTENAME(ReferenceName)),N',') WITHIN GROUP(ORDER BY Ordinal) ReferenceColumnsText
                FROM @FkExpectedColumns WHERE SourceFkId=f.object_id) c;
        IF @CopyFk=1
        BEGIN
            IF EXISTS(SELECT 1 FROM @FkExpected WHERE ParentTargetId IS NULL OR ReferenceTargetId IS NULL)
                THROW 53903,N'TableClone: COPY_FK erlaubt keine ausgehende ungemappte Referenz.',13;
            IF EXISTS(SELECT 1 FROM @FkExpectedColumns c JOIN @FkExpected e ON e.SourceFkId=c.SourceFkId
                WHERE NOT EXISTS(SELECT 1 FROM sys.columns p WHERE p.object_id=e.ParentTargetId AND CONVERT(varbinary(256),p.name)=CONVERT(varbinary(256),c.ParentName))
                   OR NOT EXISTS(SELECT 1 FROM sys.columns r WHERE r.object_id=e.ReferenceTargetId AND CONVERT(varbinary(256),r.name)=CONVERT(varbinary(256),c.ReferenceName)))
                THROW 53905,N'TableClone: COPY_FK-Zielspalten fehlen oder unterscheiden sich.',2;
            DECLARE @FkMatches TABLE(SourceFkId int NOT NULL,TargetFkId int NOT NULL,PRIMARY KEY(SourceFkId,TargetFkId));
            INSERT @FkMatches
                SELECT e.SourceFkId,f.object_id FROM @FkExpected e JOIN sys.foreign_keys f
                  ON f.parent_object_id=e.ParentTargetId AND f.referenced_object_id=e.ReferenceTargetId
                 AND f.is_disabled=e.Disabled AND f.is_not_trusted=e.Untrusted AND f.is_not_for_replication=e.Nfr
                 AND f.delete_referential_action=e.DeleteAction AND f.update_referential_action=e.UpdateAction
                WHERE NOT EXISTS(SELECT c.Ordinal,CONVERT(varbinary(256),c.ParentName),CONVERT(varbinary(256),c.ReferenceName)
                    FROM @FkExpectedColumns c WHERE c.SourceFkId=e.SourceFkId
                    EXCEPT SELECT c.constraint_column_id,CONVERT(varbinary(256),p.name),CONVERT(varbinary(256),r.name)
                    FROM sys.foreign_key_columns c JOIN sys.columns p ON p.object_id=c.parent_object_id AND p.column_id=c.parent_column_id
                    JOIN sys.columns r ON r.object_id=c.referenced_object_id AND r.column_id=c.referenced_column_id WHERE c.constraint_object_id=f.object_id)
                  AND NOT EXISTS(SELECT c.constraint_column_id,CONVERT(varbinary(256),p.name),CONVERT(varbinary(256),r.name)
                    FROM sys.foreign_key_columns c JOIN sys.columns p ON p.object_id=c.parent_object_id AND p.column_id=c.parent_column_id
                    JOIN sys.columns r ON r.object_id=c.referenced_object_id AND r.column_id=c.referenced_column_id WHERE c.constraint_object_id=f.object_id
                    EXCEPT SELECT c.Ordinal,CONVERT(varbinary(256),c.ParentName),CONVERT(varbinary(256),c.ReferenceName)
                    FROM @FkExpectedColumns c WHERE c.SourceFkId=e.SourceFkId);
            IF EXISTS(SELECT 1 FROM @FkMatches GROUP BY SourceFkId HAVING COUNT(*)<>1)
               OR EXISTS(SELECT 1 FROM @FkMatches GROUP BY TargetFkId HAVING COUNT(*)<>1)
               OR EXISTS(SELECT 1 FROM sys.foreign_keys f JOIN #tbx_TableClone_Map m ON m.TargetId=f.parent_object_id
                    WHERE NOT EXISTS(SELECT 1 FROM @FkMatches x WHERE x.TargetFkId=f.object_id))
                THROW 53903,N'TableClone: zusätzliche, abweichende oder mehrdeutige vorhandene Ziel-FK.',23;
            UPDATE e SET ExistingId=x.TargetFkId FROM @FkExpected e JOIN @FkMatches x ON x.SourceFkId=e.SourceFkId;
        END;
        DECLARE ForeignKeyCursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT MapOrdinal,SourceFkId,OriginalName,Disabled,Untrusted,Nfr,DeleteAction,UpdateAction,
                SchemaId,SchemaName,TableName,ReferenceName,GeneratedName,ColumnsText,ReferenceColumnsText,ExistingId
            FROM @FkExpected
            ORDER BY MapOrdinal,OriginalName COLLATE Latin1_General_100_BIN2,CONVERT(varbinary(256),OriginalName);
        OPEN ForeignKeyCursor;
        FETCH NEXT FROM ForeignKeyCursor INTO @MapOrdinal,@FkId,@FkName,@FkDisabled,@FkUntrusted,@FkNfr,@FkDelete,@FkUpdate,@FkSchemaId,@FkSchema,@FkTable,@FkReference,@FkGenerated,@FkColumns,@FkReferenceColumns,@FkExistingId;
        WHILE @@FETCH_STATUS=0
        BEGIN
            SET @FkOwner=QUOTENAME(@FkSchema)+N'.'+QUOTENAME(@FkTable);
            IF @CopyFk=0 OR @FkExistingId IS NULL
            BEGIN

            IF EXISTS(SELECT 1 FROM #tbx_TableClone_Names WHERE SchemaId=@FkSchemaId AND GeneratedName=@FkGenerated COLLATE DATABASE_DEFAULT)
               OR EXISTS(SELECT 1 FROM sys.objects WHERE schema_id=@FkSchemaId AND name=@FkGenerated COLLATE DATABASE_DEFAULT)
                THROW 53904,N'TableClone: deterministischer FK-Name kollidiert.',1;
            INSERT #tbx_TableClone_Names VALUES(@FkSchemaId,@FkGenerated);

            SET @FkScript=N'ALTER TABLE '+@FkOwner+CASE @FkUntrusted WHEN 0 THEN N' WITH CHECK' ELSE N' WITH NOCHECK' END
                +N' ADD CONSTRAINT '+QUOTENAME(@FkGenerated)+N' FOREIGN KEY ('+@FkColumns+N') REFERENCES '+@FkReference+N' ('+@FkReferenceColumns+N')'
                +N' ON DELETE '+CASE @FkDelete WHEN 0 THEN N'NO ACTION' WHEN 1 THEN N'CASCADE' WHEN 2 THEN N'SET NULL' WHEN 3 THEN N'SET DEFAULT' END
                +N' ON UPDATE '+CASE @FkUpdate WHEN 0 THEN N'NO ACTION' WHEN 1 THEN N'CASCADE' WHEN 2 THEN N'SET NULL' WHEN 3 THEN N'SET DEFAULT' END
                +CASE @FkNfr WHEN 1 THEN N' NOT FOR REPLICATION' ELSE N'' END+N';';
            SET @FkOrdinal+=1;
            INSERT #tbx_TableClone_Plan VALUES(@FkOrdinal,'FOREIGN_KEY',@FkOwner,@FkScript);
            IF @FkDisabled=1 INSERT @FkStates VALUES(@MapOrdinal,@FkName,@FkOwner,@FkGenerated);
            END;
            FETCH NEXT FROM ForeignKeyCursor INTO @MapOrdinal,@FkId,@FkName,@FkDisabled,@FkUntrusted,@FkNfr,@FkDelete,@FkUpdate,@FkSchemaId,@FkSchema,@FkTable,@FkReference,@FkGenerated,@FkColumns,@FkReferenceColumns,@FkExistingId;
        END;
        CLOSE ForeignKeyCursor; DEALLOCATE ForeignKeyCursor;
        INSERT #tbx_TableClone_Plan
            SELECT @FkOrdinal+ROW_NUMBER() OVER(ORDER BY MapOrdinal,FkName COLLATE Latin1_General_100_BIN2,CONVERT(varbinary(256),FkName)),
                'FOREIGN_KEY_STATE',OwnerName,N'ALTER TABLE '+OwnerName+N' NOCHECK CONSTRAINT '+QUOTENAME(GeneratedName)+N';' FROM @FkStates;
    END;
    IF @IncludeTriggers=1
    BEGIN
        -- Keine statische Parserreferenz: Option 0 bleibt ohne CLR auch auf Linux kompilierbar.
        DECLARE @TrVersion int=TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion'))*10,@TrPlatform nvarchar(max)=CONVERT(nvarchar(max),@@VERSION);
        IF @TrPlatform IS NULL OR CHARINDEX(N' on Windows ',@TrPlatform COLLATE Latin1_General_100_BIN2)=0 OR CHARINDEX(N' on Linux ',@TrPlatform COLLATE Latin1_General_100_BIN2)>0 OR @TrVersion IS NULL OR @TrVersion NOT IN(150,160,170)
            THROW 53907,N'TableClone: Trigger-Opt-in benötigt Windows und SQL Server 2019, 2022 oder 2025.',2;
        IF EXISTS(SELECT 1 FROM (VALUES(N'sys.assembly_files'),(N'sys.assembly_modules'),(N'sys.sql_expression_dependencies')) v(n)
            WHERE COALESCE(HAS_PERMS_BY_NAME(v.n,N'OBJECT',N'SELECT'),0)<>1)
            THROW 53907,N'TableClone: vollständige Parser-/Dependency-Katalogsicht fehlt.',3;
        DECLARE @TrProviderId int,@TrDomId int;
        SELECT @TrProviderId=assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_Tsql_ScriptParser' COLLATE DATABASE_DEFAULT AND permission_set=3;
        SELECT @TrDomId=assembly_id FROM sys.assemblies WHERE name=N'Microsoft.SqlServer.TransactSql.ScriptDom' COLLATE DATABASE_DEFAULT;
        IF @TrProviderId IS NULL OR @TrDomId IS NULL
          OR NOT EXISTS(SELECT 1 FROM sys.assembly_files WHERE assembly_id=@TrProviderId AND file_id=1 AND HASHBYTES('SHA2_512',content)=0x7592A3C2535F43F6B4D0CF491BC3E7A20F2B2B8712C861D1E33BE428971860CD9E2401A67B6E5E2F0853BBF453D9C20DA9C838B070C428BD796D05F86C7A0C42)
          OR NOT EXISTS(SELECT 1 FROM sys.assembly_files WHERE assembly_id=@TrDomId AND file_id=1 AND HASHBYTES('SHA2_512',content)=0x24BDEE1CC5296488C3609BB6911DD76935B510F823CAAE4D39E8C45C84D272F3D28E3F6156E1E185C0F81D5812C9100E9C71CBE788966AC477A5B213BCE672D0)
          OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=5 AND major_id=@TrProviderId AND minor_id=0 AND name=N'Toolbelt.Managed' AND SQL_VARIANT_PROPERTY(value,'BaseType')=N'int' AND TRY_CONVERT(int,value)=1)
          OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=5 AND major_id=@TrProviderId AND minor_id=0 AND name=N'Toolbelt.ModuleId' AND SQL_VARIANT_PROPERTY(value,'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'toolbelt.tsql.script-parser'))
          OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=N'Toolbelt.Module.toolbelt.tsql.script-parser.Version' AND SQL_VARIANT_PROPERTY(value,'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'2.0.0'))
          OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=N'Toolbelt.Module.toolbelt.tsql.script-parser.DeploymentMode' AND SQL_VARIANT_PROPERTY(value,'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value)) IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central')))
            THROW 53907,N'TableClone: registriertes Parser-2.0-Binary oder Modulmarker stimmt nicht.',4;
        DECLARE @TrFunctions TABLE(RoleId int NOT NULL PRIMARY KEY,Name sysname COLLATE DATABASE_DEFAULT NOT NULL,Method sysname NOT NULL,ObjectId int NULL);
        INSERT @TrFunctions VALUES(1,N'TVF_ParseScriptNodes',N'ParseScriptNodes',NULL),(2,N'TVF_ParseScriptNodeProperties',N'ParseScriptNodeProperties',NULL),
            (3,N'TVF_TokenizeScript',N'TokenizeScript',NULL),(4,N'TVF_ParseScriptErrors',N'ParseScriptErrors',NULL);
        UPDATE f SET ObjectId=o.object_id FROM @TrFunctions f JOIN sys.objects o ON o.name=f.Name COLLATE DATABASE_DEFAULT AND o.schema_id=SCHEMA_ID(N'toolbelt_tsql') AND CONVERT(varbinary(2),o.type)=CONVERT(varbinary(2),'FT');
        IF EXISTS(SELECT 1 FROM @TrFunctions f WHERE f.ObjectId IS NULL OR COALESCE(HAS_PERMS_BY_NAME(N'toolbelt_tsql.'+QUOTENAME(f.Name),N'OBJECT',N'SELECT'),0)<>1
            OR NOT EXISTS(SELECT 1 FROM sys.assembly_modules a WHERE a.object_id=f.ObjectId AND a.assembly_id=@TrProviderId
                AND CONVERT(varbinary(max),a.assembly_class)=CONVERT(varbinary(max),N'Toolbelt.Tsql.ScriptParser.ScriptParserProvider') AND CONVERT(varbinary(max),a.assembly_method)=CONVERT(varbinary(max),f.Method))
            OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=f.ObjectId AND minor_id=0 AND name=N'Toolbelt.Managed' AND SQL_VARIANT_PROPERTY(value,'BaseType')=N'int' AND TRY_CONVERT(int,value)=1)
            OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=f.ObjectId AND minor_id=0 AND name=N'Toolbelt.ModuleId' AND SQL_VARIANT_PROPERTY(value,'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'toolbelt.tsql.script-parser'))
            OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=f.ObjectId AND minor_id=0 AND name=N'Toolbelt.ModuleVersion' AND SQL_VARIANT_PROPERTY(value,'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'2.0.0'))
            OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=f.ObjectId AND minor_id=0 AND name=N'Toolbelt.Visibility' AND SQL_VARIANT_PROPERTY(value,'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'public')))
            THROW 53907,N'TableClone: vier öffentliche Parser-FTs, SELECT oder CLR-Binding fehlt.',5;
        DECLARE @TrShape TABLE(RoleId int NOT NULL,Ordinal int NOT NULL,Name sysname NOT NULL,TypeId int NOT NULL,Length smallint NOT NULL,PRIMARY KEY(RoleId,Ordinal));
        INSERT @TrShape VALUES
            (1,1,N'NodeId',56,4),(1,2,N'ParentNodeId',56,4),(1,3,N'Depth',56,4),(1,4,N'SiblingOrdinal',56,4),(1,5,N'PropertyName',231,256),(1,6,N'PropertyIndex',56,4),
            (1,7,N'NodeType',231,256),(1,8,N'StartOffset',56,4),(1,9,N'StartLine',56,4),(1,10,N'StartColumn',56,4),(1,11,N'FragmentLength',56,4),(1,12,N'FirstTokenIndex',56,4),(1,13,N'LastTokenIndex',56,4),
            (2,1,N'NodeId',56,4),(2,2,N'PropertyName',231,256),(2,3,N'PropertyKind',231,64),(2,4,N'PropertyValue',231,-1),
            (3,1,N'TokenIndex',56,4),(3,2,N'TokenType',231,128),(3,3,N'TokenText',231,-1),(3,4,N'StartOffset',56,4),(3,5,N'StartLine',56,4),(3,6,N'StartColumn',56,4),
            (4,1,N'ErrorOrdinal',56,4),(4,2,N'Number',56,4),(4,3,N'Message',231,8000),(4,4,N'StartOffset',56,4),(4,5,N'StartLine',56,4),(4,6,N'StartColumn',56,4);
        IF EXISTS(SELECT 1 FROM @TrFunctions f WHERE (SELECT COUNT(*) FROM sys.parameters WHERE object_id=f.ObjectId AND parameter_id>0)<>5
            OR EXISTS(SELECT 1 FROM (VALUES(1,N'@SqlText',231,-1),(2,N'@TSqlVersion',56,4),(3,N'@QuotedIdentifiers',104,1),(4,N'@MaxInputBytes',56,4),(5,N'@MaxNestingDepth',56,4)) p(n,name,t,l)
                WHERE NOT EXISTS(SELECT 1 FROM sys.parameters a WHERE a.object_id=f.ObjectId AND a.parameter_id=p.n AND CONVERT(varbinary(256),a.name)=CONVERT(varbinary(256),p.name) AND a.system_type_id=p.t AND a.user_type_id=a.system_type_id AND a.max_length=p.l AND a.is_output=0))
            OR (SELECT COUNT(*) FROM sys.columns WHERE object_id=f.ObjectId)<>(SELECT COUNT(*) FROM @TrShape WHERE RoleId=f.RoleId)
            OR EXISTS(SELECT 1 FROM @TrShape s WHERE s.RoleId=f.RoleId AND NOT EXISTS(SELECT 1 FROM sys.columns c WHERE c.object_id=f.ObjectId AND c.column_id=s.Ordinal AND CONVERT(varbinary(256),c.name)=CONVERT(varbinary(256),s.Name) AND c.system_type_id=s.TypeId AND c.user_type_id=c.system_type_id AND c.max_length=s.Length AND c.is_nullable=1 AND c.is_computed=0)))
            THROW 53907,N'TableClone: Parserparameter oder relationales Ausgabeschema stimmt nicht.',6;
        IF EXISTS(SELECT 1 FROM sys.triggers t JOIN #tbx_TableClone_Map m ON m.SourceId=t.parent_id LEFT JOIN sys.sql_modules s ON s.object_id=t.object_id
            WHERE t.parent_class<>1 OR CONVERT(varbinary(2),t.type)<>CONVERT(varbinary(2),'TR') OR t.is_ms_shipped=1 OR s.object_id IS NULL OR s.definition IS NULL OR s.execute_as_principal_id IS NOT NULL OR s.uses_native_compilation=1)
            THROW 53903,N'TableClone: verschlüsselter, CLR-, EXECUTE-AS- oder Spezialtrigger.',15;
        IF EXISTS(SELECT 1 FROM sys.extended_properties e JOIN sys.triggers t ON e.class=1 AND e.major_id=t.object_id JOIN #tbx_TableClone_Map m ON m.SourceId=t.parent_id)
            THROW 53903,N'TableClone: Triggerproperties werden nicht still verworfen.',10;
        -- Der Katalog bindet permanente Objekte; lokale CTE-/Aliasnamen werden erst im AST aufgelöst.
        IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d JOIN sys.triggers t ON t.object_id=d.referencing_id JOIN #tbx_TableClone_Map m ON m.SourceId=t.parent_id
            LEFT JOIN sys.objects o ON o.object_id=d.referenced_id WHERE (d.referenced_class<>1 OR d.referenced_server_name IS NOT NULL OR d.referenced_database_name IS NOT NULL
            OR d.referenced_id IS NULL OR d.is_ambiguous=1 OR d.is_caller_dependent=1 OR o.object_id IS NULL
            OR (CONVERT(varbinary(2),o.type)=CONVERT(varbinary(2),CONVERT(char(2),'U')) AND NOT EXISTS(SELECT 1 FROM #tbx_TableClone_Map r WHERE r.SourceId=o.object_id))
            OR CONVERT(varbinary(2),o.type) NOT IN(CONVERT(varbinary(2),CONVERT(char(2),'U')),CONVERT(varbinary(2),'FN'),CONVERT(varbinary(2),'IF'),CONVERT(varbinary(2),'TF'))
            OR COALESCE(HAS_PERMS_BY_NAME(QUOTENAME(OBJECT_SCHEMA_NAME(o.object_id))+N'.'+QUOTENAME(o.name),N'OBJECT',N'VIEW DEFINITION'),0)<>1)
            AND NOT (d.referenced_class=1 AND d.referenced_id IS NULL AND d.referenced_schema_name IS NULL
                AND d.referenced_database_name IS NULL AND d.referenced_server_name IS NULL
                AND d.is_ambiguous=0 AND d.is_caller_dependent=0 AND d.referenced_entity_name IS NOT NULL
                AND CONVERT(varbinary(max),LOWER(d.referenced_entity_name COLLATE Latin1_General_100_BIN2))
                    IN(CONVERT(varbinary(max),N'inserted'),CONVERT(varbinary(max),N'deleted'))))
            THROW 53903,N'TableClone: externe, ungelöste oder nicht gemappte Triggerdependency.',16;
        CREATE TABLE #tbx_TableClone_AstNodes(NodeId int NULL,ParentNodeId int NULL,Depth int NULL,SiblingOrdinal int NULL,PropertyName nvarchar(128) COLLATE Latin1_General_100_BIN2 NULL,PropertyIndex int NULL,
            NodeType nvarchar(128) COLLATE Latin1_General_100_BIN2 NULL,StartOffset int NULL,StartLine int NULL,StartColumn int NULL,FragmentLength int NULL,FirstTokenIndex int NULL,LastTokenIndex int NULL);
        CREATE TABLE #tbx_TableClone_AstProperties(NodeId int NULL,PropertyName nvarchar(128) COLLATE Latin1_General_100_BIN2 NULL,PropertyKind nvarchar(32) COLLATE Latin1_General_100_BIN2 NULL,PropertyValue nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL);
        CREATE TABLE #tbx_TableClone_AstTokens(TokenIndex int NULL,TokenType nvarchar(64) COLLATE Latin1_General_100_BIN2 NULL,TokenText nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,StartOffset int NULL,StartLine int NULL,StartColumn int NULL);
        CREATE TABLE #tbx_TableClone_AstErrors(ErrorOrdinal int NULL,Number int NULL,Message nvarchar(4000) COLLATE Latin1_General_100_BIN2 NULL,StartOffset int NULL,StartLine int NULL,StartColumn int NULL);
        DECLARE @TrId int,@TrOriginalName sysname,@TrName sysname,@TrDisabled bit,@TrInstead bit,@TrNfr bit,@TrAnsi bit,@TrQi bit,@TrDefinition nvarchar(max),@TrRewritten nvarchar(max),@TrScript nvarchar(max),@TrRoot int,@TrNameNode int,@TrOnNode int,@TrOnObject int,@TrOrdinal int;
        DECLARE @TrContext TABLE(NodeId int NOT NULL PRIMARY KEY,ScopeId int NOT NULL,OuterScopeId int NOT NULL,StatementId int NOT NULL,CteId int NOT NULL,InOutput bit NOT NULL);
        DECLARE @TrScopes TABLE(ScopeId int NOT NULL PRIMARY KEY,OuterScopeId int NOT NULL,StatementId int NOT NULL,CteId int NOT NULL);
        DECLARE @TrIds TABLE(OwnerNode int NOT NULL,Part int NOT NULL,NodeId int NOT NULL,Value nvarchar(128) COLLATE DATABASE_DEFAULT NOT NULL,StartOffset int NOT NULL,Length int NOT NULL,PRIMARY KEY(OwnerNode,Part));
        DECLARE @TrCtes TABLE(NodeId int NOT NULL PRIMARY KEY,StatementId int NOT NULL,CteOrdinal int NOT NULL,Name nvarchar(128) COLLATE DATABASE_DEFAULT NOT NULL);
        DECLARE @TrRanges TABLE(NodeId int NOT NULL PRIMARY KEY,ScopeId int NOT NULL,Name nvarchar(128) COLLATE DATABASE_DEFAULT NOT NULL,SourceId int NULL,Alias bit NOT NULL);
        DECLARE @TrReferences TABLE(NodeId int NOT NULL PRIMARY KEY,ScopeId int NOT NULL,StatementId int NOT NULL,CteId int NOT NULL,IsTarget bit NOT NULL,NameNode int NOT NULL,Parts int NOT NULL,SchemaName nvarchar(128) COLLATE DATABASE_DEFAULT NULL,TableName nvarchar(128) COLLATE DATABASE_DEFAULT NOT NULL,AliasName nvarchar(128) COLLATE DATABASE_DEFAULT NULL,SourceId int NULL,LocalReference bit NOT NULL DEFAULT(0));
        DECLARE @TrEdits TABLE(StartOffset int NOT NULL PRIMARY KEY,Length int NOT NULL,Replacement nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL);
        DECLARE @TrStates TABLE(MapOrdinal int NOT NULL,OriginalName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,TargetName nvarchar(776) COLLATE Latin1_General_100_BIN2 NOT NULL,EventOrdinal int NOT NULL,ScriptText nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL);
        DECLARE TriggerCursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT m.MapOrdinal,m.SourceId,m.TargetSchemaId,m.SourceSchema,m.SourceTable,m.TargetSchema,m.TargetTable,t.object_id,t.name,t.is_disabled,t.is_instead_of_trigger,t.is_not_for_replication,s.uses_ansi_nulls,s.uses_quoted_identifier,s.definition
            FROM sys.triggers t JOIN #tbx_TableClone_Map m ON m.SourceId=t.parent_id JOIN sys.sql_modules s ON s.object_id=t.object_id
            ORDER BY m.MapOrdinal,t.name COLLATE Latin1_General_100_BIN2,CONVERT(varbinary(256),t.name);
        OPEN TriggerCursor;
        FETCH NEXT FROM TriggerCursor INTO @MapOrdinal,@SourceId,@TargetSchemaId,@SourceSchema,@SourceTable,@TargetSchema,@TargetTable,@TrId,@TrOriginalName,@TrDisabled,@TrInstead,@TrNfr,@TrAnsi,@TrQi,@TrDefinition;
        WHILE @@FETCH_STATUS=0
        BEGIN
            SET @TrName=CONVERT(sysname,N'TR_'+CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(binary(4),DATALENGTH(@TargetSchema)))+CONVERT(varbinary(max),@TargetSchema)
                +CONVERT(binary(4),DATALENGTH(@TargetTable))+CONVERT(varbinary(max),@TargetTable)+CONVERT(binary(4),DATALENGTH(@TrOriginalName))+CONVERT(varbinary(max),@TrOriginalName)),2));
            SET @TargetName=QUOTENAME(@TargetSchema)+N'.'+QUOTENAME(@TrName);
            IF EXISTS(SELECT 1 FROM sys.objects WHERE schema_id=@TargetSchemaId AND name=@TrName COLLATE DATABASE_DEFAULT)
                OR EXISTS(SELECT 1 FROM #tbx_TableClone_Names WHERE SchemaId=@TargetSchemaId AND GeneratedName=@TrName COLLATE DATABASE_DEFAULT)
                OR EXISTS(SELECT 1 FROM #tbx_TableClone_Map WHERE TargetSchemaId=@TargetSchemaId AND TargetTable=@TrName COLLATE DATABASE_DEFAULT)
                THROW 53904,N'TableClone: deterministischer Triggername kollidiert.',2;
            INSERT #tbx_TableClone_Names VALUES(@TargetSchemaId,@TrName);
            DELETE #tbx_TableClone_AstNodes; DELETE #tbx_TableClone_AstProperties; DELETE #tbx_TableClone_AstTokens; DELETE #tbx_TableClone_AstErrors;
            DELETE @TrContext; DELETE @TrScopes; DELETE @TrIds; DELETE @TrCtes; DELETE @TrRanges; DELETE @TrReferences; DELETE @TrEdits;
            -- Errors zuerst; identische Argumente für alle vier atomaren Parserergebnisse.
            EXEC sys.sp_executesql N'INSERT #tbx_TableClone_AstErrors SELECT * FROM toolbelt_tsql.TVF_ParseScriptErrors(@s,@v,@q,2097152,100);',N'@s nvarchar(max),@v int,@q bit',@TrDefinition,@TrVersion,@TrQi;
            IF EXISTS(SELECT 1 FROM #tbx_TableClone_AstErrors) THROW 53905,N'TableClone: Triggerdefinition enthält Parserfehler.',3;
            EXEC sys.sp_executesql N'INSERT #tbx_TableClone_AstNodes SELECT * FROM toolbelt_tsql.TVF_ParseScriptNodes(@s,@v,@q,2097152,100);
                INSERT #tbx_TableClone_AstProperties SELECT * FROM toolbelt_tsql.TVF_ParseScriptNodeProperties(@s,@v,@q,2097152,100);
                INSERT #tbx_TableClone_AstTokens SELECT * FROM toolbelt_tsql.TVF_TokenizeScript(@s,@v,@q,2097152,100);',N'@s nvarchar(max),@v int,@q bit',@TrDefinition,@TrVersion,@TrQi;
            IF NOT EXISTS(SELECT 1 FROM #tbx_TableClone_AstNodes) OR EXISTS(SELECT 1 FROM #tbx_TableClone_AstNodes WHERE NodeId IS NULL OR NodeId<1 OR Depth IS NULL OR Depth NOT BETWEEN 0 AND 100 OR NodeType IS NULL)
                OR EXISTS(SELECT 1 FROM #tbx_TableClone_AstNodes GROUP BY NodeId HAVING COUNT(*)<>1)
                OR (SELECT COUNT(*) FROM #tbx_TableClone_AstNodes WHERE ParentNodeId IS NULL)<>1
                OR EXISTS(SELECT 1 FROM #tbx_TableClone_AstNodes n LEFT JOIN #tbx_TableClone_AstNodes p ON p.NodeId=n.ParentNodeId WHERE n.ParentNodeId IS NOT NULL AND (p.NodeId IS NULL OR p.NodeId>=n.NodeId OR p.Depth+1<>n.Depth))
                OR EXISTS(SELECT 1 FROM #tbx_TableClone_AstProperties p WHERE p.NodeId IS NULL OR p.PropertyName IS NULL OR NOT EXISTS(SELECT 1 FROM #tbx_TableClone_AstNodes n WHERE n.NodeId=p.NodeId))
                OR EXISTS(SELECT 1 FROM #tbx_TableClone_AstProperties GROUP BY NodeId,PropertyName HAVING COUNT(*)<>1)
                THROW 53905,N'TableClone: inkonsistenter Parserbaum oder skalare Properties.',4;
            -- Lückenloser Tokenstrom muss genau die ursprünglichen UTF16-Bytes ergeben.
            IF NOT EXISTS(SELECT 1 FROM #tbx_TableClone_AstTokens) OR EXISTS(SELECT 1 FROM #tbx_TableClone_AstTokens WHERE TokenIndex IS NULL OR TokenText IS NULL OR StartOffset IS NULL OR StartOffset<0)
                OR EXISTS(SELECT 1 FROM #tbx_TableClone_AstTokens GROUP BY TokenIndex HAVING COUNT(*)<>1)
                OR EXISTS(SELECT 1 FROM (SELECT TokenIndex,StartOffset,DATALENGTH(TokenText)/2 Length,LEAD(StartOffset) OVER(ORDER BY TokenIndex) NextOffset,ROW_NUMBER() OVER(ORDER BY TokenIndex)-1 ExpectedIndex FROM #tbx_TableClone_AstTokens) a
                    WHERE TokenIndex<>ExpectedIndex OR (TokenIndex=0 AND StartOffset<>0) OR (NextOffset IS NOT NULL AND StartOffset+Length<>NextOffset) OR StartOffset+Length>DATALENGTH(@TrDefinition)/2)
                OR CONVERT(varbinary(max),(SELECT STRING_AGG(CONVERT(nvarchar(max),TokenText),N'') WITHIN GROUP(ORDER BY TokenIndex) FROM #tbx_TableClone_AstTokens))<>CONVERT(varbinary(max),@TrDefinition)
                THROW 53905,N'TableClone: Token-/UTF16-Spannen stimmen nicht mit der Definition überein.',4;
            SELECT @TrRoot=NULL,@TrNameNode=NULL,@TrOnNode=NULL,@TrOnObject=NULL;
            SELECT @TrRoot=n.NodeId FROM #tbx_TableClone_AstNodes n JOIN #tbx_TableClone_AstNodes b ON b.NodeId=n.ParentNodeId AND b.NodeType=N'TSqlBatch'
                WHERE n.NodeType IN(N'CreateTriggerStatement',N'AlterTriggerStatement',N'CreateOrAlterTriggerStatement');
            IF @TrRoot IS NULL OR (SELECT COUNT(*) FROM #tbx_TableClone_AstNodes n JOIN #tbx_TableClone_AstNodes b ON b.NodeId=n.ParentNodeId WHERE b.NodeType=N'TSqlBatch')<>1
                OR NOT EXISTS(SELECT 1 FROM #tbx_TableClone_AstNodes WHERE ParentNodeId IS NULL AND NodeType=N'TSqlScript')
                OR EXISTS(SELECT 1 FROM #tbx_TableClone_AstNodes WHERE NodeType IN(N'ExecuteStatement',N'ExecuteAsStatement',N'CreateTriggerStatement',N'AlterTriggerStatement',N'CreateOrAlterTriggerStatement') AND NodeId<>@TrRoot)
                OR NOT EXISTS(SELECT 1 FROM #tbx_TableClone_AstProperties WHERE NodeId=@TrRoot AND PropertyName=N'TriggerType' AND PropertyKind=N'Enum' AND PropertyValue=CASE @TrInstead WHEN 1 THEN N'InsteadOf' ELSE N'After' END)
                OR NOT EXISTS(SELECT 1 FROM #tbx_TableClone_AstProperties WHERE NodeId=@TrRoot AND PropertyName=N'IsNotForReplication' AND PropertyKind=N'Boolean' AND PropertyValue=CASE @TrNfr WHEN 1 THEN N'True' ELSE N'False' END)
                OR NOT EXISTS(SELECT 1 FROM #tbx_TableClone_AstProperties WHERE NodeId=@TrRoot AND PropertyName=N'WithAppend' AND PropertyValue=N'False')
                THROW 53903,N'TableClone: nicht belegte gewöhnliche DML-Triggerform oder EXEC im Body.',17;
            SELECT @TrNameNode=NodeId FROM #tbx_TableClone_AstNodes WHERE ParentNodeId=@TrRoot AND PropertyName=N'Name' AND NodeType=N'SchemaObjectName';
            SELECT @TrOnObject=NodeId FROM #tbx_TableClone_AstNodes WHERE ParentNodeId=@TrRoot AND PropertyName=N'TriggerObject' AND NodeType=N'TriggerObject';
            SELECT @TrOnNode=NodeId FROM #tbx_TableClone_AstNodes WHERE ParentNodeId=@TrOnObject AND PropertyName=N'Name' AND NodeType=N'SchemaObjectName';
            IF @TrNameNode IS NULL OR @TrOnNode IS NULL OR NOT EXISTS(SELECT 1 FROM #tbx_TableClone_AstProperties WHERE NodeId=@TrOnObject AND PropertyName=N'TriggerScope' AND PropertyValue=N'Normal')
                THROW 53903,N'TableClone: Triggerheader oder ON-Scope ist nicht eindeutig.',17;
            -- Nur Identifiers[i], niemals die duplizierten BaseIdentifier/SchemaIdentifier-Kinder.
            INSERT @TrIds
                SELECT n.ParentNodeId,n.PropertyIndex,n.NodeId,p.PropertyValue,n.StartOffset,n.FragmentLength
                FROM #tbx_TableClone_AstNodes n JOIN #tbx_TableClone_AstProperties p ON p.NodeId=n.NodeId AND p.PropertyName=N'Value' AND p.PropertyKind=N'String'
                WHERE n.NodeType=N'Identifier' AND n.PropertyName=N'Identifiers' AND n.PropertyIndex>=0;
            IF EXISTS(SELECT 1 FROM @TrIds i JOIN #tbx_TableClone_AstNodes n ON n.NodeId=i.NodeId WHERE i.StartOffset<0 OR i.Length<1 OR i.StartOffset+i.Length>DATALENGTH(@TrDefinition)/2
                OR n.FirstTokenIndex<>n.LastTokenIndex OR NOT EXISTS(SELECT 1 FROM #tbx_TableClone_AstTokens t WHERE t.TokenIndex=n.FirstTokenIndex AND t.StartOffset=i.StartOffset AND DATALENGTH(t.TokenText)/2=i.Length))
                OR EXISTS(SELECT 1 FROM @TrIds GROUP BY OwnerNode HAVING MIN(Part)<>0 OR MAX(Part)+1<>COUNT(*))
                THROW 53905,N'TableClone: Identifierlexeme sind keine belegten Tokenfragmente.',4;
            IF (SELECT COUNT(*) FROM @TrIds WHERE OwnerNode=@TrNameNode) NOT IN(1,2) OR (SELECT COUNT(*) FROM @TrIds WHERE OwnerNode=@TrOnNode) NOT IN(1,2)
                OR NOT EXISTS(SELECT 1 FROM @TrIds WHERE OwnerNode=@TrNameNode AND Part=(SELECT MAX(Part) FROM @TrIds WHERE OwnerNode=@TrNameNode) AND Value=@TrOriginalName COLLATE DATABASE_DEFAULT)
                OR EXISTS(SELECT 1 FROM @TrIds WHERE OwnerNode=@TrNameNode AND Part=0 AND (SELECT COUNT(*) FROM @TrIds WHERE OwnerNode=@TrNameNode)=2 AND Value<>OBJECT_SCHEMA_NAME(@TrId) COLLATE DATABASE_DEFAULT)
                OR NOT EXISTS(SELECT 1 FROM @TrIds WHERE OwnerNode=@TrOnNode AND Part=(SELECT MAX(Part) FROM @TrIds WHERE OwnerNode=@TrOnNode) AND Value=@SourceTable COLLATE DATABASE_DEFAULT)
                OR EXISTS(SELECT 1 FROM @TrIds WHERE OwnerNode=@TrOnNode AND Part=0 AND (SELECT COUNT(*) FROM @TrIds WHERE OwnerNode=@TrOnNode)=2 AND Value<>@SourceSchema COLLATE DATABASE_DEFAULT)
                THROW 53903,N'TableClone: Header-/ON-Identifier passen nicht zur Catalogbindung.',18;
            ;WITH Tree AS
            (
                SELECT NodeId,CONVERT(int,0) ScopeId,CONVERT(int,0) OuterScopeId,CONVERT(int,0) StatementId,CONVERT(int,0) CteId,CONVERT(bit,0) InOutput FROM #tbx_TableClone_AstNodes WHERE ParentNodeId IS NULL
                UNION ALL
                SELECT n.NodeId,CASE WHEN n.NodeType IN(N'QuerySpecification',N'InsertSpecification',N'UpdateSpecification',N'DeleteSpecification',N'MergeSpecification') THEN n.NodeId ELSE p.ScopeId END,
                    CASE WHEN n.NodeType IN(N'QuerySpecification',N'InsertSpecification',N'UpdateSpecification',N'DeleteSpecification',N'MergeSpecification') THEN p.ScopeId ELSE p.OuterScopeId END,
                    CASE WHEN n.NodeType IN(N'SelectStatement',N'InsertStatement',N'UpdateStatement',N'DeleteStatement',N'MergeStatement') THEN n.NodeId ELSE p.StatementId END,
                    CASE WHEN n.NodeType=N'CommonTableExpression' THEN n.NodeId ELSE p.CteId END,
                    CONVERT(bit,CASE WHEN n.NodeType IN(N'OutputClause',N'OutputIntoClause') THEN 1 ELSE p.InOutput END)
                FROM #tbx_TableClone_AstNodes n JOIN Tree p ON p.NodeId=n.ParentNodeId
            )
            INSERT @TrContext SELECT * FROM Tree OPTION(MAXRECURSION 100);
            IF (SELECT COUNT(*) FROM @TrContext)<>(SELECT COUNT(*) FROM #tbx_TableClone_AstNodes)
                THROW 53905,N'TableClone: unvollständige AST-Elternhierarchie.',4;
            INSERT @TrScopes VALUES(0,0,0,0);
            INSERT @TrScopes SELECT c.ScopeId,c.OuterScopeId,c.StatementId,c.CteId FROM @TrContext c WHERE c.NodeId=c.ScopeId;
            DECLARE @TrScopeChain TABLE(ScopeId int NOT NULL,VisibleScopeId int NOT NULL,Distance int NOT NULL,PRIMARY KEY(ScopeId,VisibleScopeId));
            DELETE @TrScopeChain;
            ;WITH Chain AS
            (
                SELECT ScopeId,ScopeId VisibleScopeId,CONVERT(int,0) Distance FROM @TrScopes
                UNION ALL SELECT c.ScopeId,s.OuterScopeId,c.Distance+1 FROM Chain c JOIN @TrScopes s ON s.ScopeId=c.VisibleScopeId WHERE c.VisibleScopeId<>0
            )
            INSERT @TrScopeChain SELECT * FROM Chain OPTION(MAXRECURSION 100);
            INSERT @TrCtes
                SELECT n.NodeId,c.StatementId,n.PropertyIndex,p.PropertyValue FROM #tbx_TableClone_AstNodes n JOIN @TrContext c ON c.NodeId=n.NodeId
                JOIN #tbx_TableClone_AstNodes i ON i.ParentNodeId=n.NodeId AND i.PropertyName=N'ExpressionName' AND i.NodeType=N'Identifier'
                JOIN #tbx_TableClone_AstProperties p ON p.NodeId=i.NodeId AND p.PropertyName=N'Value' AND p.PropertyKind=N'String'
                WHERE n.NodeType=N'CommonTableExpression';
            IF (SELECT COUNT(*) FROM @TrCtes)<>(SELECT COUNT(*) FROM #tbx_TableClone_AstNodes WHERE NodeType=N'CommonTableExpression')
                OR EXISTS(SELECT 1 FROM @TrCtes GROUP BY StatementId,Name HAVING COUNT(*)<>1)
                THROW 53903,N'TableClone: CTE-Namespace ist nicht eindeutig.',19;
            INSERT @TrReferences
                SELECT n.NodeId,c.ScopeId,c.StatementId,c.CteId,CASE n.PropertyName WHEN N'Target' THEN 1 ELSE 0 END,s.NodeId,
                    (SELECT COUNT(*) FROM @TrIds WHERE OwnerNode=s.NodeId),a.Value,b.Value,al.PropertyValue,NULL,0
                FROM #tbx_TableClone_AstNodes n JOIN @TrContext c ON c.NodeId=n.NodeId
                JOIN #tbx_TableClone_AstNodes s ON s.ParentNodeId=n.NodeId AND s.PropertyName=N'SchemaObject' AND s.NodeType=N'SchemaObjectName'
                JOIN @TrIds b ON b.OwnerNode=s.NodeId AND b.Part=(SELECT MAX(Part) FROM @TrIds WHERE OwnerNode=s.NodeId)
                LEFT JOIN @TrIds a ON a.OwnerNode=s.NodeId AND a.Part=0 AND b.Part=1
                LEFT JOIN #tbx_TableClone_AstNodes ali ON ali.ParentNodeId=n.NodeId AND ali.PropertyName=N'Alias' AND ali.NodeType=N'Identifier'
                LEFT JOIN #tbx_TableClone_AstProperties al ON al.NodeId=ali.NodeId AND al.PropertyName=N'Value' AND al.PropertyKind=N'String'
                WHERE n.NodeType=N'NamedTableReference';
            IF EXISTS(SELECT 1 FROM #tbx_TableClone_AstNodes n WHERE n.NodeType=N'SchemaObjectName' AND n.NodeId NOT IN(@TrNameNode,@TrOnNode)
                AND NOT EXISTS(SELECT 1 FROM @TrReferences r WHERE r.NameNode=n.NodeId)
                AND NOT EXISTS(SELECT 1 FROM #tbx_TableClone_AstNodes p WHERE p.NodeId=n.ParentNodeId AND p.NodeType=N'SchemaObjectFunctionTableReference')
                AND NOT EXISTS(SELECT 1 FROM #tbx_TableClone_AstNodes p JOIN #tbx_TableClone_AstProperties v ON v.NodeId=p.NodeId
                    WHERE p.NodeId=n.ParentNodeId AND p.NodeType=N'SqlDataTypeReference' AND n.PropertyName=N'Name'
                      AND (SELECT COUNT(*) FROM @TrIds i WHERE i.OwnerNode=n.NodeId)=1
                      AND v.PropertyName=N'SqlDataTypeOption' AND v.PropertyKind=N'Enum'
                      AND v.PropertyValue IN(N'BigInt',N'Int',N'SmallInt',N'TinyInt',N'Bit',N'Decimal',N'Numeric',N'Money',N'SmallMoney',N'Float',N'Real',N'DateTime',N'SmallDateTime',N'Char',N'VarChar',N'Text',N'NChar',N'NVarChar',N'NText',N'Binary',N'VarBinary',N'Image',N'Cursor',N'Sql_Variant',N'Table',N'Timestamp',N'UniqueIdentifier',N'Date',N'Time',N'DateTime2',N'DateTimeOffset',N'Rowversion',N'Json',N'Vector')))
                THROW 53903,N'TableClone: Objektname außerhalb einer belegten Tabellen-/Funktionsreferenz.',19;
            IF (SELECT COUNT(*) FROM @TrReferences)<>(SELECT COUNT(*) FROM #tbx_TableClone_AstNodes WHERE NodeType=N'NamedTableReference')
                OR EXISTS(SELECT 1 FROM @TrReferences WHERE Parts NOT IN(1,2) OR ScopeId=0)
                THROW 53903,N'TableClone: fehlende oder externe NamedTableReference-Bindung.',19;
            -- Eine CTE gilt nur im nächsten sichtbaren Statementnamespace; spätere CTEs sind nicht sichtbar.
            IF EXISTS(SELECT 1 FROM @TrReferences r CROSS APPLY
                (SELECT TOP(1) ct.CteOrdinal,ct.StatementId FROM @TrScopeChain h JOIN @TrScopes sc ON sc.ScopeId=h.VisibleScopeId
                 JOIN @TrCtes ct ON ct.StatementId=sc.StatementId AND ct.Name=r.TableName WHERE h.ScopeId=r.ScopeId ORDER BY h.Distance) visible
                JOIN @TrCtes own ON own.NodeId=r.CteId AND own.StatementId=visible.StatementId
                WHERE r.Parts=1 AND own.CteOrdinal<visible.CteOrdinal)
                THROW 53903,N'TableClone: Vorwärtsreferenz auf eine spätere CTE.',19;
            UPDATE r SET LocalReference=1 FROM @TrReferences r CROSS APPLY
                (SELECT TOP(1) ct.NodeId,ct.CteOrdinal,ct.StatementId FROM @TrScopeChain h JOIN @TrScopes sc ON sc.ScopeId=h.VisibleScopeId
                 JOIN @TrCtes ct ON ct.StatementId=sc.StatementId AND ct.Name=r.TableName WHERE h.ScopeId=r.ScopeId ORDER BY h.Distance) visible
                WHERE r.Parts=1 AND (r.CteId=0 OR NOT EXISTS(SELECT 1 FROM @TrCtes own WHERE own.NodeId=r.CteId AND own.StatementId=visible.StatementId AND own.CteOrdinal<visible.CteOrdinal));
            UPDATE r SET LocalReference=1 FROM @TrReferences r WHERE r.Parts=1 AND r.TableName IN(N'inserted',N'deleted');
            UPDATE r SET SourceId=m.SourceId FROM @TrReferences r JOIN #tbx_TableClone_Map m ON m.SourceTable=r.TableName AND (r.SchemaName IS NULL OR m.SourceSchema=r.SchemaName)
                WHERE r.LocalReference=0 AND r.IsTarget=0 AND EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d WHERE d.referencing_id=@TrId AND d.referenced_id=m.SourceId)
                AND (SELECT COUNT(*) FROM #tbx_TableClone_Map mm WHERE mm.SourceTable=r.TableName AND (r.SchemaName IS NULL OR mm.SourceSchema=r.SchemaName)
                    AND EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d WHERE d.referencing_id=@TrId AND d.referenced_id=mm.SourceId))=1;
            INSERT @TrRanges SELECT NodeId,ScopeId,COALESCE(AliasName,TableName),SourceId,CASE WHEN AliasName IS NULL THEN 0 ELSE 1 END FROM @TrReferences WHERE IsTarget=0;
            -- Lokale Tabellenvariablen und Derived-Table-/Funktionsaliase besitzen keinen permanenten Mapowner.
            INSERT @TrRanges
                SELECT n.NodeId,c.ScopeId,p.PropertyValue,NULL,1 FROM #tbx_TableClone_AstNodes n JOIN @TrContext c ON c.NodeId=n.NodeId
                JOIN #tbx_TableClone_AstNodes v ON v.ParentNodeId=n.NodeId AND v.NodeType=N'VariableReference' AND v.PropertyName=N'Variable'
                JOIN #tbx_TableClone_AstProperties p ON p.NodeId=v.NodeId AND p.PropertyName=N'Name' AND p.PropertyKind=N'String'
                WHERE n.NodeType=N'VariableTableReference' AND EXISTS
                    (SELECT 1 FROM #tbx_TableClone_AstNodes d JOIN #tbx_TableClone_AstNodes dv ON dv.ParentNodeId=d.NodeId AND dv.PropertyName=N'VariableName' AND dv.NodeType=N'Identifier'
                     JOIN #tbx_TableClone_AstProperties dp ON dp.NodeId=dv.NodeId AND dp.PropertyName=N'Value' AND dp.PropertyKind=N'String'
                     WHERE d.NodeType=N'DeclareTableVariableBody' AND dp.PropertyValue COLLATE DATABASE_DEFAULT=p.PropertyValue COLLATE DATABASE_DEFAULT AND d.StartOffset<n.StartOffset);
            -- Alias einer Tabellenvariablen ersetzt ihren Range-Namen, nicht die Variable selbst.
            UPDATE r SET Name=p.PropertyValue FROM @TrRanges r JOIN #tbx_TableClone_AstNodes a ON a.ParentNodeId=r.NodeId AND a.PropertyName=N'Alias' AND a.NodeType=N'Identifier'
                JOIN #tbx_TableClone_AstProperties p ON p.NodeId=a.NodeId AND p.PropertyName=N'Value' AND p.PropertyKind=N'String';
            INSERT @TrRanges
                SELECT n.NodeId,c.ScopeId,p.PropertyValue,NULL,1 FROM #tbx_TableClone_AstNodes n JOIN @TrContext c ON c.NodeId=n.NodeId
                JOIN #tbx_TableClone_AstNodes a ON a.ParentNodeId=n.NodeId AND a.PropertyName=N'Alias' AND a.NodeType=N'Identifier'
                JOIN #tbx_TableClone_AstProperties p ON p.NodeId=a.NodeId AND p.PropertyName=N'Value' AND p.PropertyKind=N'String'
                WHERE n.NodeType IN(N'QueryDerivedTable',N'InlineDerivedTable');
            INSERT @TrRanges
                SELECT DISTINCT n.NodeId,c.ScopeId,COALESCE(ap.PropertyValue COLLATE DATABASE_DEFAULT,b.Value),o.object_id,CASE WHEN ap.PropertyValue IS NULL THEN 0 ELSE 1 END
                FROM #tbx_TableClone_AstNodes n JOIN @TrContext c ON c.NodeId=n.NodeId
                JOIN #tbx_TableClone_AstNodes sn ON sn.ParentNodeId=n.NodeId AND sn.PropertyName=N'SchemaObject' AND sn.NodeType=N'SchemaObjectName'
                JOIN @TrIds b ON b.OwnerNode=sn.NodeId AND b.Part=(SELECT MAX(Part) FROM @TrIds WHERE OwnerNode=sn.NodeId)
                LEFT JOIN @TrIds sc ON sc.OwnerNode=sn.NodeId AND sc.Part=0 AND b.Part=1
                LEFT JOIN #tbx_TableClone_AstNodes a ON a.ParentNodeId=n.NodeId AND a.PropertyName=N'Alias' AND a.NodeType=N'Identifier'
                LEFT JOIN #tbx_TableClone_AstProperties ap ON ap.NodeId=a.NodeId AND ap.PropertyName=N'Value' AND ap.PropertyKind=N'String'
                JOIN sys.sql_expression_dependencies d ON d.referencing_id=@TrId
                JOIN sys.objects o ON o.object_id=d.referenced_id AND o.name=b.Value COLLATE DATABASE_DEFAULT
                    AND (sc.Value IS NULL OR OBJECT_SCHEMA_NAME(o.object_id)=sc.Value COLLATE DATABASE_DEFAULT)
                WHERE n.NodeType=N'SchemaObjectFunctionTableReference' AND (SELECT COUNT(*) FROM @TrIds WHERE OwnerNode=sn.NodeId) IN(1,2)
                    AND CONVERT(varbinary(2),o.type) IN(CONVERT(varbinary(2),'IF'),CONVERT(varbinary(2),'TF'))
                    AND NOT EXISTS(SELECT 1 FROM sys.sql_expression_dependencies dd JOIN sys.objects oo ON oo.object_id=dd.referenced_id
                        WHERE dd.referencing_id=@TrId AND oo.object_id<>o.object_id AND oo.name=b.Value COLLATE DATABASE_DEFAULT
                          AND (sc.Value IS NULL OR OBJECT_SCHEMA_NAME(oo.object_id)=sc.Value COLLATE DATABASE_DEFAULT));
            IF EXISTS(SELECT 1 FROM #tbx_TableClone_AstNodes n WHERE n.NodeType IN(N'VariableTableReference',N'QueryDerivedTable',N'InlineDerivedTable',N'SchemaObjectFunctionTableReference') AND NOT EXISTS(SELECT 1 FROM @TrRanges WHERE NodeId=n.NodeId))
                OR EXISTS(SELECT 1 FROM #tbx_TableClone_AstNodes WHERE NodeType LIKE N'%TableReference' AND NodeType NOT IN(N'NamedTableReference',N'VariableTableReference',N'SchemaObjectFunctionTableReference'))
                OR EXISTS(SELECT 1 FROM @TrRanges GROUP BY ScopeId,Name HAVING COUNT(*)<>1)
                THROW 53903,N'TableClone: lokale TableReference oder Rangealias nicht eindeutig belegt.',19;
            -- UPDATE/DELETE-Aliastargets binden an den FROM-Scope, niemals an eine gleichnamige permanente Tabelle.
            UPDATE t SET LocalReference=CASE WHEN r.Alias=1 OR r.SourceId IS NULL THEN 1 ELSE 0 END,SourceId=r.SourceId FROM @TrReferences t JOIN @TrRanges r ON r.ScopeId=t.ScopeId AND r.Name=t.TableName
                WHERE t.IsTarget=1 AND t.Parts=1 AND t.AliasName IS NULL;
            UPDATE t SET SourceId=m.SourceId FROM @TrReferences t JOIN #tbx_TableClone_Map m ON m.SourceTable=t.TableName AND (t.SchemaName IS NULL OR m.SourceSchema=t.SchemaName)
                WHERE t.IsTarget=1 AND t.LocalReference=0 AND EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d WHERE d.referencing_id=@TrId AND d.referenced_id=m.SourceId)
                AND (SELECT COUNT(*) FROM #tbx_TableClone_Map mm WHERE mm.SourceTable=t.TableName AND (t.SchemaName IS NULL OR mm.SourceSchema=t.SchemaName)
                    AND EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d WHERE d.referencing_id=@TrId AND d.referenced_id=mm.SourceId))=1;
            IF EXISTS(SELECT 1 FROM @TrReferences WHERE LocalReference=0 AND SourceId IS NULL)
                THROW 53903,N'TableClone: permanente Tabellenbindung fehlt oder liegt außerhalb der Map.',20;
            INSERT @TrRanges SELECT NodeId,ScopeId,COALESCE(AliasName,TableName),SourceId,CASE WHEN AliasName IS NULL THEN 0 ELSE 1 END FROM @TrReferences t WHERE IsTarget=1
                AND NOT EXISTS(SELECT 1 FROM @TrRanges r WHERE r.ScopeId=t.ScopeId AND (r.Name=COALESCE(t.AliasName,t.TableName) OR r.SourceId=t.SourceId));
            -- Header-/Tabellenidentifier werden einzeln ersetzt; Punkt, Kommentare und Whitespace bleiben erhalten.
            INSERT @TrEdits SELECT i.StartOffset,i.Length,CASE WHEN (SELECT COUNT(*) FROM @TrIds WHERE OwnerNode=@TrNameNode)=1 THEN QUOTENAME(@TargetSchema)+N'.'+QUOTENAME(@TrName)
                WHEN i.Part=0 THEN QUOTENAME(@TargetSchema) ELSE QUOTENAME(@TrName) END FROM @TrIds i WHERE i.OwnerNode=@TrNameNode;
            INSERT @TrEdits SELECT i.StartOffset,i.Length,CASE WHEN (SELECT COUNT(*) FROM @TrIds WHERE OwnerNode=@TrOnNode)=1 THEN QUOTENAME(@TargetSchema)+N'.'+QUOTENAME(@TargetTable)
                WHEN i.Part=0 THEN QUOTENAME(@TargetSchema) ELSE QUOTENAME(@TargetTable) END FROM @TrIds i WHERE i.OwnerNode=@TrOnNode;
            INSERT @TrEdits SELECT i.StartOffset,i.Length,CASE WHEN r.Parts=1 THEN QUOTENAME(m.TargetSchema)+N'.'+QUOTENAME(m.TargetTable) WHEN i.Part=0 THEN QUOTENAME(m.TargetSchema) ELSE QUOTENAME(m.TargetTable) END
                FROM @TrReferences r JOIN #tbx_TableClone_Map m ON m.SourceId=r.SourceId JOIN @TrIds i ON i.OwnerNode=r.NameNode WHERE r.LocalReference=0;
            -- Mehrteilige Spaltennamen benötigen eine konkrete nächste sichtbare Rangebindung.
            DECLARE @TrColumnNode int,@TrColumnScope int,@TrColumnParts int,@TrQualifier nvarchar(128),@TrColumnSchema nvarchar(128),@TrBoundId int,@TrBoundAlias bit,@TrBindDistance int,@TrInOutput bit;
            DECLARE ColumnQualifierCursor CURSOR LOCAL FAST_FORWARD FOR
                SELECT n.NodeId,c.ScopeId,k.Parts,i.Value,s.Value,c.InOutput FROM #tbx_TableClone_AstNodes n
                JOIN #tbx_TableClone_AstNodes p ON p.NodeId=n.ParentNodeId AND p.NodeType IN(N'ColumnReferenceExpression',N'SelectStarExpression')
                CROSS APPLY(SELECT (SELECT COUNT(*) FROM @TrIds WHERE OwnerNode=n.NodeId)+CASE p.NodeType WHEN N'SelectStarExpression' THEN 1 ELSE 0 END Parts) k
                JOIN @TrContext c ON c.NodeId=n.NodeId JOIN @TrIds i ON i.OwnerNode=n.NodeId AND i.Part=k.Parts-2
                LEFT JOIN @TrIds s ON s.OwnerNode=n.NodeId AND s.Part=0 AND i.Part=1
                WHERE n.NodeType=N'MultiPartIdentifier' AND k.Parts>1;
            OPEN ColumnQualifierCursor;
            FETCH NEXT FROM ColumnQualifierCursor INTO @TrColumnNode,@TrColumnScope,@TrColumnParts,@TrQualifier,@TrColumnSchema,@TrInOutput;
            WHILE @@FETCH_STATUS=0
            BEGIN
                IF @TrInOutput=1 AND @TrColumnParts=2 AND @TrQualifier COLLATE DATABASE_DEFAULT IN(N'inserted',N'deleted')
                BEGIN
                    FETCH NEXT FROM ColumnQualifierCursor INTO @TrColumnNode,@TrColumnScope,@TrColumnParts,@TrQualifier,@TrColumnSchema,@TrInOutput;
                    CONTINUE;
                END;
                SELECT @TrBoundId=NULL,@TrBoundAlias=NULL,@TrBindDistance=NULL;
                SELECT @TrBindDistance=MIN(h.Distance) FROM @TrScopeChain h JOIN @TrRanges r ON r.ScopeId=h.VisibleScopeId LEFT JOIN #tbx_TableClone_Map m ON m.SourceId=r.SourceId
                    WHERE h.ScopeId=@TrColumnScope AND ((@TrColumnParts=2 AND r.Name=@TrQualifier COLLATE DATABASE_DEFAULT)
                        OR (@TrColumnParts=3 AND r.Alias=0 AND COALESCE(m.SourceSchema,OBJECT_SCHEMA_NAME(r.SourceId))=@TrColumnSchema COLLATE DATABASE_DEFAULT AND COALESCE(m.SourceTable,OBJECT_NAME(r.SourceId))=@TrQualifier COLLATE DATABASE_DEFAULT));
                IF @TrColumnParts NOT IN(2,3) OR @TrBindDistance IS NULL
                    OR (SELECT COUNT(*) FROM @TrScopeChain h JOIN @TrRanges r ON r.ScopeId=h.VisibleScopeId LEFT JOIN #tbx_TableClone_Map m ON m.SourceId=r.SourceId
                        WHERE h.ScopeId=@TrColumnScope AND h.Distance=@TrBindDistance AND ((@TrColumnParts=2 AND r.Name=@TrQualifier COLLATE DATABASE_DEFAULT)
                        OR (@TrColumnParts=3 AND r.Alias=0 AND COALESCE(m.SourceSchema,OBJECT_SCHEMA_NAME(r.SourceId))=@TrColumnSchema COLLATE DATABASE_DEFAULT AND COALESCE(m.SourceTable,OBJECT_NAME(r.SourceId))=@TrQualifier COLLATE DATABASE_DEFAULT)))<>1
                    THROW 53903,N'TableClone: Spaltenqualifier ist extern, ungelöst oder mehrdeutig.',21;
                SELECT @TrBoundId=r.SourceId,@TrBoundAlias=r.Alias FROM @TrScopeChain h JOIN @TrRanges r ON r.ScopeId=h.VisibleScopeId LEFT JOIN #tbx_TableClone_Map m ON m.SourceId=r.SourceId
                    WHERE h.ScopeId=@TrColumnScope AND h.Distance=@TrBindDistance AND ((@TrColumnParts=2 AND r.Name=@TrQualifier COLLATE DATABASE_DEFAULT)
                        OR (@TrColumnParts=3 AND r.Alias=0 AND COALESCE(m.SourceSchema,OBJECT_SCHEMA_NAME(r.SourceId))=@TrColumnSchema COLLATE DATABASE_DEFAULT AND COALESCE(m.SourceTable,OBJECT_NAME(r.SourceId))=@TrQualifier COLLATE DATABASE_DEFAULT));
                IF @TrBoundId IS NOT NULL AND @TrBoundAlias=0
                    INSERT @TrEdits SELECT i.StartOffset,i.Length,CASE WHEN @TrColumnParts=3 AND i.Part=0 THEN QUOTENAME(m.TargetSchema) ELSE QUOTENAME(m.TargetTable) END
                        FROM @TrIds i JOIN #tbx_TableClone_Map m ON m.SourceId=@TrBoundId WHERE i.OwnerNode=@TrColumnNode AND i.Part<@TrColumnParts-1;
                FETCH NEXT FROM ColumnQualifierCursor INTO @TrColumnNode,@TrColumnScope,@TrColumnParts,@TrQualifier,@TrColumnSchema,@TrInOutput;
            END;
            CLOSE ColumnQualifierCursor; DEALLOCATE ColumnQualifierCursor;
            -- Nur Headerkeywords ändern; Kommentare zwischen CREATE/OR/ALTER bleiben unberührt.
            IF (SELECT COUNT(*) FROM #tbx_TableClone_AstTokens WHERE StartOffset<(SELECT MIN(StartOffset) FROM @TrIds WHERE OwnerNode=@TrNameNode) AND TokenType NOT IN(N'WhiteSpace',N'SingleLineComment',N'MultilineComment') AND TokenType NOT IN(N'Create',N'Or',N'Alter',N'Trigger'))<>0
                THROW 53903,N'TableClone: Triggerheader enthält unbekannte Lexeme.',17;
            INSERT @TrEdits SELECT t.StartOffset,DATALENGTH(t.TokenText)/2,CASE WHEN t.TokenType=N'Alter' AND NOT EXISTS(SELECT 1 FROM #tbx_TableClone_AstTokens WHERE TokenType=N'Create' AND StartOffset<t.StartOffset) THEN N'CREATE' ELSE N'' END
                FROM #tbx_TableClone_AstTokens t WHERE t.StartOffset<(SELECT MIN(StartOffset) FROM @TrIds WHERE OwnerNode=@TrNameNode) AND t.TokenType IN(N'Or',N'Alter');
            IF EXISTS(SELECT 1 FROM @TrEdits a JOIN @TrEdits b ON a.StartOffset<b.StartOffset AND CONVERT(bigint,a.StartOffset)+a.Length>b.StartOffset)
                THROW 53905,N'TableClone: überlappende Rewritefragmente.',5;
            SET @TrRewritten=@TrDefinition;
            DECLARE @TrOffset int,@TrLength int,@TrReplacement nvarchar(max);
            DECLARE RewriteCursor CURSOR LOCAL FAST_FORWARD FOR SELECT StartOffset,Length,Replacement FROM @TrEdits ORDER BY StartOffset DESC;
            OPEN RewriteCursor;
            FETCH NEXT FROM RewriteCursor INTO @TrOffset,@TrLength,@TrReplacement;
            WHILE @@FETCH_STATUS=0
            BEGIN
                SET @TrRewritten=STUFF(@TrRewritten COLLATE Latin1_General_100_BIN2,@TrOffset+1,@TrLength,@TrReplacement);
                FETCH NEXT FROM RewriteCursor INTO @TrOffset,@TrLength,@TrReplacement;
            END;
            CLOSE RewriteCursor; DEALLOCATE RewriteCursor;
            DELETE #tbx_TableClone_AstErrors;
            EXEC sys.sp_executesql N'INSERT #tbx_TableClone_AstErrors SELECT * FROM toolbelt_tsql.TVF_ParseScriptErrors(@s,@v,@q,2097152,100);',N'@s nvarchar(max),@v int,@q bit',@TrRewritten,@TrVersion,@TrQi;
            IF EXISTS(SELECT 1 FROM #tbx_TableClone_AstErrors) THROW 53905,N'TableClone: umgeschriebener Trigger enthält Parserfehler.',6;
            IF (SELECT COUNT(*) FROM sys.trigger_events WHERE object_id=@TrId AND type_desc IN(N'INSERT',N'UPDATE',N'DELETE'))
                <>(SELECT COUNT(*) FROM #tbx_TableClone_AstNodes n JOIN #tbx_TableClone_AstProperties p ON p.NodeId=n.NodeId AND p.PropertyName=N'TriggerActionType' WHERE n.ParentNodeId=@TrRoot AND n.NodeType=N'TriggerAction')
                OR EXISTS(SELECT 1 FROM sys.trigger_events e WHERE e.object_id=@TrId AND NOT EXISTS
                    (SELECT 1 FROM #tbx_TableClone_AstNodes n JOIN #tbx_TableClone_AstProperties p ON p.NodeId=n.NodeId AND p.PropertyName=N'TriggerActionType' AND p.PropertyKind=N'Enum'
                     WHERE n.ParentNodeId=@TrRoot AND n.NodeType=N'TriggerAction' AND UPPER(p.PropertyValue) COLLATE DATABASE_DEFAULT=e.type_desc COLLATE DATABASE_DEFAULT))
                THROW 53903,N'TableClone: AST- und Katalogereignisse stimmen nicht überein.',22;
            -- Die feste Kapselung ist kein dynamisches SQL im Triggerbody und führt hier nichts aus.
            SET @TrScript=CONVERT(nvarchar(max),N'SET ANSI_NULLS ')+CASE @TrAnsi WHEN 1 THEN N'ON' ELSE N'OFF' END+N';'+NCHAR(10)
                +N'SET QUOTED_IDENTIFIER '+CASE @TrQi WHEN 1 THEN N'ON' ELSE N'OFF' END+N';'+NCHAR(10)
                +N'EXEC sys.sp_executesql N'''+REPLACE(@TrRewritten,N'''',N'''''')+N''';';
            SET @TrOrdinal=COALESCE((SELECT MAX(Ordinal) FROM #tbx_TableClone_Plan),0)+1;
            INSERT #tbx_TableClone_Plan VALUES(@TrOrdinal,'TRIGGER',@TargetName,@TrScript);
            IF @TrInstead=0
                INSERT @TrStates SELECT @MapOrdinal,@TrOriginalName,@TargetName,CASE e.type_desc WHEN N'INSERT' THEN 1 WHEN N'UPDATE' THEN 2 ELSE 3 END,
                    CONVERT(nvarchar(max),N'EXEC sys.sp_settriggerorder @triggername=N''')+REPLACE(@TargetName,N'''',N'''''')+N''',@order=N'''+CASE e.is_first WHEN 1 THEN N'First' ELSE N'Last' END+N''',@stmttype=N'''+e.type_desc+N''';'
                    FROM sys.trigger_events e WHERE e.object_id=@TrId AND (e.is_first=1 OR e.is_last=1);
            IF @TrDisabled=1 INSERT @TrStates VALUES(@MapOrdinal,@TrOriginalName,@TargetName,4,N'DISABLE TRIGGER '+@TargetName+N' ON '+QUOTENAME(@TargetSchema)+N'.'+QUOTENAME(@TargetTable)+N';');
            IF (SELECT SUM(CONVERT(bigint,DATALENGTH(ScriptText))) FROM #tbx_TableClone_Plan)+(SELECT COALESCE(SUM(CONVERT(bigint,DATALENGTH(ScriptText))),0) FROM @TrStates)>2097152
                THROW 53906,N'TableClone: Triggerwrapper und Zustände überschreiten die Scriptquote.',2;
            FETCH NEXT FROM TriggerCursor INTO @MapOrdinal,@SourceId,@TargetSchemaId,@SourceSchema,@SourceTable,@TargetSchema,@TargetTable,@TrId,@TrOriginalName,@TrDisabled,@TrInstead,@TrNfr,@TrAnsi,@TrQi,@TrDefinition;
        END;
        CLOSE TriggerCursor; DEALLOCATE TriggerCursor;
        SET @TrOrdinal=COALESCE((SELECT MAX(Ordinal) FROM #tbx_TableClone_Plan),0);
        INSERT #tbx_TableClone_Plan SELECT @TrOrdinal+ROW_NUMBER() OVER(ORDER BY CASE WHEN EventOrdinal=4 THEN 1 ELSE 0 END,MapOrdinal,OriginalName,CONVERT(varbinary(256),OriginalName),EventOrdinal),
            'TRIGGER_STATE',TargetName,ScriptText FROM @TrStates;
    END;
    IF EXISTS(SELECT 1 FROM #tbx_TableClone_Plan WHERE DATALENGTH(ScriptText)>2097152)
       OR (SELECT SUM(CONVERT(bigint,DATALENGTH(ScriptText))) FROM #tbx_TableClone_Plan)>2097152
        THROW 53906,N'TableClone: Vorschau überschreitet2MiB Scripttext.',2;
    IF @Debug>0 RAISERROR(N'TableClone: vollständiger Script-only-Plan bereit; keine Ausführung.',10,1) WITH NOWAIT;
    IF @ResultTable IS NULL
    BEGIN
        SELECT Ordinal,ObjectKind,TargetName,ScriptText FROM #tbx_TableClone_Plan ORDER BY Ordinal;
        RETURN;
    END;
    DECLARE @DependencyVersion nvarchar(64),@DependencyId int=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P');
    SELECT @DependencyVersion=TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties
        WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.result-table.Version';
    DECLARE @Major int=TRY_CONVERT(int,PARSENAME(@DependencyVersion,3)),@Minor int=TRY_CONVERT(int,PARSENAME(@DependencyVersion,2)),@Patch int=TRY_CONVERT(int,PARSENAME(@DependencyVersion,1));
    IF @DependencyId IS NULL OR @Major IS NULL OR @Major<1 OR @Minor IS NULL OR @Minor<0 OR @Patch IS NULL OR @Patch<0
       OR CONVERT(varbinary(max),@DependencyVersion)<>CONVERT(varbinary(max),CONCAT(@Major,N'.',@Minor,N'.',@Patch))
       OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@DependencyId AND name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'toolbelt.core.result-table'))
       OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@DependencyId AND name=N'Toolbelt.ModuleVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(64),value))=CONVERT(varbinary(max),@DependencyVersion))
        THROW 53907,N'TableClone: registrierte ResultTable-Dependency >=1.0.0 fehlt.',1;
    DECLARE @Own bit=CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END,@Savepoint varchar(32)=REPLACE(CONVERT(varchar(36),NEWID()),'-',''),@Saved bit=0;
    BEGIN TRY
        IF @Own=1 BEGIN TRANSACTION;
        ELSE BEGIN SAVE TRANSACTION @Savepoint; SET @Saved=1; END;
        EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,
            @LikeTable=N'#tbx_TableClone_Plan',@KeepData=@KeepData,@Debug=@Debug;
        DECLARE @WriteSql nvarchar(max)=N'INSERT '+QUOTENAME(@ResultTable)+N' (Ordinal,ObjectKind,TargetName,ScriptText) SELECT Ordinal,ObjectKind,TargetName,ScriptText FROM #tbx_TableClone_Plan;';
        EXEC sys.sp_executesql @WriteSql;
        IF @Own=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @Own=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        ELSE IF @Saved=1 AND XACT_STATE()=1 ROLLBACK TRANSACTION @Savepoint;
        THROW;
    END CATCH;
END;
GO

