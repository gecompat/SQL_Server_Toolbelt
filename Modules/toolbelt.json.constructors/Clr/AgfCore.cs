using System;
using System.Text;
using System.Globalization;
namespace Toolbelt.JsonConstructors {
public enum JsonPolicy { LegacyJson, AgfJson }
public sealed class JsonScanResult { public int Status,FirstFaultOffset=-1,MaxOpenDepthObserved,MaxStoredFrames,ValidDepth=-1; }
public sealed class EntryResult { public JsonScanResult Scan; public int Code,State; public string Fragment; public long RawBytes,KeyBytes,StrongBytes,FragmentBytes;public int OutputAllocated,RawPhase;public bool StrongValid; }
public static class JsonCanonicalCore {
 static EntryResult Error(EntryResult r,int c,int s){r.Code=c;r.State=s;return r;}
 static bool Utf16(string x){if(x==null)return true;for(int i=0;i<x.Length;i++){char c=x[i];if(Char.IsHighSurrogate(c)){if(i+1==x.Length||!Char.IsLowSurrogate(x[i+1]))return false;i++;}else if(Char.IsLowSurrogate(c))return false;}return true;}
 static bool Digit(char c){return c>='0'&&c<='9';}
 static int ReadNumber(string x,ref int i){if(i<x.Length&&x[i]=='-')i++;if(i<x.Length&&x[i]=='0')i++;else if(i<x.Length&&x[i]>='1'&&x[i]<='9'){i++;while(i<x.Length&&Digit(x[i]))i++;}else return 3;if(i<x.Length&&x[i]=='.'){i++;int start=i;while(i<x.Length&&Digit(x[i]))i++;if(i==start)return 4;}if(i<x.Length&&(x[i]=='e'||x[i]=='E')){i++;if(i<x.Length&&(x[i]=='+'||x[i]=='-'))i++;int start=i;while(i<x.Length&&Digit(x[i]))i++;if(i==start)return 5;}return 0;}
 static int NumberState(string x){int i=0;int e=ReadNumber(x,ref i);return e!=0?e:i==x.Length?0:6;}
 static bool White(char c){return c==' '||c=='\t'||c=='\r'||c=='\n';}
 static void Spaces(string x,ref int p){while(p<x.Length&&White(x[p]))p++;}
 static int Hex(char c){return c>='0'&&c<='9'?c-'0':c>='a'&&c<='f'?c-'a'+10:c>='A'&&c<='F'?c-'A'+10:-1;}
 static bool JsonString(string x,ref int p,out int fault){fault=p;if(p>=x.Length||x[p]!='"')return false;p++;while(p<x.Length){int pos=p;char c=x[p++];if(c=='"')return true;if(c<32){fault=pos;return false;}if(c=='\\'){if(p==x.Length){fault=p;return false;}int ep=p;char e=x[p++];if(e=='u'){for(int j=0;j<4;j++){if(p==x.Length){fault=p;return false;}if(Hex(x[p])<0){fault=p;return false;}p++;}}else if(e!='"'&&e!='\\'&&e!='/'&&e!='b'&&e!='f'&&e!='n'&&e!='r'&&e!='t'){fault=ep;return false;}}}fault=p;return false;}
 static bool Atom(string x,ref int p,string word,out int fault){for(int i=0;i<word.Length;i++){if(p+i>=x.Length||x[p+i]!=word[i]){fault=p+i;return false;}}p+=word.Length;fault=-1;return true;}
 static bool Value(string x,ref int p,int[] frames,ref int depth,JsonPolicy policy,JsonScanResult r){if(p==x.Length){r.FirstFaultOffset=p;return false;}char c=x[p];if(c=='['||c=='{'){r.MaxOpenDepthObserved=Math.Max(r.MaxOpenDepthObserved,depth+1);if(policy==JsonPolicy.AgfJson&&depth==127){r.Status=2;r.FirstFaultOffset=p;return false;}frames[depth++]=c=='['?0:3;r.MaxStoredFrames=Math.Max(r.MaxStoredFrames,depth);p++;return true;}int fault=p;bool ok;if(c=='"')ok=JsonString(x,ref p,out fault);else if(c=='t')ok=Atom(x,ref p,"true",out fault);else if(c=='f')ok=Atom(x,ref p,"false",out fault);else if(c=='n')ok=Atom(x,ref p,"null",out fault);else if(c=='-'||Digit(c)){ok=ReadNumber(x,ref p)==0;fault=p;}else ok=false;if(!ok)r.FirstFaultOffset=fault;return ok;}
 // Explizite Adapterpolicy; AGF speichert niemals Frame128. Legacy hat keine AGF-Grenze.
 public static JsonScanResult ScanJson(string x,JsonPolicy policy){if(policy!=JsonPolicy.AgfJson&&policy!=JsonPolicy.LegacyJson)throw new ArgumentException("POLICY");if(x==null)throw new ArgumentNullException("x");JsonScanResult r=new JsonScanResult();int p=0;Spaces(x,ref p);if(p==x.Length||(x[p]!='['&&x[p]!='{')){r.Status=1;r.FirstFaultOffset=p;return r;}int[] frames=new int[policy==JsonPolicy.AgfJson?127:x.Length+1];int depth=0;if(!Value(x,ref p,frames,ref depth,policy,r)){if(r.Status==0)r.Status=1;return r;}while(depth>0){Spaces(x,ref p);if(p==x.Length){r.Status=1;r.FirstFaultOffset=p;return r;}int d=depth-1,st=frames[d];char c=x[p];bool ok=true;int fault=p;if(st==0||st==1){if(st==0&&c==']'){p++;depth--;continue;}frames[d]=2;ok=Value(x,ref p,frames,ref depth,policy,r);}else if(st==2){if(c==']'){p++;depth--;}else if(c==','){p++;frames[d]=1;}else ok=false;}else if(st==3||st==4){if(st==3&&c=='}'){p++;depth--;continue;}ok=JsonString(x,ref p,out fault);if(ok)frames[d]=5;}else if(st==5){if(c!=':')ok=false;else{p++;frames[d]=6;}}else if(st==6){frames[d]=7;ok=Value(x,ref p,frames,ref depth,policy,r);}else if(st==7){if(c=='}'){p++;depth--;}else if(c==','){p++;frames[d]=4;}else ok=false;}else throw new InvalidOperationException("FRAME");if(!ok){if(r.Status==0)r.Status=1;if(r.FirstFaultOffset<0)r.FirstFaultOffset=fault;return r;}}Spaces(x,ref p);if(p!=x.Length){r.Status=1;r.FirstFaultOffset=p;return r;}r.ValidDepth=r.MaxOpenDepthObserved;return r;}
 static int DecodedState(string x){if(x.IndexOf("\\u",StringComparison.Ordinal)<0)return 0;bool inside=false,pending=false;int p=0;while(p<x.Length){int unit=x[p];if(!inside){if(unit==34){inside=true;pending=false;}p++;}else if(unit==34){if(pending)return 2;inside=false;p++;}else{if(unit==92){int next=x[p+1];if(next==117){unit=0;for(int j=0;j<4;j++)unit=unit*16+Hex(x[p+2+j]);p+=6;}else{unit=next;p+=2;}}else p++;if(pending){if(unit<56320||unit>57343)return 3;pending=false;}else if(unit>=55296&&unit<=56319)pending=true;else if(unit>=56320&&unit<=57343)return 4;}}return 0;}
 static int EscapeUnits(char c){if(c=='"'||c=='\\'||c=='/')return 2;if(c=='\b'||c=='\f'||c=='\n'||c=='\r'||c=='\t')return 2;return c<32?6:1;}
 static long EscapedUnits(string x){long n=0;foreach(char c in x)n=checked(n+EscapeUnits(c));return n;}
 static string Escape(string x){StringBuilder b=new StringBuilder();foreach(char c in x){switch(c){case '"':b.Append("\\\"");break;case '\\':b.Append("\\\\");break;case '/':b.Append("\\/");break;case '\b':b.Append("\\b");break;case '\f':b.Append("\\f");break;case '\n':b.Append("\\n");break;case '\r':b.Append("\\r");break;case '\t':b.Append("\\t");break;default:if(c<32){b.Append("\\u");b.Append(((int)c).ToString("x4",CultureInfo.InvariantCulture));}else b.Append(c);break;}}return b.ToString();}
 // Gemeinsame Vorbedingungen/Kosten und Raw-UTF16; Key vor Value, kein Literal-/Syntaxscan.
 public static EntryResult RawOnlyEntry(bool obj,string key,string kind,string value){
  EntryResult r=new EntryResult();r.RawBytes=value==null?0:checked(2L*value.Length);r.KeyBytes=obj&&key!=null?checked(2L*key.Length):0;
  if(obj&&(key==null||key.Length==0||key.Length>1024))return Error(r,53603,1);
  if(kind==null||kind.Length>7)return Error(r,53605,2);
  if(kind!="string"&&kind!="null"&&kind!="boolean"&&kind!="number"&&kind!="json")return Error(r,53605,1);
  if((kind=="null")!=(value==null))return Error(r,53606,1);
  r.StrongBytes=checked((kind=="null"?8:r.RawBytes)+(kind=="string"?4:0)+(obj?r.KeyBytes+6:0));r.StrongValid=true;
  if(obj&&!Utf16(key)){r.RawPhase=1;return Error(r,53607,1);}
  if(!Utf16(value)){r.RawPhase=2;return Error(r,53607,1);}
  return r;
 }
 public static EntryResult Evaluate(bool obj,string key,string kind,string value,JsonPolicy policy,bool materializeFragment){EntryResult r=RawOnlyEntry(obj,key,kind,value);if(r.Code!=0)return r;if(kind=="json"){r.Scan=ScanJson(value,policy);if(r.Scan.Status==2)return Error(r,912,1);if(r.Scan.Status!=0)return Error(r,53608,2);int decoded=DecodedState(value);if(decoded!=0)return Error(r,53607,decoded);}if(kind=="boolean"&&value!="true"&&value!="false")return Error(r,53608,1);if(kind=="number"){int state=NumberState(value);if(state!=0)return Error(r,53608,state);}long tokenUnits=kind=="string"?checked(EscapedUnits(value)+2):kind=="null"?4:value.Length;long memberUnits=checked(tokenUnits+(obj?EscapedUnits(key)+3:0));r.FragmentBytes=checked(2*memberUnits);if(!materializeFragment)return r;string token=kind=="string"?"\""+Escape(value)+"\"":kind=="null"?"null":value;r.Fragment=obj?"\""+Escape(key)+"\":"+token:token;r.OutputAllocated=1;if(r.FragmentBytes!=checked(2L*r.Fragment.Length))throw new InvalidOperationException("COST");return r;}
}

}
