using System;
using System.Collections;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.IO;
using System.Text;
using System.Xml;
using Microsoft.SqlServer.Server;

namespace Toolbelt.Xlsx.Qualification
{
    /// <summary>
    /// Interne datenzugriffsfreie SAFE-Status-TVFs. Gewählte Ergebnisse werden vor
    /// der Enumeration vollständig materialisiert. Erwartete Inputfehler ergeben
    /// eine Statuszeile; unerwartete Laufzeitfehler bleiben ursprüngliche CLR-Fehler.
    /// </summary>
    public static class XlsxEntryPoints
    {
        private sealed class Row
        {
            public int? Error; public string Message;
            public Workbook.Sheet Sheet; public Workbook.Cell Cell;
        }
        private static Workbook.Limits Limits(SqlInt64 archive, SqlInt64 part, SqlInt64 total,
            SqlInt32 parts, SqlInt32 sheets, SqlInt32 cells, SqlInt32 strings, SqlInt64 text,
            SqlInt32 depth, SqlDecimal ratio, SqlInt32 budget)
        {
            if (archive.IsNull || part.IsNull || total.IsNull || parts.IsNull || sheets.IsNull ||
                cells.IsNull || strings.IsNull || text.IsNull || depth.IsNull || ratio.IsNull || budget.IsNull)
                throw new InvalidDataException("TBX_XLSX_LIMIT_CONFIG");
            var limits = new Workbook.Limits { ArchiveBytes=archive.Value, PartBytes=part.Value,
                TotalBytes=total.Value, Parts=parts.Value, Sheets=sheets.Value, Cells=cells.Value,
                Strings=strings.Value, StringBytes=text.Value, Depth=depth.Value, Ratio=ratio.Value,
                BudgetMilliseconds=budget.Value };
            limits.Validate(); return limits;
        }
        private static IEnumerable Read(SqlBytes input, SqlInt32 ordinal, bool cells,
            SqlInt64 archive, SqlInt64 part, SqlInt64 total, SqlInt32 parts, SqlInt32 sheets,
            SqlInt32 maxCells, SqlInt32 strings, SqlInt64 text, SqlInt32 depth, SqlDecimal ratio, SqlInt32 budget)
        {
            var result = new List<Row>();
            try
            {
                var limits = Limits(archive,part,total,parts,sheets,maxCells,strings,text,depth,ratio,budget);
                if (cells && (ordinal.IsNull || ordinal.Value < 1)) throw new InvalidDataException("TBX_XLSX_SHEET_ORDINAL");
                if (input.IsNull) return result;
                if (input.Length > limits.ArchiveBytes) throw new InvalidDataException("TBX_XLSX_ARCHIVE_LIMIT");
                // SqlBytes.Value materialisiert das SQL-Input. Diese Archivkopie
                // kommt zu kanonischem ZIP-Payload und XML-/Ergebnisallokationen hinzu.
                var workbook = new Workbook(input.Value,limits);
                if (cells) foreach (var cell in workbook.ReadCells(ordinal.Value)) { workbook.Checkpoint(); result.Add(new Row { Cell=cell }); }
                else foreach (var sheet in workbook.ListSheets()) { workbook.Checkpoint(); result.Add(new Row { Sheet=sheet }); }
                workbook.Checkpoint();
                return result;
            }
            catch (XmlException) { return Failure("TBX_XLSX_XML_INVALID"); }
            catch (DecoderFallbackException) { return Failure("TBX_XLSX_ENCODING_INVALID"); }
            // InvalidDataException erbt im Framework nicht von IOException.
            catch (InvalidDataException exception) { return InputFailure(exception.Message); }
            catch (IOException exception)
            {
                return InputFailure(exception.Message);
            }
        }
        private static IEnumerable InputFailure(string category)
        {
                // Nur unsere begrenzte Kategorie ist öffentlich. Frameworkmeldungen
                // könnten Workbooktext enthalten und überschreiten diese Grenze nicht.
                if (!category.StartsWith("TBX_XLSX_",StringComparison.Ordinal) || category.Length>96)
                    category="TBX_XLSX_CONTAINER_INVALID";
                return Failure(category);
        }
        private static IEnumerable Failure(string category) { return new[] {new Row {Error=51520,Message=category}}; }
        [SqlFunction(FillRowMethodName="FillSheets",DataAccess=DataAccessKind.None,SystemDataAccess=SystemDataAccessKind.None,
            IsDeterministic=false,IsPrecise=true,
            TableDefinition="ErrorNumber int, ErrorMessage nvarchar(4000), SheetOrdinal int, SheetName nvarchar(max), Visibility nvarchar(16), Date1904 bit")]
        public static IEnumerable ListSheets(SqlBytes input, SqlInt64 archive, SqlInt64 part, SqlInt64 total,
            SqlInt32 parts, SqlInt32 sheets, SqlInt32 cells, SqlInt32 strings, SqlInt64 text,
            SqlInt32 depth, SqlDecimal ratio, SqlInt32 budget)
        { return Read(input,SqlInt32.Null,false,archive,part,total,parts,sheets,cells,strings,text,depth,ratio,budget); }
        [SqlFunction(FillRowMethodName="FillCells",DataAccess=DataAccessKind.None,SystemDataAccess=SystemDataAccessKind.None,
            IsDeterministic=false,IsPrecise=true,
            TableDefinition="ErrorNumber int, ErrorMessage nvarchar(4000), RowOrdinal int, ColumnOrdinal int, StoredType nvarchar(16), ValuePresent bit, RawValue nvarchar(max), TextValue nvarchar(max), FormulaPresent bit, FormulaText nvarchar(max), FormulaKind nvarchar(16), SharedFormulaIndex int, CachePresent bit, CacheValue nvarchar(max)")]
        public static IEnumerable ReadCells(SqlBytes input, SqlInt32 ordinal, SqlInt64 archive, SqlInt64 part,
            SqlInt64 total, SqlInt32 parts, SqlInt32 sheets, SqlInt32 cells, SqlInt32 strings,
            SqlInt64 text, SqlInt32 depth, SqlDecimal ratio, SqlInt32 budget)
        { return Read(input,ordinal,true,archive,part,total,parts,sheets,cells,strings,text,depth,ratio,budget); }
        private static SqlString Text(string value) { return value==null?SqlString.Null:new SqlString(value); }
        public static void FillSheets(object value,out SqlInt32 error,out SqlString message,
            out SqlInt32 ordinal,out SqlString name,out SqlString visibility,out SqlBoolean date1904)
        {
            var row=(Row)value; error=row.Error.HasValue?new SqlInt32(row.Error.Value):SqlInt32.Null;
            message=Text(row.Message); var sheet=row.Sheet;
            ordinal=sheet==null?SqlInt32.Null:new SqlInt32(sheet.Ordinal);name=Text(sheet==null?null:sheet.Name);
            visibility=Text(sheet==null?null:sheet.Visibility);date1904=sheet==null?SqlBoolean.Null:new SqlBoolean(sheet.Date1904);
        }
        public static void FillCells(object value,out SqlInt32 error,out SqlString message,
            out SqlInt32 rowOrdinal,out SqlInt32 column,out SqlString type,out SqlBoolean present,
            out SqlString raw,out SqlString text,out SqlBoolean formulaPresent,out SqlString formula,
            out SqlString kind,out SqlInt32 shared,out SqlBoolean cachePresent,out SqlString cache)
        {
            var row=(Row)value; error=row.Error.HasValue?new SqlInt32(row.Error.Value):SqlInt32.Null;message=Text(row.Message);
            var c=row.Cell; rowOrdinal=c==null?SqlInt32.Null:new SqlInt32(c.Row);column=c==null?SqlInt32.Null:new SqlInt32(c.Column);
            type=Text(c==null?null:c.StoredType);present=c==null?SqlBoolean.Null:new SqlBoolean(c.ValuePresent);
            raw=Text(c==null?null:c.RawValue);text=Text(c==null?null:c.TextValue);
            formulaPresent=c==null?SqlBoolean.Null:new SqlBoolean(c.FormulaPresent);formula=Text(c==null?null:c.FormulaText);
            kind=Text(c==null?null:c.FormulaKind);shared=c==null || !c.SharedFormulaIndex.HasValue?SqlInt32.Null:new SqlInt32(c.SharedFormulaIndex.Value);
            cachePresent=c==null?SqlBoolean.Null:new SqlBoolean(c.CachePresent);cache=Text(c==null?null:c.CacheValue);
        }
    }
}
