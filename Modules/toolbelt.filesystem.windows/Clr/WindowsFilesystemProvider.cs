using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.IO;
using System.Runtime.ExceptionServices;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
using System.Security.Principal;
using System.Security.AccessControl;
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
            WindowsIdentity callerIdentity = CaptureCallerIdentity(executionIdentity); Root root = GetRoot(rootAlias, "AllowRead", executionIdentity);
            string path = Resolve(root.RootPath, relativePath, false);
            byte[] value = null; long length = 0;
            RunAs(callerIdentity, delegate
            {
                using (NativeParents binding = new NativeParents(path, false, false))
                using (FileStream input = new FileStream(NativeOpen(path, 0x80000000, 3, false), FileAccess.Read))
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
            WindowsIdentity callerIdentity = CaptureCallerIdentity(executionIdentity); Encoding encoding = StrictEncoding(encodingName); Root root = GetRoot(rootAlias, "AllowRead", executionIdentity);
            string path = Resolve(root.RootPath, relativePath, false); byte[] bytes = null; long length = 0; int used = 0; string text = null;
            RunAs(callerIdentity, delegate
            {
                using (NativeParents binding = new NativeParents(path, false, false))
                using (FileStream input = new FileStream(NativeOpen(path, 0x80000000, 3, false), FileAccess.Read))
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
            if (content.IsNull) Fail("ContentRequired"); FilesystemExecution execution = new FilesystemExecution(executionIdentity); Root root = GetRoot(rootAlias, "AllowWrite", executionIdentity); string target = Resolve(root.RootPath, relativePath, false); long written = 0;
            // SQL-backed LOBs erst nach Undo lesen; jede Dateiaktion bleibt bei
            // derselben zuvor erfassten Identitaet. Kein ganzes LOB materialisieren.
            WriteAtomicallyScoped(root, target, overwrite, delegate(FileStream output)
            { written = CopyBinaryContent(content, output, execution.Run); }, execution.Run);
            SendWrite(written, rootAlias, relativePath);
        }

        [SqlProcedure]
        public static void WriteTextFile(string rootAlias, string relativePath, SqlChars content, string encodingName, bool writeBom, bool overwrite, string executionIdentity)
        {
            if (content.IsNull) Fail("ContentRequired"); FilesystemExecution execution = new FilesystemExecution(executionIdentity); Encoding encoding = StrictEncoding(encodingName); Root root = GetRoot(rootAlias, "AllowWrite", executionIdentity); string target = Resolve(root.RootPath, relativePath, false); long written = 0;
            WriteAtomicallyScoped(root, target, overwrite, delegate(FileStream output)
            { written = CopyTextContent(content, encoding, writeBom, output, execution.Run); }, execution.Run);
            SendWrite(written, rootAlias, relativePath);
        }

        [SqlProcedure]
        public static void TranscodeTextFile(string sourceRootAlias, string sourceRelativePath, string sourceEncoding, string targetRootAlias, string targetRelativePath, string targetEncoding, bool writeBom, bool overwrite, string executionIdentity)
        {
            WindowsIdentity callerIdentity = CaptureCallerIdentity(executionIdentity); Root source = GetRoot(sourceRootAlias, "AllowRead", executionIdentity), targetRoot = GetRoot(targetRootAlias, "AllowWrite", executionIdentity); Encoding input = StrictEncoding(sourceEncoding), output = StrictEncoding(targetEncoding);
            string sourcePath = Resolve(source.RootPath, sourceRelativePath, false), targetPath = Resolve(targetRoot.RootPath, targetRelativePath, false); long written = 0;
            RunAs(callerIdentity, delegate
            {
                WriteAtomically(targetRoot, targetPath, overwrite, delegate(FileStream destination)
                {
                    if (writeBom) { byte[] preamble = output.GetPreamble(); destination.Write(preamble, 0, preamble.Length); written += preamble.Length; }
                    using (NativeParents sourceBinding = new NativeParents(sourcePath, false, false))
                    using (StreamReader reader = new StreamReader(new FileStream(NativeOpen(sourcePath, 0x80000000, 3, false), FileAccess.Read), input, false, 32768, false))
                    { char[] characters = new char[32768]; int read; while ((read = reader.Read(characters, 0, characters.Length)) > 0) { byte[] encoded = output.GetBytes(characters, 0, read); destination.Write(encoded, 0, encoded.Length); written += encoded.Length; } }
                });
            });
            SendWrite(written, targetRootAlias, targetRelativePath);
        }

        [SqlProcedure]
        public static void ListDirectory(string rootAlias, string relativePath, bool recursive, int maxDepth, int maxEntries, string executionIdentity)
        {
            if (maxDepth < 0 || maxDepth > 64 || maxEntries < 1 || maxEntries > 10000) Fail("InvalidListLimit"); WindowsIdentity callerIdentity = CaptureCallerIdentity(executionIdentity); Root root = GetRoot(rootAlias, "AllowList", executionIdentity); string start = Resolve(root.RootPath, relativePath, true);
            List<ListedEntry> entries = new List<ListedEntry>();
            RunAs(callerIdentity, delegate
            {
                long ordinal = 0, pathBytes = 0;
                using (NativeParents rootBinding = new NativeParents(start, true, false))
                foreach (string item in Enumerate(start, recursive, maxDepth))
                {
                    if (ordinal >= maxEntries) Fail("EntryLimitExceeded");
                    string relative = Relative(root.RootPath, item);
                    long addition = (long)relative.Length * 2;
                    if (addition > 16 * 1024 * 1024 - pathBytes) Fail("PathTextLimitExceeded");
                    pathBytes += addition; ++ordinal;
                    FileAttributes attributes = File.GetAttributes(item);
                    bool isDirectory = (attributes & FileAttributes.Directory) != 0, isReparse = (attributes & FileAttributes.ReparsePoint) != 0;
                    entries.Add(new ListedEntry { Ordinal = ordinal, RelativePath = relative, EntryType = isDirectory ? "directory" : "file", SizeBytes = isDirectory ? 0 : new FileInfo(item).Length, LastWriteTimeUtc = isDirectory ? Directory.GetLastWriteTimeUtc(item) : File.GetLastWriteTimeUtc(item), IsReparsePoint = isReparse });
                }
            });
            SqlDataRecord row = Record("EntryOrdinal", SqlDbType.BigInt, "RelativePath", SqlDbType.NVarChar, 4000, "EntryType", SqlDbType.VarChar, 16, "SizeBytes", SqlDbType.BigInt, "LastWriteTimeUtc", SqlDbType.DateTime2, "IsReparsePoint", SqlDbType.Bit);
            SqlContext.Pipe.SendResultsStart(row);
            try { foreach (ListedEntry entry in entries) { row.SetInt64(0, entry.Ordinal); row.SetString(1, entry.RelativePath); row.SetString(2, entry.EntryType); row.SetInt64(3, entry.SizeBytes); row.SetDateTime(4, entry.LastWriteTimeUtc); row.SetBoolean(5, entry.IsReparsePoint); SqlContext.Pipe.SendResultsRow(row); } }
            finally { SqlContext.Pipe.SendResultsEnd(); }
        }

        [SqlProcedure]
        public static void CreateDirectory(string rootAlias, string relativePath, string executionIdentity) { WindowsIdentity callerIdentity = CaptureCallerIdentity(executionIdentity); Root root = GetRoot(rootAlias, "AllowCreateDirectory", executionIdentity); string path = Resolve(root.RootPath, relativePath, true); RunAs(callerIdentity, delegate { using (NativeParents binding = new NativeParents(path, true, true)) { } }); SendAction(rootAlias, relativePath, "created"); }
        [SqlProcedure]
        public static void RemoveFile(string rootAlias, string relativePath, string executionIdentity) { WindowsIdentity callerIdentity = CaptureCallerIdentity(executionIdentity); Root root = GetRoot(rootAlias, "AllowDelete", executionIdentity); string path = Resolve(root.RootPath, relativePath, false); RunAs(callerIdentity, delegate { using (NativeParents binding = new NativeParents(path, false, false)) using (SafeFileHandle file = NativeOpen(path, 0x10080, 3, false)) { NativeDelete(file); } }); SendAction(rootAlias, relativePath, "removed"); }
        [SqlProcedure]
        public static void RemoveDirectory(string rootAlias, string relativePath, bool recursive, int maxDepth, int maxEntries, string executionIdentity)
        {
            if (maxDepth < 0 || maxEntries < 1) Fail("InvalidListLimit"); WindowsIdentity callerIdentity = CaptureCallerIdentity(executionIdentity); Root root = GetRoot(rootAlias, "AllowDelete", executionIdentity); string path = Resolve(root.RootPath, relativePath, true); if (Same(root.RootPath, path)) Fail("RootDeletionForbidden");
            RunAs(callerIdentity, delegate { RemoveDirectoryBounded(root.RootPath, path, recursive, maxDepth, maxEntries); }); SendAction(rootAlias, relativePath, "removed");
        }

        // Vollständiger begrenzter Prüfplan vor der ersten Mutation. Ein Directory
        // jenseits der Traversierungstiefe wird abgewiesen, niemals unbesehen an
        // Directory.Delete(..., true) weitergereicht. Startdirectory hat Tiefe 0.
        private static void RemoveDirectoryBounded(string rootPath, string path, bool recursive, int maxDepth, int maxEntries)
        {
            using (NativeParents parents = new NativeParents(path, false, false))
            {
                List<NativeRemoval> plan = new List<NativeRemoval>();
                Queue<PathDepth> queue = new Queue<PathDepth>();
                SafeFileHandle start = NativeOpen(path, 0x10080, 3, true);
                try
                {
                    queue.Enqueue(new PathDepth { Path = path, Depth = 0 });
                    while (queue.Count != 0)
                    {
                        PathDepth current = queue.Dequeue();
                        foreach (string item in Directory.EnumerateFileSystemEntries(current.Path))
                        {
                            if (plan.Count >= maxEntries) Fail("EntryLimitExceeded");
                            SafeFileHandle handle = NativeOpen(item, 0x10080, 3, null);
                            bool retained = false;
                            try
                            {
                                bool directory = (NativeInfo(handle).Attributes & 0x10) != 0;
                                if (recursive && directory)
                                {
                                    if (current.Depth >= maxDepth) Fail("DepthLimitExceeded");
                                    queue.Enqueue(new PathDepth { Path = item, Depth = current.Depth + 1 });
                                }
                                plan.Add(new NativeRemoval { Handle = handle }); retained = true;
                            }
                            finally { if (!retained) handle.Dispose(); }
                        }
                    }
                    if (!recursive && plan.Count != 0) Fail("DirectoryNotEmpty");
                    // Exakte Preflighthandles ohne erneute Blattauflösung. Neue Kinder
                    // lassen nichtrekursive Löschung abbrechen; ihnen nie folgen.
                    for (int index = plan.Count - 1; index >= 0; index--)
                    { NativeDelete(plan[index].Handle); plan[index].Handle.Dispose(); }
                    NativeDelete(start);
                }
                finally { foreach (NativeRemoval entry in plan) entry.Handle.Dispose(); start.Dispose(); }
            }
        }

        private static Root GetRoot(string alias, string requiredFlag, string executionIdentity) { if (String.IsNullOrWhiteSpace(alias)) Fail("RootAliasRequired"); using (SqlConnection connection = new SqlConnection("context connection=true")) using (SqlCommand command = connection.CreateCommand()) { command.CommandText = "SELECT RootPath, WorkPath FROM toolbelt_filesystem.FileSystemRoot WHERE RootAlias = @Alias AND IsActive = 1 AND (@ServiceAccount = 0 OR AllowServiceAccount = 1) AND " + requiredFlag + " = 1;"; command.Parameters.Add("@Alias", SqlDbType.NVarChar, 128).Value = alias; command.Parameters.Add("@ServiceAccount", SqlDbType.Bit).Value = String.Equals(executionIdentity, "ServiceAccount", StringComparison.Ordinal); connection.Open(); using (SqlDataReader reader = command.ExecuteReader()) { if (!reader.Read()) Fail("RootNotAuthorized"); return new Root { RootPath = reader.GetString(0), WorkPath = reader.IsDBNull(1) ? null : reader.GetString(1) }; } } }
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
        private static WindowsIdentity CaptureCallerIdentity(string mode) { if (String.Equals(mode, "ServiceAccount", StringComparison.Ordinal)) {
            using (SqlConnection connection = new SqlConnection("context connection=true"))
            using (SqlCommand command = connection.CreateCommand()) {
                command.CommandText = "SELECT CASE WHEN EXISTS(SELECT 1 FROM sys.database_principals WHERE name=N'toolbelt_filesystem_service_account' AND type='R' AND owning_principal_id=1) AND IS_ROLEMEMBER(N'toolbelt_filesystem_service_account')=1 THEN 1 ELSE 0 END;";
                connection.Open(); object member = command.ExecuteScalar();
                if (member == null || member == DBNull.Value || Convert.ToInt32(member) != 1) Fail("ServiceAccountNotAuthorized");
            }
            return null;
        } if (!String.Equals(mode, "Caller", StringComparison.Ordinal)) Fail("InvalidExecutionIdentity"); return GetCallerIdentity(); }
        private static void RunAs(WindowsIdentity identity, Action action) { if (identity == null) { action(); return; } WindowsImpersonationContext context = null; try { context = identity.Impersonate(); action(); } finally { if (context != null) context.Undo(); } }
        private static Encoding StrictEncoding(string name) { if (String.IsNullOrWhiteSpace(name)) Fail("EncodingRequired"); try { return Encoding.GetEncoding(name, EncoderFallback.ExceptionFallback, DecoderFallback.ExceptionFallback); } catch (ArgumentException) { Fail("UnsupportedEncoding"); return null; } }
        private static string Resolve(string rootPath, string relativePath, bool allowEmpty) { if (String.IsNullOrWhiteSpace(rootPath) || relativePath == null || (!allowEmpty && relativePath.Length == 0)) Fail("InvalidPath"); if (Path.IsPathRooted(relativePath) || relativePath.IndexOf(':') >= 0) Fail("AbsolutePathForbidden"); string root = Path.GetFullPath(rootPath).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar), candidate = Path.GetFullPath(Path.Combine(root, relativePath)); if (!candidate.StartsWith(root + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase) && !Same(root, candidate)) Fail("PathOutsideRoot"); return candidate; }
        private static IEnumerable<string> Enumerate(string start, bool recursive, int maxDepth)
        {
            Queue<PathDepth> queue = new Queue<PathDepth>(); queue.Enqueue(new PathDepth { Path = start, Depth = 0 });
            while (queue.Count != 0)
            {
                PathDepth current = queue.Dequeue();
                using (NativeParents binding = new NativeParents(current.Path, true, false))
                foreach (string item in Directory.EnumerateFileSystemEntries(current.Path))
                {
                    using (SafeFileHandle handle = NativeOpen(item, 0x80, 3, null))
                    {
                        bool directory = (NativeInfo(handle).Attributes & 0x10) != 0;
                        if (recursive && directory)
                        {
                            if (current.Depth >= maxDepth) Fail("DepthLimitExceeded");
                            queue.Enqueue(new PathDepth { Path = item, Depth = current.Depth + 1 });
                        }
                        yield return item;
                    }
                }
            }
        }
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
            NativeParents targetBinding = null, stageBinding = null;
            FileStream output = null; bool published = false; ExceptionDispatchInfo failure = null;
            List<string> secondaryFailures = new List<string>(2);
            try
            {
                filesystem(delegate {
                    targetBinding = new NativeParents(target, false, false);
                    stageBinding = new NativeParents(staging, false, false);
                    uint access = 0x40010080U | (overwrite ? 0x40000U : 0U);
                    output = new FileStream(NativeOpen(staging, access, 1, false), FileAccess.Write);
                });
                write(output);
                filesystem(delegate { output.Flush(true); });
                // Stage bleibt bis zur Publikation gegen Rename/Austausch gebunden.
                filesystem(delegate { NativePublish(output, target, overwrite); published = true; });
            }
            catch (Exception exception) { failure = ExceptionDispatchInfo.Capture(exception); }
            finally
            {
                if (output != null)
                {
                    if (!published)
                        try { filesystem(delegate { NativeDelete(output.SafeFileHandle); }); }
                        catch (Exception exception) { if (failure == null) failure = ExceptionDispatchInfo.Capture(exception); else secondaryFailures.Add("CLEANUP_FAILED"); }
                    try { filesystem(delegate { output.Dispose(); }); }
                    catch (Exception exception) { if (failure == null) failure = ExceptionDispatchInfo.Capture(exception); else secondaryFailures.Add("DISPOSE_FAILED"); }
                }
                // Freigabe ausschließlich über Handles, ohne weitere Pfadoperation.
                if (stageBinding != null) stageBinding.Dispose();
                if (targetBinding != null) targetBinding.Dispose();
            }
            if (failure != null)
            {
                if (secondaryFailures.Count != 0)
                    try { failure.SourceException.Data["Toolbelt.Filesystem.SecondaryFailures"] = secondaryFailures.ToArray(); } catch { }
                failure.Throw();
            }
        }

        // SC-023: gekapselter nativer Provider ohne Pfadfallback bei ungeeigneter
        // Plattform, Reparse Points oder Sharingfehlern. Rootauswahl erfolgt zuvor.
        [StructLayout(LayoutKind.Sequential)]
        private struct NativeFileInfo
        {
            public uint Attributes, CreationLow, CreationHigh, AccessLow, AccessHigh,
                WriteLow, WriteHigh, Volume, SizeHigh, SizeLow, Links, IndexHigh, IndexLow;
        }
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern SafeFileHandle CreateFileW(string path, uint access, uint share, IntPtr security, uint creation, uint flags, IntPtr template);
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool CreateDirectoryW(string path, IntPtr security);
        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern uint GetFileType(SafeFileHandle file);
        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool GetFileInformationByHandle(SafeFileHandle file, out NativeFileInfo info);
        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool SetFileInformationByHandle(SafeFileHandle file, int kind, IntPtr information, uint length);
        private static NativeFileInfo NativeInfo(SafeFileHandle handle)
        {
            NativeFileInfo info;
            if (!GetFileInformationByHandle(handle, out info)) Fail("HandleInformationFailed");
            return info;
        }
        private static SafeFileHandle NativeOpen(string path, uint access, uint creation, bool? directory)
        {
            if (Environment.OSVersion.Platform != PlatformID.Win32NT || Path.GetPathRoot(path).Length != 3) Fail("NativeFilesystemUnsupported");
            SafeFileHandle handle = CreateFileW(path, access, 1, IntPtr.Zero, creation, 0x02200000, IntPtr.Zero);
            if (handle.IsInvalid) { handle.Dispose(); throw new IOException("TBXFS:HandleOpenFailed"); }
            try
            {
                if (GetFileType(handle) != 1) Fail("NativeFilesystemUnsupported");
                NativeFileInfo info = NativeInfo(handle);
                if ((info.Attributes & 0x400) != 0) Fail("ReparsePointForbidden");
                bool isDirectory = (info.Attributes & 0x10) != 0;
                if (directory.HasValue && directory.Value != isDirectory) Fail("HandleTypeMismatch");
                if (!isDirectory && info.Links != 1) Fail("HardLinkForbidden");
                return handle;
            }
            catch { handle.Dispose(); throw; }
        }
        private static void NativeDelete(SafeFileHandle handle)
        {
            IntPtr data = Marshal.AllocHGlobal(1);
            try { Marshal.WriteByte(data, 1); if (!SetFileInformationByHandle(handle, 4, data, 1)) throw new IOException("TBXFS:HandleDeleteFailed"); }
            finally { Marshal.FreeHGlobal(data); }
        }
        private static void NativePublish(FileStream output, string target, bool overwrite)
        {
            SafeFileHandle handle = output.SafeFileHandle;
            if (overwrite)
            {
                // Zugriffspolicy eines vorhandenen Ziels über den exakten Handle
                // übernehmen; bei Fehlern vor der Publikation abbrechen.
                SafeFileHandle existing = CreateFileW(target, 0x80020080, 5, IntPtr.Zero, 3, 0x02200000, IntPtr.Zero);
                if (existing.IsInvalid)
                {
                    int error = Marshal.GetLastWin32Error(); existing.Dispose();
                    if (error != 2) throw new IOException("TBXFS:TargetSecurityOpenFailed");
                }
                else using (existing)
                {
                    NativeFileInfo info = NativeInfo(existing);
                    if ((info.Attributes & 0x410) != 0 || info.Links != 1) Fail("TargetSecurityTypeForbidden");
                    using (FileStream old = new FileStream(existing, FileAccess.Read))
                    {
                        FileSecurity policy = new FileSecurity();
                        policy.SetSecurityDescriptorBinaryForm(old.GetAccessControl().GetSecurityDescriptorBinaryForm(),AccessControlSections.Access);
                        output.SetAccessControl(policy);
                    }
                }
            }
            byte[] name = Encoding.Unicode.GetBytes(target);
            int pointerOffset = IntPtr.Size == 8 ? 8 : 4;
            int lengthOffset = pointerOffset + IntPtr.Size, nameOffset = lengthOffset + 4;
            int size = checked(nameOffset + name.Length + 2); IntPtr data = Marshal.AllocHGlobal(size);
            try
            {
                for (int i = 0; i < size; i++) Marshal.WriteByte(data, i, 0);
                Marshal.WriteByte(data, overwrite ? (byte)1 : (byte)0);
                Marshal.WriteIntPtr(data, pointerOffset, IntPtr.Zero); Marshal.WriteInt32(data, lengthOffset, name.Length);
                Marshal.Copy(name, 0, IntPtr.Add(data, nameOffset), name.Length);
                if (!SetFileInformationByHandle(handle, 3, data, (uint)size)) throw new IOException("TBXFS:HandlePublishFailed");
            }
            finally { Marshal.FreeHGlobal(data); }
        }
        private sealed class NativeParents : IDisposable
        {
            private readonly List<SafeFileHandle> handles = new List<SafeFileHandle>();
            public NativeParents(string path, bool includeLeaf, bool create)
            {
                try
                {
                    string full = Path.GetFullPath(includeLeaf ? path : Path.GetDirectoryName(path));
                    string anchor = Path.GetPathRoot(full);
                    if (anchor.Length != 3 || anchor[1] != ':') Fail("NativeFilesystemUnsupported");
                    string current = anchor;
                    handles.Add(NativeOpen(current, 0x80, 3, true));
                    foreach (string part in full.Substring(anchor.Length).Split(new[] { '\\' }, StringSplitOptions.RemoveEmptyEntries))
                    {
                        if (part.EndsWith(".", StringComparison.Ordinal) || part.EndsWith(" ", StringComparison.Ordinal) || part.IndexOf(':') >= 0) Fail("InvalidPathComponent");
                        current = Path.Combine(current, part);
                        if (create && !CreateDirectoryW(current, IntPtr.Zero) && Marshal.GetLastWin32Error() != 183) throw new IOException("TBXFS:DirectoryCreateFailed");
                        handles.Add(NativeOpen(current, 0x80, 3, true));
                    }
                }
                catch { Dispose(); throw; }
            }
            public void Dispose() { for (int i = handles.Count - 1; i >= 0; i--) handles[i].Dispose(); handles.Clear(); }
        }
        private sealed class NativeRemoval { public SafeFileHandle Handle; }
        private sealed class FilesystemExecution
        {
            private readonly WindowsIdentity identity;
            private readonly bool serviceAccount;
            private bool restored = true;
            private ExceptionDispatchInfo identityFailure;
            public FilesystemExecution(string mode)
            {
                serviceAccount = String.Equals(mode, "ServiceAccount", StringComparison.Ordinal);
                if (serviceAccount) { CaptureCallerIdentity(mode); return; }
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
        private sealed class ListedEntry { public long Ordinal; public string RelativePath; public string EntryType; public long SizeBytes; public DateTime LastWriteTimeUtc; public bool IsReparsePoint; }
        private sealed class PathDepth { public string Path; public int Depth; }
    }
}
