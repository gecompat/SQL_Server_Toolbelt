-- Kanonischer Catalog-/Scriptkern; keine Ausführung des erzeugten Scripttexts.
-- Interner Aufruf ausschließlich über öffentliche Namespace-/Helpgrenze.
-- Definitionen werden wörtlich erhalten, kein Parser oder neue Scalar-Funktion.
CREATE OR ALTER PROCEDURE toolbelt_metadata.USP_ScriptTableCloneInternal
    @SourceSchema nvarchar(max)=NULL,@SourceTable nvarchar(max)=NULL,
    @TargetSchema nvarchar(max)=NULL,@TargetTable nvarchar(max)=NULL,
    @IncludeIdentity bit=0,@IncludeExtendedProperties bit=0,@ResultTable sysname=NULL,@KeepData bit=0,
    @Debug tinyint=0,@Hilfe bit=0
AS
BEGIN
    SET NOCOUNT ON;
    IF @Hilfe=1
    BEGIN
        EXEC toolbelt_metadata.USP_ScriptTableClone @Hilfe=1;
        RETURN;
    END;
    SELECT @KeepData=COALESCE(@KeepData,0),@Debug=COALESCE(@Debug,0);
    -- Vollständige incoming-FK- und Kollisionssicht darf nicht aus gefilterten Katalogen behauptet werden.
    IF COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1
        THROW 53901,N'TableClone: datenbankweite VIEW DEFINITION für vollständige Struktursicht erforderlich.',2;
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
    DECLARE @SourceName nvarchar(776)=QUOTENAME(@SourceSchema)+N'.'+QUOTENAME(@SourceTable),
        @TargetName nvarchar(776)=QUOTENAME(@TargetSchema)+N'.'+QUOTENAME(@TargetTable),
        @SourceId int,@TargetSchemaId int=SCHEMA_ID(@TargetSchema),@Message nvarchar(2048);
    SELECT @SourceId=t.object_id FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id
        WHERE s.name=@SourceSchema COLLATE DATABASE_DEFAULT AND t.name=@SourceTable COLLATE DATABASE_DEFAULT;
    IF @SourceId IS NULL OR HAS_PERMS_BY_NAME(@SourceName,N'OBJECT',N'VIEW DEFINITION')<>1
        THROW 53901,N'TableClone: Quelle fehlt, ist keine Tabelle oder vollständige Metadatensicht fehlt.',1;
    IF @TargetSchemaId IS NULL OR HAS_PERMS_BY_NAME(QUOTENAME(@TargetSchema),N'SCHEMA',N'VIEW DEFINITION')<>1
        THROW 53902,N'TableClone: Zielschema fehlt oder vollständige Kollisionssicht fehlt.',1;
    IF EXISTS(SELECT 1 FROM sys.objects WHERE schema_id=@TargetSchemaId AND name=@TargetTable COLLATE DATABASE_DEFAULT)
        THROW 53902,N'TableClone: Zielname existiert bereits.',2;
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
    IF EXISTS(SELECT 1 FROM sys.triggers WHERE parent_id=@SourceId)
       OR EXISTS(SELECT 1 FROM sys.foreign_keys WHERE parent_object_id=@SourceId OR referenced_object_id=@SourceId)
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

    CREATE TABLE #tbx_TableClone_Plan
        (Ordinal int NOT NULL,ObjectKind varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,
         TargetName nvarchar(776) COLLATE Latin1_General_100_BIN2 NOT NULL,
         ScriptText nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL);
    DECLARE @ColumnDdl nvarchar(max),@TableDdl nvarchar(max),@Filegroup sysname,@LobFilegroup sysname;
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
        INSERT #tbx_TableClone_Plan
    SELECT n,'SESSION_OPTION',@TargetName,Statement FROM (VALUES
       (1,N'SET ANSI_NULLS ON;'),(2,N'SET ANSI_PADDING ON;'),(3,N'SET ANSI_WARNINGS ON;'),
       (4,N'SET ARITHABORT ON;'),(5,N'SET CONCAT_NULL_YIELDS_NULL ON;'),
       (6,N'SET QUOTED_IDENTIFIER ON;'),(7,N'SET NUMERIC_ROUNDABORT OFF;')) options(n,Statement);
    INSERT #tbx_TableClone_Plan VALUES(8,'TABLE',@TargetName,@TableDdl);
    DECLARE @Objects TABLE(SortKind int NOT NULL,SourceOrdinal int NOT NULL,ObjectKind varchar(32) NOT NULL,
        GeneratedName sysname NOT NULL,ScriptText nvarchar(max) NOT NULL,SourceObjectId int NULL,SourceIndexId int NULL);
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
        SELECT 8+ROW_NUMBER() OVER(ORDER BY SortKind,SourceOrdinal),ObjectKind,
            CASE WHEN ObjectKind='INDEX' THEN @TargetName+N'.'+QUOTENAME(GeneratedName)
                 ELSE QUOTENAME(@TargetSchema)+N'.'+QUOTENAME(GeneratedName) END,ScriptText FROM @Objects;
    IF @IncludeExtendedProperties=1
    BEGIN
        -- Ownerzuordnung verwendet dieselben erzeugten Namen wie der DDL-Plan.
        -- Explizite Nullability: Tabellenowner besitzen kein Level2, unabhängig von Caller-/DB-Defaults.
        DECLARE @Owners TABLE(Class int NOT NULL,MajorId int NOT NULL,MinorId int NOT NULL,SortKind int NOT NULL,SourceOrdinal int NOT NULL,
            Level1Type nvarchar(16) NOT NULL,Level1Name sysname NOT NULL,Level2Type nvarchar(16) NULL,Level2Name sysname NULL,TargetName nvarchar(776) NOT NULL);
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
        DECLARE @EpName sysname,@EpValue sql_variant,@EpBase sysname,@EpPrecision int,@EpScale int,@EpLength int,@EpCollation sysname,
            @EpL1Type nvarchar(16),@EpL1Name sysname,@EpL2Type nvarchar(16),@EpL2Name sysname,@EpTarget nvarchar(776),
            @EpType nvarchar(512),@EpLiteral nvarchar(max),@EpExpression nvarchar(max),@EpDdl nvarchar(max),
            @EpOrdinal int=(SELECT MAX(Ordinal) FROM #tbx_TableClone_Plan),@PlanBytes bigint=(SELECT SUM(CONVERT(bigint,DATALENGTH(ScriptText))) FROM #tbx_TableClone_Plan);
        DECLARE PropertyCursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT e.name,e.value,o.Level1Type,o.Level1Name,o.Level2Type,o.Level2Name,o.TargetName
            FROM @Owners o JOIN sys.extended_properties e ON e.class=o.Class AND e.major_id=o.MajorId AND e.minor_id=o.MinorId
            ORDER BY o.SortKind,o.SourceOrdinal,e.name COLLATE Latin1_General_100_BIN2,CONVERT(varbinary(256),e.name);
        OPEN PropertyCursor;
        FETCH NEXT FROM PropertyCursor INTO @EpName,@EpValue,@EpL1Type,@EpL1Name,@EpL2Type,@EpL2Name,@EpTarget;
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
                N',@level0type=N''SCHEMA'',@level0name=N'''+REPLACE(@TargetSchema,N'''',N'''''')+N''',@level1type=N'''+@EpL1Type+
                N''',@level1name=N'''+REPLACE(@EpL1Name,N'''',N'''''')+N''''+
                CASE WHEN @EpL2Type IS NULL THEN N'' ELSE N',@level2type=N'''+@EpL2Type+N''',@level2name=N'''+REPLACE(@EpL2Name,N'''',N'''''')+N'''' END+N';';
            SET @PlanBytes+=CONVERT(bigint,DATALENGTH(@EpDdl));
            IF @PlanBytes>2097152 THROW 53906,N'TableClone: Vorschau überschreitet2MiB Scripttext.',2;
            INSERT #tbx_TableClone_Plan VALUES(@EpOrdinal,'EXTENDED_PROPERTY',@EpTarget,@EpDdl);
            FETCH NEXT FROM PropertyCursor INTO @EpName,@EpValue,@EpL1Type,@EpL1Name,@EpL2Type,@EpL2Name,@EpTarget;
        END;
        CLOSE PropertyCursor; DEALLOCATE PropertyCursor;
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
