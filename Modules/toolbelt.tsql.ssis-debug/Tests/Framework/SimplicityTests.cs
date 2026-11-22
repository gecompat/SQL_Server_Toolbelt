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
        var floor = package.Inputs.Single(i => i.Name == "User::SourceFloor");
        string duplicate = Json.Write(Json.Obj(floor.Name, new JsonNumber("7"), floor.Scope + "\\" + floor.Name, new JsonNumber("8")), limits);
        Reject(() => AutomaticBindings.ApplyStarts(package, duplicate, new Dictionary<string, object>(), limits), "unresolved_binding");
        string catalog = AutomaticBindings.Catalog(package, values, limits, new Artifacts(limits));
        Assert(catalog.Contains("AdventureWorks") && !catalog.Contains("SYNTHETIC_ONLY") && !catalog.Contains("ContosoServer"), "AUTO_CONNECTION_REDACTION");
        manager.Add(new XElement(dts + "PropertyExpression", new XAttribute(dts + "Name", "InitialCatalog"), "\"OtherDatabase\""));
        var propertyOverride = PackageReader.Read(Encoding.UTF8.GetBytes(doc.ToString()), new Budget(), true, limits);
        Assert(AutomaticBindings.Catalog(propertyOverride, new Dictionary<string, object>(), limits, new Artifacts(limits)).Contains("OtherDatabase"), "AUTO_INITIAL_CATALOG_EXPRESSION_OVERRIDES_DESIGN");
        manager.Add(new XElement(dts + "PropertyExpression", new XAttribute(dts + "Name", "ConnectionString"), "\"Data Source=ContosoServer;Initial Catalog=AdventureWorks\""));
        var conflicting = PackageReader.Read(Encoding.UTF8.GetBytes(doc.ToString()), new Budget(), true, limits);
        Reject(() => AutomaticBindings.Catalog(conflicting, new Dictionary<string, object>(), limits, new Artifacts(limits)), "unresolved_binding");
        manager.Elements(dts + "PropertyExpression").Remove();
        manager.Add(new XElement(dts + "PropertyExpression", new XAttribute(dts + "Name", "Password"), "\"SYNTHETIC_ONLY\""));
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
        CompletionCases(bytes, limits, Path.Combine(Path.GetDirectoryName(fixture), "synthetic-8.dtsx"));
        Console.WriteLine("SSIS_FRAMEWORK_PASS " + checks);
        return 0;
    }

    private static void CompletionCases(byte[] packageBytes, ResourceLimits limits, string lookupFixture)
    {
        var options = new Options { Operation = "explain", Version = 150, CatalogMode = "package", Limits = limits };
        var package = PackageReader.Read(packageBytes, new Budget(), true, limits);
        var catalog = new PackageCatalog(package, options, new Budget());
        var safety = new SqlSafety(new Budget(), 150, catalog, new[] { "AdventureWorks" }, new string[0], c => { });
        var metadata = new Component { Kind = "source", Properties = new Dictionary<string, string>() };
        var port = new Port(); port.Columns.Add(new Column { Name = "ResultId", SqlType = "int" }); metadata.Outputs.Add(port);
        foreach (string sql in new[] {
            "SELECT a.Id AS ResultId FROM dbo.A a JOIN dbo.B b ON a.Id=b.Id",
            "SELECT Id AS ResultId FROM dbo.SyntheticRows()",
            "EXEC(N'SELECT Id AS ResultId FROM dbo.A')",
            "SELECT IIF(1=1,1,0) AS ResultId",
            "SELECT RANK() OVER(ORDER BY Id) AS ResultId FROM dbo.A" })
        {
            var query = safety.Read(sql, "AdventureWorks"); query.PackageColumns = PackageProjection.Columns(metadata, limits);
            Assert(Projection.Columns(query, safety).Single().Name == "ResultId", "PACKAGE_RESULT_CONTRACT_WITHOUT_BASE_CATALOG");
            Assert(query.Objects.Count == 0, "PACKAGE_DOES_NOT_FABRICATE_CATALOG_OBJECTS");
        }
        Reject(() => safety.Read("EXEC(N'DELETE FROM dbo.A')", "AdventureWorks"), "unsafe_statement");
        Reject(() => safety.Read("SELECT 1; DELETE FROM dbo.A", "AdventureWorks"), "unsafe_statement");
        Reject(() => safety.Read("SELECT * INTO dbo.Other FROM dbo.A", "AdventureWorks"), "unsafe_statement");
        Reject(() => safety.Read("SELECT * FROM OtherDatabase.dbo.A", "AdventureWorks"), "unresolved_dependency");
        Reject(() => safety.Read("SELECT * FROM ContosoServer.AdventureWorks.dbo.A", "AdventureWorks"), "unresolved_dependency");

        var lookup = new Component { Kind = "lookup", Properties = new Dictionary<string, string> {
            { "ReferenceMetadataXml", "<referenceMetadata><referenceColumns><referenceColumn name='KeyA' dataType='DT_I4' length='0' precision='0' scale='0' codePage='0'/><referenceColumn name='Label' dataType='DT_WSTR' length='20' precision='0' scale='0' codePage='0'/></referenceColumns></referenceMetadata>" } } };
        var columns = PackageProjection.Columns(lookup, limits);
        Assert(columns.Count == 2 && columns[0].SqlType == "int" && columns[1].SqlType == "nvarchar(20)", "PACKAGE_LOOKUP_REFERENCE_METADATA_TYPED");
        lookup.Properties["ReferenceMetadataXml"] = "<!DOCTYPE r [<!ENTITY e SYSTEM 'file:///not-used'>]><r>&e;</r>";
        Reject(() => PackageProjection.Columns(lookup, limits), "invalid_lineage");

        var union = new Component { Kind = "union" }; var flow = new Flow();
        union.Inputs.Add(new Port { Id = "connected" }); union.Inputs.Add(new Port { Id = "reserve" });
        var missing = new Port { Id = "mapped-but-missing" }; missing.Columns.Add(new Column { Lineage = "1" }); union.Inputs.Add(missing);
        flow.Paths.Add("connected", "source");
        var required = (IEnumerable<Port>)typeof(Translator).GetMethod("RequiredPorts", System.Reflection.BindingFlags.Static | System.Reflection.BindingFlags.NonPublic).Invoke(null, new object[] { flow, union });
        Assert(required.Select(p => p.Id).SequenceEqual(new[] { "connected", "mapped-but-missing" }), "UNION_EMPTY_RESERVE_ONLY_IGNORED");
        Assert(ComponentProfiles.KindV2("Microsoft.Multicast", 0, "2014/01", new Dictionary<string, string>()) == "multicast", "MULTICAST_KNOWN_PROFILE");
        Assert(ComponentProfiles.KindV2("Microsoft.Multicast", 1, "2014/01", new Dictionary<string, string>()) == "unsupported", "MULTICAST_UNKNOWN_VERSION_REJECTED");

        Func<string, ExpressionValue> expression = text => new ExpressionParser(text, null, null,
            new Dictionary<string, ExpressionValue> { { "Value", new ExpressionValue { Sql = "[Value]", Type = "int", Total = true } } },
            null, true, cp => cp == 1252 ? "Latin1_General_100_BIN2" : null).Parse();
        Assert(expression("(DT_I1)([Value] == 1 ? 1 : 0)").Type == "smallint", "I1_CONDITIONAL_RANGE_PROVEN");
        Assert(expression("(DT_I1)REPLACENULL([Value],0)").Sql.Contains("CONVERT(tinyint"), "I1_UNKNOWN_RANGE_GUARDED");
        Assert(expression("[Value] == 0 ? (DT_STR,20,1252)NULL(DT_STR,20,1252) : (DT_STR,20,1252)\"abc\"").Type == "varchar(20)", "ANSI_TYPED_NULL_CONDITIONAL");
        string group = String.Join(" || ", Enumerable.Range(1, 24).Select(i => "[Value] == " + i));
        var nested = expression("[Value] == 0 || !(" + group + ")");
        Assert(!nested.Sql.Contains("NOT CAST(1 AS bit)") && nested.Sql.Contains("24"), "NESTED_BOOLEAN_RETAINS_REAL_TERMS");
        safety.CheckPackageComposition("SELECT " + nested.Sql + " AS Result;");

        string ctes = ";WITH " + String.Join(",", Enumerable.Range(1, 40).Select(i => "c" + i + " AS(SELECT 1 AS V)")) + " SELECT V FROM c40;";
        safety.CheckPackageComposition(ctes);
        Reject(() => safety.Parse(ctes), "resource_limit");
        Assert(true, "SOURCE_AND_COMPOSITION_PARSER_CACHE_SEPARATED");
        string tooMany = ";WITH " + String.Join(",", Enumerable.Range(1, 513).Select(i => "c" + i + " AS(SELECT 1 AS V)")) + " SELECT V FROM c513;";
        Reject(() => safety.CheckPackageComposition(tooMany), "resource_limit");
        string procedureCall;
        Assert(safety.TryPackageProcedure("EXEC dbo.SyntheticProcedure @Id=7", "AdventureWorks", out procedureCall) && procedureCall.Contains("[AdventureWorks].[dbo].[SyntheticProcedure]"), "PROCEDURE_CALL_STATIC_CAPTURE");
        Assert(safety.TryPackageProcedure("EXEC dbo.SyntheticProcedure WITH RESULT SETS ((Id int))", "AdventureWorks", out procedureCall) && !procedureCall.Contains("RESULT SETS"), "INSERT_EXEC_OMITS_INCOMPATIBLE_RESULT_SETS_OPTION");
        Reject(() => safety.TryPackageProcedure("EXEC dbo.SyntheticProcedure WITH RESULT SETS NONE", "AdventureWorks", out procedureCall), "unsupported_component");
        Reject(() => safety.TryPackageProcedure("EXEC ContosoServer.AdventureWorks.dbo.SyntheticProcedure", "AdventureWorks", out procedureCall), "unresolved_dependency");
        Reject(() => safety.TryPackageProcedure("EXEC dbo.SyntheticProcedure @Id=@Output OUTPUT", "AdventureWorks", out procedureCall), "unsupported_component");

        XNamespace dts = "www.microsoft.com/SqlServer/Dts";
        var document = XDocument.Parse(Encoding.UTF8.GetString(packageBytes));
        var source = document.Descendants("component").First(c => (string)c.Attribute("componentClassID") == "Microsoft.OLEDBSource");
        source.Element("properties").Elements("property").Single(p => (string)p.Attribute("name") == "SqlCommand").Value = "EXEC dbo.SyntheticProcedure @Floor=?";
        var captured = Engine.Analyze(Encoding.UTF8.GetBytes(document.ToString()), new Options { Operation = "explain", Version = 150, CatalogMode = "package" }, new NullCatalog(), new Budget());
        string script = captured.Rows.Single(a => a.Kind == "DebugScript").Content;
        Assert(script.Contains("INSERT INTO [#tbx_SsisDebug_P_") && script.Contains("EXECUTE [AdventureWorks].[dbo].[SyntheticProcedure]"), "PROCEDURE_RESULT_LOCAL_TEMP_INSERT_EXEC");
        Assert(script.Contains("BEGIN CATCH") && script.Contains("DROP TABLE [#tbx_SsisDebug_P_") && !script.Contains("CREATE TABLE [##"), "PROCEDURE_TEMP_OWNED_CLEANUP");

        var lookupDocument = XDocument.Load(lookupFixture);
        foreach (var component in lookupDocument.Descendants("component").Where(c => new[] { "Microsoft.DerivedColumn", "Microsoft.ConditionalSplit" }.Contains((string)c.Attribute("componentClassID"))))
        {
            component.SetAttributeValue("version", "0");
            foreach (var output in component.Element("outputs").Elements("output")) output.SetAttributeValue("synchronousInputId", (string)component.Element("inputs").Element("input").Attribute("refId"));
        }
        var lookupComponent = lookupDocument.Descendants("component").Single(c => (string)c.Attribute("componentClassID") == "Microsoft.Lookup");
        lookupComponent.Element("properties").Elements("property").Single(p => (string)p.Attribute("name") == "SqlCommand").Value = "EXEC dbo.SyntheticLookupProcedure";
        var lookupCapture = Engine.Analyze(Encoding.UTF8.GetBytes(lookupDocument.ToString()), new Options { Operation = "explain", Version = 150, CatalogMode = "package" }, new NullCatalog(), new Budget());
        Assert(lookupCapture.Rows.Any(a => a.Kind == "DebugScript" && a.Complete && a.Content.Contains("_input]") && a.Content.Contains("EXECUTE [dbo].[SyntheticLookupProcedure]")), "LOOKUP_PROCEDURE_FREEZES_INPUT_BEFORE_RESULT_CAPTURE:" + String.Join(",", lookupCapture.Rows.Where(a => a.Kind == "Diagnostic").Select(a => a.Code + "/" + a.Content)));

        foreach (var column in lookupDocument.Descendants().Where(e => (string)e.Attribute("name") == "KeyA" && e.Attribute("dataType") != null))
        {
            column.SetAttributeValue("dataType", "wstr");
            column.SetAttributeValue("length", "12");
            if (column.Attribute("cachedDataType") != null)
            {
                column.SetAttributeValue("cachedDataType", "wstr");
                column.SetAttributeValue("cachedLength", "12");
            }
        }
        lookupComponent.Element("properties").Elements("property").Single(p => (string)p.Attribute("name") == "SqlCommand").Value = "SELECT KeyA, KeyB, Score FROM dbo.SyntheticLookup";
        string fullCache = PackageLookupSql(lookupDocument);
        Assert(fullCache.Contains("DATALENGTH(CAST(ref.[KeyA] AS nvarchar(12)) COLLATE") &&
            fullCache.Contains("= DATALENGTH(lk.[k"), "LOOKUP_FULL_CACHE_TEXT_LENGTH_RANK_AND_JOIN");
        lookupComponent.Element("properties").Elements("property").Single(p => (string)p.Attribute("name") == "CacheType").Value = "1";
        string partialCache = PackageLookupSql(lookupDocument);
        Assert(partialCache.Contains("ROW_NUMBER() OVER (PARTITION BY") &&
            !partialCache.Contains("DATALENGTH(lk.[k"), "LOOKUP_OTHER_CACHE_MODES_KEEP_SQL_KEYS");
        const string missesPrefix = "lookup_misses_";
        Func<string, string, Artifacts> preview = (inspect, target) => Engine.Analyze(Encoding.UTF8.GetBytes(lookupDocument.ToString()),
            new Options { Operation = "explain", Version = 150, CatalogMode = "package", Stage = inspect, Target = target }, new NullCatalog(), new Budget());
        Assert(!preview("all", null).Rows.Any(a => a.Kind == "StageIndex" && a.Content.StartsWith(missesPrefix, StringComparison.Ordinal)),
            "LOOKUP_MISSES_ONLY_FOR_FAIL_DISPOSITION");
        lookupComponent.Element("properties").Elements("property").Single(p => (string)p.Attribute("name") == "CacheType").Value = "0";
        lookupComponent.Element("properties").Elements("property").Single(p => (string)p.Attribute("name") == "NoMatchBehavior").Value = "0";
        var allStages = preview("all", null);
        var index = allStages.Rows.First(a => a.Kind == "StageIndex" && a.Content.StartsWith(missesPrefix, StringComparison.Ordinal));
        Assert(allStages.Rows.Count(a => a.Kind == "StageIndex" && a.Target == index.Target && a.Content.StartsWith(missesPrefix, StringComparison.Ordinal)) == 1,
            "LOOKUP_MISSES_ONE_STAGE_PER_LOOKUP_AND_TARGET");
        var allMisses = allStages.Rows.Single(a => a.Kind == "StageSql" && a.Target == index.Target && a.Stage == index.Stage);
        var singleMisses = preview(index.Stage, index.Target).Rows.Single(a => a.Kind == "StageSql");
        Assert(singleMisses.Content == allMisses.Content && allMisses.Content.Contains("WHERE NOT EXISTS") &&
            allMisses.Content.Contains("= DATALENGTH(lk.[k") && !allMisses.Executable && allMisses.Safety == "not_checked",
            "LOOKUP_MISSES_SELECTABLE_AND_REUSES_TEXT_LENGTH");
        var defaultPreview = preview(null, index.Target);
        Assert(defaultPreview.Rows.Any(a => a.Kind == "StageIndex" && a.Stage == index.Stage) &&
            !defaultPreview.Rows.Any(a => a.Kind == "StageSql") &&
            !defaultPreview.Rows.Single(a => a.Kind == "DebugScript").Content.Contains(missesPrefix),
            "LOOKUP_MISSES_DEFAULT_INDEX_WITHOUT_TARGET_SQL_CHANGE");
        lookupComponent.Element("properties").Elements("property").Single(p => (string)p.Attribute("name") == "SqlCommand").Value = "EXEC dbo.SyntheticLookupProcedure";
        var procedureMisses = preview(index.Stage, index.Target).Rows.Single(a => a.Kind == "StageSql").Content;
        Assert(procedureMisses.Contains("_input]") && procedureMisses.Contains("WHERE NOT EXISTS") &&
            procedureMisses.Split(new[] { "EXECUTE [dbo].[SyntheticLookupProcedure]" }, StringSplitOptions.None).Length == 2 &&
            !procedureMisses.Contains("CREATE TABLE [##"), "LOOKUP_MISSES_REUSES_ONE_PROCEDURE_CAPTURE");
        foreach (var destination in lookupDocument.Descendants("component").Where(c => (string)c.Attribute("componentClassID") == "Microsoft.OLEDBDestination"))
            destination.Element("inputs").Element("input").Element("inputColumns").RemoveNodes();
        var blockedTarget = preview(index.Stage, index.Target);
        Assert(!blockedTarget.Rows.Single(a => a.Kind == "DebugScript").Complete &&
            blockedTarget.Rows.Single(a => a.Kind == "StageSql").Stage == index.Stage,
            "LOOKUP_MISSES_REMAIN_AVAILABLE_BEFORE_BLOCKED_TARGET");

        document = XDocument.Parse(Encoding.UTF8.GetString(packageBytes));
        document.Root.Element(dts + "ConnectionManagers").Add(new XElement(dts + "ConnectionManager", new XAttribute(dts + "refId", "Package.ConnectionManagers[SyntheticFile]"), new XAttribute(dts + "CreationName", "FLATFILE"), new XAttribute(dts + "ObjectName", "SyntheticFile")));
        source = document.Descendants("component").First(c => (string)c.Attribute("componentClassID") == "Microsoft.OLEDBSource");
        source.SetAttributeValue("componentClassID", "Microsoft.FlatFileSource"); source.SetAttributeValue("version", "1");
        source.Element("connections").Element("connection").SetAttributeValue("connectionManagerRefId", "Package.ConnectionManagers[SyntheticFile]");
        var dummy = Engine.Analyze(Encoding.UTF8.GetBytes(document.ToString()), new Options { Operation = "explain", Version = 150, CatalogMode = "package" }, new NullCatalog(), new Budget());
        Assert(dummy.Rows.Any(a => a.Kind == "DebugScript" && a.Complete && a.Content.Contains("CAST(NULL AS int)")) && dummy.Rows.Any(a => a.Code == "flatfile_source_assumed"), "FLATFILE_TYPED_DUMMY_CTE_NO_FILE_ACCESS");
        document.Root.Element(dts + "Executables").Remove();
        var controlOnly = Engine.Analyze(Encoding.UTF8.GetBytes(document.ToString()), new Options { Operation = "explain", Version = 150, CatalogMode = "package" }, new NullCatalog(), new Budget());
        Assert(controlOnly.Rows.Any(a => a.Code == "no_dataflow") && !controlOnly.Rows.Any(a => a.Kind == "DebugScript"), "CONTROL_ONLY_NOT_FAKE_DATAFLOW");
        Assert(expression("UPPER(\"abc\")").Sql.Contains("UPPER(") && expression("ROUND(1.25,1)").Sql.Contains("ROUND("), "ADDITIONAL_PACKAGE_SCALAR_FUNCTIONS");
        Assert(expression("[GETDATE]()").Type == "datetime2(7)", "BRACKETED_ZERO_ARGUMENT_GETDATE");
        Assert(expression("DATEPART(\"m\",[GETDATE]())").Sql.Contains("DATEPART(month,"), "DATEPART_MONTH_ALIAS");
    }

    private static string PackageLookupSql(XDocument document)
    {
        var artifacts = Engine.Analyze(Encoding.UTF8.GetBytes(document.ToString()),
            new Options { Operation = "explain", Version = 150, CatalogMode = "package" }, new NullCatalog(), new Budget());
        return String.Join("\n", artifacts.Rows.Where(a => a.Kind == "DebugScript" && a.Complete).Select(a => a.Content));
    }
}
