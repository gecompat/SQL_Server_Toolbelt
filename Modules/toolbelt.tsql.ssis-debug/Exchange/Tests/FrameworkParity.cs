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
            bool scopes=args.Length==2 && args[0]=="--scope-bundle";
            bool iterations=args.Length==2 && args[0]=="--iteration-bundle";
            bool bundle=args.Length==2 && (args[0]=="--bundle" || iterations || scopes);
            var document=PackageDocument.Read(File.ReadAllBytes(args[bundle ? 1 : 0]));
            var model=document.Export("1.0.0",new string('0',40),new string('0',64));
            object result=bundle ? (object)new System.Collections.Generic.Dictionary<string,object> {
                {"contract","ssis-export-bundle"},{"version","1.0.0"},{"model",model},{"identities",scopes ? document.ExportExecutionScopes() : document.ExportObjectIdentities(iterations)}
            } : model;
            Console.Write(new JavaScriptSerializer { MaxJsonLength=16777216 }.Serialize(result));
            return 0;
        }
        catch(ModelException error) { Console.Error.Write(error.Message); return 3; }
    }
}
