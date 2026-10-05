using System;
using Toolbelt.JsonCore;
using Toolbelt.JsonConstructors;

internal static class TokenHarness
{
    private static int cases, assertions;
    private static void Assert(bool condition)
    {
        assertions++;
        if (!condition) throw new InvalidOperationException("TOKEN_ASSERT");
    }
    private static JsonTokenDocument Parse(string source)
    {
        cases++;
        var document = JsonCanonicalCore.ScanTokens(source, 128, new JsonWorkBudget(1000000));
        Assert(document.Syntax.Status == 0);
        return document;
    }
    public static int Main()
    {
        try
        {
            foreach (string source in new[] { "null", "true", "false", "-0.000e-999", "1e1000000", "\"\"", "{}", "[]" })
            {
                JsonTokenDocument document = Parse(source);
                Assert(document.Count == 1 && document.RawText(0) == source);
                Assert(document.DecodeStrings());
                int duplicate;
                Assert(document.CheckDuplicateKeys(out duplicate) && duplicate == -1);
            }
            JsonTokenDocument tree = Parse(" {\"a\":[0,{\"b\":\"x\"}],\"c\":false} ");
            Assert(tree.Count == 6);
            Assert(tree.DecodeStrings());
            JsonToken root = tree.Get(0);
            Assert(root.Kind == JsonValueKind.Object && root.Parent == -1 && root.FirstChild == 1);
            Assert(tree.Get(1).Key == "a" && tree.Get(1).FirstChild == 2 && tree.Get(1).NextSibling == 5);
            Assert(tree.Get(3).FirstChild == 4 && tree.Get(4).Key == "b" && tree.Get(4).StringValue == "x");
            Assert(tree.RawText(1) == "[0,{\"b\":\"x\"}]");

            foreach (string source in new[] {
                "{\"a\":0,\"\\u0061\":1}", "{\"\":0,\"\":1}", "{\"\\u0000\":0,\"\\u0000\":1}",
                "{\"outer\":{\"a\":0,\"a\":1}}" })
            {
                JsonTokenDocument document = Parse(source);
                Assert(document.DecodeStrings());
                int duplicate;
                Assert(!document.CheckDuplicateKeys(out duplicate) && duplicate > 0);
            }
            foreach (string source in new[] { "{\"a\":0,\"a \":1}", "{\"a\\u0000\":0,\"\\u0000a\":1}",
                "{\"qn0jz7wp1bes\":0,\"1rm845ojyvlg\":1}", "{\"e\\u0301\":0,\"\\u00e9\":1}" })
            {
                JsonTokenDocument document = Parse(source);
                Assert(document.DecodeStrings());
                int duplicate;
                Assert(document.CheckDuplicateKeys(out duplicate));
            }
            string longKey = new string('a', 4001);
            JsonTokenDocument longKeys = Parse("{\"" + longKey + "x\":0,\"" + longKey + "y\":1}");
            Assert(longKeys.DecodeStrings());
            int longDuplicate;
            Assert(longKeys.CheckDuplicateKeys(out longDuplicate));
            Assert(longKeys.Get(1).Key.Length == 4002 && longKeys.Get(2).Key.Length == 4002);
            foreach (string source in new[] { "\"\\uD800\\uDC00\"", "\"" + (char)0xD800 + "\\uDC00\"", "\"\\uD800" + (char)0xDC00 + "\"" })
            {
                JsonTokenDocument document = Parse(source);
                Assert(document.DecodeStrings());
                Assert(document.Get(0).ScalarLength == 1 && document.Get(0).StringValue.Length == 2);
            }
            foreach (string source in new[] { "\"\\uD800\"", "{\"\\uDC00\":0}", "{\"unused\":\"\\uD800x\"}" })
            {
                JsonTokenDocument document = Parse(source);
                Assert(!document.DecodeStrings());
            }
            foreach (string source in new[] { "[1,]", "{\"a\":1,}", "01", "1.", "1e+", "[}", "true false", "\"\\x\"" })
            {
                cases++;
                Assert(JsonCanonicalCore.ScanTokens(source, 128, new JsonWorkBudget(1000000)).Syntax.Status == 1);
            }
            cases++;
            string depth128 = new string('[', 128) + "0" + new string(']', 128);
            Assert(JsonCanonicalCore.ScanTokens(depth128, 128, new JsonWorkBudget(1000000)).Syntax.Status == 0);
            cases++;
            Assert(JsonCanonicalCore.ScanTokens("[" + depth128 + "]", 128, new JsonWorkBudget(1000000)).Syntax.Status == 2);
            cases++;
            Assert(JsonCanonicalCore.ScanTokens("[[0]]", 1, new JsonWorkBudget(1000000)).Syntax.Status == 2);
            cases++;
            bool limited = false;
            try { JsonCanonicalCore.ScanTokens("[]", 128, new JsonWorkBudget(1)); }
            catch (JsonWorkLimitException) { limited = true; }
            Assert(limited);
            cases++;
            var measuring = new JsonWorkBudget(1000000);
            JsonCanonicalCore.ScanTokens("\"abc\"", 128, measuring);
            var decodeBudget = new JsonWorkBudget(measuring.Used + 3);
            JsonTokenDocument decodeLimited = JsonCanonicalCore.ScanTokens("\"abc\"", 128, decodeBudget);
            limited = false;
            try { decodeLimited.DecodeStrings(); }
            catch (JsonWorkLimitException) { limited = true; }
            Assert(limited && decodeLimited.Get(0).StringValue == null);
            Console.WriteLine("PASS CORE_TOKENS CASES " + cases + " ASSERTIONS " + assertions);
            return 0;
        }
        catch (Exception)
        {
            Console.WriteLine("FAIL CORE_TOKENS CASE " + cases);
            return 1;
        }
    }
}
