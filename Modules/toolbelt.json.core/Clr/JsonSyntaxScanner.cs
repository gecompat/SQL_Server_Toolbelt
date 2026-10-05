using System;
using Toolbelt.JsonConstructors;

namespace Toolbelt.JsonCore
{
    /// <summary>
    /// Ein gemeinsamer Frameautomat für Legacy/AGF und indexierte Schemaeingaben.
    /// Optionaler Index und Arbeitszähler verändern die Constructorpolicy nicht.
    /// </summary>
    internal sealed class JsonSyntaxScanner
    {
        private readonly string text;
        private readonly JsonPolicy policy;
        private readonly JsonWorkBudget work;
        private readonly JsonTokenDocument document;
        private readonly int maximumDepth;
        private readonly JsonScanResult result = new JsonScanResult();
        private int position, depth;
        private int[] frames, nodes, keyStarts, keyLengths;

        internal JsonSyntaxScanner(string text, JsonPolicy policy, JsonWorkBudget work,
            JsonTokenDocument document, int maximumDepth)
        {
            this.text = text;
            this.policy = policy;
            this.work = work;
            this.document = document;
            this.maximumDepth = maximumDepth;
        }

        private void Advance()
        {
            if (work != null) work.Spend(1);
            position++;
        }

        private void Spaces() { JsonCanonicalCore.Spaces(text, ref position, work); }

        internal JsonScanResult Run()
        {
            Spaces();
            if (position == text.Length || (document == null && text[position] != '[' && text[position] != '{'))
                return Syntax(position);
            int capacity = document != null ? Math.Min(maximumDepth, text.Length) :
                policy == JsonPolicy.AgfJson ? 127 : checked(text.Length + 1);
            if (work != null) work.Spend(checked(4L * capacity + 1));
            frames = new int[capacity];
            if (document != null)
            {
                nodes = new int[capacity];
                keyStarts = new int[capacity];
                keyLengths = new int[capacity];
            }
            if (!Value(-1, -1, 0)) return result;
            while (depth > 0)
            {
                Spaces();
                if (position == text.Length) return Syntax(position);
                int slot = depth - 1, state = frames[slot];
                char unit = text[position];
                if (state == 0 || state == 1)
                {
                    if (state == 0 && unit == ']') { Close(slot); continue; }
                    frames[slot] = 2;
                    if (!Value(document == null ? -1 : nodes[slot], -1, 0)) return result;
                }
                else if (state == 2)
                {
                    if (unit == ']') Close(slot);
                    else if (unit == ',') { Advance(); frames[slot] = 1; }
                    else return Syntax(position);
                }
                else if (state == 3 || state == 4)
                {
                    if (state == 3 && unit == '}') { Close(slot); continue; }
                    int start = position, fault;
                    if (!JsonCanonicalCore.JsonString(text, ref position, out fault, work)) return Syntax(fault);
                    if (document != null) { keyStarts[slot] = start; keyLengths[slot] = position - start; }
                    frames[slot] = 5;
                }
                else if (state == 5)
                {
                    if (unit != ':') return Syntax(position);
                    Advance(); frames[slot] = 6;
                }
                else if (state == 6)
                {
                    frames[slot] = 7;
                    if (!Value(document == null ? -1 : nodes[slot], document == null ? -1 : keyStarts[slot],
                        document == null ? 0 : keyLengths[slot])) return result;
                }
                else if (state == 7)
                {
                    if (unit == '}') Close(slot);
                    else if (unit == ',') { Advance(); frames[slot] = 4; }
                    else return Syntax(position);
                }
                else throw new InvalidOperationException("FRAME");
            }
            Spaces();
            if (position != text.Length) return Syntax(position);
            result.ValidDepth = result.MaxOpenDepthObserved;
            return result;
        }

        private void Close(int slot)
        {
            Advance();
            if (document != null)
            {
                JsonToken token = document.Peek(nodes[slot]);
                token.RawLength = position - token.RawStart;
            }
            depth--;
        }

        private JsonScanResult Syntax(int fault)
        {
            if (result.Status == 0) result.Status = 1;
            if (result.FirstFaultOffset < 0) result.FirstFaultOffset = fault;
            return result;
        }

        private bool Value(int parent, int keyStart, int keyLength)
        {
            if (position == text.Length) { Syntax(position); return false; }
            int start = position, fault = position;
            char unit = text[position];
            JsonValueKind kind;
            if (unit == '[' || unit == '{')
            {
                result.MaxOpenDepthObserved = Math.Max(result.MaxOpenDepthObserved, depth + 1);
                if ((document != null && depth == maximumDepth) || (document == null && policy == JsonPolicy.AgfJson && depth == 127))
                {
                    result.Status = 2; result.FirstFaultOffset = position; return false;
                }
                kind = unit == '[' ? JsonValueKind.Array : JsonValueKind.Object;
                frames[depth] = unit == '[' ? 0 : 3;
                if (document != null) nodes[depth] = document.Add(kind, start, parent, keyStart, keyLength);
                depth++;
                result.MaxStoredFrames = Math.Max(result.MaxStoredFrames, depth);
                Advance();
                return true;
            }
            bool valid;
            if (unit == '"') { kind = JsonValueKind.String; valid = JsonCanonicalCore.JsonString(text, ref position, out fault, work); }
            else if (unit == 't') { kind = JsonValueKind.Boolean; valid = JsonCanonicalCore.Atom(text, ref position, "true", out fault, work); }
            else if (unit == 'f') { kind = JsonValueKind.Boolean; valid = JsonCanonicalCore.Atom(text, ref position, "false", out fault, work); }
            else if (unit == 'n') { kind = JsonValueKind.Null; valid = JsonCanonicalCore.Atom(text, ref position, "null", out fault, work); }
            else if (unit == '-' || JsonCanonicalCore.Digit(unit))
            {
                kind = JsonValueKind.Number;
                valid = JsonCanonicalCore.ReadNumber(text, ref position, work) == 0;
                fault = position;
            }
            else { kind = JsonValueKind.Null; valid = false; }
            if (!valid) { Syntax(fault); return false; }
            if (document != null)
            {
                int id = document.Add(kind, start, parent, keyStart, keyLength);
                document.Peek(id).RawLength = position - start;
            }
            return true;
        }
    }
}
