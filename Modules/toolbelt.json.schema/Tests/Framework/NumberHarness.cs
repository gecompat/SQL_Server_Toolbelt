using System;
using System.Globalization;
using System.IO;
using Toolbelt.JsonCore;
using Toolbelt.JsonConstructors;
using Toolbelt.JsonSchema;

internal static class NumberHarness
{
    private static int cases, assertions;
    private static void Assert(bool condition)
    {
        assertions++;
        if (!condition) throw new InvalidOperationException("NUMBER_ASSERT");
    }
    private static ExactJsonNumber Parse(string literal, JsonWorkBudget work)
    {
        JsonTokenDocument document = JsonCanonicalCore.ScanTokens(literal, 128, work);
        Assert(document.Syntax.Status == 0 && document.Count == 1 && document.Get(0).Kind == JsonValueKind.Number);
        return ExactJsonNumber.FromToken(document, 0, work);
    }
    public static int Main(string[] arguments)
    {
        try
        {
            Assert(arguments.Length == 2);
            CultureInfo.CurrentCulture = CultureInfo.GetCultureInfo(arguments[1]);
            CultureInfo.CurrentUICulture = CultureInfo.CurrentCulture;
            string[] lines = File.ReadAllLines(arguments[0]);
            Assert(lines.Length > 1 && lines[0] == "Left|Right|Compare|LeftInteger|RightInteger|LeftNonNegative|RightNonNegative");
            for (int i = 1; i < lines.Length; i++)
            {
                cases++;
                string[] fields = lines[i].Split('|');
                Assert(fields.Length == 7);
                var work = new JsonWorkBudget(1000000);
                ExactJsonNumber left = Parse(fields[0], work), right = Parse(fields[1], work);
                int expected = Int32.Parse(fields[2], CultureInfo.InvariantCulture);
                Assert(left.Compare(right, work) == expected);
                Assert(right.Compare(left, work) == -expected);
                Assert(left.Compare(left, work) == 0 && right.Compare(right, work) == 0);
                Assert(left.IsInteger(work) == (fields[3] == "1") && right.IsInteger(work) == (fields[4] == "1"));
                Assert(left.IsNonNegative(work) == (fields[5] == "1") && right.IsNonNegative(work) == (fields[6] == "1"));
            }
            cases++;
            var countWork = new JsonWorkBudget(1000000);
            Assert(ExactJsonNumber.FromCount(Int32.MaxValue, countWork).Compare(Parse("2147483647", countWork), countWork) == 0);
            Assert(ExactJsonNumber.FromCount(0, countWork).Compare(Parse("-0e-999999999999999999999999", countWork), countWork) == 0);
            Console.WriteLine("PASS SCHEMA_NUMBERS CASES " + cases + " ASSERTIONS " + assertions);
            return 0;
        }
        catch (Exception)
        {
            Console.WriteLine("FAIL SCHEMA_NUMBERS CASE " + cases);
            return 1;
        }
    }
}
