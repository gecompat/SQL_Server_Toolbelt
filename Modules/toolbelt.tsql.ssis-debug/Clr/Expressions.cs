using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;

namespace Toolbelt.Tsql.SsisDebug
{
    internal sealed class ExpressionValue
    {
        internal string Sql, Type, Predicate;
        internal bool Nullable;
        internal readonly HashSet<string> Inputs = new HashSet<string>(StringComparer.Ordinal);
        internal string Condition { get { return Predicate ?? "(" + Sql + " = 1)"; } }
    }
    internal sealed class ExpressionParser
    {
        private readonly string source, scope; private int p, depth, nodes; private string token; private bool quoted, variable;
        private readonly Package package; private readonly Func<Input, ExpressionValue> resolve;
        private readonly Dictionary<string, ExpressionValue> columns;
        internal ExpressionParser(string text, Package pkg, string context, Dictionary<string, ExpressionValue> cols, Func<Input, ExpressionValue> inputs)
        { Budget.Limit((long)text.Length * 2, 16384); source = text; package = pkg; scope = context; columns = cols; resolve = inputs; Next(); }
        private DebugFault Bad() { return new DebugFault("unsupported_expression", "SSIS-Ausdruck nicht in der gebundenen V1-Teilmenge."); }
        internal ExpressionValue Parse()
        { ExpressionValue value = Conditional(); if (token != "") throw Bad(); return value; }
        internal static IEnumerable<string> References(string text)
        {
            var lexer = new ExpressionParser(text, null, null, null, null);
            while (lexer.token != "" || lexer.quoted || lexer.variable) { if (lexer.variable) yield return lexer.token; lexer.Next(); }
        }
        private void Enter() { Budget.Limit(++depth, 64); Budget.Limit(++nodes, 4096); }
        private ExpressionValue Conditional()
        {
            Enter(); ExpressionValue left = Binary(0);
            if (Take("?"))
            {
                if (left.Type != "bit") throw Bad();
                ExpressionValue yes = Conditional(); Need(":"); ExpressionValue no = Conditional();
                left = Combine("CASE WHEN " + left.Condition + " THEN " + yes.Sql + " ELSE " + no.Sql + " END", Common(yes, no), yes.Nullable || no.Nullable, left, yes, no);
            }
            depth--; return left;
        }
        private static readonly string[][] Operators = { new[] { "||" }, new[] { "&&" }, new[] { "==", "!=", "<", "<=", ">", ">=" }, new[] { "+", "-" }, new[] { "*", "/", "%" } };
        private ExpressionValue Binary(int precedence)
        {
            Enter(); ExpressionValue value = precedence == Operators.Length ? Unary() : Binary(precedence + 1);
            while (precedence < Operators.Length && !quoted && Operators[precedence].Contains(token))
            {
                string op = token; Next(); ExpressionValue right = Binary(precedence + 1);
                if (op == "&&" || op == "||") { if (value.Type != "bit" || right.Type != "bit") throw Bad(); value = Boolean("(" + value.Condition + (op == "&&" ? " AND " : " OR ") + right.Condition + ")", value.Nullable || right.Nullable, value, right); }
                else if (precedence == 2) value = Boolean("(" + value.Sql + (op == "==" ? " = " : op == "!=" ? " <> " : " " + op + " ") + right.Sql + ")", value.Nullable || right.Nullable, value, right);
                else
                {
                    string type = Common(value, right);
                    if (op == "+" && Text(type)) value = Combine("(CONVERT(nvarchar(max), " + value.Sql + ") + CONVERT(nvarchar(max), " + right.Sql + "))", "nvarchar(max)", value.Nullable || right.Nullable, value, right);
                    else { if (Text(value.Type) || Text(right.Type) || value.Type == "bit" || right.Type == "bit") throw Bad(); value = Combine("(" + value.Sql + " " + op + " " + right.Sql + ")", type, value.Nullable || right.Nullable, value, right); }
                }
            }
            depth--; return value;
        }
        private ExpressionValue Unary()
        {
            Enter(); ExpressionValue value;
            if (Take("!")) { value = Unary(); if (value.Type != "bit") throw Bad(); value = Boolean("(NOT " + value.Condition + ")", value.Nullable, value); }
            else if (!quoted && (token == "+" || token == "-")) { string op = token; Next(); value = Unary(); if (Text(value.Type) || value.Type == "bit") throw Bad(); value = Combine("(" + op + value.Sql + ")", value.Type, value.Nullable, value); }
            else value = Atom(); depth--; return value;
        }
        private ExpressionValue Atom()
        {
            if (token == "" && !quoted) throw Bad();
            if (quoted) { string s = token; Next(); return new ExpressionValue { Sql = Util.L(s), Type = "nvarchar(max)" }; }
            if (variable) { Input input = package.Resolve(token, scope); Next(); return resolve(input); }
            if (Take("("))
            {
                if (token.StartsWith("DT_", StringComparison.Ordinal))
                {
                    string type = token.Substring(3).ToLowerInvariant(); Next(); var args = new List<int>();
                    while (Take(",")) { int n; if (!Int32.TryParse(token, NumberStyles.None, CultureInfo.InvariantCulture, out n)) throw Bad(); args.Add(n); Next(); }
                    Need(")"); string sql = Types.Sql(type, args.Count > 0 ? args[0] : 0, type == "numeric" && args.Count > 0 ? args[0] : 0, type == "numeric" && args.Count > 1 ? args[1] : type == "decimal" && args.Count > 0 ? args[0] : 0);
                    // ANSI-Konvertierung braucht einen gebundenen Codepagevertrag;
                    // keine ungeprüfte CAST-Abbildung über die Caller-Collation.
                    if (sql == null || type == "str") throw Bad(); ExpressionValue v = Unary(); return Combine("CAST(" + v.Sql + " AS " + sql + ")", sql, v.Nullable, v);
                }
                ExpressionValue inside = Conditional(); Need(")"); return inside;
            }
            string name = token; Next();
            if (name == "TRUE" || name == "FALSE") return new ExpressionValue { Sql = name == "TRUE" ? "CAST(1 AS bit)" : "CAST(0 AS bit)", Type = "bit" };
            if (name == "NULL") return new ExpressionValue { Sql = "NULL", Type = "null", Nullable = true };
            if (name.Length > 0 && name[0] >= '0' && name[0] <= '9')
            {
                decimal d; if (!Decimal.TryParse(name, NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out d)) throw Bad();
                return new ExpressionValue { Sql = name, Type = name.IndexOf('.') >= 0 ? "decimal(38,18)" : d <= Int32.MaxValue ? "int" : "bigint" };
            }
            if (Take("("))
            {
                ExpressionValue one = Conditional();
                if (name == "ISNULL") { Need(")"); return Boolean("(" + one.Sql + " IS NULL)", false, one); }
                if (name == "REPLACENULL") { Need(","); ExpressionValue two = Conditional(); Need(")"); return Combine("ISNULL(" + one.Sql + ", " + two.Sql + ")", Common(one, two), one.Nullable && two.Nullable, one, two); }
                throw Bad();
            }
            ExpressionValue column; if (!columns.TryGetValue(name, out column)) throw Bad(); return column;
        }
        private static bool Text(string type) { return type != null && (type.StartsWith("nvarchar", StringComparison.Ordinal) || type.StartsWith("varchar", StringComparison.Ordinal)); }
        private string Common(ExpressionValue a, ExpressionValue b)
        {
            if (a.Type == "null") return b.Type; if (b.Type == "null") return a.Type; if (a.Type == b.Type) return a.Type;
            if (Text(a.Type) && Text(b.Type)) return "nvarchar(max)";
            if (Text(a.Type) || Text(b.Type) || a.Type == "bit" || b.Type == "bit") throw Bad();
            if (a.Type.StartsWith("float", StringComparison.Ordinal) || b.Type.StartsWith("float", StringComparison.Ordinal)) return "float(53)";
            if (a.Type == "real" || b.Type == "real") return "real";
            if (a.Type.StartsWith("decimal", StringComparison.Ordinal) || b.Type.StartsWith("decimal", StringComparison.Ordinal)) return "decimal(38,18)";
            return "bigint";
        }
        private static ExpressionValue Combine(string sql, string type, bool nullable, params ExpressionValue[] values)
        {
            var r = new ExpressionValue { Sql = sql, Type = type, Nullable = nullable };
            foreach (var v in values) r.Inputs.UnionWith(v.Inputs); return r;
        }
        private static ExpressionValue Boolean(string condition, bool nullable, params ExpressionValue[] values)
        {
            var r = Combine("CAST(CASE WHEN " + condition + " THEN 1 WHEN NOT " + condition + " THEN 0 ELSE NULL END AS bit)", "bit", nullable, values); r.Predicate = condition; return r;
        }
        private bool Take(string value) { if (!quoted && !variable && token == value) { Next(); return true; } return false; }
        private void Need(string value) { if (!Take(value)) throw Bad(); }
        private void Next()
        {
            quoted = variable = false; while (p < source.Length && Char.IsWhiteSpace(source[p])) p++;
            if (p == source.Length) { token = ""; return; }
            char c = source[p++];
            if (c == '"')
            {
                quoted = true; var b = new StringBuilder(); bool closed = false;
                while (p < source.Length)
                {
                    c = source[p++]; if (c == '"') { closed = true; break; }
                    if (c == '\\') { if (p == source.Length) throw Bad(); c = source[p++]; if (c == 'n') c = '\n'; else if (c == 'r') c = '\r'; else if (c == 't') c = '\t'; else if (c != '\\' && c != '"') throw Bad(); } b.Append(c);
                }
                if (!closed) throw Bad(); token = b.ToString(); return;
            }
            if (c == '@')
            {
                variable = true; int start = p - 1;
                if (p < source.Length && source[p] == '[') { while (p < source.Length && source[p] != ']') p++; if (p == source.Length) throw Bad(); p++; }
                else while (p < source.Length && (Char.IsLetterOrDigit(source[p]) || "_:$".IndexOf(source[p]) >= 0)) p++;
                token = source.Substring(start, p - start); return;
            }
            if (c == '[' || c == '#')
            {
                int start = p; char end = ']';
                if (c == '#') { if (p < source.Length && source[p] == '{') { p++; start = p; end = '}'; } else { while (p < source.Length && Char.IsDigit(source[p])) p++; token = "#" + source.Substring(start, p - start); return; } }
                while (p < source.Length && source[p] != end) p++; if (p == source.Length) throw Bad(); token = source.Substring(start, p - start); p++; return;
            }
            if (Char.IsLetter(c) || c == '_' || Char.IsDigit(c))
            {
                int start = p - 1; bool number = Char.IsDigit(c);
                while (p < source.Length && (Char.IsLetterOrDigit(source[p]) || source[p] == '_' || number && source[p] == '.')) p++;
                token = source.Substring(start, p - start); return;
            }
            token = c.ToString();
            if (p < source.Length && new[] { "==", "!=", "<=", ">=", "&&", "||" }.Contains(token + source[p])) token += source[p++];
        }
    }
}
