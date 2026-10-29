-- ============================================================================
-- Generiert durch Scripts/New-ContractSources.py aus Contracts/Api.json.
-- Objekt: toolbelt_tsql.USP_ExplainSsisDataFlow; öffentliche T-SQL-Fassade.
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
CREATE OR ALTER PROCEDURE toolbelt_tsql.USP_ExplainSsisDataFlow
    @PackageBytes varbinary(max) = NULL,
    @Operation varchar(32) = N'explain',
    @ProjectContext nvarchar(max) = NULL,
    @Bindings nvarchar(max) = NULL,
    @CatalogBindings nvarchar(max) = NULL,
    @TargetFlow varchar(64) = NULL,
    @InspectStage varchar(64) = NULL,
    @LookupPolicies nvarchar(max) = NULL,
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
AS
BEGIN
    SET NOCOUNT ON;
    IF @Hilfe=1
    BEGIN
        DECLARE @helpObjectName sysname=N'USP_ExplainSsisDataFlow';
SELECT CONVERT(varchar(16),'1.0') AS HelpContractVersion,
 CONVERT(sysname,N'toolbelt_tsql') AS SchemaName,CONVERT(sysname,@helpObjectName) AS ObjectName,
 CONVERT(varchar(32),v.Section) AS Section,CONVERT(int,v.Ordinal) AS Ordinal,
 CONVERT(sysname,v.ItemName) AS ItemName,CONVERT(varchar(256),v.SqlDataType) AS SqlDataType,
 CONVERT(bit,v.IsRequired) AS IsRequired,CONVERT(bit,v.IsNullable) AS IsNullable,
 CONVERT(nvarchar(4000),v.DefaultValue) AS DefaultValue,CONVERT(nvarchar(max),v.Description) AS Description,
 CONVERT(nvarchar(max),v.ExampleSql) AS ExampleSql
FROM (VALUES
(N'DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Erklärt unterstützte SSIS-Datenflüsse standardmäßig mit typisierter JSON-Eingabevorlage und vollständigen, einzeln prüfbaren Debug-SQL-Batches. Paket und enthaltenes SQL werden beim Analysieren niemals ausgeführt.',NULL),
(N'PARAMETER',1,N'@PackageBytes',N'varbinary(max)',1,0,N'NULL',N'Genau ein unterstütztes DTSX-Paket als UTF-8-/UTF-16-Binärwert. Die Standardgrenze beträgt128MiB und ist mit @MaxPackageBytes konfigurierbar. Kein Dateizugriff.',NULL),
(N'PARAMETER',2,N'@Operation',N'varchar(32)',0,0,N'explain',N'Exakt bindings-template oder explain; NULL ungültig.',NULL),
(N'PARAMETER',3,N'@ProjectContext',N'nvarchar(max)',0,1,N'NULL',N'Optionaler Projektparameter-/Connection-Kontext als JSON-Schema2; keine Credentials und keine Ressourcenoptionen.',NULL),
(N'PARAMETER',4,N'@Bindings',N'nvarchar(max)',0,1,N'NULL',N'Zurückgegebene Schema-2-Vorlage; values bearbeiten, Herkunftsmetadaten unverändert zurückgeben. Im Template-Modus NULL.',NULL),
(N'PARAMETER',5,N'@CatalogBindings',N'nvarchar(max)',0,1,N'NULL',N'Explizite Same-instance-Allowlist mit defaultDatabase, databases und connections; Template verlangt NULL.',NULL),
(N'PARAMETER',6,N'@TargetFlow',N'varchar(64)',0,1,N'NULL',N'Ausgegebene Zielfluss-ID; NULL berücksichtigt alle Ziele getrennt.',NULL),
(N'PARAMETER',7,N'@InspectStage',N'varchar(64)',0,1,N'NULL',N'NULL liefert Zielskript und Verzeichnis; all alle Stufen; konkrete ID verlangt TargetFlow.',NULL),
(N'PARAMETER',8,N'@LookupPolicies',N'nvarchar(max)',0,1,N'NULL',N'Optionale gebundene Auswahlordnung je Lookup. Standard beliebige, einmal materialisierte Auswahl.',NULL),
(N'PARAMETER',9,N'@ComparisonCollation',N'sysname',0,1,N'NULL',N'Bekannte explizite Vergleichscollation; NULL verwendet die zugeordnete Defaultdatenbank.',NULL),
(N'PARAMETER',10,N'@TSqlVersion',N'smallint',0,0,N'150',N'Exakt150,160 oder170; kein automatischer Dialektwechsel.',NULL),
(N'PARAMETER',11,N'@MaxPackageBytes',N'bigint',0,0,N'134217728',N'Maximale Paketgröße in Bytes; 0 unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',12,N'@MaxXmlCharacters',N'bigint',0,0,N'134217728',N'Maximale XML-Zeichen; 0 unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',13,N'@MaxXmlNodes',N'bigint',0,0,N'1048576',N'Maximale XML-Knoten; 0 unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',14,N'@MaxModelNodes',N'bigint',0,0,N'262144',N'Maximale Modellknoten; 0 unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',15,N'@MaxModelEdges',N'bigint',0,0,N'1048576',N'Maximale Modellkanten; 0 unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',16,N'@MaxComponents',N'bigint',0,0,N'4096',N'Maximale Komponenten; 0 unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',17,N'@MaxPaths',N'bigint',0,0,N'8192',N'Maximale Datenflusskanten; 0 unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',18,N'@MaxColumns',N'bigint',0,0,N'65536',N'Maximale Spaltenmetadaten; 0 unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',19,N'@MaxInputs',N'bigint',0,0,N'8192',N'Maximale gebundene Eingaben; 0 unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',20,N'@MaxJsonDocumentBytes',N'bigint',0,0,N'4194304',N'Maximale UTF-16-Bytes je Eingabe-JSON; 0 unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',21,N'@MaxAllJsonBytes',N'bigint',0,0,N'8388608',N'Maximale UTF-16-Bytes aller Eingabe-JSONs; 0 unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',22,N'@MaxJsonNodes',N'bigint',0,0,N'131072',N'Maximale JSON-Knoten; 0 unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',23,N'@MaxExpressionBytes',N'bigint',0,0,N'4194304',N'Maximale UTF-16-Bytes je SSIS-Ausdruck; 0 unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',24,N'@MaxExpressionTokens',N'bigint',0,0,N'262144',N'Maximale Ausdruckstokens; 0 unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',25,N'@MaxExpressionNodes',N'bigint',0,0,N'131072',N'Maximale Ausdrucksknoten; 0 unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',26,N'@MaxPlanUnits',N'bigint',0,0,N'8192',N'Maximale geprüfte Debugplaneinheiten; 0 unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',27,N'@MaxCatalogObjects',N'bigint',0,0,N'4096',N'Maximale Katalogobjekte; 0 unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',28,N'@MaxCatalogQueries',N'bigint',0,0,N'4096',N'Maximale Katalogabfragen; 0 unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',29,N'@MaxParserCalls',N'bigint',0,0,N'32768',N'Maximale SQL-Parseraufrufe; 0 unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',30,N'@MaxArtifacts',N'bigint',0,0,N'65536',N'Maximale Ergebnisartefakte; 0 unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',31,N'@MaxDiagnostics',N'bigint',0,0,N'16384',N'Maximale Diagnosen; 0 unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',32,N'@MaxSqlArtifactBytes',N'bigint',0,0,N'2097152',N'Maximale UTF-16-Bytes je SQL-Artefakt; 0 unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',33,N'@MaxTotalOutputBytes',N'bigint',0,0,N'134217728',N'Maximale UTF-16-Bytes der Gesamtausgabe; 0 unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',34,N'@MaxAnalysisMilliseconds',N'bigint',0,0,N'0',N'Analysezeitbudget in Millisekunden; Standard 0 = unbegrenzt, NULL oder negativ ungültig.',NULL),
(N'PARAMETER',35,N'@ResultTable',N'sysname',0,1,N'NULL',N'NULL liefert ein Resultset; sonst vorhandene lokale Temp-Tabelle nach Standardvertrag.',NULL),
(N'PARAMETER',36,N'@KeepData',N'bit',0,1,N'0',N'0 ersetzt,1 hängt an; NULL entspricht0. Kanonischer ResultTable-Helper.',NULL),
(N'PARAMETER',37,N'@Debug',N'tinyint',0,1,N'0',N'Nur redigierte Messages mit Ablauf/Zählern, keine Secretwerte oder zusätzlichen Resultsets.',NULL),
(N'PARAMETER',38,N'@Hilfe',N'bit',0,1,N'0',N'1 liefert ausschließlich standardisierte Hilfe, ignoriert alle Fach-/ResultTable-/Debugparameter.',NULL),
(N'RESULT_COLUMN',1,N'ArtifactKind',N'varchar(32)',1,0,NULL,N'BindingsTemplate, Workflow, StageIndex, PreparationSql, StageSql, PlanManifest, PlanUnitSql, TargetSql, RowCountSql, CleanupSql, DebugScript, FlatFileWriteProjection, ColumnLineage oder Diagnostic.',NULL),
(N'RESULT_COLUMN',2,N'TargetFlowId',N'varchar(64)',1,1,NULL,N'Modellinterne Zielfluss-ID; keine dauerhafte Projektreferenz.',NULL),
(N'RESULT_COLUMN',3,N'StageId',N'varchar(64)',1,1,NULL,N'Modellinterne Prüfpunkt-ID, innerhalb derselben Paketbindung stabil.',NULL),
(N'RESULT_COLUMN',4,N'Ordinal',N'int',1,0,NULL,N'Globale1-basierte Ausgabeordnung.',NULL),
(N'RESULT_COLUMN',5,N'ComponentId',N'nvarchar(4000)',1,1,NULL,N'Ursprüngliche gebundene Komponenten-ID.',NULL),
(N'RESULT_COLUMN',6,N'EvidenceClass',N'varchar(24)',1,0,NULL,N'descriptive, translated, pragmatic, missing_context oder unsupported.',NULL),
(N'RESULT_COLUMN',7,N'Severity',N'varchar(16)',1,1,NULL,N'info, warning oder error für Diagnosen.',NULL),
(N'RESULT_COLUMN',8,N'DiagnosticCode',N'varchar(64)',1,1,NULL,N'Stabiler maschinenlesbarer Diagnosecode.',NULL),
(N'RESULT_COLUMN',9,N'IsComplete',N'bit',1,0,NULL,N'Benötigter Pfad und Kontext vollständig im aktuellen Profil vorhanden.',NULL),
(N'RESULT_COLUMN',10,N'SafetyStatus',N'varchar(24)',1,0,NULL,N'not_applicable, not_checked, passed oder blocked.',NULL),
(N'RESULT_COLUMN',11,N'IsExecutable',N'bit',1,0,NULL,N'Vollständiger, im gebundenen Profil geprüfter Batch; kein bereits ausgeführter Runtime-Nachweis.',NULL),
(N'RESULT_COLUMN',12,N'Content',N'nvarchar(max)',1,0,NULL,N'Artefaktinhalt, insbesondere vollständiger SQL-Prüfblock oder JSON-Vorlage.',NULL),
(N'RESULT_COLUMN',13,N'DetailsJson',N'nvarchar(max)',1,1,NULL,N'Zusätzliche gültige JSON-Metadaten.',NULL),
(N'DESCRIPTION',2,NULL,NULL,NULL,NULL,NULL,N'Der aktuelle Komponentenvertrag ist der Standard für bindings-template und explain. Die editierbare Vorlage verwendet schemaVersion 2 und das Profil ssis-debug-components-v2.',NULL),
(N'LIMITATION',2,NULL,NULL,NULL,NULL,NULL,N'Ressourcenlimits werden ausschließlich durch die benannten bigint-Parameter gesetzt. 0 bedeutet unbegrenzt; NULL und negative Werte sind ungültig. resourceOptions im ProjectContext wird abgewiesen.',NULL),
(N'LIMITATION',3,NULL,NULL,NULL,NULL,NULL,N'Die Vorlage zeigt nicht-sensitive Paketdefaults als editierbare Debugwerte. Laufzeitzuweisungen und Ausdrücke bleiben als Herkunft markiert; das ist kein beobachteter SSIS-Laufzeitwert. Sensitive Werte bleiben redigiert.',NULL),
(N'LIMITATION',4,NULL,NULL,NULL,NULL,NULL,N'DebugScript ist nur bei vollständigem Pfad und gebundenem SQL-Text ausführbar. Bei fehlendem Kontext nennt Workflow/StageIndex die Erstursache und verfügbare vollständige Teilpläne; SSIS-Aufgaben werden nicht ausgeführt.',NULL),
(N'EXAMPLE',2,NULL,NULL,NULL,NULL,NULL,N'Aktuelle editierbare Parameter-Vorlage erzeugen.',N'EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @PackageBytes=@PackageBytes,@Operation=''bindings-template'';'),
(N'EXAMPLE',3,NULL,NULL,NULL,NULL,NULL,N'Eine optionale Grenze direkt am SQL-Parameter setzen; 0 ist unbegrenzt.',N'EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @PackageBytes=@PackageBytes,@MaxExpressionBytes=0;'),
(N'EXAMPLE',4,NULL,NULL,NULL,NULL,NULL,N'Gebundene Parameterwerte verwenden und bei vollständigem Kontext das gesamte DebugScript ausgeben lassen.',N'EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @PackageBytes=@PackageBytes,@Operation=''explain'',@Bindings=@Bindings,@CatalogBindings=@CatalogBindings;'),
(N'EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Reine Hilfe ohne Paket oder Katalogprüfung.',N'EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @Hilfe=1;'),
(N'PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'CALLER; EXECUTE und vollständige Katalogsicht der ausdrücklich erlaubten Datenbanken. Keine Rechtevergabe.',NULL),
(N'LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'Windows SQL Server 2019/2022/2025; UNSAFE/ScriptDom. NOLOCK erlaubt Dirty Reads und garantiert keine Sperrfreiheit. Keine Ausführung von Paket-SQL.',NULL)
) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1 WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 WHEN 'PERMISSION' THEN 4 ELSE 5 END,v.Ordinal;
        RETURN;
    END;
    -- Nur im Prozedurscope: neutrale Vertragsfehler dürfen eine gesunde
    -- Callertransaktion nicht durch geerbtes XACT_ABORT ON doomen. SQL Server
    -- stellt die geerbte SET-Option beim Verlassen dieses Scopes wieder her.
    SET XACT_ABORT OFF;
    BEGIN TRY
        -- SQL CLR kann in einer bereits doomed Transaktion vor dem C#-Preflight
        -- mit3930 scheitern. Deshalb den Vertragsfehler hier vorziehen.
        IF XACT_STATE()=-1 THROW 50000,N'TBX_SSISDBG_unresolved_binding: Callertransaktion ist nicht schreibfähig.',1;
        EXEC toolbelt_tsql.USP_ExplainSsisDataFlowInternal
        @PackageBytes=@PackageBytes,
        @Operation=@Operation,
        @ProjectContext=@ProjectContext,
        @Bindings=@Bindings,
        @CatalogBindings=@CatalogBindings,
        @TargetFlow=@TargetFlow,
        @InspectStage=@InspectStage,
        @LookupPolicies=@LookupPolicies,
        @ComparisonCollation=@ComparisonCollation,
        @TSqlVersion=@TSqlVersion,
        @MaxPackageBytes=@MaxPackageBytes,
        @MaxXmlCharacters=@MaxXmlCharacters,
        @MaxXmlNodes=@MaxXmlNodes,
        @MaxModelNodes=@MaxModelNodes,
        @MaxModelEdges=@MaxModelEdges,
        @MaxComponents=@MaxComponents,
        @MaxPaths=@MaxPaths,
        @MaxColumns=@MaxColumns,
        @MaxInputs=@MaxInputs,
        @MaxJsonDocumentBytes=@MaxJsonDocumentBytes,
        @MaxAllJsonBytes=@MaxAllJsonBytes,
        @MaxJsonNodes=@MaxJsonNodes,
        @MaxExpressionBytes=@MaxExpressionBytes,
        @MaxExpressionTokens=@MaxExpressionTokens,
        @MaxExpressionNodes=@MaxExpressionNodes,
        @MaxPlanUnits=@MaxPlanUnits,
        @MaxCatalogObjects=@MaxCatalogObjects,
        @MaxCatalogQueries=@MaxCatalogQueries,
        @MaxParserCalls=@MaxParserCalls,
        @MaxArtifacts=@MaxArtifacts,
        @MaxDiagnostics=@MaxDiagnostics,
        @MaxSqlArtifactBytes=@MaxSqlArtifactBytes,
        @MaxTotalOutputBytes=@MaxTotalOutputBytes,
        @MaxAnalysisMilliseconds=@MaxAnalysisMilliseconds,
        @ResultTable=@ResultTable,
        @KeepData=@KeepData,
        @Debug=@Debug,
        @Hilfe=@Hilfe;
    END TRY
    BEGIN CATCH
        DECLARE @message nvarchar(4000)=ERROR_MESSAGE(),@start int,@stop int,@safe nvarchar(2048);
        SET @start=CHARINDEX(N'TBX_SSISDBG_',@message);
        IF @start>0
        BEGIN
            SET @stop=CHARINDEX(NCHAR(10),@message,@start);
            SET @safe=SUBSTRING(@message,@start,CASE WHEN @stop>@start THEN @stop-@start ELSE 2048 END);
        END
        ELSE SET @safe=N'TBX_SSISDBG_sql_error: SQL-/CLR-Fehler '+CONVERT(nvarchar(12),ERROR_NUMBER())+N', State '+CONVERT(nvarchar(12),ERROR_STATE())+N'. Keine Ausgabe vertraulicher Fehlerpayloads.';
        THROW 50000,@safe,1;
    END CATCH;
END;
GO
