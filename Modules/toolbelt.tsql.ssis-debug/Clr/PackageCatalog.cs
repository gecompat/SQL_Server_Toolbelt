using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace Toolbelt.Tsql.SsisDebug
{
    // Paketmetadaten sind eine Entwurfssicht, kein Nachweis des SQL-Zielzustands.
    // Dieser Provider hat absichtlich weder Connection noch SQL-Adapter.
    internal sealed class PackageCatalog : ICatalog
    {
        private readonly Dictionary<string, BoundObject> objects = new Dictionary<string, BoundObject>(StringComparer.Ordinal);
        private readonly Package package;
        private readonly Options options;
        private readonly Budget budget;
        internal PackageCatalog(Package p, Options o, Budget b) { package = p; options = o; budget = b; }
        public string Collation(string database) { return "Latin1_General_100_BIN2"; }
        public bool IsCollation(string name) { return name == "Latin1_General_100_BIN2" || name == "Latin1_General_100_BIN2_UTF8"; }
        public int CodePage(string name) { if (!IsCollation(name)) throw new DebugFault("missing_context", "Collation ist ohne Katalog nicht bekannt."); return name.EndsWith("_UTF8", StringComparison.Ordinal) ? 65001 : 1252; }
        public string BindIdentifier(string database, IEnumerable<string> candidates, string name)
        {
            var names = candidates.Where(n => String.Equals(n, name, StringComparison.Ordinal)).ToList();
            if (names.Count > 1) throw new DebugFault("unresolved_binding", "Paketmetadaten enthalten mehrdeutige Spaltennamen.");
            return names.SingleOrDefault();
        }
        public BoundObject Resolve(string database, string schema, string name)
        {
            BoundObject value; return objects.TryGetValue(database + "\0" + (schema ?? "dbo") + "\0" + name, out value) ? value : null;
        }
        private sealed class Tables : TSqlFragmentVisitor
        {
            internal readonly List<NamedTableReference> Items = new List<NamedTableReference>();
            public override void ExplicitVisit(NamedTableReference node) { Items.Add(node); }
        }
        internal void Bind(Bindings bindings)
        {
            var syntax = new SqlSafety(budget, options.Version, this, bindings.Databases, package.Inputs.Select(i => i.SqlName), null);
            foreach (var c in package.Flows.SelectMany(f => f.Components).Where(c => c.Kind == "source" || c.Kind == "lookup"))
            {
                string database = bindings.Database(c), sql;
                {
                    string mode = PackageReader.P(c.Properties, "AccessMode", "2");
                    if (mode == "0") sql = "SELECT * FROM " + PackageReader.P(c.Properties, "OpenRowset", PackageReader.P(c.Properties, "TableOrViewName"));
                    else if (mode == "1" || mode == "3")
                    {
                        string reference = PackageReader.P(c.Properties, mode == "1" ? "OpenRowsetVariable" : "SqlCommandVariable");
                        Input input = package.Resolve(reference, c.Scope); object raw;
                        if (!bindings.Values.TryGetValue(input.Key, out raw)) raw = input.HasDefault && !input.RuntimeAssigned ? input.Default : null;
                        if (!(raw is string) || input.Expression != null && !bindings.Values.ContainsKey(input.Key))
                            throw new DebugFault("missing_context", "Ein SQL-Strukturwert muss vor der paketbasierten Analyse eindeutig als Startwert vorliegen.");
                        sql = mode == "1" ? "SELECT * FROM " + (string)raw : (string)raw;
                    }
                    else if (mode == "2") sql = PackageReader.P(c.Properties, "SqlCommand");
                    else throw new DebugFault("unsupported_component", "Paketbasierte Source-AccessMode nicht unterstützt.");
                    string parameterMapping = PackageReader.P(c.Properties, "ParameterMapping", PackageReader.P(c.Properties, "ParameterMappings"));
                    if (sql.IndexOf('?') >= 0 || parameterMapping != "")
                        sql = SqlParameters.Replace(sql, SqlParameters.Mappings(parameterMapping, package, c.Scope), i => i.SqlName);
                }
                var tables = new Tables(); syntax.Parse(sql).Accept(tables);
                var names = tables.Items.Select(t => t.SchemaObject.Identifiers.Select(i => i.Value).ToList()).ToList();
                if (names.Count == 0) continue; // Konstante SELECTs brauchen keine Objektmetadaten.
                if (names.Count != 1 || names[0].Count > 3)
                    throw new DebugFault("missing_context", "Mehrtabellen-/Serverabfragen benötigen zusätzliche Metadaten oder die Katalogabnahme.");
                var parts = names[0]; string db = parts.Count == 3 ? parts[0] : database, schema = parts.Count >= 2 ? parts[parts.Count - 2] : "dbo", name = parts[parts.Count - 1];
                var ports = c.Outputs.Where(p => !p.Error).ToList();
                var columns = ports.SelectMany(p => p.External.Count != 0 ? p.External : p.Columns).ToList();
                if (columns.Count == 0) throw new DebugFault("missing_context", "Im Paket fehlen die externen Spaltenmetadaten.");
                string key = db + "\0" + schema + "\0" + name; BoundObject bound;
                if (!objects.TryGetValue(key, out bound))
                {
                    budget.CheckLimit("catalogObjects", objects.Count + 1);
                    bound = new BoundObject { Database = db, Schema = schema, Name = name, Kind = "U", Fingerprint = package.Hash + ":package-only" };
                    objects.Add(key, bound);
                }
                foreach (var column in columns)
                {
                    if (column.SqlType == null) throw new DebugFault("missing_context", "Ein Paketspaltentyp ist nicht auf SQL abbildbar.");
                    var previous = bound.Columns.FirstOrDefault(x => x.Name == column.Name);
                    if (previous != null)
                    {
                        if (previous.SqlType != column.SqlType) throw new DebugFault("unresolved_binding", "Widersprüchliche Paketspaltentypen.");
                        continue;
                    }
                    bound.Columns.Add(new BoundColumn { Name = column.Name, SqlType = column.SqlType, Nullable = true,
                        ColumnId = bound.Columns.Count + 1, Collation = column.Type == "str" || column.Type == "wstr" ? column.CodePage == 65001 ? "Latin1_General_100_BIN2_UTF8" : "Latin1_General_100_BIN2" : null });
                }
            }
        }
        internal static void MarkUnverified(Artifacts artifacts)
        {
            foreach (var row in artifacts.Rows)
            {
                if (row.Safety == "passed") { row.Safety = "not_checked"; row.Evidence = "pragmatic"; }
                if (row.Kind.EndsWith("Sql", StringComparison.Ordinal) || row.Kind == "DebugScript" || row.Kind == "ProcedureDefinition")
                {
                    if (row.Safety != "blocked") { row.Evidence = "pragmatic"; row.Safety = "not_checked"; }
                    row.Executable = false;
                    // Einzelartefakte behalten ihre gehashten Bytes. Nur das
                    // zusammengesetzte, nicht separat gehashte Script ergaenzen.
                    if (row.Kind == "DebugScript" && row.Complete)
                        artifacts.ReplaceContent(row, "-- Paketbasierter Debugentwurf: Zielobjekte, RLS, Collation und Serveridentität nicht kataloggeprüft.\n" + row.Content);
                }
            }
            artifacts.Diagnostic("package_metadata_only", null, "SQL aus DTSX-Metadaten erzeugt, ohne Quellkatalogzugriff. Objektart, Typen, RLS und Collation nicht am Ziel geprüft. Ordinale Namensbindung und BIN2/1252 beziehungsweise explizite UTF8-Paketcodepage sind Entwurfsannahmen. IsExecutable bleibt deshalb false; manuelle Ausführung nach Prüfung möglich.");
        }
    }
}
