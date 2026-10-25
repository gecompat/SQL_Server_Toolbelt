using System;
using System.Collections.Generic;
using System.Linq;

namespace Toolbelt.Ssis.Exchange
{
    public sealed partial class PackageDocument
    {
        // Referenzen auf das bestehende Modell. Diese Projektion interpretiert
        // weder Laufzeitzeilen noch Datenwerte und berechnet keine neue Lineage.
        public Dictionary<string, object> ExportPipelineIdentities()
        {
            Build(); Check();
            var lookup = definitions.ToDictionary(x => x.Id, StringComparer.Ordinal);
            var scopes = ((List<object>)ExportExecutionScopes()["objects"]).Cast<Dictionary<string, object>>().ToDictionary(x => (string)x["nodeId"], StringComparer.Ordinal);
            var flows = new List<object>();
            foreach (var flow in definitions.Where(x => x.Kind == "EXECUTABLE" && x.IsPipeline && x.HasPipeline))
            {
                Check();
                string flowRef = (string)flow.Element.Attribute(Dts + "refId");
                bool supported = (string)scopes[flow.Id]["profileStatus"] == "SUPPORTED";
                var components = definitions.Where(x => x.Kind == "COMPONENT" && x.Parent == flow.Id).ToList();
                var componentRecords = new List<object>();
                foreach (var component in components)
                {
                    string reference = (string)component.Element.Attribute("refId");
                    bool valid = supported && reference == flowRef + "\\" + component.Name && reference.Length <= 4000 && components.Count(x => x.Name == component.Name) == 1;
                    componentRecords.Add(Obj("nodeId", component.Id, "name", Text(component.Name), "nativeRefId", reference != null && reference.Length <= 4000 ? reference : null, "profileStatus", valid ? "SUPPORTED" : "UNQUALIFIED"));
                }
                var paths = new List<object>();
                for (int index = 0; index < relationships.Count; index++)
                {
                    var path = relationships[index]; if (path.Kind != "PIPELINE_PATH" || path.Scope != flow.Id) continue;
                    Check(); Definition from = path.From == null ? null : lookup[path.From], to = path.To == null ? null : lookup[path.To];
                    Definition source = from == null ? null : lookup[from.Parent], destination = to == null ? null : lookup[to.Parent];
                    string identification = source == null || from == null ? null : "Paths[" + source.Name + "." + from.Name + "]";
                    bool valid = supported && path.Resolution == "RESOLVED" && source.Parent == flow.Id && destination.Parent == flow.Id &&
                        path.NativeName != null && path.NativeName.Length <= 4000 && path.NativeReference == flowRef + ".Paths[" + path.NativeName + "]" &&
                        (string)source.Element.Attribute("refId") == flowRef + "\\" + source.Name &&
                        (string)from.Element.Attribute("refId") == flowRef + "\\" + source.Name + ".Outputs[" + from.Name + "]" &&
                        identification.Length <= 4000;
                    paths.Add(Obj("edgeId", "edge" + (index + 1), "nativeRefId", path.NativeReference != null && path.NativeReference.Length <= 4000 ? path.NativeReference : null,
                        "name", path.NativeName != null && path.NativeName.Length <= 4000 ? path.NativeName : null,
                        "identificationString", valid ? identification : null, "fromPortId", path.From, "toPortId", path.To,
                        "sourceComponentId", source == null ? null : source.Id, "destinationComponentId", destination == null ? null : destination.Id,
                        "profileStatus", valid ? "SUPPORTED" : "UNQUALIFIED"));
                }
                flows.Add(Obj("nodeId", flow.Id, "profileStatus", supported ? "SUPPORTED" : "UNQUALIFIED", "components", componentRecords, "paths", paths));
            }
            return Obj("contract", "ssis-pipeline-identities", "version", "1.0.0", "identityProfile", "document-order-v1", "packageSha256", PackageSha256, "pipelines", flows);
        }
    }
}
