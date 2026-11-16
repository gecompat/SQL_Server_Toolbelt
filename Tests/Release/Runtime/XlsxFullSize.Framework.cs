using System;
using System.Data.SqlTypes;
using System.IO;
using System.Reflection;
using System.Security.Cryptography;
using Toolbelt.Xlsx.Qualification;

// Frameworkadapter über den unveränderten Kern und den öffentlichen Status-TVF-Einstieg.
public static class XlsxFullSizeFramework
{
    static void Require(bool condition, string reason) { if (!condition) throw new Exception(reason); }
    static string Hash(string path) {
        using (var hash = SHA256.Create()) using (var file = File.OpenRead(path))
            return BitConverter.ToString(hash.ComputeHash(file)).Replace("-", "").ToLowerInvariant();
    }
    public static int Main(string[] args) {
        try {
            Require(args.Length == 3, "ARGUMENTS");
            string dll = typeof(XlsxEntryPoints).Assembly.Location;
            Require(Hash(dll) == args[1], "XLSX_DLL_HASH");
            string zip = typeof(Toolbelt.Archive.ZipMemory.ZipEntryProvider).Assembly.Location;
            Require(Hash(zip) == args[2], "ZIP_DLL_HASH");
            string[] lines = File.ReadAllLines(Path.Combine(args[0], "cases.tsv"));
            Require(lines.Length == 8, "CASE_COUNT");
            foreach (string line in lines) {
                string[] fields = line.Split('\t');
                Require(fields.Length == 4, "CASE_FIELDS");
                string path = Path.Combine(args[0], fields[0] + ".xlsx");
                Require(Hash(path) == fields[1], "FIXTURE_HASH");
                byte[] binary = File.ReadAllBytes(path);
                try {
                    var cells = new Workbook(binary, null).ReadCells(1);
                    Require(fields[3] == "NONE" && cells.Length == 1 && cells[0].Row == 1 &&
                        cells[0].Column == 1 && cells[0].RawValue == "42", "CORE_ORACLE");
                } catch (InvalidDataException error) {
                    Require(fields[3] != "NONE" && error.Message == fields[3], "CORE_ERROR:" + error.Message);
                }
                var rows = XlsxEntryPoints.ReadCells(new SqlBytes(binary), 1,
                    16777216, 16777216, 67108864, 256, 32, 100000, 50000, 8388608,
                    64, new SqlDecimal(200), 5000);
                int count = 0;
                foreach (object row in rows) {
                    SqlInt32 error, r, c, shared;
                    SqlString message, type, raw, text, formula, kind, cache;
                    SqlBoolean present, fp, cp;
                    XlsxEntryPoints.FillCells(row, out error, out message, out r, out c,
                        out type, out present, out raw, out text, out fp, out formula,
                        out kind, out shared, out cp, out cache);
                    if (fields[2] == "NONE") {
                        Require(error.IsNull && message.IsNull, "POSITIVE_STATUS_" + fields[0]);
                        Require(!r.IsNull && r.Value == 1 && !c.IsNull && c.Value == 1 &&
                            !raw.IsNull && raw.Value == "42" && !present.IsNull && present.Value,
                            "POSITIVE_ORACLE_" + fields[0]);
                    } else {
                        Require(!error.IsNull && error.Value == 51520 && !message.IsNull &&
                            message.Value == fields[2], "NEGATIVE_STATUS_" + fields[0] + ":" + message.ToString());
                        Require(r.IsNull && c.IsNull && type.IsNull && raw.IsNull && text.IsNull &&
                            formula.IsNull && kind.IsNull && cache.IsNull && shared.IsNull &&
                            present.IsNull && fp.IsNull && cp.IsNull, "ATOMIC_FAILURE_" + fields[0]);
                    }
                    count++;
                }
                Require(count == 1, "ROW_COUNT_" + fields[0]);
                Require(Hash(path) == fields[1], "FIXTURE_POST_HASH");
                Console.WriteLine("PASS\t" + fields[0] + "\t" + fields[2]);
            }
            Require(Hash(dll) == args[1] && Hash(zip) == args[2], "DLL_POST_HASH");
            return 0;
        } catch (Exception error) { Console.Error.WriteLine(error); return 1; }
    }
}
