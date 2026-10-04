using System;
using System.IO;
using System.Text;
using System.Security.Cryptography;
namespace Toolbelt.JsonConstructors {
public sealed class FaultState {
 public readonly byte Mode,Class,Mask;public readonly uint Flags;
 public readonly long N,Raw,Pre,Strong,Output,KeyUnits;public readonly int Ordinal;public readonly ushort Phase,Tag;
 public readonly int[] Ids;public readonly byte[][] Keys;
 public FaultState(byte mode,byte cls,byte mask,uint flags,long n,long raw,long pre,long strong,long output,long units,int[] ids,byte[][] keys,int ordinal,ushort phase,ushort tag){
  Mode=mode;Class=cls;Mask=mask;Flags=flags;N=n;Raw=raw;Pre=pre;Strong=strong;Output=output;KeyUnits=units;Ordinal=ordinal;Phase=phase;Tag=tag;
  FaultCodec.Need(ids!=null&&keys!=null);Ids=(int[])ids.Clone();Keys=new byte[keys.Length][];for(int i=0;i<keys.Length;i++){FaultCodec.Need(keys[i]!=null);Keys[i]=(byte[])keys[i].Clone();}
 }
}
public sealed class FaultHeader {
 public long Total,N,Raw,Pre,Strong,Output,KeyUnits,PayloadBytes;public byte Mode,Class,Mask;public uint Flags;
 public int Ni,Nk,Np,Ordinal;public ushort Phase,Tag;
}
public static class FaultCodec {
 static readonly byte[] Magic={84,66,88,65,71,70,51,0};static readonly ByteOrder Order=new ByteOrder();
 public static void Need(bool b){if(!b)throw AgfErrors.State();}
 public static ushort PhaseFor(ushort tag){Need(tag>=1&&tag<=12);if(tag==1)return 0;if(tag==2)return 1;if(tag>=9&&tag<=11)return 3;return 2;}
 public static bool LegacySql(ushort tag,out int number,out int state){number=state=0;if(tag==12)return false;Need(tag>=1&&tag<=11);number=(tag==1||tag==2||tag>=9)?53607:53608;state=tag>=4&&tag<=7?tag-1:tag==8?2:tag>=9?tag-7:1;return true;}
 public static byte[] Exact(Stream s,int n){Need(n>=0&&n<=2048);byte[] b=new byte[n];int p=0;while(p<n){int got=s.Read(b,p,n-p);Need(got>0&&got<=n-p);p+=got;}return b;}
 public static FaultHeader Parse(byte[] bytes,bool host){Need(bytes!=null&&bytes.Length==112);FaultHeader h=new FaultHeader();using(BinaryReader b=new BinaryReader(new MemoryStream(bytes))){
  Need(ValidCodec.Equal(b.ReadBytes(8),Magic)&&b.ReadUInt16()==3&&b.ReadUInt16()==112);h.Total=b.ReadInt64();h.Mode=b.ReadByte();h.Class=b.ReadByte();h.Mask=b.ReadByte();Need(b.ReadByte()==0);h.Flags=b.ReadUInt32();h.N=b.ReadInt64();h.Raw=b.ReadInt64();h.Pre=b.ReadInt64();h.Strong=b.ReadInt64();h.Output=b.ReadInt64();h.KeyUnits=b.ReadInt64();h.Ni=b.ReadInt32();h.Nk=b.ReadInt32();h.Np=b.ReadInt32();h.Ordinal=b.ReadInt32();h.Phase=b.ReadUInt16();h.Tag=b.ReadUInt16();h.PayloadBytes=b.ReadInt64();Need(ValidCodec.Equal(b.ReadBytes(8),new byte[8]));
 }Need(h.Mode<=1&&(h.Mode==1)==host&&h.Class<=4);return h;}
 static bool AnyData(FaultHeader h){return h.N!=0||h.Raw!=0||h.Pre!=0||h.Strong!=0||h.Output!=0||h.KeyUnits!=0||h.Ni!=0||h.Nk!=0||h.Ordinal!=0||h.Phase!=0||h.Tag!=0;}
 static bool LateOrBudget(FaultHeader h,long cap){return (h.Flags&254)!=0||h.Raw>cap||h.Pre+checked(2*h.N+2)>cap||h.Strong+checked(2*h.N+2)>cap||h.Output+checked(2*h.N+2)>cap||h.Tag!=0;}
 public static void HeaderGate(FaultHeader h){
  Need(h.Class<=3&&h.Mask<=3&&h.Flags<=255&&h.Total>=144&&h.Total<=(h.Mask==1||h.Mask==2?ValidCodec.StateCap(h.Mask):144));
  Need(h.Np==0&&h.PayloadBytes==0&&h.N>=0&&h.Raw>=0&&h.Pre>=0&&h.Strong>=0&&h.Output>=0&&h.KeyUnits>=0&&h.Ni>=0&&h.Nk>=0&&h.Ordinal>=0);
  if(h.Tag!=0){Need(h.Tag<=12&&h.Phase==PhaseFor(h.Tag)&&h.Ordinal>0);Need(h.Tag!=1||h.Mode==1);}else Need(h.Ordinal==0&&h.Phase==0);
  if(h.Class==0||h.Class==2){Need(h.Total==144&&!AnyData(h));if(h.Class==0)Need(h.Mask==0&&h.Flags==0);else Need((h.Mask==3||h.Flags==1)&&(h.Flags==0||h.Flags==1));return;}
  Need((h.Mask==1||h.Mask==2)&&(h.Flags&1)==0);long cap=ValidCodec.Cap(h.Mask);int max=ValidCodec.MaxN(h.Mask);
  if(h.Class==1){Need(h.Total==144&&h.N==max+1L&&h.Flags==0&&h.Raw==0&&h.Pre==0&&h.Strong==0&&h.Output==0&&h.KeyUnits==0&&h.Ni==0&&h.Nk==0&&h.Tag==0);return;}
  Need(h.N>=1&&h.N<=max&&h.Raw<=cap+1&&h.Pre<=cap+1&&h.Strong<=cap+1&&h.Output<=cap+1&&h.KeyUnits<=cap/2);
  bool badOrd=(h.Flags&2)!=0,dupOrd=(h.Flags&4)!=0;
  Need(h.Ni<=h.N-(badOrd?1:0)-(dupOrd?1:0));if(dupOrd)Need(h.Ni>0);if(!badOrd&&!dupOrd)Need(h.Ni==h.N);
  Need(h.Nk<=h.N&&h.Nk<=h.KeyUnits&&h.KeyUnits<=1024L*h.Nk);if(h.Tag!=0)Need(h.Ni>0);
  Need(h.Total==checked(144+4L*h.Ni+4L*h.Nk+2*h.KeyUnits));long syntax=checked(2*h.N+2);bool discard=h.Raw>cap||h.Pre+syntax>cap;
  if(h.Mode==0)Need(h.Nk==0&&h.KeyUnits==0&&(h.Flags&(8|32))==0&&h.Pre==h.Raw);
  else{Need(h.Pre>=h.Raw);if(h.Pre<cap+1)Need(h.Pre>=checked(h.Raw+6*h.N));if(!discard){bool badKey=(h.Flags&8)!=0,dupKey=(h.Flags&32)!=0;Need(h.Nk<=h.N-(badKey?1:0)-(dupKey?1:0));if(dupKey)Need(h.Nk>0);if(!badKey&&!dupKey)Need(h.Nk==h.N);Need(2*h.KeyUnits<=h.Pre-h.Raw-6*h.N);}}
  if(discard)Need(h.Nk==0&&h.KeyUnits==0&&(h.Flags&32)==0);Need(LateOrBudget(h,cap));
 }
 static FaultHeader View(FaultState s){Need(s!=null);FaultHeader h=new FaultHeader();h.Mode=s.Mode;h.Class=s.Class;h.Mask=s.Mask;h.Flags=s.Flags;h.N=s.N;h.Raw=s.Raw;h.Pre=s.Pre;h.Strong=s.Strong;h.Output=s.Output;h.KeyUnits=s.KeyUnits;h.Ni=s.Ids.Length;h.Nk=s.Keys.Length;h.Ordinal=s.Ordinal;h.Phase=s.Phase;h.Tag=s.Tag;h.Total=checked(144+4L*h.Ni+4L*h.Nk+2*h.KeyUnits);Need(h.Mode<=1);return h;}
 static void Sections(FaultHeader h,int[] ids,byte[][] keys){Need(ids.Length==h.Ni&&keys.Length==h.Nk);for(int i=0;i<ids.Length;i++)Need(ids[i]>0&&(i==0||ids[i]>ids[i-1]));long units=0;for(int i=0;i<keys.Length;i++){Need(keys[i]!=null&&keys[i].Length>0&&keys[i].Length<=2048&&keys[i].Length%2==0);units=checked(units+keys[i].Length/2);Need(units<=h.KeyUnits);Need(i==0||Order.Compare(keys[i-1],keys[i])<0);}Need(units==h.KeyUnits);if(h.Tag!=0)Need(Array.BinarySearch(ids,h.Ordinal)>=0);}
 static byte[] HeaderBytes(FaultHeader h){using(MemoryStream ms=new MemoryStream()){using(BinaryWriter b=new BinaryWriter(ms,Encoding.UTF8,true)){b.Write(Magic);b.Write((ushort)3);b.Write((ushort)112);b.Write(h.Total);b.Write(h.Mode);b.Write(h.Class);b.Write(h.Mask);b.Write((byte)0);b.Write(h.Flags);b.Write(h.N);b.Write(h.Raw);b.Write(h.Pre);b.Write(h.Strong);b.Write(h.Output);b.Write(h.KeyUnits);b.Write(h.Ni);b.Write(h.Nk);b.Write(0);b.Write(h.Ordinal);b.Write(h.Phase);b.Write(h.Tag);b.Write(0L);b.Write(new byte[8]);b.Flush();byte[] bytes=ms.ToArray();Need(bytes.Length==112);return bytes;}}}
 public static byte[] Write(FaultState s){FaultHeader h=View(s);HeaderGate(h);Sections(h,s.Ids,s.Keys);using(MemoryStream ms=new MemoryStream()){using(BinaryWriter b=new BinaryWriter(ms,Encoding.UTF8,true)){b.Write(HeaderBytes(h));foreach(int id in s.Ids)b.Write(id);foreach(byte[] key in s.Keys){b.Write(key.Length);b.Write(key);}b.Flush();byte[] prefix=ms.ToArray();Need(prefix.LongLength==h.Total-32);using(SHA256 hash=SHA256.Create())b.Write(hash.ComputeHash(prefix));b.Flush();return ms.ToArray();}}}
 public static FaultState ReadBody(Stream stream,byte[] header,FaultHeader h){HeaderGate(h);long remaining=h.Total-144;using(SHA256 hash=SHA256.Create()){
  hash.TransformBlock(header,0,112,header,0);int[] ids=new int[h.Ni];byte[][] keys=new byte[h.Nk][];
  for(int i=0;i<ids.Length;i++){Need(remaining>=4);byte[] b=Exact(stream,4);remaining-=4;hash.TransformBlock(b,0,4,b,0);ids[i]=BitConverter.ToInt32(b,0);Need(ids[i]>0&&(i==0||ids[i]>ids[i-1]));}
  long sum=0;for(int i=0;i<keys.Length;i++){Need(remaining>=4);byte[] b=Exact(stream,4);remaining-=4;hash.TransformBlock(b,0,4,b,0);int length=BitConverter.ToInt32(b,0);Need(length>0&&length<=2048&&length%2==0&&length<=remaining);sum=checked(sum+length);Need(sum<=2*h.KeyUnits);keys[i]=Exact(stream,length);remaining-=length;hash.TransformBlock(keys[i],0,length,keys[i],0);Need(i==0||Order.Compare(keys[i-1],keys[i])<0);}
  Need(remaining==0);hash.TransformFinalBlock(new byte[0],0,0);Need(ValidCodec.Equal(Exact(stream,32),hash.Hash));Sections(h,ids,keys);
  return new FaultState(h.Mode,h.Class,h.Mask,h.Flags,h.N,h.Raw,h.Pre,h.Strong,h.Output,h.KeyUnits,ids,keys,h.Ordinal,h.Phase,h.Tag);
 }}
}

}
