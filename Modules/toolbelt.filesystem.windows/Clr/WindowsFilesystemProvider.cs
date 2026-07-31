using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.IO;
using System.Security.Principal;
using System.Text;
using Microsoft.SqlServer.Server;

namespace Toolbelt.Filesystem.Windows
{
    // This provider never accepts an absolute caller path. The only configured
    // physical paths are server-side root aliases and optional staging folders.
    public static class WindowsFilesystemProvider
    {
        private const int MaxChunkBytes = 16 * 1024 * 1024;
        private const int BufferBytes = 1024 * 1024;

        [SqlProcedure]
        public static void ReadBinaryFileChunk(string rootAlias, string relativePath, long byteOffset, int maxBytes, string executionIdentity)
        {
            if (byteOffset < 0 || maxBytes < 1 || maxBytes > MaxChunkBytes) Fail("InvalidChunkRange");
            Root root = GetRoot(rootAlias, "AllowRead");
            string path = Resolve(root.RootPath, relativePath, false);
            byte[] value = null; long length = 0;
            RunAs(executionIdentity, delegate
            {
                AssertNoReparsePoint(root.RootPath, path);
                using (FileStream input = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read))
                {
                    length = input.Length;
                    if (byteOffset > length) Fail("OffsetBeyondEnd");
                    input.Position = byteOffset;
                    int requested = (int)Math.Min((long)maxBytes, length - byteOffset);
                    value = new byte[requested];
                    int offset = 0, read;
                    while (offset < requested && (read = input.Read(value, offset, requested - offset)) > 0) offset += read;
                    if (offset != requested) Array.Resize(ref value, offset);
                }
            });
            SqlDataRecord row = Record("Content", SqlDbType.VarBinary, -1, "BytesRead", SqlDbType.Int, "NextByteOffset", SqlDbType.BigInt, "EndOfFile", SqlDbType.Bit);
            row.SetBytes(0, 0, value, 0, value.Length); row.SetInt32(1, value.Length); row.SetInt64(2, byteOffset + value.Length); row.SetBoolean(3, byteOffset + value.Length >= length); SqlContext.Pipe.Send(row);
        }

        [SqlProcedure]
        public static void ReadTextFileChunk(string rootAlias, string relativePath, long byteOffset, int maxBytes, string encodingName, string executionIdentity)
        {
            if (byteOffset < 0 || maxBytes < 4 || maxBytes > MaxChunkBytes) Fail("InvalidChunkRange");
            Encoding encoding = StrictEncoding(encodingName); Root root = GetRoot(rootAlias, "AllowRead");
            string path = Resolve(root.RootPath, relativePath, false); byte[] bytes = null; long length = 0; int used = 0; string text = null;
            RunAs(executionIdentity, delegate
            {
                AssertNoReparsePoint(root.RootPath, path);
                using (FileStream input = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read))
                {
                    length = input.Length; if (byteOffset > length) Fail("OffsetBeyondEnd"); input.Position = byteOffset;
                    int requested = (int)Math.Min((long)maxBytes, length - byteOffset); bytes = new byte[requested];
                    int read; while (used < requested && (read = input.Read(bytes, used, requested - used)) > 0) used += read;
                }
                // Preserve a decoder boundary; the caller continues at NextByteOffset.
                int lower = Math.Max(0, used - encoding.GetMaxByteCount(1));
                for (int candidate = used; candidate >= lower; candidate--)
                    try { text = encoding.GetString(bytes, 0, candidate); used = candidate; return; }
                    catch (DecoderFallbackException) { }
                Fail("TextChunkEndsInsideCharacter");
            });
            SqlDataRecord row = Record("Content", SqlDbType.NVarChar, -1, "BytesRead", SqlDbType.Int, "NextByteOffset", SqlDbType.BigInt, "EndOfFile", SqlDbType.Bit, "EncodingName", SqlDbType.NVarChar, 128);
            row.SetString(0, text); row.SetInt32(1, used); row.SetInt64(2, byteOffset + used); row.SetBoolean(3, byteOffset + used >= length); row.SetString(4, encoding.WebName); SqlContext.Pipe.Send(row);
        }

        [SqlProcedure]
        public static void WriteBinaryFile(string rootAlias, string relativePath, SqlBytes content, bool overwrite, string executionIdentity)
        {
            if (content.IsNull) Fail("ContentRequired"); Root root = GetRoot(rootAlias, "AllowWrite"); string target = Resolve(root.RootPath, relativePath, false); long written = 0;
            RunAs(executionIdentity, delegate
            {
                AssertNoReparsePoint(root.RootPath, Path.GetDirectoryName(target));
                if (!overwrite && File.Exists(target)) Fail("TargetExists");
                WriteAtomically(root, target, delegate(FileStream output)
                {
                    byte[] buffer = new byte[BufferBytes]; long offset = 0;
                    while (offset < content.Length) { int expected = (int)Math.Min(buffer.Length, content.Length - offset); long read = content.Read(offset, buffer, 0, expected); if (read <= 0) Fail("SourceReadFailed"); output.Write(buffer, 0, (int)read); offset += read; written += read; }
                });
            });
            SendWrite(written, rootAlias, relativePath);
        }

        [SqlProcedure]
        public static void WriteTextFile(string rootAlias, string relativePath, SqlChars content, string encodingName, bool writeBom, bool overwrite, string executionIdentity)
        {
            if (content.IsNull) Fail("ContentRequired"); Encoding encoding = StrictEncoding(encodingName); Root root = GetRoot(rootAlias, "AllowWrite"); string target = Resolve(root.RootPath, relativePath, false); long written = 0;
            RunAs(executionIdentity, delegate
            {
                AssertNoReparsePoint(root.RootPath, Path.GetDirectoryName(target)); if (!overwrite && File.Exists(target)) Fail("TargetExists");
                WriteAtomically(root, target, delegate(FileStream output)
                {
                    if (writeBom) { byte[] preamble = encoding.GetPreamble(); output.Write(preamble, 0, preamble.Length); written += preamble.Length; }
                    char[] characters = new char[32768]; long offset = 0;
                    while (offset < content.Length) { int expected = (int)Math.Min(characters.Length, content.Length - offset); long read = content.Read(offset, characters, 0, expected); if (read <= 0) Fail("SourceReadFailed"); byte[] encoded = encoding.GetBytes(characters, 0, (int)read); output.Write(encoded, 0, encoded.Length); offset += read; written += encoded.Length; }
                });
            });
            SendWrite(written, rootAlias, relativePath);
        }

        [SqlProcedure]
        public static void TranscodeTextFile(string sourceRootAlias, string sourceRelativePath, string sourceEncoding, string targetRootAlias, string targetRelativePath, string targetEncoding, bool writeBom, bool overwrite, string executionIdentity)
        {
            Root source = GetRoot(sourceRootAlias, "AllowRead"), targetRoot = GetRoot(targetRootAlias, "AllowWrite"); Encoding input = StrictEncoding(sourceEncoding), output = StrictEncoding(targetEncoding);
            string sourcePath = Resolve(source.RootPath, sourceRelativePath, false), targetPath = Resolve(targetRoot.RootPath, targetRelativePath, false); long written = 0;
            RunAs(executionIdentity, delegate
            {
                AssertNoReparsePoint(source.RootPath, sourcePath); AssertNoReparsePoint(targetRoot.RootPath, Path.GetDirectoryName(targetPath)); if (!overwrite && File.Exists(targetPath)) Fail("TargetExists");
                WriteAtomically(targetRoot, targetPath, delegate(FileStream destination)
                {
                    if (writeBom) { byte[] preamble = output.GetPreamble(); destination.Write(preamble, 0, preamble.Length); written += preamble.Length; }
                    using (StreamReader reader = new StreamReader(new FileStream(sourcePath, FileMode.Open, FileAccess.Read, FileShare.Read), input, false, 32768, false))
                    { char[] characters = new char[32768]; int read; while ((read = reader.Read(characters, 0, characters.Length)) > 0) { byte[] encoded = output.GetBytes(characters, 0, read); destination.Write(encoded, 0, encoded.Length); written += encoded.Length; } }
                });
            });
            SendWrite(written, targetRootAlias, targetRelativePath);
        }

        [SqlProcedure]
        public static void ListDirectory(string rootAlias, string relativePath, bool recursive, int maxDepth, int maxEntries, string executionIdentity)
        {
            if (maxDepth < 0 || maxEntries < 1) Fail("InvalidListLimit"); Root root = GetRoot(rootAlias, "AllowList"); string start = Resolve(root.RootPath, relativePath, true);
            RunAs(executionIdentity, delegate
            {
                AssertNoReparsePoint(root.RootPath, start); SqlDataRecord row = Record("EntryOrdinal", SqlDbType.BigInt, "RelativePath", SqlDbType.NVarChar, 4000, "EntryType", SqlDbType.VarChar, 16, "SizeBytes", SqlDbType.BigInt, "LastWriteTimeUtc", SqlDbType.DateTime2, "IsReparsePoint", SqlDbType.Bit); SqlContext.Pipe.SendResultsStart(row);
                try { long ordinal = 0; foreach (string item in Enumerate(start, recursive, maxDepth)) { if (++ordinal > maxEntries) Fail("EntryLimitExceeded"); FileAttributes attributes = File.GetAttributes(item); bool isDirectory = (attributes & FileAttributes.Directory) != 0, isReparse = (attributes & FileAttributes.ReparsePoint) != 0; row.SetInt64(0, ordinal); row.SetString(1, Relative(root.RootPath, item)); row.SetString(2, isDirectory ? "directory" : "file"); row.SetInt64(3, isDirectory ? 0 : new FileInfo(item).Length); row.SetDateTime(4, isDirectory ? Directory.GetLastWriteTimeUtc(item) : File.GetLastWriteTimeUtc(item)); row.SetBoolean(5, isReparse); SqlContext.Pipe.SendResultsRow(row); } }
                finally { SqlContext.Pipe.SendResultsEnd(); }
            });
        }

        [SqlProcedure]
        public static void CreateDirectory(string rootAlias, string relativePath, string executionIdentity) { Root root = GetRoot(rootAlias, "AllowCreateDirectory"); string path = Resolve(root.RootPath, relativePath, true); RunAs(executionIdentity, delegate { AssertNoReparsePoint(root.RootPath, Path.GetDirectoryName(path)); Directory.CreateDirectory(path); }); SendAction(rootAlias, relativePath, "created"); }
        [SqlProcedure]
        public static void RemoveFile(string rootAlias, string relativePath, string executionIdentity) { Root root = GetRoot(rootAlias, "AllowDelete"); string path = Resolve(root.RootPath, relativePath, false); RunAs(executionIdentity, delegate { AssertNoReparsePoint(root.RootPath, path); if (!File.Exists(path)) Fail("FileNotFound"); File.Delete(path); }); SendAction(rootAlias, relativePath, "removed"); }
        [SqlProcedure]
        public static void RemoveDirectory(string rootAlias, string relativePath, bool recursive, int maxDepth, int maxEntries, string executionIdentity)
        {
            if (maxDepth < 0 || maxEntries < 1) Fail("InvalidListLimit"); Root root = GetRoot(rootAlias, "AllowDelete"); string path = Resolve(root.RootPath, relativePath, true); if (Same(root.RootPath, path)) Fail("RootDeletionForbidden");
            RunAs(executionIdentity, delegate { AssertNoReparsePoint(root.RootPath, path); if (!Directory.Exists(path)) Fail("DirectoryNotFound"); int count = 0; foreach (string item in Enumerate(path, recursive, maxDepth)) { if (++count > maxEntries) Fail("EntryLimitExceeded"); if ((File.GetAttributes(item) & FileAttributes.ReparsePoint) != 0) Fail("ReparsePointForbidden"); } if (!recursive && count > 0) Fail("DirectoryNotEmpty"); Directory.Delete(path, recursive); }); SendAction(rootAlias, relativePath, "removed");
        }

        private static Root GetRoot(string alias, string requiredFlag) { if (String.IsNullOrWhiteSpace(alias)) Fail("RootAliasRequired"); using (SqlConnection connection = new SqlConnection("context connection=true")) using (SqlCommand command = connection.CreateCommand()) { command.CommandText = "SELECT RootPath, WorkPath FROM toolbelt_filesystem.FileSystemRoot WHERE RootAlias = @Alias AND IsActive = 1 AND " + requiredFlag + " = 1;"; command.Parameters.Add("@Alias", SqlDbType.NVarChar, 128).Value = alias; connection.Open(); using (SqlDataReader reader = command.ExecuteReader()) { if (!reader.Read()) Fail("RootNotAuthorized"); return new Root { RootPath = reader.GetString(0), WorkPath = reader.IsDBNull(1) ? null : reader.GetString(1) }; } } }
        private static void RunAs(string mode, Action action) { if (String.Equals(mode, "ServiceAccount", StringComparison.Ordinal)) { action(); return; } if (!String.Equals(mode, "Caller", StringComparison.Ordinal)) Fail("InvalidExecutionIdentity"); WindowsIdentity identity = SqlContext.WindowsIdentity; if (identity == null) Fail("CallerIdentityUnavailable"); WindowsImpersonationContext context = null; try { context = identity.Impersonate(); action(); } finally { if (context != null) context.Undo(); } }
        private static Encoding StrictEncoding(string name) { if (String.IsNullOrWhiteSpace(name)) Fail("EncodingRequired"); try { return Encoding.GetEncoding(name, EncoderFallback.ExceptionFallback, DecoderFallback.ExceptionFallback); } catch (ArgumentException) { Fail("UnsupportedEncoding"); return null; } }
        private static string Resolve(string rootPath, string relativePath, bool allowEmpty) { if (String.IsNullOrWhiteSpace(rootPath) || relativePath == null || (!allowEmpty && relativePath.Length == 0)) Fail("InvalidPath"); if (Path.IsPathRooted(relativePath) || relativePath.IndexOf(':') >= 0) Fail("AbsolutePathForbidden"); string root = Path.GetFullPath(rootPath).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar), candidate = Path.GetFullPath(Path.Combine(root, relativePath)); if (!candidate.StartsWith(root + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase) && !Same(root, candidate)) Fail("PathOutsideRoot"); return candidate; }
        private static void AssertNoReparsePoint(string rootPath, string candidate) { string root = Path.GetFullPath(rootPath).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar); string current = root; if (Directory.Exists(current) && (File.GetAttributes(current) & FileAttributes.ReparsePoint) != 0) Fail("ReparsePointForbidden"); foreach (string part in Relative(root, candidate).Split(new[] {'\\', '/'}, StringSplitOptions.RemoveEmptyEntries)) { current = Path.Combine(current, part); if ((Directory.Exists(current) || File.Exists(current)) && (File.GetAttributes(current) & FileAttributes.ReparsePoint) != 0) Fail("ReparsePointForbidden"); } }
        private static IEnumerable<string> Enumerate(string start, bool recursive, int maxDepth) { Queue<PathDepth> queue = new Queue<PathDepth>(); queue.Enqueue(new PathDepth { Path = start, Depth = 0 }); while (queue.Count != 0) { PathDepth current = queue.Dequeue(); foreach (string item in Directory.EnumerateFileSystemEntries(current.Path)) { yield return item; FileAttributes attributes = File.GetAttributes(item); if (recursive && (attributes & FileAttributes.Directory) != 0 && (attributes & FileAttributes.ReparsePoint) == 0 && current.Depth < maxDepth) queue.Enqueue(new PathDepth { Path = item, Depth = current.Depth + 1 }); } } }
        private static void WriteAtomically(Root root, string target, Action<FileStream> write) { string stagingDirectory = String.IsNullOrWhiteSpace(root.WorkPath) ? Path.GetDirectoryName(target) : Resolve(root.RootPath, root.WorkPath, false); AssertNoReparsePoint(root.RootPath, stagingDirectory); string staging = Path.Combine(stagingDirectory, ".tbx-" + Guid.NewGuid().ToString("N") + ".part"); try { using (FileStream output = new FileStream(staging, FileMode.CreateNew, FileAccess.Write, FileShare.None)) { write(output); output.Flush(true); } if (File.Exists(target)) File.Replace(staging, target, null, true); else File.Move(staging, target); } finally { if (File.Exists(staging)) File.Delete(staging); } }
        private static SqlDataRecord Record(params object[] definition) { List<SqlMetaData> metadata = new List<SqlMetaData>(); for (int i = 0; i < definition.Length;) { string name = (string)definition[i++]; SqlDbType type = (SqlDbType)definition[i++]; long length = 0; if (i < definition.Length && (definition[i] is int || definition[i] is long)) length = Convert.ToInt64(definition[i++]); metadata.Add(length == 0 ? new SqlMetaData(name, type) : new SqlMetaData(name, type, length)); } return new SqlDataRecord(metadata.ToArray()); }
        private static void SendWrite(long bytes, string rootAlias, string relativePath) { SqlDataRecord row = Record("BytesWritten", SqlDbType.BigInt, "RootAlias", SqlDbType.NVarChar, 128, "RelativePath", SqlDbType.NVarChar, 4000, "State", SqlDbType.VarChar, 16); row.SetInt64(0, bytes); row.SetString(1, rootAlias); row.SetString(2, relativePath); row.SetString(3, "completed"); SqlContext.Pipe.Send(row); }
        private static void SendAction(string rootAlias, string relativePath, string state) { SqlDataRecord row = Record("RootAlias", SqlDbType.NVarChar, 128, "RelativePath", SqlDbType.NVarChar, 4000, "State", SqlDbType.VarChar, 16); row.SetString(0, rootAlias); row.SetString(1, relativePath); row.SetString(2, state); SqlContext.Pipe.Send(row); }
        private static string Relative(string root, string path) { return path.Substring(root.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar).Length).TrimStart(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar); }
        private static bool Same(string left, string right) { return String.Equals(Path.GetFullPath(left).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar), Path.GetFullPath(right).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar), StringComparison.OrdinalIgnoreCase); }
        private static void Fail(string code) { throw new InvalidOperationException("TBXFS:" + code); }
        private sealed class Root { public string RootPath; public string WorkPath; }
        private sealed class PathDepth { public string Path; public int Depth; }
    }
}
