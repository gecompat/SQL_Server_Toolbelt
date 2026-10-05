using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;
using Toolbelt.JsonCore;

namespace Toolbelt.JsonSchema
{
    internal sealed class SchemaFailure : Exception
    {
        internal readonly string Status, Code, Path, Keyword;
        internal SchemaFailure(string status, string code, string path, string keyword)
            : base(code) { Status = status; Code = code; Path = path; Keyword = keyword; }
    }

    /// <summary>Unveränderte Tokenorte mit budgetierten, ordinalen Memberindizes.</summary>
    internal sealed class SchemaTree
    {
        internal readonly JsonTokenDocument Document;
        internal readonly JsonWorkBudget Work;
        internal readonly JsonOrdinalComparer Ordinal;
        private readonly Dictionary<int, Dictionary<string, int>> members;
        private readonly Dictionary<int, string> paths;

        internal SchemaTree(JsonTokenDocument document, JsonWorkBudget work)
        {
            Document = document; Work = work;
            work.Spend(checked(2L * document.Count + 3));
            Ordinal = new JsonOrdinalComparer(work);
            members = new Dictionary<int, Dictionary<string, int>>(document.Count);
            paths = new Dictionary<int, string>(document.Count);
            paths.Add(0, "");
        }

        internal List<int> Children(int id, bool sorted)
        {
            JsonToken owner = Document.Get(id);
            int count = 0;
            for (int child = owner.FirstChild; child >= 0; child = Document.Get(child).NextSibling) count++;
            Work.Spend((long)count + 1);
            var result = new List<int>(count);
            for (int child = owner.FirstChild; child >= 0; child = Document.Get(child).NextSibling) result.Add(child);
            // Keine Array.Sort-Exception-Hülle: Budgetabbrüche behalten ihren Typ.
            if (sorted && count > 1)
            {
                Work.Spend(count);
                var scratch = new int[count];
                for (long width = 1; width < count; width *= 2)
                    for (long start = 0; start < count; start += 2 * width)
                    {
                        int left = (int)start, middle = (int)Math.Min(start + width, count);
                        int right = middle, end = (int)Math.Min(start + 2 * width, count);
                        for (int dest = (int)start; dest < end; dest++)
                        {
                            Work.Spend(1);
                            bool takeLeft = right >= end || (left < middle &&
                                Ordinal.Compare(Document.Get(result[left]).Key, Document.Get(result[right]).Key) <= 0);
                            scratch[dest] = takeLeft ? result[left++] : result[right++];
                        }
                        for (int dest = (int)start; dest < end; dest++) { Work.Spend(1); result[dest] = scratch[dest]; }
                    }
            }
            return result;
        }

        internal int Member(int id, string key)
        {
            Work.Spend(1);
            Dictionary<string, int> map;
            if (!members.TryGetValue(id, out map))
            {
                if (Document.Get(id).Kind != JsonValueKind.Object) return -1;
                List<int> children = Children(id, false);
                Work.Spend((long)children.Count + 1);
                map = new Dictionary<string, int>(children.Count, Ordinal);
                foreach (int child in children) map.Add(Document.Get(child).Key, child);
                members.Add(id, map);
            }
            int result;
            return map.TryGetValue(key, out result) ? result : -1;
        }

        internal string Path(int id)
        {
            Work.Spend(1);
            string cached;
            if (paths.TryGetValue(id, out cached)) return cached;
            // Die physische JSON-Tiefe ist begrenzt; Referenzen werden hier nicht verfolgt.
            Work.Spend(129);
            var chain = new int[129];
            int count = 0, current = id;
            while (!paths.TryGetValue(current, out cached))
            {
                Work.Spend(1);
                if (count == chain.Length) throw new InvalidOperationException("TOKEN_DEPTH");
                chain[count++] = current;
                current = Document.Get(current).Parent;
            }
            while (count > 0)
            {
                int child = chain[--count];
                JsonToken token = Document.Get(child), parent = Document.Get(token.Parent);
                string segment;
                if (parent.Kind == JsonValueKind.Object) segment = Escape(token.Key, Work);
                else
                {
                    int index = 0, sibling = parent.FirstChild;
                    while (sibling != child) { sibling = Document.Get(sibling).NextSibling; index++; }
                    Work.Spend(10);
                    segment = index.ToString(CultureInfo.InvariantCulture);
                }
                Work.Spend(checked((long)cached.Length + segment.Length + 2));
                cached = cached + "/" + segment;
                paths.Add(child, cached);
            }
            return cached;
        }

        internal static string Escape(string key, JsonWorkBudget work)
        {
            work.Spend(checked(2L * key.Length + 1));
            var buffer = new StringBuilder(checked(2 * key.Length));
            foreach (char unit in key)
            {
                if (unit == '~') buffer.Append("~0");
                else if (unit == '/') buffer.Append("~1");
                else buffer.Append(unit);
            }
            work.Spend(buffer.Length);
            return buffer.ToString();
        }

        internal void Fail(string status, string code, int id, string keyword)
        {
            throw new SchemaFailure(status, code, Path(id), keyword != null && keyword.Length <= 128 ? keyword : null);
        }
    }
}
