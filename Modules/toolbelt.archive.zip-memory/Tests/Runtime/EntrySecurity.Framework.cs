using System;
using System.Collections;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.IO;
using System.IO.Compression;
using Toolbelt.Archive.ZipMemory;

// Rein synthetische Extraktionsgrenzen im gebundenen .NET-Framework-Prozess.
public static class EntrySecurityContract
{
    static int cases;
    static byte[] Archive(int size)
    {
        using (MemoryStream output = new MemoryStream())
        {
            using (ZipArchive zip = new ZipArchive(output, ZipArchiveMode.Create, true))
            using (Stream entry = zip.CreateEntry("payload.bin", CompressionLevel.Optimal).Open())
            {
                byte[] chunk = new byte[65536];
                while (size > 0) { int count = Math.Min(size, chunk.Length); entry.Write(chunk, 0, count); size -= count; }
            }
            return output.ToArray(); // Kleiner komprimierter Testcontainer, kein Extraktionsergebnis.
        }
    }
    static void Case(byte[] archive, long limit, int error, int length)
    {
        int rows = 0;
        foreach (object row in ZipEntryProvider.ExtractZipEntry(new SqlBytes(archive), "payload.bin", limit, new SqlDecimal(1000000), true))
        {
            SqlInt32 number, method, crc; SqlString message, name;
            SqlInt64 compressed, uncompressed; SqlBoolean encrypted; SqlBinary payload;
            ZipEntryProvider.FillRow(row, out number, out message, out name, out compressed, out uncompressed, out method, out crc, out encrypted, out payload);
            rows++;
            if (error == 0 ? !number.IsNull || payload.IsNull || payload.Length != length : number.IsNull || number.Value != error || !payload.IsNull)
                throw new InvalidOperationException("ZIP_ENTRY_SECURITY_ASSERT");
        }
        if (rows != 1) throw new InvalidOperationException("ZIP_ENTRY_SECURITY_ROWS");
        cases++;
    }
    static void SetSize(byte[] archive, int value)
    {
        byte[] size = BitConverter.GetBytes(value);
        Buffer.BlockCopy(size, 0, archive, 22, 4);
        for (int i = archive.Length - 46; i >= 0; i--)
            if (archive[i] == 0x50 && archive[i+1] == 0x4B && archive[i+2] == 1 && archive[i+3] == 2)
            { Buffer.BlockCopy(size, 0, archive, i + 24, 4); return; }
        throw new InvalidOperationException("ZIP_ENTRY_SECURITY_FIXTURE");
    }

    static ZipEntryProvider.ExtractionArchive Open(byte[] archive, long total = 67108864)
    {
        return new ZipEntryProvider.ExtractionArchive(new MemoryStream(archive, false), archive.LongLength,
            67108864, 1000, 67108864, total, 1000000, 1024);
    }

    static int CentralEntry(byte[] archive)
    {
        for (int i = archive.Length - 46; i >= 0; i--)
            if (archive[i] == 0x50 && archive[i + 1] == 0x4b && archive[i + 2] == 1 && archive[i + 3] == 2)
                return i;
        throw new InvalidOperationException("ZIP_STREAM_FIXTURE");
    }

    static void StreamingCases()
    {
        byte[] archive = Archive(1048576);
        var reader = Open(archive);
        long count = 0;
        int chunks = 0;
        long result = reader.CopyVerified(0, (buffer, read) =>
        {
            if (buffer.Length > 81920 || read <= 0) throw new InvalidOperationException("ZIP_STREAM_CHUNK");
            count += read;
            chunks++;
        });
        if (count != 1048576 || result != count || chunks <= 1 ||
            reader.Entries.Count != 1 || reader.Entries[0].Name != "payload.bin" ||
            reader.Entries[0].IsDirectory || reader.Entries[0].ErrorCode != null)
            throw new InvalidOperationException("ZIP_STREAM_COUNT");
        cases++;

        if (Open(archive, 1048575).Entries[0].ErrorCode != "TOTAL_SIZE_LIMIT")
            throw new InvalidOperationException("ZIP_STREAM_TOTAL");
        cases++;

        byte[] corrupt = (byte[])archive.Clone();
        corrupt[14] ^= 1;
        corrupt[CentralEntry(corrupt) + 16] ^= 1;
        try
        {
            Open(corrupt).CopyVerified(0, (buffer, read) => { });
            throw new InvalidOperationException("ZIP_STREAM_CRC_NOT_ENFORCED");
        }
        catch (InvalidDataException error)
        {
            if (error.Message != "CRC_MISMATCH") throw;
        }
        cases++;

        byte[] special = (byte[])archive.Clone();
        int entry = CentralEntry(special);
        special[entry + 5] = 3; // Unix creator.
        special[entry + 41] = 0xa0; // Symbolic link, not a regular file.
        if (Open(special).Entries[0].ErrorCode != "UNSUPPORTED_ENTRY_KIND")
            throw new InvalidOperationException("ZIP_STREAM_ENTRY_KIND");
        cases++;

        byte[] malformed = (byte[])archive.Clone();
        malformed[0] ^= 1;
        if (Open(malformed).Entries[0].ErrorCode != "INVALID_LOCAL_HEADER")
            throw new InvalidOperationException("ZIP_STREAM_LOCAL_HEADER");
        cases++;

        using (var output = new MemoryStream())
        {
            using (var zip = new ZipArchive(output, ZipArchiveMode.Create, true))
            {
                zip.CreateEntry("first.txt");
                zip.CreateEntry("empty/");
                zip.CreateEntry("first.txt");
                zip.CreateEntry("../misplaced.txt");
                zip.CreateEntry(new string('a', 1025));
            }
            var entries = Open(output.ToArray()).Entries;
            if (entries.Count != 5 || entries[0].ErrorCode != null ||
                !entries[1].IsDirectory || entries[1].ErrorCode != null ||
                entries[2].ErrorCode != "PATH_COLLISION" || entries[3].ErrorCode != "UNSAFE_PATH" ||
                entries[4].ErrorCode != "ENTRY_NAME_LIMIT" || entries[4].Name != new string('a', 1025))
                throw new InvalidOperationException("ZIP_STREAM_PREFLIGHT_SEQUENCE");
        }
        cases++;

        using (var output = new MemoryStream())
        {
            using (var zip = new ZipArchive(output, ZipArchiveMode.Create, true))
                zip.CreateEntry("empty/");
            byte[] emptyDirectory = output.ToArray();
            if (Open(emptyDirectory).CopyVerified(0, (buffer, read) => { }) != 0)
                throw new InvalidOperationException("ZIP_STREAM_DIRECTORY_SIZE");
            emptyDirectory[14] ^= 1;
            emptyDirectory[CentralEntry(emptyDirectory) + 16] ^= 1;
            try
            {
                Open(emptyDirectory).CopyVerified(0, (buffer, read) => { });
                throw new InvalidOperationException("ZIP_STREAM_DIRECTORY_CRC_NOT_ENFORCED");
            }
            catch (InvalidDataException error)
            {
                if (error.Message != "CRC_MISMATCH") throw;
            }
        }
        cases++;
    }

    sealed class TestDestination : ZipEntryProvider.IExtractionDestination
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

    static void DirectoryCases()
    {
        string[][] conflicts = {
            new[] { "parent/value", "PARENT/other" },
            new[] { "parent/value", "parent" },
            new[] { "parent/value", "parent/value" },
            new[] { "parent/value", "parent" , "parent-other" }
        };
        foreach (string[] names in conflicts)
        {
            var target = new TestDestination();
            var rows = ZipEntryProvider.ExtractDirectory(Open(ArchiveWithNames(names)), target);
            if (target.Published.Count != 0 || rows.Count != names.Length || rows[0].Status != "not_attempted" ||
                rows[1].Status != "failed" || rows[1].ErrorCode != "PATH_COLLISION")
                throw new InvalidOperationException("ZIP_DIRECTORY_COLLISION");
            cases++;
        }

        foreach (string forbidden in new[] { "NUL.txt", "LPT²", "tail.", "tail ", "name:stream", "a//b", "a\\b" })
        {
            var target = new TestDestination();
            var rows = ZipEntryProvider.ExtractDirectory(Open(ArchiveWithNames("ok", forbidden)), target);
            if (target.Published.Count != 0 || rows[0].Status != "not_attempted" || rows[1].ErrorCode != "UNSAFE_PATH")
                throw new InvalidOperationException("ZIP_DIRECTORY_UNSAFE");
            cases++;
        }

        var blocked = new TestDestination { Conflict = "second" };
        var blockedRows = ZipEntryProvider.ExtractDirectory(Open(ArchiveWithNames("first", "second", "third")), blocked);
        if (blocked.Published.Count != 0 || blockedRows[1].ErrorCode != "TARGET_EXISTS" ||
            blockedRows[0].Status != "not_attempted" || blockedRows[2].Status != "not_attempted")
            throw new InvalidOperationException("ZIP_DIRECTORY_DESTINATION_PREFLIGHT");
        cases++;

        var shortAlias = new TestDestination();
        var aliasRows = ZipEntryProvider.ExtractDirectory(Open(ArchiveWithNames("long name.txt", "LONGNA~1.TXT")), shortAlias);
        if (shortAlias.Published.Count != 0 || aliasRows[0].Status != "not_attempted" ||
            aliasRows[1].ErrorCode != "SHORT_NAME_ALIAS_FORBIDDEN")
            throw new InvalidOperationException("ZIP_DIRECTORY_SHORT_ALIAS");
        cases++;

        var expected = new TestDestination();
        var completeRows = ZipEntryProvider.ExtractDirectory(Open(ArchiveWithNames("parent/value", "parent/", "empty/")), expected);
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
        var partialRows = ZipEntryProvider.ExtractDirectory(Open(corrupted), partial);
        if (partial.Published.Count != 1 || !partial.Published.ContainsKey("first") ||
            partialRows[0].Status != "completed" || partialRows[1].ErrorCode != "CRC_MISMATCH" ||
            partialRows[2].Status != "not_attempted")
            throw new InvalidOperationException("ZIP_DIRECTORY_PARTIAL");
        cases++;

        var cleanup = new TestDestination { FailAfterPublish = "first" };
        var cleanupRows = ZipEntryProvider.ExtractDirectory(Open(ArchiveWithNames("first", "second")), cleanup);
        if (cleanup.Published.Count != 1 || cleanupRows[0].Status != "completed" ||
            cleanupRows[0].ErrorCode != "CLEANUP_FAILED" || cleanupRows[1].Status != "not_attempted")
            throw new InvalidOperationException("ZIP_DIRECTORY_POST_PUBLICATION");
        cases++;
    }

    public static int Main()
    {
        try
        {
            Case(Archive(16777215),16777216,0,16777215);
            Case(Archive(16777216),16777216,0,16777216);
            Case(Archive(16777217),16777216,51325,0);
            Case(Archive(67108864),67108864,0,67108864);
            byte[] overflow = Archive(67108865);
            Case(overflow,67108864,51325,0);
            SetSize(overflow,67108864); // Tatsächlicher Stream überschreitet beide deklarierten Größen.
            Case(overflow,67108864,51325,0);
            Case(Archive(1),67108865,51320,0);
            StreamingCases();
            DirectoryCases();
            Console.WriteLine("ZIP_ENTRY_SECURITY_PASS cases=" + cases); return 0;
        }
        catch (Exception error) { Console.Error.WriteLine("ZIP_ENTRY_SECURITY_FAILED " + error.Message); return 1; }
    }
}
