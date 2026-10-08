using System;
using System.Collections;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;

// Privater Consumer der vorhandenen Bridge; baut weder Provider noch SQL-Objekte.
public static class PhoneticDifferentialConsumer
{
    private sealed class Case
    {
        internal int Id;
        internal string Algorithm;
        internal string Text;
    }
    private static void Need(bool value)
    {
        if (!value) throw new InvalidOperationException("PHONETIC_DIFFERENTIAL_INPUT_OR_RESULT");
    }
    private static string Hex(byte[] bytes)
    {
        return BitConverter.ToString(bytes).Replace("-", "");
    }
    private static void Pin(byte[] bytes, string expected)
    {
        Need(expected != null && expected.Length == 64);
        foreach (char ch in expected) Need(ch >= '0' && ch <= '9' || ch >= 'A' && ch <= 'F');
        using (SHA256 hash = SHA256.Create()) Need(Hex(hash.ComputeHash(bytes)) == expected);
    }
    private static byte[] AssemblyBytes(string path, int expectedLength)
    {
        // Adapterlokale Aufnahmegrenze; kein Produktlimit und keine Heapgarantie.
        byte[] buffer = new byte[checked(expectedLength + 1)];
        int count = 0;
        bool eof = false;
        using (FileStream stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read))
        {
            while (count < buffer.Length)
            {
                int read = stream.Read(buffer, count, buffer.Length - count);
                if (read == 0) { eof = true; break; }
                count = checked(count + read);
            }
        }
        Need(eof && count == expectedLength);
        byte[] result = new byte[expectedLength];
        Buffer.BlockCopy(buffer, 0, result, 0, count);
        return result;
    }
    private static byte[] CorpusBytes(string path)
    {
        // Die Transportquote wird bereits beim Einlesen durch einen zusätzlichen EOF-Witness begrenzt.
        byte[] buffer = new byte[32769];
        int count = 0;
        using (FileStream stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read))
        {
            while (count < buffer.Length)
            {
                int read = stream.Read(buffer, count, buffer.Length - count);
                if (read == 0) break;
                count = checked(count + read);
            }
        }
        Need(count > 0 && count <= 32768);
        byte[] result = new byte[count];
        Buffer.BlockCopy(buffer, 0, result, 0, count);
        return result;
    }
    private static List<Case> ReadCorpus(byte[] bytes)
    {
        Need(bytes.Length > 0 && bytes.Length <= 32768);
        foreach (byte b in bytes) Need(b == 9 || b == 10 || b >= 32 && b <= 126);
        string[] lines = Encoding.ASCII.GetString(bytes).Split(new char[] {'\n'}, StringSplitOptions.None);
        Need(lines.Length >= 3 && lines.Length <= 66 && lines[0] == "PHONETIC_CORPUS_V1" && lines[lines.Length - 1] == "");
        List<Case> cases = new List<Case>();
        bool aj = false;
        for (int i = 1; i < lines.Length - 1; i++)
        {
            string[] fields = lines[i].Split(new char[] {'\t'}, StringSplitOptions.None);
            Need(fields.Length == 3 && fields[0] == i.ToString(CultureInfo.InvariantCulture));
            Need(fields[1] == "C" || fields[1] == "D");
            byte[] raw = Convert.FromBase64String(fields[2]);
            Need(Convert.ToBase64String(raw) == fields[2] && raw.Length >= 2 && raw.Length <= 256 && raw.Length % 2 == 0);
            char[] chars = new char[raw.Length / 2];
            bool hasCore = false;
            for (int j = 0; j < chars.Length; j++)
            {
                char ch = (char)(raw[2 * j] | raw[2 * j + 1] << 8);
                bool extra = fields[1] == "C" ? "ÄÖÜäöüß".IndexOf(ch) >= 0 : "ÇçÑñ".IndexOf(ch) >= 0;
                Need(ch <= 127 || extra);
                chars[j] = ch;
                hasCore |= ch > 32;
            }
            Need(fields[1] == "C" || hasCore);
            string text = new string(chars);
            aj |= fields[1] == "D" && text == "AJ";
            cases.Add(new Case { Id = i, Algorithm = fields[1], Text = text });
        }
        Need(cases.Count >= 1 && cases.Count <= 64 && aj);
        return cases;
    }
    private static string Code(SqlString code, out int length)
    {
        Need(!code.IsNull && code.Value.Length <= 16384);
        string value = code.Value;
        foreach (char ch in value) Need(ch <= 127);
        byte[] bytes = Encoding.ASCII.GetBytes(value);
        length = bytes.Length;
        return Convert.ToBase64String(bytes);
    }
    private static object[] Row(Type bridge, Case item)
    {
        string method = item.Algorithm == "C" ? "EvaluateCologne" : "EvaluateDoubleMetaphone";
        MethodInfo evaluate = bridge.GetMethod(method, BindingFlags.Public | BindingFlags.Static, null, new Type[] { typeof(SqlChars) }, null);
        Need(evaluate != null);
        IEnumerable rows = evaluate.Invoke(null, new object[] { new SqlChars(item.Text.ToCharArray()) }) as IEnumerable;
        Need(rows != null && rows.GetType().IsArray);
        IEnumerator iterator = rows.GetEnumerator();
        try
        {
            Need(iterator.MoveNext());
            object row = iterator.Current;
            Need(row != null && !iterator.MoveNext());
            return item.Algorithm == "C" ? new object[] { row, SqlString.Null, SqlInt32.Null } : new object[] { row, SqlString.Null, SqlString.Null, SqlInt32.Null };
        }
        finally
        {
            IDisposable disposable = iterator as IDisposable;
            if (disposable != null) disposable.Dispose();
        }
    }
    public static int Main(string[] args)
    {
        try
        {
            // Beide Snapshots werden einmal aufgenommen und vor fachlichem Konsum gepinnt.
            Need(args.Length == 5);
            int expectedAssemblyLength;
            Need(Int32.TryParse(args[2], NumberStyles.None, CultureInfo.InvariantCulture, out expectedAssemblyLength)
                && expectedAssemblyLength >= 1 && expectedAssemblyLength <= 4194304
                && args[2] == expectedAssemblyLength.ToString(CultureInfo.InvariantCulture));
            byte[] assemblyBytes = AssemblyBytes(args[0], expectedAssemblyLength);
            byte[] corpusBytes = CorpusBytes(args[3]);
            Pin(assemblyBytes, args[1]);
            Pin(corpusBytes, args[4]);
            List<Case> cases = ReadCorpus(corpusBytes);
            Assembly assembly = Assembly.Load(assemblyBytes);
            Need(assembly.GetName().Name == "Toolbelt.String.Phonetic" && assembly.GetName().Version.ToString() == "1.0.0.0");
            Type bridge = assembly.GetType("Toolbelt.String.Phonetic.PhoneticBridge", true);
            StringBuilder output = new StringBuilder("PHONETIC_DIFFERENTIAL_V1\n");
            foreach (Case item in cases)
            {
                object[] row = Row(bridge, item);
                bridge.GetMethod(item.Algorithm == "C" ? "FillCologneRow" : "FillDoubleMetaphoneRow", BindingFlags.Public | BindingFlags.Static).Invoke(null, row);
                SqlInt32 status = (SqlInt32)row[row.Length - 1];
                Need(!status.IsNull && status.Value == 0);
                int primaryLength;
                string primary = Code((SqlString)row[1], out primaryLength);
                int alternateLength = -1;
                string alternate = "-";
                if (item.Algorithm == "D") alternate = Code((SqlString)row[2], out alternateLength);
                Need(item.Algorithm != "D" || checked(primaryLength + alternateLength) <= 32768);
                output.Append(item.Id.ToString(CultureInfo.InvariantCulture)).Append('\t').Append(item.Algorithm).Append("\t0\t")
                    .Append(primaryLength.ToString(CultureInfo.InvariantCulture)).Append('\t').Append(primary).Append('\t')
                    .Append(alternateLength.ToString(CultureInfo.InvariantCulture)).Append('\t').Append(alternate).Append('\n');
            }
            // Kein Trim, keine Cultureänderung und keine Teilmenge vor vollständigem Erfolg.
            byte[] wire = Encoding.ASCII.GetBytes(output.ToString());
            using (Stream stream = Console.OpenStandardOutput()) stream.Write(wire, 0, wire.Length);
            return 0;
        }
        catch
        {
            Console.Error.WriteLine("PHONETIC_DIFFERENTIAL_CONSUMER_FAILED");
            return 1;
        }
    }
}
