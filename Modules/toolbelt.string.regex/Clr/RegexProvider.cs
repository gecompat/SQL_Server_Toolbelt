using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlTypes;
using System.Text;
using System.Text.RegularExpressions;
using Microsoft.SqlServer.Server;
using DotNetRegex = System.Text.RegularExpressions.Regex;

namespace Toolbelt.String.Regex
{
    /// <summary>
    /// SAFE SQL CLR provider for the deliberately small Toolbelt regex dialect.
    /// The parser accepts only the documented grammar and translates ASCII
    /// shorthand classes before invoking the .NET Framework regex engine.
    /// </summary>
    public static class RegexProvider
    {
        private const int MaxInputCodeUnits = 1048576;
        private const int MaxPatternBytes = 8000;
        private const int MaxQuantifier = 1000;
        private static readonly TimeSpan MatchTimeout =
            TimeSpan.FromMilliseconds(250);

        [SqlFunction(
            DataAccess = DataAccessKind.None,
            SystemDataAccess = SystemDataAccessKind.None,
            IsDeterministic = false,
            IsPrecise = true)]
        public static SqlBoolean RegexIsMatch(
            SqlString input,
            SqlString pattern,
            SqlString flags)
        {
            if (input.IsNull || pattern.IsNull)
            {
                return SqlBoolean.Null;
            }

            string value = ValidateInput(input.Value);
            DotNetRegex regex = CreateRegex(pattern.Value, flags);
            try
            {
                return new SqlBoolean(regex.IsMatch(value));
            }
            catch (RegexMatchTimeoutException)
            {
                throw Error(
                    "TBX_REGEX_TIMEOUT",
                    "Die feste Ausführungsgrenze von 250 ms wurde überschritten.");
            }
        }

        [SqlFunction(
            DataAccess = DataAccessKind.None,
            SystemDataAccess = SystemDataAccessKind.None,
            IsDeterministic = false,
            IsPrecise = true)]
        public static SqlInt32 RegexInstr(
            SqlString input,
            SqlString pattern,
            SqlInt32 start,
            SqlInt32 occurrence,
            SqlInt32 returnOption,
            SqlString flags)
        {
            if (input.IsNull || pattern.IsNull)
            {
                return SqlInt32.Null;
            }
            if (start.IsNull || start.Value < 1)
            {
                throw Error(
                    "TBX_REGEX_INVALID_ARGUMENT",
                    "Start muss mindestens 1 sein.");
            }
            if (occurrence.IsNull || occurrence.Value < 1)
            {
                throw Error(
                    "TBX_REGEX_INVALID_ARGUMENT",
                    "Occurrence muss mindestens 1 sein.");
            }
            if (returnOption.IsNull ||
                (returnOption.Value != 0 && returnOption.Value != 1))
            {
                throw Error(
                    "TBX_REGEX_INVALID_ARGUMENT",
                    "ReturnOption muss 0 für Start oder 1 für Ende-exklusiv sein.");
            }

            string value = ValidateInput(input.Value);
            if (start.Value > value.Length + 1)
            {
                return new SqlInt32(0);
            }

            DotNetRegex regex = CreateRegex(pattern.Value, flags);
            try
            {
                Match match = regex.Match(value, start.Value - 1);
                int current = 1;
                while (match.Success && current < occurrence.Value)
                {
                    match = match.NextMatch();
                    current++;
                }
                if (!match.Success)
                {
                    return new SqlInt32(0);
                }

                int position = returnOption.Value == 0
                    ? match.Index + 1
                    : match.Index + match.Length + 1;
                return new SqlInt32(position);
            }
            catch (RegexMatchTimeoutException)
            {
                throw Error(
                    "TBX_REGEX_TIMEOUT",
                    "Die feste Ausführungsgrenze von 250 ms wurde überschritten.");
            }
        }

        [SqlFunction(
            DataAccess = DataAccessKind.None,
            SystemDataAccess = SystemDataAccessKind.None,
            IsDeterministic = false,
            IsPrecise = true)]
        public static SqlInt32 RegexCount(
            SqlString input,
            SqlString pattern,
            SqlInt32 start,
            SqlString flags)
        {
            if (input.IsNull || pattern.IsNull)
            {
                return SqlInt32.Null;
            }
            if (start.IsNull || start.Value < 1)
            {
                throw Error(
                    "TBX_REGEX_INVALID_ARGUMENT",
                    "Start muss mindestens 1 sein.");
            }

            string value = ValidateInput(input.Value);
            if (start.Value > value.Length + 1)
            {
                return new SqlInt32(0);
            }

            DotNetRegex regex = CreateRegex(pattern.Value, flags);
            try
            {
                int count = 0;
                Match match = regex.Match(value, start.Value - 1);
                while (match.Success)
                {
                    checked
                    {
                        count++;
                    }
                    match = match.NextMatch();
                }
                return new SqlInt32(count);
            }
            catch (RegexMatchTimeoutException)
            {
                throw Error(
                    "TBX_REGEX_TIMEOUT",
                    "Die feste Ausführungsgrenze von 250 ms wurde überschritten.");
            }
        }

        private static string ValidateInput(string input)
        {
            if (input.Length > MaxInputCodeUnits)
            {
                throw Error(
                    "TBX_REGEX_INPUT_TOO_LARGE",
                    "Input darf höchstens 2 MiB UTF-16-Daten enthalten.");
            }
            return input;
        }

        private static DotNetRegex CreateRegex(string pattern, SqlString flags)
        {
            if (checked(pattern.Length * 2) > MaxPatternBytes)
            {
                throw Error(
                    "TBX_REGEX_PATTERN_TOO_LARGE",
                    "Pattern darf höchstens 8000 UTF-16-Bytes enthalten.");
            }

            RegexOptions options = ParseOptions(flags);
            string translated = TranslatePattern(
                pattern,
                (options & RegexOptions.Multiline) != 0,
                (options & RegexOptions.IgnoreCase) != 0);
            try
            {
                return new DotNetRegex(translated, options, MatchTimeout);
            }
            catch (ArgumentException)
            {
                throw Error(
                    "TBX_REGEX_INVALID_PATTERN",
                    "Pattern ist im Toolbelt-Dialekt ungültig.");
            }
        }

        private static RegexOptions ParseOptions(SqlString flags)
        {
            if (flags.IsNull)
            {
                throw Error(
                    "TBX_REGEX_INVALID_FLAGS",
                    "Flags dürfen nicht NULL sein.");
            }

            bool caseSensitive = false;
            bool ignoreCase = false;
            bool multiline = false;
            bool singleline = false;
            foreach (char flag in flags.Value)
            {
                switch (flag)
                {
                    case 'c':
                        if (caseSensitive) throw DuplicateFlag();
                        caseSensitive = true;
                        break;
                    case 'i':
                        if (ignoreCase) throw DuplicateFlag();
                        ignoreCase = true;
                        break;
                    case 'm':
                        if (multiline) throw DuplicateFlag();
                        multiline = true;
                        break;
                    case 's':
                        if (singleline) throw DuplicateFlag();
                        singleline = true;
                        break;
                    default:
                        throw Error(
                            "TBX_REGEX_INVALID_FLAGS",
                            "Erlaubt sind ausschließlich c, i, m und s.");
                }
            }
            if (caseSensitive && ignoreCase)
            {
                throw Error(
                    "TBX_REGEX_INVALID_FLAGS",
                    "c und i schließen einander aus.");
            }

            RegexOptions options = RegexOptions.CultureInvariant;
            if (ignoreCase) options |= RegexOptions.IgnoreCase;
            if (multiline) options |= RegexOptions.Multiline;
            if (singleline) options |= RegexOptions.Singleline;
            return options;
        }

        private static InvalidOperationException DuplicateFlag()
        {
            return Error(
                "TBX_REGEX_INVALID_FLAGS",
                "Flags dürfen nicht doppelt vorkommen.");
        }

        private static string TranslatePattern(
            string pattern,
            bool multiline,
            bool ignoreCase)
        {
            var output = new StringBuilder(pattern.Length + 16);
            var parentBranches = new Stack<bool>();
            bool branchHasTerm = false;
            bool canQuantify = false;

            for (int index = 0; index < pattern.Length; index++)
            {
                char current = pattern[index];
                switch (current)
                {
                    case '\\':
                        AppendEscape(
                            pattern,
                            ref index,
                            output,
                            false,
                            ignoreCase);
                        branchHasTerm = true;
                        canQuantify = true;
                        break;
                    case '[':
                        AppendCharacterClass(
                            pattern,
                            ref index,
                            output,
                            ignoreCase);
                        branchHasTerm = true;
                        canQuantify = true;
                        break;
                    case '(':
                        parentBranches.Push(branchHasTerm);
                        output.Append("(?:");
                        branchHasTerm = false;
                        canQuantify = false;
                        break;
                    case ')':
                        if (parentBranches.Count == 0 || !branchHasTerm)
                        {
                            throw InvalidPattern();
                        }
                        output.Append(')');
                        parentBranches.Pop();
                        branchHasTerm = true;
                        canQuantify = true;
                        break;
                    case '|':
                        if (!branchHasTerm)
                        {
                            throw InvalidPattern();
                        }
                        output.Append('|');
                        branchHasTerm = false;
                        canQuantify = false;
                        break;
                    case '?':
                    case '*':
                    case '+':
                        if (!canQuantify)
                        {
                            throw InvalidPattern();
                        }
                        output.Append(current);
                        canQuantify = false;
                        break;
                    case '{':
                        if (!canQuantify)
                        {
                            throw InvalidPattern();
                        }
                        AppendBoundedQuantifier(pattern, ref index, output);
                        canQuantify = false;
                        break;
                    case '^':
                        output.Append('^');
                        branchHasTerm = true;
                        canQuantify = false;
                        break;
                    case '$':
                        output.Append(multiline ? "$" : "\\z");
                        branchHasTerm = true;
                        canQuantify = false;
                        break;
                    case '.':
                        output.Append('.');
                        branchHasTerm = true;
                        canQuantify = true;
                        break;
                    case ']':
                    case '}':
                        throw InvalidPattern();
                    default:
                        output.Append(DotNetRegex.Escape(current.ToString()));
                        branchHasTerm = true;
                        canQuantify = true;
                        break;
                }
            }

            if (parentBranches.Count != 0 ||
                (pattern.Length != 0 && !branchHasTerm))
            {
                throw InvalidPattern();
            }
            return output.ToString();
        }

        private static void AppendEscape(
            string pattern,
            ref int index,
            StringBuilder output,
            bool inClass,
            bool ignoreCase)
        {
            if (++index >= pattern.Length)
            {
                throw InvalidPattern();
            }
            char escaped = pattern[index];
            switch (escaped)
            {
                case 'd': output.Append(inClass ? "0-9" : "[0-9]"); return;
                case 's': output.Append(inClass ? "\\x09-\\x0D\\x20" : "[\\x09-\\x0D\\x20]"); return;
                case 'w':
                    if (inClass)
                    {
                        output.Append("A-Za-z0-9_");
                    }
                    else
                    {
                        output.Append(ignoreCase
                            ? "(?-i:[A-Za-z0-9_])"
                            : "[A-Za-z0-9_]");
                    }
                    return;
                case 'p':
                    if (index + 3 >= pattern.Length ||
                        pattern[index + 1] != '{' ||
                        pattern[index + 2] != 'L' ||
                        pattern[index + 3] != '}')
                    {
                        throw InvalidPattern();
                    }
                    output.Append("\\p{L}");
                    index += 3;
                    return;
                case 'n':
                case 'r':
                case 't':
                case 'f':
                    output.Append('\\').Append(escaped);
                    return;
                case '\\':
                case '.':
                case '^':
                case '$':
                case '|':
                case '?':
                case '*':
                case '+':
                case '(':
                case ')':
                case '[':
                case ']':
                case '{':
                case '}':
                case '-':
                    output.Append('\\').Append(escaped);
                    return;
                default:
                    throw InvalidPattern();
            }
        }

        private static void AppendCharacterClass(
            string pattern,
            ref int index,
            StringBuilder output,
            bool ignoreCase)
        {
            int cursor = index + 1;
            bool hasItem = false;
            bool negated = false;
            bool previousWasAsciiShortcut = false;
            var normalContent = new StringBuilder();
            var asciiContent = new StringBuilder();
            if (cursor < pattern.Length && pattern[cursor] == '^')
            {
                negated = true;
                cursor++;
            }

            for (; cursor < pattern.Length; cursor++)
            {
                char current = pattern[cursor];
                if (current == ']')
                {
                    if (!hasItem)
                    {
                        throw InvalidPattern();
                    }
                    AppendTranslatedClass(
                        output,
                        normalContent,
                        asciiContent,
                        negated,
                        ignoreCase);
                    index = cursor;
                    return;
                }
                if (current == '[' || current == '^' && hasItem)
                {
                    throw InvalidPattern();
                }
                if (current == '\\')
                {
                    if (cursor + 1 >= pattern.Length)
                    {
                        throw InvalidPattern();
                    }
                    char escaped = pattern[cursor + 1];
                    bool asciiShortcut =
                        escaped == 'd' || escaped == 's' || escaped == 'w';
                    if (asciiShortcut)
                    {
                        if (normalContent.Length > 0 &&
                            normalContent[normalContent.Length - 1] == '-' ||
                            cursor + 2 < pattern.Length &&
                            pattern[cursor + 2] == '-')
                        {
                            throw InvalidPattern();
                        }
                        AppendEscape(
                            pattern,
                            ref cursor,
                            asciiContent,
                            true,
                            ignoreCase);
                    }
                    else
                    {
                        AppendEscape(
                            pattern,
                            ref cursor,
                            normalContent,
                            true,
                            ignoreCase);
                    }
                    previousWasAsciiShortcut = asciiShortcut;
                }
                else
                {
                    if (current == '-' && previousWasAsciiShortcut)
                    {
                        throw InvalidPattern();
                    }
                    normalContent.Append(current);
                    previousWasAsciiShortcut = false;
                }
                hasItem = true;
            }
            throw InvalidPattern();
        }

        private static void AppendTranslatedClass(
            StringBuilder output,
            StringBuilder normalContent,
            StringBuilder asciiContent,
            bool negated,
            bool ignoreCase)
        {
            string normalBranch = normalContent.Length == 0
                ? null
                : "[" + normalContent + "]";
            string asciiBranch = asciiContent.Length == 0
                ? null
                : "[" + asciiContent + "]";

            if (!ignoreCase || asciiBranch == null)
            {
                output.Append('[');
                if (negated) output.Append('^');
                output.Append(normalContent).Append(asciiContent).Append(']');
                return;
            }

            string asciiExact = "(?-i:" + asciiBranch + ")";
            if (!negated)
            {
                if (normalBranch == null)
                {
                    output.Append(asciiExact);
                }
                else
                {
                    output.Append("(?:")
                        .Append(normalBranch)
                        .Append('|')
                        .Append(asciiExact)
                        .Append(')');
                }
                return;
            }

            output.Append("(?!(?:");
            if (normalBranch != null)
            {
                output.Append(normalBranch).Append('|');
            }
            output.Append(asciiExact).Append("))[\\s\\S]");
        }

        private static void AppendBoundedQuantifier(
            string pattern,
            ref int index,
            StringBuilder output)
        {
            int cursor = index + 1;
            int minimum = ReadNumber(pattern, ref cursor);
            int maximum = minimum;
            bool openMaximum = false;
            if (cursor < pattern.Length && pattern[cursor] == ',')
            {
                cursor++;
                if (cursor < pattern.Length && char.IsDigit(pattern[cursor]))
                {
                    maximum = ReadNumber(pattern, ref cursor);
                }
                else
                {
                    maximum = MaxQuantifier;
                    openMaximum = true;
                }
            }
            if (cursor >= pattern.Length || pattern[cursor] != '}' ||
                minimum > MaxQuantifier || maximum > MaxQuantifier ||
                maximum < minimum)
            {
                throw InvalidPattern();
            }

            output.Append('{').Append(minimum);
            if (maximum != minimum || openMaximum)
            {
                output.Append(',');
                if (!openMaximum)
                {
                    output.Append(maximum);
                }
            }
            output.Append('}');
            index = cursor;
        }

        private static int ReadNumber(string pattern, ref int cursor)
        {
            if (cursor >= pattern.Length || !char.IsDigit(pattern[cursor]))
            {
                throw InvalidPattern();
            }
            int value = 0;
            while (cursor < pattern.Length && char.IsDigit(pattern[cursor]))
            {
                int digit = pattern[cursor] - '0';
                if (value > MaxQuantifier || value > (int.MaxValue - digit) / 10)
                {
                    throw InvalidPattern();
                }
                value = value * 10 + digit;
                cursor++;
            }
            return value;
        }

        private static InvalidOperationException InvalidPattern()
        {
            return Error(
                "TBX_REGEX_INVALID_PATTERN",
                "Pattern ist im Toolbelt-Dialekt ungültig.");
        }

        private static InvalidOperationException Error(
            string code,
            string message)
        {
            return new InvalidOperationException(code + ": " + message);
        }
    }
}
