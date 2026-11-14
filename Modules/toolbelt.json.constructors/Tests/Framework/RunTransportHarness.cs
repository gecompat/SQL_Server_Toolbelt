using System;
using System.IO;
using System.Data.SqlTypes;
using System.Security.Cryptography;
using Toolbelt.JsonConstructors;
internal static class RunTransportHarness {
 static void A(bool b){if(!b)throw new InvalidOperationException("RUN_ASSERT");}
 static SqlChars C(string s){return s==null?SqlChars.Null:new SqlChars(s.ToCharArray());}
 static string K(int i){return i.ToString("D",System.Globalization.CultureInfo.InvariantCulture);}
 static void Add(OwnedAggregateBuilder b,int i,bool obj,byte profile){b.Add(i,C(obj?K(i):null),C("null"),C(null),profile);}
 static byte[] Frame(OwnedAggregateBuilder b){using(MemoryStream m=new MemoryStream()){b.Write(m);return m.ToArray();}}
 static OwnedAggregateBuilder Read(byte[] f,bool mode){using(MemoryStream m=new MemoryStream(f)){OwnedAggregateBuilder b=OwnedAggregateBuilder.Read(m,mode);A(m.Position==m.Length);return b;}}
 static void Same(OwnedAggregateBuilder a,OwnedAggregateBuilder b){A(a.Outcome()==b.Outcome());if(a.Outcome()=="VALID"||a.Outcome()=="EMPTY")A(a.Clone().Finish()==b.Clone().Finish());else{try{a.Finish();throw new Exception();}catch(InvalidOperationException e){try{b.Finish();throw new Exception();}catch(InvalidOperationException f){A(e.Message==f.Message);}}}}
 static byte[] Seal(byte[] f){using(SHA256 h=SHA256.Create()){byte[] body=new byte[32];Array.Copy(f,body,32);Array.Copy(h.ComputeHash(body),0,f,32,32);}return f;}
 static void Reject(byte[] f,bool mode){try{Read(f,mode);throw new Exception("ACCEPTED");}catch(InvalidOperationException e){A(e.Message=="TBX_JSON_AGG_STATE_INVALID");}catch(EndOfStreamException){}}
 static void Bounds(){foreach(bool obj in new[]{false,true})foreach(byte profile in new byte[]{1,2}){
  OwnedAggregateBuilder b=new OwnedAggregateBuilder(obj);int limit=profile==1?10000:100000;
  for(int i=1;i<=limit;i++){Add(b,i,obj,profile);byte[] f=Frame(b);A(f.Length==64);b=Read(f,obj);}
  OwnedAggregateBuilder canonical=OwnedAggregateBuilder.FromTransport(b.Clone().Transport());Same(b,canonical);A(Frame(b).Length==64);
  Add(b,limit+1,obj,profile);A(b.Outcome()=="COUNT");A(Read(Frame(b),obj).Outcome()=="COUNT");
  b=new OwnedAggregateBuilder(obj);for(int i=1;i<=limit;i++)Add(b,i,obj,profile);
  b.Add(SqlInt32.Null,C(null),C("bad"),C("invalid"),profile);A(b.Outcome()=="COUNT");
  b=new OwnedAggregateBuilder(obj);Add(b,1,obj,profile);b.Add(2,C("2"),C("null"),C(null),SqlByte.Null);A(b.Outcome()=="PROFILE");
 }}
 static void Transitions(){foreach(bool obj in new[]{false,true})foreach(byte p in new byte[]{1,2}){
  foreach(int next in new[]{1,2,4,99,Int32.MaxValue}){
   OwnedAggregateBuilder a=new OwnedAggregateBuilder(obj),b=new OwnedAggregateBuilder(obj);Add(a,1,obj,p);Add(a,2,obj,p);Add(b,1,obj,p);Add(b,2,obj,p);b=OwnedAggregateBuilder.FromTransport(b.Transport());a=Read(Frame(a),obj);Add(a,next,obj,p);Add(b,next,obj,p);Same(a,b);Same(Read(Frame(a),obj),b);
  }
  foreach(string kind in new[]{"null","number","boolean","string","json","bad",null})foreach(string val in new[]{null,"0","true","x","{}","\ud800"}){
   OwnedAggregateBuilder a=new OwnedAggregateBuilder(obj),b=new OwnedAggregateBuilder(obj);Add(a,10,obj,p);Add(b,10,obj,p);b=OwnedAggregateBuilder.FromTransport(b.Transport());a=Read(Frame(a),obj);
   a.Add(11,C(obj?"different":null),C(kind),C(val),p);b.Add(11,C(obj?"different":null),C(kind),C(val),p);Same(a,b);Same(Read(Frame(a),obj),b);
  }
  OwnedAggregateBuilder left=new OwnedAggregateBuilder(obj),right=new OwnedAggregateBuilder(obj);Add(left,8,obj,p);Add(right,9,obj,p);OwnedAggregateBuilder before=right.Clone();left.Merge(right);Same(right,before);A(left.Finish()==(obj?"{\"8\":null,\"9\":null}":"[null,null]"));right.Merge(right);A(right.Outcome()=="ORDINAL");
  OwnedAggregateBuilder end=new OwnedAggregateBuilder(obj);Add(end,Int32.MaxValue,obj,p);end=Read(Frame(end),obj);Add(end,1,obj,p);A(end.Outcome()=="VALID");
 }}
 static void Malformed(){foreach(bool obj in new[]{false,true}){
  OwnedAggregateBuilder b=new OwnedAggregateBuilder(obj);Add(b,9,obj,1);Add(b,10,obj,1);byte[] f=Frame(b);A(f.Length==64);
  for(int i=0;i<64;i++)for(int bit=0;bit<8;bit++){byte[] bad=(byte[])f.Clone();bad[i]^=(byte)(1<<bit);Reject(bad,obj);}
  for(int len=0;len<64;len++){byte[] shortFrame=new byte[len];Array.Copy(f,shortFrame,len);Reject(shortFrame,obj);}
  foreach(int at in new[]{8,9,10,11,20,31}){byte[] bad=(byte[])f.Clone();bad[at]=255;Reject(Seal(bad),obj);}
  foreach(int value in new[]{0,-1,10001,Int32.MaxValue}){byte[] bad=(byte[])f.Clone();Array.Copy(BitConverter.GetBytes(value),0,bad,16,4);Reject(Seal(bad),obj);}
  foreach(int value in new[]{0,-1,Int32.MaxValue}){byte[] bad=(byte[])f.Clone();Array.Copy(BitConverter.GetBytes(value),0,bad,12,4);Reject(Seal(bad),obj);}
  Reject(f,!obj);
  JsonArrayAggregate a=new JsonArrayAggregate();a.Init();a.Accumulate(1,C("null"),C(null),1);byte[] invalid=(byte[])f.Clone();invalid[30]=1;try{using(BinaryReader r=new BinaryReader(new MemoryStream(invalid)))a.Read(r);throw new Exception();}catch(InvalidOperationException){}A(new string(a.Terminate().Value)=="[null]");
 }}
 public static int Main(){try{Bounds();Transitions();Malformed();Console.WriteLine("PASS AGGREGATE_RUN_TRANSPORT");return 0;}catch(Exception e){Console.WriteLine(e.ToString());return 1;}}
}
