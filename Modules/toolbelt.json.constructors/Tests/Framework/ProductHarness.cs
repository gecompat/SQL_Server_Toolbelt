using System;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.Reflection;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using Toolbelt.JsonConstructors;
internal static class ProductHarness {
 static int checks,rows;static void A(bool x){checks++;if(!x)throw new InvalidOperationException("HARNESS_ASSERT");}
 static string U(string x){if(x=="NULL")return null;A(x.Length%4==0);char[] b=new char[x.Length/4];for(int i=0;i<b.Length;i++)b[i]=(char)int.Parse(x.Substring(i*4,4),NumberStyles.HexNumber,CultureInfo.InvariantCulture);return new string(b);}
 static SqlChars C(string s){return s==null?SqlChars.Null:new SqlChars(s.ToCharArray());}
 static string Text(SqlChars s){return s.IsNull?null:new string(s.Value);}
 static void E(Action a,string code){bool seen=false;try{a();}catch(InvalidOperationException e){seen=true;A(e.GetType()==typeof(InvalidOperationException)&&e.Message==code&&e.InnerException==null);}A(seen);}
 static object One(SqlBoolean mode,SqlChars key,SqlChars kind,SqlChars value,SqlByte stage,SqlByte policy){IEnumerable sequence=JsonEntryEvaluateBridge.Evaluate(mode,key,kind,value,stage,policy);A(sequence!=null);IEnumerator it=sequence.GetEnumerator();try{A(it.MoveNext());object row=it.Current;A(row!=null);A(!it.MoveNext());return row;}finally{IDisposable d=it as IDisposable;if(d!=null)d.Dispose();}}
 static void Row(object item,string fragment,int n,int st,byte phase,long raw,long key,long? strong,long output){for(int repeat=0;repeat<2;repeat++){SqlChars f;SqlInt32 number,state;SqlByte ph;SqlInt64 r,k,s,o;JsonEntryEvaluateBridge.FillRow(item,out f,out number,out state,out ph,out r,out k,out s,out o);A(Text(f)==fragment);A(!number.IsNull&&number.Value==n);A(!state.IsNull&&state.Value==st);A(!ph.IsNull&&ph.Value==phase);A(!r.IsNull&&r.Value==raw);A(!k.IsNull&&k.Value==key);A(strong.HasValue?!s.IsNull&&s.Value==strong.Value:s.IsNull);A(!o.IsNull&&o.Value==output);}rows++;}
 static void SmallRows(string path){string[] all=File.ReadAllLines(path);A(all.Length==30&&all[0].StartsWith("Id|Object|Stage|Policy|",StringComparison.Ordinal));for(int i=1;i<all.Length;i++){string[] x=all[i].Split('|');A(x.Length==15);Row(One(new SqlBoolean(x[1]=="1"),C(U(x[4])),C(U(x[5])),C(U(x[6])),new SqlByte(byte.Parse(x[2],CultureInfo.InvariantCulture)),new SqlByte(byte.Parse(x[3],CultureInfo.InvariantCulture))),U(x[7]),int.Parse(x[8]),int.Parse(x[9]),byte.Parse(x[10]),long.Parse(x[11]),long.Parse(x[12]),x[13]=="NULL"?(long?)null:long.Parse(x[13]),long.Parse(x[14]));}}
 static void Extra(){
  Row(One(true,C("k"),C("json"),C("[\"\\uD800x\"]"),1,1),null,53607,3,4,22,2,30,0);
  Row(One(false,C(null),C("number"),C("-"),0,1),null,0,0,0,2,0,2,0);
  string k=new string('k',1024);Row(One(true,C(k),C("string"),C(""),0,1),null,0,0,0,0,2048,2058,0);
  Row(One(true,C(k+"k"),C("string"),C(""),0,1),null,53603,1,5,0,2050,null,0);
  Row(One(false,C(null),C("boolean"),C("false"),1,1),"false",0,0,0,10,0,10,10);
  Row(One(false,C(null),C("boolean "),C("false"),1,1),null,53605,2,5,10,0,null,0);
  Row(One(false,C(null),C("string\0"),C("a"),1,1),null,53605,1,5,2,0,null,0);
  Row(One(false,C(new string('x',1025)),C("null"),C(null),1,1),"null",0,0,0,0,0,8,8);
  E(()=>One(false,C(null),C("json"),C("x"),1,1),"TBX_JSON_ENTRY_ADAPTER_CONTRACT");
  E(()=>One(false,C(null),C("string"),C("a"),2,1),"TBX_JSON_ENTRY_ADAPTER_CONTRACT");
  E(()=>One(false,C(null),C("string"),C("a"),0,2),"TBX_JSON_ENTRY_ADAPTER_CONTRACT");
  E(()=>One(SqlBoolean.Null,C(null),C("string"),C("a"),0,1),"TBX_JSON_ENTRY_ADAPTER_CONTRACT");
  E(()=>One(false,C(null),C("string"),C("a"),SqlByte.Null,1),"TBX_JSON_ENTRY_ADAPTER_CONTRACT");
  E(()=>One(false,C(null),C("string"),C("a"),0,SqlByte.Null),"TBX_JSON_ENTRY_ADAPTER_CONTRACT");
  E(()=>One(false,null,C("string"),C("a"),0,1),"TBX_JSON_ENTRY_ADAPTER_CONTRACT");
  E(()=>One(false,C(null),null,C("a"),0,1),"TBX_JSON_ENTRY_ADAPTER_CONTRACT");
  E(()=>One(false,C(null),C("string"),null,0,1),"TBX_JSON_ENTRY_ADAPTER_CONTRACT");
  E(()=>{SqlChars f;SqlInt32 n,s;SqlByte ph;SqlInt64 r,keyCost,st,o;JsonEntryEvaluateBridge.FillRow(new object(),out f,out n,out s,out ph,out r,out keyCost,out st,out o);},"TBX_JSON_ENTRY_ADAPTER_CONTRACT");
  string d127=new string('[',127)+new string(']',127),d128="["+d127+"]";
  JsonScanResult a=JsonCanonicalCore.ScanJson(d127,JsonPolicy.AgfJson),b=JsonCanonicalCore.ScanJson(d128,JsonPolicy.AgfJson),c=JsonCanonicalCore.ScanJson(d128,JsonPolicy.LegacyJson);
  A(a.Status==0&&a.ValidDepth==127&&a.MaxStoredFrames==127);A(b.Status==2&&b.FirstFaultOffset==127&&b.MaxStoredFrames==127);A(c.Status==0&&c.ValidDepth==128);
  AggregateSmoke();
 }
 static void AggregateSmoke(){foreach(byte profile in new byte[]{1,2}){
  JsonArrayAggregate a=new JsonArrayAggregate();a.Init();A(Text(a.Terminate())=="[]");a.Accumulate(2,C("null"),C(null),profile);
  JsonArrayAggregate b=new JsonArrayAggregate();b.Init();b.Accumulate(1,C("json"),C("{}"),profile);a.Merge(b);A(Text(a.Terminate())=="[{},null]");A(Text(b.Terminate())=="[{}]");
  using(MemoryStream ms=new MemoryStream()){using(BinaryWriter w=new BinaryWriter(ms,System.Text.Encoding.UTF8,true))a.Write(w);ms.Position=0;JsonArrayAggregate copy=new JsonArrayAggregate();using(BinaryReader reader=new BinaryReader(ms,System.Text.Encoding.UTF8,true))copy.Read(reader);A(Text(copy.Terminate())=="[{},null]");A(ms.Position==ms.Length);}
  JsonObjectAggregate o=new JsonObjectAggregate();o.Init();A(Text(o.Terminate())=="{}");o.Accumulate(2,C("z"),C("boolean"),C("true"),profile);JsonObjectAggregate p=new JsonObjectAggregate();p.Init();p.Accumulate(1,C("a"),C("number"),C("1"),profile);o.Merge(p);A(Text(o.Terminate())=="{\"a\":1,\"z\":true}");A(Text(p.Terminate())=="{\"a\":1}");
  using(MemoryStream ms=new MemoryStream()){using(BinaryWriter w=new BinaryWriter(ms,System.Text.Encoding.UTF8,true))o.Write(w);ms.Position=0;JsonObjectAggregate copy=new JsonObjectAggregate();using(BinaryReader reader=new BinaryReader(ms,System.Text.Encoding.UTF8,true))copy.Read(reader);A(Text(copy.Terminate())=="{\"a\":1,\"z\":true}");A(ms.Position==ms.Length);}
 }}
 static void Method(Type t,string name,Type ret,Type[] args){MethodInfo m=t.GetMethod(name,BindingFlags.Public|BindingFlags.Instance|BindingFlags.Static,null,args,null);A(m!=null&&m.ReturnType==ret&&!m.IsGenericMethod);}
 static bool FrameworkCore(Assembly assembly){AssemblyName n=assembly.GetName();return n.Name=="mscorlib"&&n.Version==new Version(4,0,0,0)&&String.IsNullOrEmpty(n.CultureName)&&BitConverter.ToString(n.GetPublicKeyToken()).Replace("-","")=="B77A5C561934E089";}
 static void CompilerDataType(Type t){
  const string expectedField="3BD74F86FE85A3ED5594C09A0D5534D702FA35F60936B2D91BC02AC4D45D3997";
  BindingFlags own=BindingFlags.Public|BindingFlags.NonPublic|BindingFlags.Static|BindingFlags.Instance|BindingFlags.DeclaredOnly;
  A(t.FullName=="<PrivateImplementationDetails>"&&t.Namespace==null&&t.DeclaringType==null&&(int)t.Attributes==256&&t.IsClass&&!t.IsNested&&!t.IsPublic&&t.IsSealed&&!t.IsAbstract&&!t.IsGenericType&&t.BaseType==typeof(object)&&FrameworkCore(t.BaseType.Assembly));
  A(t.GetMethods(own).Length==0&&t.GetConstructors(own).Length==0&&t.TypeInitializer==null&&t.GetNestedTypes(BindingFlags.Public|BindingFlags.NonPublic).Length==0&&t.GetProperties(own).Length==0&&t.GetEvents(own).Length==0&&t.GetInterfaces().Length==0);
  IList<CustomAttributeData> attributes=CustomAttributeData.GetCustomAttributes(t);A(attributes.Count==1);CustomAttributeData attribute=attributes[0];
  Type generated=typeof(System.Runtime.CompilerServices.CompilerGeneratedAttribute);A(attribute.Constructor.DeclaringType==generated&&FrameworkCore(generated.Assembly)&&attribute.Constructor==generated.GetConstructor(Type.EmptyTypes)&&attribute.ConstructorArguments.Count==0&&attribute.NamedArguments.Count==0);
  FieldInfo[] fields=t.GetFields(own);A(fields.Length==1);FieldInfo field=fields[0];
  A(field.Name==expectedField&&(int)field.Attributes==307&&field.DeclaringType==t&&field.FieldType==typeof(long)&&FrameworkCore(field.FieldType.Assembly)&&!field.IsPublic&&!field.IsLiteral&&field.IsStatic&&field.IsInitOnly);
  byte[] actual=new byte[8];System.Runtime.CompilerServices.RuntimeHelpers.InitializeArray(actual,field.FieldHandle);byte[] expected={84,66,88,65,71,70,51,0};for(int i=0;i<8;i++)A(actual[i]==expected[i]);
  using(System.Security.Cryptography.SHA256 hash=System.Security.Cryptography.SHA256.Create())A(BitConverter.ToString(hash.ComputeHash(actual)).Replace("-","")==expectedField);
 }
 static void Metadata(){Assembly asm=typeof(JsonEntryEvaluateBridge).Assembly;A(asm.GetName().Name=="Toolbelt.JsonConstructors"&&asm.GetName().Version==new Version(1,3,0,0));AssemblyName[] refs=asm.GetReferencedAssemblies();A(refs.Length==4);bool msc=false,sys=false,data=false,core=false;foreach(AssemblyName a in refs){A(a.Name=="Toolbelt.JsonCore"?a.Version==new Version(1,0,0,0):(a.Name=="mscorlib"||a.Name=="System"||a.Name=="System.Data")&&a.Version==new Version(4,0,0,0));if(a.Name=="mscorlib")msc=true;if(a.Name=="System")sys=true;if(a.Name=="System.Data")data=true;if(a.Name=="Toolbelt.JsonCore")core=true;}A(msc&&sys&&data&&core);Assembly coreAssembly=typeof(JsonCanonicalCore).Assembly;A(coreAssembly!=asm&&coreAssembly.GetName().Name=="Toolbelt.JsonCore"&&coreAssembly.GetName().Version==new Version(1,0,0,0));int compilerDataTypes=0;foreach(Type t in asm.GetTypes()){if(t.FullName=="<PrivateImplementationDetails>"){CompilerDataType(t);compilerDataTypes++;}else A(t.Namespace=="Toolbelt.JsonConstructors"&&!t.Name.Contains("Diagnostic")&&!t.Name.Contains("Witness")&&!t.Name.Contains("Harness"));}A(compilerDataTypes==1);
  Type[] inputs={typeof(SqlBoolean),typeof(SqlChars),typeof(SqlChars),typeof(SqlChars),typeof(SqlByte),typeof(SqlByte)};Method(typeof(JsonEntryEvaluateBridge),"Evaluate",typeof(IEnumerable),inputs);MethodInfo eval=typeof(JsonEntryEvaluateBridge).GetMethod("Evaluate");SqlFunctionAttribute f=(SqlFunctionAttribute)Attribute.GetCustomAttribute(eval,typeof(SqlFunctionAttribute));A(f!=null&&f.DataAccess==DataAccessKind.None&&f.SystemDataAccess==SystemDataAccessKind.None&&f.FillRowMethodName=="FillRow");A(f.TableDefinition=="Fragment nvarchar(max), ErrorNumber int, ErrorState int, FaultPhase tinyint, RawValueBytes bigint, KeyBytes bigint, StrongMinimumBytes bigint, FragmentBytes bigint");
  Type[] outs={typeof(SqlChars),typeof(SqlInt32),typeof(SqlInt32),typeof(SqlByte),typeof(SqlInt64),typeof(SqlInt64),typeof(SqlInt64),typeof(SqlInt64)};string[] names={"fragment","errorNumber","errorState","faultPhase","rawValueBytes","keyBytes","strongMinimumBytes","fragmentBytes"};MethodInfo fill=typeof(JsonEntryEvaluateBridge).GetMethod("FillRow");A(fill.ReturnType==typeof(void));ParameterInfo[] ps=fill.GetParameters();A(ps.Length==9&&ps[0].ParameterType==typeof(object));for(int i=0;i<8;i++)A(ps[i+1].IsOut&&ps[i+1].ParameterType==outs[i].MakeByRefType()&&ps[i+1].Name==names[i]);
  foreach(Type t in new[]{typeof(JsonArrayAggregate),typeof(JsonObjectAggregate)}){SqlUserDefinedAggregateAttribute u=(SqlUserDefinedAggregateAttribute)Attribute.GetCustomAttribute(t,typeof(SqlUserDefinedAggregateAttribute));A(u!=null&&u.Format==Format.UserDefined&&u.MaxByteSize==-1&&!u.IsInvariantToNulls&&!u.IsInvariantToDuplicates&&u.IsInvariantToOrder&&!u.IsNullIfEmpty);A(typeof(IBinarySerialize).IsAssignableFrom(t));Method(t,"Init",typeof(void),new Type[0]);Method(t,"Merge",typeof(void),new[]{t});Method(t,"Read",typeof(void),new[]{typeof(BinaryReader)});Method(t,"Write",typeof(void),new[]{typeof(BinaryWriter)});Method(t,"Terminate",typeof(SqlChars),new Type[0]);Method(t,"Accumulate",typeof(void),t==typeof(JsonArrayAggregate)?new[]{typeof(SqlInt32),typeof(SqlChars),typeof(SqlChars),typeof(SqlByte)}:new[]{typeof(SqlInt32),typeof(SqlChars),typeof(SqlChars),typeof(SqlChars),typeof(SqlByte)});}
 }
 static void Large(){char[] at=new char[8388608];for(int i=0;i<at.Length;i++)at[i]='1';SqlChars valid=new SqlChars(at);Row(One(false,C(null),C("number"),valid,0,1),null,0,0,0,16777216,0,16777216,0);at=null;valid=null;
  char[] beyond=new char[8388609];for(int i=0;i<beyond.Length;i++)beyond[i]='1';SqlChars over=new SqlChars(beyond);E(()=>One(false,C(null),C("number"),over,0,1),"TBX_JSON_ENTRY_RESOURCE_FAILURE");E(()=>One(false,C(null),C("string"),over,1,1),"TBX_JSON_ENTRY_RESOURCE_FAILURE");Row(One(true,C(new string('k',1025)),C("string"),over,0,1),null,53603,1,5,16777218,2050,null,0);Row(One(false,C(null),C("12345678"),over,1,1),null,53605,2,5,16777218,0,null,0);}
 public static int Main(string[] args){try{A(args.Length==3);string mode=args[0],culture=args[1];A(mode=="SMALL"||mode=="LARGE");CultureInfo ci=culture=="invariant"?CultureInfo.InvariantCulture:CultureInfo.GetCultureInfo(culture);CultureInfo.CurrentCulture=ci;CultureInfo.CurrentUICulture=ci;if(mode=="SMALL"){A(culture=="de-DE"||culture=="en-US"||culture=="tr-TR");Metadata();SmallRows(args[2]);Extra();}else{A(culture=="invariant");Large();}Console.WriteLine("PASS PRODUCT_FRAMEWORK "+mode+" "+culture+" ROWS "+rows.ToString(CultureInfo.InvariantCulture)+" ASSERTIONS "+checks.ToString(CultureInfo.InvariantCulture));return 0;}catch(Exception){Console.WriteLine("FAIL PRODUCT_FRAMEWORK");return 1;}}
}