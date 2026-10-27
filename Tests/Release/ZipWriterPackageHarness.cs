using System;
using System.IO;
using System.Reflection;
using System.Security.Cryptography;
using Toolbelt.Archive.ZipMemory;

public static class WriterPackageHarness
{
    private static void Require(bool condition, string code)
    {
        if (!condition) throw new InvalidOperationException(code);
    }

    private static string HashFile(string path)
    {
        using (FileStream stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read))
        using (SHA256 hash = SHA256.Create())
            return BitConverter.ToString(hash.ComputeHash(stream)).Replace("-", "").ToLowerInvariant();
    }

    private static Assembly CheckLoadedAssembly(string expectedPath, string expectedSha256, string expectedVersion)
    {
        Assembly assembly = typeof(ZipEntryProvider).Assembly;
        Require(String.Equals(Path.GetFullPath(assembly.Location), expectedPath, StringComparison.OrdinalIgnoreCase), "ZIP_PACKAGE_ASSEMBLY_LOCATION");
        Require(String.Equals(assembly.GetName().Version.ToString(), expectedVersion, StringComparison.Ordinal), "ZIP_PACKAGE_ASSEMBLY_VERSION");
        Require(String.Equals(HashFile(assembly.Location), expectedSha256, StringComparison.OrdinalIgnoreCase), "ZIP_PACKAGE_ASSEMBLY_SHA256");
        return assembly;
    }

    public static int Main(string[] args)
    {
        try
        {
            Require(args.Length == 3, "ZIP_PACKAGE_ARGUMENTS");
            string expectedPath = Path.GetFullPath(args[0]);
            string expectedSha256 = args[1];
            string expectedVersion = args[2];
            Assembly loaded = CheckLoadedAssembly(expectedPath, expectedSha256, expectedVersion);
            Require(EntrySecurityContract.Main() == 0, "ZIP_ENTRY_SECURITY_CONTRACT");
            WriterFramework.Run();
            Require(Object.ReferenceEquals(loaded, typeof(ZipEntryProvider).Assembly), "ZIP_PACKAGE_ASSEMBLY_RELOAD");
            CheckLoadedAssembly(expectedPath, expectedSha256, expectedVersion);
            Console.WriteLine("ZIP_WRITER_PACKAGE_FRAMEWORK_PASS");
            return 0;
        }
        catch
        {
            Console.Error.WriteLine("ZIP_WRITER_PACKAGE_FRAMEWORK_FAILED");
            return 1;
        }
    }
}
