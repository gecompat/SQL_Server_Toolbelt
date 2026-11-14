using System;
using System.IO;
using System.Text;
using System.Collections.Generic;
using System.Data.SqlTypes;
namespace Toolbelt.JsonConstructors {

// Private A-Revision: eigener veränderbarer Zustand, keine freigegebene SQL-Source.
public static class AgfErrors {
 public static InvalidOperationException State(){return new InvalidOperationException("TBX_JSON_AGG_STATE_INVALID");}
 public static InvalidOperationException Resource(){return new InvalidOperationException("TBX_JSON_AGG_RESOURCE_FAILURE");}
 public static void Need(bool condition){if(!condition)throw State();}
 public static string Message(string outcome,int tag){
  switch(outcome){
   case "PROFILE":return "TBX_JSON_AGG_PROFILE_INVALID";case "COUNT":return "TBX_JSON_AGG_ENTRY_LIMIT";
   case "ORDINAL":return "TBX_JSON_AGG_ORDINAL_INVALID";case "KEY":return "TBX_JSON_AGG_KEY_INVALID";
   case "KIND_LENGTH":return "TBX_JSON_AGG_KIND_LENGTH";case "RAW":return "TBX_JSON_AGG_RAW_LIMIT";
   case "PRE_MIN":return "TBX_JSON_AGG_MINIMUM_LIMIT";case "DUP_KEY":return "TBX_JSON_AGG_DUPLICATE_KEY";
   case "KIND":return "TBX_JSON_AGG_KIND_INVALID";case "NULL":return "TBX_JSON_AGG_NULL_INVALID";
   case "STRONG_MIN":return "TBX_JSON_AGG_STRONG_MINIMUM_LIMIT";case "OUTPUT":return "TBX_JSON_AGG_OUTPUT_LIMIT";
   case "LATE":switch(tag){case 1:case 2:return "TBX_JSON_AGG_UTF16_INVALID";case 3:return "TBX_JSON_AGG_BOOLEAN_INVALID";case 4:case 5:case 6:case 7:return "TBX_JSON_AGG_NUMBER_INVALID";case 8:return "TBX_JSON_AGG_JSON_INVALID";case 9:case 10:case 11:return "TBX_JSON_AGG_DECODED_UTF16_INVALID";case 12:return "TBX_JSON_AGG_DEPTH_LIMIT";default:throw State();}
   default:throw State();
  }
 }
}

public sealed class OwnedAggregateBuilder {
 internal readonly bool ObjectMode;
 internal int Mask,Flags,RankOrdinal,RankPhase,RankTag;
 internal bool InvalidProfile,Poisoned;
 internal long N,Raw,Pre,Strong,Output,KeyUnits;
 bool uniformRun;int runStart,runSpan;byte[] runPacked;
 readonly SortedSet<int> ids=new SortedSet<int>();
 readonly SortedSet<byte[]> keys=new SortedSet<byte[]>(new ByteOrder());
 readonly List<VEntry> payload=new List<VEntry>();
 public OwnedAggregateBuilder(bool mode){ObjectMode=mode;}
 int Profile{get{AgfErrors.Need(Mask==1||Mask==2);return Mask;}}
 long Cap{get{return ValidCodec.Cap((byte)Profile);}}
 int MaxN{get{return ValidCodec.MaxN((byte)Profile);}}
 static long Sat(long value,long cap){return Math.Min(value,cap+1);}
 internal static long BytesFromUnits(long units,long cap){AgfErrors.Need(units>=0&&cap>=0&&cap<Int64.MaxValue);return units>cap/2?cap+1:2*units;}
 void AddLengthCosts(long valueLength,long keyLength,string kindText){
  long rawBytes=BytesFromUnits(valueLength,Cap),keyBytes=BytesFromUnits(keyLength,Cap);
  Raw=Sat(checked(Raw+rawBytes),Cap);Pre=Sat(checked(Pre+rawBytes+keyBytes+(ObjectMode?6:0)),Cap);
  Strong=Sat(checked(Strong+(kindText=="null"?8:rawBytes)+(kindText=="string"?4:0)+keyBytes+(ObjectMode?6:0)),Cap);
 }
 static byte KindByte(string kind){switch(kind){case "string":return 1;case "null":return 2;case "boolean":return 3;case "number":return 4;case "json":return 5;default:return 0;}}
 void Usable(){AgfErrors.Need(!Poisoned);}
 public void Poison(){Poisoned=true;ClearData();}
 void ClearData(){uniformRun=false;runStart=runSpan=0;runPacked=null;N=Raw=Pre=Strong=Output=KeyUnits=0;Flags=RankOrdinal=RankPhase=RankTag=0;ids.Clear();keys.Clear();payload.Clear();}
 void ClearKeys(){keys.Clear();KeyUnits=0;Flags&=~32;}
 long Syntax{get{return checked(2*N+2);}}
 string BeforeLate(){
  if((Flags&6)!=0)return "ORDINAL";if((Flags&8)!=0)return "KEY";if((Flags&16)!=0)return "KIND_LENGTH";
  if(Raw>Cap)return "RAW";if(Pre+Syntax>Cap)return "PRE_MIN";if((Flags&32)!=0)return "DUP_KEY";
  if((Flags&64)!=0)return "KIND";if((Flags&128)!=0)return "NULL";if(Strong+Syntax>Cap)return "STRONG_MIN";return null;
 }
 public string Outcome(){
  Usable();if(InvalidProfile||Mask==3)return "PROFILE";if(Mask==0)return "EMPTY";if(N>MaxN)return "COUNT";
  string early=BeforeLate();if(early!=null)return early;if(RankTag!=0)return "LATE";if(Output+Syntax>Cap)return "OUTPUT";return "VALID";
 }
 void Normalize(){
  if(InvalidProfile||Mask==3){ClearData();return;}if(Mask==0){ClearData();return;}
  if(N>MaxN){long count=MaxN+1L;ClearData();N=count;return;}
  if(Raw>Cap||Pre+Syntax>Cap)ClearKeys();
  // Unter höherem monotonem Fehler existiert keine rekonstruierbare Output-/Late-Historie.
  if(BeforeLate()!=null){RankOrdinal=RankPhase=RankTag=0;Output=0;}
  else if(RankTag!=0)Output=0;
  if(Outcome()!="VALID")payload.Clear();
 }
 void Rank(int ordinal,int phase,int tag){if(RankTag==0||ordinal<RankOrdinal||ordinal==RankOrdinal&&(phase<RankPhase||phase==RankPhase&&tag<RankTag)){RankOrdinal=ordinal;RankPhase=phase;RankTag=tag;}}
 static long Length(SqlChars chars){return chars.IsNull?0:chars.Length;}
 static string Copy(SqlChars chars,long length){
  AgfErrors.Need(!chars.IsNull&&length>=0&&length<=Int32.MaxValue&&chars.Length==length);
  char[] buffer=new char[(int)length];long used=0;
  while(used<length){int wanted=(int)Math.Min(32768L,length-used);long got=chars.Read(used,buffer,(int)used,wanted);AgfErrors.Need(got>0&&got<=wanted);used=checked(used+got);}
  return new string(buffer);
 }
 public void Add(SqlInt32 ordinal,SqlChars key,SqlChars kind,SqlChars value,SqlByte profile){
  Usable();AgfErrors.Need(key!=null&&kind!=null&&value!=null);
  if(TryUniformAdd(ordinal,key,kind,value,profile))return;
  // COUNT beziehungsweise PROFILE dominieren die verworfene Nutzlast ohnehin.
  if(uniformRun&&(profile.IsNull||profile.Value!=Mask||N>=MaxN)){uniformRun=false;runStart=runSpan=0;runPacked=null;}else MaterializeRun();
  int bit=profile.IsNull?0:profile.Value==1?1:profile.Value==2?2:0;Mask|=bit;InvalidProfile|=bit==0;
  if(InvalidProfile||Mask==3){Normalize();return;}
  N=Sat(checked(N+1),MaxN);if(N>MaxN){Normalize();return;}
  bool positive=!ordinal.IsNull&&ordinal.Value>0;if(positive){if(!ids.Add(ordinal.Value))Flags|=4;}else Flags|=2;
  long keyLength=ObjectMode?Length(key):0,kindLength=Length(kind),valueLength=Length(value);
  bool keyBad=ObjectMode&&(key.IsNull||keyLength==0||keyLength>1024),kindLengthBad=kind.IsNull||kindLength>7;
  if(keyBad)Flags|=8;if(kindLengthBad)Flags|=16;
  AgfErrors.Need(valueLength>=0&&keyLength>=0&&kindLength>=0);
  string kindText=kindLengthBad?null:Copy(kind,kindLength);byte kindByte=KindByte(kindText);
  if(kindByte==0)Flags|=64;if((kindText=="null")!=value.IsNull)Flags|=128;
  AddLengthCosts(valueLength,keyLength,kindText);
  string keyText=null;
  if(Raw>Cap||Pre+Syntax>Cap)ClearKeys();
  else if(ObjectMode&&!keyBad){keyText=Copy(key,keyLength);byte[] identity=ValidCodec.Units(keyText);if(keys.Add(identity))KeyUnits=checked(KeyUnits+keyLength);else Flags|=32;}
  // Höhere Fehler aus Metadaten stehen schon fest; kein Valuezugriff dafür.
  if(BeforeLate()!=null){Normalize();return;}
  string valueText=value.IsNull?null:Copy(value,valueLength);
  EntryResult result=JsonCanonicalCore.Evaluate(ObjectMode,keyText,kindText,valueText,JsonPolicy.AgfJson,false);
  if(result.Code==0){
   Output=Sat(checked(Output+result.FragmentBytes),Cap);
   if(RankTag==0&&Output+Syntax<=Cap){AgfErrors.Need(positive);payload.Add(new VEntry(ordinal.Value,keyText,kindByte,valueText));}
  }else if(positive){
   if(result.Code==53607&&result.State==1){bool keyFault=ObjectMode&&JsonCanonicalCore.Evaluate(true,keyText,"null",null,JsonPolicy.AgfJson,false).Code==53607;Rank(ordinal.Value,keyFault?0:1,keyFault?1:2);}
   else if(result.Code==53608){AgfErrors.Need(result.State>=1&&result.State<=6);Rank(ordinal.Value,2,result.State==1?3:result.State==2?8:result.State+1);}
   else if(result.Code==53607){AgfErrors.Need(result.State>=2&&result.State<=4);Rank(ordinal.Value,3,result.State+7);}
   else if(result.Code==912){AgfErrors.Need(result.State==1);Rank(ordinal.Value,2,12);}
   else throw AgfErrors.State();
  }
  Normalize();
 }
 public void Merge(OwnedAggregateBuilder other){
  Usable();AgfErrors.Need(other!=null&&other.ObjectMode==ObjectMode);other.Usable();
  // Selbstmerge braucht keine Quellkopie: Kosten verdoppeln, vorhandene Identitäten duplizieren.
  if(Object.ReferenceEquals(this,other)){if(uniformRun&&2*N<=MaxN)MaterializeRun();MergeSelf();return;}
  Mask|=other.Mask;InvalidProfile|=other.InvalidProfile;if(InvalidProfile||Mask==3){Normalize();return;}if(Mask==0)return;
  long combined=Sat(checked(N+other.N),MaxN);if(combined>MaxN){N=combined;Normalize();return;}
  // Profil-/Count-Gates vor jeder Expansion der kompakten Zustände.
  MaterializeRun();if(other.uniformRun){other=other.Clone();other.MaterializeRun();}N=combined;
  Flags|=other.Flags;Raw=Sat(checked(Raw+other.Raw),Cap);Pre=Sat(checked(Pre+other.Pre),Cap);Strong=Sat(checked(Strong+other.Strong),Cap);Output=Sat(checked(Output+other.Output),Cap);
  foreach(int id in other.ids)if(!ids.Add(id))Flags|=4;
  if(Raw>Cap||Pre+Syntax>Cap)ClearKeys();
  else foreach(byte[] borrowed in other.keys){byte[] own=(byte[])borrowed.Clone();if(keys.Add(own))KeyUnits=checked(KeyUnits+own.Length/2);else Flags|=32;}
  if(other.RankTag!=0)Rank(other.RankOrdinal,other.RankPhase,other.RankTag);
  if(BeforeLate()==null&&RankTag==0&&Output+Syntax<=Cap){foreach(VEntry e in other.payload)payload.Add(new VEntry(e.Ordinal,e.Key,e.Kind,e.Value));}
  Normalize();
 }
 void MergeSelf(){
  if(InvalidProfile||Mask==3){Normalize();return;}if(Mask==0)return;
  N=Sat(checked(2*N),MaxN);if(N>MaxN){Normalize();return;}
  Raw=Sat(checked(2*Raw),Cap);Pre=Sat(checked(2*Pre),Cap);Strong=Sat(checked(2*Strong),Cap);Output=Sat(checked(2*Output),Cap);
  if(ids.Count>0)Flags|=4;if(Raw>Cap||Pre+Syntax>Cap)ClearKeys();else if(keys.Count>0)Flags|=32;
  // Bestehende Sets sind bereits die eigene Union; keine Payload kann nach Duplikaten gültig bleiben.
  Normalize();
 }
 public OwnedAggregateBuilder Clone(){
  Usable();OwnedAggregateBuilder copy=new OwnedAggregateBuilder(ObjectMode);copy.Mask=Mask;copy.InvalidProfile=InvalidProfile;copy.N=N;copy.Raw=Raw;copy.Pre=Pre;copy.Strong=Strong;copy.Output=Output;copy.KeyUnits=KeyUnits;copy.Flags=Flags;copy.RankOrdinal=RankOrdinal;copy.RankPhase=RankPhase;copy.RankTag=RankTag;copy.uniformRun=uniformRun;copy.runStart=runStart;copy.runSpan=runSpan;copy.runPacked=runPacked==null?null:(byte[])runPacked.Clone();
  foreach(int id in ids)copy.ids.Add(id);foreach(byte[] key in keys)copy.keys.Add((byte[])key.Clone());foreach(VEntry e in payload)copy.payload.Add(new VEntry(e.Ordinal,e.Key,e.Kind,e.Value));return copy;
 }
 VEntry[] SortedPayload(){
  MaterializeRun();AgfErrors.Need(Outcome()=="VALID"&&payload.Count==N);VEntry[] entries=payload.ToArray();Array.Sort(entries,delegate(VEntry a,VEntry b){return a.Ordinal.CompareTo(b.Ordinal);});
  return entries;
 }
 public string Finish(){
  string outcome=Outcome();if(outcome=="EMPTY")return ObjectMode?"{}":"[]";if(outcome!="VALID")throw new InvalidOperationException(AgfErrors.Message(outcome,RankTag));
  VEntry[] entries=SortedPayload();StringBuilder output=new StringBuilder((int)((Output+Syntax)/2));output.Append(ObjectMode?'{':'[');
  for(int i=0;i<entries.Length;i++){
   VEntry e=entries[i];EntryResult r=JsonCanonicalCore.Evaluate(ObjectMode,e.Key,ValidCodec.Kind(e.Kind),e.Value,JsonPolicy.AgfJson,true);AgfErrors.Need(r.Code==0&&r.Fragment!=null);if(i!=0)output.Append(',');output.Append(r.Fragment);
  }
  output.Append(ObjectMode?'}':']');AgfErrors.Need(checked(2L*output.Length)==Output+Syntax);return output.ToString();
 }
 public TransportState Transport(){
  string outcome=Outcome();if(outcome=="VALID"){
   VState valid=ValidCodec.Build(ObjectMode,(byte)Profile,SortedPayload());AgfErrors.Need(valid.Raw==Raw&&valid.Pre==Pre&&valid.Strong==Strong&&valid.Output==Output&&valid.KeyUnits==KeyUnits);return new TransportState(valid);
  }
  byte cls=outcome=="EMPTY"?(byte)0:outcome=="COUNT"?(byte)1:outcome=="PROFILE"?(byte)2:(byte)3;
  int[] ownIds=new int[ids.Count];ids.CopyTo(ownIds);byte[][] ownKeys=new byte[keys.Count][];int used=0;foreach(byte[] k in keys)ownKeys[used++]=(byte[])k.Clone();
  FaultState f=new FaultState((byte)(ObjectMode?1:0),cls,(byte)Mask,(uint)(Flags|(InvalidProfile?1:0)),N,Raw,Pre,Strong,Output,KeyUnits,ownIds,ownKeys,RankOrdinal,(ushort)RankPhase,(ushort)RankTag);return new TransportState(f);
 }
 public static OwnedAggregateBuilder FromTransport(TransportState t){
  AgfErrors.Need(t!=null);Dispatcher.Write(t);OwnedAggregateBuilder fresh=new OwnedAggregateBuilder(t.Mode);
  if(t.Class==4){VState v=t.Valid;AgfErrors.Need(v!=null);fresh.Mask=v.Profile;fresh.N=v.Entries.Length;fresh.Raw=v.Raw;fresh.Pre=v.Pre;fresh.Strong=v.Strong;fresh.Output=v.Output;fresh.KeyUnits=v.KeyUnits;
   foreach(VEntry e in v.Entries){fresh.ids.Add(e.Ordinal);fresh.payload.Add(new VEntry(e.Ordinal,e.Key,e.Kind,e.Value));}foreach(byte[] key in v.Keys)fresh.keys.Add((byte[])key.Clone());
  }else{FaultState f=t.Fault;AgfErrors.Need(f!=null);fresh.Mask=f.Mask;fresh.InvalidProfile=(f.Flags&1)!=0;fresh.N=f.N;fresh.Raw=f.Raw;fresh.Pre=f.Pre;fresh.Strong=f.Strong;fresh.Output=f.Output;fresh.KeyUnits=f.KeyUnits;fresh.Flags=(int)(f.Flags&254);fresh.RankOrdinal=f.Ordinal;fresh.RankPhase=f.Phase;fresh.RankTag=f.Tag;
   foreach(int id in f.Ids)fresh.ids.Add(id);foreach(byte[] key in f.Keys)fresh.keys.Add((byte[])key.Clone());
  }
  fresh.Normalize();return fresh;
 }

 // SQL Server kann UserDefined-Zustände pro Zeile transportieren. Eine verifizierte
 // Nullfolge benötigt nur Start/Anzahl statt wiederholt aller Ordinale und Schlüssel.
 // Die allgemeine AGF3-Darstellung bleibt für alle übrigen Zustände zuständig.
 bool TryUniformAdd(SqlInt32 ordinal,SqlChars key,SqlChars kind,SqlChars value,SqlByte profile){
  if(!uniformRun&&(Mask!=0||InvalidProfile||N!=0))return false;
  if(profile.IsNull||(profile.Value!=1&&profile.Value!=2)||ordinal.IsNull||ordinal.Value<=0||!value.IsNull||kind.IsNull||kind.Length!=4)return false;
  if(uniformRun&&(profile.Value!=Mask||N>=MaxN))return false;
  if(Copy(kind,4)!="null")return false;
  string keyText=ObjectMode?ordinal.Value.ToString("D",System.Globalization.CultureInfo.InvariantCulture):null;
  if(ObjectMode&&(key.IsNull||key.Length!=keyText.Length||Copy(key,key.Length)!=keyText))return false;
  if(!uniformRun){uniformRun=true;runStart=ordinal.Value;Mask=profile.Value;}
  else if(!AddRunOrdinal(ordinal.Value))return false;
  N++;if(runPacked!=null&&N==runSpan){runPacked=null;runSpan=0;}
  if(ObjectMode)KeyUnits+=keyText.Length;
  Raw=0;Pre=ObjectMode?checked(2*KeyUnits+6*N):0;Strong=Output=checked(Pre+8*N);
  AgfErrors.Need(Output+Syntax<=Cap);return true;
 }
 bool AddRunOrdinal(int ordinal){
  int width=runPacked==null?checked((int)N):runSpan;long end=(long)runStart+width-1;
  if(runPacked==null){
   if((long)ordinal==end+1)return true;
   if((long)ordinal==(long)runStart-1){runStart=ordinal;return true;}
   if(ordinal>=runStart&&ordinal<=end)return false;
  }else if(ordinal>=runStart&&ordinal<=end&&HasPackedBit(runPacked,ordinal-runStart))return false;
  int start=ordinal<runStart?ordinal:runStart;long last=ordinal>end?ordinal:end,span=last-start+1;if(span>MaxN+1L)return false;
  int size=(checked((int)span)+7)/8;byte[] encoded;
  if(runPacked!=null&&start==runStart){
   // Nur betroffene Byteposition ändern, bereits komprimierte Runs nicht expandieren.
   int target=(ordinal-start)>>3,mask=1<<((ordinal-start)&7),position=0,used=0;
   int oldSize=(width+7)/8;int reserve=Math.Min(2*size,checked(runPacked.Length+8+2*((size-oldSize+254)/255)));byte[] own=new byte[reserve];
   for(int i=0;i<runPacked.Length;i+=2){int length=runPacked[i];byte value=runPacked[i+1];if(target>=position&&target<position+length){AppendPacked(own,ref used,target-position,value);AppendPacked(own,ref used,1,(byte)(value|mask));AppendPacked(own,ref used,position+length-target-1,value);}else AppendPacked(own,ref used,length,value);position+=length;}
   if(target>=position){AppendPacked(own,ref used,target-position,0);AppendPacked(own,ref used,1,(byte)mask);}
   encoded=new byte[used];Array.Copy(own,encoded,used);
  }else{
   // Seltene Verschiebung der Untergrenze oder erstmalige Run-Konvertierung.
   byte[] bits=new byte[size];int shift=runStart-start;
   for(int i=0;i<width;i++)if(runPacked==null||HasPackedBit(runPacked,i))bits[(i+shift)>>3]|=(byte)(1<<((i+shift)&7));
   bits[(ordinal-start)>>3]|=(byte)(1<<((ordinal-start)&7));encoded=Pack(bits);
  }
  runPacked=encoded;runStart=start;runSpan=checked((int)span);return true;
 }
 static void AppendPacked(byte[] own,ref int used,int length,byte value){
  if(length==0)return;
  if(used>0&&own[used-1]==value&&own[used-2]<255){int take=Math.Min(255-own[used-2],length);own[used-2]=(byte)(own[used-2]+take);length-=take;}
  while(length>0){int take=Math.Min(255,length);AgfErrors.Need(used+2<=own.Length);own[used++]=(byte)take;own[used++]=value;length-=take;}
 }
 static byte[] Pack(byte[] bits){
  byte[] own=new byte[2*bits.Length];int used=0;for(int i=0;i<bits.Length;){int length=1;while(length<255&&i+length<bits.Length&&bits[i+length]==bits[i])length++;AppendPacked(own,ref used,length,bits[i]);i+=length;}byte[] result=new byte[used];Array.Copy(own,result,used);return result;
 }
 static byte PackedByte(byte[] packed,int target){int at=0;for(int i=0;i<packed.Length;i+=2){if(target<at+packed[i])return packed[i+1];at+=packed[i];}throw AgfErrors.State();}
 static bool HasPackedBit(byte[] packed,int at){return (PackedByte(packed,at>>3)&(1<<(at&7)))!=0;}
 static int PopByte(byte b){int x=b;x-=((x>>1)&85);x=(x&51)+((x>>2)&51);return (x+(x>>4))&15;}
 static int CountPackedBits(byte[] packed,int first,int last){
  int firstByte=first>>3,lastByte=last>>3,at=0,count=0;
  for(int i=0;i<packed.Length;i+=2){int end=at+packed[i]-1,lo=at>firstByte?at:firstByte,hi=Math.Min(end,lastByte);byte value=packed[i+1];if(hi>=lo){count+=(hi-lo+1)*PopByte(value);if(lo==firstByte&&(first&7)!=0)count-=PopByte((byte)(value&((1<<(first&7))-1)));if(hi==lastByte&&(last&7)!=7)count-=PopByte((byte)(value&~((1<<((last&7)+1))-1)));}at=end+1;}return count;
 }
 void MaterializeRun(){
  if(!uniformRun)return;
  int width=runPacked==null?checked((int)N):runSpan;
  for(int i=0;i<width;i++)if(runPacked==null||HasPackedBit(runPacked,i)){
   int ordinal=checked(runStart+i);string key=ObjectMode?ordinal.ToString("D",System.Globalization.CultureInfo.InvariantCulture):null;
   ids.Add(ordinal);if(ObjectMode)keys.Add(ValidCodec.Units(key));payload.Add(new VEntry(ordinal,key,2,null));
  }
  uniformRun=false;runStart=runSpan=0;runPacked=null;
 }
 static bool IsRunPrefix(byte[] b){return b.Length==8&&b[0]==84&&b[1]==66&&b[2]==88&&b[3]==82&&b[4]==85&&b[5]==78&&b[6]==49&&b[7]==0;}
 internal bool WriteRun(BinaryWriter writer){
  Usable();if(!uniformRun)return false;
  AgfErrors.Need(writer!=null&&Outcome()=="VALID"&&N>0&&N<=MaxN&&(long)runStart+(runSpan==0?N:runSpan)-1<=Int32.MaxValue);
  int bytes=runPacked==null?0:runPacked.Length;byte[] packed=runPacked;
  byte[] body=new byte[32+bytes];body[0]=84;body[1]=66;body[2]=88;body[3]=82;body[4]=85;body[5]=78;body[6]=49;
  body[8]=(byte)(ObjectMode?1:0);body[9]=(byte)Profile;
  int count=checked((int)N);for(int i=0;i<4;i++){body[12+i]=(byte)((runStart>>(8*i))&255);body[16+i]=(byte)((count>>(8*i))&255);body[20+i]=(byte)((runSpan>>(8*i))&255);body[24+i]=(byte)((bytes>>(8*i))&255);}
  if(packed!=null)Array.Copy(packed,0,body,32,bytes);
  byte[] digest;using(System.Security.Cryptography.SHA256 hash=new System.Security.Cryptography.SHA256Managed())digest=hash.ComputeHash(body);
  writer.Write(body);writer.Write(digest);return true;
 }
 static byte[] ReadRunBytes(Stream input,int count){
  AgfErrors.Need(count>=0&&count<=25002);byte[] own=new byte[count];int used=0;
  while(used<count){int size=Math.Min(2048,count-used);Array.Copy(FaultCodec.Exact(input,size),0,own,used,size);used+=size;}return own;
 }
 static OwnedAggregateBuilder ReadRun(Stream input,byte[] prefix,bool expectedMode){
  byte[] header=new byte[32];Array.Copy(prefix,header,8);Array.Copy(FaultCodec.Exact(input,24),0,header,8,24);
  AgfErrors.Need(header[8]==(expectedMode?1:0)&&(header[9]==1||header[9]==2)&&BitConverter.IsLittleEndian&&header[10]==0&&header[11]==0);
  for(int i=28;i<32;i++)AgfErrors.Need(header[i]==0);
  int start=BitConverter.ToInt32(header,12),count=BitConverter.ToInt32(header,16),span=BitConverter.ToInt32(header,20);int max=ValidCodec.MaxN(header[9]);
  AgfErrors.Need(start>0&&count>0&&count<=max&&(span==0||(span>count&&span<=max+1))&&(long)start+(span==0?count:span)-1<=Int32.MaxValue);
  int size=span==0?0:(span+7)/8,encoded=BitConverter.ToInt32(header,24);
  AgfErrors.Need(span==0?encoded==0:encoded>0&&encoded%2==0&&encoded<=2*size);
  byte[] packed=ReadRunBytes(input,encoded);byte[] body=new byte[32+encoded];Array.Copy(header,body,32);Array.Copy(packed,0,body,32,encoded);
  byte[] actual=FaultCodec.Exact(input,32);using(System.Security.Cryptography.SHA256 hash=new System.Security.Cryptography.SHA256Managed())AgfErrors.Need(ValidCodec.Equal(actual,hash.ComputeHash(body)));
  int at=0,pop=0;for(int i=0;i<encoded;i+=2){int length=packed[i];AgfErrors.Need(length>0&&length<=size-at&&(i==0||packed[i+1]!=packed[i-1]||packed[i-2]==255));at+=length;pop+=length*PopByte(packed[i+1]);}AgfErrors.Need(at==size);
  if(span>0){AgfErrors.Need((packed[1]&1)!=0&&(packed[encoded-1]&(1<<((span-1)&7)))!=0&&pop==count);if((span&7)!=0)AgfErrors.Need((packed[encoded-1]&~((1<<(span&7))-1))==0);}
  OwnedAggregateBuilder fresh=new OwnedAggregateBuilder(expectedMode);fresh.uniformRun=true;fresh.runStart=start;fresh.Mask=header[9];fresh.N=count;fresh.runSpan=span;fresh.runPacked=span==0?null:packed;
  if(expectedMode){long end=(long)start+(span==0?count:span)-1,lo=1;for(int digits=1;digits<=10;digits++){long hi=lo*10-1;long first=lo>start?lo:start,last=Math.Min(hi,end);if(last>=first){long entries=span==0?last-first+1:CountPackedBits(packed,checked((int)(first-start)),checked((int)(last-start)));fresh.KeyUnits=checked(fresh.KeyUnits+entries*digits);}lo*=10;}}
  fresh.Pre=expectedMode?checked(2*fresh.KeyUnits+6*fresh.N):0;fresh.Strong=fresh.Output=checked(fresh.Pre+8*fresh.N);AgfErrors.Need(fresh.Output+fresh.Syntax<=fresh.Cap);return fresh;
 }

 public static OwnedAggregateBuilder Read(Stream input,bool expectedMode){
  byte[] prefix=FaultCodec.Exact(input,8);
  if(IsRunPrefix(prefix))return ReadRun(input,prefix,expectedMode);
  byte[] header=new byte[112];Array.Copy(prefix,header,8);Array.Copy(FaultCodec.Exact(input,104),0,header,8,104);
  using(HeaderReplayStream replay=new HeaderReplayStream(input,header))return FromTransport(Dispatcher.Read(replay,expectedMode));
 }
 public void Write(Stream output){using(BinaryWriter writer=new BinaryWriter(output,Encoding.UTF8,true)){if(WriteRun(writer))return;}byte[] frame=Dispatcher.Write(Transport());output.Write(frame,0,frame.Length);}
}

}
