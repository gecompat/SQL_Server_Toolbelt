using System;
using System.Collections;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

namespace Toolbelt.Xlsx.Qualification
{
    // Reiner CLR-Transport; Renderer und vorhandener Typkern besitzen die Semantik.
    public static class XlsxCellDisplayBridge
    {
        private static long Length(SqlChars value)
        { return value == null || value.IsNull ? 0 : value.Length; }
        private static string Copy(SqlChars value)
        { return value == null || value.IsNull ? null : new string(value.Value); }

        [SqlFunction(FillRowMethodName = "FillRow", TableDefinition = "DisplayText nvarchar(max), StatusCode int",
            DataAccess = DataAccessKind.None, SystemDataAccess = SystemDataAccessKind.None,
            IsDeterministic = true, IsPrecise = true)]
        public static IEnumerable Evaluate(SqlChars stored, SqlBoolean present, SqlChars raw, SqlChars text,
            SqlChars target, SqlChars format, SqlBoolean date1904, SqlChars culture)
        {
            // SqlChars.Length vor Value: übergroße Eingaben werden nicht kopiert.
            if (Length(stored) > 32 || Length(target) > 32 || Length(format) > 128
                || Length(raw) > 65536 || Length(text) > 65536 || Length(culture) > 32)
                return new[] { new XlsxCellDisplay.Result { Status = 3 } };
            return new[] { XlsxCellDisplay.Evaluate(Copy(stored), present.IsNull ? (bool?)null : present.Value,
                Copy(raw), Copy(text), Copy(target), Copy(format), date1904.IsNull ? (bool?)null : date1904.Value,
                Copy(culture)) };
        }
        public static void FillRow(object item, out SqlChars display, out SqlInt32 status)
        {
            var row = item as XlsxCellDisplay.Result;
            if (row == null || row.Status < 0 || row.Status > 11 || (row.Status != 0 && row.Display != null))
                throw new InvalidOperationException("TBX_XLSX_DISPLAY_BINDING");
            display = row.Display == null ? SqlChars.Null : new SqlChars(row.Display.ToCharArray());
            status = new SqlInt32(row.Status);
        }
    }
}
