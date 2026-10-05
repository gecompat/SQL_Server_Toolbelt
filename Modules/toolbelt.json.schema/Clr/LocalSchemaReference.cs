using System;
using System.Text;
using Toolbelt.JsonCore;

namespace Toolbelt.JsonSchema
{
    /// <summary>Einmalige RFC3986-Fragment- und danach RFC6901-Tokendecodierung.</summary>
    internal static class LocalSchemaReference
    {
        internal static int Resolve(SchemaTree tree, int reference)
        {
            string uri = tree.Document.Get(reference).StringValue;
            if (uri.Length == 0 || uri[0] != '#') tree.Fail("UNSUPPORTED", "EXTERNAL_REF", reference, "$ref");
            tree.Work.Spend(checked(3L * uri.Length + 2));
            var bytes = new byte[uri.Length - 1];
            int count = 0;
            for (int i = 1; i < uri.Length; i++)
            {
                char unit = uri[i];
                if (unit == '%')
                {
                    if (i + 2 >= uri.Length) tree.Fail("INVALID_SCHEMA", "REF_SYNTAX", reference, "$ref");
                    int high = Hex(uri[++i]), low = Hex(uri[++i]);
                    if (high < 0 || low < 0) tree.Fail("INVALID_SCHEMA", "REF_SYNTAX", reference, "$ref");
                    bytes[count++] = (byte)(high * 16 + low);
                }
                else
                {
                    if (!Allowed(unit)) tree.Fail("INVALID_SCHEMA", "REF_SYNTAX", reference, "$ref");
                    bytes[count++] = (byte)unit;
                }
            }
            string pointer;
            try { pointer = new UTF8Encoding(false, true).GetString(bytes, 0, count); }
            catch (DecoderFallbackException) { tree.Fail("INVALID_SCHEMA", "REF_SYNTAX", reference, "$ref"); return -1; }
            if (pointer.Length == 0) return 0;
            if (pointer[0] != '/') tree.Fail("INVALID_SCHEMA", "REF_SYNTAX", reference, "$ref");
            int current = 0;
            for (int start = 1; start <= pointer.Length;)
            {
                int end = start;
                while (end < pointer.Length && pointer[end] != '/') { tree.Work.Spend(1); end++; }
                tree.Work.Spend(checked(2L * (end - start) + 1));
                var segment = new StringBuilder(end - start);
                for (int i = start; i < end; i++)
                {
                    char unit = pointer[i];
                    if (unit == '~')
                    {
                        if (++i == end || (pointer[i] != '0' && pointer[i] != '1'))
                            tree.Fail("INVALID_SCHEMA", "REF_SYNTAX", reference, "$ref");
                        unit = pointer[i] == '0' ? '~' : '/';
                    }
                    segment.Append(unit);
                }
                string key = segment.ToString();
                // Lexik auch bei einem bereits fehlenden Ziel vollständig prüfen.
                if (current >= 0)
                {
                    JsonToken owner = tree.Document.Get(current);
                    if (owner.Kind == JsonValueKind.Object) current = tree.Member(current, key);
                    else if (owner.Kind == JsonValueKind.Array)
                    {
                        int index = 0;
                        bool valid = key.Length > 0 && (key.Length == 1 || key[0] != '0');
                        foreach (char unit in key)
                        {
                            tree.Work.Spend(1);
                            if (unit < '0' || unit > '9' || index > (Int32.MaxValue - (unit - '0')) / 10) { valid = false; break; }
                            index = index * 10 + unit - '0';
                        }
                        current = valid ? owner.FirstChild : -1;
                        while (current >= 0 && index-- > 0) current = tree.Document.Get(current).NextSibling;
                    }
                    else current = -1;
                }
                if (end == pointer.Length) break;
                start = end + 1;
            }
            return current;
        }

        private static int Hex(char unit)
        {
            if (unit >= '0' && unit <= '9') return unit - '0';
            if (unit >= 'A' && unit <= 'F') return unit - 'A' + 10;
            return unit >= 'a' && unit <= 'f' ? unit - 'a' + 10 : -1;
        }

        private static bool Allowed(char unit)
        {
            return (unit >= 'A' && unit <= 'Z') || (unit >= 'a' && unit <= 'z') ||
                (unit >= '0' && unit <= '9') || "-._~!$&'()*+,;=:@/?".IndexOf(unit) >= 0;
        }
    }
}
