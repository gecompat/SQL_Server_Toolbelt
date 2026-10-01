param([Parameter(Mandatory=$true)][string]$AssemblyPath)
$ErrorActionPreference='Stop'
Add-Type -Path (Resolve-Path $AssemblyPath)
Add-Type -AssemblyName System.IO.Compression
Add-Type -ReferencedAssemblies @((Resolve-Path $AssemblyPath).Path,'System.Data.dll','System.Xml.dll','System.Core.dll','System.IO.Compression.dll') -TypeDefinition @'
using System; using System.IO; using System.IO.Compression; using System.Text; using System.Data.SqlTypes;
using Toolbelt.Archive.ZipMemory;
public static class WriterFramework {
 static void Assert(bool v,string m) { if(!v) throw new Exception(m); }
 static uint OracleCrc(byte[] data){uint c=0xffffffff;foreach(byte b in data){c^=b;for(int j=0;j<8;j++)c=(c&1)!=0?(c>>1)^0xedb88320:(c>>1);}return ~c;}
 static void Headers(byte[] zip,int method,byte[][] data){
  int p=(int)BitConverter.ToUInt32(zip,zip.Length-6);
  for(int i=0;i<data.Length;i++){
   Assert(BitConverter.ToUInt32(zip,p)==0x02014b50,"central signature");
   Assert(BitConverter.ToUInt16(zip,p+8)==0x800 && BitConverter.ToUInt16(zip,p+10)==method,"flags/method");
   Assert(BitConverter.ToUInt16(zip,p+12)==0 && BitConverter.ToUInt16(zip,p+14)==0x21,"timestamp");
   Assert(BitConverter.ToUInt32(zip,p+16)==OracleCrc(data[i]),"independent CRC");
   Assert(BitConverter.ToUInt32(zip,p+38)==0,"attributes");
   int local=(int)BitConverter.ToUInt32(zip,p+42);
   Assert(BitConverter.ToUInt32(zip,local)==0x04034b50 && BitConverter.ToUInt32(zip,local+14)==OracleCrc(data[i]),"local signature/CRC");
   Assert(BitConverter.ToUInt32(zip,local+18)==BitConverter.ToUInt32(zip,p+20),"sizes");
   p+=46+BitConverter.ToUInt16(zip,p+28)+BitConverter.ToUInt16(zip,p+30)+BitConverter.ToUInt16(zip,p+32);
  }
  Assert(p==zip.Length-22,"directory end");
 }
 static byte[] Envelope(string[] names, byte[][] data) {
  using(var s=new MemoryStream()) using(var w=new BinaryWriter(s)) {
   w.Write(0x575a4254U);w.Write(1U);w.Write((uint)names.Length);
   for(int i=0;i<names.Length;i++){var n=new UTF8Encoding(false,true).GetBytes(names[i]);w.Write(i+1);w.Write((uint)n.Length);w.Write((ulong)data[i].Length);w.Write(n);w.Write(data[i]);}return s.ToArray();
  }
 }
 static byte[] Create(byte[] e,int method,long archive=71303168) {
  return ZipEntryProvider.CreateWriterArchive(new SqlBytes(e),method,256,1024,16777216,67108864,archive,71303168,30000).Value;
 }
 static byte[] CreateCeiling(byte[] e,int method) {
  return ZipEntryProvider.CreateWriterArchive(new SqlBytes(e),method,1024,2048,33554432,134217728,150994944,142606336,60000).Value;
 }
 static void Fail(byte[] e,int method,long cap,string category) {
  try {Create(e,method,cap); throw new Exception("Expected "+category);} catch(Exception x){Assert(x.Message.StartsWith("TBX_ZIP_WRITE_"+category+":"),"Error category "+x.Message);}
 }
 public static void Run() {
  var names=new[]{"empty.txt","unicode-\u00e4\ud83d\ude00.txt","space ","space"};
  var bytes=new[]{new byte[0],new byte[]{0,255,1,2},Encoding.UTF8.GetBytes("tail "),new byte[200000]};
  var e=Envelope(names,bytes);
  foreach(int method in new[]{0,8}) {
   var z=Create(e,method);Headers(z,method,bytes); using(var s=new MemoryStream(z))using(var reader=new ZipArchive(s,ZipArchiveMode.Read)) {
    Assert(reader.Entries.Count==4,"count");
    for(int i=0;i<4;i++){var entry=reader.Entries[i];Assert(entry.FullName==names[i],"name");using(var p=entry.Open())using(var o=new MemoryStream()){p.CopyTo(o);Assert(Convert.ToBase64String(o.ToArray())==Convert.ToBase64String(bytes[i]),"payload");}}
   }
   if(method==8){Assert(z[30+names[0].Length]==3 && z[31+names[0].Length]==0,"empty raw deflate block");}
   if(method==0) Assert(Convert.ToBase64String(z)==Convert.ToBase64String(Create(e,method)),"Stored determinism");
  }
  var empty=Envelope(new string[0],new byte[0][]);Assert(Create(empty,0,22).Length==22,"empty22");Fail(empty,0,21,"RESOURCE_LIMIT");
  var bad=(byte[])e.Clone();bad[4]=2;Fail(bad,0,71303168,"TRANSPORT_INVALID");
  var trailing=new byte[e.Length+1];Array.Copy(e,trailing,e.Length);Fail(trailing,0,71303168,"TRANSPORT_INVALID");
  Fail(new byte[11],0,71303168,"TRANSPORT_INVALID");
  bad=(byte[])e.Clone();bad[28]=0xff;Fail(bad,0,71303168,"INVALID_NAME");
  Fail(Envelope(new[]{"x","x"},new[]{new byte[0],new byte[0]}),0,71303168,"DUPLICATE_NAME");
  foreach(var n in new[]{"../x","/x","x\\y","x:","x//y","x/","\ud800"}) {
   try{ZipEntryProvider.EncodeWriterName(new SqlString(n),1024);throw new Exception("invalid name accepted");}catch(Exception x){Assert(x.Message.StartsWith("TBX_ZIP_WRITE_INVALID_NAME:"),"name error");}
  }
  var stream=new MemoryStream(e);stream.Position=e.Length;Assert(ZipEntryProvider.CreateWriterArchive(new SqlBytes(stream),0,256,1024,16777216,67108864,71303168,71303168,30000).Length>0,"seeked transport");
  System.Threading.Tasks.Parallel.For(0,4,i=>{Assert(Create(e,i%2==0?0:8).Length>0,"parallel");});
  // Tatsächliche Payload-/Entry-/Count-/Name-Ceilings gemeinsam, nicht nur
  // Parameterakzeptanz. Namen/Framing bleiben unter unabhängigen Budgetcaps.
  var ceilingNames=new string[1024];var ceilingData=new byte[1024][];
  var payload=new byte[33554432];for(int i=0;i<payload.Length;i++) payload[i]=(byte)(i*31+i/97);
  for(int i=0;i<1024;i++){ceilingNames[i]=i.ToString("D4")+new string('\u4e00',2044);ceilingData[i]=i<4?payload:new byte[0];}
  var large=Envelope(ceilingNames,ceilingData);
  var deadline=ZipEntryProvider.CreateWriterArchiveStatus(new SqlBytes(large),0,1024,2048,33554432,134217728,150994944,142606336,1);
  foreach(var row in deadline){SqlInt32 error;SqlString message;SqlBytes result;ZipEntryProvider.FillWriterStatus(row,out error,out message,out result);Assert(error.Value==51356 && result.IsNull,"cooperative deadline status");}
  foreach(int method in new[]{0,8}) {
   var z=CreateCeiling(large,method);using(var s=new MemoryStream(z))using(var archive=new ZipArchive(s,ZipArchiveMode.Read)) {
    Assert(archive.Entries.Count==1024,"ceiling count");Assert(archive.Entries[0].FullName.Length==2048,"ceiling name");
    using(var p=archive.Entries[3].Open()){var b=new byte[81920];long total=0;int read;while((read=p.Read(b,0,b.Length))>0){for(int j=0;j<read;j++)Assert(b[j]==payload[(int)total+j],"ceiling payload");total+=read;}Assert(total==33554432,"ceiling size");}
   }
  }
  Console.WriteLine("ZIP Writer Framework: independent ZipArchive roundtrips, empty Deflate, deterministic Stored, boundaries, names, malformed transport and parallel calls PASS.");
 }
}
'@
[WriterFramework]::Run()
