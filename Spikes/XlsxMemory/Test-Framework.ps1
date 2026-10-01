param([switch]$FixtureOnly,[switch]$RepeatedStringFixtureOnly)
$ErrorActionPreference = 'Stop'
$bin = Join-Path $PSScriptRoot 'bin/Release'
Add-Type -Path (Join-Path $bin 'Toolbelt.Archive.ZipMemory.dll')
Add-Type -Path (Join-Path $bin 'Toolbelt.File.XlsxMemory.dll')
Add-Type -Path (Join-Path $bin 'Toolbelt.Xlsx.Qualification.dll')
Add-Type -AssemblyName System.IO.Compression
Add-Type -ReferencedAssemblies @((Join-Path $bin 'Toolbelt.Archive.ZipMemory.dll'),(Join-Path $bin 'Toolbelt.File.XlsxMemory.dll'),(Join-Path $bin 'Toolbelt.Xlsx.Qualification.dll'),'System.Data.dll','System.Xml.dll','System.Core.dll','System.IO.Compression.dll') -TypeDefinition @'
using System; using System.IO; using System.IO.Compression; using System.Text; using System.Collections.Generic; using System.Data.SqlTypes;
using Toolbelt.Xlsx.Qualification;
public static class XlsxOracle {
 const string N=Workbook.Spreadsheet;
 const string R="http://schemas.openxmlformats.org/officeDocument/2006/relationships";
 const string P="http://schemas.openxmlformats.org/package/2006/relationships";
 public static Dictionary<string,string> Parts() {
  return new Dictionary<string,string> {
   {"[Content_Types].xml","<Types xmlns='http://schemas.openxmlformats.org/package/2006/content-types'><Override PartName='/xl/workbook.xml' ContentType='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml'/><Override PartName='/xl/worksheets/sheet1.xml' ContentType='application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml'/><Override PartName='/xl/sharedStrings.xml' ContentType='application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml'/></Types>"},
   {"_rels/.rels","<Relationships xmlns='"+P+"'><Relationship Id='r1' Type='"+R+"/officeDocument' Target='xl/workbook.xml'/></Relationships>"},
   {"xl/workbook.xml","<workbook xmlns='"+N+"' xmlns:r='"+R+"'><workbookPr date1904='true'/><sheets><sheet name='Synthetic' sheetId='1' state='hidden' r:id='r1'/></sheets></workbook>"},
   {"xl/_rels/workbook.xml.rels","<Relationships xmlns='"+P+"'><Relationship Id='r1' Type='"+R+"/worksheet' Target='worksheets/sheet1.xml'/><Relationship Id='r2' Type='"+R+"/sharedStrings' Target='sharedStrings.xml'/></Relationships>"},
   {"xl/sharedStrings.xml","<sst xmlns='"+N+"'><si><r><t xml:space='preserve'>tail </t></r><r><t>\u00e4\ud83d\ude00</t></r><rPh sb='0' eb='1'><t>ignored</t></rPh></si><si><t/></si></sst>"},
   {"xl/worksheets/sheet1.xml","<worksheet xmlns='"+N+"'><sheetData><row r='1'><c r='A1' t='s'><v>0</v></c><c r='C1' t='inlineStr'><is><t/></is></c><c r='D1'><v/></c><c r='E1'/><c r='F1'><f t='shared' si='0'>SUM(A1)</f><v/></c><c r='G1'><f t='shared' si='0'/></c><c r='H1' t='b'><v>1</v></c><c r='I1' t='e'><v>#DIV/0!</v></c></row><row r='1048576'><c r='XFD1048576'><v>42</v></c></row></sheetData></worksheet>"}
  };
 }
 public static Dictionary<string,string> RepeatedParts() {
  var p=Parts();p["xl/sharedStrings.xml"]="<sst xmlns='"+N+"'><si><t>"+new string('x',500000)+"</t></si></sst>";
  var cells=new StringBuilder("<worksheet xmlns='"+N+"'><sheetData>");
  for(int i=1;i<=100;i++)cells.Append("<row r='"+i+"'><c r='A"+i+"' t='s'><v>0</v></c></row>");
  cells.Append("</sheetData></worksheet>");p["xl/worksheets/sheet1.xml"]=cells.ToString();return p;
 }
 public static void Status(byte[] binary,int ordinal,int expectedCount,bool failure) {
  var rows=XlsxEntryPoints.ReadCells(new SqlBytes(binary),ordinal,16777216,16777216,67108864,256,32,100000,50000,8388608,64,new SqlDecimal(200),5000);
  int count=0;
  foreach(object row in rows) {
   SqlInt32 error,r,c,shared;SqlString message,type,raw,text,formula,kind,cache;SqlBoolean present,fp,cp;
   XlsxEntryPoints.FillCells(row,out error,out message,out r,out c,out type,out present,out raw,out text,out fp,out formula,out kind,out shared,out cp,out cache);
   Assert(failure ? (!error.IsNull&&error.Value==51520&&!message.IsNull&&r.IsNull&&c.IsNull) : error.IsNull,"atomic status row");count++;
  }
  Assert(count==expectedCount,"status row count");
 }
 public static byte[] Zip(Dictionary<string,string> p,bool deflate) {
  using(var m=new MemoryStream()) {using(var z=new ZipArchive(m,ZipArchiveMode.Create,true))foreach(var kv in p){var e=z.CreateEntry(kv.Key,deflate?CompressionLevel.Optimal:CompressionLevel.NoCompression);using(var s=e.Open()){var b=Encoding.UTF8.GetBytes(kv.Value);s.Write(b,0,b.Length);}} return m.ToArray();}
 }
 static void Assert(bool p,string msg){if(!p)throw new Exception(msg);}
 static void Fail(Dictionary<string,string> p,string suffix,Workbook.Limits limits=null) {
  try{var w=new Workbook(Zip(p,false),limits);w.ReadCells(1);throw new Exception("Expected "+suffix);}catch(InvalidDataException x){Assert(x.Message=="TBX_XLSX_"+suffix || x.Message.EndsWith(suffix),"Unexpected category "+x.Message);}
 }
 static string Column(int value) { string s="";while(value>0){value--;s=(char)('A'+value%26)+s;value/=26;}return s; }
 public static void Run() {
  foreach(bool d in new[]{false,true}) {
   var w=new Workbook(Zip(Parts(),d),null);var sheets=w.ListSheets();Assert(sheets.Length==1 && sheets[0].Ordinal==1 && sheets[0].Name=="Synthetic" && sheets[0].Visibility=="hidden" && sheets[0].Date1904,"sheets");
   var c=w.ReadCells(1);Assert(c.Length==9,"sparse count");Assert(c[0].TextValue=="tail \u00e4\ud83d\ude00" && c[0].RawValue=="0","rich text");
   Assert(c[1].Column==3 && c[1].TextValue=="" && !c[1].ValuePresent,"inline empty");
   Assert(c[2].ValuePresent && c[2].RawValue=="" && !c[3].ValuePresent && c[3].RawValue==null,"missing versus empty");
   Assert(c[4].FormulaPresent && c[4].FormulaKind=="shared" && c[4].SharedFormulaIndex==0 && c[4].CachePresent && c[4].CacheValue=="","formula empty cache");
   Assert(c[5].FormulaPresent && c[5].FormulaText=="" && !c[5].CachePresent,"shared no cache");
   Assert(c[8].Row==1048576 && c[8].Column==16384,"coordinate ceiling");
   Assert(w.ReadCells(1).Length==9,"repeat");
  }
  var p=Parts();p["_rels/.rels"]=p["_rels/.rels"].Replace("Target='xl/workbook.xml'","TargetMode='External' Target='https://example.invalid/no-access'");Fail(p,"EXTERNAL_RELATION_UNSUPPORTED");
  p=Parts();p["xl/sharedStrings.xml"]="<!DOCTYPE sst [<!ENTITY a SYSTEM 'file:///no-access'>]><sst xmlns='"+N+"'><si><t>&a;</t></si></sst>";
  try{new Workbook(Zip(p,false),null).ReadCells(1);throw new Exception("DTD accepted");}catch(System.Xml.XmlException){}
  p=Parts();p["xl/worksheets/sheet1.xml"]=p["xl/worksheets/sheet1.xml"].Replace("r='C1'","r='A1'");Fail(p,"CELL_DUPLICATE");
  p=Parts();p["xl/worksheets/sheet1.xml"]=p["xl/worksheets/sheet1.xml"].Replace("<v>0</v>","<v>2</v>");Fail(p,"SHARED_STRING_REFERENCE");
  p=Parts();p["xl/workbook.xml"]=p["xl/workbook.xml"].Replace("state='hidden'","state='invalid'");Fail(p,"SHEET_VISIBILITY_INVALID");
  Fail(Parts(),"CELL_LIMIT",new Workbook.Limits{Cells=8});Assert(new Workbook(Zip(Parts(),false),new Workbook.Limits{Cells=9}).ReadCells(1).Length==9,"cell exact");
  Fail(Parts(),"SHARED_STRING_COUNT_LIMIT",new Workbook.Limits{Strings=1});
  Fail(Parts(),"XML_DEPTH_LIMIT",new Workbook.Limits{Depth=2});
  Fail(Parts(),"ZIP_PART_LIMIT",new Workbook.Limits{Parts=5});
  var b=Zip(Parts(),false);try{new Workbook(b,new Workbook.Limits{ArchiveBytes=b.Length-1});throw new Exception("archive limit");}catch(InvalidDataException x){Assert(x.Message=="ZIP_ARCHIVE_LIMIT","archive category");}
  Assert(new Workbook(b,new Workbook.Limits{ArchiveBytes=b.Length}).ReadCells(1).Length==9,"archive exact");
  var counted=new Workbook(b,null);counted.ReadCells(1);long exact=counted.CountedAllocationBytes;
  Assert(new Workbook(b,new Workbook.Limits{AllocationBytes=exact}).ReadCells(1).Length==9,"counted allocation exact");
  Fail(Parts(),"COUNTED_ALLOCATION_LIMIT",new Workbook.Limits{AllocationBytes=exact-1});
  Fail(RepeatedParts(),"COUNTED_ALLOCATION_LIMIT");
  Fail(Parts(),"COUNTED_ALLOCATION_LIMIT",new Workbook.Limits{AllocationBytes=100});
  p=Parts();p["[Content_Types].xml"]=p["[Content_Types].xml"].Replace("PartName='/xl/workbook.xml'","PartName='/other.xml'");Fail(p,"CONTENT_TYPE_MISMATCH");
  p=Parts();p["xl/worksheets/sheet1.xml"]=p["xl/worksheets/sheet1.xml"].Replace("<c r='E1'/>","<c r='E1'><unknown/></c>");Fail(p,"CELL_CONTENT_UNSUPPORTED");
  p=Parts();p["xl/worksheets/sheet1.xml"]=p["xl/worksheets/sheet1.xml"].Replace("<c r='H1' t='b'><v>1</v>","<c r='H1' t='b'><v>2</v>");Fail(p,"BOOLEAN_VALUE_INVALID");
  p=Parts();p["xl/worksheets/sheet1.xml"]=p["xl/worksheets/sheet1.xml"].Replace("sheetData","fakeContainer");Fail(p,"ROW_NESTING_INVALID");
  p=Parts();p["xl/workbook.xml"]=p["xl/workbook.xml"].Replace("<sheets>","<fakeContainer>").Replace("</sheets>","</fakeContainer>");Fail(p,"SHEET_NESTING_INVALID");
  p=Parts();p["xl/workbook.xml"]=p["xl/workbook.xml"].Replace("<workbookPr date1904='true'/>","<workbookPr/><workbookPr/>");Fail(p,"WORKBOOK_PROPERTIES_INVALID");
  p=Parts();p["xl/sharedStrings.xml"]=p["xl/sharedStrings.xml"].Replace("<si><t/></si>","<fakeContainer><si><t/></si></fakeContainer>");Fail(p,"SHARED_STRING_NESTING_INVALID");
  // Tatsächlicher Zell-Ceiling, nicht bloße Parameterannahme. Unabhängiger
  // Fixture-Writer erzeugt Stored, damit Ratio keine zweite Variable ist.
  var xml=new StringBuilder("<worksheet xmlns='"+N+"'><sheetData>");
  for(int row=1;row<=1000;row++){xml.Append("<row r='"+row+"'>");for(int col=1;col<=100;col++)xml.Append("<c r='"+Column(col)+row+"'><v>1</v></c>");xml.Append("</row>");}
  xml.Append("</sheetData></worksheet>");p=Parts();p["xl/worksheets/sheet1.xml"]=xml.ToString();
  Assert(new Workbook(Zip(p,false),null).ReadCells(1).Length==100000,"actual cell ceiling");
  p["xl/worksheets/sheet1.xml"]=xml.ToString().Replace("</sheetData>","<row r='1001'><c r='A1001'><v>1</v></c></row></sheetData>");Fail(p,"CELL_LIMIT");
  p=Parts();p["xl/sharedStrings.xml"]="<sst xmlns='"+N+"'><si><t>"+new string('x',4194304)+"</t></si><si><t/></si></sst>";
  Assert(new Workbook(Zip(p,false),null).ReadCells(1)[0].TextValue.Length==4194304,"actual shared text exact8MiB");
  p["xl/sharedStrings.xml"]=p["xl/sharedStrings.xml"].Replace("</t></si>","x</t></si>");Fail(p,"SHARED_STRING_TEXT_LIMIT");
  System.Threading.Tasks.Parallel.For(0,4,i=>{Assert(new Workbook(Zip(Parts(),i%2==0),null).ReadCells(1).Length==9,"parallel independent");});
 }
}
'@
if ($RepeatedStringFixtureOnly) { [Convert]::ToBase64String([XlsxOracle]::Zip([XlsxOracle]::RepeatedParts(), $false)); return }
if ($FixtureOnly) { [Convert]::ToBase64String([XlsxOracle]::Zip([XlsxOracle]::Parts(), $true)); return }
[XlsxOracle]::Run()
[XlsxOracle]::Status([XlsxOracle]::Zip([XlsxOracle]::Parts(),$true),1,9,$false)
[XlsxOracle]::Status([XlsxOracle]::Zip([XlsxOracle]::Parts(),$true),0,1,$true)
[XlsxOracle]::Status([byte[]]@(1,2,3),1,1,$true)
'PASS: Framework ZIP/XML fixtures, sparse/null-empty/formula/rich-text semantics, selected limits, repeats and parallel calls. No SAFE or NoIO claim.'
$fixture = [XlsxOracle]::Zip([XlsxOracle]::Parts(), $true)
& (Join-Path $bin 'Toolbelt.Xlsx.Sandbox.exe') ([Convert]::ToBase64String($fixture))
if ($LASTEXITCODE) { throw 'INCONCLUSIVE: restrictive Framework sandbox failed; no public XLSX API authorized by this run.' }
$externalParts = [XlsxOracle]::Parts()
$externalParts['_rels/.rels'] = $externalParts['_rels/.rels'].Replace("Target='xl/workbook.xml'", "TargetMode='External' Target='https://example.invalid/no-access'")
& (Join-Path $bin 'Toolbelt.Xlsx.Sandbox.exe') ([Convert]::ToBase64String([XlsxOracle]::Zip($externalParts,$true))) 'TBX_XLSX_EXTERNAL_RELATION_UNSUPPORTED'
if ($LASTEXITCODE) { throw 'INCONCLUSIVE: external-relationship sandbox boundary failed.' }
$dtdParts = [XlsxOracle]::Parts()
$dtdParts['xl/sharedStrings.xml'] = "<!DOCTYPE sst [<!ENTITY a SYSTEM 'file:///no-access'>]><sst xmlns='http://schemas.openxmlformats.org/spreadsheetml/2006/main'><si><t>&a;</t></si></sst>"
& (Join-Path $bin 'Toolbelt.Xlsx.Sandbox.exe') ([Convert]::ToBase64String([XlsxOracle]::Zip($dtdParts,$true))) 'DTD'
if ($LASTEXITCODE) { throw 'INCONCLUSIVE: external-entity sandbox boundary failed.' }
& (Join-Path $PSScriptRoot 'Test-ProviderIL.ps1')
