using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;
using Toolbelt.Ssis.Exchange;

namespace Toolbelt.Tsql.SsisDebug
{
    internal static class ResourceOptions
    {
        internal static ResourceLimits ControlBootstrap { get { return ResourceLimits.Create("unlimited", true, new Dictionary<string, string>(StringComparer.Ordinal) { { "jsonDocumentBytes", "4194304" } }); } }
        internal static ResourceLimits Parse(string projectContext, string operation, string bindingProfile, out bool contextV2)
        { Dictionary<string, object> ignored; return Parse(projectContext, operation, bindingProfile, out contextV2, out ignored); }
        internal static ResourceLimits Parse(string projectContext, string operation, string bindingProfile, out bool contextV2, out Dictionary<string, object> parsedContext)
        {
            bool operationV2 = operation == "bindings-template-v2" || bindingProfile == "ssis-debug-components-v2";
            contextV2 = false; parsedContext = projectContext == null ? Json.Obj("schemaVersion", new JsonNumber("1")) : null;
            if (projectContext == null) return operationV2 ? ResourceLimits.Create("large10x", true) : ResourceLimits.Legacy;
            if ((long)projectContext.Length * 2 > 4194304) throw new DebugFault("resource_limit", "counter=controlProtocolBytes; actual=" + ((long)projectContext.Length * 2).ToString(CultureInfo.InvariantCulture) + "; limit=4194304; profile=control-protocol.");
            // The ProjectContext is the bounded control bootstrap: its 4 MiB
            // UTF-16 envelope and JSON depth remain protocol limits, while data
            // document limits are resolved only after its schema is known.
            long contextNodes, resourceOptionsBytes;
            var context = Json.Object(Json.Parse(projectContext, ControlBootstrap, out contextNodes, out resourceOptionsBytes)); parsedContext = context;
            object versionValue = Json.Get(context, "schemaVersion");
            bool schema2 = versionValue is JsonNumber && ((JsonNumber)versionValue).Text == "2";
            if (!schema2)
            {
                Json.CheckJsonLimit(ResourceLimits.Legacy, "jsonDocumentBytes", (long)projectContext.Length * 2);
                Json.CheckJsonLimit(ResourceLimits.Legacy, "jsonNodes", contextNodes);
                if (context.ContainsKey("resourceOptions")) throw new DebugFault("invalid_template", "ResourceOptions verlangt ProjectContext schemaVersion 2.");
                if (operationV2) return ResourceLimits.Create("large10x", true);
                return ResourceLimits.Legacy;
            }
            contextV2 = true;
            if (operation == "bindings-template") throw new DebugFault("invalid_template", "V2-Vorlage verlangt bindings-template-v2.");
            operationV2 = true; // ProjectContext 2 ist selbst das ausdrückliche V2-Opt-in.
            var options = context.ContainsKey("resourceOptions") ? Json.Object(context["resourceOptions"]) : Json.Obj();
            if (context.ContainsKey("resourceOptions"))
            {
                if (resourceOptionsBytes > 16384) throw new DebugFault("resource_limit", "counter=resourceOptionsJsonBytes; actual=" + resourceOptionsBytes.ToString(CultureInfo.InvariantCulture) + "; limit=16384; profile=control-protocol.");
                Json.Version(options); Json.Keys(options, "schemaVersion", "preset", "limits");
            }
            string preset = options.ContainsKey("preset") ? Json.Text(options["preset"]) : "large10x";
            var overrides = new Dictionary<string, string>(StringComparer.Ordinal);
            if (options.ContainsKey("limits"))
            {
                foreach (var entry in Json.Object(options["limits"]))
                {
                    if (entry.Value is string)
                    {
                        string value = (string)entry.Value; if (value != "unlimited") throw new DebugFault("invalid_template", "ResourceOptions-Limit ungültig.");
                        overrides.Add(entry.Key, value);
                    }
                    else if (entry.Value is JsonNumber)
                    {
                        string text = ((JsonNumber)entry.Value).Text; long n;
                        if (!Regex.IsMatch(text, "\\A[1-9][0-9]*\\z") || !Int64.TryParse(text, NumberStyles.None, CultureInfo.InvariantCulture, out n)) throw new DebugFault("invalid_template", "ResourceOptions-Limit muss eine positive exakte Int64-Zahl sein.");
                        overrides.Add(entry.Key, text);
                    }
                    else throw new DebugFault("invalid_template", "ResourceOptions-Limit ungültig.");
                }
            }
            ResourceLimits resolved;
            try { resolved = ResourceLimits.Create(preset, true, overrides); }
            catch (ArgumentException) { throw new DebugFault("invalid_template", "ResourceOptions-Preset oder Zähler ungültig."); }
            Json.CheckJsonLimit(resolved, "jsonNodes", contextNodes);
            return resolved;
        }

        internal static ResourceLimits Resolve(string projectContext, string operation, string bindingsJson, out bool contextV2, out string bindingProfile)
        { Dictionary<string, object> ignored; return Resolve(projectContext, operation, bindingsJson, out contextV2, out bindingProfile, out ignored); }
        internal static ResourceLimits Resolve(string projectContext, string operation, string bindingsJson, out bool contextV2, out string bindingProfile, out Dictionary<string, object> parsedContext)
        {
            ResourceLimits bootstrap = Parse(projectContext, operation, null, out contextV2, out parsedContext);
            bindingProfile = null;
            if (bindingsJson != null)
            {
                ResourceLimits bindingBootstrap = contextV2 ? bootstrap : ResourceLimits.Legacy;
                long bindingNodes;
                var binding = Json.Object(Json.Parse(bindingsJson, bindingBootstrap, out bindingNodes));
                bindingProfile = Json.Text(Json.Get(binding, "profile"));
                if (bindingProfile != "ssis-debug-v1" && bindingProfile != "ssis-debug-components-v2") throw new DebugFault("invalid_template", "Bindingprofil ungültig.");
                ResourceLimits effectiveBindingLimits = contextV2 ? bootstrap : bindingProfile == "ssis-debug-components-v2" ? ResourceLimits.Create("large10x", true) : ResourceLimits.Legacy;
                Json.CheckJsonLimit(effectiveBindingLimits, "jsonDocumentBytes", (long)bindingsJson.Length * 2);
                Json.CheckJsonLimit(effectiveBindingLimits, "jsonNodes", bindingNodes);
            }
            if (contextV2)
            {
                if (bindingProfile != null && bindingProfile != "ssis-debug-components-v2") throw new DebugFault("invalid_template", "ProjectContext V2 und Bindingprofil stimmen nicht überein.");
                return bootstrap;
            }
            if (bindingProfile == "ssis-debug-components-v2") return ResourceLimits.Create("large10x", true);
            return bootstrap;
        }
    }
}
