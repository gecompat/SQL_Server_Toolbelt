using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Threading;
using System.Text;
using System.Xml.Linq;
using Toolbelt.Tsql.SsisDebug;

internal sealed class SyntheticCatalog : ICatalog
{
    internal bool TextKeys;
    internal bool Drift;
    private int resolutions;
    public string Collation(string database) { return "Latin1_General_100_BIN2"; }
    public bool IsCollation(string name) { return name == "Latin1_General_100_BIN2"; }
    public int CodePage(string name) { return 1252; }
    public string BindIdentifier(string database, IEnumerable<string> names, string name) { return names.SingleOrDefault(x => x == name); }
    public BoundObject Resolve(string database, string schema, string name)
    {
        if (database != "AdventureWorks" || schema != null && schema != "dbo" || !(name == "SyntheticSourceA" || name == "SyntheticSourceB" || name == "SyntheticLookup" || name == "SyntheticIf" || name == "SyntheticPure")) return null;
        var o = new BoundObject { Database = database, Schema = schema, Name = name, Kind = "U", Fingerprint = name + (Drift ? (++resolutions).ToString() : "") };
        if (name == "SyntheticIf") { o.Kind = "IF"; o.Schema = "dbo"; o.Definition = "CREATE FUNCTION dbo.SyntheticIf() RETURNS TABLE AS RETURN (SELECT KeyA,KeyB,Amount FROM dbo.SyntheticSourceA);"; }
        if (name == "SyntheticPure") { o.Kind = "IF"; o.Schema = "dbo"; o.Definition = "CREATE FUNCTION dbo.SyntheticPure() RETURNS TABLE AS RETURN (SELECT 1 AS KeyA,10 AS KeyB,100 AS Amount);"; }
        foreach (string column in new[] { "KeyA", "KeyB", name == "SyntheticLookup" ? "Score" : "Amount" }) o.Columns.Add(new BoundColumn { Name = column, SqlType = TextKeys && column == "KeyA" ? "nvarchar(10)" : "int", Collation = TextKeys && column == "KeyA" ? "Latin1_General_100_CS_AS" : null, Nullable = false });
        return o;
    }
}
internal static class ContractTests
{
    private static int checks;
    private static void Assert(bool value, string name) { checks++; if (!value) throw new Exception(name); }
    private static void Reject(Action action, string code)
    { bool failed = false; try { action(); } catch (DebugFault e) { failed = e.Code == code; } Assert(failed, "EXPECTED_" + code); }
    private static Options Options(string operation)
    {
        return new Options { Operation = operation, Version = 150, CatalogBindings = operation == "explain" ? "{\"schemaVersion\":1,\"defaultDatabase\":\"AdventureWorks\",\"databases\":[\"AdventureWorks\"],\"connections\":{\"Package.ConnectionManagers[Synthetic]\":\"AdventureWorks\"}}" : null };
    }
    private static byte[] Change(byte[] bytes, Action<XDocument> edit)
    { var document = XDocument.Parse(Encoding.UTF8.GetString(bytes)); edit(document); return Encoding.UTF8.GetBytes(document.ToString()); }
    private static SqlSafety Safety(SyntheticCatalog cat)
    { return new SqlSafety(new Budget(), 150, cat, new[] { "AdventureWorks" }, new string[0], code => { }); }
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
                if(n<=10000){add();Assert(output.Rows.Count==n,"ARTIFACT_COUNT");}else Reject(add,"resource_limit");
            }
            foreach (int n in new[] { 999,1000,1001 }) {
                var output = new Artifacts(); Action add = () => { for(int i=0;i<n;i++) output.Diagnostic("synthetic","synthetic",""); };
                if(n<=1000){add();Assert(output.Rows.Count==n,"DIAGNOSTIC_COUNT");}else Reject(add,"resource_limit");
            }
            foreach (int n in new[] { 1048575,1048576,1048577 }) {
                var output=new Artifacts();Action add=()=>output.Add(new Artifact {Kind="StageSql",Content=new string('x',n)});
                if(n<=1048576){add();Assert(output.Rows.Count==1,"SQL_OUTPUT_BYTES");}else Reject(add,"resource_limit");
            }
            foreach (int n in new[] { 4194303,4194304,4194305 }) {
                var output=new Artifacts();Action add=()=>output.Add(new Artifact {Kind="Workflow",Content=new string('x',n-1),Details="x"});
                if(n<=4194304){add();Assert(output.Rows.Count==1,"TOTAL_CONTENT_DETAILS_BYTES");}else Reject(add,"resource_limit");
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
                var options = Options("explain"); options.Bindings = Json.Write(json);
                var package = PackageReader.Read(bytes, new Budget()); var bindings = new Bindings(package, options, cat, new Artifacts());
                Assert(bindings.Template().Count == 6, "ROUNDTRIP");
                Json.Object(json["values"])["v0001"] = "5";
                bindings = new Bindings(PackageReader.Read(bytes, new Budget()), new Options { Operation = "bindings-template", Version = 150 }, cat, new Artifacts());
                Assert(package.Flows[0].Components.Count == 8, "COMPONENTS_TWO_SOURCES_UNION_DERIVED_LOOKUP_SPLIT_TWO_DESTINATIONS");
            }
            else if (args[0] == "translate")
            {
                var options = Options("explain"); options.Bindings = Json.Write(json); options.Stage = "all";
                var result = Engine.Analyze(bytes, options, cat, new Budget());
                var sql = result.Rows.Where(a => a.Kind == "TargetSql").ToList();
                foreach (Artifact error in result.Rows.Where(a => a.Kind == "Diagnostic" && a.Code != "nolock_read_uncommitted" && a.Code != "arbitrary_lookup_selection" && a.Code != "lookup_comparison_deviation")) Console.Error.WriteLine(error.Content);
                Assert(sql.Count == 2, "TWO_TARGETS");
                var sourceStages=result.Rows.Where(a=>a.Kind=="StageSql" && a.Component=="Package\\Flow\\SourceA").ToList();
                Assert(sourceStages.Count==2 && sourceStages.Select(a=>a.Target).Distinct().Count()==2,"SOURCE_STAGE_PER_TARGET");
                foreach(int width in new[]{3999,4000,4001}) {
                    byte[] longId=Change(bytes,d=>d.Descendants("component").Last().SetAttributeValue("refId",new string('x',width)));
                    var longOptions=Options("explain");longOptions.Stage="all";
                    if(width<=4000){longOptions.Bindings=Engine.Analyze(longId,Options("bindings-template"),cat,new Budget()).Rows[0].Content;var full=Engine.Analyze(longId,longOptions,cat,new Budget());Assert(full.Rows.Any(a=>a.Component!=null && a.Component.Length==width),"ORIGINAL_COMPONENT_ID_NOT_TRUNCATED");}
                    else Reject(()=>Engine.Analyze(longId,Options("bindings-template"),cat,new Budget()),"resource_limit");
                }
                Assert(sql.All(a => a.Executable && a.Content.Contains("WITH (NOLOCK)") && a.Content.Contains("ROW_NUMBER() OVER (PARTITION BY") && a.Content.Contains("DECLARE @v")), "SQL_CONTRACT");
                Assert(result.Rows.Any(a => a.Kind == "StageSql") && result.Rows.Any(a => a.Kind == "CleanupSql"), "STAGES_CLEANUP");
                Assert(sql.All(a => a.Details != null && a.Details.Contains("catalogBinding") && a.Details.Contains("catalogSha256")), "CATALOG_BINDING_EXPORTED");
                if (args.Length > 2) File.WriteAllText(args[2], sql[0].Content);
            }
            else if (args[0] == "sql-regression")
            {
                var safety = Safety(cat);
                var filtered = safety.Read("SELECT KeyA FROM dbo.SyntheticLookup WHERE KeyA >= 2", "AdventureWorks");
                Assert(filtered.Sql.Contains("WHERE"), "READ_PRESERVES_WHERE");
                var pure = safety.Read("SELECT KeyA,KeyB,Amount FROM dbo.SyntheticPure()", "AdventureWorks");
                Assert(Projection.Columns(pure,safety).Count==3,"PURE_INLINE_FUNCTION");
                Projection.Columns(filtered, safety);
                Assert(safety.Generate(filtered.Statement.QueryExpression).Contains("WHERE"), "PROJECTION_PRESERVES_WHERE");
                var options = Options("explain");
                byte[] parameterized = Change(bytes, d => { var c = d.Descendants("component").Single(x => (string)x.Attribute("name") == "Lookup"); c.Descendants("property").Single(x => (string)x.Attribute("name") == "SqlCommand").Value = "SELECT KeyA,KeyB,Score FROM dbo.SyntheticLookup WHERE KeyA >= ?"; c.Element("properties").Add(new XElement("property", new XAttribute("name", "ParameterMapping"), "\"@Floor:Input\",{11111111-1111-1111-1111-000000000002};")); });
                var result = Engine.Analyze(parameterized, options, cat, new Budget());
                Assert(result.Rows.Count(a => a.Kind == "TargetSql" && a.Executable) == 2, "REFERENCE_FILTER_TWO_EXECUTABLE_TARGETS");
                if (args.Length > 2) File.WriteAllText(args[2], result.Rows.First(a => a.Kind == "TargetSql").Content);
                Assert(result.Rows.Where(a => a.Kind == "TargetSql").All(a => System.Text.RegularExpressions.Regex.IsMatch(a.Content, @"WHERE\s+\[?KeyA\]?\s*>=\s*@v0002")), "LOOKUP_PRESERVES_REFERENCE_FILTER");
                Reject(() => Util.CollationToken("Latin1_General_100_BIN2;SELECT 1"), "unresolved_binding");
                Reject(() => Util.CollationToken("[Latin1_General_100_BIN2]"), "unresolved_binding");
                byte[] textKeys = Change(bytes, d => { foreach (var column in d.Descendants().Where(x => (x.Name.LocalName == "inputColumn" || x.Name.LocalName == "outputColumn" || x.Name.LocalName == "externalMetadataColumn") && (string)x.Attribute("name") == "KeyA")) { column.SetAttributeValue("dataType", "wstr"); column.SetAttributeValue("cachedDataType", "wstr"); column.SetAttributeValue("length", "10"); column.SetAttributeValue("cachedLength", "10"); } });
                cat.TextKeys = true;
                foreach (int version in new[] { 150, 160, 170 })
                {
                    var textOptions = Options("explain"); textOptions.Version = version;
                    var textResult = Engine.Analyze(textKeys, textOptions, cat, new Budget());
                    var textTargets = textResult.Rows.Where(a => a.Kind == "TargetSql" && a.Executable).ToList();
                    Assert(textTargets.Count == 2, "UNICODE_LOOKUP_TWO_EXECUTABLE_TARGETS");
                    Assert(textTargets.All(a => a.Content.Contains("COLLATE Latin1_General_100_BIN2") && !a.Content.Contains("COLLATE [")), "COLLATION_TOKEN_SYNTAX");
                }
                cat.Drift = true;
                Reject(() => Engine.Analyze(textKeys, Options("explain"), cat, new Budget()), "catalog_drift");
            }
            else if (args[0] == "safety")
            {
                var safety = Safety(cat);
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
                var failLookup = Change(bytes, d => d.Descendants("component").Single(x => (string)x.Attribute("name") == "Lookup").Descendants("property").Single(x => (string)x.Attribute("name") == "NoMatchBehavior").Value = "0");
                var matches = Engine.Analyze(failLookup, Options("explain"), cat, new Budget());
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
                var lookupProduct = Change(bytes, d => d.Descendants("component").Single(x => (string)x.Attribute("name") == "Lookup").Descendants("property").Single(x => (string)x.Attribute("name") == "SqlCommand").Value = "SELECT KeyA,KeyB,CAST(1.23 AS decimal(10,2))*CAST(2.34 AS decimal(10,2)) AS Score FROM dbo.SyntheticLookup");
                var product = Engine.Analyze(lookupProduct, Options("explain"), cat, new Budget());
                Assert(product.Rows.Where(x => x.Kind == "TargetSql").Count(x => x.Executable && x.Content.Contains("decimal(21,4)")) == 2, "LOOKUP_PRODUCT_CACHE_PRECISION");
            }
            else throw new Exception("UNKNOWN_CASE");
        }
        Console.WriteLine("SSIS_FRAMEWORK_PASS " + checks);
    }
    internal static int Main(string[] args)
    {
        Exception failure = null;
        var worker = new Thread(() => { try { Run(args); } catch (Exception e) { failure = e; } }, 262144);
        worker.Start(); worker.Join();
        if (failure != null) { Console.Error.WriteLine(failure); return 1; }
        return 0;
    }
}
