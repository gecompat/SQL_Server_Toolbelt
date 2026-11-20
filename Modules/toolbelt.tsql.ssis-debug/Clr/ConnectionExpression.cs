using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;

namespace Toolbelt.Tsql.SsisDebug
{
    // Wertet nur lokale SSIS-Start-/Connectionausdrücke aus. Kein SQL, kein
    // Netzwerk und kein Reflection-/Script-Execute. AST vor Auswertung bauen,
    // damit ?:, && und || nicht benötigte Zweige nicht auflösen.
    internal sealed class ConnectionExpression
    {
        private readonly string text;
        private readonly Func<string, object> resolve;
        private readonly Toolbelt.Ssis.Exchange.ResourceLimits limits;
        private int offset, tokens, nodes, depth, evaluating;
        private string token;
        private object value;
        internal ConnectionExpression(string expression, Func<string, object> resolver, Toolbelt.Ssis.Exchange.ResourceLimits resourceLimits)
        {
            text = expression ?? ""; resolve = resolver; limits = resourceLimits;
            limits.Check("expressionBytes", (long)text.Length * 2);
            Next();
        }
        private static DebugFault Invalid() { return new DebugFault("unresolved_binding", "Start-/Connectionausdruck ist unvollständig, nicht unterstützt oder nicht typgerecht."); }
        private Func<object> Node(Func<object> node)
        {
            limits.Check("expressionNodes", ++nodes);
            return () =>
            {
                if (++evaluating > 64) { evaluating--; throw Invalid(); }
                try { object result = node(); if (result is string) limits.Check("expressionBytes", (long)((string)result).Length * 2); return result; }
                finally { evaluating--; }
            };
        }
        private static string Text(object v)
        {
            if (v == null) return null;
            var number = v as JsonNumber;
            return number != null ? number.Text : Convert.ToString(v, CultureInfo.InvariantCulture);
        }
        private static decimal Number(object v)
        {
            decimal n;
            if (v is bool || v == null || !Decimal.TryParse(Text(v), NumberStyles.Float, CultureInfo.InvariantCulture, out n)) throw Invalid();
            return n;
        }
        private static bool Boolean(object v) { if (!(v is bool)) throw Invalid(); return (bool)v; }
        internal object Evaluate()
        {
            Func<object> node = Conditional();
            if (token != "end") throw Invalid();
            try { return node(); }
            catch (OverflowException) { throw Invalid(); }
            catch (DivideByZeroException) { throw Invalid(); }
            catch (ArgumentOutOfRangeException) { throw Invalid(); }
        }
        private Func<object> Conditional()
        {
            if (++depth > 64) throw Invalid();
            try
            {
                Func<object> condition = Binary(0);
                if (!Take("?")) return condition;
                Func<object> yes = Conditional(); Require(":"); Func<object> no = Conditional();
                return Node(() => Boolean(condition()) ? yes() : no());
            }
            finally { depth--; }
        }
        private static readonly string[][] Operators = {
            new[] { "||" }, new[] { "&&" }, new[] { "==", "!=" },
            new[] { "<", "<=", ">", ">=" }, new[] { "+", "-" }, new[] { "*", "/", "%" }
        };
        private Func<object> Binary(int level)
        {
            if (level == Operators.Length) return Unary();
            Func<object> left = Binary(level + 1);
            while (Array.IndexOf(Operators[level], token) >= 0)
            {
                string op = token; Next(); Func<object> a = left, b = Binary(level + 1);
                left = Node(() => Apply(op, a, b));
            }
            return left;
        }
        private static object Apply(string op, Func<object> left, Func<object> right)
        {
            object a = left();
            if (op == "&&") return Boolean(a) && Boolean(right());
            if (op == "||") return Boolean(a) || Boolean(right());
            object b = right();
            if (op == "+" && a is string && b is string) return (string)a + (string)b;
            if (op == "==" || op == "!=")
            {
                bool equal = a == null || b == null ? a == b : a is string && b is string ? String.Equals((string)a, (string)b, StringComparison.Ordinal) : a is bool && b is bool ? (bool)a == (bool)b : Number(a) == Number(b);
                return op == "==" ? equal : !equal;
            }
            if (a == null || b == null || a is string || b is string)
            {
                if (!(a is string) || !(b is string)) throw Invalid();
                int c = String.CompareOrdinal((string)a, (string)b);
                switch (op) { case "<": return c < 0; case "<=": return c <= 0; case ">": return c > 0; case ">=": return c >= 0; }
                throw Invalid();
            }
            decimal x = Number(a), y = Number(b);
            switch (op)
            {
                case "+": return x + y; case "-": return x - y; case "*": return x * y;
                case "/": return x / y; case "%": return x % y;
                case "<": return x < y; case "<=": return x <= y; case ">": return x > y; case ">=": return x >= y;
                default: throw Invalid();
            }
        }
        private Func<object> Unary()
        {
            if (++depth > 64) throw Invalid();
            try
            {
                if (token == "!" || token == "+" || token == "-")
                {
                    string op = token; Next(); Func<object> operand = Unary();
                    return Node(() => op == "!" ? (object)!Boolean(operand()) : op == "-" ? -Number(operand()) : Number(operand()));
                }
                if (Take("("))
                {
                    if (token == "identifier" && ((string)value).StartsWith("DT_", StringComparison.Ordinal))
                    {
                        string type = (string)value; Next(); var arguments = new List<int>();
                        while (Take(",")) { if (token != "number") throw Invalid(); int n; if (!Int32.TryParse(Text(value), NumberStyles.None, CultureInfo.InvariantCulture, out n)) throw Invalid(); arguments.Add(n); Next(); }
                        Require(")"); Func<object> operand = Unary();
                        if (type == "DT_WSTR" && arguments.Count == 1 && arguments[0] > 0)
                            return Node(() => { string s = Text(operand()); if (s != null && s.Length > arguments[0]) throw Invalid(); return s; });
                        if ((type == "DT_I4" || type == "DT_I8") && arguments.Count == 0)
                            return Node(() => { decimal n = Number(operand()); if (Decimal.Truncate(n) != n || n < (type == "DT_I4" ? Int32.MinValue : Int64.MinValue) || n > (type == "DT_I4" ? Int32.MaxValue : Int64.MaxValue)) throw Invalid(); return n; });
                        throw Invalid();
                    }
                    Func<object> inner = Conditional(); Require(")"); return inner;
                }
                if (token == "reference") { string name = (string)value; Next(); return Node(() => resolve(name)); }
                if (token == "string" || token == "number" || token == "boolean" || token == "null") { object v = value; Next(); return Node(() => v); }
                if (token == "identifier")
                {
                    string name = (string)value; Next(); Require("("); var arguments = new List<Func<object>>();
                    if (token != ")") { do { arguments.Add(Conditional()); } while (Take(",")); }
                    Require(")");
                    if ((name == "UPPER" || name == "LOWER" || name == "LTRIM" || name == "RTRIM" || name == "TRIM" || name == "LEN") && arguments.Count == 1)
                        return Node(() => { string s = arguments[0]() as string; if (s == null) throw Invalid(); switch (name) { case "UPPER": return s.ToUpperInvariant(); case "LOWER": return s.ToLowerInvariant(); case "LTRIM": return s.TrimStart(' '); case "RTRIM": return s.TrimEnd(' '); case "TRIM": return s.Trim(' '); default: return (object)(decimal)s.Length; } });
                    if (name == "REPLACE" && arguments.Count == 3)
                        return Node(() => { string s = arguments[0]() as string, a = arguments[1]() as string, b = arguments[2]() as string; if (s == null || String.IsNullOrEmpty(a) || b == null) throw Invalid(); return s.Replace(a, b); });
                    throw Invalid();
                }
                throw Invalid();
            }
            finally { depth--; }
        }
        private bool Take(string expected) { if (token != expected) return false; Next(); return true; }
        private void Require(string expected) { if (!Take(expected)) throw Invalid(); }
        private void Next()
        {
            limits.Check("expressionTokens", ++tokens);
            while (offset < text.Length && Char.IsWhiteSpace(text[offset])) offset++;
            value = null;
            if (offset == text.Length) { token = "end"; return; }
            char c = text[offset++];
            if (c == '"')
            {
                var buffer = new StringBuilder(); bool closed = false;
                while (offset < text.Length)
                {
                    char next = text[offset++]; if (next == '"') { closed = true; break; }
                    if (next == '\\')
                    {
                        if (offset == text.Length) throw Invalid(); next = text[offset++];
                        switch (next) { case 'n': next = '\n'; break; case 'r': next = '\r'; break; case 't': next = '\t'; break; case '\\': case '"': break; default: throw Invalid(); }
                    }
                    buffer.Append(next);
                }
                if (!closed) throw Invalid(); token = "string"; value = buffer.ToString(); return;
            }
            if (c == '@' && offset < text.Length && text[offset] == '[')
            {
                int start = ++offset; while (offset < text.Length && text[offset] != ']') offset++;
                if (offset == text.Length || offset == start) throw Invalid(); value = text.Substring(start, offset++ - start); token = "reference"; return;
            }
            if (Char.IsDigit(c))
            {
                int start = offset - 1; while (offset < text.Length && (Char.IsDigit(text[offset]) || text[offset] == '.')) offset++;
                decimal n; if (!Decimal.TryParse(text.Substring(start, offset - start), NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out n)) throw Invalid();
                value = n; token = "number"; return;
            }
            if (Char.IsLetter(c) || c == '_')
            {
                int start = offset - 1; while (offset < text.Length && (Char.IsLetterOrDigit(text[offset]) || text[offset] == '_')) offset++;
                string word = text.Substring(start, offset - start); token = "identifier"; value = word;
                if (word == "TRUE" || word == "FALSE") { token = "boolean"; value = word == "TRUE"; }
                if (word == "NULL") { token = "null"; value = null; }
                return;
            }
            string pair = offset < text.Length ? new string(new[] { c, text[offset] }) : "";
            if (Array.IndexOf(new[] { "&&", "||", "==", "!=", "<=", ">=" }, pair) >= 0) { offset++; token = pair; return; }
            if ("+-*/%!?():,<>".IndexOf(c) >= 0) { token = c.ToString(); return; }
            throw Invalid();
        }
    }
}
