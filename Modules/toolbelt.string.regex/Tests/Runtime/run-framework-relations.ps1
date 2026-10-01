[CmdletBinding()]
param([Parameter(Mandatory)][string]$AssemblyPath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$resolvedAssembly=(Resolve-Path -LiteralPath $AssemblyPath).Path
# Die Suite muss im echten .NET Framework laufen, nicht als Core-Ersatz.
if($PSVersionTable.PSEdition -ne 'Desktop'){throw 'Windows PowerShell/.NET Framework wird benötigt.'}
$null=[Reflection.Assembly]::LoadFrom($resolvedAssembly)
Add-Type -ReferencedAssemblies $resolvedAssembly,System.Data,System.Xml -TypeDefinition @'
using System;
using System.Collections;
using System.Collections.Generic;
using System.Data.SqlTypes;
using Toolbelt.String.Regex;
public static class RegexRelationContract {
 static void Check(bool value,string message){if(!value)throw new Exception(message);}
 static List<object[]> Rows(IEnumerable sequence){var result=new List<object[]>(); foreach(var row in sequence){SqlInt64 o,s,l;SqlString v;RegexProvider.FillRelationRow(row,out o,out s,out l,out v);Check(!o.IsNull&&!s.IsNull&&!l.IsNull&&!v.IsNull,"nonnull row");result.Add(new object[]{o.Value,s.Value,l.Value,v.Value});}return result;}
 static List<object[]> Matches(string input,string pattern,int start=1,int max=10000,string flags="c",string profile="standard"){return Rows(RegexProvider.RegexMatches(input,pattern,start,flags,profile,max));}
 static List<object[]> Split(string input,string pattern,int max=10000){return Rows(RegexProvider.RegexSplit(input,pattern,"c","standard",max));}
 static void Error(Action action,string prefix){bool failed=false;try{action();}catch(InvalidOperationException e){Check(e.Message.StartsWith(prefix+":"),"wrong error prefix");failed=true;}Check(failed,"missing error");}
 static void Token(List<object[]> rows,int ordinal,long start,string value){var r=rows[ordinal-1];Check((long)r[0]==ordinal&&(long)r[1]==start&&(long)r[2]==value.Length&&(string)r[3]==value,"token bytes/position");}
 public static void Run(){
  var r=Matches("a12 b3 ","[0-9]+");Check(r.Count==2,"match count");Token(r,1,2,"12");Token(r,2,6,"3");
  Check(Matches("a","Z").Count==0,"no match");Check(Matches("a","a",3).Count==0,"start outside");
  r=Matches("abc","");Check(r.Count==4,"terminal match once");for(int i=0;i<4;i++)Token(r,i+1,i+1,"");
  r=Matches("abc", "",4);Check(r.Count==1,"terminal start");Token(r,1,4,"");
  r=Split("a,,b,",",");Check(r.Count==4,"empty preserved");Token(r,1,1,"a");Token(r,2,3,"");Token(r,3,4,"b");Token(r,4,6,"");
  r=Split("abc","");Check(r.Count==5,"zero separator count");Token(r,1,1,"");Token(r,2,1,"a");Token(r,3,2,"b");Token(r,4,3,"c");Token(r,5,4,"");
  r=Split("", "Z");Check(r.Count==1,"empty input no match");Token(r,1,1,"");
  r=Split("", "");Check(r.Count==2,"empty input empty separator");Token(r,1,1,"");Token(r,2,1,"");
  r=Split("abc","$");Check(r.Count==2,"terminal anchor");Token(r,1,1,"abc");Token(r,2,4,"");
  r=Split("abc","^");Check(r.Count==2,"initial anchor");Token(r,1,1,"");Token(r,2,1,"abc");
  r=Split("abc","a*");Check(r.Count==5,"mixed consumed/empty");Token(r,1,1,"");Token(r,2,2,"");Token(r,3,2,"b");Token(r,4,3,"c");Token(r,5,4,"");
  string supplementary="A\ud83d\ude00B";r=Split(supplementary,"");Check(r.Count==6,"UTF16 split units");for(int i=0;i<4;i++)Token(r,i+2,i+1,supplementary.Substring(i,1));
  r=Matches("x  "," +$");Token(r,1,2,"  ");
  Check(Rows(RegexProvider.RegexMatches(SqlString.Null,"[",SqlInt32.Null,SqlString.Null,SqlString.Null,SqlInt32.Null)).Count==0,"NULL priority");
  Check(Rows(RegexProvider.RegexSplit("x",SqlString.Null,SqlString.Null,SqlString.Null,SqlInt32.Null)).Count==0,"NULL split priority");
  Error(()=>Matches("x","[",0,0,"bad","bad"),"TBX_REGEX_INVALID_ARGUMENT");
  Error(()=>Matches("x","[",0),"TBX_REGEX_INVALID_ARGUMENT");
  Error(()=>Matches("x","[",1,0,"bad"),"TBX_REGEX_INVALID_ARGUMENT");
  Error(()=>Matches("x","[",1,10,"bad"),"TBX_REGEX_INVALID_FLAGS");
  Error(()=>Matches("x","[",3),"TBX_REGEX_INVALID_PATTERN");
  Error(()=>Matches("abc","",1,3),"TBX_REGEX_TOO_MANY_ROWS");
  Error(()=>Split("abc","",4),"TBX_REGEX_TOO_MANY_ROWS");
  Check(Matches("abc","",1,4).Count==4&&Split("abc","",5).Count==5,"exact caps");
  Check(Matches(new string('x',99999),"",1,100000,"c","large").Count==100000,"actual row ceiling");
  Error(()=>Matches(new string('x',100000),"",1,100000,"c","large"),"TBX_REGEX_TOO_MANY_ROWS");
  Error(()=>Matches(new string('x',1048577),"x"),"TBX_REGEX_INPUT_TOO_LARGE");
  Error(()=>Matches("x",new string('x',8001)),"TBX_REGEX_PATTERN_TOO_LARGE");
  var large=new string('x',8388608);r=Matches(large,"^.*$",1,1,"c","large");Check(r.Count==1&&(long)r[0][2]==8388608,"large text output");
  Error(()=>Matches(new string('a',100000)+"!","^(a|aa)+$"),"TBX_REGEX_TIMEOUT");
  // Fachfehler wird beim Aufruf, vor einer ersten MoveNext-Operation erzeugt.
  IEnumerable notReturned=null;Error(()=>notReturned=RegexProvider.RegexSplit("abc","","c","standard",4),"TBX_REGEX_TOO_MANY_ROWS");Check(notReturned==null,"atomic before enumeration");
 }
}
'@
[RegexRelationContract]::Run()
'Regex R2b Framework contract PASS (keine SQL-SAFE-Evidenz).'
