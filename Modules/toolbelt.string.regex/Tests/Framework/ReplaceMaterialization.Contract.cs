using System;
using System.Data.SqlTypes;
using Toolbelt.String.Regex;

public static class ReplaceMaterializationContract
{
    private static SqlString Run(string input, string pattern, string replacement, int occurrence)
    {
        return RegexProvider.RegexReplace(new SqlString(input), new SqlString(pattern),
            new SqlString(replacement), new SqlInt32(1), new SqlInt32(occurrence),
            new SqlString("c"), new SqlString("large"));
    }

    public static int Check()
    {
        // Deterministischer Mechanismusnachweis statt einer Laufzeitmessung:
        // bereits validierte vollständige Strings brauchen keine neue Kopie.
        // Das ist keine öffentliche SQL-Referenzidentitätsgarantie.
        string large = new string('a', 8388608);
        var unchanged = Run(large, "Z", "", 0);
        if (unchanged.IsNull || unchanged.Value.Length != large.Length || unchanged.Value != large)
            throw new Exception("REPLACE_NO_MATCH_BYTES");
        if (!Object.ReferenceEquals(large, unchanged.Value))
            throw new Exception("REPLACE_REDUNDANT_NO_MATCH_COPY");
        var missingOccurrence = Run(large, "^a", "X", 2);
        if (missingOccurrence.IsNull || missingOccurrence.Value != large ||
            !Object.ReferenceEquals(large, missingOccurrence.Value))
            throw new Exception("REPLACE_REDUNDANT_MISSING_OCCURRENCE_COPY");
        var full = Run("x", "x", large, 1);
        if (full.IsNull || full.Value != large || !Object.ReferenceEquals(large, full.Value))
            throw new Exception("REPLACE_REDUNDANT_FULL_REPLACEMENT_COPY");
        if (Run("x", "x|$", "Y", 0).Value != "YY")
            throw new Exception("REPLACE_TERMINAL_EMPTY_MATCH_LOST");
        if (Run("", "", "Y", 1).Value != "Y" || Run("ab", "", "", 2).Value != "ab")
            throw new Exception("REPLACE_EMPTY_OR_ZERO_LENGTH_REPLACEMENT");
        if (Run("xabx", "x", "Y", 2).Value != "xabY")
            throw new Exception("REPLACE_PARTIAL_PREFIX_SUFFIX");
        bool invalid = false;
        try { Run("x", "(", large, 1); }
        catch (InvalidOperationException error) { invalid = error.Message.Contains("TBX_REGEX_INVALID_PATTERN"); }
        if (!invalid) throw new Exception("REPLACE_VALIDATION_BYPASS");
        return 7;
    }
}
