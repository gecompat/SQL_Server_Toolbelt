using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.Linq;
using System.Security.Cryptography;
using System.Text;

namespace Toolbelt.Tsql.SsisDebug
{
    internal sealed class DebugFault : Exception
    {
        internal readonly string Code;
        internal DebugFault(string code, string text) : base("TBX_SSISDBG_" + code + ": " + text) { Code = code; }
    }

    // Pro Aufruf eigener Zustand; kein veränderlicher globaler Cache in SQL CLR.
    internal sealed class Budget
    {
        private readonly Stopwatch watch = Stopwatch.StartNew();
        internal int SqlCalls, CatalogCalls;
        internal void Check() { if (watch.ElapsedMilliseconds > 30000) throw new DebugFault("resource_limit", "Analysebudget erschöpft."); }
        internal static void Limit(long actual, long maximum) { if (actual > maximum) throw new DebugFault("resource_limit", "Feste V1-Grenze überschritten."); }
    }

    // Numerische JSON-Lexeme bleiben exakt: kein Zwischenweg über Double.
    internal sealed class JsonNumber
    {
        internal readonly string Text;
        internal JsonNumber(string text) { Text = text; }
        public override string ToString() { return Text; }
    }

    internal static class Json
    {
        internal static Dictionary<string, object> Obj(params object[] pairs)
        {
            var r = new Dictionary<string, object>(StringComparer.Ordinal);
            for (int i = 0; i < pairs.Length; i += 2) r.Add((string)pairs[i], pairs[i + 1]);
            return r;
        }
        internal static Dictionary<string, object> Object(object v)
        {
            var r = v as Dictionary<string, object>;
            if (r == null) throw new DebugFault("invalid_template", "JSON-Objekt erwartet.");
            return r;
        }
        internal static List<object> Array(object v)
        {
            var r = v as List<object>;
            if (r == null) throw new DebugFault("invalid_template", "JSON-Array erwartet.");
            return r;
        }
        internal static string Text(object v)
        {
            if (!(v is string)) throw new DebugFault("invalid_template", "JSON-String erwartet.");
            return (string)v;
        }
        internal static object Get(Dictionary<string, object> o, string key, object fallback = null) { object v; return o.TryGetValue(key, out v) ? v : fallback; }
        internal static bool Bool(Dictionary<string, object> o, string key)
        {
            object v = Get(o, key, false);
            if (!(v is bool)) throw new DebugFault("invalid_template", "JSON-Boolean erwartet.");
            return (bool)v;
        }
        internal static void Keys(Dictionary<string, object> o, params string[] names)
        {
            foreach (string k in o.Keys) if (!names.Contains(k, StringComparer.Ordinal)) throw new DebugFault("invalid_template", "Unbekanntes JSON-Feld.");
        }
        internal static void Version(Dictionary<string, object> o)
        {
            object v = Get(o, "schemaVersion");
            if (!(v is JsonNumber) || ((JsonNumber)v).Text != "1") throw new DebugFault("invalid_template", "schemaVersion muss 1 sein.");
        }
        internal static object Parse(string text)
        {
            Budget.Limit((long)text.Length * 2, 4194304);
            return new Reader(text).Read();
        }
        internal static string Write(object value)
        {
            var b = new StringBuilder(); Append(b, value, 0); return b.ToString();
        }
        private static void Append(StringBuilder b, object v, int depth)
        {
            Budget.Limit(depth, 32); Budget.Limit((long)b.Length * 2, 50331648);
            if (v == null) { b.Append("null"); return; }
            if (v is string) { Quote(b, (string)v); return; }
            if (v is bool) { b.Append((bool)v ? "true" : "false"); return; }
            if (v is JsonNumber) { b.Append(((JsonNumber)v).Text); return; }
            var o = v as Dictionary<string, object>;
            if (o != null)
            {
                b.Append('{'); bool first = true;
                foreach (string k in o.Keys.OrderBy(k => k, StringComparer.Ordinal))
                { if (!first) b.Append(','); first = false; Quote(b, k); b.Append(':'); Append(b, o[k], depth + 1); }
                b.Append('}'); return;
            }
            var a = v as IEnumerable;
            if (a != null)
            {
                b.Append('['); bool first = true;
                foreach (object x in a) { if (!first) b.Append(','); first = false; Append(b, x, depth + 1); }
                b.Append(']'); return;
            }
            b.Append(Convert.ToString(v, CultureInfo.InvariantCulture));
        }
        private static void Quote(StringBuilder b, string s)
        {
            b.Append('"');
            foreach (char c in s)
            {
                switch (c)
                {
                    case '"': b.Append("\\\""); break;
                    case '\\': b.Append("\\\\"); break;
                    default: if (c < 32 || Char.IsSurrogate(c)) b.Append("\\u" + ((int)c).ToString("x4", CultureInfo.InvariantCulture)); else b.Append(c); break;
                }
            }
            b.Append('"');
        }
        // Zusätzlicher strikter Scanner für Duplicate Keys, Tiefe und kanonische
        // Werte. Der SQL-Adapter prüft dieselben Eingaben außerdem nativ mit OPENJSON.
        private sealed class Reader
        {
            private readonly string s; private int p, nodes;
            internal Reader(string text) { s = text; }
            private void Space() { while (p < s.Length && (s[p] == ' ' || s[p] == '\r' || s[p] == '\n' || s[p] == '\t')) p++; }
            private DebugFault Bad() { return new DebugFault("invalid_template", "Ungültiges oder mehrdeutiges JSON."); }
            internal object Read() { object v = Value(0); Space(); if (p != s.Length) throw Bad(); return v; }
            private object Value(int depth)
            {
                Budget.Limit(depth, 32); Budget.Limit(++nodes, 131072); Space(); if (p >= s.Length) throw Bad();
                char c = s[p++];
                if (c == '"') return String();
                if (c == '{')
                {
                    var o = Obj(); Space(); if (Take('}')) return o;
                    do { Space(); if (!Take('"')) throw Bad(); string k = String(); Space(); if (!Take(':') || o.ContainsKey(k)) throw Bad(); o.Add(k, Value(depth + 1)); Space(); } while (Take(','));
                    if (!Take('}')) throw Bad(); return o;
                }
                if (c == '[')
                {
                    var a = new List<object>(); Space(); if (Take(']')) return a;
                    do { a.Add(Value(depth + 1)); Space(); } while (Take(','));
                    if (!Take(']')) throw Bad(); return a;
                }
                if (c == 't' && Tail("rue")) return true;
                if (c == 'f' && Tail("alse")) return false;
                if (c == 'n' && Tail("ull")) return null;
                p--; int start = p; if (Take('-') && p == s.Length) throw Bad();
                if (!Take('0')) { if (p >= s.Length || s[p] < '1' || s[p] > '9') throw Bad(); while (Digit()) p++; }
                if (Take('.')) { int q = p; while (Digit()) p++; if (p == q) throw Bad(); }
                if (Take('e') || Take('E')) { if (!Take('+')) Take('-'); int q = p; while (Digit()) p++; if (p == q) throw Bad(); }
                return new JsonNumber(s.Substring(start, p - start));
            }
            private bool Digit() { return p < s.Length && s[p] >= '0' && s[p] <= '9'; }
            private bool Take(char c) { if (p < s.Length && s[p] == c) { p++; return true; } return false; }
            private bool Tail(string tail) { if (p + tail.Length > s.Length || System.String.CompareOrdinal(s, p, tail, 0, tail.Length) != 0) return false; p += tail.Length; return true; }
            private string String()
            {
                var b = new StringBuilder();
                while (p < s.Length)
                {
                    char c = s[p++]; if (c == '"')
                    {
                        string result = b.ToString();
                        for (int i = 0; i < result.Length; i++)
                            if (Char.IsHighSurrogate(result[i])) { if (++i >= result.Length || !Char.IsLowSurrogate(result[i])) throw Bad(); }
                            else if (Char.IsLowSurrogate(result[i])) throw Bad();
                        return result;
                    }
                    if (c < 32) throw Bad();
                    if (c == '\\')
                    {
                        if (p == s.Length) throw Bad(); c = s[p++];
                        switch (c)
                        {
                            case '"': case '\\': case '/': break;
                            case 'b': c = '\b'; break; case 'f': c = '\f'; break; case 'n': c = '\n'; break; case 'r': c = '\r'; break; case 't': c = '\t'; break;
                            case 'u': int n; if (p + 4 > s.Length || !Int32.TryParse(s.Substring(p, 4), NumberStyles.AllowHexSpecifier, CultureInfo.InvariantCulture, out n)) throw Bad(); c = (char)n; p += 4; break;
                            default: throw Bad();
                        }
                    }
                    b.Append(c);
                }
                throw Bad();
            }
        }
    }

    internal static class Util
    {
        // COLLATE verlangt einen undelimitierten Namen. Nur das geschlossene
        // ASCII-Tokenprofil zulassen; die fachliche Existenz prüft der Katalog.
        internal static string CollationToken(string name)
        {
            if (String.IsNullOrEmpty(name) || name.Length > 128 || name.Any(c => !(c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z' || c >= '0' && c <= '9' || c == '_')))
                throw new DebugFault("unresolved_binding", "Ungültiger Collationname.");
            return name;
        }
        internal static string Q(string name) { if (String.IsNullOrEmpty(name) || name.Length > 128 || name.IndexOf('\0') >= 0) throw new DebugFault("unresolved_binding", "Ungültiger SQL-Identifier."); return "[" + name.Replace("]", "]]") + "]"; }
        internal static string L(string text) { return "N'" + text.Replace("'", "''") + "'"; }
        internal static string Hash(byte[] bytes) { using (var h = SHA256.Create()) return BitConverter.ToString(h.ComputeHash(bytes)).Replace("-", ""); }
        internal static string Hash(string text) { return Hash(Encoding.UTF8.GetBytes(text)); }
        internal static bool Flag(string value) { return value == "1" || String.Equals(value, "true", StringComparison.OrdinalIgnoreCase); }
        internal static string Id(string prefix, int n) { return prefix + n.ToString("D4", CultureInfo.InvariantCulture); }
    }

    internal sealed class Artifact
    {
        internal string Kind, Target, Stage, Component, Evidence = "descriptive", Severity, Code, Safety = "not_applicable", Content, Details;
        internal bool Complete = true, Executable;
        internal int Ordinal;
    }

    internal sealed class Artifacts
    {
        internal readonly List<Artifact> Rows = new List<Artifact>(); private long bytes; private int diagnostics;
        internal void Add(Artifact a)
        {
            Budget.Limit(Rows.Count + 1, 10000);
            if (a.Kind == "Diagnostic") Budget.Limit(++diagnostics, 1000);
            if (a.Content == null) a.Content = "";
            if (a.Kind.EndsWith("Sql", StringComparison.Ordinal)) Budget.Limit((long)a.Content.Length * 2, 2097152);
            bytes += 2L * (a.Content.Length + (a.Details ?? "").Length); Budget.Limit(bytes, 8388608);
            a.Ordinal = Rows.Count + 1; Rows.Add(a);
        }
        internal void Diagnostic(string code, string component, string text, string target = null)
        { Add(new Artifact { Kind = "Diagnostic", Code = code, Component = component, Target = target, Severity = "warning", Evidence = "pragmatic", Content = text, Complete = false, Safety = "not_checked" }); }
        internal void BindCatalog(object binding)
        {
            foreach (var row in Rows.Where(a => a.Kind.EndsWith("Sql", StringComparison.Ordinal) || a.Kind == "StageIndex"))
            {
                var details = row.Details == null ? Json.Obj() : Json.Object(Json.Parse(row.Details));
                details.Add("catalogBinding", binding); string json = Json.Write(details);
                bytes += 2L * (json.Length - (row.Details ?? "").Length); Budget.Limit(bytes, 8388608); row.Details = json;
            }
        }
    }
}
