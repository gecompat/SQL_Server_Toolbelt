using System;
using System.Collections;
using System.Data.SqlTypes;
using System.Globalization;
using System.IO;
using System.Text;
using Microsoft.SqlServer.Server;
using Toolbelt.String.EditDistance;

// Unveränderte öffentliche Paket-DLL gegen die bestehenden festen Framework-Goldens.
internal static class EditDistancePackageContract
{
    private static int assertions;
    private static int goldenRows;
    private static int jaroCases;

    private static void Need(bool condition)
    {
        assertions++;
        if (!condition) throw new Exception("EDIT_DISTANCE_PACKAGE_ASSERTION");
    }

    private static SqlChars Text(string value)
    {
        return value == null ? SqlChars.Null : new SqlChars(value);
    }

    private static void Distance(bool osa, string left, string right, int? threshold,
                                 string profile, int? expectedDistance,
                                 bool? expectedExceeds, int expectedError)
    {
        IEnumerable rows = osa
            ? DistanceProvider.Osa(Text(left), Text(right), threshold.HasValue ? new SqlInt32(threshold.Value) : SqlInt32.Null, Text(profile))
            : DistanceProvider.Levenshtein(Text(left), Text(right), threshold.HasValue ? new SqlInt32(threshold.Value) : SqlInt32.Null, Text(profile));
        object row = null;
        int count = 0;
        foreach (object item in rows) { row = item; count++; }
        Need(count == 1 && row != null);
        SqlInt32 distance, error;
        SqlBoolean exceeds;
        DistanceProvider.FillRow(row, out distance, out exceeds, out error);
        Need(!error.IsNull && error.Value == expectedError);
        Need(expectedDistance.HasValue ? (!distance.IsNull && distance.Value == expectedDistance.Value) : distance.IsNull);
        Need(expectedExceeds.HasValue ? (!exceeds.IsNull && exceeds.Value == expectedExceeds.Value) : exceeds.IsNull);
    }

    private static string HexText(string hex)
    {
        byte[] bytes = new byte[hex.Length / 2];
        for (int i = 0; i < bytes.Length; i++) bytes[i] = Convert.ToByte(hex.Substring(i * 2, 2), 16);
        return new UnicodeEncoding(false, false, true).GetString(bytes);
    }

    private static void GoldenFile(string file)
    {
        foreach (string line in File.ReadLines(file))
        {
            string[] fields = line.Split('|');
            bool osa = fields[0] == "1";
            int threshold = Int32.Parse(fields[3], CultureInfo.InvariantCulture);
            int expected = Int32.Parse(fields[4], CultureInfo.InvariantCulture);
            Distance(osa, HexText(fields[1]), HexText(fields[2]),
                threshold < 0 ? (int?)null : threshold, "standard",
                expected < 0 ? (int?)null : expected, expected < 0 ? (bool?)true : false, 0);
            goldenRows++;
        }
        Need(goldenRows == 27104);
    }

    private static void DistanceValidation()
    {
        foreach (bool osa in new[] { false, true })
        {
            Distance(osa, null, "\uD800", -1, "invalid", null, null, 0);
            Distance(osa, "\uD800", "a", -1, "invalid", null, null, 1);
            Distance(osa, "\uD800", "a", -1, "standard", null, null, 2);
            foreach (string invalid in new[] { "\uD800", "\uDFFF", "\uD800x", "x\uDC00", "\uDC00\uD800" })
                Distance(osa, invalid, "a", null, "standard", null, null, 4);
            Distance(osa, new string('a', 2049), "a", null, "standard", null, null, 3);
            Distance(osa, new string('a', 1025), "a", null, "standard", null, null, 5);
            Distance(osa, Repeat("\U0001F600", 1024), "", null, "standard", 1024, false, 0);
            Distance(osa, new string('a', 32768), "", null, "large", 32768, false, 0);
            Distance(osa, new string('a', 32769), "", null, "large", null, null, 5);
            Distance(osa, new string('a', 65537), "", null, "large", null, null, 3);
            Distance(osa, new string('a', 4096), new string('b', 4097), null, "large", null, null, 6);
            Distance(osa, "a", "b", Int32.MaxValue, "standard", 1, false, 0);
        }
    }

    private static string Repeat(string value, int count)
    {
        return new StringBuilder(value.Length * count).Insert(0, value, count).ToString();
    }

    private static void Similarity(string left, string right, string profile, double? expected, int expectedError)
    {
        object row = null;
        int count = 0;
        foreach (object item in JaroProvider.Evaluate(Text(left), Text(right), Text(profile))) { row = item; count++; }
        Need(count == 1 && row != null);
        SqlDouble score;
        SqlInt32 error;
        JaroProvider.FillRow(row, out score, out error);
        Need(!error.IsNull && error.Value == expectedError);
        Need(expected.HasValue ? (!score.IsNull && Math.Abs(score.Value - expected.Value) <= 1e-12) : score.IsNull);
    }

    private static void JaroGolden(string left, string right, double expected)
    {
        foreach (string profile in new[] { "standard", "large" })
        {
            Similarity(left, right, profile, expected, 0);
            Similarity(right, left, profile, expected, 0);
        }
        jaroCases++;
    }

    private static void JaroGoldens()
    {
        int start = jaroCases;
        JaroGolden("", "", 1); JaroGolden("A", "", 0); JaroGolden("A", "A", 1);
        JaroGolden("A", "a", 0); JaroGolden("A", "A ", 17.0 / 20); JaroGolden("A", "B", 0);
        JaroGolden("AB", "BA", 0); JaroGolden("ABC", "ACB", 5.0 / 9); JaroGolden("ABCA", "ACBA", 37.0 / 40);
        JaroGolden("ABCDEF", "ABDCEF", 43.0 / 45); JaroGolden("AAAAABBBBB", "AAAAACCCCC", 2.0 / 3);
        JaroGolden(new string('A', 11) + new string('B', 9), new string('A', 11) + new string('C', 9), 7.0 / 10);
        JaroGolden("AAAAAABBBB", "AAAAAACCCC", 21.0 / 25); JaroGolden("ABCDEF", "BDHECFGD", 259.0 / 360);
        JaroGolden("\U0001F600", "\U0001F600", 1); JaroGolden("\U0001F600", "", 0);
        JaroGolden("e\u0301", "\u00E9", 0); JaroGolden("\0", "\0", 1);
        JaroGolden("AABAA", "ABAAB", 161.0 / 200); JaroGolden("ABA", "BAAB", 29.0 / 36);
        Need(jaroCases - start == 20);
    }

    private static void JaroValidation()
    {
        foreach (string culture in new[] { "de-DE", "en-US", "tr-TR" })
        {
            CultureInfo.CurrentCulture = CultureInfo.GetCultureInfo(culture);
            JaroGoldens();
            Similarity(null, "x", "invalid", null, 0);
            Similarity("x", "x", "invalid", null, 1);
            Similarity(new string('x', 2049), "x", "standard", null, 3);
            Similarity("\uD800", "x", "standard", null, 4);
            Similarity("x", "\uDC00", "standard", null, 4);
            Similarity(new string('x', 1025), "x", "standard", null, 5);
            Similarity(new string('x', 5000), new string('x', 5000), "large", null, 6);
        }
    }

    private static void Metadata()
    {
        SqlFunctionAttribute distanceAttribute = (SqlFunctionAttribute)Attribute.GetCustomAttribute(
            typeof(DistanceProvider).GetMethod("Levenshtein"), typeof(SqlFunctionAttribute));
        SqlFunctionAttribute jaroAttribute = (SqlFunctionAttribute)Attribute.GetCustomAttribute(
            typeof(JaroProvider).GetMethod("Evaluate"), typeof(SqlFunctionAttribute));
        Need(distanceAttribute != null && distanceAttribute.IsDeterministic && distanceAttribute.IsPrecise &&
            distanceAttribute.DataAccess == DataAccessKind.None && distanceAttribute.SystemDataAccess == SystemDataAccessKind.None &&
            distanceAttribute.FillRowMethodName == "FillRow" &&
            distanceAttribute.TableDefinition == "Distance int, ExceedsMaxDistance bit, ErrorCode int");
        Need(jaroAttribute != null && jaroAttribute.IsDeterministic && !jaroAttribute.IsPrecise &&
            jaroAttribute.DataAccess == DataAccessKind.None && jaroAttribute.SystemDataAccess == SystemDataAccessKind.None &&
            jaroAttribute.FillRowMethodName == "FillRow" &&
            jaroAttribute.TableDefinition == "Similarity float, ErrorCode int");
    }

    public static int Main(string[] args)
    {
        try
        {
            GoldenFile(args[0]);
            DistanceValidation();
            JaroValidation();
            Metadata();
            Console.WriteLine("PASS;GOLDEN_ROWS=" + goldenRows.ToString(CultureInfo.InvariantCulture) +
                ";JARO_CASES=" + jaroCases.ToString(CultureInfo.InvariantCulture) +
                ";ASSERTIONS=" + assertions.ToString(CultureInfo.InvariantCulture));
            return 0;
        }
        catch
        {
            Console.Error.WriteLine("EDIT_DISTANCE_PACKAGE_FIXTURE_FAILED");
            return 1;
        }
    }
}
