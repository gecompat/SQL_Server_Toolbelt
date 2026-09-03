-- ============================================================================
-- Objekt:          toolbelt_glc.TVF_ParseTenantDatabaseName
-- Typ:             Inline Table-Valued Function (iTVF)
-- Zweck:           Zerlegt einen physischen Datenbanknamen deterministisch in:
--                  - MandantPrefix (immer der Teil vor dem 1. '_', z. B. 'R00', 'R34', 'RA34')
--                  - NormalizedDatabaseName (Teil nach dem 1. '_', z. B. 'ZDW', 'META_DELIVERY', 'lrctpis')
--                  - IsCurrentTenant (1 = gleicher Mandant wie Context, 0 = fremder Mandant oder mandantenlos)
--                  - HasTenantPrefix (1 = besitzt ein '_', 0 = mandantenlose DB wie master/tempdb)
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF SCHEMA_ID(N'toolbelt_glc') IS NULL
    EXEC sys.sp_executesql N'CREATE SCHEMA [toolbelt_glc];';
GO

CREATE OR ALTER FUNCTION [toolbelt_glc].[TVF_ParseTenantDatabaseName]
(
      @DatabaseName       sysname
    , @CurrentDatabase    sysname = NULL
)
RETURNS TABLE
AS
RETURN
WITH CurrentContext AS (
    SELECT 
          COALESCE(@CurrentDatabase, DB_NAME()) AS ContextDb
        , CASE 
            -- Mandanten-Präfix ist immer der Teil vor dem ersten Unterstrich
            WHEN CHARINDEX(N'_', COALESCE(@CurrentDatabase, DB_NAME())) > 1
                THEN LEFT(COALESCE(@CurrentDatabase, DB_NAME()), CHARINDEX(N'_', COALESCE(@CurrentDatabase, DB_NAME())) - 1)
            ELSE NULL 
          END AS CurrentTenantPrefix
),
InputAnalysis AS (
    SELECT 
          @DatabaseName AS RawDatabaseName
        , CASE 
            WHEN CHARINDEX(N'_', @DatabaseName) > 1
                THEN LEFT(@DatabaseName, CHARINDEX(N'_', @DatabaseName) - 1)
            ELSE NULL 
          END AS ExtractedTenantPrefix
)
SELECT 
      ia.RawDatabaseName
    , ia.ExtractedTenantPrefix AS TenantPrefix
    , CASE 
        WHEN ia.ExtractedTenantPrefix IS NOT NULL 
            THEN SUBSTRING(ia.RawDatabaseName, LEN(ia.ExtractedTenantPrefix) + 2, 128)
        ELSE ia.RawDatabaseName
      END AS NormalizedDatabaseName
    , CASE 
        -- 1: Trägt exakt das Präfix des aktuellen Mandanten
        WHEN ia.ExtractedTenantPrefix IS NOT NULL AND ia.ExtractedTenantPrefix = ctx.CurrentTenantPrefix THEN CAST(1 AS bit)
        -- 0: Fremder Mandant oder mandantenlos
        ELSE CAST(0 AS bit)
      END AS IsCurrentTenant
    , CASE 
        WHEN ia.ExtractedTenantPrefix IS NOT NULL THEN CAST(1 AS bit)
        ELSE CAST(0 AS bit)
      END AS HasTenantPrefix
FROM InputAnalysis AS ia
CROSS JOIN CurrentContext AS ctx;
GO
