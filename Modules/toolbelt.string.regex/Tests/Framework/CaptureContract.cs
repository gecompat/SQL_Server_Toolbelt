using System;
using System.Collections;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.Reflection;
using System.Threading;
using Toolbelt.String.Regex;

// Synthetische Vertragsorakel im echten Framework; keine SQL-Ausführung.
public static class CaptureContract
{
    static int checks;
    static void Check(bool value) { checks++; if (!value) throw new Exception("Vertragsorakel fehlgeschlagen."); }
    static void Error(Action action, string prefix)
    {
        bool failed = false;
        try { action(); }
        catch (InvalidOperationException e) { Check(e.Message.StartsWith(prefix + ":", StringComparison.Ordinal)); failed = true; }
        Check(failed);
    }
    static List<object[]> Rows(string input, string pattern, int max = 10000, int start = 1,
        string flags = "c", string profile = "standard")
    {
        IEnumerable sequence = RegexProvider.RegexCaptures(input, pattern, start, flags, profile, max);
        var result = new List<object[]>();
        foreach (object row in sequence)
        {
            SqlInt64 m, c, p, l; SqlInt32 g; SqlString n, v; SqlBoolean matched;
            RegexProvider.FillCaptureRow(row, out m, out g, out c, out n, out matched, out p, out l, out v);
            Check(!m.IsNull && !g.IsNull && !c.IsNull && !n.IsNull && !matched.IsNull);
            Check(matched.Value == !p.IsNull && matched.Value == !l.IsNull && matched.Value == !v.IsNull);
            result.Add(new object[] { m.Value, g.Value, c.Value, n.Value, matched.Value,
                p.IsNull ? null : (object)p.Value, l.IsNull ? null : (object)l.Value, v.IsNull ? null : v.Value });
        }
        return result;
    }
    static string Replace(string input, string pattern, string template, int occurrence = 0, int start = 1)
    { return RegexProvider.RegexReplaceGroups(input, pattern, template, start, occurrence, "c", "standard").Value; }
    static void Row(object[] r, long m, int g, long c, string name, bool matched, object p, object l, string value)
    { Check((long)r[0] == m && (int)r[1] == g && (long)r[2] == c && (string)r[3] == name && (bool)r[4] == matched && Equals(r[5],p) && Equals(r[6],l) && Equals(r[7],value)); }

    static void Core()
    {
        var rows = Rows("abc", "(a)(?<X>b)(c)");
        Check(rows.Count == 3); Row(rows[0],1,1,1,"1",true,1L,1L,"a"); Row(rows[1],1,2,1,"X",true,2L,1L,"b"); Row(rows[2],1,3,1,"3",true,3L,1L,"c");
        rows = Rows("aaa", "(a)+"); Check(rows.Count == 3); for (int i=0;i<3;i++) Row(rows[i],1,1,i+1,"1",true,(long)i+1,1L,"a");
        rows=Rows("b","(a)?(b)"); Row(rows[0],1,1,0,"1",false,null,null,null); Row(rows[1],1,2,1,"2",true,1L,1L,"b");
        rows=Rows("","(a?)"); Row(rows[0],1,1,1,"1",true,1L,0L,"");
        rows=Rows("ab","((a)(b))"); Check(rows.Count==3); Row(rows[0],1,1,1,"1",true,1L,2L,"ab");
        rows=Rows("a","(a?)"); Check(rows.Count==2); Row(rows[1],2,1,1,"1",true,2L,0L,"");
        Check(Rows("a","a").Count==0); Check(Rows("a","(a)",10000,3).Count==0);
        rows=Rows("\uD83D\uDE00", "(.)"); Check(rows.Count==2); Check((long)rows[1][5]==2);
        Check(Rows("ABC", "([a-z]+)",10000,1,"i")[0][7].Equals("ABC"));
        Check(Rows("\u212A", "(\\w)",10000,1,"i").Count==0);
        Check(Replace("abc","(a)(?<X>b)(c)","$3${X}$1") == "cba");
        Check(Replace("aaa","(a)+","<$1>") == "<a>");
        Check(Replace("b","(a)?(b)","$1-$2") == "-b");
        Check(Replace("a","(a)","$$1:$${Name}:\\$1") == "$1:${Name}:\\a");
        Check(Replace("$x","(.)","$1") == "$x");
        Check(Replace("aaa","(a)","x",2) == "axa");
        Check(Replace("aaa","(a)","x",0,2) == "axx");
        Check(Replace("a","(a?)","x") == "xx");
        Check(Replace("a","(a)","x",0,3) == "a");
        Check(Replace("abc","Z","$$") == "abc");
        Check(RegexProvider.RegexReplace("a","(a)","$1",1,0,"c","standard").Value == "$1");
        Check(RegexProvider.RegexSubstring("abc","(b)",1,1,"c","standard").Value == "b");
        Check(RegexProvider.RegexIsMatch("aaa","(a)+","c").Value);
        Check(RegexProvider.RegexInstr("aba","a",1,2,0,"c").Value==3);
        Check(RegexProvider.RegexCount("aba","a",1,"c").Value==2);
        Check(RegexProvider.RegexReplaceGroups(SqlString.Null,"(","$0",0,-1,SqlString.Null,SqlString.Null).IsNull);
        Check(!RegexProvider.RegexCaptures(SqlString.Null,"(",0,SqlString.Null,SqlString.Null,0).GetEnumerator().MoveNext());
    }
    static void Faults()
    {
        foreach(string p in new[]{"(?<X>a)(?<x>b)","(?<X>a)(?<X>b)","(?<0>a)","(?:a)","(?=a)","(a)\\1","(a)?+","(?<X>a", "(?<"+new string('x',129)+">a)"})
            Error(()=>Rows("",p),"TBX_REGEX_INVALID_PATTERN");
        foreach(string t in new[]{"$0","$01","$10","$-1","$","${","${Unknown}","${1}","${x}","$2147483648","$\u0661"})
            Error(()=>Replace("Z","(?<X>a)",t,0,100),"TBX_REGEX_INVALID_REPLACEMENT");
        Error(()=>Rows("",new string('(',65)+"a"+new string(')',65)),"TBX_REGEX_PATTERN_TOO_COMPLEX");
        Error(()=>Rows("",new string('a',8001)),"TBX_REGEX_PATTERN_TOO_LARGE");
        Error(()=>Rows("a","(a)",0),"TBX_REGEX_INVALID_ARGUMENT");
        Error(()=>Rows("a","(a)",10000,0,"z","x"),"TBX_REGEX_INVALID_ARGUMENT");
        Error(()=>Rows("a","(a)",10000,1,"z"),"TBX_REGEX_INVALID_FLAGS");
        Error(()=>Rows(new string('a',1048577),"("),"TBX_REGEX_INPUT_TOO_LARGE");
        Error(()=>Replace("a","(",new string('a',1048577)),"TBX_REGEX_REPLACEMENT_TOO_LARGE");
        Error(()=>Rows("aa","(a)",1),"TBX_REGEX_TOO_MANY_ROWS");
        Error(()=>Rows("b","(a)?(b)",1),"TBX_REGEX_TOO_MANY_ROWS");
        Error(()=>Rows("", "((a*)*)",10000,100),"TBX_REGEX_CAPTURE_HISTORY_LIMIT");
        Error(()=>Replace("", "((a*)*)", "$0"),"TBX_REGEX_CAPTURE_HISTORY_LIMIT");
        string groups = ""; for(int i=0;i<64;i++) groups += "(a?)";
        Check(Rows("",groups).Count==64);
        Error(()=>Rows("",groups+"(a?)"),"TBX_REGEX_PATTERN_TOO_COMPLEX");
    }
    static void History()
    {
        Check(Rows("","(a?){1000}").Count==1000);
        Check(Rows("","(a*)").Count==1);
        Check(Rows("","(a){0}")[0][4].Equals(false));
        Check(Rows("","(a){1,}").Count==0);
        Error(()=>Rows(new string('a',100001),"(a)+",100000,100003),"TBX_REGEX_CAPTURE_HISTORY_LIMIT");
        Check(Rows(new string('a',100000),"(a)+",100000).Count==100000);
        Error(()=>Rows("","((a?){1000}){100}"),"TBX_REGEX_CAPTURE_HISTORY_LIMIT");
        Check(Rows("","((a?){1000}){99}",100000).Count==99099);
        Check(Rows("aa","((a)|(b)){1,2}").Count==5);
    }
    static void Output()
    {
        Check(Rows(new string('a',1048575),"(a+)")[0][7].ToString().Length==1048575);
        Error(()=>Rows(new string('a',1048576),"(a+)"),"TBX_REGEX_OUTPUT_TOO_LARGE");
        string value=new string('a',8388607);
        Check(Rows(value,"(a+)",10000,1,"c","large").Count==1);
        Error(()=>Rows(value+"a","(a+)",10000,1,"c","large"),"TBX_REGEX_OUTPUT_TOO_LARGE");
        Error(()=>Replace(new string('a',1048576),"(a)","$1$1"),"TBX_REGEX_OUTPUT_TOO_LARGE");
        string name=new string('x',128);
        Check(Rows("b","(?<"+name+">a)?b")[0][3].Equals(name));
    }
    static void Legacy()
    {
        string[] input={"abc-123","a",".","\t","ac","ac","abbc",new string('a',1000),"ABC","ABC","cat","b","ä","\u212A","\u212A","\u212A","ä","x\n","a\nx","a\nb"};
        string[] pattern={"^[a-z]+-\\d{3}$","a","^\\.$","^\\s$","^ab?c$","^ab*c$","^ab{2,3}c$","^a{1000}$","^[a-z]+$","^[a-z]+$","^(cat|dog)$","^[^a-c]$","^\\w$","^\\w$","^[\\w]$","^[^\\w]$","^\\p{L}$","x$","^x$","^a.b$"};
        string[] flags={"c","c","c","c","c","c","c","c","c","i","c","c","c","i","i","i","c","c","cm","cs"};
        bool[] expected={true,true,true,true,true,true,true,true,false,true,true,false,false,false,false,true,true,false,true,true};
        for(int i=0;i<input.Length;i++) Check(RegexProvider.RegexIsMatch(input[i],pattern[i],flags[i]).Value==expected[i]);
        foreach(string p in new[]{"(.)\\1","a(?=b)","(?<=a)b","(?!a)","(?<x>a)","(?>a)","(?(1)a|b)","(?<open>a)(?<-open>b)","a{1001}","a??","[a-z-[aeiou]]","\\P{L}"})
            Error(()=>RegexProvider.RegexIsMatch("ab",p,"c"),"TBX_REGEX_INVALID_PATTERN");
        Check(RegexProvider.RegexIsMatch(SqlString.Null,"(",SqlString.Null).IsNull);
        Check(RegexProvider.RegexInstr("a",SqlString.Null,0,0,2,SqlString.Null).IsNull);
        Check(RegexProvider.RegexCount(SqlString.Null,"(",0,SqlString.Null).IsNull);
        Check(RegexProvider.RegexInstr("baacaa","aa",1,2,0,"c").Value==5);
        Check(RegexProvider.RegexInstr("baacaa","aa",1,2,1,"c").Value==7);
        Check(RegexProvider.RegexInstr("baacaa","aa",3,1,0,"c").Value==5);
        Check(RegexProvider.RegexInstr("abc","z",1,1,0,"c").Value==0);
        Check(RegexProvider.RegexInstr("\uD83D\uDE00a","a",1,1,0,"c").Value==3);
        Check(RegexProvider.RegexCount("aaaa","aa",1,"c").Value==2);
        Check(RegexProvider.RegexCount("baaaa","aa",3,"c").Value==1);
        Check(RegexProvider.RegexCount("bbb","a*",1,"c").Value==4);
        Check(RegexProvider.RegexInstr("bbb","a*",1,3,0,"c").Value==3);
        Error(()=>RegexProvider.RegexIsMatch("a","a","ci"),"TBX_REGEX_INVALID_FLAGS");
        Error(()=>RegexProvider.RegexIsMatch("a","a",SqlString.Null),"TBX_REGEX_INVALID_FLAGS");
        Error(()=>RegexProvider.RegexInstr("a","a",0,1,0,"c"),"TBX_REGEX_INVALID_ARGUMENT");
        Error(()=>RegexProvider.RegexCount("a","a",SqlInt32.Null,"c"),"TBX_REGEX_INVALID_ARGUMENT");
        Error(()=>RegexProvider.RegexIsMatch(new string('a',1048577),"a","c"),"TBX_REGEX_INPUT_TOO_LARGE");
        Error(()=>RegexProvider.RegexIsMatch("a",new string('a',4001),"c"),"TBX_REGEX_PATTERN_TOO_LARGE");
        Check(RegexProvider.RegexIsMatch(new string('a',4000),new string('a',4000),"c").Value);
        Error(()=>RegexProvider.RegexIsMatch(new string('a',20000)+"X","^(a|aa)+$","c"),"TBX_REGEX_TIMEOUT");
        Check(RegexProvider.RegexReplace("ab12cd34","[0-9]+","$1\\x",1,0,"c","standard").Value=="ab$1\\xcd$1\\x");
        Check(RegexProvider.RegexReplace("ab12cd34","[0-9]+","X",1,2,"c","standard").Value=="ab12cdX");
        Check(RegexProvider.RegexSubstring("ab12cd34","[0-9]+",1,2,"c","standard").Value=="34");
        Check(RegexProvider.RegexReplace("ab","","-",1,0,"c","standard").Value=="-a-b-");
    }

    static void Budget()
    {
        Type type=typeof(RegexProvider).GetNestedType("TransformationContext",BindingFlags.NonPublic);
        BindingFlags binding=BindingFlags.Instance|BindingFlags.NonPublic;
        object context=Activator.CreateInstance(type,binding,null,new object[]{new SqlString("standard")},null);
        type.GetMethod("ValidateFlags",binding).Invoke(context,new object[]{new SqlString("c")});
        type.GetMethod("InitializeCaptures",binding).Invoke(context,new object[]{"(a?)",1});
        Thread.Sleep(300);
        MethodInfo search=type.GetMethod("Search",binding);
        for(int i=0;i<100;i++) Check(((System.Text.RegularExpressions.Match)search.Invoke(context,new object[]{"a",0})).Success);
        Thread.Sleep(550);
        bool failed=false;
        try { type.GetMethod("Remaining",binding).Invoke(context,null); }
        catch(TargetInvocationException e) { Check(e.InnerException.Message.StartsWith("TBX_REGEX_TIMEOUT:")); failed=true; }
        Check(failed);
    }

    static void Exhaustive()
    {
        string[] atoms={"a","b","(a)","(b?)","(?<X>a*)","(a|b)","((a)(b))","(a?){0}","(a?){2}","(a)+","(a){1,3}"};
        foreach(string p in atoms) for(int n=0;n<16;n++)
        {
            string value=""; for(int j=0;j<4;j++) value+=(n&(1<<j))==0?"a":"b";
            var rows=Rows(value,p,100000);
            long previousM=0,previousC=0; int previousG=0;
            foreach(object[] r in rows)
            {
                long m=(long)r[0], c=(long)r[2]; int g=(int)r[1];
                Check(m>previousM || m==previousM && (g>previousG || g==previousG && c>previousC));
                previousM=m;previousG=g;previousC=c;
                if((bool)r[4]) Check(value.Substring((int)(long)r[5]-1,(int)(long)r[6])==(string)r[7]);
            }
        }
    }
    public static int Main(string[] args)
    {
        Exception failure=null;
        var thread=new Thread(()=>{try {switch(args[0]){case "legacy":Legacy();break;case "budget":Budget();break;case "core":Core();break;case "faults":Faults();break;case "history":History();break;case "output":Output();break;case "exhaustive":Exhaustive();break;default:throw new Exception();}} catch(Exception e){failure=e;}},256*1024);
        thread.Start(); thread.Join();
        if(failure!=null){Console.Error.WriteLine(failure.ToString());return 1;}
        Console.WriteLine("PASS "+args[0]+" "+checks); return 0;
    }
}
