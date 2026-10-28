using System;
using System.Linq;

namespace Toolbelt.Tsql.SsisDebug
{
    internal static class Engine
    {
        internal static Artifacts Analyze(byte[] bytes, Options options, ICatalog catalog, Budget budget)
        {
            try { return AnalyzeCore(bytes, options, catalog, budget); }
            catch (Toolbelt.Ssis.Exchange.ResourceLimitException error)
            {
                if (options.Limits == null || !options.Limits.IsV2)
                {
                    if (options.ResourceProbe && options.Limits != null && options.Limits.DetailedDiagnostics) throw new DebugFault("resource_limit", "counter=" + error.Counter + "; actual=" + error.Actual.ToString(System.Globalization.CultureInfo.InvariantCulture) + "; limit=" + error.Maximum.ToString(System.Globalization.CultureInfo.InvariantCulture) + "; profile=legacy-v1.");
                    throw new DebugFault("resource_limit", error.Counter == "analysisMilliseconds" ? "Analysebudget erschöpft." : "Feste V1-Grenze überschritten.");
                }
                throw new DebugFault("resource_limit", "counter=" + error.Counter + "; " + (error.ActualIsLowerBound ? "actualAtLeast=" : "actual=") + error.Actual.ToString(System.Globalization.CultureInfo.InvariantCulture) + "; limit=" + (options.Limits.IsUnlimitedCounter(error.Counter) ? "unlimited" : error.Maximum.ToString(System.Globalization.CultureInfo.InvariantCulture)) + "; profile=" + error.Preset + ".");
            }
        }
        private static Artifacts AnalyzeCore(byte[] bytes, Options options, ICatalog catalog, Budget budget)
        {
            if (bytes == null) throw new DebugFault("unresolved_binding", "PackageBytes erforderlich.");
            if (options.Operation != "bindings-template" && options.Operation != "bindings-template-v2" && options.Operation != "explain") throw new DebugFault("unresolved_binding", "Operation ungültig.");
            if (options.Version != 150 && options.Version != 160 && options.Version != 170) throw new DebugFault("unresolved_binding", "TSqlVersion muss 150, 160 oder 170 sein.");
            if (options.Stage != null && options.Stage != "all" && options.Target == null) throw new DebugFault("unresolved_binding", "Konkrete Stufe verlangt Zielfluss.");
            bool contextV2;
            if (options.ResourceProbe) { options.Limits = Toolbelt.Ssis.Exchange.ResourceLimits.LegacyProbe; contextV2 = false; }
            else if (options.Limits != null) contextV2 = options.ResourceContextV2;
            else { options.Limits = ResourceOptions.Resolve(options.ProjectContext, options.Operation, options.Bindings, out contextV2, out options.BindingProfile, out options.ProjectContextValue); options.ResourceContextV2 = contextV2; }
            if (options.ProjectContext != null && options.ProjectContextValue == null)
            {
                long controlNodes; options.ProjectContextValue = Json.Object(Json.Parse(options.ProjectContext, ResourceOptions.ControlBootstrap, out controlNodes));
                Json.CheckJsonLimit(options.Limits, "jsonNodes", controlNodes);
            }
            if (options.BindingProfile == null && options.Bindings != null) options.BindingProfile = Json.Text(Json.Get(Json.Object(Json.Parse(options.Bindings, options.Limits)), "profile"));
            bool componentsV2 = options.Operation == "bindings-template-v2" || contextV2 || options.BindingProfile == "ssis-debug-components-v2";
            if (contextV2 && options.BindingProfile != null && options.BindingProfile != "ssis-debug-components-v2") throw new DebugFault("invalid_template", "ProjectContext V2 und Bindingprofil stimmen nicht überein.");
            budget.Limits = options.Limits;
            long jsonBytes = 0;
            foreach (string json in new[] { options.Bindings, options.CatalogBindings, options.LookupPolicies })
            {
                if (json == null) continue;
                options.Limits.Check("jsonDocumentBytes", (long)json.Length * 2);
                jsonBytes += (long)json.Length * 2;
            }
            options.Limits.Check("allJsonBytes", jsonBytes);
            var output = new Artifacts(options.Limits); Package package = PackageReader.Read(bytes, budget, componentsV2, options.Limits);
            if (package.Profile == "unsupported") { output.Diagnostic("unsupported_package_format", null, "Wohlgeformtes Paket ohne unterstütztes DTSX2-Formatprofil 6/8."); return output; }
            var bindings = new Bindings(package, options, catalog, output);
            if (options.Operation == "bindings-template" || options.Operation == "bindings-template-v2")
            { output.Add(new Artifact { Kind = "BindingsTemplate", Content = Json.Write(bindings.Template(), options.Limits) }); return output; }
            var workflow = Json.Obj("formatProfile", package.Profile, "tasks", package.Workflow, "dataFlows", package.Flows.Select(f => (object)Json.Obj("id", f.Id, "name", f.Name, "paths", f.Paths.Select(p => (object)Json.Obj("from", p.Value, "to", p.Key)).ToList())).ToList());
            if (componentsV2)
            {
                workflow.Add("resourcePolicy", options.Limits.Metadata());
                if (bindings.BoundResourcePolicyHash != null)
                {
                    workflow.Add("bindingResourcePolicyHash", bindings.BoundResourcePolicyHash);
                    workflow.Add("resourcePolicyChanged", bindings.ResourcePolicyChanged);
                }
            }
            output.Add(new Artifact { Kind = "Workflow", Content = Json.Write(workflow, options.Limits) });
            var safety = new SqlSafety(budget, options.Version, catalog, bindings.Databases, package.Inputs.Select(v => v.SqlName), code => output.Diagnostic(code, null, code == "locking_hint_replaced" ? "Vorhandener Sperrhint wird durch das vereinbarte NOLOCK-Profil ersetzt." : "NOLOCK gilt nur an unterstützten direkten Referenzen; keine Behauptung transitiver Hintabdeckung."));
            foreach (Input input in package.Inputs) if (input.SqlType != null) safety.VariableTypes.Add(input.SqlName, input.SqlType);
            safety.ExecutionDatabase = bindings.DefaultDatabase;
            new Translator(package, bindings, options, safety, catalog, output).Run();
            safety.VerifyCatalog(); output.BindCatalog(safety.CatalogBinding()); budget.Check(); return output;
        }
    }
}
