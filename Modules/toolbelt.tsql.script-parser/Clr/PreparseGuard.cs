// Legacywrapper: öffentliche Grenzen und Fehlerpriorität bleiben unverändert.
namespace Toolbelt.Tsql.ScriptParser
{
 internal static class PreparseGuard
 {
  internal const int AtomLimit=512, StructureLimit=32, CommentLimit=16;
  internal static string Guard(string sql,int requestedDepth,out int atoms,out int maxStructure,out int maxComments) {
   return PreparseGuardCore.Guard(sql,requestedDepth,new GuardProfile(AtomLimit,8192,StructureLimit,CommentLimit,0,0),out atoms,out maxStructure,out maxComments);
  }
 }
}
