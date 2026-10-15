using System;
using System.Collections;
using System.Data.SqlTypes;
using System.IO;
using System.IO.Compression;
using Toolbelt.Archive.ZipMemory;

// Rein synthetische Extraktionsgrenzen im gebundenen .NET-Framework-Prozess.
public static class EntrySecurityContract
{
    static int cases;
    static byte[] Archive(int size)
    {
        using (MemoryStream output = new MemoryStream())
        {
            using (ZipArchive zip = new ZipArchive(output, ZipArchiveMode.Create, true))
            using (Stream entry = zip.CreateEntry("payload.bin", CompressionLevel.Optimal).Open())
            {
                byte[] chunk = new byte[65536];
                while (size > 0) { int count = Math.Min(size, chunk.Length); entry.Write(chunk, 0, count); size -= count; }
            }
            return output.ToArray(); // Kleiner komprimierter Testcontainer, kein Extraktionsergebnis.
        }
    }
    static void Case(byte[] archive, long limit, int error, int length)
    {
        int rows = 0;
        foreach (object row in ZipEntryProvider.ExtractZipEntry(new SqlBytes(archive), "payload.bin", limit, new SqlDecimal(1000000), true))
        {
            SqlInt32 number, method, crc; SqlString message, name;
            SqlInt64 compressed, uncompressed; SqlBoolean encrypted; SqlBinary payload;
            ZipEntryProvider.FillRow(row, out number, out message, out name, out compressed, out uncompressed, out method, out crc, out encrypted, out payload);
            rows++;
            if (error == 0 ? !number.IsNull || payload.IsNull || payload.Length != length : number.IsNull || number.Value != error || !payload.IsNull)
                throw new InvalidOperationException("ZIP_ENTRY_SECURITY_ASSERT");
        }
        if (rows != 1) throw new InvalidOperationException("ZIP_ENTRY_SECURITY_ROWS");
        cases++;
    }
    static void SetSize(byte[] archive, int value)
    {
        byte[] size = BitConverter.GetBytes(value);
        Buffer.BlockCopy(size, 0, archive, 22, 4);
        for (int i = archive.Length - 46; i >= 0; i--)
            if (archive[i] == 0x50 && archive[i+1] == 0x4B && archive[i+2] == 1 && archive[i+3] == 2)
            { Buffer.BlockCopy(size, 0, archive, i + 24, 4); return; }
        throw new InvalidOperationException("ZIP_ENTRY_SECURITY_FIXTURE");
    }
    public static int Main()
    {
        try
        {
            Case(Archive(16777215),16777216,0,16777215);
            Case(Archive(16777216),16777216,0,16777216);
            Case(Archive(16777217),16777216,51325,0);
            Case(Archive(67108864),67108864,0,67108864);
            byte[] overflow = Archive(67108865);
            Case(overflow,67108864,51325,0);
            SetSize(overflow,67108864); // Tatsächlicher Stream überschreitet beide deklarierten Größen.
            Case(overflow,67108864,51325,0);
            Case(Archive(1),67108865,51320,0);
            Console.WriteLine("ZIP_ENTRY_SECURITY_PASS cases=" + cases); return 0;
        }
        catch { Console.Error.WriteLine("ZIP_ENTRY_SECURITY_FAILED"); return 1; }
    }
}
