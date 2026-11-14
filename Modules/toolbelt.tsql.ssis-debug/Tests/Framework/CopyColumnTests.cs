using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml.Linq;
using Toolbelt.Ssis.Exchange;
using Toolbelt.Tsql.SsisDebug;

internal static partial class ContractTests
{
    // Eigenständige Source→Copy→Destination-Kette. Die Erwartung folgt der
    // Identitätsprojektion, nicht den internen Aliasnamen des Generators.
    private static byte[] CopyColumnPackage(byte[] original, bool text)
    {
        return Change(original, d => {
            var pipeline = d.Descendants("pipeline").Single();
            var source = new XElement(pipeline.Descendants("component").Single(c => (string)c.Attribute("name") == "SourceA"));
            source.Descendants("property").Single(p => (string)p.Attribute("name") == "SqlCommand").Value = "SELECT KeyA,KeyB,Amount FROM dbo.SyntheticSourceA";
            source.Descendants("property").Where(p => (string)p.Attribute("name") == "ParameterMapping").Remove();
            int lineage = 100;
            foreach (var c in source.Descendants("outputColumn"))
            {
                c.SetAttributeValue("lineageId", (++lineage).ToString(System.Globalization.CultureInfo.InvariantCulture));
                if (text && (string)c.Attribute("name") == "KeyA")
                { c.SetAttributeValue("dataType", "wstr"); c.SetAttributeValue("cachedDataType", "wstr"); c.SetAttributeValue("length", "10"); }
            }
            foreach (var c in source.Descendants("externalMetadataColumn").Where(c => text && (string)c.Attribute("name") == "KeyA"))
            { c.SetAttributeValue("dataType", "wstr"); c.SetAttributeValue("length", "10"); }
            string input = "Copy.input", output = "Copy.output";
            var copy = new XElement("component", new XAttribute("refId", "Copy"), new XAttribute("name", "Copy"),
                new XAttribute("componentClassID", "{D231ABC4-4754-481B-8F7A-CD4BD8D09832}"), new XAttribute("version", "1"),
                new XElement("properties"), new XElement("inputs", new XElement("input", new XAttribute("refId", input), new XAttribute("name", "Input"),
                    new XElement("inputColumns", new XElement("inputColumn", new XAttribute("refId", "Copy.input.KeyA"), new XAttribute("name", "KeyA"), new XAttribute("lineageId", "101"), new XAttribute("dataType", text ? "wstr" : "i4"), new XAttribute("length", text ? "10" : "0")),
                        new XElement("inputColumn", new XAttribute("refId", "Copy.input.Amount"), new XAttribute("name", "Amount"), new XAttribute("lineageId", "103"), new XAttribute("dataType", "i4"))))),
                new XElement("outputs", new XElement("output", new XAttribute("refId", output), new XAttribute("name", "Rows"), new XAttribute("synchronousInputId", input),
                    new XElement("outputColumns",
                        CopyOutput("201", "KeyACopy", "101", text ? "wstr" : "i4", text ? "10" : "0"),
                        CopyOutput("202", "AmountCopy", "103", "i4", "0")))));
            var columns = new XElement("inputColumns"); var external = new XElement("externalMetadataColumns");
            string[] names = { "OriginalKeyA", "KeyACopy", "OriginalAmount", "AmountCopy" };
            string[] ids = { "101", "201", "103", "202" };
            for (int i = 0; i < names.Length; i++)
            {
                string type = text && i < 2 ? "wstr" : "i4", length = text && i < 2 ? "10" : "0", ext = "Destination.external." + i;
                columns.Add(new XElement("inputColumn", new XAttribute("refId", "Destination.input." + i), new XAttribute("name", names[i]), new XAttribute("lineageId", ids[i]), new XAttribute("dataType", type), new XAttribute("length", length), new XAttribute("externalMetadataColumnId", ext)));
                external.Add(new XElement("externalMetadataColumn", new XAttribute("refId", ext), new XAttribute("name", names[i]), new XAttribute("dataType", type), new XAttribute("length", length)));
            }
            var destination = new XElement("component", new XAttribute("refId", "Destination"), new XAttribute("name", "Destination"), new XAttribute("componentClassID", "Microsoft.OLEDBDestination"), new XAttribute("version", "4"),
                new XElement("properties"), new XElement("inputs", new XElement("input", new XAttribute("refId", "Destination.input"), new XAttribute("name", "Input"), columns, external)), new XElement("outputs"));
            pipeline.Element("components").ReplaceNodes(source, copy, destination);
            pipeline.Element("paths").ReplaceNodes(
                new XElement("path", new XAttribute("refId", "source-copy"), new XAttribute("startId", source.Element("outputs").Element("output").Attribute("refId").Value), new XAttribute("endId", input)),
                new XElement("path", new XAttribute("refId", "copy-destination"), new XAttribute("startId", output), new XAttribute("endId", "Destination.input")));
        });
    }
    private static XElement CopyOutput(string id, string name, string source, string type, string length)
    {
        return new XElement("outputColumn", new XAttribute("refId", "Copy.output." + id), new XAttribute("name", name), new XAttribute("lineageId", id), new XAttribute("dataType", type), new XAttribute("length", length),
            new XElement("properties", new XElement("property", new XAttribute("name", "copyColumnId"), source)));
    }
    private static XElement CopyComponent(XDocument d)
    { return d.Descendants("component").Single(c => (string)c.Attribute("name") == "Copy"); }
    private static void CopyColumnRejected(byte[] bytes, string label)
    {
        try
        {
            var result = ExplainV2(bytes);
            Assert(result.Rows.Any(x => x.Kind == "Diagnostic") && !result.Rows.Any(x => x.Kind == "TargetSql" && x.Executable), "COPY_REJECT_" + label);
        }
        catch (DebugFault e) { Assert(e.Code == "invalid_lineage" || e.Code == "unsupported_component", "COPY_REJECT_CODE_" + label + "_" + e.Code); }
    }
    private static void CopyColumnContract(string[] args)
    {
        byte[] original = File.ReadAllBytes(args[1]);
        foreach (bool text in new[] { false, true })
        {
            byte[] package = CopyColumnPackage(original, text);
            var catalog = new SyntheticCatalog { TextKeys = text, NullableKeys = true };
            var result = ExplainV2(package, catalog: catalog);
            Assert(result.Rows.Any(x => x.Kind == "TargetSql" && x.Executable && x.Complete && x.Safety == "passed"), "COPY_TARGET_COMPLETE " + String.Join("|", result.Rows.Where(x => x.Kind == "Diagnostic").Select(x => x.Code + ":" + x.Content)));
            var lineage = Json.Array(Json.Object(Json.Parse(result.Rows.Single(x => x.Kind == "StageIndex" && x.Component == "Copy").Details))["columns"]).Select(Json.Object).ToList();
            Assert(lineage.Count == 5, "COPY_SOURCE_COLUMNS_PRESERVED");
            Assert(String.Join(",", lineage.Select(c => Json.Text(c["lineageId"]))) == "101,102,103,201,202", "COPY_DECLARATION_ORDER");
            Assert(Json.Text(lineage[0]["sqlType"]) == Json.Text(lineage[3]["sqlType"]) && Json.Text(lineage[2]["sqlType"]) == Json.Text(lineage[4]["sqlType"]), "COPY_EXACT_TYPES");
            Assert(PackageDocument.Read(package, null, true).Definitions.Single(x => x.Kind == "COMPONENT" && x.Name == "Copy").ComponentKind == "copy-column", "COPY_RECOGNIZED");
            if (args.Length > 2)
            {
                string template = Engine.Analyze(package, Options("bindings-template"), catalog, new Budget()).Rows.Single().Content;
                ExportSyntheticFixture(args[2], text ? "copy-column-text" : "copy-column-int", package, "{}", template, Options("explain").CatalogBindings);
            }
            foreach (string guid in new[] { "{98F16A65-E02F-4B0F-87D4-C217EA074619}", "{D231ABC4-4754-481B-8F7A-CD4BD8D09832}" })
            {
                var supported = Change(package, d => CopyComponent(d).SetAttributeValue("componentClassID", guid));
                Assert(ExplainV2(supported, catalog: catalog).Rows.Any(x => x.Kind == "TargetSql" && x.Executable), "COPY_NATIVE_CLASSID");
            }
            var repeatSource = Change(package, d => CopyComponent(d).Descendants("outputColumns").Single().Add(CopyOutput("203", "AnotherKeyACopy", "101", text ? "wstr" : "i4", text ? "10" : "0")));
            var repeatResult = ExplainV2(repeatSource, catalog: catalog);
            Assert(repeatResult.Rows.Any(x => x.Kind == "TargetSql" && x.Executable), "COPY_MULTIPLE_COPIES_OF_ONE_SOURCE");
            var quoted = Change(package, d => CopyComponent(d).Descendants("outputColumn").First().SetAttributeValue("name", "Kopie_日本語]; DROP TABLE [Contoso];--"));
            Assert(ExplainV2(quoted, catalog: catalog).Rows.Any(x => x.Kind == "TargetSql" && x.Executable), "COPY_METADATA_NAME_IS_NOT_SQL");
        }
        byte[] valid = CopyColumnPackage(original, false);
        foreach (string id in new[] { "", "0", "-1", "0101", "+101", " 101", "2147483648", "999" })
            CopyColumnRejected(Change(valid, d => CopyComponent(d).Descendants("property").First(p => (string)p.Attribute("name") == "copyColumnId").Value = id), "SOURCE_" + id);
        foreach (string id in new[] { "", "0", "-1", "0201", "101", "202" })
            CopyColumnRejected(Change(valid, d => CopyComponent(d).Descendants("outputColumn").First().SetAttributeValue("lineageId", id)), "OUTPUT_" + id);
        foreach (string name in new[] { "", "KeyA", "keya", "AmountCopy" })
            CopyColumnRejected(Change(valid, d => CopyComponent(d).Descendants("outputColumn").First().SetAttributeValue("name", name)), "NAME_" + name);
        CopyColumnRejected(Change(valid, d => CopyComponent(d).SetAttributeValue("version", "2")), "VERSION");
        CopyColumnRejected(Change(valid, d => CopyComponent(d).Element("outputs").Element("output").SetAttributeValue("synchronousInputId", "foreign")), "SYNC");
        CopyColumnRejected(Change(valid, d => CopyComponent(d).Element("outputs").Element("output").SetAttributeValue("isErrorOut", "true")), "ERROR_PORT");
        CopyColumnRejected(Change(valid, d => CopyComponent(d).Descendants("outputColumn").First().SetAttributeValue("dataType", "i8")), "TYPE");
        CopyColumnRejected(Change(valid, d => CopyComponent(d).Descendants("inputColumn").First().SetAttributeValue("dataType", "i8")), "INPUT_TYPE");
        CopyColumnRejected(Change(valid, d => CopyComponent(d).Descendants("outputColumn").First().SetAttributeValue("codePage", "65001")), "CODEPAGE");
        CopyColumnRejected(Change(valid, d => CopyComponent(d).Descendants("outputColumns").Single().RemoveNodes()), "EMPTY_OUTPUT");
        CopyColumnRejected(Change(valid, d => { var duplicate = new XElement(CopyComponent(d).Descendants("inputColumn").First()); duplicate.SetAttributeValue("refId", "Copy.input.duplicate"); CopyComponent(d).Descendants("inputColumns").Single().Add(duplicate); }), "DUPLICATE_INPUT");
        CopyColumnRejected(Change(valid, d => { var columns = CopyComponent(d).Descendants("inputColumns").Single(); foreach (string id in new[] { "one", "two" }) columns.Add(new XElement("inputColumn", new XAttribute("refId", "Copy.input.extra." + id), new XAttribute("name", "KeyB"), new XAttribute("lineageId", "102"), new XAttribute("dataType", "i4"))); }), "UNSELECTED_DUPLICATE_INPUT");
    }
}
