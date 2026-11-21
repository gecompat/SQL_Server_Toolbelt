using System;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.Principal;
using Toolbelt.Archive.ZipMemory;
using Toolbelt.Filesystem.Windows;

public static class ArchiveDestinationFramework
{
    private static ZipEntryProvider.ExtractionArchive Open(params string[] names)
    {
        return Open(false, names);
    }

    private static ZipEntryProvider.ExtractionArchive Open(bool damageSecond, params string[] names)
    {
        var input = new MemoryStream();
        using (var zip = new ZipArchive(input, ZipArchiveMode.Create, true))
            foreach (string name in names)
                if (name.EndsWith("/", StringComparison.Ordinal))
                    zip.CreateEntry(name);
                else
                    using (Stream entry = zip.CreateEntry(name).Open()) entry.WriteByte(11);
        byte[] zipBytes = input.ToArray();
        if (damageSecond)
        {
            int central = 0;
            for (int i = 0; i < zipBytes.Length - 46; i++)
                if (zipBytes[i] == 0x50 && zipBytes[i + 1] == 0x4b && zipBytes[i + 2] == 1 && zipBytes[i + 3] == 2 &&
                    ++central == 2)
                {
                    zipBytes[BitConverter.ToInt32(zipBytes, i + 42) + 14] ^= 1;
                    zipBytes[i + 16] ^= 1;
                    break;
                }
            if (central != 2) throw new InvalidOperationException("CRC_FIXTURE_FAILED");
        }
        return new ZipEntryProvider.ExtractionArchive(new MemoryStream(zipBytes), zipBytes.Length, 1048576, 32,
            1048576, 1048576, 200, 1024);
    }

    private static ZipEntryProvider.IExtractionDestination Bind(string root, bool overwrite, bool exclusiveRoot)
    {
        Type type = typeof(WindowsFilesystemProvider).GetNestedType("ArchiveDestination", BindingFlags.NonPublic);
        try
        {
            return (ZipEntryProvider.IExtractionDestination)Activator.CreateInstance(type, root, String.Empty,
                null, true, overwrite, exclusiveRoot, (Action<Action>)(action => action()));
        }
        catch (TargetInvocationException error) { throw error.InnerException; }
    }

    private static void PrivateAcl(string root, bool permitOtherWriter = false)
    {
        using (WindowsIdentity current = WindowsIdentity.GetCurrent())
        {
            var acl = new DirectorySecurity();
            acl.SetOwner(current.User);
            acl.SetAccessRuleProtection(true, false);
            acl.AddAccessRule(new FileSystemAccessRule(current.User, FileSystemRights.FullControl,
                InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit, PropagationFlags.None,
                AccessControlType.Allow));
            if (permitOtherWriter)
                acl.AddAccessRule(new FileSystemAccessRule(new SecurityIdentifier(WellKnownSidType.WorldSid, null),
                    FileSystemRights.WriteData, AccessControlType.Allow));
            Directory.SetAccessControl(root, acl);
        }
    }

    public static int Main(string[] args)
    {
        string root = Path.Combine(Path.GetFullPath(args[0]), "archive-target-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(root);
        try
        {
            var regular = Bind(root, false, false);
            using ((IDisposable)regular)
            {
                var rows = ZipEntryProvider.ExtractDirectory(Open("nested/input", "empty/"), regular);
                if (rows.Count != 2 || rows[0].Status != "completed" || rows[1].Status != "completed")
                    throw new InvalidOperationException("CREATE_FAILED " + rows[0].ErrorCode + " " + rows[1].ErrorCode);
            }
            string first = Path.Combine(root, "nested", "input");
            if (File.ReadAllBytes(first)[0] != 11 || !Directory.Exists(Path.Combine(root, "empty")))
                throw new InvalidOperationException("FILESYSTEM_RESULT");
            regular = Bind(root, false, false);
            using ((IDisposable)regular)
            {
                var rows = ZipEntryProvider.ExtractDirectory(Open("not-made", "nested/input"), regular);
                if (rows[0].Status != "not_attempted" || rows[1].ErrorCode != "TARGET_EXISTS" ||
                    File.Exists(Path.Combine(root, "not-made")))
                    throw new InvalidOperationException("PREFLIGHT_MUTATED");
            }
            regular = Bind(root, false, false);
            using ((IDisposable)regular)
            {
                var rows = ZipEntryProvider.ExtractDirectory(Open(true, "good", "broken", "not-made"), regular);
                if (rows[0].Status != "completed" || rows[1].Status != "failed" || rows[1].ErrorCode != "CRC_MISMATCH" ||
                    rows[2].Status != "not_attempted" || File.Exists(Path.Combine(root, "broken")) ||
                    Directory.GetFiles(root, "*.part").Length != 0)
                    throw new InvalidOperationException("CRC_PARTIAL_RESULT_FAILED");
            }
            regular = Bind(root, false, false);
            using ((IDisposable)regular)
            {
                var rows = ZipEntryProvider.ExtractDirectory(Open(true, "again", "broken-directory/", "not-made"), regular);
                if (rows[0].Status != "completed" || rows[1].ErrorCode != "CRC_MISMATCH" ||
                    rows[2].Status != "not_attempted" || Directory.Exists(Path.Combine(root, "broken-directory")))
                    throw new InvalidOperationException("DIRECTORY_CRC_FAILED");
            }
            regular = Bind(root, false, false);
            using ((IDisposable)regular)
            {
                string late = Path.Combine(root, "late");
                if (regular.Inspect("late", false) != null) throw new InvalidOperationException("LATE_FIXTURE_FAILED");
                bool published;
                string code = regular.Publish("late", false, write =>
                {
                    write(new byte[] { 11 }, 1);
                    File.WriteAllBytes(late, new byte[] { 7 });
                }, out published);
                if (published || code != "TARGET_EXISTS" || File.ReadAllBytes(late)[0] != 7)
                    throw new InvalidOperationException("RIVAL_CHANGED_TARGET");
            }
            try
            {
                using ((IDisposable)Bind(root, true, false))
                    throw new InvalidOperationException("OVERWRITE_WITHOUT_ADMIN_POLICY");
            }
            catch (IOException error)
            {
                if (error.Message != "OVERWRITE_EXCLUSIVITY_REQUIRED") throw;
            }
            PrivateAcl(root, true);
            try
            {
                using ((IDisposable)Bind(root, true, true))
                    throw new InvalidOperationException("OVERWRITE_ALLOWED_UNTRUSTED_WRITER");
            }
            catch (IOException error)
            {
                if (error.Message != "OVERWRITE_EXCLUSIVITY_REQUIRED") throw;
            }
            PrivateAcl(root);
            File.WriteAllBytes(Path.Combine(root, "replace"), new byte[] { 4 });
            var replace = Bind(root, true, true);
            using ((IDisposable)replace)
            {
                var rows = ZipEntryProvider.ExtractDirectory(Open("replace"), replace);
                if (rows[0].Status != "completed" || rows[0].ErrorCode != null ||
                    File.ReadAllBytes(Path.Combine(root, "replace"))[0] != 11)
                    throw new InvalidOperationException("ATOMIC_REPLACE_FAILED " + rows[0].ErrorCode);
                var competing = Bind(root, false, true);
                using ((IDisposable)competing)
                {
                    var second = ZipEntryProvider.ExtractDirectory(Open("competing"), competing);
                    if (second[0].Status != "failed" || File.Exists(Path.Combine(root, "competing")))
                        throw new InvalidOperationException("OVERLAPPING_LOCK_FAILED");
                }
            }
            Console.WriteLine("ZIP_WINDOWS_DESTINATION_PASS");
            return 0;
        }
        catch (Exception error) { Console.Error.WriteLine(error.GetType().Name + " " + error.Message); return 1; }
        finally
        {
            string nested = Path.Combine(root, "nested", "input");
            if (File.Exists(nested)) File.Delete(nested);
            foreach (string leaf in new[] { "replace", "good", "again", "late" })
                File.Delete(Path.Combine(root, leaf));
            foreach (string child in new[] { "nested", "empty" })
            {
                string path = Path.Combine(root, child);
                if (Directory.Exists(path)) Directory.Delete(path);
            }
            Directory.Delete(root);
        }
    }
}
