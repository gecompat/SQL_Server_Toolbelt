using System;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Xml.Linq;
using Toolbelt.Ssis.Exchange;
using Toolbelt.Tsql.SsisDebug;

internal static partial class ContractTests
{
    private static int Simplicity(string fixture)
    {
        var limits = ResourceLimits.Legacy;
        Func<string, object> missing = name => { throw new DebugFault("missing_context", "synthetic missing value"); };
        Func<string, object> evaluate = text => new ConnectionExpression(text, missing, limits).Evaluate();
        Assert((string)evaluate("\"Initial Catalog=\" + (DT_WSTR,20)(2+3)") == "Initial Catalog=5", "AUTO_EXPRESSION_CAST_CONCAT");
        Assert((string)evaluate("TRUE ? \"AdventureWorks\" : @[User::Missing]") == "AdventureWorks", "AUTO_EXPRESSION_LAZY_BRANCH");
        Assert((bool)evaluate("FALSE && @[User::Missing]") == false, "AUTO_EXPRESSION_LAZY_AND");
        Assert((bool)evaluate("TRUE || @[User::Missing]") == true, "AUTO_EXPRESSION_LAZY_OR");
        Assert((string)evaluate("REPLACE(UPPER(\"contoso_dev\"),\"_DEV\",\"\")") == "CONTOSO", "AUTO_EXPRESSION_FUNCTION");
        Reject(() => evaluate("EXEC(\"arbitrary\")"), "unresolved_binding");
        Reject(() => evaluate("\"x\" + 5"), "unresolved_binding");
        Reject(() => evaluate("(DT_WSTR,2)\"abcdef\""), "unresolved_binding");
        Reject(() => evaluate(new string('!', 100) + "TRUE"), "unresolved_binding");
        Reject(() => evaluate(new string('(', 100) + "TRUE" + new string(')', 100)), "unresolved_binding");
        Reject(() => evaluate(String.Join("+", Enumerable.Repeat("1", 100))), "unresolved_binding");

        byte[] original = File.ReadAllBytes(fixture);
        var doc = XDocument.Parse(Encoding.UTF8.GetString(original));
        XNamespace dts = "www.microsoft.com/SqlServer/Dts";
        var manager = doc.Descendants(dts + "ConnectionManager").Single();
        string connection = "Provider=MSOLEDBSQL;Data Source=ContosoServer;Initial Catalog=AdventureWorks;User ID=Synthetic;Password=\"SYNTHETIC_ONLY;not-a-secret\"";
        manager.Add(new XElement(dts + "ObjectData", new XElement(dts + "ConnectionManager", new XAttribute(dts + "ConnectionString", connection))));
        byte[] bytes = Encoding.UTF8.GetBytes(doc.ToString());
        var package = PackageReader.Read(bytes, new Budget(), true, limits);
        var values = new Dictionary<string, object>(StringComparer.Ordinal);
        int ordinal = 0; foreach (var input in package.Inputs) input.Key = "v" + (++ordinal);
        AutomaticBindings.ApplyStarts(package, "{\"User::SourceFloor\":7}", values, limits);
        Assert(values.Count == 1 && values.Values.Single() is JsonNumber, "AUTO_TYPED_START_VALUES");
        Reject(() => AutomaticBindings.ApplyStarts(package, "{\"User::NotDeclared\":7}", values, limits), "unresolved_binding");
        Reject(() => AutomaticBindings.ApplyStarts(package, "{\"User::SourceFloor\":\"not-an-integer\"}", values, limits), "invalid_template");
        string catalog = AutomaticBindings.Catalog(package, values, limits, new Artifacts(limits));
        Assert(catalog.Contains("AdventureWorks") && !catalog.Contains("SYNTHETIC_ONLY") && !catalog.Contains("ContosoServer"), "AUTO_CONNECTION_REDACTION");
        manager.Add(new XElement(dts + "PropertyExpression", new XAttribute(dts + "Name", "InitialCatalog"), "\"OtherDatabase\""));
        var unsupported = PackageReader.Read(Encoding.UTF8.GetBytes(doc.ToString()), new Budget(), true, limits);
        Reject(() => AutomaticBindings.Catalog(unsupported, new Dictionary<string, object>(), limits, new Artifacts(limits)), "missing_context");
        manager.Elements(dts + "PropertyExpression").Remove();

        string xmlText = "<?xml version=\"1.0\" encoding=\"utf-16\"?>" + doc.ToString();
        byte[] xmlBytes = XmlInput.Read(SqlBytes.Null, new SqlString(xmlText), limits);
        Assert(PackageReader.Read(xmlBytes, new Budget(), true, limits).Profile == package.Profile, "AUTO_XML_UNICODE_INPUT");
        xmlBytes = XmlInput.Read(SqlBytes.Null, new SqlString(xmlText.Replace("<?xml ", "<?xml\n")), limits);
        Assert(PackageReader.Read(xmlBytes, new Budget(), true, limits).Profile == package.Profile, "AUTO_XML_DECLARATION_WHITESPACE");
        Reject(() => XmlInput.Read(new SqlBytes(bytes), new SqlString(doc.ToString()), limits), "invalid_template");
        Reject(() => XmlInput.Read(SqlBytes.Null, SqlString.Null, limits), "unresolved_binding");
        Reject(() => Engine.Analyze(bytes, new Options { Operation = "bindings-template", Version = 150,
            CatalogMode = "package", StartValues = "{}" }, new NullCatalog(), new Budget()), "invalid_template");

        // A NullCatalog throws on every metadata operation. A successful
        // package run therefore proves the core did not call that provider.
        var options = new Options { Operation = "explain", Version = 150, CatalogMode = "package", StartValues = "{\"User::SourceFloor\":7}" };
        var result = Engine.Analyze(bytes, options, new NullCatalog(), new Budget());
        var debug = result.Rows.Where(r => r.Kind == "DebugScript").ToList();
        Assert(debug.Count > 0 && debug.Any(r => r.Complete), "AUTO_PACKAGE_DEBUG_SCRIPT");
        Assert(debug.All(r => !r.Executable && r.Safety == "not_checked"), "AUTO_UNVERIFIED_NOT_PROMOTED");
        foreach (var script in debug.Where(r => r.Complete))
        {
            System.Collections.Generic.IList<Microsoft.SqlServer.TransactSql.ScriptDom.ParseError> errors;
            using (var reader = new StringReader(script.Content))
                new Microsoft.SqlServer.TransactSql.ScriptDom.TSql160Parser(true).Parse(reader, out errors);
            Assert(errors.Count == 0, "AUTO_COMPLETE_DEBUG_SYNTAX");
        }
        Assert(result.Rows.All(r => r.Safety != "passed"), "AUTO_MANIFEST_NOT_PROMOTED");
        foreach (var unit in result.Rows.Where(r => r.Kind == "PlanUnitSql"))
            Assert(Json.Text(Json.Get(Json.Object(Json.Parse(unit.Details, limits)), "unitContentSha256")) == Util.Hash(unit.Content), "AUTO_UNIT_HASH_UNCHANGED");
        Assert(result.Rows.Any(r => r.Code == "package_metadata_only"), "AUTO_PACKAGE_LIMITATION_REPORTED");
        Assert(result.Rows.All(r => !r.Content.Contains("SYNTHETIC_ONLY") && !(r.Details ?? "").Contains("SYNTHETIC_ONLY")), "AUTO_NO_CREDENTIAL_EXPORT");
        Assert(debug.Any(r => Regex.IsMatch(r.Content, @"DECLARE @v[0-9]+ int = 7;")), "AUTO_START_VALUE_IN_SQL");
        var strict = Options("explain"); strict.CatalogMode = "catalog";
        Reject(() => Engine.Analyze(bytes, strict, new NullCatalog(), new Budget()), "probe_catalog_access");

        // Resolve a database through a variable expression, including its
        // default and an explicit override. Never evaluate it through SQL.
        var variable = new XElement(dts + "Variable", new XAttribute(dts + "Namespace", "User"), new XAttribute(dts + "ObjectName", "Database"),
            new XAttribute(dts + "EvaluateAsExpression", "True"), new XAttribute(dts + "Expression", "\"Adventure\" + \"Works\""),
            new XElement(dts + "VariableValue", new XAttribute(dts + "DataType", "8"), "ignored"));
        doc.Root.Element(dts + "Variables").Add(variable);
        manager.Add(new XElement(dts + "PropertyExpression", new XAttribute(dts + "Name", "ConnectionString"), "\"Data Source=ContosoServer;Initial Catalog=\" + @[User::Database]"));
        options = new Options { Operation = "explain", Version = 150, CatalogMode = "package" };
        result = Engine.Analyze(Encoding.UTF8.GetBytes(doc.ToString()), options, new NullCatalog(), new Budget());
        Assert(result.Rows.Any(r => r.Kind == "DebugScript" && r.Complete), "AUTO_CONNECTION_EXPRESSION_DEFAULT");
        variable.SetAttributeValue(dts + "Expression", "@[User::Database]");
        Reject(() => Engine.Analyze(Encoding.UTF8.GetBytes(doc.ToString()), new Options { Operation = "explain", Version = 150, CatalogMode = "package" }, new NullCatalog(), new Budget()), "unresolved_binding");
        Console.WriteLine("SSIS_FRAMEWORK_PASS " + checks);
        return 0;
    }
}
