using System;
using System.IO;
using System.Net;
using System.Security;
using System.Security.Permissions;
using System.Runtime.CompilerServices;
using Toolbelt.Xlsx.Qualification;

// Nur Non-SQL-Harness. Kein Bestandteil der Providerassembly oder ihrer Trustkette.
public sealed class XlsxSandboxRunner : MarshalByRefObject
{
    [MethodImpl(MethodImplOptions.NoInlining)]
    private static void Demand(CodeAccessPermission permission) { permission.Demand(); }
    public string Run(byte[] binary, string expectedError)
    {
        var executionOnly = new PermissionSet(PermissionState.None);
        executionOnly.AddPermission(new SecurityPermission(SecurityPermissionFlag.Execution));
        executionOnly.PermitOnly();
        try
        {
            // Demand-Canaries beweisen, dass die restriktive Stackgrenze aktiv ist.
            // Keine dieser Operationen wird ausgeführt; eine erlaubte Demand ist
            // ein fehlgeschlagenes Gate, nicht Anlass zum Zugriff.
            int denied = 0;
            try { Demand(new FileIOPermission(FileIOPermissionAccess.Read, "C:\\SyntheticNoAccess\\fixture.bin")); } catch (SecurityException) { denied++; }
            try { Demand(new WebPermission(NetworkAccess.Connect, "https://example.invalid/no-access")); } catch (SecurityException) { denied++; }
            try { Demand(new IsolatedStorageFilePermission(PermissionState.Unrestricted)); } catch (SecurityException) { denied++; }
            try { Demand(new SecurityPermission(SecurityPermissionFlag.UnmanagedCode)); } catch (SecurityException) { denied++; }
            try { Demand(new SecurityPermission(SecurityPermissionFlag.AllFlags)); } catch (SecurityException) { denied++; }
            if (denied != 5) return "INCONCLUSIVE: sandbox demands not denied; domain=" +
                AppDomain.CurrentDomain.IsFullyTrusted + "; harness=" + typeof(XlsxSandboxRunner).Assembly.IsFullyTrusted + "; denied=" + denied;
            try
            {
                var workbook = new Workbook(binary, null);
                if (workbook.ListSheets().Length != 1 || workbook.ReadCells(1).Length != 9)
                    throw new Exception("Sandbox result mismatch");
                if (expectedError != null) throw new Exception("Expected sandbox rejection missing");
            }
            catch (System.Xml.XmlException) { if (expectedError != "DTD") throw; }
            catch (InvalidDataException e) { if (expectedError == null || e.Message != expectedError) throw; }
            return "PASS: restricted Framework execution and deny canaries; not OS syscall observation";
        }
        finally { CodeAccessPermission.RevertPermitOnly(); }
    }
}

public static class XlsxSandboxHost
{
    public static int Main(string[] args)
    {
        if (args.Length < 1 || args.Length > 2) return 2;
        string result = Run(AppDomain.CurrentDomain.BaseDirectory, Convert.FromBase64String(args[0]),args.Length==2?args[1]:null);
        Console.WriteLine(result); return result.StartsWith("PASS:",StringComparison.Ordinal) ? 0 : 3;
    }
    public static string Run(string baseDirectory, byte[] fixture, string expectedError)
    {
        var permissions = new PermissionSet(PermissionState.None);
        permissions.AddPermission(new SecurityPermission(SecurityPermissionFlag.Execution));
        // Ausschließlich Loader-Bootstrap. PermitOnly entfernt diese Permission
        // vor den Canaries und dem eigentlichen Parseraufruf.
        permissions.AddPermission(new FileIOPermission(FileIOPermissionAccess.Read | FileIOPermissionAccess.PathDiscovery, baseDirectory));
        var domain = AppDomain.CreateDomain("SyntheticXlsxRestricted", null,
            new AppDomainSetup { ApplicationBase = baseDirectory }, permissions);
        try
        {
            var runner = (XlsxSandboxRunner)domain.CreateInstanceAndUnwrap(
                typeof(XlsxSandboxRunner).Assembly.FullName, typeof(XlsxSandboxRunner).FullName);
            return runner.Run(fixture, expectedError);
        }
        finally { AppDomain.Unload(domain); }
    }
}
