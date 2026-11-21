using System;
using System.Collections.Generic;
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

    private static ArchiveDirectoryExtraction.IExtractionDestination Bind(string root, bool overwrite, bool exclusiveRoot)
    {
        Type type = typeof(WindowsFilesystemProvider).GetNestedType("ArchiveDestination", BindingFlags.NonPublic);
        try
        {
            return (ArchiveDirectoryExtraction.IExtractionDestination)Activator.CreateInstance(type, root, String.Empty,
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

    static int CentralEntry(byte[] archive)
    {
        for (int i = archive.Length - 46; i >= 0; i--)
            if (archive[i] == 0x50 && archive[i + 1] == 0x4b && archive[i + 2] == 1 && archive[i + 3] == 2)
                return i;
        throw new InvalidOperationException("ZIP_STREAM_FIXTURE");
    }

    private static ZipEntryProvider.ExtractionArchive Open(byte[] bytes)
    {
        return new ZipEntryProvider.ExtractionArchive(new MemoryStream(bytes), bytes.Length, 1048576, 32,
            1048576, 1048576, 200000, 1024);
    }

    sealed class TestDestination : ArchiveDirectoryExtraction.IExtractionDestination
    {
        public readonly List<string> Inspections = new List<string>();
        public readonly Dictionary<string, byte[]> Published = new Dictionary<string, byte[]>();
        public string Conflict;
        public string FailAfterPublish;

        public string Inspect(string path, bool directory)
        {
            Inspections.Add(path);
            return path == Conflict ? "TARGET_EXISTS" : null;
        }

        public string Publish(string path, bool directory, Action<Action<byte[], int>> copy, out bool published)
        {
            published = false;
            using (var stage = new MemoryStream())
            {
                try { copy((buffer, count) => stage.Write(buffer, 0, count)); }
                catch (InvalidDataException error) { return error.Message; }
                Published.Add(path, stage.ToArray());
                published = true;
            }
            return path == FailAfterPublish ? "CLEANUP_FAILED" : null;
        }
    }

    static byte[] ArchiveWithNames(params string[] names)
    {
        using (var output = new MemoryStream())
        {
            using (var zip = new ZipArchive(output, ZipArchiveMode.Create, true))
                foreach (string name in names)
                    if (name.EndsWith("/", StringComparison.Ordinal))
                        zip.CreateEntry(name);
                    else
                        using (var content = zip.CreateEntry(name).Open()) content.WriteByte(11);
            return output.ToArray();
        }
    }

    static int DirectoryCases()
    {
        int cases = 0;
        string[][] conflicts = {
            new[] { "parent/value", "PARENT/other" },
            new[] { "parent/value", "parent" },
            new[] { "parent/value", "parent/value" },
            new[] { "parent/value", "parent" , "parent-other" }
        };
        foreach (string[] names in conflicts)
        {
            var target = new TestDestination();
            var rows = ArchiveDirectoryExtraction.ExtractDirectory(Open(ArchiveWithNames(names)), target);
            if (target.Published.Count != 0 || rows.Count != names.Length || rows[0].Status != "not_attempted" ||
                rows[1].Status != "failed" || rows[1].ErrorCode != "PATH_COLLISION")
                throw new InvalidOperationException("ZIP_DIRECTORY_COLLISION");
            cases++;
        }

        foreach (string forbidden in new[] { "NUL.txt", "LPT\u00b2", "tail.", "tail ", "name:stream", "a//b", "a\\b" })
        {
            var target = new TestDestination();
            var rows = ArchiveDirectoryExtraction.ExtractDirectory(Open(ArchiveWithNames("ok", forbidden)), target);
            if (target.Published.Count != 0 || rows[0].Status != "not_attempted" || rows[1].ErrorCode != "UNSAFE_PATH")
                throw new InvalidOperationException("ZIP_DIRECTORY_UNSAFE");
            cases++;
        }

        var blocked = new TestDestination { Conflict = "second" };
        var blockedRows = ArchiveDirectoryExtraction.ExtractDirectory(Open(ArchiveWithNames("first", "second", "third")), blocked);
        if (blocked.Published.Count != 0 || blockedRows[1].ErrorCode != "TARGET_EXISTS" ||
            blockedRows[0].Status != "not_attempted" || blockedRows[2].Status != "not_attempted")
            throw new InvalidOperationException("ZIP_DIRECTORY_DESTINATION_PREFLIGHT");
        cases++;

        var shortAlias = new TestDestination();
        var aliasRows = ArchiveDirectoryExtraction.ExtractDirectory(Open(ArchiveWithNames("long name.txt", "LONGNA~1.TXT")), shortAlias);
        if (shortAlias.Published.Count != 0 || aliasRows[0].Status != "not_attempted" ||
            aliasRows[1].ErrorCode != "SHORT_NAME_ALIAS_FORBIDDEN")
            throw new InvalidOperationException("ZIP_DIRECTORY_SHORT_ALIAS");
        cases++;

        var expected = new TestDestination();
        var completeRows = ArchiveDirectoryExtraction.ExtractDirectory(Open(ArchiveWithNames("parent/value", "parent/", "empty/")), expected);
        if (expected.Inspections.Count != 3 || expected.Published.Count != 3 || completeRows[0].BytesWritten != 1 ||
            completeRows[1].BytesWritten != 0 || completeRows[2].Status != "completed")
            throw new InvalidOperationException("ZIP_DIRECTORY_SUCCESS");
        cases++;

        // Change the middle entry's declared CRC in both headers without
        // disturbing the directory or the verification of the first payload.
        byte[] corrupted = ArchiveWithNames("first", "second", "third");
        int central = CentralEntry(corrupted) - (46 + "second".Length);
        int local = BitConverter.ToInt32(corrupted, central + 42);
        corrupted[central + 16] ^= 1;
        corrupted[local + 14] ^= 1;
        var partial = new TestDestination();
        var partialRows = ArchiveDirectoryExtraction.ExtractDirectory(Open(corrupted), partial);
        if (partial.Published.Count != 1 || !partial.Published.ContainsKey("first") ||
            partialRows[0].Status != "completed" || partialRows[1].ErrorCode != "CRC_MISMATCH" ||
            partialRows[2].Status != "not_attempted")
            throw new InvalidOperationException("ZIP_DIRECTORY_PARTIAL");
        cases++;

        var cleanup = new TestDestination { FailAfterPublish = "first" };
        var cleanupRows = ArchiveDirectoryExtraction.ExtractDirectory(Open(ArchiveWithNames("first", "second")), cleanup);
        if (cleanup.Published.Count != 1 || cleanupRows[0].Status != "completed" ||
            cleanupRows[0].ErrorCode != "CLEANUP_FAILED" || cleanupRows[1].Status != "not_attempted")
            throw new InvalidOperationException("ZIP_DIRECTORY_POST_PUBLICATION");
        return cases + 1;
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
                var rows = ArchiveDirectoryExtraction.ExtractDirectory(Open("nested/input", "empty/"), regular);
                if (rows.Count != 2 || rows[0].Status != "completed" || rows[1].Status != "completed")
                    throw new InvalidOperationException("CREATE_FAILED " + rows[0].ErrorCode + " " + rows[1].ErrorCode);
            }
            string first = Path.Combine(root, "nested", "input");
            if (File.ReadAllBytes(first)[0] != 11 || !Directory.Exists(Path.Combine(root, "empty")))
                throw new InvalidOperationException("FILESYSTEM_RESULT");
            regular = Bind(root, false, false);
            using ((IDisposable)regular)
            {
                var rows = ArchiveDirectoryExtraction.ExtractDirectory(Open("not-made", "nested/input"), regular);
                if (rows[0].Status != "not_attempted" || rows[1].ErrorCode != "TARGET_EXISTS" ||
                    File.Exists(Path.Combine(root, "not-made")))
                    throw new InvalidOperationException("PREFLIGHT_MUTATED");
            }
            regular = Bind(root, false, false);
            using ((IDisposable)regular)
            {
                var rows = ArchiveDirectoryExtraction.ExtractDirectory(Open(true, "good", "broken", "not-made"), regular);
                if (rows[0].Status != "completed" || rows[1].Status != "failed" || rows[1].ErrorCode != "CRC_MISMATCH" ||
                    rows[2].Status != "not_attempted" || File.Exists(Path.Combine(root, "broken")) ||
                    Directory.GetFiles(root, "*.part").Length != 0)
                    throw new InvalidOperationException("CRC_PARTIAL_RESULT_FAILED");
            }
            regular = Bind(root, false, false);
            using ((IDisposable)regular)
            {
                var rows = ArchiveDirectoryExtraction.ExtractDirectory(Open(true, "again", "broken-directory/", "not-made"), regular);
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
                var rows = ArchiveDirectoryExtraction.ExtractDirectory(Open("replace"), replace);
                if (rows[0].Status != "completed" || rows[0].ErrorCode != null ||
                    File.ReadAllBytes(Path.Combine(root, "replace"))[0] != 11)
                    throw new InvalidOperationException("ATOMIC_REPLACE_FAILED " + rows[0].ErrorCode);
                var competing = Bind(root, false, true);
                using ((IDisposable)competing)
                {
                    var second = ArchiveDirectoryExtraction.ExtractDirectory(Open("competing"), competing);
                    if (second[0].Status != "failed" || File.Exists(Path.Combine(root, "competing")))
                        throw new InvalidOperationException("OVERLAPPING_LOCK_FAILED");
                }
            }
            Console.WriteLine("ZIP_WINDOWS_DESTINATION_PASS planningCases=" + DirectoryCases());
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
