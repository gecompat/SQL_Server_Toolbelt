using System;
using System.Data;
using System.IO;
using System.IO.Compression;
using Microsoft.SqlServer.Server;

namespace Toolbelt.ZipClr.Spike
{
    /// <summary>
    /// Nicht-produktive SQL-CLR-Probe. Sie öffnet ausschließlich ein
    /// fest eingebettetes leeres ZIP im Speicher und beweist damit den
    /// Ladevorgang von System.IO.Compression unter PERMISSION_SET = SAFE.
    /// </summary>
    public static class ZipClrProbe
    {
        private static readonly byte[] EmptyZipArchive =
        {
            0x50, 0x4B, 0x05, 0x06, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        };

        [SqlProcedure]
        public static void ProbeZipArchive()
        {
            int entryCount;

            using (var stream = new MemoryStream(EmptyZipArchive, writable: false))
            using (var archive = new ZipArchive(stream, ZipArchiveMode.Read, leaveOpen: false))
            {
                entryCount = archive.Entries.Count;
            }

            var metadata = new[]
            {
                new SqlMetaData("ProviderAssembly", SqlDbType.NVarChar, 512),
                new SqlMetaData("EntryCount", SqlDbType.Int)
            };
            var record = new SqlDataRecord(metadata);
            record.SetString(0, typeof(ZipArchive).Assembly.FullName);
            record.SetInt32(1, entryCount);

            SqlContext.Pipe.SendResultsStart(record);
            SqlContext.Pipe.SendResultsRow(record);
            SqlContext.Pipe.SendResultsEnd();
        }
    }
}
