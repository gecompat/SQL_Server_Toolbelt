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
 void ClearData(){N=Raw=Pre=Strong=Output=KeyUnits=0;Flags=RankOrdinal=RankPhase=RankTag=0;ids.Clear();keys.Clear();payload.Clear();}
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
  if(Object.ReferenceEquals(this,other)){MergeSelf();return;}
  Mask|=other.Mask;InvalidProfile|=other.InvalidProfile;if(InvalidProfile||Mask==3){Normalize();return;}if(Mask==0)return;
  N=Sat(checked(N+other.N),MaxN);if(N>MaxN){Normalize();return;}
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
  Usable();OwnedAggregateBuilder copy=new OwnedAggregateBuilder(ObjectMode);copy.Mask=Mask;copy.InvalidProfile=InvalidProfile;copy.N=N;copy.Raw=Raw;copy.Pre=Pre;copy.Strong=Strong;copy.Output=Output;copy.KeyUnits=KeyUnits;copy.Flags=Flags;copy.RankOrdinal=RankOrdinal;copy.RankPhase=RankPhase;copy.RankTag=RankTag;
  foreach(int id in ids)copy.ids.Add(id);foreach(byte[] key in keys)copy.keys.Add((byte[])key.Clone());foreach(VEntry e in payload)copy.payload.Add(new VEntry(e.Ordinal,e.Key,e.Kind,e.Value));return copy;
 }
 VEntry[] SortedPayload(){
  AgfErrors.Need(Outcome()=="VALID"&&payload.Count==N);VEntry[] entries=payload.ToArray();Array.Sort(entries,delegate(VEntry a,VEntry b){return a.Ordinal.CompareTo(b.Ordinal);});
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
 public static OwnedAggregateBuilder Read(Stream input,bool expectedMode){return FromTransport(Dispatcher.Read(input,expectedMode));}
 public void Write(Stream output){byte[] frame=Dispatcher.Write(Transport());output.Write(frame,0,frame.Length);}
}

}
