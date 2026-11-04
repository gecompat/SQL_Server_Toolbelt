using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace Toolbelt.Tsql.SsisDebug
{
    internal static class ProcedureDefinition
    {
        internal static void ValidateOptions(Options options)
        {
            if (!options.ProcedureDefinition)
            {
                if (options.ProcedureSchema != null || options.ProcedureName != null)
                    throw new DebugFault("unresolved_binding", "ProcedureSchema und ProcedureName verlangen procedure-definition.");
                return;
            }
            if (String.IsNullOrEmpty(options.Target) || options.Stage != null)
                throw new DebugFault("unresolved_binding", "procedure-definition verlangt TargetFlow und InspectStage=NULL.");
            if (!ValidName(options.ProcedureSchema) || !ValidName(options.ProcedureName) ||
                !options.ProcedureName.StartsWith("USP_", StringComparison.Ordinal) || options.ProcedureName.Length == 4)
                throw new DebugFault("unresolved_binding", "ProcedureSchema und USP_-Name müssen gültige einzelne ASCII-Identifier sein.");
        }

        private static bool ValidName(string name)
        {
            return name != null && Regex.IsMatch(name, @"\A[A-Za-z][A-Za-z0-9_]{0,127}\z");
        }

        internal static void Emit(Options options, Bindings bindings, SqlSafety safety, Artifacts output,
            string target, Stage end, LookupCache[] units, HashSet<string> inputs)
        {
            var parameters = bindings.DeclarationOrder.Where(p => inputs.Contains(p.Key)).ToArray();
            var sources = safety.BoundObjects().ToArray();
            if (parameters.Length > 2096 || parameters.Length != inputs.Count || parameters.Any(p => p.Sensitive || p.Expression != null ||
                p.Kind == "system" || p.Kind == "context" || !NumericParameter(p.SqlType)) ||
                bindings.Databases.Count != 1 || sources.Length == 0 || sources.Any(o =>
                    o.Database != bindings.DefaultDatabase || o.Kind != "U" || o.ObjectId <= 0 || o.MemoryOptimized ||
                    o.External || o.SecurityFunctions.Count != 0 || o.Dependencies.Count != 0 ||
                    o.Columns.Any(c => c.Computed != null)))
            {
                output.Diagnostic("procedure_profile", end.Component,
                    "Prozedur verlangt numerische Szenariowerte und gewöhnliche Tabellen einer Datenbank ohne berechnete Spalten oder Sicherheitsprädikate.", target);
                return;
            }
            if (end.Columns.Select(c => c.Name).Distinct(StringComparer.OrdinalIgnoreCase).Count() != end.Columns.Count)
            {
                output.Diagnostic("procedure_profile", end.Component, "Zielspaltennamen müssen eindeutig sein.", target);
                return;
            }

            // Die validierten Plan-Units liefern Definition und INSERT SELECT.
            // Ein dynamischer Scope besitzt sämtliche Temps und bindet Werte typisiert.
            var last = units[units.Length - 1];
            string result = last.Name + "_result";
            string names = String.Join(",", end.Columns.Select(c => Util.Q(c.Name)));
            string aliases = String.Join(",", end.Columns.Select(c => Util.Q(c.Alias)));
            string shape = String.Join(",", end.Columns.Select(c => Util.Q(c.Name) + " " + c.Type +
                (IsText(c.Type) ? " COLLATE " + Util.CollationToken(c.Collation ?? bindings.Collation) : "") +
                (c.Nullable ? " NULL" : " NOT NULL")));
            var owned = units.Select(u => u.Name).Concat(new[] { result }).ToArray();
            string plan = String.Join("\n", units.Select(u => "CREATE TABLE " + Util.Q(u.Name) + " (" + u.Definition + ");\n" + u.Insert)) +
                "\nCREATE TABLE " + Util.Q(result) + " (" + shape + ");\nINSERT INTO " + Util.Q(result) + " (" + names +
                ") SELECT " + aliases + " FROM " + Util.Q(last.Name) + ";\n";
            safety.Generated(plan, bindings.DefaultDatabase, owned, true);
            var batch = new StringBuilder();
            batch.Append("IF CONVERT(varbinary(max),DB_NAME())<>CONVERT(varbinary(max),")
                .Append(Util.L(bindings.DefaultDatabase)).AppendLine(") THROW 50000,N'TBX_SSISDBG_catalog_drift: Falsche Datenbank.',1;");
            batch.AppendLine("IF COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1 OR COALESCE(HAS_PERMS_BY_NAME(N'sys.security_predicates',N'OBJECT',N'SELECT'),0)<>1 THROW 50000,N'TBX_SSISDBG_catalog_visibility: Vollständige Katalogsicht fehlt.',1;");
            foreach (var source in sources) batch.AppendLine(SourceGuard(source));
            foreach (string temp in owned)
                batch.Append("IF OBJECT_ID(").Append(Util.L("tempdb.." + Util.Q(temp)))
                    .AppendLine(") IS NOT NULL THROW 50000,N'TBX_SSISDBG_cache_ownership: Temp-Name bereits belegt.',1;");
            batch.Append(plan);
            // Die Quelle wird erneut geprüft, bevor Ergebnisdaten sichtbar werden.
            foreach (var source in sources) batch.AppendLine(SourceGuard(source));
            batch.Append("IF @Debug>0 PRINT N'SSIS Debug: Zielprojektion materialisiert.';\n")
                .Append("IF @ResultTable IS NULL BEGIN SELECT ").Append(names).Append(" FROM ").Append(Util.Q(result)).AppendLine("; RETURN; END;");
            string insert = " (" + names + ") SELECT " + names + " FROM " + Util.Q(result) + ";";
            batch.Append("DECLARE @write nvarchar(max)=CAST(N'INSERT INTO ' AS nvarchar(max))+QUOTENAME(@ResultTable)+")
                .Append(Util.L(insert)).AppendLine(";")
                .AppendLine("SET XACT_ABORT ON;")
                .AppendLine("BEGIN TRY")
                .AppendLine("BEGIN TRANSACTION;")
                .Append("EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=")
                .Append(Util.L(result)).AppendLine(",@KeepData=@KeepData,@Debug=0,@Hilfe=0;")
                .AppendLine("EXEC sys.sp_executesql @write;")
                .AppendLine("COMMIT TRANSACTION;")
                .AppendLine("END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;");

            var parameterDefinitions = parameters.Select(p => p.SqlName + " " + p.SqlType).ToArray();
            var arguments = parameters.Select(p => p.SqlName + "=" + p.SqlName).Concat(new[] { "@ResultTable=@ResultTable", "@KeepData=@KeepData", "@Debug=@Debug" });
            string fullName = Util.Q(options.ProcedureSchema) + "." + Util.Q(options.ProcedureName);
            var definition = new StringBuilder("CREATE PROCEDURE ").Append(fullName).AppendLine()
                .AppendLine(String.Join(",\n", parameterDefinitions.Select(p => p + "=NULL").Concat(new[] {
                    "@ResultTable sysname=NULL", "@KeepData bit=0", "@Debug tinyint=0", "@Hilfe bit=0" })))
                .AppendLine("WITH EXECUTE AS CALLER\nAS\nBEGIN\nSET NOCOUNT ON;")
                .AppendLine(Help(options, end, parameters, fullName))
                .AppendLine("SET XACT_ABORT OFF;")
                .AppendLine("IF @@TRANCOUNT<>0 OR (@@OPTIONS & 2)<>0 THROW 50000,N'TBX_SSISDBG_cache_context_changed: Ausführung verlangt eine Sitzung ohne Callertransaktion und IMPLICIT_TRANSACTIONS OFF.',1;")
                .AppendLine("IF @ResultTable IS NOT NULL AND (LEFT(@ResultTable,1)<>N'#' OR LEFT(@ResultTable,2)=N'##' OR DATALENGTH(@ResultTable) NOT BETWEEN 4 AND 232 OR OBJECT_ID(N'tempdb..'+QUOTENAME(@ResultTable),N'U') IS NULL) THROW 50000,N'TBX_SSISDBG_unresolved_binding: Vorhandene lokale ResultTable erforderlich.',1;");
            foreach (Input p in parameters)
                definition.Append("IF ").Append(p.SqlName).Append(" IS NULL THROW 50000,")
                    .Append(Util.L("TBX_SSISDBG_unresolved_binding: " + p.SqlName + " ist erforderlich.")).AppendLine(",1;");
            definition.Append("DECLARE @statement nvarchar(max)=").Append(Util.L(batch.ToString())).AppendLine(";")
                .Append("EXEC sys.sp_executesql @statement,")
                .Append(Util.L(String.Join(",", parameterDefinitions.Concat(new[] { "@ResultTable sysname", "@KeepData bit", "@Debug tinyint" }))))
                .Append(',').Append(String.Join(",", arguments)).AppendLine(";")
                .AppendLine("END;");
            string ddl = definition.ToString().Replace("\r\n", "\n");
            output.Limits.Check("sqlArtifactBytes", 2L * ddl.Length);
            var parsed = (TSqlScript)safety.Parse(ddl);
            if (parsed.Batches.Count != 1 || parsed.Batches[0].Statements.Count != 1 || !(parsed.Batches[0].Statements[0] is CreateProcedureStatement))
                throw new DebugFault("unsafe_statement", "Prozedurdefinition muss aus genau einem CREATE bestehen.");
            string manifest = Json.Write(Json.Obj("schemaVersion", 1, "database", bindings.DefaultDatabase,
                "schema", options.ProcedureSchema, "name", options.ProcedureName, "targetFlow", target,
                "tsqlVersion", options.Version, "planSha256", Util.Hash(plan), "definitionSha256", Util.Hash(ddl),
                "catalogBinding", safety.CatalogBinding(),
                "parameters", parameters.Select(p => (object)Json.Obj("name", p.SqlName, "inputName", p.Name, "inputScope", p.Scope,
                    "sqlType", p.SqlType, "required", true)).ToArray(),
                "columns", end.Columns.Select(c => (object)Json.Obj("name", c.Name, "sqlType", c.Type, "nullable", c.Nullable)).ToArray()), bindings.Limits);
            output.Add(new Artifact { Kind = "ProcedureDefinition", Target = target, Stage = end.Id, Component = end.Component,
                Content = ddl, Safety = "passed", Evidence = "translated" });
            output.Add(new Artifact { Kind = "ProcedureManifest", Target = target, Stage = end.Id, Component = end.Component, Content = manifest });
        }

        private static bool NumericParameter(string type)
        {
            return type == "int" || type == "bigint" || (type != null && Regex.IsMatch(type, @"\Adecimal\([0-9]{1,2},[0-9]{1,2}\)\z"));
        }

        private static bool IsText(string type)
        {
            return type.StartsWith("varchar", StringComparison.Ordinal) || type.StartsWith("nvarchar", StringComparison.Ordinal) ||
                type.StartsWith("char", StringComparison.Ordinal) || type.StartsWith("nchar", StringComparison.Ordinal);
        }

        private static string SourceGuard(BoundObject source)
        {
            string id = Number(source.ObjectId);
            string modified = Util.L(source.Modified.ToString("yyyy-MM-ddTHH:mm:ss.fff", CultureInfo.InvariantCulture));
            string columns = String.Join(",", source.Columns.Select(c => "(" + Number(c.ColumnId) + "," +
                Util.L(c.Name) + "," + Number(c.SystemTypeId) + "," + Number(c.UserTypeId) + "," + Number(c.Length) +
                "," + Number(c.Precision) + "," + Number(c.Scale) + "," + (c.Nullable ? "1" : "0") + "," +
                (c.Collation == null ? "NULL" : Util.L(c.Collation)) + ")"));
            return "IF ISNULL(OBJECT_ID(" + Util.L(source.Qualified) + ",N'U'),0)<>" + id +
                " OR NOT EXISTS(SELECT 1 FROM sys.tables WHERE object_id=" + id + " AND modify_date=CONVERT(datetime," +
                modified + ",126) AND is_memory_optimized=0 AND is_external=0)\n" +
                " OR (SELECT COUNT(*) FROM sys.columns WHERE object_id=" + id + ")<>" + Number(source.Columns.Count) + "\n" +
                " OR EXISTS(SELECT e.column_id,CONVERT(varbinary(256),e.name),e.system_type_id,e.user_type_id,e.max_length," +
                "e.precision,e.scale,e.is_nullable,CONVERT(varbinary(256),e.collation_name) FROM (VALUES " + columns + ") " +
                "AS e(column_id,name,system_type_id,user_type_id,max_length,precision,scale,is_nullable,collation_name)\n" +
                "EXCEPT SELECT column_id,CONVERT(varbinary(256),name),system_type_id,user_type_id,max_length,precision,scale," +
                "is_nullable,CONVERT(varbinary(256),collation_name) FROM sys.columns WHERE object_id=" + id + " AND is_computed=0)\n" +
                " OR EXISTS(SELECT 1 FROM sys.security_predicates AS p JOIN sys.security_policies AS s ON s.object_id=p.object_id WHERE p.target_object_id=" +
                id + " AND s.is_enabled=1) THROW 50000,N'TBX_SSISDBG_catalog_drift: Gebundene Quelle geändert oder nicht sichtbar.',1;";
        }

        private static string Number(int value)
        {
            return value.ToString(CultureInfo.InvariantCulture);
        }

        private static string Help(Options options, Stage end, Input[] parameters, string fullName)
        {
            var rows = new List<string>();
            rows.Add("(N'DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,CAST(N'Lesende Zielprojektion aus dem gebundenen SSIS-Debugplan.' AS nvarchar(max)),NULL)");
            int ordinal = 0;
            foreach (Input p in parameters)
                rows.Add("(N'PARAMETER'," + (++ordinal) + "," + Util.L(p.SqlName) + "," + Util.L(p.SqlType) +
                    ",1,0,N'NULL',N'Typisierter Szenariowert für den gebundenen Eingabekey. Im Normalaufruf Pflicht und nicht NULL. SQL-Server-Konvertierung und Grenzen des deklarierten Typs gelten.',NULL)");
            rows.Add("(N'PARAMETER'," + (++ordinal) + ",N'@ResultTable',N'sysname',0,1,N'NULL',N'NULL liefert SELECT. Andernfalls Name einer vorhandenen lokalen #Temp-Tabelle, 2 bis 116 UTF-16-Einheiten, für das fachliche Resultset.',NULL)");
            rows.Add("(N'PARAMETER'," + (++ordinal) + ",N'@KeepData',N'bit',0,1,N'0',N'0 oder NULL ersetzt, 1 hängt bei kompatibler ResultTable an. Nur mit ResultTable wirksam.',NULL)");
            rows.Add("(N'PARAMETER'," + (++ordinal) + ",N'@Debug',N'tinyint',0,1,N'0',N'0 oder NULL bleibt still. 1 bis 255 meldet den Abschluss der Materialisierung in Messages.',NULL)");
            rows.Add("(N'PARAMETER'," + (++ordinal) + ",N'@Hilfe',N'bit',0,1,N'0',N'1 liefert nur diese Hilfe. 0 oder NULL führt die Zielprojektion aus.',NULL)");
            ordinal = 0;
            foreach (StageColumn c in end.Columns)
                rows.Add("(N'RESULT_COLUMN'," + (++ordinal) + "," + Util.L(c.Name) + "," + Util.L(c.Type) + ",NULL," +
                    (c.Nullable ? "1" : "0") + ",NULL,N'Gebundene Zielspalte.',NULL)");
            rows.Add("(N'EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Hilfe zur installierten Zielprojektion.'," +
                Util.L("EXEC " + fullName + " @Hilfe=1;") + ")");
            return "IF @Hilfe=1 BEGIN\nSELECT CONVERT(varchar(16),'1.0') AS HelpContractVersion,CONVERT(sysname," +
                Util.L(options.ProcedureSchema) + ") AS SchemaName,CONVERT(sysname," + Util.L(options.ProcedureName) +
                ") AS ObjectName,CONVERT(varchar(32),v.Section) AS Section,v.Ordinal,CONVERT(sysname,v.ItemName) AS ItemName," +
                "CONVERT(varchar(256),v.SqlDataType) AS SqlDataType,CONVERT(bit,v.IsRequired) AS IsRequired," +
                "CONVERT(bit,v.IsNullable) AS IsNullable,CONVERT(nvarchar(4000),v.DefaultValue) AS DefaultValue," +
                "CONVERT(nvarchar(max),v.Description) AS Description,CONVERT(nvarchar(max),v.ExampleSql) AS ExampleSql\nFROM (VALUES\n" +
                String.Join(",\n", rows) + "\n) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)\n" +
                "ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1 WHEN 'RESULT_COLUMN' THEN 2 ELSE 3 END,v.Ordinal;\nRETURN; END;";
        }
    }
}
