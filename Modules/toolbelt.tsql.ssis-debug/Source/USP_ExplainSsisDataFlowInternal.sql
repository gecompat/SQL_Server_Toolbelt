-- ============================================================================
-- Generiert durch Scripts/New-ContractSources.py aus Contracts/Api.json.
-- Objekt: toolbelt_tsql.USP_ExplainSsisDataFlowInternal; interne CLR-USP mit Unicodebindung und gleichem Standardtail.
-- Zweck: DTSX2 erklären, JSON-Vorlage und lesende CTE-Debugskripte erzeugen.
-- Vertrag: SSIS_CURRENT_API_CONTRACT.md; USP_CONTRACT1.0; Version1.0.0.
-- Parameter/Resultset: vollständig in Contracts/Api.json und @Hilfe=1.
-- Aktuelle Ergänzungen: schema-validiertes Contracts/ComponentsV2.json Help-Overlay.
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
    @MaxPackageBytes bigint = 134217728,
    @MaxXmlCharacters bigint = 134217728,
    @MaxXmlNodes bigint = 1048576,
    @MaxModelNodes bigint = 262144,
    @MaxModelEdges bigint = 1048576,
    @MaxComponents bigint = 4096,
    @MaxPaths bigint = 8192,
    @MaxColumns bigint = 65536,
    @MaxInputs bigint = 8192,
    @MaxJsonDocumentBytes bigint = 4194304,
    @MaxAllJsonBytes bigint = 8388608,
    @MaxJsonNodes bigint = 131072,
    @MaxExpressionBytes bigint = 4194304,
    @MaxExpressionTokens bigint = 262144,
    @MaxExpressionNodes bigint = 131072,
    @MaxPlanUnits bigint = 8192,
    @MaxCatalogObjects bigint = 4096,
    @MaxCatalogQueries bigint = 4096,
    @MaxParserCalls bigint = 32768,
    @MaxArtifacts bigint = 65536,
    @MaxDiagnostics bigint = 16384,
    @MaxSqlArtifactBytes bigint = 2097152,
    @MaxTotalOutputBytes bigint = 134217728,
    @MaxAnalysisMilliseconds bigint = 0,
    @ResultTable sysname = NULL,
    @KeepData bit = 0,
    @Debug tinyint = 0,
    @Hilfe bit = 0
AS EXTERNAL NAME [Toolbelt_Tsql_SsisDebug].[Toolbelt.Tsql.SsisDebug.SsisDebugProvider].[ExplainSsisDataFlow];
GO
