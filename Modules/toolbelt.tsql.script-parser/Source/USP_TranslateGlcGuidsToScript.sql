-- ============================================================================
-- Objekt:          toolbelt_glc.USP_TranslateGlcGuidsToScript
-- Typ:             Stored Procedure (Betriebsintern)
-- Zweck:           Übersetzt ein mit GLC-GUID-Tags versehenes SQL-Statement
--                  wieder zurück in lauffähigen T-SQL-Code anhand der
--                  aktuellen Metadaten im GlobalCatalog.
--                  Berücksichtigt:
--                  - Standard-Objektpfade ([{glc:<GUID>}])
--                  - Synonyme ([{glc:<GUID>,syn}])
--                  - Explizit fremde Mandanten ([{glc:<GUID>,tenant:R34_}])
--                  - Flattened Aliase mit _ ([{glc:<GUID>,_}])
--                  - Point-Aliase mit . ([{glc:<GUID>,.}])
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_glc].[USP_TranslateGlcGuidsToScript]
(
      @SqlText            nvarchar(max)
    , @CatalogTable       nvarchar(512) = N'[glc].[GlobalCatalog]'
    , @CurrentDatabase    sysname       = NULL
    , @TranslatedSql      nvarchar(max) = NULL OUTPUT
    , @Debug              bit           = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ContextDb sysname = COALESCE(@CurrentDatabase, DB_NAME());
    
    -- Ermittle aktuelles Mandanten-Präfix
    DECLARE @CurrentTenantPrefix nvarchar(32);
    SELECT @CurrentTenantPrefix = TenantPrefix
    FROM toolbelt_glc.TVF_ParseTenantDatabaseName(@ContextDb, @ContextDb);

    -- 1. Tokens aus dem Script lesen
    DECLARE @Tokens TABLE
    (
          TokenIndex          int PRIMARY KEY
        , TokenType           nvarchar(64)
        , TokenText           nvarchar(max)
        , StartOffset         int
        , StartLine           int
        , StartColumn         int
    );

    INSERT INTO @Tokens
    SELECT * FROM toolbelt_tsql.TVF_TokenizeScript(@SqlText, NULL, NULL, NULL, NULL);

    -- 2. GLC-Tags identifizieren (Tokens, die mit [{glc: beginnen)
    DECLARE @Tags TABLE
    (
          TokenIndex          int PRIMARY KEY
        , RawTokenText        nvarchar(max)
        , ExtractedGuid       nvarchar(64)
        , Modifiers           nvarchar(128)
    );

    INSERT INTO @Tags (TokenIndex, RawTokenText, ExtractedGuid, Modifiers)
    SELECT
          t.TokenIndex
        , t.TokenText
        , CASE 
            WHEN CHARINDEX(N',', SUBSTRING(t.TokenText, 7, LEN(t.TokenText) - 7)) > 0
                THEN LEFT(SUBSTRING(t.TokenText, 7, LEN(t.TokenText) - 7), CHARINDEX(N',', SUBSTRING(t.TokenText, 7, LEN(t.TokenText) - 7)) - 1)
            ELSE LEFT(SUBSTRING(t.TokenText, 7, LEN(t.TokenText) - 7), LEN(SUBSTRING(t.TokenText, 7, LEN(t.TokenText) - 7)) - 1)
          END AS ExtractedGuid
        , CASE 
            WHEN CHARINDEX(N',', SUBSTRING(t.TokenText, 7, LEN(t.TokenText) - 7)) > 0
                THEN LEFT(
                        SUBSTRING(
                            SUBSTRING(t.TokenText, 7, LEN(t.TokenText) - 7), 
                            CHARINDEX(N',', SUBSTRING(t.TokenText, 7, LEN(t.TokenText) - 7)) + 1, 
                            128), 
                        LEN(SUBSTRING(
                            SUBSTRING(t.TokenText, 7, LEN(t.TokenText) - 7), 
                            CHARINDEX(N',', SUBSTRING(t.TokenText, 7, LEN(t.TokenText) - 7)) + 1, 
                            128)) - 1)
            ELSE N''
          END AS Modifiers
    FROM @Tokens AS t
    WHERE LEFT(t.TokenText, 6) = N'[{glc:' AND RIGHT(t.TokenText, 1) = N']';

    -- 3. Katalog-Metadaten für alle gefundenen GUIDs laden
    CREATE TABLE #TagMeta
    (
          GUID                        nvarchar(64) PRIMARY KEY
        , ObjectType                  nvarchar(32)
        , Name                        sysname
        , Qualifier1                  sysname NULL
        , Qualifier2                  sysname NULL
        , Qualifier3                  sysname NULL
        , Qualifier4                  sysname NULL
        , FullQualifiedObjectName_quoted   nvarchar(512) NULL
        , FullQualifiedObjectname_unquoted nvarchar(512) NULL
    );

    SELECT DISTINCT ExtractedGuid INTO #DistinctGuids FROM @Tags;

    DECLARE @SqlCatalogLookup nvarchar(max) = N'
    INSERT INTO #TagMeta
    SELECT 
          cat.GUID
        , cat.ObjectType
        , cat.Name
        , cat.Qualifier1
        , cat.Qualifier2
        , cat.Qualifier3
        , cat.Qualifier4
        , cat.FullQualifiedObjectName_quoted
        , cat.FullQualifiedObjectname_unquoted
    FROM #DistinctGuids AS g
    INNER JOIN ' + @CatalogTable + N' AS cat
        ON cat.GUID = g.ExtractedGuid
       AND cat.IsDeleted = 0;
    ';

    EXEC sys.sp_executesql @SqlCatalogLookup;

    -- 4. Ersetzungen berechnen unter Auswertung der Modifikatoren
    DECLARE @Replacements [toolbelt_tsql].[TT_TokenReplacement];

    INSERT INTO @Replacements (TokenIndex, ReplacementText)
    SELECT
          tg.TokenIndex
        , CASE
            -- Modifier: Name-only
            -- Modifier: Name-only
            WHEN CHARINDEX(N'name', tg.Modifiers) > 0 THEN tm.Name
            
            -- Modifier: Synonym (nur Tabellenname)
            WHEN CHARINDEX(N'syn', tg.Modifiers) > 0 THEN tm.Name
            
            -- Modifier: Underscore Alias mit eckigen Klammern [DB_Schema_Table] -> Modifikator 'q_'
            WHEN CHARINDEX(N'q_', tg.Modifiers) > 0 AND CHARINDEX(N'tenant:', tg.Modifiers) = 0 THEN 
                CASE 
                    WHEN tm.ObjectType IN (N'S_OU', N'S_OV') 
                        THEN CONCAT(
                                N'[',
                                CASE WHEN @CurrentTenantPrefix IS NOT NULL THEN CONCAT(@CurrentTenantPrefix, N'_') ELSE N'' END,
                                tm.Qualifier1, N'_', tm.Qualifier2, N'_', tm.Qualifier3, N']')
                    ELSE CONCAT(N'[', tm.Name, N']')
                END
                
            -- Modifier: Underscore Alias mit eckigen Klammern und fremdem Mandanten [R34_DB_Schema_Table] -> Modifikator 'q_'
            WHEN CHARINDEX(N'q_', tg.Modifiers) > 0 AND CHARINDEX(N'tenant:', tg.Modifiers) > 0 THEN 
                CASE 
                    WHEN tm.ObjectType IN (N'S_OU', N'S_OV') 
                        THEN CONCAT(
                                N'[',
                                SUBSTRING(tg.Modifiers, CHARINDEX(N'tenant:', tg.Modifiers) + 7, 32), N'_',
                                tm.Qualifier1, N'_', tm.Qualifier2, N'_', tm.Qualifier3, N']')
                    ELSE CONCAT(N'[', tm.Name, N']')
                END

            -- Modifier: Unquotierter Underscore Alias DB_Schema_Table
            WHEN CHARINDEX(N'_', tg.Modifiers) > 0 AND CHARINDEX(N'tenant:', tg.Modifiers) = 0 THEN 
                CASE 
                    WHEN tm.ObjectType IN (N'S_OU', N'S_OV') 
                        THEN CONCAT(
                                CASE WHEN @CurrentTenantPrefix IS NOT NULL THEN CONCAT(@CurrentTenantPrefix, N'_') ELSE N'' END,
                                tm.Qualifier1, N'_', tm.Qualifier2, N'_', tm.Qualifier3)
                    ELSE tm.Name
                END
                
            -- Modifier: Unquotierter Underscore Alias mit fremdem Mandanten R34_DB_Schema_Table
            WHEN CHARINDEX(N'_', tg.Modifiers) > 0 AND CHARINDEX(N'tenant:', tg.Modifiers) > 0 THEN 
                CASE 
                    WHEN tm.ObjectType IN (N'S_OU', N'S_OV') 
                        THEN CONCAT(
                                SUBSTRING(tg.Modifiers, CHARINDEX(N'tenant:', tg.Modifiers) + 7, 32), N'_',
                                tm.Qualifier1, N'_', tm.Qualifier2, N'_', tm.Qualifier3)
                    ELSE tm.Name
                END
                
            -- Modifier: Dot Alias [DB.Schema.Table]
            WHEN CHARINDEX(N'.', tg.Modifiers) > 0 AND CHARINDEX(N'tenant:', tg.Modifiers) = 0 THEN 
                CASE 
                    WHEN tm.ObjectType IN (N'S_OU', N'S_OV') 
                        THEN CONCAT(
                                N'[', 
                                CASE WHEN @CurrentTenantPrefix IS NOT NULL THEN CONCAT(@CurrentTenantPrefix, N'_') ELSE N'' END,
                                tm.Qualifier1, N'.', tm.Qualifier2, N'.', tm.Qualifier3, N']')
                    ELSE CONCAT(N'[', tm.Name, N']')
                END
                
            -- Modifier: Dot Alias mit fremdem Mandanten [R34_DB.Schema.Table]
            WHEN CHARINDEX(N'.', tg.Modifiers) > 0 AND CHARINDEX(N'tenant:', tg.Modifiers) > 0 THEN 
                CASE 
                    WHEN tm.ObjectType IN (N'S_OU', N'S_OV') 
                        THEN CONCAT(
                                N'[', 
                                SUBSTRING(tg.Modifiers, CHARINDEX(N'tenant:', tg.Modifiers) + 7, 32), N'_',
                                tm.Qualifier1, N'.', tm.Qualifier2, N'.', tm.Qualifier3, N']')
                    ELSE CONCAT(N'[', tm.Name, N']')
                END
            
            -- Standard: Spalte -> reiner Name oder [Name]
            WHEN tm.ObjectType = N'S_COL' THEN CONCAT(N'[', tm.Name, N']')
            
            -- Standard: Schema -> Name
            WHEN tm.ObjectType = N'S_SCHEMA' THEN tm.Name
            
            -- Standard: Datenbank -> Name mit dynamischem oder fixem Mandanten
            WHEN tm.ObjectType = N'S_DB' THEN 
                CASE 
                    WHEN CHARINDEX(N'tenant:', tg.Modifiers) > 0
                        THEN CONCAT(SUBSTRING(tg.Modifiers, CHARINDEX(N'tenant:', tg.Modifiers) + 7, 32), N'_', tm.Name)
                    WHEN @CurrentTenantPrefix IS NOT NULL
                        THEN CONCAT(@CurrentTenantPrefix, N'_', tm.Name)
                    ELSE tm.Name
                END

            -- Standard: Tabelle -> Name
            WHEN tm.ObjectType IN (N'S_OU', N'S_OV') THEN tm.Name
                
            ELSE tm.Name
          END AS ReplacementText
    FROM @Tags AS tg
    INNER JOIN #TagMeta AS tm
        ON tm.GUID = tg.ExtractedGuid;

    -- 5. SQL verlustfrei neu zusammensetzen
    EXEC [toolbelt_tsql].[USP_ApplyTokenReplacements]
          @SqlText = @SqlText
        , @Replacements = @Replacements
        , @RewrittenSql = @TranslatedSql OUTPUT;

    IF @Debug = 1
    BEGIN
        SELECT * FROM @Tags;
        SELECT * FROM #TagMeta;
        SELECT * FROM @Replacements;
    END;

    DROP TABLE IF EXISTS #DistinctGuids;
    DROP TABLE IF EXISTS #TagMeta;

    RETURN 0;
END;
GO
