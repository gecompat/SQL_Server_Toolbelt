using System;
using System.Data;
using System.IO;
using System.IO.Compression;
using System.Text;
using Microsoft.SqlServer.Server;

namespace Toolbelt.ZipClr.Spike
{
    /// <summary>
    /// Nicht-produktive SQL-CLR-Probe für den späteren ZIP-Method-8-Kern.
    /// Sie dekomprimiert ausschließlich einen fest eingebetteten Raw-Deflate-
    /// Stream im Speicher und prüft den Payload zusätzlich mit CRC32.
    /// </summary>
    public static class ZipClrProbe
    {
        private const string ExpectedPayloadText = "SQL Server Toolbelt CLR ZIP probe";
        private const uint ExpectedPayloadCrc32 = 0xBD97DF6A;

        // Raw DEFLATE nach RFC 1951, ohne zlib- oder gzip-Wrapper.
        private static readonly byte[] DeflatedPayload =
        {
            0x0B, 0x0E, 0xF4, 0x51, 0x08, 0x4E, 0x2D, 0x2A,
            0x4B, 0x2D, 0x52, 0x08, 0xC9, 0xCF, 0xCF, 0x49,
            0x4A, 0xCD, 0x29, 0x51, 0x70, 0xF6, 0x09, 0x52,
            0x88, 0xF2, 0x0C, 0x50, 0x28, 0x28, 0xCA, 0x4F,
            0x4A, 0x05, 0x00
        };

        [SqlProcedure]
        public static void ProbeDeflatePrimitive()
        {
            byte[] payload;

            using (var input = new MemoryStream(DeflatedPayload, false))
            using (var inflater = new DeflateStream(input, CompressionMode.Decompress, false))
            using (var output = new MemoryStream())
            {
                inflater.CopyTo(output);
                payload = output.ToArray();
            }

            var expectedPayload = Encoding.UTF8.GetBytes(ExpectedPayloadText);
            if (!ByteArraysEqual(payload, expectedPayload))
            {
                throw new InvalidDataException("Die Deflate-Probe lieferte nicht den erwarteten Payload.");
            }

            var crc32 = ComputeCrc32(payload);
            if (crc32 != ExpectedPayloadCrc32)
            {
                throw new InvalidDataException("Die CRC32-Prüfung der Deflate-Probe ist fehlgeschlagen.");
            }

            var metadata = new[]
            {
                new SqlMetaData("ProviderAssembly", SqlDbType.NVarChar, 512),
                new SqlMetaData("PayloadLength", SqlDbType.Int),
                new SqlMetaData("PayloadCrc32", SqlDbType.Char, 8),
                new SqlMetaData("PayloadText", SqlDbType.NVarChar, 128)
            };
            var record = new SqlDataRecord(metadata);
            record.SetString(0, typeof(DeflateStream).Assembly.FullName);
            record.SetInt32(1, payload.Length);
            record.SetString(2, crc32.ToString("X8"));
            record.SetString(3, Encoding.UTF8.GetString(payload));

            SqlContext.Pipe.SendResultsStart(record);
            SqlContext.Pipe.SendResultsRow(record);
            SqlContext.Pipe.SendResultsEnd();
        }

        private static bool ByteArraysEqual(byte[] left, byte[] right)
        {
            if (left.Length != right.Length)
            {
                return false;
            }

            for (var index = 0; index < left.Length; index++)
            {
                if (left[index] != right[index])
                {
                    return false;
                }
            }

            return true;
        }

        private static uint ComputeCrc32(byte[] payload)
        {
            var crc = 0xFFFFFFFFu;

            foreach (var value in payload)
            {
                crc ^= value;
                for (var bit = 0; bit < 8; bit++)
                {
                    crc = (crc & 1u) != 0u
                        ? (crc >> 1) ^ 0xEDB88320u
                        : crc >> 1;
                }
            }

            return ~crc;
        }
    }
}
