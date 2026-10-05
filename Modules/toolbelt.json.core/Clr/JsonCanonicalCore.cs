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
 internal static bool Digit(char c){return c>='0'&&c<='9';}
 internal static void Advance(ref int p,Toolbelt.JsonCore.JsonWorkBudget work){if(work!=null)work.Spend(1);p++;}
 internal static int ReadNumber(string x,ref int i,Toolbelt.JsonCore.JsonWorkBudget work=null){
  if(i<x.Length&&x[i]=='-')Advance(ref i,work);
  if(i<x.Length&&x[i]=='0')Advance(ref i,work);
  else if(i<x.Length&&x[i]>='1'&&x[i]<='9'){Advance(ref i,work);while(i<x.Length&&Digit(x[i]))Advance(ref i,work);}else return 3;
  if(i<x.Length&&x[i]=='.'){Advance(ref i,work);int start=i;while(i<x.Length&&Digit(x[i]))Advance(ref i,work);if(i==start)return 4;}
  if(i<x.Length&&(x[i]=='e'||x[i]=='E')){Advance(ref i,work);if(i<x.Length&&(x[i]=='+'||x[i]=='-'))Advance(ref i,work);int start=i;while(i<x.Length&&Digit(x[i]))Advance(ref i,work);if(i==start)return 5;}
  return 0;
 }
 static int NumberState(string x){int i=0;int e=ReadNumber(x,ref i);return e!=0?e:i==x.Length?0:6;}
 static bool White(char c){return c==' '||c=='\t'||c=='\r'||c=='\n';}
 internal static void Spaces(string x,ref int p,Toolbelt.JsonCore.JsonWorkBudget work=null){while(p<x.Length&&White(x[p]))Advance(ref p,work);}
 internal static int Hex(char c){return c>='0'&&c<='9'?c-'0':c>='a'&&c<='f'?c-'a'+10:c>='A'&&c<='F'?c-'A'+10:-1;}
 internal static bool JsonString(string x,ref int p,out int fault,Toolbelt.JsonCore.JsonWorkBudget work=null){
  fault=p;if(p>=x.Length||x[p]!='"')return false;Advance(ref p,work);
  while(p<x.Length){int pos=p;char c=x[p];Advance(ref p,work);if(c=='"')return true;if(c<32){fault=pos;return false;}
   if(c=='\\'){if(p==x.Length){fault=p;return false;}int ep=p;char e=x[p];Advance(ref p,work);
    if(e=='u'){for(int j=0;j<4;j++){if(p==x.Length){fault=p;return false;}if(Hex(x[p])<0){fault=p;return false;}Advance(ref p,work);}}
    else if(e!='"'&&e!='\\'&&e!='/'&&e!='b'&&e!='f'&&e!='n'&&e!='r'&&e!='t'){fault=ep;return false;}
   }
  }
  fault=p;return false;
 }
 internal static bool Atom(string x,ref int p,string word,out int fault,Toolbelt.JsonCore.JsonWorkBudget work=null){
  for(int i=0;i<word.Length;i++){if(p+i>=x.Length){fault=p+i;return false;}if(work!=null)work.Spend(1);if(x[p+i]!=word[i]){fault=p+i;return false;}}
  p+=word.Length;fault=-1;return true;
 }
 // Explizite Adapterpolicy; AGF speichert niemals Frame128. Legacy hat keine AGF-Grenze.
 public static JsonScanResult ScanJson(string x,JsonPolicy policy){
  if(policy!=JsonPolicy.AgfJson&&policy!=JsonPolicy.LegacyJson)throw new ArgumentException("POLICY");
  if(x==null)throw new ArgumentNullException("x");
  return new Toolbelt.JsonCore.JsonSyntaxScanner(x,policy,null,null,0).Run();
 }
 // Schema verwendet denselben Syntaxautomaten mit Scalarroots, Tokenindex und Budget.
 public static Toolbelt.JsonCore.JsonTokenDocument ScanTokens(string x,int maximumDepth,Toolbelt.JsonCore.JsonWorkBudget work){
  if(x==null)throw new ArgumentNullException("x");
  if(work==null)throw new ArgumentNullException("work");
  if(maximumDepth<1||maximumDepth>128)throw new ArgumentOutOfRangeException("maximumDepth");
  work.Spend(4);
  var document=new Toolbelt.JsonCore.JsonTokenDocument(x,work);
  document.Syntax=new Toolbelt.JsonCore.JsonSyntaxScanner(x,JsonPolicy.LegacyJson,work,document,maximumDepth).Run();
  return document;
 }
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
