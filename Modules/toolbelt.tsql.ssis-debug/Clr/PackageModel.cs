using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

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
        internal Toolbelt.Ssis.Exchange.PackageDocument Document;
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

    // Projektion des kanonischen typisierten Kerns in den bestehenden Debugvertrag.
    // Kein XML-Leser und keine eigene native Port-/Spaltenreferenzauflösung.
    internal static class PackageReader
    {
        internal static string P(Dictionary<string,string> properties, string key, string fallback = "")
        { string value; return properties.TryGetValue(key,out value) ? value : fallback; }
        internal static Package Read(byte[] bytes, Budget budget)
        {
            try
            {
                var document = Toolbelt.Ssis.Exchange.PackageDocument.Read(bytes,budget.Check);
                var result = new Package { Hash = document.PackageSha256.ToUpperInvariant(), Profile = document.XmlProfile == "UNKNOWN" ? "unsupported" : document.XmlProfile, Document = document };
                if (result.Profile == "unsupported") return result;
                var definitions = document.Definitions;
                if (document.HasDuplicateNativeIds) throw new DebugFault("invalid_lineage","Doppelte refId.");
                if (document.HasOverlongNativeIds) throw new DebugFault("resource_limit","Feste Kennungsgrenze überschritten.");
                foreach (var executable in definitions.Where(x => x.Kind == "PACKAGE" || x.Kind == "EXECUTABLE" && x.Attributes["isEventHandler"] as bool? != true)) result.Workflow.Add(executable.Get("ExecutableType"));
                foreach (var variable in definitions.Where(x => x.Kind == "VARIABLE"))
                {
                    var input = new Input { Kind = "variable", DtsId = variable.Get("DTSID") == "" ? null : variable.Get("DTSID"), Scope = variable.LegacyScope,
                        Name = variable.Get("Namespace")+"::"+variable.Name, Type = variable.VariableDataType, Sensitive = Util.Flag(variable.Get("Sensitive")),
                        Expression = Util.Flag(variable.Get("EvaluateAsExpression")) ? variable.Get("Expression") : null };
                    input.SqlType=Types.Sql(input.Type); input.HasDefault=variable.HasDefault && input.Expression==null; input.Default=input.HasDefault?Default(variable.ValueText,input):null;
                    input.RuntimeAssigned=result.Workflow.Any(t => t.IndexOf("Script",StringComparison.OrdinalIgnoreCase)>=0 || t.IndexOf("For",StringComparison.OrdinalIgnoreCase)>=0 || t.IndexOf("ExecuteSQL",StringComparison.OrdinalIgnoreCase)>=0);
                    result.Inputs.Add(input);
                }
                foreach (var parameter in definitions.Where(x => x.Kind == "PARAMETER"))
                {
                    var input=new Input {Kind="package-parameter",Scope="Package",Name="$Package::"+parameter.Name,Type=parameter.Get("DataType"),Sensitive=Util.Flag(parameter.Get("Sensitive")),HasDefault=parameter.HasDefault};
                    input.SqlType=Types.Sql(input.Type); input.Default=parameter.HasDefault?Default(parameter.ValueText,input):null; result.Inputs.Add(input);
                }
                foreach (var connection in definitions.Where(x => x.Kind == "CONNECTION"))
                {
                    string id=connection.Get("refId"),kind=connection.Get("CreationName");
                    if(id=="" || result.Connections.ContainsKey(id)) throw new DebugFault("invalid_lineage","Connection-ID ungültig.");
                    result.Connections.Add(id,kind.StartsWith("OLEDB",StringComparison.Ordinal)?"sqlserver-oledb":kind.IndexOf("ADO.NET",StringComparison.OrdinalIgnoreCase)>=0?"sqlserver-adonet":"unsupported");
                }
                int components=0,columns=0,paths=0;
                var byId=definitions.ToDictionary(x=>x.Id,StringComparer.Ordinal);
                foreach (var executable in definitions.Where(x=>x.IsPipeline))
                {
                    if(!executable.HasPipeline) throw new DebugFault("invalid_lineage","Pipeline-Struktur fehlt.");
                    if(document.IncompletePipelineScopes.Contains(executable.Id)) throw new DebugFault("invalid_lineage","Dangling Pipelinekante.");
                    var flow=new Flow {Id=executable.Get("refId"),Name=executable.Name};
                    foreach(var definition in definitions.Where(x=>x.Kind=="COMPONENT" && x.Parent==executable.Id))
                    {
                        Budget.Limit(++components,512);
                        var component=new Component {Id=definition.Get("refId"),Scope=flow.Id,Name=definition.Name,Class=definition.Get("componentClassID"),Version=definition.Nonnegative("version"),Properties=definition.Properties,HasPropertyExpressions=definition.HasPropertyExpressions,Kind=definition.ComponentKind};
                        string manager; if(definition.Native.TryGetValue("@singleConnection",out manager)) component.Connection=manager;
                        foreach(var port in definitions.Where(x=>x.Kind=="PORT" && x.Parent==definition.Id))
                        {
                            var projection=ReadPort(port,definitions,ref columns);
                            if((string)port.Attributes["direction"]=="INPUT") component.Inputs.Add(projection); else component.Outputs.Add(projection);
                        }
                        if(component.Id=="") throw new DebugFault("invalid_lineage","Komponenten-ID fehlt."); flow.Components.Add(component);
                    }
                    foreach(var path in document.Relationships.Where(x=>x.Kind=="PIPELINE_PATH" && x.Scope==executable.Id))
                    {
                        Budget.Limit(++paths,2048);
                        if(path.Resolution!="RESOLVED") throw new DebugFault("invalid_lineage","Dangling Pipelinekante.");
                        string input=byId[path.To].Get("refId"),output=byId[path.From].Get("refId");
                        if(flow.Paths.ContainsKey(input)) throw new DebugFault("ambiguous_path","Mehrere Kanten an einem Input.");
                        flow.Paths.Add(input,output);
                    }
                    result.Flows.Add(flow);
                }
                if(result.Inputs.Where(v=>v.DtsId!=null).GroupBy(v=>v.DtsId,StringComparer.OrdinalIgnoreCase).Any(g=>g.Count()>1)) throw new DebugFault("invalid_lineage","Doppelte Variablen-DTSID.");
                Budget.Limit(result.Inputs.Count,2048); return result;
            }
            catch(Toolbelt.Ssis.Exchange.ModelException error)
            { throw new DebugFault(error.Code=="LIMIT_EXCEEDED"?"resource_limit":error.Code=="UNSUPPORTED_PACKAGE_FORMAT"?"unsupported_package_format":"invalid_lineage","Neutraler DTSX-Kern: "+error.Code); }
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
        private static Port ReadPort(Toolbelt.Ssis.Exchange.PackageDocument.Definition definition, IList<Toolbelt.Ssis.Exchange.PackageDocument.Definition> objects, ref int count)
        {
            var port=new Port {Id=definition.Get("refId"),Name=definition.Name,Sync=definition.Get("synchronousInputId"),Error=Util.Flag(definition.Get("isErrorOut")),ErrorDisposition=definition.Get("errorRowDisposition"),TruncationDisposition=definition.Get("truncationRowDisposition"),Properties=definition.Properties};
            if(port.Id=="") throw new DebugFault("invalid_lineage","Port-ID fehlt.");
            foreach(var column in objects.Where(x=>x.Kind=="COLUMN" && x.Parent==definition.Id))
            {
                var projection=ReadColumn(column,ref count);
                if((string)column.Attributes["columnRole"]=="EXTERNAL_METADATA") port.External.Add(projection); else port.Columns.Add(projection);
            }
            return port;
        }
        private static Column ReadColumn(Toolbelt.Ssis.Exchange.PackageDocument.Definition definition, ref int count)
        {
            Budget.Limit(++count,8192); string type=(string)definition.Attributes["typeCode"]??"";
            int length=definition.Nonnegative("length"),precision=definition.Nonnegative("precision");
            return new Column {Id=definition.Get("refId"),Lineage=definition.Get("lineageId"),Name=definition.Name,Type=type,
                SqlType=Types.Sql(type,length==0?definition.Nonnegative("cachedLength"):length,precision==0?definition.Nonnegative("cachedPrecision"):precision,definition.Get("scale")==""?definition.Nonnegative("cachedScale"):definition.Nonnegative("scale")),
                External=definition.Get("externalMetadataColumnId"),CodePage=definition.Nonnegative("codePage")==0?definition.Nonnegative("cachedCodePage"):definition.Nonnegative("codePage"),Properties=definition.Properties};
        }
    }
}
