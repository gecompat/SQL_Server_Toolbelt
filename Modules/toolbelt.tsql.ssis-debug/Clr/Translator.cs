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
        // ANSI-Lineage nur nach Katalogprüfung setzen; kein Encoding raten.
        internal int? SourceCodePage;
    }
    internal sealed class Stage
    {
        internal string Id, Cte, Query, Component, Error, ErrorText, RootCauseCode, RootCauseStage, RootCauseComponent, RootCauseText;
        internal string RowCountVariable, RowCountType;
        internal string FlatFileWriteMetadata;
        internal long RowCountMinimum, RowCountMaximum;
        internal readonly List<StageColumn> Columns = new List<StageColumn>();
        internal readonly List<Stage> Parents = new List<Stage>();
        internal readonly List<KeyValuePair<string, string>> ExtraCtes = new List<KeyValuePair<string, string>>();
        internal readonly HashSet<string> Inputs = new HashSet<string>(StringComparer.Ordinal);
        internal readonly HashSet<string> ReferenceInputs = new HashSet<string>(StringComparer.Ordinal);
        internal readonly List<LookupCache> Caches = new List<LookupCache>();
        internal readonly List<string> StructureGuards = new List<string>();
        internal readonly List<ProcedureDataset> Procedures = new List<ProcedureDataset>();
    }
    internal sealed class ProcedureDataset
    {
        internal string Name, Call;
        internal Stage Input;
        internal List<BoundColumn> Columns;
    }
    internal sealed class LookupCache
    {
        internal string Name, StateName, Insert, Definition, Owner;
        internal string PreviewQuery;
        internal readonly List<KeyValuePair<string, string>> PreviewCtes = new List<KeyValuePair<string, string>>();
        internal string PlanSaltState, PlanSaltOwner, PlanHash;
        internal bool FreshPerExecution, PreserveTextKeyLength;
        internal readonly List<StageColumn> Columns = new List<StageColumn>();
        internal readonly HashSet<string> Inputs = new HashSet<string>(StringComparer.Ordinal);
        internal readonly List<LookupCache> Dependencies = new List<LookupCache>();
    }
    internal sealed class Translator
    {
        private sealed class BuildFrame { internal Flow Flow; internal string OutputId; internal Component Owner; internal Port Port; internal bool After; }
        private readonly Package package; private readonly Bindings bindings; private readonly Options options;
        private readonly SqlSafety safety; private readonly ICatalog catalog; private readonly Artifacts output;
        private readonly Dictionary<string, Stage> stages = new Dictionary<string, Stage>(StringComparer.Ordinal);
        private readonly HashSet<string> building = new HashSet<string>(StringComparer.Ordinal);
        private readonly Dictionary<string, string> stageIds = new Dictionary<string, string>(StringComparer.Ordinal), lookupIds = new Dictionary<string, string>(StringComparer.Ordinal);
        private readonly Dictionary<string, Component> outputOwners = new Dictionary<string, Component>(StringComparer.Ordinal);
        private readonly Dictionary<string, Port> outputPorts = new Dictionary<string, Port>(StringComparer.Ordinal);
        private readonly Dictionary<string, LookupCache> lookupCaches = new Dictionary<string, LookupCache>(StringComparer.Ordinal);
        private readonly Dictionary<string, ProcedureDataset> procedureDatasets = new Dictionary<string, ProcedureDataset>(StringComparer.Ordinal);
        private int nextStage, nextColumn, nextSyntheticStage; private readonly string runToken, runHash;
        private readonly HashSet<string> emittedV2Plans = new HashSet<string>(StringComparer.Ordinal);
        internal Translator(Package p, Bindings b, Options o, SqlSafety sql, ICatalog cat, Artifacts result)
        {
            package = p; bindings = b; options = o; safety = sql; catalog = cat; output = result;
            var effective = Json.Obj();
            foreach (Input input in p.Inputs)
            { object v; effective.Add(input.Key, b.Values.TryGetValue(input.Key, out v) ? Types.Literal(input, v) : input.HasDefault && !input.Sensitive && input.SqlType != null ? Types.Literal(input, input.Default) : input.Expression ?? "<runtime>"); }
            runHash = Util.Hash(p.Hash + b.ContextHash + Json.Write(effective, b.Limits) + (o.CatalogBindings == null ? "" : Json.Write(Json.Parse(o.CatalogBindings, b.Limits), b.Limits)) + (o.LookupPolicies == null ? "" : Json.Write(Json.Parse(o.LookupPolicies, b.Limits), b.Limits)) + b.Collation + o.Version);
            string generationSalt = bindings.ComponentsV2 ? Guid.NewGuid().ToString("N") : "";
            // Prozedurdefinitionen verwenden stabile Temp-Namen ohne Analysewerte.
            runToken = (options.ProcedureDefinition
                ? Util.Hash(Json.Write(Json.Obj("package", p.Hash, "target", o.Target, "database", b.DefaultDatabase,
                    "schema", o.ProcedureSchema, "procedure", o.ProcedureName), b.Limits))
                : Util.Hash(runHash + "|" + generationSalt)).Substring(0, 16);
            int lookups = 0;
            foreach (Flow flow in p.Flows) foreach (Component component in flow.Components)
            {
                foreach (Port port in component.Outputs) { stageIds.Add(port.Id, Util.Id("s", ++nextStage)); outputOwners.Add(port.Id, component); outputPorts.Add(port.Id, port); }
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
                bool sharedSnapshotPending = end.Error == null && !bindings.ComponentsV2 && ancestors.Any(s => s.RowCountVariable != null);
                var pathDetails = Json.Obj("stages", ancestors.Select(s => (object)Json.Obj("stageId", s.Id, "componentId", s.Component, "parentStageIds", s.Parents.Select(p => p.Id).ToList(), "status", s.Error == null ? "available" : "blocked",
                    "rootCause", s.Error == null ? null : Json.Obj("code", s.RootCauseCode ?? s.Error, "stageId", s.RootCauseStage ?? s.Id, "componentId", s.RootCauseComponent ?? s.Component, "message", s.RootCauseText ?? s.ErrorText))).ToList());
                if (sharedSnapshotPending) pathDetails.Add("completenessNote", "RowCount und Hauptprojektion nutzen noch keinen gemeinsamen materialisierten Debugstand.");
                output.Add(new Artifact { Kind = "Workflow", Target = target.Key, Component = destination.Id, Content = Json.Write(Json.Obj("flow", flow.Id, "destination", destination.Id, "components", flow.Components.Select(c => (object)(bindings.ComponentsV2 ? Json.Obj("id", c.Id, "kind", c.Kind, "classId", c.Class, "version", c.Version, "versionRaw", c.VersionRaw, "versionPresent", c.VersionPresent, "versionOrigin", c.VersionOrigin, "name", c.Name) : Json.Obj("id", c.Id, "kind", c.Kind, "classId", c.Class, "version", c.Version, "name", c.Name))).ToList(), "tasks", package.Workflow), bindings.Limits), Complete = end.Error == null && !sharedSnapshotPending,
                    Details = Json.Write(pathDetails, bindings.Limits) });
                foreach (Stage stage in ancestors)
                    output.Add(new Artifact { Kind = "StageIndex", Target = target.Key, Stage = stage.Id, Component = stage.Component, Content = stage.Cte, Complete = stage.Error == null, Evidence = stage.Error == null ? "pragmatic" : "unsupported", Safety = stage.Error == null ? "not_checked" : "blocked", Details = Json.Write(Json.Obj("parents", stage.Parents.Select(x => (object)x.Id).ToList(), "columns", stage.Columns.Select(c => (object)Json.Obj("lineageId", c.Id, "name", c.Name, "sqlAlias", c.Alias, "sqlType", c.Type)).ToList(), "status", stage.Error == null ? "available" : "blocked", "rootCause", stage.Error == null ? null : Json.Obj("code", stage.RootCauseCode ?? stage.Error, "stageId", stage.RootCauseStage ?? stage.Id, "componentId", stage.RootCauseComponent ?? stage.Component, "message", stage.RootCauseText ?? stage.ErrorText)), bindings.Limits) });
                if (options.ProcedureDefinition)
                {
                    if (end.Error != null) output.Diagnostic(end.Error, destination.Id, end.ErrorText, target.Key);
                    else if (ancestors.Count != 3 || destination.Kind != "destination" ||
                        flow.Components.Single(c => c.Id == ancestors[0].Component).Kind != "source" ||
                        flow.Components.Single(c => c.Id == ancestors[1].Component).Kind != "derived" ||
                        ancestors[1].Parents.Count != 1 || ancestors.Any(s => s.StructureGuards.Count != 0 || s.Caches.Count != 0))
                        output.Diagnostic("procedure_profile", destination.Id, "Prozedur erfordert einen linearen SQL-Quellpfad über eine Derived Column zur SQL-Zielprojektion.", target.Key);
                    else EmitV2Plan(end, "TargetSql", target.Key);
                    continue;
                }
                if (options.Stage != null && options.Stage != "all" && !ancestors.Any(s => s.Id == options.Stage)) throw new DebugFault("unresolved_binding", "Stufe gehört nicht zum ausgewählten Zielfluss.");
                if (options.CatalogMode == "package")
                {
                    if (end.Error != null)
                    {
                        output.Diagnostic(end.RootCauseCode ?? end.Error, end.RootCauseComponent ?? end.Component, end.RootCauseText ?? end.ErrorText, target.Key);
                        output.Add(new Artifact { Kind = "DebugScript", Target = target.Key, Stage = end.Id, Component = end.Component, Content = "-- Unvollständiger Paketpfad; konkrete Erstursache in Diagnostic/StageIndex.\n", Complete = false, Safety = "blocked", Executable = false });
                        continue;
                    }
                    if (options.Stage == "all") foreach (var stage in ancestors) EmitPackagePreview(stage, "StageSql", target.Key);
                    else if (options.Stage != null) EmitPackagePreview(ancestors.Single(s => s.Id == options.Stage), "StageSql", target.Key);
                    string preview = EmitPackagePreview(end, "TargetSql", target.Key);
                    output.Add(new Artifact { Kind = "DebugScript", Target = target.Key, Stage = end.Id, Component = end.Component, Content = preview, Complete = true, Safety = "not_checked", Executable = false, Evidence = "pragmatic" });
                    continue;
                }
                if (options.Stage == "all") foreach (Stage stage in ancestors.Where(s => s.Error == null)) Emit(stage, "StageSql", target.Key);
                else if (options.Stage != null) { Stage stage = ancestors.Single(s => s.Id == options.Stage); if (stage.Error == null) Emit(stage, "StageSql", target.Key); }
                if (end.Error == null && destination.Kind == "flatfile-destination")
                {
                    output.Add(new Artifact { Kind = "FlatFileWriteProjection", Target = target.Key, Stage = end.Id, Component = destination.Id, Content = end.FlatFileWriteMetadata, Evidence = "pragmatic", Complete = false, Safety = "not_checked", Details = Json.Write(Json.Obj("limitation", "Metadatenprojektion ohne Dateiserialisierung oder Zielschreibvorgang."), bindings.Limits) });
                    Emit(end, "TargetSql", target.Key);
                }
                else if (end.Error == null) Emit(end, "TargetSql", target.Key);
                else output.Diagnostic(end.Error, destination.Id, end.ErrorText, target.Key);
                EmitDebugScript(target.Key, end, ancestors);
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
                if (c.Kind == "flatfile-destination")
                {
                    if (!bindings.ComponentsV2 || c.Inputs.Count != 1 || c.Outputs.Count != 0) throw new DebugFault("unsupported_component", "Flatfile-Zielprofil nicht unterstützt.");
                    string destinationConnectionKind;
                    if (c.Connection == null || !package.ConnectionKinds.TryGetValue(c.Connection, out destinationConnectionKind) || destinationConnectionKind != "FLATFILE") throw new DebugFault("missing_context", "Expliziter Flatfile-Zielconnectionmanager fehlt.");
                    Stage fileParent = Input(flow, c.Inputs[0]); Inherit(result, fileParent); Need(result, fileParent);
                    var fields = new List<string>(); var mapping = new List<object>(); int ordinal = 0;
                    foreach (Column input in c.Inputs[0].Columns)
                    {
                        StageColumn source = Find(fileParent, input.Lineage); Column external = c.Inputs[0].External.SingleOrDefault(x => x.Id == input.External);
                        string name = external == null ? input.Name : external.Name;
                        if (input.SqlType == null) throw new DebugFault("missing_context", "Flatfile-Zieltyp fehlt.");
                        var col = NewColumn(input.Id, name, input.SqlType, source.Nullable); result.Columns.Add(col);
                        fields.Add("CAST(m." + Util.Q(source.Alias) + " AS " + col.Type + ") AS " + Util.Q(col.Alias));
                        mapping.Add(Json.Obj("ordinal", ++ordinal, "inputIdentity", input.Id, "name", name, "sourceLineageId", source.Id, "sqlType", col.Type));
                    }
                    if (fields.Count == 0) throw new DebugFault("missing_context", "Flatfile-Zielspaltenprojektion fehlt.");
                    result.Query = "SELECT " + String.Join(", ", fields) + " FROM " + Util.Q(fileParent.Cte) + " AS m";
                    var fileProperties = c.Properties.ToDictionary(x => x.Key, x => (object)x.Value, StringComparer.Ordinal);
                    result.FlatFileWriteMetadata = Json.Write(Json.Obj("mode", "metadata-only-no-file-write", "connectionManagerRefId", c.Connection, "columns", mapping, "properties", fileProperties, "complete", false), bindings.Limits);
                    return result;
                }
                if (c.Kind != "destination" || c.Inputs.Count != 1) throw new DebugFault("unsupported_component", "Zielform nicht unterstützt.");
                Stage parent = Input(flow, c.Inputs[0]); Inherit(result, parent); Need(result, parent);
                var list = new List<string>();
                foreach (Column input in c.Inputs[0].Columns)
                {
                    StageColumn source = Find(parent, input.Lineage); Column external = c.Inputs[0].External.SingleOrDefault(x => x.Id == input.External);
                    if ((external == null || external.SqlType == null) && options.CatalogMode == "package")
                    {
                        external = new Column { Name = external == null ? input.Name : external.Name, SqlType = source.Type };
                        output.Diagnostic("destination_projection_only", c.Id, "Ziel-DML wird nicht erzeugt; fehlendes Zielmapping verwendet den deklarierten Namen des Datenflusseingangs.");
                    }
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
        private static IEnumerable<Port> RequiredPorts(Flow flow, Component component)
        {
            // SSIS lässt beim Union All einen leeren Reserveeingang stehen.
            // Nur dieser unverbundene Port ohne Mapping ist bedeutungslos.
            return component.Inputs.Where(p => component.Kind != "union" || p.Columns.Count != 0 || flow.Paths.ContainsKey(p.Id));
        }
        private Stage Build(Flow flow, string outputId)
        {
            if (bindings.ComponentsV2) return BuildV2Iterative(flow, outputId);
            return BuildLegacy(flow, outputId);
        }
        private Stage BuildLegacy(Flow flow, string outputId)
        {
            bindings.Limits.Check("planUnits", building.Count + 1);
            Stage saved; if (stages.TryGetValue(outputId, out saved)) { if (building.Contains(outputId)) throw new DebugFault("ambiguous_path", "Zyklischer Datenfluss."); return saved; }
            var owner = flow.Components.SingleOrDefault(c => c.Outputs.Any(p => p.Id == outputId));
            if (owner == null) throw new DebugFault("invalid_lineage", "Output nicht gebunden.");
            Port port = owner.Outputs.Single(p => p.Id == outputId); Stage result = New(owner.Id, owner.Kind, outputId); stages.Add(outputId, result); building.Add(outputId);
            try
            {
                foreach (Port input in RequiredPorts(flow, owner)) { Stage parent = Input(flow, input); Inherit(result, parent); }
                foreach (Stage parent in result.Parents) Need(result, parent);
                if (port.Error && owner.Kind != "flatfile-source" || owner.HasPropertyExpressions) throw new DebugFault("unsupported_component", "Errorport oder nicht aufgelöster Eigenschaftsausdruck.");
                switch (owner.Kind)
                {
                    case "source": Source(owner, port, result); break;
                    case "flatfile-source": FlatFileSource(owner, port, result); break;
                    case "union": Union(flow, owner, port, result); break;
                    case "copy-column": CopyColumn(owner, port, result); break;
                    case "derived": case "convert": Derived(owner, port, result); break;
                    case "rowcount": RowCount(owner, port, result); break;
                    case "multicast": Multicast(owner, port, result); break;
                    case "unpivot": Unpivot(owner, port, result); break;
                    case "split": Split(owner, port, result); break;
                    case "lookup": Lookup(owner, port, result); break;
                    default: throw new DebugFault("unsupported_component", "Komponente nicht im V1-Profil.");
                }
            }
            catch (DebugFault e) { if (e.Code == "resource_limit" || e.Code == "invalid_template") throw; Block(result, e); }
            finally { building.Remove(outputId); }
            return result;
        }
        private Stage BuildV2Iterative(Flow flow, string outputId)
        {
            Stage existing;
            if (stages.TryGetValue(outputId, out existing)) { if (building.Contains(outputId)) throw new DebugFault("ambiguous_path", "Zyklischer Datenfluss."); return existing; }
            var pending = new Stack<BuildFrame>(); pending.Push(new BuildFrame { Flow = flow, OutputId = outputId });
            while (pending.Count != 0)
            {
                BuildFrame frame = pending.Pop();
                if (frame.After)
                {
                    try { BuildV2Stage(frame.Flow, frame.OutputId, frame.Owner, frame.Port); }
                    finally { building.Remove(frame.OutputId); }
                    continue;
                }
                if (stages.ContainsKey(frame.OutputId)) continue;
                if (!building.Add(frame.OutputId)) throw new DebugFault("ambiguous_path", "Zyklischer Datenfluss.");
                Component owner; Port port;
                if (!outputOwners.TryGetValue(frame.OutputId, out owner) || !outputPorts.TryGetValue(frame.OutputId, out port)) { building.Remove(frame.OutputId); throw new DebugFault("invalid_lineage", "Output nicht gebunden."); }
                bindings.Limits.Check("planUnits", stages.Count + building.Count);
                pending.Push(new BuildFrame { Flow = frame.Flow, OutputId = frame.OutputId, Owner = owner, Port = port, After = true });
                for (int i = owner.Inputs.Count - 1; i >= 0; i--)
                {
                    string parentOutput;
                    if (!frame.Flow.Paths.TryGetValue(owner.Inputs[i].Id, out parentOutput)) continue;
                    if (building.Contains(parentOutput)) throw new DebugFault("ambiguous_path", "Zyklischer Datenfluss.");
                    if (!stages.ContainsKey(parentOutput)) pending.Push(new BuildFrame { Flow = frame.Flow, OutputId = parentOutput });
                }
            }
            Stage result;
            if (!stages.TryGetValue(outputId, out result)) throw new DebugFault("invalid_lineage", "Output nicht aufgebaut.");
            return result;
        }
        private void BuildV2Stage(Flow flow, string outputId, Component owner, Port port)
        {
            Stage result = New(owner.Id, owner.Kind, outputId); stages.Add(outputId, result);
            try
            {
                foreach (Port input in RequiredPorts(flow, owner)) { Stage parent = Input(flow, input); Inherit(result, parent); }
                foreach (Stage parent in result.Parents) Need(result, parent);
                if (port.Error && owner.Kind != "flatfile-source" || owner.HasPropertyExpressions) throw new DebugFault("unsupported_component", "Errorport oder nicht aufgelöster Eigenschaftsausdruck.");
                switch (owner.Kind)
                {
                    case "source": Source(owner, port, result); break;
                    case "flatfile-source": FlatFileSource(owner, port, result); break;
                    case "union": Union(flow, owner, port, result); break;
                    case "copy-column": CopyColumn(owner, port, result); break;
                    case "derived": case "convert": Derived(owner, port, result); break;
                    case "rowcount": RowCount(owner, port, result); break;
                    case "multicast": Multicast(owner, port, result); break;
                    case "unpivot": Unpivot(owner, port, result); break;
                    case "split": Split(owner, port, result); break;
                    case "lookup": Lookup(owner, port, result); break;
                    default: throw new DebugFault("unsupported_component", "Komponente nicht im V1-Profil.");
                }
            }
            catch (DebugFault e) { if (e.Code == "resource_limit" || e.Code == "invalid_template") throw; Block(result, e); }
        }
        private static void Block(Stage stage, DebugFault e)
        {
            stage.Error = e.Code; stage.ErrorText = e.Message;
            stage.RootCauseCode = e.RootCode ?? e.Code; stage.RootCauseStage = e.RootStage ?? stage.Id;
            stage.RootCauseComponent = e.RootComponent ?? stage.Component; stage.RootCauseText = e.RootText ?? e.Message;
        }
        private static void Need(Stage dependent, Stage parent)
        {
            if (parent.Error == null) return;
            throw new DebugFault("partial_target", "Stufe " + parent.Id + " (Komponente " + parent.Component + ") blockiert diesen Pfad; Erstursache " + parent.RootCauseCode + " an Stufe " + parent.RootCauseStage + ": " + parent.RootCauseText,
                parent.RootCauseCode ?? parent.Error, parent.RootCauseStage ?? parent.Id, parent.RootCauseComponent ?? parent.Component, parent.RootCauseText ?? parent.ErrorText);
        }
        private static void Inherit(Stage stage, Stage parent)
        { if (!stage.Parents.Contains(parent)) stage.Parents.Add(parent); stage.Inputs.UnionWith(parent.Inputs); foreach (var cache in parent.Caches) if (!stage.Caches.Contains(cache)) stage.Caches.Add(cache); foreach (var procedure in parent.Procedures) if (!stage.Procedures.Contains(procedure)) stage.Procedures.Add(procedure); }
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
                bool objectName = mode == "1";
                string valueLabel = objectName ? "Objektname" : "Command-Text";
                string var = PackageReader.P(c.Properties, objectName ? "OpenRowsetVariable" : "SqlCommandVariable"); Input input = package.Resolve(var, c.Scope); object value;
                input.Required = true;
            if (!bindings.Values.TryGetValue(input.Key, out value))
            {
                if (!input.HasDefault || input.RuntimeAssigned || input.Expression != null)
                {
                        string bindingTarget = input.Sensitive ? "die sensible Eingabe (Name redigiert)" : "den values-Schlüssel " + input.Key + " für " + input.Name;
                        string reason = input.Sensitive ? "Der benötigte " + valueLabel + " ist sensibel und wird nicht ausgegeben." :
                            input.AssignmentState == "unknown" ? "Die Zuweisungsstelle ist nicht statisch auflösbar; einen expliziten Debugwert für " + bindingTarget + " binden." :
                            input.RuntimeAssigned ? "Der benötigte " + valueLabel + " wird an einer Paket-Zuweisungsstelle gesetzt; einen expliziten Debugwert für " + bindingTarget + " binden." :
                            input.Expression != null ? "Der benötigte " + valueLabel + " stammt aus einem Ausdruck; dessen Eingaben in values binden." :
                            "Der benötigte " + valueLabel + " fehlt; " + (objectName ? "den Objektnamen" : "den SQL-Text") + " für " + bindingTarget + " in values binden.";
                    throw new DebugFault("unresolved_binding", reason);
                }
                value = input.Default;
            }
                if (input.Sensitive || !(value is string)) throw new DebugFault("unresolved_binding", "Commandvariable nicht exportierbar.");
                var structural = bindings.Resolve(input); stage.Inputs.UnionWith(structural.Inputs); stage.ReferenceInputs.UnionWith(structural.Inputs);
                // Strukturwerte bleiben sichtbar; ein geänderter SQL-Text muss
                // erneut analysiert werden, bevor er ausführbar werden darf.
                stage.StructureGuards.Add("IF " + input.SqlName + " IS NULL OR CONVERT(varbinary(max), " + input.SqlName + ") <> CONVERT(varbinary(max), " + Util.L((string)value) + ") THROW 50000, 'TBX_SSISDBG_unresolved_binding: SQL-Struktur geaendert; erneut generieren.', 1;");
                sql = mode == "1" ? "SELECT * FROM " + (string)value : (string)value;
            }
            else if (mode == "2") sql = PackageReader.P(c.Properties, "SqlCommand");
            else throw new DebugFault("unsupported_component", "Source-AccessMode nicht unterstützt.");
            if (sql == "")
            {
                if (mode == "1" || mode == "3")
                {
                    string reference = PackageReader.P(c.Properties, mode == "1" ? "OpenRowsetVariable" : "SqlCommandVariable");
                    Input input = package.Resolve(reference, c.Scope);
                    throw new DebugFault("unresolved_binding", "Der gebundene " + (mode == "1" ? "Objektname" : "Command-Text") + " ist leer; values-Schlüssel " + input.Key + " für " + input.Name + " muss einen nicht-leeren Wert enthalten.");
                }
                throw new DebugFault("unresolved_binding", "Source-/Lookup-SQL fehlt.");
            }
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
        {
            string sql = SqlCommand(c, stage), call;
            List<BoundColumn> columns = options.CatalogMode == "package" ? PackageProjection.Columns(c, bindings.Limits) : null;
            string database = options.CatalogMode == "package" && bindings.LocalConnections.Contains(c.Connection) ? null : bindings.Database(c);
            if (options.CatalogMode == "package" && safety.TryPackageProcedure(sql, database, out call))
            {
                ProcedureDataset dataset;
                if (!procedureDatasets.TryGetValue(c.Id, out dataset))
                {
                    dataset = new ProcedureDataset { Name = "#tbx_SsisDebug_P_" + runToken + "_" + procedureDatasets.Count, Call = call, Columns = columns, Input = c.Kind == "lookup" ? stage.Parents.Single() : null };
                    procedureDatasets.Add(c.Id, dataset);
                    output.Diagnostic("procedure_result_materialized", c.Id, "Prozedurergebnis wird beim manuellen Ausführen in einer lokalen #-Tabelle materialisiert. Resultsetschema stammt aus DTSX; Prozedurinneres und Seiteneffekte sind nicht geprüft.");
                }
                if (!stage.Procedures.Contains(dataset)) stage.Procedures.Add(dataset);
                sql = "SELECT * FROM " + Util.Q(dataset.Name);
            }
            var query = safety.Read(sql, database);
            if (columns != null) query.PackageColumns = columns;
            return query;
        }
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
                col.SourceCodePage = outputColumn.Type == "str" ? (int?)outputColumn.CodePage : null;
                list.Add("CAST(src." + Util.Q(name) + " AS " + col.Type + ") AS " + Util.Q(col.Alias));
            }
            if (list.Count == 0) throw new DebugFault("invalid_lineage", "Source-Ausgang hat keine Metadaten.");
            stage.Query = "SELECT " + String.Join(", ", list) + " FROM (" + sql + ") AS src";
        }
        private void RowCount(Component c, Port port, Stage stage)
        {
            if (!bindings.ComponentsV2 || c.Inputs.Count != 1 || stage.Parents.Count != 1 || c.Outputs.Count(x => !x.Error) != 1 || port.Error)
                throw new DebugFault("unsupported_component", "Row Count Portprofil nicht unterstützt.");
            string reference = PackageReader.P(c.Properties, "VariableName", PackageReader.P(c.Properties, "Variable"));
            if (reference == "") throw new DebugFault("missing_context", "Row Count Zielvariable fehlt.");
            Input variable;
            try { variable = package.Resolve(reference, c.Scope); }
            catch (DebugFault) { throw new DebugFault("missing_context", "Row Count Zielvariable ist nicht eindeutig gebunden."); }
            if (variable.Kind != "variable" || variable.ReadOnly || variable.Sensitive || variable.SqlType == null || variable.Expression != null)
                throw new DebugFault("missing_context", "Row Count Ziel muss eine beschreibbare Paketvariable sein.");
            long minimum, maximum;
            switch ((variable.Type ?? "").ToLowerInvariant())
            {
                case "i1": case "sbyte": case "16": minimum = SByte.MinValue; maximum = SByte.MaxValue; break;
                case "ui1": case "byte": case "17": minimum = 0; maximum = Byte.MaxValue; break;
                case "i2": case "int16": case "2": minimum = Int16.MinValue; maximum = Int16.MaxValue; break;
                case "ui2": case "uint16": case "18": minimum = 0; maximum = UInt16.MaxValue; break;
                case "i4": case "int32": case "3": minimum = Int32.MinValue; maximum = Int32.MaxValue; break;
                case "ui4": case "uint32": case "19": minimum = 0; maximum = UInt32.MaxValue; break;
                case "i8": case "int64": case "20": minimum = Int64.MinValue; maximum = Int64.MaxValue; break;
                case "ui8": case "uint64": case "21": minimum = 0; maximum = Int64.MaxValue; break;
                default: throw new DebugFault("missing_context", "Row Count Zielvariable muss einen unterstützten Integer-Typ haben.");
            }
            Stage parent = stage.Parents[0]; Inherit(stage, parent); Need(stage, parent);
            stage.Columns.AddRange(parent.Columns);
            stage.Query = "SELECT " + Fields(parent, "m") + " FROM " + Util.Q(parent.Cte) + " AS m";
            stage.RowCountVariable = variable.Name; stage.RowCountType = variable.Type; stage.RowCountMinimum = minimum; stage.RowCountMaximum = maximum;
        }
        private void FlatFileSource(Component c, Port port, Stage stage)
        {
            Bindings.FlatFileInputBinding binding;
            if (c.Connection == null || !bindings.FlatFileInputs.TryGetValue(c.Connection, out binding))
            {
                if (options.CatalogMode != "package" || port.Error) throw new DebugFault("missing_context", "Expliziter relationaler Flatfile-Zeilenbestand fehlt.");
                // Ausdrücklich gewünschte lokale Annahme: eine Dummyzeile mit
                // den deklarierten DTSX-Typen, kein Datei-/Serverzugriff.
                var fields = new List<string>();
                foreach (var column in port.Columns)
                {
                    if (column.SqlType == null) throw new DebugFault("missing_context", "Flatfile-Dummyspalte besitzt keinen unterstützten DTSX-Typ.");
                    var value = NewColumn(column.Lineage == "" ? column.Id : column.Lineage, column.Name, column.SqlType, true);
                    value.SourceCodePage = column.Type == "str" ? (int?)column.CodePage : null;
                    stage.Columns.Add(value);
                    fields.Add("CAST(NULL AS " + value.Type + ") AS " + Util.Q(value.Alias));
                }
                if (fields.Count == 0) throw new DebugFault("missing_context", "Flatfile-Dummyquelle hat keine Spalten.");
                stage.Query = "-- Angenommene Flatfile-Quelle: Dummywerte durch lokale Beispielwerte ersetzen.\nSELECT " + String.Join(", ", fields);
                output.Diagnostic("flatfile_source_assumed", c.Id, "Flatfile als eine lokale Dummyzeile mit typisierten NULL-Spalten angenommen; keine Datei gelesen und keine Datenparität behauptet.");
                return;
            }
            string sourceConnectionKind;
            if (!package.ConnectionKinds.TryGetValue(c.Connection, out sourceConnectionKind) || sourceConnectionKind != "FLATFILE") throw new DebugFault("missing_context", "Flatfile-Quelle muss an einen Flatfile-Connectionmanager gebunden sein.");
            if (port.Error)
            {
                if (binding.ErrorRows == null) throw new DebugFault("missing_context", "Explizite Fehlerzeilenquelle fehlt.");
                binding = FlatFileErrorBinding(binding);
            }
            var mapping = new List<KeyValuePair<Column, string>>(); var used = new HashSet<string>(StringComparer.Ordinal);
            foreach (Column column in port.Columns)
            {
                string sqlName;
                if (!binding.Columns.TryGetValue(column.Id, out sqlName) || column.SqlType == null || !used.Add(sqlName)) throw new DebugFault("missing_context", "Explizite Flatfile-Spaltenidentität oder SQL-Typ fehlt.");
                mapping.Add(new KeyValuePair<Column, string>(column, sqlName));
            }
            if (mapping.Count == 0) throw new DebugFault("missing_context", "Flatfile-Ausgang enthält keine gebundenen Spalten.");
            string db = binding.Database;
            if (!bindings.Databases.Contains(db, StringComparer.Ordinal)) throw new DebugFault("invalid_template", "Flatfile-Quelle außerhalb der Datenbank-Allowlist.");
            var selected = mapping.Select((m, i) => Util.Q(m.Value) + " AS " + Util.Q("ff" + i.ToString(CultureInfo.InvariantCulture))).ToList();
            if (binding.RowOrdinalColumn != null) selected.Add(Util.Q(binding.RowOrdinalColumn) + " AS [ff_ordinal]");
            string select = String.Join(", ", selected);
            SqlQuery query = safety.Read("SELECT " + select + " FROM " + Util.Q(db) + "." + Util.Q(binding.Schema) + "." + Util.Q(binding.Object), db);
            var projected = Projection.Columns(query, safety); string sql = Attach(query, stage, stage.Id + "_ff"); var list = new List<string>();
            for (int i = 0; i < mapping.Count; i++)
            {
                Column input = mapping[i].Key; BoundColumn source = projected.SingleOrDefault(x => x.Name == "ff" + i.ToString(CultureInfo.InvariantCulture));
                if (source == null) throw new DebugFault("missing_context", "Flatfile-Ersatzquelle enthält eine gebundene SQL-Spalte nicht.");
                var col = NewColumn(input.Lineage == "" ? input.Id : input.Lineage, input.Name, input.SqlType, source.Nullable); stage.Columns.Add(col);
                list.Add("CAST(src." + Util.Q(source.Name) + " AS " + col.Type + ") AS " + Util.Q(col.Alias));
            }
            stage.Query = "SELECT " + String.Join(", ", list) + " FROM (" + sql + ") AS src";
            if (binding.RowOrdinalColumn != null)
            {
                if (projected.All(x => x.Name != "ff_ordinal")) throw new DebugFault("missing_context", "Angeforderte originale Flatfile-Zeilenreihenfolge fehlt.");
                output.Diagnostic("flatfile_row_ordinal", c.Id, "Die bereitgestellte Reihenfolgenspalte ist gebunden; der Debugfluss behauptet ohne explizite Sortieroperation keine Zeilenreihenfolge.");
            }
            var flatProperties = c.Properties.ToDictionary(x => x.Key, x => (object)x.Value, StringComparer.Ordinal);
            output.Add(new Artifact { Kind = "FlatFileSourceMetadata", Component = c.Id, Content = Json.Write(Json.Obj("mode", "caller-supplied-relational-rows", "fileBytesRead", false, "errorPort", port.Error, "rowOrdinalProvided", binding.RowOrdinalColumn != null, "properties", flatProperties), bindings.Limits), Evidence = "pragmatic", Complete = false });
        }
        private Bindings.FlatFileInputBinding FlatFileErrorBinding(Bindings.FlatFileInputBinding parent)
        {
            var value = Json.Object(parent.ErrorRows); Json.Keys(value, "database", "schema", "object", "columns", "rowOrdinalColumn");
            string db = Json.Text(Json.Get(value, "database")), schema = Json.Text(Json.Get(value, "schema")), name = Json.Text(Json.Get(value, "object"));
            Util.Q(db); Util.Q(schema); Util.Q(name);
            if (!bindings.Databases.Contains(db, StringComparer.Ordinal)) throw new DebugFault("invalid_template", "Fehlerzeilenquelle außerhalb der Datenbank-Allowlist.");
            var result = new Bindings.FlatFileInputBinding { Database = db, Schema = schema, Object = name, RowOrdinalColumn = value.ContainsKey("rowOrdinalColumn") ? Json.Text(value["rowOrdinalColumn"]) : null };
            foreach (var column in Json.Object(Json.Get(value, "columns"))) { string sqlName = Json.Text(column.Value); Util.Q(sqlName); result.Columns.Add(column.Key, sqlName); }
            if (result.Columns.Count == 0) throw new DebugFault("missing_context", "Fehlerzeilen-Spaltenzuordnung fehlt.");
            return result;
        }
        private void ValidateCodePage(Column column, string collation)
        { if (options.CatalogMode != "package" && column.Type == "str" && (column.CodePage <= 0 || collation == null || catalog.CodePage(collation) != column.CodePage)) throw new DebugFault("unresolved_binding", "ANSI-Codepage nicht exakt belegt."); }
        private void Multicast(Component component, Port port, Stage stage)
        {
            if (stage.Parents.Count != 1 || component.Inputs.Count != 1 || port.Error || port.Sync != component.Inputs[0].Id || port.Columns.Count != 0)
                throw new DebugFault("unsupported_component", "Multicast benötigt synchrone unveränderte Ausgänge.");
            var parent = stage.Parents[0]; stage.Columns.AddRange(parent.Columns);
            stage.Query = "SELECT " + Fields(parent, "m") + " FROM " + Util.Q(parent.Cte) + " AS m";
        }
        private void Unpivot(Component component, Port port, Stage stage)
        {
            if (options.CatalogMode != "package" || component.Inputs.Count != 1 || stage.Parents.Count != 1 || component.Outputs.Count != 1 || port.Error)
                throw new DebugFault("unsupported_component", "Unpivot ist als lokaler Paketentwurf mit einem Eingang/Ausgang verfügbar.");
            var parent = stage.Parents[0]; var pivot = port.Columns.Where(c => Util.Flag(PackageReader.P(c.Properties, "PivotKey"))).ToList();
            if (pivot.Count != 1) throw new DebugFault("invalid_lineage", "Unpivot benötigt genau eine PivotKey-Spalte.");
            Func<string, string> reference = s => s.StartsWith("#{", StringComparison.Ordinal) && s.EndsWith("}", StringComparison.Ordinal) ? s.Substring(2, s.Length - 3) : s;
            var pass = new Dictionary<Column, Column>(); var groups = new Dictionary<string, Dictionary<Column, Column>>(StringComparer.Ordinal);
            foreach (var input in component.Inputs[0].Columns)
            {
                string target = reference(PackageReader.P(input.Properties, "DestinationColumn"));
                var outputColumn = port.Columns.SingleOrDefault(c => c.Id == target || c.Lineage == target);
                if (outputColumn == null || outputColumn == pivot[0]) throw new DebugFault("invalid_lineage", "Unpivot-Zielspalte ist nicht eindeutig gebunden.");
                string key = PackageReader.P(input.Properties, "PivotKeyValue");
                if (key == "") { if (pass.ContainsKey(outputColumn)) throw new DebugFault("invalid_lineage", "Unpivot-Passthrough ist doppelt."); pass.Add(outputColumn, input); }
                else
                {
                    Dictionary<Column, Column> group;
                    if (!groups.TryGetValue(key, out group)) groups.Add(key, group = new Dictionary<Column, Column>());
                    if (group.ContainsKey(outputColumn)) throw new DebugFault("invalid_lineage", "Unpivot-Mapping ist doppelt.");
                    group.Add(outputColumn, input);
                }
            }
            var values = port.Columns.Where(c => c != pivot[0] && !pass.ContainsKey(c)).ToList();
            if (groups.Count == 0 || values.Count == 0 || groups.Values.Any(g => g.Count != values.Count || values.Any(c => !g.ContainsKey(c))))
                throw new DebugFault("invalid_lineage", "Unpivot-Schlüsselgruppen sind unvollständig.");
            var rows = new List<string>(); int ordinal = 0;
            foreach (var group in groups)
            {
                var fields = new List<string> { (ordinal++).ToString(CultureInfo.InvariantCulture), "CAST(" + Util.L(group.Key) + " AS " + pivot[0].SqlType + ")" };
                fields.AddRange(values.Select(c => "CAST(m." + Util.Q(Find(parent, group.Value[c].Lineage).Alias) + " AS " + c.SqlType + ")"));
                rows.Add("(" + String.Join(",", fields) + ")");
            }
            var select = new List<string>();
            foreach (var outputColumn in port.Columns)
            {
                var col = NewColumn(outputColumn.Lineage == "" ? outputColumn.Id : outputColumn.Lineage, outputColumn.Name, outputColumn.SqlType, true); stage.Columns.Add(col);
                string expression = outputColumn == pivot[0] ? "u.[PivotKey]" : pass.ContainsKey(outputColumn) ? "CAST(m." + Util.Q(Find(parent, pass[outputColumn].Lineage).Alias) + " AS " + col.Type + ")" : "u." + Util.Q("Value" + values.IndexOf(outputColumn));
                select.Add(expression + " AS " + Util.Q(col.Alias));
            }
            var aliases = new[] { "[Ordinal]", "[PivotKey]" }.Concat(values.Select((c, i) => Util.Q("Value" + i)));
            var present = values.Select((c, i) => "u." + Util.Q("Value" + i) + " IS NOT NULL");
            var inputs = groups.Values.SelectMany(g => g.Values).Select(c => "CONVERT(nvarchar(max), m." + Util.Q(Find(parent, c.Lineage).Alias) + ")").Distinct().ToList();
            string allNull = inputs.Count == 1 ? inputs[0] : "COALESCE(" + String.Join(",", inputs) + ")";
            stage.Query = "SELECT " + String.Join(",", select) + " FROM " + Util.Q(parent.Cte) + " AS m CROSS APPLY (VALUES " + String.Join(",", rows) + ") AS u(" + String.Join(",", aliases) + ") WHERE (" + String.Join(" OR ", present) + ") OR (u.[Ordinal]=0 AND " + allNull + " IS NULL)";
            output.Diagnostic("unpivot_preview", component.Id, "Unpivot-Schlüssel und Werte aus dem Paket rekonstruiert; reine NULL-Gruppen entfallen, bei vollständig NULL-Eingaben bleibt eine Vorschauzeile. Keine SSIS-Runtime-Parität behauptet.");
        }
        private void Union(Flow flow, Component c, Port port, Stage stage)
        {
            foreach (Column outputColumn in port.Columns) stage.Columns.Add(NewColumn(outputColumn.Lineage == "" ? outputColumn.Id : outputColumn.Lineage, outputColumn.Name, outputColumn.SqlType, false));
            var branches = new List<string>();
            var inputs = RequiredPorts(flow, c).ToList();
            for (int i = 0; i < inputs.Count; i++)
            {
                Stage parent = Input(flow, inputs[i]); var fields = new List<string>();
                foreach (StageColumn target in stage.Columns)
                {
                    var matches = inputs[i].Columns.Where(x => PackageReader.P(x.Properties, "OutputColumnLineageID") == target.Id).ToList();
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
        private Dictionary<string, ExpressionValue> ExpressionColumns(Stage parent, Component component)
        {
            var cols = new Dictionary<string, ExpressionValue>(StringComparer.Ordinal); var duplicateNames = new HashSet<string>(StringComparer.Ordinal);
            foreach (StageColumn c in parent.Columns)
            {
                var value = new ExpressionValue { Sql = "m." + Util.Q(c.Alias), Type = c.Type, Nullable = c.Nullable, Total = bindings.ComponentsV2 };
                cols[c.Id] = value; if (!c.Id.StartsWith("#", StringComparison.Ordinal)) cols["#" + c.Id] = value;
                if (cols.ContainsKey(c.Name)) duplicateNames.Add(c.Name); else cols.Add(c.Name, value);
            }
            foreach (string name in duplicateNames) cols.Remove(name);
            // Der Komponenten-Eingang bindet Namen an konkrete Lineage-IDs.
            // Andere gleichnamige Spalten des Upstream-Flusses machen diesen
            // ausdrücklich ausgewählten Eingang nicht mehrdeutig.
            foreach (var group in component.Inputs.SelectMany(p => p.Columns).GroupBy(c => c.Name, StringComparer.Ordinal))
            {
                if (group.Select(c => c.Lineage).Distinct(StringComparer.Ordinal).Count() != 1) { cols.Remove(group.Key); continue; }
                var selected = Find(parent, group.First().Lineage);
                cols[group.Key] = new ExpressionValue { Sql = "m." + Util.Q(selected.Alias), Type = selected.Type, Nullable = selected.Nullable, Total = bindings.ComponentsV2 };
            }
            return cols;
        }
        private ExpressionValue Expression(string expression, Component c, Stage parent, Stage stage)
        { var result = new ExpressionParser(expression, package, c.Scope, ExpressionColumns(parent, c), bindings.Resolve, bindings.ComponentsV2, bindings.CollationForCodePage, bindings.Limits).Parse(); stage.Inputs.UnionWith(result.Inputs); return result; }
        private void Derived(Component c, Port port, Stage stage)
        {
            if (stage.Parents.Count != 1 || c.Inputs.Count != 1) throw new DebugFault("unsupported_component", "Transformation benötigt einen Eingang.");
            Stage parent = stage.Parents[0]; Stage originalParent = parent; var projections = parent.Columns.ToDictionary(x => x.Id, x => "m." + Util.Q(x.Alias), StringComparer.Ordinal);
            var existing = parent.Columns.ToDictionary(x => x.Id, x => x, StringComparer.Ordinal);
            var replacements = new Dictionary<string, StageColumn>(StringComparer.Ordinal);
            foreach (Column input in c.Inputs[0].Columns)
            {
                string expr = PackageReader.P(input.Properties, "Expression"); if (expr == "") continue;
                var old = Find(originalParent, input.Lineage); var value = Expression(expr, c, parent, stage);
                if (value.BooleanTerms != null && (value.BooleanTerms.Count > 16 || !value.Total)) { value = LowerBooleanChain(value, c, ref parent); stage.Parents.Clear(); Inherit(stage, parent); }
                projections[old.Id] = "CAST(" + value.Sql + " AS " + old.Type + ")";
                replacements.Add(old.Id, NewColumn(old.Id, old.Name, old.Type, value.Nullable));
            }
            foreach (StageColumn col in originalParent.Columns) stage.Columns.Add(replacements.ContainsKey(col.Id) ? replacements[col.Id] : col);
            foreach (Column col in port.Columns)
            {
                string expr = PackageReader.P(col.Properties, "Expression"); ExpressionValue value;
                if (c.Kind == "convert")
                { string source = PackageReader.P(col.Properties, "SourceInputColumnLineageID"); var old = Find(parent, source); value = new ExpressionValue { Sql = "m." + Util.Q(old.Alias), Type = old.Type, Nullable = old.Nullable }; }
                else value = Expression(expr, c, parent, stage);
                if (value.DeferredBooleanCondition != null)
                {
                    ExpressionValue loweredCondition = LowerBooleanChain(value.DeferredBooleanCondition, c, ref parent);
                    string condition = loweredCondition.Condition;
                    value.Sql = "CASE WHEN " + condition + " THEN " + value.DeferredConditionalTrue + " WHEN NOT (" + condition + ") THEN " + value.DeferredConditionalFalse + " ELSE CAST(NULL AS " + value.DeferredConditionalType + ") END";
                    value.DeferredBooleanCondition = null;
                    stage.Parents.Clear(); Inherit(stage, parent);
                }
                if (value.BooleanTerms != null && (value.BooleanTerms.Count > 16 || !value.Total)) { value = LowerBooleanChain(value, c, ref parent); stage.Parents.Clear(); Inherit(stage, parent); }
                var target = NewColumn(col.Lineage == "" ? col.Id : col.Lineage, col.Name, col.SqlType, value.Nullable);
                if (existing.ContainsKey(target.Id)) throw new DebugFault("invalid_lineage", "Neue Spaltenversion kollidiert.");
                stage.Columns.Add(target); projections.Add(target.Id, "CAST(" + value.Sql + " AS " + target.Type + ")");
            }
            var projectedColumns = options.CatalogMode == "package"
                ? stage.Columns.Where(x => !originalParent.Columns.Any(old => old.Alias == x.Alias)) : stage.Columns;
            var fields = projectedColumns.Select(x => projections[x.Id] + " AS " + Util.Q(x.Alias)).ToList();
            if (options.CatalogMode == "package") fields.Insert(0, "m.*");
            stage.Query = "SELECT " + String.Join(", ", fields) + " FROM " + Util.Q(parent.Cte) + " AS m";
        }
        private void CopyColumn(Component c, Port port, Stage stage)
        {
            // Die Einzelfreigabe umfasst nur Debug-SQL. Der gemeinsame
            // Stagebuilder darf die Komponente nicht stillschweigend auch
            // für die getrennte Prozedurdefinition zulassen.
            if (options.ProcedureDefinition)
                throw new DebugFault("procedure_profile", "Copy Column V1 ist ausschließlich für explain freigegeben.");
            if (stage.Parents.Count != 1 || c.Inputs.Count != 1 || c.Outputs.Count != 1 || c.Outputs[0].Error || port.Id != c.Outputs[0].Id || port.Sync != c.Inputs[0].Id)
                throw new DebugFault("unsupported_component", "Copy Column benötigt genau einen synchronen Eingang und einen normalen Ausgang ohne Fehlerausgang.");

            Stage parent = stage.Parents[0];
            var sourceLineages = c.Inputs[0].Columns.GroupBy(x => x.Lineage, StringComparer.Ordinal).ToDictionary(g => g.Key, g => g.ToList(), StringComparer.Ordinal);
            // Auch unkopierte Eingabespalten gehören zur deklarierten Portform.
            // Doppelte Bindungen werden nicht durch die Auswahl einer anderen
            // Kopie verdeckt; die tatsächliche Quelle bleibt der Parentstage.
            if (sourceLineages.Any(g => g.Value.Count != 1))
                throw new DebugFault("invalid_lineage", "Copy Column-Eingangs-Lineage ist doppelt deklariert.");
            var outputNames = new HashSet<string>(parent.Columns.Select(x => x.Name), StringComparer.OrdinalIgnoreCase);
            var outputIds = new HashSet<string>(parent.Columns.Select(x => x.Id), StringComparer.Ordinal);
            var fields = new List<string>();
            foreach (StageColumn source in parent.Columns)
            {
                stage.Columns.Add(source);
                fields.Add("m." + Util.Q(source.Alias) + " AS " + Util.Q(source.Alias));
            }

            foreach (Column copy in port.Columns)
            {
                string sourceId = PackageReader.P(copy.Properties, "copyColumnId");
                int parsedSourceId;
                if (sourceId == "" || !Int32.TryParse(sourceId, NumberStyles.None, CultureInfo.InvariantCulture, out parsedSourceId) || parsedSourceId <= 0 || sourceId != parsedSourceId.ToString(CultureInfo.InvariantCulture))
                    throw new DebugFault("invalid_lineage", "Copy Column copyColumnId fehlt oder ist keine positive Lineage-ID.");
                List<Column> selected;
                if (!sourceLineages.TryGetValue(sourceId, out selected) || selected.Count != 1)
                    throw new DebugFault("invalid_lineage", "Copy Column-Quelle ist nicht eindeutig als Eingangsspalte gebunden.");
                StageColumn input = Find(parent, sourceId);
                string outputId = copy.Lineage;
                int parsedOutputId;
                if (outputId == "" || !Int32.TryParse(outputId, NumberStyles.None, CultureInfo.InvariantCulture, out parsedOutputId) || parsedOutputId <= 0 || outputId != parsedOutputId.ToString(CultureInfo.InvariantCulture) || !outputIds.Add(outputId))
                    throw new DebugFault("invalid_lineage", "Copy Column-Ausgabe-Lineage fehlt, ist ungültig oder kollidiert mit einer vorhandenen Spalte.");
                if (copy.Name == "" || !outputNames.Add(copy.Name))
                    throw new DebugFault("invalid_lineage", "Copy Column-Ausgabename fehlt oder kollidiert case-insensitiv mit einer vorhandenen Spalte.");
                if (copy.SqlType == null || copy.SqlType != input.Type || selected[0].SqlType != input.Type || copy.CodePage != selected[0].CodePage)
                    throw new DebugFault("unsupported_component", "Copy Column-Ausgabetyp stimmt nicht exakt mit dem gebundenen Eingangstyp überein.");
                // Übereinstimmende XML-Ports beweisen keine ANSI-Identität:
                // beide können dieselbe falsche Codepage deklarieren. Die
                // tatsächliche Encodinggrenze folgt der aufgelösten Quelle.
                if (selected[0].Type == "str" && (selected[0].CodePage <= 0 || !input.SourceCodePage.HasValue || input.SourceCodePage.Value != selected[0].CodePage))
                    throw new DebugFault("unsupported_component", "Copy Column-ANSI-Codepage stimmt nicht mit der aufgelösten Quellcollation überein.");

                StageColumn outputColumn = NewColumn(outputId, copy.Name, input.Type, input.Nullable);
                outputColumn.Collation = input.Collation;
                outputColumn.SourceCodePage = input.SourceCodePage;
                stage.Columns.Add(outputColumn);
                fields.Add("m." + Util.Q(input.Alias) + " AS " + Util.Q(outputColumn.Alias));
            }
            if (port.Columns.Count == 0) throw new DebugFault("invalid_lineage", "Copy Column-Ausgabespalten fehlen.");
            stage.Query = "SELECT " + String.Join(", ", fields) + " FROM " + Util.Q(parent.Cte) + " AS m";
        }
        private ExpressionValue LowerBooleanChain(ExpressionValue value, Component component, ref Stage parent)
        {
            if (!bindings.ComponentsV2 || (value.BooleanOperator != "&&" && value.BooleanOperator != "||") || value.BooleanTerms == null || value.BooleanTerms.Any(t => t.Type != "bit"))
                throw new DebugFault("unsupported_expression", "Ausdruck ist nicht als typisierter Boolean-Plan beweisbar.");
            if (!value.Total && value.BooleanTerms.Any(t => !t.Total && t.BooleanTerms != null))
                throw new DebugFault("unsupported_expression", "Verschachtelte potenziell fehlernde Boolean-Verknüpfung benötigt eine nicht belegte SSIS-Fehlerreihenfolge.");
            var baseColumns = parent.Columns.Where(c => !c.Id.StartsWith("v2-boolean-", StringComparison.Ordinal)).ToList(); Stage current = parent; StageColumn accumulator = null;
            int termsPerUnit = value.Total ? (value.BooleanTerms.Any(t => t.BooleanTerms != null) ? 4 : 16) : 1;
            for (int start = 0; start < value.BooleanTerms.Count; start += termsPerUnit)
            {
                bindings.Limits.Check("planUnits", stages.Count + ++nextSyntheticStage);
                var terms = value.BooleanTerms.Skip(start).Take(termsPerUnit).ToList();
                string predicate;
                if (value.Total)
                {
                    predicate = "(" + String.Join(value.BooleanOperator == "&&" ? " AND " : " OR ", terms.Select(BranchCondition)) + ")";
                    if (accumulator != null) predicate = "(m." + Util.Q(accumulator.Alias) + (value.BooleanOperator == "&&" ? " = 1 AND " : " = 1 OR ") + predicate + ")";
                    predicate = "CASE WHEN " + predicate + " THEN CAST(1 AS bit) WHEN NOT (" + predicate + ") THEN CAST(0 AS bit) ELSE CAST(NULL AS bit) END";
                }
                else
                {
                    string left = accumulator == null ? null : "m." + Util.Q(accumulator.Alias);
                    foreach (ExpressionValue term in terms) left = left == null ? BooleanTruth(BranchCondition(term)) : BooleanFold(left, BranchCondition(term), value.BooleanOperator);
                    predicate = left;
                }
                string alias = Util.Id("b", nextSyntheticStage);
                var column = new StageColumn { Id = "v2-boolean-" + component.Id + "-" + nextSyntheticStage.ToString(CultureInfo.InvariantCulture), Name = "V2BooleanUnit_" + nextSyntheticStage.ToString(CultureInfo.InvariantCulture), Alias = alias, Type = "bit", Nullable = terms.Any(t => t.Nullable) || accumulator != null && accumulator.Nullable };
                var next = new Stage { Id = "v" + nextSyntheticStage.ToString("D6", CultureInfo.InvariantCulture), Cte = "v2_" + nextSyntheticStage.ToString("D6", CultureInfo.InvariantCulture), Component = component.Id };
                next.Parents.Add(current); next.Inputs.UnionWith(current.Inputs); next.Columns.AddRange(baseColumns); next.Columns.Add(column);
                next.Query = "SELECT " + (options.CatalogMode == "package" ? "m.*" : FieldsBy(baseColumns, "m")) + ", " + predicate + " AS " + Util.Q(column.Alias) + " FROM " + Util.Q(current.Cte) + " AS m";
                current = next; accumulator = column;
            }
            parent = current;
            var lowered = new ExpressionValue { Sql = "m." + Util.Q(accumulator.Alias), Type = "bit", Nullable = value.Nullable, Total = true };
            lowered.Inputs.UnionWith(value.Inputs); return lowered;
        }
        private static string BooleanTruth(string term)
        { return "CASE WHEN " + term + " THEN CAST(1 AS bit) WHEN NOT (" + term + ") THEN CAST(0 AS bit) ELSE CAST(NULL AS bit) END"; }
        private static string BranchCondition(ExpressionValue value)
        {
            if (value.BooleanTerms == null || value.BooleanTerms.Count == 0) return value.Condition;
            if (value.Total) return value.Condition;
            if (value.BooleanTerms.Count > 4) throw new DebugFault("unsupported_expression", "Verschachtelte Boolean-Gruppe ist für eine sichere Einzelunit zu groß.");
            string result = BranchCondition(value.BooleanTerms[0]);
            for (int i = 1; i < value.BooleanTerms.Count; i++) result = BooleanFold(result, BranchCondition(value.BooleanTerms[i]), value.BooleanOperator);
            return "(" + result + " = CAST(1 AS bit))";
        }
        private static string BooleanFold(string left, string right, string op)
        {
            if (op == "&&") return "CASE WHEN " + left + " = CAST(0 AS bit) THEN CAST(0 AS bit) WHEN " + left + " = CAST(1 AS bit) THEN " + BooleanTruth(right) + " ELSE CASE WHEN NOT (" + right + ") THEN CAST(0 AS bit) ELSE CAST(NULL AS bit) END END";
            return "CASE WHEN " + left + " = CAST(1 AS bit) THEN CAST(1 AS bit) WHEN " + left + " = CAST(0 AS bit) THEN " + BooleanTruth(right) + " ELSE CASE WHEN " + right + " THEN CAST(1 AS bit) ELSE CAST(NULL AS bit) END END";
        }
        private static string FieldsBy(IEnumerable<StageColumn> columns, string alias) { return String.Join(", ", columns.Select(c => alias + "." + Util.Q(c.Alias) + " AS " + Util.Q(c.Alias))); }
        private void Split(Component c, Port selected, Stage stage)
        {
            if (stage.Parents.Count != 1) throw new DebugFault("unsupported_component", "Split benötigt einen Eingang.");
            Stage parent = stage.Parents[0]; var branches = new List<KeyValuePair<int, ExpressionValue>>(); int selectedOrder = -1, defaultOrder = -1; bool nullFailure = false;
            foreach (Port p in c.Outputs.Where(x => !x.Error))
            {
                int order;
                bool isDefault = Util.Flag(PackageReader.P(p.Properties, "IsDefaultOut"));
                string rawOrder = PackageReader.P(p.Properties, "EvaluationOrder");
                if (isDefault && rawOrder == "") order = Int32.MaxValue;
                else if (!Int32.TryParse(rawOrder, NumberStyles.None, CultureInfo.InvariantCulture, out order) || order < 0) throw new DebugFault("ambiguous_path", "Splitpriorität fehlt.");
                if (p.Id == selected.Id) selectedOrder = order;
                if (isDefault) { if (defaultOrder >= 0) throw new DebugFault("ambiguous_path", "Mehrere Defaultausgänge."); defaultOrder = order; continue; }
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
            if (nullFailure && options.CatalogMode != "package") throw new DebugFault("split_null_disposition", "Möglicher NULL-Fehler blockiert Routing; Bedingungsansicht " + conditions.Id + " bleibt prüfbar.");
            if (nullFailure && options.CatalogMode == "package") output.Diagnostic("split_null_preview", c.Id, "NULL-Bedingungen sind in der Bedingungs-CTE sichtbar; die lokale Vorschau verwendet den Defaultzweig statt einen SSIS-Paketabbruch zu simulieren.");
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
            if (lookupCaches.TryGetValue(c.Id, out savedCache))
            {
                stage.Caches.Add(savedCache); stage.Inputs.UnionWith(savedCache.Inputs);
                ProcedureDataset dataset; if (procedureDatasets.TryGetValue(c.Id, out dataset) && !stage.Procedures.Contains(dataset)) stage.Procedures.Add(dataset);
                RenderLookupJoin(c, port, stage, parent, savedCache, keys, mode, noMatch); if (mode == "0") LookupMatchView(c, stage, parent); return;
            }
            SqlQuery query = Query(c, stage); List<BoundColumn> reference = Projection.Columns(query, safety);
            string suffix = runToken + "_" + lookupIds[c.Id];
            var cache = new LookupCache { Name = "#tbx_SsisDebug_L_" + suffix, StateName = "#tbx_SsisDebug_S_" + suffix,
                PreserveTextKeyLength = options.CatalogMode == "package" && PackageReader.P(c.Properties, "CacheType", "0") == "0" };
            if (options.CatalogMode == "package") cache.Name = "lookup_reference_" + lookupIds[c.Id];
            cache.Inputs.UnionWith(stage.ReferenceInputs);
            var projections = new List<string>(); var partitions = new List<string>(); int ordinal = 0;
            foreach (Column key in keys)
            {
                StageColumn left = Find(parent, key.Lineage); string name = ReferenceName(c, PackageReader.P(key.Properties, "JoinToReferenceColumn")); BoundColumn right = reference.SingleOrDefault(x => x.Name == name);
                if (right == null) throw new DebugFault("invalid_lineage", "Lookup-Referenzschlüssel fehlt.");
                ValidateCodePage(key, right.Collation);
                string alias = Util.Id("k", ++ordinal), normalized = Normalize("ref." + Util.Q(name), left.Type);
                cache.Columns.Add(new StageColumn { Alias = alias, Name = alias, Id = key.Id, Type = left.Type, Nullable = true, Collation = bindings.Collation });
                projections.Add(normalized + " AS " + Util.Q(alias)); partitions.Add(normalized);
                if (cache.PreserveTextKeyLength && TextType(left.Type)) partitions.Add("DATALENGTH(" + normalized + ")");
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
            cache.PreviewCtes.AddRange(ctes);
            cache.PreviewQuery = "SELECT " + columns + " FROM (" + ranked + ") AS ranked WHERE [tbx_rn] = 1";
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
            if (options.CatalogMode == "package")
            {
                output.Diagnostic("lookup_failure_condition", c.Id, "Lookup ist im Paket auf Fehler bei fehlendem Treffer eingestellt. Die lokale CTE-Vorschau zeigt den Matchpfad; keine Simulation des Paketabbruchs.");
                return;
            }
            string key = "lookup-match:" + c.Id; Stage matches;
            if (!stages.TryGetValue(key, out matches))
            { matches = New(c.Id, "lookup_matches", key); Inherit(matches, parent); matches.Query = stage.Query; matches.Columns.AddRange(stage.Columns); matches.Inputs.UnionWith(stage.Inputs); matches.Caches.AddRange(stage.Caches.Where(x => !matches.Caches.Contains(x))); stages.Add(key, matches); }
            Inherit(stage, matches); Block(stage, new DebugFault("unsupported_component", "Lookup-Fail-Disposition bleibt blockiert; Matchansicht " + matches.Id + " ist prüfbar."));
        }
        private void RenderLookupJoin(Component c, Port port, Stage stage, Stage parent, LookupCache cache, List<Column> keys, string mode, bool noMatch)
        {
            var joins = new List<string>();
            foreach (Column key in keys)
            {
                StageColumn left = Find(parent, key.Lineage);
                StageColumn right = cache.Columns.Single(x => x.Id == key.Id && x.Alias.StartsWith("k", StringComparison.Ordinal));
                string source = Normalize("m." + Util.Q(left.Alias), left.Type), reference = "lk." + Util.Q(right.Alias);
                joins.Add(source + " = " + reference);
                // SQL equality pads strings with spaces even under BIN2. Keep the
                // same text-and-length tuple for lookup ranking and matching.
                if (cache.PreserveTextKeyLength && TextType(left.Type))
                    joins.Add("DATALENGTH(" + source + ") = DATALENGTH(" + reference + ")");
            }
            stage.Columns.AddRange(parent.Columns); var fields = parent.Columns.Select(x => "m." + Util.Q(x.Alias) + " AS " + Util.Q(x.Alias)).ToList();
            var refAliases = cache.Columns.Where(x => x.Name != null && x.Alias.StartsWith("r", StringComparison.Ordinal)).ToDictionary(x => x.Name, x => x, StringComparer.Ordinal);
            if (options.CatalogMode == "package")
                fields = new List<string> { "m.*" };
            foreach (Column col in c.Inputs.SelectMany(p => p.Columns).Where(x => PackageReader.P(x.Properties, "CopyFromReferenceColumn") != ""))
            {
                StageColumn previous = Find(parent, col.Lineage), replacement;
                if (!refAliases.TryGetValue(ReferenceName(c, PackageReader.P(col.Properties, "CopyFromReferenceColumn")), out replacement)) throw new DebugFault("invalid_lineage", "Lookup-Ersetzung nicht gebunden.");
                var changed = NewColumn(previous.Id, previous.Name, previous.Type, true); int index = stage.Columns.IndexOf(previous); stage.Columns[index] = changed;
                string field = "CAST(lk." + Util.Q(replacement.Alias) + " AS " + changed.Type + ") AS " + Util.Q(changed.Alias);
                if (options.CatalogMode == "package") fields.Add(field); else fields[index] = field;
            }
            foreach (Column col in port.Columns)
            {
                string name = ReferenceName(c, PackageReader.P(col.Properties, "CopyFromReferenceColumn")); StageColumn refCol;
                if (!refAliases.TryGetValue(name, out refCol)) throw new DebugFault("invalid_lineage", "Lookup-Payloadmapping fehlt.");
                var outputCol = NewColumn(col.Lineage == "" ? col.Id : col.Lineage, col.Name, col.SqlType, true); stage.Columns.Add(outputCol);
                fields.Add("CAST(lk." + Util.Q(refCol.Alias) + " AS " + outputCol.Type + ") AS " + Util.Q(outputCol.Alias));
            }
            stage.Query = "SELECT " + String.Join(", ", fields) + " FROM " + Util.Q(parent.Cte) + " AS m " + (mode == "1" || noMatch ? "LEFT JOIN " : "INNER JOIN ") + Util.Q(cache.Name) + " AS lk" + (options.CatalogMode == "package" ? "" : " WITH (NOLOCK)") + " ON " + String.Join(" AND ", joins) + (noMatch ? " WHERE lk.[tbx_match] IS NULL" : "");
        }
        private string EmitPackagePreview(Stage end, string kind, string target)
        {
            var ancestors = Ancestors(end);
            var keys = new HashSet<string>(ancestors.SelectMany(s => s.Inputs), StringComparer.Ordinal);
            var snapshots = new Dictionary<Stage, string>(); var preparation = new StringBuilder();
            var temps = new List<string>();
            foreach (var procedure in ancestors.SelectMany(s => s.Procedures).Distinct())
            {
                if (procedure.Input != null && !snapshots.ContainsKey(procedure.Input))
                {
                    string inputName = procedure.Name + "_input";
                    preparation.Append(CreatePreviewTemp(inputName, procedure.Input.Columns.Select(c => new BoundColumn { Name = c.Alias, SqlType = c.Type }).ToList(), temps));
                    preparation.Append(";WITH " + PreviewCtes(procedure.Input, snapshots) + "\nINSERT INTO " + Util.Q(inputName) + " SELECT " + String.Join(",", procedure.Input.Columns.Select(c => "d." + Util.Q(c.Alias))) + " FROM " + Util.Q(procedure.Input.Cte) + " AS d;\n");
                    snapshots.Add(procedure.Input, inputName);
                }
                preparation.Append(CreatePreviewTemp(procedure.Name, procedure.Columns, temps));
                preparation.Append("INSERT INTO " + Util.Q(procedure.Name) + " (" + String.Join(",", procedure.Columns.Select(c => Util.Q(c.Name))) + ") " + procedure.Call + "\n");
            }
            string sql = "-- Lokaler Paketentwurf; Variablen anpassen, letzten SELECT auf die gewünschte CTE setzen.\n" + bindings.Declarations(keys) + "\n" +
                String.Join("\n", ancestors.SelectMany(s => s.StructureGuards).Distinct()) + "\n";
            for (int i = 0; i < temps.Count; i++) sql += "DECLARE @tbx_preview_own" + i + " bit=0;\n";
            if (temps.Count != 0) sql += "-- Die folgenden Original-Prozeduraufrufe werden erst beim manuellen Ausführen ausgeführt.\nBEGIN TRY\n" + preparation;
            sql += ";WITH " + PreviewCtes(end, snapshots) + "\nSELECT " + String.Join(", ", end.Columns.Select(c => "d." + Util.Q(c.Alias) + " AS " + Util.Q(c.Name))) + " FROM " + Util.Q(end.Cte) + " AS d;";
            if (temps.Count != 0)
            {
                string cleanup = String.Join("\n", temps.Select((name, i) => "IF @tbx_preview_own" + i + "=1 AND OBJECT_ID(" + Util.L("tempdb.." + name) + ",N'U') IS NOT NULL DROP TABLE " + Util.Q(name) + ";").Reverse());
                sql += "\n" + cleanup + "\nEND TRY\nBEGIN CATCH\n" + cleanup + "\nTHROW;\nEND CATCH;";
            }
            safety.CheckPackageComposition(sql);
            output.Add(new Artifact { Kind = kind, Target = target, Stage = end.Id, Component = end.Component, Content = sql, Complete = true, Safety = "not_checked", Executable = false, Evidence = "pragmatic" });
            return sql;
        }
        private static string CreatePreviewTemp(string name, List<BoundColumn> columns, List<string> temps)
        {
            int id = temps.Count; temps.Add(name);
            return "IF OBJECT_ID(" + Util.L("tempdb.." + name) + ",N'U') IS NOT NULL THROW 50000,'TBX_SSISDBG_preview_temp_exists',1;\nCREATE TABLE " + Util.Q(name) + " (" + String.Join(",", columns.Select(c => Util.Q(c.Name) + " " + c.SqlType + " NULL")) + ");\nSET @tbx_preview_own" + id + "=1;\n";
        }
        private string PreviewCtes(Stage end, Dictionary<Stage, string> snapshots)
        {
            var ancestors = Ancestors(end);
            var ctes = new List<KeyValuePair<string, string>>();
            foreach (var cache in ancestors.SelectMany(s => s.Caches).Distinct())
            { ctes.AddRange(cache.PreviewCtes); ctes.Add(new KeyValuePair<string, string>(Util.Q(cache.Name), cache.PreviewQuery)); }
            foreach (var stage in ancestors)
            {
                ctes.AddRange(stage.ExtraCtes);
                string label = stage.Component.Replace("\r", " ").Replace("\n", " ");
                string snapshot;
                string query = snapshots.TryGetValue(stage, out snapshot) ? "SELECT * FROM " + Util.Q(snapshot) : stage.Query;
                ctes.Add(new KeyValuePair<string, string>(Util.Q(stage.Cte), "-- " + stage.Id + ": " + label + "\n" + query));
            }
            if (ctes.Select(c => c.Key).Distinct(StringComparer.Ordinal).Count() != ctes.Count) throw new DebugFault("invalid_lineage", "CTE-Name ist nicht eindeutig.");
            return String.Join(",\n", ctes.Select(c => c.Key + " AS (\n" + c.Value + "\n)"));
        }
        private static string ReferenceName(Component c, string id)
        {
            var match = c.Inputs.SelectMany(p => p.External).Concat(c.Outputs.SelectMany(p => p.External)).SingleOrDefault(x => x.Id == id);
            return match == null ? id : match.Name;
        }
        private static bool TextType(string type) { return type.StartsWith("nvarchar", StringComparison.Ordinal) || type.StartsWith("varchar", StringComparison.Ordinal) || type.StartsWith("nchar", StringComparison.Ordinal) || type.StartsWith("char", StringComparison.Ordinal); }
        private string Normalize(string expression, string type) { return "CAST(" + expression + " AS " + type + ")" + (TextType(type) ? " COLLATE " + Util.CollationToken(bindings.Collation) : ""); }
        private string Fields(Stage stage, string alias) { return options.CatalogMode == "package" ? alias + ".*" : String.Join(", ", stage.Columns.Select(c => alias + "." + Util.Q(c.Alias))); }
        private static List<Stage> Ancestors(Stage stage)
        {
            var result = new List<Stage>(); var seen = new HashSet<Stage>(); var pending = new Stack<KeyValuePair<Stage, bool>>(); pending.Push(new KeyValuePair<Stage, bool>(stage, false));
            while (pending.Count != 0)
            {
                var frame = pending.Pop();
                if (frame.Value) { result.Add(frame.Key); continue; }
                if (!seen.Add(frame.Key)) continue;
                pending.Push(new KeyValuePair<Stage, bool>(frame.Key, true));
                for (int i = frame.Key.Parents.Count - 1; i >= 0; i--) pending.Push(new KeyValuePair<Stage, bool>(frame.Key.Parents[i], false));
            }
            return result;
        }
        private void EmitDebugScript(string target, Stage end, List<Stage> ancestors)
        {
            if (end.Error != null)
            {
                if (bindings.ComponentsV2)
                {
                    Stage available = ancestors.LastOrDefault(s => s.Error == null);
                    if (available != null) Emit(available, "StageSql", target);
                }
                var missing = package.Inputs.Where(input => input.Required && !input.Sensitive &&
                    !bindings.Values.ContainsKey(input.Key) && (input.Expression != null || input.RuntimeAssigned || !input.HasDefault))
                    .Select(input => (object)Json.Obj("key", input.Key, "name", input.Name, "state", input.AssignmentState == "unknown" ? "assignment-unknown" : input.Expression != null ? "expression-context-required" : input.RuntimeAssigned ? "runtime-value-required" : "value-required")).ToList();
                if (package.Inputs.Any(input => input.Required && input.Sensitive && !bindings.Values.ContainsKey(input.Key))) missing.Add(Json.Obj("state", "sensitive-input-required", "nameRedacted", true));
                var rootCause = Json.Obj("code", end.RootCauseCode ?? end.Error, "stageId", end.RootCauseStage ?? end.Id,
                    "componentId", end.RootCauseComponent ?? end.Component, "message", end.RootCauseText ?? end.ErrorText);
                var availableStages = output.Rows.Where(a => a.Target == target && a.Kind == "StageSql" && a.Executable && a.Safety == "passed").Select(a => a.Stage).Distinct(StringComparer.Ordinal).ToList();
                output.Add(new Artifact { Kind = "DebugScript", Target = target, Stage = end.Id, Component = end.Component,
                    Content = "-- Nicht ausführbar: Zielpfad ist unvollständig. Vollständiger Pfad und Erstursache stehen in Workflow/StageIndex/Diagnostic; verfügbare Teilpläne sind als StageSql-Artefakte enthalten.",
                    Evidence = "descriptive", Safety = "blocked", Executable = false, Complete = false,
                    Details = Json.Write(Json.Obj("status", "incomplete", "rootCause", rootCause, "path", ancestors.Select(s => (object)Json.Obj("stageId", s.Id, "componentId", s.Component, "status", s.Error == null ? "available" : "blocked")).ToList(), "missingInputs", missing, "availableStageArtifacts", availableStages), bindings.Limits) });
                return;
            }
            Artifact manifest = output.Rows.LastOrDefault(a => a.Kind == "PlanManifest" && a.Target == target && a.Stage == end.Id);
            Artifact targetSql = output.Rows.LastOrDefault(a => a.Kind == "TargetSql" && a.Target == target && a.Stage == end.Id);
            if (!bindings.ComponentsV2 || manifest == null || targetSql == null)
            {
                output.Add(new Artifact { Kind = "DebugScript", Target = target, Stage = end.Id, Component = end.Component,
                    Content = "-- Nicht ausführbar: Für dieses Ziel liegt kein vollständig validierter aktueller Plan vor.", Evidence = "descriptive", Safety = "blocked", Executable = false, Complete = false,
                    Details = Json.Write(Json.Obj("status", "incomplete", "reason", "validated-current-plan-required"), bindings.Limits) });
                return;
            }
            Func<Artifact, Dictionary<string, object>> details = a => Json.Object(Json.Parse(a.Details, bindings.Limits));
            string planHash = Json.Text(Json.Get(details(targetSql), "planHash"));
            Func<Artifact, string> hash = a => Json.Text(Json.Get(details(a), "planHash"));
            Func<Artifact, string, int> orderValue = (a, name) => Int32.Parse(((JsonNumber)Json.Get(details(a), name)).Text, CultureInfo.InvariantCulture);
            var units = output.Rows.Where(a => a.Kind == "PlanUnitSql" && a.Target == target && hash(a) == planHash)
                .OrderBy(a => orderValue(a, "ordinal")).ToList();
            var counts = output.Rows.Where(a => a.Kind == "RowCountSql" && a.Target == target && hash(a) == planHash).ToList();
            var cleanup = output.Rows.Where(a => a.Kind == "CleanupSql" && a.Target == target && hash(a) == planHash)
                .OrderBy(a => orderValue(a, "cleanupOrdinal")).ToList();
            var core = units.Concat(new[] { targetSql }).Concat(counts).Concat(cleanup).ToList();
            var referencedTemps = new HashSet<string>(Regex.Matches(String.Join("\n", core.Select(a => a.Content)), @"#tbx_[A-Za-z0-9_]+")
                .Cast<Match>().Select(m => m.Value), StringComparer.Ordinal);
            Func<Artifact, bool> preparationIsRelated = a =>
            {
                if (!String.IsNullOrEmpty(a.Details))
                {
                    object artifactPlanHash = Json.Get(details(a), "planHash");
                    if (artifactPlanHash != null && Json.Text(artifactPlanHash) == planHash) return true;
                }
                return Regex.Matches(a.Content, @"#tbx_[A-Za-z0-9_]+")
                    .Cast<Match>().Any(m => referencedTemps.Contains(m.Value));
            };
            var prepCandidates = output.Rows.Where(a => a.Kind == "PreparationSql" && a.Target == target && preparationIsRelated(a))
                .OrderBy(a => a.Ordinal).ToList();
            var preparation = prepCandidates.Where(a => a.Executable && a.Complete && a.Safety == "passed").ToList();
            var ordered = preparation.Concat(core).ToList();
            int expectedUnitCount = Int32.Parse(((JsonNumber)Json.Get(details(targetSql), "unitCount")).Text, CultureInfo.InvariantCulture);
            bool unitOrderComplete = units.Count == expectedUnitCount && units.Select((a, i) => orderValue(a, "ordinal") == i).All(x => x);
            int expectedCleanupCount = Int32.Parse(((JsonNumber)Json.Get(details(targetSql), "cleanupCount")).Text, CultureInfo.InvariantCulture);
            int expectedRowCountCount = Json.Array(Json.Get(details(targetSql), "rowCountTargets")).Count;
            bool cleanupOrderComplete = cleanup.Count == expectedCleanupCount && cleanup.Select((a, i) => orderValue(a, "cleanupOrdinal") == i &&
                Int32.Parse(((JsonNumber)Json.Get(details(a), "cleanupCount")).Text, CultureInfo.InvariantCulture) == expectedCleanupCount).All(x => x);
            bool readsComplete = counts.Count == expectedRowCountCount;
            bool safe = core.Count > 0 && unitOrderComplete && cleanupOrderComplete && readsComplete && !prepCandidates.Any(a => !a.Executable || !a.Complete || a.Safety != "passed") && ordered.All(a => a.Executable && a.Complete && a.Safety == "passed");
            string script = "-- Neue SQL-Sitzung verwenden. Bei einem Vorbereitungsfehler keine Ergebnislesebatches verwenden; CleanupSql anschließend in derselben Sitzung ausführen.\n-- Keine SSIS-Tasks werden ausgeführt.\n" + String.Join("\nGO\n", ordered.Select(a => a.Content.TrimEnd())) + "\n";
            var batchDetails = ordered.Select((a, index) => (object)Json.Obj("sequence", index + 1, "resultOrdinal", a.Ordinal, "artifactKind", a.Kind, "stageId", a.Stage, "contentSha256", Util.Hash(a.Content))).ToList();
            output.Add(new Artifact { Kind = "DebugScript", Target = target, Stage = end.Id, Component = end.Component, Content = script,
                Evidence = "pragmatic", Safety = safe ? "passed" : "blocked", Executable = safe, Complete = safe,
                Details = Json.Write(Json.Obj("status", safe ? "complete" : "incomplete", "planHash", planHash, "batchOrder", ordered.Select(a => a.Kind + ":" + a.Stage).ToList(), "batches", batchDetails,
                    "freshSessionRequired", true, "cleanupAfterPartialFailure", true, "batchSeparator", "GO", "atomicity", "none", "sssisTasksExecuted", false), bindings.Limits) });
        }
        private void Emit(Stage stage, string kind, string target)
        {
            if (options.CatalogMode == "package") { EmitPackagePreview(stage, kind, target); return; }
            if (bindings.ComponentsV2) { EmitV2Plan(stage, kind, target); return; }
            var chain = Ancestors(stage); var caches = chain.SelectMany(x => x.Caches).Distinct().ToList(); var inputKeys = new HashSet<string>(chain.SelectMany(x => x.Inputs), StringComparer.Ordinal);
            string declarations = "-- Bearbeitbare Szenariowerte; zusammen mit WITH/SELECT ausführen.\n" + bindings.Declarations(inputKeys) + "\n";
            string preparation = String.Join("\n", caches.Select(c => CacheSql.Prepare(c, bindings)));
            string with = ";WITH " + String.Join(",\n", chain.SelectMany(s => s.ExtraCtes).Select(p => p.Key + " AS (" + p.Value + ")").Concat(chain.Select(s => Util.Q(s.Cte) + " AS (\n" + s.Query + "\n)")));
            string select = "SELECT " + String.Join(", ", stage.Columns.Select(c => Util.Q(c.Alias) + " AS " + Util.Q(c.Name))) + " FROM " + Util.Q(stage.Cte) + ";";
            string guards = "IF CONVERT(varbinary(max), DB_NAME()) <> CONVERT(varbinary(max), " + Util.L(bindings.DefaultDatabase) + ") THROW 50000, 'TBX_SSISDBG_cache_context_changed: Falscher Datenbankkontext.', 1;\n" + String.Join("\n", chain.SelectMany(s => s.StructureGuards));
            string sql = declarations + guards + "\n" + preparation + "\n" + with + "\n" + select;
            var owned = caches.SelectMany(c => new[] { c.Name, c.StateName }).ToList(); safety.Generated(sql, bindings.DefaultDatabase, owned, bindings.ComponentsV2);
            bool sharedSnapshotPending = chain.Any(s => s.RowCountVariable != null);
            string projectionDetails = null;
            if (sharedSnapshotPending || stage.FlatFileWriteMetadata != null)
            {
                var detailValues = Json.Obj();
                if (sharedSnapshotPending) detailValues.Add("completenessNote", "RowCount-Zählung ist ein separates COUNT_BIG-Artefakt; keine gemeinsame materialisierte Momentaufnahme mit dieser Projektion.");
                if (stage.FlatFileWriteMetadata != null) { detailValues.Add("targetMode", "flatfile-debug-projection"); detailValues.Add("fileWriteSimulated", false); }
                projectionDetails = Json.Write(detailValues, bindings.Limits);
            }
            output.Add(new Artifact { Kind = kind, Target = target, Stage = stage.Id, Component = stage.Component, Content = sql, Evidence = "pragmatic", Safety = "passed", Executable = true, Complete = !sharedSnapshotPending,
                Details = projectionDetails });
            foreach (Stage countStage in chain.Where(x => x.RowCountVariable != null)) EmitRowCount(countStage, target);
            output.Add(new Artifact { Kind = "ColumnLineage", Target = target, Stage = stage.Id, Component = stage.Component, Content = Json.Write(stage.Columns.Select(c => (object)Json.Obj("name", c.Name, "lineageId", c.Id, "sqlType", c.Type, "sqlAlias", c.Alias)).ToList(), bindings.Limits) });
            if (caches.Count > 0)
            {
                string prep = declarations + guards + "\n" + preparation; safety.Generated(prep, bindings.DefaultDatabase, owned, bindings.ComponentsV2);
                output.Add(new Artifact { Kind = "PreparationSql", Target = target, Stage = stage.Id, Content = prep, Evidence = "pragmatic", Safety = "passed", Executable = true });
                string cleanup = CacheSql.Cleanup(caches, bindings.Collation); safety.Generated(cleanup, bindings.DefaultDatabase, owned);
                output.Add(new Artifact { Kind = "CleanupSql", Target = target, Stage = stage.Id, Content = cleanup, Evidence = "translated", Safety = "passed", Executable = true });
            }
        }
        private void EmitRowCount(Stage stage, string target)
        {
            var chain = Ancestors(stage); var caches = chain.SelectMany(x => x.Caches).Distinct().ToList(); var inputKeys = new HashSet<string>(chain.SelectMany(x => x.Inputs), StringComparer.Ordinal);
            string declarations = "-- Zählwert ist ein Debugergebnis; die SSIS-Variable wird nicht verändert.\n" + bindings.Declarations(inputKeys) + "\n";
            string preparation = String.Join("\n", caches.Select(c => CacheSql.Prepare(c, bindings)));
            string with = ";WITH " + String.Join(",\n", chain.SelectMany(s => s.ExtraCtes).Select(p => p.Key + " AS (" + p.Value + ")").Concat(chain.Select(s => Util.Q(s.Cte) + " AS (\n" + s.Query + "\n)")));
            string guards = "IF CONVERT(varbinary(max), DB_NAME()) <> CONVERT(varbinary(max), " + Util.L(bindings.DefaultDatabase) + ") THROW 50000, 'TBX_SSISDBG_cache_context_changed: Falscher Datenbankkontext.', 1;\n" + String.Join("\n", chain.SelectMany(s => s.StructureGuards));
            string select = "SELECT COUNT_BIG(*) AS [CountValue], CASE WHEN COUNT_BIG(*) BETWEEN " + stage.RowCountMinimum.ToString(CultureInfo.InvariantCulture) + " AND " + stage.RowCountMaximum.ToString(CultureInfo.InvariantCulture) + " THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS [FitsTargetVariable] FROM " + Util.Q(stage.Cte) + ";";
            string sql = declarations + guards + "\n" + preparation + "\n" + with + "\n" + select;
            var owned = caches.SelectMany(c => new[] { c.Name, c.StateName }).ToList(); safety.Generated(sql, bindings.DefaultDatabase, owned, bindings.ComponentsV2);
            output.Add(new Artifact { Kind = "RowCountSql", Target = target, Stage = stage.Id, Component = stage.Component, Content = sql, Evidence = "pragmatic", Safety = "passed", Executable = true, Complete = false,
                Details = Json.Write(Json.Obj("targetVariable", stage.RowCountVariable, "ssisType", stage.RowCountType, "assignmentTiming", "after-last-row", "snapshotSharedWithProjection", false, "warning", "Count and projection are separate executions until a materialized shared debug snapshot is available."), bindings.Limits) });
        }

        private void EmitV2Plan(Stage targetStage, string kind, string target)
        {
            string emittedPlanKey = targetStage.Id + "|" + target;
            if (!emittedV2Plans.Add(emittedPlanKey))
            {
                Artifact prior = output.Rows.LastOrDefault(x => (x.Kind == "StageSql" || x.Kind == "TargetSql") && x.Stage == targetStage.Id && x.Target == target);
                if (prior != null && prior.Kind != kind) output.Add(new Artifact { Kind = kind, Target = target, Stage = prior.Stage, Component = prior.Component, Content = prior.Content, Evidence = prior.Evidence, Safety = prior.Safety, Executable = prior.Executable, Complete = prior.Complete, Details = prior.Details });
                return;
            }
            var chain = Ancestors(targetStage);
            var inputs = new HashSet<string>(chain.SelectMany(s => s.Inputs), StringComparer.Ordinal);
            var lookup = new List<LookupCache>(); var lookupSet = new HashSet<LookupCache>();
            var stageCaches = new Dictionary<Stage, LookupCache>();
            var units = new List<KeyValuePair<Stage, LookupCache>>();
            var cteToTemp = new Dictionary<string, string>(StringComparer.Ordinal);

            foreach (Stage stage in chain)
            {
                foreach (LookupCache c in stage.Caches) if (lookupSet.Add(c)) lookup.Add(c);
                if (stage.Error != null) throw new DebugFault(stage.Error, stage.ErrorText);
                string suffix = runToken + "_" + stage.Id;
                var cache = new LookupCache { Name = "#tbx_SsisDebug_P_" + suffix, StateName = "#tbx_SsisDebug_Q_" + suffix, FreshPerExecution = true };
                foreach (StageColumn column in stage.Columns) cache.Columns.Add(new StageColumn { Id = column.Id, Name = column.Name, Alias = column.Alias, Type = column.Type, Nullable = column.Nullable, Collation = column.Collation });
                cache.Definition = String.Join(", ", cache.Columns.Select(c => Util.Q(c.Alias) + " " + c.Type + (TextType(c.Type) ? " COLLATE " + Util.CollationToken(c.Collation ?? bindings.Collation) : "") + (c.Nullable ? " NULL" : " NOT NULL")));
                cache.Owner = Util.Hash("ssis-components-v2-plan|" + runHash + "|" + stage.Id + "|" + cache.Definition);
                cache.Inputs.UnionWith(stage.Inputs);
                foreach (Stage ancestor in stage.Parents)
                {
                    LookupCache parentCache;
                    if (!stageCaches.TryGetValue(ancestor, out parentCache)) throw new DebugFault("invalid_lineage", "Plan-Parent steht nicht vor seiner abhängigen Unit.");
                    if (!cache.Dependencies.Contains(parentCache)) cache.Dependencies.Add(parentCache);
                }
                foreach (LookupCache lookupCache in stage.Caches) if (!cache.Dependencies.Contains(lookupCache)) cache.Dependencies.Add(lookupCache);
                var allCtes = stage.ExtraCtes.Select(c => c.Key + " AS (" + c.Value + ")").ToList();
                allCtes.Add(Util.Q(stage.Cte) + " AS (" + stage.Query + ")");
                string select = (allCtes.Count == 0 ? "" : ";WITH " + String.Join(",\n", allCtes) + "\n") +
                    "SELECT " + String.Join(", ", stage.Columns.Select(c => Util.Q(c.Alias) + " AS " + Util.Q(c.Alias))) + " FROM " + Util.Q(stage.Cte) + ";";
                var allowedCtes = new HashSet<string>(stage.Parents.Select(s => s.Cte), StringComparer.Ordinal);
                var replacements = cteToTemp.Where(p => allowedCtes.Contains(p.Key)).ToDictionary(p => p.Key, p => p.Value, StringComparer.Ordinal);
                string rewritten;
                try { rewritten = safety.RewriteStageTables(select, replacements); }
                catch (DebugFault error) { throw new DebugFault(error.Code, "StageSELECT " + stage.Id + " UTF16=" + select.Length.ToString(CultureInfo.InvariantCulture) + ": " + error.Message); }
                int finalSelect = rewritten.LastIndexOf("\nSELECT ", StringComparison.Ordinal);
                if (finalSelect < 0) finalSelect = rewritten.StartsWith("SELECT ", StringComparison.Ordinal) ? 0 : -1;
                if (finalSelect < 0) throw new DebugFault("unsafe_statement", "Generierter Stage-SELECT ist nicht kanonisch.");
                string withPrefix = finalSelect == 0 ? "" : rewritten.Substring(0, finalSelect) + "\n";
                string selectTail = rewritten.Substring(finalSelect).Trim().TrimEnd(';');
                cache.Insert = withPrefix + "INSERT INTO " + Util.Q(cache.Name) + " (" + String.Join(", ", cache.Columns.Select(c => Util.Q(c.Alias))) + ")\n" + selectTail + ";";
                cache.FreshPerExecution = true;
                stageCaches.Add(stage, cache); cteToTemp.Add(stage.Cte, cache.Name); units.Add(new KeyValuePair<Stage, LookupCache>(stage, cache));
            }

            ValidateV2Plan(units, stageCaches, targetStage, inputs);
            if (options.ProcedureDefinition)
            {
                ProcedureDefinition.Emit(options, bindings, safety, output, target, targetStage,
                    units.Select(u => u.Value).ToArray(), inputs);
                return;
            }
            var allCaches = lookup.Concat(units.Select(u => u.Value)).Distinct().ToList();
            var owned = allCaches.SelectMany(c => new[] { c.Name, c.StateName }).ToList();
            string planHash = Util.Hash(String.Join("|", units.Select(u => u.Key.Id + ":" + Util.Hash(u.Value.Insert + u.Value.Definition))));
            string planOwner = Util.Hash("ssis-components-v2-state|" + runHash + "|" + runToken + "|" + targetStage.Id + "|" + planHash);
            string planState = "#tbx_SsisDebug_Plan_" + runToken + "_" + targetStage.Id;
            string stateId = "@tbx_ps" + targetStage.Id.Substring(Math.Max(0, targetStage.Id.Length - 5));
            string valuesHash = CacheSql.PlanValuesHash(package.Inputs.Where(i => inputs.Contains(i.Key)));
            string declarations = "-- V2-Plan: jede Einheit bindet Ordinal, Owner, Planhash und Snapshot-Salt.\n" + bindings.Declarations(inputs) + "\n";
            string databaseGuard = "IF CONVERT(varbinary(max), DB_NAME()) <> CONVERT(varbinary(max), " + Util.L(bindings.DefaultDatabase) + ") THROW 50000, 'TBX_SSISDBG_cache_context_changed: Falscher Datenbankkontext.', 1;\n";
            var remainingLookup = new HashSet<LookupCache>(lookup); var availableTemps = new HashSet<string>(StringComparer.Ordinal); int ordinal = 0;
            foreach (var unit in units)
            {
                unit.Value.PlanSaltState = planState; unit.Value.PlanSaltOwner = planOwner; unit.Value.PlanHash = planHash;
                string unitSql = declarations + databaseGuard + String.Join("\n", unit.Key.StructureGuards) + "\n";
                if (ordinal == 0) unitSql += CacheSql.GuardNoTransaction() + CacheSql.PlanStateGuard(planState, planOwner, planHash, valuesHash, null, false, 0, bindings.Collation, true);
                unitSql += "DECLARE " + stateId + " int = OBJECT_ID(" + Util.L("tempdb.." + planState) + ", N'U');\n" + CacheSql.PlanStateGuard(planState, planOwner, planHash, valuesHash, stateId, true, ordinal, bindings.Collation, true);
                foreach (LookupCache c in unit.Key.Caches) if (remainingLookup.Remove(c))
                {
                    c.PlanSaltState = planState; c.PlanSaltOwner = planOwner; c.PlanHash = planHash;
                    unitSql += CacheSql.Prepare(c, bindings);
                    availableTemps.Add(c.Name); availableTemps.Add(c.StateName);
                }
                foreach (LookupCache dependency in unit.Value.Dependencies)
                {
                    if (!availableTemps.Contains(dependency.Name) || !availableTemps.Contains(dependency.StateName))
                        throw new DebugFault("invalid_lineage", "Unit verweist auf eine nicht vorbereitete Vorgängergeneration.");
                }
                unitSql += CacheSql.RequireReady(unit.Value.Dependencies, bindings.Collation, bindings);
                unitSql += CacheSql.Prepare(unit.Value, bindings);
                var cacheClosure = new HashSet<LookupCache>(unit.Value.Dependencies);
                cacheClosure.UnionWith(unit.Value.Dependencies.SelectMany(c => c.Dependencies));
                var unitOwned = new HashSet<string>(cacheClosure.SelectMany(c => new[] { c.Name, c.StateName }), StringComparer.Ordinal) { unit.Value.Name, unit.Value.StateName, planState };
                unitOwned.UnionWith(unit.Key.Caches.SelectMany(c => new[] { c.Name, c.StateName }));
                string stateTable = Util.Q(planState);
                unitSql += "UPDATE " + stateTable + " SET [NextUnit] = " + (ordinal + 1).ToString(CultureInfo.InvariantCulture) + " WHERE [Owner] = 0x" + planOwner + " AND [PlanHash] = 0x" + planHash + " AND [NextUnit] = " + ordinal.ToString(CultureInfo.InvariantCulture) + ";\nIF @@ROWCOUNT <> 1 THROW 50000, N'TBX_SSISDBG_plan_order: Planstate konnte nicht fortgeschrieben werden.', 1;\n";
                try { safety.Generated(unitSql, bindings.DefaultDatabase, unitOwned, true); }
                catch (DebugFault error) { throw new DebugFault(error.Code, "Planunit " + ordinal.ToString(CultureInfo.InvariantCulture) + " / " + unit.Key.Id + " SQLbytes=" + (2L * unitSql.Length).ToString(CultureInfo.InvariantCulture) + ": " + error.Message); }
                output.Add(new Artifact { Kind = "PlanUnitSql", Target = target, Stage = unit.Key.Id, Component = unit.Key.Component, Content = unitSql, Evidence = "translated", Safety = "passed", Executable = true, Complete = true,
                    Details = Json.Write(Json.Obj("ordinal", ordinal, "unitSha256", Util.Hash(unit.Value.Insert), "unitContentSha256", Util.Hash(unitSql), "ownerSha256", unit.Value.Owner, "planOwnerSha256", planOwner, "planHash", planHash, "outputShapeSha256", Util.Hash(unit.Value.Definition), "dependencies", unit.Key.Parents.Select(p => p.Id).ToList(),
                        "inputs", unit.Key.Parents.Select(p => (object)Json.Obj("unitId", p.Id, "columns", p.Columns.Select(c => (object)Json.Obj("identity", c.Id, "type", c.Type, "nullable", c.Nullable)).ToList())).ToList(),
                        "outputs", unit.Value.Columns.Select(c => (object)Json.Obj("identity", c.Id, "type", c.Type, "nullable", c.Nullable)).ToList()), bindings.Limits) });
                ordinal++;
                availableTemps.Add(unit.Value.Name); availableTemps.Add(unit.Value.StateName);
            }
            owned.Add(planState);
            string finalStateGuard = "DECLARE " + stateId + " int = OBJECT_ID(" + Util.L("tempdb.." + planState) + ", N'U');\n" + CacheSql.PlanStateGuard(planState, planOwner, planHash, valuesHash, stateId, true, units.Count, bindings.Collation, true);
            LookupCache targetCache = stageCaches[targetStage];
            var readCaches = new List<LookupCache> { targetCache };
            readCaches.AddRange(units.Where(u => u.Key.RowCountVariable != null).Select(u => u.Value));
            string readyCaches = CacheSql.RequireReady(readCaches, bindings.Collation, bindings);
            var readClosure = new HashSet<LookupCache>(readCaches.Distinct());
            readClosure.UnionWith(readCaches.Distinct().SelectMany(c => c.Dependencies));
            var readOwned = readClosure.SelectMany(c => new[] { c.Name, c.StateName }).Concat(new[] { planState }).ToList();
            string readPrelude = bindings.Declarations(inputs) + "\n" + databaseGuard + finalStateGuard + readyCaches;
            var finalProjection = "SELECT " + String.Join(", ", targetStage.Columns.Select(c => Util.Q(c.Alias) + " AS " + Util.Q(c.Name))) + " FROM " + Util.Q(targetCache.Name) + ";";
            var counts = units.Where(u => u.Key.RowCountVariable != null).Select(u =>
                "SELECT COUNT_BIG(*) AS [CountValue], CASE WHEN COUNT_BIG(*) BETWEEN " + u.Key.RowCountMinimum.ToString(CultureInfo.InvariantCulture) + " AND " + u.Key.RowCountMaximum.ToString(CultureInfo.InvariantCulture) + " THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS [FitsTargetVariable] FROM " + Util.Q(u.Value.Name) + ";").ToList();
            string execution = readPrelude + finalProjection;
            try { safety.Generated(execution, bindings.DefaultDatabase, readOwned, true); }
            catch (DebugFault error) { throw new DebugFault(error.Code, "Planresult SQLbytes=" + (2L * execution.Length).ToString(CultureInfo.InvariantCulture) + ": " + error.Message); }
            bool flatTarget = targetStage.FlatFileWriteMetadata != null;
            var details = Json.Obj("planHash", planHash, "planOwnerSha256", planOwner, "planStateTemp", planState, "unitCount", units.Count, "cleanupCount", allCaches.Count,
                "snapshotSharedWithProjection", true, "rowCountTargets", units.Where(u => u.Key.RowCountVariable != null).Select(u => (object)Json.Obj("variable", u.Key.RowCountVariable, "ssisType", u.Key.RowCountType, "assignmentTiming", "after-last-row")).ToList());
            if (flatTarget) { details.Add("targetMode", "flatfile-debug-projection"); details.Add("fileWriteSimulated", false); }
            string detailJson = Json.Write(details, bindings.Limits);
            output.Add(new Artifact { Kind = kind, Target = target, Stage = targetStage.Id, Component = targetStage.Component, Content = execution, Evidence = "pragmatic", Safety = "passed", Executable = true, Complete = true, Details = detailJson });
            var manifestUnits = units.Select((u, i) => (object)Json.Obj("ordinal", i, "unitId", u.Key.Id, "component", u.Key.Component, "unitSha256", Util.Hash(u.Value.Insert), "ownerSha256", u.Value.Owner,
                "outputShapeSha256", Util.Hash(u.Value.Definition), "dependencies", u.Key.Parents.Select(p => p.Id).ToList(),
                "inputs", u.Key.Parents.Select(p => (object)Json.Obj("unitId", p.Id, "columns", p.Columns.Select(c => (object)Json.Obj("identity", c.Id, "type", c.Type, "nullable", c.Nullable)).ToList())).ToList(),
                "outputs", u.Value.Columns.Select(c => (object)Json.Obj("identity", c.Id, "type", c.Type, "nullable", c.Nullable)).ToList())).ToList();
            output.Add(new Artifact { Kind = "PlanManifest", Target = target, Stage = targetStage.Id, Component = targetStage.Component, Content = Json.Write(Json.Obj("schemaVersion", 1, "planHash", Json.Text(details["planHash"]), "businessBindingHash", bindings.ContextHash, "units", manifestUnits), bindings.Limits), Evidence = "translated", Safety = "passed", Complete = true });
            output.Add(new Artifact { Kind = "ColumnLineage", Target = target, Stage = targetStage.Id, Component = targetStage.Component, Content = Json.Write(targetStage.Columns.Select(c => (object)Json.Obj("name", c.Name, "lineageId", c.Id, "sqlType", c.Type, "sqlAlias", c.Alias)).ToList(), bindings.Limits) });
            if (units.Any(u => u.Key.RowCountVariable != null))
                foreach (var unit in units.Where(u => u.Key.RowCountVariable != null))
                {
                    string rowSql = readPrelude + counts[units.Where(u => u.Key.RowCountVariable != null).ToList().IndexOf(unit)];
                    safety.Generated(rowSql, bindings.DefaultDatabase, readOwned, true);
                    output.Add(new Artifact { Kind = "RowCountSql", Target = target, Stage = unit.Key.Id, Component = unit.Key.Component,
                        Content = rowSql, Evidence = "pragmatic", Safety = "passed", Executable = true, Complete = true,
                        Details = Json.Write(Json.Obj("targetVariable", unit.Key.RowCountVariable, "ssisType", unit.Key.RowCountType, "assignmentTiming", "after-last-row", "snapshotSharedWithProjection", true, "executeWithPlanArtifact", true, "planHash", planHash), bindings.Limits) });
                }
            var cleanupCaches = allCaches.AsEnumerable().Reverse().ToList();
            for (int i = 0; i < cleanupCaches.Count; i++)
            {
                string tempAbsent = "OBJECT_ID(" + Util.L("tempdb.." + cleanupCaches[i].Name) + ", N'U') IS NULL AND OBJECT_ID(" + Util.L("tempdb.." + cleanupCaches[i].StateName) + ", N'U') IS NULL";
                string cleanup = bindings.Declarations(inputs) + "\n" + databaseGuard +
                    "IF OBJECT_ID(" + Util.L("tempdb.." + planState) + ", N'U') IS NULL\nBEGIN\nIF NOT (" + tempAbsent + ") THROW 50000, N'TBX_SSISDBG_plan_ownership: Tempcache ohne Planstate.', 1;\nEND\nELSE\nBEGIN\n" +
                    "DECLARE " + stateId + " int = OBJECT_ID(" + Util.L("tempdb.." + planState) + ", N'U');\n" + CacheSql.PlanStateGuard(planState, planOwner, planHash, valuesHash, stateId, true, -1, bindings.Collation, true, true, i == 0 ? -1 : i, units.Count);
                string stateTable = Util.Q(planState);
                string beforeDrop = i == 0
                    ? "UPDATE " + stateTable + " SET [CleanupOrdinal] = 0 WHERE [Owner]=0x" + planOwner + " AND [PlanHash]=0x" + planHash + " AND [CleanupOrdinal]=-1;\nIF NOT EXISTS (SELECT 1 FROM " + stateTable + " WITH (NOLOCK) WHERE [Owner]=0x" + planOwner + " AND [PlanHash]=0x" + planHash + " AND [CleanupOrdinal]=0) THROW 50000, N'TBX_SSISDBG_plan_cleanup_order: Cleanup konnte nicht begonnen werden.', 1;\n"
                    : "";
                string afterDrop = i == cleanupCaches.Count - 1
                    ? "DROP TABLE " + stateTable + ";\n"
                    : "UPDATE " + stateTable + " SET [CleanupOrdinal] = " + (i + 1).ToString(CultureInfo.InvariantCulture) + " WHERE [Owner]=0x" + planOwner + " AND [PlanHash]=0x" + planHash + " AND [CleanupOrdinal]=" + i.ToString(CultureInfo.InvariantCulture) + ";\nIF @@ROWCOUNT <> 1 THROW 50000, N'TBX_SSISDBG_plan_cleanup_order: Cleanupgeneration konnte nicht fortgeschrieben werden.', 1;\n";
                cleanup += CacheSql.CleanupPlan(cleanupCaches[i], bindings.Collation, beforeDrop, afterDrop);
                cleanup += "END;\n";
                safety.Generated(cleanup, bindings.DefaultDatabase, new[] { cleanupCaches[i].Name, cleanupCaches[i].StateName, planState });
                output.Add(new Artifact { Kind = "CleanupSql", Target = target, Stage = targetStage.Id, Content = cleanup, Evidence = "translated", Safety = "passed", Executable = true, Complete = true,
                    Details = Json.Write(Json.Obj("cleanupOrdinal", i, "cleanupCount", cleanupCaches.Count, "planHash", planHash), bindings.Limits) });
            }
            if (flatTarget) output.Add(new Artifact { Kind = "FlatFileWriteProjection", Target = target, Stage = targetStage.Id, Component = targetStage.Component, Content = targetStage.FlatFileWriteMetadata, Evidence = "pragmatic", Safety = "not_applicable", Executable = false, Complete = false,
                Details = Json.Write(Json.Obj("limitation", "Metadaten ohne Dateiserialisierung oder Zielschreibvorgang.", "debugProjectionIncludedInPlan", true), bindings.Limits) });
        }

        private void ValidateV2Plan(List<KeyValuePair<Stage, LookupCache>> units, Dictionary<Stage, LookupCache> stageCaches, Stage target, HashSet<string> inputs)
        {
            bindings.Limits.Check("planUnits", units.Count);
            if (units.Count == 0 || units[units.Count - 1].Key != target) throw new DebugFault("invalid_lineage", "Plan endet nicht in der angeforderten Zielstufe.");
            var seen = new HashSet<Stage>(); var cacheNames = new HashSet<string>(StringComparer.Ordinal); long bytes = 0;
            foreach (var unit in units)
            {
                Stage stage = unit.Key; LookupCache cache = unit.Value;
                if (!seen.Add(stage) || !cacheNames.Add(cache.Name) || !cacheNames.Add(cache.StateName) || cache.Owner != Util.Hash("ssis-components-v2-plan|" + runHash + "|" + stage.Id + "|" + cache.Definition))
                    throw new DebugFault("invalid_lineage", "Planunit-ID, Ownership oder Ausgabeform ist dupliziert/abweichend.");
                foreach (Stage parent in stage.Parents) if (!seen.Contains(parent)) throw new DebugFault("invalid_lineage", "Planabhängigkeit steht nicht vor ihrer Verwendung.");
                var expectedDependencies = stage.Parents.Select(s => stageCaches[s]).Concat(stage.Caches).Distinct().ToList();
                if (cache.Dependencies.Count != expectedDependencies.Count || cache.Dependencies.Where((d, i) => !Object.ReferenceEquals(d, expectedDependencies[i])).Any())
                    throw new DebugFault("invalid_lineage", "Planmanifest und typisierte Cacheabhängigkeiten weichen voneinander ab.");
                foreach (Stage parent in stage.Parents)
                {
                    LookupCache parentCache = stageCaches[parent];
                    if (parentCache.Columns.Count != parent.Columns.Count || parentCache.Columns.Where((c, i) => c.Id != parent.Columns[i].Id || c.Type != parent.Columns[i].Type || c.Nullable != parent.Columns[i].Nullable).Any())
                        throw new DebugFault("invalid_lineage", "Planinputstufe ist typmäßig abweichend.");
                }
                if (cache.Columns.Count != stage.Columns.Count || cache.Columns.Select(c => c.Alias).Distinct(StringComparer.Ordinal).Count() != cache.Columns.Count ||
                    cache.Columns.Where((c, i) => c.Alias != stage.Columns[i].Alias || c.Type != stage.Columns[i].Type || c.Nullable != stage.Columns[i].Nullable).Any())
                    throw new DebugFault("invalid_lineage", "Planoutput ist nicht typidentisch zur Stufe.");
                bytes = checked(bytes + 2L * (cache.Insert.Length + cache.Definition.Length)); bindings.Limits.Check("sqlArtifactBytes", 2L * cache.Insert.Length);
            }
            bindings.Limits.Check("totalOutputBytes", bytes);
            if (!inputs.SetEquals(units.SelectMany(u => u.Key.Inputs))) throw new DebugFault("invalid_lineage", "Planinputs stimmen nicht mit der gebundenen Zielkette überein.");
        }
    }
}
