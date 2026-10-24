using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;

namespace Toolbelt.Ssis.Exchange
{
    // Ein kanonischer Komponentenklassifikator für Generator und neutralen Export.
    public static class ComponentProfiles
    {
        private static string Get(Dictionary<string,string> properties, string key)
        { string value; return properties.TryGetValue(key, out value) ? value : ""; }
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
    }
}
