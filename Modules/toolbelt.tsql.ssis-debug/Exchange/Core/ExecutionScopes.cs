using System;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;

namespace Toolbelt.Ssis.Exchange
{
    public sealed partial class PackageDocument
    {
        // Statische Scopeprofile entstehen aus denselben Definitionen wie Modell
        // und Lineage. Die Laufzeitzuordnung und Kataloglesung bleiben beim Consumer.
        public Dictionary<string, object> ExportExecutionScopes()
        {
            Build(); Check();
            var objects = new List<object>();
            var known = new Dictionary<string, Definition>(StringComparer.Ordinal);
            var steps = new Dictionary<string, List<object>>(StringComparer.Ordinal);
            var supported = new Dictionary<string, bool>(StringComparer.Ordinal);
            foreach (var d in definitions.Where(x => x.Kind == "PACKAGE" || x.Kind == "EXECUTABLE"))
            {
                Check(); known.Add(d.Id, d);
                string reference = (string)d.Element.Attribute(Dts + "refId");
                string eventName = d.Element.Name == Dts + "EventHandler" ? (string)d.Element.Attribute(Dts + "EventName") : null;
                bool handler = eventName == "OnPreExecute" || eventName == "OnPostExecute" || eventName == "OnError";
                object type; d.Attributes.TryGetValue("executableType", out type);
                bool loop = ComponentProfiles.IsIterationContainer(type as string);
                bool call = (type as string) == "Microsoft.ExecutePackageTask";
                string role = d.Kind == "PACKAGE" ? "PACKAGE" : d.Element.Name == Dts + "EventHandler" ? "HANDLER" : call ? "CALL" : loop ? "LOOP" : "EXECUTABLE";
                var pathSteps = new List<object>(); bool valid = false;
                if (d.Kind == "PACKAGE") valid = reference == "Package";
                else
                {
                    Definition parent;
                    if (d.Parent != null && known.TryGetValue(d.Parent, out parent) && supported[parent.Id] && reference != null)
                    {
                        string parentReference = (string)parent.Element.Attribute(Dts + "refId");
                        pathSteps.AddRange(steps[parent.Id]);
                        // Der letzte Schritt eines Schleifenobjekts erhält erst
                        // beim Übergang zu seinem Kind einen Iterationszähler.
                        object parentType; parent.Attributes.TryGetValue("executableType", out parentType);
                        if (pathSteps.Count > 0 && ComponentProfiles.IsIterationContainer(parentType as string))
                        {
                            var old = (Dictionary<string, object>)pathSteps[pathSteps.Count - 1];
                            pathSteps[pathSteps.Count - 1] = Obj("text", old["text"], "counter", true);
                        }
                        if (role == "HANDLER")
                        {
                            valid = handler && reference == parentReference + ".EventHandlers[" + eventName + "]";
                            if (valid) pathSteps.Add(Obj("text", "\\" + eventName, "counter", false));
                        }
                        else if (reference.StartsWith(parentReference + "\\", StringComparison.Ordinal))
                        {
                            string segment = reference.Substring(parentReference.Length);
                            valid = segment.Length > 1 && segment.IndexOf('\\', 1) < 0;
                            if (valid) pathSteps.Add(Obj("text", segment, "counter", false));
                        }
                    }
                }
                valid = valid && reference != null && reference.Length < 4000 && pathSteps.Count <= 32;
                supported.Add(d.Id, valid); steps.Add(d.Id, pathSteps);
                string target = null;
                if (call)
                {
                    var data = d.Element.Elements(Dts + "ObjectData").Elements("ExecutePackageTask").ToList();
                    if (data.Count == 1 && !d.Element.Elements(Dts + "PropertyExpression").Any())
                    {
                        string project = (string)data[0].Element("UseProjectReference"), outside = (string)data[0].Element("ExecuteOutOfProcess");
                        string name = (string)data[0].Element("PackageName");
                        if (project == "True" && (outside == null || outside == "False") && name != null && name.Length > 5 && name.Length <= 260 &&
                            name.EndsWith(".dtsx", StringComparison.Ordinal) && name.IndexOfAny(new[] { '\\', '/', ':', '\0' }) < 0) target = name;
                    }
                }
                Guid guid;
                objects.Add(Obj("nodeId", d.Id, "nodeKind", d.Kind, "parentId", d.Parent,
                    "dtsId", Guid.TryParse(d.NativeDtsId, out guid) ? guid.ToString("D").ToLowerInvariant() : null,
                    "packagePath", valid ? "\\" + reference : null, "scopeKind", role, "eventName", handler ? eventName : null,
                    "callTarget", target, "steps", valid ? pathSteps : new List<object>(), "profileStatus", valid ? "SUPPORTED" : "UNQUALIFIED"));
            }
            return Obj("contract", "ssis-object-identities", "version", "1.2.0", "identityProfile", "document-order-v1", "packageSha256", PackageSha256, "objects", objects);
        }
    }
}
