using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

namespace Toolbelt.Xlsx.Qualification
{
    /// <summary>Nur internes, disposable SAFE-Qualifizierungsbinding; keine öffentliche Reader-API.</summary>
    public static class QualificationEntryPoints
    {
        [SqlFunction(DataAccess = DataAccessKind.None, SystemDataAccess = SystemDataAccessKind.None,
            IsDeterministic = false, IsPrecise = true)]
        public static SqlString Probe(SqlBytes binary, SqlInt32 sheetOrdinal)
        {
            if (binary.IsNull) return SqlString.Null;
            if (binary.Length > 16777216) throw new System.IO.InvalidDataException("TBX_XLSX_ARCHIVE_LIMIT");
            var workbook = new Workbook(binary.Value, null);
            var cells = workbook.ReadCells(sheetOrdinal.IsNull ? 1 : sheetOrdinal.Value);
            return new SqlString(workbook.ListSheets().Length + "|" + cells.Length + "|" +
                (cells.Length == 0 ? "" : cells[0].TextValue));
        }
    }
}
