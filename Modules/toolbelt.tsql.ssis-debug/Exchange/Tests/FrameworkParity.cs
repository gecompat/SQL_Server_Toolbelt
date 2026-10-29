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
            bool pipelines=args.Length==2 && args[0]=="--pipeline-bundle";
            bool componentsV2=true;
            bool scopes=pipelines || args.Length==2 && args[0]=="--scope-bundle";
            bool iterations=args.Length==2 && args[0]=="--iteration-bundle";
            bool bundle=args.Length==2 && (args[0]=="--bundle" || iterations || scopes);
            bool modeArgument=bundle;
            var limits=ResourceLimits.CreateCurrent();
            var document=PackageDocument.Read(File.ReadAllBytes(args[modeArgument ? 1 : 0]),null,componentsV2,limits);
            var model=document.ExportComponentsV2("1.0.0",new string('0',40),new string('0',64));
            object result=bundle ? (object)new System.Collections.Generic.Dictionary<string,object> {
                {"contract","ssis-export-bundle"},{"version","1.0.0"},{"model",model},{"identities",scopes ? document.ExportExecutionScopes() : document.ExportObjectIdentities(iterations)}
            } : model;
            if(pipelines) ((System.Collections.Generic.Dictionary<string,object>)result).Add("pipelineIdentities",document.ExportPipelineIdentities());
            Console.Write(new JavaScriptSerializer { MaxJsonLength=16777216 }.Serialize(result));
            return 0;
        }
        catch(ModelException error) { Console.Error.Write(error.Message); return 3; }
    }
}
