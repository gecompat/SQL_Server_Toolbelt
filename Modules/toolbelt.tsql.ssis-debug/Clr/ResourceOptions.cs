using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Data.SqlTypes;
using Toolbelt.Ssis.Exchange;

namespace Toolbelt.Tsql.SsisDebug
{
    /// <summary>Bindet den aktuellen Ressourcenvertrag ausschließlich an benannte SQL-bigint-Parameter.</summary>
    internal static class ResourceOptions
    {
        internal static ResourceLimits ControlBootstrap
        { get { return ResourceLimits.Create("unlimited", true, new Dictionary<string, string>(StringComparer.Ordinal) { { "jsonDocumentBytes", "4194304" } }); } }

        internal static readonly string[] SqlParameterNames = {
            "@MaxPackageBytes", "@MaxXmlCharacters", "@MaxXmlNodes", "@MaxModelNodes", "@MaxModelEdges",
            "@MaxComponents", "@MaxPaths", "@MaxColumns", "@MaxInputs", "@MaxJsonDocumentBytes", "@MaxAllJsonBytes",
            "@MaxJsonNodes", "@MaxExpressionBytes", "@MaxExpressionTokens", "@MaxExpressionNodes", "@MaxPlanUnits",
            "@MaxCatalogObjects", "@MaxCatalogQueries", "@MaxParserCalls", "@MaxArtifacts", "@MaxDiagnostics",
            "@MaxSqlArtifactBytes", "@MaxTotalOutputBytes", "@MaxAnalysisMilliseconds"
        };

        private static readonly string[] Counters = {
            "packageBytes", "xmlCharacters", "xmlNodes", "modelNodes", "modelEdges", "components", "paths", "columns", "inputs",
            "jsonDocumentBytes", "allJsonBytes", "jsonNodes", "expressionBytes", "expressionTokens", "expressionNodes", "planUnits",
            "catalogObjects", "catalogQueries", "parserCalls", "artifacts", "diagnostics", "sqlArtifactBytes", "totalOutputBytes", "analysisMilliseconds"
        };

        internal static ResourceLimits FromSqlParameters(params SqlInt64[] parameters)
        {
            if (parameters == null || parameters.Length != SqlParameterNames.Length) throw new DebugFault("unresolved_binding", "Ressourcenparameter unvollständig.");
            var limits = new Dictionary<string, long>(StringComparer.Ordinal);
            for (int i = 0; i < parameters.Length; i++)
            {
                if (parameters[i].IsNull) throw new DebugFault("unresolved_binding", "Parameter " + SqlParameterNames[i] + " darf nicht NULL sein; 0 bedeutet unbegrenzt.");
                long value = parameters[i].Value;
                if (value < 0) throw new DebugFault("unresolved_binding", "Parameter " + SqlParameterNames[i] + " muss 0 oder positiv sein.");
                limits.Add(Counters[i], value);
            }
            return ResourceLimits.CreateCurrent(limits);
        }

        internal static ResourceLimits CurrentDefaults { get { return ResourceLimits.CreateCurrent(); } }

        internal static ResourceLimits Parse(string projectContext, string operation, string bindingProfile, out bool contextV2)
        { Dictionary<string, object> ignored; return Parse(projectContext, operation, bindingProfile, out contextV2, out ignored); }

        internal static ResourceLimits Parse(string projectContext, string operation, string bindingProfile, out bool contextV2, out Dictionary<string, object> parsedContext)
        { return Parse(projectContext, operation, bindingProfile, CurrentDefaults, out contextV2, out parsedContext); }

        internal static ResourceLimits Parse(string projectContext, string operation, string bindingProfile, ResourceLimits limits, out bool contextV2, out Dictionary<string, object> parsedContext)
        {
            limits = limits ?? CurrentDefaults;
            contextV2 = false;
            parsedContext = projectContext == null ? Json.Obj("schemaVersion", new JsonNumber("2")) : null;
            if (projectContext == null) return limits;
            if ((long)projectContext.Length * 2 > 4194304)
                throw new DebugFault("resource_limit", "counter=controlProtocolBytes; actual=" + ((long)projectContext.Length * 2).ToString(CultureInfo.InvariantCulture) + "; limit=4194304; profile=current.");

            // ProjectContext bleibt auf Geschäftskontext begrenzt. Ressourcensteuerung
            // wird ausschließlich über die öffentlichen bigint-Parameter gebunden.
            long nodeCount;
            var context = Json.Object(Json.Parse(projectContext, ControlBootstrap, out nodeCount));
            object version = Json.Get(context, "schemaVersion");
            if (!(version is JsonNumber) || ((JsonNumber)version).Text != "2")
                throw new DebugFault("invalid_template", "ProjectContext schemaVersion muss 2 sein.");
            if (context.ContainsKey("resourceOptions"))
                throw new DebugFault("invalid_template", "resourceOptions ist nicht zulässig; Ressourcenlimits über @MaxPackageBytes und @MaxAnalysisMilliseconds setzen.");
            contextV2 = ((JsonNumber)version).Text == "2";
            Json.Keys(context, "schemaVersion", "projectParameters", "connectionManagers");
            Json.CheckJsonLimit(limits, "jsonDocumentBytes", (long)projectContext.Length * 2);
            Json.CheckJsonLimit(limits, "jsonNodes", nodeCount);
            parsedContext = context;
            return limits;
        }

        internal static ResourceLimits Resolve(string projectContext, string operation, string bindingsJson, out bool contextV2, out string bindingProfile)
        { Dictionary<string, object> ignored; return Resolve(projectContext, operation, bindingsJson, out contextV2, out bindingProfile, out ignored); }

        internal static ResourceLimits Resolve(string projectContext, string operation, string bindingsJson, out bool contextV2, out string bindingProfile, out Dictionary<string, object> parsedContext)
        { return Resolve(projectContext, operation, bindingsJson, CurrentDefaults, out contextV2, out bindingProfile, out parsedContext); }

        internal static ResourceLimits Resolve(string projectContext, string operation, string bindingsJson, ResourceLimits limits, out bool contextV2, out string bindingProfile, out Dictionary<string, object> parsedContext)
        {
            limits = Parse(projectContext, operation, null, limits, out contextV2, out parsedContext);
            bindingProfile = null;
            if (bindingsJson != null)
            {
                long nodes;
                var binding = Json.Object(Json.Parse(bindingsJson, limits, out nodes));
                bindingProfile = Json.Text(Json.Get(binding, "profile"));
                if (bindingProfile != "ssis-debug-components-v2") throw new DebugFault("invalid_template", "Bindingprofil muss ssis-debug-components-v2 sein.");
                Json.Version(binding, 2);
                Json.CheckJsonLimit(limits, "jsonNodes", nodes);
            }
            return limits;
        }
    }
}
