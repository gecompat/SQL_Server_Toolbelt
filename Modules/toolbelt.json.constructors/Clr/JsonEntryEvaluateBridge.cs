using System;
using System.Collections;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
namespace Toolbelt.JsonConstructors {
// Interne Pure-Entry-Brücke: globaler SQL-Preflight und echtes ISJSON verbleiben im TSQL-Adapter.
public static class JsonEntryEvaluateBridge {
 const long MaxValueUnits=8388608;
 sealed class ContractFailure : InvalidOperationException { internal ContractFailure():base("TBX_JSON_ENTRY_ADAPTER_CONTRACT"){} }
 static void Need(bool value){if(!value)throw new ContractFailure();}
 sealed class Row {
  internal readonly SqlChars Fragment;
  internal readonly SqlInt32 Number,State;
  internal readonly SqlByte Phase;
  internal readonly SqlInt64 Raw,Key,Strong,Output;
  internal Row(EntryResult r,byte phase){
   Need(r!=null&&r.Code>=0&&r.State>=0&&r.RawBytes>=0&&r.KeyBytes>=0&&r.FragmentBytes>=0);
   Need(r.Code==0?r.State==0&&phase==0:r.State>0&&phase>=1&&phase<=5);
   Need(r.Code==0||r.Fragment==null&&r.FragmentBytes==0);
   if(r.Fragment!=null)Need(checked(2L*r.Fragment.Length)==r.FragmentBytes);
   Fragment=r.Fragment==null?SqlChars.Null:new SqlChars(r.Fragment.ToCharArray());
   Number=new SqlInt32(r.Code);State=new SqlInt32(r.State);Phase=new SqlByte(phase);
   Raw=new SqlInt64(r.RawBytes);Key=new SqlInt64(r.KeyBytes);
   Strong=r.StrongValid?new SqlInt64(r.StrongBytes):SqlInt64.Null;Output=new SqlInt64(r.FragmentBytes);
  }
 }
 static long Length(SqlChars x){Need(x!=null);return x.IsNull?0:x.Length;}
 static string Copy(SqlChars x,long expected){
  Need(x!=null&&!x.IsNull&&expected>=0&&expected<=MaxValueUnits&&x.Length==expected);
  char[] buffer=new char[(int)expected];long used=0;
  while(used<expected){int wanted=(int)Math.Min(32768L,expected-used);long got=x.Read(used,buffer,(int)used,wanted);Need(got>0&&got<=wanted);used=checked(used+got);}
  Need(x.Length==expected);return new string(buffer);
 }
 static EntryResult Defensive(long raw,long key,int number,int state){return new EntryResult{RawBytes=raw,KeyBytes=key,Code=number,State=state};}
 static byte Phase(EntryResult r){
  if(r.Code==0)return 0;
  if(r.Code==53603||r.Code==53605||r.Code==53606)return 5;
  if(r.Code==53607){if(r.State==1){Need(r.RawPhase==1||r.RawPhase==2);return (byte)r.RawPhase;}Need(r.State>=2&&r.State<=4);return 4;}
  if(r.Code==53608){Need(r.State==1||r.State>=3&&r.State<=6);return 3;}
  throw new ContractFailure();
 }
 [SqlFunction(FillRowMethodName="FillRow",TableDefinition="Fragment nvarchar(max), ErrorNumber int, ErrorState int, FaultPhase tinyint, RawValueBytes bigint, KeyBytes bigint, StrongMinimumBytes bigint, FragmentBytes bigint",DataAccess=DataAccessKind.None,SystemDataAccess=SystemDataAccessKind.None)]
 public static IEnumerable Evaluate(SqlBoolean objectMode,SqlChars key,SqlChars valueKind,SqlChars value,SqlByte stage,SqlByte policy){
  try{
   Need(!objectMode.IsNull&&!stage.IsNull&&!policy.IsNull&&(stage.Value==0||stage.Value==1)&&policy.Value==1);
   Need(key!=null&&valueKind!=null&&value!=null);
   bool obj=objectMode.Value;long kl=obj?Length(key):0,vl=Length(value),tl=Length(valueKind);
   Need(kl>=0&&vl>=0&&tl>=0);
   long raw=checked(2L*vl),kb=checked(2L*kl);EntryResult result;
   if(obj&&(key.IsNull||kl==0||kl>1024))result=Defensive(raw,kb,53603,1);
   else if(valueKind.IsNull||tl>7)result=Defensive(raw,kb,53605,2);
   else{
    string kind=Copy(valueKind,tl);
    if(kind!="string"&&kind!="null"&&kind!="boolean"&&kind!="number"&&kind!="json")result=Defensive(raw,kb,53605,1);
    else if((kind=="null")!=value.IsNull)result=Defensive(raw,kb,53606,1);
    else{
     if(vl>MaxValueUnits)throw new InvalidOperationException("TBX_JSON_ENTRY_RESOURCE_FAILURE");
     string k=obj?Copy(key,kl):null;string v=value.IsNull?null:Copy(value,vl);
     result=stage.Value==0?JsonCanonicalCore.RawOnlyEntry(obj,k,kind,v):JsonCanonicalCore.Evaluate(obj,k,kind,v,JsonPolicy.LegacyJson,true);
     // Native ISJSON muss vor Stage1 bereits erfolgreich gewesen sein; eigene Abweichung ist technisch.
     if(stage.Value==1&&kind=="json"&&result.Code==53608&&result.State==2)throw new ContractFailure();
    }
   }
   byte phase=Phase(result);Need(stage.Value!=0||result.Fragment==null&&result.FragmentBytes==0);
   Need(stage.Value!=1||result.Code!=0||result.Fragment!=null);
   Row row=new Row(result,phase);return new object[]{row};
  }catch(ContractFailure){throw new InvalidOperationException("TBX_JSON_ENTRY_ADAPTER_CONTRACT");}
   catch(Exception){throw new InvalidOperationException("TBX_JSON_ENTRY_RESOURCE_FAILURE");}
 }
 public static void FillRow(object item,out SqlChars fragment,out SqlInt32 errorNumber,out SqlInt32 errorState,out SqlByte faultPhase,out SqlInt64 rawValueBytes,out SqlInt64 keyBytes,out SqlInt64 strongMinimumBytes,out SqlInt64 fragmentBytes){
  Row row=item as Row;if(row==null)throw new InvalidOperationException("TBX_JSON_ENTRY_ADAPTER_CONTRACT");
  fragment=row.Fragment;errorNumber=row.Number;errorState=row.State;faultPhase=row.Phase;
  rawValueBytes=row.Raw;keyBytes=row.Key;strongMinimumBytes=row.Strong;fragmentBytes=row.Output;
 }
}
}