using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;
using Toolbelt.JsonSchema;

internal static class SchemaHarness
{
    private static int cases, assertions;
    private static void Assert(bool value, string label)
    { assertions++; if (!value) throw new Exception(label); }
    private static IReadOnlyList<SchemaResultRow> Check(string label, string json, string schema,
        string status, string code = null, int maxErrors = 100, int depth = 128,
        long steps = 1000000, long documentBytes = 16777216, long schemaBytes = 1048576)
    {
        cases++;
        var rows = SchemaValidator.Validate(json, schema, SchemaValidator.ProfileName,
            documentBytes, schemaBytes, depth, steps, maxErrors);
        Assert(rows.Count >= 1 && rows.Count <= maxErrors + 1, label + ": row count");
        Assert(rows[0].RowKind == "SUMMARY" && rows[0].ErrorOrdinal == 0, label + ": summary");
        Assert(rows[0].Status == status && rows[0].ErrorCode == code, label + ": " + rows[0].Status + "/" + rows[0].ErrorCode);
        bool? expected = status == "VALID" ? (bool?)true : status == "INVALID_INSTANCE" ? (bool?)false : null;
        foreach (var row in rows)
        {
            Assert(row.Profile == SchemaValidator.ProfileName && row.Status == status && row.IsValid == expected, label + ": final verdict");
            Assert(row.ErrorsTruncated == rows[0].ErrorsTruncated, label + ": final truncation");
        }
        for (int i = 1; i < rows.Count; i++) Assert(rows[i].RowKind == "ERROR" && rows[i].ErrorOrdinal == i, label + ": error order");
        return rows;
    }

    private static void Main(string[] args)
    {
        CultureInfo.CurrentCulture = CultureInfo.GetCultureInfo(args[0]);
        CultureInfo.CurrentUICulture = CultureInfo.CurrentCulture;
        Check("true", "null", "true", "VALID");
        Check("false", "null", "false", "INVALID_INSTANCE", "INSTANCE_VIOLATION");
        Check("empty", "42", "{}", "VALID");
        Check("SQL null first", null, "{", "SQL_NULL", "SQL_NULL", schemaBytes: 1);
        Check("schema bytes", "{", "true", "LIMIT", "SCHEMA_BYTES", schemaBytes: 7);
        Check("schema syntax before document bytes", "123", "{", "INVALID_SCHEMA", "JSON_SYNTAX", documentBytes: 1);
        Check("schema form", "null", "[]", "INVALID_SCHEMA", "SCHEMA_FORM");
        Check("document bytes", "null", "true", "LIMIT", "DOCUMENT_BYTES", documentBytes: 7);
        Check("document syntax", "[1,]", "{}", "INVALID_JSON", "JSON_SYNTAX");
        Check("schema dup", "null", "{\"title\":\"a\",\"title\":\"b\"}", "INVALID_SCHEMA", "DUPLICATE_KEY");
        Check("document dup", "{\"a\":1,\"\\u0061\":2}", "true", "INVALID_JSON", "DUPLICATE_KEY");
        Check("unused surrogate", "null", "{\"$defs\":{\"a\":{\"title\":\"\\ud800\"}}}", "UNSUPPORTED", "UNPAIRED_SURROGATE");
        Check("syntax before unicode", "\"\\ud800\"x", "true", "INVALID_JSON", "JSON_SYNTAX");
        Check("scalar syntax", "01", "true", "INVALID_JSON", "JSON_SYNTAX");
        Check("annotation form", "null", "{\"title\":1}", "INVALID_SCHEMA", "KEYWORD_FORM");
        Check("draft", "null", "{\"$schema\":\"http://json-schema.org/draft-07/schema#\"}", "UNSUPPORTED", "DRAFT");
        Check("draft valid", "null", "{\"$schema\":\"https://json-schema.org/draft/2020-12/schema\"}", "VALID");
        foreach (string keyword in new[] {"format", "pattern", "enum", "const", "allOf", "$id", "$anchor", "multipleOf", "uniqueItems", "unevaluatedProperties"})
            Check("unsupported " + keyword, "null", "{\"" + keyword + "\":null}", "UNSUPPORTED", "KEYWORD_UNSUPPORTED");
        Check("unused unsupported", "null", "{\"$defs\":{\"unused\":{\"format\":\"email\"}}}", "UNSUPPORTED", "KEYWORD_UNSUPPORTED");
        Check("names are not keywords", "{\"format\":1}", "{\"properties\":{\"format\":true}}", "VALID");
        string[] types = {"null", "boolean", "number", "string", "object", "array", "integer"};
        string[] documents = {"null", "true", "0.5", "\"x\"", "{}", "[]", "1e3"};
        for (int i = 0; i < types.Length; i++)
            for (int j = 0; j < documents.Length; j++)
            {
                bool valid = i == j || (i == 2 && j == 6);
                Check(types[i] + "/" + j, documents[j], "{\"type\":\"" + types[i] + "\"}",
                    valid ? "VALID" : "INVALID_INSTANCE", valid ? null : "INSTANCE_VIOLATION");
            }
        Check("integer decimal exact", "1.000e0", "{\"type\":\"integer\"}", "VALID");
        Check("negative zero huge", "-0e-999999999999999999999", "{\"type\":\"integer\"}", "VALID");
        Check("type duplicate", "null", "{\"type\":[\"number\",\"number\"]}", "INVALID_SCHEMA", "KEYWORD_FORM");
        Check("type empty", "null", "{\"type\":[]}", "INVALID_SCHEMA", "KEYWORD_FORM");
        Check("type union", "42", "{\"type\":[\"null\",\"integer\"]}", "VALID");
        Check("type union form", "null", "{\"type\":[true]}", "INVALID_SCHEMA", "KEYWORD_FORM");
        foreach (string keyword in new[] {"minItems", "maxItems", "minProperties", "maxProperties", "minLength", "maxLength"})
        {
            Check(keyword + " negative", "null", "{\"" + keyword + "\":-1}", "INVALID_SCHEMA", "KEYWORD_FORM");
            Check(keyword + " fractional", "null", "{\"" + keyword + "\":0.5}", "INVALID_SCHEMA", "KEYWORD_FORM");
            Check(keyword + " huge integer", "null", "{\"" + keyword + "\":1e999999999999999999}", "VALID");
        }
        Check("bounds contradiction", "1", "{\"minimum\":2,\"maximum\":0}", "INVALID_INSTANCE", "INSTANCE_VIOLATION");
        Check("exact below minimum", "9007199254740992", "{\"minimum\":9007199254740993}", "INVALID_INSTANCE", "INSTANCE_VIOLATION");
        Check("exact equal", "1e100000000000000000000", "{\"minimum\":10e99999999999999999999,\"maximum\":1e100000000000000000000}", "VALID");
        Check("exclusive equal", "1", "{\"exclusiveMinimum\":1,\"exclusiveMaximum\":1}", "INVALID_INSTANCE", "INSTANCE_VIOLATION");
        Check("unicode scalar", "\"\\ud83d\\ude00\"", "{\"minLength\":1,\"maxLength\":1}", "VALID");
        Check("unicode mixed", "\"" + '\ud83d' + "\\ude00\"", "{\"maxLength\":1}", "VALID");
        Check("NUL counts", "\"\\u0000\"", "{\"minLength\":1}", "VALID");
        Check("required empty", "{}", "{\"required\":[]}", "VALID");
        Check("required duplicate", "{}", "{\"required\":[\"a\",\"\\u0061\"]}", "INVALID_SCHEMA", "KEYWORD_FORM");
        Check("required nonstring", "{}", "{\"required\":[1]}", "INVALID_SCHEMA", "KEYWORD_FORM");
        var required = Check("required pointer", "{}", "{\"required\":[\"z\",\"a\"]}", "INVALID_INSTANCE", "INSTANCE_VIOLATION");
        Assert(required[1].DocumentPointer == "" && required[1].SchemaPointer == "/required/0", "required path");
        Assert(required[2].SchemaPointer == "/required/1", "required array order");
        Check("ordinal required", "{\"a \":1}", "{\"required\":[\"a\"]}", "INVALID_INSTANCE", "INSTANCE_VIOLATION");
        Check("NUL required", "{\"a\\u0000\":1}", "{\"required\":[\"a\\u0000\"]}", "VALID");
        var properties = Check("property order", "{\"z\":1,\"a/b~\":2,\"a\":3}", "{\"properties\":{\"z\":false,\"a\":false,\"a/b~\":false}}", "INVALID_INSTANCE", "INSTANCE_VIOLATION");
        Assert(properties[1].DocumentPointer == "/a" && properties[2].DocumentPointer == "/a~1b~0" && properties[3].DocumentPointer == "/z", "property ordinal paths");
        var additional = Check("additional", "{\"z\":1,\"a\":2}", "{\"additionalProperties\":false}", "INVALID_INSTANCE", "INSTANCE_VIOLATION");
        Assert(additional[1].ErrorCode == "ADDITIONAL_PROPERTY" && additional[1].DocumentPointer == "/a", "additional code/order");
        Check("additional schema", "{\"a\":1}", "{\"additionalProperties\":{\"type\":\"string\"}}", "INVALID_INSTANCE", "INSTANCE_VIOLATION");
        Check("property exempts additional", "{\"a\":1}", "{\"properties\":{\"a\":true},\"additionalProperties\":false}", "VALID");
        Check("prefix empty", "[]", "{\"prefixItems\":[]}", "INVALID_SCHEMA", "KEYWORD_FORM");
        var array = Check("prefix and items", "[1,2,3]", "{\"prefixItems\":[false],\"items\":false}", "INVALID_INSTANCE", "INSTANCE_VIOLATION");
        Assert(array.Count == 4 && array[1].DocumentPointer == "/0" && array[2].DocumentPointer == "/1" && array[3].DocumentPointer == "/2", "array order");
        Check("no implicit array type", "null", "{\"minItems\":100,\"items\":false}", "VALID");
        foreach (string reference in new[] {"#/$defs/a", "#%2F$defs%2Fa"})
            Check("local ref " + reference, "1", "{\"$defs\":{\"a\":{\"type\":\"integer\"}},\"$ref\":\"" + reference + "\"}", "VALID");
        Check("ref sibling", "1", "{\"$defs\":{\"a\":true},\"$ref\":\"#/$defs/a\",\"type\":\"string\"}", "INVALID_INSTANCE", "INSTANCE_VIOLATION");
        Check("escaped ref", "null", "{\"$defs\":{\"a/b~\":true},\"$ref\":\"#/$defs/a~1b~0\"}", "VALID");
        Check("utf8 ref", "null", "{\"$defs\":{\"\\u00e4\":true},\"$ref\":\"#/$defs/%C3%A4\"}", "VALID");
        Check("NUL ref", "null", "{\"$defs\":{\"\\u0000\":true},\"$ref\":\"#/$defs/%00\"}", "VALID");
        Check("single percent decode", "null", "{\"$defs\":{\"%2F\":true},\"$ref\":\"#/$defs/%252F\"}", "VALID");
        foreach (string reference in new[] {"#/%", "#/%GG", "#/%C0%AF", "#/%ED%A0%80", "#/%F4%90%80%80", "#/%E2%82", "#/a~2", "#/a~", "#abc", "#/a b", "#/a#b", "#/ä"})
            Check("bad ref " + reference, "null", "{\"$ref\":\"" + reference + "\"}", "INVALID_SCHEMA", "REF_SYNTAX");
        Check("external", "null", "{\"$ref\":\"https://example.com/schema\"}", "UNSUPPORTED", "EXTERNAL_REF");
        Check("missing ref", "null", "{\"$ref\":\"#/$defs/no\"}", "INVALID_SCHEMA", "REF_TARGET");
        Check("map not schema ref", "null", "{\"$defs\":{},\"$ref\":\"#/$defs\"}", "INVALID_SCHEMA", "REF_TARGET");
        Check("root cycle", "null", "{\"$ref\":\"#\"}", "UNSUPPORTED", "REF_CYCLE");
        Check("unused cycle", "null", "{\"$defs\":{\"a\":{\"$ref\":\"#/$defs/b\"},\"b\":{\"$ref\":\"#/$defs/a\"}}}", "UNSUPPORTED", "REF_CYCLE");
        Check("containment cycle", "null", "{\"properties\":{\"a\":{\"$ref\":\"#\"}}}", "UNSUPPORTED", "REF_CYCLE");
        // Schemaorte verwenden codierte Pointer: z < ~0 < ~1. Die Discovery
        // und Instanzevaluation nach decodierten Keys bleiben / < z < ~.
        var formOrder = Check("encoded schema form order", "null", "{\"$defs\":{\"/\":1,\"~\":[],\"z\":null}}", "INVALID_SCHEMA", "SCHEMA_FORM");
        Assert(formOrder[0].SchemaPointer == "/$defs/z" && formOrder[1].SchemaPointer == "/$defs/z", "encoded form path");
        var keywordOrder = Check("encoded schema keyword order", "null", "{\"$defs\":{\"/\":{\"pattern\":\"x\"},\"~\":{\"pattern\":\"x\"},\"z\":{\"pattern\":\"x\"}}}", "UNSUPPORTED", "KEYWORD_UNSUPPORTED");
        Assert(keywordOrder[1].SchemaPointer == "/$defs/z/pattern", "encoded keyword path");
        var mixedOrder = Check("encoded mixed schema order", "null", "{\"$defs\":{\"/\":1,\"z\":{\"pattern\":\"x\"}}}", "UNSUPPORTED", "KEYWORD_UNSUPPORTED");
        Assert(mixedOrder[1].SchemaPointer == "/$defs/z/pattern", "ordered keyword before later form");
        var formIndex = Check("encoded schema array form order", "null", "{\"prefixItems\":[true,true,1,true,true,true,true,true,true,true,null]}", "INVALID_SCHEMA", "SCHEMA_FORM");
        Assert(formIndex[1].SchemaPointer == "/prefixItems/10", "encoded array index before two");
        var cycleOrder = Check("encoded graph order", "null", "{\"$defs\":{\"/\":{\"$ref\":\"#/$defs/~1\"},\"~\":{\"$ref\":\"#/$defs/~0\"},\"z\":{\"$ref\":\"#/$defs/z\"}}}", "UNSUPPORTED", "REF_CYCLE");
        Assert(cycleOrder[0].SchemaPointer == "/$defs/z/$ref" && cycleOrder[1].SchemaPointer == "/$defs/z/$ref", "encoded first cycle path");
        var cycleIndex = Check("encoded graph array order", "null", "{\"prefixItems\":[true,true,{\"$ref\":\"#/prefixItems/2\"},true,true,true,true,true,true,true,{\"$ref\":\"#/prefixItems/10\"}]}", "UNSUPPORTED", "REF_CYCLE");
        Assert(cycleIndex[1].SchemaPointer == "/prefixItems/10/$ref", "encoded first array cycle");
        var decodedOrder = Check("decoded instance member order", "{\"~\":1,\"z\":1,\"/\":1}", "{\"properties\":{\"z\":false,\"/\":false,\"~\":false}}", "INVALID_INSTANCE", "INSTANCE_VIOLATION");
        Assert(decodedOrder[1].DocumentPointer == "/~1" && decodedOrder[2].DocumentPointer == "/z" && decodedOrder[3].DocumentPointer == "/~0", "decoded instance paths retained");
        var decodedExtra = Check("decoded additional member order", "{\"~\":1,\"z\":1,\"/\":1}", "{\"additionalProperties\":false}", "INVALID_INSTANCE", "INSTANCE_VIOLATION");
        Assert(decodedExtra[1].DocumentPointer == "/~1" && decodedExtra[2].DocumentPointer == "/z" && decodedExtra[3].DocumentPointer == "/~0", "decoded additional paths retained");
        var numericIndex = Check("numeric instance array order", "[0,0,0,0,0,0,0,0,0,0,0]", "{\"prefixItems\":[true,true,false,true,true,true,true,true,true,true,false]}", "INVALID_INSTANCE", "INSTANCE_VIOLATION");
        Assert(numericIndex[1].DocumentPointer == "/2" && numericIndex[2].DocumentPointer == "/10", "numeric instance index retained");
        Check("encoded graph bounded work", "null", "{\"$defs\":{\"/\":true,\"~\":true,\"z\":true}}", "LIMIT", "EVALUATION_LIMIT", steps: 200);
        Check("ref array", "null", "{\"prefixItems\":[true],\"$ref\":\"#/prefixItems/0\"}", "VALID");
        Check("ref array leading zero", "null", "{\"prefixItems\":[true],\"$ref\":\"#/prefixItems/00\"}", "INVALID_SCHEMA", "REF_TARGET");
        Check("ref array overflow", "null", "{\"prefixItems\":[true],\"$ref\":\"#/prefixItems/99999999999999999\"}", "INVALID_SCHEMA", "REF_TARGET");
        var zero = Check("zero diagnostics", "[1,2]", "{\"items\":false}", "INVALID_INSTANCE", "INSTANCE_VIOLATION", maxErrors: 0);
        Assert(zero.Count == 1 && zero[0].ErrorsTruncated, "zero diag complete verdict");
        var one = Check("one diagnostic", "[1,2]", "{\"items\":false}", "INVALID_INSTANCE", "INSTANCE_VIOLATION", maxErrors: 1);
        Assert(one.Count == 2 && one[0].ErrorsTruncated && one[1].DocumentPointer == "/0", "prefix retained");
        Check("one work", "null", "true", "LIMIT", "EVALUATION_LIMIT", steps: 1);
        string deep = new string('[', 129) + "0" + new string(']', 129);
        Check("depth 129", deep, "true", "LIMIT", "DEPTH_LIMIT");
        Check("depth 128", new string('[', 128) + "0" + new string(']', 128), "true", "VALID");
        Check("lowered depth", "[[]]", "true", "LIMIT", "DEPTH_LIMIT", depth: 1);
        Check("depth before later syntax", deep + "x", "true", "LIMIT", "DEPTH_LIMIT");
        var chain = new StringBuilder("{\"$defs\":{");
        for (int i = 0; i < 200; i++)
        {
            if (i > 0) chain.Append(',');
            chain.Append('"').Append(i).Append("\":");
            if (i == 199) chain.Append("true");
            else chain.Append("{\"$ref\":\"#/$defs/").Append(i + 1).Append("\"}");
        }
        chain.Append("},\"$ref\":\"#/$defs/0\"}");
        Check("long ref chain iterative", "null", chain.ToString(), "VALID");
        // Find an actual cutoff after the first retained violation; the later
        // work limit must erase the partial Boolurteil on every retained row.
        bool witnessed = false;
        for (long steps = 250; steps < 3000 && !witnessed; steps += 17)
        {
            var rows = SchemaValidator.Validate("[1,2,3,4,5,6,7,8]", "{\"items\":false}",
                SchemaValidator.ProfileName, 16777216, 1048576, 128, steps, 1);
            if (rows[0].Status == "LIMIT" && rows.Count == 2)
            {
                cases++; witnessed = true;
                Assert(rows[0].IsValid == null && rows[1].IsValid == null && rows[1].Status == "LIMIT", "later limit overrides partial invalid");
            }
        }
        Assert(witnessed, "post-violation work cutoff witnessed");
        Console.WriteLine("PASS SCHEMA_PROFILE cases=" + cases + " assertions=" + assertions + " culture=" + args[0]);
    }
}
