using System;
using System.Linq;

namespace Toolbelt.Tsql.SsisDebug
{
    internal static class Engine
    {
        internal static Artifacts Analyze(byte[] bytes, Options options, ICatalog catalog, Budget budget)
        {
            if (bytes == null) throw new DebugFault("unresolved_binding", "PackageBytes erforderlich.");
            if (options.Operation != "bindings-template" && options.Operation != "explain") throw new DebugFault("unresolved_binding", "Operation ungültig.");
            if (options.Version != 150 && options.Version != 160 && options.Version != 170) throw new DebugFault("unresolved_binding", "TSqlVersion muss 150, 160 oder 170 sein.");
            if (options.Stage != null && options.Stage != "all" && options.Target == null) throw new DebugFault("unresolved_binding", "Konkrete Stufe verlangt Zielfluss.");
            long jsonBytes = 0;
            foreach (string json in new[] { options.ProjectContext, options.Bindings, options.CatalogBindings, options.LookupPolicies })
            { if (json != null) { Budget.Limit((long)json.Length * 2, 4194304); jsonBytes += (long)json.Length * 2; } }
            Budget.Limit(jsonBytes, 8388608);
            var output = new Artifacts(); Package package = PackageReader.Read(bytes, budget);
            if (package.Profile == "unsupported") { output.Diagnostic("unsupported_package_format", null, "Wohlgeformtes Paket ohne unterstütztes DTSX2-Formatprofil 6/8."); return output; }
            var bindings = new Bindings(package, options, catalog, output);
            if (options.Operation == "bindings-template")
            { output.Add(new Artifact { Kind = "BindingsTemplate", Content = Json.Write(bindings.Template()) }); return output; }
            output.Add(new Artifact { Kind = "Workflow", Content = Json.Write(Json.Obj("formatProfile", package.Profile, "tasks", package.Workflow, "dataFlows", package.Flows.Select(f => (object)Json.Obj("id", f.Id, "name", f.Name, "paths", f.Paths.Select(p => (object)Json.Obj("from", p.Value, "to", p.Key)).ToList())).ToList())) });
            var safety = new SqlSafety(budget, options.Version, catalog, bindings.Databases, package.Inputs.Select(v => v.SqlName), code => output.Diagnostic(code, null, code == "locking_hint_replaced" ? "Vorhandener Sperrhint wird durch das vereinbarte NOLOCK-Profil ersetzt." : "NOLOCK gilt nur an unterstützten direkten Referenzen; keine Behauptung transitiver Hintabdeckung."));
            foreach (Input input in package.Inputs) if (input.SqlType != null) safety.VariableTypes.Add(input.SqlName, input.SqlType);
            safety.ExecutionDatabase = bindings.DefaultDatabase;
            new Translator(package, bindings, options, safety, catalog, output).Run();
            safety.VerifyCatalog(); output.BindCatalog(safety.CatalogBinding()); budget.Check(); return output;
        }
    }
}
