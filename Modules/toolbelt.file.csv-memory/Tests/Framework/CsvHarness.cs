using System;
using System.Collections;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.Globalization;
using System.Reflection;
using System.Reflection.Emit;
using Toolbelt.Csv;

internal static class CsvHarness
{
    private static int assertions;
    private static SqlChars Chars(string value) { return value == null ? SqlChars.Null : new SqlChars(value.ToCharArray()); }
    private static void Check(bool condition) { assertions++; if (!condition) throw new Exception("CSV_FRAMEWORK_ASSERTION"); }
    private sealed class Row
    {
        internal SqlString Kind; internal SqlInt64 Number; internal SqlInt32 Column, Error; internal SqlChars Value;
    }
    private static List<Row> Parse(string text, bool header = false, string token = null, string separator = ",",
        long rows = 100000, int columns = 1024, long cells = 1000000, long bytes = 16777216)
    {
        IEnumerable result = CsvEntryPoints.Parse(Chars(text), Chars(separator), new SqlBoolean(header), Chars(token),
            new SqlInt64(rows), new SqlInt32(columns), new SqlInt64(cells), new SqlInt64(bytes));
        List<Row> output = new List<Row>();
        foreach (object item in result)
        {
            Row row = new Row();
            CsvEntryPoints.FillCell(item, out row.Kind, out row.Number, out row.Column, out row.Value, out row.Error);
            output.Add(row);
        }
        return output;
    }
    private static string Text(SqlChars value) { return value.IsNull ? null : new string(value.Value); }
    private static void Error(List<Row> rows, int code)
    {
        Check(rows.Count == 1); Row row = rows[0]; Check(!row.Error.IsNull && row.Error.Value == code);
        Check(row.Kind.IsNull && row.Number.IsNull && row.Column.IsNull && row.Value.IsNull);
    }
    private static void Value(Row row, string kind, long ordinal, int column, string text)
    {
        Check(row.Error.Value == 0 && row.Kind.Value == kind && row.Number.Value == ordinal && row.Column.Value == column);
        Check(Text(row.Value) == text);
    }
    private static string Quote(string text, string separator = ",", string token = null, bool header = false)
    {
        SqlInt64 charge = CsvEntryPoints.MeasureCell(Chars(text), Chars(separator), Chars(token), new SqlBoolean(header));
        Check(!charge.IsNull && charge.Value >= 0);
        SqlChars result = CsvEntryPoints.QuoteCell(Chars(text), Chars(separator), Chars(token), new SqlBoolean(header), new SqlInt64(16777216));
        Check(!result.IsNull && result.Length * 2 == charge.Value);
        return Text(result);
    }
    private static void Corpus()
    {
        Check(Parse("").Count == 0); Check(Parse("", true).Count == 0);
        Value(Parse("\"\"")[0], "DATA", 1, 1, "");
        List<Row> rows = Parse(","); Check(rows.Count == 2); Value(rows[0], "DATA", 1, 1, ""); Value(rows[1], "DATA", 1, 2, "");
        rows = Parse("a,"); Check(rows.Count == 2); Value(rows[1], "DATA", 1, 2, "");
        rows = Parse("\n"); Check(rows.Count == 1); Value(rows[0], "DATA", 1, 1, "");
        rows = Parse("\r\n"); Check(rows.Count == 1); Value(rows[0], "DATA", 1, 1, "");
        rows = Parse("a\n\n"); Check(rows.Count == 2); Value(rows[1], "DATA", 2, 1, "");
        rows = Parse("a\r\nb\nc\r\n"); Check(rows.Count == 3); Value(rows[2], "DATA", 3, 1, "c");
        rows = Parse("\"a\r\nb\nc\rd\",\"x\"\"y\""); Check(rows.Count == 2);
        Value(rows[0], "DATA", 1, 1, "a\r\nb\nc\rd"); Value(rows[1], "DATA", 1, 2, "x\"y");
        foreach (string invalid in new string[] { "a\r", "a\rb", "a\"b", "\"a\"x", "\"a\" ", "\"a", "a\n\"bad" }) Error(Parse(invalid), 55301);
        Error(Parse("a,b\nc"), 55302); Error(Parse("a\nb,c"), 55302);
        rows = Parse("NULL,\"NULL\",,\"\"", false, "NULL"); Check(rows.Count == 4);
        Value(rows[0], "DATA", 1, 1, null); Value(rows[1], "DATA", 1, 2, "NULL"); Value(rows[2], "DATA", 1, 3, "");
        rows = Parse("NULL,NULL \nNULL ,NULL", true, "NULL "); Check(rows.Count == 4);
        Value(rows[0], "HEADER", 0, 1, "NULL"); Value(rows[1], "HEADER", 0, 2, "NULL ");
        Value(rows[2], "DATA", 1, 1, null); Value(rows[3], "DATA", 1, 2, "NULL");
        rows = Parse(",\n", true); Check(rows.Count == 2); Value(rows[1], "HEADER", 0, 2, "");
        rows = Parse("x,x\nx,y", true, null, ",", 1, 2, 4); Check(rows.Count == 4);
        Error(Parse("x,x\nx,y", true, null, ",", 1, 2, 3), 55303);
        Error(Parse("x\ny\nz", true, null, ",", 1), 55303);
        Error(Parse("a,b", false, null, ",", 1, 1), 55303);
        Error(Parse("a", false, null, ",", 0), 55303); Error(Parse("a", false, null, ",", 100001), 55303);
        Error(Parse("a", false, null, ",", 1, 1025), 55303);
        Error(Parse("a", false, null, ",", 1, 1, 1000001), 55303);
        Error(Parse("a", false, null, ",", 1, 1, 1, 16777217), 55303);
        Check(Parse("a", false, null, ",", 1, 1, 1, 2).Count == 1);
        Error(Parse("a", false, null, ",", 1, 1, 1, 1), 55303);
        Error(Parse(null), 55300);
        foreach (string separator in new string[] { null, "", "ab", "\"", "\r", "\n", "\0", "\uD800", "\uDC00", "\uD83D\uDE00" })
            Error(Parse("", false, null, separator), 55300);
        foreach (string token in new string[] { "", ",", "\"", "\r", "\n", "\0", "\uD800", "\uDC00", new string('x', 129) })
            Error(Parse("", false, token), 55300);
        string unicode = "\0\uD800x\uDC00\uD83D\uDE00\uFEFF";
        Value(Parse(unicode)[0], "DATA", 1, 1, unicode);
        string[] values = new string[] { "", "a", " a ", ",", "\"", "\r", "\n", "\r\n", "NULL", "NULL ", unicode, "a;z", "\u0130\u0131\u00DF" };
        foreach (string separator in new string[] { ",", ";", "\t", "\u00A7" })
            foreach (string token in new string[] { null, "NULL", "NULL ", "\uD83D\uDE00" })
                foreach (string value in values)
                {
                    string quoted = Quote(value, separator, token);
                    rows = Parse(quoted + "\r\n", false, token, separator);
                    Check(rows.Count == 1); Value(rows[0], "DATA", 1, 1, value);
                    // Unabhängige feste Quotingorakel vermeiden ausschließlich Roundtrip-Selbstbestätigung.
                    if (separator == "," && token == null && value == "a") Check(quoted == "a");
                    if (value == "\"") Check(quoted == "\"\"\"\"");
                    if (value == "\r\n") Check(quoted == "\"\r\n\"");
                    if (value == token) Check(quoted == "\"" + token + "\"");
                }
        Check(Quote("", ",", null) == ""); Check(Quote(",") == "\",\"");
        Check(Quote("NULL", ",", "NULL", true) == "\"NULL\"");
        Check(Quote(null, ",", "NULL") == "NULL");
        Check(CsvEntryPoints.MeasureCell(SqlChars.Null, Chars(","), SqlChars.Null, SqlBoolean.False).Value == -55307);
        Check(CsvEntryPoints.MeasureCell(SqlChars.Null, Chars(","), Chars("NULL"), SqlBoolean.True).Value == -55307);
        Check(CsvEntryPoints.MeasureCell(Chars("a"), Chars(","), SqlChars.Null, SqlBoolean.Null).Value == -55300);
        Check(CsvEntryPoints.MeasureCell(Chars("a"), Chars("\0"), SqlChars.Null, SqlBoolean.False).Value == -55300);
        bool rejected = false;
        try { CsvEntryPoints.QuoteCell(Chars("\""), Chars(","), SqlChars.Null, SqlBoolean.False, new SqlInt64(7)); }
        catch (InvalidOperationException) { rejected = true; }
        Check(rejected); Check(Text(CsvEntryPoints.QuoteCell(Chars("\""), Chars(","), SqlChars.Null, SqlBoolean.False, new SqlInt64(8))) == "\"\"\"\"");
    }
    private static void Boundaries()
    {
        string maximum = new string('a', 8388608);
        List<Row> rows = Parse(maximum); Check(rows.Count == 1); Check(rows[0].Value.Length == 8388608);
        Error(Parse(maximum + "a"), 55303);
        Check(CsvEntryPoints.MeasureCell(Chars(maximum), Chars(","), SqlChars.Null, SqlBoolean.False).Value == 16777216);
        Check(CsvEntryPoints.QuoteCell(Chars(maximum), Chars(","), SqlChars.Null, SqlBoolean.False, new SqlInt64(16777216)).Length == 8388608);
        Check(CsvEntryPoints.MeasureCell(Chars(maximum + "a"), Chars(","), SqlChars.Null, SqlBoolean.False).Value == -55303);
        string quoteMaximum = new string('"', 4194303);
        Check(CsvEntryPoints.MeasureCell(Chars(quoteMaximum), Chars(","), SqlChars.Null, SqlBoolean.False).Value == 16777216);
        Check(CsvEntryPoints.MeasureCell(Chars(quoteMaximum + "\""), Chars(","), SqlChars.Null, SqlBoolean.False).Value == 16777220);
        Check(CsvEntryPoints.QuoteCell(Chars(quoteMaximum), Chars(","), SqlChars.Null, SqlBoolean.False, new SqlInt64(16777216)).Length == 8388608);
        string columns = new string(',', 1023); Check(Parse(columns).Count == 1024); Error(Parse(columns + ","), 55303);
        string records = new string('\n', 100000); Check(Parse(records).Count == 100000); Error(Parse(records + "\n"), 55303);
        // Eine Million Felder werden gezählt, ohne im Harness eine Million Rowobjekte zu halten.
        string ten = ",,,,,,,,,\n";
        System.Text.StringBuilder data = new System.Text.StringBuilder(1000000);
        for (int i = 0; i < 100000; i++) data.Append(ten);
        int count = 0;
        foreach (object item in CsvEntryPoints.Parse(Chars(data.ToString()), Chars(","), SqlBoolean.False, SqlChars.Null,
            new SqlInt64(100000), new SqlInt32(1024), new SqlInt64(1000000), new SqlInt64(16777216)))
        {
            SqlString kind; SqlInt64 row; SqlInt32 col, error; SqlChars value;
            CsvEntryPoints.FillCell(item, out kind, out row, out col, out value, out error);
            if (error.IsNull || error.Value != 0) throw new Exception("CSV_FRAMEWORK_MAXCELLS");
            count++;
        }
        Check(count == 1000000);
        Error(Parse(data.ToString(), false, null, ",", 100000, 1024, 999999), 55303);
        Check(CsvEntryPoints.MeasureCell(SqlChars.Null, Chars(","), Chars(new string('n', 128)), SqlBoolean.False).Value * 1000000L == 256000000L);
    }
    private static void Metadata()
    {
        Assembly assembly = typeof(CsvEntryPoints).Assembly;
        Check(assembly.GetName().Name == "Toolbelt.File.CsvMemory");
        Check(assembly.GetName().Version.ToString() == "1.0.0.0");
        foreach (AssemblyName name in assembly.GetReferencedAssemblies())
            Check(name.Name == "mscorlib" || name.Name == "System" || name.Name == "System.Data");
        foreach (string method in new string[] { "Parse", "MeasureCell", "QuoteCell" })
        {
            MethodInfo info = typeof(CsvEntryPoints).GetMethod(method);
            Microsoft.SqlServer.Server.SqlFunctionAttribute attribute = (Microsoft.SqlServer.Server.SqlFunctionAttribute)
                Attribute.GetCustomAttribute(info, typeof(Microsoft.SqlServer.Server.SqlFunctionAttribute));
            Check(attribute != null && attribute.IsDeterministic && attribute.DataAccess == Microsoft.SqlServer.Server.DataAccessKind.None &&
                attribute.SystemDataAccess == Microsoft.SqlServer.Server.SystemDataAccessKind.None);
            if (method == "Parse") Check(attribute.FillRowMethodName == "FillCell" && attribute.TableDefinition ==
                "RowKind nvarchar(6), RowOrdinal bigint, ColumnOrdinal int, Value nvarchar(max), ErrorCode int");
        }
    }
    private static bool Forbidden(Type type)
    {
        if (type == null) return false;
        string name = type.FullName ?? type.Name;
        return name.StartsWith("System.IO.", StringComparison.Ordinal) || name.StartsWith("System.Net.", StringComparison.Ordinal) ||
            name.StartsWith("System.Data.SqlClient.", StringComparison.Ordinal) || name.StartsWith("System.Reflection.", StringComparison.Ordinal) ||
            name.StartsWith("System.Threading.Thread", StringComparison.Ordinal) || name.StartsWith("System.Threading.Tasks.", StringComparison.Ordinal) ||
            name == "System.Activator" || name == "Microsoft.SqlServer.Server.SqlContext" ||
            name.StartsWith("System.Diagnostics.Process", StringComparison.Ordinal) || name == "System.Runtime.InteropServices.Marshal";
    }
    private static void ProductIL()
    {
        Assembly product = typeof(CsvEntryPoints).Assembly;
        Dictionary<short, OpCode> opcodes = new Dictionary<short, OpCode>();
        foreach (FieldInfo field in typeof(OpCodes).GetFields(BindingFlags.Public | BindingFlags.Static))
            if (field.FieldType == typeof(OpCode)) { OpCode code = (OpCode)field.GetValue(null); opcodes[code.Value] = code; }
        int methods = 0;
        foreach (Type type in product.GetTypes())
        {
            foreach (FieldInfo field in type.GetFields(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static | BindingFlags.DeclaredOnly))
                Check(field.IsLiteral); // Kein versteckter globaler veränderlicher Zustand.
            List<MethodBase> bodies = new List<MethodBase>();
            bodies.AddRange(type.GetMethods(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static | BindingFlags.Instance | BindingFlags.DeclaredOnly));
            bodies.AddRange(type.GetConstructors(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static | BindingFlags.Instance));
            foreach (MethodBase method in bodies)
            {
                Check((method.Attributes & MethodAttributes.PinvokeImpl) == 0);
                MethodBody body = method.GetMethodBody(); if (body == null) continue; methods++;
                foreach (ExceptionHandlingClause clause in body.ExceptionHandlingClauses)
                    if (clause.Flags == ExceptionHandlingClauseOptions.Clause) Check(clause.CatchType.FullName == "Toolbelt.Csv.CsvFault");
                byte[] il = body.GetILAsByteArray(); int position = 0;
                while (position < il.Length)
                {
                    short key = il[position++] == 0xFE ? unchecked((short)(0xFE00 | il[position++])) : (short)il[position - 1];
                    OpCode code; if (!opcodes.TryGetValue(key, out code)) throw new Exception("CSV_FRAMEWORK_IL_OPCODE");
                    int size;
                    switch (code.OperandType)
                    {
                        case OperandType.InlineNone: size = 0; break;
                        case OperandType.ShortInlineBrTarget: case OperandType.ShortInlineI: case OperandType.ShortInlineVar: size = 1; break;
                        case OperandType.InlineVar: size = 2; break;
                        case OperandType.InlineI8: case OperandType.InlineR: size = 8; break;
                        case OperandType.InlineSwitch: size = checked(4 + 4 * BitConverter.ToInt32(il, position)); break;
                        default: size = 4; break;
                    }
                    if (position + size > il.Length) throw new Exception("CSV_FRAMEWORK_IL_LENGTH");
                    if (code.OperandType == OperandType.InlineMethod || code.OperandType == OperandType.InlineField ||
                        code.OperandType == OperandType.InlineType || code.OperandType == OperandType.InlineTok)
                    {
                        MemberInfo reference = method.Module.ResolveMember(BitConverter.ToInt32(il, position),
                            type.IsGenericType ? type.GetGenericArguments() : null,
                            method.IsGenericMethod ? method.GetGenericArguments() : null);
                        Check(!Forbidden(reference as Type ?? reference.DeclaringType));
                    }
                    position += size;
                }
            }
        }
        Check(methods > 0);
    }
    public static int Main(string[] args)
    {
        try
        {
            if (args.Length != 2) throw new Exception("CSV_FRAMEWORK_ARGUMENTS");
            CultureInfo.CurrentCulture = CultureInfo.GetCultureInfo(args[0]);
            CultureInfo.CurrentUICulture = CultureInfo.CurrentCulture;
            Metadata(); ProductIL(); Corpus();
            if (args[1] == "boundaries") Boundaries();
            else if (args[1] != "corpus") throw new Exception("CSV_FRAMEWORK_PHASE");
            Console.WriteLine("PASS CSV_FRAMEWORK;ASSERTIONS=" + assertions.ToString(CultureInfo.InvariantCulture)); return 0;
        }
        catch { Console.Error.WriteLine("FAILED CSV_FRAMEWORK"); return 1; }
    }
}
