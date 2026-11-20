// Real release assembly, offline only. Invalid business inputs are chosen so
// the false/NULL control paths fail before context/root/file access.
using System;
using System.Data.SqlTypes;
using System.IO;
using System.Reflection;
using System.Text;
using Microsoft.SqlServer.Server;

internal static class ClrProviderUsageSkillHarness
{
    private static int assertions;
    private static void Check(bool value)
    {
        if (!value) throw new Exception("CLR_PROVIDER_SKILL_ASSERTION_" + assertions);
        assertions++;
    }

    private static Exception Invoke(MethodInfo method, object[] values)
    {
        try { method.Invoke(null, values); return null; }
        catch (TargetInvocationException error) { return error.InnerException; }
    }

    private static int Main(string[] args)
    {
        try { return Run(args); }
        catch (Exception failure)
        {
            string code = failure.Message.StartsWith("CLR_PROVIDER_SKILL_ASSERTION_", StringComparison.Ordinal)
                ? failure.Message : failure.GetType().Name;
            Console.Error.WriteLine("CLR_PROVIDER_SKILL_OFFLINE_FAILED " + code);
            return 1;
        }
    }

    private static int Run(string[] args)
    {
        Check(args.Length == 2);
        Check(!SqlContext.IsAvailable);
        Assembly assembly = Assembly.LoadFrom(Path.GetFullPath(args[0]));
        Type provider = assembly.GetType("Toolbelt.Filesystem.Windows.WindowsFilesystemProvider", true);
        Type generated = assembly.GetType("Toolbelt.Filesystem.Windows.UsageSkillsGenerated", true);
        MethodInfo factory = generated.GetMethod("CreateRecord", BindingFlags.Static | BindingFlags.NonPublic);
        Check(factory != null);
        string[] entries = File.ReadAllLines(Path.Combine(args[1], "Expected.tsv"), new UTF8Encoding(false, true));
        Check(entries.Length == 9);
        foreach (string entry in entries)
        {
            string[] parts = entry.Split('\t');
            Check(parts.Length == 3);
            string expected = File.ReadAllText(Path.Combine(args[1], parts[2]), new UTF8Encoding(false, true));
            SqlDataRecord row = (SqlDataRecord)factory.Invoke(null, new object[] { parts[0], parts[1] });
            Check(row.FieldCount == 4);
            Check(row.GetString(0) == "1.0" && row.GetString(1) == parts[0] && row.GetString(2) == parts[1]);
            Check(row.GetSqlMetaData(3).MaxLength == SqlMetaData.Max);
            Check(String.Equals(row.GetString(3), expected, StringComparison.Ordinal));
            string methodName = parts[1].Substring(4);
            MethodInfo method = provider.GetMethod(methodName, BindingFlags.Static | BindingFlags.Public);
            Check(method != null);
            ParameterInfo[] parameters = method.GetParameters();
            Check(parameters[parameters.Length - 1].Name == "hilfe");
            Check(parameters[parameters.Length - 1].ParameterType == typeof(SqlBoolean));
            Check(parameters[parameters.Length - 1].IsOptional);
            object[] values = new object[parameters.Length];
            for (int i = 0; i < values.Length - 1; i++)
            {
                Type type = parameters[i].ParameterType;
                if (type == typeof(string)) values[i] = parameters[i].Name == "executionIdentity" ? "invalid" : null;
                else if (type == typeof(long)) values[i] = -1L;
                else if (type == typeof(int)) values[i] = -1;
                else if (type == typeof(bool)) values[i] = false;
                else if (type == typeof(SqlBytes)) values[i] = SqlBytes.Null;
                else if (type == typeof(SqlChars)) values[i] = SqlChars.Null;
                else throw new Exception("UNEXPECTED_PROVIDER_PARAMETER_TYPE");
            }
            string code = methodName.StartsWith("Read", StringComparison.Ordinal) ? "InvalidChunkRange"
                : methodName.StartsWith("Write", StringComparison.Ordinal) ? "ContentRequired"
                : methodName == "ListDirectory" || methodName == "RemoveDirectory" ? "InvalidListLimit"
                : "InvalidExecutionIdentity";
            foreach (SqlBoolean mode in new SqlBoolean[] { SqlBoolean.False, SqlBoolean.Null })
            {
                values[values.Length - 1] = mode;
                Exception failure = Invoke(method, values);
                Check(failure is InvalidOperationException && failure.Message == "TBXFS:" + code);
            }
            values[values.Length - 1] = SqlBoolean.True;
            Exception help = Invoke(method, values);
            // Compare with the actual host's missing-Pipe behavior rather than
            // assuming one exception class across Framework installations.
            Exception missingHost = null;
            try { SqlContext.Pipe.Send(row); }
            catch (Exception failure) { missingHost = failure; }
            Check(missingHost != null && help != null && help.GetType() == missingHost.GetType()
                  && help.Message == missingHost.Message);
        }
        Console.WriteLine("CLR_PROVIDER_SKILL_OFFLINE_PASS objects=9 assertions=" + assertions
            + "; SQL_NOT_EXECUTED; PIPE_NOT_QUALIFIED; FILE_OPERATIONS_NOT_EXECUTED");
        return 0;
    }
}
