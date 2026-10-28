using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Reflection;
using Microsoft.SqlServer.TransactSql.ScriptDom;
using Toolbelt.Tsql.ScriptParser;

namespace Toolbelt.Tsql.SsisDebug
{
    internal sealed class BoundColumn
    {
        internal string Name, SqlType, Collation, Computed;
        internal bool Nullable;
    }
    internal sealed class BoundObject
    {
        internal string Database, Schema, Name, Kind, Definition, Synonym, Fingerprint;
        internal bool MemoryOptimized, External;
        internal readonly List<BoundColumn> Columns = new List<BoundColumn>();
        internal readonly List<string> SecurityFunctions = new List<string>();
        internal readonly List<string[]> Dependencies = new List<string[]>();
        internal string Key { get { return Database + "\0" + Schema + "\0" + Name; } }
        internal string Qualified { get { return Util.Q(Database) + "." + Util.Q(Schema) + "." + Util.Q(Name); } }
    }
    internal interface ICatalog
    {
        string Collation(string database);
        bool IsCollation(string name);
        int CodePage(string collation);
        BoundObject Resolve(string database, string schema, string name);
        string BindIdentifier(string database, IEnumerable<string> candidates, string name);
    }
    internal sealed class SqlQuery
    {
        internal string Sql, Database;
        internal SelectStatement Statement;
        internal readonly List<BoundObject> Objects = new List<BoundObject>();
    }

    internal sealed class SqlSafety
    {
        private readonly Budget budget; private readonly int version;
        private readonly ICatalog catalog; private readonly HashSet<string> databases;
        private readonly Dictionary<string, BoundObject> objects = new Dictionary<string, BoundObject>(StringComparer.Ordinal);
        private readonly HashSet<string> checking = new HashSet<string>(StringComparer.Ordinal);
        private readonly HashSet<string> checkedObjects = new HashSet<string>(StringComparer.Ordinal);
        private readonly Dictionary<string, TSqlFragment> parsed = new Dictionary<string, TSqlFragment>(StringComparer.Ordinal);
        private readonly Action<string> diagnostic;
        private readonly HashSet<string> variables;
        internal readonly HashSet<string> ReadNames = new HashSet<string>(StringComparer.Ordinal);
        internal readonly Dictionary<string, string> VariableTypes = new Dictionary<string, string>(StringComparer.Ordinal);
        internal readonly Dictionary<string, string> ScalarReturns = new Dictionary<string, string>(StringComparer.Ordinal);
        internal string ExecutionDatabase;
        internal string Identifier(string database, IEnumerable<string> candidates, string name) { return catalog.BindIdentifier(database, candidates, name); }
        internal SqlSafety(Budget b, int v, ICatalog c, IEnumerable<string> dbs, IEnumerable<string> vars, Action<string> note)
        { budget = b; version = v; catalog = c; databases = new HashSet<string>(dbs, StringComparer.Ordinal); variables = new HashSet<string>(vars, StringComparer.Ordinal); diagnostic = note; }

        // Geschlossene Knotenmengen: neue ScriptDom-Syntax erhält keine implizite Freigabe.
        private static readonly HashSet<string> ReadNodes = new HashSet<string>((
            "TSqlScript TSqlBatch SelectStatement WithCtesAndXmlNamespaces CommonTableExpression Identifier " +
            "QuerySpecification BinaryQueryExpression QueryParenthesisExpression SelectScalarExpression SelectStarExpression " +
            "FromClause NamedTableReference QueryDerivedTable InlineDerivedTable QualifiedJoin UnqualifiedJoin JoinParenthesisTableReference " +
            "WhereClause HavingClause GroupByClause ExpressionGroupingSpecification OrderByClause ExpressionWithSortOrder TopRowFilter " +
            "IntegerLiteral NumericLiteral RealLiteral MoneyLiteral StringLiteral NullLiteral BinaryLiteral MaxLiteral " +
            "ColumnReferenceExpression MultiPartIdentifier SchemaObjectName IdentifierOrValueExpression VariableReference " +
            "BinaryExpression UnaryExpression ParenthesisExpression ScalarSubquery FunctionCall CastCall ConvertCall " +
            "SqlDataTypeReference BooleanComparisonExpression BooleanBinaryExpression BooleanNotExpression " +
            "BooleanParenthesisExpression BooleanIsNullExpression InPredicate LikePredicate BooleanTernaryExpression ExistsPredicate " +
            "SearchedCaseExpression SearchedWhenClause SimpleCaseExpression SimpleWhenClause CoalesceExpression NullIfExpression " +
            "OverClause WindowFrameClause WindowFrameExtent WindowFrameDelimiter TableHint IndexTableHint " +
            "SchemaObjectFunctionTableReference MultiPartIdentifierCallTarget RowValue").Split(' '), StringComparer.Ordinal);
        private static readonly HashSet<string> GeneratedNodes = new HashSet<string>((
            "DeclareVariableStatement DeclareVariableElement IfStatement BeginEndBlockStatement StatementList ThrowStatement UpdateStatement UpdateSpecification SetClause AssignmentSetClause " +
            "TryCatchStatement CreateTableStatement TableDefinition ColumnDefinition NullableConstraintDefinition " +
            "InsertStatement InsertSpecification SelectInsertSource DropTableStatement SetVariableStatement GlobalVariableExpression " +
            "BeginTransactionStatement CommitTransactionStatement RollbackTransactionStatement SaveTransactionStatement " +
            "IdentifierOrScalarExpression CheckConstraintDefinition WithinGroupClause").Split(' '), StringComparer.Ordinal);
        private static readonly HashSet<string> V2ExpressionNodes = new HashSet<string>(new[] { "CollateExpression" }, StringComparer.Ordinal);
        private static readonly HashSet<string> Functions = new HashSet<string>((
            "ISNULL COALESCE NULLIF ABS CEILING FLOOR ROUND UPPER LOWER LTRIM RTRIM SUBSTRING LEN DATALENGTH DATEADD DATEDIFF DATEFROMPARTS " +
            "COUNT COUNT_BIG SUM AVG MIN MAX ROW_NUMBER").Split(' '), StringComparer.OrdinalIgnoreCase);
        private static readonly HashSet<string> V2ExpressionFunctions = new HashSet<string>(new[] { "TRIM", "REPLACE" }, StringComparer.OrdinalIgnoreCase);
        private static readonly HashSet<string> GuardFunctions = new HashSet<string>(("OBJECT_ID HASHBYTES SQL_VARIANT_PROPERTY COL_LENGTH DB_NAME NEWID STRING_AGG CONCAT").Split(' '), StringComparer.OrdinalIgnoreCase);
        internal TSqlFragment Parse(string sql)
        {
            budget.Check(); Budget.Limit((long)sql.Length * 2, 2097152);
            TSqlFragment previous; if (parsed.TryGetValue(sql, out previous)) return previous;
            budget.CheckLimit("parserCalls", ++budget.SqlCalls);
            Guard(sql);
            TSqlParser parser = version == 150 ? (TSqlParser)new TSql150Parser(true) : version == 160 ? (TSqlParser)new TSql160Parser(true) : new TSql170Parser(true);
            IList<ParseError> errors; IList<TSqlParserToken> tokens;
            using (var reader = new StringReader(sql)) tokens = parser.GetTokenStream(reader, out errors);
            Budget.Limit(tokens.Count, 65536);
            if (errors.Count != 0) throw new DebugFault("unsafe_statement", "SQL-Lexing fehlgeschlagen.");
            TSqlFragment ast = parser.Parse(tokens, out errors);
            if (errors.Count != 0 || ast == null)
            {
                ParseError first = errors.Count == 0 ? null : errors[0];
                throw new DebugFault("unsafe_statement", "SQL-Syntax ungültig; errors=" + errors.Count.ToString(CultureInfo.InvariantCulture) + (first == null ? "" : "; line=" + first.Line.ToString(CultureInfo.InvariantCulture) + "; column=" + first.Column.ToString(CultureInfo.InvariantCulture) + "; number=" + first.Number.ToString(CultureInfo.InvariantCulture)) + ".");
            }
            // Iterativer, begrenzter Walk statt rekursiver Reflectionvisitor.
            foreach (TSqlFragment node in Walk(ast))
            {
                var q = node as QuerySpecification; if (q != null) Budget.Limit(q.SelectElements.Count, 256);
                var values = node as RowValue; if (values != null) Budget.Limit(values.ColumnValues.Count, 256);
                var w = node as WithCtesAndXmlNamespaces; if (w != null) Budget.Limit(w.CommonTableExpressions.Count, 32);
            }
            parsed.Add(sql, ast); return ast;
        }
        internal static void Guard(string sql, List<int> parameterOffsets = null)
        {
            int atoms, structure, comments;
            string status = PreparseGuardCore.Guard(sql, 32, new GuardProfile(4096, 65536, 32, 16, 256, 64), out atoms, out structure, out comments, parameterOffsets);
            if (status != "ACCEPT") throw new DebugFault("resource_limit", "SQL-Vorfiltergrenze erreicht; counter=" + status + "; atoms=" + atoms.ToString(CultureInfo.InvariantCulture) + "; structure=" + structure.ToString(CultureInfo.InvariantCulture) + ".");
        }
        internal IEnumerable<TSqlFragment> Walk(TSqlFragment root)
        {
            var todo = new Stack<KeyValuePair<TSqlFragment, int>>(); todo.Push(new KeyValuePair<TSqlFragment, int>(root, 1));
            int count = 0, properties = 0;
            while (todo.Count != 0)
            {
                budget.Check(); var work = todo.Pop(); Budget.Limit(work.Value, 100); Budget.Limit(++count, 65536);
                TSqlFragment node = work.Key; yield return node;
                foreach (PropertyInfo p in node.GetType().GetProperties(BindingFlags.Public | BindingFlags.Instance))
                {
                    Budget.Limit(++properties, 262144);
                    if (p.GetIndexParameters().Length != 0 || p.Name == "ScriptTokenStream") continue;
                    object value = p.GetValue(node, null); var child = value as TSqlFragment;
                    if (child != null) todo.Push(new KeyValuePair<TSqlFragment, int>(child, work.Value + 1));
                    else if (value is IList) foreach (object item in (IList)value) if (item is TSqlFragment) todo.Push(new KeyValuePair<TSqlFragment, int>((TSqlFragment)item, work.Value + 1));
                }
            }
        }
        internal string Generate(TSqlFragment ast)
        {
            // ScriptDom 180.117 rendert eine allein übergebene QueryExpression
            // ohne ihren vollständigen SELECT-Kontext; dabei gehen u.a. WHERE-
            // Klauseln verloren. Auch CTE-/Derived-Queryfragmente daher immer
            // als SelectStatement rendern. Der vorhandene AST bleibt unverändert.
            var expression = ast as QueryExpression;
            if (expression != null) ast = new SelectStatement { QueryExpression = expression };
            SqlScriptGenerator g = version == 150 ? (SqlScriptGenerator)new Sql150ScriptGenerator() : version == 160 ? (SqlScriptGenerator)new Sql160ScriptGenerator() : new Sql170ScriptGenerator();
            string sql; g.GenerateScript(ast, out sql); return sql.Trim().TrimEnd(';');
        }
        private TSqlFragment Clone(TSqlFragment root)
        {
            // Der Parsecache bleibt unverändert. Bindung/NOLOCK/CTE-Umbenennung
            // arbeiten pro Verwendung auf einer iterativ erzeugten AST-Kopie.
            var copies = new Dictionary<TSqlFragment, TSqlFragment>(); var todo = new Queue<TSqlFragment>();
            Func<TSqlFragment, TSqlFragment> copy = fragment =>
            { TSqlFragment value; if (!copies.TryGetValue(fragment, out value)) { value = (TSqlFragment)Activator.CreateInstance(fragment.GetType()); copies.Add(fragment, value); todo.Enqueue(fragment); } return value; };
            var result = copy(root); int properties = 0;
            while (todo.Count != 0)
            {
                budget.Check(); Budget.Limit(copies.Count, 65536); var from = todo.Dequeue(); var to = copies[from];
                foreach (var p in from.GetType().GetProperties(BindingFlags.Public | BindingFlags.Instance))
                {
                    Budget.Limit(++properties, 262144); if (p.GetIndexParameters().Length != 0) continue;
                    object value = p.GetValue(from, null);
                    if (p.Name == "ScriptTokenStream") { if (p.CanWrite) p.SetValue(to, value, null); continue; }
                    var child = value as TSqlFragment;
                    // ScriptDom bietet berechnete, schreibgeschützte Aliase wie
                    // BaseIdentifier zusätzlich zur eigentlichen Identifiers-Liste.
                    if (child != null) { if (p.CanWrite) p.SetValue(to, copy(child), null); }
                    else if (value is IList)
                    { var list = p.GetValue(to, null) as IList; if (list == null) throw new DebugFault("unsafe_statement", "AST-Liste nicht kopierbar."); foreach (object item in (IList)value) list.Add(item is TSqlFragment ? copy((TSqlFragment)item) : item); }
                    else if (p.CanWrite) p.SetValue(to, value, null);
                }
            }
            return result;
        }
        internal SqlQuery Read(string sql, string database)
        {
            var script = Clone(Parse(sql)) as TSqlScript;
            if (script == null || script.Batches.Count != 1 || script.Batches[0].Statements.Count != 1 || !(script.Batches[0].Statements[0] is SelectStatement)) throw new DebugFault("unsafe_statement", "Genau ein SELECT erforderlich.");
            var statement = (SelectStatement)script.Batches[0].Statements[0]; var q = new SqlQuery { Statement = statement, Database = database };
            Validate(statement, database, null, q);
            q.Sql = Generate(statement); return q;
        }
        private void Validate(TSqlFragment ast, string database, HashSet<string> ownTemps, SqlQuery query, bool v2Expressions = false)
        {
            var nodes = Walk(ast).ToList();
            var ctes = new HashSet<string>(nodes.OfType<CommonTableExpression>().Select(c => c.ExpressionName.Value), StringComparer.Ordinal);
            if (ctes.Count != nodes.OfType<CommonTableExpression>().Count()) throw new DebugFault("invalid_lineage", "Doppelte CTE-Namen.");
            foreach (var cte in nodes.OfType<CommonTableExpression>())
                if (Walk(cte.QueryExpression).OfType<NamedTableReference>().Any(t => t.SchemaObject.Identifiers.Count == 1 && (ownTemps == null ? Identifier(database, new[] { cte.ExpressionName.Value }, t.SchemaObject.BaseIdentifier.Value) != null : cte.ExpressionName.Value == t.SchemaObject.BaseIdentifier.Value))) throw new DebugFault("unsafe_statement", "Rekursive CTE nicht unterstützt.");
            foreach (TSqlFragment node in nodes)
            {
                string kind = node.GetType().Name;
                if (!ReadNodes.Contains(kind) && (ownTemps == null || !GeneratedNodes.Contains(kind) && !(v2Expressions && V2ExpressionNodes.Contains(kind)))) throw new DebugFault("unsafe_statement", "AST-Knoten nicht im V1-Profil: " + kind + ".");
                var select = node as SelectStatement;
                if (select != null && (select.Into != null || select.OptimizerHints.Count != 0 || select.ComputeClauses.Count != 0)) throw new DebugFault("unsafe_statement", "SELECT-Erweiterung nicht freigegeben.");
                var variable = node as VariableReference;
                if (variable != null && !variables.Contains(variable.Name) && !(ownTemps != null && variable.Name.StartsWith("@tbx_", StringComparison.Ordinal))) throw new DebugFault("unresolved_binding", "SQL-Variable nicht gebunden.");
                var function = node as FunctionCall;
                if (function != null)
                {
                    if (function.CallTarget == null)
                    {
                        if (!Functions.Contains(function.FunctionName.Value) && !(v2Expressions && V2ExpressionFunctions.Contains(function.FunctionName.Value)) && !(ownTemps != null && GuardFunctions.Contains(function.FunctionName.Value))) throw new DebugFault("unsafe_statement", "Funktion nicht im gebundenen Profil.");
                    }
                    else
                    {
                        var target = function.CallTarget as MultiPartIdentifierCallTarget;
                        if (target == null) throw new DebugFault("unsafe_statement", "Unbekanntes Funktionsziel.");
                        var identifiers = target.MultiPartIdentifier.Identifiers.Select(x => x.Value).Concat(new[] { function.FunctionName.Value }).ToList();
                        var boundFunction = Resolve(identifiers, database);
                        if (boundFunction.Kind != "FN") throw new DebugFault("unresolved_dependency", "Skalaraufruf ist keine reine T-SQL-Skalarfunktion.");
                        CheckObject(boundFunction, 0);
                        target.MultiPartIdentifier.Identifiers.Clear();
                        foreach (string x in new[] { boundFunction.Database, boundFunction.Schema }) target.MultiPartIdentifier.Identifiers.Add(new Identifier { Value = x, QuoteType = QuoteType.SquareBracket });
                        function.FunctionName.Value = boundFunction.Name; function.FunctionName.QuoteType = QuoteType.SquareBracket;
                    }
                }
                var type = node as SqlDataTypeReference;
                if (type != null && !AllowedType(type.SqlDataTypeOption.ToString())) throw new DebugFault("unsafe_statement", "SQL-Typ nicht freigegeben.");
                var table = node as NamedTableReference;
                if (table != null)
                {
                    string name = table.SchemaObject.BaseIdentifier.Value;
                    string cteName = table.SchemaObject.Identifiers.Count == 1 ? ownTemps == null ? Identifier(database, ctes, name) : ctes.Contains(name) ? name : null : null;
                    if (cteName != null) { table.SchemaObject.BaseIdentifier.Value = cteName; if (table.TableHints.Count != 0) throw new DebugFault("unsafe_statement", "CTE-Hints nicht freigegeben."); continue; }
                    if (ownTemps != null && ownTemps.Contains(name) && table.SchemaObject.Identifiers.Count == 1) { NoLock(table, IsWriteTarget(node, nodes)); continue; }
                    if (ownTemps != null && table.SchemaObject.Identifiers.Count == 3 && table.SchemaObject.Identifiers[0].Value == "tempdb" && table.SchemaObject.Identifiers[1].Value == "sys" && new[] { "objects", "columns", "types", "extended_properties", "indexes", "check_constraints" }.Contains(name)) { NoLock(table, false); continue; }
                    var bound = Resolve(table.SchemaObject.Identifiers.Select(x => x.Value).ToList(), database);
                    if (bound.Kind != "U" && bound.Kind != "V" && bound.Kind != "SN") throw new DebugFault("unresolved_dependency", "Benannte Tabellenreferenz hat falschen Objekttyp.");
                    CheckObject(bound, 0); ReadNames.Add(bound.Qualified);
                    if (query != null && !query.Objects.Any(x => x.Key == bound.Key)) query.Objects.Add(bound);
                    table.SchemaObject.Identifiers.Clear(); foreach (string x in new[] { bound.Database, bound.Schema, bound.Name }) table.SchemaObject.Identifiers.Add(new Identifier { Value = x, QuoteType = QuoteType.SquareBracket });
                    NoLock(table, false);
                }
                var tvf = node as SchemaObjectFunctionTableReference;
                if (tvf != null)
                {
                    var bound = Resolve(tvf.SchemaObject.Identifiers.Select(x => x.Value).ToList(), database);
                    if (bound.Kind != "IF") throw new DebugFault("unresolved_dependency", "Nur gebundene Inline-TVF erlaubt.");
                    CheckObject(bound, 0); if (query != null && !query.Objects.Any(x => x.Key == bound.Key)) query.Objects.Add(bound);
                    tvf.SchemaObject.Identifiers.Clear(); foreach (string x in new[] { bound.Database, bound.Schema, bound.Name }) tvf.SchemaObject.Identifiers.Add(new Identifier { Value = x, QuoteType = QuoteType.SquareBracket });
                    diagnostic("nolock_read_uncommitted");
                }
                if (ownTemps != null)
                {
                    var create = node as CreateTableStatement; if (create != null) Own(create.SchemaObjectName, ownTemps);
                    var drop = node as DropTableStatement; if (drop != null) foreach (var n in drop.Objects) Own(n, ownTemps);
                    var insert = node as InsertSpecification;
                    if (insert != null)
                    { var t = insert.Target as NamedTableReference; if (t == null || insert.OutputClause != null || insert.OutputIntoClause != null || !(insert.InsertSource is SelectInsertSource)) throw new DebugFault("unsafe_statement", "Nur eigener INSERT SELECT erlaubt."); Own(t.SchemaObject, ownTemps); }
                    var update = node as UpdateSpecification;
                    if (update != null) { var t = update.Target as NamedTableReference; if (t == null || update.FromClause != null || update.OutputClause != null) throw new DebugFault("unsafe_statement", "Nur einfaches UPDATE des eigenen Planstates erlaubt."); Own(t.SchemaObject, ownTemps); }
                }
            }
        }
        private static bool IsWriteTarget(TSqlFragment node, List<TSqlFragment> nodes) { return nodes.OfType<InsertSpecification>().Any(i => Object.ReferenceEquals(i.Target, node)) || nodes.OfType<UpdateSpecification>().Any(i => Object.ReferenceEquals(i.Target, node)); }
        private static void Own(SchemaObjectName name, HashSet<string> own)
        { if (name.Identifiers.Count != 1 || !own.Contains(name.BaseIdentifier.Value) || !name.BaseIdentifier.Value.StartsWith("#tbx_SsisDebug_", StringComparison.Ordinal)) throw new DebugFault("unsafe_statement", "Fremdes Schreibziel."); }
        private static bool AllowedType(string t)
        { return new[] { "Bit", "TinyInt", "SmallInt", "Int", "BigInt", "Decimal", "Numeric", "Money", "SmallMoney", "Real", "Float", "Char", "VarChar", "NChar", "NVarChar", "Date", "Time", "DateTime", "SmallDateTime", "DateTime2", "UniqueIdentifier", "Binary", "VarBinary" }.Contains(t); }
        private void NoLock(NamedTableReference table, bool write)
        {
            if (write) { if (table.TableHints.Count != 0) throw new DebugFault("unsafe_statement", "Schreibzielhint nicht erlaubt."); return; }
            foreach (TableHint hint in table.TableHints)
                if (hint.HintKind != TableHintKind.NoLock && hint.HintKind != TableHintKind.ReadUncommitted) diagnostic("locking_hint_replaced");
            // Unbekannte Optimizer-/Providerhints werden nicht still entfernt.
            if (table.TableHints.Any(h => h is IndexTableHint || !new[] { "NoLock", "ReadUncommitted", "HoldLock", "UpdLock", "XLock", "ReadCommitted", "ReadCommittedLock", "RepeatableRead", "Serializable", "RowLock", "PageLock", "TabLock", "TabLockX", "ReadPast" }.Contains(h.HintKind.ToString()))) throw new DebugFault("hint_not_supported", "Hintkombination nicht verstanden.");
            table.TableHints.Clear(); table.TableHints.Add(new TableHint { HintKind = TableHintKind.NoLock });
        }
        private BoundObject Resolve(IList<string> names, string database)
        {
            if (names.Count < 1 || names.Count > 3 || names.Any(String.IsNullOrEmpty)) throw new DebugFault("unresolved_dependency", "Nur lokale ein-/zwei-/dreiteilige Objekte erlaubt.");
            string db = names.Count == 3 ? names[0] : database, schema = names.Count >= 2 ? names[names.Count - 2] : null, name = names[names.Count - 1];
            if (!databases.Contains(db) || name.StartsWith("#", StringComparison.Ordinal)) throw new DebugFault("unresolved_dependency", "Datenbank oder Objekt nicht explizit erlaubt.");
            string key = db + "\0" + schema + "\0" + name; BoundObject found;
            if (objects.TryGetValue(key, out found)) return found;
            budget.CheckLimit("catalogObjects", objects.Count + 1); found = catalog.Resolve(db, schema, name);
            if (found == null) throw new DebugFault("unresolved_dependency", "Objekt nicht vollständig sichtbar.");
            objects.Add(key, found); return found;
        }
        private void CheckObject(BoundObject o, int depth)
        {
            if (checkedObjects.Contains(o.Key)) return;
            Budget.Limit(depth, 16); Budget.Limit(checking.Count + 1, 16);
            if (!checking.Add(o.Key)) throw new DebugFault("unresolved_dependency", "Zyklische Objektabhängigkeit.");
            try
            {
                if (o.MemoryOptimized || o.External) throw new DebugFault("hint_not_supported", "Objekttyp nicht im NOLOCK-Profil.");
                if (o.Kind == "SN")
                {
                    var syn = Parse("SELECT 1 FROM " + o.Synonym) as TSqlScript;
                    var name = Walk(syn).OfType<NamedTableReference>().SingleOrDefault();
                    if (name == null) throw new DebugFault("unresolved_dependency", "Synonymziel nicht gebunden.");
                    var target = Resolve(name.SchemaObject.Identifiers.Select(x => x.Value).ToList(), o.Database); CheckObject(target, depth + 1);
                    if (target.Kind != "U" && target.Kind != "V" && target.Kind != "SN") throw new DebugFault("unresolved_dependency", "Synonymziel ist keine lesbare Tabelle/View.");
                    if (o.Columns.Count == 0) o.Columns.AddRange(target.Columns);
                }
                else if (o.Kind == "V")
                {
                    if (o.Definition == null) throw new DebugFault("catalog_visibility", "Viewdefinition fehlt.");
                    var ast = Clone(Parse(o.Definition)); var body = Walk(ast).OfType<ViewStatementBody>().SingleOrDefault();
                    if (body == null || body.SelectStatement == null) throw new DebugFault("unresolved_dependency", "Viewdefinition nicht gebunden.");
                    Validate(body.SelectStatement, o.Database, null, null);
                }
                else if (o.Kind == "IF" || o.Kind == "FN")
                {
                    if (o.Definition == null) throw new DebugFault("catalog_visibility", "Funktionsdefinition fehlt.");
                    var ast = Clone(Parse(o.Definition)); var body = Walk(ast).OfType<FunctionStatementBody>().SingleOrDefault();
                    if (body == null) throw new DebugFault("unresolved_dependency", "Funktionsdefinition nicht gebunden.");
                    var added = new List<string>();
                    foreach (var parameter in body.Parameters)
                    { var type = parameter.DataType as SqlDataTypeReference; if (type == null || !AllowedType(type.SqlDataTypeOption.ToString())) throw new DebugFault("unresolved_dependency", "Funktionsparameter mit unbekanntem Typ."); if (variables.Add(parameter.VariableName.Value)) added.Add(parameter.VariableName.Value); }
                    try
                    {
                        if (o.Kind == "IF" && body.ReturnType is SelectFunctionReturnType)
                        {
                            var select = ((SelectFunctionReturnType)body.ReturnType).SelectStatement;
                            // Der Funktionsaufruf übernimmt unsere AST-Änderung an
                            // der Definition nicht. Kein unbelegtes NOLOCK-PASS.
                            if (Walk(select).Any(n => n is NamedTableReference || n is SchemaObjectFunctionTableReference)) throw new DebugFault("hint_not_supported", "Inline-TVF mit transitivem Tabellenzugriff: NOLOCK kann ohne Definitionsänderung nicht durchgesetzt werden.");
                            Validate(select, o.Database, null, null);
                        }
                        else if (o.Kind == "FN" && body.StatementList != null && body.StatementList.Statements.Count == 1 && body.StatementList.Statements[0] is ReturnStatement)
                        { var r = (ReturnStatement)body.StatementList.Statements[0]; var returnType = body.ReturnType as ScalarFunctionReturnType; if (returnType == null || !(returnType.DataType is SqlDataTypeReference) || !AllowedType(((SqlDataTypeReference)returnType.DataType).SqlDataTypeOption.ToString()) || r.Expression == null || Walk(r.Expression).Any(x => x is ScalarSubquery || x is VariableReference && !variables.Contains(((VariableReference)x).Name))) throw new DebugFault("unresolved_dependency", "Skalarfunktion nicht rein."); Validate(r.Expression, o.Database, null, null); ScalarReturns[o.Qualified] = SqlTypeRules.CastType(Generate(returnType.DataType)); }
                        else throw new DebugFault("unsupported_component", "Nur Inline-TVF oder reiner Ein-RETURN-Ausdruck erlaubt.");
                    }
                    finally { foreach (string p in added) variables.Remove(p); }
                }
                else if (o.Kind != "U") throw new DebugFault("unresolved_dependency", "Objekttyp nicht freigegeben.");
                foreach (var c in o.Columns.Where(x => x.Computed != null)) Read("SELECT (" + c.Computed + ")", o.Database);
                foreach (string f in o.SecurityFunctions) CheckObject(Resolve(f.Split('\0'), o.Database), depth + 1);
                // Tatsächliche Modulbindungen ergänzen die AST-Bindung: geerbte
                // Schemas/NULL-IDs dürfen keine versteckte UDF-Abhängigkeit umgehen.
                foreach (string[] dependency in o.Dependencies) CheckObject(Resolve(dependency, o.Database), depth + 1);
                checkedObjects.Add(o.Key);
            }
            finally { checking.Remove(o.Key); }
        }
        internal void VerifyCatalog()
        {
            foreach (BoundObject old in objects.Values)
            { budget.Check(); BoundObject now = catalog.Resolve(old.Database, old.Schema, old.Name); if (now == null || old.Fingerprint != now.Fingerprint) throw new DebugFault("catalog_drift", "Katalog während der Analyse geändert."); }
        }
        internal object CatalogBinding()
        {
            return Json.Obj("scope", "analysis", "objects", objects.Values.GroupBy(o => o.Key).Select(g => g.First()).OrderBy(o => o.Key, StringComparer.Ordinal).Select(o => (object)Json.Obj(
                "database", o.Database, "schema", o.Schema, "name", o.Name, "kind", o.Kind,
                "catalogSha256", o.Fingerprint, "definitionSha256", o.Definition == null ? null : Util.Hash(o.Definition))).ToList());
        }
        internal void Generated(string sql, string database, IEnumerable<string> owned, bool v2Expressions = false)
        { Validate(Parse(sql), database, new HashSet<string>(owned, StringComparer.Ordinal), null, v2Expressions); }

        // Nur echte Tabellenreferenzen mit exakt registriertem Ein-Part-Namen
        // werden ersetzt. Textuelles Replace könnte sonst Literale, Identifier
        // oder freie Fragmente verändern. Der Aufrufer führt danach Generated
        // über den vollständigen resultierenden SQL-Abschnitt aus.
        internal string RewriteStageTables(string sql, IDictionary<string, string> replacements)
        {
            var script = Clone(Parse(sql)) as TSqlScript;
            if (script == null || script.Batches.Count != 1 || script.Batches[0].Statements.Count != 1 || !(script.Batches[0].Statements[0] is SelectStatement))
                throw new DebugFault("unsafe_statement", "Stage-Unit ist kein einzelnes SELECT.");
            foreach (NamedTableReference table in Walk(script).OfType<NamedTableReference>())
            {
                if (table.SchemaObject.Identifiers.Count != 1) continue;
                string name = table.SchemaObject.BaseIdentifier.Value, replacement;
                if (!replacements.TryGetValue(name, out replacement)) continue;
                if (String.IsNullOrEmpty(replacement) || !replacement.StartsWith("#tbx_SsisDebug_", StringComparison.Ordinal))
                    throw new DebugFault("unsafe_statement", "Stage-Temp ist nicht durch den Plan gebunden.");
                table.SchemaObject.Identifiers[0].Value = replacement;
                table.SchemaObject.Identifiers[0].QuoteType = QuoteType.SquareBracket;
            }
            return Generate(script);
        }
    }
}
