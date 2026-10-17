// Generiert aus Contracts/Api.json; nicht manuell parallel pflegen.
namespace Toolbelt.Tsql.SsisDebug
{
    internal static class HelpContract
    {
        internal const string Sql = @"SELECT CONVERT(varchar(16),'1.0') AS HelpContractVersion,
 CONVERT(sysname,N'toolbelt_tsql') AS SchemaName,CONVERT(sysname,@helpObjectName) AS ObjectName,
 CONVERT(varchar(32),v.Section) AS Section,CONVERT(int,v.Ordinal) AS Ordinal,
 CONVERT(sysname,v.ItemName) AS ItemName,CONVERT(varchar(256),CASE WHEN v.Section='PARAMETER' AND v.SqlDataType LIKE 'varchar(%' THEN 'n'+v.SqlDataType ELSE v.SqlDataType END) AS SqlDataType,
 CONVERT(bit,CASE WHEN v.Section='PARAMETER' AND v.SqlDataType IN('nvarchar(max)','varbinary(max)') THEN 1 ELSE v.IsRequired END) AS IsRequired,CONVERT(bit,v.IsNullable) AS IsNullable,
 CONVERT(nvarchar(4000),CASE WHEN v.Section='PARAMETER' AND v.SqlDataType IN('nvarchar(max)','varbinary(max)') THEN NULL ELSE v.DefaultValue END) AS DefaultValue,CONVERT(nvarchar(max),v.Description) AS Description,
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
ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1 WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 WHEN 'PERMISSION' THEN 4 ELSE 5 END,v.Ordinal;";
        internal const string Columns = @"[ArtifactKind],[TargetFlowId],[StageId],[Ordinal],[ComponentId],[EvidenceClass],[Severity],[DiagnosticCode],[IsComplete],[SafetyStatus],[IsExecutable],[Content],[DetailsJson]";
        internal const string Shape = @"[ArtifactKind] varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,[TargetFlowId] varchar(64) COLLATE Latin1_General_100_BIN2 NULL,[StageId] varchar(64) COLLATE Latin1_General_100_BIN2 NULL,[Ordinal] int NOT NULL,[ComponentId] nvarchar(4000) COLLATE Latin1_General_100_BIN2 NULL,[EvidenceClass] varchar(24) COLLATE Latin1_General_100_BIN2 NOT NULL,[Severity] varchar(16) COLLATE Latin1_General_100_BIN2 NULL,[DiagnosticCode] varchar(64) COLLATE Latin1_General_100_BIN2 NULL,[IsComplete] bit NOT NULL,[SafetyStatus] varchar(24) COLLATE Latin1_General_100_BIN2 NOT NULL,[IsExecutable] bit NOT NULL,[Content] nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,[DetailsJson] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL";
        internal const string Select = @"SELECT ISNULL([ArtifactKind],N'') COLLATE Latin1_General_100_BIN2 AS [ArtifactKind],[TargetFlowId] COLLATE Latin1_General_100_BIN2 AS [TargetFlowId],[StageId] COLLATE Latin1_General_100_BIN2 AS [StageId],ISNULL([Ordinal],CAST(0 AS int)) AS [Ordinal],[ComponentId] COLLATE Latin1_General_100_BIN2 AS [ComponentId],ISNULL([EvidenceClass],N'') COLLATE Latin1_General_100_BIN2 AS [EvidenceClass],[Severity] COLLATE Latin1_General_100_BIN2 AS [Severity],[DiagnosticCode] COLLATE Latin1_General_100_BIN2 AS [DiagnosticCode],ISNULL([IsComplete],CAST(0 AS bit)) AS [IsComplete],ISNULL([SafetyStatus],N'') COLLATE Latin1_General_100_BIN2 AS [SafetyStatus],ISNULL([IsExecutable],CAST(0 AS bit)) AS [IsExecutable],ISNULL([Content],N'') COLLATE Latin1_General_100_BIN2 AS [Content],[DetailsJson] COLLATE Latin1_General_100_BIN2 AS [DetailsJson] FROM OPENJSON(@rows) WITH ([ArtifactKind] varchar(32),[TargetFlowId] varchar(64),[StageId] varchar(64),[Ordinal] int,[ComponentId] nvarchar(4000),[EvidenceClass] varchar(24),[Severity] varchar(16),[DiagnosticCode] varchar(64),[IsComplete] bit,[SafetyStatus] varchar(24),[IsExecutable] bit,[Content] nvarchar(max),[DetailsJson] nvarchar(max))";
    }
}
