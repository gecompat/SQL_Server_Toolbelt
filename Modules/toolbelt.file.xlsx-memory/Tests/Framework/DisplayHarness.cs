using System;
using System.Globalization;
using System.IO;
using Toolbelt.Xlsx.Qualification;
internal static class DisplayHarness
{
    private static int count;
    private static void Check(string stored, bool? present, string raw, string text, string target,
        string format, bool? date1904, string culture, int status, string display)
    {
        var got = XlsxCellDisplay.Evaluate(stored, present, raw, text, target, format, date1904, culture);
        count++;
        if (got.Status != status || got.Display != display)
            throw new Exception("Case " + count + ": " + raw + "/" + format + " expected "
                + status + ":" + display + " got " + got.Status + ":" + got.Display);
    }
    private static int Main(string[] args)
    {
        try
        {
            CultureInfo.CurrentCulture = new CultureInfo(args[1], false);
            foreach (string line in File.ReadLines(args[0]))
            {
                string[] f = line.Split('\t');
                Check("n", true, f[0], null, "number", f[1], null, f[2], 0, f[3]);
            }
            Check(null,null,null,null,null,null,null,null,1,null);
            Check(null,null,null,null,null,null,null,new string('x',33),3,null);
            Check(null,null,null,null,null,null,null,"\ud800",4,null);
            Check("n",true,"2.5",null,"number","0",null,"en-US",0,"3");
            Check("n",true,"-0.49",null,"number","0",null,"de-DE",0,"0");
            Check("n",true,"9.995",null,"number","0.00E+00",null,"en-US",0,"1.00E+01");
            Check("n",true,"1",null,"number","0",null,null,2,null);
            Check("n",true,"1",null,"number","0",null,"en-US ",2,null);
            Check("n",true,"bad",null,"number","0",null,null,4,null);
            Check("n",true,"60.5",null,"datetime","yyyy-mm-dd hh:mm:ss",false,"en-US",7,null);
            Check("n",true,"1",null,"duration","[h]:mm:ss",null,"en-US",6,null);
            Check("d",true,"2020-12-31T23:59:59.5000000",null,"datetime","yyyy-mm-dd hh:mm:ss",null,"en-US",0,"2021-01-01 00:00:00");
            Check("d",true,"2020-12-31T23:59:59.4999999",null,"datetime","yyyy-mm-dd hh:mm:ss",null,"de-DE",0,"2020-12-31 23:59:59");
            Check("d",true,"9999-12-31T23:59:59.5000000",null,"datetime","yyyy-mm-dd hh:mm:ss",null,"tr-TR",8,null);
            Check("n",true,"0.999999999999",null,"time","hh:mm:ss",null,"en-US",8,null);
            Check("n",true,"0",null,"date","yyyy-mm-dd",true,"tr-TR",0,"1904-01-01");
            Check("inlineStr",false,null,"",null,"@",null,"en-US",0,"");
            Check("s",true,"0",new string('a',32733),"text","@",null,"en-US",0,new string('a',32733));
            Check("s",true,"0",new string('a',32734),"text","@",null,"en-US",3,null);
            Check("str",true,new string('a',21821),new string('a',21821),"text","@",null,"de-DE",0,new string('a',21821));
            Check("str",true,new string('a',21822),new string('a',21822),"text","@",null,"de-DE",3,null);
            Console.WriteLine("PASS CASES=" + count); return 0;
        }
        catch (Exception error) { Console.Error.WriteLine(error.Message); return 1; }
    }
}
