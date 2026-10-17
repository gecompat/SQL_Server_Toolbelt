using System;
using System.Collections.Generic;
namespace Toolbelt.Tsql.ScriptParser
{
 // Gemeinsame Buildquelle; Legacyprofil und SSIS-Profil bleiben getrennt.
 internal sealed class GuardProfile
 {
  internal readonly int AtomLimit, RawUnitLimit, StructureLimit, CommentLimit, OperatorLimit, QueryOperatorLimit;
  internal GuardProfile(int atoms,int raw,int structure,int comments,int operators,int queries) {
   AtomLimit=atoms;RawUnitLimit=raw;StructureLimit=structure;CommentLimit=comments;OperatorLimit=operators;QueryOperatorLimit=queries;
  }
 }
 internal static class PreparseGuardCore
 {
 internal static bool IsWordStart(char c){var category=Char.GetUnicodeCategory(c);return Char.IsLetter(c)||c=='_'||category==System.Globalization.UnicodeCategory.NonSpacingMark||category==System.Globalization.UnicodeCategory.SpacingCombiningMark||category==System.Globalization.UnicodeCategory.EnclosingMark;}
 internal static bool IsDecimal(char c){return Char.GetUnicodeCategory(c)==System.Globalization.UnicodeCategory.DecimalDigitNumber;}
 internal static string Guard(string sql,int requestedDepth,GuardProfile profile,out int atoms,out int maxStructure,out int maxComments,List<int> parameterOffsets=null) {
  atoms=0;maxStructure=0;maxComments=0;int rawUnits=0, operators=0, queryOperators=0;var stack=new Stack<char>();
  if(sql.Length>1048576)return "TBX_TSQLPARSE_INPUT_TOO_LARGE";
  for(int i=0;i<sql.Length;) {
   char c=sql[i];
   if(Char.IsWhiteSpace(c)){if(++rawUnits>profile.RawUnitLimit)return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";i++;continue;}
   if(c=='-'&&i+1<sql.Length&&sql[i+1]=='-'){
    if((rawUnits+=2)>profile.RawUnitLimit)return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";i+=2;
    while(i<sql.Length&&sql[i]!='\r'&&sql[i]!='\n'){if(++rawUnits>profile.RawUnitLimit)return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";i++;}continue;
   }
   if(c=='/'&&i+1<sql.Length&&sql[i+1]=='*') {
    if((rawUnits+=2)>profile.RawUnitLimit)return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";int depth=1;maxComments=Math.Max(maxComments,depth);i+=2;
    while(i<sql.Length&&depth>0){
     if(i+1<sql.Length&&sql[i]=='/'&&sql[i+1]=='*'){
      if((rawUnits+=2)>profile.RawUnitLimit)return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";
      depth++;maxComments=Math.Max(maxComments,depth);if(depth>profile.CommentLimit)return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";i+=2;
     }
     else if(i+1<sql.Length&&sql[i]=='*'&&sql[i+1]=='/'){
      if((rawUnits+=2)>profile.RawUnitLimit)return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";depth--;i+=2;
     }
     else {if(++rawUnits>profile.RawUnitLimit)return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";i++;}
    }continue;
   }
   atoms++;rawUnits++;if(atoms>profile.AtomLimit||rawUnits>profile.RawUnitLimit)return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";
   if(c=='\''||c=='"'||c=='[') {
    char close=c=='['?']':c;i++;
    while(i<sql.Length){if(sql[i]==close){if(i+1<sql.Length&&sql[i+1]==close){i+=2;continue;}i++;break;}i++;}continue;
   }
   if(IsWordStart(c)||IsDecimal(c)) {
    bool numeric=IsDecimal(c);int start=i++;
    while(i<sql.Length&&(numeric?IsDecimal(sql[i]):IsWordStart(sql[i])||IsDecimal(sql[i]))){if(++rawUnits>profile.RawUnitLimit)return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";i++;}
    if(!numeric){string word=sql.Substring(start,i-start);
     // Nur das neue Profil begrenzt zusätzliche Rekursionsketten vor ScriptDom.
     if(profile.OperatorLimit>0 && (String.Equals(word,"AND",StringComparison.OrdinalIgnoreCase)||String.Equals(word,"OR",StringComparison.OrdinalIgnoreCase)||String.Equals(word,"NOT",StringComparison.OrdinalIgnoreCase)||String.Equals(word,"LIKE",StringComparison.OrdinalIgnoreCase)||String.Equals(word,"IN",StringComparison.OrdinalIgnoreCase)||String.Equals(word,"BETWEEN",StringComparison.OrdinalIgnoreCase)))
      if(++operators>profile.OperatorLimit)return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";
     if(profile.QueryOperatorLimit>0 && (String.Equals(word,"UNION",StringComparison.OrdinalIgnoreCase)||String.Equals(word,"INTERSECT",StringComparison.OrdinalIgnoreCase)||String.Equals(word,"EXCEPT",StringComparison.OrdinalIgnoreCase)))
      if(++queryOperators>profile.QueryOperatorLimit)return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";
     if(String.Equals(word,"CASE",StringComparison.OrdinalIgnoreCase)||String.Equals(word,"BEGIN",StringComparison.OrdinalIgnoreCase))stack.Push('B');
     else if(String.Equals(word,"END",StringComparison.OrdinalIgnoreCase)&&stack.Count>0&&stack.Peek()=='B')stack.Pop();
    }
   }else {
    if(c=='?' && parameterOffsets!=null)parameterOffsets.Add(i);
    if(profile.OperatorLimit>0 && "+-*/%&|^~!=<>".IndexOf(c)>=0 && ++operators>profile.OperatorLimit)return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";
    if(c=='(')stack.Push(c);
    else if(c==')'&&stack.Count>0&&stack.Peek()=='(')stack.Pop();
    i++;
   }
   maxStructure=Math.Max(maxStructure,stack.Count);if(stack.Count>Math.Min(profile.StructureLimit,requestedDepth))return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";
  }return "ACCEPT";
 }
 }
}
