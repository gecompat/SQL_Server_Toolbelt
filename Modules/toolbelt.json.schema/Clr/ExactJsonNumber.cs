using System;
using System.Globalization;
using Toolbelt.JsonCore;

namespace Toolbelt.JsonSchema
{
    /// <summary>
    /// Normalform sign * D * 10^q aus bereits validierter JSON-Numberlexik.
    /// Riesige Exponenten bleiben Ziffern; virtuelle Nullpads werden nicht erzeugt.
    /// </summary>
    public sealed class ExactJsonNumber
    {
        private readonly int sign;
        private readonly string digits;
        private readonly SignedDecimalDigits power;
        private ExactJsonNumber(int sign, string digits, SignedDecimalDigits power)
        {
            this.sign = sign; this.digits = digits; this.power = power;
        }

        public static ExactJsonNumber FromToken(JsonTokenDocument document, int tokenIndex, JsonWorkBudget work)
        {
            if (document.Syntax == null || document.Syntax.Status != 0) throw new InvalidOperationException("NUMBER_SYNTAX");
            if (document.Get(tokenIndex).Kind != JsonValueKind.Number) throw new InvalidOperationException("NUMBER_TOKEN");
            return Normalize(document.RawText(tokenIndex), work);
        }

        public static ExactJsonNumber FromCount(int count, JsonWorkBudget work)
        {
            if (count < 0) throw new ArgumentOutOfRangeException("count");
            // Ein interner int-Count braucht höchstens zehn ASCII-Ziffern.
            work.Spend(10);
            return Normalize(count.ToString(CultureInfo.InvariantCulture), work);
        }

        private static ExactJsonNumber Normalize(string literal, JsonWorkBudget work)
        {
            int sign = literal[0] == '-' ? -1 : 1;
            int begin = sign < 0 ? 1 : 0, end = begin;
            while (end < literal.Length && literal[end] != 'e' && literal[end] != 'E') { work.Spend(1); end++; }
            int capacity = end - begin;
            work.Spend(capacity);
            var coefficient = new char[capacity];
            int count = 0, fraction = 0;
            bool fractional = false;
            for (int i = begin; i < end; i++)
            {
                work.Spend(1);
                char unit = literal[i];
                if (unit == '.') fractional = true;
                else { coefficient[count++] = unit; if (fractional) fraction++; }
            }
            int first = 0, last = count - 1;
            while (first < count && coefficient[first] == '0') { work.Spend(1); first++; }
            if (first == count)
            {
                work.Spend(1);
                return new ExactJsonNumber(0, "0", SignedDecimalDigits.Zero);
            }
            while (last > first && coefficient[last] == '0') { work.Spend(1); last--; }
            int trailing = count - last - 1, length = last - first + 1;
            SignedDecimalDigits exponent = end == literal.Length ? SignedDecimalDigits.Zero :
                SignedDecimalDigits.FromExponent(literal, end + 1, work);
            SignedDecimalDigits power = exponent.AddSmall((long)trailing - fraction, work);
            work.Spend(checked((long)length + 1));
            return new ExactJsonNumber(sign, new String(coefficient, first, length), power);
        }

        public bool IsInteger(JsonWorkBudget work)
        {
            work.Spend(1);
            return sign == 0 || power.Compare(SignedDecimalDigits.Zero, work) >= 0;
        }

        public bool IsNonNegative(JsonWorkBudget work) { work.Spend(1); return sign >= 0; }

        public int Compare(ExactJsonNumber other, JsonWorkBudget work)
        {
            work.Spend(1);
            if (sign != other.sign) return sign < other.sign ? -1 : 1;
            if (sign == 0) return 0;
            SignedDecimalDigits order = power.AddSmall(digits.Length, work);
            SignedDecimalDigits otherOrder = other.power.AddSmall(other.digits.Length, work);
            int comparison = order.Compare(otherOrder, work);
            if (comparison != 0) return sign * comparison;
            int length = Math.Max(digits.Length, other.digits.Length);
            for (int i = 0; i < length; i++)
            {
                work.Spend(1);
                char left = i < digits.Length ? digits[i] : '0';
                char right = i < other.digits.Length ? other.digits[i] : '0';
                if (left != right) return sign * (left < right ? -1 : 1);
            }
            return 0;
        }
    }
}
