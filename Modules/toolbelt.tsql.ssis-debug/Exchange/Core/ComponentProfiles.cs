using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;

namespace Toolbelt.Ssis.Exchange
{
    // Ein kanonischer Komponentenklassifikator für Generator und neutralen Export.
    public static class ComponentProfiles
    {
        public sealed class V2OutputPort
        {
            public bool? IsErrorOutput { get; set; }
            public bool ErrorFlagPresent { get; set; }
            public string SynchronousInputId { get; set; }
        }
        // Nur diese nativen Containerprofile erlauben Iterationssegmente.
        // Unbekannte Typen werden weder aus Namen noch aus Laufzeitpfaden erraten.
        public static bool IsIterationContainer(string executableType)
        {
            return executableType == "STOCK:FORLOOP" || executableType == "STOCK:FOREACHLOOP";
        }
        private static string Get(Dictionary<string,string> properties, string key)
        { string value; return properties.TryGetValue(key, out value) ? value : ""; }
        // Im qualifizierten Lookupprofil folgt der No-Match-Ausgang auf den
        // Match-Ausgang. Anzeigenamen dürfen beide Ausgänge beliebig umbenennen.
        public static bool IsLookupNoMatchOutput(int nonErrorOutputIndex)
        { return nonErrorOutputIndex == 1; }
        public static string Kind(string id, int version, Dictionary<string, string> properties)
        {
            // Nur strukturell qualifizierte native Komponentenprofile.
            bool source = id == "Microsoft.OLEDBSource" || id == "{165A526D-D5DE-47FF-96A6-F8274C19826B}";
            bool destination = id == "Microsoft.OLEDBDestination" || id == "{4ADA7EAA-136C-4215-8098-D7A7C27FC0D1}";
            bool lookup = id == "Microsoft.Lookup" || id == "{671046B0-AA63-4C9F-90E4-C06E0B710CE3}";
            bool managed = id == "Microsoft.ManagedComponentHost" || id == "{874F7595-FB5F-40FF-96AF-FBFF8250E3EF}";
            if (source ? version != 7 : destination ? version != 4 : lookup ? version != 6 : managed ? version != 0 && version != 1 : version != 1) return "unsupported";
            switch (id)
            {
                case "{165A526D-D5DE-47FF-96A6-F8274C19826B}": case "Microsoft.OLEDBSource": return "source";
                case "{4ADA7EAA-136C-4215-8098-D7A7C27FC0D1}": case "Microsoft.OLEDBDestination": return "destination";
                case "{B594E9A8-4351-4939-891C-CFE1AB93E925}": case "Microsoft.UnionAll": return "union";
                case "{49928E82-9C4E-49F0-AABE-3812B82707EC}": case "Microsoft.DerivedColumn": return "derived";
                case "{62B1106C-7DB8-4EC8-ADD6-4C664DFFC54A}": case "Microsoft.DataConvert": return "convert";
                case "{671046B0-AA63-4C9F-90E4-C06E0B710CE3}": case "Microsoft.Lookup": return "lookup";
                case "{7F88F654-4E20-4D14-84F4-AF9C925D3087}": case "Microsoft.ConditionalSplit": return "split";
                case "Microsoft.ManagedComponentHost": case "{874F7595-FB5F-40FF-96AF-FBFF8250E3EF}":
                    string name = Get(properties, "UserComponentTypeName");
                    if (Regex.IsMatch(name, "\\AMicrosoft\\.SqlServer\\.Dts\\.Pipeline\\.ADONETSource, Microsoft\\.SqlServer\\.ADONETSrc, Version=(11|12|13|14|15|16|17)\\.0\\.0\\.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91\\z")) return "source";
                    if (Regex.IsMatch(name, "\\AMicrosoft\\.SqlServer\\.Dts\\.Pipeline\\.ADONETDestination, Microsoft\\.SqlServer\\.ADONETDest, Version=(11|12|13|14|15|16|17)\\.0\\.0\\.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91\\z")) return "destination";
                    return "unsupported";
                default: return "unsupported";
            }
        }

        // V2 profiles are selected only from an explicit DTSX2 package profile.
        // A missing component version is represented by schemaDefaultVersion=0;
        // callers must reject present-but-invalid values before reaching here.
        public static string KindV2(string id, int version, string packageProfile, Dictionary<string, string> properties)
        {
            if (packageProfile != "2012/01" && packageProfile != "2014/01") return "unsupported";
            string baseKind = Kind(id, version, properties);
            if (baseKind != "unsupported") return baseKind;
            if (version != 0 && version != 1) return "unsupported";
            switch (id)
            {
                case "Microsoft.DerivedColumn": case "{49928E82-9C4E-49F0-AABE-3812B82707EC}": return version == 0 ? "derived" : "unsupported";
                case "Microsoft.ConditionalSplit": case "{7F88F654-4E20-4D14-84F4-AF9C925D3087}": return version == 0 ? "split" : "unsupported";
                case "Microsoft.RowCount": return version == 0 ? "rowcount" : "unsupported";
                case "Microsoft.FlatFileSource": return version == 1 ? "flatfile-source" : "unsupported";
                case "Microsoft.FlatFileDestination": return version == 0 ? "flatfile-destination" : "unsupported";
                default: return "unsupported";
            }
        }
        public static bool HasV2PortProfile(string kind, int inputs, IList<string> inputIds, IList<V2OutputPort> outputs)
        {
            if (inputIds == null || outputs == null || inputs != inputIds.Count || inputIds.Any(String.IsNullOrEmpty) || inputIds.Distinct(StringComparer.Ordinal).Count() != inputIds.Count) return false;
            if (outputs.Any(p => p == null || p.ErrorFlagPresent && !p.IsErrorOutput.HasValue)) return false;
            int normal = outputs.Count(p => p.IsErrorOutput != true), errors = outputs.Count(p => p.IsErrorOutput == true);
            bool allSynchronous = inputs == 1 && outputs.All(p => p.SynchronousInputId == inputIds[0]);
            bool sourceSynchronous = inputs == 0 && outputs.All(p => String.IsNullOrEmpty(p.SynchronousInputId) || p.SynchronousInputId == "0");
            switch (kind)
            {
                case "derived": return inputs == 1 && normal == 1 && errors <= 1 && allSynchronous;
                case "split": return inputs == 1 && normal >= 2 && errors <= 1 && allSynchronous;
                case "rowcount": return inputs == 1 && normal == 1 && errors == 0 && allSynchronous;
                case "flatfile-source": return inputs == 0 && normal == 1 && errors <= 1 && sourceSynchronous;
                case "flatfile-destination": return inputs == 1 && outputs.Count == 0;
                default: return true;
            }
        }
    }
}
