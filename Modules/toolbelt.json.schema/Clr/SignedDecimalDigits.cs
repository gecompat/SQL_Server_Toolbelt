using System;
using Toolbelt.JsonCore;

namespace Toolbelt.JsonSchema
{
    /// <summary>Exponent als Vorzeichen und Ziffern, niemals als native Zahl.</summary>
    internal sealed class SignedDecimalDigits
    {
        internal static readonly SignedDecimalDigits Zero = new SignedDecimalDigits(0, String.Empty);
        internal readonly int Sign;
        internal readonly string Digits;
        private SignedDecimalDigits(int sign, string digits) { Sign = sign; Digits = digits; }

        internal static SignedDecimalDigits FromExponent(string text, int start, JsonWorkBudget work)
        {
            if (start == text.Length) return Zero;
            int sign = 1;
            if (text[start] == '+' || text[start] == '-')
            {
                work.Spend(1);
                if (text[start] == '-') sign = -1;
                start++;
            }
            while (start < text.Length && text[start] == '0') { work.Spend(1); start++; }
            if (start == text.Length) return Zero;
            int length = text.Length - start;
            work.Spend(checked(2L * length + 1));
            return new SignedDecimalDigits(sign, text.Substring(start, length));
        }

        internal static SignedDecimalDigits FromSmall(long value, JsonWorkBudget work)
        {
            if (value == 0) return Zero;
            ulong magnitude = value < 0 ? (ulong)(-(value + 1)) + 1UL : (ulong)value;
            ulong remainder = magnitude;
            int length = 0;
            do { work.Spend(1); length++; remainder /= 10; } while (remainder != 0);
            work.Spend(length);
            var buffer = new char[length];
            for (int i = length - 1; i >= 0; i--)
            {
                work.Spend(1);
                buffer[i] = (char)('0' + magnitude % 10);
                magnitude /= 10;
            }
            work.Spend(checked((long)length + 1));
            return new SignedDecimalDigits(value < 0 ? -1 : 1, new String(buffer));
        }

        private static int MagnitudeCompare(string left, string right, JsonWorkBudget work)
        {
            work.Spend(1);
            if (left.Length != right.Length) return left.Length < right.Length ? -1 : 1;
            for (int i = 0; i < left.Length; i++)
            {
                work.Spend(1);
                if (left[i] != right[i]) return left[i] < right[i] ? -1 : 1;
            }
            return 0;
        }

        internal int Compare(SignedDecimalDigits other, JsonWorkBudget work)
        {
            work.Spend(1);
            if (Sign != other.Sign) return Sign < other.Sign ? -1 : 1;
            if (Sign == 0) return 0;
            return Sign * MagnitudeCompare(Digits, other.Digits, work);
        }

        internal SignedDecimalDigits AddSmall(long offset, JsonWorkBudget work)
        {
            work.Spend(1);
            if (offset == 0) return this;
            SignedDecimalDigits other = FromSmall(offset, work);
            if (Sign == 0) return other;
            if (Sign == other.Sign) return AddMagnitude(other, work);
            int comparison = MagnitudeCompare(Digits, other.Digits, work);
            if (comparison == 0) return Zero;
            return comparison > 0 ? SubtractMagnitude(other, work) : other.SubtractMagnitude(this, work);
        }

        private SignedDecimalDigits AddMagnitude(SignedDecimalDigits other, JsonWorkBudget work)
        {
            int length = checked(Math.Max(Digits.Length, other.Digits.Length) + 1);
            work.Spend(length);
            var buffer = new char[length];
            int left = Digits.Length - 1, right = other.Digits.Length - 1, carry = 0;
            for (int p = length - 1; p >= 0; p--)
            {
                work.Spend(1);
                int digit = carry + (left >= 0 ? Digits[left--] - '0' : 0) +
                    (right >= 0 ? other.Digits[right--] - '0' : 0);
                buffer[p] = (char)('0' + digit % 10);
                carry = digit / 10;
            }
            int start = buffer[0] == '0' ? 1 : 0;
            work.Spend(checked((long)length - start + 1));
            return new SignedDecimalDigits(Sign, new String(buffer, start, length - start));
        }

        private SignedDecimalDigits SubtractMagnitude(SignedDecimalDigits other, JsonWorkBudget work)
        {
            work.Spend(Digits.Length);
            var buffer = new char[Digits.Length];
            int right = other.Digits.Length - 1, borrow = 0;
            for (int p = Digits.Length - 1; p >= 0; p--)
            {
                work.Spend(1);
                int digit = Digits[p] - '0' - borrow - (right >= 0 ? other.Digits[right--] - '0' : 0);
                borrow = digit < 0 ? 1 : 0;
                if (digit < 0) digit += 10;
                buffer[p] = (char)('0' + digit);
            }
            if (borrow != 0) throw new InvalidOperationException("EXPONENT_BORROW");
            int start = 0;
            while (start < buffer.Length && buffer[start] == '0') { work.Spend(1); start++; }
            if (start == buffer.Length) return Zero;
            work.Spend(checked((long)buffer.Length - start + 1));
            return new SignedDecimalDigits(Sign, new String(buffer, start, buffer.Length - start));
        }
    }
}
