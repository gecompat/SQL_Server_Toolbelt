using System;
using System.Data.SqlTypes;
using System.Globalization;
using System.Text;

namespace Toolbelt.Xlsx.Qualification
{
    // Privater Kandidat: endlicher Renderer auf unverändertem Typkern.
    internal static class XlsxCellDisplay
    {
        internal sealed class Result { internal string Display; internal int Status; }
        private static Result Error(int status) { return new Result { Status = status }; }
        private static int Units(string text) { return text == null ? 0 : text.Length; }
        private static bool Utf16(string text)
        {
            if (text == null) return true;
            for (int i = 0; i < text.Length; i++)
            {
                if (Char.IsHighSurrogate(text[i]))
                { if (++i >= text.Length || !Char.IsLowSurrogate(text[i])) return false; }
                else if (Char.IsLowSurrogate(text[i])) return false;
            }
            return true;
        }
        internal static Result Evaluate(string stored, bool? present, string raw, string text,
            string target, string format, bool? date1904, string culture)
        {
            // Alle allgemeinen Längen vor jeglicher UTF16-/Zweigprüfung.
            if (Units(stored) > 32 || Units(target) > 32 || Units(format) > 128
                || Units(raw) > 65536 || Units(text) > 65536 || Units(culture) > 32) return Error(3);
            if (!Utf16(stored) || !Utf16(raw) || !Utf16(text) || !Utf16(target)
                || !Utf16(format) || !Utf16(culture)) return Error(4);
            var typed = XlsxCellType.Evaluate(stored, present, raw, text, target, format, date1904);
            if (typed.Status != 0) return Error(typed.Status);
            if (culture != "en-US" && culture != "de-DE" && culture != "tr-TR") return Error(2);
            if (format == null) return Error(2);
            string display;
            switch (format)
            {
                case "0": case "0.00": case "#,##0.00": case "0%": case "0.00%": case "0.00E+00":
                    if (typed.Number.IsNull) return Error(11);
                    display = Number(typed.Number, format, culture); break;
                case "@":
                    if (typed.TypedText == null) return Error(11);
                    display = typed.TypedText; break;
                case "yyyy-mm-dd":
                    if (!typed.Date.HasValue) return Error(11);
                    display = typed.Date.Value.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture); break;
                case "yyyy-mm-dd hh:mm:ss":
                    if (!typed.DateTime.HasValue) return Error(11);
                    long dtTicks;
                    if (!RoundSeconds(typed.DateTime.Value.Ticks, DateTime.MaxValue.Ticks, out dtTicks)) return Error(8);
                    display = new DateTime(dtTicks).ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture); break;
                case "hh:mm:ss":
                    if (!typed.Time.HasValue) return Error(11);
                    long timeTicks;
                    if (!RoundSeconds(typed.Time.Value.Ticks, TimeSpan.TicksPerDay - 1, out timeTicks)) return Error(8);
                    var time = new TimeSpan(timeTicks);
                    display = time.Hours.ToString("D2", CultureInfo.InvariantCulture) + ":"
                        + time.Minutes.ToString("D2", CultureInfo.InvariantCulture) + ":"
                        + time.Seconds.ToString("D2", CultureInfo.InvariantCulture); break;
                default: return Error(6);
            }
            if (256L + 4L * display.Length > 262144) return Error(3);
            return new Result { Display = display, Status = 0 };
        }
        private static bool RoundSeconds(long ticks, long maximum, out long rounded)
        {
            long seconds = ticks / TimeSpan.TicksPerSecond;
            if (ticks % TimeSpan.TicksPerSecond >= TimeSpan.TicksPerSecond / 2) seconds++;
            if (seconds > maximum / TimeSpan.TicksPerSecond) { rounded = 0; return false; }
            rounded = seconds * TimeSpan.TicksPerSecond; return true;
        }
        internal static string Coefficient(SqlDecimal value)
        {
            // Vier 32-Bit-Worte dezimal teilen; kein System.Decimal oder Double.
            int[] data = value.Data;
            var words = new uint[4];
            for (int i = 0; i < 4; i++) words[i] = unchecked((uint)data[i]);
            var digits = new char[39]; int p = digits.Length;
            do
            {
                ulong remainder = 0;
                for (int i = 3; i >= 0; i--)
                {
                    ulong part = (remainder << 32) | words[i];
                    words[i] = (uint)(part / 10); remainder = part % 10;
                }
                digits[--p] = (char)('0' + remainder);
            } while (words[0] != 0 || words[1] != 0 || words[2] != 0 || words[3] != 0);
            return new string(digits, p, digits.Length - p);
        }
        private static string Increment(string value)
        {
            char[] chars = value.ToCharArray();
            for (int i = chars.Length - 1; i >= 0; i--)
            {
                if (chars[i] != '9') { chars[i]++; return new string(chars); }
                chars[i] = '0';
            }
            return "1" + new string(chars);
        }
        private static string Quantize(string digits, int discard)
        {
            if (discard <= 0) return digits + new string('0', -discard);
            if (discard > digits.Length) return "0";
            int keep = digits.Length - discard;
            string whole = keep == 0 ? "0" : digits.Substring(0, keep);
            return digits[keep] >= '5' ? Increment(whole) : whole;
        }
        internal static string Number(SqlDecimal value, string format, string culture)
        {
            string digits = Coefficient(value);
            string point = culture == "en-US" ? "." : ",";
            string group = culture == "en-US" ? "," : ".";
            if (format == "0.00E+00")
            {
                int exponent = digits == "0" ? 0 : digits.Length - value.Scale - 1;
                string significant = Quantize(digits, digits.Length - 3);
                if (significant.Length > 3) { significant = "100"; exponent++; }
                string sign = !value.IsPositive && digits != "0" ? "-" : "";
                return sign + significant[0] + point + significant.Substring(1)
                    + "E" + (exponent < 0 ? "-" : "+")
                    + Math.Abs(exponent).ToString("D2", CultureInfo.InvariantCulture);
            }
            bool percent = format == "0%" || format == "0.00%";
            int decimals = format == "0" || format == "0%" ? 0 : 2;
            string units = Quantize(digits, value.Scale - (percent ? 2 : 0) - decimals);
            bool zero = units.Trim('0').Length == 0;
            if (units.Length <= decimals) units = new string('0', decimals + 1 - units.Length) + units;
            string whole = decimals == 0 ? units : units.Substring(0, units.Length - decimals);
            whole = whole.TrimStart('0');
            if (whole.Length == 0) whole = "0";
            if (format == "#,##0.00")
            {
                var grouped = new StringBuilder();
                for (int i = 0; i < whole.Length; i++)
                { if (i > 0 && (whole.Length - i) % 3 == 0) grouped.Append(group); grouped.Append(whole[i]); }
                whole = grouped.ToString();
            }
            return (!value.IsPositive && !zero ? "-" : "") + whole
                + (decimals == 0 ? "" : point + units.Substring(units.Length - decimals))
                + (percent ? "%" : "");
        }
    }
}
