using System;
using System.Globalization;
using System.IO;
using Toolbelt.JsonConstructors;

/// <summary>
/// Derselbe Testcaller wird gegen historische und neue Quelle kompiliert.
/// Getrennte Prozesse vermeiden Assemblybindung zwischen beiden Versionen.
/// </summary>
internal static class SyntaxDifferentialHarness
{
    public static int Main(string[] arguments)
    {
        try
        {
            if (arguments.Length != 1) return 2;
            foreach (string line in File.ReadAllLines(arguments[0]))
            {
                if (line.Length % 4 != 0) return 2;
                var units = new char[line.Length / 4];
                for (int i = 0; i < units.Length; i++)
                    units[i] = (char)Int32.Parse(line.Substring(i * 4, 4), NumberStyles.HexNumber, CultureInfo.InvariantCulture);
                string source = new string(units);
                foreach (JsonPolicy policy in new[] { JsonPolicy.LegacyJson, JsonPolicy.AgfJson })
                {
                    JsonScanResult result = JsonCanonicalCore.ScanJson(source, policy);
                    Console.WriteLine(String.Format(CultureInfo.InvariantCulture, "{0}|{1}|{2}|{3}|{4}",
                        result.Status, result.FirstFaultOffset, result.MaxOpenDepthObserved,
                        result.MaxStoredFrames, result.ValidDepth));
                }
            }
            return 0;
        }
        catch (Exception) { return 1; }
    }
}
