using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Linq;
using System.Text.RegularExpressions;
using Microsoft.SqlServer.TransactSql.ScriptDom;
using Toolbelt.Tsql.ScriptParser;

namespace Toolbelt.Tsql.SsisDebug
{
    internal static class SqlParameters
    {
        internal static Dictionary<int, Input> Mappings(string mapping, Package package, string scope)
        {
            var result = new Dictionary<int, Input>(); var labels = new HashSet<string>(StringComparer.Ordinal);
            foreach (string entry in mapping.Split(';').Where(x => x.Trim() != ""))
            {
                var m = Regex.Match(entry.Trim(), "\\A\"([^\"]+):Input\",([^;]+)\\z");
                if (!m.Success || !labels.Add(m.Groups[1].Value)) throw new DebugFault("unresolved_binding", "Parameter-Mapping ist nicht eindeutig im nativen V1-Format.");
                result.Add(result.Count, package.Resolve(m.Groups[2].Value.Trim(), scope));
            }
            return result;
        }
        internal static string Replace(string sql, Dictionary<int, Input> mapping, Func<Input, string> resolve)
        {
            var offsets = new List<int>(); SqlSafety.Guard(sql, offsets);
            var b = new StringBuilder(); int end = 0, ordinal = 0;
            foreach (int offset in offsets)
            {
                Input input; if (!mapping.TryGetValue(ordinal++, out input)) throw new DebugFault("unresolved_binding", "Ordinaler Source-Parameter fehlt.");
                b.Append(sql, end, offset - end); b.Append(resolve(input)); end = offset + 1;
            }
            if (ordinal != mapping.Count) throw new DebugFault("unresolved_binding", "Parameteranzahl stimmt nicht mit Mapping überein.");
            b.Append(sql, end, sql.Length - end); return b.ToString();
        }
    }
}
