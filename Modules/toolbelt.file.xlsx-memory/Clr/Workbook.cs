using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Xml;
using Toolbelt.Archive.ZipMemory;

namespace Toolbelt.Xlsx.Qualification
{
    /// <summary>
    /// Begrenzter XLSX-Readerkern; öffentliche SQL-Aufrufe erfolgen über Status-TVFs.
    /// ZIP wird ausschließlich durch die versionierte kanonische Assembly gelesen.
    /// Pro Aufruf lokale Daten, XmlResolver=null, DTD-Verbot und kooperatives Budget.
    /// </summary>
    public sealed class Workbook
    {
        public const string Spreadsheet = "http://schemas.openxmlformats.org/spreadsheetml/2006/main";
        private const string Relations = "http://schemas.openxmlformats.org/package/2006/relationships";
        private const string OfficeRelations = "http://schemas.openxmlformats.org/officeDocument/2006/relationships";
        private readonly ZipEntryProvider.ArchiveSession archive;
        private readonly Stopwatch clock = Stopwatch.StartNew();
        private readonly Dictionary<string, byte[]> parts = new Dictionary<string, byte[]>(StringComparer.Ordinal);
        private readonly Dictionary<string, string> contentTypes = new Dictionary<string, string>(StringComparer.Ordinal);
        private readonly List<Sheet> sheets = new List<Sheet>();
        private readonly Limits limits;
        private long materializedBytes;
        private long decodedBytes;
        private readonly string workbookPart;
        private readonly Dictionary<string, string> workbookRelations;
        public bool Date1904 { get; private set; }

        public sealed class Limits
        {
            public long ArchiveBytes = 16777216, PartBytes = 16777216, TotalBytes = 67108864;
            public int Parts = 256, Sheets = 32, Cells = 100000, Strings = 50000, Depth = 64;
            public long StringBytes = 8388608, AllocationBytes = 134217728;
            public int BudgetMilliseconds = 5000;
            public decimal Ratio = 200;
            public void Validate()
            {
                if (ArchiveBytes < 1 || ArchiveBytes > 16777216 || PartBytes < 1 || PartBytes > 16777216 ||
                    TotalBytes < 1 || TotalBytes > 67108864 || Parts < 1 || Parts > 256 || Sheets < 1 || Sheets > 32 ||
                    Cells < 1 || Cells > 100000 || Strings < 1 || Strings > 50000 || Depth < 1 || Depth > 64 ||
                    StringBytes < 1 || StringBytes > 8388608 || AllocationBytes < 1 || AllocationBytes > 134217728 ||
                    BudgetMilliseconds < 1 || BudgetMilliseconds > 5000 || Ratio < 1 || Ratio > 200)
                    Fail("LIMIT_CONFIG");
            }
        }
        public sealed class Sheet
        {
            public int Ordinal;
            public string Name, Visibility, Part;
            public bool Date1904;
        }
        public sealed class Cell
        {
            public int Row, Column;
            public string StoredType, RawValue, TextValue, FormulaText, FormulaKind, CacheValue;
            public bool ValuePresent, FormulaPresent, CachePresent;
            public int? SharedFormulaIndex;
        }

        public Workbook(byte[] binary, Limits limits)
        {
            this.limits = limits ?? new Limits(); this.limits.Validate();
            if (binary == null) Fail("INPUT_NULL_INTERNAL");
            // Das Input wird nicht kopiert. Part-Output, ToArray-Kopie, XML-/String-
            // Aufwand werden konservativ gezählt; dies ist keine totale Peakmessung.
            Charge(binary.LongLength);
            archive = new ZipEntryProvider.ArchiveSession(new MemoryStream(binary, false), binary.LongLength,
                this.limits.ArchiveBytes, this.limits.Parts, this.limits.PartBytes,
                this.limits.TotalBytes, this.limits.Ratio, Check);
            foreach (string name in archive.PartNames)
            {
                CanonicalPart(name);
                if (name.EndsWith(".rels", StringComparison.Ordinal)) ReadRelations(name, SourceOfRelationships(name));
            }
            var root = ReadRelations("_rels/.rels", "");
            string main = null;
            foreach (var pair in root)
                if (pair.Key.EndsWith("\u0001officeDocument", StringComparison.Ordinal))
                { if (main != null) Fail("WORKBOOK_RELATION_DUPLICATE"); main = pair.Value; }
            if (main == null) Fail("WORKBOOK_RELATION_MISSING");
            workbookPart = main;
            ValidateContentTypes();
            RequireContentType(main, "sheet.main");
            workbookRelations = ReadRelations(RelationshipPart(main), main);
            ReadWorkbook();
        }

        public long CountedAllocationBytes { get { return charged; } }
        public void Checkpoint() { Check(); }
        public Sheet[] ListSheets()
        {
            Check();
            foreach (var sheet in sheets) { OutputCharge(sheet.Name); OutputCharge(sheet.Visibility); }
            Charge((long)sheets.Count * 16); Check(); return sheets.ToArray();
        }

        public Cell[] ReadCells(int sheetOrdinal)
        {
            if (sheetOrdinal < 1 || sheetOrdinal > sheets.Count) Fail("SHEET_ORDINAL");
            var strings = ReadStrings();
            var cells = new List<Cell>();
            var coordinates = new Dictionary<long, bool>();
            using (var reader = OpenXml(sheets[sheetOrdinal - 1].Part))
            {
                bool rootSeen = false, inSheetData = false, sheetDataSeen = false; int row = 0;
                RequireContentType(sheets[sheetOrdinal - 1].Part, "worksheet");
                while (Read(reader))
                {
                    if (reader.NodeType == XmlNodeType.EndElement && reader.LocalName == "row" && reader.NamespaceURI == Spreadsheet) row = 0;
                    if (reader.NodeType == XmlNodeType.EndElement && reader.LocalName == "sheetData" && reader.NamespaceURI == Spreadsheet && reader.Depth == 1) inSheetData = false;
                    if (reader.NodeType != XmlNodeType.Element) continue;
                    if (!rootSeen) { Root(reader, "worksheet", Spreadsheet); rootSeen = true; }
                    if (reader.NamespaceURI != Spreadsheet) continue;
                    if (reader.LocalName == "sheetData")
                    {
                        if (reader.Depth != 1 || sheetDataSeen) Fail("SHEET_DATA_NESTING_INVALID");
                        sheetDataSeen = true; inSheetData = !reader.IsEmptyElement;
                    }
                    if (reader.LocalName == "row")
                    {
                        if (reader.Depth != 2 || !inSheetData) Fail("ROW_NESTING_INVALID");
                        row = Positive(reader.GetAttribute("r"), 1048576, "ROW_REFERENCE");
                        if (reader.IsEmptyElement) row = 0;
                    }
                    if (reader.LocalName != "c") continue;
                    if (reader.Depth != 3 || row == 0) Fail("CELL_NESTING_INVALID");
                    if (cells.Count >= limits.Cells) Fail("CELL_LIMIT");
                    var cell = ReadCell(reader, row, strings);
                    long key = ((long)cell.Row << 32) | (uint)cell.Column;
                    if (coordinates.ContainsKey(key)) Fail("CELL_DUPLICATE");
                    coordinates.Add(key, true); cells.Add(cell); Charge(128);
                }
                if (!rootSeen || !sheetDataSeen) Fail("WORKSHEET_EMPTY");
            }
            cells.Sort((a,b) => a.Row == b.Row ? a.Column.CompareTo(b.Column) : a.Row.CompareTo(b.Row));
            Charge((long)cells.Count * 16); Check(); return cells.ToArray();
        }

        private Cell ReadCell(XmlReader reader, int row, List<string> strings)
        {
            string reference = reader.GetAttribute("r"); int column, ownRow; Coordinate(reference, out ownRow, out column);
            if (row != ownRow) Fail("CELL_ROW_MISMATCH");
            string type = reader.GetAttribute("t") ?? "n";
            if (type != "n" && type != "s" && type != "inlineStr" && type != "str" && type != "b" && type != "e" && type != "d")
                Fail("CELL_TYPE_UNSUPPORTED");
            var cell = new Cell { Row = row, Column = column, StoredType = type };
            int depth = reader.Depth;
            if (!reader.IsEmptyElement)
                while (Read(reader) && !(reader.NodeType == XmlNodeType.EndElement && reader.Depth == depth))
                {
                    if (reader.NodeType != XmlNodeType.Element) continue;
                    if (reader.NamespaceURI != Spreadsheet) Fail("CELL_CONTENT_UNSUPPORTED");
                    if (reader.LocalName == "v" && reader.Depth == depth + 1)
                    { if (cell.ValuePresent) Fail("VALUE_DUPLICATE"); cell.ValuePresent = true; cell.RawValue = Text(reader); }
                    else if (reader.LocalName == "f" && reader.Depth == depth + 1)
                    {
                        if (cell.FormulaPresent) Fail("FORMULA_DUPLICATE"); cell.FormulaPresent = true;
                        cell.FormulaKind = reader.GetAttribute("t") ?? "normal";
                        if (cell.FormulaKind != "normal" && cell.FormulaKind != "shared" && cell.FormulaKind != "array" && cell.FormulaKind != "dataTable")
                            Fail("FORMULA_KIND_UNSUPPORTED");
                        string index = reader.GetAttribute("si");
                        if (index != null) cell.SharedFormulaIndex = Nonnegative(index, Int32.MaxValue, "FORMULA_SHARED_INDEX");
                        if (cell.FormulaKind == "shared" && index == null) Fail("FORMULA_SHARED_INDEX");
                        cell.FormulaText = Text(reader);
                    }
                    else if (reader.LocalName == "is" && reader.Depth == depth + 1)
                    { if (cell.TextValue != null || type != "inlineStr") Fail("INLINE_STRING_INVALID"); cell.TextValue = RichText(reader); }
                    else Fail("CELL_CONTENT_UNSUPPORTED");
                }
            if (type == "s")
            {
                if (!cell.ValuePresent) Fail("SHARED_STRING_REFERENCE");
                int i = Nonnegative(cell.RawValue, Int32.MaxValue, "SHARED_STRING_REFERENCE");
                if (i >= strings.Count) Fail("SHARED_STRING_REFERENCE"); cell.TextValue = strings[i];
            }
            else if (type == "str" && cell.ValuePresent) cell.TextValue = cell.RawValue;
            if (type == "inlineStr" && cell.ValuePresent) Fail("INLINE_STRING_INVALID");
            if (type == "b" && cell.ValuePresent && cell.RawValue != "" && cell.RawValue != "0" && cell.RawValue != "1") Fail("BOOLEAN_VALUE_INVALID");
            if (cell.FormulaPresent) { cell.CachePresent = cell.ValuePresent; cell.CacheValue = cell.RawValue; }
            // SQL-Ausgabe materialisiert jede Feldinstanz. Derselbe Shared String
            // darf daher nicht nur einmal gezählt werden; wiederholte Referenzen
            // und gleichwertige Raw-/Cachefelder belasten jeweils das Chargebudget.
            OutputCharge(cell.StoredType); OutputCharge(cell.RawValue); OutputCharge(cell.TextValue);
            OutputCharge(cell.FormulaText); OutputCharge(cell.FormulaKind); OutputCharge(cell.CacheValue);
            return cell;
        }

        private List<string> ReadStrings()
        {
            string part = null;
            foreach (var pair in workbookRelations)
                if (pair.Key.EndsWith("\u0001sharedStrings", StringComparison.Ordinal))
                { if (part != null) Fail("SHARED_STRINGS_DUPLICATE"); part = pair.Value; }
            var result = new List<string>(); if (part == null) return result;
            RequireContentType(part, "sharedStrings");
            using (var reader = OpenXml(part))
            {
                bool rootSeen = false;
                while (Read(reader))
                {
                    if (reader.NodeType != XmlNodeType.Element) continue;
                    if (!rootSeen) { Root(reader, "sst", Spreadsheet); rootSeen = true; }
                    if (reader.LocalName == "si" && reader.NamespaceURI == Spreadsheet)
                    {
                        if (reader.Depth != 1) Fail("SHARED_STRING_NESTING_INVALID");
                        if (result.Count >= limits.Strings) Fail("SHARED_STRING_COUNT_LIMIT");
                        string value = RichText(reader); decodedBytes += (long)value.Length * 2;
                        if (decodedBytes > limits.StringBytes) Fail("SHARED_STRING_TEXT_LIMIT"); result.Add(value);
                    }
                }
                if (!rootSeen) Fail("SHARED_STRINGS_EMPTY");
            }
            return result;
        }

        private void ReadWorkbook()
        {
            var names = new Dictionary<string, bool>(StringComparer.Ordinal);
            using (var reader = OpenXml(workbookPart))
            {
                bool rootSeen = false, inSheets = false, sheetsSeen = false, propertiesSeen = false;
                while (Read(reader))
                {
                    if (reader.NodeType == XmlNodeType.EndElement && reader.LocalName == "sheets" && reader.NamespaceURI == Spreadsheet && reader.Depth == 1) inSheets = false;
                    if (reader.NodeType != XmlNodeType.Element) continue;
                    if (!rootSeen) { Root(reader, "workbook", Spreadsheet); rootSeen = true; }
                    if (reader.NamespaceURI != Spreadsheet) continue;
                    if (reader.LocalName == "sheets")
                    {
                        if (reader.Depth != 1 || sheetsSeen) Fail("SHEETS_NESTING_INVALID");
                        sheetsSeen = true; inSheets = !reader.IsEmptyElement;
                    }
                    if (reader.LocalName == "workbookPr")
                    {
                        if (reader.Depth != 1 || propertiesSeen) Fail("WORKBOOK_PROPERTIES_INVALID");
                        propertiesSeen = true;
                        string date = reader.GetAttribute("date1904");
                        if (date != null && date != "0" && date != "1" && date != "false" && date != "true") Fail("DATE1904_INVALID");
                        Date1904 = date == "1" || date == "true";
                    }
                    if (reader.LocalName != "sheet") continue;
                    if (reader.Depth != 2 || !inSheets) Fail("SHEET_NESTING_INVALID");
                    if (sheets.Count >= limits.Sheets) Fail("SHEET_LIMIT");
                    string name = reader.GetAttribute("name"); string id = reader.GetAttribute("id", OfficeRelations);
                    string state = reader.GetAttribute("state") ?? "visible", part;
                    if (String.IsNullOrEmpty(name) || names.ContainsKey(name)) Fail("SHEET_NAME_INVALID");
                    if (state != "visible" && state != "hidden" && state != "veryHidden") Fail("SHEET_VISIBILITY_INVALID");
                    if (id == null || !workbookRelations.TryGetValue(id + "\u0001worksheet", out part)) Fail("SHEET_RELATION_MISSING");
                    else sheets.Add(new Sheet { Ordinal = sheets.Count + 1, Name = name, Visibility = state, Part = part });
                    names.Add(name, true);
                }
                if (!rootSeen || !sheetsSeen || sheets.Count == 0) Fail("WORKBOOK_EMPTY");
            }
            foreach (var sheet in sheets) sheet.Date1904 = Date1904;
        }

        private Dictionary<string, string> ReadRelations(string part, string source)
        {
            var result = new Dictionary<string, string>(StringComparer.Ordinal);
            var ids = new Dictionary<string, bool>(StringComparer.Ordinal);
            using (var reader = OpenXml(part))
            {
                bool rootSeen = false;
                while (Read(reader))
                {
                    if (reader.NodeType != XmlNodeType.Element) continue;
                    if (!rootSeen) { Root(reader, "Relationships", Relations); rootSeen = true; }
                    if (reader.LocalName != "Relationship" || reader.NamespaceURI != Relations || reader.Depth != 1) continue;
                    string mode = reader.GetAttribute("TargetMode"), id = reader.GetAttribute("Id"), type = reader.GetAttribute("Type"), target = reader.GetAttribute("Target");
                    if (mode != null && mode != "Internal") Fail("EXTERNAL_RELATION_UNSUPPORTED");
                    if (String.IsNullOrEmpty(id) || ids.ContainsKey(id) || type == null || target == null) Fail("RELATION_INVALID");
                    ids.Add(id, true);
                    if (!type.StartsWith(OfficeRelations + "/", StringComparison.Ordinal)) Fail("RELATION_TYPE_UNSUPPORTED");
                    string kind = type.Substring(OfficeRelations.Length + 1);
                    if (kind == "vbaProject" || kind == "externalLink" || kind == "connections" || kind == "control" || kind == "oleObject") Fail("RELATION_TYPE_UNSUPPORTED");
                    string resolved = Resolve(source, target);
                    if (!archive.Contains(resolved)) Fail("RELATION_TARGET_MISSING");
                    result.Add(id + "\u0001" + kind, resolved);
                }
                if (!rootSeen) Fail("RELATION_EMPTY");
            }
            return result;
        }

        private void ValidateContentTypes()
        {
            const string ns = "http://schemas.openxmlformats.org/package/2006/content-types";
            bool rootSeen = false;
            using (var reader = OpenXml("[Content_Types].xml"))
                while (Read(reader))
                {
                    if (reader.NodeType != XmlNodeType.Element) continue;
                    if (!rootSeen) { Root(reader, "Types", ns); rootSeen = true; }
                    if (reader.NamespaceURI != ns || reader.Depth != 1) continue;
                    string type = reader.GetAttribute("ContentType");
                    if (type == null) Fail("CONTENT_TYPE_INVALID");
                    if (reader.LocalName == "Override")
                    {
                        string name = reader.GetAttribute("PartName");
                        if (name == null || !name.StartsWith("/",StringComparison.Ordinal)) Fail("CONTENT_TYPE_INVALID");
                        name = name.Substring(1); CanonicalPart(name);
                        if (contentTypes.ContainsKey(name)) Fail("CONTENT_TYPE_DUPLICATE");
                        contentTypes.Add(name,type);
                    }
                    else if (reader.LocalName != "Default") Fail("CONTENT_TYPE_UNSUPPORTED");
                    if (type.IndexOf("macro", StringComparison.OrdinalIgnoreCase) >= 0 || type.IndexOf("vba", StringComparison.OrdinalIgnoreCase) >= 0 ||
                        type.IndexOf("activeX", StringComparison.OrdinalIgnoreCase) >= 0 || type.IndexOf("externalLink", StringComparison.OrdinalIgnoreCase) >= 0 ||
                        type.IndexOf("connections", StringComparison.OrdinalIgnoreCase) >= 0) Fail("CONTENT_TYPE_UNSUPPORTED");
                }
            if (!rootSeen) Fail("XLSX_CONTENT_TYPE_MISSING");
        }

        private void RequireContentType(string part, string suffix)
        {
            string type;
            if (!contentTypes.TryGetValue(part,out type) || type != "application/vnd.openxmlformats-officedocument.spreadsheetml." + suffix + "+xml")
                Fail("CONTENT_TYPE_MISMATCH");
        }

        private XmlReader OpenXml(string part)
        {
            Check(); byte[] payload;
            if (!parts.TryGetValue(part, out payload))
            {
                payload = archive.ReadPart(part); materializedBytes += payload.LongLength;
                if (materializedBytes > limits.TotalBytes) Fail("PART_SUM_LIMIT");
                Charge(payload.LongLength * 4 + 81920); parts.Add(part, payload);
            }
            var settings = new XmlReaderSettings { DtdProcessing = DtdProcessing.Prohibit, XmlResolver = null,
                MaxCharactersInDocument = limits.PartBytes, MaxCharactersFromEntities = 1,
                IgnoreComments = true, IgnoreProcessingInstructions = true, CloseInput = true };
            return XmlReader.Create(new MemoryStream(payload, false), settings);
        }
        private bool Read(XmlReader reader)
        {
            Check(); bool result = reader.Read(); Check();
            if (result && reader.Depth > limits.Depth) Fail("XML_DEPTH_LIMIT"); return result;
        }
        private string Text(XmlReader reader)
        {
            int depth = reader.Depth; if (reader.IsEmptyElement) return "";
            var value = new StringBuilder();
            while (Read(reader) && !(reader.NodeType == XmlNodeType.EndElement && reader.Depth == depth))
            {
                if (reader.NodeType == XmlNodeType.Element) Fail("TEXT_NESTING_INVALID");
                if (reader.NodeType == XmlNodeType.Text || reader.NodeType == XmlNodeType.CDATA ||
                    reader.NodeType == XmlNodeType.SignificantWhitespace || reader.NodeType == XmlNodeType.Whitespace)
                { Charge((long)reader.Value.Length * 4); value.Append(reader.Value); }
            }
            return value.ToString();
        }
        private string RichText(XmlReader reader)
        {
            int depth = reader.Depth; if (reader.IsEmptyElement) return "";
            var result = new StringBuilder(); int phonetic = -1;
            while (Read(reader) && !(reader.NodeType == XmlNodeType.EndElement && reader.Depth == depth))
            {
                if (reader.NodeType == XmlNodeType.EndElement && reader.Depth == phonetic) phonetic = -1;
                if (reader.NodeType != XmlNodeType.Element || reader.NamespaceURI != Spreadsheet) continue;
                if (reader.LocalName == "rPh" && !reader.IsEmptyElement) phonetic = reader.Depth;
                if (reader.LocalName == "t" && phonetic < 0)
                { string text = Text(reader); Charge((long)text.Length * 4); result.Append(text); }
            }
            return result.ToString();
        }
        private long charged;
        private void OutputCharge(string value) { if (value != null) Charge(checked((long)value.Length * 4)); }
        private void Charge(long bytes) { if (bytes < 0 || bytes > limits.AllocationBytes - charged) Fail("COUNTED_ALLOCATION_LIMIT"); charged += bytes; }
        private void Check() { if (clock.ElapsedMilliseconds >= limits.BudgetMilliseconds) Fail("BUDGET_EXCEEDED"); }
        private static void Fail(string category) { throw new InvalidDataException("TBX_XLSX_" + category); }
        private static void Root(XmlReader r, string name, string ns) { if (r.Depth != 0 || r.LocalName != name || r.NamespaceURI != ns) Fail("XML_ROOT_UNSUPPORTED"); }
        private static int Nonnegative(string text, int max, string error)
        {
            if (String.IsNullOrEmpty(text)) { Fail(error); return 0; }
            long value = 0; foreach (char c in text) { if (c < '0' || c > '9') Fail(error); value = value * 10 + c - '0'; if (value > max) Fail(error); } return (int)value;
        }
        private static int Positive(string text, int max, string error) { int v = Nonnegative(text,max,error); if (v == 0) Fail(error); return v; }
        private static void Coordinate(string text, out int row, out int column)
        {
            column = 0; row = 0; if (String.IsNullOrEmpty(text)) Fail("CELL_REFERENCE"); int i = 0;
            while (i < text.Length && text[i] >= 'A' && text[i] <= 'Z') { column = column * 26 + text[i++] - 'A' + 1; if (column > 16384) Fail("CELL_REFERENCE"); }
            if (i == 0 || i == text.Length) Fail("CELL_REFERENCE"); row = Positive(text.Substring(i),1048576,"CELL_REFERENCE");
        }
        private static void CanonicalPart(string name)
        {
            if (String.IsNullOrEmpty(name) || name[0] == '/' || name.IndexOf('\\') >= 0 || name.IndexOf(':') >= 0 ||
                name.IndexOf('%') >= 0 || name.IndexOf('?') >= 0 || name.IndexOf('#') >= 0) Fail("PART_NAME_UNSUPPORTED");
            foreach (string segment in name.Split('/')) if (segment == "" || segment == "." || segment == "..") Fail("PART_NAME_UNSUPPORTED");
        }
        private static string Resolve(string source, string target)
        {
            if (String.IsNullOrEmpty(target) || target.IndexOf(':') >= 0 || target.IndexOf('\\') >= 0 || target.IndexOf('%') >= 0 || target.IndexOf('?') >= 0 || target.IndexOf('#') >= 0) Fail("RELATION_TARGET_UNSUPPORTED");
            var segments = new List<string>();
            if (!target.StartsWith("/", StringComparison.Ordinal) && source.LastIndexOf('/') >= 0)
                segments.AddRange(source.Substring(0,source.LastIndexOf('/')).Split('/'));
            foreach (string segment in target.TrimStart('/').Split('/'))
            {
                if (segment == "..") { if (segments.Count == 0) Fail("RELATION_TARGET_ESCAPE"); segments.RemoveAt(segments.Count - 1); }
                else if (segment != ".") { if (segment == "") Fail("RELATION_TARGET_UNSUPPORTED"); segments.Add(segment); }
            }
            string result = String.Join("/",segments); CanonicalPart(result); return result;
        }
        private static string RelationshipPart(string source) { int p=source.LastIndexOf('/'); return (p<0?"":source.Substring(0,p+1))+"_rels/"+source.Substring(p+1)+".rels"; }
        private static string SourceOfRelationships(string rel)
        {
            if (rel == "_rels/.rels") return ""; int p=rel.LastIndexOf("/_rels/",StringComparison.Ordinal);
            if (p<0 && rel.StartsWith("_rels/",StringComparison.Ordinal) && rel.EndsWith(".rels",StringComparison.Ordinal))
                return rel.Substring(6,rel.Length-11);
            if (p<0 || !rel.EndsWith(".rels",StringComparison.Ordinal)) { Fail("RELATION_PART_NAME"); return ""; }
            return rel.Substring(0,p+1)+rel.Substring(p+7,rel.Length-p-12);
        }
    }
}
