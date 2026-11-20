using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Xml;
using System.Xml.Linq;

namespace Toolbelt.Tsql.SsisDebug
{
    // Der deklarierte Resultsetvertrag ist für den katalogfreien Entwurf
    // ausreichend. Keine erfundenen Basistabellen, kein Objekt-/Typnachweis.
    internal static class PackageProjection
    {
        internal static List<BoundColumn> Columns(Component component, Toolbelt.Ssis.Exchange.ResourceLimits limits)
        {
            var result = new List<BoundColumn>();
            Action<string, string, int> add = (name, type, codePage) =>
            {
                if (String.IsNullOrEmpty(name) || type == null) throw new DebugFault("missing_context", "Deklarierte Paket-Ausgabespalte oder ihr Datentyp fehlt.");
                Util.Q(name); var existing = result.SingleOrDefault(c => c.Name == name);
                if (existing != null)
                {
                    if (existing.SqlType != type) throw new DebugFault("unresolved_binding", "Widersprüchliche Paket-Ausgabetypen.");
                    return;
                }
                limits.Check("columns", result.Count + 1);
                result.Add(new BoundColumn { Name = name, SqlType = type, Nullable = true,
                    Collation = type.StartsWith("varchar", StringComparison.Ordinal) || type.StartsWith("nvarchar", StringComparison.Ordinal)
                        ? codePage == 65001 ? "Latin1_General_100_BIN2_UTF8" : "Latin1_General_100_BIN2" : null });
            };
            if (component.Kind == "lookup")
            {
                string metadata = PackageReader.P(component.Properties, "ReferenceMetadataXml");
                if (!String.IsNullOrWhiteSpace(metadata))
                {
                    limits.Check("xmlCharacters", metadata.Length);
                    var settings = new XmlReaderSettings { DtdProcessing = DtdProcessing.Prohibit, XmlResolver = null, MaxCharactersInDocument = metadata.Length + 1L };
                    XDocument document;
                    try
                    {
                        using (var reader = XmlReader.Create(new StringReader(metadata), settings))
                        {
                            int nodes = 0;
                            while (reader.Read()) { limits.Check("xmlNodes", ++nodes); if (reader.Depth > 128) throw new DebugFault("resource_limit", "Lookup-Metadaten überschreiten die feste XML-Tiefe."); }
                        }
                        using (var reader = XmlReader.Create(new StringReader(metadata), settings)) document = XDocument.Load(reader);
                    }
                    catch (XmlException) { throw new DebugFault("invalid_lineage", "Lookup-Referenzmetadaten sind kein zulässiges XML."); }
                    foreach (var column in document.Descendants().Where(e => e.Name.LocalName == "referenceColumn"))
                    {
                        Func<string, int> number = key => { int n; string text = (string)column.Attribute(key) ?? "0"; if (!Int32.TryParse(text, NumberStyles.None, CultureInfo.InvariantCulture, out n)) throw new DebugFault("invalid_lineage", "Ungültige Lookup-Typmetadaten."); return n; };
                        string type = ((string)column.Attribute("dataType") ?? "").ToLowerInvariant();
                        if (type.StartsWith("dt_", StringComparison.Ordinal)) type = type.Substring(3);
                        add((string)column.Attribute("name"), Types.Sql(type, number("length"), number("precision"), number("scale")), number("codePage"));
                    }
                }
                // Nicht jeder Serializer persistiert ReferenceMetadataXml.
                // In diesem Fall nur explizite Join-/Return-Verträge verwenden.
                foreach (Column key in component.Inputs.SelectMany(p => p.Columns))
                {
                    string name = PackageReader.P(key.Properties, "JoinToReferenceColumn");
                    if (name != "" && !result.Any(c => c.Name == name)) add(name, key.SqlType, key.CodePage);
                }
                foreach (Column value in component.Outputs.Where(p => !p.Error).SelectMany(p => p.Columns))
                {
                    string name = PackageReader.P(value.Properties, "CopyFromReferenceColumn");
                    if (name != "" && !result.Any(c => c.Name == name)) add(name, value.SqlType, value.CodePage);
                }
            }
            else
            {
                foreach (var port in component.Outputs.Where(p => !p.Error))
                    foreach (var column in port.External.Count != 0 ? port.External : port.Columns)
                        add(column.Name, column.SqlType, column.CodePage);
            }
            if (result.Count == 0) throw new DebugFault("missing_context", "Im Paket ist keine Abfrageausgabe beschrieben.");
            return result;
        }
    }
}
