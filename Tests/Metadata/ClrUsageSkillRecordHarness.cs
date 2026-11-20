// Reiner In-memory-Vertragstest der generierten CLR-Record-Factory.
// Keine SQL-Verbindung, Pipe-Ausgabe oder Dateisystem-Fachoperation.
using System;
using System.Data;
using System.IO;
using System.Text;
using Microsoft.SqlServer.Server;

internal static class ClrUsageSkillRecordHarness
{
    private static int assertions;
    private static void Check(bool value)
    {
        if (!value) throw new Exception("CLR_RECORD_ASSERTION_" + assertions);
        assertions++;
    }

    private static int Main(string[] args)
    {
        if (args.Length == 2 && args[0] == "--module-fixture")
        {
            string[] entries = File.ReadAllLines(Path.Combine(args[1], "Expected.tsv"), new UTF8Encoding(false, true));
            Check(entries.Length == 9);
            foreach (string entry in entries)
            {
                string[] parts = entry.Split('\t');
                Check(parts.Length == 3);
                string markdown = File.ReadAllText(Path.Combine(args[1], parts[2]), new UTF8Encoding(false, true));
                SqlDataRecord actual = Toolbelt.Metadata.UsageSkillsGenerated.CreateRecord(parts[0], parts[1]);
                Check(actual.FieldCount == 4);
                Check(actual.GetString(0) == "1.0");
                Check(actual.GetString(1) == parts[0]);
                Check(actual.GetString(2) == parts[1]);
                Check(actual.GetSqlMetaData(3).MaxLength == SqlMetaData.Max);
                Check(String.Equals(actual.GetString(3), markdown, StringComparison.Ordinal));
                Check(actual.GetSqlChars(3).Length == markdown.Length);
            }
            Console.WriteLine("CLR_MODULE_SKILL_RECORD_PASS objects=9 assertions=" + assertions
                + "; SQL_NOT_EXECUTED; PIPE_NOT_INVOKED; PROVIDER_NOT_INVOKED");
            return 0;
        }
        if (args.Length != 1) throw new ArgumentException("CLR_RECORD_EXPECTED_FIXTURE_REQUIRED");
        string expected = File.ReadAllText(args[0], new UTF8Encoding(false, true));
        SqlDataRecord row = Toolbelt.Metadata.UsageSkillsGenerated.CreateRecord(
            "toolbelt_core", "USP_PrepareResultTable");
        Check(row.FieldCount == 4);
        string[] names = { "SkillFormatVersion", "SchemaName", "ObjectName", "SkillMarkdown" };
        for (int i = 0; i < names.Length; i++) Check(row.GetName(i) == names[i]);
        Check(row.GetSqlMetaData(0).SqlDbType == SqlDbType.VarChar && row.GetSqlMetaData(0).MaxLength == 16);
        Check(row.GetSqlMetaData(1).SqlDbType == SqlDbType.NVarChar && row.GetSqlMetaData(1).MaxLength == 128);
        Check(row.GetSqlMetaData(2).SqlDbType == SqlDbType.NVarChar && row.GetSqlMetaData(2).MaxLength == 128);
        Check(row.GetSqlMetaData(3).SqlDbType == SqlDbType.NVarChar && row.GetSqlMetaData(3).MaxLength == SqlMetaData.Max);
        Check(row.GetString(0) == "1.0");
        Check(row.GetString(1) == "toolbelt_core");
        Check(row.GetString(2) == "USP_PrepareResultTable");
        Check(expected.Length > 4000);
        Check(row.GetString(3).Length == expected.Length);
        Check(String.Equals(row.GetString(3), expected, StringComparison.Ordinal));
        Check(row.GetSqlChars(3).Length == expected.Length);
        SqlDataRecord other = Toolbelt.Metadata.UsageSkillsGenerated.CreateRecord(
            "toolbelt_core", "USP_SecondSessionProbe");
        Check(other.GetString(2) == "USP_SecondSessionProbe");
        Check(other.GetString(3).Contains("@RemoteSessionId"));
        bool rejected = false;
        try { Toolbelt.Metadata.UsageSkillsGenerated.CreateRecord("missing", "missing"); }
        catch (ArgumentException exception) { rejected = exception.Message == "USAGE_SKILL_UNKNOWN_OBJECT"; }
        Check(rejected);
        Console.WriteLine("CLR_SKILL_RECORD_PASS assertions=" + assertions
            + "; SQL_NOT_EXECUTED; PIPE_NOT_INVOKED");
        return 0;
    }
}
