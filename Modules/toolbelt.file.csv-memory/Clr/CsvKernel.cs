using System;
using System.Collections.Generic;
using System.Data.SqlTypes;

namespace Toolbelt.Csv
{
    // Nur eigene Fachfehler werden intern in Statuscodes übersetzt; technische Exceptions bleiben erhalten.
    internal sealed class CsvFault : Exception
    {
        internal readonly int Code;
        internal CsvFault(int code) : base("CSV_MEMORY_BUSINESS_ERROR") { Code = code; }
    }

    internal sealed class CsvDialect
    {
        internal readonly char Separator;
        internal readonly char[] NullToken;
        internal CsvDialect(char separator, char[] token) { Separator = separator; NullToken = token; }
    }

    internal struct CsvField
    {
        internal char[] Input;
        internal int Start, RawLength, DecodedLength, Column;
        internal long Row;
        internal bool Header, Quoted, IsNull;
    }

    internal sealed class CsvCell
    {
        internal SqlString Kind;
        internal SqlInt64 Row;
        internal SqlInt32 Column, Error;
        internal SqlChars Value;
        internal static CsvCell Failure(int code)
        {
            return new CsvCell { Kind = SqlString.Null, Row = SqlInt64.Null,
                Column = SqlInt32.Null, Value = SqlChars.Null, Error = new SqlInt32(code) };
        }
    }

    internal struct CsvAnalysis
    {
        internal char[] Value;
        internal bool Quoted;
        internal long Bytes;
    }

    internal static class CsvKernel
    {
        internal const long ByteCeiling = 16777216;
        internal static bool IsNull(SqlChars value) { return value == null || value.IsNull; }
        internal static void Limit(long value, long ceiling)
        {
            if (value < 1 || value > ceiling) throw new CsvFault(55303);
        }
        internal static CsvDialect Dialect(SqlChars separator, SqlChars token)
        {
            if (IsNull(separator) || separator.Length != 1) throw new CsvFault(55300);
            char sep = separator[0];
            if (sep == '"' || sep == '\r' || sep == '\n' || sep == '\0' || Char.IsSurrogate(sep))
                throw new CsvFault(55300);
            char[] nullToken = null;
            if (!IsNull(token))
            {
                if (token.Length < 1 || token.Length > 128) throw new CsvFault(55300);
                nullToken = token.Value;
                for (int i = 0; i < nullToken.Length; i++)
                {
                    char c = nullToken[i];
                    if (c == sep || c == '"' || c == '\r' || c == '\n' || c == '\0') throw new CsvFault(55300);
                    if (Char.IsHighSurrogate(c))
                    {
                        if (i + 1 == nullToken.Length || !Char.IsLowSurrogate(nullToken[i + 1])) throw new CsvFault(55300);
                        i++;
                    }
                    else if (Char.IsLowSurrogate(c)) throw new CsvFault(55300);
                }
            }
            return new CsvDialect(sep, nullToken);
        }
        private static bool Equal(char[] input, int start, int length, char[] token)
        {
            if (token == null || length != token.Length) return false;
            for (int i = 0; i < length; i++) if (input[start + i] != token[i]) return false;
            return true;
        }

        // Derselbe Scanner validiert zuerst ohne Wertallokationen und liefert danach Feldbeschreibungen.
        // Quoted/AfterQuote werden rein syntaktisch getrennt; NUL und UTF-16-Codeeinheiten bleiben Wertinhalt.
        internal static IEnumerable<CsvField> Scan(char[] input, CsvDialect dialect, bool hasHeader,
            long maxRows, int maxColumns, long maxCells)
        {
            int position = 0, width = 0;
            long record = 0, cells = 0;
            while (position < input.Length)
            {
                record++;
                bool header = hasHeader && record == 1;
                long row = hasHeader ? record - 1 : record;
                if (!header && row > maxRows) throw new CsvFault(55303);
                int column = 0;
                while (true)
                {
                    bool quoted = position < input.Length && input[position] == '"';
                    int start = position, decoded = 0, end;
                    if (quoted)
                    {
                        position++; start = position;
                        bool closed = false;
                        end = position;
                        while (position < input.Length)
                        {
                            if (input[position] == '"')
                            {
                                if (position + 1 < input.Length && input[position + 1] == '"')
                                { decoded++; position += 2; continue; }
                                end = position++; closed = true; break;
                            }
                            decoded++; position++;
                        }
                        if (!closed) throw new CsvFault(55301);
                        if (position < input.Length && input[position] != dialect.Separator &&
                            input[position] != '\r' && input[position] != '\n') throw new CsvFault(55301);
                    }
                    else
                    {
                        while (position < input.Length && input[position] != dialect.Separator &&
                            input[position] != '\r' && input[position] != '\n')
                        {
                            if (input[position] == '"') throw new CsvFault(55301);
                            position++; decoded++;
                        }
                        end = position;
                    }
                    column++; cells++;
                    if (column > maxColumns || cells > maxCells) throw new CsvFault(55303);
                    yield return new CsvField { Input = input, Start = start, RawLength = end - start,
                        DecodedLength = decoded, Column = column, Row = row, Header = header, Quoted = quoted,
                        IsNull = !header && !quoted && Equal(input, start, end - start, dialect.NullToken) };
                    if (position < input.Length && input[position] == dialect.Separator)
                    { position++; continue; } // Auch EOF nach Separator enthält ein letztes leeres Feld.
                    if (position < input.Length && input[position] == '\r')
                    {
                        if (position + 1 == input.Length || input[position + 1] != '\n') throw new CsvFault(55301);
                        position += 2;
                    }
                    else if (position < input.Length && input[position] == '\n') position++;
                    if (width == 0) width = column;
                    else if (width != column) throw new CsvFault(55302);
                    break;
                }
            }
        }

        internal static CsvCell Decode(CsvField field)
        {
            SqlChars value = SqlChars.Null;
            if (!field.IsNull)
            {
                char[] decoded = new char[field.DecodedLength];
                if (!field.Quoted) Array.Copy(field.Input, field.Start, decoded, 0, decoded.Length);
                else
                {
                    int output = 0, end = field.Start + field.RawLength;
                    for (int i = field.Start; i < end; i++)
                    {
                        decoded[output++] = field.Input[i];
                        if (field.Input[i] == '"') i++;
                    }
                    if (output != decoded.Length) throw new InvalidOperationException("CSV_DECODE_INVARIANT");
                }
                value = new SqlChars(decoded);
            }
            return new CsvCell { Kind = new SqlString(field.Header ? "HEADER" : "DATA"),
                Row = new SqlInt64(field.Row), Column = new SqlInt32(field.Column), Value = value, Error = new SqlInt32(0) };
        }

        // Maß und Ausgabe teilen Quote-/Tokenentscheidung. Vor Value-Kopie zuerst Länge prüfen.
        internal static CsvAnalysis AnalyzeCell(SqlChars value, CsvDialect dialect, bool header)
        {
            if (IsNull(value))
            {
                if (header || dialect.NullToken == null) throw new CsvFault(55307);
                return new CsvAnalysis { Value = dialect.NullToken, Quoted = false, Bytes = dialect.NullToken.Length * 2L };
            }
            if (value.Length > ByteCeiling / 2) throw new CsvFault(55303);
            char[] text = value.Value;
            bool quoted = Equal(text, 0, text.Length, dialect.NullToken);
            long quotes = 0;
            foreach (char c in text)
            {
                if (c == '"') { quotes++; quoted = true; }
                else if (c == dialect.Separator || c == '\r' || c == '\n') quoted = true;
            }
            return new CsvAnalysis { Value = text, Quoted = quoted,
                Bytes = checked(2L * (text.Length + quotes + (quoted ? 2 : 0))) };
        }
        internal static SqlChars Quote(CsvAnalysis analysis, long maxBytes)
        {
            if (analysis.Bytes > maxBytes) throw new InvalidOperationException("CSV_QUOTE_PREVALIDATION_REQUIRED");
            char[] output = new char[checked((int)(analysis.Bytes / 2))];
            int position = 0;
            if (analysis.Quoted) output[position++] = '"';
            foreach (char c in analysis.Value)
            {
                output[position++] = c;
                if (analysis.Quoted && c == '"') output[position++] = '"';
            }
            if (analysis.Quoted) output[position++] = '"';
            if (position != output.Length) throw new InvalidOperationException("CSV_QUOTE_INVARIANT");
            return new SqlChars(output);
        }
    }
}
