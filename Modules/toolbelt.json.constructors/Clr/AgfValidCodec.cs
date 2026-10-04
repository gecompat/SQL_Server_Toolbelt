using System;
using System.IO;
using System.Text;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Globalization;
namespace Toolbelt.JsonConstructors {

public sealed class VEntry {
 public readonly int Ordinal;public readonly string Key,Value;public readonly byte Kind;
 public VEntry(int ordinal,string key,byte kind,string value){Ordinal=ordinal;Key=key;Kind=kind;Value=value;}
}
public sealed class VState {
 public readonly bool ObjectMode;public readonly byte Profile;public readonly VEntry[] Entries;public readonly byte[][] Keys;
 public readonly long Raw,Pre,Strong,Output,KeyUnits,FrameBytes;
 public VState(bool mode,byte profile,VEntry[] entries,byte[][] keys,long raw,long pre,long strong,long output,long units,long frame){ObjectMode=mode;Profile=profile;Entries=entries;Keys=keys;Raw=raw;Pre=pre;Strong=strong;Output=output;KeyUnits=units;FrameBytes=frame;}
}
public sealed class ByteOrder : IComparer<byte[]> {
 public int Compare(byte[] a,byte[] b){int n=Math.Min(a.Length,b.Length);for(int i=0;i<n;i++){int c=a[i].CompareTo(b[i]);if(c!=0)return c;}return a.Length.CompareTo(b.Length);}
}
public static class ValidCodec {
 static readonly byte[] Magic={84,66,88,65,71,70,51,0};
 static readonly ByteOrder Order=new ByteOrder();
 public static void Need(bool b){if(!b)throw AgfErrors.State();}
 public static int MaxN(byte p){Need(p==1||p==2);return p==1?10000:100000;}
 public static long Cap(byte p){Need(p==1||p==2);return p==1?2097152L:16777216L;}
 public static long StateCap(byte p){Need(p==1||p==2);return p==1?5242880L:37748736L;}
 public static string Kind(byte k){switch(k){case 1:return "string";case 2:return "null";case 3:return "boolean";case 4:return "number";case 5:return "json";default:throw AgfErrors.State();}}
 // Wiretransport der Codeunits; kein Encoderreplacement und kein JSON-Escaper.
 public static byte[] Units(string value){Need(value!=null);byte[] b=new byte[checked(value.Length*2)];for(int i=0;i<value.Length;i++){b[2*i]=(byte)(value[i]&255);b[2*i+1]=(byte)(value[i]>>8);}return b;}
 public static string Text(byte[] b){Need(b.Length%2==0);char[] c=new char[b.Length/2];for(int i=0;i<c.Length;i++)c[i]=(char)(b[2*i]|b[2*i+1]<<8);return new string(c);}
 public static bool Equal(byte[] a,byte[] b){if(a.Length!=b.Length)return false;for(int i=0;i<a.Length;i++)if(a[i]!=b[i])return false;return true;}
 public static VState Build(bool mode,byte profile,VEntry[] input){
  Need(input!=null&&input.Length>0&&input.Length<=MaxN(profile));VEntry[] es=(VEntry[])input.Clone();
  Array.Sort(es,delegate(VEntry a,VEntry b){Need(a!=null&&b!=null);return a.Ordinal.CompareTo(b.Ordinal);});
  long raw=0,pre=0,strong=0,output=0,keyBytes=0;List<byte[]> ks=new List<byte[]>();
  for(int i=0;i<es.Length;i++){
   VEntry e=es[i];Need(e!=null&&e.Ordinal>0&&(i==0||e.Ordinal>es[i-1].Ordinal));
   string kind=Kind(e.Kind);EntryResult r=JsonCanonicalCore.Evaluate(mode,e.Key,kind,e.Value,JsonPolicy.AgfJson,false);Need(r.Code==0);
   raw=checked(raw+r.RawBytes);pre=checked(pre+r.RawBytes+r.KeyBytes+(mode?6:0));strong=checked(strong+r.StrongBytes);output=checked(output+r.FragmentBytes);
   Need(raw<=Cap(profile)&&pre+2L*es.Length+2<=Cap(profile)&&strong+2L*es.Length+2<=Cap(profile)&&output+2L*es.Length+2<=Cap(profile));
   if(mode){byte[] key=Units(e.Key);keyBytes=checked(keyBytes+key.Length);Need(keyBytes<=Cap(profile));ks.Add(key);}
   else es[i]=new VEntry(e.Ordinal,null,e.Kind,e.Value);
  }
  byte[][] keys=ks.ToArray();Array.Sort(keys,Order);for(int i=1;i<keys.Length;i++)Need(Order.Compare(keys[i-1],keys[i])<0);
  long total=checked(144L+4L*es.Length+4L*keys.Length+keyBytes+16L*es.Length+raw);Need(total<=StateCap(profile));
  return new VState(mode,profile,es,keys,raw,pre,strong,output,keyBytes/2,total);
 }
 public static byte[] Write(VState state){
  Need(state!=null);VState s=Build(state.ObjectMode,state.Profile,state.Entries);Need(s.Raw==state.Raw&&s.Pre==state.Pre&&s.Strong==state.Strong&&s.Output==state.Output&&s.KeyUnits==state.KeyUnits&&s.FrameBytes==state.FrameBytes);
  Need(s.Keys.Length==state.Keys.Length);for(int i=0;i<s.Keys.Length;i++)Need(Equal(s.Keys[i],state.Keys[i]));
  using(MemoryStream ms=new MemoryStream()){
   using(BinaryWriter b=new BinaryWriter(ms,Encoding.UTF8,true)){
    b.Write(Magic);b.Write((ushort)3);b.Write((ushort)112);b.Write(s.FrameBytes);b.Write((byte)(s.ObjectMode?1:0));b.Write((byte)4);b.Write(s.Profile);b.Write((byte)0);b.Write((uint)0);
    b.Write((long)s.Entries.Length);b.Write(s.Raw);b.Write(s.Pre);b.Write(s.Strong);b.Write(s.Output);b.Write(s.KeyUnits);
    b.Write(s.Entries.Length);b.Write(s.Keys.Length);b.Write(s.Entries.Length);b.Write(0);b.Write((ushort)0);b.Write((ushort)0);b.Write(s.Raw);b.Write(new byte[8]);
    foreach(VEntry e in s.Entries)b.Write(e.Ordinal);
    foreach(byte[] k in s.Keys){b.Write(k.Length);b.Write(k);}
    foreach(VEntry e in s.Entries){
     int index=s.ObjectMode?Array.BinarySearch(s.Keys,Units(e.Key),Order):-1;Need(!s.ObjectMode||index>=0);
     b.Write(e.Ordinal);b.Write(index);b.Write(e.Kind);b.Write((byte)0);b.Write((ushort)0);
     if(e.Value==null)b.Write(-1);else{byte[] raw=Units(e.Value);b.Write(raw.Length);b.Write(raw);}
    }
    b.Flush();byte[] prefix=ms.ToArray();Need(prefix.LongLength==s.FrameBytes-32);
    using(SHA256 h=SHA256.Create())b.Write(h.ComputeHash(prefix));b.Flush();return ms.ToArray();
   }
  }
 }
 sealed class Reader : IDisposable {
  readonly Stream stream;readonly SHA256 hash;public long Remaining;
  public Reader(Stream s,byte[] header,long body){stream=s;Remaining=body;hash=SHA256.Create();hash.TransformBlock(header,0,header.Length,header,0);}
  public byte[] Take(int n){Need(n>=0&&n<=32768&&n<=Remaining);byte[] b=Exact(stream,n);Remaining-=n;hash.TransformBlock(b,0,b.Length,b,0);return b;}
  // Längen-/Profil-/Remaining-Gates vor char[]; verlustlose UTF16-Chunks.
  public string TextBounded(int bytes,long cap){Need(bytes>=0&&bytes%2==0&&bytes<=cap&&bytes<=Remaining);char[] units=new char[bytes/2];int used=0;while(used<bytes){int count=Math.Min(32768,bytes-used);byte[] chunk=Take(count);for(int j=0;j<count;j+=2)units[(used+j)/2]=(char)(chunk[j]|chunk[j+1]<<8);used+=count;}return new string(units);}
  public int Int(){byte[] b=Take(4);return unchecked((int)((uint)b[0]|(uint)b[1]<<8|(uint)b[2]<<16|(uint)b[3]<<24));}
  public void Finish(){Need(Remaining==0);hash.TransformFinalBlock(new byte[0],0,0);Need(Equal(Exact(stream,32),hash.Hash));}
  public void Dispose(){hash.Dispose();}
 }
 static byte[] Exact(Stream s,int n){Need(n>=0&&n<=32768);byte[] b=new byte[n];int p=0;while(p<n){int got=s.Read(b,p,n-p);Need(got>0&&got<=n-p);p+=got;}return b;}
 public static VState Read(Stream stream,bool expectedMode){
  byte[] header=Exact(stream,112);long total,n,raw,pre,strong,output,keyunits,payloadbytes;byte profile;int ni,nk,np;
  using(BinaryReader b=new BinaryReader(new MemoryStream(header))){
   Need(Equal(b.ReadBytes(8),Magic)&&b.ReadUInt16()==3&&b.ReadUInt16()==112);total=b.ReadInt64();
   byte mode=b.ReadByte();Need(mode<=1&&(mode==1)==expectedMode);Need(b.ReadByte()==4);profile=b.ReadByte();Need(profile==1||profile==2);Need(b.ReadByte()==0&&b.ReadUInt32()==0);
   n=b.ReadInt64();raw=b.ReadInt64();pre=b.ReadInt64();strong=b.ReadInt64();output=b.ReadInt64();keyunits=b.ReadInt64();ni=b.ReadInt32();nk=b.ReadInt32();np=b.ReadInt32();
   Need(b.ReadInt32()==0&&b.ReadUInt16()==0&&b.ReadUInt16()==0);payloadbytes=b.ReadInt64();Need(Equal(b.ReadBytes(8),new byte[8]));
  }
  Need(n>0&&n<=MaxN(profile)&&ni==n&&np==n&&nk==(expectedMode?n:0));
  Need(raw>=0&&raw<=Cap(profile)&&payloadbytes==raw&&keyunits>=0&&keyunits<=Cap(profile)/2);
  Need(pre>=0&&strong>=pre&&output>=strong&&output<=Cap(profile));long syntax=checked(2*n+2);
  Need(pre+syntax<=Cap(profile)&&strong+syntax<=Cap(profile)&&output+syntax<=Cap(profile));
  Need(expectedMode?keyunits>=nk&&keyunits<=1024L*nk&&pre==checked(raw+2*keyunits+6*n):keyunits==0&&pre==raw);
  Need(total==checked(144+4L*ni+4L*nk+2*keyunits+16L*np+payloadbytes)&&total<=StateCap(profile));
  using(Reader r=new Reader(stream,header,total-144)){
   int[] ids=new int[ni];for(int i=0;i<ni;i++){ids[i]=r.Int();Need(ids[i]>0&&(i==0||ids[i]>ids[i-1]));}
   byte[][] keys=new byte[nk][];long keySum=0;
   for(int i=0;i<nk;i++){int len=r.Int();Need(len>0&&len<=2048&&len%2==0);keySum=checked(keySum+len);Need(keySum<=2*keyunits);Need(r.Remaining>=len+4L*(nk-i-1)+16L*np+payloadbytes);keys[i]=r.Take(len);Need(i==0||Order.Compare(keys[i-1],keys[i])<0);}
   Need(keySum==2*keyunits);bool[] used=new bool[nk];VEntry[] entries=new VEntry[np];long rawSum=0;
   for(int i=0;i<np;i++){
    int ordinal=r.Int(),keyIndex=r.Int();byte[] tags=r.Take(4);byte kind=tags[0];Need(kind>=1&&kind<=5&&tags[1]==0&&tags[2]==0&&tags[3]==0);int len=r.Int();Need(ordinal==ids[i]);
    string key=null;if(expectedMode){Need(keyIndex>=0&&keyIndex<nk&&!used[keyIndex]);used[keyIndex]=true;key=Text(keys[keyIndex]);}else Need(keyIndex==-1);
    Need(kind==2?len==-1:len>=0&&len%2==0);string value=null;
    if(len>=0){Need(len<=Cap(profile));rawSum=checked(rawSum+len);Need(rawSum<=payloadbytes&&r.Remaining>=len+16L*(np-i-1));value=r.TextBounded(len,Cap(profile));}
    entries[i]=new VEntry(ordinal,key,kind,value);
   }
   Need(rawSum==payloadbytes);foreach(bool u in used)Need(u);r.Finish();
   VState s=Build(expectedMode,profile,entries);Need(s.Raw==raw&&s.Pre==pre&&s.Strong==strong&&s.Output==output&&s.KeyUnits==keyunits&&s.FrameBytes==total);
   for(int i=0;i<nk;i++)Need(Equal(s.Keys[i],keys[i]));return s;
  }
 }
 public static void ReadInto(ref VState live,Stream stream,bool expectedMode){Need(live!=null&&live.ObjectMode==expectedMode);VState fresh=Read(stream,expectedMode);live=fresh;}
}


}
