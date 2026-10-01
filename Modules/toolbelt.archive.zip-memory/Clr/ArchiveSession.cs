using System;
using System.Collections.Generic;
using System.IO;

namespace Toolbelt.Archive.ZipMemory
{
    public static partial class ZipEntryProvider
    {
        /// <summary>
        /// Technische CLR-Fassade ohne SQL-Binding. Einmaliger kanonischer ZIP-Index
        /// und CRC-geprüfte begrenzte Partmaterialisierung für den XLSX-Spike.
        /// Der Aufrufer besitzt den seekbaren Stream und hält ihn unverändert.
        /// Keine Streaming-/Memory-Grant-Zusage; ToArray erzeugt eine Payloadkopie.
        /// </summary>
        public sealed class ArchiveSession
        {
            private readonly ArchiveReader reader;
            private readonly Dictionary<string, EntryMetadata> entries;
            private readonly Action checkpoint;
            private readonly long maxPartBytes;
            private readonly decimal maxRatio;
            public string[] PartNames { get; private set; }
            public long DeclaredTotalBytes { get; private set; }

            public ArchiveSession(Stream source, long length, long maxArchiveBytes,
                int maxParts, long maxPartBytes, long maxTotalBytes,
                decimal maxRatio, Action checkpoint)
            {
                try
                {
                if (source == null || maxArchiveBytes < 1 || maxArchiveBytes > MaxArchiveBytes ||
                    maxParts < 1 || maxParts > MaxEntries || maxPartBytes < 1 ||
                    maxPartBytes > Int32.MaxValue || maxTotalBytes < 1 || maxRatio < 1)
                    throw new ArgumentException("Ungültige technische ZIP-Grenzen.");
                if (length < 0 || length > maxArchiveBytes)
                    throw new InvalidDataException("ZIP_ARCHIVE_LIMIT");
                this.checkpoint = checkpoint;
                this.maxPartBytes = maxPartBytes;
                this.maxRatio = maxRatio;
                Check();
                reader = new ArchiveReader(source, length);
                var end = ReadEndOfCentralDirectory(reader);
                if (end.TotalEntries > maxParts) throw new InvalidDataException("ZIP_PART_LIMIT");
                var index = ReadEntries(reader, end, checkpoint);
                entries = new Dictionary<string, EntryMetadata>(StringComparer.Ordinal);
                PartNames = new string[index.Count];
                for (int i = 0; i < index.Count; i++)
                {
                    Check();
                    var entry = index[i];
                    if (entries.ContainsKey(entry.EntryName)) throw new InvalidDataException("ZIP_DUPLICATE_PART");
                    if ((entry.GeneralPurposeFlags & (EncryptionFlag | StrongEncryptionFlag)) != 0 ||
                        (entry.CompressionMethod != 0 && entry.CompressionMethod != 8))
                        throw new InvalidDataException("ZIP_UNSUPPORTED_PART");
                    if (GetPathStatus(entry.EntryName) != PathSafe || entry.IsDirectory)
                        throw new InvalidDataException("ZIP_NONCANONICAL_PART");
                    if (entry.UncompressedBytes > maxPartBytes || entry.CompressedBytes > MaxCompressedBytes ||
                        entry.UncompressedBytes > maxTotalBytes - DeclaredTotalBytes)
                        throw new InvalidDataException("ZIP_PART_OR_SUM_LIMIT");
                    EnforceCompressionRatio(entry.UncompressedBytes, entry.CompressedBytes, maxRatio);
                    DeclaredTotalBytes += entry.UncompressedBytes;
                    entries.Add(entry.EntryName, entry);
                    PartNames[i] = entry.EntryName;
                }
                Check();
                }
                catch (ZipProviderException exception)
                {
                    // Technische Aufrufer hängen nicht vom privaten Readertyp ab
                    // und parsen keine lokalisierten Providermeldungen.
                    throw new InvalidDataException("ZIP_STRUCTURE_OR_RESOURCE", exception);
                }
            }

            public bool Contains(string name) { return entries.ContainsKey(name); }

            public byte[] ReadPart(string name)
            {
                try
                {
                Check();
                EntryMetadata entry;
                if (!entries.TryGetValue(name, out entry)) throw new InvalidDataException("ZIP_PART_MISSING");
                var payload = ReadPayload(reader, entry, maxPartBytes, maxRatio, checkpoint);
                if (payload.LongLength != entry.UncompressedBytes || ComputeCrc32(payload, checkpoint) != entry.Crc32)
                    throw new InvalidDataException("ZIP_PART_INTEGRITY");
                Check();
                return payload;
                }
                catch (ZipProviderException exception)
                {
                    throw new InvalidDataException("ZIP_STRUCTURE_OR_RESOURCE", exception);
                }
            }

            private void Check() { if (checkpoint != null) checkpoint(); }
        }
    }
}
