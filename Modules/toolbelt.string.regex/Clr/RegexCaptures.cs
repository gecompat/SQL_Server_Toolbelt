using System;
using System.Collections;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;
using Microsoft.SqlServer.Server;

namespace Toolbelt.String.Regex
{
    public static partial class RegexProvider
    {
        // Zusatzinformationen entstehen im selben iterativen Dialektparser.
        // Die Grenze betrifft nur erfolgreiche Pfade, nicht Heap/Backtracking.
        private sealed class CaptureDeclaration
        {
            internal int Ordinal;
            internal string Name, EngineName;
            internal bool Named;
        }

        private struct CaptureSummary
        {
            internal long Minimum, History;
            internal CaptureSummary(long minimum, long history)
            { Minimum = minimum; History = history; }
        }

        private sealed class CapturePlan
        {
            internal readonly int InputLength;
            internal readonly List<CaptureDeclaration> Groups = new List<CaptureDeclaration>();
            private readonly List<string> names = new List<string>();
            internal bool NullableHistory;
            internal CapturePlan(int inputLength) { InputLength = inputLength; }
            internal long HistoryAdd(long a, long b) { return Math.Min(100001L, a + b); }
            internal long MinimumAdd(long a, long b) { return Math.Min((long)InputLength + 1, a + b); }
            internal CaptureDeclaration Declare(string pattern, ref int index)
            {
                string name = null;
                if (index + 1 < pattern.Length && pattern[index + 1] == '?')
                {
                    int cursor = index + 2;
                    if (cursor >= pattern.Length || pattern[cursor++] != '<') throw InvalidPattern();
                    int begin = cursor;
                    if (cursor >= pattern.Length || !NameStart(pattern[cursor])) throw InvalidPattern();
                    cursor++;
                    while (cursor < pattern.Length && NamePart(pattern[cursor])) cursor++;
                    if (cursor >= pattern.Length || pattern[cursor] != '>' || cursor - begin > 128)
                        throw InvalidPattern();
                    name = pattern.Substring(begin, cursor - begin);
                    foreach (string existing in names)
                        if (string.Equals(existing, name, StringComparison.OrdinalIgnoreCase)) throw InvalidPattern();
                    names.Add(name);
                    index = cursor;
                }
                if (Groups.Count == 64)
                    throw Error("TBX_REGEX_PATTERN_TOO_COMPLEX", "Höchstens 64 Capturegruppen sind erlaubt.");
                int ordinal = Groups.Count + 1;
                string number = ordinal.ToString(CultureInfo.InvariantCulture);
                var declaration = new CaptureDeclaration {
                    Ordinal = ordinal, Name = name ?? number, Named = name != null,
                    EngineName = "tbx" + number };
                Groups.Add(declaration);
                return declaration;
            }
            internal void ValidateHistory(CaptureSummary summary)
            {
                if (NullableHistory || summary.History > 100000)
                    throw Error("TBX_REGEX_CAPTURE_HISTORY_LIMIT", "Die konservative Capture-History-Grenze wurde überschritten.");
            }
        }

        private static bool NameStart(char c)
        { return c == '_' || c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z'; }
        private static bool NamePart(char c) { return NameStart(c) || c >= '0' && c <= '9'; }

        private sealed class CaptureFrame
        {
            private readonly CapturePlan plan;
            private CaptureSummary accumulated, last, alternative;
            private bool hasLast, hasAlternative;
            internal CaptureFrame(CapturePlan plan) { this.plan = plan; }
            internal void Add(CaptureSummary summary)
            {
                Flush(); last = summary; hasLast = true;
            }
            private void Flush()
            {
                if (!hasLast) return;
                accumulated.Minimum = plan.MinimumAdd(accumulated.Minimum, last.Minimum);
                accumulated.History = plan.HistoryAdd(accumulated.History, last.History);
                hasLast = false;
            }
            internal void Quantify(int lower, int upper)
            {
                long count;
                if (last.Minimum > 0)
                {
                    count = plan.InputLength / last.Minimum;
                    if (upper >= 0) count = Math.Min(count, upper);
                }
                else if (upper >= 0) count = upper;
                else
                {
                    if (last.History > 0) plan.NullableHistory = true;
                    count = 0;
                }
                last = new CaptureSummary(
                    Math.Min((long)plan.InputLength + 1, last.Minimum * lower),
                    Math.Min(100001L, last.History * count));
            }
            internal void Alternate()
            {
                Flush();
                if (!hasAlternative) { alternative = accumulated; hasAlternative = true; }
                else alternative = new CaptureSummary(Math.Min(alternative.Minimum, accumulated.Minimum),
                    Math.Max(alternative.History, accumulated.History));
                accumulated = new CaptureSummary();
            }
            internal CaptureSummary Finish()
            {
                Alternate(); return alternative;
            }
        }

        private sealed class CaptureRow
        {
            internal long MatchOrdinal, CaptureOrdinal;
            internal CaptureDeclaration Group;
            internal bool Matched;
            internal int Position, Length;
            internal string Value;
        }

        [SqlFunction(DataAccess = DataAccessKind.None, SystemDataAccess = SystemDataAccessKind.None,
            IsDeterministic = false, IsPrecise = true, FillRowMethodName = "FillCaptureRow",
            TableDefinition = "MatchOrdinal bigint, GroupOrdinal int, CaptureOrdinal bigint, GroupName nvarchar(128), Matched bit, StartPosition bigint, Length bigint, Value nvarchar(max)")]
        public static IEnumerable RegexCaptures(SqlString input, SqlString pattern, SqlInt32 start,
            SqlString flags, SqlString profile, SqlInt32 maxRows)
        {
            var rows = new List<CaptureRow>();
            if (input.IsNull || pattern.IsNull) return rows;
            var context = new TransformationContext(profile);
            if (start.IsNull || start.Value < 1 || maxRows.IsNull || maxRows.Value < 1 || maxRows.Value > 100000)
                throw Error("TBX_REGEX_INVALID_ARGUMENT", "Start oder MaxRows ist ungültig.");
            context.ValidateFlags(flags);
            string value = input.Value;
            context.CheckSize(value, "TBX_REGEX_INPUT_TOO_LARGE");
            CapturePlan plan = context.InitializeCaptures(pattern.Value, value.Length);
            int cursor = start.Value - 1;
            long ordinal = 0, charged = 0;
            if (plan.Groups.Count == 0) { context.Remaining(); return rows; }
            while (cursor <= value.Length)
            {
                Match match = context.Search(value, cursor);
                if (!match.Success) break;
                ordinal++;
                foreach (CaptureDeclaration declaration in plan.Groups)
                {
                    Group group = match.Groups[declaration.EngineName];
                    if (group.Captures.Count == 0)
                        AddCaptureRow(rows, context, maxRows.Value, ref charged, ordinal, declaration, 0, null);
                    else for (int index = 0; index < group.Captures.Count; index++)
                        AddCaptureRow(rows, context, maxRows.Value, ref charged, ordinal, declaration, index + 1, group.Captures[index]);
                }
                cursor = match.Index + match.Length + (match.Length == 0 ? 1 : 0);
            }
            context.Remaining();
            return rows;
        }

        private static void AddCaptureRow(List<CaptureRow> rows, TransformationContext context,
            int maxRows, ref long charged, long matchOrdinal, CaptureDeclaration declaration,
            long captureOrdinal, Capture capture)
        {
            context.Remaining();
            if (rows.Count >= maxRows)
                throw Error("TBX_REGEX_TOO_MANY_ROWS", "MaxRows wurde überschritten.");
            long next = charged + declaration.Name.Length + (capture == null ? 0 : capture.Length);
            if (next > context.Limit)
                throw Error("TBX_REGEX_OUTPUT_TOO_LARGE", "Capturetexte überschreiten die Profilgrenze.");
            charged = next;
            rows.Add(new CaptureRow { MatchOrdinal = matchOrdinal, Group = declaration,
                CaptureOrdinal = captureOrdinal, Matched = capture != null,
                Position = capture == null ? 0 : capture.Index + 1,
                Length = capture == null ? 0 : capture.Length,
                Value = capture == null ? null : capture.Value });
            context.Remaining();
        }

        public static void FillCaptureRow(object row, out SqlInt64 matchOrdinal, out SqlInt32 groupOrdinal,
            out SqlInt64 captureOrdinal, out SqlString groupName, out SqlBoolean matched,
            out SqlInt64 startPosition, out SqlInt64 length, out SqlString value)
        {
            var capture = (CaptureRow)row;
            matchOrdinal = new SqlInt64(capture.MatchOrdinal);
            groupOrdinal = new SqlInt32(capture.Group.Ordinal);
            captureOrdinal = new SqlInt64(capture.CaptureOrdinal);
            groupName = new SqlString(capture.Group.Name);
            matched = new SqlBoolean(capture.Matched);
            startPosition = capture.Matched ? new SqlInt64(capture.Position) : SqlInt64.Null;
            length = capture.Matched ? new SqlInt64(capture.Length) : SqlInt64.Null;
            value = capture.Matched ? new SqlString(capture.Value) : SqlString.Null;
        }

        private sealed class ReplacementPart
        {
            internal string Literal;
            internal CaptureDeclaration Group;
        }
        private static InvalidOperationException InvalidReplacement()
        { return Error("TBX_REGEX_INVALID_REPLACEMENT", "Replacement ist ungültig oder verweist auf eine unbekannte Gruppe."); }

        private static List<ReplacementPart> ParseReplacement(string text, CapturePlan plan)
        {
            var result = new List<ReplacementPart>();
            var literal = new StringBuilder();
            for (int index = 0; index < text.Length; index++)
            {
                if (text[index] != '$') { literal.Append(text[index]); continue; }
                if (++index >= text.Length) throw InvalidReplacement();
                if (text[index] == '$') { literal.Append('$'); continue; }
                CaptureDeclaration group = null;
                if (text[index] >= '1' && text[index] <= '9')
                {
                    int ordinal = 0;
                    do {
                        int digit = text[index] - '0';
                        if (ordinal > (int.MaxValue - digit) / 10) throw InvalidReplacement();
                        ordinal = ordinal * 10 + digit;
                        index++;
                    } while (index < text.Length && text[index] >= '0' && text[index] <= '9');
                    index--;
                    if (ordinal > plan.Groups.Count) throw InvalidReplacement();
                    group = plan.Groups[ordinal - 1];
                }
                else if (text[index] == '{')
                {
                    int begin = ++index;
                    if (index >= text.Length || !NameStart(text[index])) throw InvalidReplacement();
                    while (index < text.Length && NamePart(text[index])) index++;
                    if (index >= text.Length || text[index] != '}' || index - begin > 128) throw InvalidReplacement();
                    string name = text.Substring(begin, index - begin);
                    foreach (CaptureDeclaration declaration in plan.Groups)
                        if (declaration.Named && declaration.Name == name) { group = declaration; break; }
                    if (group == null) throw InvalidReplacement();
                }
                else throw InvalidReplacement();
                if (literal.Length > 0) { result.Add(new ReplacementPart { Literal = literal.ToString() }); literal.Clear(); }
                result.Add(new ReplacementPart { Group = group });
            }
            if (literal.Length > 0) result.Add(new ReplacementPart { Literal = literal.ToString() });
            return result;
        }

        [SqlFunction(DataAccess = DataAccessKind.None, SystemDataAccess = SystemDataAccessKind.None,
            IsDeterministic = false, IsPrecise = true)]
        public static SqlString RegexReplaceGroups(SqlString input, SqlString pattern, SqlString replacement,
            SqlInt32 start, SqlInt32 occurrence, SqlString flags, SqlString profile)
        {
            if (input.IsNull || pattern.IsNull || replacement.IsNull) return SqlString.Null;
            var context = new TransformationContext(profile);
            ValidateTransformationArguments(start, occurrence, true);
            context.ValidateFlags(flags);
            string value = input.Value;
            context.CheckSize(value, "TBX_REGEX_INPUT_TOO_LARGE");
            context.CheckSize(replacement.Value, "TBX_REGEX_REPLACEMENT_TOO_LARGE");
            CapturePlan plan = context.InitializeCaptures(pattern.Value, value.Length);
            List<ReplacementPart> parts = ParseReplacement(replacement.Value, plan);
            context.Remaining();
            int cursor = start.Value - 1;
            if (cursor > value.Length) return input;
            var output = new StringBuilder();
            int copied = 0, ordinal = 0;
            while (cursor <= value.Length)
            {
                Match match = context.Search(value, cursor);
                if (!match.Success) break;
                ordinal++;
                if (occurrence.Value == 0 || ordinal == occurrence.Value)
                {
                    context.Append(output, value, copied, match.Index - copied);
                    foreach (ReplacementPart part in parts)
                    {
                        if (part.Group == null) context.Append(output, part.Literal, 0, part.Literal.Length);
                        else
                        {
                            Group group = match.Groups[part.Group.EngineName];
                            context.Append(output, value, group.Success ? group.Index : 0, group.Success ? group.Length : 0);
                        }
                    }
                    copied = match.Index + match.Length;
                    if (occurrence.Value != 0) break;
                }
                cursor = match.Index + match.Length + (match.Length == 0 ? 1 : 0);
            }
            context.Append(output, value, copied, value.Length - copied);
            string result = output.ToString();
            context.Remaining();
            return new SqlString(result);
        }
    }
}
