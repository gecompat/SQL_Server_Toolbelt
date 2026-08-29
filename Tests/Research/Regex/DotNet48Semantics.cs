using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;

internal static class DotNet48Semantics
{
    private sealed class Case
    {
        internal Case(string id, string input, string pattern, string flags,
                      bool like, int start, int end, int count)
        {
            Id = id;
            Input = input;
            Pattern = pattern;
            Flags = flags;
            Like = like;
            Start = start;
            End = end;
            Count = count;
        }

        internal string Id { get; private set; }
        internal string Input { get; private set; }
        internal string Pattern { get; private set; }
        internal string Flags { get; private set; }
        internal bool Like { get; private set; }
        internal int Start { get; private set; }
        internal int End { get; private set; }
        internal int Count { get; private set; }
    }

    private static readonly Case[] Cases =
    {
        new Case("basic", "abc123", "[0-9]+", "c", true, 4, 7, 1),
        new Case("case-sensitive", "AbC", "^abc$", "c", false, 0, 0, 0),
        new Case("case-insensitive", "AbC", "^abc$", "i", true, 1, 4, 1),
        new Case("ascii-word", "é", @"^\w+$", "c", false, 0, 0, 0),
        new Case("unicode-letter", "é", @"^\p{L}+$", "c", true, 1, 2, 1),
        new Case("alternation", "ab", "a|ab", "c", true, 1, 2, 1),
        new Case("greedy", "a1b2b", "a.*b", "c", true, 1, 6, 1),
        new Case("lazy", "a1b2b", "a.*?b", "c", true, 1, 4, 1),
        new Case("dot-no-newline", "a\nb", "a.b", "c", false, 0, 0, 0),
        new Case("dot-singleline", "a\nb", "a.b", "s", true, 1, 4, 1),
        new Case("multiline", "a\nb", "^b$", "m", true, 3, 4, 1),
        new Case("final-newline", "b\n", "b$", "c", false, 0, 0, 0),
        new Case("non-overlap", "aaaa", "aa", "c", true, 1, 3, 2),
        new Case("empty-pattern", "ab", "", "c", true, 1, 1, 3),
        new Case("emoji-position", "a\U0001F600b", "b", "c", true, 4, 5, 1)
    };

    private static RegexOptions ToOptions(string flags, bool ecmaScript)
    {
        RegexOptions options = ecmaScript
            ? RegexOptions.ECMAScript
            : RegexOptions.CultureInvariant;
        if (flags.IndexOf('i') >= 0)
        {
            options |= RegexOptions.IgnoreCase;
        }
        if (flags.IndexOf('m') >= 0)
        {
            options |= RegexOptions.Multiline;
        }
        if (flags.IndexOf('s') >= 0)
        {
            options |= RegexOptions.Singleline;
        }
        return options;
    }

    private static string[] FindMismatches(bool ecmaScript)
    {
        var mismatches = new List<string>();
        foreach (Case item in Cases)
        {
            if (ecmaScript && item.Flags.IndexOf('s') >= 0)
            {
                mismatches.Add(item.Id);
                continue;
            }
            var regex = new Regex(item.Pattern, ToOptions(item.Flags, ecmaScript),
                                  TimeSpan.FromMilliseconds(250));
            Match match = regex.Match(item.Input);
            bool like = match.Success;
            int start = match.Success ? match.Index + 1 : 0;
            int end = match.Success ? match.Index + match.Length + 1 : 0;
            int count = regex.Matches(item.Input).Count;

            if (like != item.Like || start != item.Start || end != item.End ||
                count != item.Count)
            {
                mismatches.Add(item.Id);
            }
        }
        return mismatches.ToArray();
    }

    private static void RequireExactSet(string label, string[] actual,
                                        params string[] expected)
    {
        string[] normalizedActual = actual.OrderBy(value => value).ToArray();
        string[] normalizedExpected = expected.OrderBy(value => value).ToArray();
        if (!normalizedActual.SequenceEqual(normalizedExpected))
        {
            throw new InvalidOperationException(
                label + " Abweichungen: " + string.Join(",", normalizedActual));
        }
    }

    public static int Main()
    {
        RequireExactSet(".NET Framework CultureInvariant",
                        FindMismatches(false),
                        "ascii-word", "final-newline");
        RequireExactSet(".NET Framework ECMAScript",
                        FindMismatches(true),
                        "dot-singleline", "final-newline");

        string[] re2RejectedButDotNetAccepted =
        {
            @"(a)\1",
            @"a(?=b)",
            @"a{1001}"
        };
        foreach (string pattern in re2RejectedButDotNetAccepted)
        {
            var regex = new Regex(pattern, RegexOptions.CultureInvariant,
                                  TimeSpan.FromMilliseconds(250));
            GC.KeepAlive(regex);
        }

        Console.WriteLine(
            "R1a .NET Framework 4.8 Semantik: erwartete Abweichungen bestätigt");
        return 0;
    }
}
