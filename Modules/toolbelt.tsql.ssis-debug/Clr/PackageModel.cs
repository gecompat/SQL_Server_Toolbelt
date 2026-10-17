using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Xml;
using System.Xml.Linq;

namespace Toolbelt.Tsql.SsisDebug
{
    internal sealed class Input
    {
        internal string Key, Kind, Scope, Name, Type, SqlType, Expression, DtsId, Origin = "design";
        internal bool Sensitive, HasDefault, Required, RuntimeAssigned;
        internal object Default;
        internal string SqlName { get { return "@" + Key; } }
        internal Dictionary<string, object> Metadata()
        {
            return Json.Obj("key", Key, "kind", Kind, "scope", Scope, "name", Name, "ssisType", Type, "sqlType", SqlType,
                "defaultAvailable", HasDefault && SqlType != null && !Sensitive && !RuntimeAssigned, "defaultValue", Sensitive || RuntimeAssigned || SqlType == null ? null : Default,
                "expression", Sensitive ? null : Expression, "valueOrigin", Origin, "requiredForSelectedFlow", Required,
                "sensitive", Sensitive, "state", Sensitive ? "redacted" : SqlType == null ? "unsupported" : RuntimeAssigned ? "needs-value" : Expression != null ? "derived" : HasDefault ? "literal" : "needs-value");
        }
    }
    internal sealed class Column
    {
        internal string Id, Name, Type, SqlType, External, Lineage;
        internal int CodePage;
        internal Dictionary<string, string> Properties;
    }
    internal sealed class Port
    {
        internal string Id, Name, Sync, ErrorDisposition, TruncationDisposition;
        internal bool Error;
        internal readonly List<Column> Columns = new List<Column>();
        internal readonly List<Column> External = new List<Column>();
        internal Dictionary<string, string> Properties;
    }
    internal sealed class Component
    {
        internal string Id, Name, Kind, Class, Connection, Scope;
        internal int Version;
        internal readonly List<Port> Inputs = new List<Port>(), Outputs = new List<Port>();
        internal Dictionary<string, string> Properties;
        internal bool HasPropertyExpressions;
    }
    internal sealed class Flow
    {
        internal string Id, Name;
        internal readonly List<Component> Components = new List<Component>();
        internal readonly Dictionary<string, string> Paths = new Dictionary<string, string>(StringComparer.Ordinal);
    }
    internal sealed class Package
    {
        internal string Hash, Profile;
        internal readonly List<Input> Inputs = new List<Input>();
        internal readonly List<Flow> Flows = new List<Flow>();
        internal readonly Dictionary<string, string> Connections = new Dictionary<string, string>(StringComparer.Ordinal);
        internal readonly List<string> Workflow = new List<string>();
        internal List<KeyValuePair<string, KeyValuePair<Flow, Component>>> Targets()
        {
            int n = 0; var result = new List<KeyValuePair<string, KeyValuePair<Flow, Component>>>();
            foreach (Flow flow in Flows) foreach (Component c in flow.Components.Where(c => c.Kind == "destination" || c.Outputs.Count == 0 && c.Inputs.Count > 0)) result.Add(new KeyValuePair<string, KeyValuePair<Flow, Component>>(Util.Id("f", ++n), new KeyValuePair<Flow, Component>(flow, c)));
            return result;
        }
        internal Input Resolve(string reference, string scope)
        {
            string name = reference;
            if (name.StartsWith("@[", StringComparison.Ordinal) && name.EndsWith("]", StringComparison.Ordinal)) name = name.Substring(2, name.Length - 3);
            if (name.StartsWith("@", StringComparison.Ordinal)) name = name.Substring(1);
            var found = Inputs.Where(v => (v.Name == name || v.DtsId != null && String.Equals(v.DtsId, name, StringComparison.OrdinalIgnoreCase)) && (v.Kind == "project-parameter" || v.Scope == "$Project" || scope == v.Scope || scope.StartsWith(v.Scope + "\\", StringComparison.Ordinal))).OrderByDescending(v => v.Scope.Length).ToList();
            if (found.Count == 0) throw new DebugFault("unresolved_binding", "Variable oder Parameter nicht deklariert.");
            if (found.Count > 1 && found[0].Scope == found[1].Scope) throw new DebugFault("unresolved_binding", "Mehrdeutiger Eingabename.");
            return found[0];
        }
    }

    internal static class Types
    {
        internal static string Sql(string type, int length = 0, int precision = 0, int scale = 0)
        {
            switch ((type ?? "").ToLowerInvariant())
            {
                case "11": case "boolean": case "bool": return "bit";
                case "16": case "sbyte": case "i1": case "2": case "int16": case "i2": return "smallint";
                case "17": case "byte": case "ui1": return "tinyint";
                case "18": case "uint16": case "ui2": case "3": case "int32": case "i4": return "int";
                case "19": case "uint32": case "ui4": case "20": case "int64": case "i8": return "bigint";
                case "21": case "uint64": case "ui8": return "decimal(20,0)";
                case "4": case "single": case "r4": return "real";
                case "5": case "double": case "r8": return "float(53)";
                case "6": case "currency": case "cy": return "decimal(19,4)";
                case "14": case "decimal": case "numeric":
                    if (precision == 0) { precision = 38; scale = 18; }
                    if (precision < 1 || precision > 38 || scale < 0 || scale > precision) return null;
                    return "decimal(" + precision + "," + scale + ")";
                case "8": case "string": case "wstr": return length > 0 && length <= 4000 ? "nvarchar(" + length + ")" : "nvarchar(max)";
                case "str": return length > 0 && length <= 8000 ? "varchar(" + length + ")" : "varchar(max)";
                case "7": case "datetime": case "date": case "dbtimestamp": return "datetime2(7)";
                case "dbtimestamp2": return scale <= 7 ? "datetime2(" + scale + ")" : null;
                case "dbdate": return "date";
                case "dbtime": return "time(0)";
                case "dbtime2": return scale <= 7 ? "time(" + scale + ")" : null;
                case "72": case "guid": return "uniqueidentifier";
                case "bytes": return length > 0 && length <= 8000 ? "varbinary(" + length + ")" : "varbinary(max)";
                default: return null;
            }
        }
        internal static string Literal(Input v, object value)
        {
            if (v.SqlType == null) throw new DebugFault("unsupported_expression", "Eingabetyp nicht unterstützt.");
            if (v.Sensitive) throw new DebugFault("unresolved_binding", "Sensitive Eingabe wird nicht in SQL exportiert.");
            if (value == null) return "NULL";
            string text = value is JsonNumber ? ((JsonNumber)value).Text : value as string;
            string t = v.SqlType;
            if (t == "bit") { if (!(value is bool)) throw new DebugFault("invalid_template", "Boolean erwartet."); return (bool)value ? "1" : "0"; }
            if (t.StartsWith("nvarchar", StringComparison.Ordinal))
            { if (text == null || value is JsonNumber) throw new DebugFault("invalid_template", "Text erwartet."); var size = Regex.Match(t, "\\A(?:n?varchar)\\(([0-9]+)\\)\\z"); if (size.Success && text.Length > Int32.Parse(size.Groups[1].Value, CultureInfo.InvariantCulture)) throw new DebugFault("invalid_template", "Text überschreitet die deklarierte Länge."); return Util.L(text); }
            if (t == "uniqueidentifier")
            { Guid g; if (text == null || !Guid.TryParseExact(text, "D", out g)) throw new DebugFault("invalid_template", "GUID ungültig."); return Util.L(g.ToString("D")); }
            if (t.StartsWith("varbinary", StringComparison.Ordinal))
            { if (text == null || !Regex.IsMatch(text, "\\A0x(?:[0-9A-Fa-f]{2})*\\z")) throw new DebugFault("invalid_template", "Hexwert ungültig."); var size = Regex.Match(t, "\\Avarbinary\\(([0-9]+)\\)\\z"); if (size.Success && (text.Length - 2) / 2 > Int32.Parse(size.Groups[1].Value, CultureInfo.InvariantCulture)) throw new DebugFault("invalid_template", "Binärwert überschreitet die deklarierte Länge."); return text; }
            if (t.StartsWith("datetime2", StringComparison.Ordinal) || t == "date" || t.StartsWith("time", StringComparison.Ordinal))
            {
                DateTime dt; string[] formats = t == "date" ? new[] { "yyyy-MM-dd" } : t.StartsWith("time", StringComparison.Ordinal) ? new[] { "HH:mm:ss", "HH:mm:ss.FFFFFFF" } : new[] { "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd'T'HH:mm:ss.FFFFFFF" };
                if (text == null || !DateTime.TryParseExact(text, formats, CultureInfo.InvariantCulture, DateTimeStyles.None, out dt)) throw new DebugFault("invalid_template", "ISO-Datum/Zeit ungültig.");
                var scale = Regex.Match(t, "\\A(?:time|datetime2)\\(([0-7])\\)\\z"); int dot = text.IndexOf('.');
                if (scale.Success && dot >= 0 && text.Substring(dot + 1).TrimEnd('0').Length > Int32.Parse(scale.Groups[1].Value, CultureInfo.InvariantCulture)) throw new DebugFault("invalid_template", "Zeitpräzision nicht exakt darstellbar.");
                return Util.L(text);
            }
            if (text == null || !Regex.IsMatch(text, "\\A-?(?:0|[1-9][0-9]*)(?:\\.[0-9]+)?(?:[eE][+-]?[0-9]+)?\\z")) throw new DebugFault("invalid_template", "Numerischer Wert ungültig.");
            if (value is JsonNumber && t != "real" && !t.StartsWith("float", StringComparison.Ordinal))
            { decimal safe; if (!Decimal.TryParse(text, NumberStyles.AllowLeadingSign, CultureInfo.InvariantCulture, out safe) || Math.Abs(safe) > 9007199254740991m) throw new DebugFault("invalid_template", "JSON-Zahl außerhalb des exakten Integerbereichs; String verwenden."); }
            if (t == "real" || t.StartsWith("float", StringComparison.Ordinal))
            { double f; if (!Double.TryParse(text, NumberStyles.Float, CultureInfo.InvariantCulture, out f) || Double.IsNaN(f) || Double.IsInfinity(f) || (t == "real" && (f > Single.MaxValue || f < -Single.MaxValue))) throw new DebugFault("invalid_template", "Float außerhalb des Wertebereichs."); return text; }
            if (t.StartsWith("decimal", StringComparison.Ordinal))
            {
                var m = Regex.Match(t, "decimal\\(([0-9]+),([0-9]+)\\)"); int p = Int32.Parse(m.Groups[1].Value), s = Int32.Parse(m.Groups[2].Value);
                if (!Regex.IsMatch(text, "\\A-?[0-9]+(?:\\.[0-9]+)?\\z")) throw new DebugFault("invalid_template", "Exakter Dezimalstring erwartet.");
                string[] a = text.TrimStart('-').Split('.'); int before = a[0].TrimStart('0').Length, after = a.Length == 1 ? 0 : a[1].Length;
                bool unsigned64 = new[] { "21", "uint64", "ui8" }.Contains((v.Type ?? "").ToLowerInvariant());
                if (value is JsonNumber && !unsigned64 || before > p - s || after > s || unsigned64 && (text.StartsWith("-", StringComparison.Ordinal) || String.CompareOrdinal(a[0].TrimStart('0').PadLeft(20, '0'), "18446744073709551615") > 0)) throw new DebugFault("invalid_template", "Dezimalwert außerhalb des exakten Wertebereichs.");
                return text;
            }
            decimal n; if (!Decimal.TryParse(text, NumberStyles.AllowLeadingSign, CultureInfo.InvariantCulture, out n)) throw new DebugFault("invalid_template", "Integer erwartet.");
            decimal min = t == "tinyint" ? 0 : t == "smallint" ? Int16.MinValue : t == "int" ? Int32.MinValue : Int64.MinValue;
            decimal max = t == "tinyint" ? Byte.MaxValue : t == "smallint" ? Int16.MaxValue : t == "int" ? Int32.MaxValue : Int64.MaxValue;
            switch ((v.Type ?? "").ToLowerInvariant()) { case "i1": case "sbyte": case "16": min = SByte.MinValue; max = SByte.MaxValue; break; case "ui2": case "uint16": case "18": min = 0; max = UInt16.MaxValue; break; case "ui4": case "uint32": case "19": min = 0; max = UInt32.MaxValue; break; }
            if (n < min || n > max) throw new DebugFault("invalid_template", "Integer außerhalb des Wertebereichs."); return text;
        }
    }

    internal static class PackageReader
    {
        internal static readonly XNamespace Dts = "www.microsoft.com/SqlServer/Dts";
        internal static string A(XElement e, string name) { return (string)e.Attribute(name) ?? (string)e.Attribute(Dts + name) ?? ""; }
        internal static int N(XElement e, string name) { string value = A(e, name); int n; if (value == "") return 0; if (!Int32.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out n) || n < 0) throw new DebugFault("invalid_lineage", "Numerisches XML-Attribut ungültig."); return n; }
        internal static Dictionary<string, string> Props(XElement e, string container = "properties", string property = "property")
        {
            var r = new Dictionary<string, string>(StringComparer.Ordinal);
            XElement c = e.Element(container);
            if (c != null) foreach (var p in c.Elements(property)) { string n = A(p, "name"); if (r.ContainsKey(n)) throw new DebugFault("invalid_lineage", "Doppelte Komponenteneigenschaft."); r.Add(n, p.Value); }
            return r;
        }
        internal static string P(Dictionary<string, string> p, string name, string fallback = "") { string v; return p.TryGetValue(name, out v) ? v : fallback; }
        internal static Package Read(byte[] bytes, Budget budget)
        {
            Budget.Limit(bytes.LongLength, 16777216);
            if (bytes.Length == 0) throw new DebugFault("unsupported_package_format", "Leeres Paket.");
            if (bytes.Length >= 4 && ((bytes[0] == 0 && bytes[1] == 0) || (bytes[2] == 0 && bytes[3] == 0))) throw new DebugFault("unsupported_package_format", "UTF-32 nicht unterstützt.");
            var settings = new XmlReaderSettings { DtdProcessing = DtdProcessing.Prohibit, XmlResolver = null, MaxCharactersInDocument = 16777216, MaxCharactersFromEntities = 0 };
            XDocument doc;
            try
            {
                // Tiefen-/Knotenprüfung vor dem Aufbau des DOM; kein externer Resolver.
                using (var ms = new MemoryStream(bytes)) using (var r = XmlReader.Create(ms, settings))
                { int nodes = 0; while (r.Read()) { budget.Check(); Budget.Limit(r.Depth, 128); Budget.Limit(++nodes, 262144); if (r.NodeType == XmlNodeType.XmlDeclaration) { string encoding = r.GetAttribute("encoding"); if (encoding != null && !new[] { "utf-8", "utf-16", "utf-16le", "utf-16be" }.Contains(encoding.ToLowerInvariant())) throw new DebugFault("unsupported_package_format", "Nur UTF-8/UTF-16 unterstützt."); } if (r.NamespaceURI == "http://www.w3.org/2001/XInclude") throw new DebugFault("unsupported_package_format", "XInclude nicht unterstützt."); } }
                using (var ms = new MemoryStream(bytes)) using (var r = XmlReader.Create(ms, settings)) doc = XDocument.Load(r, LoadOptions.None);
            }
            catch (XmlException) { throw new DebugFault("unsupported_package_format", "XML/Encoding ungültig; nur UTF-8/UTF-16 ohne DTD."); }
            var root = doc.Root;
            if (root == null || root.Name != Dts + "Executable") throw new DebugFault("unsupported_package_format", "DTSX2-Root fehlt.");
            var formats = root.Elements(Dts + "Property").Where(x => A(x, "Name") == "PackageFormatVersion").Select(x => x.Value).ToList();
            string format = formats.Count == 1 ? formats[0] : null;
            if (format != "6" && format != "8") return new Package { Hash = Util.Hash(bytes), Profile = "unsupported" };
            var result = new Package { Hash = Util.Hash(bytes), Profile = format == "6" ? "2012/01" : "2014/01" };
            var ids = new HashSet<string>(StringComparer.Ordinal); int components = 0, columns = 0, paths = 0;
            foreach (XElement e in root.DescendantsAndSelf())
            {
                budget.Check();
                if (e.Name.Namespace != Dts && e.Name.Namespace != XNamespace.None) continue;
                string id = A(e, "refId"); Budget.Limit(id.Length, 4000); if (id != "" && !ids.Add(id)) throw new DebugFault("invalid_lineage", "Doppelte refId.");
                if (e.Name == Dts + "Executable") result.Workflow.Add(A(e, "ExecutableType"));
            }
            foreach (XElement v in root.Descendants(Dts + "Variable"))
            {
                XElement parent = v.Ancestors(Dts + "Executable").FirstOrDefault(); XElement value = v.Element(Dts + "VariableValue");
                string name = A(v, "Namespace") + "::" + A(v, "ObjectName"), expr = A(v, "Expression");
                var input = new Input { Kind = "variable", DtsId = A(v, "DTSID") == "" ? null : A(v, "DTSID"), Scope = parent == null ? "Package" : A(parent, "refId"), Name = name, Type = value == null ? "" : A(value, "DataType"), Sensitive = Util.Flag(A(v, "Sensitive")), Expression = Util.Flag(A(v, "EvaluateAsExpression")) ? expr : null };
                input.SqlType = Types.Sql(input.Type); input.HasDefault = value != null && input.Expression == null; input.Default = input.HasDefault ? Default(value.Value, input) : null;
                // Unbekannte schreibende Tasks/Loops vor dem Datenfluss sind kein Designwertbeweis.
                input.RuntimeAssigned = result.Workflow.Any(t => t.IndexOf("Script", StringComparison.OrdinalIgnoreCase) >= 0 || t.IndexOf("For", StringComparison.OrdinalIgnoreCase) >= 0 || t.IndexOf("ExecuteSQL", StringComparison.OrdinalIgnoreCase) >= 0);
                result.Inputs.Add(input);
            }
            foreach (XElement v in root.Descendants(Dts + "PackageParameter"))
            {
                XElement value = v.Elements(Dts + "Property").FirstOrDefault(p => A(p, "Name") == "ParameterValue");
                var input = new Input { Kind = "package-parameter", Scope = "Package", Name = "$Package::" + A(v, "ObjectName"), Type = A(v, "DataType"), Sensitive = Util.Flag(A(v, "Sensitive")), HasDefault = value != null };
                input.SqlType = Types.Sql(input.Type); input.Default = value == null ? null : Default(value.Value, input); result.Inputs.Add(input);
            }
            foreach (XElement c in root.Descendants(Dts + "ConnectionManagers").Elements(Dts + "ConnectionManager"))
            {
                string id = A(c, "refId"), kind = A(c, "CreationName");
                if (id == "" || result.Connections.ContainsKey(id)) throw new DebugFault("invalid_lineage", "Connection-ID ungültig.");
                result.Connections.Add(id, kind.StartsWith("OLEDB", StringComparison.Ordinal) ? "sqlserver-oledb" : kind.IndexOf("ADO.NET", StringComparison.OrdinalIgnoreCase) >= 0 ? "sqlserver-adonet" : "unsupported");
            }
            foreach (XElement exe in root.DescendantsAndSelf(Dts + "Executable"))
            {
                string kind = A(exe, "ExecutableType");
                if (!(kind == "SSIS.Pipeline" || kind == "SSIS.Pipeline.3" || kind == "STOCK:SSIS.Pipeline" || kind == "Microsoft.Pipeline")) continue;
                XElement pipeline = exe.Element(Dts + "ObjectData") == null ? null : exe.Element(Dts + "ObjectData").Element("pipeline");
                if (pipeline == null) throw new DebugFault("invalid_lineage", "Pipeline-Struktur fehlt.");
                var flow = new Flow { Id = A(exe, "refId"), Name = A(exe, "ObjectName") };
                foreach (XElement c in pipeline.Elements("components").Elements("component"))
                {
                    Budget.Limit(++components, 512);
                    var component = new Component { Id = A(c, "refId"), Scope = flow.Id, Name = A(c, "name"), Class = A(c, "componentClassID"), Version = N(c, "version"), Properties = Props(c), HasPropertyExpressions = c.Descendants(Dts + "PropertyExpression").Any() };
                    component.Kind = ComponentKind(component.Class, component.Version, component.Properties);
                    var connections = c.Elements("connections").Elements("connection").ToList();
                    if (connections.Count == 1) component.Connection = A(connections[0], "connectionManagerRefId");
                    foreach (XElement port in c.Elements("inputs").Elements("input")) component.Inputs.Add(ReadPort(port, true, ref columns));
                    foreach (XElement port in c.Elements("outputs").Elements("output")) component.Outputs.Add(ReadPort(port, false, ref columns));
                    if (component.Id == "") throw new DebugFault("invalid_lineage", "Komponenten-ID fehlt."); flow.Components.Add(component);
                }
                foreach (XElement path in pipeline.Elements("paths").Elements("path"))
                { Budget.Limit(++paths, 2048); string input = A(path, "endId"), output = A(path, "startId"); if (flow.Paths.ContainsKey(input)) throw new DebugFault("ambiguous_path", "Mehrere Kanten an einem Input."); flow.Paths.Add(input, output); }
                var outputs = new HashSet<string>(flow.Components.SelectMany(c => c.Outputs).Select(p => p.Id), StringComparer.Ordinal);
                var inputs = new HashSet<string>(flow.Components.SelectMany(c => c.Inputs).Select(p => p.Id), StringComparer.Ordinal);
                if (flow.Paths.Any(p => !outputs.Contains(p.Value) || !inputs.Contains(p.Key))) throw new DebugFault("invalid_lineage", "Dangling Pipelinekante.");
                result.Flows.Add(flow);
            }
            if (result.Inputs.Where(v => v.DtsId != null).GroupBy(v => v.DtsId, StringComparer.OrdinalIgnoreCase).Any(g => g.Count() > 1)) throw new DebugFault("invalid_lineage", "Doppelte Variablen-DTSID.");
            Budget.Limit(result.Inputs.Count, 2048); return result;
        }
        private static object Default(string text, Input v)
        {
            if (v.Sensitive || v.SqlType == null) { v.HasDefault = false; return null; }
            object value = text;
            if (v.SqlType == "bit")
            { if (!new[] { "0", "1", "-1", "true", "false" }.Contains(text.ToLowerInvariant())) { v.HasDefault = false; v.Origin = "design-unresolved"; return text; } value = Util.Flag(text) || text == "-1"; }
            try { Types.Literal(v, value); } catch (DebugFault) { v.HasDefault = false; v.Origin = "design-unresolved"; }
            return value;
        }
        private static Port ReadPort(XElement e, bool input, ref int count)
        {
            var p = new Port { Id = A(e, "refId"), Name = A(e, "name"), Sync = A(e, "synchronousInputId"), Error = Util.Flag(A(e, "isErrorOut")), ErrorDisposition = A(e, "errorRowDisposition"), TruncationDisposition = A(e, "truncationRowDisposition"), Properties = Props(e) };
            if (p.Id == "") throw new DebugFault("invalid_lineage", "Port-ID fehlt.");
            foreach (XElement c in e.Elements(input ? "inputColumns" : "outputColumns").Elements(input ? "inputColumn" : "outputColumn")) p.Columns.Add(ReadColumn(c, ref count));
            foreach (XElement c in e.Elements("externalMetadataColumns").Elements("externalMetadataColumn")) p.External.Add(ReadColumn(c, ref count));
            return p;
        }
        private static Column ReadColumn(XElement c, ref int count)
        {
            Budget.Limit(++count, 8192); string t = A(c, "dataType"); if (t == "") t = A(c, "cachedDataType");
            return new Column { Id = A(c, "refId"), Lineage = A(c, "lineageId"), Name = A(c, "name") == "" ? A(c, "cachedName") : A(c, "name"), Type = t, SqlType = Types.Sql(t, N(c, "length") == 0 ? N(c, "cachedLength") : N(c, "length"), N(c, "precision") == 0 ? N(c, "cachedPrecision") : N(c, "precision"), c.Attribute("scale") == null ? N(c, "cachedScale") : N(c, "scale")), External = A(c, "externalMetadataColumnId"), CodePage = N(c, "codePage") == 0 ? N(c, "cachedCodePage") : N(c, "codePage"), Properties = Props(c) };
        }
        private static string ComponentKind(string id, int version, Dictionary<string, string> properties)
        {
            // Nur strukturell qualifizierte native Komponentenprofile.
            bool source = id == "Microsoft.OLEDBSource" || id == "{165A526D-D5DE-47FF-96A6-F8274C19826B}";
            bool destination = id == "Microsoft.OLEDBDestination" || id == "{4ADA7EAA-136C-4215-8098-D7A7C27FC0D1}";
            bool lookup = id == "Microsoft.Lookup" || id == "{671046B0-AA63-4C9F-90E4-C06E0B710CE3}";
            bool managed = id == "Microsoft.ManagedComponentHost" || id == "{874F7595-FB5F-40FF-96AF-FBFF8250E3EF}";
            if (source ? version != 7 : destination ? version != 4 : lookup ? version != 6 : managed ? version != 0 && version != 1 : version != 1) return "unsupported";
            switch (id)
            {
                case "{165A526D-D5DE-47FF-96A6-F8274C19826B}": case "Microsoft.OLEDBSource": return "source";
                case "{4ADA7EAA-136C-4215-8098-D7A7C27FC0D1}": case "Microsoft.OLEDBDestination": return "destination";
                case "{B594E9A8-4351-4939-891C-CFE1AB93E925}": case "Microsoft.UnionAll": return "union";
                case "{49928E82-9C4E-49F0-AABE-3812B82707EC}": case "Microsoft.DerivedColumn": return "derived";
                case "{62B1106C-7DB8-4EC8-ADD6-4C664DFFC54A}": case "Microsoft.DataConvert": return "convert";
                case "{671046B0-AA63-4C9F-90E4-C06E0B710CE3}": case "Microsoft.Lookup": return "lookup";
                case "{7F88F654-4E20-4D14-84F4-AF9C925D3087}": case "Microsoft.ConditionalSplit": return "split";
                case "Microsoft.ManagedComponentHost": case "{874F7595-FB5F-40FF-96AF-FBFF8250E3EF}":
                    string name = P(properties, "UserComponentTypeName");
                    if (Regex.IsMatch(name, "\\AMicrosoft\\.SqlServer\\.Dts\\.Pipeline\\.ADONETSource, Microsoft\\.SqlServer\\.ADONETSrc, Version=(11|12|13|14|15|16|17)\\.0\\.0\\.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91\\z")) return "source";
                    if (Regex.IsMatch(name, "\\AMicrosoft\\.SqlServer\\.Dts\\.Pipeline\\.ADONETDestination, Microsoft\\.SqlServer\\.ADONETDest, Version=(11|12|13|14|15|16|17)\\.0\\.0\\.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91\\z")) return "destination";
                    return "unsupported";
                default: return "unsupported";
            }
        }
    }
}
