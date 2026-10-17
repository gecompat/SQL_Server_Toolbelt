-- ============================================================================
-- Generiert durch Scripts/New-ContractSources.py aus Contracts/Api.json.
-- Objekt: toolbelt_tsql.USP_ExplainSsisDataFlow; öffentliche T-SQL-Fassade.
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
(N'DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Erklärt einen begrenzten DTSX2-Datenfluss und erzeugt JSON-Eingabevorlagen sowie vollständige, einzeln prüfbare T-SQL-CTE-Batches mit NOLOCK. Paket und enthaltenes SQL werden beim Analysieren niemals ausgeführt.',NULL),
(N'PARAMETER',1,N'@PackageBytes',N'varbinary(max)',1,0,N'NULL',N'Genau ein DTSX2-Paket als UTF-8-/UTF-16-Binärwert, höchstens16MiB. Kein Dateizugriff.',NULL),
(N'PARAMETER',2,N'@Operation',N'varchar(32)',0,0,N'explain',N'Exakt bindings-template oder explain; NULL ungültig.',NULL),
(N'PARAMETER',3,N'@ProjectContext',N'nvarchar(max)',0,1,N'NULL',N'Optionaler Projektparameter-/Connection-Kontext, JSON-Schema1; keine Credentials.',NULL),
(N'PARAMETER',4,N'@Bindings',N'nvarchar(max)',0,1,N'NULL',N'Zurückgegebene vollständige JSON-Vorlage; nur values bearbeiten. Im Template-Modus NULL.',NULL),
(N'PARAMETER',5,N'@CatalogBindings',N'nvarchar(max)',0,1,N'NULL',N'Explizite Same-instance-Allowlist mit defaultDatabase, databases und connections; Template verlangt NULL.',NULL),
(N'PARAMETER',6,N'@TargetFlow',N'varchar(64)',0,1,N'NULL',N'Ausgegebene Zielfluss-ID; NULL berücksichtigt alle Ziele getrennt.',NULL),
(N'PARAMETER',7,N'@InspectStage',N'varchar(64)',0,1,N'NULL',N'NULL liefert Zielskript und Verzeichnis; all alle Stufen; konkrete ID verlangt TargetFlow.',NULL),
(N'PARAMETER',8,N'@LookupPolicies',N'nvarchar(max)',0,1,N'NULL',N'Optionale gebundene Auswahlordnung je Lookup. Standard beliebige, einmal materialisierte Auswahl.',NULL),
(N'PARAMETER',9,N'@ComparisonCollation',N'sysname',0,1,N'NULL',N'Bekannte explizite Vergleichscollation; NULL verwendet die zugeordnete Defaultdatenbank.',NULL),
(N'PARAMETER',10,N'@TSqlVersion',N'smallint',0,0,N'150',N'Exakt150,160 oder170; kein automatischer Dialektwechsel.',NULL),
(N'PARAMETER',11,N'@ResultTable',N'sysname',0,1,N'NULL',N'NULL liefert ein Resultset; sonst vorhandene lokale Temp-Tabelle nach Standardvertrag.',NULL),
(N'PARAMETER',12,N'@KeepData',N'bit',0,1,N'0',N'0 ersetzt,1 hängt an; NULL entspricht0. Kanonischer ResultTable-Helper.',NULL),
(N'PARAMETER',13,N'@Debug',N'tinyint',0,1,N'0',N'Nur redigierte Messages mit Ablauf/Zählern, keine Secretwerte oder zusätzlichen Resultsets.',NULL),
(N'PARAMETER',14,N'@Hilfe',N'bit',0,1,N'0',N'1 liefert ausschließlich standardisierte Hilfe, ignoriert alle Fach-/ResultTable-/Debugparameter.',NULL),
(N'RESULT_COLUMN',1,N'ArtifactKind',N'varchar(32)',1,0,NULL,N'BindingsTemplate, Workflow, StageIndex, PreparationSql, StageSql, TargetSql, CleanupSql, ColumnLineage oder Diagnostic.',NULL),
(N'RESULT_COLUMN',2,N'TargetFlowId',N'varchar(64)',1,1,NULL,N'Modellinterne Zielfluss-ID; keine dauerhafte Projektreferenz.',NULL),
(N'RESULT_COLUMN',3,N'StageId',N'varchar(64)',1,1,NULL,N'Modellinterne Prüfpunkt-ID, innerhalb derselben Paketbindung stabil.',NULL),
(N'RESULT_COLUMN',4,N'Ordinal',N'int',1,0,NULL,N'Globale1-basierte Ausgabeordnung.',NULL),
(N'RESULT_COLUMN',5,N'ComponentId',N'nvarchar(4000)',1,1,NULL,N'Ursprüngliche gebundene Komponenten-ID.',NULL),
(N'RESULT_COLUMN',6,N'EvidenceClass',N'varchar(24)',1,0,NULL,N'descriptive, translated, pragmatic, missing_context oder unsupported.',NULL),
(N'RESULT_COLUMN',7,N'Severity',N'varchar(16)',1,1,NULL,N'info, warning oder error für Diagnosen.',NULL),
(N'RESULT_COLUMN',8,N'DiagnosticCode',N'varchar(64)',1,1,NULL,N'Stabiler maschinenlesbarer Diagnosecode.',NULL),
(N'RESULT_COLUMN',9,N'IsComplete',N'bit',1,0,NULL,N'Benötigter Pfad und Kontext vollständig im V1-Profil vorhanden.',NULL),
(N'RESULT_COLUMN',10,N'SafetyStatus',N'varchar(24)',1,0,NULL,N'not_applicable, not_checked, passed oder blocked.',NULL),
(N'RESULT_COLUMN',11,N'IsExecutable',N'bit',1,0,NULL,N'Vollständiger, im gebundenen Profil geprüfter Batch; kein bereits ausgeführter Runtime-Nachweis.',NULL),
(N'RESULT_COLUMN',12,N'Content',N'nvarchar(max)',1,0,NULL,N'Artefaktinhalt, insbesondere vollständiger SQL-Prüfblock oder JSON-Vorlage.',NULL),
(N'RESULT_COLUMN',13,N'DetailsJson',N'nvarchar(max)',1,1,NULL,N'Zusätzliche gültige JSON-Metadaten.',NULL),
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
