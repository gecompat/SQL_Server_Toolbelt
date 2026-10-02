-- Ausschließlich synthetische, dedizierte Testdatenbank; Wiederherstellung besitzt der Runner.
-- Nach Setup: Snapshot aufnehmen, Deploy/Uninstall erwartbar ablehnen, Snapshot vergleichen.
SET NOCOUNT ON;
DECLARE @FaultCase nvarchar(64) = N'$(FaultCase)';
IF @FaultCase = N'UnknownVersion'
    EXEC sys.sp_updateextendedproperty @name = N'Toolbelt.Module.toolbelt.tsql.script-parser.Version', @value = N'9.9.9';
ELSE IF @FaultCase = N'MissingVersion'
    EXEC sys.sp_dropextendedproperty @name = N'Toolbelt.Module.toolbelt.tsql.script-parser.Version';
ELSE IF @FaultCase = N'ForeignFunctionMarker'
    EXEC sys.sp_updateextendedproperty @name = N'Toolbelt.ModuleId', @value = N'Contoso.Foreign',
         @level0type = N'SCHEMA', @level0name = N'toolbelt_tsql', @level1type = N'FUNCTION', @level1name = N'TVF_ParseScriptNodes';
ELSE IF @FaultCase = N'ForeignProviderMarker'
    EXEC sys.sp_updateextendedproperty @name = N'Toolbelt.ModuleId', @value = N'Contoso.Foreign',
         @level0type = N'ASSEMBLY', @level0name = N'Toolbelt_Tsql_ScriptParser';
ELSE IF @FaultCase = N'InconsistentFunctionVersion'
    EXEC sys.sp_updateextendedproperty @name = N'Toolbelt.ModuleVersion', @value = N'1.0.0',
         @level0type = N'SCHEMA', @level0name = N'toolbelt_tsql', @level1type = N'FUNCTION', @level1name = N'TVF_ParseScriptNodes';
ELSE IF @FaultCase = N'ForeignConsumer'
    EXEC sys.sp_executesql N'CREATE VIEW dbo.ContosoParserConsumer AS SELECT NodeId FROM toolbelt_tsql.TVF_ParseScriptNodes(N''SELECT 1;'',160,1,2097152,100);';
ELSE
    THROW 53131, N'Unbekannter synthetischer Lifecycle-Fehlerfall.', 1;
