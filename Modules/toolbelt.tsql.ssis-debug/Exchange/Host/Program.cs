using System;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Toolbelt.Ssis.Exchange;

// Der Host übernimmt ausschließlich den ausdrücklich gewählten Eingabepfad.
// Der gemeinsame Kern kennt weder Dateisystem noch SQL Server oder SSIS SDK.
internal static class Program
{
    private static int Main(string[] args)
    {
        bool pipelines = args.Length == 2 && args[0] == "--pipeline-bundle";
        bool scopes = pipelines || args.Length == 2 && args[0] == "--scope-bundle";
        bool iterations = args.Length == 2 && args[0] == "--iteration-bundle";
        bool bundle = args.Length == 2 && (args[0] == "--bundle" || iterations || scopes);
        if (args.Length != 1 && !bundle) { Console.Error.WriteLine("Usage: Toolbelt.Ssis.Export [--bundle|--iteration-bundle|--scope-bundle|--pipeline-bundle] <package.dtsx>; JSON on stdout, codes on stderr."); return 2; }
        try
        {
            var input = new FileInfo(args[bundle ? 1 : 0]);
            if (!String.Equals(input.Extension, ".dtsx", StringComparison.OrdinalIgnoreCase)) throw new ModelException("UNSUPPORTED_PACKAGE_FORMAT");
            if (input.Length > 16777216) throw new ModelException("LIMIT_EXCEEDED");
            byte[] bytes;
            using (var stream = new FileStream(input.FullName, FileMode.Open, FileAccess.Read, FileShare.Read))
            {
                if (stream.Length > 16777216) throw new ModelException("LIMIT_EXCEEDED");
                using (var memory = new MemoryStream())
                {
                    byte[] buffer = new byte[65536]; int read;
                    while ((read = stream.Read(buffer, 0, buffer.Length)) != 0)
                    { if (memory.Length + read > 16777216) throw new ModelException("LIMIT_EXCEEDED"); memory.Write(buffer, 0, read); }
                    bytes = memory.ToArray();
                }
            }
            string assembly = Assembly.GetExecutingAssembly().Location;
            string buildHash = Convert.ToHexString(SHA256.HashData(File.ReadAllBytes(assembly))).ToLowerInvariant();
            string commit = Assembly.GetExecutingAssembly().GetCustomAttributes<AssemblyMetadataAttribute>().Single(x => x.Key == "SourceCommit").Value;
            var document = PackageDocument.Read(bytes);
            var model = document.Export("1.0.0", commit, buildHash);
            var sidecar = pipelines ? document.ExportPipelineIdentities() : null;
            object output = bundle ? (object)new System.Collections.Generic.Dictionary<string, object> {
                { "contract", "ssis-export-bundle" }, { "version", "1.0.0" }, { "model", model }, { "identities", scopes ? document.ExportExecutionScopes() : document.ExportObjectIdentities(iterations) }
            } : model;
            if (pipelines) ((System.Collections.Generic.Dictionary<string, object>)output).Add("pipelineIdentities", sidecar);
            string json = JsonSerializer.Serialize(output);
            if ((long)json.Length * 2 > 16777216) throw new ModelException("LIMIT_EXCEEDED");
            Console.OutputEncoding = new UTF8Encoding(false); Console.Out.Write(json); return 0;
        }
        catch (ModelException error) { Console.Error.WriteLine(error.Message); return 3; }
        catch (Exception) { Console.Error.WriteLine("TBX_SSISMODEL_HOST_FAILURE"); return 4; }
    }
}
