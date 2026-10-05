using System;
using System.Collections.Generic;

namespace Toolbelt.JsonCore
{
    /// <summary>UTF16-Identität ohne Kultur, Normalisierung oder ignorierte NULs.</summary>
    public sealed class JsonOrdinalComparer : IEqualityComparer<string>, IComparer<string>
    {
        private readonly JsonWorkBudget work;
        public JsonOrdinalComparer(JsonWorkBudget work)
        {
            if (work == null) throw new ArgumentNullException("work");
            this.work = work;
        }

        public int Compare(string left, string right)
        {
            if (left == null || right == null) throw new ArgumentNullException("value");
            int count = Math.Min(left.Length, right.Length);
            for (int i = 0; i < count; i++)
            {
                work.Spend(1);
                if (left[i] != right[i]) return left[i] < right[i] ? -1 : 1;
            }
            return left.Length.CompareTo(right.Length);
        }

        public bool Equals(string left, string right)
        {
            if (left == null || right == null) throw new ArgumentNullException("value");
            return left.Length == right.Length && Compare(left, right) == 0;
        }

        public int GetHashCode(string value)
        {
            if (value == null) throw new ArgumentNullException("value");
            uint hash = 2166136261;
            for (int i = 0; i < value.Length; i++)
            {
                work.Spend(1);
                hash = unchecked((hash ^ value[i]) * 16777619);
            }
            return unchecked((int)hash);
        }
    }
}
