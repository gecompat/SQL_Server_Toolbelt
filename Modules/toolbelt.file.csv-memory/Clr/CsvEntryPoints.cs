using System;
using System.Collections;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

namespace Toolbelt.Csv
{
    public static class CsvEntryPoints
    {
        [SqlFunction(FillRowMethodName = "FillCell", IsDeterministic = true,
            DataAccess = DataAccessKind.None, SystemDataAccess = SystemDataAccessKind.None,
            TableDefinition = "RowKind nvarchar(6), RowOrdinal bigint, ColumnOrdinal int, Value nvarchar(max), ErrorCode int")]
        public static IEnumerable Parse(SqlChars text, SqlChars separator, SqlBoolean hasHeader,
            SqlChars nullToken, SqlInt64 maxRows, SqlInt32 maxColumns, SqlInt64 maxCells, SqlInt64 maxInputBytes)
        {
            char[] input;
            CsvDialect dialect;
            try
            {
                if (maxRows.IsNull || maxColumns.IsNull || maxCells.IsNull || maxInputBytes.IsNull) throw new CsvFault(55303);
                CsvKernel.Limit(maxRows.Value, 100000); CsvKernel.Limit(maxColumns.Value, 1024);
                CsvKernel.Limit(maxCells.Value, 1000000); CsvKernel.Limit(maxInputBytes.Value, CsvKernel.ByteCeiling);
                if (CsvKernel.IsNull(text) || hasHeader.IsNull) throw new CsvFault(55300);
                dialect = CsvKernel.Dialect(separator, nullToken);
                if (text.Length > maxInputBytes.Value / 2) throw new CsvFault(55303);
                input = text.Value;
                // Vor Rückgabe des IEnumerable vollständig prüfen, auch Fehler im letzten Record.
                foreach (CsvField field in CsvKernel.Scan(input, dialect, hasHeader.Value, maxRows.Value, maxColumns.Value, maxCells.Value)) { }
            }
            catch (CsvFault fault) { return new CsvCell[] { CsvCell.Failure(fault.Code) }; }
            return Decode(input, dialect, hasHeader.Value, maxRows.Value, maxColumns.Value, maxCells.Value);
        }

        private static IEnumerable Decode(char[] input, CsvDialect dialect, bool header, long rows, int columns, long cells)
        {
            foreach (CsvField field in CsvKernel.Scan(input, dialect, header, rows, columns, cells)) yield return CsvKernel.Decode(field);
        }
        public static void FillCell(object cell, out SqlString rowKind, out SqlInt64 rowOrdinal,
            out SqlInt32 columnOrdinal, out SqlChars value, out SqlInt32 errorCode)
        {
            CsvCell row = (CsvCell)cell;
            rowKind = row.Kind; rowOrdinal = row.Row; columnOrdinal = row.Column; value = row.Value; errorCode = row.Error;
        }

        [SqlFunction(IsDeterministic = true, DataAccess = DataAccessKind.None, SystemDataAccess = SystemDataAccessKind.None)]
        public static SqlInt64 MeasureCell(SqlChars value, SqlChars separator, SqlChars nullToken, SqlBoolean isHeader)
        {
            try
            {
                if (isHeader.IsNull) throw new CsvFault(55300);
                return new SqlInt64(CsvKernel.AnalyzeCell(value, CsvKernel.Dialect(separator, nullToken), isHeader.Value).Bytes);
            }
            catch (CsvFault fault) { return new SqlInt64(-fault.Code); }
        }

        [SqlFunction(IsDeterministic = true, DataAccess = DataAccessKind.None, SystemDataAccess = SystemDataAccessKind.None)]
        public static SqlChars QuoteCell(SqlChars value, SqlChars separator, SqlChars nullToken, SqlBoolean isHeader, SqlInt64 maxOutputBytes)
        {
            if (isHeader.IsNull || maxOutputBytes.IsNull) throw new InvalidOperationException("CSV_QUOTE_PREVALIDATION_REQUIRED");
            CsvKernel.Limit(maxOutputBytes.Value, CsvKernel.ByteCeiling);
            return CsvKernel.Quote(CsvKernel.AnalyzeCell(value, CsvKernel.Dialect(separator, nullToken), isHeader.Value), maxOutputBytes.Value);
        }
    }
}
