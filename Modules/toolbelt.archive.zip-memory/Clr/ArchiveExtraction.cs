using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace Toolbelt.Archive.ZipMemory
{
    public static partial class ZipEntryProvider
    {
        // The consumer owns the seekable archive and an unpublished staging sink.
        // An exception from copying or validation must prevent its publication.
        public sealed class ExtractionArchive
        {
            private readonly ArchiveReader reader;
            private readonly IList<EntryMetadata> entries;
            private readonly long maxEntryBytes;
            private readonly decimal maxRatio;

            public ExtractionArchive(Stream source, long length, long maxArchive, long maxEntries,
                long maxEntry, long maxTotal, decimal maxRatio, int maxName)
            {
                CheckBound(maxArchive, MaxArchiveBytes, "MaxArchiveBytes");
                CheckBound(maxEntries, MaxEntries, "MaxEntries");
                CheckBound(maxEntry, MaxExtractedEntryBytes, "MaxEntryBytes");
                CheckBound(maxName, MaxEntryNameCharacters, "MaxPathLength");
                if (maxTotal < 1) throw new ArgumentException("ZIP_INVALID_LIMIT MaxTotalExpandedBytes");
                if (maxRatio < 1 || maxRatio > 9999999.99M)
                    throw new ArgumentException("ZIP_INVALID_LIMIT MaxCompressionRatio MAX=9999999.99");
                if (length > maxArchive) throw new InvalidDataException("ZIP_ARCHIVE_LIMIT");
                try
                {
                    reader = new ArchiveReader(source, length);
                    var end = ReadEndOfCentralDirectory(reader);
                    if (end.TotalEntries > maxEntries) throw new InvalidDataException("ZIP_ENTRY_COUNT_LIMIT");
                    entries = ReadEntries(reader, end, retainLocalHeaderErrors: true);
                }
                catch (ZipProviderException) { throw new InvalidDataException("ZIP_INVALID_STRUCTURE"); }
                catch (DecoderFallbackException) { throw new InvalidDataException("ZIP_INVALID_NAME_ENCODING"); }
                catch (EndOfStreamException) { throw new InvalidDataException("ZIP_INVALID_STRUCTURE"); }
                maxEntryBytes = maxEntry;
                this.maxRatio = maxRatio;
                var manifest = new List<ExtractionEntry>(entries.Count);
                // The same hosting constraint applies as in the ZIP writer:
                // HashSet<T> requests MayLeakOnAbort in the SQL CLR SAFE host.
                var names = new Dictionary<string, bool>(StringComparer.Ordinal);
                long total = 0;
                foreach (var entry in entries)
                {
                    string error = null;
                    int unixKind = (int)(entry.ExternalAttributes >> 16) & 0xf000;
                    if (entry.LocalHeaderInvalid)
                        error = "INVALID_LOCAL_HEADER";
                    else if ((entry.ExternalAttributes & 0x400) != 0 ||
                        ((entry.CreatorPlatform == 3 || entry.CreatorPlatform == 19) && unixKind != 0 &&
                        unixKind != (entry.IsDirectory ? 0x4000 : 0x8000)) ||
                        ((entry.ExternalAttributes & 0x10) != 0 && !entry.IsDirectory))
                        error = "UNSUPPORTED_ENTRY_KIND";
                    else if ((entry.GeneralPurposeFlags & (EncryptionFlag | StrongEncryptionFlag)) != 0 ||
                        (entry.CompressionMethod != 0 && entry.CompressionMethod != 8))
                        error = "UNSUPPORTED_ENTRY_FORMAT";
                    else if (entry.EntryName == null || entry.EntryName.Length > maxName)
                        error = "ENTRY_NAME_LIMIT";
                    else if (GetPathStatus(entry.EntryName) != PathSafe || entry.EntryName.IndexOf('\0') >= 0)
                        error = "UNSAFE_PATH";
                    else if (names.ContainsKey(entry.EntryName))
                        error = "PATH_COLLISION";
                    else if (entry.IsDirectory && entry.UncompressedBytes != 0)
                        error = "INVALID_DIRECTORY_PAYLOAD";
                    else if (entry.CompressionMethod == 0 && entry.CompressedBytes != entry.UncompressedBytes)
                        error = "INVALID_ENTRY_PAYLOAD";
                    else if (entry.UncompressedBytes > maxEntry || entry.CompressedBytes > MaxCompressedBytes)
                        error = "ENTRY_SIZE_LIMIT";
                    else if (entry.UncompressedBytes > maxTotal - total)
                        error = "TOTAL_SIZE_LIMIT";
                    else if (entry.UncompressedBytes != 0 &&
                        (entry.CompressedBytes == 0 || (decimal)entry.UncompressedBytes / entry.CompressedBytes > maxRatio))
                        error = "COMPRESSION_RATIO_LIMIT";
                    if (entry.UncompressedBytes <= maxTotal - total) total += entry.UncompressedBytes;
                    if (entry.EntryName != null && !names.ContainsKey(entry.EntryName))
                        names.Add(entry.EntryName, true);
                    // Oversized names never participate in path resolution. Re-read
                    // them only if the caller needs the original name for its outcome.
                    Func<string> readName = entry.EntryName != null ? null : (Func<string>)(() =>
                        DecodeEntryName(reader.ReadBytes(entry.LongNameOffset, entry.LongNameBytes), entry.GeneralPurposeFlags));
                    manifest.Add(new ExtractionEntry(entry.EntryName, readName, entry.IsDirectory, error));
                }
                Entries = manifest.AsReadOnly();
            }

            public IList<ExtractionEntry> Entries { get; private set; }

            // The returned segment remains valid until the next MoveNext().
            // Exhaust the sequence before publishing. No filesystem code
            // executes on the SAFE reader's stack.
            public IEnumerable<ArraySegment<byte>> ReadVerified(int index)
            {
                var entry = entries[index];
                if (Entries[index].ErrorCode != null) throw new InvalidOperationException("ZIP_ENTRY_PREFLIGHT_FAILED");
                uint crc = UInt32.MaxValue;
                using (var chunks = ReadPayloadChunks(reader, entry, maxEntryBytes, maxRatio, null).GetEnumerator())
                {
                    while (MoveToNextChunk(chunks))
                    {
                        var chunk = chunks.Current;
                        for (int i = 0; i < chunk.Count; i++)
                            crc = CrcTable[(int)((crc ^ chunk.Array[chunk.Offset + i]) & 0xffU)] ^ (crc >> 8);
                        yield return chunk;
                    }
                }
                if (~crc != entry.Crc32) throw new InvalidDataException("CRC_MISMATCH");
            }

            private static bool MoveToNextChunk(IEnumerator<ArraySegment<byte>> chunks)
            {
                try { return chunks.MoveNext(); }
                catch (ZipProviderException error)
                {
                    throw new InvalidDataException(error.ErrorNumber == 51325 ? "ENTRY_SIZE_LIMIT" :
                        error.ErrorNumber == 51326 ? "COMPRESSION_RATIO_LIMIT" : "INVALID_ENTRY_PAYLOAD");
                }
            }

            private static void CheckBound(long value, long max, string name)
            {
                if (value < 1 || value > max)
                    throw new ArgumentException("ZIP_INVALID_LIMIT " + name + " MAX=" + max);
            }
        }

        public sealed class ExtractionEntry
        {
            private readonly string name;
            private readonly Func<string> readName;

            internal ExtractionEntry(string name, Func<string> readName, bool directory, string error)
            { this.name = name; this.readName = readName; IsDirectory = directory; ErrorCode = error; }

            public string Name { get { return name ?? readName(); } }
            public bool IsDirectory { get; private set; }
            public string ErrorCode { get; private set; }
        }
    }
}
