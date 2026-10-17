using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;

namespace Toolbelt.Tsql.SsisDebug
{
    internal sealed class Options
    {
        internal string Operation, ProjectContext, Bindings, CatalogBindings, Target, Stage, LookupPolicies, ComparisonCollation;
        internal int Version;
    }
    internal sealed class Bindings
    {
        internal readonly Package Package;
        internal readonly Dictionary<string, object> Values = Json.Obj();
        internal readonly Dictionary<string, string> Connections = new Dictionary<string, string>(StringComparer.Ordinal);
        internal readonly List<string> Databases = new List<string>();
        internal readonly Dictionary<string, List<KeyValuePair<string, string>>> LookupOrders = new Dictionary<string, List<KeyValuePair<string, string>>>(StringComparer.Ordinal);
        internal string DefaultDatabase, Collation, ContextHash;
        private readonly Dictionary<string, ExpressionValue> resolved = new Dictionary<string, ExpressionValue>(StringComparer.Ordinal);
        private readonly HashSet<string> resolving = new HashSet<string>(StringComparer.Ordinal);
        internal readonly List<Input> DeclarationOrder = new List<Input>();
        private readonly Artifacts artifacts;
        internal Bindings(Package package, Options options, ICatalog catalog, Artifacts output)
        {
            Package = package; artifacts = output;
            var context = options.ProjectContext == null ? Json.Obj("schemaVersion", new JsonNumber("1")) : Json.Object(Json.Parse(options.ProjectContext));
            Json.Version(context); Json.Keys(context, "schemaVersion", "projectParameters", "connectionManagers");
            var canonical = Json.Obj("schemaVersion", new JsonNumber("1"), "profile", "ssis-debug-v1");
            foreach (string field in new[] { "projectParameters", "connectionManagers" })
            {
                object raw = Json.Get(context, field); if (raw == null) { canonical.Add(field, new List<object>()); continue; }
                var entries = Json.Array(raw).Select(Json.Object).ToList(); Budget.Limit(entries.Count, 2048);
                string idField = field == "projectParameters" ? "name" : "refId";
                var seen = new HashSet<string>(StringComparer.Ordinal);
                foreach (var e in entries)
                {
                    string id = Json.Text(Json.Get(e, idField)); if (id == "" || !seen.Add(id)) throw new DebugFault("invalid_template", "Doppelte Kontextidentität.");
                    if (field == "projectParameters")
                    {
                        Json.Keys(e, "name", "ssisType", "designValue", "required", "sensitive");
                        string type = Json.Text(Json.Get(e, "ssisType"));
                        var input = new Input { Kind = "project-parameter", Scope = "$Project", Name = "$Project::" + id, Type = type, SqlType = Types.Sql(type), HasDefault = e.ContainsKey("designValue"), Default = Json.Get(e, "designValue"), Sensitive = Json.Bool(e, "sensitive"), Required = Json.Bool(e, "required"), Origin = "project-context" };
                        if (input.HasDefault && !input.Sensitive && input.SqlType != null) Types.Literal(input, input.Default);
                        package.Inputs.Add(input);
                    }
                    else
                    {
                        Json.Keys(e, "refId", "name", "provider"); Json.Text(Json.Get(e, "name")); string provider = Json.Text(Json.Get(e, "provider"));
                        if (provider != "sqlserver-oledb" && provider != "sqlserver-adonet") throw new DebugFault("invalid_template", "Connectionprovider nicht unterstützt.");
                        if (package.Connections.ContainsKey(id)) throw new DebugFault("invalid_template", "Projektconnection kollidiert mit Paketconnection.");
                        package.Connections.Add(id, provider);
                    }
                }
                canonical.Add(field, entries.OrderBy(e => Json.Text(e[idField]), StringComparer.Ordinal).Cast<object>().ToList());
            }
            ContextHash = Util.Hash(Json.Write(canonical));
            DiscoverInputs(package);
            Budget.Limit(package.Inputs.Count, 2048);
            var names = new HashSet<string>(StringComparer.Ordinal);
            for (int i = 0; i < package.Inputs.Count; i++)
            { var input = package.Inputs[i]; input.Key = Util.Id("v", i + 1); if (!names.Add(input.Scope + "\0" + input.Name)) throw new DebugFault("unresolved_binding", "Doppelte Eingabe im Scope."); }
            MarkRequired(package, options.Target);
            if (options.Bindings != null)
            {
                var root = Json.Object(Json.Parse(options.Bindings)); Json.Version(root);
                Json.Keys(root, "schemaVersion", "profile", "packageSha256", "contextSha256", "values", "availableInputs");
                if (Json.Text(Json.Get(root, "profile")) != "ssis-debug-v1" || Json.Text(Json.Get(root, "packageSha256")) != package.Hash || Json.Text(Json.Get(root, "contextSha256")) != ContextHash) throw new DebugFault("invalid_template", "Vorlage gehört zu anderem Paket oder Kontext.");
                var metadata = Json.Array(Json.Get(root, "availableInputs"));
                if (metadata.Count != package.Inputs.Count) throw new DebugFault("invalid_template", "Eingabeverzeichnis geändert.");
                var byKey = new Dictionary<string, Dictionary<string, object>>(StringComparer.Ordinal);
                foreach (object v in metadata)
                {
                    var e = Json.Object(v); Json.Keys(e, "key", "kind", "scope", "name", "ssisType", "sqlType", "defaultAvailable", "defaultValue", "expression", "valueOrigin", "requiredForSelectedFlow", "sensitive", "state");
                    foreach (string required in new[] { "key", "kind", "scope", "name", "ssisType", "sqlType", "defaultAvailable", "defaultValue", "expression", "valueOrigin", "requiredForSelectedFlow", "sensitive", "state" }) if (!e.ContainsKey(required)) throw new DebugFault("invalid_template", "Unvollständige Eingabemetadaten.");
                    foreach (string flag in new[] { "defaultAvailable", "requiredForSelectedFlow", "sensitive" }) if (!(e[flag] is bool)) throw new DebugFault("invalid_template", "Boolean-Metadaten erwartet.");
                    foreach (string text in new[] { "valueOrigin", "state" }) Json.Text(e[text]);
                    if (e["expression"] != null) Json.Text(e["expression"]);
                    string key = Json.Text(e["key"]); if (byKey.ContainsKey(key)) throw new DebugFault("invalid_template", "Doppelte Eingabeidentität."); byKey.Add(key, e);
                }
                foreach (Input input in package.Inputs)
                {
                    Dictionary<string, object> e; if (!byKey.TryGetValue(input.Key, out e)) throw new DebugFault("invalid_template", "Eingabe fehlt.");
                    var expected = input.Metadata();
                    foreach (string key in new[] { "key", "kind", "scope", "name", "ssisType", "sqlType" }) if (Json.Write(e[key]) != Json.Write(expected[key])) throw new DebugFault("invalid_template", "Identitäts-/Typmetadaten geändert.");
                }
                foreach (var v in Json.Object(Json.Get(root, "values")))
                {
                    Input input = package.Inputs.SingleOrDefault(x => x.Key == v.Key);
                    if (input == null || input.SqlType == null || input.Sensitive) throw new DebugFault("invalid_template", "Unbekannter oder nicht bindbarer Wertekey.");
                    Types.Literal(input, v.Value); Values.Add(v.Key, v.Value);
                }
            }
            if (options.Operation == "bindings-template")
            {
                if (options.Bindings != null || options.CatalogBindings != null) throw new DebugFault("invalid_template", "Template-Modus verlangt Bindings und CatalogBindings NULL.");
                return;
            }
            if (options.CatalogBindings != null)
            {
                var root = Json.Object(Json.Parse(options.CatalogBindings)); Json.Version(root); Json.Keys(root, "schemaVersion", "defaultDatabase", "databases", "connections");
                DefaultDatabase = Json.Text(Json.Get(root, "defaultDatabase"));
                foreach (object value in Json.Array(Json.Get(root, "databases"))) { string name = Json.Text(value); Util.Q(name); if (Databases.Contains(name, StringComparer.Ordinal)) throw new DebugFault("invalid_template", "Doppelte Datenbank."); Databases.Add(name); }
                if (!Databases.Contains(DefaultDatabase, StringComparer.Ordinal)) throw new DebugFault("invalid_template", "Defaultdatenbank fehlt in Allowlist.");
                foreach (var entry in Json.Object(Json.Get(root, "connections")))
                { string db = Json.Text(entry.Value); if (!package.Connections.ContainsKey(entry.Key) || !Databases.Contains(db, StringComparer.Ordinal)) throw new DebugFault("invalid_template", "Connectionmapping nicht gebunden."); Connections.Add(entry.Key, db); }
                Collation = options.ComparisonCollation ?? catalog.Collation(DefaultDatabase);
                if (!catalog.IsCollation(Collation)) throw new DebugFault("unresolved_binding", "Vergleichscollation unbekannt.");
            }
            else if (options.ComparisonCollation != null)
            { if (!catalog.IsCollation(options.ComparisonCollation)) throw new DebugFault("unresolved_binding", "Vergleichscollation unbekannt."); Collation = options.ComparisonCollation; }
            if (options.LookupPolicies != null)
            {
                var root = Json.Object(Json.Parse(options.LookupPolicies)); Json.Version(root); Json.Keys(root, "schemaVersion", "lookups");
                foreach (var entry in Json.Object(Json.Get(root, "lookups")))
                {
                    if (!package.Flows.SelectMany(f => f.Components).Any(c => c.Id == entry.Key && c.Kind == "lookup")) throw new DebugFault("invalid_template", "Unbekannte Lookup-ID.");
                    var policy = Json.Object(entry.Value); Json.Keys(policy, "orderBy"); var order = new List<KeyValuePair<string, string>>();
                    foreach (object raw in Json.Array(Json.Get(policy, "orderBy")))
                    { var item = Json.Object(raw); Json.Keys(item, "column", "direction"); string col = Json.Text(Json.Get(item, "column")), direction = Json.Text(Json.Get(item, "direction")); if (direction != "asc" && direction != "desc" || order.Any(x => x.Key == col)) throw new DebugFault("invalid_template", "Lookupordnung ungültig."); order.Add(new KeyValuePair<string, string>(col, direction)); }
                    if (order.Count == 0) throw new DebugFault("invalid_template", "Leere Lookupordnung."); LookupOrders.Add(entry.Key, order);
                }
            }
        }
        private static IEnumerable<string> Expressions(Component c)
        {
            return c.Properties.Where(p => p.Key == "Expression").Select(p => p.Value)
                .Concat(c.Inputs.Concat(c.Outputs).SelectMany(p => p.Properties.Where(x => x.Key == "Expression").Select(x => x.Value)))
                .Concat(c.Inputs.Concat(c.Outputs).SelectMany(p => p.Columns).SelectMany(col => col.Properties.Where(x => x.Key == "Expression").Select(x => x.Value)));
        }
        private static IEnumerable<string> References(string text)
        {
            try { return ExpressionParser.References(text).ToList(); }
            catch (DebugFault e) { if (e.Code == "resource_limit") throw; return new string[0]; }
        }
        private static void DiscoverInputs(Package package)
        {
            var texts = package.Flows.SelectMany(f => f.Components).SelectMany(c => Expressions(c).Select(v => new KeyValuePair<string, string>(c.Scope, v)))
                .Concat(package.Inputs.Select(v => new KeyValuePair<string, string>(v.Scope, v.Expression ?? ""))).ToList();
            foreach (var text in texts) foreach (string reference in References(text.Value))
            {
                string name = reference.StartsWith("@[", StringComparison.Ordinal) ? reference.Substring(2, reference.Length - 3) : reference.TrimStart('@');
                if (!name.StartsWith("System::", StringComparison.Ordinal) && !name.StartsWith("$Project::", StringComparison.Ordinal)) continue;
                string scope = name.StartsWith("$Project::", StringComparison.Ordinal) ? "$Project" : text.Key;
                if (package.Inputs.Any(i => i.Name == name && i.Scope == scope)) continue;
                string shortName = name.Substring(name.IndexOf("::", StringComparison.Ordinal) + 2), type = "";
                if (name.StartsWith("System::", StringComparison.Ordinal))
                {
                    if (new[] { "ContainerStartTime", "CreationDate", "StartTime" }.Contains(shortName)) type = "DateTime";
                    else if (new[] { "CancelEvent", "LocaleId", "VersionBuild", "VersionMajor", "VersionMinor", "TaskTransactionOption", "ErrorCode", "PercentComplete", "ProgressCountHigh", "ProgressCountLow" }.Contains(shortName)) type = "Int32";
                    else if (shortName == "ServerExecutionID") type = "Int64";
                    else if (new[] { "IgnoreConfigurationsOnLoad", "InteractiveMode", "OfflineMode", "Cancel", "ExecutionStatus", "Propagate" }.Contains(shortName)) type = "Boolean";
                    else if (new[] { "CreatorComputerName", "CreatorName", "ExecutionInstanceGUID", "FailedConfigurations", "MachineName", "PackageID", "PackageName", "UserName", "VersionComment", "VersionGUID", "CreationName", "TaskID", "TaskName", "ErrorDescription", "ProgressDescription", "SourceDescription", "SourceID", "SourceName", "VariableDescription", "VariableID" }.Contains(shortName)) type = "String";
                }
                package.Inputs.Add(new Input { Kind = name.StartsWith("System::", StringComparison.Ordinal) ? "system" : "context", Name = name, Scope = scope, Type = type, SqlType = Types.Sql(type), Origin = "runtime" });
            }
        }
        private static void MarkRequired(Package package, string target)
        {
            var selected = package.Targets();
            if (target != null && !selected.Any(t => t.Key == target)) throw new DebugFault("unresolved_binding", "Unbekannter Zielfluss.");
            var queue = new Queue<Input>();
            Action<Input> mark = input => { if (!input.Required) { input.Required = true; queue.Enqueue(input); } };
            foreach (var t in selected.Where(t => target == null || t.Key == target))
            {
                Flow flow = t.Value.Key; var todo = new Stack<Component>(); var seen = new HashSet<Component>(); todo.Push(t.Value.Value);
                while (todo.Count > 0)
                {
                    var c = todo.Pop(); if (!seen.Add(c)) continue;
                    foreach (string text in Expressions(c)) foreach (string reference in References(text))
                        try { mark(package.Resolve(reference, c.Scope)); } catch (DebugFault) { }
                    foreach (string name in new[] { "SqlCommandVariable", "OpenRowsetVariable" })
                    { string reference = PackageReader.P(c.Properties, name); if (reference != "") try { mark(package.Resolve(reference, c.Scope)); } catch (DebugFault) { } }
                    string mapping = PackageReader.P(c.Properties, "ParameterMapping");
                    if (mapping != "") try { foreach (Input input in SqlParameters.Mappings(mapping, package, c.Scope).Values) mark(input); } catch (DebugFault) { }
                    foreach (Port input in c.Inputs) { string output; if (flow.Paths.TryGetValue(input.Id, out output)) { var owner = flow.Components.SingleOrDefault(x => x.Outputs.Any(p => p.Id == output)); if (owner != null) todo.Push(owner); } }
                }
            }
            while (queue.Count > 0)
            { Input input = queue.Dequeue(); if (input.Expression != null) foreach (string reference in References(input.Expression)) try { mark(package.Resolve(reference, input.Scope)); } catch (DebugFault) { } }
        }
        internal Dictionary<string, object> Template()
        {
            var values = Json.Obj();
            foreach (Input input in Package.Inputs)
                if (input.HasDefault && !input.RuntimeAssigned && !input.Sensitive && input.SqlType != null && input.Expression == null) values.Add(input.Key, input.Default);
            return Json.Obj("schemaVersion", new JsonNumber("1"), "profile", "ssis-debug-v1", "packageSha256", Package.Hash, "contextSha256", ContextHash, "values", values, "availableInputs", Package.Inputs.Select(v => (object)v.Metadata()).ToList());
        }
        internal ExpressionValue Resolve(Input input)
        {
            input.Required = true; ExpressionValue found; if (resolved.TryGetValue(input.Key, out found)) return found;
            Budget.Limit(resolving.Count + 1, 16);
            if (!resolving.Add(input.Key)) throw new DebugFault("unresolved_binding", "Zyklischer Variablenausdruck.");
            try
            {
                object value; string sql; bool nullable = false; var dependencies = new HashSet<string>(StringComparer.Ordinal);
                if (Values.TryGetValue(input.Key, out value))
                { sql = Types.Literal(input, value); nullable = value == null; if (input.Expression != null || input.Kind == "system" || input.RuntimeAssigned || value == null) artifacts.Diagnostic("connection_binding", null, "Expliziter pragmatischer Debugwert für " + input.Key + "."); }
                else if (input.Expression != null)
                { var expr = new ExpressionParser(input.Expression, Package, input.Scope, new Dictionary<string, ExpressionValue>(StringComparer.Ordinal), Resolve).Parse(); sql = expr.Sql; nullable = expr.Nullable; dependencies.UnionWith(expr.Inputs); }
                else if (input.HasDefault && !input.RuntimeAssigned) { sql = Types.Literal(input, input.Default); nullable = input.Default == null; }
                else throw new DebugFault("unresolved_binding", "Wert für " + input.Key + " fehlt.");
                if (input.SqlType == null || input.Sensitive) throw new DebugFault("unresolved_binding", "Benötigte Eingabe nicht exportierbar.");
                var result = new ExpressionValue { Sql = input.SqlName, Type = input.SqlType, Nullable = nullable }; result.Inputs.UnionWith(dependencies); result.Inputs.Add(input.Key);
                resolved.Add(input.Key, result); Initializers.Add(input.Key, sql); DeclarationOrder.Add(input); return result;
            }
            finally { resolving.Remove(input.Key); }
        }
        internal readonly Dictionary<string, string> Initializers = new Dictionary<string, string>(StringComparer.Ordinal);
        internal string Database(Component component)
        { string db; if (component.Connection == null || !Connections.TryGetValue(component.Connection, out db) || !Package.Connections.ContainsKey(component.Connection) || Package.Connections[component.Connection] == "unsupported") throw new DebugFault("unresolved_binding", "Explizites unterstütztes Connectionmapping fehlt."); return db; }
        internal string Declarations(IEnumerable<string> keys)
        {
            var set = new HashSet<string>(keys, StringComparer.Ordinal);
            return String.Join("\n", DeclarationOrder.Where(i => set.Contains(i.Key)).Select(i => "DECLARE " + i.SqlName + " " + i.SqlType + " = " + Initializers[i.Key] + ";"));
        }
    }
}
