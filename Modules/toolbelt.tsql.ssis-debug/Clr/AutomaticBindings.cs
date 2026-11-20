using System;
using System.Collections.Generic;
using System.Data.Common;
using System.Globalization;
using System.Linq;
using System.Xml.Linq;

namespace Toolbelt.Tsql.SsisDebug
{
    // Komfortkontext bleibt lokal im Generator. Connectionstrings gelangen
    // weder ins neutrale Austauschmodell noch in die ausgegebenen Artefakte.
    internal static class AutomaticBindings
    {
        internal static void ApplyStarts(Package package, string json, Dictionary<string, object> values, Toolbelt.Ssis.Exchange.ResourceLimits limits)
        {
            if (json == null) return;
            var starts = Json.Object(Json.Parse(json, limits));
            limits.Check("inputs", starts.Count);
            foreach (var entry in starts)
            {
                var inputs = package.Inputs.Where(i => i.Name == entry.Key || i.Scope + "\\" + i.Name == entry.Key).ToList();
                if (inputs.Count != 1) throw new DebugFault("unresolved_binding", "Startwertname ist unbekannt oder im Paket mehrdeutig; bei Bedarf den vollständigen Scope angeben.");
                Input input = inputs[0];
                if (input.Sensitive || input.SqlType == null) throw new DebugFault("unresolved_binding", "Dieser Startwert darf nicht in Debug-SQL übernommen werden.");
                Types.Literal(input, entry.Value);
                values[input.Key] = entry.Value;
            }
        }
        private sealed class Values
        {
            private readonly Package package;
            private readonly Dictionary<string, object> starts;
            private readonly Toolbelt.Ssis.Exchange.ResourceLimits limits;
            private readonly Dictionary<Input, object> cache = new Dictionary<Input, object>();
            private readonly HashSet<Input> resolving = new HashSet<Input>();
            internal Values(Package p, Dictionary<string, object> values, Toolbelt.Ssis.Exchange.ResourceLimits l) { package = p; starts = values; limits = l; }
            internal object Resolve(string reference, string scope)
            {
                Input input = package.Resolve(reference, scope);
                if (input.Sensitive) throw new DebugFault("missing_context", "Die Connectionexpression benötigt sensitive Informationen; stattdessen eine explizite Datenbankzuordnung verwenden.");
                object value;
                if (input.Key != null && starts.TryGetValue(input.Key, out value)) return Typed(input, value);
                if (cache.TryGetValue(input, out value)) return value;
                if (resolving.Count >= 16 || !resolving.Add(input)) throw new DebugFault("unresolved_binding", "Zyklische oder zu tiefe Start-/Connectionexpression.");
                try
                {
                    if (input.Expression != null)
                        value = new ConnectionExpression(input.Expression, name => Resolve(name, input.Scope), limits).Evaluate();
                    else if (input.HasDefault && !input.RuntimeAssigned) value = input.Default;
                    else throw new DebugFault("missing_context", "Ein zur Connectionauflösung erforderlicher Startwert fehlt.");
                    value = Typed(input, value); cache.Add(input, value); return value;
                }
                finally { resolving.Remove(input); }
            }
            private static object Typed(Input input, object value)
            {
                if (value == null) return null;
                string type = input.SqlType ?? "";
                if (type == "tinyint" || type == "smallint" || type == "int" || type == "bigint" || type == "real" || type.StartsWith("decimal(", StringComparison.Ordinal) || type.StartsWith("float(", StringComparison.Ordinal))
                {
                    decimal number; var json = value as JsonNumber;
                    if (!Decimal.TryParse(json == null ? Convert.ToString(value, CultureInfo.InvariantCulture) : json.Text, NumberStyles.Float, CultureInfo.InvariantCulture, out number))
                        throw new DebugFault("unresolved_binding", "Numerischer Startwert für Connectionexpression nicht darstellbar.");
                    return number;
                }
                return value;
            }
        }
        internal static object ResolveValue(Package package, Dictionary<string, object> starts, string reference, string scope, Toolbelt.Ssis.Exchange.ResourceLimits limits)
        { return new Values(package, starts, limits).Resolve(reference, scope); }
        internal static void ResolveStructureValues(Package package, Dictionary<string, object> starts, Toolbelt.Ssis.Exchange.ResourceLimits limits)
        {
            var values = new Values(package, starts, limits);
            foreach (var component in package.Flows.SelectMany(f => f.Components))
            {
                string mode = PackageReader.P(component.Properties, "AccessMode");
                if (component.Kind != "source" || (mode != "1" && mode != "3")) continue;
                string reference = PackageReader.P(component.Properties, mode == "1" ? "OpenRowsetVariable" : "SqlCommandVariable");
                Input input = package.Resolve(reference, component.Scope);
                if (input.Expression != null && !starts.ContainsKey(input.Key))
                {
                    object value = values.Resolve(reference, component.Scope);
                    Types.Literal(input, value); starts.Add(input.Key, value);
                }
            }
        }
        private static string Setting(DbConnectionStringBuilder builder, params string[] aliases)
        {
            string found = null;
            foreach (string alias in aliases)
            {
                object raw; if (!builder.TryGetValue(alias, out raw)) continue;
                string value = Convert.ToString(raw, CultureInfo.InvariantCulture);
                if (String.IsNullOrWhiteSpace(value)) throw new DebugFault("missing_context", "Eine erforderliche Connectionangabe ist leer.");
                if (found != null && !String.Equals(found, value, StringComparison.Ordinal)) throw new DebugFault("unresolved_binding", "Widersprüchliche Connectionangaben.");
                found = value;
            }
            return found;
        }
        internal static string Catalog(Package package, Dictionary<string, object> starts, Toolbelt.Ssis.Exchange.ResourceLimits limits, Artifacts artifacts)
        {
            var needed = new HashSet<string>(package.Flows.SelectMany(f => f.Components).Where(c => c.Connection != null).Select(c => c.Connection), StringComparer.Ordinal);
            var mapping = Json.Obj(); var databases = new List<object>(); var servers = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var values = new Values(package, starts, limits);
            foreach (var connection in package.Document.Definitions.Where(d => d.Kind == "CONNECTION"))
            {
                string id = connection.Get("refId"), provider;
                if (!needed.Contains(id) || !package.Connections.TryGetValue(id, out provider) || provider == "unsupported") continue;
                var element = connection.Element;
                if (element.Elements(Toolbelt.Ssis.Exchange.PackageDocument.Dts + "PropertyExpression")
                    .Any(e => Toolbelt.Ssis.Exchange.PackageDocument.Attribute(e, "Name") != "ConnectionString"))
                    throw new DebugFault("missing_context", "Weitere Connectionproperty-Ausdrücke benötigen eine explizite Zuordnung; statische Verbindungswerte werden nicht stillschweigend übernommen.");
                var expressions = element.Elements(Toolbelt.Ssis.Exchange.PackageDocument.Dts + "PropertyExpression")
                    .Where(e => Toolbelt.Ssis.Exchange.PackageDocument.Attribute(e, "Name") == "ConnectionString").ToList();
                if (expressions.Count > 1) throw new DebugFault("unresolved_binding", "Mehrdeutige Connectionexpression.");
                string connectionString;
                if (expressions.Count == 1)
                {
                    connectionString = new ConnectionExpression(expressions[0].Value, name => values.Resolve(name, connection.LegacyScope), limits).Evaluate() as string;
                    if (connectionString == null) throw new DebugFault("unresolved_binding", "Connectionexpression liefert keinen Text.");
                }
                else
                {
                    var candidates = element.Descendants().Attributes().Where(a => a.Name.LocalName == "ConnectionString").Select(a => a.Value).ToList();
                    if (candidates.Count != 1) throw new DebugFault("missing_context", "Connectionstring fehlt im Paket oder ist nicht eindeutig; Projektkontext beziehungsweise explizite Zuordnung erforderlich.");
                    connectionString = candidates[0];
                }
                limits.Check("jsonDocumentBytes", (long)connectionString.Length * 2);
                DbConnectionStringBuilder builder;
                try { builder = new DbConnectionStringBuilder { ConnectionString = connectionString }; }
                catch (ArgumentException) { throw new DebugFault("unresolved_binding", "Connectionstring kann nicht sicher gelesen werden."); }
                string database = Setting(builder, "Initial Catalog", "Database");
                string server = Setting(builder, "Data Source", "Server", "Address", "Addr", "Network Address");
                if (database == null) throw new DebugFault("missing_context", "Die Paketverbindung enthält keinen Datenbanknamen.");
                Util.Q(database); mapping.Add(id, database);
                if (!databases.Contains(database)) databases.Add(database);
                if (server != null) servers.Add(server);
            }
            if (servers.Count > 1) throw new DebugFault("missing_context", "Mehrere unterschiedliche Server benötigen eine explizite Zuordnung; es werden keine externen Verbindungen geöffnet.");
            if (mapping.Count == 0) throw new DebugFault("missing_context", "Keine benötigte SQL-Server-Verbindung aus dem Paket auflösbar.");
            string primary = package.Flows.SelectMany(f => f.Components).Where(c => c.Kind == "source" && c.Connection != null && mapping.ContainsKey(c.Connection)).Select(c => (string)mapping[c.Connection]).FirstOrDefault() ?? (string)databases[0];
            artifacts.Diagnostic("automatic_connection_binding", null, "Datenbankzuordnung aus dem Paket abgeleitet. Serveridentität und Datenbankzustand sind damit nicht geprüft; SQL nur im vorgesehenen Zielkontext ausführen.");
            return Json.Write(Json.Obj("schemaVersion", new JsonNumber("2"), "defaultDatabase", primary, "databases", databases, "connections", mapping, "flatFileInputs", Json.Obj()), limits);
        }
    }
}
