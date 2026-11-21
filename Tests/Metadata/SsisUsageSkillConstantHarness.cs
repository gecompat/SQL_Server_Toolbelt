// Offline inspection of the compiled SSIS help constant; no provider invocation.
using System;
using System.IO;
using System.Reflection;
using System.Text;

internal static class SsisUsageSkillConstantHarness
{
    private static int Main(string[] args)
    {
        if (args.Length != 2) throw new ArgumentException("provider and expected skill SELECT required");
        Assembly provider = Assembly.LoadFrom(args[0]);
        Type help = provider.GetType("Toolbelt.Tsql.SsisDebug.HelpContract", true);
        FieldInfo field = help.GetField("Sql", BindingFlags.Static | BindingFlags.NonPublic);
        if (field == null || !field.IsLiteral || field.FieldType != typeof(string))
            throw new InvalidOperationException("SSIS_HELP_CONSTANT_REQUIRED");
        string sql = (string)field.GetRawConstantValue();
        string expected = File.ReadAllText(args[1], new UTF8Encoding(false, true));
        if (!sql.EndsWith("\n" + expected, StringComparison.Ordinal))
            throw new InvalidOperationException("SSIS_HELP_SKILL_BYTES_DIFFER");
        string standard = sql.Substring(0, sql.Length - expected.Length - 1);
        if (standard.IndexOf("HelpContractVersion", StringComparison.Ordinal) < 0 ||
            expected.IndexOf("SkillMarkdown", StringComparison.Ordinal) < 0 ||
            expected.IndexOf("nvarchar(max)", StringComparison.Ordinal) < 0 ||
            expected.IndexOf('\r') >= 0 || expected.Length <= 4000)
            throw new InvalidOperationException("SSIS_HELP_SKILL_SHAPE_INVALID");
        Console.WriteLine("SSIS_USAGE_SKILL_CONSTANT_PASS; NO_SQL_EXECUTED");
        return 0;
    }
}
