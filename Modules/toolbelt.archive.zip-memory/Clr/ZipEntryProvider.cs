using System;
using System.Collections;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlTypes;
using System.IO;
using System.IO.Compression;
using System.Text;
using Microsoft.SqlServer.Server;

namespace Toolbelt.Archive.ZipMemory
{
    /// <summary>
    /// Interner SAFE-SQL-CLR-Provider für die begrenzte In-memory-Extraktion
    /// genau eines ZIP-Entries. Unterstützt ausschließlich Methods 0 und 8.
    /// </summary>
    public static class ZipEntryProvider
    {
        private const long MaxArchiveBytes = 268435456L;
        private const long MaxCompressedBytes = 134217728L;
        private const int MaxEntries = 10000;
        private const int MaxEntryNameCharacters = 1024;

        private const uint LocalHeaderSignature = 0x04034B50U;
        private const uint CentralHeaderSignature = 0x02014B50U;
        private const uint EndOfCentralDirectorySignature = 0x06054B50U;

        private const int EncryptionFlag = 0x0001;
        private const int CompressionOptionFlags = 0x0006;
        private const int DataDescriptorFlag = 0x0008;
        private const int StrongEncryptionFlag = 0x0040;
        private const int Utf8Flag = 0x0800;
        private const int RelevantLocalFlags =
            EncryptionFlag |
            CompressionOptionFlags |
            DataDescriptorFlag |
            StrongEncryptionFlag |
            Utf8Flag;

        private const string PathSafe = "safe";
        private const string PathAbsolute = "absolute";
        private const string PathDriveQualified = "drive-qualified";
        private const string PathParentTraversal = "parent-traversal";
        private const string PathNonCanonical = "noncanonical";

        private static readonly Encoding Utf8Strict =
            new UTF8Encoding(false, true);

        private static readonly Encoding Cp437Strict =
            Encoding.GetEncoding(
                437,
                EncoderFallback.ExceptionFallback,
                DecoderFallback.ExceptionFallback);

        private static readonly uint[] CrcTable = BuildCrcTable();

        [SqlFunction(
            DataAccess = DataAccessKind.None,
            SystemDataAccess = SystemDataAccessKind.None,
            IsDeterministic = true,
            IsPrecise = true,
            FillRowMethodName = "FillRow",
            TableDefinition =
                "ErrorNumber int, " +
                "ErrorMessage nvarchar(4000), " +
                "EntryName nvarchar(1024), " +
                "CompressedBytes bigint, " +
                "UncompressedBytes bigint, " +
                "CompressionMethod int, " +
                "Crc32 int, " +
                "IsEncrypted bit, " +
                "EntryPayload varbinary(max)")]
        public static IEnumerable ExtractZipEntry(
            SqlBytes zipArchive,
            SqlString entryName,
            SqlInt64 maxEntryBytes,
            SqlDecimal maxCompressionRatio,
            SqlBoolean failIfEncrypted)
        {
            ProviderResult result;

            try
            {
                result = Extract(
                    zipArchive,
                    entryName,
                    maxEntryBytes,
                    maxCompressionRatio,
                    failIfEncrypted);
            }
            catch (ZipProviderException exception)
            {
                result = ProviderResult.Failure(
                    exception.ErrorNumber,
                    exception.Message);
            }
            catch (InvalidDataException)
            {
                result = ProviderResult.Failure(
                    51321,
                    "Der komprimierte ZIP-Payload ist ungültig oder unvollständig.");
            }
            catch (DecoderFallbackException)
            {
                result = ProviderResult.Failure(
                    51321,
                    "Ein ZIP-Entry-Name verwendet eine ungültige Zeichenkodierung.");
            }
            catch (EndOfStreamException)
            {
                result = ProviderResult.Failure(
                    51321,
                    "Der ZIP-Container endet innerhalb einer benötigten Struktur.");
            }
            catch (IOException)
            {
                result = ProviderResult.Failure(
                    51321,
                    "Der ZIP-Container konnte nicht vollständig gelesen werden.");
            }

            return new ProviderResult[] { result };
        }

        [SqlFunction(
            DataAccess = DataAccessKind.None,
            SystemDataAccess = SystemDataAccessKind.None,
            IsDeterministic = true,
            IsPrecise = true,
            FillRowMethodName = "FillListRow",
            TableDefinition =
                "ErrorNumber int, " +
                "ErrorMessage nvarchar(4000), " +
                "EntryOrdinal int, " +
                "EntryName nvarchar(1024), " +
                "IsDirectory bit, " +
                "CompressedBytes bigint, " +
                "UncompressedBytes bigint, " +
                "CompressionMethod int, " +
                "Crc32 int, " +
                "IsEncrypted bit, " +
                "IsExtractionSupported bit, " +
                "DuplicateCount int, " +
                "IsPathSafe bit, " +
                "PathStatus varchar(32), " +
                "LastModifiedAt datetime2(0)")]
        public static IEnumerable ListZipEntriesFromBinary(
            SqlBytes zipArchive,
            SqlInt32 maxEntries)
        {
            ProviderListResult result;

            try
            {
                return ListEntries(zipArchive, maxEntries);
            }
            catch (ZipProviderException exception)
            {
                result = ProviderListResult.Failure(
                    exception.ErrorNumber,
                    exception.Message);
            }
            catch (InvalidDataException)
            {
                result = ProviderListResult.Failure(
                    51321,
                    "Der ZIP-Container ist strukturell ungültig oder unvollständig.");
            }
            catch (DecoderFallbackException)
            {
                result = ProviderListResult.Failure(
                    51321,
                    "Ein ZIP-Entry-Name verwendet eine ungültige Zeichenkodierung.");
            }
            catch (EndOfStreamException)
            {
                result = ProviderListResult.Failure(
                    51321,
                    "Der ZIP-Container endet innerhalb einer benötigten Struktur.");
            }
            catch (IOException)
            {
                result = ProviderListResult.Failure(
                    51321,
                    "Der ZIP-Container konnte nicht vollständig gelesen werden.");
            }

            return new ProviderListResult[] { result };
        }

        public static void FillRow(
            object value,
            out SqlInt32 errorNumber,
            out SqlString errorMessage,
            out SqlString entryName,
            out SqlInt64 compressedBytes,
            out SqlInt64 uncompressedBytes,
            out SqlInt32 compressionMethod,
            out SqlInt32 crc32,
            out SqlBoolean isEncrypted,
            out SqlBytes entryPayload)
        {
            ProviderResult result = (ProviderResult)value;

            errorNumber = result.ErrorNumber.HasValue
                ? new SqlInt32(result.ErrorNumber.Value)
                : SqlInt32.Null;
            errorMessage = result.ErrorMessage == null
                ? SqlString.Null
                : new SqlString(result.ErrorMessage);
            entryName = result.EntryName == null
                ? SqlString.Null
                : new SqlString(result.EntryName);
            compressedBytes = result.CompressedBytes.HasValue
                ? new SqlInt64(result.CompressedBytes.Value)
                : SqlInt64.Null;
            uncompressedBytes = result.UncompressedBytes.HasValue
                ? new SqlInt64(result.UncompressedBytes.Value)
                : SqlInt64.Null;
            compressionMethod = result.CompressionMethod.HasValue
                ? new SqlInt32(result.CompressionMethod.Value)
                : SqlInt32.Null;
            crc32 = result.Crc32.HasValue
                ? new SqlInt32(result.Crc32.Value)
                : SqlInt32.Null;
            isEncrypted = result.IsEncrypted.HasValue
                ? new SqlBoolean(result.IsEncrypted.Value)
                : SqlBoolean.Null;
            entryPayload = result.EntryPayload == null
                ? SqlBytes.Null
                : new SqlBytes(result.EntryPayload);
        }

        public static void FillListRow(
            object value,
            out SqlInt32 errorNumber,
            out SqlString errorMessage,
            out SqlInt32 entryOrdinal,
            out SqlString entryName,
            out SqlBoolean isDirectory,
            out SqlInt64 compressedBytes,
            out SqlInt64 uncompressedBytes,
            out SqlInt32 compressionMethod,
            out SqlInt32 crc32,
            out SqlBoolean isEncrypted,
            out SqlBoolean isExtractionSupported,
            out SqlInt32 duplicateCount,
            out SqlBoolean isPathSafe,
            out SqlString pathStatus,
            out SqlDateTime lastModifiedAt)
        {
            ProviderListResult result = (ProviderListResult)value;

            errorNumber = result.ErrorNumber.HasValue
                ? new SqlInt32(result.ErrorNumber.Value)
                : SqlInt32.Null;
            errorMessage = result.ErrorMessage == null
                ? SqlString.Null
                : new SqlString(result.ErrorMessage);
            entryOrdinal = result.EntryOrdinal.HasValue
                ? new SqlInt32(result.EntryOrdinal.Value)
                : SqlInt32.Null;
            entryName = result.EntryName == null
                ? SqlString.Null
                : new SqlString(result.EntryName);
            isDirectory = result.IsDirectory.HasValue
                ? new SqlBoolean(result.IsDirectory.Value)
                : SqlBoolean.Null;
            compressedBytes = result.CompressedBytes.HasValue
                ? new SqlInt64(result.CompressedBytes.Value)
                : SqlInt64.Null;
            uncompressedBytes = result.UncompressedBytes.HasValue
                ? new SqlInt64(result.UncompressedBytes.Value)
                : SqlInt64.Null;
            compressionMethod = result.CompressionMethod.HasValue
                ? new SqlInt32(result.CompressionMethod.Value)
                : SqlInt32.Null;
            crc32 = result.Crc32.HasValue
                ? new SqlInt32(result.Crc32.Value)
                : SqlInt32.Null;
            isEncrypted = result.IsEncrypted.HasValue
                ? new SqlBoolean(result.IsEncrypted.Value)
                : SqlBoolean.Null;
            isExtractionSupported = result.IsExtractionSupported.HasValue
                ? new SqlBoolean(result.IsExtractionSupported.Value)
                : SqlBoolean.Null;
            duplicateCount = result.DuplicateCount.HasValue
                ? new SqlInt32(result.DuplicateCount.Value)
                : SqlInt32.Null;
            isPathSafe = result.IsPathSafe.HasValue
                ? new SqlBoolean(result.IsPathSafe.Value)
                : SqlBoolean.Null;
            pathStatus = result.PathStatus == null
                ? SqlString.Null
                : new SqlString(result.PathStatus);

            if (result.LastModifiedAt.HasValue)
                lastModifiedAt = new SqlDateTime(result.LastModifiedAt.Value);
            else
                lastModifiedAt = SqlDateTime.Null;
        }

        private static ProviderResult Extract(
            SqlBytes zipArchive,
            SqlString entryName,
            SqlInt64 maxEntryBytes,
            SqlDecimal maxCompressionRatio,
            SqlBoolean failIfEncrypted)
        {
            if (zipArchive == null || zipArchive.IsNull || zipArchive.Length == 0)
            {
                throw new ZipProviderException(
                    51320,
                    "@ZipArchive muss einen nicht leeren ZIP-Container enthalten.");
            }

            if (entryName.IsNull || entryName.Value.Length == 0)
            {
                throw new ZipProviderException(
                    51320,
                    "@EntryName muss gesetzt sein.");
            }

            if (entryName.Value.Length > MaxEntryNameCharacters)
            {
                throw new ZipProviderException(
                    51320,
                    "@EntryName darf höchstens 1024 Zeichen enthalten.");
            }

            if (maxEntryBytes.IsNull ||
                maxEntryBytes.Value <= 0 ||
                maxEntryBytes.Value > Int32.MaxValue)
            {
                throw new ZipProviderException(
                    51320,
                    "@MaxEntryBytes muss zwischen 1 und 2147483647 liegen.");
            }

            if (maxCompressionRatio.IsNull ||
                maxCompressionRatio.Value < 1M)
            {
                throw new ZipProviderException(
                    51320,
                    "@MaxCompressionRatio muss größer oder gleich 1 sein.");
            }

            if (failIfEncrypted.IsNull)
            {
                throw new ZipProviderException(
                    51320,
                    "@FailIfEncrypted darf nicht NULL sein.");
            }

            if (zipArchive.Length > MaxArchiveBytes)
            {
                throw new ZipProviderException(
                    51325,
                    "Der ZIP-Container überschreitet das harte Providerlimit von 268435456 Bytes.");
            }

            Stream source = zipArchive.Stream;
            MemoryStream ownedCopy = null;

            try
            {
                if (!source.CanSeek)
                {
                    ownedCopy = CopyToSeekableStream(
                        source,
                        zipArchive.Length);
                    source = ownedCopy;
                }

                ArchiveReader reader = new ArchiveReader(
                    source,
                    zipArchive.Length);

                EntryMetadata entry = FindEntry(
                    reader,
                    entryName.Value);

                bool encrypted =
                    (entry.GeneralPurposeFlags &
                        (EncryptionFlag | StrongEncryptionFlag)) != 0;

                if (encrypted)
                {
                    if (failIfEncrypted.Value)
                    {
                        throw new ZipProviderException(
                            51324,
                            "Der angeforderte ZIP-Entry ist verschlüsselt.");
                    }

                    return ProviderResult.Success(
                        entry.EntryName,
                        entry.CompressedBytes,
                        entry.UncompressedBytes,
                        entry.CompressionMethod,
                        unchecked((int)entry.Crc32),
                        true,
                        null);
                }

                if (entry.CompressionMethod != 0 &&
                    entry.CompressionMethod != 8)
                {
                    throw new ZipProviderException(
                        51327,
                        "Die ZIP Compression Method wird nicht unterstützt. Zulässig sind nur 0 und 8.");
                }

                if (entry.UncompressedBytes > maxEntryBytes.Value)
                {
                    throw new ZipProviderException(
                        51325,
                        "Der ZIP-Entry überschreitet @MaxEntryBytes.");
                }

                if (entry.CompressedBytes > MaxCompressedBytes)
                {
                    throw new ZipProviderException(
                        51325,
                        "Der komprimierte ZIP-Entry überschreitet das harte Providerlimit von 134217728 Bytes.");
                }

                EnforceCompressionRatio(
                    entry.UncompressedBytes,
                    entry.CompressedBytes,
                    maxCompressionRatio.Value);

                ValidateLocalHeader(reader, entry);

                byte[] payload = ReadPayload(
                    reader,
                    entry,
                    maxEntryBytes.Value,
                    maxCompressionRatio.Value);

                if (payload.LongLength != entry.UncompressedBytes)
                {
                    throw new ZipProviderException(
                        51328,
                        "Die tatsächlich ausgegebene Payload-Länge stimmt nicht mit dem Central Directory überein.");
                }

                uint actualCrc32 = ComputeCrc32(payload);
                if (actualCrc32 != entry.Crc32)
                {
                    throw new ZipProviderException(
                        51328,
                        "Die CRC32-Prüfung des dekomprimierten Payloads ist fehlgeschlagen.");
                }

                return ProviderResult.Success(
                    entry.EntryName,
                    entry.CompressedBytes,
                    entry.UncompressedBytes,
                    entry.CompressionMethod,
                    unchecked((int)actualCrc32),
                    false,
                    payload);
            }
            finally
            {
                if (ownedCopy != null)
                    ownedCopy.Dispose();
            }
        }

        private static IEnumerable ListEntries(
            SqlBytes zipArchive,
            SqlInt32 maxEntries)
        {
            if (zipArchive == null || zipArchive.IsNull || zipArchive.Length == 0)
            {
                throw new ZipProviderException(
                    51320,
                    "@ZipArchive muss einen nicht leeren ZIP-Container enthalten.");
            }

            if (maxEntries.IsNull ||
                maxEntries.Value < 1 ||
                maxEntries.Value > MaxEntries)
            {
                throw new ZipProviderException(
                    51320,
                    "@MaxEntries muss zwischen 1 und 10000 liegen.");
            }

            if (zipArchive.Length > MaxArchiveBytes)
            {
                throw new ZipProviderException(
                    51325,
                    "Der ZIP-Container überschreitet das harte Providerlimit von 268435456 Bytes.");
            }

            Stream source = zipArchive.Stream;
            MemoryStream ownedCopy = null;

            try
            {
                if (!source.CanSeek)
                {
                    ownedCopy = CopyToSeekableStream(
                        source,
                        zipArchive.Length);
                    source = ownedCopy;
                }

                ArchiveReader reader = new ArchiveReader(
                    source,
                    zipArchive.Length);
                EndOfCentralDirectory eocd =
                    ReadEndOfCentralDirectory(reader);

                if (eocd.TotalEntries == 0)
                {
                    return Array.Empty<ProviderListResult>();
                }

                if (eocd.TotalEntries > maxEntries.Value)
                {
                    throw new ZipProviderException(
                        51325,
                        "Das ZIP enthält mehr Entries als @MaxEntries zulässt.");
                }

                IList<EntryMetadata> entries = ReadEntries(reader, eocd);
                if (entries.Count == 0)
                {
                    return Array.Empty<ProviderListResult>();
                }

                Dictionary<string, int> duplicateCounts =
                    BuildDuplicateCounts(entries);

                ProviderListResult[] result =
                    new ProviderListResult[entries.Count];

                for (int index = 0; index < entries.Count; index++)
                {
                    EntryMetadata entry = entries[index];
                    bool isEncrypted =
                        (entry.GeneralPurposeFlags &
                            (EncryptionFlag | StrongEncryptionFlag)) != 0;
                    string pathStatus = GetPathStatus(entry.EntryName);

                    result[index] = ProviderListResult.Success(
                        entry.EntryOrdinal,
                        entry.EntryName,
                        entry.IsDirectory,
                        entry.CompressedBytes,
                        entry.UncompressedBytes,
                        entry.CompressionMethod,
                        unchecked((int)entry.Crc32),
                        isEncrypted,
                        (entry.CompressionMethod == 0 ||
                         entry.CompressionMethod == 8) &&
                        !isEncrypted,
                        duplicateCounts.ContainsKey(entry.EntryName)
                            ? duplicateCounts[entry.EntryName]
                            : 1,
                        pathStatus == PathSafe,
                        pathStatus,
                        entry.LastModifiedAt);
                }

                return result;
            }
            finally
            {
                if (ownedCopy != null)
                    ownedCopy.Dispose();
            }
        }

        private static MemoryStream CopyToSeekableStream(
            Stream source,
            long expectedLength)
        {
            MemoryStream target = new MemoryStream(
                expectedLength <= Int32.MaxValue
                    ? (int)expectedLength
                    : 0);

            byte[] buffer = new byte[81920];
            long total = 0;

            while (true)
            {
                int read = source.Read(
                    buffer,
                    0,
                    buffer.Length);

                if (read == 0)
                {
                    break;
                }

                total += read;
                if (total > MaxArchiveBytes)
                {
                    target.Dispose();
                    throw new ZipProviderException(
                        51325,
                        "Der ZIP-Container überschreitet das harte Providerlimit.");
                }

                target.Write(buffer, 0, read);
            }

            if (total != expectedLength)
            {
                target.Dispose();
                throw new ZipProviderException(
                    51321,
                    "Die gelesene Archivlänge stimmt nicht mit der varbinary(max)-Länge überein.");
            }

            target.Position = 0;
            return target;
        }

        private static EntryMetadata FindEntry(
            ArchiveReader reader,
            string requestedEntryName)
        {
            EndOfCentralDirectory eocd =
                ReadEndOfCentralDirectory(reader);

            IList<EntryMetadata> entries = ReadEntries(reader, eocd);

            EntryMetadata match = null;
            int matchCount = 0;

            for (int ordinal = 0; ordinal < entries.Count; ordinal++)
            {
                EntryMetadata entry = entries[ordinal];
                if (String.Equals(
                    entry.EntryName,
                    requestedEntryName,
                    StringComparison.Ordinal))
                {
                    matchCount++;
                    if (matchCount > 1)
                    {
                        throw new ZipProviderException(
                            51323,
                            "Der angeforderte Entry-Name ist im ZIP-Archiv nicht eindeutig.");
                    }
                    match = entry;
                }
            }

            if (match == null)
            {
                throw new ZipProviderException(
                    51322,
                    "Der angeforderte ZIP-Entry wurde nicht gefunden.");
            }

            return match;
        }

        private static IList<EntryMetadata> ReadEntries(
            ArchiveReader reader,
            EndOfCentralDirectory eocd)
        {
            long centralEnd =
                eocd.CentralDirectoryOffset +
                eocd.CentralDirectorySize;

            if (eocd.TotalEntries > MaxEntries)
            {
                throw new ZipProviderException(
                    51325,
                    "Das ZIP-Archiv überschreitet das harte Providerlimit von 10000 Entries.");
            }

            if (centralEnd != eocd.Offset)
            {
                throw new ZipProviderException(
                    51327,
                    "Zusätzliche Central-Directory-Datensätze werden in dieser Provider-Version nicht unterstützt.");
            }

            long cursor = eocd.CentralDirectoryOffset;
            List<EntryMetadata> entries = new List<EntryMetadata>(eocd.TotalEntries);

            for (int ordinal = 0;
                 ordinal < eocd.TotalEntries;
                 ordinal++)
            {
                reader.RequireRange(cursor, 46);

                if (reader.ReadUInt32(cursor) !=
                    CentralHeaderSignature)
                {
                    throw new ZipProviderException(
                        51321,
                        "Ein Central-Directory-Header besitzt eine ungültige Signatur.");
                }

                int flags = reader.ReadUInt16(cursor + 8);
                int method = reader.ReadUInt16(cursor + 10);
                uint crc32 = reader.ReadUInt32(cursor + 16);
                uint compressed = reader.ReadUInt32(cursor + 20);
                uint uncompressed = reader.ReadUInt32(cursor + 24);
                int nameLength = reader.ReadUInt16(cursor + 28);
                int extraLength = reader.ReadUInt16(cursor + 30);
                int commentLength = reader.ReadUInt16(cursor + 32);
                int diskStart = reader.ReadUInt16(cursor + 34);
                uint localOffset = reader.ReadUInt32(cursor + 42);
                int localFileTime = reader.ReadUInt16(cursor + 12);
                int localFileDate = reader.ReadUInt16(cursor + 14);

                if (compressed == UInt32.MaxValue ||
                    uncompressed == UInt32.MaxValue ||
                    localOffset == UInt32.MaxValue ||
                    diskStart == UInt16.MaxValue)
                {
                    throw new ZipProviderException(
                        51327,
                        "ZIP64 wird von dieser Provider-Version nicht unterstützt.");
                }

                if (diskStart != 0)
                {
                    throw new ZipProviderException(
                        51327,
                        "Multi-Disk-ZIP-Archive werden nicht unterstützt.");
                }

                long recordLength =
                    46L +
                    nameLength +
                    extraLength +
                    commentLength;

                reader.RequireRange(cursor, recordLength);

                byte[] nameBytes =
                    reader.ReadBytes(cursor + 46, nameLength);
                string decodedName =
                    DecodeEntryName(nameBytes, flags);

                if (decodedName.Length > MaxEntryNameCharacters)
                {
                    throw new ZipProviderException(
                        51320,
                        "Ein Entry-Name überschreitet die maximale Länge von 1024 Zeichen.");
                }

                EntryMetadata entry = new EntryMetadata(
                    ordinal + 1,
                    decodedName,
                    nameBytes,
                    localOffset,
                    method,
                    flags,
                    crc32,
                    compressed,
                    uncompressed,
                    ConvertDosDateTime(localFileDate, localFileTime),
                    eocd.CentralDirectoryOffset);

                ValidateLocalHeader(reader, entry);
                entries.Add(entry);
                cursor += recordLength;
            }

            if (cursor != centralEnd)
            {
                throw new ZipProviderException(
                    51321,
                    "Die Central-Directory-Größe ist inkonsistent.");
            }

            return entries;
        }

        private static Dictionary<string, int> BuildDuplicateCounts(
            IList<EntryMetadata> entries)
        {
            Dictionary<string, int> duplicateCounts =
                new Dictionary<string, int>(StringComparer.Ordinal);

            for (int index = 0; index < entries.Count; index++)
            {
                string entryName = entries[index].EntryName;

                int count;
                if (!duplicateCounts.TryGetValue(entryName, out count))
                {
                    duplicateCounts.Add(entryName, 1);
                }
                else
                {
                    duplicateCounts[entryName] = count + 1;
                }
            }

            return duplicateCounts;
        }

        private static string GetPathStatus(string entryName)
        {
            if (entryName.Length > 2 &&
                Char.IsLetter(entryName[0]) &&
                entryName[1] == ':' &&
                (entryName[2] == '/' || entryName[2] == '\\'))
            {
                return PathDriveQualified;
            }

            if (entryName.Length > 0 &&
                (entryName[0] == '/' || entryName[0] == '\\'))
            {
                return PathAbsolute;
            }

            if (entryName.IndexOf("../", StringComparison.Ordinal) >= 0 ||
                entryName.IndexOf("..\\", StringComparison.Ordinal) >= 0 ||
                entryName.IndexOf("/../", StringComparison.Ordinal) >= 0 ||
                entryName.IndexOf("\\..\\", StringComparison.Ordinal) >= 0 ||
                entryName.StartsWith("../", StringComparison.Ordinal) ||
                entryName.StartsWith("..\\", StringComparison.Ordinal) ||
                entryName.EndsWith("/..") ||
                entryName.EndsWith("\\.."))
            {
                return PathParentTraversal;
            }

            if (entryName.IndexOf("\\", StringComparison.Ordinal) >= 0 ||
                entryName.IndexOf("//", StringComparison.Ordinal) >= 0 ||
                entryName.IndexOf("/./", StringComparison.Ordinal) >= 0 ||
                entryName.IndexOf("\\.\\", StringComparison.Ordinal) >= 0 ||
                entryName.IndexOf("/\\", StringComparison.Ordinal) >= 0 ||
                entryName.IndexOf("\\/", StringComparison.Ordinal) >= 0)
            {
                return PathNonCanonical;
            }

            return PathSafe;
        }

        private static void ValidateLocalHeader(
            ArchiveReader reader,
            EntryMetadata entry)
        {
            long offset = entry.LocalHeaderOffset;
            reader.RequireRange(offset, 30);

            if (reader.ReadUInt32(offset) !=
                LocalHeaderSignature)
            {
                throw new ZipProviderException(
                    51321,
                    "Der Local File Header besitzt eine ungültige Signatur.");
            }

            int localFlags = reader.ReadUInt16(offset + 6);
            int localMethod = reader.ReadUInt16(offset + 8);
            uint localCrc32 = reader.ReadUInt32(offset + 14);
            uint localCompressed = reader.ReadUInt32(offset + 18);
            uint localUncompressed = reader.ReadUInt32(offset + 22);
            int localNameLength = reader.ReadUInt16(offset + 26);
            int localExtraLength = reader.ReadUInt16(offset + 28);

            if ((localFlags & RelevantLocalFlags) !=
                (entry.GeneralPurposeFlags & RelevantLocalFlags))
            {
                throw new ZipProviderException(
                    51321,
                    "General-Purpose-Flags von Local Header und Central Directory stimmen nicht überein.");
            }

            if (localMethod != entry.CompressionMethod)
            {
                throw new ZipProviderException(
                    51321,
                    "Compression Method von Local Header und Central Directory stimmt nicht überein.");
            }

            long payloadOffset =
                offset +
                30L +
                localNameLength +
                localExtraLength;

            reader.RequireRange(
                offset + 30,
                (long)localNameLength + localExtraLength);
            reader.RequireRange(
                payloadOffset,
                entry.CompressedBytes);

            byte[] localNameBytes =
                reader.ReadBytes(
                    offset + 30,
                    localNameLength);

            if (!ByteArraysEqual(
                localNameBytes,
                entry.EntryNameBytes))
            {
                throw new ZipProviderException(
                    51321,
                    "Entry-Name von Local Header und Central Directory stimmt nicht überein.");
            }

            if (payloadOffset + entry.CompressedBytes >
                entry.CentralDirectoryOffset)
            {
                throw new ZipProviderException(
                    51321,
                    "Der komprimierte Payload überlappt das Central Directory.");
            }

            if ((localFlags & DataDescriptorFlag) == 0 &&
                (localCrc32 != entry.Crc32 ||
                 localCompressed != entry.CompressedBytes ||
                 localUncompressed != entry.UncompressedBytes))
            {
                throw new ZipProviderException(
                    51321,
                    "CRC32 oder Größen von Local Header und Central Directory stimmen nicht überein.");
            }

            entry.PayloadOffset = payloadOffset;
        }

        private static byte[] ReadPayload(
            ArchiveReader reader,
            EntryMetadata entry,
            long maxEntryBytes,
            decimal maxCompressionRatio)
        {
            using (BoundedReadStream compressed =
                reader.OpenBoundedStream(
                    entry.PayloadOffset,
                    entry.CompressedBytes))
            using (MemoryStream output = new MemoryStream())
            {
                Stream payloadStream = compressed;
                DeflateStream deflate = null;

                try
                {
                    if (entry.CompressionMethod == 8)
                    {
                        deflate = new DeflateStream(
                            compressed,
                            CompressionMode.Decompress,
                            true);
                        payloadStream = deflate;
                    }
                    else if (entry.CompressedBytes !=
                             entry.UncompressedBytes)
                    {
                        throw new ZipProviderException(
                            51328,
                            "Stored-Entry besitzt unterschiedliche komprimierte und unkomprimierte Größen.");
                    }

                    byte[] buffer = new byte[81920];
                    long total = 0;

                    while (true)
                    {
                        int read = payloadStream.Read(
                            buffer,
                            0,
                            buffer.Length);

                        if (read == 0)
                        {
                            break;
                        }

                        total += read;

                        if (total > maxEntryBytes)
                        {
                            throw new ZipProviderException(
                                51325,
                                "Die tatsächliche Payload überschreitet @MaxEntryBytes.");
                        }

                        EnforceCompressionRatio(
                            total,
                            entry.CompressedBytes,
                            maxCompressionRatio);

                        output.Write(buffer, 0, read);
                    }
                }
                finally
                {
                    if (deflate != null)
                    {
                        deflate.Dispose();
                    }
                }

                if (compressed.Remaining != 0)
                {
                    throw new ZipProviderException(
                        51321,
                        "Der komprimierte Payload enthält nicht konsumierte Bytes.");
                }

                return output.ToArray();
            }
        }

        private static void EnforceCompressionRatio(
            long uncompressedBytes,
            long compressedBytes,
            decimal maximumRatio)
        {
            if (uncompressedBytes == 0)
            {
                return;
            }

            if (compressedBytes == 0)
            {
                throw new ZipProviderException(
                    51326,
                    "Die Compression Ratio ist wegen einer komprimierten Größe von 0 unzulässig.");
            }

            decimal ratio =
                (decimal)uncompressedBytes /
                compressedBytes;

            if (ratio > maximumRatio)
            {
                throw new ZipProviderException(
                    51326,
                    "Der ZIP-Entry überschreitet @MaxCompressionRatio.");
            }
        }

        private static string DecodeEntryName(
            byte[] value,
            int flags)
        {
            return (flags & Utf8Flag) != 0
                ? Utf8Strict.GetString(value)
                : Cp437Strict.GetString(value);
        }

        private static uint ComputeCrc32(byte[] value)
        {
            uint crc = UInt32.MaxValue;

            for (int index = 0;
                 index < value.Length;
                 index++)
            {
                crc =
                    CrcTable[(int)((crc ^ value[index]) & 0xFFU)] ^
                    (crc >> 8);
            }

            return ~crc;
        }

        private static DateTime? ConvertDosDateTime(
            int dosDate,
            int dosTime)
        {
            int second = (dosTime & 0x1F) * 2;
            int minute = (dosTime >> 5) & 0x3F;
            int hour = (dosTime >> 11) & 0x1F;
            int day = dosDate & 0x1F;
            int month = (dosDate >> 5) & 0x0F;
            int year = 1980 + ((dosDate >> 9) & 0x7F);

            if (dosTime == 0 && dosDate == 0)
                return null;

            if (hour > 23 || minute > 59 || second > 59 ||
                month < 1 || month > 12 ||
                day < 1 || day > 31 ||
                year > 2107)
            {
                return null;
            }

            try
            {
                return new DateTime(year, month, day, hour, minute, second);
            }
            catch (ArgumentOutOfRangeException)
            {
                return null;
            }
        }

        private static uint[] BuildCrcTable()
        {
            uint[] table = new uint[256];

            for (uint value = 0;
                 value < table.Length;
                 value++)
            {
                uint current = value;

                for (int bit = 0;
                     bit < 8;
                     bit++)
                {
                    current =
                        (current & 1U) != 0
                            ? 0xEDB88320U ^ (current >> 1)
                            : current >> 1;
                }

                table[(int)value] = current;
            }

            return table;
        }

        private static bool ByteArraysEqual(
            byte[] left,
            byte[] right)
        {
            if (left.Length != right.Length)
            {
                return false;
            }

            for (int index = 0;
                 index < left.Length;
                 index++)
            {
                if (left[index] != right[index])
                {
                    return false;
                }
            }

            return true;
        }

        private static int ReadUInt16(
            byte[] value,
            int offset)
        {
            return
                value[offset] |
                (value[offset + 1] << 8);
        }

        private static uint ReadUInt32(
            byte[] value,
            int offset)
        {
            return
                (uint)value[offset] |
                ((uint)value[offset + 1] << 8) |
                ((uint)value[offset + 2] << 16) |
                ((uint)value[offset + 3] << 24);
        }

        private static EndOfCentralDirectory ReadEndOfCentralDirectory(
            ArchiveReader reader)
        {
            if (reader.Length < 22)
            {
                throw new ZipProviderException(
                    51321,
                    "Der ZIP-Container ist zu kurz für einen gültigen EOCD-Record.");
            }

            int tailLength =
                (int)Math.Min(reader.Length, 65557L);
            long tailOffset =
                reader.Length - tailLength;
            byte[] tail =
                reader.ReadBytes(tailOffset, tailLength);

            for (int index = tail.Length - 22;
                 index >= 0;
                 index--)
            {
                if (ReadUInt32(tail, index) !=
                    EndOfCentralDirectorySignature)
                {
                    continue;
                }

                int commentLength =
                    ReadUInt16(tail, index + 20);

                if (index + 22 + commentLength !=
                    tail.Length)
                {
                    continue;
                }

                long offset = tailOffset + index;
                int diskNumber = ReadUInt16(tail, index + 4);
                int centralDisk = ReadUInt16(tail, index + 6);
                int entriesOnDisk = ReadUInt16(tail, index + 8);
                int totalEntries = ReadUInt16(tail, index + 10);
                uint centralSize = ReadUInt32(tail, index + 12);
                uint centralOffset = ReadUInt32(tail, index + 16);

                if (diskNumber != 0 ||
                    centralDisk != 0 ||
                    entriesOnDisk != totalEntries)
                {
                    throw new ZipProviderException(
                        51327,
                        "Multi-Disk-ZIP-Archive werden nicht unterstützt.");
                }

                if (entriesOnDisk == UInt16.MaxValue ||
                    totalEntries == UInt16.MaxValue ||
                    centralSize == UInt32.MaxValue ||
                    centralOffset == UInt32.MaxValue)
                {
                    throw new ZipProviderException(
                        51327,
                        "ZIP64 wird von dieser Provider-Version nicht unterstützt.");
                }

                long centralEnd =
                    (long)centralOffset +
                    centralSize;

                if (centralEnd > offset ||
                    centralEnd > reader.Length)
                {
                    throw new ZipProviderException(
                        51321,
                        "Central Directory Offset oder Größe ist ungültig.");
                }

                return new EndOfCentralDirectory(
                    offset,
                    totalEntries,
                    centralOffset,
                    centralSize);
            }

            throw new ZipProviderException(
                51321,
                "EOCD-Signatur wurde im ZIP-Container nicht gefunden.");
        }

        private sealed class ArchiveReader
        {
            private readonly Stream _stream;

            public ArchiveReader(
                Stream stream,
                long length)
            {
                if (!stream.CanRead ||
                    !stream.CanSeek)
                {
                    throw new ZipProviderException(
                        51321,
                        "Der ZIP-Eingabestream ist nicht lesbar und seekbar.");
                }

                _stream = stream;
                Length = length;
            }

            public long Length { get; private set; }

            public int ReadUInt16(long offset)
            {
                byte[] bytes = ReadBytes(offset, 2);
                return ZipEntryProvider.ReadUInt16(bytes, 0);
            }

            public uint ReadUInt32(long offset)
            {
                byte[] bytes = ReadBytes(offset, 4);
                return ZipEntryProvider.ReadUInt32(bytes, 0);
            }

            public byte[] ReadBytes(
                long offset,
                int count)
            {
                RequireRange(offset, count);

                byte[] value = new byte[count];
                _stream.Position = offset;

                int completed = 0;
                while (completed < count)
                {
                    int read = _stream.Read(
                        value,
                        completed,
                        count - completed);

                    if (read == 0)
                    {
                        throw new EndOfStreamException();
                    }

                    completed += read;
                }

                return value;
            }

            public void RequireRange(
                long offset,
                long count)
            {
                if (offset < 0 ||
                    count < 0 ||
                    offset > Length ||
                    count > Length - offset)
                {
                    throw new ZipProviderException(
                        51321,
                        "Eine ZIP-Struktur verweist außerhalb des Containers.");
                }
            }

            public BoundedReadStream OpenBoundedStream(
                long offset,
                long length)
            {
                RequireRange(offset, length);
                return new BoundedReadStream(
                    _stream,
                    offset,
                    length);
            }
        }

        private sealed class BoundedReadStream : Stream
        {
            private readonly Stream _source;
            private long _remaining;

            public BoundedReadStream(
                Stream source,
                long offset,
                long length)
            {
                _source = source;
                _source.Position = offset;
                _remaining = length;
            }

            public long Remaining
            {
                get { return _remaining; }
            }

            public override bool CanRead
            {
                get { return true; }
            }

            public override bool CanSeek
            {
                get { return false; }
            }

            public override bool CanWrite
            {
                get { return false; }
            }

            public override long Length
            {
                get { throw new NotSupportedException(); }
            }

            public override long Position
            {
                get { throw new NotSupportedException(); }
                set { throw new NotSupportedException(); }
            }

            public override int Read(
                byte[] buffer,
                int offset,
                int count)
            {
                if (_remaining == 0)
                {
                    return 0;
                }

                int requested =
                    (int)Math.Min(
                        count,
                        _remaining);

                int read = _source.Read(
                    buffer,
                    offset,
                    requested);

                if (read == 0)
                {
                    throw new EndOfStreamException();
                }

                _remaining -= read;
                return read;
            }

            public override void Flush()
            {
            }

            public override long Seek(
                long offset,
                SeekOrigin origin)
            {
                throw new NotSupportedException();
            }

            public override void SetLength(long value)
            {
                throw new NotSupportedException();
            }

            public override void Write(
                byte[] buffer,
                int offset,
                int count)
            {
                throw new NotSupportedException();
            }

            protected override void Dispose(bool disposing)
            {
                base.Dispose(disposing);
            }
        }

        private sealed class EndOfCentralDirectory
        {
            public EndOfCentralDirectory(
                long offset,
                int totalEntries,
                long centralDirectoryOffset,
                long centralDirectorySize)
            {
                Offset = offset;
                TotalEntries = totalEntries;
                CentralDirectoryOffset =
                    centralDirectoryOffset;
                CentralDirectorySize =
                    centralDirectorySize;
            }

            public long Offset { get; private set; }
            public int TotalEntries { get; private set; }
            public long CentralDirectoryOffset { get; private set; }
            public long CentralDirectorySize { get; private set; }
        }

        private sealed class EntryMetadata
        {
            public EntryMetadata(
                int entryOrdinal,
                string entryName,
                byte[] entryNameBytes,
                long localHeaderOffset,
                int compressionMethod,
                int generalPurposeFlags,
                uint crc32,
                long compressedBytes,
                long uncompressedBytes,
                DateTime? lastModifiedAt,
                long centralDirectoryOffset)
            {
                EntryOrdinal = entryOrdinal;
                EntryName = entryName;
                EntryNameBytes = entryNameBytes;
                LocalHeaderOffset = localHeaderOffset;
                CompressionMethod = compressionMethod;
                GeneralPurposeFlags = generalPurposeFlags;
                Crc32 = crc32;
                CompressedBytes = compressedBytes;
                UncompressedBytes = uncompressedBytes;
                LastModifiedAt = lastModifiedAt;
                CentralDirectoryOffset =
                    centralDirectoryOffset;
            }

            public int EntryOrdinal { get; private set; }
            public string EntryName { get; private set; }
            public byte[] EntryNameBytes { get; private set; }
            public long LocalHeaderOffset { get; private set; }
            public int CompressionMethod { get; private set; }
            public int GeneralPurposeFlags { get; private set; }
            public uint Crc32 { get; private set; }
            public long CompressedBytes { get; private set; }
            public long UncompressedBytes { get; private set; }
            public DateTime? LastModifiedAt { get; private set; }
            public long CentralDirectoryOffset { get; private set; }
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

        private sealed class ProviderResult
        {
            public int? ErrorNumber { get; private set; }
            public string ErrorMessage { get; private set; }
            public string EntryName { get; private set; }
            public long? CompressedBytes { get; private set; }
            public long? UncompressedBytes { get; private set; }
            public int? CompressionMethod { get; private set; }
            public int? Crc32 { get; private set; }
            public bool? IsEncrypted { get; private set; }
            public byte[] EntryPayload { get; private set; }

            public static ProviderResult Failure(
                int errorNumber,
                string errorMessage)
            {
                return new ProviderResult
                {
                    ErrorNumber = errorNumber,
                    ErrorMessage = errorMessage
                };
            }

            public static ProviderResult Success(
                string entryName,
                long compressedBytes,
                long uncompressedBytes,
                int compressionMethod,
                int crc32,
                bool isEncrypted,
                byte[] entryPayload)
            {
                return new ProviderResult
                {
                    EntryName = entryName,
                    CompressedBytes = compressedBytes,
                    UncompressedBytes = uncompressedBytes,
                    CompressionMethod = compressionMethod,
                    Crc32 = crc32,
                    IsEncrypted = isEncrypted,
                    EntryPayload = entryPayload
                };
            }
        }

        private sealed class ProviderListResult
        {
            public int? ErrorNumber { get; private set; }
            public string ErrorMessage { get; private set; }
            public int? EntryOrdinal { get; private set; }
            public string EntryName { get; private set; }
            public bool? IsDirectory { get; private set; }
            public long? CompressedBytes { get; private set; }
            public long? UncompressedBytes { get; private set; }
            public int? CompressionMethod { get; private set; }
            public int? Crc32 { get; private set; }
            public bool? IsEncrypted { get; private set; }
            public bool? IsExtractionSupported { get; private set; }
            public int? DuplicateCount { get; private set; }
            public bool? IsPathSafe { get; private set; }
            public string PathStatus { get; private set; }
            public DateTime? LastModifiedAt { get; private set; }

            public static ProviderListResult Failure(
                int errorNumber,
                string errorMessage)
            {
                return new ProviderListResult
                {
                    ErrorNumber = errorNumber,
                    ErrorMessage = errorMessage
                };
            }

            public static ProviderListResult Success(
                int entryOrdinal,
                string entryName,
                bool isDirectory,
                long compressedBytes,
                long uncompressedBytes,
                int compressionMethod,
                int crc32,
                bool isEncrypted,
                bool isExtractionSupported,
                int duplicateCount,
                bool isPathSafe,
                string pathStatus,
                DateTime? lastModifiedAt)
            {
                return new ProviderListResult
                {
                    EntryOrdinal = entryOrdinal,
                    EntryName = entryName,
                    IsDirectory = isDirectory,
                    CompressedBytes = compressedBytes,
                    UncompressedBytes = uncompressedBytes,
                    CompressionMethod = compressionMethod,
                    Crc32 = crc32,
                    IsEncrypted = isEncrypted,
                    IsExtractionSupported = isExtractionSupported,
                    DuplicateCount = duplicateCount,
                    IsPathSafe = isPathSafe,
                    PathStatus = pathStatus,
                    LastModifiedAt = lastModifiedAt
                };
            }
        }

        private sealed class ZipProviderException : Exception
        {
            public ZipProviderException(
                int errorNumber,
                string message)
                : base(message)
            {
                ErrorNumber = errorNumber;
            }

            public int ErrorNumber { get; private set; }
        }
    }
}
