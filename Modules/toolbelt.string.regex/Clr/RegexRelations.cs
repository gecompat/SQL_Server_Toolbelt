using System;
using System.Collections;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.Text.RegularExpressions;
using Microsoft.SqlServer.Server;

namespace Toolbelt.String.Regex
{
    public static partial class RegexProvider
    {
        private sealed class RelationRow
        {
            internal long Ordinal;
            internal long StartPosition;
            internal long Length;
            internal string Value;
        }

        // Bewusst kein Iterator/yield: sämtliche Suche, Prüfung und Textkopien
        // erfolgen vor der Rückgabe an den SQL-Enumerator. Fachfehler können
        // deshalb keine verwertbare Teilmenge ausgeben. List<T> ist mscorlib.
        private static IEnumerable BuildRelation(SqlString input, SqlString pattern,
            SqlInt32 start, SqlString flags, SqlString profile, SqlInt32 maxRows, bool split)
        {
            if (input.IsNull || pattern.IsNull) return new RelationRow[0];
            var context = new TransformationContext(profile);
            if (start.IsNull || start.Value < 1 || maxRows.IsNull ||
                maxRows.Value < 1 || maxRows.Value > 100000)
                throw Error("TBX_REGEX_INVALID_ARGUMENT", "Start und MaxRows müssen gültige positive Grenzen sein.");
            context.ValidateFlags(flags);
            string value = input.Value;
            context.CheckSize(value, "TBX_REGEX_INPUT_TOO_LARGE");
            context.Initialize(pattern.Value);
            int searchCursor = start.Value - 1;
            var rows = new List<RelationRow>();
            long textUnits = 0;
            if (searchCursor > value.Length) { context.Remaining(); return rows; }
            int tokenStart = 0;
            while (searchCursor <= value.Length)
            {
                Match match = context.Search(value, searchCursor);
                if (!match.Success) break;
                if (split)
                {
                    AddRelationRow(rows, value, tokenStart, match.Index - tokenStart,
                        maxRows.Value, ref textUnits, context);
                    // Der Tokenanfang folgt nur dem tatsächlich konsumierten
                    // Separator. Bei leerem Match bleibt er am Matchindex;
                    // ausschließlich der SUCHcursor rückt weiter. Kein Zeichen
                    // geht verloren, auch nicht bei terminalen leeren Treffern.
                    tokenStart = match.Index + match.Length;
                }
                else
                    AddRelationRow(rows, value, match.Index, match.Length,
                        maxRows.Value, ref textUnits, context);
                searchCursor = match.Index + match.Length + (match.Length == 0 ? 1 : 0);
            }
            if (split)
                AddRelationRow(rows, value, tokenStart, value.Length - tokenStart,
                    maxRows.Value, ref textUnits, context);
            context.Remaining();
            return rows;
        }

        private static void AddRelationRow(List<RelationRow> rows, string input, int start,
            int length, int maxRows, ref long textUnits, TransformationContext context)
        {
            context.Remaining();
            if (rows.Count >= maxRows)
                throw Error("TBX_REGEX_TOO_MANY_ROWS", "Die MaxRows-Grenze wurde überschritten.");
            textUnits = checked(textUnits + length);
            if (textUnits > context.Limit)
                throw Error("TBX_REGEX_OUTPUT_TOO_LARGE", "Die Ergebnistextsumme überschreitet das Profil.");
            string text = input.Substring(start, length);
            context.Remaining();
            rows.Add(new RelationRow { Ordinal = rows.Count + 1L,
                StartPosition = start + 1L, Length = length, Value = text });
            context.Remaining();
        }

        [SqlFunction(DataAccess = DataAccessKind.None, SystemDataAccess = SystemDataAccessKind.None,
            FillRowMethodName = "FillRelationRow", TableDefinition = "Ordinal bigint, StartPosition bigint, Length bigint, Value nvarchar(max)",
            IsDeterministic = false, IsPrecise = true)]
        public static IEnumerable RegexMatches(SqlString input, SqlString pattern, SqlInt32 start,
            SqlString flags, SqlString profile, SqlInt32 maxRows)
        {
            return BuildRelation(input, pattern, start, flags, profile, maxRows, false);
        }

        [SqlFunction(DataAccess = DataAccessKind.None, SystemDataAccess = SystemDataAccessKind.None,
            FillRowMethodName = "FillRelationRow", TableDefinition = "Ordinal bigint, StartPosition bigint, Length bigint, Value nvarchar(max)",
            IsDeterministic = false, IsPrecise = true)]
        public static IEnumerable RegexSplit(SqlString input, SqlString pattern,
            SqlString flags, SqlString profile, SqlInt32 maxRows)
        {
            return BuildRelation(input, pattern, new SqlInt32(1), flags, profile, maxRows, true);
        }

        public static void FillRelationRow(object row, out SqlInt64 ordinal,
            out SqlInt64 startPosition, out SqlInt64 length, out SqlString value)
        {
            var result = (RelationRow)row;
            ordinal = new SqlInt64(result.Ordinal);
            startPosition = new SqlInt64(result.StartPosition);
            length = new SqlInt64(result.Length);
            value = new SqlString(result.Value);
        }
    }
}
