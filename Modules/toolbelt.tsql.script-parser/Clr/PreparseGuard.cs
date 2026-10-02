using System;
using System.Collections.Generic;
namespace Toolbelt.Tsql.ScriptParser
{
 internal static class PreparseGuard
 {
 internal const int AtomLimit=512, StructureLimit=32, CommentLimit=16;
 internal static bool IsWordStart(char c){var category=Char.GetUnicodeCategory(c);return Char.IsLetter(c)||c=='_'||category==System.Globalization.UnicodeCategory.NonSpacingMark||category==System.Globalization.UnicodeCategory.SpacingCombiningMark||category==System.Globalization.UnicodeCategory.EnclosingMark;}
 internal static bool IsDecimal(char c){return Char.GetUnicodeCategory(c)==System.Globalization.UnicodeCategory.DecimalDigitNumber;}
 internal static string Guard(string sql,int requestedDepth,out int atoms,out int maxStructure,out int maxComments) {
  atoms=0;maxStructure=0;maxComments=0;int rawUnits=0;var stack=new Stack<char>();
  if(sql.Length>1048576)return "TBX_TSQLPARSE_INPUT_TOO_LARGE";
  for(int i=0;i<sql.Length;) {
   char c=sql[i];
   if(Char.IsWhiteSpace(c)){if(++rawUnits>8192)return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";i++;continue;}
   if(c=='-'&&i+1<sql.Length&&sql[i+1]=='-'){
    if((rawUnits+=2)>8192)return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";i+=2;
    while(i<sql.Length&&sql[i]!='\r'&&sql[i]!='\n'){if(++rawUnits>8192)return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";i++;}continue;
   }
   if(c=='/'&&i+1<sql.Length&&sql[i+1]=='*') {
    if((rawUnits+=2)>8192)return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";int depth=1;maxComments=Math.Max(maxComments,depth);i+=2;
    while(i<sql.Length&&depth>0){
     if(i+1<sql.Length&&sql[i]=='/'&&sql[i+1]=='*'){
      if((rawUnits+=2)>8192)return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";
      depth++;maxComments=Math.Max(maxComments,depth);if(depth>CommentLimit)return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";i+=2;
     }
     else if(i+1<sql.Length&&sql[i]=='*'&&sql[i+1]=='/'){
      if((rawUnits+=2)>8192)return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";depth--;i+=2;
     }
     else {if(++rawUnits>8192)return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";i++;}
    }continue;
   }
   atoms++;rawUnits++;if(atoms>AtomLimit||rawUnits>8192)return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";
   if(c=='\''||c=='"'||c=='[') {
    char close=c=='['?']':c;i++;
    while(i<sql.Length){if(sql[i]==close){if(i+1<sql.Length&&sql[i+1]==close){i+=2;continue;}i++;break;}i++;}continue;
   }
   if(IsWordStart(c)||IsDecimal(c)) {
    bool numeric=IsDecimal(c);int start=i++;
    while(i<sql.Length&&(numeric?IsDecimal(sql[i]):IsWordStart(sql[i])||IsDecimal(sql[i]))){if(++rawUnits>8192)return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";i++;}
    if(!numeric){string word=sql.Substring(start,i-start);
     if(String.Equals(word,"CASE",StringComparison.OrdinalIgnoreCase)||String.Equals(word,"BEGIN",StringComparison.OrdinalIgnoreCase))stack.Push('B');
     else if(String.Equals(word,"END",StringComparison.OrdinalIgnoreCase)&&stack.Count>0&&stack.Peek()=='B')stack.Pop();
    }
   }else {
    if(c=='(')stack.Push(c);
    else if(c==')'&&stack.Count>0&&stack.Peek()=='(')stack.Pop();
    i++;
   }
   maxStructure=Math.Max(maxStructure,stack.Count);if(stack.Count>Math.Min(StructureLimit,requestedDepth))return "TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT";
  }return "ACCEPT";
 }
 }
}
