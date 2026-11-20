using System;
using System.Data.SqlTypes;
using System.Text;
using System.Text.RegularExpressions;

namespace Toolbelt.Tsql.SsisDebug
{
    internal static class XmlInput
    {
        internal static byte[] Read(SqlBytes bytes, SqlString xml, Toolbelt.Ssis.Exchange.ResourceLimits limits)
        {
            if (!bytes.IsNull && !xml.IsNull) throw new DebugFault("invalid_template", "Genau PackageXml oder PackageBytes übergeben, nicht beide.");
            if (xml.IsNull)
            {
                if (bytes.IsNull) throw new DebugFault("unresolved_binding", "DTSX über PackageXml oder PackageBytes erforderlich.");
                limits.Check("packageBytes", bytes.Length); return bytes.Value;
            }
            string text = xml.Value;
            // NVARCHAR besteht bereits aus Unicodezeichen. Nur die XML-
            // Kodierungsdeklaration an die erzeugten UTF8-Bytes anpassen;
            // kein Zugriff auf Resolver und keine Änderung der Paketwerte.
            int start = text.Length > 0 && text[0] == '\uFEFF' ? 1 : 0;
            if (text.Length > start + 5 && String.CompareOrdinal(text, start, "<?xml", 0, 5) == 0 &&
                (text[start + 5] == ' ' || text[start + 5] == '\t' || text[start + 5] == '\r' || text[start + 5] == '\n'))
            {
                int end = text.IndexOf("?>", start, StringComparison.Ordinal);
                if (end >= 0)
                {
                    string declaration = text.Substring(start, end + 2 - start);
                    string normalized = Regex.Replace(declaration, "encoding\\s*=\\s*([\"'])([^\"']*)\\1", "encoding=\"utf-8\"");
                    text = text.Substring(0, start) + normalized + text.Substring(end + 2);
                }
            }
            try
            {
                var encoding = new UTF8Encoding(false, true);
                limits.Check("packageBytes", encoding.GetByteCount(text));
                return encoding.GetBytes(text);
            }
            catch (EncoderFallbackException) { throw new DebugFault("invalid_xml", "PackageXml enthält ungültige Unicodezeichen."); }
        }
    }
}
