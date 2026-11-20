using System;
using System.IO;
using System.Security.Cryptography;
using Mono.Cecil;

// Reiner Buildschritt: unveraendertes Original einlesen und eine gesonderte,
// unsignierte Toolbelt-Identitaet schreiben. Kein Patchen installierter DLLs.
internal static class PrivateScriptDom
{
    internal const string Name = "tlblt.Microsoft.SqlServer.TransactSql.ScriptDom";
    private static int Main(string[] args)
    {
        if (args.Length != 2 || File.Exists(args[1])) return 2;
        byte[] input = File.ReadAllBytes(args[0]);
        using (var hash = SHA512.Create())
            if (BitConverter.ToString(hash.ComputeHash(input)).Replace("-", "") != "459E137268A4CA378023CD7E68A04655CEC2C19A8D01546E81B1A7ABF1FE2F9226A03CC3FA2323081C3C1B05626AF988C98527711D577919CF409367F853DAC7") return 6;
        using (var stream = new MemoryStream(input, false))
        using (var assembly = AssemblyDefinition.ReadAssembly(stream, new ReaderParameters { InMemory = true, ReadSymbols = false }))
        {
            string original = assembly.Name.Name;
            if (original != "Microsoft.SqlServer.TransactSql.ScriptDom" || assembly.Name.Version.ToString() != "18.0.0.0") return 3;
            foreach (var module in assembly.Modules)
            {
                foreach (var type in module.Types)
                    if (!Check(type, original)) return 4;
                foreach (var reference in module.AssemblyReferences)
                    if (reference.Name == original) return 5;
                module.Attributes &= ~ModuleAttributes.StrongNameSigned;
                module.Name = Name + ".dll";
            }
            assembly.Name.Name = Name;
            // Eigene schwache Identitaet mit stabiler Version0; Herkunft
            // und Produktversion des Microsoft-Originals bleiben separat
            // durch dessen unveraenderten Hash und Dateimetadaten gebunden.
            assembly.Name.Version = new Version(0, 0, 0, 0);
            assembly.Name.PublicKey = new byte[0];
            assembly.Name.PublicKeyToken = new byte[0];
            assembly.Name.HasPublicKey = false;
            for (int i = assembly.CustomAttributes.Count - 1; i >= 0; i--)
            {
                string type = assembly.CustomAttributes[i].AttributeType.FullName;
                if (type == "System.Reflection.AssemblySignatureKeyAttribute" || type == "System.Reflection.AssemblyDelaySignAttribute" || type == "System.Reflection.AssemblyKeyFileAttribute" || type == "System.Reflection.AssemblyKeyNameAttribute")
                    assembly.CustomAttributes.RemoveAt(i);
            }
            assembly.Write(args[1], new WriterParameters { DeterministicMvid = true, Timestamp = 0 });
        }
        Console.WriteLine("PRIVATE_SCRIPTDOM_CREATED");
        return 0;
    }
    private static bool Check(TypeDefinition type, string original)
    {
        foreach (var method in type.Methods)
        {
            if (!method.HasBody) continue;
            foreach (var instruction in method.Body.Instructions)
            {
                var text = instruction.Operand as string;
                if (text != null && (text == original || text.IndexOf(original + ",", StringComparison.Ordinal) >= 0)) return false;
            }
        }
        foreach (var child in type.NestedTypes) if (!Check(child, original)) return false;
        return true;
    }
}
