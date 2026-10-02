using System;
using System.Collections;
using System.Data.SqlTypes;
using System.Globalization;
using Microsoft.SqlServer.Server;

namespace Toolbelt.Xlsx.Qualification
{
    /// <summary>Reine Einzelzellinterpretation; keine Workbook- oder Styleauswertung.</summary>
    public static class XlsxCellType
    {
        internal sealed class Result
        {
            internal string Stored, Raw, Text, Resolved, TypedText;
            internal bool? Present;
            internal bool Echo = true;
            internal int Status;
            internal SqlDecimal Number = SqlDecimal.Null;
            internal bool? Boolean;
            internal DateTime? Date, DateTime;
            internal TimeSpan? Time;
            internal long? Duration;
        }
        private sealed class DecimalParts
        {
            internal string Digits;
            internal int Scale;
            internal bool Negative;
            internal SqlDecimal Value;
        }
        private const long DayTicks = 864000000000L;
        private static int Units(string value) { return value == null ? 0 : value.Length; }
        private static Result Discard(int status) { return new Result { Status = status, Echo = false }; }
        private static Result Finish(Result row, int status)
        {
            row.Status = status;
            if (status != 0)
            {
                row.Number = SqlDecimal.Null; row.Boolean = null; row.Date = null;
                row.DateTime = null; row.Time = null; row.Duration = null; row.TypedText = null;
            }
            long charge = 256L + 4L * (Units(row.Stored) + Units(row.Raw) + Units(row.Text)
                + Units(row.Resolved) + Units(row.TypedText));
            return charge > 262144 ? Discard(3) : row;
        }
        private static bool Utf16(string value)
        {
            if (value == null) return true;
            for (int i = 0; i < value.Length; i++)
            {
                if (Char.IsHighSurrogate(value[i]))
                {
                    if (++i == value.Length || !Char.IsLowSurrogate(value[i])) return false;
                }
                else if (Char.IsLowSurrogate(value[i])) return false;
            }
            return true;
        }
        private static bool IsTarget(string value)
        {
            return value == "number" || value == "boolean" || value == "text" || value == "date"
                || value == "datetime" || value == "time" || value == "duration";
        }
        private static string Classify(string value)
        {
            switch (value)
            {
                case "0": case "0.00": case "#,##0.00": case "0%": case "0.00%": case "0.00E+00": return "number";
                case "yyyy-mm-dd": return "date";
                case "yyyy-mm-dd hh:mm:ss": return "datetime";
                case "hh:mm:ss": return "time";
                case "[h]:mm:ss": return "duration";
                case "@": return "text";
                default: return null;
            }
        }
        private static bool Digit(char value) { return value >= '0' && value <= '9'; }
        private static bool NumberForm(string value)
        {
            // Endliche ASCII-Grammatik ohne Regex oder Kulturabhängigkeit.
            int p = 0, digits = 0;
            if (value.Length == 0) return false;
            if (value[p] == '+' || value[p] == '-') p++;
            while (p < value.Length && Digit(value[p])) { p++; digits++; }
            if (p < value.Length && value[p] == '.')
            {
                p++; while (p < value.Length && Digit(value[p])) { p++; digits++; }
            }
            if (digits == 0) return false;
            if (p < value.Length && (value[p] == 'e' || value[p] == 'E'))
            {
                p++; if (p < value.Length && (value[p] == '+' || value[p] == '-')) p++;
                int start = p; while (p < value.Length && Digit(value[p])) p++;
                if (p == start) return false;
            }
            return p == value.Length;
        }
        private static bool IsoForm(string value, bool date)
        {
            if (value == null || (date ? value.Length != 10 : value.Length != 19 && (value.Length < 21 || value.Length > 27))) return false;
            for (int i = 0; i < value.Length; i++)
            {
                if (i == 4 || i == 7) { if (value[i] != '-') return false; }
                else if (i == 10) { if (value[i] != 'T') return false; }
                else if (i == 13 || i == 16) { if (value[i] != ':') return false; }
                else if (i == 19) { if (value[i] != '.') return false; }
                else if (!Digit(value[i])) return false;
            }
            return true;
        }
        internal static Result Evaluate(string stored, bool? present, string raw, string text,
            string target, string format, bool? date1904)
        {
            if (Units(stored) > 32 || Units(target) > 32 || Units(format) > 128
                || Units(raw) > 65536 || Units(text) > 65536) return Discard(3);
            var row = new Result { Stored = stored, Present = present, Raw = raw, Text = text };
            if (!Utf16(stored) || !Utf16(raw) || !Utf16(text) || !Utf16(target) || !Utf16(format)) return Finish(row, 4);
            if (stored == null || !present.HasValue) return Finish(row, 1);
            if (stored == "inlineStr")
            {
                if (present.Value || raw != null) return Finish(row, 2);
                if (text == null) return Finish(row, 1);
            }
            else if (!present.Value) return Finish(row, raw == null && text == null ? 1 : 2);
            int sharedIndex;
            if ((stored == "s" && (raw == null || !Int32.TryParse(raw, NumberStyles.None,
                CultureInfo.InvariantCulture, out sharedIndex))) || (stored == "str" && raw != text)) return Finish(row, 2);
            if (stored != "n" && stored != "b" && stored != "s" && stored != "str"
                && stored != "inlineStr" && stored != "d" && stored != "e") return Finish(row, 6);
            if (target != null && !IsTarget(target)) return Finish(row, 2);
            string classified = format == null ? null : Classify(format);
            if (format != null && classified == null) return Finish(row, 6);
            if (target != null && classified != null && target != classified) return Finish(row, 2);
            row.Resolved = target ?? classified ?? (stored == "n" ? "number" : stored == "b" ? "boolean" : stored == "d" ? "datetime" : "text");
            if (stored == "e") return Finish(row, 10);
            if (row.Resolved == "text")
            {
                row.TypedText = stored == "s" || stored == "str" || stored == "inlineStr" ? text : raw;
                return Finish(row, row.TypedText == null ? 2 : 0);
            }
            if (row.Resolved == "boolean")
            {
                if (stored != "b") return Finish(row, 2);
                if (raw != "0" && raw != "1") return Finish(row, 4);
                row.Boolean = raw == "1"; return Finish(row, 0);
            }
            if (stored == "d")
            {
                if (row.Resolved != "date" && row.Resolved != "datetime") return Finish(row, 2);
                DateTime value;
                if (!IsoForm(raw, row.Resolved == "date")
                    || !System.DateTime.TryParseExact(raw, row.Resolved == "date" ? new[] { "yyyy-MM-dd" }
                    : new[] { "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd'T'HH:mm:ss.FFFFFFF" },
                    CultureInfo.InvariantCulture, DateTimeStyles.None, out value)) return Finish(row, 4);
                if (row.Resolved == "date") row.Date = value; else row.DateTime = value;
                return Finish(row, 0);
            }
            if (stored != "n" || raw == null) return Finish(row, 2);
            if (raw.Length > 128) return Discard(3);
            if ((row.Resolved == "date" || row.Resolved == "datetime") && !date1904.HasValue) return Finish(row, 2);
            DecimalParts number;
            int status = Parse(raw, out number);
            if (status != 0) return Finish(row, status);
            if (row.Resolved == "number") { row.Number = number.Value; return Finish(row, 0); }
            return Finish(row, Temporal(number, row, date1904 ?? false));
        }
        private static int Parse(string raw, out DecimalParts number)
        {
            number = null;
            // Nur der bereits auf 128 Einheiten begrenzte Number-/Serialzweig.
            if (!NumberForm(raw)) return 4;
            bool negative = raw[0] == '-';
            if (raw[0] == '-' || raw[0] == '+') raw = raw.Substring(1);
            int e = raw.IndexOfAny(new[] { 'e', 'E' }), exponent = 0;
            if (e >= 0)
            {
                if (!Int32.TryParse(raw.Substring(e + 1), NumberStyles.AllowLeadingSign, CultureInfo.InvariantCulture,
                    out exponent) || exponent < -64 || exponent > 64) return 5;
                raw = raw.Substring(0, e);
            }
            int dot = raw.IndexOf('.'), scale = (dot < 0 ? 0 : raw.Length - dot - 1) - exponent;
            string digits = raw.Replace(".", "").TrimStart('0');
            if (digits.Length == 0) { number = new DecimalParts { Digits = "0", Value = new SqlDecimal(0) }; return 0; }
            while (scale > 0 && digits.EndsWith("0", StringComparison.Ordinal)) { digits = digits.Substring(0, digits.Length - 1); scale--; }
            if (scale < 0)
            {
                if (digits.Length - scale > 38) return 5;
                digits += new string('0', -scale); scale = 0;
            }
            if (digits.Length > 38 || scale > 38) return 5;
            // SqlDecimal-Konstruktor mit vier 32-Bit-Worten vermeidet Culture-/Decimal-Näherung.
            var words = new uint[4];
            foreach (char digit in digits)
            {
                ulong carry = (uint)(digit - '0');
                for (int i = 0; i < words.Length; i++) { ulong value = words[i] * 10UL + carry; words[i] = (uint)value; carry = value >> 32; }
                if (carry != 0) throw new OverflowException();
            }
            var bits = new int[4]; for (int i = 0; i < 4; i++) bits[i] = unchecked((int)words[i]);
            number = new DecimalParts { Digits = digits, Scale = scale, Negative = negative,
                Value = new SqlDecimal((byte)Math.Max(1, Math.Max(digits.Length, scale)), (byte)scale, !negative, bits) };
            return 0;
        }
        private static string Multiply(string digits)
        {
            long carry = 0; char[] result = new char[digits.Length + 14]; int p = result.Length;
            for (int i = digits.Length - 1; i >= 0; i--)
            {
                long value = (digits[i] - '0') * DayTicks + carry;
                result[--p] = (char)('0' + value % 10); carry = value / 10;
            }
            while (carry > 0) { result[--p] = (char)('0' + carry % 10); carry /= 10; }
            return new string(result, p, result.Length - p);
        }
        private static bool Quantize(string digits, int scale, out long ticks)
        {
            string value = Multiply(digits);
            if (value.Length <= scale) value = new string('0', scale + 1 - value.Length) + value;
            string whole = scale == 0 ? value : value.Substring(0, value.Length - scale);
            if (!Int64.TryParse(whole, NumberStyles.None, CultureInfo.InvariantCulture, out ticks)) return false;
            if (scale > 0 && value[value.Length - scale] >= '5') { if (ticks == Int64.MaxValue) return false; ticks++; }
            return true;
        }
        private static int Temporal(DecimalParts number, Result row, bool date1904)
        {
            if (number.Negative && row.Resolved != "duration") return 8;
            string padded = number.Digits;
            if (padded.Length <= number.Scale) padded = new string('0', number.Scale + 1 - padded.Length) + padded;
            string integer = number.Scale == 0 ? padded : padded.Substring(0, padded.Length - number.Scale);
            string fraction = number.Scale == 0 ? "0" : padded.Substring(padded.Length - number.Scale);
            long whole, ticks;
            if (!Int64.TryParse(integer, NumberStyles.None, CultureInfo.InvariantCulture, out whole)) return 8;
            if (row.Resolved == "duration")
            {
                if (!Quantize(number.Digits, number.Scale, out ticks)) return 8;
                row.Duration = number.Negative ? -ticks : ticks; return 0;
            }
            if (row.Resolved == "time")
            {
                if (whole != 0 || !Quantize(number.Digits, number.Scale, out ticks) || ticks >= DayTicks) return 8;
                row.Time = new TimeSpan(ticks); return 0;
            }
            // Das Originalintervall [60,61) bleibt vor Rundung und date-Präzision gesperrt.
            if (!date1904 && whole == 60) return 7;
            if ((!date1904 && whole < 1) || whole > 3652058) return 8;
            if (row.Resolved == "date" && fraction.Trim('0').Length != 0) return 9;
            if (!Quantize(fraction, number.Scale, out ticks)) return 8;
            long days = date1904 ? whole : whole - (whole > 60 ? 1 : 0);
            long origin = (date1904 ? new DateTime(1904, 1, 1) : new DateTime(1899, 12, 31)).Ticks;
            long absolute = origin + days * DayTicks + ticks;
            if (absolute < 0 || absolute > System.DateTime.MaxValue.Ticks) return 8;
            if (row.Resolved == "date") row.Date = new DateTime(absolute); else row.DateTime = new DateTime(absolute);
            return 0;
        }

        [SqlFunction(FillRowMethodName = "Fill", DataAccess = DataAccessKind.None,
            SystemDataAccess = SystemDataAccessKind.None, IsDeterministic = true, IsPrecise = true,
            TableDefinition = "StoredType nvarchar(32), ValuePresent bit, RawValue nvarchar(max), TextValue nvarchar(max), EchoPreserved bit, ResolvedType nvarchar(16), NumberValue sql_variant, BooleanValue bit, DateValue date, DateTimeValue datetime2(7), TimeValue time(7), DurationTicks bigint, TypedTextValue nvarchar(max), StatusCode int")]
        public static IEnumerable Interpret(SqlChars stored, SqlBoolean present, SqlChars raw, SqlChars text,
            SqlChars target, SqlChars format, SqlBoolean date1904)
        {
            // SqlChars.Length vor Value; keine Kopie übergroßer Callerinputs.
            if (Length(stored) > 32 || Length(target) > 32 || Length(format) > 128
                || Length(raw) > 65536 || Length(text) > 65536) return new[] { Discard(3) };
            return new[] { Evaluate(String(stored), present.IsNull ? (bool?)null : present.Value,
                String(raw), String(text), String(target), String(format), date1904.IsNull ? (bool?)null : date1904.Value) };
        }
        private static long Length(SqlChars value) { return value == null || value.IsNull ? 0 : value.Length; }
        private static string String(SqlChars value) { return value == null || value.IsNull ? null : new string(value.Value); }
        private static SqlString Text(string value) { return value == null ? SqlString.Null : new SqlString(value); }
        public static void Fill(object value, out SqlString stored, out SqlBoolean present, out SqlString raw,
            out SqlString text, out SqlBoolean echo, out SqlString resolved, out object number, out SqlBoolean boolean,
            out DateTime? date, out DateTime? dateTime, out TimeSpan? time, out SqlInt64 duration,
            out SqlString typedText, out SqlInt32 status)
        {
            var row = (Result)value;
            stored = Text(row.Stored); present = row.Present.HasValue ? new SqlBoolean(row.Present.Value) : SqlBoolean.Null;
            raw = Text(row.Raw); text = Text(row.Text); echo = new SqlBoolean(row.Echo); resolved = Text(row.Resolved);
            number = row.Number.IsNull ? null : (object)row.Number;
            boolean = row.Boolean.HasValue ? new SqlBoolean(row.Boolean.Value) : SqlBoolean.Null;
            date = row.Date; dateTime = row.DateTime; time = row.Time;
            duration = row.Duration.HasValue ? new SqlInt64(row.Duration.Value) : SqlInt64.Null;
            typedText = Text(row.TypedText); status = new SqlInt32(row.Status);
        }
    }
}
