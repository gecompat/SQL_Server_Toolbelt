using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.Globalization;
using System.Linq;
using Microsoft.SqlServer.Server;

namespace Toolbelt.Tsql.SsisDebug
{
    internal sealed class SqlCatalog : ICatalog
    {
        private readonly SqlConnection connection; private readonly Budget budget;
        private readonly Dictionary<string, int> pages = new Dictionary<string, int>(StringComparer.Ordinal);
        private readonly Dictionary<string, bool> collations = new Dictionary<string, bool>(StringComparer.Ordinal);
        private readonly Dictionary<string, string> names = new Dictionary<string, string>(StringComparer.Ordinal);
        internal SqlCatalog(SqlConnection c, Budget b) { connection = c; budget = b; }
        private SqlCommand Command(string text)
        { budget.Check(); budget.CheckLimit("catalogQueries", ++budget.CatalogCalls); return new SqlCommand(text, connection); }
        public string Collation(string database)
        {
            using (var cmd = Command("SELECT CONVERT(nvarchar(128), DATABASEPROPERTYEX(@db,N'Collation')) WHERE HAS_DBACCESS(@db)=1;"))
            { cmd.Parameters.Add("@db", SqlDbType.NVarChar, 128).Value = database; object value = cmd.ExecuteScalar(); if (value == null || value == DBNull.Value) throw new DebugFault("catalog_visibility", "Datenbank nicht zugänglich."); return (string)value; }
        }
        public bool IsCollation(string name)
        {
            if (name == null) return false; bool result;
            if (collations.TryGetValue(name, out result)) return result;
            using (var cmd = Command("SELECT COUNT_BIG(*) FROM sys.fn_helpcollations() WHERE name=@name COLLATE Latin1_General_100_BIN2;"))
            { cmd.Parameters.Add("@name", SqlDbType.NVarChar, 128).Value = name; result = (long)cmd.ExecuteScalar() == 1; }
            collations.Add(name, result); return result;
        }
        public int CodePage(string collation)
        {
            int value; if (pages.TryGetValue(collation, out value)) return value;
            using (var cmd = Command("SELECT CONVERT(int,COLLATIONPROPERTY(@name,N'CodePage'));"))
            { cmd.Parameters.Add("@name", SqlDbType.NVarChar, 128).Value = collation; object raw = cmd.ExecuteScalar(); if (raw == null || raw == DBNull.Value) throw new DebugFault("catalog_visibility", "Codepage nicht sichtbar."); value = (int)raw; }
            pages.Add(collation, value); return value;
        }
        public string BindIdentifier(string database, IEnumerable<string> candidates, string name)
        {
            var list = candidates.Distinct(StringComparer.Ordinal).OrderBy(x => x, StringComparer.Ordinal).ToList(); if (list.Count == 0) return null;
            // Ordinal gleiche Namen brauchen keine Collation-Heuristik. Mehrere
            // äquivalente Namen werden trotzdem über den tatsächlichen DB-Kontext geprüft.
            string json = Json.Write(list, budget.Limits); string key = database + "\0" + name + "\0" + json, result;
            if (names.TryGetValue(key, out result)) return result;
            using (var cmd = Command("EXEC " + Util.Q(database) + ".sys.sp_executesql N'SELECT CONVERT(nvarchar(128),j.value) FROM OPENJSON(@names) AS j WHERE j.value COLLATE DATABASE_DEFAULT=@name COLLATE DATABASE_DEFAULT;',N'@names nvarchar(max),@name nvarchar(128)',@names,@name;"))
            {
                cmd.Parameters.Add("@names", SqlDbType.NVarChar, -1).Value = json; cmd.Parameters.Add("@name", SqlDbType.NVarChar, 128).Value = name;
                using (var r = cmd.ExecuteReader()) { result = r.Read() ? r.GetString(0) : null; if (r.Read()) throw new DebugFault("unresolved_binding", "SQL-Identifier ist im tatsächlichen DB-Kontext mehrdeutig."); }
            }
            names.Add(key, result); return result;
        }
        private const string MetadataSql = @"
IF COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1
 OR COALESCE(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1
 OR COALESCE(HAS_PERMS_BY_NAME(N'sys.security_predicates',N'OBJECT',N'SELECT'),0)<>1
 THROW 50000,N'TBX_SSISDBG_catalog_visibility: Vollständige Katalogsicht fehlt.',1;
DECLARE @oid int;
SELECT @oid=o.object_id FROM sys.objects AS o WITH (NOLOCK)
JOIN sys.schemas AS s WITH (NOLOCK) ON s.schema_id=o.schema_id
WHERE s.name=COALESCE(@schema,SCHEMA_NAME()) AND o.name=@name;
IF @oid IS NULL AND @schema IS NULL SELECT @oid=o.object_id FROM sys.objects AS o WITH (NOLOCK) JOIN sys.schemas AS s WITH (NOLOCK) ON s.schema_id=o.schema_id WHERE s.name=N'dbo' AND o.name=@name;
IF EXISTS(SELECT 1 FROM sys.sql_modules AS m WITH (NOLOCK) WHERE m.object_id=@oid AND DATALENGTH(m.definition)>2097152)
 THROW 50000,N'TBX_SSISDBG_resource_limit: Moduldefinition zu groß.',1;
SELECT o.object_id,o.type,m.definition,y.base_object_name,CONVERT(bit,COALESCE(t.is_memory_optimized,0)),
 CASE WHEN x.object_id IS NULL THEN CAST(0 AS bit) ELSE CAST(1 AS bit) END,o.modify_date,
 s.name,o.name
FROM sys.objects AS o WITH (NOLOCK)
JOIN sys.schemas AS s WITH (NOLOCK) ON s.schema_id=o.schema_id
LEFT JOIN sys.tables AS t WITH (NOLOCK) ON t.object_id=o.object_id
LEFT JOIN sys.sql_modules AS m WITH (NOLOCK) ON m.object_id=o.object_id
LEFT JOIN sys.synonyms AS y WITH (NOLOCK) ON y.object_id=o.object_id
LEFT JOIN sys.external_tables AS x WITH (NOLOCK) ON x.object_id=o.object_id
WHERE o.object_id=@oid;
SELECT c.column_id,c.name,bt.name,c.max_length,c.precision,c.scale,c.is_nullable,c.collation_name,
 cc.definition,ut.is_user_defined,ut.is_assembly_type
FROM sys.columns AS c WITH (NOLOCK)
JOIN sys.types AS ut WITH (NOLOCK) ON ut.user_type_id=c.user_type_id
JOIN sys.types AS bt WITH (NOLOCK) ON bt.user_type_id=c.system_type_id AND bt.system_type_id=c.system_type_id
LEFT JOIN sys.computed_columns AS cc WITH (NOLOCK) ON cc.object_id=c.object_id AND cc.column_id=c.column_id
WHERE c.object_id=@oid ORDER BY c.column_id;
SELECT DISTINCT p.object_id,p.security_predicate_id,d.referenced_server_name,d.referenced_database_name,
 d.referenced_schema_name,d.referenced_entity_name,f.type
FROM sys.security_predicates AS p WITH (NOLOCK)
JOIN sys.security_policies AS policy WITH (NOLOCK) ON policy.object_id=p.object_id AND policy.is_enabled=1
LEFT JOIN sys.sql_expression_dependencies AS d WITH (NOLOCK) ON d.referencing_id=p.object_id AND (d.referenced_id<>p.target_object_id OR d.referenced_id IS NULL)
LEFT JOIN sys.objects AS f WITH (NOLOCK) ON f.object_id=d.referenced_id
WHERE p.target_object_id=@oid
ORDER BY p.object_id,p.security_predicate_id,d.referenced_server_name,d.referenced_database_name,d.referenced_schema_name,d.referenced_entity_name,f.type;
SELECT d.referenced_server_name,d.referenced_database_name,COALESCE(s.name,d.referenced_schema_name),COALESCE(o.name,d.referenced_entity_name),d.referenced_id,d.is_caller_dependent,d.is_ambiguous,
 CASE WHEN d.referenced_id=@oid AND d.referenced_server_name IS NULL AND d.referenced_database_name IS NULL
  AND d.referencing_minor_id>0 AND d.referenced_minor_id>0 AND d.is_caller_dependent=0 AND d.is_ambiguous=0
  AND EXISTS(SELECT 1 FROM sys.computed_columns cc WITH(NOLOCK) WHERE cc.object_id=@oid AND cc.column_id=d.referencing_minor_id)
  AND EXISTS(SELECT 1 FROM sys.columns c WITH(NOLOCK) WHERE c.object_id=@oid AND c.column_id=d.referenced_minor_id)
  THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END,
 d.referencing_minor_id,d.referenced_minor_id
FROM sys.sql_expression_dependencies AS d WITH (NOLOCK)
LEFT JOIN sys.objects AS o WITH (NOLOCK) ON o.object_id=d.referenced_id
LEFT JOIN sys.schemas AS s WITH (NOLOCK) ON s.schema_id=o.schema_id
WHERE d.referencing_id=@oid AND d.referenced_class=1
ORDER BY d.referenced_server_name,d.referenced_database_name,COALESCE(s.name,d.referenced_schema_name),COALESCE(o.name,d.referenced_entity_name),d.referenced_id,d.referencing_minor_id,d.referenced_minor_id;";
        public BoundObject Resolve(string database, string schema, string name)
        {
            // Nur Identifier aus der expliziten Allowlist; Definitionen/Suchwerte
            // bleiben Datenparameter. Das feste Systemverfahren ändert keinen Caller-DB-Kontext.
            using (var cmd = Command("EXEC " + Util.Q(database) + ".sys.sp_executesql @sql,N'@schema sysname,@name sysname',@schema,@name;"))
            {
                cmd.Parameters.Add("@sql", SqlDbType.NVarChar, -1).Value = MetadataSql;
                cmd.Parameters.Add("@schema", SqlDbType.NVarChar, 128).Value = (object)schema ?? DBNull.Value;
                cmd.Parameters.Add("@name", SqlDbType.NVarChar, 128).Value = name;
                using (var r = cmd.ExecuteReader())
                {
                    if (!r.Read()) return null;
                    var o = new BoundObject { Database = database, Schema = r.GetString(7), Name = r.GetString(8), Kind = r.GetString(1).Trim(), Definition = r.IsDBNull(2) ? null : r.GetString(2), Synonym = r.IsDBNull(3) ? null : r.GetString(3), MemoryOptimized = r.GetBoolean(4), External = r.GetBoolean(5) };
                    var facts = new List<object> { r.GetInt32(0), o.Kind, o.Definition, o.Synonym, o.MemoryOptimized, o.External, r.GetDateTime(6).ToString("O", CultureInfo.InvariantCulture), o.Schema, o.Name };
                    if (r.Read() || !r.NextResult()) throw new DebugFault("catalog_drift", "Objektmetadaten inkonsistent.");
                    while (r.Read())
                    {
                        budget.Check(); Budget.Limit(facts.Count, 65536);
                        Budget.Limit(o.Columns.Count + 1, 8192);
                        string type = r.GetBoolean(9) || r.GetBoolean(10) ? null : CatalogType(r.GetString(2), r.GetInt16(3), r.GetByte(4), r.GetByte(5));
                        var c = new BoundColumn { Name = r.GetString(1), SqlType = type, Nullable = r.GetBoolean(6), Collation = r.IsDBNull(7) ? null : r.GetString(7), Computed = r.IsDBNull(8) ? null : r.GetString(8) };
                        o.Columns.Add(c); facts.Add(Json.Obj("id", r.GetInt32(0), "name", c.Name, "type", type, "nullable", c.Nullable, "collation", c.Collation, "computed", c.Computed));
                    }
                    if (!r.NextResult()) throw new DebugFault("catalog_drift", "RLS-Metadaten fehlen.");
                    while (r.Read())
                    {
                        budget.Check(); Budget.Limit(facts.Count, 65536);
                        if (!r.IsDBNull(2) || !r.IsDBNull(3) || r.IsDBNull(4) || r.IsDBNull(5) || r.IsDBNull(6) || (r.GetString(6).Trim() != "IF" && r.GetString(6).Trim() != "FN")) throw new DebugFault("unresolved_dependency", "Sicherheitsprädikat nicht vollständig gebunden.");
                        string f = r.GetString(4) + "\0" + r.GetString(5); if (!o.SecurityFunctions.Contains(f)) o.SecurityFunctions.Add(f);
                        facts.Add(Json.Obj("policy", r.GetInt32(0), "predicate", r.GetInt32(1), "function", f));
                    }
                    if (!r.NextResult()) throw new DebugFault("catalog_drift", "Dependencykatalog fehlt.");
                    while (r.Read())
                    {
                        budget.Check(); Budget.Limit(facts.Count, 65536);
                        if (!r.IsDBNull(0)) throw new DebugFault("unresolved_dependency", "Remoteabhängigkeit nicht freigegeben.");
                        if (r.IsDBNull(2) || r.IsDBNull(3) || r.GetBoolean(5) || r.GetBoolean(6)) throw new DebugFault("unresolved_dependency", "Moduldependency nicht eindeutig gebunden.");
                        // Eine berechnete Spalte verweist regulär auf andere
                        // Spalten derselben Tabelle. Das ist keine rekursive
                        // Modulabhängigkeit. Nur die katalogbelegte interne
                        // Spaltenkante ausnehmen; Definition und Kante bleiben
                        // vollständig in der Driftbindung. UDF-/Viewkanten und
                        // unklare/remote Referenzen durchlaufen weiter den Guard.
                        bool localComputed = o.Kind == "U" && r.GetBoolean(7);
                        if (!localComputed) o.Dependencies.Add(new[] { r.IsDBNull(1) ? database : r.GetString(1), r.GetString(2), r.GetString(3) });
                        // NULL-ID wird nicht zu PASS erklärt. Die tatsächliche Bindung
                        // jeder AST-Referenz erfolgt zusätzlich über den gleichen Adapter.
                        facts.Add(Json.Obj("database", r.IsDBNull(1) ? null : r.GetString(1), "schema", r.IsDBNull(2) ? null : r.GetString(2), "entity", r.IsDBNull(3) ? null : r.GetString(3), "id", r.IsDBNull(4) ? null : (object)r.GetInt32(4), "internalComputed", localComputed, "sourceColumnId", r.GetInt32(8), "targetColumnId", r.GetInt32(9)));
                    }
                    o.Fingerprint = Util.Hash(Json.Write(facts, budget.Limits)); return o;
                }
            }
        }
        private static string CatalogType(string t, int length, int precision, int scale)
        {
            switch (t)
            {
                case "varchar": case "char": case "nvarchar": case "nchar": case "varbinary": case "binary":
                    return t + "(" + (length == -1 ? "max" : (t.StartsWith("n", StringComparison.Ordinal) ? length / 2 : length).ToString(CultureInfo.InvariantCulture)) + ")";
                case "decimal": case "numeric": return "decimal(" + precision + "," + scale + ")";
                case "datetime2": case "time": return t + "(" + scale + ")";
                case "datetime": case "smalldatetime": case "money": case "smallmoney": return t;
                case "float": return "float(53)";
                case "bit": case "tinyint": case "smallint": case "int": case "bigint": case "real": case "date": case "uniqueidentifier": return t;
                default: return null;
            }
        }
    }

    public static class SsisDebugProvider
    {
        private static string Value(SqlString s) { return s.IsNull ? null : s.Value; }
        [SqlProcedure]
        public static void ExplainSsisDataFlow(SqlBytes packageBytes, SqlString operation, SqlString projectContext, SqlString bindings, SqlString catalogBindings, SqlString targetFlow, SqlString inspectStage, SqlString lookupPolicies, SqlString comparisonCollation, SqlInt16 tSqlVersion,
            SqlInt64 maxPackageBytes, SqlInt64 maxXmlCharacters, SqlInt64 maxXmlNodes, SqlInt64 maxModelNodes, SqlInt64 maxModelEdges, SqlInt64 maxComponents, SqlInt64 maxPaths, SqlInt64 maxColumns, SqlInt64 maxInputs,
            SqlInt64 maxJsonDocumentBytes, SqlInt64 maxAllJsonBytes, SqlInt64 maxJsonNodes, SqlInt64 maxExpressionBytes, SqlInt64 maxExpressionTokens, SqlInt64 maxExpressionNodes, SqlInt64 maxPlanUnits,
            SqlInt64 maxCatalogObjects, SqlInt64 maxCatalogQueries, SqlInt64 maxParserCalls, SqlInt64 maxArtifacts, SqlInt64 maxDiagnostics, SqlInt64 maxSqlArtifactBytes, SqlInt64 maxTotalOutputBytes, SqlInt64 maxAnalysisMilliseconds,
            SqlString resultTable, SqlBoolean keepData, SqlByte debug, SqlBoolean hilfe)
        {
            using (var connection = new SqlConnection("context connection=true"))
            {
                connection.Open();
                if (!hilfe.IsNull && hilfe.Value)
                {
                    using (var help = new SqlCommand(HelpContract.Sql, connection))
                    { help.Parameters.Add("@helpObjectName", SqlDbType.NVarChar, 128).Value = "USP_ExplainSsisDataFlowInternal"; SqlContext.Pipe.ExecuteAndSend(help); }
                    return;
                }
                var options = new Options { Operation = Value(operation), ProjectContext = Value(projectContext), Bindings = Value(bindings), CatalogBindings = Value(catalogBindings), Target = Value(targetFlow), Stage = Value(inspectStage), LookupPolicies = Value(lookupPolicies), ComparisonCollation = Value(comparisonCollation), Version = tSqlVersion.IsNull ? -1 : tSqlVersion.Value };
                options.Limits = ResourceOptions.FromSqlParameters(maxPackageBytes,maxXmlCharacters,maxXmlNodes,maxModelNodes,maxModelEdges,maxComponents,maxPaths,maxColumns,maxInputs,
                    maxJsonDocumentBytes,maxAllJsonBytes,maxJsonNodes,maxExpressionBytes,maxExpressionTokens,maxExpressionNodes,maxPlanUnits,maxCatalogObjects,maxCatalogQueries,maxParserCalls,
                    maxArtifacts,maxDiagnostics,maxSqlArtifactBytes,maxTotalOutputBytes,maxAnalysisMilliseconds);
                ResourceOptions.Resolve(options.ProjectContext, options.Operation, options.Bindings, options.Limits, out options.ResourceContextV2, out options.BindingProfile, out options.ProjectContextValue);
                var budget = new Budget();
                using (var state = new SqlCommand("SELECT XACT_STATE();", connection)) if (Convert.ToInt32(state.ExecuteScalar(), CultureInfo.InvariantCulture) == -1) throw new DebugFault("unresolved_binding", "Callertransaktion ist nicht schreibfähig.");
                using (var dependencies = new SqlCommand(DependencyPins.Sql, connection)) { budget.CatalogCalls++; dependencies.ExecuteNonQuery(); }
                budget.Limits = options.Limits;
                long allJsonBytes = 0;
                foreach (string json in new[] { options.Bindings, options.CatalogBindings, options.LookupPolicies })
                {
                    if (json == null) continue; budget.CheckLimit("jsonDocumentBytes", (long)json.Length * 2); allJsonBytes += (long)json.Length * 2;
                }
                budget.CheckLimit("allJsonBytes", allJsonBytes);
                foreach (string json in new[] { options.Bindings, options.CatalogBindings, options.LookupPolicies })
                {
                    if (json == null) continue; Json.Parse(json, options.Limits);
                    using (var validate = new SqlCommand("IF ISJSON(@j)<>1 THROW 50000,N'TBX_SSISDBG_invalid_template: Ungültiges JSON.',1; SELECT COUNT_BIG(*) FROM OPENJSON(@j);", connection))
                    { validate.Parameters.Add("@j", SqlDbType.NVarChar, -1).Value = json; validate.ExecuteScalar(); }
                }
                if (options.ProjectContext != null && options.ProjectContextValue != null)
                {
                    using (var validate = new SqlCommand("IF ISJSON(@j)<>1 THROW 50000,N'TBX_SSISDBG_invalid_template: Ungültiges JSON.',1; SELECT COUNT_BIG(*) FROM OPENJSON(@j);", connection))
                    { validate.Parameters.Add("@j", SqlDbType.NVarChar, -1).Value = options.ProjectContext; validate.ExecuteScalar(); }
                }
                if (packageBytes.IsNull) throw new DebugFault("unresolved_binding", "PackageBytes erforderlich."); budget.CheckLimit("packageBytes", packageBytes.Length);
                Artifacts result = Engine.Analyze(packageBytes.Value, options, new SqlCatalog(connection, budget), budget);
                if (!debug.IsNull && debug.Value > 0) SqlContext.Pipe.Send("SSIS Debug: Analyse abgeschlossen; Artefakte=" + result.Rows.Count.ToString(CultureInfo.InvariantCulture) + "; SQL-Prüfeinheiten=" + budget.SqlCalls.ToString(CultureInfo.InvariantCulture) + ".");
                Send(connection, result, Value(resultTable), !keepData.IsNull && keepData.Value);
            }
        }
        internal const string Columns = HelpContract.Columns;
        internal const string Shape = HelpContract.Shape;
        private static void Send(SqlConnection connection, Artifacts output, string resultTable, bool keep)
        {
            var rows = output.Rows.Select(a => (object)Json.Obj("ArtifactKind", a.Kind, "TargetFlowId", a.Target, "StageId", a.Stage, "Ordinal", a.Ordinal, "ComponentId", a.Component, "EvidenceClass", a.Evidence, "Severity", a.Severity, "DiagnosticCode", a.Code, "IsComplete", a.Complete, "SafetyStatus", a.Safety, "IsExecutable", a.Executable, "Content", a.Content, "DetailsJson", a.Details)).ToList();
            string json = Json.Write(rows, output.Limits);
            string select = HelpContract.Select;
            if (resultTable == null)
            {
                using (var cmd = new SqlCommand(select + " ORDER BY [Ordinal];", connection)) { cmd.Parameters.Add("@rows", SqlDbType.NVarChar, -1).Value = json; SqlContext.Pipe.ExecuteAndSend(cmd); }
                return;
            }
            if (!resultTable.StartsWith("#", StringComparison.Ordinal) || resultTable.StartsWith("##", StringComparison.Ordinal) || resultTable.Length > 116 || resultTable.Length < 2) throw new DebugFault("unresolved_binding", "Nur vorhandene lokale ResultTable erlaubt.");
            string helper = "#tbx_SsisDebug_ResultShape_" + Guid.NewGuid().ToString("N"), savepoint = "tbx" + Guid.NewGuid().ToString("N").Substring(0,29);
            // Erst nach dem Helper kompilieren: die bestehende Zieltemp kann
            // vor der Schemaanpassung noch ausschließlich die Dummyspalte haben.
            // @insert enthält nur festen Adapter-SQL und den gequoteten Tempnamen;
            // die Artefakte bleiben ein separater Datenparameter.
            string insert = "INSERT INTO " + Util.Q(resultTable) + " (" + Columns + ") " + select + ";";
            string sql = "DECLARE @owned bit=CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END;\nIF @owned=1 BEGIN TRANSACTION; ELSE SAVE TRANSACTION " + savepoint + ";\nBEGIN TRY\nCREATE TABLE " + Util.Q(helper) + " (" + Shape + ");\nEXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@target,@LikeTable=@like,@KeepData=@keep,@Debug=0,@Hilfe=0;\nEXEC sys.sp_executesql @insert,N'@rows nvarchar(max)',@rows=@rows;\nDROP TABLE " + Util.Q(helper) + ";\nIF @owned=1 COMMIT TRANSACTION;\nEND TRY\nBEGIN CATCH\nIF XACT_STATE()<>0 AND @owned=1 ROLLBACK TRANSACTION; ELSE IF XACT_STATE()=1 ROLLBACK TRANSACTION " + savepoint + ";\nTHROW;\nEND CATCH;";
            using (var cmd = new SqlCommand(sql, connection))
            {
                cmd.Parameters.Add("@rows", SqlDbType.NVarChar, -1).Value = json;
                cmd.Parameters.Add("@insert", SqlDbType.NVarChar, -1).Value = insert;
                cmd.Parameters.Add("@target", SqlDbType.NVarChar, 128).Value = resultTable;
                cmd.Parameters.Add("@like", SqlDbType.NVarChar, 776).Value = helper;
                cmd.Parameters.Add("@keep", SqlDbType.Bit).Value = keep;
                cmd.ExecuteNonQuery();
            }
        }
    }
}
