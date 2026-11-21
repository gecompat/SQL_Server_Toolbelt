using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;
using System.Text;
using Microsoft.Win32.SafeHandles;

namespace Toolbelt.Filesystem.Windows
{
    public static partial class WindowsFilesystemProvider
    {
        private const uint ArchiveTraverse = 0x001000a0; // Synchronize, traverse, read attributes.
        private const uint ArchiveReadPolicy = 0x00020000;
        private const uint ArchiveOpen = 1;
        private const uint ArchiveCreate = 2;
        private const uint ArchiveShareReadWrite = 3;
        private const uint ArchiveSynchronous = 0x20;
        private const uint ArchiveOpenReparsePoint = 0x00200000;
        private const uint ArchiveDirectoryFile = 1;
        private const uint ArchiveNonDirectoryFile = 0x40;
        private const int ArchiveNameNotFound = unchecked((int)0xc0000034);
        private const int ArchiveNameCollision = unchecked((int)0xc0000035);

        // Entries below a bound drive use a single checked component. In
        // particular, no directory supplied by an entry is opened by full path.
        [StructLayout(LayoutKind.Sequential)]
        private struct ArchiveUnicodeString { public ushort Length, Capacity; public IntPtr Buffer; }
        [StructLayout(LayoutKind.Sequential)]
        private struct ArchiveObjectAttributes
        {
            public int Length;
            public IntPtr Root, Name;
            public uint Flags;
            public IntPtr Security, Qos;
        }
        [StructLayout(LayoutKind.Sequential)]
        private struct ArchiveIoStatus { public IntPtr Status, Information; }

        [DllImport("ntdll.dll")]
        private static extern int NtCreateFile(out SafeFileHandle file, uint access,
            ref ArchiveObjectAttributes attributes, out ArchiveIoStatus status, IntPtr allocation,
            uint fileAttributes, uint share, uint disposition, uint options, IntPtr ea, uint eaLength);
        [DllImport("ntdll.dll")]
        private static extern int NtSetInformationFile(SafeFileHandle file, out ArchiveIoStatus status,
            IntPtr data, uint length, uint kind);
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool GetVolumeInformationByHandleW(SafeFileHandle handle, IntPtr name, uint nameSize,
            out uint serial, out uint maximumComponentLength, out uint flags, StringBuilder fileSystem, uint fileSystemSize);
        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool GetFileInformationByHandleEx(SafeFileHandle file, int kind, IntPtr buffer, uint length);
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
        private static extern uint GetDriveTypeW(string root);
        [DllImport("advapi32.dll")]
        private static extern uint GetSecurityInfo(SafeFileHandle handle, uint objectType,
            uint securityInformation, IntPtr owner, IntPtr group, IntPtr dacl, IntPtr sacl, out IntPtr descriptor);
        [DllImport("advapi32.dll")]
        private static extern uint GetSecurityDescriptorLength(IntPtr descriptor);
        [DllImport("kernel32.dll")]
        private static extern IntPtr LocalFree(IntPtr allocation);

        private static SafeFileHandle OpenArchiveDrive(string drive)
        {
            if (Environment.OSVersion.Platform != PlatformID.Win32NT || drive.Length != 3 || drive[1] != ':' ||
                drive[2] != '\\' || GetDriveTypeW(drive) != 3)
                throw new IOException("UNSUPPORTED_VOLUME");
            var handle = NativeOpen(drive, ArchiveTraverse, 3, true, ArchiveShareReadWrite);
            try
            {
                uint serial, maximumComponentLength, flags;
                var name = new StringBuilder(32);
                if (!GetVolumeInformationByHandleW(handle, IntPtr.Zero, 0, out serial,
                        out maximumComponentLength, out flags, name, (uint)name.Capacity) ||
                    !String.Equals(name.ToString(), "NTFS", StringComparison.Ordinal))
                    throw new IOException("UNSUPPORTED_VOLUME");
                return handle;
            }
            catch { handle.Dispose(); throw; }
        }

        private static SafeFileHandle OpenArchiveChild(SafeFileHandle parent, string leaf, uint access,
            uint share, bool create, bool? directory, bool deleteOnClose = false, byte[] policy = null)
        {
            if (leaf.Length == 0 || leaf.Length > 255 || leaf == "." || leaf == ".." ||
                leaf.IndexOfAny(new[] { '/', '\\', ':', '\0' }) >= 0)
                throw new IOException("UNSAFE_PATH");
            IntPtr chars = Marshal.StringToHGlobalUni(leaf);
            IntPtr name = IntPtr.Zero;
            GCHandle policyHandle = default(GCHandle);
            try
            {
                name = Marshal.AllocHGlobal(Marshal.SizeOf(typeof(ArchiveUnicodeString)));
                ushort length = checked((ushort)(leaf.Length * 2));
                Marshal.StructureToPtr(new ArchiveUnicodeString
                { Length = length, Capacity = length, Buffer = chars }, name, false);
                var attributes = new ArchiveObjectAttributes
                {
                    Length = Marshal.SizeOf(typeof(ArchiveObjectAttributes)),
                    Root = parent.DangerousGetHandle(), Name = name, Flags = 0x1040
                };
                if (policy != null)
                {
                    policyHandle = GCHandle.Alloc(policy, GCHandleType.Pinned);
                    attributes.Security = policyHandle.AddrOfPinnedObject();
                }
                uint options = ArchiveSynchronous | ArchiveOpenReparsePoint;
                // Do not follow a reparse point even if a rival creates its
                // name between the absent check and the exclusive create.
                if (create) options |= directory.Value ? ArchiveDirectoryFile : ArchiveNonDirectoryFile;
                if (deleteOnClose) options |= 0x1000;
                SafeFileHandle handle;
                ArchiveIoStatus status;
                int result = NtCreateFile(out handle, access, ref attributes, out status, IntPtr.Zero,
                    0x80, share, create ? ArchiveCreate : ArchiveOpen, options, IntPtr.Zero, 0);
                if (result != 0)
                {
                    if (handle != null) handle.Dispose();
                    if (!create && result == ArchiveNameNotFound) return null;
                    throw new IOException(result == ArchiveNameCollision ? "TARGET_EXISTS" : "TARGET_OPEN_FAILED");
                }
                try
                {
                    var info = NativeInfo(handle);
                    if (GetFileType(handle) != 1 || (info.Attributes & 0x400) != 0 ||
                        info.Volume != NativeInfo(parent).Volume)
                        throw new IOException("UNSAFE_TARGET");
                    bool isDirectory = (info.Attributes & 0x10) != 0;
                    if (directory.HasValue && directory.Value != isDirectory)
                        throw new IOException("TARGET_TYPE_CONFLICT");
                    if (!isDirectory && info.Links != 1)
                        throw new IOException("HARDLINK_FORBIDDEN");
                    if (!create && !ArchiveHandleNameMatches(handle, leaf))
                        throw new IOException("TARGET_ALIAS_FORBIDDEN");
                    return handle;
                }
                catch { handle.Dispose(); throw; }
            }
            finally
            {
                if (policyHandle.IsAllocated) policyHandle.Free();
                if (name != IntPtr.Zero) Marshal.FreeHGlobal(name);
                Marshal.FreeHGlobal(chars);
            }
        }

        private static byte[] ArchivePrivatePolicy(SecurityIdentifier owner)
        {
            var acl = new RawAcl(GenericAcl.AclRevision, 1);
            acl.InsertAce(0, new CommonAce(AceFlags.None, AceQualifier.AccessAllowed,
                (int)FileSystemRights.FullControl, owner, false, null));
            var descriptor = new RawSecurityDescriptor(ControlFlags.DiscretionaryAclPresent |
                ControlFlags.DiscretionaryAclProtected, owner, null, null, acl);
            var bytes = new byte[descriptor.BinaryLength];
            descriptor.GetBinaryForm(bytes, 0);
            return bytes;
        }

        private static bool ArchiveHandleNameMatches(SafeFileHandle handle, string leaf)
        {
            const int size = 65540;
            IntPtr data = Marshal.AllocHGlobal(size);
            try
            {
                if (!GetFileInformationByHandleEx(handle, 2, data, size)) return false;
                int bytes = Marshal.ReadInt32(data);
                if (bytes < 2 || bytes > size - 4 || (bytes & 1) != 0) return false;
                int chars = bytes / 2;
                int remaining = leaf.Length;
                if (chars <= remaining || Marshal.ReadInt16(data, 4 + (chars - remaining - 1) * 2) != '\\')
                    return false;
                string actual = Marshal.PtrToStringUni(IntPtr.Add(data, 4 + (chars - remaining) * 2), remaining);
                return String.Equals(actual, leaf, StringComparison.OrdinalIgnoreCase);
            }
            finally { Marshal.FreeHGlobal(data); }
        }

        private static void PublishArchiveStage(SafeFileHandle stage, SafeFileHandle parent, string leaf, bool replace)
        {
            int pointerOffset = IntPtr.Size == 8 ? 8 : 4;
            int lengthOffset = pointerOffset + IntPtr.Size;
            byte[] name = Encoding.Unicode.GetBytes(leaf);
            int size = lengthOffset + 4 + name.Length;
            IntPtr data = Marshal.AllocHGlobal(size);
            try
            {
                Marshal.Copy(new byte[size], 0, data, size);
                Marshal.WriteByte(data, replace ? (byte)1 : (byte)0);
                Marshal.WriteIntPtr(data, pointerOffset, parent.DangerousGetHandle());
                Marshal.WriteInt32(data, lengthOffset, name.Length);
                Marshal.Copy(name, 0, IntPtr.Add(data, lengthOffset + 4), name.Length);
                ArchiveIoStatus status;
                int result = NtSetInformationFile(stage, out status, data, (uint)size, 10);
                if (result != 0)
                    throw new IOException(result == ArchiveNameCollision ? "TARGET_EXISTS" : "PUBLISH_FAILED");
            }
            finally { Marshal.FreeHGlobal(data); }
        }

        private static RawSecurityDescriptor ReadArchivePolicy(SafeFileHandle handle)
        {
            IntPtr descriptor = IntPtr.Zero;
            try
            {
                if (GetSecurityInfo(handle, 1, 5, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, out descriptor) != 0 ||
                    descriptor == IntPtr.Zero)
                    throw new IOException("OVERWRITE_SECURITY_UNAVAILABLE");
                uint size = GetSecurityDescriptorLength(descriptor);
                if (size == 0 || size > 262144) throw new IOException("OVERWRITE_SECURITY_UNAVAILABLE");
                var bytes = new byte[size];
                Marshal.Copy(descriptor, bytes, 0, bytes.Length);
                return new RawSecurityDescriptor(bytes, 0);
            }
            finally { if (descriptor != IntPtr.Zero) LocalFree(descriptor); }
        }

        private static bool ArchivePolicyPrincipalIsTrusted(SecurityIdentifier principal, SecurityIdentifier operation)
        {
            return principal != null && (principal.Equals(operation) ||
                principal.IsWellKnown(WellKnownSidType.LocalSystemSid) ||
                principal.IsWellKnown(WellKnownSidType.BuiltinAdministratorsSid));
        }

        private static RawSecurityDescriptor RequireArchiveExclusivePolicy(SafeFileHandle handle,
            SecurityIdentifier operation)
        {
            var descriptor = ReadArchivePolicy(handle);
            if (!ArchivePolicyPrincipalIsTrusted(descriptor.Owner, operation) || descriptor.DiscretionaryAcl == null ||
                (descriptor.ControlFlags & ControlFlags.DiscretionaryAclPresent) == 0)
                throw new IOException("OVERWRITE_EXCLUSIVITY_REQUIRED");
            foreach (GenericAce entry in descriptor.DiscretionaryAcl)
            {
                var ace = entry as CommonAce;
                if (ace == null || ace.IsCallback ||
                    (ace.AceQualifier != AceQualifier.AccessAllowed && ace.AceQualifier != AceQualifier.AccessDenied))
                    throw new IOException("OVERWRITE_EXCLUSIVITY_REQUIRED");
                // Generic write/all/maximum allowed, owner/DACL/delete rights,
                // file data/EA/attribute writes and directory delete child.
                const uint mutation = 0x520d0156;
                if (ace.AceQualifier == AceQualifier.AccessAllowed && ((uint)ace.AccessMask & mutation) != 0 &&
                    !ArchivePolicyPrincipalIsTrusted(ace.SecurityIdentifier, operation))
                    throw new IOException("OVERWRITE_EXCLUSIVITY_REQUIRED");
            }
            return descriptor;
        }
    }
}
