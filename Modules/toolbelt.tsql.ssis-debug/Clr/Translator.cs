using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace Toolbelt.Tsql.SsisDebug
{
    internal sealed class StageColumn
    {
        internal string Id, Name, Alias, Type, Collation;
        internal bool Nullable;
    }
    internal sealed class Stage
    {
        internal string Id, Cte, Query, Component, Error, ErrorText;
        internal readonly List<StageColumn> Columns = new List<StageColumn>();
        internal readonly List<Stage> Parents = new List<Stage>();
        internal readonly List<KeyValuePair<string, string>> ExtraCtes = new List<KeyValuePair<string, string>>();
        internal readonly HashSet<string> Inputs = new HashSet<string>(StringComparer.Ordinal);
        internal readonly HashSet<string> ReferenceInputs = new HashSet<string>(StringComparer.Ordinal);
        internal readonly List<LookupCache> Caches = new List<LookupCache>();
        internal readonly List<string> StructureGuards = new List<string>();
    }
    internal sealed class LookupCache
    {
        internal string Name, StateName, Insert, Definition, Owner;
        internal readonly List<StageColumn> Columns = new List<StageColumn>();
        internal readonly HashSet<string> Inputs = new HashSet<string>(StringComparer.Ordinal);
    }
    internal sealed class Translator
    {
        private readonly Package package; private readonly Bindings bindings; private readonly Options options;
        private readonly SqlSafety safety; private readonly ICatalog catalog; private readonly Artifacts output;
        private readonly Dictionary<string, Stage> stages = new Dictionary<string, Stage>(StringComparer.Ordinal);
        private readonly HashSet<string> building = new HashSet<string>(StringComparer.Ordinal);
        private readonly Dictionary<string, string> stageIds = new Dictionary<string, string>(StringComparer.Ordinal), lookupIds = new Dictionary<string, string>(StringComparer.Ordinal);
        private readonly Dictionary<string, LookupCache> lookupCaches = new Dictionary<string, LookupCache>(StringComparer.Ordinal);
        private int nextStage, nextColumn; private readonly string runToken, runHash;
        internal Translator(Package p, Bindings b, Options o, SqlSafety sql, ICatalog cat, Artifacts result)
        {
            package = p; bindings = b; options = o; safety = sql; catalog = cat; output = result;
            var effective = Json.Obj();
            foreach (Input input in p.Inputs)
            { object v; effective.Add(input.Key, b.Values.TryGetValue(input.Key, out v) ? Types.Literal(input, v) : input.HasDefault && !input.Sensitive && input.SqlType != null ? Types.Literal(input, input.Default) : input.Expression ?? "<runtime>"); }
            runHash = Util.Hash(p.Hash + b.ContextHash + Json.Write(effective) + (o.CatalogBindings == null ? "" : Json.Write(Json.Parse(o.CatalogBindings))) + (o.LookupPolicies == null ? "" : Json.Write(Json.Parse(o.LookupPolicies))) + b.Collation + o.Version); runToken = runHash.Substring(0, 16);
            int lookups = 0;
            foreach (Flow flow in p.Flows) foreach (Component component in flow.Components)
            {
                foreach (Port port in component.Outputs) stageIds.Add(port.Id, Util.Id("s", ++nextStage));
                if (component.Kind == "destination" || component.Outputs.Count == 0 && component.Inputs.Count > 0) stageIds.Add("destination:" + component.Id, Util.Id("s", ++nextStage));
                if (component.Kind == "lookup") lookupIds.Add(component.Id, Util.Id("l", ++lookups));
                if (component.Kind == "lookup") stageIds.Add("lookup-match:" + component.Id, Util.Id("s", ++nextStage));
                if (component.Kind == "split") { stageIds.Add("split-conditions:" + component.Id, Util.Id("s", ++nextStage)); stageIds.Add("split-route:" + component.Id, Util.Id("s", ++nextStage)); }
            }
        }
        internal void Run()
        {
            var targets = package.Targets();
            if (options.Target != null && !targets.Any(t => t.Key == options.Target)) throw new DebugFault("unresolved_binding", "Unbekannter Zielfluss.");
            foreach (var target in targets)
            {
                if (options.Target != null && options.Target != target.Key) continue;
                Flow flow = target.Value.Key; Component destination = target.Value.Value;
                Stage end = BuildDestination(flow, destination);
                var ancestors = Ancestors(end);
                output.Add(new Artifact { Kind = "Workflow", Target = target.Key, Component = destination.Id, Content = Json.Write(Json.Obj("flow", flow.Id, "destination", destination.Id, "components", flow.Components.Select(c => (object)Json.Obj("id", c.Id, "kind", c.Kind, "classId", c.Class, "version", c.Version, "name", c.Name)).ToList(), "tasks", package.Workflow)), Complete = end.Error == null });
                foreach (Stage stage in ancestors)
                    output.Add(new Artifact { Kind = "StageIndex", Target = target.Key, Stage = stage.Id, Component = stage.Component, Content = stage.Cte, Complete = stage.Error == null, Evidence = stage.Error == null ? "pragmatic" : "unsupported", Safety = stage.Error == null ? "not_checked" : "blocked", Details = Json.Write(Json.Obj("parents", stage.Parents.Select(x => (object)x.Id).ToList(), "columns", stage.Columns.Select(c => (object)Json.Obj("lineageId", c.Id, "name", c.Name, "sqlAlias", c.Alias, "sqlType", c.Type)).ToList())) });
                if (options.Stage != null && options.Stage != "all" && !ancestors.Any(s => s.Id == options.Stage)) throw new DebugFault("unresolved_binding", "Stufe gehört nicht zum ausgewählten Zielfluss.");
                if (options.Stage == "all") foreach (Stage stage in ancestors.Where(s => s.Error == null)) Emit(stage, "StageSql", target.Key);
                else if (options.Stage != null) { Stage stage = ancestors.Single(s => s.Id == options.Stage); if (stage.Error == null) Emit(stage, "StageSql", target.Key); }
                if (end.Error == null) Emit(end, "TargetSql", target.Key);
                else output.Diagnostic(end.Error, destination.Id, end.ErrorText, target.Key);
            }
            foreach (var pair in stages.Where(p => p.Value.Error != null)) output.Diagnostic(pair.Value.Error, pair.Value.Component, pair.Value.ErrorText);
            output.Diagnostic("nolock_read_uncommitted", null, "NOLOCK: unbestätigte, fehlende oder doppelt gelesene Zeilen möglich; Schemasperren bleiben möglich. Lookupauswahl wird pro lokalem Cachelauf festgehalten.");
        }
        private Stage New(string component, string prefix, string key)
        { string id = stageIds[key]; return new Stage { Id = id, Component = component, Cte = prefix + "_" + id }; }
        private StageColumn NewColumn(string id, string name, string type, bool nullable)
        { if (type == null) throw new DebugFault("unsupported_expression", "Spaltentyp nicht unterstützt."); return new StageColumn { Id = id, Name = name, Type = type, Nullable = nullable, Alias = Util.Id("c", ++nextColumn) }; }
        private Stage BuildDestination(Flow flow, Component c)
        {
            string key = "destination:" + c.Id; Stage saved; if (stages.TryGetValue(key, out saved)) return saved;
            Stage result = New(c.Id, "destination", key); stages.Add(key, result);
            try
            {
                if (c.Kind != "destination" || c.Inputs.Count != 1) throw new DebugFault("unsupported_component", "Zielform nicht unterstützt.");
                Stage parent = Input(flow, c.Inputs[0]); Inherit(result, parent); Need(parent);
                var list = new List<string>();
                foreach (Column input in c.Inputs[0].Columns)
                {
                    StageColumn source = Find(parent, input.Lineage); Column external = c.Inputs[0].External.SingleOrDefault(x => x.Id == input.External);
                    if (external == null || external.SqlType == null) throw new DebugFault("invalid_lineage", "Explizites Zielspaltenmapping fehlt.");
                    var col = NewColumn(input.Id, external.Name, external.SqlType, source.Nullable); result.Columns.Add(col);
                    list.Add("CAST(m." + Util.Q(source.Alias) + " AS " + col.Type + ") AS " + Util.Q(col.Alias));
                }
                if (list.Count == 0) throw new DebugFault("invalid_lineage", "Leere Zielprojektion."); result.Query = "SELECT " + String.Join(", ", list) + " FROM " + Util.Q(parent.Cte) + " AS m";
            }
            catch (DebugFault e) { if (e.Code == "resource_limit" || e.Code == "invalid_template") throw; Block(result, e); }
            return result;
        }
        private Stage Input(Flow flow, Port input)
        {
            string output; if (!flow.Paths.TryGetValue(input.Id, out output)) throw new DebugFault("invalid_lineage", "Benötigter Eingang nicht verbunden.");
            return Build(flow, output);
        }
        private Stage Build(Flow flow, string outputId)
        {
            Budget.Limit(building.Count + 1, 32);
            Stage saved; if (stages.TryGetValue(outputId, out saved)) { if (building.Contains(outputId)) throw new DebugFault("ambiguous_path", "Zyklischer Datenfluss."); return saved; }
            var owner = flow.Components.SingleOrDefault(c => c.Outputs.Any(p => p.Id == outputId));
            if (owner == null) throw new DebugFault("invalid_lineage", "Output nicht gebunden.");
            Port port = owner.Outputs.Single(p => p.Id == outputId); Stage result = New(owner.Id, owner.Kind, outputId); stages.Add(outputId, result); building.Add(outputId);
            try
            {
                foreach (Port input in owner.Inputs) { Stage parent = Input(flow, input); Inherit(result, parent); }
                foreach (Stage parent in result.Parents) Need(parent);
                if (port.Error || owner.HasPropertyExpressions) throw new DebugFault("unsupported_component", "Errorport oder nicht aufgelöster Eigenschaftsausdruck.");
                switch (owner.Kind)
                {
                    case "source": Source(owner, port, result); break;
                    case "union": Union(owner, port, result); break;
                    case "derived": case "convert": Derived(owner, port, result); break;
                    case "split": Split(owner, port, result); break;
                    case "lookup": Lookup(owner, port, result); break;
                    default: throw new DebugFault("unsupported_component", "Komponente nicht im V1-Profil.");
                }
            }
            catch (DebugFault e) { if (e.Code == "resource_limit" || e.Code == "invalid_template") throw; Block(result, e); }
            finally { building.Remove(outputId); }
            return result;
        }
        private static void Block(Stage stage, DebugFault e) { stage.Error = e.Code; stage.ErrorText = e.Message; }
        private static void Need(Stage stage) { if (stage.Error != null) throw new DebugFault("partial_target", "Benötigte Vorgängerstufe " + stage.Id + " ist unvollständig."); }
        private static void Inherit(Stage stage, Stage parent)
        { if (!stage.Parents.Contains(parent)) stage.Parents.Add(parent); stage.Inputs.UnionWith(parent.Inputs); foreach (var cache in parent.Caches) if (!stage.Caches.Contains(cache)) stage.Caches.Add(cache); }
        private static StageColumn Find(Stage stage, string lineage)
        {
            var cols = stage.Columns.Where(c => c.Id == lineage).ToList();
            if (cols.Count != 1) throw new DebugFault("invalid_lineage", "Spaltenherkunft nicht eindeutig gebunden."); return cols[0];
        }
        private string SqlCommand(Component c, Stage stage)
        {
            string mode = PackageReader.P(c.Properties, "AccessMode", "2");
            string sql;
            if (mode == "0") sql = "SELECT * FROM " + PackageReader.P(c.Properties, "OpenRowset", PackageReader.P(c.Properties, "TableOrViewName"));
            else if (mode == "1" || mode == "3")
            {
                string var = PackageReader.P(c.Properties, mode == "1" ? "OpenRowsetVariable" : "SqlCommandVariable"); Input input = package.Resolve(var, c.Scope); object value;
                if (!bindings.Values.TryGetValue(input.Key, out value)) { if (!input.HasDefault || input.RuntimeAssigned || input.Expression != null) throw new DebugFault("unresolved_binding", "Command-/Objektvariable nicht statisch aufgelöst."); value = input.Default; }
                if (input.Sensitive || !(value is string)) throw new DebugFault("unresolved_binding", "Commandvariable nicht exportierbar.");
                var structural = bindings.Resolve(input); stage.Inputs.UnionWith(structural.Inputs); stage.ReferenceInputs.UnionWith(structural.Inputs);
                // Strukturwerte bleiben sichtbar; ein geänderter SQL-Text muss
                // erneut analysiert werden, bevor er ausführbar werden darf.
                stage.StructureGuards.Add("IF " + input.SqlName + " IS NULL OR CONVERT(varbinary(max), " + input.SqlName + ") <> CONVERT(varbinary(max), " + Util.L((string)value) + ") THROW 50000, 'TBX_SSISDBG_unresolved_binding: SQL-Struktur geaendert; erneut generieren.', 1;");
                sql = mode == "1" ? "SELECT * FROM " + (string)value : (string)value;
            }
            else if (mode == "2") sql = PackageReader.P(c.Properties, "SqlCommand");
            else throw new DebugFault("unsupported_component", "Source-AccessMode nicht unterstützt.");
            if (sql == "") throw new DebugFault("unresolved_binding", "Source-/Lookup-SQL fehlt.");
            string mapping = PackageReader.P(c.Properties, "ParameterMapping", PackageReader.P(c.Properties, "ParameterMappings"));
            if (sql.IndexOf('?') >= 0 || mapping != "")
            {
                // Nur echte Parameterpositionen aus dem kanonischen Vorfilter;
                // native OLE-DB-Form: "Parametername:Input",{Variablen-DTSID};
                var maps = SqlParameters.Mappings(mapping, package, c.Scope);
                var tokens = SqlParameters.Replace(sql, maps, input => { var value = bindings.Resolve(input); stage.Inputs.UnionWith(value.Inputs); stage.ReferenceInputs.UnionWith(value.Inputs); return value.Sql; }); sql = tokens;
            }
            return sql;
        }
        private SqlQuery Query(Component c, Stage stage)
        { return safety.Read(SqlCommand(c, stage), bindings.Database(c)); }
        private string Attach(SqlQuery q, Stage stage, string prefix)
        {
            var with = q.Statement.WithCtesAndXmlNamespaces;
            if (with != null)
            {
                int ordinal = 0;
                var names = with.CommonTableExpressions.ToDictionary(x => x.ExpressionName.Value, x => prefix + "_q" + (++ordinal).ToString(CultureInfo.InvariantCulture), StringComparer.Ordinal);
                foreach (var table in safety.Walk(q.Statement).OfType<NamedTableReference>())
                { string name; if (table.SchemaObject.Identifiers.Count == 1 && names.TryGetValue(table.SchemaObject.BaseIdentifier.Value, out name)) table.SchemaObject.BaseIdentifier.Value = name; }
                foreach (var cte in with.CommonTableExpressions)
                {
                    string name = Util.Q(names[cte.ExpressionName.Value]);
                    if (cte.Columns.Count != 0) name += "(" + String.Join(",", cte.Columns.Select(x => Util.Q(x.Value))) + ")";
                    stage.ExtraCtes.Add(new KeyValuePair<string, string>(name, safety.Generate(cte.QueryExpression)));
                }
            }
            var spec = q.Statement.QueryExpression as QuerySpecification;
            if (spec != null && spec.TopRowFilter == null && spec.OrderByClause != null)
            { spec.OrderByClause = null; output.Diagnostic("lookup_comparison_deviation", stage.Component, "Reine Source-Sortierung ohne TOP wird im relationalen Prüfblock weggelassen."); }
            return safety.Generate(q.Statement.QueryExpression);
        }
        private void Source(Component c, Port port, Stage stage)
        {
            if (c.Inputs.Count != 0 || c.Outputs.Count(p => !p.Error) != 1) throw new DebugFault("unsupported_component", "Source-Portform nicht unterstützt.");
            SqlQuery query = Query(c, stage); var projected = Projection.Columns(query, safety);
            string sql = Attach(query, stage, stage.Id + "_src"); var list = new List<string>();
            foreach (Column outputColumn in port.Columns)
            {
                Column external = port.External.SingleOrDefault(x => x.Id == outputColumn.External); string name = external == null ? outputColumn.Name : external.Name;
                BoundColumn column = projected.SingleOrDefault(x => x.Name == name);
                if (column == null || outputColumn.SqlType == null) throw new DebugFault("unresolved_binding", "Source-Ausgang nicht gegen Abfragespalte gebunden.");
                ValidateCodePage(outputColumn, column.Collation);
                var col = NewColumn(outputColumn.Lineage == "" ? outputColumn.Id : outputColumn.Lineage, outputColumn.Name, outputColumn.SqlType, column.Nullable); stage.Columns.Add(col);
                list.Add("CAST(src." + Util.Q(name) + " AS " + col.Type + ") AS " + Util.Q(col.Alias));
            }
            if (list.Count == 0) throw new DebugFault("invalid_lineage", "Source-Ausgang hat keine Metadaten.");
            stage.Query = "SELECT " + String.Join(", ", list) + " FROM (" + sql + ") AS src";
        }
        private void ValidateCodePage(Column column, string collation)
        { if (column.Type == "str" && (column.CodePage <= 0 || collation == null || catalog.CodePage(collation) != column.CodePage)) throw new DebugFault("unresolved_binding", "ANSI-Codepage nicht exakt belegt."); }
        private void Union(Component c, Port port, Stage stage)
        {
            foreach (Column outputColumn in port.Columns) stage.Columns.Add(NewColumn(outputColumn.Lineage == "" ? outputColumn.Id : outputColumn.Lineage, outputColumn.Name, outputColumn.SqlType, false));
            var branches = new List<string>();
            for (int i = 0; i < c.Inputs.Count; i++)
            {
                Stage parent = stage.Parents[i]; var fields = new List<string>();
                foreach (StageColumn target in stage.Columns)
                {
                    var matches = c.Inputs[i].Columns.Where(x => PackageReader.P(x.Properties, "OutputColumnLineageID") == target.Id).ToList();
                    if (matches.Count > 1) throw new DebugFault("invalid_lineage", "Union-Spalte mehrfach gemappt.");
                    string value = matches.Count == 0 ? "NULL" : "m." + Util.Q(Find(parent, matches[0].Lineage).Alias);
                    target.Nullable |= matches.Count == 0 || Find(parent, matches[0].Lineage).Nullable;
                    fields.Add("CAST(" + value + " AS " + target.Type + ") AS " + Util.Q(target.Alias));
                }
                branches.Add("SELECT " + String.Join(", ", fields) + " FROM " + Util.Q(parent.Cte) + " AS m");
            }
            if (branches.Count < 1 || stage.Columns.Count == 0) throw new DebugFault("invalid_lineage", "Union benötigt verbundenen Eingang und explizite Ausgänge.");
            stage.Query = String.Join("\nUNION ALL\n", branches);
        }
        private Dictionary<string, ExpressionValue> ExpressionColumns(Stage parent)
        {
            var cols = new Dictionary<string, ExpressionValue>(StringComparer.Ordinal); var duplicateNames = new HashSet<string>(StringComparer.Ordinal);
            foreach (StageColumn c in parent.Columns)
            {
                var value = new ExpressionValue { Sql = "m." + Util.Q(c.Alias), Type = c.Type, Nullable = c.Nullable };
                cols[c.Id] = value; if (!c.Id.StartsWith("#", StringComparison.Ordinal)) cols["#" + c.Id] = value;
                if (cols.ContainsKey(c.Name)) duplicateNames.Add(c.Name); else cols.Add(c.Name, value);
            }
            foreach (string name in duplicateNames) cols.Remove(name); return cols;
        }
        private ExpressionValue Expression(string expression, Component c, Stage parent, Stage stage)
        { var result = new ExpressionParser(expression, package, c.Scope, ExpressionColumns(parent), bindings.Resolve).Parse(); stage.Inputs.UnionWith(result.Inputs); return result; }
        private void Derived(Component c, Port port, Stage stage)
        {
            if (stage.Parents.Count != 1 || c.Inputs.Count != 1) throw new DebugFault("unsupported_component", "Transformation benötigt einen Eingang.");
            Stage parent = stage.Parents[0]; var projections = parent.Columns.ToDictionary(x => x.Id, x => "m." + Util.Q(x.Alias), StringComparer.Ordinal);
            var existing = parent.Columns.ToDictionary(x => x.Id, x => x, StringComparer.Ordinal);
            var replacements = new Dictionary<string, StageColumn>(StringComparer.Ordinal);
            foreach (Column input in c.Inputs[0].Columns)
            {
                string expr = PackageReader.P(input.Properties, "Expression"); if (expr == "") continue;
                var old = Find(parent, input.Lineage); var value = Expression(expr, c, parent, stage);
                projections[old.Id] = "CAST(" + value.Sql + " AS " + old.Type + ")";
                replacements.Add(old.Id, NewColumn(old.Id, old.Name, old.Type, value.Nullable));
            }
            foreach (StageColumn col in parent.Columns) stage.Columns.Add(replacements.ContainsKey(col.Id) ? replacements[col.Id] : col);
            foreach (Column col in port.Columns)
            {
                string expr = PackageReader.P(col.Properties, "Expression"); ExpressionValue value;
                if (c.Kind == "convert")
                { string source = PackageReader.P(col.Properties, "SourceInputColumnLineageID"); var old = Find(parent, source); value = new ExpressionValue { Sql = "m." + Util.Q(old.Alias), Type = old.Type, Nullable = old.Nullable }; }
                else value = Expression(expr, c, parent, stage);
                var target = NewColumn(col.Lineage == "" ? col.Id : col.Lineage, col.Name, col.SqlType, value.Nullable);
                if (existing.ContainsKey(target.Id)) throw new DebugFault("invalid_lineage", "Neue Spaltenversion kollidiert.");
                stage.Columns.Add(target); projections.Add(target.Id, "CAST(" + value.Sql + " AS " + target.Type + ")");
            }
            stage.Query = "SELECT " + String.Join(", ", stage.Columns.Select(x => projections[x.Id] + " AS " + Util.Q(x.Alias))) + " FROM " + Util.Q(parent.Cte) + " AS m";
        }
        private void Split(Component c, Port selected, Stage stage)
        {
            if (stage.Parents.Count != 1) throw new DebugFault("unsupported_component", "Split benötigt einen Eingang.");
            Stage parent = stage.Parents[0]; var branches = new List<KeyValuePair<int, ExpressionValue>>(); int selectedOrder = -1, defaultOrder = -1; bool nullFailure = false;
            foreach (Port p in c.Outputs.Where(x => !x.Error))
            {
                int order;
                if (!Int32.TryParse(PackageReader.P(p.Properties, "EvaluationOrder"), NumberStyles.None, CultureInfo.InvariantCulture, out order) || order < 0) throw new DebugFault("ambiguous_path", "Splitpriorität fehlt.");
                if (p.Id == selected.Id) selectedOrder = order;
                if (Util.Flag(PackageReader.P(p.Properties, "IsDefaultOut"))) { if (defaultOrder >= 0) throw new DebugFault("ambiguous_path", "Mehrere Defaultausgänge."); defaultOrder = order; continue; }
                var value = Expression(PackageReader.P(p.Properties, "Expression"), c, parent, stage);
                if (value.Type != "bit") throw new DebugFault("unsupported_expression", "Splitbedingung ist nicht Boolean.");
                nullFailure |= value.Nullable && p.ErrorDisposition != "IgnoreFailure";
                branches.Add(new KeyValuePair<int, ExpressionValue>(order, value));
            }
            if (selectedOrder < 0 || defaultOrder < 0 || branches.Select(x => x.Key).Concat(new[] { defaultOrder }).Distinct().Count() != branches.Count + 1) throw new DebugFault("ambiguous_path", "Splitreihenfolge widersprüchlich.");
            string conditionKey = "split-conditions:" + c.Id; Stage conditions;
            if (!stages.TryGetValue(conditionKey, out conditions))
            {
                conditions = New(c.Id, "conditions", conditionKey); Inherit(conditions, parent); conditions.Inputs.UnionWith(stage.Inputs); conditions.Columns.AddRange(parent.Columns);
                var fields = new List<string> { Fields(parent, "m") };
                foreach (var branch in branches.OrderBy(x => x.Key)) { var col = NewColumn(conditionKey + ":" + branch.Key, "DebugCondition_" + branch.Key, "bit", branch.Value.Nullable); conditions.Columns.Add(col); fields.Add(branch.Value.Sql + " AS " + Util.Q(col.Alias)); }
                conditions.Query = "SELECT " + String.Join(", ", fields) + " FROM " + Util.Q(parent.Cte) + " AS m"; stages.Add(conditionKey, conditions);
            }
            Inherit(stage, conditions);
            if (nullFailure) throw new DebugFault("split_null_disposition", "Möglicher NULL-Fehler blockiert Routing; Bedingungsansicht " + conditions.Id + " bleibt prüfbar.");
            string route = "CASE " + String.Join(" ", branches.OrderBy(x => x.Key).Select(x => "WHEN " + x.Value.Condition + " THEN " + x.Key)) + " ELSE " + defaultOrder + " END";
            string routeKey = "split-route:" + c.Id; Stage routed;
            if (!stages.TryGetValue(routeKey, out routed))
            {
                routed = New(c.Id, "routed", routeKey); Inherit(routed, parent); routed.Inputs.UnionWith(stage.Inputs); routed.Columns.AddRange(parent.Columns);
                var branchColumn = NewColumn(routeKey, "DebugBranchId", "int", false); routed.Columns.Add(branchColumn);
                routed.Query = "SELECT " + Fields(parent, "m") + ", " + route + " AS " + Util.Q(branchColumn.Alias) + " FROM " + Util.Q(parent.Cte) + " AS m"; stages.Add(routeKey, routed);
            }
            Inherit(stage, routed);
            stage.Columns.AddRange(parent.Columns); stage.Query = "SELECT " + Fields(parent, "m") + " FROM " + Util.Q(routed.Cte) + " AS m WHERE m." + Util.Q(routed.Columns.Last().Alias) + " = " + selectedOrder;
        }
        private void Lookup(Component c, Port port, Stage stage)
        {
            if (stage.Parents.Count != 1 || bindings.Collation == null) throw new DebugFault("unresolved_binding", "Lookup benötigt einen Eingang und Vergleichsprofil.");
            Stage parent = stage.Parents[0];
            var keys = c.Inputs[0].Columns.Where(x => PackageReader.P(x.Properties, "JoinToReferenceColumn") != "").ToList();
            if (keys.Count == 0) throw new DebugFault("invalid_lineage", "Vollständiger Lookupschlüssel fehlt.");
            string mode = PackageReader.P(c.Properties, "NoMatchBehavior", "0");
            bool noMatch = Toolbelt.Ssis.Exchange.ComponentProfiles.IsLookupNoMatchOutput(c.Outputs.Where(p => !p.Error).ToList().IndexOf(port));
            if (mode != "0" && mode != "1" && mode != "2") throw new DebugFault("unsupported_component", "Lookup-NoMatch-Disposition unbekannt.");
            LookupCache savedCache;
            if (lookupCaches.TryGetValue(c.Id, out savedCache)) { stage.Caches.Add(savedCache); stage.Inputs.UnionWith(savedCache.Inputs); RenderLookupJoin(c, port, stage, parent, savedCache, keys, mode, noMatch); if (mode == "0") LookupMatchView(c, stage, parent); return; }
            SqlQuery query = Query(c, stage); List<BoundColumn> reference = Projection.Columns(query, safety);
            string suffix = runToken + "_" + lookupIds[c.Id];
            var cache = new LookupCache { Name = "#tbx_SsisDebug_L_" + suffix, StateName = "#tbx_SsisDebug_S_" + suffix };
            cache.Inputs.UnionWith(stage.ReferenceInputs);
            var projections = new List<string>(); var partitions = new List<string>(); var joins = new List<string>(); int ordinal = 0;
            foreach (Column key in keys)
            {
                StageColumn left = Find(parent, key.Lineage); string name = ReferenceName(c, PackageReader.P(key.Properties, "JoinToReferenceColumn")); BoundColumn right = reference.SingleOrDefault(x => x.Name == name);
                if (right == null) throw new DebugFault("invalid_lineage", "Lookup-Referenzschlüssel fehlt.");
                ValidateCodePage(key, right.Collation);
                string alias = Util.Id("k", ++ordinal), normalized = Normalize("ref." + Util.Q(name), left.Type), source = Normalize("m." + Util.Q(left.Alias), left.Type);
                cache.Columns.Add(new StageColumn { Alias = alias, Name = alias, Id = key.Id, Type = left.Type, Nullable = true, Collation = bindings.Collation });
                projections.Add(normalized + " AS " + Util.Q(alias)); partitions.Add(normalized); joins.Add(source + " = lk." + Util.Q(alias));
            }
            var refAliases = new Dictionary<string, StageColumn>(StringComparer.Ordinal);
            foreach (BoundColumn r in reference)
            {
                var col = new StageColumn { Alias = Util.Id("r", ++ordinal), Id = r.Name, Name = r.Name, Type = r.SqlType, Nullable = true, Collation = r.Collation ?? bindings.Collation };
                if (col.Type == null) throw new DebugFault("unresolved_binding", "Referenztyp nicht ableitbar."); cache.Columns.Add(col); refAliases.Add(r.Name, col);
                projections.Add("ref." + Util.Q(r.Name) + " AS " + Util.Q(col.Alias));
            }
            cache.Columns.Add(new StageColumn { Alias = "tbx_match", Id = "tbx_match", Type = "bit", Nullable = false }); projections.Add("CAST(1 AS bit) AS [tbx_match]");
            List<KeyValuePair<string, string>> order;
            string ordering = "(SELECT NULL)";
            if (bindings.LookupOrders.TryGetValue(c.Id, out order))
            {
                var expressions = new List<string>();
                foreach (var item in order) { string name = ReferenceName(c, item.Key); if (!refAliases.ContainsKey(name)) throw new DebugFault("invalid_template", "Auswahlspalte fehlt in Lookupreferenz."); expressions.Add("ref." + Util.Q(name) + " " + item.Value.ToUpperInvariant()); }
                ordering = String.Join(", ", expressions);
            }
            else output.Diagnostic("arbitrary_lookup_selection", c.Id, "ROW_NUMBER ORDER BY (SELECT NULL): beliebige Auswahl, pro lokalem Cache festgehalten.");
            string refSql = Attach(query, stage, lookupIds[c.Id] + "_ref");
            var ctes = stage.ExtraCtes.ToList(); stage.ExtraCtes.Clear();
            string ranked = "SELECT " + String.Join(", ", projections) + ", ROW_NUMBER() OVER (PARTITION BY " + String.Join(", ", partitions) + " ORDER BY " + ordering + ") AS [tbx_rn] FROM (" + refSql + ") AS ref";
            string columns = String.Join(", ", cache.Columns.Select(x => Util.Q(x.Alias)));
            cache.Insert = (ctes.Count == 0 ? "" : ";WITH " + String.Join(",\n", ctes.Select(x => x.Key + " AS (" + x.Value + ")")) + "\n") + "INSERT INTO " + Util.Q(cache.Name) + " (" + columns + ") SELECT " + columns + " FROM (" + ranked + ") AS ranked WHERE [tbx_rn] = 1;";
            cache.Definition = String.Join(", ", cache.Columns.Select(x => Util.Q(x.Alias) + " " + x.Type + (TextType(x.Type) ? " COLLATE " + Util.CollationToken(x.Collation ?? bindings.Collation) : "") + (x.Nullable ? " NULL" : " NOT NULL")));
            cache.Owner = Util.Hash("ssis-debug-v1|" + runHash + "|" + c.Id + "|" + cache.Definition);
            lookupCaches.Add(c.Id, cache); stage.Caches.Add(cache);
            RenderLookupJoin(c, port, stage, parent, cache, keys, mode, noMatch);
            if (mode == "0") LookupMatchView(c, stage, parent);
            output.Diagnostic("lookup_comparison_deviation", c.Id, "SQL-Gleichheit mit vollständigem Schlüssel und expliziter Vergleichscollation; keine SSIS-Full-Cache-Parität.");
        }
        private void LookupMatchView(Component c, Stage stage, Stage parent)
        {
            string key = "lookup-match:" + c.Id; Stage matches;
            if (!stages.TryGetValue(key, out matches))
            { matches = New(c.Id, "lookup_matches", key); Inherit(matches, parent); matches.Query = stage.Query; matches.Columns.AddRange(stage.Columns); matches.Inputs.UnionWith(stage.Inputs); matches.Caches.AddRange(stage.Caches.Where(x => !matches.Caches.Contains(x))); stages.Add(key, matches); }
            Inherit(stage, matches); Block(stage, new DebugFault("unsupported_component", "Lookup-Fail-Disposition bleibt blockiert; Matchansicht " + matches.Id + " ist prüfbar."));
        }
        private void RenderLookupJoin(Component c, Port port, Stage stage, Stage parent, LookupCache cache, List<Column> keys, string mode, bool noMatch)
        {
            var joins = keys.Select(k => { StageColumn left = Find(parent, k.Lineage); StageColumn right = cache.Columns.Single(x => x.Id == k.Id && x.Alias.StartsWith("k", StringComparison.Ordinal)); return Normalize("m." + Util.Q(left.Alias), left.Type) + " = lk." + Util.Q(right.Alias); }).ToList();
            stage.Columns.AddRange(parent.Columns); var fields = parent.Columns.Select(x => "m." + Util.Q(x.Alias) + " AS " + Util.Q(x.Alias)).ToList();
            var refAliases = cache.Columns.Where(x => x.Name != null && x.Alias.StartsWith("r", StringComparison.Ordinal)).ToDictionary(x => x.Name, x => x, StringComparer.Ordinal);
            foreach (Column col in c.Inputs.SelectMany(p => p.Columns).Where(x => PackageReader.P(x.Properties, "CopyFromReferenceColumn") != ""))
            {
                StageColumn previous = Find(parent, col.Lineage), replacement;
                if (!refAliases.TryGetValue(ReferenceName(c, PackageReader.P(col.Properties, "CopyFromReferenceColumn")), out replacement)) throw new DebugFault("invalid_lineage", "Lookup-Ersetzung nicht gebunden.");
                var changed = NewColumn(previous.Id, previous.Name, previous.Type, true); int index = stage.Columns.IndexOf(previous); stage.Columns[index] = changed;
                fields[index] = "CAST(lk." + Util.Q(replacement.Alias) + " AS " + changed.Type + ") AS " + Util.Q(changed.Alias);
            }
            foreach (Column col in port.Columns)
            {
                string name = ReferenceName(c, PackageReader.P(col.Properties, "CopyFromReferenceColumn")); StageColumn refCol;
                if (!refAliases.TryGetValue(name, out refCol)) throw new DebugFault("invalid_lineage", "Lookup-Payloadmapping fehlt.");
                var outputCol = NewColumn(col.Lineage == "" ? col.Id : col.Lineage, col.Name, col.SqlType, true); stage.Columns.Add(outputCol);
                fields.Add("CAST(lk." + Util.Q(refCol.Alias) + " AS " + outputCol.Type + ") AS " + Util.Q(outputCol.Alias));
            }
            stage.Query = "SELECT " + String.Join(", ", fields) + " FROM " + Util.Q(parent.Cte) + " AS m " + (mode == "1" || noMatch ? "LEFT JOIN " : "INNER JOIN ") + Util.Q(cache.Name) + " AS lk WITH (NOLOCK) ON " + String.Join(" AND ", joins) + (noMatch ? " WHERE lk.[tbx_match] IS NULL" : "");
        }
        private static string ReferenceName(Component c, string id)
        {
            var match = c.Inputs.SelectMany(p => p.External).Concat(c.Outputs.SelectMany(p => p.External)).SingleOrDefault(x => x.Id == id);
            return match == null ? id : match.Name;
        }
        private static bool TextType(string type) { return type.StartsWith("nvarchar", StringComparison.Ordinal) || type.StartsWith("varchar", StringComparison.Ordinal) || type.StartsWith("nchar", StringComparison.Ordinal) || type.StartsWith("char", StringComparison.Ordinal); }
        private string Normalize(string expression, string type) { return "CAST(" + expression + " AS " + type + ")" + (TextType(type) ? " COLLATE " + Util.CollationToken(bindings.Collation) : ""); }
        private static string Fields(Stage stage, string alias) { return String.Join(", ", stage.Columns.Select(c => alias + "." + Util.Q(c.Alias))); }
        private static List<Stage> Ancestors(Stage stage)
        {
            var result = new List<Stage>(); var seen = new HashSet<Stage>();
            Action<Stage> add = null; add = s => { if (!seen.Add(s)) return; foreach (Stage p in s.Parents) add(p); result.Add(s); }; add(stage); return result;
        }
        private void Emit(Stage stage, string kind, string target)
        {
            var chain = Ancestors(stage); var caches = chain.SelectMany(x => x.Caches).Distinct().ToList(); var inputKeys = new HashSet<string>(chain.SelectMany(x => x.Inputs), StringComparer.Ordinal);
            string declarations = "-- Bearbeitbare Szenariowerte; zusammen mit WITH/SELECT ausführen.\n" + bindings.Declarations(inputKeys) + "\n";
            string preparation = String.Join("\n", caches.Select(c => CacheSql.Prepare(c, bindings)));
            string with = ";WITH " + String.Join(",\n", chain.SelectMany(s => s.ExtraCtes).Select(p => p.Key + " AS (" + p.Value + ")").Concat(chain.Select(s => Util.Q(s.Cte) + " AS (\n" + s.Query + "\n)")));
            string select = "SELECT " + String.Join(", ", stage.Columns.Select(c => Util.Q(c.Alias) + " AS " + Util.Q(c.Name))) + " FROM " + Util.Q(stage.Cte) + ";";
            string guards = "IF CONVERT(varbinary(max), DB_NAME()) <> CONVERT(varbinary(max), " + Util.L(bindings.DefaultDatabase) + ") THROW 50000, 'TBX_SSISDBG_cache_context_changed: Falscher Datenbankkontext.', 1;\n" + String.Join("\n", chain.SelectMany(s => s.StructureGuards));
            string sql = declarations + guards + "\n" + preparation + "\n" + with + "\n" + select;
            var owned = caches.SelectMany(c => new[] { c.Name, c.StateName }).ToList(); safety.Generated(sql, bindings.DefaultDatabase, owned);
            output.Add(new Artifact { Kind = kind, Target = target, Stage = stage.Id, Component = stage.Component, Content = sql, Evidence = "pragmatic", Safety = "passed", Executable = true });
            output.Add(new Artifact { Kind = "ColumnLineage", Target = target, Stage = stage.Id, Component = stage.Component, Content = Json.Write(stage.Columns.Select(c => (object)Json.Obj("name", c.Name, "lineageId", c.Id, "sqlType", c.Type, "sqlAlias", c.Alias)).ToList()) });
            if (caches.Count > 0)
            {
                string prep = declarations + guards + "\n" + preparation; safety.Generated(prep, bindings.DefaultDatabase, owned);
                output.Add(new Artifact { Kind = "PreparationSql", Target = target, Stage = stage.Id, Content = prep, Evidence = "pragmatic", Safety = "passed", Executable = true });
                string cleanup = CacheSql.Cleanup(caches, bindings.Collation); safety.Generated(cleanup, bindings.DefaultDatabase, owned);
                output.Add(new Artifact { Kind = "CleanupSql", Target = target, Stage = stage.Id, Content = cleanup, Evidence = "translated", Safety = "passed", Executable = true });
            }
        }
    }
}
