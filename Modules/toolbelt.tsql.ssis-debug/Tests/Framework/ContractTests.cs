using System;
using System.Collections;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Threading;
using System.Text;
using System.Xml.Linq;
using Microsoft.SqlServer.TransactSql.ScriptDom;
using Toolbelt.Ssis.Exchange;
using Toolbelt.Tsql.SsisDebug;

internal sealed class SyntheticCatalog : ICatalog
{
    internal bool TextKeys;
    internal string TextKeyCollation;
    internal bool NullableKeys;
    internal bool NullableKeyB;
    internal bool NullableLookupScore;
    internal bool Drift;
    private int resolutions;
    public string Collation(string database) { return TextKeyCollation ?? "Latin1_General_100_BIN2"; }
    public bool IsCollation(string name) { return name == "Latin1_General_100_BIN2" || name == "Latin1_General_100_CI_AS_SC_UTF8"; }
    public int CodePage(string name) { return name == "Latin1_General_100_CI_AS_SC_UTF8" ? 65001 : 1252; }
    public string BindIdentifier(string database, IEnumerable<string> names, string name) { return names.SingleOrDefault(x => x == name); }
    public BoundObject Resolve(string database, string schema, string name)
    {
        bool lookup = name == "SyntheticLookup" || name == "SyntheticV2TextLookup";
        if (database != "AdventureWorks" || schema != null && schema != "dbo" || !(name == "SyntheticSourceA" || name == "SyntheticSourceB" || name == "SyntheticLookup" || name == "SyntheticV2TextA" || name == "SyntheticV2TextB" || name == "SyntheticV2TextLookup" || name == "SyntheticIf" || name == "SyntheticPure" || name == "SyntheticFlatFileRows")) return null;
        var o = new BoundObject { Database = database, Schema = schema, Name = name, Kind = "U", Fingerprint = name + (Drift ? (++resolutions).ToString() : "") };
        if (name == "SyntheticIf") { o.Kind = "IF"; o.Schema = "dbo"; o.Definition = "CREATE FUNCTION dbo.SyntheticIf() RETURNS TABLE AS RETURN (SELECT KeyA,KeyB,Amount FROM dbo.SyntheticSourceA);"; }
        if (name == "SyntheticPure") { o.Kind = "IF"; o.Schema = "dbo"; o.Definition = "CREATE FUNCTION dbo.SyntheticPure() RETURNS TABLE AS RETURN (SELECT 1 AS KeyA,10 AS KeyB,100 AS Amount);"; }
        foreach (string column in new[] { "KeyA", "KeyB", lookup ? "Score" : "Amount" }) o.Columns.Add(new BoundColumn { Name = column, SqlType = TextKeys && column == "KeyA" ? "nvarchar(10)" : "int", Collation = TextKeys && column == "KeyA" ? TextKeyCollation ?? "Latin1_General_100_CS_AS" : null, Nullable = (NullableKeys && column == "KeyA") || (NullableKeyB && column == "KeyB") || (NullableLookupScore && lookup && column == "Score") });
        return o;
    }
}
internal sealed class NullCatalog : ICatalog
{
    private static DebugFault Offline() { return new DebugFault("probe_catalog_access", "Offline probe does not access catalog metadata."); }
    public string Collation(string database) { throw Offline(); }
    public bool IsCollation(string name) { throw Offline(); }
    public int CodePage(string name) { throw Offline(); }
    public string BindIdentifier(string database, IEnumerable<string> candidates, string name) { throw Offline(); }
    public BoundObject Resolve(string database, string schema, string name) { throw Offline(); }
}
internal static class ContractTests
{
    private static int checks;
    private static void Assert(bool value, string name) { checks++; if (!value) throw new Exception(name); }
    private static void Reject(Action action, string code)
    { bool failed = false; try { action(); } catch (DebugFault e) { failed = e.Code == code; } Assert(failed, "EXPECTED_" + code); }
    private static void RejectResourceLimit(Action action, string counter, long actual, long maximum)
    {
        bool failed = false;
        try { action(); }
        catch (ResourceLimitException error) { failed = error.Counter == counter && error.Actual == actual && error.Maximum == maximum && error.Preset == "legacy-v1"; }
        Assert(failed, "EXPECTED_RESOURCE_LIMIT_" + counter);
    }
    private static Options Options(string operation)
    {
        return new Options { Operation = operation, Version = 150, CatalogBindings = operation == "explain" ? "{\"schemaVersion\":1,\"defaultDatabase\":\"AdventureWorks\",\"databases\":[\"AdventureWorks\"],\"connections\":{\"Package.ConnectionManagers[Synthetic]\":\"AdventureWorks\"}}" : null };
    }
    private static byte[] Change(byte[] bytes, Action<XDocument> edit)
    { var document = XDocument.Parse(Encoding.UTF8.GetString(bytes)); edit(document); return Encoding.UTF8.GetBytes(document.ToString()); }
    private static Artifacts ExplainV2(byte[] bytes, string target = null, string projectContext = null, SyntheticCatalog catalog = null, ResourceLimits resourceLimits = null)
    { catalog = catalog ?? new SyntheticCatalog(); var templateOptions = Options("bindings-template"); templateOptions.ProjectContext = projectContext; templateOptions.Limits = resourceLimits; var template = Engine.Analyze(bytes, templateOptions, catalog, new Budget()).Rows.Single().Content; var options = Options("explain"); options.ProjectContext = projectContext; options.Target = target; options.Bindings = template; options.Limits = resourceLimits; return Engine.Analyze(bytes, options, catalog, new Budget()); }
    private static byte[] SerializeUtf16(XDocument document)
    { using (var stream = new MemoryStream()) { var settings = new System.Xml.XmlWriterSettings { Encoding = Encoding.Unicode, Indent = false, OmitXmlDeclaration = false }; using (var writer = System.Xml.XmlWriter.Create(stream, settings)) document.Save(writer); return stream.ToArray(); } }
    private static void ExportSyntheticFixture(string root, string name, byte[] package, string projectContext, string template, string catalog)
    {
        string folder = Path.Combine(root, name); Directory.CreateDirectory(folder);
        File.WriteAllBytes(Path.Combine(folder, "package.dtsx"), package);
        File.WriteAllText(Path.Combine(folder, "project-context.json"), projectContext, new UTF8Encoding(false));
        File.WriteAllText(Path.Combine(folder, "bindings-template.json"), template, new UTF8Encoding(false));
        File.WriteAllText(Path.Combine(folder, "catalog-bindings.json"), catalog, new UTF8Encoding(false));
    }
    private static SqlSafety Safety(SyntheticCatalog cat)
    { return new SqlSafety(new Budget(), 150, cat, new[] { "AdventureWorks" }, new string[0], code => { }); }
    private static void AssertWalkParity(SqlSafety safety, string sql)
    {
        TSqlFragment root = safety.Parse(sql); var expected = new List<TSqlFragment>(); var todo = new Stack<TSqlFragment>(); todo.Push(root);
        while (todo.Count != 0)
        {
            TSqlFragment node = todo.Pop(); expected.Add(node);
            foreach (PropertyInfo property in node.GetType().GetProperties(BindingFlags.Public | BindingFlags.Instance))
            {
                if (property.GetIndexParameters().Length != 0 || property.Name == "ScriptTokenStream") continue;
                object value = property.GetValue(node, null); TSqlFragment child = value as TSqlFragment;
                if (child != null) todo.Push(child);
                else if (value is IList) foreach (object item in (IList)value) if (item is TSqlFragment) todo.Push((TSqlFragment)item);
            }
        }
        var actual = safety.Walk(root).ToList();
        Assert(actual.Count == expected.Count && !actual.Where((node, index) => !Object.ReferenceEquals(node, expected[index])).Any(), "SQL_AST_WALK_PRESERVES_NODE_SEQUENCE");
    }
    private static void ProjectType(string expression, string expected)
    { try { var safety = Safety(new SyntheticCatalog()); var query = safety.Read("SELECT " + expression + " AS Value", "AdventureWorks"); Assert(Projection.Columns(query, safety)[0].SqlType == expected, "EXACT_SQL_TYPE_" + expected); } catch (Exception e) { throw new Exception("PROJECT_TYPE_" + expression, e); } }
    private static void Run(string[] args)
    {
        if (args[0] == "cooperative-budget")
        {
            var budget = new Budget(); budget.Check(); checks++;
            System.Threading.Thread.Sleep(30050);
            Reject(() => budget.Check(), "resource_limit");
        }
        else if (args[0] == "release-output-bounds")
        {
            // Feste Vertragsgrenzen am echten Providerkern; keine SQL-/Heapmessung.
            foreach (int n in new[] { 9999,10000,10001 }) {
                var output = new Artifacts(); Action add = () => { for(int i=0;i<n;i++) output.Add(new Artifact { Kind="Workflow", Content="" }); };
                if(n<=10000){add();Assert(output.Rows.Count==n,"ARTIFACT_COUNT");}else RejectResourceLimit(add,"artifacts",n,10000);
            }
            foreach (int n in new[] { 999,1000,1001 }) {
                var output = new Artifacts(); Action add = () => { for(int i=0;i<n;i++) output.Diagnostic("synthetic","synthetic",""); };
                if(n<=1000){add();Assert(output.Rows.Count==n,"DIAGNOSTIC_COUNT");}else RejectResourceLimit(add,"diagnostics",n,1000);
            }
            foreach (int n in new[] { 1048575,1048576,1048577 }) {
                var output=new Artifacts();Action add=()=>output.Add(new Artifact {Kind="StageSql",Content=new string('x',n)});
                if(n<=1048576){add();Assert(output.Rows.Count==1,"SQL_OUTPUT_BYTES");}else RejectResourceLimit(add,"sqlArtifactBytes",(long)n*2,2097152);
            }
            foreach (int n in new[] { 4194303,4194304,4194305 }) {
                var output=new Artifacts();Action add=()=>output.Add(new Artifact {Kind="Workflow",Content=new string('x',n-1),Details="x"});
                if(n<=4194304){add();Assert(output.Rows.Count==1,"TOTAL_CONTENT_DETAILS_BYTES");}else RejectResourceLimit(add,"totalOutputBytes",(long)n*2,8388608);
            }
            foreach(int n in new[]{127,128,129}) {
                var safety=Safety(new SyntheticCatalog());Action parse=()=>{for(int i=0;i<n;i++)safety.Parse("SELECT "+i);};
                if(n<=128){parse();safety.Parse("SELECT 0");checks++;}else Reject(parse,"resource_limit");
            }
            // Der feste Command-Guard wird ohne Öffnen einer SQL-Verbindung geprüft.
            foreach(int n in new[]{127,128,129}) {
                var catalog=new SqlCatalog(new System.Data.SqlClient.SqlConnection(),new Budget());
                var command=typeof(SqlCatalog).GetMethod("Command",BindingFlags.Instance|BindingFlags.NonPublic);
                Action create=()=>{for(int i=0;i<n;i++){try{using(var c=(System.Data.SqlClient.SqlCommand)command.Invoke(catalog,new object[]{"SELECT 1"})) { }}catch(TargetInvocationException e){throw e.InnerException;}}};
                if(n<=128){create();checks++;}else Reject(create,"resource_limit");
            }
        }
        else if (args[0] == "json")
        {
            Assert(Json.Write(Json.Parse("{\"b\":true,\"a\":18446744073709551615}")) == "{\"a\":18446744073709551615,\"b\":true}", "EXACT_JSON");
            Reject(() => Json.Parse("{\"a\":1,\"a\":2}"), "invalid_template");
            Reject(() => Json.Parse("[01]"), "invalid_template");
            Reject(() => Json.Parse("\"\\uD800\""), "invalid_template");
            Assert(Json.Text(Json.Parse("\"\\uD83D\\uDE00\"")) == "\uD83D\uDE00", "SURROGATE_PAIR");
            var v = new Input { Type = "Int64", SqlType = "bigint" };
            Assert(Types.Literal(v, "9223372036854775807") == "9223372036854775807", "INT64_MAX");
            Reject(() => Types.Literal(v, "9223372036854775808"), "invalid_template");
            Reject(() => Types.Literal(v, new JsonNumber("9007199254740992")), "invalid_template");
        }
        else if (args[0] == "components-v2-branch")
        {
            var columns = new Dictionary<string, ExpressionValue> {
                { "Flag", new ExpressionValue { Sql = "m.[Flag]", Type = "bit", Nullable = true, Total = true, Predicate = "m.[Flag]" } },
                { "TextValue", new ExpressionValue { Sql = "m.[TextValue]", Type = "nvarchar(20)", Nullable = true, Total = true } },
                { "IntegerValue", new ExpressionValue { Sql = "m.[IntegerValue]", Type = "int", Nullable = true, Total = true } }
            };
            var literal = new ExpressionParser("TRUE?1:2", null, null, columns, null, true).Parse();
            Assert(literal.Total && !literal.Nullable && literal.Type == "int", "V2_TERNARY_LITERAL_BRANCHES_TOTAL");
            var textReference = new ExpressionParser("[Flag]?[TextValue]:\"fallback\"", null, null, columns, null, true).Parse();
            Assert(textReference.Total && textReference.Nullable && textReference.Type == "nvarchar(max)", "V2_TERNARY_NULLABLE_TEXT_REFERENCE_TOTAL");
            var integerReference = new ExpressionParser("[Flag]?[IntegerValue]:0", null, null, columns, null, true).Parse();
            Assert(integerReference.Total && integerReference.Nullable && integerReference.Type == "int", "V2_TERNARY_NULLABLE_INTEGER_REFERENCE_TOTAL");
            var failingArm = new ExpressionParser("TRUE?1:(DT_I4)\"bad\"", null, null, columns, null, true).Parse();
            Assert(!failingArm.Total, "V2_TERNARY_POTENTIALLY_FAILING_ARM_NOT_TOTAL");
        }
        else if (args[0] == "components-v2-utf8-collation")
        {
            byte[] original = File.ReadAllBytes(args[1]);
            byte[] package = Change(original, d => {
                foreach (var sql in d.Descendants("property").Where(x => (string)x.Attribute("name") == "SqlCommand"))
                    sql.Value = sql.Value.Replace("dbo.SyntheticSourceA", "dbo.SyntheticV2TextA").Replace("dbo.SyntheticSourceB", "dbo.SyntheticV2TextB").Replace("dbo.SyntheticLookup", "dbo.SyntheticV2TextLookup");
                foreach (var element in d.Descendants().Where(x => (x.Name == "outputColumn" || x.Name == "inputColumn" || x.Name == "externalMetadataColumn") && (string)x.Attribute("name") == "KeyA"))
                { element.SetAttributeValue("dataType", "wstr"); element.SetAttributeValue("length", "10"); if (element.Attribute("cachedDataType") != null) element.SetAttributeValue("cachedDataType", "wstr"); if (element.Attribute("cachedLength") != null) element.SetAttributeValue("cachedLength", "10"); }
                var derived = d.Descendants("component").Single(x => (string)x.Attribute("name") == "Derived"); derived.SetAttributeValue("version", "0");
                derived.Element("outputs").Element("output").SetAttributeValue("synchronousInputId", derived.Element("inputs").Element("input").Attribute("refId").Value);
                var split = d.Descendants("component").Single(x => (string)x.Attribute("name") == "Split"); split.SetAttributeValue("version", "0");
                foreach (var output in split.Element("outputs").Elements("output")) output.SetAttributeValue("synchronousInputId", split.Element("inputs").Element("input").Attribute("refId").Value);
            });
            string catalogJson = Json.Write(Json.Obj("schemaVersion", new JsonNumber("2"), "defaultDatabase", "AdventureWorks", "databases", new List<object> { "AdventureWorks" }, "connections", Json.Obj("Package.ConnectionManagers[Synthetic]", "AdventureWorks"), "flatFileInputs", Json.Obj()));
            var catalog = new SyntheticCatalog { TextKeys = true, NullableKeys = true, NullableKeyB = true, NullableLookupScore = true, TextKeyCollation = "Latin1_General_100_CI_AS_SC_UTF8" };
            string shortExpression = "((DT_STR,10,1252)[KeyA] == \"5\") ? 1 : 0";
            string left = "((DT_STR,10,1252)[KeyA] == (DT_STR,10,1252)\"5\") ? TRUE : FALSE";
            string right = "((DT_STR,10,1252)[KeyB] == (DT_STR,10,1252)\"7\") ? TRUE : FALSE";
            string group = "((" + left + ") && (" + right + "))";
            string longExpression = "(" + String.Join(" || ", Enumerable.Repeat(group, 256)) + ") ? 1 : 0";
            foreach (string expression in new[] { shortExpression, longExpression })
            {
                try
                {
                    byte[] variant = Change(package, d => d.Descendants("component").Single(x => (string)x.Attribute("name") == "Derived").Descendants("property").Single(x => (string)x.Attribute("name") == "Expression").Value = expression);
                    var templateOptions = Options("bindings-template"); templateOptions.ProjectContext = "{\"schemaVersion\":2}"; templateOptions.Version = 170;
                    string template = Engine.Analyze(variant, templateOptions, catalog, new Budget()).Rows.Single().Content;
                    var options = Options("explain"); options.ProjectContext = "{\"schemaVersion\":2}"; options.Version = 170; options.ComparisonCollation = "Latin1_General_100_BIN2"; options.Bindings = template; options.CatalogBindings = catalogJson;
                    var index = Engine.Analyze(variant, options, catalog, new Budget());
                    var selected = index.Rows.First(x => x.Kind == "StageIndex" && x.Component == "Package\\Flow\\Derived");
                    options.Target = selected.Target; options.Stage = selected.Stage;
                    var result = Engine.Analyze(variant, options, catalog, new Budget());
                    var planUnitsForWalk = result.Rows.Where(x => x.Kind == "PlanUnitSql").ToList();
                    if (planUnitsForWalk.Count > 0) { var walker = Safety(catalog); AssertWalkParity(walker, planUnitsForWalk[0].Content); AssertWalkParity(walker, planUnitsForWalk[planUnitsForWalk.Count - 1].Content); }
                    AssertWalkParity(Safety(catalog), "SELECT CASE WHEN EXISTS (SELECT 1 FROM (VALUES (1),(2)) AS v(x) WHERE v.x=1) THEN N'a' ELSE N'b' END AS [x];");
                    Assert(result.Rows.Any(x => x.Kind == "StageSql" && x.Stage == selected.Stage && x.Complete && x.Safety == "passed"), "V2_UTF8_DATABASE_COLLATION_STAGE_SQL:" + String.Join(",", result.Rows.Where(x => x.Kind == "Diagnostic").Select(x => x.Code + "/" + x.Component)));
                }
                catch (Exception error) { throw new Exception(expression == shortExpression ? "V2_UTF8_SHORT_VARIANT" : "V2_UTF8_LONG_VARIANT", error); }
            }
        }
        else if (args[0] == "components-v2")
        {
            byte[] original = File.ReadAllBytes(args[1]);
            var templateResult = Engine.Analyze(original, Options("bindings-template"), new SyntheticCatalog(), new Budget());
            var template = Json.Object(Json.Parse(templateResult.Rows.Single().Content));
            Assert(((JsonNumber)template["schemaVersion"]).Text == "2" && Json.Text(template["profile"]) == "ssis-debug-components-v2", "CURRENT_TEMPLATE_SCHEMA2_DEFAULT");
            Assert(!template.ContainsKey("resourcePolicy") && template.ContainsKey("values") && template.ContainsKey("availableInputs"), "CURRENT_TEMPLATE_VALUES_WITHOUT_RESOURCE_POLICY");
            var defaults = new long[] {134217728,134217728,1048576,262144,1048576,4096,8192,65536,8192,4194304,8388608,131072,4194304,262144,131072,8192,4096,4096,32768,65536,16384,2097152,134217728,0};
            var defaultValues = defaults.Select(x => new SqlInt64(x)).ToArray();
            var currentLimits = ResourceOptions.FromSqlParameters(defaultValues);
            Assert(currentLimits.IsV2 && currentLimits.Preset == "current" && currentLimits.Maximum("packageBytes") == 134217728 && currentLimits.IsUnlimitedCounter("analysisMilliseconds"), "CURRENT_SQL_PARAMETER_DEFAULTS");
            var parameterNames = new[] { "@MaxPackageBytes", "@MaxXmlCharacters", "@MaxXmlNodes", "@MaxModelNodes", "@MaxModelEdges", "@MaxComponents", "@MaxPaths", "@MaxColumns", "@MaxInputs", "@MaxJsonDocumentBytes", "@MaxAllJsonBytes", "@MaxJsonNodes", "@MaxExpressionBytes", "@MaxExpressionTokens", "@MaxExpressionNodes", "@MaxPlanUnits", "@MaxCatalogObjects", "@MaxCatalogQueries", "@MaxParserCalls", "@MaxArtifacts", "@MaxDiagnostics", "@MaxSqlArtifactBytes", "@MaxTotalOutputBytes", "@MaxAnalysisMilliseconds" };
            Assert(ResourceOptions.SqlParameterNames.SequenceEqual(parameterNames), "CURRENT_SQL_PARAMETER_ORDER");
            Assert(ResourceLimits.CounterNames.Count() == defaults.Length, "CURRENT_SQL_PARAMETER_COUNTER_COUNT");
            foreach (string counter in ResourceLimits.CounterNames)
            {
                int index = Array.IndexOf(ResourceLimits.CounterNames.ToArray(), counter);
                Assert(index >= 0, "CURRENT_SQL_LIMIT_COUNTER_MAP_" + counter);
                var values = defaults.Select(x => new SqlInt64(x)).ToArray(); values[index] = new SqlInt64(17);
                Assert(ResourceOptions.FromSqlParameters(values).Maximum(counter) == 17, "CURRENT_SQL_LIMIT_OVERRIDE_" + counter);
                values[index] = new SqlInt64(0);
                Assert(ResourceOptions.FromSqlParameters(values).IsUnlimitedCounter(counter), "CURRENT_SQL_LIMIT_ZERO_" + counter);
                values[index] = SqlInt64.Null; Reject(() => ResourceOptions.FromSqlParameters(values), "unresolved_binding");
                values[index] = new SqlInt64(-1); Reject(() => ResourceOptions.FromSqlParameters(values), "unresolved_binding");
            }
            bool contextV2;
            ResourceOptions.Parse("{\"schemaVersion\":2}", "explain", null, out contextV2);
            Assert(contextV2, "CURRENT_PROJECT_CONTEXT_SCHEMA2");
            Reject(() => ResourceOptions.Parse("{\"schemaVersion\":2,\"resourceOptions\":{}}", "explain", null, out contextV2), "invalid_template");
            bool legacyContextRejected = false; try { ResourceOptions.Parse("{\"schemaVersion\":1}", "explain", null, out contextV2); } catch (DebugFault error) { legacyContextRejected = error.Code == "invalid_template"; }
            Assert(legacyContextRejected, "CURRENT_PROJECT_CONTEXT_REQUIRES_SCHEMA2");
            bool resourceOptionsExplained = false; try { ResourceOptions.Parse("{\"schemaVersion\":2,\"resourceOptions\":{}}", "explain", null, out contextV2); } catch (DebugFault error) { resourceOptionsExplained = error.Message.Contains("@MaxPackageBytes") && error.Message.Contains("@MaxAnalysisMilliseconds"); }
            Assert(resourceOptionsExplained, "CURRENT_RESOURCE_OPTIONS_ERROR_NAMES_SQL_PARAMETERS");
            var inputs = Json.Array(template["availableInputs"]).Select(Json.Object).ToList();
            Assert(inputs.Any(x => Json.Bool(x, "defaultAvailable") && !Json.Bool(x, "sensitive")) && Json.Object(template["values"]).Count > 0, "CURRENT_DESIGN_DEFAULTS_EDITABLE");
            byte[] assignmentPackage = Change(original, d => {
                XNamespace dts = "www.microsoft.com/SqlServer/Dts";
                var variables = d.Root.Element(dts + "Variables"); if (variables == null) { variables = new XElement(dts + "Variables"); d.Root.Add(variables); }
                int id = 900;
                Action<string, string> addVariable = (name, value) => variables.Add(new XElement(dts + "Variable", new XAttribute(dts + "Namespace", "User"), new XAttribute(dts + "ObjectName", name), new XAttribute(dts + "DTSID", "{" + (++id).ToString("D8", CultureInfo.InvariantCulture) + "-1111-1111-1111-111111111111}"), new XElement(dts + "VariableValue", new XAttribute(dts + "DataType", "Int32"), value)));
                foreach (var item in new[] { new KeyValuePair<string,string>("Independent", "7"), new KeyValuePair<string,string>("ScriptWritten", "8"), new KeyValuePair<string,string>("LoopValue", "0"), new KeyValuePair<string,string>("LoopAttribute", "0"), new KeyValuePair<string,string>("ScriptAttribute", "0"), new KeyValuePair<string,string>("EmptyWriteList", "3"), new KeyValuePair<string,string>("ExpressionDefault", "42"), new KeyValuePair<string,string>("SqlResult", "0"), new KeyValuePair<string,string>("ForeachValue", "0") }) addVariable(item.Key, item.Value);
                var expressionDefault = variables.Elements(dts + "Variable").Single(x => (string)x.Attribute(dts + "ObjectName") == "ExpressionDefault");
                expressionDefault.SetAttributeValue(dts + "EvaluateAsExpression", "True"); expressionDefault.SetAttributeValue(dts + "Expression", "@[User::Independent] + 1");
                d.Root.Add(new XElement(dts + "Executable", new XAttribute(dts + "refId", "Package\\Tasks\\Script"), new XAttribute(dts + "ExecutableType", "Microsoft.ScriptTask"), new XElement(dts + "Property", new XAttribute(dts + "Name", "ReadWriteVariables"), "User::ScriptWritten")));
                d.Root.Add(new XElement(dts + "Executable", new XAttribute(dts + "refId", "Package\\Tasks\\Loop"), new XAttribute(dts + "ExecutableType", "STOCK:FORLOOP"), new XElement(dts + "Property", new XAttribute(dts + "Name", "AssignExpression"), "@[User::LoopValue] = @[User::LoopValue] + 1")));
                d.Root.Add(new XElement(dts + "Executable", new XAttribute(dts + "refId", "Package\\Tasks\\LoopAttribute"), new XAttribute(dts + "ExecutableType", "STOCK:FORLOOP"), new XAttribute(dts + "AssignExpression", "@[User::LoopAttribute] = 1")));
                d.Root.Add(new XElement(dts + "Executable", new XAttribute(dts + "refId", "Package\\Tasks\\ScriptAttribute"), new XAttribute(dts + "ExecutableType", "Microsoft.ScriptTask"), new XElement(dts + "ScriptTaskData", new XAttribute(dts + "ReadWriteVariables", "User::ScriptAttribute"))));
                d.Root.Add(new XElement(dts + "Executable", new XAttribute(dts + "refId", "Package\\Tasks\\ScriptEmpty"), new XAttribute(dts + "ExecutableType", "Microsoft.ScriptTask"), new XAttribute(dts + "ReadWriteVariables", "")));
                d.Root.Add(new XElement(dts + "Executable", new XAttribute(dts + "refId", "Package\\Tasks\\ScriptEmptyProperty"), new XAttribute(dts + "ExecutableType", "Microsoft.ScriptTask"), new XElement(dts + "Property", new XAttribute(dts + "Name", "ReadWriteVariables"), "")));
                d.Root.Add(new XElement(dts + "Executable", new XAttribute(dts + "refId", "Package\\Tasks\\ExecuteSql"), new XAttribute(dts + "ExecutableType", "Microsoft.ExecuteSQLTask"), new XElement(dts + "ObjectData", new XElement(dts + "ResultBindings", new XElement(dts + "ResultBinding", new XAttribute(dts + "VariableName", "User::SqlResult"))))));
                d.Root.Add(new XElement(dts + "Executable", new XAttribute(dts + "refId", "Package\\Tasks\\Foreach"), new XAttribute(dts + "ExecutableType", "STOCK:FOREACHLOOP"), new XElement(dts + "ObjectData", new XElement(dts + "VariableMappings", new XElement(dts + "VariableMapping", new XAttribute(dts + "VariableName", "User::ForeachValue"))))));
                d.Root.Add(new XElement(dts + "Executable", new XAttribute(dts + "refId", "Package\\Tasks\\UnknownScript"), new XAttribute(dts + "ExecutableType", "Microsoft.ScriptTask"), new XElement(dts + "Variables", new XElement(dts + "Variable", new XAttribute(dts + "Namespace", "User"), new XAttribute(dts + "ObjectName", "UnknownScriptValue"), new XAttribute(dts + "DTSID", "{bbbbbbbb-1111-1111-1111-111111111111}"), new XElement(dts + "VariableValue", new XAttribute(dts + "DataType", "Int32"), "9")))));
            });
            var assignmentModel = PackageDocument.Read(assignmentPackage, null, true);
            var exportedInputs = assignmentModel.Definitions.Where(x => x.Kind == "VARIABLE").ToDictionary(x => x.Name, StringComparer.Ordinal);
            Func<string, string, bool> hasProducerKind = (name, kind) => Json.Array(Json.Get(exportedInputs[name].Attributes, "assignmentProducers")).Any(x => Json.Text(Json.Get(Json.Object(x), "kind")) == kind);
            Assert(Json.Text(Json.Get(exportedInputs["Independent"].Attributes, "assignmentState")) == "unknown", "ASSIGNMENT_UNKNOWN_SCRIPT_EFFECTS_ARE_VISIBLE_SCOPE");
            Assert(Json.Text(Json.Get(exportedInputs["ScriptWritten"].Attributes, "assignmentState")) == "unknown" && hasProducerKind("ScriptWritten", "script-read-write-variable"), "ASSIGNMENT_SCRIPT_READWRITE_VARIABLE_AND_UNKNOWN_VISIBLE_WRITER");
            Assert(hasProducerKind("LoopValue", "for-loop-assignment-expression"), "ASSIGNMENT_FORLOOP_PROPERTY_TARGET");
            Assert(hasProducerKind("LoopAttribute", "for-loop-assignment-expression"), "ASSIGNMENT_FORLOOP_ATTRIBUTE_TARGET");
            Assert(hasProducerKind("ScriptAttribute", "script-read-write-variable"), "ASSIGNMENT_SCRIPT_READWRITE_ATTRIBUTE");
            Assert(hasProducerKind("SqlResult", "execute-sql-result"), "ASSIGNMENT_EXECUTESQL_RESULT_BINDING");
            Assert(hasProducerKind("ForeachValue", "foreach-variable-mapping"), "ASSIGNMENT_FOREACH_MAPPING");
            Assert(Json.Text(Json.Get(exportedInputs["UnknownScriptValue"].Attributes, "assignmentState")) == "unknown", "ASSIGNMENT_UNKNOWN_SCRIPT_SCOPE_REMAINS_UNKNOWN");
            var assignmentHostModel = assignmentModel.ExportComponentsV2("1.0.0", new string('0', 40), new string('0', 64));
            var hostIndependent = Json.Object(Json.Array(Json.Get(assignmentHostModel, "nodes")).Select(Json.Object).Single(x => String.Equals(Json.Get(x, "name") as string, "Independent", StringComparison.Ordinal))["attributes"]);
            Assert(Json.Text(Json.Get(hostIndependent, "assignmentState")) == Json.Text(Json.Get(exportedInputs["Independent"].Attributes, "assignmentState")) && Json.Text(Json.Get(hostIndependent, "assignmentState")) == "unknown", "ASSIGNMENT_CLR_AND_NEUTRAL_HOST_PARITY");
            var assignmentTemplate = Engine.Analyze(assignmentPackage, Options("bindings-template"), new SyntheticCatalog(), new Budget());
            var assignmentTemplateDoc = Json.Object(Json.Parse(assignmentTemplate.Rows.Single().Content));
            var independentMetadata = Json.Object(Json.Array(Json.Get(assignmentTemplateDoc, "availableInputs")).Single(x => Json.Text(Json.Get(Json.Object(x), "name")) == "User::Independent"));
            Assert(Json.Bool(independentMetadata, "defaultAvailable") && Json.Text(Json.Get(independentMetadata, "assignmentState")) == "unknown" && Json.Text(Json.Get(independentMetadata, "state")) == "runtime-assigned-design-default", "ASSIGNMENT_UNKNOWN_SCRIPT_PRESERVES_DESIGN_DEFAULT_PROVENANCE");
            var expressionDefaultMetadata = Json.Object(Json.Array(Json.Get(assignmentTemplateDoc, "availableInputs")).Single(x => Json.Text(Json.Get(Json.Object(x), "name")) == "User::ExpressionDefault"));
            var expressionDefaultKey = Json.Text(Json.Get(expressionDefaultMetadata, "key"));
            Assert(Json.Bool(expressionDefaultMetadata, "defaultAvailable") && Json.Text(Json.Get(expressionDefaultMetadata, "state")) == "derived" && Json.Get(Json.Object(assignmentTemplateDoc["values"]), expressionDefaultKey) == null, "ASSIGNMENT_EXPRESSION_DESIGN_DEFAULT_VISIBLE_NOT_AUTOBINDING");
            byte[] emptyWriteListPackage = Change(assignmentPackage, d => { XNamespace assignmentDts = "www.microsoft.com/SqlServer/Dts"; d.Root.Elements(assignmentDts + "Executable").Single(x => (string)x.Attribute(assignmentDts + "refId") == "Package\\Tasks\\UnknownScript").Remove(); });
            var emptyWriteListModel = PackageDocument.Read(emptyWriteListPackage, null, true);
            var emptyWriteListVariable = emptyWriteListModel.Definitions.Single(x => x.Kind == "VARIABLE" && x.Name == "EmptyWriteList");
            var emptyIndependentVariable = emptyWriteListModel.Definitions.Single(x => x.Kind == "VARIABLE" && x.Name == "Independent");
            Assert(Json.Text(Json.Get(emptyWriteListVariable.Attributes, "assignmentState")) == "none" && Json.Text(Json.Get(emptyIndependentVariable.Attributes, "assignmentState")) == "none", "ASSIGNMENT_EXPLICIT_EMPTY_SCRIPT_LIST_IS_KNOWN_EMPTY");
            var roundtrip = Options("explain"); roundtrip.Bindings = Json.Write(template); roundtrip.Limits = currentLimits;
            var currentExplain = Engine.Analyze(original, roundtrip, new SyntheticCatalog(), new Budget());
            Assert(currentExplain.Rows.Any(x => x.Kind == "Workflow"), "CURRENT_TEMPLATE_ROUNDTRIP");
            byte[] currentCompletePackage = Change(original, d => {
                var derivedComplete = d.Descendants("component").Single(x => (string)x.Attribute("name") == "Derived");
                derivedComplete.SetAttributeValue("version", "0"); derivedComplete.Element("outputs").Element("output").SetAttributeValue("synchronousInputId", derivedComplete.Element("inputs").Element("input").Attribute("refId").Value);
                var split = d.Descendants("component").Single(x => (string)x.Attribute("name") == "Split"); string splitInput = split.Element("inputs").Element("input").Attribute("refId").Value; split.SetAttributeValue("version", "0");
                foreach (var output in split.Element("outputs").Elements("output")) output.SetAttributeValue("synchronousInputId", splitInput);
            });
            var currentCompleteTemplate = Engine.Analyze(currentCompletePackage, Options("bindings-template"), new SyntheticCatalog(), new Budget());
            var currentCompleteOptions = Options("explain"); currentCompleteOptions.Bindings = currentCompleteTemplate.Rows.Single().Content;
            var currentComplete = Engine.Analyze(currentCompletePackage, currentCompleteOptions, new SyntheticCatalog(), new Budget());
            var currentScript = currentComplete.Rows.Single(x => x.Kind == "DebugScript" && x.Target == "f0001");
            Assert(currentScript.Executable && currentScript.Complete && currentScript.Safety == "passed" && currentScript.Content.Contains("\nGO\n"), "CURRENT_DEBUG_SCRIPT_COMPLETE_AND_BATCHED");
            var currentScriptDetails = Json.Object(Json.Parse(currentScript.Details));
            Assert(Json.Text(Json.Get(currentScriptDetails, "status")) == "complete" && !Json.Bool(currentScriptDetails, "sssisTasksExecuted"), "CURRENT_DEBUG_SCRIPT_PROVENANCE");
            var scriptBatches = Json.Array(Json.Get(currentScriptDetails, "batches")).Select(Json.Object).ToList();
            bool scriptBatchPinsValid = scriptBatches.Count > 0;
            for (int batchIndex = 0; batchIndex < scriptBatches.Count && scriptBatchPinsValid; batchIndex++)
            {
                var batch = scriptBatches[batchIndex];
                int sequence = Int32.Parse(((JsonNumber)Json.Get(batch, "sequence")).Text, CultureInfo.InvariantCulture);
                int ordinal = Int32.Parse(((JsonNumber)Json.Get(batch, "resultOrdinal")).Text, CultureInfo.InvariantCulture);
                var sourceArtifact = currentComplete.Rows.Single(a => a.Ordinal == ordinal);
                scriptBatchPinsValid = sequence == batchIndex + 1 && sourceArtifact.Kind == Json.Text(Json.Get(batch, "artifactKind")) &&
                    Util.Hash(sourceArtifact.Content) == Json.Text(Json.Get(batch, "contentSha256")) && currentScript.Content.Contains(sourceArtifact.Content.TrimEnd());
            }
            Assert(scriptBatchPinsValid && Json.Text(Json.Get(currentScriptDetails, "batchSeparator")) == "GO" && Json.Bool(currentScriptDetails, "freshSessionRequired") && Json.Bool(currentScriptDetails, "cleanupAfterPartialFailure"), "CURRENT_DEBUG_SCRIPT_BATCH_ORDER_AND_CONTENT_BINDING");
            byte[] missingCommandPackage = Change(original, d => {
                XNamespace dts = "www.microsoft.com/SqlServer/Dts";
                var variables = d.Root.Element(dts + "Variables"); if (variables == null) { variables = new XElement(dts + "Variables"); d.Root.Add(variables); }
                variables.Add(new XElement(dts + "Variable", new XAttribute(dts + "Namespace", "User"), new XAttribute(dts + "ObjectName", "CommandText"), new XAttribute(dts + "DTSID", "{aaaaaaaa-1111-1111-1111-111111111111}")));
                var source = d.Descendants("component").Single(x => (string)x.Attribute("name") == "SourceA");
                var properties = source.Element("properties"); properties.Elements("property").Single(x => (string)x.Attribute("name") == "AccessMode").Value = "3";
                properties.Add(new XElement("property", new XAttribute("name", "SqlCommandVariable"), "User::CommandText"));
            });
            var missingCommandTemplate = Engine.Analyze(missingCommandPackage, Options("bindings-template"), new SyntheticCatalog(), new Budget());
            var missingCommandOptions = Options("explain"); missingCommandOptions.Bindings = missingCommandTemplate.Rows.Single().Content;
            var missingCommand = Engine.Analyze(missingCommandPackage, missingCommandOptions, new SyntheticCatalog(), new Budget());
            Assert(!missingCommand.Rows.Any(x => (x.Kind == "TargetSql" || x.Kind == "DebugScript") && x.Executable) && missingCommand.Rows.Any(x => x.Kind == "DebugScript" && !x.Executable), "MISSING_COMMAND_TEXT_NEVER_BECOMES_EXECUTABLE");
            Assert(missingCommand.Rows.Any(x => x.Kind == "Diagnostic" && x.Code == "unresolved_binding" && x.Content.Contains("Command-Text")) && missingCommand.Rows.Any(x => x.Kind == "Diagnostic" && x.Code == "partial_target" && x.Content.Contains("Erstursache unresolved_binding")), "PARTIAL_TARGET_PRESERVES_ROOT_CAUSE");
            var blockedPath = Json.Array(Json.Get(Json.Object(Json.Parse(missingCommand.Rows.Single(x => x.Kind == "Workflow" && x.Target == "f0001").Details)), "stages"));
            Assert(blockedPath.Count > 1 && Json.Array(Json.Get(Json.Object(Json.Parse(missingCommand.Rows.Single(x => x.Kind == "DebugScript" && x.Target == "f0001").Details)), "missingInputs")).Any(x => Json.Text(Json.Get(Json.Object(x), "name")) == "User::CommandText"), "BLOCKED_PATH_AND_MISSING_INPUT_ARE_EXPLICIT");
            var injectedPolicy = Json.Object(Json.Parse(Json.Write(template))); injectedPolicy.Add("resourcePolicy", ResourceLimits.CreateCurrent().Metadata()); roundtrip.Bindings = Json.Write(injectedPolicy);
            Reject(() => Engine.Analyze(original, roundtrip, new SyntheticCatalog(), new Budget()), "invalid_template");
            Reject(() => Engine.Analyze(original, Options("bindings-template-v2"), new SyntheticCatalog(), new Budget()), "unresolved_binding");
            byte[] v2ExpressionPackage = Change(original, d => {
                var component = d.Descendants("component").Single(x => (string)x.Attribute("name") == "Derived");
                component.Element("outputs").Element("output").SetAttributeValue("synchronousInputId", component.Element("inputs").Element("input").Attribute("refId").Value);
                component.Descendants("outputColumn").Single().Descendants("property").Single(x => (string)x.Attribute("name") == "Expression").Value = "LEN(\"x  \")";
                var split = d.Descendants("component").Single(x => (string)x.Attribute("name") == "Split"); string splitInput = split.Element("inputs").Element("input").Attribute("refId").Value;
                foreach (var output in split.Element("outputs").Elements("output")) output.SetAttributeValue("synchronousInputId", splitInput);
            });
            var v2ExpressionTemplate = Engine.Analyze(v2ExpressionPackage, Options("bindings-template"), new SyntheticCatalog(), new Budget());
            var v2ExplainOptions = Options("explain"); v2ExplainOptions.Bindings = v2ExpressionTemplate.Rows[0].Content;
            var v2Explain = Engine.Analyze(v2ExpressionPackage, v2ExplainOptions, new SyntheticCatalog(), new Budget());
            Assert(v2Explain.Rows.Any(x => x.Kind == "PlanUnitSql" && x.Content.Contains("LEN(N'x  ' + N'.') - 1")), "V2_DERIVED_EXPRESSION_TRANSLATION");
            var inspectAllOptions = Options("explain"); inspectAllOptions.Target = "f0001"; inspectAllOptions.Stage = "all"; inspectAllOptions.Bindings = v2ExpressionTemplate.Rows[0].Content;
            var inspectAllV2 = Engine.Analyze(v2ExpressionPackage, inspectAllOptions, new SyntheticCatalog(), new Budget());
            var inspectTargetSql = inspectAllV2.Rows.Single(x => x.Kind == "TargetSql" && x.Target == "f0001");
            var inspectSameStageSql = inspectAllV2.Rows.Single(x => x.Kind == "StageSql" && x.Target == "f0001" && x.Stage == inspectTargetSql.Stage);
            var inspectManifest = Json.Object(Json.Parse(inspectAllV2.Rows.Single(x => x.Kind == "PlanManifest" && x.Target == "f0001" && x.Stage == inspectTargetSql.Stage).Content));
            string inspectPlanHash = Json.Text(inspectManifest["planHash"]);
            int inspectManifestUnits = Json.Array(inspectManifest["units"]).Count, inspectTargetUnits = inspectAllV2.Rows.Count(x => x.Kind == "PlanUnitSql" && x.Target == "f0001" && Json.Text(Json.Object(Json.Parse(x.Details))["planHash"]) == inspectPlanHash);
            Assert(inspectTargetSql.Content == inspectSameStageSql.Content && inspectAllV2.Rows.Count(x => x.Kind == "PlanManifest" && x.Target == "f0001" && x.Stage == inspectTargetSql.Stage) == 1 && inspectManifestUnits == inspectTargetUnits, "V2_INSPECT_ALL_REUSES_ONE_TARGET_PLAN_AND_MANIFEST content=" + (inspectTargetSql.Content == inspectSameStageSql.Content).ToString() + " manifestUnits=" + inspectManifestUnits.ToString(CultureInfo.InvariantCulture) + " planUnits=" + inspectTargetUnits.ToString(CultureInfo.InvariantCulture));
            string firstV2UnitSql = v2Explain.Rows.First(x => x.Kind == "PlanUnitSql").Content;
            var stateMissingMatch = System.Text.RegularExpressions.Regex.Match(firstV2UnitSql, @"IF @tbx_ps\w+ IS NULL THROW 50000, N'TBX_SSISDBG_plan_state:");
            int stateMissingGuard = stateMissingMatch.Success ? stateMissingMatch.Index : -1;
            int stateShapeRead = firstV2UnitSql.IndexOf("STRING_AGG(", StringComparison.Ordinal);
            int transactionGuard = firstV2UnitSql.IndexOf("IF @@TRANCOUNT <> 0 OR (@@OPTIONS & 2) <> 0", StringComparison.Ordinal);
            int planStateCreate = firstV2UnitSql.IndexOf("CREATE TABLE [#tbx_SsisDebug_Plan_", StringComparison.Ordinal);
            Assert(stateMissingGuard > 0 && stateShapeRead > stateMissingGuard, "V2_MISSING_PLANSTATE_GUARDED_BEFORE_SHAPE_READ");
            Assert(transactionGuard > 0 && planStateCreate > transactionGuard, "V2_INITIAL_MUTATION_REJECTS_CALLER_TRANSACTION_FIRST");
            bool planBench = args.Length > 2 && args[2].StartsWith("planbench:", StringComparison.Ordinal);
            int longBooleanTerms = planBench ? Int32.Parse(args[2].Substring("planbench:".Length), CultureInfo.InvariantCulture) : 16 * 2729 + 1;
            string branchTerm = "((DT_STR,10,1252)[KeyA] == (DT_STR,10,1252)\"5\") ? TRUE : FALSE";
            string branchTerm2 = "((DT_STR,10,1252)[KeyB] == (DT_STR,10,1252)\"7\") ? TRUE : FALSE";
            string branchGroup = "((" + branchTerm + ") && (" + branchTerm2 + "))";
            string longBoolean = planBench ? String.Join(" || ", Enumerable.Repeat(branchGroup, longBooleanTerms)) : String.Join(" && ", Enumerable.Repeat("TRUE", longBooleanTerms));
            if (planBench && longBoolean.Length < 1440000) longBoolean += new string(' ', 1440000 - longBoolean.Length);
            string longPlanContext = "{\"schemaVersion\":2}";
            var longPlanLimits = ResourceLimits.CreateCurrent(new Dictionary<string, long> { { "expressionNodes", 524288 }, { "totalOutputBytes", 536870912 }, { "analysisMilliseconds", 120000 } });
            var benchmarkColumns = new Dictionary<string, ExpressionValue> { { "KeyA", new ExpressionValue { Sql = "m.[KeyA]", Type = "int", Nullable = true, Total = true } }, { "KeyB", new ExpressionValue { Sql = "m.[KeyB]", Type = "int", Total = true } } };
            var longParser = new ExpressionParser(longBoolean, null, null, benchmarkColumns, null, true, cp => cp == 1252 ? "Latin1_General_100_BIN2" : null, ResourceLimits.Create("large10x", true, new Dictionary<string, string> { { "expressionNodes", "524288" } }));
            var longValue = longParser.Parse(); int exactTokens = longParser.ParsedTokenCount, exactNodes = longParser.ParsedNodeCount, exactExpressionBytes = longBoolean.Length * 2;
            Assert((planBench || longBoolean.Length > 16384) && longValue.Type == "bit" && longValue.BooleanTerms.Count == longBooleanTerms, "V2_LONG_BOOLEAN_EXPRESSION_REMAINS_STRUCTURED_UNTIL_PLAN_LOWERING");
            byte[] longBooleanPackage = Change(v2ExpressionPackage, d => d.Descendants("component").Single(x => (string)x.Attribute("name") == "Derived").Descendants("property").Single(x => (string)x.Attribute("name") == "Expression").Value = longBoolean);
            var planWatch = System.Diagnostics.Stopwatch.StartNew();
            var longBooleanExplain = ExplainV2(longBooleanPackage, "f0001", longPlanContext, new SyntheticCatalog { NullableKeys = true }, longPlanLimits);
            planWatch.Stop();
            if (planBench) { var planUnits = longBooleanExplain.Rows.Where(x => x.Kind == "PlanUnitSql").ToList(); Console.WriteLine("SSIS_V2_PLAN_BENCH terms=" + longBooleanTerms.ToString(CultureInfo.InvariantCulture) + " expressionUtf16Bytes=" + (longBoolean.Length * 2L).ToString(CultureInfo.InvariantCulture) + " units=" + planUnits.Count.ToString(CultureInfo.InvariantCulture) + " sqlUtf16Bytes=" + longBooleanExplain.Rows.Sum(x => (long)x.Content.Length * 2L).ToString(CultureInfo.InvariantCulture) + " maxUnitUtf16Bytes=" + (planUnits.Count == 0 ? 0L : planUnits.Max(x => (long)x.Content.Length * 2L)).ToString(CultureInfo.InvariantCulture) + " ms=" + planWatch.ElapsedMilliseconds.ToString(CultureInfo.InvariantCulture)); return; }
            Assert(longBooleanExplain.Rows.Any(x => x.Kind == "TargetSql" && x.Complete) && longBooleanExplain.Rows.Count(x => x.Kind == "PlanUnitSql") >= 2730 && longBooleanExplain.Rows.Where(x => x.Kind == "PlanUnitSql").All(x => x.Executable && x.Safety == "passed"), "V2_2730_UNIT_BOOLEAN_PLAN_PASSES_PER_UNIT_SQL_SAFETY");
            foreach (var boundary in new[] { new KeyValuePair<string, int>("expressionBytes", exactExpressionBytes), new KeyValuePair<string, int>("expressionTokens", exactTokens), new KeyValuePair<string, int>("expressionNodes", exactNodes) })
            {
                foreach (int delta in new[] { -1, 0, 1 })
                {
                    int maximum = boundary.Value + delta; var overrides = new Dictionary<string, string> { { boundary.Key, maximum.ToString(CultureInfo.InvariantCulture) } };
                    if (boundary.Key != "expressionNodes") overrides.Add("expressionNodes", exactNodes.ToString(CultureInfo.InvariantCulture));
                    var limits = ResourceLimits.Create("large10x", true, overrides);
                    Action parseLong = () => new ExpressionParser(longBoolean, null, null, new Dictionary<string, ExpressionValue>(), null, true, null, limits).Parse();
                    if (delta < 0) Reject(parseLong, "resource_limit"); else parseLong();
                }
            }
            byte[] missingVersion = Change(original, d => {
                var component = d.Descendants("component").First(x => (string)x.Attribute("componentClassID") == "Microsoft.DerivedColumn");
                component.Attribute("version").Remove(); component.Element("outputs").Element("output").SetAttributeValue("synchronousInputId", component.Element("inputs").Element("input").Attribute("refId").Value);
            });
            var model = PackageDocument.Read(missingVersion, null, true);
            var derived = model.Definitions.Single(x => x.Kind == "COMPONENT" && x.Get("componentClassID") == "Microsoft.DerivedColumn");
            Assert(derived.ComponentKind == "derived" && derived.ComponentVersion == 0 && !derived.ComponentVersionPresent && derived.ComponentVersionOrigin == "schema-default-0", "V2_SCHEMA_DEFAULT_PROVENANCE");
            var exported = model.ExportComponentsV2("1.0.0", new string('0', 40), new string('0', 64));
            Assert(Json.Text(exported["contract"]) == "ssis-package-model-components-v2", "V2_EXPORT_CONTRACT");
            byte[] qualifiedPorts = Change(original, d => {
                var component = d.Descendants("component").Single(x => (string)x.Attribute("name") == "Derived");
                var input = component.Element("inputs").Element("input"); var output = component.Element("outputs").Element("output");
                component.Attribute("version").Remove(); output.SetAttributeValue("synchronousInputId", input.Attribute("refId").Value);
                component.Element("outputs").Add(new XElement("output", new XAttribute("refId", "Package\\Flow\\Derived.output[Error]"), new XAttribute("name", "Renamed error"), new XAttribute("isErrorOut", "true"), new XAttribute("synchronousInputId", input.Attribute("refId").Value)));
                var components = d.Descendants("components").Single(); components.Add(new XElement("component", new XAttribute("refId", "Package\\Flow\\FlatSource"), new XAttribute("name", "FlatSource"), new XAttribute("componentClassID", "Microsoft.FlatFileSource"), new XAttribute("version", "1"), new XElement("inputs"), new XElement("outputs", new XElement("output", new XAttribute("refId", "Package\\Flow\\FlatSource.output[Rows]"), new XAttribute("name", "Renamed rows"), new XAttribute("synchronousInputId", "0")), new XElement("output", new XAttribute("refId", "Package\\Flow\\FlatSource.output[Error]"), new XAttribute("name", "Renamed error"), new XAttribute("isErrorOut", "true"), new XAttribute("synchronousInputId", "0")))));
            });
            var portModel = PackageDocument.Read(qualifiedPorts, null, true);
            var derivedWithError = portModel.Definitions.Single(x => x.Kind == "COMPONENT" && x.Name == "Derived");
            var flatSource = portModel.Definitions.Single(x => x.Kind == "COMPONENT" && x.Name == "FlatSource");
            Assert(derivedWithError.ComponentKind == "derived" && flatSource.ComponentKind == "flatfile-source", "V2_NORMAL_AND_ERROR_PORT_PROFILES");
            var derivedPortRoles = portModel.Definitions.Where(x => x.Kind == "PORT" && x.Parent == derivedWithError.Id && Json.Text(x.Attributes["direction"]) == "OUTPUT").Select(x => Json.Text(x.Attributes["portRole"])).OrderBy(x => x, StringComparer.Ordinal).ToArray();
            Assert(derivedPortRoles.SequenceEqual(new[] { "ERROR", "NORMAL" }), "V2_PORT_ROLE_FROM_FLAG_AND_RENAMED_NAME");
            byte[] badDerivedSync = Change(qualifiedPorts, d => d.Descendants("component").Single(x => (string)x.Attribute("name") == "Derived").Element("outputs").Element("output").SetAttributeValue("synchronousInputId", "not-the-input"));
            var badSyncModel = PackageDocument.Read(badDerivedSync, null, true);
            Assert(badSyncModel.Definitions.Single(x => x.Kind == "COMPONENT" && x.Name == "Derived").ComponentKind == "unsupported", "V2_BAD_SYNC_MAPPING_REJECTED");
            byte[] badErrorFlag = Change(qualifiedPorts, d => d.Descendants("component").Single(x => (string)x.Attribute("name") == "FlatSource").Element("outputs").Elements("output").Last().SetAttributeValue("isErrorOut", "not-a-boolean"));
            var badFlagModel = PackageDocument.Read(badErrorFlag, null, true);
            Assert(badFlagModel.Definitions.Single(x => x.Kind == "COMPONENT" && x.Name == "FlatSource").ComponentKind == "unsupported", "V2_BAD_ERROR_FLAG_REJECTED");
            byte[] duplicateNormal = Change(qualifiedPorts, d => {
                var component = d.Descendants("component").Single(x => (string)x.Attribute("name") == "Derived");
                var normal = component.Element("outputs").Element("output"); var clone = new XElement(normal); clone.SetAttributeValue("refId", "Package\\Flow\\Derived.output[Extra]"); clone.SetAttributeValue("name", "Yet another normal"); component.Element("outputs").Add(clone);
            });
            Assert(PackageDocument.Read(duplicateNormal, null, true).Definitions.Single(x => x.Kind == "COMPONENT" && x.Name == "Derived").ComponentKind == "unsupported", "V2_MULTIPLE_NORMAL_PORTS_REJECTED");
            byte[] rowCountPackage = Change(original, d => {
                XNamespace dts = "www.microsoft.com/SqlServer/Dts";
                var variables = d.Root.Element(dts + "Variables");
                if (variables == null) throw new Exception("ROWCOUNT_PACKAGE_VARIABLES_MISSING");
                variables.Add(new XElement(dts + "Variable", new XAttribute(dts + "Namespace", "User"), new XAttribute(dts + "ObjectName", "RowsProcessed"), new XAttribute(dts + "DTSID", "{11111111-1111-1111-1111-000000000099}"), new XElement(dts + "VariableValue", new XAttribute(dts + "DataType", "Int32"), "0")));
                var pipeline = d.Descendants("pipeline").Single(); var split = pipeline.Descendants("component").Single(x => (string)x.Attribute("name") == "Split");
                var derivedForRowCount = pipeline.Descendants("component").Single(x => (string)x.Attribute("name") == "Derived");
                derivedForRowCount.Element("outputs").Element("output").SetAttributeValue("synchronousInputId", derivedForRowCount.Element("inputs").Element("input").Attribute("refId").Value);
                string splitInputId = split.Element("inputs").Element("input").Attribute("refId").Value;
                foreach (var splitOutput in split.Element("outputs").Elements("output")) splitOutput.SetAttributeValue("synchronousInputId", splitInputId);
                if (pipeline.Element("components") == null || pipeline.Element("paths") == null) throw new Exception("ROWCOUNT_PIPELINE_STRUCTURE_MISSING");
                var high = split.Element("outputs").Elements("output").First(x => (string)x.Attribute("name") == "High");
                if (high.Element("outputColumns") == null) throw new Exception("ROWCOUNT_SPLIT_OUTPUT_COLUMNS_MISSING");
                var rowInputId = "Package\\Flow\\RowCount.input[Input]"; var rowOutputId = "Package\\Flow\\RowCount.output[Rows]";
                var inputColumns = new XElement("inputColumns"); var outputColumns = new XElement("outputColumns");
                foreach (var outputColumn in high.Element("outputColumns").Elements("outputColumn")) {
                    string id = (string)outputColumn.Attribute("refId"), name = (string)outputColumn.Attribute("name"), type = (string)outputColumn.Attribute("dataType");
                    inputColumns.Add(new XElement("inputColumn", new XAttribute("refId", rowInputId + ".Columns[" + name + "]"), new XAttribute("name", name), new XAttribute("dataType", type), new XAttribute("lineageId", id), new XElement("properties")));
                    var clonedOutput = new XElement(outputColumn); clonedOutput.SetAttributeValue("refId", rowOutputId + ".Columns[" + name + "]"); outputColumns.Add(clonedOutput);
                }
                var rowCount = new XElement("component", new XAttribute("refId", "Package\\Flow\\RowCount"), new XAttribute("name", "RowCount"), new XAttribute("componentClassID", "Microsoft.RowCount"),
                    new XElement("properties", new XElement("property", new XAttribute("name", "VariableName"), "User::RowsProcessed")),
                    new XElement("inputs", new XElement("input", new XAttribute("refId", rowInputId), new XAttribute("name", "Input"), new XElement("properties"), inputColumns)),
                    new XElement("outputs", new XElement("output", new XAttribute("refId", rowOutputId), new XAttribute("name", "Rows"), new XAttribute("synchronousInputId", rowInputId), new XElement("properties"), outputColumns)));
                pipeline.Element("components").Add(rowCount);
                pipeline.Element("paths").Elements("path").Single(x => (string)x.Attribute("refId") == "path6").SetAttributeValue("startId", rowOutputId);
                pipeline.Element("paths").Add(new XElement("path", new XAttribute("refId", "pathRowCount"), new XAttribute("startId", (string)high.Attribute("refId")), new XAttribute("endId", rowInputId)));
            });
            var rowCountModel = PackageDocument.Read(rowCountPackage, null, true);
            var rowCountDefinition = rowCountModel.Definitions.Single(x => x.Kind == "COMPONENT" && x.Name == "RowCount");
            Assert(rowCountDefinition.ComponentKind == "rowcount", "V2_ROWCOUNT_PROFILE_ACCEPTED " + rowCountDefinition.ComponentKind);
            var rowCountVariableDefinition = rowCountModel.Definitions.Single(x => x.Kind == "VARIABLE" && x.Name == "RowsProcessed");
            Assert(Json.Text(Json.Get(rowCountVariableDefinition.Attributes, "assignmentState")) == "declared" && Json.Text(Json.Get(Json.Object(Json.Array(Json.Get(rowCountVariableDefinition.Attributes, "assignmentProducers")).Single()), "kind")) == "row-count-variable", "ASSIGNMENT_ROWCOUNT_PRODUCER");
            var rowCountTemplateOptions = Options("bindings-template");
            var rowCountTemplate = Engine.Analyze(rowCountPackage, rowCountTemplateOptions, new SyntheticCatalog(), new Budget());
            var rowCountTemplateDoc = Json.Object(Json.Parse(rowCountTemplate.Rows.Single().Content));
            string rowCountVariableKey = Json.Text(Json.Object(Json.Array(Json.Get(rowCountTemplateDoc, "availableInputs")).Single(x => Json.Text(Json.Get(Json.Object(x), "name")) == "User::RowsProcessed"))["key"]);
            var rowCountExplainOptions = Options("explain"); rowCountExplainOptions.Bindings = rowCountTemplate.Rows.Single().Content;
            var rowCountExplain = Engine.Analyze(rowCountPackage, rowCountExplainOptions, new SyntheticCatalog(), new Budget());
            var rowCountSql = rowCountExplain.Rows.FirstOrDefault(x => x.Kind == "RowCountSql");
            Assert(rowCountSql != null && rowCountSql.Content.Contains("COUNT_BIG(*)") && !rowCountSql.Content.Contains("SET @" + rowCountVariableKey), "V2_ROWCOUNT_COUNT_BIG_NO_VARIABLE_WRITE");
            Assert(rowCountSql.Complete && rowCountExplain.Rows.Any(x => x.Kind == "TargetSql" && x.Target == rowCountSql.Target && x.Complete) && rowCountExplain.Rows.Any(x => x.Kind == "Workflow" && x.Target == rowCountSql.Target && x.Complete) && rowCountExplain.Rows.Any(x => x.Kind == "PlanUnitSql" && x.Target == rowCountSql.Target), "V2_ROWCOUNT_AND_PROJECTION_USE_VALIDATED_SHARED_PLAN");
            var rowCountDetails = Json.Object(Json.Parse(rowCountSql.Details));
            Assert(Json.Text(rowCountDetails["targetVariable"]) == "User::RowsProcessed" && Json.Text(rowCountDetails["assignmentTiming"]) == "after-last-row" && Json.Bool(rowCountDetails, "snapshotSharedWithProjection") && Json.Bool(rowCountDetails, "executeWithPlanArtifact"), "V2_ROWCOUNT_TYPED_TARGET_AND_POST_FLOW_EFFECT");
            var rowDebugScript = rowCountExplain.Rows.Single(x => x.Kind == "DebugScript" && x.Target == rowCountSql.Target);
            var rowDebugBatches = Json.Array(Json.Get(Json.Object(Json.Parse(rowDebugScript.Details)), "batchOrder")).Select(Json.Text).ToList();
            int rowTargetBatch = rowDebugBatches.FindIndex(x => x.StartsWith("TargetSql:", StringComparison.Ordinal)), rowCountBatch = rowDebugBatches.FindIndex(x => x.StartsWith("RowCountSql:", StringComparison.Ordinal)), cleanupBatch = rowDebugBatches.FindIndex(x => x.StartsWith("CleanupSql:", StringComparison.Ordinal));
            Assert(rowDebugScript.Executable && rowDebugScript.Complete && rowTargetBatch >= 0 && rowTargetBatch < rowCountBatch && rowCountBatch < cleanupBatch, "V2_DEBUG_SCRIPT_TARGET_COUNT_CLEANUP_ORDER");
            Assert(rowCountSql.Content.Contains("BETWEEN -2147483648 AND 2147483647"), "V2_ROWCOUNT_INT32_RANGE_GUARD");
            byte[] rowCountUnknown = Change(rowCountPackage, d => d.Descendants("component").Single(x => (string)x.Attribute("name") == "RowCount").Descendants("property").Single(x => (string)x.Attribute("name") == "VariableName").Value = "User::Unknown");
            Assert(ExplainV2(rowCountUnknown).Rows.Any(x => x.Kind == "Diagnostic" && x.Code == "missing_context" && x.Component == "Package\\Flow\\RowCount"), "V2_ROWCOUNT_UNKNOWN_VARIABLE_REJECTED");
            byte[] rowCountReadonly = Change(rowCountPackage, d => d.Root.Element((XNamespace)"www.microsoft.com/SqlServer/Dts" + "Variables").Elements((XNamespace)"www.microsoft.com/SqlServer/Dts" + "Variable").Single(x => (string)x.Attribute((XNamespace)"www.microsoft.com/SqlServer/Dts" + "ObjectName") == "RowsProcessed").SetAttributeValue((XNamespace)"www.microsoft.com/SqlServer/Dts" + "ReadOnly", "true"));
            Assert(ExplainV2(rowCountReadonly).Rows.Any(x => x.Kind == "Diagnostic" && x.Code == "missing_context" && x.Component == "Package\\Flow\\RowCount"), "V2_ROWCOUNT_READONLY_VARIABLE_REJECTED");
            byte[] rowCountFloat = Change(rowCountPackage, d => d.Root.Element((XNamespace)"www.microsoft.com/SqlServer/Dts" + "Variables").Elements((XNamespace)"www.microsoft.com/SqlServer/Dts" + "Variable").Single(x => (string)x.Attribute((XNamespace)"www.microsoft.com/SqlServer/Dts" + "ObjectName") == "RowsProcessed").Element((XNamespace)"www.microsoft.com/SqlServer/Dts" + "VariableValue").SetAttributeValue((XNamespace)"www.microsoft.com/SqlServer/Dts" + "DataType", "Double"));
            Assert(ExplainV2(rowCountFloat).Rows.Any(x => x.Kind == "Diagnostic" && x.Code == "missing_context" && x.Component == "Package\\Flow\\RowCount"), "V2_ROWCOUNT_NONINTEGER_VARIABLE_REJECTED");
            byte[] flatFilePackage = Change(original, d => {
                var pipeline = d.Descendants("pipeline").Single(); var components = pipeline.Element("components");
                string connectionId = "Package.ConnectionManagers[FlatInput]", targetConnectionId = "Package.ConnectionManagers[FlatOutput]", sourceId = "Package\\Flow\\FlatSource", normalId = sourceId + ".output[Rows]", errorId = sourceId + ".output[Error]";
                XNamespace dts = d.Root.Name.Namespace;
                d.Root.Element(dts + "ConnectionManagers").Add(new XElement(dts + "ConnectionManager", new XAttribute(dts + "refId", connectionId), new XAttribute(dts + "CreationName", "FLATFILE"), new XAttribute(dts + "ObjectName", "FlatInput")));
                d.Root.Element(dts + "ConnectionManagers").Add(new XElement(dts + "ConnectionManager", new XAttribute(dts + "refId", targetConnectionId), new XAttribute(dts + "CreationName", "FLATFILE"), new XAttribute(dts + "ObjectName", "FlatOutput")));
                var outputColumns = new XElement("outputColumns"); var destinationColumns = new XElement("inputColumns"); var destinationExternal = new XElement("externalMetadataColumns");
                var errorOutputColumns = new XElement("outputColumns"); var errorDestinationColumns = new XElement("inputColumns"); var errorDestinationExternal = new XElement("externalMetadataColumns");
                foreach (string name in new[] { "KeyA", "Amount" }) {
                    string outputColumnId = normalId + ".Columns[" + name + "]", destinationInputId = "Package\\Flow\\FlatTarget.input[Input].Columns[" + name + "]", externalId = "Package\\Flow\\FlatTarget.input[Input].External[" + name + "]";
                    outputColumns.Add(new XElement("outputColumn", new XAttribute("refId", outputColumnId), new XAttribute("name", name), new XAttribute("dataType", "i4"), new XAttribute("cachedDataType", "i4"), new XAttribute("lineageId", outputColumnId), new XElement("properties")));
                    destinationColumns.Add(new XElement("inputColumn", new XAttribute("refId", destinationInputId), new XAttribute("name", name), new XAttribute("dataType", "i4"), new XAttribute("lineageId", outputColumnId), new XAttribute("externalMetadataColumnId", externalId), new XElement("properties")));
                    destinationExternal.Add(new XElement("externalMetadataColumn", new XAttribute("refId", externalId), new XAttribute("name", name), new XAttribute("dataType", "i4")));
                    string errorColumnId = errorId + ".Columns[" + name + "]", errorInputId = "Package\\Flow\\FlatErrorTarget.input[Input].Columns[" + name + "]", errorExternalId = "Package\\Flow\\FlatErrorTarget.input[Input].External[" + name + "]";
                    errorOutputColumns.Add(new XElement("outputColumn", new XAttribute("refId", errorColumnId), new XAttribute("name", name), new XAttribute("dataType", "i4"), new XAttribute("cachedDataType", "i4"), new XAttribute("lineageId", errorColumnId), new XElement("properties")));
                    errorDestinationColumns.Add(new XElement("inputColumn", new XAttribute("refId", errorInputId), new XAttribute("name", name), new XAttribute("dataType", "i4"), new XAttribute("lineageId", errorColumnId), new XAttribute("externalMetadataColumnId", errorExternalId), new XElement("properties")));
                    errorDestinationExternal.Add(new XElement("externalMetadataColumn", new XAttribute("refId", errorExternalId), new XAttribute("name", name), new XAttribute("dataType", "i4")));
                }
                var flatSourceComponent = new XElement("component", new XAttribute("refId", sourceId), new XAttribute("name", "FlatSource"), new XAttribute("componentClassID", "Microsoft.FlatFileSource"), new XAttribute("version", "1"),
                    new XElement("properties", new XElement("property", new XAttribute("name", "Format"), "Delimited"), new XElement("property", new XAttribute("name", "HeaderRowDelimiter"), "CRLF")),
                    new XElement("connections", new XElement("connection", new XAttribute("connectionManagerRefId", connectionId))), new XElement("inputs"),
                    new XElement("outputs", new XElement("output", new XAttribute("refId", normalId), new XAttribute("name", "Rows"), new XAttribute("synchronousInputId", "0"), new XElement("properties"), outputColumns, new XElement("externalMetadataColumns")),
                        new XElement("output", new XAttribute("refId", errorId), new XAttribute("name", "Renamed error"), new XAttribute("isErrorOut", "true"), new XAttribute("synchronousInputId", "0"), new XElement("properties"), errorOutputColumns, new XElement("externalMetadataColumns"))));
                var targetInputId = "Package\\Flow\\FlatTarget.input[Input]";
                var flatTarget = new XElement("component", new XAttribute("refId", "Package\\Flow\\FlatTarget"), new XAttribute("name", "FlatTarget"), new XAttribute("componentClassID", "Microsoft.FlatFileDestination"),
                    new XElement("properties", new XElement("property", new XAttribute("name", "Format"), "Delimited"), new XElement("property", new XAttribute("name", "Header"), "true"), new XElement("property", new XAttribute("name", "Overwrite"), "false")),
                    new XElement("connections", new XElement("connection", new XAttribute("connectionManagerRefId", targetConnectionId))),
                    new XElement("inputs", new XElement("input", new XAttribute("refId", targetInputId), new XAttribute("name", "Input"), new XElement("properties"), destinationColumns, destinationExternal)), new XElement("outputs"));
                var errorTargetInputId = "Package\\Flow\\FlatErrorTarget.input[Input]";
                var flatErrorTarget = new XElement("component", new XAttribute("refId", "Package\\Flow\\FlatErrorTarget"), new XAttribute("name", "FlatErrorTarget"), new XAttribute("componentClassID", "Microsoft.FlatFileDestination"),
                    new XElement("properties"), new XElement("connections", new XElement("connection", new XAttribute("connectionManagerRefId", targetConnectionId))), new XElement("inputs", new XElement("input", new XAttribute("refId", errorTargetInputId), new XAttribute("name", "Input"), new XElement("properties"), errorDestinationColumns, errorDestinationExternal)), new XElement("outputs"));
                components.Add(flatSourceComponent); components.Add(flatTarget); components.Add(flatErrorTarget);
                pipeline.Element("paths").Add(new XElement("path", new XAttribute("refId", "pathFlatSource"), new XAttribute("startId", normalId), new XAttribute("endId", targetInputId)));
                pipeline.Element("paths").Add(new XElement("path", new XAttribute("refId", "pathFlatError"), new XAttribute("startId", errorId), new XAttribute("endId", errorTargetInputId)));
            });
            string flatSourceId = "Package\\Flow\\FlatSource.output[Rows].Columns[KeyA]", flatAmountId = "Package\\Flow\\FlatSource.output[Rows].Columns[Amount]";
            var flatBindings = Json.Write(Json.Obj("schemaVersion", new JsonNumber("2"), "defaultDatabase", "AdventureWorks", "databases", new List<object> { "AdventureWorks" },
                "connections", Json.Obj("Package.ConnectionManagers[Synthetic]", "AdventureWorks"),
                "flatFileInputs", Json.Obj("Package.ConnectionManagers[FlatInput]", Json.Obj("database", "AdventureWorks", "schema", "dbo", "object", "SyntheticFlatFileRows", "columns", Json.Obj(flatSourceId, "KeyA", flatAmountId, "Amount")))));
            Json.Parse(flatBindings); checks++;
            var flatTemplateOptions = Options("bindings-template"); flatTemplateOptions.ProjectContext = "{\"schemaVersion\":2}";
            string flatTemplate = Engine.Analyze(flatFilePackage, flatTemplateOptions, new SyntheticCatalog(), new Budget()).Rows.Single().Content;
            var flatExplainOptions = Options("explain"); flatExplainOptions.ProjectContext = "{\"schemaVersion\":2}";
            flatExplainOptions.Bindings = flatTemplate; flatExplainOptions.CatalogBindings = flatBindings;
            var flatExplain = Engine.Analyze(flatFilePackage, flatExplainOptions, new SyntheticCatalog(), new Budget());
            var flatWrite = flatExplain.Rows.FirstOrDefault(x => x.Kind == "FlatFileWriteProjection" && x.Component == "Package\\Flow\\FlatTarget");
            Assert(flatWrite != null && !flatWrite.Executable && !flatWrite.Complete, "V2_FLATFILE_TARGET_IS_METADATA_ONLY");
            var flatDebugSql = flatExplain.Rows.FirstOrDefault(x => x.Kind == "TargetSql" && x.Component == "Package\\Flow\\FlatTarget");
            Assert(flatDebugSql != null && flatDebugSql.Executable && flatDebugSql.Complete && flatExplain.Rows.Any(x => x.Kind == "PlanUnitSql" && x.Content.Contains("SyntheticFlatFileRows")), "V2_FLATFILE_TARGET_EMITS_READONLY_RELATIONAL_PROJECTION");
            var flatSqlDetails = Json.Object(Json.Parse(flatDebugSql.Details));
            Assert(Json.Text(flatSqlDetails["targetMode"]) == "flatfile-debug-projection" && !Json.Bool(flatSqlDetails, "fileWriteSimulated"), "V2_FLATFILE_PROJECTION_EXPLICIT_NO_FILE_WRITE");
            var flatWriteJson = Json.Object(Json.Parse(flatWrite.Content));
            Assert(Json.Text(flatWriteJson["mode"]) == "metadata-only-no-file-write" && Json.Array(flatWriteJson["columns"]).Count == 2 && flatWrite.Content.Contains("Header"), "V2_FLATFILE_PROJECTED_COLUMNS_AND_FORMAT_PROPERTIES");
            Assert(flatExplain.Rows.Any(x => x.Kind == "Diagnostic" && x.Code == "missing_context" && x.Component == "Package\\Flow\\FlatSource"), "V2_FLATFILE_ERROR_PORT_REQUIRES_EXPLICIT_ERROR_ROWS");
            if (args.Length > 2)
            {
                string exportRoot = Path.GetFullPath(args[2]);
                if (!exportRoot.Contains(Path.DirectorySeparatorChar + ".runtime" + Path.DirectorySeparatorChar)) throw new Exception("V2_FIXTURE_EXPORT_OUTSIDE_RUNTIME");
                string context2 = "{\"schemaVersion\":2}";
                var rowTemplateOptions = Options("bindings-template"); rowTemplateOptions.ProjectContext = context2;
                string rowTemplate = Engine.Analyze(rowCountPackage, rowTemplateOptions, new SyntheticCatalog(), new Budget()).Rows.Single().Content;
                string rowCatalog = Json.Write(Json.Obj("schemaVersion", new JsonNumber("2"), "defaultDatabase", "AdventureWorks", "databases", new List<object> { "AdventureWorks" }, "connections", Json.Obj("Package.ConnectionManagers[Synthetic]", "AdventureWorks")));
                ExportSyntheticFixture(exportRoot, "rowcount", rowCountPackage, context2, rowTemplate, rowCatalog);
                ExportSyntheticFixture(exportRoot, "flatfile", flatFilePackage, "{\"schemaVersion\":2}", flatTemplate, flatBindings);
                byte[] variableStringPackage = Change(original, d => {
                    foreach (var element in d.Descendants().Where(x => (x.Name == "outputColumn" || x.Name == "inputColumn" || x.Name == "externalMetadataColumn") && (string)x.Attribute("name") == "KeyA"))
                    {
                        element.SetAttributeValue("dataType", "wstr"); element.SetAttributeValue("length", "10");
                        if (element.Attribute("cachedDataType") != null) element.SetAttributeValue("cachedDataType", "wstr");
                        if (element.Attribute("cachedLength") != null) element.SetAttributeValue("cachedLength", "10");
                    }
                    var derivedComponentXml = d.Descendants("component").Single(x => (string)x.Attribute("name") == "Derived");
                    derivedComponentXml.SetAttributeValue("version", "0");
                    derivedComponentXml.Element("outputs").Element("output").SetAttributeValue("synchronousInputId", derivedComponentXml.Element("inputs").Element("input").Attribute("refId").Value);
                    derivedComponentXml.Descendants("property").Single(x => (string)x.Attribute("name") == "Expression").Value = "(DT_STR,10,1252)[KeyA] == \"x\" ? 1 : 0";
                    var splitComponentXml = d.Descendants("component").Single(x => (string)x.Attribute("name") == "Split");
                    splitComponentXml.SetAttributeValue("version", "0");
                    foreach (var splitOutput in splitComponentXml.Element("outputs").Elements("output")) splitOutput.SetAttributeValue("synchronousInputId", splitComponentXml.Element("inputs").Element("input").Attribute("refId").Value);
                });
                string variableCatalog = Json.Write(Json.Obj("schemaVersion", new JsonNumber("2"), "defaultDatabase", "AdventureWorks", "databases", new List<object> { "AdventureWorks" }, "connections", Json.Obj("Package.ConnectionManagers[Synthetic]", "AdventureWorks"), "flatFileInputs", Json.Obj()));
                var variableTemplateOptions = Options("bindings-template"); variableTemplateOptions.ProjectContext = "{\"schemaVersion\":2}";
                string variableTemplate = Engine.Analyze(variableStringPackage, variableTemplateOptions, new SyntheticCatalog { TextKeys = true }, new Budget()).Rows.Single().Content;
                var variableExplainOptions = Options("explain"); variableExplainOptions.ProjectContext = "{\"schemaVersion\":2}"; variableExplainOptions.Bindings = variableTemplate; variableExplainOptions.CatalogBindings = variableCatalog;
                var variableExplain = Engine.Analyze(variableStringPackage, variableExplainOptions, new SyntheticCatalog { TextKeys = true }, new Budget());
                Assert(variableExplain.Rows.Any(x => x.Kind == "TargetSql" && x.Complete) && variableExplain.Rows.Where(x => x.Kind == "PlanUnitSql").All(x => x.Executable && x.Safety == "passed"), "V2_VARIABLE_STRING_CAST_PLAN_SYNTHETIC:" + String.Join(",", variableExplain.Rows.Where(x => x.Kind == "Diagnostic").Select(x => x.Code + "/" + x.Component)));
                ExportSyntheticFixture(exportRoot, "variable-string", variableStringPackage, "{\"schemaVersion\":2}", variableTemplate, variableCatalog);
            }
            byte[] emptyVersion = Change(original, d => d.Descendants("component").First(x => (string)x.Attribute("componentClassID") == "Microsoft.DerivedColumn").SetAttributeValue("version", ""));
            Reject(() => PackageReader.Read(emptyVersion, new Budget(), true), "invalid_lineage");
            var parser = new ExpressionParser("NULL(DT_WSTR,10)", null, null, new Dictionary<string, ExpressionValue>(), null, true);
            var typedNull = parser.Parse(); Assert(typedNull.Type == "nvarchar(10)" && typedNull.Nullable && typedNull.Sql == "CAST(NULL AS nvarchar(10))", "V2_TYPED_NULL");
            var numericNull = new ExpressionParser("NULL(DT_NUMERIC,10,2)", null, null, new Dictionary<string, ExpressionValue>(), null, true).Parse();
            Assert(numericNull.Type == "decimal(10,2)" && numericNull.Nullable, "V2_TYPED_NUMERIC_NULL");
            Assert(new ExpressionParser("NULL(DT_NUMERIC,10,0)", null, null, new Dictionary<string, ExpressionValue>(), null, true).Parse().Type == "decimal(10,0)", "V2_TYPED_NUMERIC_ZERO_SCALE");
            Reject(() => new ExpressionParser("NULL(DT_I4,1)", null, null, new Dictionary<string, ExpressionValue>(), null, true).Parse(), "unsupported_expression");
            Reject(() => new ExpressionParser("(DT_WSTR)\"x\"", null, null, new Dictionary<string, ExpressionValue>(), null, true).Parse(), "unsupported_expression");
            var ansiNull = new ExpressionParser("NULL(DT_STR,10,1252)", null, null, new Dictionary<string, ExpressionValue>(), null, true, cp => cp == 1252 ? "Latin1_General_100_BIN2" : null).Parse();
            Assert(ansiNull.Type == "varchar(10)" && ansiNull.Nullable && ansiNull.Sql.Contains("COLLATE Latin1_General_100_BIN2"), "V2_TYPED_ANSI_NULL_ROOT");
            Reject(() => new ExpressionParser("TRIM(NULL(DT_STR,10,1252))", null, null, new Dictionary<string, ExpressionValue>(), null, true, cp => cp == 1252 ? "Latin1_General_100_BIN2" : null).Parse(), "unsupported_expression");
            var ansiValue = new ExpressionParser("(DT_STR,2,1252)\"éé\"", null, null, new Dictionary<string, ExpressionValue>(), null, true, cp => cp == 1252 ? "Latin1_General_100_BIN2" : null).Parse();
            Assert(ansiValue.Type == "varchar(2)" && ansiValue.Sql.Contains("CONVERT(varchar(2), (CONVERT(nvarchar(max), N'éé') COLLATE Latin1_General_100_BIN2))"), "V2_DT_STR_COLLATION_BEFORE_BYTE_CONVERSION");
            var nullableIntegerReference = new ExpressionValue { Sql = "m.[SyntheticInteger]", Type = "int", Nullable = true, Total = true };
            var integerStringCast = new ExpressionParser("(DT_STR,10,1252)[KeyA] == (DT_STR,10,1252)\"5\"", null, null, new Dictionary<string, ExpressionValue> { { "KeyA", nullableIntegerReference } }, null, true, cp => cp == 1252 ? "Latin1_General_100_BIN2" : null).Parse();
            Assert(integerStringCast.Type == "bit" && integerStringCast.Nullable && integerStringCast.Total && integerStringCast.Sql.Contains("CONVERT(nvarchar(max), m.[SyntheticInteger])"), "V2_INNER_INTEGER_DT_STR_IS_WIDENED_AND_NULLABLE_TOTAL");
            var ansiNested = new ExpressionParser("TRIM((DT_STR,2,1252)\"éé\")", null, null, new Dictionary<string, ExpressionValue>(), null, true, cp => cp == 1252 ? "Latin1_General_100_BIN2" : null).Parse();
            Assert(ansiNested.Type == "nvarchar(max)" && !ansiNested.Sql.Contains("varchar(2)") && ansiNested.Sql.Contains("TRIM(CONVERT(nvarchar(max), N'éé'))"), "V2_NESTED_DT_STR_WIDENS_BEFORE_TRUNCATION");
            var innerAnsiColumn = new ExpressionParser("(DT_STR,1,1252)[Value] == \"雪\"", null, null, new Dictionary<string, ExpressionValue> { { "Value", new ExpressionValue { Sql = "[Value]", Type = "varchar(20)", Total = true } } }, null, true, cp => cp == 1252 ? "Latin1_General_100_BIN2" : null).Parse();
            Assert(innerAnsiColumn.Total && innerAnsiColumn.Sql.Contains("CONVERT(nvarchar(max), [Value])") && !innerAnsiColumn.Sql.Contains("CONVERT(varchar(1)"), "V2_INNER_DT_STR_WIDENING_IS_NOT_ANSI_BYTE_CONVERSION");
            var nonTextAnsiCast = new ExpressionParser("(DT_STR,10,1252)[Value]", null, null, new Dictionary<string, ExpressionValue> { { "Value", new ExpressionValue { Sql = "[Value]", Type = "int", Total = true } } }, null, true, cp => cp == 1252 ? "Latin1_General_100_BIN2" : null).Parse();
            Assert(!nonTextAnsiCast.Total, "V2_INNER_DT_STR_NON_TEXT_COERCION_NOT_ASSUMED_TOTAL");
            Assert(new ExpressionParser("(DT_I1)127", null, null, new Dictionary<string, ExpressionValue>(), null, true).Parse().Type == "smallint", "V2_I1_LITERAL_IN_RANGE");
            Reject(() => new ExpressionParser("(DT_I1)128", null, null, new Dictionary<string, ExpressionValue>(), null, true).Parse(), "unsupported_expression");
            Reject(() => new ExpressionParser("(DT_I1)[Value]", null, null, new Dictionary<string, ExpressionValue> { { "Value", new ExpressionValue { Sql = "[Value]", Type = "int" } } }, null, true).Parse(), "unsupported_expression");
            Reject(() => new ExpressionParser("(DT_UI1)TRUE", null, null, new Dictionary<string, ExpressionValue>(), null, true).Parse(), "unsupported_expression");
            var len = new ExpressionParser("LEN(\"x  \" )", null, null, new Dictionary<string, ExpressionValue>(), null, true).Parse();
            Assert(len.Type == "int" && len.Sql.Contains("LEN(") && len.Sql.Contains("N'.') - 1"), "V2_LEN_TRAILING_SPACES");
            Assert(new ExpressionParser("TRIM(\" x \" )", null, null, new Dictionary<string, ExpressionValue>(), null, true).Parse().Sql.StartsWith("TRIM(", StringComparison.Ordinal), "V2_TRIM_SPACE_PROFILE");
            Assert(new ExpressionParser("(DT_I4)TRUE", null, null, new Dictionary<string, ExpressionValue>(), null, true).Parse().Sql.Contains("THEN -1"), "V2_TRUE_NUMERIC_MINUS_ONE");
            Assert(new ExpressionParser("(DT_I4)FALSE", null, null, new Dictionary<string, ExpressionValue>(), null, true).Parse().Sql.Contains("THEN 0"), "V2_FALSE_NUMERIC_ZERO");
            var nullConditional = new ExpressionParser("NULL(DT_BOOL)?1:2", null, null, new Dictionary<string, ExpressionValue>(), null, true).Parse();
            Assert(nullConditional.Nullable && nullConditional.Sql.Contains("WHEN NOT (") && nullConditional.Sql.Contains("ELSE CAST(NULL AS int)"), "V2_CONDITIONAL_UNKNOWN_IS_TYPED_NULL");
            var trueConditional = new ExpressionParser("TRUE?1:(1/0)", null, null, new Dictionary<string, ExpressionValue>(), null, true).Parse();
            Assert(trueConditional.Sql.StartsWith("CASE WHEN ", StringComparison.Ordinal) && trueConditional.Sql.Contains("THEN 1 WHEN NOT (") && trueConditional.Sql.Contains("THEN (1 / 0)"), "V2_CONDITIONAL_BRANCHES_STAY_LAZY_CASE_ARMS");
            var falseConditional = new ExpressionParser("FALSE?(1/0):2", null, null, new Dictionary<string, ExpressionValue>(), null, true).Parse();
            Assert(falseConditional.Sql.Contains("THEN (1 / 0) WHEN NOT (") && falseConditional.Sql.Contains("THEN 2 ELSE CAST(NULL AS int)"), "V2_FALSE_CONDITIONAL_SELECTS_NO_ARM");
            Reject(() => new ExpressionParser("NULL(DT_BOOL)?1:2", null, null, new Dictionary<string, ExpressionValue>(), null, false).Parse(), "unsupported_expression");
            var substringZero = new ExpressionParser("SUBSTRING(\"abc\",1,0)", null, null, new Dictionary<string, ExpressionValue>(), null, true).Parse();
            Assert(substringZero.Sql.Contains("SUBSTRING(") && substringZero.Sql.Contains(", 0)"), "V2_SUBSTRING_ZERO_LENGTH");
            Assert(new ExpressionParser("REPLACE(\"abc\",NULL,\"x\")", null, null, new Dictionary<string, ExpressionValue>(), null, true).Parse().Nullable, "V2_REPLACE_NULL_PROPAGATION");
            Reject(() => new ExpressionParser("SUBSTRING(\"abc\",0,1)", null, null, new Dictionary<string, ExpressionValue>(), null, true).Parse(), "unsupported_expression");
            Reject(() => new ExpressionParser("REPLACE(\"abc\",\"\",\"x\")", null, null, new Dictionary<string, ExpressionValue>(), null, true).Parse(), "unsupported_expression");
            string exactBytes = "1" + new string(' ', 2097151);
            Assert(new ExpressionParser(exactBytes, null, null, new Dictionary<string, ExpressionValue>(), null, true).Parse().Type == "int", "V2_EXPRESSION_BYTES_EXACT");
            try { new ExpressionParser("1" + new string(' ', 2097152), null, null, new Dictionary<string, ExpressionValue>(), null, true); throw new Exception("V2_EXPRESSION_BYTE_LIMIT_NOT_REJECTED"); }
            catch (DebugFault error) { Assert(error.Code == "resource_limit" && error.Message.Contains("counter=expressionBytes") && error.Message.Contains("limit=4194304"), "V2_EXPRESSION_BYTES_DIAGNOSTIC"); }
            Assert(ExpressionParser.References(String.Join(" ", Enumerable.Repeat("@x", 262144)), true).Count() == 262144, "V2_EXPRESSION_TOKENS_EXACT");
            Reject(() => ExpressionParser.References(String.Join(" ", Enumerable.Repeat("@x", 262145)), true).ToList(), "resource_limit");
            var ansi = new ExpressionParser("(DT_STR,10,1252)\"abc\"", null, null, new Dictionary<string, ExpressionValue>(), null, true, cp => cp == 1252 ? "Latin1_General_100_BIN2" : null).Parse();
            Assert(ansi.Type == "varchar(10)" && ansi.Sql.Contains("COLLATE Latin1_General_100_BIN2"), "V2_DT_STR_CODEPAGE_BOUND");
            Reject(() => new ExpressionParser("(DT_STR,10,65001)\"abc\"", null, null, new Dictionary<string, ExpressionValue>(), null, true, cp => null).Parse(), "unresolved_binding");
            var safe = Safety(new SyntheticCatalog());
            safe.Generated("SELECT " + nullConditional.Sql + " AS [V]", "AdventureWorks", new string[0], true);
            safe.Generated("SELECT " + trueConditional.Sql + " AS [V]", "AdventureWorks", new string[0], true);
            safe.Generated("SELECT " + falseConditional.Sql + " AS [V]", "AdventureWorks", new string[0], true);
            safe.Generated("SELECT REPLACE(TRIM(N' a '), N'a', N'b'), CAST(CONVERT(nvarchar(max), N'x') AS varchar(1)) COLLATE Latin1_General_100_BIN2", "AdventureWorks", new string[0], true);
            safe.Generated("SELECT CONVERT(varchar(2), (CONVERT(nvarchar(max), N'éé') COLLATE Latin1_General_100_BIN2))", "AdventureWorks", new string[0], true);
            Reject(() => safe.Read("SELECT REPLACE(N'a', N'b', N'c')", "AdventureWorks"), "unsafe_statement");
        }
        else if (args[0] == "v1-boundaries")
        {
            foreach (int n in new[] { 4095,4096,4097 }) { string s = String.Concat(Enumerable.Repeat("x ",n)); if(n<=4096){SqlSafety.Guard(s);checks++;}else Reject(()=>SqlSafety.Guard(s),"resource_limit"); }
            foreach (int n in new[] { 65535,65536,65537 }) { string s = new string(' ',n); if(n<=65536){SqlSafety.Guard(s);checks++;}else Reject(()=>SqlSafety.Guard(s),"resource_limit"); }
            foreach (int n in new[] { 31,32,33 }) { string s = new string('(',n)+"1"+new string(')',n); if(n<=32){SqlSafety.Guard(s);checks++;}else Reject(()=>SqlSafety.Guard(s),"resource_limit"); }
            foreach (int n in new[] { 15,16,17 }) { string s = String.Concat(Enumerable.Repeat("/*",n))+"x"+String.Concat(Enumerable.Repeat("*/",n)); if(n<=16){SqlSafety.Guard(s);checks++;}else Reject(()=>SqlSafety.Guard(s),"resource_limit"); }
            foreach (int n in new[] { 255,256,257 }) { string s = String.Concat(Enumerable.Repeat("1+",n))+"1"; if(n<=256){SqlSafety.Guard(s);checks++;}else Reject(()=>SqlSafety.Guard(s),"resource_limit"); }
            foreach (int n in new[] { 63,64,65 }) { string s = String.Concat(Enumerable.Repeat("SELECT 1 UNION ALL ",n))+"SELECT 1"; if(n<=64){SqlSafety.Guard(s);checks++;}else Reject(()=>SqlSafety.Guard(s),"resource_limit"); }
            foreach(int n in new[]{31,32,33}) {string s=new string('[',n)+"0"+new string(']',n);if(n<=32){Json.Parse(s);checks++;}else Reject(()=>Json.Parse(s),"resource_limit");}
            foreach(int n in new[]{2097151,2097152,2097153}) {string s="\""+new string('x',n-2)+"\"";if(n<=2097152){Json.Parse(s);checks++;}else Reject(()=>Json.Parse(s),"resource_limit");}
            byte[] original=File.ReadAllBytes(args[1]);
            foreach(int n in new[]{16777215,16777216,16777217}) {var b=new byte[n];Buffer.BlockCopy(original,0,b,0,original.Length);for(int i=original.Length;i<n;i++)b[i]=32;if(n<=16777216){PackageReader.Read(b,new Budget());checks++;}else Reject(()=>PackageReader.Read(b,new Budget()),"resource_limit");}
            string xml=Encoding.UTF8.GetString(original).Replace("encoding='utf-8'","encoding='utf-16'").Replace("encoding=\"utf-8\"","encoding=\"utf-16\"");
            Assert(PackageReader.Read(Encoding.Unicode.GetPreamble().Concat(Encoding.Unicode.GetBytes(xml)).ToArray(),new Budget()).Flows.Count==1,"UTF16_PROFILE");
            Reject(()=>PackageReader.Read(Encoding.UTF8.GetBytes("<!DOCTYPE x [<!ENTITY x 'x'>]>"+Encoding.UTF8.GetString(original).Replace("<?xml version='1.0' encoding='utf-8'?>","")),new Budget()),"unsupported_package_format");
            byte[] duplicate=Change(original,d=>{var cs=d.Descendants("component").ToList();cs[1].SetAttributeValue("refId",cs[0].Attribute("refId").Value);});
            Reject(()=>PackageReader.Read(duplicate,new Budget()),"invalid_lineage");
            XNamespace ns="www.microsoft.com/SqlServer/Dts";
            byte[] sensitive=Change(original,d=>d.Descendants(ns+"Variable").First().SetAttributeValue(ns+"Sensitive","true"));
            var redacted=Engine.Analyze(sensitive,Options("bindings-template"),new SyntheticCatalog(),new Budget());
            var template=Json.Object(Json.Parse(redacted.Rows[0].Content));var metadata=Json.Object(Json.Array(template["availableInputs"])[0]);
            Assert((bool)metadata["sensitive"] && metadata["defaultValue"]==null && !Json.Object(template["values"]).ContainsKey("v0001"),"SENSITIVE_REDACTED");
        }
        else if (args[0] == "v1-graph-boundaries")
        {
            byte[] original=File.ReadAllBytes(args[1]);XNamespace ns="www.microsoft.com/SqlServer/Dts";
            foreach(int n in new[]{511,512,513}){
                byte[] b=Change(original,d=>{var cs=d.Descendants("components").Single();while(cs.Elements().Count()<n){int i=cs.Elements().Count();cs.Add(new XElement("component",new XAttribute("refId","SyntheticExtra"+i),new XAttribute("componentClassID","Synthetic.Unconnected"),new XAttribute("version",1),new XElement("inputs"),new XElement("outputs")));}});
                if(n<=512){Assert(PackageReader.Read(b,new Budget()).Flows[0].Components.Count==n,"COMPONENT_LIMIT_ACCEPT");}else Reject(()=>PackageReader.Read(b,new Budget()),"resource_limit");
            }
            foreach(int n in new[]{2047,2048,2049}){
                byte[] b=Change(original,d=>{var vs=d.Root.Element(ns+"Variables");while(vs.Elements().Count()<n){int i=vs.Elements().Count();vs.Add(new XElement(ns+"Variable",new XAttribute(ns+"Namespace","User"),new XAttribute(ns+"ObjectName","SyntheticInput"+i),new XElement(ns+"VariableValue",new XAttribute(ns+"DataType",3),"0")));}});
                if(n<=2048){Assert(PackageReader.Read(b,new Budget()).Inputs.Count==n,"INPUT_LIMIT_ACCEPT");}else Reject(()=>PackageReader.Read(b,new Budget()),"resource_limit");
            }
            foreach(int n in new[]{8191,8192,8193}){
                byte[] b=Change(original,d=>{int count=d.Descendants().Count(x=>x.Name=="inputColumn"||x.Name=="outputColumn"||x.Name=="externalMetadataColumn");var cols=new XElement("outputColumns");for(int i=count;i<n;i++)cols.Add(new XElement("outputColumn",new XAttribute("refId","SyntheticColumn"+i),new XAttribute("name","C"+i),new XAttribute("lineageId","SyntheticColumn"+i),new XAttribute("dataType","i4")));d.Descendants("components").Single().Add(new XElement("component",new XAttribute("refId","SyntheticCarrier"),new XAttribute("componentClassID","Synthetic.Unconnected"),new XAttribute("version",1),new XElement("inputs"),new XElement("outputs",new XElement("output",new XAttribute("refId","SyntheticColumnsOut"),cols))));});
                if(n<=8192){PackageReader.Read(b,new Budget());checks++;}else Reject(()=>PackageReader.Read(b,new Budget()),"resource_limit");
            }
            foreach(int n in new[]{2047,2048,2049}){
                byte[] b=Change(original,d=>{var paths=d.Descendants("paths").Single();var inputs=d.Descendants("component").Single(c=>(string)c.Attribute("name")=="Union").Element("inputs");string source=d.Descendants("path").First().Attribute("startId").Value;while(paths.Elements().Count()<n){int i=paths.Elements().Count();string id="SyntheticInputPort"+i;inputs.Add(new XElement("input",new XAttribute("refId",id),new XElement("inputColumns")));paths.Add(new XElement("path",new XAttribute("refId","SyntheticPath"+i),new XAttribute("startId",source),new XAttribute("endId",id)));}});
                if(n<=2048){PackageReader.Read(b,new Budget());checks++;}else Reject(()=>PackageReader.Read(b,new Budget()),"resource_limit");
            }
            foreach(int n in new[]{127,128,129}){
                byte[] b=Change(original,d=>{var p=new XElement("SyntheticDepth");d.Root.Add(p);for(int i=1;i<n;i++){var c=new XElement("SyntheticDepth");p.Add(c);p=c;}});
                if(n<=128){PackageReader.Read(b,new Budget());checks++;}else Reject(()=>PackageReader.Read(b,new Budget()),"resource_limit");
            }
            foreach(int v in new[]{11,12,13,14,15,16,17}){
                byte[] b=Change(original,d=>{var c=d.Descendants("component").First();c.SetAttributeValue("componentClassID","Microsoft.ManagedComponentHost");c.SetAttributeValue("version",1);c.Element("properties").Add(new XElement("property",new XAttribute("name","UserComponentTypeName"),"Microsoft.SqlServer.Dts.Pipeline.ADONETSource, Microsoft.SqlServer.ADONETSrc, Version="+v+".0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"));});
                Assert(PackageReader.Read(b,new Budget()).Flows[0].Components[0].Kind=="source","MANAGED_SOURCE_ALIAS");
            }
        }
        else if (args[0] == "components-v2-scale")
        {
            byte[] original = File.ReadAllBytes(args[1]);
            byte[] scaled = Change(original, d =>
            {
                var components = d.Descendants("components").Single();
                while (components.Elements().Count() < 4096)
                {
                    int i = components.Elements().Count();
                    components.Add(new XElement("component", new XAttribute("refId", "SyntheticScale" + i), new XAttribute("componentClassID", "Synthetic.Unconnected"), new XAttribute("version", 1), new XElement("inputs"), new XElement("outputs")));
                }
            });
            var watch = System.Diagnostics.Stopwatch.StartNew();
            var limits = ResourceLimits.Create("large10x", true); var budget = new Budget(); budget.Limits = limits;
            var model = PackageReader.Read(scaled, budget, true, limits);
            watch.Stop();
            Assert(model.Flows.Sum(flow => flow.Components.Count) == 4096, "V2_SCALE_COMPONENT_COUNT");
            Console.WriteLine("SSIS_FRAMEWORK_SCALE_PASS components=4096 ms=" + watch.ElapsedMilliseconds.ToString());
            return;
        }
        else if (args[0] == "components-v2-combined-scale")
        {
            const int targetBytes = 134217728, targetComponents = 3072, targetColumns = 57344, expressionUtf16Bytes = 3145728;
            byte[] original = File.ReadAllBytes(args[1]); var document = XDocument.Load(new MemoryStream(original));
            var derived = document.Descendants("component").Single(x => (string)x.Attribute("name") == "Derived");
            string derivedInputId = derived.Element("inputs").Element("input").Attribute("refId").Value;
            derived.Element("outputs").Element("output").SetAttributeValue("synchronousInputId", derivedInputId); derived.Attribute("version").Remove();
            string expression = "1" + new string(' ', expressionUtf16Bytes / 2 - 1);
            derived.Descendants("outputColumn").Single().Descendants("property").Single(x => (string)x.Attribute("name") == "Expression").Value = expression;
            var split = document.Descendants("component").Single(x => (string)x.Attribute("name") == "Split"); string splitInputId = split.Element("inputs").Element("input").Attribute("refId").Value;
            foreach (var output in split.Element("outputs").Elements("output")) output.SetAttributeValue("synchronousInputId", splitInputId);
            var components = document.Descendants("components").Single();
            var carrier = new XElement("component", new XAttribute("refId", "Package\\Flow\\SyntheticScaleCarrier"), new XAttribute("name", "SyntheticScaleCarrier"), new XAttribute("componentClassID", "Synthetic.Unconnected"), new XAttribute("version", 1), new XElement("inputs"), new XElement("outputs", new XElement("output", new XAttribute("refId", "Package\\Flow\\SyntheticScaleCarrier.output[Out]"), new XAttribute("name", "Out"), new XElement("outputColumns"))));
            components.Add(carrier); var outputColumns = carrier.Element("outputs").Element("output").Element("outputColumns");
            int existingColumns = document.Descendants().Count(x => x.Name == "inputColumn" || x.Name == "outputColumn" || x.Name == "externalMetadataColumn");
            for (int i = 0; i < targetColumns - existingColumns; i++)
            {
                string columnId = "Package\\Flow\\SyntheticScaleCarrier.output[Out].Columns[C" + i.ToString(CultureInfo.InvariantCulture) + "]";
                outputColumns.Add(new XElement("outputColumn", new XAttribute("refId", columnId), new XAttribute("name", "C" + i.ToString(CultureInfo.InvariantCulture)), new XAttribute("dataType", "i4")));
            }
            while (components.Elements("component").Count() < targetComponents)
            {
                int i = components.Elements("component").Count(); string id = "Package\\Flow\\SyntheticScale" + i.ToString(CultureInfo.InvariantCulture);
                components.Add(new XElement("component", new XAttribute("refId", id), new XAttribute("name", "SyntheticScale" + i.ToString(CultureInfo.InvariantCulture)), new XAttribute("componentClassID", "Synthetic.Unconnected"), new XAttribute("version", 1), new XElement("inputs"), new XElement("outputs")));
            }
            var padding = new XComment(""); document.Root.Add(padding); byte[] baseline = SerializeUtf16(document);
            int paddingChars = (targetBytes - baseline.Length) / 2;
            if (paddingChars < 0 || (targetBytes - baseline.Length) % 2 != 0) throw new Exception("V2_SCALE_BASE_SIZE");
            padding.Value = new string('x', paddingChars); byte[] packageBytes = SerializeUtf16(document);
            document = null; padding = null; original = null; baseline = null; GC.Collect(); GC.WaitForPendingFinalizers(); GC.Collect();
            if (packageBytes.Length != targetBytes) throw new Exception("V2_SCALE_INPUT_BYTE_LENGTH");
            var limits = ResourceLimits.Create("large10x", true); var budget = new Budget(); budget.Limits = limits; var watch = System.Diagnostics.Stopwatch.StartNew();
            var model = PackageReader.Read(packageBytes, budget, true, limits);
            var derivedModel = model.Flows.SelectMany(x => x.Components).Single(x => x.Kind == "derived");
            string sourceExpression = derivedModel.Outputs.SelectMany(port => port.Columns).Single(column => column.Properties.ContainsKey("Expression")).Properties["Expression"];
            var value = new ExpressionParser(sourceExpression, model, derivedModel.Scope, new Dictionary<string, ExpressionValue>(), null, true, null, limits).Parse();
            watch.Stop();
            Assert(model.Flows.Sum(flow => flow.Components.Count) == targetComponents, "V2_COMBINED_SCALE_COMPONENT_COUNT");
            Assert(model.Document.Definitions.Count(definition => definition.Kind == "COLUMN") == targetColumns, "V2_COMBINED_SCALE_COLUMN_COUNT");
            Assert(packageBytes.Length == targetBytes && sourceExpression.Length * 2 == expressionUtf16Bytes && value.Type == "int", "V2_COMBINED_SCALE_INPUT_AND_EXPRESSION");
            string prefix = "SSIS_FRAMEWORK_SCALE_PASS components=3072 columns=57344 inputBytes=134217728 expressionUtf16Bytes=3145728";
            if (args.Length > 2 && args[2] == "private-metrics") Console.WriteLine(prefix + " ms=" + watch.ElapsedMilliseconds.ToString(CultureInfo.InvariantCulture) + " peakWorkingSetBytes=" + System.Diagnostics.Process.GetCurrentProcess().PeakWorkingSet64.ToString(CultureInfo.InvariantCulture));
            else Console.WriteLine(prefix);
            return;
        }
        else if (args[0] == "parser-shape")
        {
            var safety = Safety(new SyntheticCatalog()); string sql;
            switch (args[1]) {
                case "union": sql = String.Join(" UNION ALL ", Enumerable.Repeat("SELECT 1", 65)); break;
                case "nested": sql = "SELECT " + new string('(', 32) + "1" + new string(')',32); break;
                case "unary": sql = "SELECT " + String.Join(" ", Enumerable.Repeat("-",256)) + " 1"; break;
                case "boolean": sql = "SELECT 1 WHERE " + String.Join(" OR ",Enumerable.Repeat("1=1",128)); break;
                case "projection": sql = "SELECT " + String.Join(",",Enumerable.Repeat("1",256)); break;
                case "comments": sql = "SELECT " + String.Concat(Enumerable.Repeat("/*",17)) + "x" + String.Concat(Enumerable.Repeat("*/",17)) + "1"; break;
                case "literal": sql = "SELECT N'" + new string('x',65536) + "'"; break;
                default: throw new Exception("UNKNOWN_SHAPE");
            }
            try { safety.Parse(sql); checks++; } catch (DebugFault e) { Assert(e.Code == "resource_limit", "BOUNDED_SHAPE_REJECTION"); }
        }
        else if (args[0] == "parser-boundary")
        {
            var safety = Safety(new SyntheticCatalog());
            string expression = "SELECT " + String.Join(" + ", Enumerable.Repeat("1", Int32.Parse(args[1])));
            try { safety.Parse(expression); checks++; } catch (DebugFault e) { Assert(e.Code == "resource_limit", "BOUNDED_PARSER_REJECTION"); }
        }
        else
        {
            byte[] bytes = File.ReadAllBytes(args[1]); var cat = new SyntheticCatalog();
            var template = Engine.Analyze(bytes, Options("bindings-template"), cat, new Budget());
            Assert(template.Rows.Count == 1 && template.Rows[0].Kind == "BindingsTemplate", "TEMPLATE_SHAPE");
            var json = Json.Object(Json.Parse(template.Rows[0].Content)); Assert(Json.Array(json["availableInputs"]).Count == 4, "INPUTS");
            if (args[0] == "import")
            {
                Assert(Json.Text(json["profile"]) == "ssis-debug-components-v2" &&
                       ((JsonNumber)json["schemaVersion"]).Text == "2", "CURRENT_BINDING_TEMPLATE_CONTRACT");
                var options = Options("explain"); options.Bindings = Json.Write(json);
                var package = PackageReader.Read(bytes, new Budget(), true); var bindings = new Bindings(package, options, cat, new Artifacts());
                Assert(bindings.Template().Count == 6, "ROUNDTRIP");
                Json.Object(json["values"])["v0001"] = "5";
                bindings = new Bindings(PackageReader.Read(bytes, new Budget(), true), new Options { Operation = "bindings-template", Version = 150 }, cat, new Artifacts());
                Assert(package.Flows[0].Components.Count == 8, "COMPONENTS_TWO_SOURCES_UNION_DERIVED_LOOKUP_SPLIT_TWO_DESTINATIONS");
            }
            else if (args[0] == "translate")
            {
                byte[] translatePackage = Change(bytes, d => {
                    var derived = d.Descendants("component").Single(x => (string)x.Attribute("name") == "Derived");
                    derived.SetAttributeValue("version", "0");
                    derived.Element("outputs").Element("output").SetAttributeValue("synchronousInputId", derived.Element("inputs").Element("input").Attribute("refId").Value);
                    var split = d.Descendants("component").Single(x => (string)x.Attribute("name") == "Split");
                    string splitInput = split.Element("inputs").Element("input").Attribute("refId").Value;
                    split.SetAttributeValue("version", "0");
                    foreach (var output in split.Element("outputs").Elements("output")) output.SetAttributeValue("synchronousInputId", splitInput);
                });
                string translateBindings = Engine.Analyze(translatePackage, Options("bindings-template"), cat, new Budget()).Rows.Single().Content;
                var options = Options("explain"); options.Bindings = translateBindings; options.Stage = "all";
                var result = Engine.Analyze(translatePackage, options, cat, new Budget());
                var sql = result.Rows.Where(a => a.Kind == "TargetSql").ToList();
                foreach (Artifact error in result.Rows.Where(a => a.Kind == "Diagnostic" && a.Code != "nolock_read_uncommitted" && a.Code != "arbitrary_lookup_selection" && a.Code != "lookup_comparison_deviation")) Console.Error.WriteLine(error.Content);
                Assert(sql.Count == 2, "TWO_TARGETS");
                var sourceStages=result.Rows.Where(a=>a.Kind=="StageSql" && a.Component=="Package\\Flow\\SourceA").ToList();
                Assert(sourceStages.Count==2 && sourceStages.Select(a=>a.Target).Distinct().Count()==2,"SOURCE_STAGE_PER_TARGET");
                foreach(int width in new[]{3999,4000,4001}) {
                    byte[] longId=Change(translatePackage,d=>d.Descendants("component").Last().SetAttributeValue("refId",new string('x',width)));
                    var longOptions=Options("explain");longOptions.Stage="all";
                    if(width<=4000){longOptions.Bindings=Engine.Analyze(longId,Options("bindings-template"),cat,new Budget()).Rows[0].Content;var full=Engine.Analyze(longId,longOptions,cat,new Budget());Assert(full.Rows.Any(a=>a.Component!=null && a.Component.Length==width),"ORIGINAL_COMPONENT_ID_NOT_TRUNCATED");}
                    else Reject(()=>Engine.Analyze(longId,Options("bindings-template"),cat,new Budget()),"resource_limit");
                }
                var planUnits = result.Rows.Where(a => a.Kind == "PlanUnitSql").ToList();
                bool sqlContract = sql.Count == 2 && planUnits.Count > 0 && planUnits.All(a => a.Executable && a.Safety == "passed");
                Assert(sqlContract, "SQL_CONTRACT_ARTIFACT_SAFETY");
                foreach (Artifact target in sql)
                {
                    // V2 legt Cachevorbereitung in guarded PlanUnitSql ab; separate PreparationSql wird mitgeprüft, falls vorhanden.
                    var targetArtifacts = result.Rows.Where(a => a.Target == target.Target &&
                        (a.Kind == "PreparationSql" || a.Kind == "PlanUnitSql" || a.Kind == "TargetSql") &&
                        a.Executable && a.Safety == "passed").ToList();
                    string targetPlanSql = String.Join("\n", targetArtifacts.Select(a => a.Content));
                    Assert(target.Executable && target.Complete && target.Content.IndexOf("SELECT", StringComparison.Ordinal) >= 0,
                           "SQL_CONTRACT_TARGET_PROJECTION");
                    Assert(targetArtifacts.Any(a => a.Kind == "PlanUnitSql"), "SQL_CONTRACT_TARGET_PLAN_UNITS");
                    Assert(targetArtifacts.Any(a => a.Kind == "TargetSql"), "SQL_CONTRACT_TARGET_READ");
                    Assert(targetPlanSql.Contains("WITH (NOLOCK)"), "SQL_CONTRACT_NOLOCK");
                    Assert(targetPlanSql.Contains("ROW_NUMBER() OVER (PARTITION BY"), "SQL_CONTRACT_LOOKUP_ROW_NUMBER");
                    Assert(targetPlanSql.Contains("DECLARE @v"), "SQL_CONTRACT_SCENARIO_DECLARATIONS");
                }
                Assert(result.Rows.Any(a => a.Kind == "StageSql") && result.Rows.Any(a => a.Kind == "CleanupSql"), "STAGES_CLEANUP");
                Assert(sql.All(a => a.Details != null && a.Details.Contains("catalogBinding") && a.Details.Contains("catalogSha256")), "CATALOG_BINDING_EXPORTED");
                if (args.Length > 2) File.WriteAllText(args[2], sql[0].Content);
            }
            else if (args[0] == "sql-regression")
            {
                var safety = Safety(cat);
                byte[] regressionPackage = Change(bytes, d => {
                    var derived = d.Descendants("component").Single(x => (string)x.Attribute("name") == "Derived");
                    derived.SetAttributeValue("version", "0");
                    derived.Element("outputs").Element("output").SetAttributeValue("synchronousInputId", derived.Element("inputs").Element("input").Attribute("refId").Value);
                    var split = d.Descendants("component").Single(x => (string)x.Attribute("name") == "Split");
                    string splitInput = split.Element("inputs").Element("input").Attribute("refId").Value;
                    split.SetAttributeValue("version", "0");
                    foreach (var output in split.Element("outputs").Elements("output")) output.SetAttributeValue("synchronousInputId", splitInput);
                });
                var filtered = safety.Read("SELECT KeyA FROM dbo.SyntheticLookup WHERE KeyA >= 2", "AdventureWorks");
                Assert(filtered.Sql.Contains("WHERE"), "READ_PRESERVES_WHERE");
                var pure = safety.Read("SELECT KeyA,KeyB,Amount FROM dbo.SyntheticPure()", "AdventureWorks");
                Assert(Projection.Columns(pure,safety).Count==3,"PURE_INLINE_FUNCTION");
                Projection.Columns(filtered, safety);
                Assert(safety.Generate(filtered.Statement.QueryExpression).Contains("WHERE"), "PROJECTION_PRESERVES_WHERE");
                var options = Options("explain");
                byte[] parameterized = Change(regressionPackage, d => { var c = d.Descendants("component").Single(x => (string)x.Attribute("name") == "Lookup"); c.Descendants("property").Single(x => (string)x.Attribute("name") == "SqlCommand").Value = "SELECT KeyA,KeyB,Score FROM dbo.SyntheticLookup WHERE KeyA >= ?"; c.Element("properties").Add(new XElement("property", new XAttribute("name", "ParameterMapping"), "\"@Floor:Input\",{11111111-1111-1111-1111-000000000002};")); });
                options.Bindings = Engine.Analyze(parameterized, Options("bindings-template"), cat, new Budget()).Rows.Single().Content;
                var result = Engine.Analyze(parameterized, options, cat, new Budget());
                Assert(result.Rows.Count(a => a.Kind == "TargetSql" && a.Executable) == 2, "REFERENCE_FILTER_TWO_EXECUTABLE_TARGETS");
                if (args.Length > 2) File.WriteAllText(args[2], result.Rows.First(a => a.Kind == "TargetSql").Content);
                Assert(result.Rows.Where(a => a.Kind == "PlanUnitSql").Any(a => System.Text.RegularExpressions.Regex.IsMatch(a.Content, @"WHERE\s+\[?KeyA\]?\s*>=\s*@v0002")), "LOOKUP_PRESERVES_REFERENCE_FILTER");
                Reject(() => Util.CollationToken("Latin1_General_100_BIN2;SELECT 1"), "unresolved_binding");
                Reject(() => Util.CollationToken("[Latin1_General_100_BIN2]"), "unresolved_binding");
                byte[] textKeys = Change(regressionPackage, d => { foreach (var column in d.Descendants().Where(x => (x.Name.LocalName == "inputColumn" || x.Name.LocalName == "outputColumn" || x.Name.LocalName == "externalMetadataColumn") && (string)x.Attribute("name") == "KeyA")) { column.SetAttributeValue("dataType", "wstr"); column.SetAttributeValue("cachedDataType", "wstr"); column.SetAttributeValue("length", "10"); column.SetAttributeValue("cachedLength", "10"); } });
                cat.TextKeys = true;
                foreach (int version in new[] { 150, 160, 170 })
                {
                    var textOptions = Options("explain"); textOptions.Bindings = Engine.Analyze(textKeys, Options("bindings-template"), cat, new Budget()).Rows.Single().Content; textOptions.Version = version;
                    var textResult = Engine.Analyze(textKeys, textOptions, cat, new Budget());
                    var textTargets = textResult.Rows.Where(a => a.Kind == "TargetSql" && a.Executable).ToList();
                    Assert(textTargets.Count == 2, "UNICODE_LOOKUP_TWO_EXECUTABLE_TARGETS");
                    Assert(textResult.Rows.Where(a => a.Kind == "PlanUnitSql").Any(a => a.Content.Contains("COLLATE Latin1_General_100_BIN2") && !a.Content.Contains("COLLATE [")), "COLLATION_TOKEN_SYNTAX");
                }
                cat.Drift = true;
                var driftOptions = Options("explain"); driftOptions.Bindings = Engine.Analyze(textKeys, Options("bindings-template"), cat, new Budget()).Rows.Single().Content;
                Reject(() => Engine.Analyze(textKeys, driftOptions, cat, new Budget()), "catalog_drift");
            }
            else if (args[0] == "safety")
            {
                var safety = Safety(cat);
                byte[] safetyPackage = Change(bytes, d => {
                    var derived = d.Descendants("component").Single(x => (string)x.Attribute("name") == "Derived");
                    derived.SetAttributeValue("version", "0");
                    derived.Element("outputs").Element("output").SetAttributeValue("synchronousInputId", derived.Element("inputs").Element("input").Attribute("refId").Value);
                    var split = d.Descendants("component").Single(x => (string)x.Attribute("name") == "Split");
                    string splitInput = split.Element("inputs").Element("input").Attribute("refId").Value;
                    split.SetAttributeValue("version", "0");
                    foreach (var output in split.Element("outputs").Elements("output")) output.SetAttributeValue("synchronousInputId", splitInput);
                });
                foreach (string sql in new[] { "DELETE FROM dbo.SyntheticSourceA", "SELECT * INTO dbo.Unsafe FROM dbo.SyntheticSourceA", "SELECT GETDATE()", "SELECT * FROM [Other].[dbo].[SyntheticSourceA]", "SELECT * FROM [Remote].[AdventureWorks].[dbo].[SyntheticSourceA]", "EXEC dbo.Unsafe" })
                { bool rejected = false; try { safety.Read(sql, "AdventureWorks"); } catch (DebugFault) { rejected = true; } Assert(rejected, "CLOSED_SQL_PROFILE"); }
                string cte = "WITH x AS (SELECT KeyA, KeyB, Amount FROM dbo.SyntheticSourceA) SELECT KeyA, KeyB, Amount FROM x";
                string first = safety.Read(cte, "AdventureWorks").Sql;
                var altered = safety.Read(cte, "AdventureWorks"); altered.Statement.WithCtesAndXmlNamespaces.CommonTableExpressions[0].ExpressionName.Value = "changed";
                Assert(safety.Read(cte, "AdventureWorks").Sql == first, "IMMUTABLE_PARSE_CACHE");
                Reject(() => SqlSafety.Guard("SELECT " + new string('(', 33) + "1" + new string(')', 33)), "resource_limit");
                Reject(() => SqlSafety.Guard("SELECT " + String.Join("+", Enumerable.Repeat("1", 258))), "resource_limit");
                Reject(() => Json.Parse(new string('[', 33) + "0" + new string(']', 33)), "resource_limit");
                var missing = Options("explain"); missing.Bindings = Json.Write(json);
                var bad = Json.Object(Json.Parse(missing.Bindings)); bad["packageSha256"] = new string('0', 64); missing.Bindings = Json.Write(bad);
                Reject(() => Engine.Analyze(bytes, missing, cat, new Budget()), "invalid_template");
                Reject(() => PackageReader.Read(Encoding.UTF8.GetBytes("<!DOCTYPE x SYSTEM 'file:///synthetic.dtd'><x/>"), new Budget()), "unsupported_package_format");
                var unsupported = Change(bytes, d => d.Descendants("component").First().SetAttributeValue("componentClassID", "Synthetic.Unsupported"));
                var partial = Engine.Analyze(unsupported, Options("explain"), cat, new Budget());
                Assert(partial.Rows.Any(x => x.Code == "unsupported_component"), "LOCAL_COMPONENT_DIAGNOSIS");
                Assert(!partial.Rows.Any(x => x.Kind == "TargetSql" && x.Executable), "BLOCKED_DEPENDENT_TARGETS");
                var failLookup = Change(safetyPackage, d => d.Descendants("component").Single(x => (string)x.Attribute("name") == "Lookup").Descendants("property").Single(x => (string)x.Attribute("name") == "NoMatchBehavior").Value = "0");
                var failLookupOptions = Options("explain"); failLookupOptions.Bindings = Engine.Analyze(failLookup, Options("bindings-template"), cat, new Budget()).Rows.Single().Content;
                var matches = Engine.Analyze(failLookup, failLookupOptions, cat, new Budget());
                Assert(matches.Rows.Any(x => x.Kind == "StageIndex" && x.Content.Contains("lookup_matches")), "LOOKUP_FAIL_MATCH_VIEW");
                var decimalInput = new Input { Type = "Decimal", SqlType = Types.Sql("Decimal") };
                Assert(Types.Literal(decimalInput, "123.456") == "123.456", "EXACT_DECIMAL_FRACTION");
                Reject(() => Types.Literal(decimalInput, "0.1234567890123456789"), "invalid_template");
                Reject(() => safety.Read("SELECT * FROM dbo.SyntheticIf() AS f", "AdventureWorks"), "hint_not_supported");
                Reject(() => Types.Literal(new Input { SqlType = "time(0)" }, "12:34:56.1234567"), "invalid_template");
                Reject(() => Types.Literal(new Input { SqlType = "datetime2(2)" }, "2026-10-16T12:34:56.1234567"), "invalid_template");
                Assert(Types.Literal(new Input { SqlType = "time(2)" }, "12:34:56.1200000").Contains("12:34:56.1200000"), "EXACT_TRAILING_ZEROS");
                Reject(() => Types.Literal(new Input { SqlType = "nvarchar(2)" }, "abcd"), "invalid_template");
                Reject(() => Types.Literal(new Input { SqlType = "varbinary(2)" }, "0x01020304"), "invalid_template");
                ProjectType("CAST(1.23 AS decimal(10,2))*CAST(2.34 AS decimal(10,2))", "decimal(21,4)");
                ProjectType("CAST(N'abc' AS nvarchar(3))+CAST(N'def' AS nvarchar(3))", "nvarchar(6)");
                ProjectType("AVG(CAST(1.23 AS decimal(10,2)))", "decimal(38,6)");
                ProjectType("SUM(CAST(1.23 AS decimal(10,2)))", "decimal(38,2)");
                ProjectType("LEN(CAST(N'abc' AS nvarchar(max)))", "bigint");
                ProjectType("CAST(1 AS tinyint)+CAST(2 AS tinyint)", "tinyint");
                ProjectType("CAST(1 AS smallint)+CAST(2 AS smallint)", "smallint");
                ProjectType("(CAST(1 AS tinyint)+CAST(2 AS tinyint))*CAST(1 AS decimal(38,18))", "decimal(38,14)");
                ProjectType("NULLIF(1,1)", "int");
                var ansiQuery = safety.Read("SELECT 'é' AS Value", "AdventureWorks");
                Reject(() => Projection.Columns(ansiQuery, safety), "unresolved_binding");
                ProjectType("CAST('é' AS varchar(8))", "varchar(8)");
                ProjectType("N'é'", "nvarchar(1)");
                var unionQuery = safety.Read("SELECT 1 AS Value UNION ALL SELECT NULL AS Value", "AdventureWorks");
                Assert(Projection.Columns(unionQuery, safety)[0].Nullable, "SQL_UNION_NULLABILITY");
                var valuesQuery = safety.Read("SELECT v.Value FROM (VALUES(1),(NULL)) AS v(Value)", "AdventureWorks");
                Assert(Projection.Columns(valuesQuery, safety)[0].Nullable, "SQL_VALUES_NULLABILITY");
                var lookupProduct = Change(safetyPackage, d => d.Descendants("component").Single(x => (string)x.Attribute("name") == "Lookup").Descendants("property").Single(x => (string)x.Attribute("name") == "SqlCommand").Value = "SELECT KeyA,KeyB,CAST(1.23 AS decimal(10,2))*CAST(2.34 AS decimal(10,2)) AS Score FROM dbo.SyntheticLookup");
                var productOptions = Options("explain"); productOptions.Bindings = Engine.Analyze(lookupProduct, Options("bindings-template"), cat, new Budget()).Rows.Single().Content;
                var product = Engine.Analyze(lookupProduct, productOptions, cat, new Budget());
                Assert(product.Rows.Where(x => x.Kind == "PlanUnitSql").Count(x => x.Executable && x.Content.Contains("decimal(21,4)")) > 0, "LOOKUP_PRODUCT_CACHE_PRECISION");
            }
            else throw new Exception("UNKNOWN_CASE");
        }
        Console.WriteLine("SSIS_FRAMEWORK_PASS " + checks);
    }
    internal static int Main(string[] args)
    {
        if (args.Length == 3 && (args[0] == "v1-resource-probe" || args[0] == "v2-resource-probe"))
        {
            bool v2 = args[0] == "v2-resource-probe";
            try
            {
                var file = new FileInfo(args[2]);
                if (!file.Exists || (file.Attributes & FileAttributes.ReparsePoint) != 0 || file.Length > 16777216) throw new DebugFault("probe_input", "Offline probe input is outside its bounded file profile.");
                byte[] package;
                if (args[1] == "bytes") package = File.ReadAllBytes(file.FullName);
                else if (args[1] == "utf16-nvarchar")
                {
                    string text; using (var reader = new StreamReader(file.FullName, new UTF8Encoding(false, true), true)) text = reader.ReadToEnd();
                    if (text.Length > 8388608) throw new DebugFault("probe_input", "Offline probe text exceeds the V1 nvarchar bound.");
                    package = Encoding.Unicode.GetBytes(text);
                }
                else throw new DebugFault("probe_input", "Offline probe input format is invalid.");
                var options = new Options { Operation = "explain", Version = 150 };
                if (v2) options.ProjectContext = "{\"schemaVersion\":2}";
                Engine.Analyze(package, options, new NullCatalog(), new Budget());
                Console.WriteLine((v2 ? "SSIS_V2_RESOURCE_PROBE" : "SSIS_V1_RESOURCE_PROBE") + " first=none counter=none");
            }
            catch (DebugFault error)
            {
                string counter = "none", marker = "counter=";
                int start = error.Message.IndexOf(marker, StringComparison.Ordinal);
                if (start >= 0) { start += marker.Length; int end = error.Message.IndexOf(';', start); if (end > start) counter = error.Message.Substring(start, end - start); }
                Console.WriteLine((v2 ? "SSIS_V2_RESOURCE_PROBE" : "SSIS_V1_RESOURCE_PROBE") + " first=" + error.Code + " counter=" + counter);
            }
            catch
            {
                Console.WriteLine((v2 ? "SSIS_V2_RESOURCE_PROBE" : "SSIS_V1_RESOURCE_PROBE") + " first=probe_failure counter=none");
            }
            return 0;
        }
        Exception failure = null;
        var worker = new Thread(() => { try { Run(args); } catch (Exception e) { failure = e; } }, 262144);
        worker.Start(); worker.Join();
        if (failure != null) { Console.Error.WriteLine(failure); return 1; }
        return 0;
    }
}
