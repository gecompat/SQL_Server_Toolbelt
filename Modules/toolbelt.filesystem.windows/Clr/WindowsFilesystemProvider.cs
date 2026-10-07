using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.IO;
using System.Runtime.ExceptionServices;
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
            FilesystemExecution execution = new FilesystemExecution(executionIdentity);
            execution.Run(delegate
            {
                AssertNoReparsePoint(root.RootPath, Path.GetDirectoryName(target));
                if (!overwrite && File.Exists(target)) Fail("TargetExists");
            });
            // SQL-backed LOBs erst nach Undo lesen; jede Dateiaktion bleibt bei
            // derselben zuvor erfassten Identitaet. Kein ganzes LOB materialisieren.
            WriteAtomicallyScoped(root, target, overwrite, delegate(FileStream output)
            { written = CopyBinaryContent(content, output, execution.Run); }, execution.Run);
            SendWrite(written, rootAlias, relativePath);
        }

        [SqlProcedure]
        public static void WriteTextFile(string rootAlias, string relativePath, SqlChars content, string encodingName, bool writeBom, bool overwrite, string executionIdentity)
        {
            if (content.IsNull) Fail("ContentRequired"); Encoding encoding = StrictEncoding(encodingName); Root root = GetRoot(rootAlias, "AllowWrite"); string target = Resolve(root.RootPath, relativePath, false); long written = 0;
            FilesystemExecution execution = new FilesystemExecution(executionIdentity);
            execution.Run(delegate
            {
                AssertNoReparsePoint(root.RootPath, Path.GetDirectoryName(target)); if (!overwrite && File.Exists(target)) Fail("TargetExists");
            });
            WriteAtomicallyScoped(root, target, overwrite, delegate(FileStream output)
            { written = CopyTextContent(content, encoding, writeBom, output, execution.Run); }, execution.Run);
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
                WriteAtomically(targetRoot, targetPath, overwrite, delegate(FileStream destination)
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
            List<ListedEntry> entries = new List<ListedEntry>();
            RunAs(executionIdentity, delegate
            {
                AssertNoReparsePoint(root.RootPath, start); long ordinal = 0;
                foreach (string item in Enumerate(start, recursive, maxDepth))
                {
                    if (++ordinal > maxEntries) Fail("EntryLimitExceeded");
                    FileAttributes attributes = File.GetAttributes(item);
                    bool isDirectory = (attributes & FileAttributes.Directory) != 0, isReparse = (attributes & FileAttributes.ReparsePoint) != 0;
                    entries.Add(new ListedEntry { Ordinal = ordinal, RelativePath = Relative(root.RootPath, item), EntryType = isDirectory ? "directory" : "file", SizeBytes = isDirectory ? 0 : new FileInfo(item).Length, LastWriteTimeUtc = isDirectory ? Directory.GetLastWriteTimeUtc(item) : File.GetLastWriteTimeUtc(item), IsReparsePoint = isReparse });
                }
            });
            SqlDataRecord row = Record("EntryOrdinal", SqlDbType.BigInt, "RelativePath", SqlDbType.NVarChar, 4000, "EntryType", SqlDbType.VarChar, 16, "SizeBytes", SqlDbType.BigInt, "LastWriteTimeUtc", SqlDbType.DateTime2, "IsReparsePoint", SqlDbType.Bit);
            SqlContext.Pipe.SendResultsStart(row);
            try { foreach (ListedEntry entry in entries) { row.SetInt64(0, entry.Ordinal); row.SetString(1, entry.RelativePath); row.SetString(2, entry.EntryType); row.SetInt64(3, entry.SizeBytes); row.SetDateTime(4, entry.LastWriteTimeUtc); row.SetBoolean(5, entry.IsReparsePoint); SqlContext.Pipe.SendResultsRow(row); } }
            finally { SqlContext.Pipe.SendResultsEnd(); }
        }

        [SqlProcedure]
        public static void CreateDirectory(string rootAlias, string relativePath, string executionIdentity) { Root root = GetRoot(rootAlias, "AllowCreateDirectory"); string path = Resolve(root.RootPath, relativePath, true); RunAs(executionIdentity, delegate { AssertNoReparsePoint(root.RootPath, Path.GetDirectoryName(path)); Directory.CreateDirectory(path); }); SendAction(rootAlias, relativePath, "created"); }
        [SqlProcedure]
        public static void RemoveFile(string rootAlias, string relativePath, string executionIdentity) { Root root = GetRoot(rootAlias, "AllowDelete"); string path = Resolve(root.RootPath, relativePath, false); RunAs(executionIdentity, delegate { AssertNoReparsePoint(root.RootPath, path); if (!File.Exists(path)) Fail("FileNotFound"); File.Delete(path); }); SendAction(rootAlias, relativePath, "removed"); }
        [SqlProcedure]
        public static void RemoveDirectory(string rootAlias, string relativePath, bool recursive, int maxDepth, int maxEntries, string executionIdentity)
        {
            if (maxDepth < 0 || maxEntries < 1) Fail("InvalidListLimit"); Root root = GetRoot(rootAlias, "AllowDelete"); string path = Resolve(root.RootPath, relativePath, true); if (Same(root.RootPath, path)) Fail("RootDeletionForbidden");
            RunAs(executionIdentity, delegate { RemoveDirectoryBounded(root.RootPath, path, recursive, maxDepth, maxEntries); }); SendAction(rootAlias, relativePath, "removed");
        }

        // Vollständiger begrenzter Prüfplan vor der ersten Mutation. Ein Directory
        // jenseits der Traversierungstiefe wird abgewiesen, niemals unbesehen an
        // Directory.Delete(..., true) weitergereicht. Startdirectory hat Tiefe 0.
        private static void RemoveDirectoryBounded(string rootPath, string path, bool recursive, int maxDepth, int maxEntries)
        {
            AssertNoReparsePoint(rootPath, path);
            if (!Directory.Exists(path)) Fail("DirectoryNotFound");
            List<RemovalEntry> plan = new List<RemovalEntry>();
            Queue<PathDepth> queue = new Queue<PathDepth>();
            queue.Enqueue(new PathDepth { Path = path, Depth = 0 });
            while (queue.Count != 0)
            {
                PathDepth current = queue.Dequeue();
                AssertNoReparsePoint(rootPath, current.Path);
                foreach (string item in Directory.EnumerateFileSystemEntries(current.Path))
                {
                    // Vergleich vor Increment/Allokation vermeidet auch int-Overflow.
                    if (plan.Count >= maxEntries) Fail("EntryLimitExceeded");
                    FileAttributes attributes = File.GetAttributes(item);
                    if ((attributes & FileAttributes.ReparsePoint) != 0) Fail("ReparsePointForbidden");
                    bool isDirectory = (attributes & FileAttributes.Directory) != 0;
                    if (recursive && isDirectory)
                    {
                        if (current.Depth >= maxDepth) Fail("DepthLimitExceeded");
                        queue.Enqueue(new PathDepth { Path = item, Depth = current.Depth + 1 });
                    }
                    plan.Add(new RemovalEntry { Path = item, IsDirectory = isDirectory });
                }
            }
            if (!recursive && plan.Count != 0) Fail("DirectoryNotEmpty");

            // Umgekehrte BFS-Reihenfolge entfernt nur vorher geprüfte Nachfahren.
            // Frische Reparse-/Typprüfung begrenzt Änderungen am Plan. Neue Kinder
            // bleiben durch nichtrekursives Delete erhalten; bei I/O-/Racefehlern
            // können bereits entfernte geprüfte Einträge nicht rollbackt werden.
            for (int index = plan.Count - 1; index >= 0; index--)
            {
                RemovalEntry entry = plan[index];
                AssertNoReparsePoint(rootPath, entry.Path);
                FileAttributes attributes = File.GetAttributes(entry.Path);
                if ((attributes & FileAttributes.ReparsePoint) != 0) Fail("ReparsePointForbidden");
                if (((attributes & FileAttributes.Directory) != 0) != entry.IsDirectory) Fail("DirectoryTreeChanged");
                if (entry.IsDirectory) Directory.Delete(entry.Path, false);
                else File.Delete(entry.Path);
            }
            AssertNoReparsePoint(rootPath, path);
            Directory.Delete(path, false);
        }

        private static Root GetRoot(string alias, string requiredFlag) { if (String.IsNullOrWhiteSpace(alias)) Fail("RootAliasRequired"); using (SqlConnection connection = new SqlConnection("context connection=true")) using (SqlCommand command = connection.CreateCommand()) { command.CommandText = "SELECT RootPath, WorkPath FROM toolbelt_filesystem.FileSystemRoot WHERE RootAlias = @Alias AND IsActive = 1 AND " + requiredFlag + " = 1;"; command.Parameters.Add("@Alias", SqlDbType.NVarChar, 128).Value = alias; connection.Open(); using (SqlDataReader reader = command.ExecuteReader()) { if (!reader.Read()) Fail("RootNotAuthorized"); return new Root { RootPath = reader.GetString(0), WorkPath = reader.IsDBNull(1) ? null : reader.GetString(1) }; } } }
        // Requestbezogene Authentifizierung vor jedem Caller-Enter pruefen.
        // Contextzugriff und Dispose muessen vor Identity-Erfassung abgeschlossen sein.
        private static WindowsIdentity GetCallerIdentity()
        {
            object scheme;
            using (SqlConnection connection = new SqlConnection("context connection=true"))
            {
                connection.Open();
                using (SqlCommand command = connection.CreateCommand())
                {
                    command.CommandText = "SELECT CONVERT(nvarchar(40), CONNECTIONPROPERTY('auth_scheme'));";
                    scheme = command.ExecuteScalar();
                }
            }
            if (!IsWindowsAuthenticationScheme(scheme)) Fail("CallerWindowsAuthenticationRequired");
            WindowsIdentity identity = SqlContext.WindowsIdentity;
            if (identity == null) Fail("CallerWindowsAuthenticationRequired");
            return identity;
        }
        private static bool IsWindowsAuthenticationScheme(object scheme)
        {
            string value = scheme as string;
            return String.Equals(value, "NTLM", StringComparison.Ordinal)
                || String.Equals(value, "KERBEROS", StringComparison.Ordinal)
                || String.Equals(value, "DIGEST", StringComparison.Ordinal)
                || String.Equals(value, "BASIC", StringComparison.Ordinal)
                || String.Equals(value, "NEGOTIATE", StringComparison.Ordinal);
        }
        private static void RunAs(string mode, Action action) { if (String.Equals(mode, "ServiceAccount", StringComparison.Ordinal)) { action(); return; } if (!String.Equals(mode, "Caller", StringComparison.Ordinal)) Fail("InvalidExecutionIdentity"); WindowsIdentity identity = GetCallerIdentity(); WindowsImpersonationContext context = null; try { context = identity.Impersonate(); action(); } finally { if (context != null) context.Undo(); } }
        private static Encoding StrictEncoding(string name) { if (String.IsNullOrWhiteSpace(name)) Fail("EncodingRequired"); try { return Encoding.GetEncoding(name, EncoderFallback.ExceptionFallback, DecoderFallback.ExceptionFallback); } catch (ArgumentException) { Fail("UnsupportedEncoding"); return null; } }
        private static string Resolve(string rootPath, string relativePath, bool allowEmpty) { if (String.IsNullOrWhiteSpace(rootPath) || relativePath == null || (!allowEmpty && relativePath.Length == 0)) Fail("InvalidPath"); if (Path.IsPathRooted(relativePath) || relativePath.IndexOf(':') >= 0) Fail("AbsolutePathForbidden"); string root = Path.GetFullPath(rootPath).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar), candidate = Path.GetFullPath(Path.Combine(root, relativePath)); if (!candidate.StartsWith(root + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase) && !Same(root, candidate)) Fail("PathOutsideRoot"); return candidate; }
        private static void AssertNoReparsePoint(string rootPath, string candidate) { string root = Path.GetFullPath(rootPath).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar); string current = root; if (Directory.Exists(current) && (File.GetAttributes(current) & FileAttributes.ReparsePoint) != 0) Fail("ReparsePointForbidden"); foreach (string part in Relative(root, candidate).Split(new[] {'\\', '/'}, StringSplitOptions.RemoveEmptyEntries)) { current = Path.Combine(current, part); if ((Directory.Exists(current) || File.Exists(current)) && (File.GetAttributes(current) & FileAttributes.ReparsePoint) != 0) Fail("ReparsePointForbidden"); } }
        private static IEnumerable<string> Enumerate(string start, bool recursive, int maxDepth) { Queue<PathDepth> queue = new Queue<PathDepth>(); queue.Enqueue(new PathDepth { Path = start, Depth = 0 }); while (queue.Count != 0) { PathDepth current = queue.Dequeue(); foreach (string item in Directory.EnumerateFileSystemEntries(current.Path)) { yield return item; FileAttributes attributes = File.GetAttributes(item); if (recursive && (attributes & FileAttributes.Directory) != 0 && (attributes & FileAttributes.ReparsePoint) == 0 && current.Depth < maxDepth) queue.Enqueue(new PathDepth { Path = item, Depth = current.Depth + 1 }); } } }
        private static long CopyBinaryContent(SqlBytes content, FileStream output, Action<Action> filesystem)
        {
            byte[] buffer = new byte[BufferBytes]; long offset = 0, written = 0;
            while (offset < content.Length)
            {
                int expected = (int)Math.Min(buffer.Length, content.Length - offset);
                long read = content.Read(offset, buffer, 0, expected);
                if (read <= 0) Fail("SourceReadFailed");
                filesystem(delegate { output.Write(buffer, 0, (int)read); });
                offset += read; written += read;
            }
            return written;
        }
        private static long CopyTextContent(SqlChars content, Encoding encoding, bool writeBom, FileStream output, Action<Action> filesystem)
        {
            long written = 0;
            if (writeBom) { byte[] preamble = encoding.GetPreamble(); filesystem(delegate { output.Write(preamble, 0, preamble.Length); }); written += preamble.Length; }
            char[] characters = new char[32768]; long offset = 0;
            while (offset < content.Length)
            {
                int expected = (int)Math.Min(characters.Length, content.Length - offset);
                long read = content.Read(offset, characters, 0, expected);
                if (read <= 0) Fail("SourceReadFailed");
                byte[] encoded = encoding.GetBytes(characters, 0, (int)read);
                filesystem(delegate { output.Write(encoded, 0, encoded.Length); });
                offset += read; written += encoded.Length;
            }
            return written;
        }
        // Alte Helper-Signatur bleibt fuer Transcode und dessen Regression erhalten.
        private static void WriteAtomically(Root root, string target, bool overwrite, Action<FileStream> write)
        { WriteAtomicallyScoped(root, target, overwrite, write, delegate(Action action) { action(); }); }
        private static void WriteAtomicallyScoped(Root root, string target, bool overwrite, Action<FileStream> write, Action<Action> filesystem)
        {
            string stagingDirectory = String.IsNullOrWhiteSpace(root.WorkPath) ? Path.GetDirectoryName(target) : Resolve(root.RootPath, root.WorkPath, false);
            string staging = Path.Combine(stagingDirectory, ".tbx-" + Guid.NewGuid().ToString("N") + ".part");
            FileStream output = null; bool ownStage = false; ExceptionDispatchInfo failure = null;
            List<string> secondaryFailures = new List<string>(2);
            try
            {
                filesystem(delegate { AssertNoReparsePoint(root.RootPath, stagingDirectory); output = new FileStream(staging, FileMode.CreateNew, FileAccess.Write, FileShare.None); ownStage = true; });
                write(output);
                filesystem(delegate { output.Flush(true); });
            }
            catch (Exception exception) { failure = ExceptionDispatchInfo.Capture(exception); }
            finally
            {
                if (output != null)
                    try { filesystem(delegate { output.Dispose(); }); }
                    catch (Exception exception) { if (failure == null) failure = ExceptionDispatchInfo.Capture(exception); else secondaryFailures.Add("DISPOSE_FAILED"); }
            }
            try
            {
                // Nur nach erfolgreichem Schreiben, Flush und Dispose publizieren.
                if (failure == null) filesystem(delegate { if (!overwrite) File.Move(staging, target); else if (File.Exists(target)) File.Replace(staging, target, null, true); else File.Move(staging, target); });
            }
            catch (Exception exception) { if (failure == null) failure = ExceptionDispatchInfo.Capture(exception); }
            finally
            {
                if (ownStage)
                    try { filesystem(delegate { if (File.Exists(staging)) File.Delete(staging); }); }
                    catch (Exception exception) { if (failure == null) failure = ExceptionDispatchInfo.Capture(exception); else secondaryFailures.Add("CLEANUP_FAILED"); }
            }
            if (failure != null)
            {
                // Nur feste interne Codes; keine zweiten Exceptionmessages oder Pfade.
                if (secondaryFailures.Count != 0)
                    try { failure.SourceException.Data["Toolbelt.Filesystem.SecondaryFailures"] = secondaryFailures.ToArray(); }
                    catch { /* Ein Diagnosefehler darf den urspruenglichen Fehler nicht ersetzen. */ }
                failure.Throw();
            }
        }
        private sealed class FilesystemExecution
        {
            private readonly WindowsIdentity identity;
            private readonly bool serviceAccount;
            private bool restored = true;
            private ExceptionDispatchInfo identityFailure;
            public FilesystemExecution(string mode)
            {
                serviceAccount = String.Equals(mode, "ServiceAccount", StringComparison.Ordinal);
                if (serviceAccount) return;
                if (!String.Equals(mode, "Caller", StringComparison.Ordinal)) Fail("InvalidExecutionIdentity");
                identity = GetCallerIdentity();
            }
            public void Run(Action action)
            {
                // Nach ungewissem Undo niemals unter ServiceAccount weiterarbeiten.
                if (!restored) { identityFailure.Throw(); return; }
                if (serviceAccount) { action(); return; }
                WindowsImpersonationContext context = null; ExceptionDispatchInfo failure = null;
                try
                {
                    context = identity.Impersonate();
                    if (context == null) Fail("InvalidExecutionIdentity");
                    action();
                }
                catch (Exception exception)
                {
                    failure = ExceptionDispatchInfo.Capture(exception);
                    if (context == null) { restored = false; identityFailure = failure; }
                }
                finally
                {
                    if (context != null)
                        try { context.Undo(); }
                        catch (Exception exception) { restored = false; identityFailure = ExceptionDispatchInfo.Capture(exception); if (failure == null) failure = identityFailure; }
                }
                // Lokaler Catch beendet die erste Exception-Suche vor Undo;
                // fremde Exceptionfilter sehen erst den wiederhergestellten Kontext.
                if (failure != null) failure.Throw();
            }
        }
        private static SqlDataRecord Record(params object[] definition) { List<SqlMetaData> metadata = new List<SqlMetaData>(); for (int i = 0; i < definition.Length;) { string name = (string)definition[i++]; SqlDbType type = (SqlDbType)definition[i++]; long length = 0; if (i < definition.Length && (definition[i] is int || definition[i] is long)) length = Convert.ToInt64(definition[i++]); metadata.Add(length == 0 ? new SqlMetaData(name, type) : new SqlMetaData(name, type, length)); } return new SqlDataRecord(metadata.ToArray()); }
        private static void SendWrite(long bytes, string rootAlias, string relativePath) { SqlDataRecord row = Record("BytesWritten", SqlDbType.BigInt, "RootAlias", SqlDbType.NVarChar, 128, "RelativePath", SqlDbType.NVarChar, 4000, "State", SqlDbType.VarChar, 16); row.SetInt64(0, bytes); row.SetString(1, rootAlias); row.SetString(2, relativePath); row.SetString(3, "completed"); SqlContext.Pipe.Send(row); }
        private static void SendAction(string rootAlias, string relativePath, string state) { SqlDataRecord row = Record("RootAlias", SqlDbType.NVarChar, 128, "RelativePath", SqlDbType.NVarChar, 4000, "State", SqlDbType.VarChar, 16); row.SetString(0, rootAlias); row.SetString(1, relativePath); row.SetString(2, state); SqlContext.Pipe.Send(row); }
        private static string Relative(string root, string path) { return path.Substring(root.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar).Length).TrimStart(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar); }
        private static bool Same(string left, string right) { return String.Equals(Path.GetFullPath(left).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar), Path.GetFullPath(right).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar), StringComparison.OrdinalIgnoreCase); }
        private static void Fail(string code) { throw new InvalidOperationException("TBXFS:" + code); }
        private sealed class Root { public string RootPath; public string WorkPath; }
        private sealed class RemovalEntry { public string Path; public bool IsDirectory; }
        private sealed class ListedEntry { public long Ordinal; public string RelativePath; public string EntryType; public long SizeBytes; public DateTime LastWriteTimeUtc; public bool IsReparsePoint; }
        private sealed class PathDepth { public string Path; public int Depth; }
    }
}
