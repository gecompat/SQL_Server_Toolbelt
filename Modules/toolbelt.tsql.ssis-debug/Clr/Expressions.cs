using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;

namespace Toolbelt.Tsql.SsisDebug
{
    internal sealed class SqlText
    {
        private readonly object[] parts;
        private readonly string text;
        internal long Length { get; private set; }
        internal SqlText(string value) { text = value ?? ""; Length = text.Length; }
        private SqlText(object[] values)
        {
            parts = values; long length = 0;
            foreach (object value in values) { var nested = value as SqlText; length = checked(length + (nested == null ? ((string)value).Length : nested.Length)); }
            Length = length;
        }
        internal static SqlText Join(params object[] values) { return new SqlText(values); }
        internal string Render()
        {
            if (Length > Int32.MaxValue) throw new DebugFault("resource_limit", "counter=sqlArtifactBytes; actual=" + checked(Length * 2).ToString(CultureInfo.InvariantCulture) + "; limit=" + Int32.MaxValue.ToString(CultureInfo.InvariantCulture) + "; profile=platform-string-limit.");
            var builder = new StringBuilder((int)Length); var pending = new Stack<object>(); pending.Push(this);
            while (pending.Count != 0)
            {
                object item = pending.Pop(); var nested = item as SqlText;
                if (nested != null)
                {
                    if (nested.parts == null) builder.Append(nested.text);
                    else for (int i = nested.parts.Length - 1; i >= 0; i--) pending.Push(nested.parts[i]);
                }
                else builder.Append((string)item);
            }
            return builder.ToString();
        }
        public override string ToString() { return Render(); }
    }
    internal sealed class ExpressionValue
    {
        private string sql, predicate;
        private SqlText deferredSql, deferredPredicate;
        internal string Sql { get { return deferredSql == null ? sql : deferredSql.Render(); } set { sql = value; deferredSql = null; } }
        internal SqlText SqlValue { get { return deferredSql ?? new SqlText(sql); } set { deferredSql = value; sql = null; } }
        internal string Predicate { get { return deferredPredicate == null ? predicate : deferredPredicate.Render(); } set { predicate = value; deferredPredicate = null; } }
        internal SqlText PredicateValue { get { return deferredPredicate ?? (predicate == null ? null : new SqlText(predicate)); } set { deferredPredicate = value; predicate = null; } }
        internal string Type;
        internal string RootAnsiType, RootAnsiCollation;
        internal decimal? ConstantNumber;
        internal string ConstantText;
        internal bool Nullable;
        internal bool Total;
        internal string BooleanOperator;
        internal List<ExpressionValue> BooleanTerms;
        internal bool AnsiTypedNull;
        internal readonly HashSet<string> Inputs = new HashSet<string>(StringComparer.Ordinal);
        internal string Condition { get { return ConditionValue.Render(); } }
        internal SqlText ConditionValue { get { return PredicateValue ?? SqlText.Join("(", SqlValue, " = 1)"); } }
    }
    internal sealed class ExpressionParser
    {
        private readonly string source, scope; private int p, depth, nodes, tokens; private string token; private bool quoted, variable, v2;
        private readonly Package package; private readonly Func<Input, ExpressionValue> resolve;
        private readonly Func<int, string> resolveCodepage;
        private readonly Toolbelt.Ssis.Exchange.ResourceLimits limits;
        private readonly Dictionary<string, ExpressionValue> columns;
        internal int ParsedTokenCount { get { return tokens; } }
        internal int ParsedNodeCount { get { return nodes; } }
        internal ExpressionParser(string text, Package pkg, string context, Dictionary<string, ExpressionValue> cols, Func<Input, ExpressionValue> inputs, bool extended = false, Func<int, string> codepage = null, Toolbelt.Ssis.Exchange.ResourceLimits resourceLimits = null)
        { v2 = extended; limits = resourceLimits ?? (extended ? Toolbelt.Ssis.Exchange.ResourceLimits.Create("large10x", true) : Toolbelt.Ssis.Exchange.ResourceLimits.Legacy); Limit("expressionBytes", (long)text.Length * 2, 16384); source = text; package = pkg; scope = context; columns = cols; resolve = inputs; resolveCodepage = codepage; Next(); }
        private void Limit(string counter, long actual, long maximum)
        { if (!v2 && !limits.DetailedDiagnostics) { Budget.Limit(actual, maximum); return; } try { limits.Check(counter, actual); } catch (Toolbelt.Ssis.Exchange.ResourceLimitException error) { throw new DebugFault("resource_limit", "counter=" + counter + "; actual=" + actual.ToString(CultureInfo.InvariantCulture) + "; limit=" + (limits.IsUnlimitedCounter(error.Counter) ? "unlimited" : error.Maximum.ToString(CultureInfo.InvariantCulture)) + "; profile=" + error.Preset + "."); } }
        private DebugFault Bad() { return new DebugFault("unsupported_expression", "SSIS-Ausdruck nicht in der gebundenen V1-Teilmenge."); }
        internal ExpressionValue Parse()
        {
            ExpressionValue value = Conditional(); if (token != "") throw Bad();
            if (v2)
            {
                long renderedLength = value.SqlValue.Length;
                if (value.RootAnsiType != null) renderedLength = checked(renderedLength + value.RootAnsiType.Length + value.RootAnsiCollation.Length + 16);
                try { limits.Check("sqlArtifactBytes", checked(renderedLength * 2)); }
                catch (Toolbelt.Ssis.Exchange.ResourceLimitException error) { throw new DebugFault("resource_limit", "counter=" + error.Counter + "; actual=" + error.Actual.ToString(CultureInfo.InvariantCulture) + "; limit=" + (limits.IsUnlimitedCounter(error.Counter) ? "unlimited" : error.Maximum.ToString(CultureInfo.InvariantCulture)) + "; profile=" + error.Preset + "."); }
            }
            if (value.RootAnsiType != null)
            {
                var root = new ExpressionValue { Sql = "CONVERT(" + value.RootAnsiType + ", (" + value.Sql + " COLLATE " + Util.CollationToken(value.RootAnsiCollation) + "))", Type = value.RootAnsiType, Nullable = value.Nullable };
                root.Inputs.UnionWith(value.Inputs); return root;
            }
            return value;
        }
        internal static IEnumerable<string> References(string text, bool extended = false, Toolbelt.Ssis.Exchange.ResourceLimits resourceLimits = null)
        {
            var lexer = new ExpressionParser(text, null, null, null, null, extended, null, resourceLimits);
            while (lexer.token != "" || lexer.quoted || lexer.variable) { if (lexer.variable) yield return lexer.token; lexer.Next(); }
        }
        private void Enter() { Budget.Limit(++depth, 64); Limit("expressionNodes", ++nodes, 4096); }
        private ExpressionValue Conditional()
        {
            Enter(); ExpressionValue left = Binary(0);
            if (Take("?"))
            {
                if (left.Type != "bit") throw Bad();
                ExpressionValue yes = Conditional(); Need(":"); ExpressionValue no = Conditional();
                string resultType = Common(yes, no);
                string condition = left.Condition;
                bool conditionTotal = left.Total;
                // SSIS liefert bei unbekannter Bedingung NULL. Ein einfaches
                // ELSE würde SQL-UNKNOWN fälschlich dem Nein-Zweig zuordnen.
                // CASE hält beide Wertzweige bedingt; der letzte Zweig ist
                // ausschließlich das typisierte NULL für den UNKNOWN-Fall.
                left = Combine("CASE WHEN " + condition + " THEN " + yes.Sql + " WHEN NOT (" + condition + ") THEN " + no.Sql + " ELSE CAST(NULL AS " + resultType + ") END", resultType, left.Nullable || yes.Nullable || no.Nullable, left, yes, no);
                left.Total = v2 && conditionTotal && yes.Total && no.Total;
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
                if (op == "&&" || op == "||")
                {
                    if (value.Type != "bit" || right.Type != "bit") throw Bad();
                    bool splittable = v2;
                    bool total = value.Total && right.Total;
                    List<ExpressionValue> terms = new List<ExpressionValue>();
                    if (splittable)
                    {
                        if (value.BooleanOperator == op && value.BooleanTerms != null) terms = value.BooleanTerms; else terms.Add(value);
                        if (right.BooleanOperator == op && right.BooleanTerms != null) terms.AddRange(right.BooleanTerms); else terms.Add(right);
                    }
                    ExpressionValue combined;
                    if (splittable && terms.Count > 16)
                    {
                        combined = new ExpressionValue { Sql = "CAST(1 AS bit)", Predicate = "CAST(1 AS bit)", Type = "bit", Nullable = value.Nullable || right.Nullable };
                        combined.Inputs.UnionWith(value.Inputs); combined.Inputs.UnionWith(right.Inputs);
                    }
                    else combined = Boolean(SqlText.Join("(", value.ConditionValue, op == "&&" ? " AND " : " OR ", right.ConditionValue, ")"), value.Nullable || right.Nullable, value, right);
                    combined.Total = splittable && total; if (splittable) { combined.BooleanOperator = op; combined.BooleanTerms = terms; }
                    value = combined;
                }
                else if (precedence == 2)
                { bool total = v2 && value.Total && right.Total; value = Boolean(SqlText.Join("(", value.SqlValue, op == "==" ? " = " : op == "!=" ? " <> " : " " + op + " ", right.SqlValue, ")"), value.Nullable || right.Nullable, value, right); value.Total = total; }
                else
                {
                    string type = Common(value, right);
                    if (op == "+" && Text(type)) value = Combine(SqlText.Join("(CONVERT(nvarchar(max), ", value.SqlValue, ") + CONVERT(nvarchar(max), ", right.SqlValue, "))"), "nvarchar(max)", value.Nullable || right.Nullable, value, right);
                    else { if (Text(value.Type) || Text(right.Type) || value.Type == "bit" || right.Type == "bit") throw Bad(); value = Combine(SqlText.Join("(", value.SqlValue, " " + op + " ", right.SqlValue, ")"), type, value.Nullable || right.Nullable, value, right); }
                }
            }
            depth--; return value;
        }
        private ExpressionValue Unary()
        {
            Enter(); ExpressionValue value;
            if (Take("!")) { value = Unary(); if (value.Type != "bit") throw Bad(); bool total = value.Total; value = Boolean("(NOT " + value.Condition + ")", value.Nullable, value); value.Total = total; }
            else if (!quoted && (token == "+" || token == "-")) { string op = token; Next(); value = Unary(); if (Text(value.Type) || value.Type == "bit") throw Bad(); decimal? constant = value.ConstantNumber; value = Combine("(" + op + value.Sql + ")", value.Type, value.Nullable, value); if (constant.HasValue) value.ConstantNumber = op == "-" ? -constant.Value : constant.Value; }
            else value = Atom(); depth--; return value;
        }
        private ExpressionValue Atom()
        {
            if (token == "" && !quoted) throw Bad();
            if (quoted) { string s = token; Next(); return new ExpressionValue { Sql = Util.L(s), Type = "nvarchar(max)", ConstantText = s, Total = v2 }; }
            if (variable) { Input input = package.Resolve(token, scope); Next(); return resolve(input); }
            if (Take("("))
            {
                if (token.StartsWith("DT_", v2 ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal))
                {
                    string type = token.Substring(3).ToLowerInvariant(); Next(); var args = new List<int>();
                    while (Take(",")) { int n; if (!Int32.TryParse(token, NumberStyles.None, CultureInfo.InvariantCulture, out n)) throw Bad(); args.Add(n); Next(); }
                    if (v2 && !ValidV2TypeArguments(type, args)) throw Bad();
                    Need(")"); string sql = Types.Sql(type, args.Count > 0 ? args[0] : 0, type == "numeric" && args.Count > 0 ? args[0] : 0, type == "numeric" && args.Count > 1 ? args[1] : type == "decimal" && args.Count > 0 ? args[0] : 0);
                    // ANSI-Konvertierung braucht einen gebundenen Codepagevertrag;
                    // keine ungeprüfte CAST-Abbildung über die Caller-Collation.
                    if (v2 && type == "str")
                    {
                        if (args.Count != 2 || args[0] <= 0 || args[0] > 8000 || args[1] <= 0 || resolveCodepage == null) throw Bad();
                        string collation = resolveCodepage(args[1]); if (collation == null) throw new DebugFault("unresolved_binding", "DT_STR-Codepage stimmt nicht mit der gebundenen Datenbankcollation überein.");
                        ExpressionValue ansi = Unary(); if (ansi.AnsiTypedNull) throw Bad();
                        string ansiType = "varchar(" + args[0].ToString(CultureInfo.InvariantCulture) + ")";
                        // Interne DT_STR-Casts werden vom SSIS-Ausdrucksauswerter
                        // zu DT_WSTR koerziert. Die ANSI-Bytekonvertierung gilt
                        // ausschließlich für einen DT_STR-Ausdruck am Wurzelknoten.
                        bool innerWideningTotal = v2 && ansi.Total && (Text(ansi.Type) || IntegerTextType(ansi.Type));
                        var internalAnsi = new ExpressionValue { Sql = "CONVERT(nvarchar(max), " + ansi.Sql + ")", Type = "nvarchar(max)", Nullable = ansi.Nullable, Total = innerWideningTotal, RootAnsiType = ansiType, RootAnsiCollation = collation, ConstantText = innerWideningTotal ? ansi.ConstantText : null };
                        internalAnsi.Inputs.UnionWith(ansi.Inputs); return internalAnsi;
                    }
                    if (sql == null || type == "str" || v2 && !new[] { "i1", "ui1", "i2", "i4", "i8", "numeric", "wstr", "dbdate", "dbtimestamp", "bool" }.Contains(type)) throw Bad(); ExpressionValue v = Unary(); if (v2 && v.AnsiTypedNull) throw Bad();
                    if (v2 && type == "i1" && v.Type != "bit" && (!v.ConstantNumber.HasValue || v.ConstantNumber.Value < -128 || v.ConstantNumber.Value > 127)) throw Bad();
                    if (v2 && type == "ui1" && v.Type == "bit") throw Bad();
                    if (v2 && v.Type == "bit" && new[] { "i1", "i2", "i4", "i8", "numeric" }.Contains(type))
                    { string boolValue = "CASE WHEN " + v.Condition + " THEN -1 WHEN NOT " + v.Condition + " THEN 0 ELSE NULL END"; return Combine("CAST(" + boolValue + " AS " + sql + ")", sql, v.Nullable, v); }
                    return Combine("CAST(" + v.Sql + " AS " + sql + ")", sql, v.Nullable, v);
                }
                ExpressionValue inside = Conditional(); Need(")"); return inside;
            }
            string name = token; Next();
            if (name == "TRUE" || name == "FALSE") return new ExpressionValue { Sql = name == "TRUE" ? "CAST(1 AS bit)" : "CAST(0 AS bit)", Type = "bit", ConstantNumber = name == "TRUE" ? -1 : 0, Total = v2 };
            if (name == "NULL" || v2 && String.Equals(name, "NULL", StringComparison.OrdinalIgnoreCase))
            {
                if (!v2 || !Take("(")) return new ExpressionValue { Sql = "NULL", Type = "null", Nullable = true };
                string cast = token; if (!cast.StartsWith("DT_", StringComparison.OrdinalIgnoreCase)) throw Bad(); Next(); var args = new List<int>();
                while (Take(",")) { int arg; if (!Int32.TryParse(token, NumberStyles.None, CultureInfo.InvariantCulture, out arg) || arg < 0) throw Bad(); args.Add(arg); Next(); }
                if (!ValidV2TypeArguments(cast.Substring(3).ToLowerInvariant(), args)) throw Bad();
                Need(")"); string nullType = V2Type(cast, args);
                string nullCollation = null;
                if (String.Equals(cast, "DT_STR", StringComparison.OrdinalIgnoreCase) && args.Count == 2 && args[0] <= 8000 && resolveCodepage != null)
                { nullCollation = resolveCodepage(args[1]); if (nullCollation == null) throw new DebugFault("unresolved_binding", "DT_STR-Codepage stimmt nicht mit der gebundenen Datenbankcollation überein."); nullType = "varchar(" + args[0].ToString(CultureInfo.InvariantCulture) + ")"; }
                if (nullType == null) throw Bad();
                return new ExpressionValue { Sql = "CAST(NULL AS " + nullType + ")" + (nullCollation == null ? "" : " COLLATE " + Util.CollationToken(nullCollation)), Type = nullType, Nullable = true, AnsiTypedNull = nullCollation != null };
            }
            if (name.Length > 0 && name[0] >= '0' && name[0] <= '9')
            {
                decimal d; if (!Decimal.TryParse(name, NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out d)) throw Bad();
                return new ExpressionValue { Sql = name, Type = name.IndexOf('.') >= 0 ? "decimal(38,18)" : d <= Int32.MaxValue ? "int" : "bigint", ConstantNumber = d, Total = v2 };
            }
            if (Take("("))
            {
                ExpressionValue one = Conditional();
                string function = v2 ? name.ToUpperInvariant() : name;
                if (v2 && one.AnsiTypedNull) throw Bad();
                if (function == "ISNULL") { Need(")"); return Boolean("(" + one.Sql + " IS NULL)", false, one); }
                if (function == "REPLACENULL") { Need(","); ExpressionValue two = Conditional(); Need(")"); return Combine("ISNULL(" + one.Sql + ", " + two.Sql + ")", Common(one, two), one.Nullable && two.Nullable, one, two); }
                if (v2 && new[] { "TRIM", "LTRIM", "RTRIM", "LEN" }.Contains(function))
                {
                    Need(")"); if (!Text(one.Type)) throw Bad(); one = Wide(one);
                    if (function == "LEN") return Combine("CAST((LEN(" + one.Sql + " + N'.') - 1) AS int)", "int", one.Nullable, one);
                    return Combine(function + "(" + one.Sql + ")", one.Type, one.Nullable, one);
                }
                if (v2 && (function == "SUBSTRING" || function == "REPLACE"))
                {
                    Need(","); ExpressionValue two = Conditional();
                    if (function == "SUBSTRING") { Need(","); ExpressionValue three = Conditional(); Need(")"); if (!Text(one.Type) || two.Type != "int" && two.Type != "bigint" || three.Type != "int" && three.Type != "bigint" || !PositiveOrZero(three.Sql) || !PositiveStart(two.Sql)) throw Bad(); one = Wide(one); return Combine("SUBSTRING(" + one.Sql + ", " + two.Sql + ", " + three.Sql + ")", one.Type, one.Nullable || two.Nullable || three.Nullable, one, two, three); }
                    Need(","); ExpressionValue replacement = Conditional(); Need(")"); if (!Text(one.Type) || !(Text(two.Type) || two.Type == "null") || !(Text(replacement.Type) || replacement.Type == "null") || two.Type != "null" && !NonEmptyLiteral(two.Sql) || one.AnsiTypedNull || two.AnsiTypedNull || replacement.AnsiTypedNull) throw Bad(); one = Wide(one); if (two.Type != "null") two = Wide(two); if (replacement.Type != "null") replacement = Wide(replacement); return Combine("REPLACE(" + one.Sql + ", " + two.Sql + ", " + replacement.Sql + ")", one.Type, one.Nullable || two.Nullable || replacement.Nullable, one, two, replacement);
                }
                throw Bad();
            }
            ExpressionValue column; if (!columns.TryGetValue(name, out column)) throw Bad(); return column;
        }
        private static bool Text(string type) { return type != null && (type.StartsWith("nvarchar", StringComparison.Ordinal) || type.StartsWith("varchar", StringComparison.Ordinal)); }
        private static bool IntegerTextType(string type)
        { return type == "tinyint" || type == "smallint" || type == "int" || type == "bigint"; }
        private static bool PositiveStart(string sql) { int value; return Int32.TryParse(sql, NumberStyles.None, CultureInfo.InvariantCulture, out value) && value > 0; }
        private static bool PositiveOrZero(string sql) { int value; return Int32.TryParse(sql, NumberStyles.None, CultureInfo.InvariantCulture, out value) && value >= 0; }
        private static bool NonEmptyLiteral(string sql) { return sql != null && (sql.StartsWith("N'", StringComparison.Ordinal) && sql.Length > 3 || sql.StartsWith("'", StringComparison.Ordinal) && sql.Length > 2); }
        private static ExpressionValue Wide(ExpressionValue value)
        { if (value.AnsiTypedNull) throw new DebugFault("unsupported_expression", "NULL(DT_STR,...) ist nur als gesamter Ausdruck zulässig."); if (value.Type != null && value.Type.StartsWith("varchar", StringComparison.Ordinal)) return Combine("CONVERT(nvarchar(max), " + value.Sql + ")", "nvarchar(max)", value.Nullable, value); return value; }
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
            if (values.Any(v => v.AnsiTypedNull)) throw new DebugFault("unsupported_expression", "NULL(DT_STR,...) ist nur als gesamter Ausdruck zulässig.");
            var r = new ExpressionValue { Sql = sql, Type = type, Nullable = nullable };
            foreach (var v in values) r.Inputs.UnionWith(v.Inputs); return r;
        }
        private static ExpressionValue Combine(SqlText sql, string type, bool nullable, params ExpressionValue[] values)
        {
            if (values.Any(v => v.AnsiTypedNull)) throw new DebugFault("unsupported_expression", "NULL(DT_STR,...) ist nur als gesamter Ausdruck zulässig.");
            var r = new ExpressionValue { Type = type, Nullable = nullable, SqlValue = sql };
            foreach (var v in values) r.Inputs.UnionWith(v.Inputs); return r;
        }
        private static ExpressionValue Boolean(string condition, bool nullable, params ExpressionValue[] values)
        {
            var r = Combine("CAST(CASE WHEN " + condition + " THEN 1 WHEN NOT " + condition + " THEN 0 ELSE NULL END AS bit)", "bit", nullable, values); r.Predicate = condition; return r;
        }
        private static ExpressionValue Boolean(SqlText condition, bool nullable, params ExpressionValue[] values)
        {
            var r = Combine(SqlText.Join("CAST(CASE WHEN ", condition, " THEN 1 WHEN NOT ", condition, " THEN 0 ELSE NULL END AS bit)"), "bit", nullable, values); r.PredicateValue = condition; return r;
        }
        private bool Take(string value) { if (!quoted && !variable && token == value) { Next(); return true; } return false; }
        private void Need(string value) { if (!Take(value)) throw Bad(); }
        private void Next()
        {
            quoted = variable = false; while (p < source.Length && Char.IsWhiteSpace(source[p])) p++;
            if (p == source.Length) { token = ""; return; }
            Limit("expressionTokens", ++tokens, 16384);
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
        private static string V2Type(string cast, List<int> args)
        {
            cast = cast.ToUpperInvariant();
            switch (cast)
            {
                case "DT_I1": return "smallint"; case "DT_UI1": return "tinyint"; case "DT_I2": return "smallint"; case "DT_I4": return "int"; case "DT_I8": return "bigint"; case "DT_BOOL": return "bit";
                case "DT_NUMERIC": return args.Count == 2 && args[0] <= 38 && args[1] <= args[0] ? "decimal(" + args[0] + "," + args[1] + ")" : null;
                case "DT_WSTR": return args.Count == 1 && args[0] <= 4000 ? "nvarchar(" + args[0] + ")" : null;
                case "DT_DBDATE": return "date"; case "DT_DBTIMESTAMP": return "datetime2(7)"; default: return null;
            }
        }
        private static bool ValidV2TypeArguments(string type, List<int> args)
        {
            if (type == "str") return args.Count == 2 && args[0] > 0 && args[0] <= 8000 && args[1] > 0;
            if (type == "wstr") return args.Count == 1 && args[0] > 0 && args[0] <= 4000;
            if (type == "numeric") return args.Count == 2 && args[0] >= 1 && args[0] <= 38 && args[1] >= 0 && args[1] <= args[0];
            return args.Count == 0;
        }
    }
}
