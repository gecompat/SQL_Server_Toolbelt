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
        internal static string GuardNoTransaction()
        { return "IF @@TRANCOUNT <> 0 OR (@@OPTIONS & 2) <> 0 THROW 50000, N'TBX_SSISDBG_cache_context_changed: Cachemutation verlangt keine Callertransaktion und IMPLICIT_TRANSACTIONS OFF.', 1;\n"; }
        private static string ShapeLegacy(string objectId, IEnumerable<StageColumn> columns, string collation)
        {
            var cs = columns.ToList(); var matches = new List<string>(); int ordinal = 0;
            foreach (StageColumn c in cs)
            {
                string t = c.Type.ToLowerInvariant(); var m = Regex.Match(t, "\\A([a-z0-9]+)(?:\\((max|[0-9]+)(?:,([0-9]+))?\\))?\\z");
                if (!m.Success) throw new DebugFault("unresolved_binding", "Temp-Spaltentyp nicht im festen Renderer.");
                string family = m.Groups[1].Value, length = m.Groups[2].Value; int type, size, precision = 0, scale = 0;
                switch (family)
                {
                    case "bit": type = 104; size = 1; break; case "tinyint": type = 48; size = 1; break; case "smallint": type = 52; size = 2; break; case "int": type = 56; size = 4; break; case "bigint": type = 127; size = 8; break;
                    case "real": type = 59; size = 4; break; case "float": type = 62; size = 8; break; case "money": type = 60; size = 8; break; case "smallmoney": type = 122; size = 4; break;
                    case "datetime": type = 61; size = 8; break; case "smalldatetime": type = 58; size = 4; break;
                    case "decimal": type = 106; precision = Int32.Parse(length, CultureInfo.InvariantCulture); scale = Int32.Parse(m.Groups[3].Value, CultureInfo.InvariantCulture); size = precision <= 9 ? 5 : precision <= 19 ? 9 : precision <= 28 ? 13 : 17; break;
                    case "nchar": case "nvarchar": type = family == "nchar" ? 239 : 231; size = length == "max" ? -1 : Int32.Parse(length, CultureInfo.InvariantCulture) * 2; break;
                    case "char": case "varchar": type = family == "char" ? 175 : 167; size = length == "max" ? -1 : Int32.Parse(length, CultureInfo.InvariantCulture); break;
                    case "varbinary": type = 165; size = length == "max" ? -1 : Int32.Parse(length, CultureInfo.InvariantCulture); break; case "binary": type = 173; size = Int32.Parse(length, CultureInfo.InvariantCulture); break;
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
        private static string ExpectedShapeHash(IEnumerable<StageColumn> columns, string collation)
        {
            var cs = columns.ToList(); var shapeRows = new List<string>();
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
                bool text = new[] { "char", "varchar", "nchar", "nvarchar" }.Contains(family);
                string expectedCollation = text ? c.Collation ?? collation : null;
                string nameHex = BitConverter.ToString(System.Text.Encoding.Unicode.GetBytes(c.Alias)).Replace("-", "");
                string collationHex = expectedCollation == null ? "~" : BitConverter.ToString(System.Text.Encoding.Unicode.GetBytes(expectedCollation)).Replace("-", "");
                shapeRows.Add(String.Join("|", new[] { (++ordinal).ToString(CultureInfo.InvariantCulture), nameHex,
                    type.ToString(CultureInfo.InvariantCulture), size.ToString(CultureInfo.InvariantCulture), c.Nullable ? "1" : "0", "0", "0",
                    precision.ToString(CultureInfo.InvariantCulture), scale.ToString(CultureInfo.InvariantCulture), collationHex, "0", "0", type.ToString(CultureInfo.InvariantCulture) }));
            }
            return Util.Hash(String.Join(";", shapeRows));
        }
        private static string ShapeV2Rows(string objectId)
        { return "STRING_AGG(CONVERT(varchar(max),CONCAT(CONVERT(varchar(11),c.[column_id]),'|',CONVERT(varchar(max),CONVERT(varbinary(max),c.[name]),2),'|',CONVERT(varchar(11),c.[system_type_id]),'|',CONVERT(varchar(11),c.[max_length]),'|',CONVERT(varchar(11),c.[is_nullable]),'|',CONVERT(varchar(11),c.[is_computed]),'|',CONVERT(varchar(11),c.[is_identity]),'|',CONVERT(varchar(11),CASE WHEN c.[system_type_id]=106 THEN c.[precision] ELSE 0 END),'|',CONVERT(varchar(11),CASE WHEN c.[system_type_id] IN (106,41,42) THEN c.[scale] ELSE 0 END),'|',COALESCE(CONVERT(varchar(max),CONVERT(varbinary(max),c.[collation_name]),2),'~'),'|',CONVERT(varchar(11),c.[default_object_id]),'|',CONVERT(varchar(11),c.[rule_object_id]),'|',CONVERT(varchar(11),c.[user_type_id]))), ';') WITHIN GROUP (ORDER BY c.[column_id])"; }
        internal static string ShapeV2(string objectId, IEnumerable<StageColumn> columns, string collation)
        { return "(HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),COALESCE((SELECT " + ShapeV2Rows(objectId) + " FROM tempdb.sys.columns AS c WITH (NOLOCK) WHERE c.[object_id]=" + objectId + "),''))) <> 0x" + ExpectedShapeHash(columns, collation) + ") OR EXISTS (SELECT 1 FROM tempdb.sys.indexes AS i WITH (NOLOCK) WHERE i.[object_id]=" + objectId + " AND i.[index_id]<>0) OR EXISTS (SELECT 1 FROM tempdb.sys.check_constraints AS cc WITH (NOLOCK) WHERE cc.[parent_object_id]=" + objectId + ")"; }
        private static List<StageColumn> StateColumns()
        { return new List<StageColumn> { new StageColumn { Alias = "Owner", Type = "binary(32)", Nullable = false }, new StageColumn { Alias = "Fingerprint", Type = "binary(32)", Nullable = false } }; }
        private static string Validate(LookupCache cache, string id, string sid, string collation, bool v2 = false)
        {
            Func<string, IEnumerable<StageColumn>, string> shape = v2 ? (Func<string, IEnumerable<StageColumn>, string>)((objectId, columns) => ShapeV2(objectId, columns, collation)) : (objectId, columns) => ShapeLegacy(objectId, columns, collation);
            return "IF " + shape(id, cache.Columns) + " OR " + shape(sid, StateColumns()) + "\nTHROW 50000, N'TBX_SSISDBG_cache_ownership: Temp-Schema abweichend.', 1;\n" +
                "IF (SELECT COUNT_BIG(*) FROM " + Util.Q(cache.StateName) + " AS st WITH (NOLOCK)) <> 1 OR NOT EXISTS (SELECT 1 FROM " + Util.Q(cache.StateName) + " AS st WITH (NOLOCK) WHERE st.[Owner] = 0x" + cache.Owner + ")\nTHROW 50000, N'TBX_SSISDBG_cache_ownership: Ownershipmarker oder Generation fehlt/ist abweichend.', 1;\n";
        }
        internal static string RequireReady(LookupCache cache, string collation, bool v2 = false)
        {
            string suffix = Suffix(cache), id = "@tbx_o" + suffix, sid = "@tbx_s" + suffix;
            return "DECLARE " + id + " int = OBJECT_ID(" + Local(cache.Name) + ", N'U');\nDECLARE " + sid + " int = OBJECT_ID(" + Local(cache.StateName) + ", N'U');\nIF " + id + " IS NULL OR " + sid + " IS NULL THROW 50000, N'TBX_SSISDBG_plan_dependency: Vorgängergeneration fehlt.', 1;\n" + Validate(cache, id, sid, collation, v2);
        }
        internal static string RequireReady(IEnumerable<LookupCache> caches, string collation, Bindings bindings)
        {
            var all = caches.Distinct().ToList(); if (all.Count == 0) return "";
            var objectRows = new List<string>(); var markers = new List<string>(); var declarations = new List<string>(); var indexRows = new List<string>();
            int index = 0;
            foreach (LookupCache cache in all)
            {
                string id = "@tbx_ro" + index.ToString(CultureInfo.InvariantCulture), sid = "@tbx_rs" + index.ToString(CultureInfo.InvariantCulture);
                declarations.Add("DECLARE " + id + " int = OBJECT_ID(" + Local(cache.Name) + ", N'U');\nDECLARE " + sid + " int = OBJECT_ID(" + Local(cache.StateName) + ", N'U');\nIF " + id + " IS NULL OR " + sid + " IS NULL THROW 50000, N'TBX_SSISDBG_plan_dependency: Vorgängergeneration fehlt.', 1;");
                objectRows.Add("(" + id + ",0x" + ExpectedShapeHash(cache.Columns, collation) + "),(" + sid + ",0x" + ExpectedShapeHash(StateColumns(), collation) + ")");
                indexRows.Add("(" + id + "),(" + sid + ")");
                string fingerprint = "HASHBYTES(N'SHA2_256'," + FingerprintExpression(cache, bindings, true) + ")";
                markers.Add("IF (SELECT COUNT_BIG(*) FROM " + Util.Q(cache.StateName) + " AS st WITH (NOLOCK)) <> 1 OR NOT EXISTS (SELECT 1 FROM " + Util.Q(cache.StateName) + " AS st WITH (NOLOCK) WHERE st.[Owner]=0x" + cache.Owner + " AND st.[Fingerprint]=" + fingerprint + ") THROW 50000, N'TBX_SSISDBG_plan_dependency: Owner oder Generation abweichend.', 1;");
                index++;
            }
            string expected = "(VALUES " + String.Join(",", objectRows) + ") AS e([object_id],[shape_hash])";
            string shapeRows = ShapeV2Rows("e.[object_id]");
            string shapeCheck = "IF EXISTS (SELECT 1 FROM " + expected + " OUTER APPLY (SELECT HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),COALESCE((SELECT " + shapeRows + " FROM tempdb.sys.columns AS c WITH (NOLOCK) WHERE c.[object_id]=e.[object_id]),''))) AS [actual_hash]) AS a WHERE e.[object_id] IS NULL OR a.[actual_hash]<>e.[shape_hash]) OR EXISTS (SELECT 1 FROM tempdb.sys.indexes AS i WITH (NOLOCK) JOIN (VALUES " + String.Join(",", indexRows) + ") AS e([object_id]) ON e.[object_id]=i.[object_id] WHERE i.[index_id]<>0) OR EXISTS (SELECT 1 FROM tempdb.sys.check_constraints AS cc WITH (NOLOCK) JOIN (VALUES " + String.Join(",", indexRows) + ") AS e([object_id]) ON e.[object_id]=cc.[parent_object_id]) THROW 50000, N'TBX_SSISDBG_plan_dependency: Vorgängerschema abweichend.', 1;\n";
            return String.Join("\n", declarations) + "\n" + shapeCheck + String.Join("\n", markers);
        }
        internal static string Prepare(LookupCache cache, Bindings bindings)
        {
            string suffix = Suffix(cache), id = "@tbx_o" + suffix, sid = "@tbx_s" + suffix, fp = "@tbx_f" + suffix, need = "@tbx_n" + suffix;
            string fingerprint = FingerprintExpression(cache, bindings, cache.FreshPerExecution && cache.PlanSaltState != null);
            string state = Util.Q(cache.StateName), table = Util.Q(cache.Name);
            if (cache.FreshPerExecution && cache.PlanSaltState != null)
                return "-- Einmalige salzgebundene Planstufe; vorhandene gleichnamige Temps werden nie übernommen.\nDECLARE " + id + " int = OBJECT_ID(" + Local(cache.Name) + ", N'U');\nDECLARE " + sid + " int = OBJECT_ID(" + Local(cache.StateName) + ", N'U');\nIF " + id + " IS NOT NULL OR " + sid + " IS NOT NULL THROW 50000, N'TBX_SSISDBG_cache_ownership: Tempname ist bereits belegt.', 1;\nDECLARE " + fp + " binary(32) = HASHBYTES(N'SHA2_256', " + fingerprint + ");\n" + GuardNoTransaction() + "BEGIN TRY\nBEGIN TRANSACTION;\nCREATE TABLE " + table + " (" + cache.Definition + ");\nCREATE TABLE " + state + " ([Owner] binary(32) NOT NULL, [Fingerprint] binary(32) NOT NULL);\n" + cache.Insert + "\nINSERT INTO " + state + " ([Owner], [Fingerprint]) SELECT 0x" + cache.Owner + ", " + fp + ";\nCOMMIT TRANSACTION;\nEND TRY\nBEGIN CATCH\nIF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;\nTHROW;\nEND CATCH;";
            return "-- Einmalige Lookupauswahl für denselben lokalen Debuglauf.\nDECLARE " + id + " int = OBJECT_ID(" + Local(cache.Name) + ", N'U');\nDECLARE " + sid + " int = OBJECT_ID(" + Local(cache.StateName) + ", N'U');\nDECLARE " + fp + " binary(32) = HASHBYTES(N'SHA2_256', " + fingerprint + ");\nDECLARE " + need + " bit = 0;\n" +
                "IF " + id + " IS NULL AND " + sid + " IS NULL SET " + need + " = 1;\nELSE\nBEGIN\nIF " + id + " IS NULL OR " + sid + " IS NULL THROW 50000, N'TBX_SSISDBG_cache_ownership: Unklarer Teilzustand.', 1;\n" +
                Validate(cache, id, sid, bindings.Collation) + "IF NOT EXISTS (SELECT 1 FROM " + state + " AS st WITH (NOLOCK) WHERE st.[Fingerprint] = " + fp + ") SET " + need + " = 1;\nEND;\n" +
                "IF " + need + " = 1\nBEGIN\n" + GuardNoTransaction() + "BEGIN TRY\nBEGIN TRANSACTION;\nIF " + id + " IS NOT NULL DROP TABLE " + table + ";\nIF " + sid + " IS NOT NULL DROP TABLE " + state + ";\n" +
                "CREATE TABLE " + table + " (" + cache.Definition + ");\nCREATE TABLE " + state + " ([Owner] binary(32) NOT NULL, [Fingerprint] binary(32) NOT NULL);\n" +
                cache.Insert + "\nINSERT INTO " + state + " ([Owner], [Fingerprint]) SELECT 0x" + cache.Owner + ", " + fp + ";\nCOMMIT TRANSACTION;\nEND TRY\nBEGIN CATCH\nIF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;\nTHROW;\nEND CATCH;\nEND;";
        }
        private static string FingerprintExpression(LookupCache cache, Bindings bindings, bool compact)
        {
            string fingerprint = "CAST(0x" + Util.Hash(cache.Insert + cache.Definition) + " AS varbinary(max))";
            foreach (Input input in bindings.Package.Inputs.Where(i => cache.Inputs.Contains(i.Key)))
                fingerprint += " + CAST(0x" + Util.Hash(input.Key + "|" + input.SqlType) + " AS varbinary(max)) + CASE WHEN " + input.SqlName + " IS NULL THEN 0x00 ELSE 0x01 + " + (compact ? "HASHBYTES(N'SHA2_256',CONVERT(varbinary(max)," + input.SqlName + "))" : "CONVERT(binary(4), DATALENGTH(CONVERT(varbinary(max), " + input.SqlName + "))) + CONVERT(varbinary(max), " + input.SqlName + ")") + " END";
            foreach (LookupCache dependency in cache.Dependencies)
                fingerprint += " + CONVERT(varbinary(max), (SELECT ds.[Fingerprint] FROM " + Util.Q(dependency.StateName) + " AS ds WITH (NOLOCK) WHERE ds.[Owner] = 0x" + dependency.Owner + "))";
            if (cache.FreshPerExecution && cache.PlanSaltState != null)
                fingerprint += " + CONVERT(binary(16), (SELECT ps.[Salt] FROM " + Util.Q(cache.PlanSaltState) + " AS ps WITH (NOLOCK) WHERE ps.[Owner] = 0x" + cache.PlanSaltOwner + " AND ps.[PlanHash] = 0x" + cache.PlanHash + "))";
            else if (cache.FreshPerExecution) fingerprint += " + CONVERT(binary(16), @tbx_plan_salt)";
            return fingerprint;
        }
        internal static string Cleanup(IEnumerable<LookupCache> caches, string collation, bool v2 = false)
        {
            var blocks = new List<string> { GuardNoTransaction() };
            foreach (LookupCache cache in caches)
            {
                string suffix = Suffix(cache), id = "@tbx_o" + suffix, sid = "@tbx_s" + suffix;
                blocks.Add("DECLARE " + id + " int = OBJECT_ID(" + Local(cache.Name) + ", N'U');\nDECLARE " + sid + " int = OBJECT_ID(" + Local(cache.StateName) + ", N'U');\nIF " + id + " IS NOT NULL OR " + sid + " IS NOT NULL\nBEGIN\nIF " + id + " IS NULL OR " + sid + " IS NULL THROW 50000, N'TBX_SSISDBG_cache_ownership: Unklarer Teilzustand.', 1;\n" + Validate(cache, id, sid, collation, v2) + "DROP TABLE " + Util.Q(cache.Name) + ";\nDROP TABLE " + Util.Q(cache.StateName) + ";\nEND;");
            }
            return String.Join("\n", blocks);
        }
        internal static string CleanupPlan(LookupCache cache, string collation, string beforeDrop, string afterDrop)
        {
            string suffix = Suffix(cache), id = "@tbx_o" + suffix, sid = "@tbx_s" + suffix;
            return GuardNoTransaction() +
                "DECLARE " + id + " int = OBJECT_ID(" + Local(cache.Name) + ", N'U');\nDECLARE " + sid + " int = OBJECT_ID(" + Local(cache.StateName) + ", N'U');\n" +
                "IF " + id + " IS NULL AND " + sid + " IS NOT NULL OR " + id + " IS NOT NULL AND " + sid + " IS NULL THROW 50000, N'TBX_SSISDBG_cache_ownership: Unklarer Teilzustand.', 1;\n" +
                "BEGIN TRY\nBEGIN TRANSACTION;\n" +
                "IF " + id + " IS NOT NULL BEGIN\n" + Validate(cache, id, sid, collation, true) + "END;\n" + beforeDrop +
                "IF " + id + " IS NOT NULL BEGIN DROP TABLE " + Util.Q(cache.Name) + "; DROP TABLE " + Util.Q(cache.StateName) + "; END;\n" + afterDrop +
                "COMMIT TRANSACTION;\nEND TRY\nBEGIN CATCH\nIF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;\nTHROW;\nEND CATCH;";
        }
        internal static List<StageColumn> PlanStateColumns()
        { return new List<StageColumn> { new StageColumn { Alias = "Owner", Type = "binary(32)", Nullable = false }, new StageColumn { Alias = "PlanHash", Type = "binary(32)", Nullable = false }, new StageColumn { Alias = "ValuesHash", Type = "binary(32)", Nullable = false }, new StageColumn { Alias = "NextUnit", Type = "int", Nullable = false }, new StageColumn { Alias = "Salt", Type = "uniqueidentifier", Nullable = false }, new StageColumn { Alias = "CleanupOrdinal", Type = "int", Nullable = false } }; }
        internal static string PlanValuesHash(IEnumerable<Input> inputs)
        {
            string material = "CAST(0x" + Util.Hash("ssis-components-v2-input-values") + " AS varbinary(max))";
            foreach (Input input in inputs.OrderBy(i => i.Key, StringComparer.Ordinal))
                material += " + CAST(0x" + Util.Hash(input.Key + "|" + input.SqlType) + " AS varbinary(max)) + CASE WHEN " + input.SqlName + " IS NULL THEN 0x00 ELSE 0x01 + CONVERT(binary(4), DATALENGTH(CONVERT(varbinary(max), " + input.SqlName + "))) + CONVERT(varbinary(max), " + input.SqlName + ") END";
            return "HASHBYTES(N'SHA2_256', " + material + ")";
        }
        internal static string PlanStateGuard(string name, string owner, string planHash, string valuesHash, string id, bool requireReady, int readyCount, string collation, bool v2 = false, bool cleanup = false, int cleanupOrdinal = -1, int unitCount = 0)
        {
            string local = Local(name);
            string stateColumns = String.Join(", ", PlanStateColumns().Select(c => Util.Q(c.Alias) + " " + c.Type + " NOT NULL"));
            string valueGuard = valuesHash == null ? "" : " AND [ValuesHash] = " + valuesHash;
            string shape = v2 ? ShapeV2(id, PlanStateColumns(), collation) : ShapeLegacy(id, PlanStateColumns(), collation);
            string progress = "";
            if (requireReady && cleanup) progress = " AND [NextUnit] BETWEEN 0 AND " + unitCount.ToString(CultureInfo.InvariantCulture) + " AND ([CleanupOrdinal] = " + cleanupOrdinal.ToString(CultureInfo.InvariantCulture) + (cleanupOrdinal == -1 ? " OR [CleanupOrdinal] = 0" : "") + ")";
            else if (requireReady) progress = " AND [NextUnit] = " + readyCount.ToString(CultureInfo.InvariantCulture) + " AND [CleanupOrdinal] = -1";
            string marker = "IF " + shape + " OR (SELECT COUNT_BIG(*) FROM " + Util.Q(name) + " WITH (NOLOCK)) <> 1 OR NOT EXISTS (SELECT 1 FROM " + Util.Q(name) + " WITH (NOLOCK) WHERE [Owner] = 0x" + owner + " AND [PlanHash] = 0x" + planHash + valueGuard + progress + ")\nTHROW 50000, N'TBX_SSISDBG_plan_state: Planstate fehlt, abweichend oder unvollständig.', 1;\n";
            if (id == null) return "IF OBJECT_ID(" + local + ", N'U') IS NOT NULL THROW 50000, N'TBX_SSISDBG_plan_ownership: Planstate existiert bereits.', 1;\nCREATE TABLE " + Util.Q(name) + " (" + stateColumns + ");\nINSERT INTO " + Util.Q(name) + " ([Owner],[PlanHash],[ValuesHash],[NextUnit],[Salt],[CleanupOrdinal]) SELECT 0x" + owner + ",0x" + planHash + "," + valuesHash + ",0,NEWID(),-1;\n";
            return "IF " + id + " IS NULL THROW 50000, N'TBX_SSISDBG_plan_state: Planstate fehlt.', 1;\n" + marker;
        }
    }
}
