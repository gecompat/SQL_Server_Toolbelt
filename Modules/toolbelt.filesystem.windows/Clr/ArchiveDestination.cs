using System;
using System.Collections.Generic;
using System.IO;
using System.Security.AccessControl;
using System.Security.Principal;
using Microsoft.Win32.SafeHandles;
using Toolbelt.Archive.ZipMemory;

namespace Toolbelt.Filesystem.Windows
{
    public static partial class WindowsFilesystemProvider
    {
        private sealed class ArchiveDestination : ZipEntryProvider.IExtractionDestination, IDisposable
        {
            private const string LockName = ".tlblt-zip-extract.lock";
            private const uint ReadFilePolicy = 0x00120080;
            private readonly Action<Action> filesystem;
            private readonly bool createDirectories, overwrite, exclusiveRoot;
            private readonly string relativeTarget, workPath;
            private readonly ArchiveDirectoryChain anchor = new ArchiveDirectoryChain();
            private readonly Dictionary<string, NativeFileInfo> replacements =
                new Dictionary<string, NativeFileInfo>(StringComparer.Ordinal);
            private SecurityIdentifier identity;
            private byte[] privatePolicy;
            private SafeFileHandle guard;

            public ArchiveDestination(string root, string target, string work, bool createDirectories,
                bool overwrite, bool exclusiveRoot, Action<Action> filesystem)
            {
                this.filesystem = filesystem;
                this.createDirectories = createDirectories;
                this.overwrite = overwrite;
                this.exclusiveRoot = exclusiveRoot;
                if (overwrite && !exclusiveRoot) throw new IOException("OVERWRITE_EXCLUSIVITY_REQUIRED");
                relativeTarget = ValidateArchiveDirectory(target ?? String.Empty);
                workPath = String.IsNullOrWhiteSpace(work) ? null : ValidateArchiveDirectory(work);
                try
                {
                    filesystem(() =>
                    {
                        using (var current = WindowsIdentity.GetCurrent()) identity = current.User;
                        if (identity == null) throw new IOException("FILESYSTEM_IDENTITY_REQUIRED");
                        privatePolicy = ArchivePrivatePolicy(identity);
                        if (root == null || root.Length < 3 || root[1] != ':' || root[2] != '\\')
                            throw new IOException("INVALID_ROOT_PATH");
                        string full = Path.GetFullPath(root);
                        string drive = Path.GetPathRoot(full);
                        anchor.Add(OpenArchiveDrive(drive));
                        string[] components = full.Substring(drive.Length).TrimEnd('\\').Split('\\');
                        if (components[0].Length == 0) throw new IOException("VOLUME_ROOT_FORBIDDEN");
                        for (int i = 0; i < components.Length; i++)
                        {
                            var next = OpenArchiveChild(anchor.Last, components[i], ArchiveTraverse |
                                (overwrite && i == components.Length - 1 ? ArchiveReadPolicy : 0),
                                ArchiveShareReadWrite, false, true);
                            if (next == null) throw new IOException("ROOT_NOT_FOUND");
                            anchor.Add(next);
                        }
                        CheckDirectory(anchor.Last);
                        if (workPath != null)
                            using (ArchiveDirectoryChain workChain = Walk(workPath, false))
                                if (workChain == null) throw new IOException("WORK_DIRECTORY_NOT_FOUND");
                    });
                }
                catch { Dispose(); throw; }
            }

            public string Inspect(string path, bool directory)
            {
                return EntryOperation(() =>
                {
                    string full = Target(path);
                    using (ArchiveDirectoryChain parent = Walk(Parent(full), false))
                    {
                        if (parent == null) return createDirectories ? null : "DIRECTORY_CREATION_NOT_ALLOWED";
                        using (var entry = OpenArchiveChild(parent.Last, Leaf(full), directory ?
                            ArchiveTraverse | (overwrite ? ArchiveReadPolicy : 0) : ReadFilePolicy,
                            ArchiveShareReadWrite, false, directory))
                        {
                            if (entry == null) return !directory || createDirectories ? null : "DIRECTORY_CREATION_NOT_ALLOWED";
                            if (directory) CheckDirectory(entry);
                            else if (!overwrite) return "TARGET_EXISTS";
                            else
                            {
                                RequireArchiveExclusivePolicy(entry, identity);
                                replacements.Add(path, NativeInfo(entry));
                            }
                        }
                        return null;
                    }
                });
            }

            public string Publish(string path, bool directory, Action<Action<byte[], int>> copy, out bool published)
            {
                bool committed = false;
                string error;
                if (directory)
                    error = EntryOperation(() =>
                    {
                        // A zero-length entry is still a payload with a CRC.
                        copy((buffer, count) => { });
                        EnsureGuard();
                        using (var target = Walk(Target(path), true)) committed = true;
                        return null;
                    }, false);
                else
                    error = PublishFile(path, copy, ref committed);
                published = committed;
                return error;
            }

            private string PublishFile(string path, Action<Action<byte[], int>> copy, ref bool committed)
            {
                string full = Target(path);
                ArchiveDirectoryChain parent = null, work = null;
                SafeFileHandle handle = null;
                FileStream output = null;
                bool published = false;
                string cleanup = null;
                string error;
                try
                {
                    error = EntryOperation(() =>
                    {
                        EnsureGuard();
                        filesystem(() =>
                        {
                            parent = Walk(Parent(full), true);
                            if (workPath != null) work = Walk(workPath, false);
                            if (workPath != null && work == null) throw new IOException("WORK_DIRECTORY_NOT_FOUND");
                            handle = OpenArchiveChild(work == null ? parent.Last : work.Last,
                                ".tlblt-" + Guid.NewGuid().ToString("N") + ".part",
                                0x40130080 | (overwrite ? 0x00040000U : 0), 0, true, false, policy: privatePolicy);
                            output = new FileStream(handle, FileAccess.Write);
                        });
                        copy((buffer, count) => filesystem(() => output.Write(buffer, 0, count)));
                        filesystem(() =>
                        {
                            RecheckRename(path, full, parent.Last, output);
                            output.Flush(true);
                            PublishArchiveStage(handle, parent.Last, Leaf(full), replacements.ContainsKey(path));
                            published = true;
                        });
                        return null;
                    }, false);
                }
                finally
                {
                    try
                    {
                        if (handle != null)
                        {
                            if (output != null)
                            {
                                // Discard pending writes on failure by marking
                                // the owned stage before stream disposal.
                                if (!published)
                                    cleanup = EntryOperation(() => { NativeDelete(handle); return null; });
                                string disposed = EntryOperation(() => { output.Dispose(); return null; });
                                if (disposed != null) cleanup = disposed;
                            }
                            else if (!published)
                            {
                                cleanup = EntryOperation(() => { NativeDelete(handle); return null; });
                            }
                        }
                    }
                    finally
                    {
                        if (handle != null) handle.Dispose();
                        if (work != null) work.Dispose();
                        if (parent != null) parent.Dispose();
                    }
                }
                committed = published;
                if (cleanup != null) return "STAGE_CLEANUP_FAILED";
                return error;
            }

            private void RecheckRename(string path, string full, SafeFileHandle parent, FileStream stage)
            {
                CheckDirectory(parent);
                var stageHandle = stage.SafeFileHandle;
                var stagedInfo = NativeInfo(stageHandle);
                if ((stagedInfo.Attributes & 0x410) != 0 || stagedInfo.Links != 1)
                    throw new IOException("UNSAFE_STAGE");
                var staged = RequireArchiveExclusivePolicy(stageHandle, identity);
                if (!staged.Owner.Equals(identity) ||
                    (staged.ControlFlags & ControlFlags.DiscretionaryAclProtected) == 0)
                    throw new IOException("UNSAFE_STAGE");
                NativeFileInfo expected;
                if (!replacements.TryGetValue(path, out expected)) return;
                using (var target = OpenArchiveChild(parent, Leaf(full), ReadFilePolicy, ArchiveShareReadWrite, false, false))
                {
                    if (target == null) throw new IOException("TARGET_CHANGED");
                    var actual = NativeInfo(target);
                    if (expected.Volume != actual.Volume || expected.IndexLow != actual.IndexLow ||
                        expected.IndexHigh != actual.IndexHigh) throw new IOException("TARGET_CHANGED");
                    var prior = RequireArchiveExclusivePolicy(target, identity);
                    if (!prior.Owner.Equals(staged.Owner)) throw new IOException("OVERWRITE_OWNER_MISMATCH");
                    var descriptor = new byte[prior.BinaryLength];
                    prior.GetBinaryForm(descriptor, 0);
                    var policy = new FileSecurity();
                    policy.SetSecurityDescriptorBinaryForm(descriptor, AccessControlSections.Access);
                    stage.SetAccessControl(policy);
                    var updated = RequireArchiveExclusivePolicy(stageHandle, identity);
                    var expectedDacl = new byte[prior.DiscretionaryAcl.BinaryLength];
                    var actualDacl = new byte[updated.DiscretionaryAcl.BinaryLength];
                    prior.DiscretionaryAcl.GetBinaryForm(expectedDacl, 0);
                    updated.DiscretionaryAcl.GetBinaryForm(actualDacl, 0);
                    if (!prior.Owner.Equals(updated.Owner) ||
                        ((prior.ControlFlags ^ updated.ControlFlags) & ControlFlags.DiscretionaryAclProtected) != 0 ||
                        !System.Linq.Enumerable.SequenceEqual(expectedDacl, actualDacl))
                        throw new IOException("OVERWRITE_DACL_MISMATCH");
                }
            }

            private void EnsureGuard()
            {
                if (!exclusiveRoot || guard != null) return;
                filesystem(() =>
                {
                    CheckDirectory(anchor.Last);
                    guard = OpenArchiveChild(anchor.Last, LockName, 0x00110080, 0, true, false, true, privatePolicy);
                });
            }

            private ArchiveDirectoryChain Walk(string path, bool create)
            {
                var chain = new ArchiveDirectoryChain(anchor.Last);
                try
                {
                    CheckDirectory(chain.Last);
                    if (path.Length != 0)
                        foreach (string part in path.Split('\\'))
                        {
                            uint access = ArchiveTraverse | (overwrite ? ArchiveReadPolicy : 0);
                            var next = OpenArchiveChild(chain.Last, part, access, ArchiveShareReadWrite, false, true);
                            if (next == null)
                            {
                                if (!create) { chain.Dispose(); return null; }
                                if (!createDirectories) throw new IOException("DIRECTORY_CREATION_NOT_ALLOWED");
                                next = OpenArchiveChild(chain.Last, part, access, ArchiveShareReadWrite, true, true);
                            }
                            chain.Add(next);
                            CheckDirectory(next);
                        }
                    return chain;
                }
                catch { chain.Dispose(); throw; }
            }

            private void CheckDirectory(SafeFileHandle handle)
            {
                if ((NativeInfo(handle).Attributes & 0x410) != 0x10) throw new IOException("UNSAFE_TARGET");
                if (overwrite) RequireArchiveExclusivePolicy(handle, identity);
            }

            private string Target(string path)
            {
                ValidateArchiveDirectory(path);
                return relativeTarget.Length == 0 ? path : relativeTarget + "\\" + path;
            }

            private static string ValidateArchiveDirectory(string path)
            {
                string normal = path.Replace('/', '\\');
                if (normal.Length != 0)
                    foreach (string part in normal.Split('\\'))
                        if (!ZipEntryProvider.IsWindowsPathComponent(part) ||
                            String.Equals(part, LockName, StringComparison.OrdinalIgnoreCase))
                            throw new IOException("UNSAFE_PATH");
                return normal;
            }

            private static string Parent(string path)
            {
                int separator = path.LastIndexOf('\\');
                return separator < 0 ? String.Empty : path.Substring(0, separator);
            }

            private static string Leaf(string path) { return path.Substring(path.LastIndexOf('\\') + 1); }

            // Unexpected CLR/impersonation failures must propagate. Once
            // restoration is uncertain the caller cannot safely emit SQL rows.
            private string EntryOperation(Func<string> action, bool impersonate = true)
            {
                try
                {
                    string result = null;
                    if (impersonate) filesystem(() => result = action());
                    else result = action();
                    return result;
                }
                catch (InvalidDataException error) { return ArchiveErrorCode(error.Message, "INVALID_ENTRY_PAYLOAD"); }
                catch (IOException error) { return ArchiveErrorCode(error.Message, "FILESYSTEM_IO_FAILED"); }
                catch (UnauthorizedAccessException) { return "FILESYSTEM_ACCESS_DENIED"; }
            }

            private static string ArchiveErrorCode(string value, string fallback)
            {
                if (value.Length == 0 || value.Length > 64) return fallback;
                foreach (char ch in value)
                    if (ch != '_' && (ch < 'A' || ch > 'Z')) return fallback;
                return value;
            }

            public void Dispose()
            {
                if (guard != null) guard.Dispose();
                anchor.Dispose();
            }
        }

        private sealed class ArchiveDirectoryChain : IDisposable
        {
            private readonly List<SafeFileHandle> handles = new List<SafeFileHandle>();
            private readonly SafeFileHandle parent;
            public ArchiveDirectoryChain(SafeFileHandle parent = null) { this.parent = parent; }
            public SafeFileHandle Last { get { return handles.Count == 0 ? parent : handles[handles.Count - 1]; } }
            public void Add(SafeFileHandle handle) { handles.Add(handle); }
            public void Dispose()
            {
                for (int i = handles.Count - 1; i >= 0; i--) handles[i].Dispose();
                handles.Clear();
            }
        }
    }
}
