using System;
using System.Collections;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Text;
using Microsoft.SqlServer.Server;

namespace Toolbelt.Archive.ZipMemory
{
    public static partial class ZipEntryProvider
    {
        // Writerformat v1: TBZW, UInt32-Version, UInt32-Anzahl; danach
        // Int32-Ordinal, UInt32-UTF8-Namensbytes, UInt64-Payloadbytes, Name,
        // Payload. Zahlen little endian. Keine CLR-Datenabfrage/Datei-I/O.
        private sealed class WriterException : Exception
        {
            internal readonly int Number;
            internal WriterException(string category, int number)
                : base("TBX_ZIP_WRITE_" + category + ": ZIP-Writer-Vertrag verletzt.") { Number = number; }
        }

        private static WriterException WriterError(string category)
        {
            int number;
            switch (category)
            {
                case "INVALID_ARGUMENT": number = 51350; break;
                case "INVALID_NAME": number = 51352; break;
                case "DUPLICATE_NAME": number = 51353; break;
                case "RESOURCE_LIMIT": number = 51354; break;
                case "FORMAT_LIMIT": number = 51355; break;
                case "TIMEOUT": number = 51356; break;
                case "TRANSPORT_INVALID": number = 51358; break;
                default: number = 51359; break;
            }
            return new WriterException(category, number);
        }

        private sealed class WriterStatus
        {
            internal int ErrorNumber;
            internal string ErrorMessage;
            internal SqlBytes Payload;
        }

        private static IEnumerable WriterStatusResult(Func<SqlBytes> operation)
        {
            var status = new WriterStatus { Payload = SqlBytes.Null };
            try { status.Payload = operation(); }
            catch (WriterException exception) { status.ErrorNumber = exception.Number; status.ErrorMessage = exception.Message; }
            catch (OverflowException) { status.ErrorNumber = 51355; status.ErrorMessage = "TBX_ZIP_WRITE_FORMAT_LIMIT: Numerisches Formatlimit."; }
            catch (EndOfStreamException) { status.ErrorNumber = 51358; status.ErrorMessage = "TBX_ZIP_WRITE_TRANSPORT_INVALID: Envelope unvollständig."; }
            return new[] { status };
        }

        [SqlFunction(DataAccess = DataAccessKind.None, SystemDataAccess = SystemDataAccessKind.None,
            FillRowMethodName = "FillWriterStatus", TableDefinition = "ErrorNumber int, ErrorMessage nvarchar(4000), Payload varbinary(max)")]
        public static IEnumerable EncodeWriterNameStatus(SqlString name, SqlInt32 limit)
        {
            return WriterStatusResult(() => EncodeWriterName(name, limit));
        }

        [SqlFunction(DataAccess = DataAccessKind.None, SystemDataAccess = SystemDataAccessKind.None,
            FillRowMethodName = "FillWriterStatus", TableDefinition = "ErrorNumber int, ErrorMessage nvarchar(4000), Payload varbinary(max)")]
        public static IEnumerable CreateWriterArchiveStatus(SqlBytes envelope, SqlInt32 method,
            SqlInt32 maxEntries, SqlInt32 maxNameUnits, SqlInt64 maxEntry,
            SqlInt64 maxTotal, SqlInt64 maxArchive, SqlInt64 maxEnvelope, SqlInt32 budget)
        {
            return WriterStatusResult(() => CreateWriterArchive(envelope, method, maxEntries,
                maxNameUnits, maxEntry, maxTotal, maxArchive, maxEnvelope, budget));
        }

        public static void FillWriterStatus(object row, out SqlInt32 errorNumber,
            out SqlString errorMessage, out SqlBytes payload)
        {
            var status = (WriterStatus)row;
            errorNumber = new SqlInt32(status.ErrorNumber);
            errorMessage = status.ErrorMessage == null ? SqlString.Null : new SqlString(status.ErrorMessage);
            payload = status.Payload;
        }

        [SqlFunction(DataAccess = DataAccessKind.None, SystemDataAccess = SystemDataAccessKind.None,
            IsDeterministic = true, IsPrecise = true)]
        public static SqlBytes EncodeWriterName(SqlString name, SqlInt32 limit)
        {
            if (name.IsNull || limit.IsNull || limit.Value < 1 || limit.Value > 2048)
                throw WriterError("INVALID_NAME");
            string value = name.Value;
            if (value.Length == 0 || value.Length > limit.Value || value[0] == '/' ||
                value[value.Length - 1] == '/' || value.IndexOf('\\') >= 0 ||
                value.IndexOf(':') >= 0 || value.IndexOf('\0') >= 0)
                throw WriterError("INVALID_NAME");
            foreach (string segment in value.Split('/'))
                if (segment.Length == 0 || segment == "." || segment == "..")
                    throw WriterError("INVALID_NAME");
            // Exception-Fallback verhindert Ersatzzeichen für kaputte Surrogates.
            try { return new SqlBytes(new UTF8Encoding(false, true).GetBytes(value)); }
            catch (EncoderFallbackException) { throw WriterError("INVALID_NAME"); }
        }

        private sealed class WriterEntry
        {
            internal byte[] Name;
            internal long PayloadOffset;
            internal int PayloadLength;
            internal long LocalOffset;
            internal uint Crc;
            internal uint Compressed;
        }

        private sealed class WriterClock
        {
            private readonly Stopwatch clock = Stopwatch.StartNew();
            private readonly int budget;
            internal WriterClock(int value) { budget = value; }
            internal void Check()
            {
                if (clock.ElapsedMilliseconds >= budget) throw WriterError("TIMEOUT");
            }
        }

        // Kapazität wächst begrenzt; Writer prüft vor jeder Allokation/Write.
        // MemoryStream-Wachstum und ToArray verursachen dennoch Kopien. Keine
        // Streaming- oder globales CLR-Memory-Grant-Zusage.
        private sealed class WriterBuffer : MemoryStream
        {
            private readonly long limit;
            private readonly WriterClock clock;
            internal WriterBuffer(long max, WriterClock timer) { limit = max; clock = timer; }
            public override void Write(byte[] buffer, int offset, int count)
            {
                clock.Check();
                long end = checked(Position + count);
                if (end > limit) throw WriterError("RESOURCE_LIMIT");
                if (end > Capacity)
                    Capacity = checked((int)Math.Min(limit, Math.Max(end, Math.Max(4096L, (long)Capacity * 2))));
                base.Write(buffer, offset, count);
                clock.Check();
            }
            public override void WriteByte(byte value)
            {
                Write(new[] { value }, 0, 1);
            }
        }

        [SqlFunction(DataAccess = DataAccessKind.None, SystemDataAccess = SystemDataAccessKind.None,
            IsDeterministic = false, IsPrecise = true)]
        public static SqlBytes CreateWriterArchive(SqlBytes envelope, SqlInt32 method,
            SqlInt32 maxEntries, SqlInt32 maxNameUnits, SqlInt64 maxEntry,
            SqlInt64 maxTotal, SqlInt64 maxArchive, SqlInt64 maxEnvelope, SqlInt32 budget)
        {
            if (envelope.IsNull || method.IsNull || (method.Value != 0 && method.Value != 8) ||
                maxEntries.IsNull || maxEntries.Value < 1 || maxEntries.Value > 1024 ||
                maxNameUnits.IsNull || maxNameUnits.Value < 1 || maxNameUnits.Value > 2048 ||
                maxEntry.IsNull || maxEntry.Value < 1 || maxEntry.Value > 33554432 ||
                maxTotal.IsNull || maxTotal.Value < 1 || maxTotal.Value > 134217728 ||
                maxArchive.IsNull || maxArchive.Value < 1 || maxArchive.Value > 150994944 ||
                maxEnvelope.IsNull || maxEnvelope.Value < 1 || maxEnvelope.Value > 142606336 ||
                budget.IsNull || budget.Value < 1 || budget.Value > 60000)
                throw WriterError("INVALID_ARGUMENT");
            var timer = new WriterClock(budget.Value);
            if (envelope.Length > maxEnvelope.Value) throw WriterError("RESOURCE_LIMIT");
            // SQL-Binarytransport wird einmal übernommen, nicht pro Entry. Auch
            // nichtseekende SqlBytes sind ohne Filefallback unterstützt.
            using (var owned = new WriterBuffer(maxEnvelope.Value, timer))
            {
                Stream source = envelope.Stream;
                if (source.CanSeek) source.Position = 0;
                byte[] copy = new byte[81920];
                long actual = 0;
                int got;
                while ((got = source.Read(copy, 0, copy.Length)) > 0)
                {
                    actual += got;
                    owned.Write(copy, 0, got);
                }
                if (actual != envelope.Length) throw WriterError("TRANSPORT_INVALID");
                owned.Position = 0;
                using (var reader = new BinaryReader(owned, Encoding.UTF8, true))
                {
                    var entries = ReadWriterEntries(reader, maxEntries.Value, maxNameUnits.Value,
                        maxEntry.Value, maxTotal.Value, timer);
                    using (var output = new WriterBuffer(maxArchive.Value, timer))
                    using (var writer = new BinaryWriter(output, Encoding.UTF8, true))
                    {
                        foreach (WriterEntry entry in entries)
                        {
                            timer.Check();
                            entry.LocalOffset = output.Position;
                            writer.Write(0x04034b50U); writer.Write((ushort)20);
                            writer.Write((ushort)0x800); writer.Write((ushort)method.Value);
                            writer.Write((ushort)0); writer.Write((ushort)0x21);
                            writer.Write(0U); writer.Write(0U); writer.Write((uint)entry.PayloadLength);
                            writer.Write((ushort)entry.Name.Length); writer.Write((ushort)0); writer.Write(entry.Name);
                            long begin = output.Position;
                            owned.Position = entry.PayloadOffset;
                            uint crc = UInt32.MaxValue;
                            int left = entry.PayloadLength;
                            // Leeres DeflateStream.Dispose kann frameworkabhängig
                            // keine Bytes schreiben. RFC1951-finaler leerer Block.
                            if (method.Value == 8 && left == 0) output.Write(new byte[] { 3, 0 }, 0, 2);
                            DeflateStream compressor = method.Value == 8 && left != 0
                                ? new DeflateStream(output, CompressionLevel.Optimal, true) : null;
                            try
                            {
                                while (left > 0)
                                {
                                    timer.Check();
                                    int read = owned.Read(copy, 0, Math.Min(left, copy.Length));
                                    if (read <= 0) throw WriterError("TRANSPORT_INVALID");
                                    for (int index = 0; index < read; index++)
                                        crc = CrcTable[(int)((crc ^ copy[index]) & 255U)] ^ (crc >> 8);
                                    if (compressor != null) compressor.Write(copy, 0, read);
                                    else output.Write(copy, 0, read);
                                    left -= read;
                                }
                            }
                            finally { if (compressor != null) compressor.Dispose(); }
                            timer.Check();
                            entry.Crc = ~crc;
                            entry.Compressed = checked((uint)(output.Position - begin));
                            long end = output.Position;
                            output.Position = entry.LocalOffset + 14;
                            writer.Write(entry.Crc); writer.Write(entry.Compressed);
                            output.Position = end;
                        }
                        long directory = output.Position;
                        foreach (WriterEntry entry in entries)
                        {
                            timer.Check();
                            writer.Write(0x02014b50U); writer.Write((ushort)20); writer.Write((ushort)20);
                            writer.Write((ushort)0x800); writer.Write((ushort)method.Value);
                            writer.Write((ushort)0); writer.Write((ushort)0x21);
                            writer.Write(entry.Crc); writer.Write(entry.Compressed); writer.Write((uint)entry.PayloadLength);
                            writer.Write((ushort)entry.Name.Length); writer.Write((ushort)0); writer.Write((ushort)0);
                            writer.Write((ushort)0); writer.Write((ushort)0); writer.Write(0U);
                            writer.Write(checked((uint)entry.LocalOffset)); writer.Write(entry.Name);
                        }
                        uint directoryBytes = checked((uint)(output.Position - directory));
                        writer.Write(0x06054b50U); writer.Write((ushort)0); writer.Write((ushort)0);
                        writer.Write((ushort)entries.Count); writer.Write((ushort)entries.Count);
                        writer.Write(directoryBytes); writer.Write(checked((uint)directory)); writer.Write((ushort)0);
                        writer.Flush(); timer.Check();
                        byte[] result = output.ToArray(); timer.Check();
                        return new SqlBytes(result);
                    }
                }
            }
        }

        private static List<WriterEntry> ReadWriterEntries(BinaryReader reader, int maxEntries,
            int maxNameUnits, long maxEntry, long maxTotal, WriterClock timer)
        {
            Stream source = reader.BaseStream;
            Action<long> require = count => {
                timer.Check();
                if (count < 0 || count > source.Length - source.Position) throw WriterError("TRANSPORT_INVALID");
            };
            require(12);
            if (reader.ReadUInt32() != 0x575a4254U || reader.ReadUInt32() != 1U)
                throw WriterError("TRANSPORT_INVALID");
            uint countEntries = reader.ReadUInt32();
            if (countEntries > maxEntries) throw WriterError("RESOURCE_LIMIT");
            var result = new List<WriterEntry>((int)countEntries);
            // HashSet<T> (System.Core) trägt im Framework HostProtection und
            // wird im SQL-SAFE-Host abgelehnt. Dictionary aus mscorlib erhält
            // denselben ordinalen Vertrag ohne Privilegienausweitung.
            var names = new Dictionary<string, bool>(StringComparer.Ordinal);
            int previous = 0;
            long total = 0;
            for (int index = 0; index < countEntries; index++)
            {
                require(16);
                int ordinal = reader.ReadInt32(); uint nameBytes = reader.ReadUInt32();
                ulong payload = reader.ReadUInt64();
                if (ordinal <= previous) throw WriterError("TRANSPORT_INVALID");
                previous = ordinal;
                if (nameBytes == 0 || nameBytes > 65535 || nameBytes > maxNameUnits * 3)
                    throw WriterError("INVALID_NAME");
                if (payload > (ulong)maxEntry) throw WriterError("RESOURCE_LIMIT");
                total = checked(total + (long)payload);
                if (total > maxTotal) throw WriterError("RESOURCE_LIMIT");
                require(checked((long)nameBytes + (long)payload));
                byte[] name = reader.ReadBytes((int)nameBytes);
                string decoded;
                try { decoded = new UTF8Encoding(false, true).GetString(name); }
                catch (DecoderFallbackException) { throw WriterError("INVALID_NAME"); }
                EncodeWriterName(new SqlString(decoded), new SqlInt32(maxNameUnits));
                if (names.ContainsKey(decoded)) throw WriterError("DUPLICATE_NAME");
                names.Add(decoded, true);
                result.Add(new WriterEntry { Name = name, PayloadOffset = source.Position, PayloadLength = (int)payload });
                source.Position += (long)payload;
            }
            if (source.Position != source.Length) throw WriterError("TRANSPORT_INVALID");
            return result;
        }
    }
}
