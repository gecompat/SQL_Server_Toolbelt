using System;
using System.IO;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
namespace Toolbelt.JsonConstructors {

// Privater Bindingkandidat. Keine installierte SQL-Assembly und keine Sourcefreigabe.
internal static class AggregateBoundary {
 internal static Exception Technical(Exception error){
  // Keine originalen Messages/InnerExceptions übernehmen.
  if(error is InvalidOperationException||error is InvalidDataException||error is EndOfStreamException)return AgfErrors.State();
  return AgfErrors.Resource();
 }
 internal static void NeedBuilder(OwnedAggregateBuilder builder){AgfErrors.Need(builder!=null&&!builder.Poisoned);}
}

[Serializable]
[SqlUserDefinedAggregate(Format.UserDefined,MaxByteSize=-1,IsInvariantToNulls=false,IsInvariantToDuplicates=false,IsInvariantToOrder=true,IsNullIfEmpty=false)]
public sealed class JsonArrayAggregate : IBinarySerialize {
 OwnedAggregateBuilder builder;
 public void Init(){builder=null;try{builder=new OwnedAggregateBuilder(false);}catch(Exception e){throw AggregateBoundary.Technical(e);}}
 public void Accumulate(SqlInt32 ordinal,SqlChars valueKind,SqlChars value,SqlByte profile){
  try{AggregateBoundary.NeedBuilder(builder);builder.Add(ordinal,SqlChars.Null,valueKind,value,profile);}catch(Exception e){if(builder!=null)builder.Poison();throw AggregateBoundary.Technical(e);}
 }
 public void Merge(JsonArrayAggregate value){
  try{AggregateBoundary.NeedBuilder(builder);AgfErrors.Need(value!=null);AggregateBoundary.NeedBuilder(value.builder);builder.Merge(value.builder);}catch(Exception e){if(builder!=null)builder.Poison();throw AggregateBoundary.Technical(e);}
 }
 public SqlChars Terminate(){
  AggregateBoundary.NeedBuilder(builder);string outcome=builder.Outcome();if(outcome!="VALID"&&outcome!="EMPTY")throw new InvalidOperationException(AgfErrors.Message(outcome,builder.RankTag));
  try{return new SqlChars(builder.Finish().ToCharArray());}catch(Exception e){builder.Poison();throw AggregateBoundary.Technical(e);}
 }
 public void Read(BinaryReader reader){
  // Neuer Enginewrapper braucht vor Read kein Init; Mode ist fest an die Klasse gebunden.
  try{AgfErrors.Need(reader!=null);OwnedAggregateBuilder fresh=OwnedAggregateBuilder.Read(reader.BaseStream,false);builder=fresh;}catch(Exception e){throw AggregateBoundary.Technical(e);}
 }
 public void Write(BinaryWriter writer){
  try{AggregateBoundary.NeedBuilder(builder);AgfErrors.Need(writer!=null);byte[] bytes=Dispatcher.Write(builder.Transport());writer.Write(bytes);}catch(Exception e){throw AggregateBoundary.Technical(e);}
 }
}

[Serializable]
[SqlUserDefinedAggregate(Format.UserDefined,MaxByteSize=-1,IsInvariantToNulls=false,IsInvariantToDuplicates=false,IsInvariantToOrder=true,IsNullIfEmpty=false)]
public sealed class JsonObjectAggregate : IBinarySerialize {
 OwnedAggregateBuilder builder;
 public void Init(){builder=null;try{builder=new OwnedAggregateBuilder(true);}catch(Exception e){throw AggregateBoundary.Technical(e);}}
 public void Accumulate(SqlInt32 ordinal,SqlChars key,SqlChars valueKind,SqlChars value,SqlByte profile){
  try{AggregateBoundary.NeedBuilder(builder);builder.Add(ordinal,key,valueKind,value,profile);}catch(Exception e){if(builder!=null)builder.Poison();throw AggregateBoundary.Technical(e);}
 }
 public void Merge(JsonObjectAggregate value){
  try{AggregateBoundary.NeedBuilder(builder);AgfErrors.Need(value!=null);AggregateBoundary.NeedBuilder(value.builder);builder.Merge(value.builder);}catch(Exception e){if(builder!=null)builder.Poison();throw AggregateBoundary.Technical(e);}
 }
 public SqlChars Terminate(){
  AggregateBoundary.NeedBuilder(builder);string outcome=builder.Outcome();if(outcome!="VALID"&&outcome!="EMPTY")throw new InvalidOperationException(AgfErrors.Message(outcome,builder.RankTag));
  try{return new SqlChars(builder.Finish().ToCharArray());}catch(Exception e){builder.Poison();throw AggregateBoundary.Technical(e);}
 }
 public void Read(BinaryReader reader){
  try{AgfErrors.Need(reader!=null);OwnedAggregateBuilder fresh=OwnedAggregateBuilder.Read(reader.BaseStream,true);builder=fresh;}catch(Exception e){throw AggregateBoundary.Technical(e);}
 }
 public void Write(BinaryWriter writer){
  try{AggregateBoundary.NeedBuilder(builder);AgfErrors.Need(writer!=null);byte[] bytes=Dispatcher.Write(builder.Transport());writer.Write(bytes);}catch(Exception e){throw AggregateBoundary.Technical(e);}
 }
}

}
