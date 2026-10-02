using System;
using System.IO;
using System.Text;
using System.Data.SqlTypes;
using System.Collections;
using Toolbelt.String.EditDistance;
using Answer = DistanceKernel.Answer;
public static class FrameworkContract
{
    private static int assertions;
    private static void Require(bool condition) { if(!condition) throw new Exception("ASSERTION"); assertions++; }
    private static Answer Evaluate(string a,string b,int? k,string p,bool osa) { return DistanceKernel.Evaluate(a,b,k,p,osa); }
    private static long PlannedCells(int n,int m,int? k) { return DistanceKernel.PlannedCells(n,m,k); }
    private static void Transport()
    {
        foreach(bool osa in new[]{false,true})
        {
            Func<SqlChars,SqlChars,SqlInt32,SqlChars,IEnumerable> call=osa ? (Func<SqlChars,SqlChars,SqlInt32,SqlChars,IEnumerable>)DistanceProvider.Osa : DistanceProvider.Levenshtein;
            foreach(object row in call(new SqlChars("CA"),new SqlChars("AC"),SqlInt32.Null,new SqlChars("standard")))
            {
                SqlInt32 d,e;SqlBoolean x;DistanceProvider.FillRow(row,out d,out x,out e);
                Require(!e.IsNull && e.Value==0 && d.Value==(osa?1:2) && !x.Value);
            }
            foreach(object row in call(SqlChars.Null,new SqlChars("x"),new SqlInt32(-1),SqlChars.Null))
            {
                SqlInt32 d,e;SqlBoolean x;DistanceProvider.FillRow(row,out d,out x,out e);
                Require(d.IsNull && x.IsNull && !e.IsNull && e.Value==0);
            }
            foreach(string p in new[]{"standard ","STANDARD","standard\0",new string('x',65536)})
            foreach(object row in call(new SqlChars("a"),new SqlChars("a"),SqlInt32.Null,new SqlChars(p)))
            { SqlInt32 d,e;SqlBoolean x;DistanceProvider.FillRow(row,out d,out x,out e);Require(e.Value==1 && d.IsNull && x.IsNull); }
        }
    }
    private static string HexText(string hex)
    {
        byte[] bytes=new byte[hex.Length/2];
        for(int i=0;i<bytes.Length;i++) bytes[i]=Convert.ToByte(hex.Substring(i*2,2),16);
        return new UnicodeEncoding(false,false,true).GetString(bytes);
    }
    private static void GoldenFile(string file)
    {
        int cases=0;
        foreach(string line in File.ReadLines(file))
        {
            string[] p=line.Split('|');bool osa=p[0]=="1";
            int k=Int32.Parse(p[3]),expected=Int32.Parse(p[4]);
            Answer answer=Evaluate(HexText(p[1]),HexText(p[2]),k<0?(int?)null:k,"standard",osa);
            Require(answer.Error==0);
            Require(answer.Distance==(expected<0?(int?)null:expected));
            Require(answer.Exceeds==(expected<0));
            cases++;
        }
        Require(cases==27104);
        Console.WriteLine("GOLDEN_CASES="+cases);
    }
    private static void Validation()
    {
        Require(Evaluate(null,"\uD800",-1,"invalid",true).Error==0);
        Require(Evaluate("\uD800","a",-1,"invalid",true).Error==1);
        Require(Evaluate("\uD800","a",-1,"standard",true).Error==2);
        foreach(string invalid in new string[]{"\uD800","\uDFFF","\uD800x","x\uDC00","\uDC00\uD800"})
            Require(Evaluate(invalid,"a",null,"standard",true).Error==4);
        Require(Evaluate(new string('a',2049),"a",null,"standard",true).Error==3);
        Require(Evaluate(new string('a',1025),"a",null,"standard",true).Error==5);
        string emoji=Char.ConvertFromUtf32(0x1F600);
        Require(Evaluate(Repeat(emoji,1024),"",null,"standard",true).Distance==1024);
        Require(Evaluate(Repeat(emoji,1025),"",null,"standard",true).Error==3);
        Require(Evaluate(new string('a',32768),"",null,"large",true).Distance==32768);
        Require(Evaluate(new string('a',32769),"",null,"large",true).Error==5);
        Require(Evaluate(new string('a',65537),"",null,"large",true).Error==3);
        Require(Evaluate(new string('a',4096),new string('b',4097),null,"large",true).Error==6);
        Require(Evaluate("a","b",Int32.MaxValue,"standard",true).Distance==1);
        Require(Evaluate("\u0000\uFEFF\uFFFE"+Char.ConvertFromUtf32(0x10000)+Char.ConvertFromUtf32(0x10FFFF),"",null,"standard",true).Distance==5);
        Require(PlannedCells(4096,4096,null)==16777216);
        Require(PlannedCells(4096,4097,null)>16777216);
        Require(PlannedCells(32768,32768,1)==98302);
        Require(Evaluate("CA","ABC",1,"standard",true).Exceeds==true);
        Require(Evaluate("CA","ABC",3,"standard",true).Distance==3);
        Require(Evaluate(Repeat(emoji,32767)+"a","",null,"large",true).Distance==32768);
        Require(Evaluate(Repeat(emoji,32768),"",null,"large",true).Distance==32768);
        Require(Evaluate(Repeat(emoji,32768)+"a","",null,"large",true).Error==3);
        Require(Evaluate(Repeat(emoji,32767)+"a\uD800","",null,"large",true).Error==4);
        Require(PlannedCells(1024,1024,Int32.MaxValue)==1048576);
    }
    private static string Repeat(string text,int n) {return new StringBuilder(text.Length*n).Insert(0,text,n).ToString();}
    private static void Full(bool large,bool osa)
    {
        int n=large?4096:1024;
        Answer answer=Evaluate(new string('a',n),new string('b',n),null,large?"large":"standard",osa);
        Require(answer.Error==0 && answer.Distance==n && answer.Exceeds==false);
        Require(answer.Cells==(large?16777216:1048576));
        Require(answer.IntBufferBytes==4L*(2*n+(osa?3L:2L)*(n+1)));
        Report(answer);
    }
    private static void LargeBand(bool osa)
    {
        string left=new string('a',32766)+"ab",right=new string('a',32766)+"ba";
        Answer answer=Evaluate(left,right,osa?1:2,"large",osa);
        Require(answer.Error==0 && answer.Distance==(osa?1:2));
        Require(answer.IntBufferBytes<=655372);
        Require(answer.BoundaryWrites<=3L*32768 && answer.InitializationWrites<100000);
        Report(answer);
        Answer cutoff=Evaluate(left,new string('b',32768),1,"large",osa);
        Require(cutoff.Error==0 && cutoff.Distance==null && cutoff.Exceeds==true);
        Require(cutoff.Cells==98302);
    }
    private static void Report(Answer a)
    {
        Console.WriteLine("CELLS="+a.Cells+";PREDICTED="+a.PredictedCells+";INT_BUFFER_BYTES="+a.IntBufferBytes+
                          ";INITIALIZATION_WRITES="+a.InitializationWrites+";BOUNDARY_WRITES="+a.BoundaryWrites);
    }
    private static void SupplementaryBand()
    {
        string emoji=Char.ConvertFromUtf32(0x1F600),other=Char.ConvertFromUtf32(0x1F601);
        string left=Repeat(emoji,32766)+emoji+other,right=Repeat(emoji,32766)+other+emoji;
        Require(left.Length==65536 && right.Length==65536);
        Answer answer=Evaluate(left,right,1,"large",true);
        Require(answer.Error==0 && answer.Distance==1 && answer.Cells==98302);
        Require(answer.IntBufferBytes==655372);
        Report(answer);
        Answer exactZero=Evaluate(left,left,0,"large",true);
        Require(exactZero.Error==0 && exactZero.Distance==0 && exactZero.Cells==32768);
        Answer exceeded=Evaluate(left,right,0,"large",true);
        Require(exceeded.Error==0 && exceeded.Distance==null && exceeded.Exceeds==true);
    }
    public static int Main(string[] args)
    {
        try
        {
            switch(args[0])
            {
                case "goldens":GoldenFile(args[1]);break;
                case "validation":Validation();Transport();break;
                case "lev_standard":Full(false,false);break;
                case "osa_standard":Full(false,true);break;
                case "lev_large":Full(true,false);break;
                case "osa_large":Full(true,true);break;
                case "lev_band":LargeBand(false);break;
                case "osa_band":LargeBand(true);break;
                case "osa_supplementary_band":SupplementaryBand();break;
                default:throw new Exception("CASE");
            }
            Console.WriteLine("PASS;ASSERTIONS="+assertions);return 0;
        }
        catch {Console.WriteLine("FAIL");return 1;}
    }
}
