using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace Toolbelt.Tsql.SsisDebug
{
    internal static class Projection
    {
        internal static List<BoundColumn> Columns(SqlQuery query, SqlSafety safety)
        {
            var ctes = new Dictionary<string, CommonTableExpression>(StringComparer.Ordinal);
            if (query.Statement.WithCtesAndXmlNamespaces != null) foreach (var c in query.Statement.WithCtesAndXmlNamespaces.CommonTableExpressions) ctes.Add(c.ExpressionName.Value, c);
            return new Binder(query, safety, ctes).Query(query.Statement.QueryExpression, new Dictionary<string, List<BoundColumn>>(StringComparer.Ordinal));
        }
        private sealed class Binder
        {
            private readonly SqlQuery query; private readonly SqlSafety safety; private readonly Dictionary<string, CommonTableExpression> ctes;
            private readonly HashSet<string> active = new HashSet<string>(StringComparer.Ordinal); private int depth;
            internal Binder(SqlQuery q, SqlSafety s, Dictionary<string, CommonTableExpression> c) { query = q; safety = s; ctes = c; }
            private DebugFault Bad() { return new DebugFault("unresolved_binding", "SQL-Spalten oder Typen nicht vollständig gebunden."); }
            internal List<BoundColumn> Query(QueryExpression expression, Dictionary<string, List<BoundColumn>> outer)
            {
                Budget.Limit(++depth, 32);
                try
                {
                    var paren = expression as QueryParenthesisExpression; if (paren != null) return Query(paren.QueryExpression, outer);
                    var union = expression as BinaryQueryExpression;
                    if (union != null)
                    {
                        if (!union.All || union.BinaryQueryExpressionType != BinaryQueryExpressionType.Union) throw Bad();
                        var left = Query(union.FirstQueryExpression, outer); var right = Query(union.SecondQueryExpression, outer);
                        if (left.Count != right.Count) throw Bad();
                        for (int i = 0; i < left.Count; i++) { if (left[i].SqlType != right[i].SqlType) throw Bad(); left[i] = new BoundColumn { Name = left[i].Name, SqlType = left[i].SqlType, Collation = left[i].Collation, Nullable = left[i].Nullable || right[i].Nullable }; } return left;
                    }
                    var spec = expression as QuerySpecification; if (spec == null) throw Bad();
                    var aliases = new Dictionary<string, List<BoundColumn>>(outer, StringComparer.Ordinal);
                    if (spec.FromClause != null) foreach (TableReference table in spec.FromClause.TableReferences) Table(table, aliases);
                    var output = new List<BoundColumn>();
                    foreach (var select in spec.SelectElements)
                    {
                        var star = select as SelectStarExpression;
                        if (star != null)
                        {
                            if (star.Qualifier != null && star.Qualifier.Identifiers.Count != 0)
                            { string alias = star.Qualifier.Identifiers.Last().Value; List<BoundColumn> cols; if (!aliases.TryGetValue(alias, out cols)) throw Bad(); output.AddRange(cols); }
                            else { if (spec.FromClause == null) throw Bad(); foreach (string alias in aliases.Keys.Except(outer.Keys)) output.AddRange(aliases[alias]); }
                            continue;
                        }
                        var scalar = select as SelectScalarExpression; if (scalar == null) throw Bad();
                        BoundColumn column = Infer(scalar.Expression, aliases);
                        var reference = scalar.Expression as ColumnReferenceExpression;
                        string name = scalar.ColumnName == null ? reference == null || reference.MultiPartIdentifier == null ? null : column.Name : scalar.ColumnName.Identifier != null ? scalar.ColumnName.Identifier.Value : (scalar.ColumnName.ValueExpression as StringLiteral) == null ? null : ((StringLiteral)scalar.ColumnName.ValueExpression).Value;
                        if (name == null) throw Bad(); output.Add(new BoundColumn { Name = name, SqlType = column.SqlType, Collation = column.Collation, Nullable = column.Nullable });
                    }
                    if (spec.WhereClause != null) ValidateExpression(spec.WhereClause.SearchCondition, aliases);
                    if (spec.HavingClause != null) ValidateExpression(spec.HavingClause.SearchCondition, aliases);
                    if (spec.GroupByClause != null) ValidateExpression(spec.GroupByClause, aliases);
                    if (spec.OrderByClause != null)
                    {
                        var orderAliases = new Dictionary<string, List<BoundColumn>>(aliases, StringComparer.Ordinal); orderAliases.Add("<output>", output);
                        foreach (var item in spec.OrderByClause.OrderByElements)
                        { var r = item.Expression as ColumnReferenceExpression; if (r != null && r.MultiPartIdentifier != null && r.MultiPartIdentifier.Identifiers.Count == 1 && output.Any(c => c.Name == r.MultiPartIdentifier.Identifiers[0].Value)) continue; Infer(item.Expression, orderAliases); }
                    }
                    if (output.Count == 0 || output.GroupBy(x => x.Name, StringComparer.Ordinal).Any(g => g.Count() != 1) || output.Any(x => x.SqlType == null)) throw Bad();
                    DistinctNames(output.Select(x => x.Name));
                    return output;
                }
                finally { depth--; }
            }
            private void Table(TableReference table, Dictionary<string, List<BoundColumn>> aliases)
            {
                var join = table as QualifiedJoin;
                if (join != null)
                {
                    var before = new HashSet<string>(aliases.Keys, StringComparer.Ordinal); Table(join.FirstTableReference, aliases);
                    var left = new HashSet<string>(aliases.Keys.Except(before), StringComparer.Ordinal); Table(join.SecondTableReference, aliases);
                    var right = new HashSet<string>(aliases.Keys.Except(before).Except(left), StringComparer.Ordinal);
                    foreach (string key in aliases.Keys.ToList())
                        if (left.Contains(key) && (join.QualifiedJoinType == QualifiedJoinType.RightOuter || join.QualifiedJoinType == QualifiedJoinType.FullOuter) || right.Contains(key) && (join.QualifiedJoinType == QualifiedJoinType.LeftOuter || join.QualifiedJoinType == QualifiedJoinType.FullOuter))
                            aliases[key] = aliases[key].Select(c => new BoundColumn { Name = c.Name, SqlType = c.SqlType, Collation = c.Collation, Nullable = true, Computed = c.Computed }).ToList();
                    ValidateExpression(join.SearchCondition, aliases); return;
                }
                var cross = table as UnqualifiedJoin;
                if (cross != null) { if (cross.UnqualifiedJoinType != UnqualifiedJoinType.CrossJoin) throw Bad(); Table(cross.FirstTableReference, aliases); Table(cross.SecondTableReference, aliases); return; }
                var paren = table as JoinParenthesisTableReference; if (paren != null) { Table(paren.Join, aliases); return; }
                var named = table as NamedTableReference;
                if (named != null)
                {
                    string name = named.SchemaObject.BaseIdentifier.Value; List<BoundColumn> columns;
                    CommonTableExpression cte;
                    if (named.SchemaObject.Identifiers.Count == 1 && ctes.TryGetValue(name, out cte))
                    {
                        if (!active.Add(name)) throw Bad(); try { columns = Query(cte.QueryExpression, new Dictionary<string, List<BoundColumn>>(StringComparer.Ordinal)); } finally { active.Remove(name); }
                        Rename(columns, cte.Columns);
                    }
                    else
                    {
                        if (named.SchemaObject.Identifiers.Count != 3) throw Bad();
                        BoundObject obj = query.Objects.SingleOrDefault(o => o.Database == named.SchemaObject.Identifiers[0].Value && o.Schema == named.SchemaObject.Identifiers[1].Value && o.Name == name);
                        if (obj == null || obj.Columns.Count == 0) throw Bad(); columns = obj.Columns;
                    }
                    Add(aliases, named.Alias == null ? name : named.Alias.Value, columns); return;
                }
                var derived = table as QueryDerivedTable;
                if (derived != null)
                { var cols = Query(derived.QueryExpression, new Dictionary<string, List<BoundColumn>>(StringComparer.Ordinal)); Rename(cols, derived.Columns); if (derived.Alias == null) throw Bad(); Add(aliases, derived.Alias.Value, cols); return; }
                var inline = table as InlineDerivedTable;
                if (inline != null)
                {
                    if (inline.Alias == null || inline.RowValues.Count == 0 || inline.Columns.Count == 0) throw Bad();
                    var cols = inline.RowValues[0].ColumnValues.Select(x => Infer(x, aliases)).ToList(); Rename(cols, inline.Columns);
                    foreach (var row in inline.RowValues) { if (row.ColumnValues.Count != cols.Count) throw Bad(); for (int i = 0; i < cols.Count; i++) { var item = Infer(row.ColumnValues[i], aliases); if (item.SqlType != cols[i].SqlType) throw Bad(); cols[i].Nullable |= item.Nullable; } }
                    Add(aliases, inline.Alias.Value, cols); return;
                }
                var function = table as SchemaObjectFunctionTableReference;
                if (function != null)
                {
                    var obj = query.Objects.SingleOrDefault(o => o.Qualified == safety.Generate(function.SchemaObject));
                    if (obj == null || obj.Columns.Count == 0) throw Bad();
                    foreach (var argument in function.Parameters) Infer(argument, aliases);
                    // Wie bei normalen Tabellen ist ein Alias optional. Der
                    // gebundene Funktionsname ist dann der relationale Name.
                    Add(aliases, function.Alias == null ? function.SchemaObject.BaseIdentifier.Value : function.Alias.Value, obj.Columns); return;
                }
                throw Bad();
            }
            private void Rename(List<BoundColumn> columns, IList<Identifier> names)
            { if (names.Count == 0) return; if (columns.Count != names.Count) throw Bad(); for (int i = 0; i < columns.Count; i++) columns[i] = new BoundColumn { Name = names[i].Value, SqlType = columns[i].SqlType, Collation = columns[i].Collation, Nullable = columns[i].Nullable }; DistinctNames(columns.Select(x => x.Name)); }
            private void DistinctNames(IEnumerable<string> names)
            {
                var list = names.ToList(); if (list.Distinct(StringComparer.Ordinal).Count() != list.Count) throw Bad();
                foreach (string name in list)
                { Util.Q(name); safety.Identifier(query.Database, list, name); if (safety.ExecutionDatabase != null && safety.ExecutionDatabase != query.Database) safety.Identifier(safety.ExecutionDatabase, list, name); }
            }
            private void Add(Dictionary<string, List<BoundColumn>> aliases, string key, List<BoundColumn> columns)
            {
                if (aliases.ContainsKey(key) || safety.Identifier(query.Database, aliases.Keys, key) != null || safety.ExecutionDatabase != null && safety.Identifier(safety.ExecutionDatabase, aliases.Keys, key) != null) throw Bad(); aliases.Add(key, columns);
            }
            private BoundColumn Ref(ColumnReferenceExpression r, Dictionary<string, List<BoundColumn>> aliases)
            {
                if (r.MultiPartIdentifier == null) throw Bad(); var parts = r.MultiPartIdentifier.Identifiers;
                List<BoundColumn> columns;
                if (parts.Count == 2)
                { string alias = safety.Identifier(query.Database, aliases.Keys, parts[0].Value); if (alias == null || !aliases.TryGetValue(alias, out columns)) throw Bad(); parts[0].Value = alias; parts[0].QuoteType = QuoteType.SquareBracket; }
                else if (parts.Count == 1) columns = aliases.Values.SelectMany(x => x).ToList(); else throw Bad();
                string actual = safety.Identifier(query.Database, columns.Select(c => c.Name), parts.Last().Value);
                var found = columns.Where(c => c.Name == actual).ToList(); if (found.Count != 1 || found[0].SqlType == null) throw Bad();
                parts.Last().Value = actual; parts.Last().QuoteType = QuoteType.SquareBracket; return found[0];
            }
            private void ValidateExpression(TSqlFragment e, Dictionary<string, List<BoundColumn>> aliases)
            {
                foreach (var col in safety.Walk(e).OfType<ColumnReferenceExpression>()) if (col.ColumnType != ColumnType.Wildcard) Ref(col, aliases);
            }
            private BoundColumn Infer(ScalarExpression e, Dictionary<string, List<BoundColumn>> aliases)
            {
                var r = e as ColumnReferenceExpression; if (r != null) return Ref(r, aliases);
                var cast = e as CastCall; if (cast != null) { var c = Infer(cast.Parameter, aliases); return new BoundColumn { SqlType = NormalizeType(safety.Generate(cast.DataType)), Nullable = c.Nullable, Collation = c.Collation }; }
                var convert = e as ConvertCall; if (convert != null) { var c = Infer(convert.Parameter, aliases); return new BoundColumn { SqlType = NormalizeType(safety.Generate(convert.DataType)), Nullable = c.Nullable, Collation = c.Collation }; }
                var p = e as ParenthesisExpression; if (p != null) return Infer(p.Expression, aliases);
                var unary = e as UnaryExpression; if (unary != null) return Infer(unary.Expression, aliases);
                if (e is IntegerLiteral) { string value = ((IntegerLiteral)e).Value; long n; return new BoundColumn { SqlType = Int64.TryParse(value, out n) && n <= Int32.MaxValue ? "int" : "decimal(" + value.Length + ",0)", Nullable = false }; }
                if (e is NumericLiteral) { string value = ((NumericLiteral)e).Value; int dot = value.IndexOf('.'); return new BoundColumn { SqlType = "decimal(" + value.Count(Char.IsDigit) + "," + (dot < 0 ? 0 : value.Length - dot - 1) + ")" }; }
                if (e is RealLiteral) return new BoundColumn { SqlType = "float(53)" };
                if (e is StringLiteral) { var text = (StringLiteral)e; int length = Math.Max(1, text.Value.Length); return new BoundColumn { SqlType = !text.IsNational && text.Value.Any(c => c > 127) ? null : (text.IsNational ? "nvarchar(" : "varchar(") + (length > (text.IsNational ? 4000 : 8000) ? "max" : length.ToString()) + ")", Collation = query.Objects.SelectMany(o => o.Columns).Select(c => c.Collation).FirstOrDefault(c => c != null) }; }
                if (e is NullLiteral) return new BoundColumn { SqlType = "int", Nullable = true };
                if (e is BinaryLiteral) return new BoundColumn { SqlType = "varbinary(max)" };
                var variable = e as VariableReference; if (variable != null) { string type; if (!safety.VariableTypes.TryGetValue(variable.Name, out type)) throw Bad(); return new BoundColumn { SqlType = type, Nullable = true }; }
                var scalar = e as ScalarSubquery; if (scalar != null) { var cols = Query(scalar.QueryExpression, aliases); if (cols.Count != 1) throw Bad(); return new BoundColumn { SqlType = cols[0].SqlType, Collation = cols[0].Collation, Nullable = true }; }
                var binary = e as BinaryExpression;
                if (binary != null) { var l = Infer(binary.FirstExpression, aliases); var rr = Infer(binary.SecondExpression, aliases); return new BoundColumn { SqlType = SqlTypeRules.Binary(l.SqlType, rr.SqlType, binary.BinaryExpressionType.ToString()), Collation = l.Collation, Nullable = l.Nullable || rr.Nullable }; }
                var coalesce = e as CoalesceExpression;
                var nullif = e as NullIfExpression;
                if (nullif != null) { var first = Infer(nullif.FirstExpression, aliases); Infer(nullif.SecondExpression, aliases); return new BoundColumn { SqlType = first.SqlType, Collation = first.Collation, Nullable = true }; }
                if (coalesce != null) { var cols = coalesce.Expressions.Select(x => Infer(x, aliases)).ToList(); if (cols.Any(x => x.SqlType != cols[0].SqlType)) throw Bad(); return new BoundColumn { SqlType = cols[0].SqlType, Collation = cols[0].Collation, Nullable = cols.All(x => x.Nullable) }; }
                var searched = e as SearchedCaseExpression;
                if (searched != null)
                {
                    foreach (var w in searched.WhenClauses) ValidateExpression(w.WhenExpression, aliases);
                    var cols = searched.WhenClauses.Select(w => Infer(w.ThenExpression, aliases)).ToList(); if (searched.ElseExpression != null) cols.Add(Infer(searched.ElseExpression, aliases));
                    if (cols.Count == 0 || cols.Any(c => c.SqlType != cols[0].SqlType)) throw Bad(); return new BoundColumn { SqlType = cols[0].SqlType, Collation = cols[0].Collation, Nullable = searched.ElseExpression == null || cols.Any(c => c.Nullable) };
                }
                var f = e as FunctionCall;
                if (f != null && f.CallTarget != null)
                { string type; string name = safety.Generate(f.CallTarget) + "." + Util.Q(f.FunctionName.Value); foreach (var arg in f.Parameters) Infer(arg, aliases); if (!safety.ScalarReturns.TryGetValue(name, out type)) throw Bad(); return new BoundColumn { SqlType = type, Nullable = true }; }
                if (f != null && f.CallTarget == null)
                {
                    string name = f.FunctionName.Value.ToUpperInvariant(); int skip = name == "DATEADD" || name == "DATEDIFF" ? 1 : 0;
                    var args = f.Parameters.Skip(skip).Where(x => !((name == "COUNT" || name == "COUNT_BIG") && x is ColumnReferenceExpression && ((ColumnReferenceExpression)x).ColumnType == ColumnType.Wildcard)).Select(x => Infer(x, aliases)).ToList();
                    if (f.OverClause != null) ValidateExpression(f.OverClause, aliases);
                    if (name == "COUNT" || name == "COUNT_BIG" || name == "ROW_NUMBER" || name == "LEN" || name == "DATALENGTH" || name == "DATEDIFF") return new BoundColumn { SqlType = name == "COUNT_BIG" || name == "ROW_NUMBER" || (name == "DATALENGTH" || name == "LEN") && args.Count > 0 && args[0].SqlType != null && args[0].SqlType.EndsWith("(max)", StringComparison.Ordinal) ? "bigint" : "int", Nullable = name == "ROW_NUMBER" ? false : name == "COUNT" || name == "COUNT_BIG" || args.Any(c => c.Nullable) };
                    if (name == "DATEFROMPARTS") return new BoundColumn { SqlType = "date", Nullable = args.Any(c => c.Nullable) };
                    if (name == "ISNULL" && args.Count == 2) { var value = f.Parameters[0] is NullLiteral ? args[1] : args[0]; return new BoundColumn { SqlType = value.SqlType, Collation = value.Collation, Nullable = args[0].Nullable && args[1].Nullable }; }
                    if (name == "DATEADD" && args.Count == 2) return new BoundColumn { SqlType = f.Parameters[2] is StringLiteral ? "datetime" : args[1].SqlType, Nullable = args.Any(c => c.Nullable) };
                    if (args.Count > 0) return new BoundColumn { SqlType = SqlTypeRules.Function(name, args[0].SqlType), Collation = args[0].Collation, Nullable = args.Any(c => c.Nullable) || name == "NULLIF" || name == "AVG" || name == "SUM" || name == "MIN" || name == "MAX" };
                }
                throw Bad();
            }
            private static string NormalizeType(string type) { return SqlTypeRules.CastType(type); }
        }
    }
}
