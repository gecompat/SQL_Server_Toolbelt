using System;
using System.Collections;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.Globalization;
using System.Reflection;
using System.Threading;
using Toolbelt.Tsql.ScriptParser;

internal static class ProviderTests
{
    private static object Get(object row, string name) { return row.GetType().GetProperty(name).GetValue(row, null); }
    private static List<object> Collect(IEnumerable value) { var rows = new List<object>(); foreach (object row in value) rows.Add(row); return rows; }
    private static int assertion;
    private static void Assert(bool ok) { assertion++; if (!ok) throw new Exception("ASSERTION_" + assertion); }
    private static IEnumerable Call(string method, string sql, int version = 160, int bytes = 2097152, int depth = 100, bool quoted = true)
    {
        try { return (IEnumerable)typeof(ScriptParserProvider).GetMethod(method).Invoke(null, new object[] {
            sql == null ? SqlChars.Null : new SqlChars(sql), new SqlInt32(version), new SqlBoolean(quoted), new SqlInt32(bytes), new SqlInt32(depth) }); }
        catch (TargetInvocationException e) { throw e.InnerException; }
    }
    private static void Failure(Action action, string prefix)
    {
        try { action(); } catch (Exception e) { Assert(e.Message.StartsWith(prefix, StringComparison.Ordinal)); return; }
        throw new Exception("EXPECTED_FAILURE");
    }
    private static void Parameters()
    {
        foreach (string method in new[] { "ParseScriptNodes", "ParseScriptNodeProperties", "TokenizeScript", "ParseScriptErrors" })
        {
            Assert(Collect(Call(method, null, 999, 0, 0)).Count == 0);
            Failure(() => Call(method, "SELECT 1;", 999, 0, 0), "TBX_TSQLPARSE_INVALID_VERSION");
            Failure(() => Call(method, "SELECT 1;", 160, 0, 0), "TBX_TSQLPARSE_INVALID_MAX_BYTES");
            Failure(() => Call(method, "SELECT 1;", 160, 2097153, 0), "TBX_TSQLPARSE_INVALID_MAX_BYTES");
            Failure(() => Call(method, "SELECT 1;", 160, 1, 0), "TBX_TSQLPARSE_INVALID_MAX_DEPTH");
            Failure(() => Call(method, "SELECT 1;", 160, 1, 257), "TBX_TSQLPARSE_INVALID_MAX_DEPTH");
            Failure(() => Call(method, "SELECT 1;", 160, 1, 100), "TBX_TSQLPARSE_INPUT_TOO_LARGE");
            Failure(() => Call(method, "SELECT " + new string('~', 510) + "1;"), "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT");
            Assert(Collect(Call(method, "SELECT 'unterminated;")).Count == (method == "ParseScriptErrors" ? 1 : 0));
            var defaults = (IEnumerable)typeof(ScriptParserProvider).GetMethod(method).Invoke(null, new object[] { new SqlChars("SELECT 1;"), SqlInt32.Null, SqlBoolean.Null, SqlInt32.Null, SqlInt32.Null });
            Assert(Collect(defaults).Count == (method == "ParseScriptErrors" ? 0 : Collect(Call(method, "SELECT 1;")).Count));
        }
        Assert(Collect(Call("TokenizeScript", "SELECT FROM;")).Count > 0);
        Assert(Collect(Call("ParseScriptNodes", "SELECT FROM;")).Count == 0);
        Assert(Collect(Call("ParseScriptNodeProperties", "SELECT FROM;")).Count == 0);
        Assert(Collect(Call("ParseScriptErrors", "SELECT FROM;")).Count > 0);
        Failure(() => Call("ParseScriptNodes", "SELECT " + new string('~', 100) + "1;"), "TBX_TSQLPARSE_MAX_DEPTH_EXCEEDED");
        Failure(() => Call("ParseScriptNodeProperties", "SELECT " + new string('~', 100) + "1;"), "TBX_TSQLPARSE_MAX_DEPTH_EXCEEDED");
        Failure(() => Call("ParseScriptErrors", "SELECT " + new string('~', 100) + "1;"), "TBX_TSQLPARSE_MAX_DEPTH_EXCEEDED");
        Assert(Collect(Call("TokenizeScript", "SELECT " + new string('~', 100) + "1;")).Count > 0);
        foreach (int depth in new[] { 4, 5, 6 })
        {
            foreach (string method in new[] { "ParseScriptNodes", "ParseScriptNodeProperties", "ParseScriptErrors" })
            {
                if (depth < 5) Failure(() => Call(method, "SELECT 1;", 160, 2097152, depth), "TBX_TSQLPARSE_MAX_DEPTH_EXCEEDED");
                else Collect(Call(method, "SELECT 1;", 160, 2097152, depth));
            }
        }
        var diagnostics = Collect(Call("ParseScriptErrors", "SELECT\nFROM;"));
        Assert(diagnostics.Count == 1 && (int)Get(diagnostics[0], "StartOffset") == 7 &&
            (int)Get(diagnostics[0], "StartLine") == 2 && (int)Get(diagnostics[0], "StartColumn") == 1);
        var literals = Collect(Call("ParseScriptNodes", "SELECT 1;"));
        object literal = literals.Find(row => (string)Get(row, "NodeType") == "IntegerLiteral");
        Assert(literal != null && (int)Get(literal, "StartOffset") == 7 && (int)Get(literal, "FragmentLength") == 1);
        Assert(Collect(Call("ParseScriptNodeProperties", "SELECT 1;")).Exists(row =>
            (int)Get(row, "NodeId") == (int)Get(literal, "NodeId") && (string)Get(row, "PropertyName") == "Value" && (string)Get(row, "PropertyValue") == "1"));
        foreach (string method in new[] { "ParseScriptNodes", "ParseScriptNodeProperties" })
        {
            CultureInfo original = Thread.CurrentThread.CurrentCulture;
            try
            {
                Thread.CurrentThread.CurrentCulture = CultureInfo.GetCultureInfo("de-DE");
                string first = Signature(Collect(Call(method, "SELECT 1.25 AS [ä], N'𝄞';")));
                Thread.CurrentThread.CurrentCulture = CultureInfo.GetCultureInfo("en-US");
                Assert(first == Signature(Collect(Call(method, "SELECT 1.25 AS [ä], N'𝄞';"))));
            }
            finally { Thread.CurrentThread.CurrentCulture = original; }
        }
    }
    private static string Signature(List<object> rows)
    {
        var result = new System.Text.StringBuilder();
        foreach (object row in rows)
        {
            PropertyInfo[] fields = row.GetType().GetProperties();
            Array.Sort(fields, (a, b) => StringComparer.Ordinal.Compare(a.Name, b.Name));
            foreach (var field in fields) result.Append(field.Name).Append('=').Append(Convert.ToString(field.GetValue(row, null), CultureInfo.InvariantCulture)).Append('|');
            result.Append('\n');
        }
        return result.ToString();
    }
    private static void Corpus(string sql, int version)
    {
        Assert(Collect(Call("ParseScriptErrors", sql, version, 2097152, 256)).Count == 0);
        var nodes = Collect(Call("ParseScriptNodes", sql, version, 2097152, 256));
        var properties = Collect(Call("ParseScriptNodeProperties", sql, version, 2097152, 256));
        var ids = new HashSet<int>();
        var depths = new Dictionary<int, int>();
        int expected = 1;
        foreach (object node in nodes)
        {
            int id = (int)Get(node, "NodeId"); Assert(id == expected++); ids.Add(id);
            int? parent = (int?)Get(node, "ParentNodeId");
            Assert(parent == null ? id == 1 : parent.Value < id);
            int depth = (int)Get(node, "Depth"); Assert(parent == null ? depth == 0 : depth == depths[parent.Value] + 1); depths.Add(id, depth);
            int offset = (int)Get(node, "StartOffset"), length = (int)Get(node, "FragmentLength");
            // ScriptDom may expose an empty synthetic StatementList with -1 position metadata.
            Assert((offset == -1 && length == -1 && (int)Get(node, "FirstTokenIndex") == -1) ||
                (offset >= 0 && length >= 0 && offset + length <= sql.Length));
        }
        foreach (object row in properties) Assert(ids.Contains((int)Get(row, "NodeId")));
        string joined = ""; int index = 0;
        foreach (object token in Collect(Call("TokenizeScript", sql, version)))
        {
            Assert((int)Get(token, "TokenIndex") == index++);
            string value = (string)Get(token, "TokenText"); int offset = (int)Get(token, "StartOffset");
            if (value.Length != 0) Assert(sql.Substring(offset, value.Length) == value);
            joined += value;
        }
        Assert(joined == sql);
    }
    private static void Quotas()
    {
        Type type = typeof(ScriptParserProvider).GetNestedType("OutputBudget", BindingFlags.NonPublic);
        var ctor = type.GetConstructor(BindingFlags.Instance | BindingFlags.NonPublic, null, new[] { typeof(int), typeof(long) }, null);
        var add = type.GetMethod("Add", BindingFlags.NonPublic | BindingFlags.Instance);
        object rowBudget = ctor.Invoke(new object[] { 2, 1000L });
        add.Invoke(rowBudget, new object[] { new[] { "a" } }); add.Invoke(rowBudget, new object[] { new[] { "b" } });
        Failure(() => { try { add.Invoke(rowBudget, new object[] { new[] { "c" } }); } catch (TargetInvocationException e) { throw e.InnerException; } }, "TBX_TSQLPARSE_OUTPUT_LIMIT");
        object bytes = ctor.Invoke(new object[] { 3, 130L }); add.Invoke(bytes, new object[] { new[] { "a" } });
        Failure(() => { try { add.Invoke(bytes, new object[] { new string[0] }); } catch (TargetInvocationException e) { throw e.InnerException; } }, "TBX_TSQLPARSE_OUTPUT_LIMIT");
        foreach (long limit in new[] { 129L, 130L, 131L })
        {
            object budget = ctor.Invoke(new object[] { 1, limit });
            if (limit == 129) Failure(() => { try { add.Invoke(budget, new object[] { new[] { "a" } }); } catch (TargetInvocationException e) { throw e.InnerException; } }, "TBX_TSQLPARSE_OUTPUT_LIMIT");
            else add.Invoke(budget, new object[] { new[] { "a" } });
        }
        foreach (int limit in new[] { 256, 8192, 32768, 131072 })
        {
            object budget = ctor.Invoke(new object[] { limit, long.MaxValue });
            for (int i = 0; i < limit - 1; i++) add.Invoke(budget, new object[] { new string[0] });
            add.Invoke(budget, new object[] { new string[0] });
            Failure(() => { try { add.Invoke(budget, new object[] { new string[0] }); } catch (TargetInvocationException e) { throw e.InnerException; } }, "TBX_TSQLPARSE_OUTPUT_LIMIT");
        }
        string exactBytes = new string('x', (16777216 - 128) / 2);
        foreach (long limit in new[] { 16777215L, 16777216L, 16777217L })
        {
            object budget = ctor.Invoke(new object[] { 1, limit });
            if (limit < 16777216) Failure(() => { try { add.Invoke(budget, new object[] { new[] { exactBytes } }); } catch (TargetInvocationException e) { throw e.InnerException; } }, "TBX_TSQLPARSE_OUTPUT_LIMIT");
            else add.Invoke(budget, new object[] { new[] { exactBytes } });
        }
        MethodInfo width = typeof(ScriptParserProvider).GetMethod("CheckWidth", BindingFlags.NonPublic | BindingFlags.Static);
        foreach (int limit in new[] { 32, 64, 128, 4000 })
        {
            width.Invoke(null, new object[] { new string('x', limit - 1), limit });
            width.Invoke(null, new object[] { new string('x', limit), limit });
            Failure(() => { try { width.Invoke(null, new object[] { new string('x', limit + 1), limit }); } catch (TargetInvocationException e) { throw e.InnerException; } }, "TBX_TSQLPARSE_OUTPUT_LIMIT");
        }
    }
    private static void Boundary(string name, int n, int version, string status)
    {
        string sql = TestInputs.Make(name, n);
        foreach (string method in new[] { "ParseScriptNodes", "ParseScriptNodeProperties", "TokenizeScript", "ParseScriptErrors" })
        {
            if (status != "ACCEPT")
            {
                Failure(() => Call(method, sql, version, 2097152, 256), status == "INPUT" ? "TBX_TSQLPARSE_INPUT_TOO_LARGE" : "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT");
            }
            else
            {
                // The raw guard and AST depth are separate limits; accepted long unary chains may exceed the latter.
                try { Collect(Call(method, sql, version, 2097152, 256)); }
                catch (InvalidOperationException e) { Assert(method != "TokenizeScript" && e.Message == "TBX_TSQLPARSE_MAX_DEPTH_EXCEEDED"); }
            }
        }
    }
    public static int Main(string[] args)
    {
        Exception failure = null;
        var thread = new Thread(() => { try {
            switch (args[0]) {
                case "parameters": Parameters(); break;
                case "quotas": Quotas(); break;
                case "boundary": Boundary(args[1], Int32.Parse(args[2]), Int32.Parse(args[3]), args[4]); break;
                case "negative": Assert(Collect(Call("ParseScriptErrors", System.IO.File.ReadAllText(args[1]), Int32.Parse(args[2]))).Count > 0); Assert(Collect(Call("ParseScriptNodes", System.IO.File.ReadAllText(args[1]), Int32.Parse(args[2]))).Count == 0); break;
                case "corpus": Corpus(System.IO.File.ReadAllText(args[1]), Int32.Parse(args[2])); break;
                case "legacy": Corpus("SELECT 1;", Int32.Parse(args[1])); Corpus("SELECT \"text\";", Int32.Parse(args[1])); Assert(Collect(Call("TokenizeScript", "SELECT \"text\";", Int32.Parse(args[1]), 2097152, 100, false)).Count > 0); break;
                default: throw new Exception("UNKNOWN_CASE");
            }
        } catch (Exception e) { failure = e; } }, 262144);
        thread.Start(); thread.Join();
        if (failure != null) { Console.WriteLine("FRAMEWORK_FAILED " + (failure.Message.StartsWith("ASSERTION_", StringComparison.Ordinal) || failure.Message.StartsWith("TBX_TSQLPARSE_", StringComparison.Ordinal) ? failure.Message : failure.GetType().Name)); return 1; }
        Console.WriteLine("FRAMEWORK_PASS"); return 0;
    }
}
