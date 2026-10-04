using System;
using System.Data.SqlTypes;
using System.Globalization;
using System.IO;
using Toolbelt.Xlsx.Qualification;

// Offline-Testprogramm; Dateizugriffe gehören ausschließlich zum Harness.
public static class TypeHarness
{
    private static int checks;
    private sealed class PublicRow {
        public int Status; public bool Echo; public string Resolved,Stored,Raw,Text,TypedText;
        public bool? Present,Boolean; public SqlDecimal Number; public DateTime? Date,DateTime;
        public TimeSpan? Time; public long? Duration;
    }
    private static SqlChars C(string s) { return s==null?SqlChars.Null:new SqlChars(s.ToCharArray()); }
    private static SqlBoolean B(bool? b) { return b.HasValue?new SqlBoolean(b.Value):SqlBoolean.Null; }
    private static string S(SqlString s) { return s.IsNull?null:s.Value; }
    private static PublicRow Evaluate(string stored,bool? present,string raw,string text,string target,string format,bool? date1904) {
        var rows=XlsxCellType.Interpret(C(stored),B(present),C(raw),C(text),C(target),C(format),B(date1904)).GetEnumerator();
        try {
            if(!rows.MoveNext()) throw new InvalidOperationException("PUBLIC_ROW_MISSING");
            SqlString st,ra,te,re,tt; SqlBoolean pr,ec,bo; object nu;
            DateTime? da,dt; TimeSpan? ti; SqlInt64 du; SqlInt32 status;
            XlsxCellType.Fill(rows.Current,out st,out pr,out ra,out te,out ec,out re,out nu,out bo,out da,out dt,out ti,out du,out tt,out status);
            if(status.IsNull||ec.IsNull||(nu!=null&&nu.GetType()!=typeof(SqlDecimal))) throw new InvalidOperationException("PUBLIC_SHAPE");
            var result=new PublicRow{Status=status.Value,Echo=ec.Value,Stored=S(st),Raw=S(ra),Text=S(te),Resolved=S(re),TypedText=S(tt),
                Present=pr.IsNull?(bool?)null:pr.Value,Boolean=bo.IsNull?(bool?)null:bo.Value,Number=nu==null?SqlDecimal.Null:(SqlDecimal)nu,
                Date=da,DateTime=dt,Time=ti,Duration=du.IsNull?(long?)null:du.Value};
            if(rows.MoveNext()) throw new InvalidOperationException("PUBLIC_EXTRA_ROW"); return result;
        } finally { var disposable=rows as IDisposable;if(disposable!=null)disposable.Dispose(); }
    }

    private static void Check(bool value) { checks++; if (!value) throw new InvalidOperationException("ASSERT_" + checks); }
    private static string Decode(string value)
    {
        if (value == "~") return null;
        if (value == "!") return String.Empty;
        if (value.StartsWith("!", StringComparison.Ordinal))
        {
            // Verlustfreie synthetische UTF-16-Lauflänge statt mehrmegabytegroßer Goldendatei.
            var result = new System.Text.StringBuilder();
            foreach (string run in value.Substring(1).Split(','))
            {
                string[] fields = run.Split(':');
                result.Append((char)Int32.Parse(fields[0], NumberStyles.HexNumber, CultureInfo.InvariantCulture),
                    Int32.Parse(fields[1], CultureInfo.InvariantCulture));
            }
            return result.ToString();
        }
        byte[] bytes = Convert.FromBase64String(value); char[] units = new char[bytes.Length / 2];
        for (int i = 0; i < units.Length; i++) units[i] = (char)(bytes[i * 2] | bytes[i * 2 + 1] << 8);
        return new string(units);
    }
    private static string Value(PublicRow row)
    {
        if (row.Status != 0) return null;
        switch (row.Resolved)
        {
            case "text": return row.TypedText;
            case "boolean": return row.Boolean.Value ? "1" : "0";
            case "number": return row.Number.ToString();
            case "date": return row.Date.Value.Ticks.ToString(CultureInfo.InvariantCulture);
            case "datetime": return row.DateTime.Value.Ticks.ToString(CultureInfo.InvariantCulture);
            case "time": return row.Time.Value.Ticks.ToString(CultureInfo.InvariantCulture);
            default: return row.Duration.Value.ToString(CultureInfo.InvariantCulture);
        }
    }
    public static int Main(string[] args)
    {
        try
        {
            System.Threading.Thread.CurrentThread.CurrentCulture = new CultureInfo(args[2]);
            int api = 0, numeric = 0;
            foreach (string line in File.ReadLines(args[0]))
            {
                string[] p = line.Split('\t');
                var row = Evaluate(Decode(p[0]), p[1] == "~" ? (bool?)null : p[1] == "1",
                    Decode(p[2]), Decode(p[3]), Decode(p[4]), Decode(p[5]), p[6] == "~" ? (bool?)null : p[6] == "1");
                Check(row.Status == Int32.Parse(p[7], CultureInfo.InvariantCulture));
                Check(row.Echo == (p[8] == "1")); Check(row.Resolved == Decode(p[9])); Check(Value(row) == Decode(p[10]));
                Check(row.Stored == (row.Echo ? Decode(p[0]) : null)); Check(row.Raw == (row.Echo ? Decode(p[2]) : null));
                Check(row.Text == (row.Echo ? Decode(p[3]) : null));
                Check(row.Present == (row.Echo && p[1] != "~" ? (bool?)(p[1] == "1") : null));
                if (row.Status != 0) Check(row.Number.IsNull && !row.Boolean.HasValue && !row.Date.HasValue
                    && !row.DateTime.HasValue && !row.Time.HasValue && !row.Duration.HasValue && row.TypedText == null);
                api++;
            }
            foreach (string line in File.ReadLines(args[1]))
            {
                string[] p = line.Split('|');
                var row = Evaluate("n", true, p[0], null, p[1], null, p[2] == "1");
                Check(row.Status == Int32.Parse(p[3], CultureInfo.InvariantCulture)); Check(Value(row) == (p[4].Length == 0 ? null : p[4])); numeric++;
            }
            var exact = Evaluate("n", true, "0.00000000000000000000000000000000000001", null, null, null, null);
            Check(exact.Number.Precision == 38 && exact.Number.Scale == 38 && exact.Number.Data[0] == 1 && exact.Number.Data[1] == 0 && exact.Number.Data[2] == 0 && exact.Number.Data[3] == 0);
            foreach (string prefix in new[] { "", "-" })
            {
                var max = Evaluate("n", true, prefix + new string('9', 38), null, null, null, null);
                Check(max.Status == 0 && max.Number.Precision == 38 && max.Number.Scale == 0 && max.Number.IsPositive == (prefix.Length == 0));
            }
            foreach (var raw in new[] { "0", "-0", "+000.000", "0e-38" })
            {
                var zero = Evaluate("n", true, raw, null, null, null, null);
                Check(zero.Status == 0 && zero.Number.Precision == 1 && zero.Number.Scale == 0 && zero.Number.IsPositive);
            }
            Console.WriteLine("PASS API=" + api + " NUMERIC=" + numeric + " ASSERTIONS=" + checks); return 0;
        }
        catch (Exception exception) { Console.WriteLine("FAIL " + exception.GetType().Name + " ASSERTIONS=" + checks); return 1; }
    }
}
