using System;
using System.Collections.Generic;
using Toolbelt.Tsql.ScriptParser;

internal static class GuardTests
{
    private static int count;
    private static void Check(string sql, bool accepted, int depth = 100, int expectedAtoms = -1)
    {
        int atoms, structure, comments;
        string status = PreparseGuard.Guard(sql, depth, out atoms, out structure, out comments);
        if ((status == "ACCEPT") != accepted || (expectedAtoms >= 0 && atoms != expectedAtoms))
            throw new Exception("GUARD_ASSERTION");
        count++;
    }
    private static string Repeat(string value, int n) { return string.Concat(new List<string>(new string[n]).ConvertAll(x => value)); }
    public static int Main()
    {
        try
        {
            foreach (int n in new[] { 508, 509, 510 }) Check("SELECT " + new string('~', n) + "1;", n <= 509, 100, n + 3);
            foreach (int n in new[] { 31, 32, 33 }) Check("SELECT " + new string('(', n) + "1" + new string(')', n) + ";", n <= 32);
            foreach (int n in new[] { 15, 16, 17 }) Check(Repeat("/*", n) + "x" + Repeat("*/", n) + "SELECT 1;", n <= 16);
            foreach (int n in new[] { 8182, 8183, 8184 }) Check(new string(' ', n) + "SELECT 1;", n <= 8183);
            foreach (int n in new[] { 127, 128, 129 }) Check(Repeat("SELECT 1;\nGO\n", n), n <= 128);
            foreach (int n in new[] { 168, 169, 170 }) Check("SELECT " + Repeat("1e1+", n) + "1;", n <= 169);
            Check("SELECT " + Repeat("1e1+", 169) + "1;", true, 100, 510);
            Check("SELECT " + Repeat("1e1+", 170) + "1;", false, 100, 513);
            Check("SELECT @#$;", true, 100, 5);
            Check("SELECT a\u0301_1;", true, 100, 3);
            Check("SELECT 'GO CASE BEGIN /* '' still literal', \"GO\"\"CASE\", [END]]BEGIN];", true);
            Check("/* ' \" [ */ -- ' \" [\nSELECT 1;", true);
            Check("SELECT 'unterminated", true);
            Check("/* unterminated", true);
            Check("BEGIN SELECT ((1)); END", false, 2);
            Check("BEGIN SELECT ((1)); END", true, 3);
            Check(new string(' ', 8159) + Repeat("/*", 17), false);
            Check("SELECT '" + new string('x', 1048566) + "';", true);
            Check("SELECT '" + new string('x', 1048567) + "';", false);
            foreach (string name in new[] { "case", "begin", "subquery" })
                foreach (int n in new[] { 31, 32, 33 }) Check(TestInputs.Make(name, n), n <= 32);
            foreach (int n in new[] { 0, 1 }) Check(TestInputs.Make("mixed", n), n == 0);
            foreach (int n in new[] { 499, 500, 501 }) Check(TestInputs.Make("mixedunary", n), n <= 500);
            foreach (int n in new[] { 169, 170, 171 }) Check(TestInputs.Make("semicolons", n), n <= 170);
            foreach (int n in new[] { 126, 127, 128 }) Check(TestInputs.Make("union", n), n <= 127);
            foreach (int n in new[] { 253, 254, 255 }) Check(TestInputs.Make("binary", n), n <= 254);
            foreach (int n in new[] { 168, 169, 170 }) Check(TestInputs.Make("symbols", n), n <= 169);
            foreach (int n in new[] { 508, 509, 510 }) Check(TestInputs.Make("combining", n), n <= 509);
            Console.WriteLine("GUARD_PASS " + count);
            return 0;
        }
        catch { Console.WriteLine("GUARD_FAILED"); return 1; }
    }
}
