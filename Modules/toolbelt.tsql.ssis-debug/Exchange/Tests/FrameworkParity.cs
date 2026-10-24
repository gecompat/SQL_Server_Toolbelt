using System;
using System.IO;
using System.Web.Script.Serialization;
using Toolbelt.Ssis.Exchange;

// Ausschließlich synthetische Testdateien. Dieser Host lädt keine SQL-Instanz.
internal static class FrameworkParity
{
    private static int Main(string[] args)
    {
        try
        {
            var model=PackageDocument.Read(File.ReadAllBytes(args[0])).Export("1.0.0",new string('0',40),new string('0',64));
            Console.Write(new JavaScriptSerializer { MaxJsonLength=16777216 }.Serialize(model));
            return 0;
        }
        catch(ModelException error) { Console.Error.Write(error.Message); return 3; }
    }
}
