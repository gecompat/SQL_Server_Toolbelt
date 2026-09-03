-- ============================================================================
-- Objekt:          toolbelt_glc.USP_RewriteScriptToGlcGuids
-- Typ:             Stored Procedure (Betriebsintern)
-- Zweck:           Transformiert ein T-SQL-Statement in GLC-GUID-Tags unter
--                  Berücksichtigung von:
--                  1. GlobalCatalog-Lookups (DB, Schema, Tabelle, Spalte)
--                  2. Mandanten-Präfix-Entfernung (z. B. R00_META_DELIVERY -> META_DELIVERY)
--                  3. Synonym-Auflösung (z. B. md_adb.Ausfallkennzeichen -> META_DELIVERY.adb.Ausfallkennzeichen)
--                  4. Tag-Modifikatoren (,syn, ,_, ,.)
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF SCHEMA_ID(N'toolbelt_glc') IS NULL
    EXEC sys.sp_executesql N'CREATE SCHEMA [toolbelt_glc];';
GO

CREATE OR ALTER PROCEDURE [toolbelt_glc].[USP_RewriteScriptToGlcGuids]
(
      @SqlText            nvarchar(max)
    , @CatalogTable       nvarchar(512) = N'[glc].[GlobalCatalog]'
    , @SynonymSourceDb    sysname       = NULL
    , @CurrentDatabase    sysname       = NULL
    , @DefaultDatabase    nvarchar(128) = NULL
    , @DefaultSchema      nvarchar(128) = N'dbo'
    , @RewrittenSql       nvarchar(max) = NULL OUTPUT
    , @Debug              bit           = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ContextDb sysname = COALESCE(@CurrentDatabase, DB_NAME());
    DECLARE @SynDb     sysname = COALESCE(@SynonymSourceDb, @ContextDb);

    -- 1. Tabellen- und Spaltenreferenzen aus dem generischen AST-Parser extrahieren
    DECLARE @Tables TABLE
    (
          TableNodeId                 int
        , ServerName                  sysname NULL
        , DatabaseName                sysname NULL
        , SchemaName                  sysname NULL
        , ObjectName                  sysname
        , FormattedObjectNameQuoted   nvarchar(512)
        , FormattedObjectNameUnquoted nvarchar(512)
        , AliasName                   sysname NULL
        , AliasQuoteType              nvarchar(32) NULL
        , AliasTokenIndex             int NULL
        , SchemaObjectFirstTokenIndex int
        , SchemaObjectLastTokenIndex  int
        , DatabaseTokenIndex          int NULL
        , SchemaTokenIndex            int NULL
        , ObjectTokenIndex            int NULL
    );

    INSERT INTO @Tables
    SELECT * FROM toolbelt_tsql.TVF_ExtractScriptTableReferences(@SqlText, NULL, NULL, NULL, NULL);

    DECLARE @Columns TABLE
    (
          ColRefNodeId                int
        , TotalParts                  int
        , TableOrAliasQualifier       sysname NULL
        , ColumnName                  sysname
        , ColumnQuoteType             nvarchar(32)
        , ColumnTokenIndex            int
        , QualifierTokenIndex         int NULL
        , StartOffset                 int
        , FragmentLength              int
        , FirstTokenIndex             int
        , LastTokenIndex              int
    );

    INSERT INTO @Columns
    SELECT * FROM toolbelt_tsql.TVF_ExtractScriptColumnReferences(@SqlText, NULL, NULL, NULL, NULL);

    -- 2. Synonym-Auflösung aus der angegebenen Synonym-Datenbank (z. B. R00_BASIS)
    CREATE TABLE #SynonymLookup
    (
          SynonymSchemaName   sysname
        , SynonymName         sysname
        , BaseDatabaseName    sysname NULL
        , BaseSchemaName      sysname NULL
        , BaseObjectNameOnly  sysname NULL
    );

    DECLARE @SqlSynLookup nvarchar(max) = N'
    INSERT INTO #SynonymLookup (SynonymSchemaName, SynonymName, BaseDatabaseName, BaseSchemaName, BaseObjectNameOnly)
    SELECT 
          sch.name AS SynonymSchemaName
        , s.name AS SynonymName
        , PARSENAME(s.base_object_name, 3) AS BaseDatabaseName
        , PARSENAME(s.base_object_name, 2) AS BaseSchemaName
        , PARSENAME(s.base_object_name, 1) AS BaseObjectNameOnly
    FROM ' + QUOTENAME(@SynDb) + N'.sys.synonyms AS s
    JOIN ' + QUOTENAME(@SynDb) + N'.sys.schemas AS sch ON sch.schema_id = s.schema_id;
    ';

    EXEC sys.sp_executesql @SqlSynLookup;

    -- 3. Tabellen auflösen und Mandanten-Präfixe analysieren
    CREATE TABLE #ResolvedTables
    (
          TableNodeId                 int
        , OrigDatabaseName            sysname NULL
        , OrigSchemaName              sysname NULL
        , OrigObjectName              sysname
        , IsSynonym                   bit
        , TargetDatabaseName          sysname NULL
        , TargetSchemaName            sysname NULL
        , TargetObjectName            sysname
        , TenantPrefix                nvarchar(32) NULL
        , NormalizedDatabaseName      sysname NULL
        , IsCurrentTenant             bit
        , HasTenantPrefix             bit
        , AliasName                   sysname NULL
        , AliasQuoteType              nvarchar(32) NULL
        , AliasTokenIndex             int NULL
        , DatabaseTokenIndex          int NULL
        , SchemaTokenIndex            int NULL
        , ObjectTokenIndex            int NULL
    );

    INSERT INTO #ResolvedTables
    SELECT
          t.TableNodeId
        , t.DatabaseName
        , t.SchemaName
        , t.ObjectName
        , CASE WHEN syn.SynonymName IS NOT NULL THEN 1 ELSE 0 END AS IsSynonym
        , COALESCE(syn.BaseDatabaseName, t.DatabaseName, @DefaultDatabase) AS TargetDatabaseName
        , COALESCE(syn.BaseSchemaName, t.SchemaName, @DefaultSchema) AS TargetSchemaName
        , COALESCE(syn.BaseObjectNameOnly, t.ObjectName) AS TargetObjectName
        , tp.TenantPrefix
        , tp.NormalizedDatabaseName
        , tp.IsCurrentTenant
        , tp.HasTenantPrefix
        , t.AliasName
        , t.AliasQuoteType
        , t.AliasTokenIndex
        , t.DatabaseTokenIndex
        , t.SchemaTokenIndex
        , t.ObjectTokenIndex
    FROM @Tables AS t
    LEFT JOIN #SynonymLookup AS syn
        ON syn.SynonymName = t.ObjectName
       AND (syn.SynonymSchemaName = t.SchemaName OR t.SchemaName IS NULL)
    CROSS APPLY toolbelt_glc.TVF_ParseTenantDatabaseName(
          COALESCE(syn.BaseDatabaseName, t.DatabaseName, @DefaultDatabase)
        , @ContextDb
    ) AS tp;

    -- 4. GlobalCatalog-Match
    CREATE TABLE #ResolvedCatalog
    (
          TableNodeId                 int
        , TableGuid                   nvarchar(64)
        , SchemaGuid                  nvarchar(64)
        , DbGuid                      nvarchar(64)
        , IsSynonym                   bit
        , TenantPrefix                nvarchar(32) NULL
        , IsCurrentTenant             bit
        , HasTenantPrefix             bit
        , AliasName                   sysname NULL
        , AliasQuoteType              nvarchar(32) NULL
        , AliasTokenIndex             int NULL
        , DatabaseTokenIndex          int NULL
        , SchemaTokenIndex            int NULL
        , ObjectTokenIndex            int NULL
        , NormalizedDatabaseName      sysname NULL
        , TargetSchemaName            sysname NULL
        , TargetObjectName            sysname
    );

    CREATE TABLE #TargetLookup
    (
          TableNodeId                 int
        , NormalizedDatabaseName      sysname NULL
        , TargetSchemaName            sysname NULL
        , TargetObjectName            sysname
        , IsSynonym                   bit
        , TenantPrefix                nvarchar(32) NULL
        , IsCurrentTenant             bit
        , HasTenantPrefix             bit
        , AliasName                   sysname NULL
        , AliasQuoteType              nvarchar(32) NULL
        , AliasTokenIndex             int NULL
        , DatabaseTokenIndex          int NULL
        , SchemaTokenIndex            int NULL
        , ObjectTokenIndex            int NULL
    );

    INSERT INTO #TargetLookup
    SELECT 
          TableNodeId
        , NormalizedDatabaseName
        , TargetSchemaName
        , TargetObjectName
        , IsSynonym
        , TenantPrefix
        , IsCurrentTenant
        , HasTenantPrefix
        , AliasName
        , AliasQuoteType
        , AliasTokenIndex
        , DatabaseTokenIndex
        , SchemaTokenIndex
        , ObjectTokenIndex
    FROM #ResolvedTables;

    DECLARE @SqlCatalogLookup nvarchar(max) = N'
    INSERT INTO #ResolvedCatalog
    SELECT 
          t.TableNodeId
        , cat.GUID AS TableGuid
        , cat.Qualifier2GUID AS SchemaGuid
        , cat.Qualifier1GUID AS DbGuid
        , t.IsSynonym
        , t.TenantPrefix
        , t.IsCurrentTenant
        , t.HasTenantPrefix
        , t.AliasName
        , t.AliasQuoteType
        , t.AliasTokenIndex
        , t.DatabaseTokenIndex
        , t.SchemaTokenIndex
        , t.ObjectTokenIndex
        , t.NormalizedDatabaseName
        , t.TargetSchemaName
        , t.TargetObjectName
    FROM #TargetLookup AS t
    LEFT JOIN ' + @CatalogTable + N' AS cat
        ON cat.Qualifier1 = t.NormalizedDatabaseName
       AND cat.Qualifier2 = t.TargetSchemaName
       AND cat.Qualifier3 = t.TargetObjectName
       AND cat.ObjectType IN (''S_OU'', ''S_OV'')
       AND cat.IsDeleted = 0;
    ';

    EXEC sys.sp_executesql @SqlCatalogLookup;

    -- 5. Spalten-GUIDs nachschlagen
    CREATE TABLE #ResolvedColumns
    (
          ColRefNodeId                int
        , ColumnTokenIndex            int
        , ColumnName                  sysname
        , ColumnGuid                  nvarchar(64)
        , QualifierTokenIndex         int NULL
        , TableOrAliasQualifier       sysname NULL
        , TableGuid                   nvarchar(64) NULL
        , TenantPrefix                nvarchar(32) NULL
        , IsCurrentTenant             bit NULL
        , AliasQuoteType              nvarchar(32) NULL
    );

    SELECT * INTO #ColumnsTemp FROM @Columns;

    DECLARE @SqlColExec nvarchar(max) = N'
    INSERT INTO #ResolvedColumns
    SELECT 
          c.ColRefNodeId
        , c.ColumnTokenIndex
        , c.ColumnName
        , colCat.GUID AS ColumnGuid
        , c.QualifierTokenIndex
        , c.TableOrAliasQualifier
        , t.TableGuid
        , t.TenantPrefix
        , t.IsCurrentTenant
        , t.AliasQuoteType
    FROM #ColumnsTemp AS c
    LEFT JOIN #ResolvedCatalog AS t
        ON (c.TableOrAliasQualifier IS NULL)
        OR (c.TableOrAliasQualifier = t.AliasName)
        OR (c.TableOrAliasQualifier = t.TargetObjectName)
        OR (c.TableOrAliasQualifier = CONCAT(t.NormalizedDatabaseName, N''_'' , t.TargetSchemaName, N''_'' , t.TargetObjectName))
        OR (c.TableOrAliasQualifier = CONCAT(t.NormalizedDatabaseName, N''.'' , t.TargetSchemaName, N''.'' , t.TargetObjectName))
        OR (t.TenantPrefix IS NOT NULL AND c.TableOrAliasQualifier = CONCAT(t.TenantPrefix, N''_'' , t.NormalizedDatabaseName, N''.'' , t.TargetSchemaName, N''.'' , t.TargetObjectName))
    LEFT JOIN ' + @CatalogTable + N' AS colCat
        ON colCat.ParentGUID = t.TableGuid
       AND colCat.Qualifier4 = c.ColumnName
       AND colCat.ObjectType = ''S_COL''
       AND colCat.IsDeleted = 0;
    ';

    EXEC sys.sp_executesql @SqlColExec;

    -- 6. Ersetzungsliste zusammenbauen
    DECLARE @Replacements [toolbelt_tsql].[TT_TokenReplacement];

    -- A. Datenbank-Ersetzungen (nur wenn nicht Synonym)
    INSERT INTO @Replacements (TokenIndex, ReplacementText)
    SELECT
          rc.DatabaseTokenIndex
        , CASE 
            -- Fremder / fixer Mandant (z. B. R34)
            WHEN rc.IsCurrentTenant = 0 AND rc.TenantPrefix IS NOT NULL 
                THEN CONCAT(N'[{glc:', rc.DbGuid, N',tenant:', rc.TenantPrefix, N'}]')
            -- Eigener Mandant / Standard
            ELSE CONCAT(N'[{glc:', rc.DbGuid, N'}]')
          END
    FROM #ResolvedCatalog AS rc
    WHERE rc.DatabaseTokenIndex IS NOT NULL
      AND rc.DbGuid IS NOT NULL
      AND rc.IsSynonym = 0;

    -- B. Schema-Ersetzungen (nur wenn nicht Synonym)
    INSERT INTO @Replacements (TokenIndex, ReplacementText)
    SELECT
          rc.SchemaTokenIndex
        , CONCAT(N'[{glc:', rc.SchemaGuid, N'}]')
    FROM #ResolvedCatalog AS rc
    WHERE rc.SchemaTokenIndex IS NOT NULL
      AND rc.SchemaGuid IS NOT NULL
      AND rc.IsSynonym = 0;

    -- C. Tabellen-Ersetzungen
    INSERT INTO @Replacements (TokenIndex, ReplacementText)
    SELECT
          rc.ObjectTokenIndex
        , CASE 
            WHEN rc.TableGuid IS NULL THEN rc.TargetObjectName
            -- Synonym
            WHEN rc.IsSynonym = 1 THEN CONCAT(N'[{glc:', rc.TableGuid, N',syn}]')
            -- Fremder / fixer Mandant (z. B. R34)
            WHEN rc.IsCurrentTenant = 0 AND rc.TenantPrefix IS NOT NULL 
                THEN CONCAT(N'[{glc:', rc.TableGuid, N',tenant:', rc.TenantPrefix, N'}]')
            -- Eigener Mandant / Standard
            ELSE CONCAT(N'[{glc:', rc.TableGuid, N'}]')
          END
    FROM #ResolvedCatalog AS rc
    WHERE rc.ObjectTokenIndex IS NOT NULL;

    -- D. Alias-Ersetzungen
    INSERT INTO @Replacements (TokenIndex, ReplacementText)
    SELECT
          rc.AliasTokenIndex
        , CASE
            -- Dot-Alias [DB.Schema.Table]
            WHEN rc.AliasName LIKE N'%.%' AND rc.IsCurrentTenant = 0 AND rc.TenantPrefix IS NOT NULL
                THEN CONCAT(N'[{glc:', rc.TableGuid, N',.,tenant:', rc.TenantPrefix, N'}]')
            WHEN rc.AliasName LIKE N'%.%'
                THEN CONCAT(N'[{glc:', rc.TableGuid, N',.}]')
            -- Underscore-Alias mit eckigen Klammern [ZDW_vertrag_Konto] -> Modifikator 'q_'
            WHEN t.AliasQuoteType = N'SquareBracket' AND rc.IsCurrentTenant = 0 AND rc.TenantPrefix IS NOT NULL
                THEN CONCAT(N'[{glc:', rc.TableGuid, N',q_,tenant:', rc.TenantPrefix, N'}]')
            WHEN t.AliasQuoteType = N'SquareBracket'
                THEN CONCAT(N'[{glc:', rc.TableGuid, N',q_}]')
            -- Unquotierter Underscore-Alias ZDW_vertrag_Konto -> Modifikator '_'
            WHEN rc.IsCurrentTenant = 0 AND rc.TenantPrefix IS NOT NULL
                THEN CONCAT(N'[{glc:', rc.TableGuid, N',_,tenant:', rc.TenantPrefix, N'}]')
            ELSE CONCAT(N'[{glc:', rc.TableGuid, N',_}]')
          END
    FROM #ResolvedCatalog AS rc
    INNER JOIN @Tables AS t
        ON t.TableNodeId = rc.TableNodeId
    WHERE rc.AliasTokenIndex IS NOT NULL
      AND rc.TableGuid IS NOT NULL
      AND (
            rc.AliasName LIKE N'%' + rc.NormalizedDatabaseName + N'%' + rc.TargetObjectName + N'%'
            OR rc.AliasName LIKE N'%' + rc.TargetSchemaName + N'%' + rc.TargetObjectName + N'%'
      );

    -- E. Spalten-Qualifier-Ersetzungen (z. B. [ZDW_vertrag_Konto].KontoNr oder [ZDW.vertrag.Konto].KontoNr)
    INSERT INTO @Replacements (TokenIndex, ReplacementText)
    SELECT
          rc.QualifierTokenIndex
        , MAX(CASE
            -- Dot-Qualifier [DB.Schema.Table]
            WHEN rc.TableOrAliasQualifier LIKE N'%.%' AND rc.IsCurrentTenant = 0 AND rc.TenantPrefix IS NOT NULL
                THEN CONCAT(N'[{glc:', rc.TableGuid, N',.,tenant:', rc.TenantPrefix, N'}]')
            WHEN rc.TableOrAliasQualifier LIKE N'%.%'
                THEN CONCAT(N'[{glc:', rc.TableGuid, N',.}]')
            -- Underscore-Qualifier in eckigen Klammern [ZDW_vertrag_Konto]
            WHEN rc.AliasQuoteType = N'SquareBracket' AND rc.IsCurrentTenant = 0 AND rc.TenantPrefix IS NOT NULL
                THEN CONCAT(N'[{glc:', rc.TableGuid, N',q_,tenant:', rc.TenantPrefix, N'}]')
            WHEN rc.AliasQuoteType = N'SquareBracket'
                THEN CONCAT(N'[{glc:', rc.TableGuid, N',q_}]')
            -- Unquotierter Underscore-Qualifier ZDW_vertrag_Konto
            WHEN rc.IsCurrentTenant = 0 AND rc.TenantPrefix IS NOT NULL
                THEN CONCAT(N'[{glc:', rc.TableGuid, N',_,tenant:', rc.TenantPrefix, N'}]')
            ELSE CONCAT(N'[{glc:', rc.TableGuid, N',_}]')
          END)
    FROM #ResolvedColumns AS rc
    WHERE rc.QualifierTokenIndex IS NOT NULL
      AND rc.TableGuid IS NOT NULL
      AND (
            rc.TableOrAliasQualifier LIKE N'%.%'
            OR rc.TableOrAliasQualifier LIKE N'%[_]%'
      )
    GROUP BY rc.QualifierTokenIndex;

    -- F. Spalten-Ersetzungen
    INSERT INTO @Replacements (TokenIndex, ReplacementText)
    SELECT
          rc.ColumnTokenIndex
        , CONCAT(N'[{glc:', MAX(rc.ColumnGuid), N'}]')
    FROM #ResolvedColumns AS rc
    WHERE rc.ColumnTokenIndex IS NOT NULL
      AND rc.ColumnGuid IS NOT NULL
    GROUP BY rc.ColumnTokenIndex;

    -- 7. Re-Assembling des finalen SQL-Statements
    EXEC [toolbelt_tsql].[USP_ApplyTokenReplacements]
          @SqlText = @SqlText
        , @Replacements = @Replacements
        , @RewrittenSql = @RewrittenSql OUTPUT;

    IF @Debug = 1
    BEGIN
        SELECT * FROM #ResolvedCatalog;
        SELECT * FROM #ResolvedColumns;
        SELECT * FROM @Replacements;
    END;

    DROP TABLE IF EXISTS #ResolvedCatalog;
    DROP TABLE IF EXISTS #TargetLookup;
    DROP TABLE IF EXISTS #ResolvedColumns;
    DROP TABLE IF EXISTS #ColumnsTemp;
    DROP TABLE IF EXISTS #SynonymLookup;

    RETURN 0;
END;
GO
