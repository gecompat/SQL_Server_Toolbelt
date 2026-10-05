using System;
using System.Collections.Generic;
using System.Text;
using Toolbelt.JsonConstructors;

namespace Toolbelt.JsonCore
{
    public enum JsonValueKind { Null, Boolean, Number, String, Object, Array }

    /// <summary>Spans beziehen sich auf das unveränderte UTF16-Original.</summary>
    public sealed class JsonToken
    {
        public JsonValueKind Kind { get; internal set; }
        public int RawStart { get; internal set; }
        public int RawLength { get; internal set; }
        public int Parent { get; internal set; }
        public int FirstChild { get; internal set; }
        public int NextSibling { get; internal set; }
        public string Key { get; internal set; }
        public string StringValue { get; internal set; }
        public int ScalarLength { get; internal set; }
        internal int LastChild = -1;
        internal int KeyStart = -1;
        internal int KeyLength;
    }

    public sealed class JsonTokenDocument
    {
        private readonly List<JsonToken> tokens = new List<JsonToken>();
        private readonly string source;
        private readonly JsonWorkBudget work;
        private bool decoded;
        public JsonScanResult Syntax { get; internal set; }
        public int Count { get { return tokens.Count; } }

        internal JsonTokenDocument(string source, JsonWorkBudget work)
        {
            this.source = source;
            this.work = work;
        }

        public JsonToken Get(int index)
        {
            work.Spend(1);
            return tokens[index];
        }

        internal JsonToken Peek(int index) { return tokens[index]; }

        internal int Add(JsonValueKind kind, int start, int parent, int keyStart, int keyLength)
        {
            // Listwachstum wird vor der Allokation belastet, ebenso der Token.
            if (tokens.Count == tokens.Capacity)
            {
                int capacity = tokens.Capacity == 0 ? 4 : checked(tokens.Capacity * 2);
                work.Spend(checked((long)capacity + tokens.Count));
                tokens.Capacity = capacity;
            }
            work.Spend(1);
            var token = new JsonToken { Kind = kind, RawStart = start, Parent = parent,
                FirstChild = -1, NextSibling = -1, KeyStart = keyStart, KeyLength = keyLength };
            int id = tokens.Count;
            tokens.Add(token);
            if (parent >= 0)
            {
                work.Spend(1);
                JsonToken owner = tokens[parent];
                if (owner.LastChild < 0) owner.FirstChild = id;
                else tokens[owner.LastChild].NextSibling = id;
                owner.LastChild = id;
            }
            return id;
        }

        public string RawText(int index)
        {
            JsonToken token = Get(index);
            work.Spend(token.RawLength);
            return source.Substring(token.RawStart, token.RawLength);
        }

        /// <summary>
        /// Erst nach vollständiger Syntaxprüfung aufrufen. Raw und escaped
        /// Surrogate werden im selben decodierten Strom gepaart, auch in Keys.
        /// </summary>
        public bool DecodeStrings()
        {
            if (Syntax == null || Syntax.Status != 0) throw new InvalidOperationException("TOKEN_SYNTAX");
            for (int i = 0; i < tokens.Count; i++)
            {
                JsonToken token = Get(i);
                int scalars;
                string decoded;
                if (token.KeyStart >= 0)
                {
                    if (!Decode(token.KeyStart, token.KeyLength, out decoded, out scalars)) return false;
                    token.Key = decoded;
                }
                if (token.Kind == JsonValueKind.String)
                {
                    if (!Decode(token.RawStart, token.RawLength, out decoded, out scalars)) return false;
                    token.StringValue = decoded;
                    token.ScalarLength = scalars;
                }
            }
            decoded = true;
            return true;
        }

        /// <summary>
        /// Vollständige Keyprüfung nach Unicode; Hashes ersetzen nie ordinale
        /// Gleichheit. Jeder Hash und jeder Kollisionsvergleich kostet Arbeit.
        /// </summary>
        public bool CheckDuplicateKeys(out int duplicateToken)
        {
            if (!decoded) throw new InvalidOperationException("TOKEN_UNICODE");
            duplicateToken = -1;
            for (int ownerIndex = 0; ownerIndex < tokens.Count; ownerIndex++)
            {
                JsonToken owner = Get(ownerIndex);
                if (owner.Kind != JsonValueKind.Object) continue;
                int count = 0;
                for (int child = owner.FirstChild; child >= 0; child = tokens[child].NextSibling)
                {
                    work.Spend(1);
                    count++;
                }
                work.Spend(checked((long)count + 2));
                var keys = new Dictionary<string, int>(count, new JsonOrdinalComparer(work));
                for (int child = owner.FirstChild; child >= 0; child = tokens[child].NextSibling)
                {
                    JsonToken member = Get(child);
                    if (keys.ContainsKey(member.Key)) { duplicateToken = child; return false; }
                    keys.Add(member.Key, child);
                }
            }
            return true;
        }

        private bool Decode(int start, int length, out string result, out int scalars)
        {
            int units = length - 2;
            // Originalscan plus begrenzte maximale Buffercapacity vorab prüfen.
            work.Spend(checked(2L * units + 1));
            var buffer = new StringBuilder(units);
            scalars = 0;
            bool pendingHigh = false;
            int end = start + length - 1;
            for (int p = start + 1; p < end; p++)
            {
                char unit = source[p];
                if (unit == '\\')
                {
                    char escape = source[++p];
                    if (escape == 'u')
                    {
                        int value = 0;
                        for (int hex = 0; hex < 4; hex++) value = value * 16 + JsonCanonicalCore.Hex(source[++p]);
                        unit = (char)value;
                    }
                    else
                    {
                        switch (escape)
                        {
                            case 'b': unit = '\b'; break;
                            case 'f': unit = '\f'; break;
                            case 'n': unit = '\n'; break;
                            case 'r': unit = '\r'; break;
                            case 't': unit = '\t'; break;
                            default: unit = escape; break;
                        }
                    }
                }
                if (pendingHigh)
                {
                    if (!Char.IsLowSurrogate(unit)) { result = null; return false; }
                    pendingHigh = false;
                    scalars++;
                }
                else if (Char.IsHighSurrogate(unit)) pendingHigh = true;
                else if (Char.IsLowSurrogate(unit)) { result = null; return false; }
                else scalars++;
                buffer.Append(unit);
            }
            if (pendingHigh) { result = null; return false; }
            work.Spend(buffer.Length);
            result = buffer.ToString();
            return true;
        }
    }
}
