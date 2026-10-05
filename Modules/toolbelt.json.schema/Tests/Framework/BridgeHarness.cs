using System;
using System.Collections;
using System.Data.SqlTypes;
using System.Globalization;
using System.Reflection;
using Microsoft.SqlServer.Server;
using Toolbelt.JsonCore;
using Toolbelt.JsonSchema;

internal static class BridgeHarness
{
    private static int assertions;
    private static void Assert(bool value, string label)
    { assertions++; if (!value) throw new Exception(label); }
    private static IEnumerable Run(string json, string schema, int errors = 100)
    {
        return JsonSchemaBridge.Validate(json == null ? SqlChars.Null : new SqlChars(json),
            schema == null ? SqlChars.Null : new SqlChars(schema), new SqlString(SchemaValidator.ProfileName),
            new SqlInt64(16777216), new SqlInt64(1048576), new SqlInt32(128), new SqlInt64(1000000), new SqlInt32(errors));
    }
    private static void Main(string[] args)
    {
        CultureInfo.CurrentCulture = CultureInfo.GetCultureInfo(args[0]);
        var method = typeof(JsonSchemaBridge).GetMethod("Validate");
        Type[] inputs = { typeof(SqlChars), typeof(SqlChars), typeof(SqlString), typeof(SqlInt64), typeof(SqlInt64), typeof(SqlInt32), typeof(SqlInt64), typeof(SqlInt32) };
        var parameters = method.GetParameters();
        Assert(parameters.Length == 8 && method.ReturnType == typeof(IEnumerable), "bridge signature");
        for (int i = 0; i < inputs.Length; i++) Assert(parameters[i].ParameterType == inputs[i], "input " + i);
        var attribute = (SqlFunctionAttribute)Attribute.GetCustomAttribute(method, typeof(SqlFunctionAttribute));
        Assert(attribute != null && attribute.DataAccess == DataAccessKind.None && attribute.SystemDataAccess == SystemDataAccessKind.None &&
            attribute.IsDeterministic && attribute.IsPrecise && attribute.FillRowMethodName == "FillRow", "SQL attribute");
        Assert(attribute.TableDefinition == "RowKind nvarchar(8), ErrorOrdinal int, Status nvarchar(24), Profile nvarchar(32), IsValid bit, DocumentPointer nvarchar(max), SchemaPointer nvarchar(max), Keyword nvarchar(128), ErrorCode nvarchar(32), ErrorsTruncated bit", "physical ten column contract");
        var fill = typeof(JsonSchemaBridge).GetMethod("FillRow").GetParameters();
        Type[] outputs = { typeof(SqlString), typeof(SqlInt32), typeof(SqlString), typeof(SqlString), typeof(SqlBoolean), typeof(SqlChars), typeof(SqlChars), typeof(SqlString), typeof(SqlString), typeof(SqlBoolean) };
        Assert(fill.Length == 11 && fill[0].ParameterType == typeof(object), "fill signature");
        for (int i = 0; i < outputs.Length; i++) Assert(fill[i + 1].IsOut && fill[i + 1].ParameterType == outputs[i].MakeByRefType(), "output " + i);
        Assert(typeof(JsonTokenDocument).Assembly != typeof(JsonSchemaBridge).Assembly, "physical shared core");
        Assert(typeof(JsonSchemaBridge).Assembly.GetName().Version == new Version(1,0,0,0), "schema identity");
        Assert(typeof(JsonTokenDocument).Assembly.GetName().Name == "Toolbelt.JsonCore", "core identity");
        foreach (Type type in typeof(JsonTokenDocument).Assembly.GetTypes())
            foreach (MethodInfo member in type.GetMethods(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Static | BindingFlags.DeclaredOnly))
                Assert(!Attribute.IsDefined(member, typeof(SqlFunctionAttribute)), "no core SQL API");
        foreach (string json in new[] { null, "1", "\"x\"", "[1,2]", "{\"a\":1}" })
        {
            int ordinal = 0;
            foreach (object row in Run(json, "{\"type\":\"integer\"}"))
            {
                SqlString kind, status, profile, keyword, code;
                SqlInt32 errorOrdinal;
                SqlBoolean valid, truncated;
                SqlChars document, schema;
                JsonSchemaBridge.FillRow(row, out kind, out errorOrdinal, out status, out profile, out valid,
                    out document, out schema, out keyword, out code, out truncated);
                Assert(kind.Value == (ordinal == 0 ? "SUMMARY" : "ERROR") && errorOrdinal.Value == ordinal++, "stream ordinal");
                Assert(profile.Value == SchemaValidator.ProfileName && !truncated.IsNull, "stream constants");
                if (json == null) Assert(status.Value == "SQL_NULL" && valid.IsNull && document.IsNull && schema.IsNull, "stream SQL null");
                else if (json == "1") Assert(status.Value == "VALID" && valid.Value && code.IsNull, "stream valid");
                else Assert(status.Value == "INVALID_INSTANCE" && !valid.IsNull && !valid.Value, "stream invalid");
            }
        }
        string longKey = new String('x', 5000) + "/~";
        string doc = "{\"" + longKey + "\":1}";
        string schemaText = "{\"properties\":{\"" + longKey + "\":false}}";
        var large = SchemaValidator.Validate(doc, schemaText, SchemaValidator.ProfileName, 16777216,1048576,128,1000000,100);
        Assert(large[1].DocumentPointer == "/" + new String('x',5000) + "~1~0" && large[1].SchemaPointer == "/properties/" + new String('x',5000) + "~1~0", "untruncated long pointers");
        var unsupported = SchemaValidator.Validate("null", "{\"" + new String('k',129) + "\":null}", SchemaValidator.ProfileName,16777216,1048576,128,1000000,100);
        Assert(unsupported[0].Status == "UNSUPPORTED" && unsupported[0].Keyword == null && unsupported[0].SchemaPointer.Length == 130, "unsupported keyword length");
        for (int field = 0; field < 6; field++)
        {
            bool rejected = false;
            try
            {
                JsonSchemaBridge.Validate(SqlChars.Null, SqlChars.Null,
                    field == 0 ? SqlString.Null : new SqlString(SchemaValidator.ProfileName),
                    field == 1 ? SqlInt64.Null : new SqlInt64(16777216),
                    field == 2 ? SqlInt64.Null : new SqlInt64(1048576),
                    field == 3 ? SqlInt32.Null : new SqlInt32(128),
                    field == 4 ? SqlInt64.Null : new SqlInt64(1000000),
                    field == 5 ? SqlInt32.Null : new SqlInt32(100));
            }
            catch (ArgumentException) { rejected = true; }
            Assert(rejected, "null argument " + field);
        }
        foreach (string profile in new[] { "TOOLBELT-2020-12-V1", "toolbelt-2020-12-v1 ", "toolbelt-2020-12-v1\0", "" })
        {
            bool rejected = false;
            try { SchemaValidator.Validate(null,null,profile,16777216,1048576,128,1000000,100); }
            catch (ArgumentException) { rejected = true; }
            Assert(rejected, "exact profile");
        }
        Console.WriteLine("PASS SCHEMA_BRIDGE assertions=" + assertions + " culture=" + args[0]);
    }
}
