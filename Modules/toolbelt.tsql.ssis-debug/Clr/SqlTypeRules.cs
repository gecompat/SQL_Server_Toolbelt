using System;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;

namespace Toolbelt.Tsql.SsisDebug
{
    // Endliche Metadatenregeln, keine angenommene Rückgabe des linken Operanden.
    // https://learn.microsoft.com/sql/t-sql/data-types/precision-scale-and-length-transact-sql
    internal static class SqlTypeRules
    {
        internal static bool Integer(string type) { return new[] { "tinyint", "smallint", "int", "bigint" }.Contains(type); }
        private static int Rank(string type) { return Array.IndexOf(new[] { "tinyint", "smallint", "int", "bigint" }, type); }
        private static bool DecimalType(string type, out int precision, out int scale)
        {
            var m = Regex.Match(type ?? "", "\\Adecimal\\(([0-9]+),([0-9]+)\\)\\z");
            precision = m.Success ? Int32.Parse(m.Groups[1].Value, CultureInfo.InvariantCulture) : type == "bigint" ? 19 : type == "int" ? 10 : type == "smallint" ? 5 : type == "tinyint" ? 3 : 0;
            scale = m.Success ? Int32.Parse(m.Groups[2].Value, CultureInfo.InvariantCulture) : 0; return precision > 0;
        }
        internal static string CastType(string text)
        {
            string type = Regex.Replace(text.ToLowerInvariant(), "\\s+", "");
            if (type == "decimal" || type == "numeric") return "decimal(18,0)";
            if (type.StartsWith("numeric(", StringComparison.Ordinal)) type = "decimal" + type.Substring(7);
            if (Regex.IsMatch(type, "\\Adecimal\\([0-9]+\\)\\z")) type = type.Substring(0, type.Length - 1) + ",0)";
            if (type == "float") return "float(53)";
            var floating = Regex.Match(type, "\\Afloat\\(([0-9]+)\\)\\z");
            if (floating.Success) { int bits = Int32.Parse(floating.Groups[1].Value, CultureInfo.InvariantCulture); return bits < 1 || bits > 53 ? null : bits <= 24 ? "real" : "float(53)"; }
            if (new[] { "char", "varchar", "nchar", "nvarchar", "binary", "varbinary" }.Contains(type)) return type + "(30)";
            if (type == "datetime2" || type == "time") return type + "(7)";
            var dec = Regex.Match(type, "\\Adecimal\\(([0-9]+),([0-9]+)\\)\\z");
            if (dec.Success) { int p = Int32.Parse(dec.Groups[1].Value), s = Int32.Parse(dec.Groups[2].Value); return p < 1 || p > 38 || s > p ? null : type; }
            var sized = Regex.Match(type, "\\A(n?var(?:char|binary)|n?char|binary)\\((max|[0-9]+)\\)\\z");
            if (sized.Success) { string size = sized.Groups[2].Value, family = sized.Groups[1].Value; if (size == "max") return family.Contains("var") ? type : null; int n = Int32.Parse(size); return n < 1 || n > (family.StartsWith("n", StringComparison.Ordinal) ? 4000 : 8000) ? null : type; }
            var time = Regex.Match(type, "\\A(?:datetime2|time)\\(([0-9]+)\\)\\z");
            if (time.Success && Int32.Parse(time.Groups[1].Value) > 7) return null;
            return type;
        }
        internal static string Binary(string left, string right, string operation)
        {
            if (left == null || right == null) return null;
            var l = Regex.Match(left, "\\A(n?varchar)\\((max|[0-9]+)\\)\\z"); var r = Regex.Match(right, "\\A(n?varchar)\\((max|[0-9]+)\\)\\z");
            if (operation == "Add" && l.Success && r.Success && l.Groups[1].Value == r.Groups[1].Value)
            {
                string family = l.Groups[1].Value;
                return family + "(" + (l.Groups[2].Value == "max" || r.Groups[2].Value == "max" ? "max" : Math.Min(family == "nvarchar" ? 4000 : 8000, Int32.Parse(l.Groups[2].Value) + Int32.Parse(r.Groups[2].Value)).ToString(CultureInfo.InvariantCulture)) + ")";
            }
            if (Integer(left) && Integer(right)) return new[] { "tinyint", "smallint", "int", "bigint" }[Math.Max(Rank(left), Rank(right))];
            int p1, s1, p2, s2;
            if (DecimalType(left, out p1, out s1) && DecimalType(right, out p2, out s2))
            {
                int precision, scale;
                switch (operation) {
                    case "Add": case "Subtract": scale = Math.Max(s1, s2); precision = scale + Math.Max(p1 - s1, p2 - s2) + 1; break;
                    case "Multiply": precision = p1 + p2 + 1; scale = s1 + s2; break;
                    case "Divide": scale = Math.Max(6, s1 + p2 + 1); precision = p1 - s1 + s2 + scale; break;
                    case "Modulo": scale = Math.Max(s1, s2); precision = Math.Min(p1 - s1, p2 - s2) + scale; break;
                    default: return null;
                }
                if (precision > 38) {
                    int integral = precision - scale;
                    if (operation == "Multiply" || operation == "Divide") scale = integral <= 32 ? Math.Min(scale, 38 - integral) : Math.Min(scale, 6);
                    else scale = Math.Max(0, Math.Min(scale, 38 - integral));
                    precision = 38;
                }
                return "decimal(" + precision + "," + scale + ")";
            }
            if (left == right && (left == "real" || left == "float(53)" || left == "money" || left == "smallmoney")) return left;
            return null;
        }
        internal static string Function(string name, string type)
        {
            if (type == null) return null;
            int p, s; bool dec = type.StartsWith("decimal(", StringComparison.Ordinal) && DecimalType(type, out p, out s);
            DecimalType(type, out p, out s);
            if (name == "MIN" || name == "MAX" || name == "NULLIF") return type;
            if (name == "ROUND") { if (Integer(type)) return type == "bigint" ? "bigint" : "int"; if (dec) return type; if (type == "real" || type == "float(53)") return "float(53)"; if (type == "money" || type == "smallmoney") return "money"; return null; }
            if (name == "AVG" || name == "SUM") {
                if (Integer(type)) return type == "bigint" ? "bigint" : "int";
                if (dec) return "decimal(38," + (name == "AVG" ? Math.Max(s, 6) : s) + ")";
                if (type == "float(53)" || type == "real") return "float(53)";
                if (type == "money" || type == "smallmoney") return "money";
            }
            if (name == "ABS" || name == "CEILING" || name == "FLOOR") {
                if (Integer(type)) return type == "bigint" ? "bigint" : "int";
                // Dezimale CEILING/FLOOR-Metadaten bis zur nativen
                // Versionsqualifikation nur mit explizitem äußerem CAST.
                if (dec) return name == "ABS" ? "decimal(38," + s + ")" : null;
                if (type == "float(53)" || type == "real" || type == "bit") return "float(53)";
                if (type == "money" || type == "smallmoney") return "money";
            }
            if (new[] { "UPPER", "LOWER", "LTRIM", "RTRIM" }.Contains(name) && Regex.IsMatch(type, "\\A(n?varchar)\\((max|[0-9]+)\\)\\z")) return type;
            return null; // Ohne Beweis nur unter ausdrücklichem CAST verwendbar.
        }
    }
}
