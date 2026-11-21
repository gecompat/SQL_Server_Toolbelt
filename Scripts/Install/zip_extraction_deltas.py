"""Compare the exact ZIP V1 source deltas without inheriting native evidence."""

NEW_FILES = frozenset((
    'Modules/toolbelt.archive.zip-files/Source/USP_ExtractZipArchiveToDirectory.sql',
    'Modules/toolbelt.archive.zip-memory/Clr/ArchiveExtraction.cs',
    'Modules/toolbelt.filesystem.windows/Clr/ArchiveDirectoryExtraction.cs',
    'Modules/toolbelt.filesystem.windows/Clr/ArchiveDestination.cs',
    'Modules/toolbelt.filesystem.windows/Clr/ArchiveNativePaths.cs',
    'Modules/toolbelt.filesystem.windows/Clr/ArchiveSqlBridge.cs',
    'Modules/toolbelt.filesystem.windows/Source/ArchiveExtraction.sql',
))

REGIONS = {
    'Modules/toolbelt.archive.zip-memory/Clr/ZipEntryProvider.cs': (
        (r"""            ArchiveReader reader,
            EndOfCentralDirectory eocd,
            Action checkpoint = null)
        {
            long centralEnd =
""", r"""            ArchiveReader reader,
            EndOfCentralDirectory eocd,
            Action checkpoint = null,
            bool retainLocalHeaderErrors = false)
        {
            long centralEnd =
"""),
        (r"""                    DecodeEntryName(nameBytes, flags);

                if (decodedName.Length > MaxEntryNameCharacters)
                {
                    throw new ZipProviderException(
""", r"""                    DecodeEntryName(nameBytes, flags);

                if (decodedName.Length > MaxEntryNameCharacters && !retainLocalHeaderErrors)
                {
                    throw new ZipProviderException(
"""),
        (r"""                    ConvertDosDateTime(localFileDate, localFileTime),
                    eocd.CentralDirectoryOffset);

                ValidateLocalHeader(reader, entry);
                entries.Add(entry);
                cursor += recordLength;
""", r"""                    ConvertDosDateTime(localFileDate, localFileTime),
                    eocd.CentralDirectoryOffset);
                entry.CreatorPlatform = reader.ReadUInt16(cursor + 4) >> 8;
                entry.ExternalAttributes = reader.ReadUInt32(cursor + 38);

                if (retainLocalHeaderErrors)
                {
                    try { ValidateLocalHeader(reader, entry); }
                    catch (ZipProviderException) { entry.LocalHeaderInvalid = true; }
                    catch (EndOfStreamException) { entry.LocalHeaderInvalid = true; }
                    entry.ReleaseIndexedNameBytes(cursor + 46);
                }
                else ValidateLocalHeader(reader, entry);
                entries.Add(entry);
                cursor += recordLength;
"""),
        (r"""            Action checkpoint = null)
        {
            using (BoundedReadStream compressed =
                reader.OpenBoundedStream(
""", r"""            Action checkpoint = null)
        {
            byte[] output;
            using (var chunks = ReadPayloadChunks(reader, entry, maxEntryBytes, maxCompressionRatio, checkpoint).GetEnumerator())
            {
                bool more = chunks.MoveNext();
                output = new byte[checked((int)entry.UncompressedBytes)];
                int offset = 0;
                while (more)
                {
                    var chunk = chunks.Current;
                    Buffer.BlockCopy(chunk.Array, chunk.Offset, output, offset, chunk.Count);
                    offset += chunk.Count;
                    more = chunks.MoveNext();
                }
            }
            return output;
        }

        private static IEnumerable<ArraySegment<byte>> ReadPayloadChunks(
            ArchiveReader reader, EntryMetadata entry, long maxEntryBytes,
            decimal maxCompressionRatio, Action checkpoint)
        {
            using (BoundedReadStream compressed =
                reader.OpenBoundedStream(
"""),
        (r"""                if (maxEntryBytes < 1 || maxEntryBytes > MaxExtractedEntryBytes || entry.UncompressedBytes > maxEntryBytes)
                    throw new ZipProviderException(51325, "ZIP-Entry überschreitet die feste Extraktionsgrenze.");
                byte[] output = new byte[checked((int)entry.UncompressedBytes)];
                Stream payloadStream = compressed;
                DeflateStream deflate = null;
""", r"""                if (maxEntryBytes < 1 || maxEntryBytes > MaxExtractedEntryBytes || entry.UncompressedBytes > maxEntryBytes)
                    throw new ZipProviderException(51325, "ZIP-Entry überschreitet die feste Extraktionsgrenze.");
                Stream payloadStream = compressed;
                DeflateStream deflate = null;
"""),
        (r"""                        totalBytesRead = total;

                        if (total > maxEntryBytes || total > output.LongLength)
                        {
                            throw new ZipProviderException(
""", r"""                        totalBytesRead = total;

                        if (total > maxEntryBytes || total > entry.UncompressedBytes)
                        {
                            throw new ZipProviderException(
"""),
        (r"""                            maxCompressionRatio);

                        Buffer.BlockCopy(buffer, 0, output, checked((int)(total - read)), read);
                    }
                }
""", r"""                            maxCompressionRatio);

                        yield return new ArraySegment<byte>(buffer, 0, read);
                    }
                }
"""),
        (r"""                }

                if (output.LongLength != totalBytesRead)
                    throw new ZipProviderException(51321, "Die tatsächliche ZIP-Entrygröße weicht von der Deklaration ab.");
                return output;
            }
        }
""", r"""                }

                if (entry.UncompressedBytes != totalBytesRead)
                    throw new ZipProviderException(51321, "Die tatsächliche ZIP-Entrygröße weicht von der Deklaration ab.");
            }
        }
"""),
        (r"""                EntryName = entryName;
                EntryNameBytes = entryNameBytes;
                LocalHeaderOffset = localHeaderOffset;
                CompressionMethod = compressionMethod;
""", r"""                EntryName = entryName;
                EntryNameBytes = entryNameBytes;
                IsDirectory = entryName.EndsWith("/", StringComparison.Ordinal) ||
                    entryName.EndsWith("\\", StringComparison.Ordinal);
                LocalHeaderOffset = localHeaderOffset;
                CompressionMethod = compressionMethod;
"""),
        (r"""            public long CentralDirectoryOffset { get; private set; }
            public long PayloadOffset { get; set; }

            public bool IsDirectory
            {
                get
                {
                    return EntryName.EndsWith("/", StringComparison.Ordinal) ||
                           EntryName.EndsWith("\\", StringComparison.Ordinal);
                }
            }
        }
""", r"""            public long CentralDirectoryOffset { get; private set; }
            public long PayloadOffset { get; set; }
            public int CreatorPlatform { get; set; }
            public uint ExternalAttributes { get; set; }
            public bool LocalHeaderInvalid { get; set; }
            public long LongNameOffset { get; private set; }
            public int LongNameBytes { get; private set; }
            public bool IsDirectory { get; private set; }

            public void ReleaseIndexedNameBytes(long nameOffset)
            {
                if (EntryName.Length > MaxEntryNameCharacters)
                {
                    LongNameOffset = nameOffset;
                    LongNameBytes = EntryNameBytes.Length;
                    EntryName = null;
                }
                EntryNameBytes = null;
            }
        }
"""),
    ),
    'Modules/toolbelt.archive.zip-memory/Clr/Toolbelt.Archive.ZipMemory.csproj': (
        (r"""    <Compile Include="ZipWriter.cs" />
    <Compile Include="ArchiveSession.cs" />
  </ItemGroup>
  <Import Project="$(MSBuildToolsPath)\Microsoft.CSharp.targets" />
""", r"""    <Compile Include="ZipWriter.cs" />
    <Compile Include="ArchiveSession.cs" />
    <Compile Include="ArchiveExtraction.cs" />
  </ItemGroup>
  <Import Project="$(MSBuildToolsPath)\Microsoft.CSharp.targets" />
"""),
    ),
    'Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs': (
        (r"""    public static class WindowsFilesystemProvider
""", r"""    public static partial class WindowsFilesystemProvider
"""),
        (r"""        private sealed class FilesystemExecution
""", r"""        private sealed partial class FilesystemExecution
"""),
    ),
    'Modules/toolbelt.filesystem.windows/Clr/Toolbelt.Filesystem.Windows.csproj': (
        (r"""    <Compile Include="Properties\AssemblyInfo.cs" />
    <Compile Include="WindowsFilesystemProvider.cs" />
  </ItemGroup>
  <Import Project="$(MSBuildToolsPath)\Microsoft.CSharp.targets" />
""", r"""    <Compile Include="Properties\AssemblyInfo.cs" />
    <Compile Include="WindowsFilesystemProvider.cs" />
    <Compile Include="ArchiveNativePaths.cs" />
    <Compile Include="ArchiveDestination.cs" />
    <Compile Include="ArchiveDirectoryExtraction.cs" />
    <Compile Include="ArchiveSqlBridge.cs" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\toolbelt.archive.zip-memory\Clr\Toolbelt.Archive.ZipMemory.csproj">
      <Name>Toolbelt.Archive.ZipMemory</Name>
    </ProjectReference>
  </ItemGroup>
  <Import Project="$(MSBuildToolsPath)\Microsoft.CSharp.targets" />
"""),
    ),
    'Modules/toolbelt.filesystem.windows/Source/FileSystemRoot.sql': (
        (r"""    , AllowDelete          bit             NOT NULL CONSTRAINT [DF_FileSystemRoot_AllowDelete] DEFAULT (0)
    , AllowCreateDirectory bit             NOT NULL CONSTRAINT [DF_FileSystemRoot_AllowCreateDirectory] DEFAULT (0)
    , IsActive             bit             NOT NULL CONSTRAINT [DF_FileSystemRoot_IsActive] DEFAULT (1)
    , CONSTRAINT [PK_FileSystemRoot] PRIMARY KEY CLUSTERED (RootAlias)
""", r"""    , AllowDelete          bit             NOT NULL CONSTRAINT [DF_FileSystemRoot_AllowDelete] DEFAULT (0)
    , AllowCreateDirectory bit             NOT NULL CONSTRAINT [DF_FileSystemRoot_AllowCreateDirectory] DEFAULT (0)
    , AllowZipOverwrite    bit             NOT NULL CONSTRAINT [DF_FileSystemRoot_AllowZipOverwrite] DEFAULT (0)
    , IsActive             bit             NOT NULL CONSTRAINT [DF_FileSystemRoot_IsActive] DEFAULT (1)
    , CONSTRAINT [PK_FileSystemRoot] PRIMARY KEY CLUSTERED (RootAlias)
"""),
    ),
}


def apply(original, path):
    text = original.decode("utf-8").replace("\r\n", "\n")
    for before, after in REGIONS[path]:
        if text.count(before) != 1:
            raise ValueError("CURRENT_ZIP_SOURCE_DELTA_ANCHOR: " + path)
        text = text.replace(before, after, 1)
    return text.encode("utf-8")
