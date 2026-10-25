using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Xml;
using System.Xml.Linq;

namespace Toolbelt.Ssis.Exchange
{
    /// <summary>Neutraler DTSX-Kern für Generator und externen Host; keine SQL-, Datei- oder Netzwerkzugriffe.</summary>
    public sealed class ModelException : Exception
    {
        public string Code { get; private set; }
        internal ModelException(string code) : base("TBX_SSISMODEL_" + code) { Code = code; }
    }

    public sealed partial class PackageDocument
    {
        internal static readonly XNamespace Dts = "www.microsoft.com/SqlServer/Dts";
        internal XElement Root { get; private set; }
        public string PackageSha256 { get; private set; }
        public int ByteLength { get; private set; }
        public string XmlProfile { get; private set; }
        private readonly Stopwatch watch = Stopwatch.StartNew();
        private readonly Action callerCheck;
        private PackageDocument(Action check) { callerCheck = check; }
        private void Check() { if (watch.ElapsedMilliseconds > 30000) throw new ModelException("LIMIT_EXCEEDED"); if (callerCheck != null) callerCheck(); }
        private static void Limit(long value, long limit) { if (value > limit) throw new ModelException("LIMIT_EXCEEDED"); }
        internal static string Attribute(XElement e, string key) { return (string)e.Attribute(key) ?? (string)e.Attribute(Dts + key) ?? ""; }
        private static object Text(string value) { return value == "" ? null : (object)value; }
        private static object Number(string value) { int n; return Int32.TryParse(value, NumberStyles.AllowLeadingSign, CultureInfo.InvariantCulture, out n) ? (object)n : null; }
        private static object Flag(string value)
        {
            if (value == "1" || value == "-1" || String.Equals(value, "true", StringComparison.OrdinalIgnoreCase)) return true;
            if (value == "0" || String.Equals(value, "false", StringComparison.OrdinalIgnoreCase)) return false;
            return null;
        }
        private static Dictionary<string, object> Obj(params object[] items)
        { var result = new Dictionary<string, object>(StringComparer.Ordinal); for (int i = 0; i < items.Length; i += 2) result.Add((string)items[i], items[i + 1]); return result; }

        public static PackageDocument Read(byte[] input, Action check = null)
        {
            if (input == null || input.Length == 0) throw new ModelException("UNSUPPORTED_PACKAGE_FORMAT");
            Limit(input.LongLength, 16777216);
            // Hash und XML beruhen auf demselben privaten Snapshot, auch bei veränderlichem Callerbuffer.
            byte[] bytes = (byte[])input.Clone(); var result = new PackageDocument(check);
            if (bytes.Length >= 4 && ((bytes[0] == 0 && bytes[1] == 0) || (bytes[2] == 0 && bytes[3] == 0))) throw new ModelException("UNSUPPORTED_PACKAGE_FORMAT");
            var settings = new XmlReaderSettings { DtdProcessing = DtdProcessing.Prohibit, XmlResolver = null, MaxCharactersInDocument = 16777216, MaxCharactersFromEntities = 0 };
            try
            {
                using (var stream = new MemoryStream(bytes)) using (var reader = XmlReader.Create(stream, settings))
                {
                    int nodes = 0;
                    while (reader.Read())
                    {
                        result.Check(); Limit(reader.Depth, 128); Limit(++nodes, 262144);
                        if (reader.NamespaceURI == "http://www.w3.org/2001/XInclude") throw new ModelException("UNSUPPORTED_PACKAGE_FORMAT");
                        if (reader.NodeType == XmlNodeType.XmlDeclaration)
                        {
                            string encoding = reader.GetAttribute("encoding");
                            if (encoding != null && !new[] { "utf-8", "utf-16", "utf-16le", "utf-16be" }.Contains(encoding.ToLowerInvariant())) throw new ModelException("UNSUPPORTED_PACKAGE_FORMAT");
                        }
                    }
                }
                using (var stream = new MemoryStream(bytes)) using (var reader = XmlReader.Create(stream, settings)) result.Root = XDocument.Load(reader, LoadOptions.None).Root;
            }
            catch (XmlException) { throw new ModelException("UNSUPPORTED_PACKAGE_FORMAT"); }
            if (result.Root == null || result.Root.Name != Dts + "Executable") throw new ModelException("UNSUPPORTED_PACKAGE_FORMAT");
            using (var hash = SHA256.Create()) result.PackageSha256 = BitConverter.ToString(hash.ComputeHash(bytes)).Replace("-", "").ToLowerInvariant();
            result.ByteLength = bytes.Length;
            var formats = result.Root.Elements(Dts + "Property").Where(x => Attribute(x, "Name") == "PackageFormatVersion").Select(x => x.Value).ToList();
            string format = formats.Count == 1 ? formats[0] : null;
            result.XmlProfile = format == "6" ? "2012/01" : format == "8" ? "2014/01" : "UNKNOWN";
            return result;
        }

        internal sealed class Definition
        {
            internal XElement Element; internal string Id, Kind, Parent, Name, LegacyScope, NativeDtsId, NativePackagePath; internal int Order;
            internal Dictionary<string, object> Attributes;
            internal Dictionary<string, string> Native, Properties;
            internal string ValueText, VariableDataType, ComponentKind;
            internal bool HasDefault, HasPropertyExpressions, HasPipeline, IsPipeline;
            internal string Get(string key) { string value; return Native.TryGetValue(key, out value) ? value : ""; }
            internal int Nonnegative(string key)
            {
                string text = Get(key); int value;
                if (text == "") return 0;
                if (!Int32.TryParse(text, NumberStyles.Integer, CultureInfo.InvariantCulture, out value) || value < 0) throw new ModelException("INVALID_METADATA");
                return value;
            }
        }
        internal sealed class Link
        {
            internal string Kind, Scope, From, To, Resolution, Rule, Mapping; internal int Order;
            internal object Export(int ordinal) { return Obj("id", "edge" + ordinal, "kind", Kind, "scopeId", Scope, "fromId", From, "toId", To, "resolution", Resolution, "evidence", Rule == null ? "DECLARED" : "DERIVED", "ruleId", Rule, "mappingRole", Mapping); }
        }
        private static string Classify(XElement e, XElement root)
        {
            if (e == root) return "PACKAGE";
            if (e.Name == Dts + "Executable" || e.Name == Dts + "EventHandler") return "EXECUTABLE";
            if (e.Name == Dts + "Variable" && e.Parent.Name == Dts + "Variables") return "VARIABLE";
            if (e.Name == Dts + "PackageParameter" && e.Parent.Name == Dts + "PackageParameters" && e.Parent.Parent == root) return "PARAMETER";
            if (e.Name == Dts + "ConnectionManager" && e.Parent.Name == Dts + "ConnectionManagers") return "CONNECTION";
            if (e.Name == Dts + "PropertyExpression") return "EXPRESSION";
            if (e.Name.Namespace != XNamespace.None) return null;
            if (e.Name.LocalName == "component" && e.Parent.Name == "components" && e.Parent.Parent.Name == "pipeline" && e.Parent.Parent.Parent.Name == Dts + "ObjectData") return "COMPONENT";
            if ((e.Name == "input" && e.Parent.Name == "inputs" || e.Name == "output" && e.Parent.Name == "outputs") && e.Parent.Parent.Name == "component") return "PORT";
            if ((e.Name == "inputColumn" && e.Parent.Name == "inputColumns" || e.Name == "outputColumn" && e.Parent.Name == "outputColumns" || e.Name == "externalMetadataColumn" && e.Parent.Name == "externalMetadataColumns") && (e.Parent.Parent.Name == "input" || e.Parent.Parent.Name == "output")) return "COLUMN";
            if (e.Name == "property" && Attribute(e, "name") == "Expression" && e.Ancestors().Any(x => x.Name == "component")) return "EXPRESSION";
            return null;
        }
        private static readonly Dictionary<string, string> Prefixes = new Dictionary<string, string> { {"PACKAGE","pkg"}, {"EXECUTABLE","exe"}, {"COMPONENT","cmp"}, {"PORT","port"}, {"COLUMN","col"}, {"VARIABLE","var"}, {"PARAMETER","par"}, {"CONNECTION","con"}, {"EXPRESSION","expr"} };

        private List<Definition> definitions;
        private List<Link> relationships;
        private List<object> modelCoverage, modelDiagnostics;
        private readonly HashSet<string> incompletePipelines = new HashSet<string>(StringComparer.Ordinal);
        internal ICollection<string> IncompletePipelineScopes { get { Build(); return incompletePipelines; } }
        internal bool HasDuplicateNativeIds { get; private set; }
        internal bool HasOverlongNativeIds { get; private set; }
        internal IList<Definition> Definitions { get { Build(); return definitions.AsReadOnly(); } }
        internal IList<Link> Relationships { get { Build(); return relationships.AsReadOnly(); } }
        private void Build()
        {
            if (definitions != null) return;
            var items = new List<Definition>(); var byElement = new Dictionary<XElement, Definition>(); var counts = new Dictionary<string, int>();
            int order = 0;
            foreach (var element in Root.DescendantsAndSelf())
            {
                Check(); string kind = Classify(element, Root); ++order; if (kind == null) continue;
                int count; counts.TryGetValue(kind, out count); counts[kind] = ++count;
                var item = new Definition { Element = element, Kind = kind, Id = Prefixes[kind] + count.ToString(CultureInfo.InvariantCulture), Order = order };
                var parent = element.Ancestors().FirstOrDefault(byElement.ContainsKey); item.Parent = parent == null ? null : byElement[parent].Id;
                item.Name = Attribute(element,"ObjectName"); if (item.Name == "") item.Name = Attribute(element,"name");
                if (item.Name == "" && kind == "COLUMN") item.Name = Attribute(element,"cachedName");
                var legacyOwner = element.Ancestors(Dts + "Executable").FirstOrDefault();
                item.LegacyScope = legacyOwner == null ? "Package" : Attribute(legacyOwner,"refId");
                item.Native = new Dictionary<string,string>(StringComparer.Ordinal);
                item.NativeDtsId = (string)element.Attribute(Dts + "DTSID");
                string nativeReference = (string)element.Attribute(Dts + "refId");
                item.NativePackagePath = nativeReference != null && nativeReference.Length < 4000 &&
                    (nativeReference == "Package" || nativeReference.StartsWith("Package\\", StringComparison.Ordinal)) ? "\\" + nativeReference : null;
                foreach (var attribute in element.Attributes().Where(x => x.Name.Namespace == XNamespace.None).Concat(element.Attributes().Where(x => x.Name.Namespace == Dts)))
                    if (!item.Native.ContainsKey(attribute.Name.LocalName)) item.Native.Add(attribute.Name.LocalName, attribute.Value);
                item.Properties = new Dictionary<string,string>(StringComparer.Ordinal);
                foreach (var property in element.Elements("properties").Elements("property"))
                {
                    string key = Attribute(property, "name");
                    if (item.Properties.ContainsKey(key)) throw new ModelException("INVALID_METADATA");
                    item.Properties.Add(key, property.Value);
                }
                var connections=element.Elements("connections").Elements("connection").ToList();
                if(connections.Count==1) item.Native.Add("@singleConnection",Attribute(connections[0],"connectionManagerRefId"));
                item.HasPropertyExpressions = element.Descendants(Dts + "PropertyExpression").Any();
                if (kind == "VARIABLE")
                {
                    var value = element.Element(Dts + "VariableValue"); item.HasDefault = value != null;
                    item.ValueText = value == null ? null : value.Value; item.VariableDataType = value == null ? "" : Attribute(value, "DataType");
                }
                if (kind == "PARAMETER")
                {
                    var value = element.Elements(Dts + "Property").FirstOrDefault(x => Attribute(x, "Name") == "ParameterValue");
                    item.HasDefault = value != null; item.ValueText = value == null ? null : value.Value;
                }
                item.IsPipeline = new[] { "SSIS.Pipeline", "SSIS.Pipeline.3", "STOCK:SSIS.Pipeline", "Microsoft.Pipeline" }.Contains(item.Get("ExecutableType"));
                item.HasPipeline = element.Element(Dts + "ObjectData") != null && element.Element(Dts + "ObjectData").Element("pipeline") != null;
                items.Add(item); byElement.Add(element, item); Limit(items.Count, 20000);
            }
            var lookup = items.ToDictionary(x => x.Id, StringComparer.Ordinal);
            foreach (var item in items.Where(x => x.Kind != "PACKAGE"))
            {
                Definition parent;
                if (item.Parent == null || !lookup.TryGetValue(item.Parent,out parent) || !(
                    item.Kind == "EXECUTABLE" && (parent.Kind == "PACKAGE" || parent.Kind == "EXECUTABLE") ||
                    item.Kind == "COMPONENT" && parent.Kind == "EXECUTABLE" || item.Kind == "PORT" && parent.Kind == "COMPONENT" ||
                    item.Kind == "COLUMN" && parent.Kind == "PORT" || item.Kind == "VARIABLE" && (parent.Kind == "PACKAGE" || parent.Kind == "EXECUTABLE") ||
                    (item.Kind == "PARAMETER" || item.Kind == "CONNECTION") && parent.Kind == "PACKAGE" ||
                    item.Kind == "EXPRESSION" && parent.Kind != "PARAMETER")) throw new ModelException("INVALID_METADATA");
            }
            Func<Definition, string> scope = item => { Definition current = item; while (current.Kind != "EXECUTABLE" && current.Kind != "PACKAGE") current = lookup[current.Parent]; return current.Id; };
            Func<string, string, string, Definition> resolve = (reference, kind, owner) =>
            {
                if (reference == "") return null;
                var found = items.Where(x => x.Kind == kind && scope(x) == owner && Attribute(x.Element, "refId") == reference).Take(2).ToList();
                return found.Count == 1 ? found[0] : null;
            };
            var diagnostics = new List<object>(); bool unknown = false, expressions = Root.DescendantsAndSelf().Any(x => x.Attributes().Any(a => a.Name.LocalName == "Expression")), encrypted = Root.Descendants().Any(x => x.Name.Namespace == Dts && x.Name.LocalName.IndexOf("Encrypted", StringComparison.OrdinalIgnoreCase) >= 0);
            foreach (var item in items)
            {
                Check(); XElement e = item.Element; Func<string, string> a = key => Attribute(e, key);
                switch (item.Kind)
                {
                    case "PACKAGE": item.Attributes = Obj("protectionLevel", Text(a("ProtectionLevel"))); break;
                    case "EXECUTABLE": item.Attributes = Obj("executableType", Text(a("ExecutableType")), "isDisabled", Flag(a("Disabled")), "isEventHandler", e.Name == Dts + "EventHandler"); break;
                    case "COMPONENT":
                        item.Attributes = Obj("componentClassId", Text(a("componentClassID")));
                        int version; Int32.TryParse(a("version"), out version);
                        item.ComponentKind = ComponentProfiles.Kind(a("componentClassID"), version, item.Properties);
                        if (item.ComponentKind == "unsupported") { unknown = true; diagnostics.Add(Obj("code", "UNKNOWN_COMPONENT", "objectId", item.Id)); }
                        break;
                    case "PORT":
                        string sync = a("synchronousInputId"); var syncDefinitions = sync == "" || sync == "0" ? new List<Definition>() : items.Where(x => x.Kind == "PORT" && x.Parent == item.Parent && Attribute(x.Element, "refId") == sync).Take(2).ToList(); Definition syncDefinition = syncDefinitions.Count == 1 ? syncDefinitions[0] : null;
                        item.Attributes = Obj("direction", e.Name == "input" ? "INPUT" : "OUTPUT", "portRole", Flag(a("isErrorOut")) as bool? == true ? "ERROR" : "UNKNOWN", "synchronousInputPortId", syncDefinition == null ? null : syncDefinition.Id); break;
                    case "COLUMN":
                        Func<string, string, object> number = (key, cached) => Number(a(key) == "" ? a(cached) : a(key));
                        item.Attributes = Obj("columnRole", e.Name == "externalMetadataColumn" ? "EXTERNAL_METADATA" : "DATA", "typeCode", Text(a("dataType") == "" ? a("cachedDataType") : a("dataType")), "length", number("length", "cachedLength"), "precision", number("precision", "cachedPrecision"), "scale", number("scale", "cachedScale"), "codePage", number("codePage", "cachedCodePage"), "isNullable", Flag(a("isNullable"))); break;
                    case "VARIABLE":
                        XElement value = e.Element(Dts + "VariableValue");
                        item.Attributes = Obj("namespace", Text(a("Namespace")), "typeCode", value == null ? null : Text(Attribute(value, "DataType")), "isReadOnly", Flag(a("ReadOnly")), "evaluateAsExpression", Flag(a("EvaluateAsExpression")));
                        if (Flag(a("EvaluateAsExpression")) as bool? == true) expressions = true;
                        break;
                    case "PARAMETER": item.Attributes = Obj("typeCode", Text(a("DataType"))); break;
                    case "CONNECTION": item.Attributes = Obj("connectionKind", Text(a("CreationName"))); break;
                    default: item.Attributes = Obj("propertyName", Text(a("Name") == "" ? a("name") : a("Name"))); expressions = true; break;
                }
                Limit(item.Name.Length, 256);
                foreach (var attribute in item.Attributes)
                {
                    string text = attribute.Value as string;
                    if (text != null) Limit(text.Length, attribute.Key == "typeCode" || attribute.Key == "protectionLevel" ? 64 : attribute.Key == "connectionKind" ? 128 : 256);
                    if (attribute.Value is int)
                    {
                        int n = (int)attribute.Value;
                        if (n < (attribute.Key == "length" ? -1 : 0) || (attribute.Key == "precision" || attribute.Key == "scale") && n > 255) throw new ModelException("INVALID_METADATA");
                    }
                }
            }
            var links = new List<Link>(); bool partial = false;
            Action<string, Definition, Definition, string, int, string> link = (kind, from, to, owner, declarationPosition, mapping) =>
            {
                if (kind == "PIPELINE_PATH")
                {
                    if (from != null && (string)from.Attributes["direction"] != "OUTPUT") from = null;
                    if (to != null && (string)to.Attributes["direction"] != "INPUT") to = null;
                    if (from == null || to == null) incompletePipelines.Add(owner);
                }
                if (from == null && to == null) { partial = true; return; }
                bool complete = from != null && to != null; partial |= !complete;
                links.Add(new Link { Kind = kind, From = from == null ? null : from.Id, To = to == null ? null : to.Id, Scope = owner, Order = declarationPosition, Resolution = complete ? "RESOLVED" : "UNRESOLVED", Mapping = mapping });
                Limit(links.Count, 50000);
            };
            int position = 0;
            foreach (var e in Root.DescendantsAndSelf())
            {
                Check(); ++position;
                if (e.Name == "path" && e.Parent.Name == "paths" && e.Parent.Parent.Name == "pipeline")
                {
                    Definition owner = byElement[e.Ancestors().First(x => byElement.ContainsKey(x) && byElement[x].Kind == "EXECUTABLE")];
                    link("PIPELINE_PATH", resolve(Attribute(e, "startId"), "PORT", owner.Id), resolve(Attribute(e, "endId"), "PORT", owner.Id), owner.Id, position, null);
                }
                if (e.Name == Dts + "PrecedenceConstraint")
                {
                    var parent = e.Ancestors().First(x => byElement.ContainsKey(x) && (byElement[x].Kind == "PACKAGE" || byElement[x].Kind == "EXECUTABLE")); Definition owner = byElement[parent];
                    Func<string, Definition> endpoint = reference => { var found = items.Where(x => x.Kind == "EXECUTABLE" && x.Parent == owner.Id && Attribute(x.Element, "refId") == reference).Take(2).ToList(); return found.Count == 1 ? found[0] : null; };
                    link("CONTROL_FLOW", endpoint(Attribute(e, "From")), endpoint(Attribute(e, "To")), owner.Id, position, null);
                }
                Definition column;
                if (!byElement.TryGetValue(e, out column) || column.Kind != "COLUMN" || e.Name == "externalMetadataColumn") continue;
                string externalId = Attribute(e, "externalMetadataColumnId");
                if (externalId != "" && externalId != "0")
                {
                    var external = items.Where(x => x.Kind == "COLUMN" && x.Parent == column.Parent && x.Element.Name == "externalMetadataColumn" && Attribute(x.Element, "refId") == externalId).Take(2).ToList();
                    link("COLUMN_MAP", column, external.Count == 1 ? external[0] : null, scope(column), position, "METADATA_REFERENCE");
                }
                if (e.Name != "inputColumn") continue;
                Definition port = lookup[column.Parent]; string flow = scope(column), lineage = Attribute(e, "lineageId");
                var incoming = Root.Descendants("path").Where(x => Attribute(x, "endId") == Attribute(port.Element, "refId") && x.Ancestors().Contains(lookup[flow].Element)).ToList();
                Definition sourcePort = incoming.Count == 1 ? resolve(Attribute(incoming[0], "startId"), "PORT", flow) : null;
                var candidates = items.Where(x => x.Kind == "COLUMN" && sourcePort != null && x.Parent == sourcePort.Id && x.Element.Name == "outputColumn" && lineage != "" && (Attribute(x.Element, "lineageId") == lineage || Attribute(x.Element, "refId") == lineage)).Take(2).ToList();
                link("COLUMN_MAP", candidates.Count == 1 ? candidates[0] : null, column, flow, position, "DATA_TRANSFER");
            }
            foreach (var declared in links.Where(x => x.Kind == "COLUMN_MAP" && x.Mapping == "DATA_TRANSFER" && x.Resolution == "RESOLVED").ToList())
                links.Add(new Link { Kind = "VALUE_DEPENDENCY", From = declared.From, To = declared.To, Scope = declared.Scope, Resolution = "RESOLVED", Rule = "MAPPED_VALUE_INPUT" });
            Limit(links.Count, 50000); Limit(diagnostics.Count, 1000);
            bool complex = items.Where(x => x.Kind == "COMPONENT").Any(x => { string c = Attribute(x.Element, "componentClassID"); return !(c == "Microsoft.OLEDBSource" || c == "Microsoft.OLEDBDestination"); });
            if (encrypted) diagnostics.Add(Obj("code", "ENCRYPTED_CONTENT", "objectId", "pkg1"));
            if (partial) diagnostics.Add(Obj("code", "PARTIAL_LINEAGE", "objectId", null));
            if (expressions) diagnostics.Add(Obj("code", "EXPRESSION_UNRESOLVED", "objectId", null));
            Limit(diagnostics.Count, 1000);
            var coverage = new List<object>();
            foreach (string feature in new[] { "inventory", "controlFlow", "pipelineGraph", "columnMetadata", "directColumnMapping", "valueLineage", "rowLineage", "expressionReferences" })
            {
                bool limited = encrypted || ((feature == "pipelineGraph" || feature == "controlFlow" || feature == "directColumnMapping") && partial) || (feature == "columnMetadata" && items.Where(x => x.Kind == "COLUMN").Any(x => x.Attributes["typeCode"] == null || x.Attributes["isNullable"] == null)) || (feature == "valueLineage" && (partial || complex || unknown || expressions)) || (feature == "rowLineage" && (complex || unknown)) || (feature == "expressionReferences" && expressions);
                coverage.Add(Obj("feature", feature, "status", limited ? "PARTIAL" : "COMPLETE", "reasonCode", limited ? encrypted ? "ENCRYPTED_CONTENT" : unknown ? "UNKNOWN_COMPONENT" : expressions ? "EXPRESSION_UNRESOLVED" : "PROFILE_LIMIT" : null));
            }
            var ordered = links.Where(x => x.Rule == null).OrderBy(x => x.Order).ThenBy(x => x.Kind, StringComparer.Ordinal).Concat(links.Where(x => x.Rule != null).OrderBy(x => x.Kind, StringComparer.Ordinal).ThenBy(x => x.Scope, StringComparer.Ordinal).ThenBy(x => x.From, StringComparer.Ordinal).ThenBy(x => x.To, StringComparer.Ordinal).ThenBy(x => x.Rule, StringComparer.Ordinal)).ToList();
            definitions = items; relationships = ordered; modelCoverage = coverage; modelDiagnostics = diagnostics;
            var references = Root.DescendantsAndSelf().Where(x => x.Name.Namespace == Dts || x.Name.Namespace == XNamespace.None).Select(x => Attribute(x,"refId")).Where(x => x != "").ToList();
            HasDuplicateNativeIds = references.Distinct(StringComparer.Ordinal).Count() != references.Count;
            HasOverlongNativeIds = references.Any(x => x.Length > 4000);
        }

        /// <summary>Rendert das einmal materialisierte neutrale Modell; keine erneute XML-Auswertung.</summary>
        public Dictionary<string, object> Export(string producerVersion, string sourceCommit, string buildSha256)
        {
            if (!IsHex(sourceCommit,40) || !IsHex(buildSha256,64) || producerVersion != "1.0.0") throw new ModelException("INVALID_PRODUCER_IDENTITY");
            if (XmlProfile == "UNKNOWN") throw new ModelException("UNSUPPORTED_PACKAGE_FORMAT");
            Build(); Check();
            var formatValue = Root.Elements(Dts + "Property").Single(x => Attribute(x, "Name") == "PackageFormatVersion").Value;
            return Obj("contract", "ssis-package-model", "version", "1.0.0", "identityProfile", "document-order-v1",
                "producer", Obj("id", "toolbelt.ssis-model", "version", producerVersion, "sourceCommit", sourceCommit, "buildSha256", buildSha256),
                "source", Obj("kind", "DTSX_BYTES", "packageSha256", PackageSha256, "byteLength", ByteLength, "packageFormatVersion", Number(formatValue), "xmlProfile", XmlProfile),
                "profiles", Obj("format", "1.0.0", "components", "1.0.0", "lineage", "1.0.0"), "coverage", modelCoverage,
                "nodes", definitions.Select(x => (object)Obj("id", x.Id, "kind", x.Kind, "parentId", x.Parent, "name", Text(x.Name), "attributes", x.Attributes)).ToList(),
                "edges", relationships.Select((x, n) => x.Export(n + 1)).ToList(), "diagnostics", modelDiagnostics);
        }
        /// <summary>Native Paket-/Executablekennungen aus denselben Definitionen; keine Namensauflösung oder Laufzeitbehauptung.</summary>
        public Dictionary<string, object> ExportObjectIdentities()
        {
            return ExportObjectIdentities(false);
        }
        public Dictionary<string, object> ExportObjectIdentities(bool includeIterationRoles)
        {
            if (XmlProfile == "UNKNOWN") throw new ModelException("UNSUPPORTED_PACKAGE_FORMAT");
            Build(); Check();
            var objects = new List<object>();
            foreach (var definition in definitions.Where(x => x.Kind == "PACKAGE" || x.Kind == "EXECUTABLE"))
            {
                Check(); Guid id;
                // Ungültige oder fehlende DTSIDs bleiben ungebunden; doppelte GUIDs bleiben getrennte Vorkommen.
                object nativeId = Guid.TryParse(definition.NativeDtsId, out id) ? (object)id.ToString("D").ToLowerInvariant() : null;
                var identity = Obj("nodeId", definition.Id, "nodeKind", definition.Kind, "dtsId", nativeId, "packagePath", definition.NativePackagePath);
                if (includeIterationRoles)
                {
                    object executableType, eventHandler;
                    identity["iterationContainer"] = definition.Kind == "EXECUTABLE" &&
                        definition.Attributes.TryGetValue("isEventHandler", out eventHandler) && Object.Equals(eventHandler, false) &&
                        definition.Attributes.TryGetValue("executableType", out executableType) && ComponentProfiles.IsIterationContainer(executableType as string);
                }
                objects.Add(identity);
            }
            return Obj("contract", "ssis-object-identities", "version", includeIterationRoles ? "1.1.0" : "1.0.0", "identityProfile", "document-order-v1",
                "packageSha256", PackageSha256, "objects", objects);
        }
        private static bool IsHex(string value, int length) { return value != null && value.Length == length && value.All(c => c >= '0' && c <= '9' || c >= 'a' && c <= 'f'); }
    }
}
