-- ============================================================================
-- Generiert durch Scripts/New-ContractSources.py aus Contracts/Api.json.
-- Objekt: toolbelt_tsql.USP_ExplainSsisDataFlowInternal; interne CLR-USP mit Unicodebindung und gleichem Standardtail.
-- Zweck: DTSX2 erklären, JSON-Vorlage und lesende CTE-Debugskripte erzeugen.
-- Vertrag: SSIS_DTSX_DEBUG_SELECT_V1_CONTRACT.md; USP_CONTRACT1.0; Version1.0.0.
-- Parameter/Resultset: vollständig in Contracts/Api.json und @Hilfe=1.
-- Dependencies: Parser exakt2.0.1 mit gepinntem ScriptDom; ResultTable>=1.0.0.
-- Rechte: CALLER, EXECUTE; explizite Same-instance-Katalogvollsicht.
-- Plattform: Windows SQL Server2019/2022/2025 CL150/160/170; UNSAFE.
-- Fehler:50000/TBX_SSISDBG_; keine fachliche Teilresultatausgabe bei globalem Fehler.
-- Performance: endliches Import-/AST-/Katalog-/Ausgabebudget; kein harter Watchdog.
-- Grenzen: kein Datei-/Netzzugriff, kein SSIS-/Paket-SQL-Execute, keine Ziel-DML.
-- NOLOCK: mögliche Dirty-/Missing-/Duplicate-Reads und verbleibende Schemasperren.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_tsql.USP_ExplainSsisDataFlowInternal
    @PackageBytes varbinary(max),
    @Operation nvarchar(32) = N'explain',
    @ProjectContext nvarchar(max),
    @Bindings nvarchar(max),
    @CatalogBindings nvarchar(max),
    @TargetFlow nvarchar(64) = NULL,
    @InspectStage nvarchar(64) = NULL,
    @LookupPolicies nvarchar(max),
    @ComparisonCollation sysname = NULL,
    @TSqlVersion smallint = 150,
    @ResultTable sysname = NULL,
    @KeepData bit = 0,
    @Debug tinyint = 0,
    @Hilfe bit = 0
AS EXTERNAL NAME [Toolbelt_Tsql_SsisDebug].[Toolbelt.Tsql.SsisDebug.SsisDebugProvider].[ExplainSsisDataFlow];
GO
