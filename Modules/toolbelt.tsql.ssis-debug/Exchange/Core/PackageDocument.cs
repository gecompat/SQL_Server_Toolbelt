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
        public bool ComponentsV2 { get; private set; }
        internal ResourceLimits Limits { get; private set; }
        private readonly Stopwatch watch = Stopwatch.StartNew();
        private readonly Action callerCheck;
        private PackageDocument(Action check) { callerCheck = check; }
        private void Check() { Limits.Check("analysisMilliseconds", watch.ElapsedMilliseconds); if (callerCheck != null) callerCheck(); }
        private static void Limit(long value, long limit) { if (value > limit) throw new ModelException("LIMIT_EXCEEDED"); }
        internal static string Attribute(XElement e, string key) { return (string)e.Attribute(key) ?? (string)e.Attribute(Dts + key) ?? ""; }
        private static string LocalAttribute(XElement e, string key)
        { var attribute = e.Attributes().FirstOrDefault(x => String.Equals(x.Name.LocalName, key, StringComparison.OrdinalIgnoreCase)); return attribute == null ? "" : attribute.Value; }
        private static bool HasLocalAttribute(XElement e, string key)
        { return e.Attributes().Any(x => String.Equals(x.Name.LocalName, key, StringComparison.OrdinalIgnoreCase)); }
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

        public static PackageDocument Read(byte[] input, Action check = null, bool componentsV2 = false, ResourceLimits limits = null)
        {
            if (input == null || input.Length == 0) throw new ModelException("UNSUPPORTED_PACKAGE_FORMAT");
            limits = limits ?? (componentsV2 ? ResourceLimits.Create("large10x", true) : ResourceLimits.Legacy); limits.Check("packageBytes", input.LongLength);
            // Hash und XML beruhen auf demselben privaten Snapshot, auch bei veränderlichem Callerbuffer.
            byte[] bytes = (byte[])input.Clone(); var result = new PackageDocument(check); result.ComponentsV2 = componentsV2; result.Limits = limits;
            if (bytes.Length >= 4 && ((bytes[0] == 0 && bytes[1] == 0) || (bytes[2] == 0 && bytes[3] == 0))) throw new ModelException("UNSUPPORTED_PACKAGE_FORMAT");
            bool xmlCharacterLimitUnlimited = limits.IsUnlimitedCounter("xmlCharacters");
            var settings = new XmlReaderSettings { DtdProcessing = DtdProcessing.Prohibit, XmlResolver = null, MaxCharactersInDocument = xmlCharacterLimitUnlimited ? 0 : limits.Maximum("xmlCharacters"), MaxCharactersFromEntities = 0 };
            try
            {
                using (var stream = new MemoryStream(bytes)) using (var reader = XmlReader.Create(stream, settings))
                {
                    int nodes = 0;
                    while (reader.Read())
                    {
                        result.Check(); Limit(reader.Depth, 128); limits.Check("xmlNodes", ++nodes);
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
            catch (XmlException)
            {
                // MaxCharactersInDocument reports its limit as XmlException. Reparse
                // only this failure with the same safe streaming settings and no
                // character cap: valid XML proves the first parse hit its policy,
                // while malformed XML and prohibited DTDs keep the format failure.
                if (limits.IsV2 && !xmlCharacterLimitUnlimited)
                {
                    try
                    {
                        var verify = new XmlReaderSettings { DtdProcessing = DtdProcessing.Prohibit, XmlResolver = null, MaxCharactersInDocument = 0, MaxCharactersFromEntities = 0 };
                        using (var stream = new MemoryStream(bytes)) using (var reader = XmlReader.Create(stream, verify))
                        {
                            int nodes = 0;
                            while (reader.Read())
                            {
                                result.Check(); Limit(reader.Depth, 128); limits.Check("xmlNodes", ++nodes);
                                if (reader.NamespaceURI == "http://www.w3.org/2001/XInclude") throw new ModelException("UNSUPPORTED_PACKAGE_FORMAT");
                            }
                        }
                        long maximum = limits.Maximum("xmlCharacters");
                        if (maximum < Int64.MaxValue) throw new ResourceLimitException("xmlCharacters", maximum + 1, maximum, limits.Preset, true);
                    }
                    catch (ResourceLimitException) { throw; }
                    catch (ModelException) { throw; }
                    catch (XmlException) { }
                }
                throw new ModelException("UNSUPPORTED_PACKAGE_FORMAT");
            }
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
            internal string ValueText, VariableDataType, ComponentKind, ComponentVersionRaw, ComponentVersionOrigin;
            internal bool ComponentVersionPresent;
            internal int ComponentVersion;
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
            internal string Kind, Scope, From, To, Resolution, Rule, Mapping, NativeReference, NativeName; internal int Order;
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
            int order = 0, inputCount = 0;
            var propertyExpressionOwners = new HashSet<XElement>();
            foreach (var expressionElement in Root.Descendants(Dts + "PropertyExpression"))
                foreach (var ancestor in expressionElement.Ancestors()) propertyExpressionOwners.Add(ancestor);
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
                item.HasPropertyExpressions = propertyExpressionOwners.Contains(element);
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
                items.Add(item); byElement.Add(element, item); Limits.Check("modelNodes", items.Count);
                if (kind == "COMPONENT") Limits.Check("components", counts[kind]);
                if (kind == "COLUMN") Limits.Check("columns", counts[kind]);
                if (kind == "VARIABLE" || kind == "PARAMETER") Limits.Check("inputs", ++inputCount);
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
            var scopes = new Dictionary<string, string>(StringComparer.Ordinal);
            foreach (var item in items)
            {
                Definition current = item;
                while (current.Kind != "EXECUTABLE" && current.Kind != "PACKAGE") current = lookup[current.Parent];
                scopes.Add(item.Id, current.Id);
            }
            Func<Definition, string> scope = item => scopes[item.Id];
            // Resolve native references through one bounded index. The old per-reference
            // scan made a large but otherwise valid pipeline quadratic in component count.
            var referenceIndex = new Dictionary<string, List<Definition>>(StringComparer.Ordinal);
            foreach (var item in items)
            {
                string reference = Attribute(item.Element, "refId"); if (reference == "") continue;
                string key = item.Kind + "\0" + scope(item) + "\0" + reference;
                List<Definition> found; if (!referenceIndex.TryGetValue(key, out found)) referenceIndex.Add(key, found = new List<Definition>(2));
                if (found.Count < 2) found.Add(item);
            }
            Func<string, string, string, Definition> resolve = (reference, kind, owner) =>
            {
                if (reference == "") return null;
                List<Definition> found; return referenceIndex.TryGetValue(kind + "\0" + owner + "\0" + reference, out found) && found.Count == 1 ? found[0] : null;
            };
            var executablesByParentAndReference = new Dictionary<string, List<Definition>>(StringComparer.Ordinal);
            foreach (var item in items.Where(x => x.Kind == "EXECUTABLE"))
            {
                string key = item.Parent + "\0" + Attribute(item.Element, "refId");
                List<Definition> found; if (!executablesByParentAndReference.TryGetValue(key, out found)) executablesByParentAndReference.Add(key, found = new List<Definition>(2));
                if (found.Count < 2) found.Add(item);
            }
            var pathsByFlowAndEnd = new Dictionary<string, List<XElement>>(StringComparer.Ordinal);
            foreach (var path in Root.Descendants("path").Where(x => x.Parent.Name == "paths" && x.Parent.Parent.Name == "pipeline"))
            {
                var flowElement = path.Ancestors().FirstOrDefault(x => byElement.ContainsKey(x) && byElement[x].Kind == "EXECUTABLE");
                if (flowElement == null) continue;
                string key = byElement[flowElement].Id + "\0" + Attribute(path, "endId");
                List<XElement> found; if (!pathsByFlowAndEnd.TryGetValue(key, out found)) pathsByFlowAndEnd.Add(key, found = new List<XElement>(2));
                if (found.Count < 2) found.Add(path);
            }
            var columnsByParentAndIdentity = new Dictionary<string, List<Definition>>(StringComparer.Ordinal);
            foreach (var item in items.Where(x => x.Kind == "COLUMN" && x.Element.Name == "outputColumn"))
                foreach (string identity in new[] { Attribute(item.Element, "lineageId"), Attribute(item.Element, "refId") }.Where(x => x != "").Distinct(StringComparer.Ordinal))
                {
                    string key = item.Parent + "\0" + identity;
                    List<Definition> found; if (!columnsByParentAndIdentity.TryGetValue(key, out found)) columnsByParentAndIdentity.Add(key, found = new List<Definition>(2));
                    if (found.Count < 2) found.Add(item);
                }
            var externalColumnsByParentRef = new Dictionary<string, List<Definition>>(StringComparer.Ordinal);
            foreach (var item in items.Where(x => x.Kind == "COLUMN" && x.Element.Name == "externalMetadataColumn"))
            {
                string key = item.Parent + "\0" + Attribute(item.Element, "refId");
                List<Definition> found; if (!externalColumnsByParentRef.TryGetValue(key, out found)) externalColumnsByParentRef.Add(key, found = new List<Definition>(2));
                if (found.Count < 2) found.Add(item);
            }
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
                        string rawVersion = a("version");
                        bool unqualifiedVersion = e.Attribute("version") != null, namespacedVersion = e.Attribute(Dts + "version") != null;
                        if (ComponentsV2 && unqualifiedVersion && namespacedVersion) throw new ModelException("INVALID_METADATA");
                        item.ComponentVersionPresent = unqualifiedVersion || namespacedVersion;
                        item.ComponentVersionRaw = item.ComponentVersionPresent ? rawVersion : null;
                        item.ComponentVersionOrigin = item.ComponentVersionPresent ? "explicit" : "schema-default-0";
                        if (ComponentsV2)
                        {
                            int version = 0;
                            if (item.ComponentVersionPresent && (rawVersion == "" || !Int32.TryParse(rawVersion, NumberStyles.AllowLeadingSign, CultureInfo.InvariantCulture, out version))) throw new ModelException("INVALID_METADATA");
                            if (!item.ComponentVersionPresent) version = 0;
                            if (version < 0) throw new ModelException("INVALID_METADATA");
                            item.ComponentVersion = version;
                            item.ComponentKind = ComponentProfiles.KindV2(a("componentClassID"), version, XmlProfile, item.Properties);
                            var inputElements = e.Element("inputs") == null ? new List<XElement>() : e.Element("inputs").Elements("input").ToList();
                            var outputElements = e.Element("outputs") == null ? new List<XElement>() : e.Element("outputs").Elements("output").ToList();
                            var outputProfiles = outputElements.Select(output => {
                                XAttribute errorUnqualified = output.Attribute("isErrorOut"), errorNamespaced = output.Attribute(Dts + "isErrorOut");
                                XAttribute syncUnqualified = output.Attribute("synchronousInputId"), syncNamespaced = output.Attribute(Dts + "synchronousInputId");
                                if (errorUnqualified != null && errorNamespaced != null || syncUnqualified != null && syncNamespaced != null) throw new ModelException("INVALID_METADATA");
                                XAttribute errorFlag = errorUnqualified ?? errorNamespaced;
                                return new ComponentProfiles.V2OutputPort {
                                    IsErrorOutput = Flag(Attribute(output, "isErrorOut")) as bool?,
                                    ErrorFlagPresent = errorFlag != null,
                                    SynchronousInputId = Attribute(output, "synchronousInputId")
                                };
                            }).ToList();
                            if (!ComponentProfiles.HasV2PortProfile(item.ComponentKind, inputElements.Count, inputElements.Select(input => Attribute(input, "refId")).ToList(), outputProfiles)) item.ComponentKind = "unsupported";
                            item.Attributes = Obj("componentClassId", Text(a("componentClassID")), "versionRaw", Text(rawVersion), "versionPresent", item.ComponentVersionPresent, "effectiveVersion", version, "versionOrigin", item.ComponentVersionOrigin);
                        }
                        else
                        {
                            int version; Int32.TryParse(rawVersion, out version);
                            item.ComponentVersion = version;
                            item.ComponentKind = ComponentProfiles.Kind(a("componentClassID"), version, item.Properties);
                        }
                        if (item.ComponentKind == "unsupported") { unknown = true; diagnostics.Add(Obj("code", "UNKNOWN_COMPONENT", "objectId", item.Id)); }
                        break;
                    case "PORT":
                        string sync = a("synchronousInputId"); List<Definition> syncDefinitions; referenceIndex.TryGetValue("PORT\0" + scopes[item.Id] + "\0" + sync, out syncDefinitions); Definition syncDefinition = sync == "" || sync == "0" || syncDefinitions == null || syncDefinitions.Count != 1 || syncDefinitions[0].Parent != item.Parent ? null : syncDefinitions[0];
                        Definition owner; if (!lookup.TryGetValue(item.Parent, out owner) || owner.Kind != "COMPONENT") owner = null;
                        object errorFlagValue = Flag(a("isErrorOut"));
                        string portRole = errorFlagValue as bool? == true ? "ERROR" : "UNKNOWN";
                        if (ComponentsV2 && e.Name == "output" && owner != null && (owner.ComponentKind == "derived" || owner.ComponentKind == "split" || owner.ComponentKind == "rowcount" || owner.ComponentKind == "flatfile-source" || owner.ComponentKind == "flatfile-destination") && errorFlagValue as bool? != true)
                            portRole = errorFlagValue as bool? == false || e.Attribute("isErrorOut") == null && e.Attribute(Dts + "isErrorOut") == null ? "NORMAL" : "UNKNOWN";
                        if (e.Name == "output" && portRole != "ERROR" && owner != null && owner.ComponentKind == "lookup")
                        {
                            var normal = owner.Element.Element("outputs").Elements("output").Where(x => Flag(Attribute(x,"isErrorOut")) as bool? != true).ToList();
                            string mode; owner.Properties.TryGetValue("NoMatchBehavior",out mode);
                            if (normal.Count == 2 && (mode == "0" || mode == "1") && ComponentProfiles.IsLookupNoMatchOutput(normal.IndexOf(e))) portRole = "NO_MATCH";
                        }
                        item.Attributes = Obj("direction", e.Name == "input" ? "INPUT" : "OUTPUT", "portRole", portRole, "synchronousInputPortId", syncDefinition == null ? null : syncDefinition.Id); break;
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
            long assignmentEdges = ResolveVariableAssignments(items);
            var links = new List<Link>(); bool partial = false; int pathCount = 0;
            Action<string, Definition, Definition, string, int, string> link = (kind, from, to, owner, declarationPosition, mapping) =>
            {
                if (kind == "PIPELINE_PATH")
                {
                    Limits.Check("paths", ++pathCount);
                    if (from != null && (string)from.Attributes["direction"] != "OUTPUT") from = null;
                    if (to != null && (string)to.Attributes["direction"] != "INPUT") to = null;
                    if (from == null || to == null) incompletePipelines.Add(owner);
                }
                if (from == null && to == null) { partial = true; return; }
                bool complete = from != null && to != null; partial |= !complete;
                links.Add(new Link { Kind = kind, From = from == null ? null : from.Id, To = to == null ? null : to.Id, Scope = owner, Order = declarationPosition, Resolution = complete ? "RESOLVED" : "UNRESOLVED", Mapping = mapping });
                Limits.Check("modelEdges", links.Count);
            };
            int position = 0;
            foreach (var e in Root.DescendantsAndSelf())
            {
                Check(); ++position;
                if (e.Name == "path" && e.Parent.Name == "paths" && e.Parent.Parent.Name == "pipeline")
                {
                    Definition owner = byElement[e.Ancestors().First(x => byElement.ContainsKey(x) && byElement[x].Kind == "EXECUTABLE")];
                    int before = links.Count;
                    link("PIPELINE_PATH", resolve(Attribute(e, "startId"), "PORT", owner.Id), resolve(Attribute(e, "endId"), "PORT", owner.Id), owner.Id, position, null);
                    // Der optionale Ausführungssidecar verwendet die bereits
                    // hier materialisierte Deklaration; kein zweiter Pfadparser.
                    if (links.Count > before) { links[links.Count - 1].NativeReference = (string)e.Attribute("refId"); links[links.Count - 1].NativeName = (string)e.Attribute("name"); }
                }
                if (e.Name == Dts + "PrecedenceConstraint")
                {
                    var parent = e.Ancestors().First(x => byElement.ContainsKey(x) && (byElement[x].Kind == "PACKAGE" || byElement[x].Kind == "EXECUTABLE")); Definition owner = byElement[parent];
                    Func<string, Definition> endpoint = reference => { List<Definition> found; return executablesByParentAndReference.TryGetValue(owner.Id + "\0" + reference, out found) && found.Count == 1 ? found[0] : null; };
                    link("CONTROL_FLOW", endpoint(Attribute(e, "From")), endpoint(Attribute(e, "To")), owner.Id, position, null);
                }
                Definition column;
                if (!byElement.TryGetValue(e, out column) || column.Kind != "COLUMN" || e.Name == "externalMetadataColumn") continue;
                string externalId = Attribute(e, "externalMetadataColumnId");
                if (externalId != "" && externalId != "0")
                {
                    List<Definition> external; externalColumnsByParentRef.TryGetValue(column.Parent + "\0" + externalId, out external);
                    link("COLUMN_MAP", column, external.Count == 1 ? external[0] : null, scope(column), position, "METADATA_REFERENCE");
                }
                if (e.Name != "inputColumn") continue;
                Definition port = lookup[column.Parent]; string flow = scope(column), lineage = Attribute(e, "lineageId");
                List<XElement> incoming; pathsByFlowAndEnd.TryGetValue(flow + "\0" + Attribute(port.Element, "refId"), out incoming);
                Definition sourcePort = incoming != null && incoming.Count == 1 ? resolve(Attribute(incoming[0], "startId"), "PORT", flow) : null;
                List<Definition> candidates; columnsByParentAndIdentity.TryGetValue((sourcePort == null ? "" : sourcePort.Id) + "\0" + lineage, out candidates);
                if (candidates == null) candidates = new List<Definition>();
                link("COLUMN_MAP", candidates.Count == 1 ? candidates[0] : null, column, flow, position, "DATA_TRANSFER");
            }
            foreach (var declared in links.Where(x => x.Kind == "COLUMN_MAP" && x.Mapping == "DATA_TRANSFER" && x.Resolution == "RESOLVED").ToList())
                links.Add(new Link { Kind = "VALUE_DEPENDENCY", From = declared.From, To = declared.To, Scope = declared.Scope, Resolution = "RESOLVED", Rule = "MAPPED_VALUE_INPUT" });
            Limits.Check("modelEdges", links.Count + assignmentEdges); Limits.Check("diagnostics", diagnostics.Count);
            bool complex = items.Where(x => x.Kind == "COMPONENT").Any(x => { string c = Attribute(x.Element, "componentClassID"); return !(c == "Microsoft.OLEDBSource" || c == "Microsoft.OLEDBDestination"); });
            if (encrypted) diagnostics.Add(Obj("code", "ENCRYPTED_CONTENT", "objectId", "pkg1"));
            if (partial) diagnostics.Add(Obj("code", "PARTIAL_LINEAGE", "objectId", null));
            if (expressions) diagnostics.Add(Obj("code", "EXPRESSION_UNRESOLVED", "objectId", null));
            Limits.Check("diagnostics", diagnostics.Count);
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

        private long ResolveVariableAssignments(IList<Definition> items)
        {
            var variables = items.Where(x => x.Kind == "VARIABLE").ToList();
            var scopeIds = new Dictionary<string, string>(StringComparer.Ordinal) { { "Package", items.Single(x => x.Kind == "PACKAGE").Id } };
            var ambiguousScopes = new HashSet<string>(StringComparer.Ordinal);
            foreach (var executable in items.Where(x => x.Kind == "EXECUTABLE"))
            {
                string path = executable.Get("refId");
                if (String.IsNullOrEmpty(path)) continue;
                if (scopeIds.ContainsKey(path)) { scopeIds.Remove(path); ambiguousScopes.Add(path); }
                else if (!ambiguousScopes.Contains(path)) scopeIds.Add(path, executable.Id);
            }
            Func<string, string> scopeId = path => { string id; return !String.IsNullOrEmpty(path) && !ambiguousScopes.Contains(path) && scopeIds.TryGetValue(path, out id) ? id : null; };
            var seenProducers = new Dictionary<Definition, HashSet<string>>();
            long assignmentEdges = 0;
            foreach (var variable in variables)
            { variable.Attributes["assignmentState"] = "none"; variable.Attributes["assignmentProducers"] = new List<object>(); seenProducers.Add(variable, new HashSet<string>(StringComparer.Ordinal)); }
            Action<Definition, string, Definition> add = (variable, kind, producer) =>
            {
                variable.Attributes["assignmentState"] = "declared";
                var list = (List<object>)variable.Attributes["assignmentProducers"];
                if (seenProducers[variable].Add(kind + "\0" + producer.Id))
                { Limits.Check("modelEdges", ++assignmentEdges); Check();
                    list.Add(Obj("kind", kind, "producerId", producer.Id, "scopeId", scopeId(producer.LegacyScope)));
                }
            };
            Action<Definition, Definition> unknown = (variable, producer) =>
            {
                variable.Attributes["assignmentState"] = "unknown";
                if (seenProducers[variable].Add("script-write-scope-unknown\0" + producer.Id))
                { Limits.Check("modelEdges", ++assignmentEdges); Check();
                    ((List<object>)variable.Attributes["assignmentProducers"]).Add(Obj("kind", "script-write-scope-unknown", "producerId", producer.Id, "scopeId", scopeId(producer.LegacyScope)));
                }
            };
            Action<Definition> markScopeUnknown = producer =>
            {
                string path = producer.Get("refId");
                if (String.IsNullOrEmpty(path)) path = producer.LegacyScope;
                foreach (var variable in variables.Where(v => v.LegacyScope == "Package" || path == v.LegacyScope || path.StartsWith(v.LegacyScope + "\\", StringComparison.Ordinal))) unknown(variable, producer);
            };
            Action<string, string, Definition> resolve = (reference, kind, producer) =>
            {
                string name = reference == null ? "" : reference.Trim();
                if (name.StartsWith("@[", StringComparison.Ordinal) && name.EndsWith("]", StringComparison.Ordinal)) name = name.Substring(2, name.Length - 3);
                else if (name.StartsWith("@", StringComparison.Ordinal)) name = name.Substring(1);
                if (name.StartsWith("[", StringComparison.Ordinal)) name = name.Substring(1);
                if (name.EndsWith("]", StringComparison.Ordinal)) name = name.Substring(0, name.Length - 1);
                var found = variables.Where(v => String.Equals(Attribute(v.Element, "Namespace") + "::" + v.Name, name, StringComparison.OrdinalIgnoreCase) &&
                    (producer.LegacyScope == "Package" || v.LegacyScope == producer.LegacyScope || producer.LegacyScope.StartsWith(v.LegacyScope + "\\", StringComparison.Ordinal))).ToList();
                if (found.Count == 1) add(found[0], kind, producer); else markScopeUnknown(producer);
            };
            foreach (var producer in items.Where(x => x.Kind == "EXECUTABLE"))
            {
                string executableType = producer.Get("ExecutableType");
                bool script = executableType.IndexOf("Script", StringComparison.OrdinalIgnoreCase) >= 0, hasScriptWriteList = false;
                foreach (var node in producer.Element.DescendantsAndSelf().Where(e => e.Ancestors(Dts + "Executable").FirstOrDefault() == producer.Element && (e.Name.LocalName == "ResultBinding" || e.Name.LocalName == "VariableMapping")))
                {
                    string reference = LocalAttribute(node, "VariableName");
                    if (reference != "") resolve(reference, node.Name.LocalName == "ResultBinding" ? "execute-sql-result" : "foreach-variable-mapping", producer);
                    else if (node.Name.LocalName == "VariableMapping") markScopeUnknown(producer);
                }
                foreach (var property in producer.Element.DescendantsAndSelf().Where(e => e.Ancestors(Dts + "Executable").FirstOrDefault() == producer.Element && e.Name.LocalName == "Property"))
                {
                    string name = LocalAttribute(property, "Name"), value = property.Value ?? "";
                    if (script && String.Equals(name, "ReadWriteVariables", StringComparison.OrdinalIgnoreCase))
                    {
                        hasScriptWriteList = true;
                        var matches = System.Text.RegularExpressions.Regex.Matches(value, @"(?:@\[)?(?:User|Project)::[^\],;\s]+\]?");
                        if (matches.Count == 0 && value.Trim() != "")
                            markScopeUnknown(producer);
                        else foreach (System.Text.RegularExpressions.Match match in matches) resolve(match.Value, "script-read-write-variable", producer);
                    }
                    if (String.Equals(name, "AssignExpression", StringComparison.OrdinalIgnoreCase))
                    {
                        var matches = System.Text.RegularExpressions.Regex.Matches(value, @"@\[(?<name>(?:User|Project)::[^\]]+)\]\s*=");
                        if (matches.Count == 0 && value.Trim() != "") markScopeUnknown(producer);
                        foreach (System.Text.RegularExpressions.Match match in matches) resolve(match.Groups["name"].Value, "for-loop-assignment-expression", producer);
                    }
                }
                foreach (var node in producer.Element.DescendantsAndSelf().Where(e => e == producer.Element || e.Ancestors(Dts + "Executable").FirstOrDefault() == producer.Element))
                {
                    if (script && HasLocalAttribute(node, "ReadWriteVariables"))
                    {
                        hasScriptWriteList = true;
                        string value = LocalAttribute(node, "ReadWriteVariables");
                        var matches = System.Text.RegularExpressions.Regex.Matches(value, @"(?:@\[)?(?:User|Project)::[^\],;\s]+\]?");
                        if (matches.Count == 0 && value.Trim() != "") markScopeUnknown(producer);
                        else foreach (System.Text.RegularExpressions.Match match in matches) resolve(match.Value, "script-read-write-variable", producer);
                    }
                    if (HasLocalAttribute(node, "AssignExpression"))
                    {
                        string value = LocalAttribute(node, "AssignExpression");
                        var matches = System.Text.RegularExpressions.Regex.Matches(value, @"@\[(?<name>(?:User|Project)::[^\]]+)\]\s*=");
                        if (matches.Count == 0 && value.Trim() != "") markScopeUnknown(producer);
                        foreach (System.Text.RegularExpressions.Match match in matches) resolve(match.Groups["name"].Value, "for-loop-assignment-expression", producer);
                    }
                }
                if (script && !hasScriptWriteList)
                    markScopeUnknown(producer);
            }
            foreach (var producer in items.Where(x => x.Kind == "COMPONENT" && x.ComponentKind == "rowcount"))
            {
                string reference;
                if (!producer.Properties.TryGetValue("VariableName", out reference)) producer.Properties.TryGetValue("Variable", out reference);
                if (!String.IsNullOrWhiteSpace(reference)) resolve(reference, "row-count-variable", producer);
            }
            return assignmentEdges;
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
        public Dictionary<string, object> ExportComponentsV2(string producerVersion, string sourceCommit, string buildSha256)
        {
            if (!ComponentsV2) throw new ModelException("INVALID_PROFILE_MODE");
            var model = Export(producerVersion, sourceCommit, buildSha256);
            model["version"] = "2.0.0";
            model["profiles"] = Obj("format", "1.0.0", "components", "2.0.0", "lineage", "1.0.0");
            model["contract"] = "ssis-package-model-components-v2";
            model["resourcePolicy"] = Limits.Metadata();
            return model;
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
