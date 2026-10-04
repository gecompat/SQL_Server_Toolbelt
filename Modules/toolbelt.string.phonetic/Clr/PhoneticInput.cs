using System;
using System.Data.SqlTypes;
using System.Text;

namespace Toolbelt.String.Phonetic
{
    internal sealed class PhoneticQuotaException : Exception
    {
        internal PhoneticQuotaException() : base("PHONETIC_QUOTA") { }
    }

    internal static class PhoneticInput
    {
        internal const int MaximumInput = 4096;
        internal const int MaximumTransformed = 8192;
        internal const int MaximumCode = 16384;
        internal const int MaximumCodePair = 32768;

        // Die rohe Quote wird vor jeder Textkopie geprüft. UTF16 gewinnt nach
        // dieser Quote stets vor Alphabetfehlern, unabhängig von deren Position.
        internal static int Prepare(SqlChars text, bool cologne, out string prepared)
        {
            prepared = null;
            if (text.IsNull) return 0;
            long length = text.Length;
            if (length > MaximumInput) return 2;
            if (length < 0) throw new InvalidOperationException("PHONETIC_INPUT_LENGTH");
            char[] raw = new char[(int)length];
            long read = 0;
            while (read < length)
            {
                long count = text.Read(read, raw, checked((int)read), checked((int)(length - read)));
                if (count <= 0 || count > length - read) throw new InvalidOperationException("PHONETIC_INPUT_READ");
                read = checked(read + count);
            }
            for (int i = 0; i < raw.Length; i++)
            {
                if (char.IsHighSurrogate(raw[i]))
                {
                    if (i + 1 >= raw.Length || !char.IsLowSurrogate(raw[i + 1])) return 1;
                    i++;
                }
                else if (char.IsLowSurrogate(raw[i])) return 1;
            }
            foreach (char value in raw)
            {
                bool allowed = value <= '\u007F' || (cologne
                    ? value == 'Ä' || value == 'Ö' || value == 'Ü' || value == 'ä' || value == 'ö' || value == 'ü' || value == 'ß'
                    : value == 'Ç' || value == 'ç' || value == 'Ñ' || value == 'ñ');
                if (!allowed) return 3;
            }
            int start = 0, end = raw.Length;
            if (!cologne)
            {
                while (start < end && raw[start] <= '\u0020') start++;
                while (end > start && raw[end - 1] <= '\u0020') end--;
            }
            StringBuilder result = new StringBuilder();
            for (int i = start; i < end; i++)
            {
                char value = raw[i];
                if (cologne && value == 'ß') { Append(result, 'S'); Append(result, 'S'); continue; }
                if (value >= 'a' && value <= 'z') value = (char)(value - ('a' - 'A'));
                else if (cologne)
                {
                    if (value == 'Ä' || value == 'ä') value = 'A';
                    else if (value == 'Ö' || value == 'ö') value = 'O';
                    else if (value == 'Ü' || value == 'ü') value = 'U';
                }
                else
                {
                    if (value == 'ç') value = 'Ç';
                    else if (value == 'ñ') value = 'Ñ';
                }
                Append(result, value);
            }
            prepared = result.ToString();
            return 0;
        }

        private static void Append(StringBuilder result, char value)
        {
            if (checked(result.Length + 1) > MaximumTransformed) throw new PhoneticQuotaException();
            result.Append(value);
        }

        internal static void ValidateCode(string code)
        {
            if (code == null || code.Length > MaximumCode) throw new InvalidOperationException("PHONETIC_CODE_SHAPE");
            foreach (char value in code)
                if (value > '\u007F') throw new InvalidOperationException("PHONETIC_CODE_ALPHABET");
        }
    }
}
