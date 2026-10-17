using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;

namespace Toolbelt.Tsql.SsisDebug
{
    internal static class CacheSql
    {
        private static string Suffix(LookupCache cache) { return cache.Name.Substring(cache.Name.Length - 5); }
        private static string Local(string name) { return Util.L("tempdb.." + name); }
        private static string GuardNoTransaction()
        { return "IF @@TRANCOUNT <> 0 OR (@@OPTIONS & 2) <> 0 THROW 50000, N'TBX_SSISDBG_cache_context_changed: Cachemutation verlangt keine Callertransaktion und IMPLICIT_TRANSACTIONS OFF.', 1;\n"; }
        private static string Shape(string objectId, IEnumerable<StageColumn> columns, string collation)
        {
            var cs = columns.ToList(); var matches = new List<string>();
            int ordinal = 0;
            foreach (StageColumn c in cs)
            {
                string t = c.Type.ToLowerInvariant(); var m = Regex.Match(t, "\\A([a-z0-9]+)(?:\\((max|[0-9]+)(?:,([0-9]+))?\\))?\\z");
                if (!m.Success) throw new DebugFault("unresolved_binding", "Temp-Spaltentyp nicht im festen Renderer.");
                string family = m.Groups[1].Value, length = m.Groups[2].Value; int type, size, precision = 0, scale = 0;
                switch (family)
                {
                    case "bit": type = 104; size = 1; break; case "tinyint": type = 48; size = 1; break;
                    case "smallint": type = 52; size = 2; break; case "int": type = 56; size = 4; break; case "bigint": type = 127; size = 8; break;
                    case "real": type = 59; size = 4; break; case "float": type = 62; size = 8; break;
                    case "money": type = 60; size = 8; break; case "smallmoney": type = 122; size = 4; break;
                    case "datetime": type = 61; size = 8; break; case "smalldatetime": type = 58; size = 4; break;
                    case "decimal": type = 106; precision = Int32.Parse(length, CultureInfo.InvariantCulture); scale = Int32.Parse(m.Groups[3].Value, CultureInfo.InvariantCulture); size = precision <= 9 ? 5 : precision <= 19 ? 9 : precision <= 28 ? 13 : 17; break;
                    case "nchar": case "nvarchar": type = family == "nchar" ? 239 : 231; size = length == "max" ? -1 : Int32.Parse(length, CultureInfo.InvariantCulture) * 2; break;
                    case "char": case "varchar": type = family == "char" ? 175 : 167; size = length == "max" ? -1 : Int32.Parse(length, CultureInfo.InvariantCulture); break;
                    case "varbinary": type = 165; size = length == "max" ? -1 : Int32.Parse(length, CultureInfo.InvariantCulture); break;
                    case "binary": type = 173; size = Int32.Parse(length, CultureInfo.InvariantCulture); break;
                    case "date": type = 40; size = 3; break; case "time": type = 41; scale = Int32.Parse(length, CultureInfo.InvariantCulture); size = scale <= 2 ? 3 : scale <= 4 ? 4 : 5; break;
                    case "datetime2": type = 42; scale = Int32.Parse(length, CultureInfo.InvariantCulture); size = scale <= 2 ? 6 : scale <= 4 ? 7 : 8; break; case "uniqueidentifier": type = 36; size = 16; break;
                    default: throw new DebugFault("unresolved_binding", "Temp-Spaltentyp nicht im festen Renderer.");
                }
                string expectedCollation = new[] { "char", "varchar", "nchar", "nvarchar" }.Contains(family) ? Util.L(c.Collation ?? collation) : "CAST(NULL AS nvarchar(128))";
                matches.Add("(" + (++ordinal) + "," + Util.L(c.Alias) + "," + type + "," + size + "," + (c.Nullable ? "1" : "0") + ",0,0," + precision + "," + scale + "," + expectedCollation + ")");
            }
            return "EXISTS (SELECT c.[column_id], c.[name] COLLATE Latin1_General_100_BIN2, c.[system_type_id], c.[max_length], c.[is_nullable], c.[is_computed], c.[is_identity], CASE WHEN c.[system_type_id] = 106 THEN c.[precision] ELSE 0 END, CASE WHEN c.[system_type_id] IN (106,41,42) THEN c.[scale] ELSE 0 END, c.[collation_name] COLLATE Latin1_General_100_BIN2 FROM tempdb.sys.columns AS c WITH (NOLOCK) WHERE c.[object_id] = " + objectId + " EXCEPT SELECT v.[o],v.[n] COLLATE Latin1_General_100_BIN2,v.[t],v.[l],v.[z],v.[c],v.[i],v.[p],v.[s],v.[a] COLLATE Latin1_General_100_BIN2 FROM (VALUES " + String.Join(",", matches) + ") AS v([o],[n],[t],[l],[z],[c],[i],[p],[s],[a])) OR (SELECT COUNT_BIG(*) FROM tempdb.sys.columns AS c WITH (NOLOCK) WHERE c.[object_id] = " + objectId + ") <> " + cs.Count +
                " OR EXISTS (SELECT 1 FROM tempdb.sys.columns AS c WITH (NOLOCK) WHERE c.[object_id]=" + objectId + " AND (c.[default_object_id]<>0 OR c.[rule_object_id]<>0 OR c.[user_type_id]<>c.[system_type_id])) OR EXISTS (SELECT 1 FROM tempdb.sys.indexes AS i WITH (NOLOCK) WHERE i.[object_id]=" + objectId + " AND i.[index_id]<>0) OR EXISTS (SELECT 1 FROM tempdb.sys.check_constraints AS cc WITH (NOLOCK) WHERE cc.[parent_object_id]=" + objectId + ")";
        }
        private static List<StageColumn> StateColumns()
        { return new List<StageColumn> { new StageColumn { Alias = "Owner", Type = "binary(32)", Nullable = false }, new StageColumn { Alias = "Fingerprint", Type = "binary(32)", Nullable = false } }; }
        private static string Validate(LookupCache cache, string id, string sid, string collation)
        {
            return "IF " + Shape(id, cache.Columns, collation) + " OR " + Shape(sid, StateColumns(), collation) + "\nTHROW 50000, N'TBX_SSISDBG_cache_ownership: Temp-Schema abweichend.', 1;\n" +
                "IF (SELECT COUNT_BIG(*) FROM " + Util.Q(cache.StateName) + " AS st WITH (NOLOCK)) <> 1 OR NOT EXISTS (SELECT 1 FROM " + Util.Q(cache.StateName) + " AS st WITH (NOLOCK) WHERE st.[Owner] = 0x" + cache.Owner + ")\nTHROW 50000, N'TBX_SSISDBG_cache_ownership: Ownershipmarker fehlt oder ist abweichend.', 1;\n";
        }
        internal static string Prepare(LookupCache cache, Bindings bindings)
        {
            string suffix = Suffix(cache), id = "@tbx_o" + suffix, sid = "@tbx_s" + suffix, fp = "@tbx_f" + suffix, need = "@tbx_n" + suffix;
            string fingerprint = "CAST(0x" + Util.Hash(cache.Insert + cache.Definition) + " AS varbinary(max))";
            foreach (Input input in bindings.Package.Inputs.Where(i => cache.Inputs.Contains(i.Key)))
                fingerprint += " + CAST(0x" + Util.Hash(input.Key + "|" + input.SqlType) + " AS varbinary(max)) + CASE WHEN " + input.SqlName + " IS NULL THEN 0x00 ELSE 0x01 + CONVERT(binary(4), DATALENGTH(CONVERT(varbinary(max), " + input.SqlName + "))) + CONVERT(varbinary(max), " + input.SqlName + ") END";
            string state = Util.Q(cache.StateName), table = Util.Q(cache.Name);
            return "-- Einmalige Lookupauswahl für denselben lokalen Debuglauf.\nDECLARE " + id + " int = OBJECT_ID(" + Local(cache.Name) + ", N'U');\nDECLARE " + sid + " int = OBJECT_ID(" + Local(cache.StateName) + ", N'U');\nDECLARE " + fp + " binary(32) = HASHBYTES(N'SHA2_256', " + fingerprint + ");\nDECLARE " + need + " bit = 0;\n" +
                "IF " + id + " IS NULL AND " + sid + " IS NULL SET " + need + " = 1;\nELSE\nBEGIN\nIF " + id + " IS NULL OR " + sid + " IS NULL THROW 50000, N'TBX_SSISDBG_cache_ownership: Unklarer Teilzustand.', 1;\n" +
                Validate(cache, id, sid, bindings.Collation) + "IF NOT EXISTS (SELECT 1 FROM " + state + " AS st WITH (NOLOCK) WHERE st.[Fingerprint] = " + fp + ") SET " + need + " = 1;\nEND;\n" +
                "IF " + need + " = 1\nBEGIN\n" + GuardNoTransaction() + "BEGIN TRY\nBEGIN TRANSACTION;\nIF " + id + " IS NOT NULL DROP TABLE " + table + ";\nIF " + sid + " IS NOT NULL DROP TABLE " + state + ";\n" +
                "CREATE TABLE " + table + " (" + cache.Definition + ");\nCREATE TABLE " + state + " ([Owner] binary(32) NOT NULL, [Fingerprint] binary(32) NOT NULL);\n" +
                cache.Insert + "\nINSERT INTO " + state + " ([Owner], [Fingerprint]) SELECT 0x" + cache.Owner + ", " + fp + ";\nCOMMIT TRANSACTION;\nEND TRY\nBEGIN CATCH\nIF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;\nTHROW;\nEND CATCH;\nEND;";
        }
        internal static string Cleanup(IEnumerable<LookupCache> caches, string collation)
        {
            var blocks = new List<string> { GuardNoTransaction() };
            foreach (LookupCache cache in caches)
            {
                string suffix = Suffix(cache), id = "@tbx_o" + suffix, sid = "@tbx_s" + suffix;
                blocks.Add("DECLARE " + id + " int = OBJECT_ID(" + Local(cache.Name) + ", N'U');\nDECLARE " + sid + " int = OBJECT_ID(" + Local(cache.StateName) + ", N'U');\nIF " + id + " IS NOT NULL OR " + sid + " IS NOT NULL\nBEGIN\nIF " + id + " IS NULL OR " + sid + " IS NULL THROW 50000, N'TBX_SSISDBG_cache_ownership: Unklarer Teilzustand.', 1;\n" + Validate(cache, id, sid, collation) + "DROP TABLE " + Util.Q(cache.Name) + ";\nDROP TABLE " + Util.Q(cache.StateName) + ";\nEND;");
            }
            return String.Join("\n", blocks);
        }
    }
}
