using System;
using System.Data.SqlTypes;
using System.Diagnostics;
using System.Text;
using System.Text.RegularExpressions;
using Microsoft.SqlServer.Server;
using DotNetRegex = System.Text.RegularExpressions.Regex;

namespace Toolbelt.String.Regex
{
    public static partial class RegexProvider
    {
        private const int R2PatternCodeUnits = 8000;
        private const int R2TranslatedCodeUnits = 64000;
        private const int R2MaxGroupDepth = 64;
        private const int R2MaxAlternations = 1024;

        // Der Budgetwächter umfasst Parser, Konstruktor, Suche und Output.
        // CLR-Allokation und Regex-Konstruktor bleiben kooperativ, nicht
        // unterbrechbar. R1b verwendet weiterhin seinen bisherigen Vertrag.
        private sealed class TransformationContext
        {
            internal readonly Stopwatch Clock = Stopwatch.StartNew();
            internal readonly int Limit;
            internal readonly int Budget;
            internal string Pattern;
            internal RegexOptions Options;
            private DotNetRegex regex;
            private int regexTimeout;

            internal TransformationContext(SqlString profile)
            {
                if (profile.IsNull || (profile.Value != "standard" && profile.Value != "large"))
                    throw Error("TBX_REGEX_INVALID_ARGUMENT", "Profile muss standard oder large sein.");
                Limit = profile.Value == "standard" ? 1048576 : 8388608;
                Budget = profile.Value == "standard" ? 500 : 2000;
            }

            internal int Remaining()
            {
                long left = Budget - Clock.ElapsedMilliseconds;
                if (left <= 0)
                    throw Error("TBX_REGEX_TIMEOUT", "Das Gesamtbudget der Transformation wurde überschritten.");
                return (int)left;
            }

            internal void CheckSize(string value, string prefix)
            {
                Remaining();
                if (value.Length > Limit)
                    throw Error(prefix, "Die UTF-16-Größengrenze des Profils wurde überschritten.");
            }

            internal void ValidateFlags(SqlString flags)
            {
                if (flags.IsNull || flags.Value.Length > 4)
                    throw Error("TBX_REGEX_INVALID_FLAGS", "Flags müssen höchstens vier Codeeinheiten enthalten.");
                Options = ParseOptions(flags);
            }

            internal void Initialize(string pattern)
            {
                if (pattern.Length > R2PatternCodeUnits)
                    throw Error("TBX_REGEX_PATTERN_TOO_LARGE", "Pattern darf höchstens 8000 UTF-16-Codeeinheiten enthalten.");
                CheckComplexity(pattern);
                Pattern = TranslatePattern(pattern,
                    (Options & RegexOptions.Multiline) != 0,
                    (Options & RegexOptions.IgnoreCase) != 0);
                if (Pattern.Length > R2TranslatedCodeUnits)
                    throw Error("TBX_REGEX_PATTERN_TOO_LARGE", "Das übersetzte Pattern ist zu groß.");
                regexTimeout = Math.Min(250, Remaining());
                regex = Construct(regexTimeout);
            }

            private DotNetRegex Construct(int milliseconds)
            {
                Remaining();
                try
                {
                    var result = new DotNetRegex(Pattern, Options, TimeSpan.FromMilliseconds(milliseconds));
                    Remaining();
                    return result;
                }
                catch (ArgumentException)
                {
                    throw Error("TBX_REGEX_INVALID_PATTERN", "Pattern ist im Toolbelt-Dialekt ungültig.");
                }
            }

            internal Match Search(string input, int cursor)
            {
                // .NET bindet den Timeout an die Regexinstanz. Eine Instanz
                // wird wiederverwendet, solange ihre Grenze ins Restbudget
                // passt. Rekonstruktion parst das übersetzte Pattern erneut;
                // halbiertes Restbudget vermeidet Neukonstruktion pro Treffer.
                // Match(input,cursor) erhält den ganzen Input für korrekte Anker.
                while (regexTimeout > Remaining())
                {
                    regexTimeout = Math.Max(1, Remaining() / 2);
                    regex = Construct(regexTimeout);
                }
                try
                {
                    Match match = regex.Match(input, cursor);
                    Remaining();
                    return match;
                }
                catch (RegexMatchTimeoutException)
                {
                    throw Error("TBX_REGEX_TIMEOUT", "Die Suchschrittgrenze wurde überschritten.");
                }
            }

            internal void Append(StringBuilder builder, string text, int start, int length)
            {
                Remaining();
                if (checked((long)builder.Length + length) > Limit)
                    throw Error("TBX_REGEX_OUTPUT_TOO_LARGE", "Das Ergebnis überschreitet die Profilgrenze.");
                builder.Append(text, start, length);
                Remaining();
            }
        }

        // Die Zusatzprüfung schützt den R2a-Konstruktor vor übermäßiger
        // Verschachtelung/Alternation. Die eigentliche Grammatikprüfung bleibt
        // ausschließlich im kanonischen R1b-Parser; Escapes/Klassen zählen
        // nicht versehentlich als strukturelle Gruppen oder Alternationen.
        private static void CheckComplexity(string pattern)
        {
            int depth = 0, alternatives = 0;
            bool escaped = false, inClass = false;
            foreach (char token in pattern)
            {
                if (escaped) { escaped = false; continue; }
                if (token == '\\') { escaped = true; continue; }
                if (inClass) { if (token == ']') inClass = false; continue; }
                if (token == '[') { inClass = true; continue; }
                if (token == '(' && ++depth > R2MaxGroupDepth)
                    throw Error("TBX_REGEX_PATTERN_TOO_COMPLEX", "Gruppenverschachtelung überschreitet 64.");
                if (token == ')') depth--;
                if (token == '|' && ++alternatives > R2MaxAlternations)
                    throw Error("TBX_REGEX_PATTERN_TOO_COMPLEX", "Alternationsanzahl überschreitet 1024.");
            }
        }

        private static void ValidateTransformationArguments(SqlInt32 start, SqlInt32 occurrence, bool replace)
        {
            if (start.IsNull || start.Value < 1 || occurrence.IsNull || occurrence.Value < (replace ? 0 : 1))
                throw Error("TBX_REGEX_INVALID_ARGUMENT", "Start oder Occurrence ist ungültig.");
        }

        [SqlFunction(DataAccess = DataAccessKind.None, SystemDataAccess = SystemDataAccessKind.None,
            IsDeterministic = false, IsPrecise = true)]
        public static SqlString RegexSubstring(SqlString input, SqlString pattern, SqlInt32 start,
            SqlInt32 occurrence, SqlString flags, SqlString profile)
        {
            if (input.IsNull || pattern.IsNull) return SqlString.Null;
            var context = new TransformationContext(profile);
            ValidateTransformationArguments(start, occurrence, false);
            context.ValidateFlags(flags);
            string value = input.Value;
            context.CheckSize(value, "TBX_REGEX_INPUT_TOO_LARGE");
            context.Initialize(pattern.Value);
            int cursor = start.Value - 1;
            if (cursor > value.Length) return SqlString.Null;
            int ordinal = 0;
            while (cursor <= value.Length)
            {
                Match match = context.Search(value, cursor);
                if (!match.Success) break;
                if (++ordinal == occurrence.Value)
                {
                    var result = new StringBuilder();
                    context.Append(result, value, match.Index, match.Length);
                    string output = result.ToString();
                    context.Remaining();
                    return new SqlString(output);
                }
                cursor = match.Index + match.Length + (match.Length == 0 ? 1 : 0);
            }
            context.Remaining();
            return SqlString.Null;
        }

        [SqlFunction(DataAccess = DataAccessKind.None, SystemDataAccess = SystemDataAccessKind.None,
            IsDeterministic = false, IsPrecise = true)]
        public static SqlString RegexReplace(SqlString input, SqlString pattern, SqlString replacement,
            SqlInt32 start, SqlInt32 occurrence, SqlString flags, SqlString profile)
        {
            if (input.IsNull || pattern.IsNull || replacement.IsNull) return SqlString.Null;
            var context = new TransformationContext(profile);
            ValidateTransformationArguments(start, occurrence, true);
            context.ValidateFlags(flags);
            string value = input.Value, literal = replacement.Value;
            context.CheckSize(value, "TBX_REGEX_INPUT_TOO_LARGE");
            context.CheckSize(literal, "TBX_REGEX_REPLACEMENT_TOO_LARGE");
            context.Initialize(pattern.Value);
            int cursor = start.Value - 1;
            if (cursor > value.Length) return input;
            var result = new StringBuilder();
            int copied = 0, ordinal = 0;
            while (cursor <= value.Length)
            {
                Match match = context.Search(value, cursor);
                if (!match.Success) break;
                ordinal++;
                if (occurrence.Value == 0 || ordinal == occurrence.Value)
                {
                    context.Append(result, value, copied, match.Index - copied);
                    context.Append(result, literal, 0, literal.Length);
                    copied = match.Index + match.Length;
                    if (occurrence.Value != 0) break;
                }
                cursor = match.Index + match.Length + (match.Length == 0 ? 1 : 0);
            }
            context.Append(result, value, copied, value.Length - copied);
            string output = result.ToString();
            context.Remaining();
            return new SqlString(output);
        }
    }
}
