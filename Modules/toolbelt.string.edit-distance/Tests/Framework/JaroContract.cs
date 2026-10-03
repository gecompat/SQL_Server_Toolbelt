// Synthetische Vertragsgoldens; keine zweite Matchingimplementierung.
using System;
using System.Data.SqlTypes;
using System.Globalization;
using Toolbelt.String.EditDistance;

internal static class JaroContract
{
    private static int checks;
    private static void Need(bool value) { checks++; if (!value) throw new Exception("JARO_FIXTURE"); }
    private static void Golden(string a, string b, double expected)
    {
        foreach (string profile in new string[] { "standard", "large" }) {
            JaroKernel.Answer x = JaroKernel.Evaluate(a,b,profile);
            JaroKernel.Answer y = JaroKernel.Evaluate(b,a,profile);
            Need(x.Error == 0 && x.Similarity.HasValue && Math.Abs(x.Similarity.Value-expected) <= 1e-12);
            Need(y.Error == 0 && y.Similarity == x.Similarity);
            Need(x.VisitedWork <= x.PlannedWork);
        }
    }
    public static int Main(string[] args)
    {
        try {
            CultureInfo.CurrentCulture = CultureInfo.GetCultureInfo(args[0]);
            Golden("","",1); Golden("A","",0); Golden("A","A",1);
            Golden("A","a",0); Golden("A","A ",17.0/20);
            Golden("A","B",0); Golden("AB","BA",0);
            Golden("ABC","ACB",5.0/9); Golden("ABCA","ACBA",37.0/40);
            Golden("ABCDEF","ABDCEF",43.0/45);
            Golden("AAAAABBBBB","AAAAACCCCC",2.0/3);
            Golden(new string('A',11)+new string('B',9),new string('A',11)+new string('C',9),7.0/10);
            Golden("AAAAAABBBB","AAAAAACCCC",21.0/25);
            Golden("ABCDEF","BDHECFGD",259.0/360);
            JaroKernel.Answer odd = JaroKernel.Evaluate("ABCDEF","BDHECFGD","standard");
            Need(odd.Matches == 5 && odd.Mismatches == 3 && odd.Prefix == 0);
            Golden("\uD83D\uDE00","\uD83D\uDE00",1);
            Golden("\uD83D\uDE00","",0);
            Golden("e\u0301","\u00E9",0); Golden("\0","\0",1);
            // Manuell zugeordnete Duplikat-/Fensterzeugen: c4/h2/p1 und c3/h2/p0.
            Golden("AABAA","ABAAB",161.0/200);
            Golden("ABA","BAAB",29.0/36);
            Need(JaroKernel.Evaluate(null,"x","invalid").Error == 0);
            Need(JaroKernel.Evaluate("x","x",null).Error == 1);
            Need(JaroKernel.Evaluate(new string('x',2049),"x","standard").Error == 3);
            Need(JaroKernel.Evaluate("\uD800","x","standard").Error == 4);
            Need(JaroKernel.Evaluate("x","\uDC00","standard").Error == 4);
            Need(JaroKernel.Evaluate(new string('x',1025),"x","standard").Error == 5);
            Need(JaroKernel.PlannedWindowWork(4096,4096) == 12580864L);
            Need(JaroKernel.PlannedWindowWork(5000,5000) == 18747500L);
            JaroKernel.Answer ceiling = JaroKernel.Evaluate(new string('x',4096),new string('x',4096),"large");
            Need(ceiling.Error == 0 && ceiling.Similarity == 1 && ceiling.PlannedWork == 12580864L);
            Need(JaroKernel.Evaluate(new string('x',1024),new string('x',1024),"standard").Similarity == 1);
            char[] pairs = new char[65536];
            for(int i=0;i<pairs.Length;i+=2) { pairs[i]='\uD83D'; pairs[i+1]='\uDE00'; }
            Need(JaroKernel.Evaluate(new string(pairs),"","large").Similarity == 0);
            Need(JaroKernel.Evaluate(new string('x',32769),"","large").Error == 5);
            Need(JaroKernel.Evaluate(new string('x',5000),new string('x',5000),"large").Error == 6);
            Need(JaroKernel.Evaluate("\uD800",new string('x',2049),"standard").Error == 3);
            Need(JaroKernel.Evaluate("\uD800",new string('x',1025),"standard").Error == 4);
            var attr = (Microsoft.SqlServer.Server.SqlFunctionAttribute)Attribute.GetCustomAttribute(
                typeof(JaroProvider).GetMethod("Evaluate"),typeof(Microsoft.SqlServer.Server.SqlFunctionAttribute));
            Need(attr.IsDeterministic && !attr.IsPrecise && attr.DataAccess == Microsoft.SqlServer.Server.DataAccessKind.None);
            object row=null; int rows=0;
            foreach(object value in JaroProvider.Evaluate(new SqlChars("ABC"),new SqlChars("ACB"),new SqlChars("standard"))) { row=value; rows++; }
            SqlDouble similarity; SqlInt32 error; JaroProvider.FillRow(row,out similarity,out error);
            Need(rows == 1 && error.Value == 0 && Math.Abs(similarity.Value-5.0/9) <= 1e-12);
            Console.WriteLine("PASS;ASSERTIONS="+checks.ToString(CultureInfo.InvariantCulture)); return 0;
        } catch { Console.Error.WriteLine("JARO_FIXTURE_FAILED"); return 1; }
    }
}
