SET NOCOUNT ON;

IF OBJECT_ID(N'toolbelt_string.SVF_RegexIsMatch', N'FS') IS NULL
   OR OBJECT_ID(N'toolbelt_string.SVF_RegexInstr', N'FS') IS NULL
   OR OBJECT_ID(N'toolbelt_string.SVF_RegexCount', N'FS') IS NULL
    THROW 52070, N'Die drei öffentlichen CLR-Skalarfunktionen fehlen.', 1;

IF toolbelt_string.SVF_RegexIsMatch(N'abc-123', N'^[a-z]+-\d{3}$', 'c') <> 1
   OR toolbelt_string.SVF_RegexIsMatch(N'a', N'a', DEFAULT) <> 1
   OR toolbelt_string.SVF_RegexIsMatch(N'.', N'^\.$', 'c') <> 1
   OR toolbelt_string.SVF_RegexIsMatch(NCHAR(9), N'^\s$', 'c') <> 1
   OR toolbelt_string.SVF_RegexIsMatch(N'ac', N'^ab?c$', 'c') <> 1
   OR toolbelt_string.SVF_RegexIsMatch(N'ac', N'^ab*c$', 'c') <> 1
   OR toolbelt_string.SVF_RegexIsMatch(N'abbc', N'^ab{2,3}c$', 'c') <> 1
   OR toolbelt_string.SVF_RegexIsMatch(REPLICATE(N'a', 1000), N'^a{1000}$', 'c') <> 1
   OR toolbelt_string.SVF_RegexIsMatch(N'ABC', N'^[a-z]+$', 'c') <> 0
   OR toolbelt_string.SVF_RegexIsMatch(N'ABC', N'^[a-z]+$', 'i') <> 1
   OR toolbelt_string.SVF_RegexIsMatch(N'cat', N'^(cat|dog)$', 'c') <> 1
   OR toolbelt_string.SVF_RegexIsMatch(N'b', N'^[^a-c]$', 'c') <> 0
   OR toolbelt_string.SVF_RegexIsMatch(N'ä', N'^\w$', 'c') <> 0
   OR toolbelt_string.SVF_RegexIsMatch(NCHAR(0x212A), N'^\w$', 'i') <> 0
   OR toolbelt_string.SVF_RegexIsMatch(NCHAR(0x212A), N'^[\w]$', 'i') <> 0
   OR toolbelt_string.SVF_RegexIsMatch(NCHAR(0x212A), N'^[^\w]$', 'i') <> 1
   OR toolbelt_string.SVF_RegexIsMatch(N'ä', N'^\p{L}$', 'c') <> 1
    THROW 52071, N'Literal-, Klassen-, Gruppen-, Anker-, Quantifier- oder Flagsemantik ist falsch.', 1;

IF toolbelt_string.SVF_RegexIsMatch(N'x' + NCHAR(10), N'x$', 'c') <> 0
   OR toolbelt_string.SVF_RegexIsMatch(N'a' + NCHAR(10) + N'x', N'^x$', 'cm') <> 1
   OR toolbelt_string.SVF_RegexIsMatch(N'a' + NCHAR(10) + N'b', N'^a.b$', 'cs') <> 1
    THROW 52072, N'Multiline-, Singleline- oder absolute Endankersementik ist falsch.', 1;

IF toolbelt_string.SVF_RegexIsMatch(NULL, N'a', 'c') IS NOT NULL
   OR toolbelt_string.SVF_RegexInstr(N'a', NULL, 1, 1, 0, 'c') IS NOT NULL
   OR toolbelt_string.SVF_RegexCount(NULL, N'a', 1, 'c') IS NOT NULL
    THROW 52073, N'NULL-Propagation ist verletzt.', 1;

IF toolbelt_string.SVF_RegexInstr(N'baacaa', N'aa', 1, 2, 0, 'c') <> 5
   OR toolbelt_string.SVF_RegexInstr(N'baacaa', N'aa', 1, 2, 1, 'c') <> 7
   OR toolbelt_string.SVF_RegexInstr(N'baacaa', N'aa', 3, 1, 0, 'c') <> 5
   OR toolbelt_string.SVF_RegexInstr(N'abc', N'z', 1, 1, 0, 'c') <> 0
   OR toolbelt_string.SVF_RegexInstr(NCHAR(0xD83D) + NCHAR(0xDE00) + N'a', N'a', 1, 1, 0, 'c') <> 3
    THROW 52074, N'Instr-Position, Occurrence, ReturnOption oder UTF-16-Semantik ist falsch.', 1;

IF toolbelt_string.SVF_RegexCount(N'aaaa', N'aa', 1, 'c') <> 2
   OR toolbelt_string.SVF_RegexCount(N'baaaa', N'aa', 3, 'c') <> 1
   OR toolbelt_string.SVF_RegexCount(N'bbb', N'a*', 1, 'c') <> 4
   OR toolbelt_string.SVF_RegexInstr(N'bbb', N'a*', 1, 3, 0, 'c') <> 3
    THROW 52075, N'Count- oder Empty-Match-Fortschritt ist falsch.', 1;

DECLARE @InvalidPatterns TABLE (Pattern nvarchar(4000) NOT NULL);
INSERT @InvalidPatterns (Pattern)
VALUES (N'(.)\1'), (N'a(?=b)'), (N'(?<=a)b'), (N'(?!a)'),
       (N'(?<x>a)'), (N'(?>a)'), (N'(?(1)a|b)'),
       (N'(?<open>a)(?<-open>b)'), (N'a{1001}'),
       (N'a??'), (N'[a-z-[aeiou]]'), (N'\P{L}');

DECLARE @Pattern nvarchar(4000);
DECLARE InvalidPatternCursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT Pattern FROM @InvalidPatterns;
OPEN InvalidPatternCursor;
FETCH NEXT FROM InvalidPatternCursor INTO @Pattern;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        DECLARE @UnexpectedBit bit =
            toolbelt_string.SVF_RegexIsMatch(N'ab', @Pattern, 'c');
        THROW 52076, N'Ein verbotenes Pattern wurde akzeptiert.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 6522
           OR ERROR_MESSAGE() NOT LIKE N'%TBX_REGEX_INVALID_PATTERN%'
            THROW;
    END CATCH;
    FETCH NEXT FROM InvalidPatternCursor INTO @Pattern;
END;
CLOSE InvalidPatternCursor;
DEALLOCATE InvalidPatternCursor;

BEGIN TRY
    DECLARE @BadFlags bit =
        toolbelt_string.SVF_RegexIsMatch(N'a', N'a', 'ci');
    THROW 52077, N'Ungültige Flags wurden akzeptiert.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 6522
       OR ERROR_MESSAGE() NOT LIKE N'%TBX_REGEX_INVALID_FLAGS%'
        THROW;
END CATCH;

BEGIN TRY
    DECLARE @NullFlags bit =
        toolbelt_string.SVF_RegexIsMatch(N'a', N'a', NULL);
    THROW 52077, N'NULL-Flags wurden akzeptiert.', 2;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 6522
       OR ERROR_MESSAGE() NOT LIKE N'%TBX_REGEX_INVALID_FLAGS%'
        THROW;
END CATCH;

BEGIN TRY
    DECLARE @BadStart int =
        toolbelt_string.SVF_RegexInstr(N'a', N'a', 0, 1, 0, 'c');
    THROW 52078, N'Ungültige Positionsparameter wurden akzeptiert.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 6522
       OR ERROR_MESSAGE() NOT LIKE N'%TBX_REGEX_INVALID_ARGUMENT%'
        THROW;
END CATCH;

BEGIN TRY
    DECLARE @NullStart int =
        toolbelt_string.SVF_RegexCount(N'a', N'a', NULL, N'c');
    THROW 52078, N'NULL als Start wurde akzeptiert.', 2;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 6522
       OR ERROR_MESSAGE() NOT LIKE N'%TBX_REGEX_INVALID_ARGUMENT%'
        THROW;
END CATCH;

BEGIN TRY
    DECLARE @LargeInput bit =
        toolbelt_string.SVF_RegexIsMatch(
            CONVERT(nvarchar(max), REPLICATE(CONVERT(nvarchar(max), N'a'), 1048577)),
            N'a', 'c');
    THROW 52079, N'Ein Input über 2 MiB wurde akzeptiert.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 6522
       OR ERROR_MESSAGE() NOT LIKE N'%TBX_REGEX_INPUT_TOO_LARGE%'
        THROW;
END CATCH;

BEGIN TRY
    DECLARE @LargePattern bit =
        toolbelt_string.SVF_RegexIsMatch(
            N'a', REPLICATE(CONVERT(nvarchar(max), N'a'), 4001), 'c');
    THROW 52080, N'Ein Pattern über 8000 Bytes wurde akzeptiert.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 6522
       OR ERROR_MESSAGE() NOT LIKE N'%TBX_REGEX_PATTERN_TOO_LARGE%'
        THROW;
END CATCH;

IF toolbelt_string.SVF_RegexIsMatch(
       REPLICATE(CONVERT(nvarchar(max), N'a'), 4000),
       REPLICATE(CONVERT(nvarchar(max), N'a'), 4000), N'c') <> 1
    THROW 52080, N'Die exakt zulässige 8000-Byte-Pattern-Grenze wurde abgewiesen.', 2;

BEGIN TRY
    DECLARE @TimedOut bit =
        toolbelt_string.SVF_RegexIsMatch(
            REPLICATE(CONVERT(nvarchar(max), N'a'), 20000) + N'X',
            N'^(a|aa)+$', 'c');
    THROW 52081, N'Der ReDoS-Vektor erreichte den festen Timeout nicht.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 6522
       OR ERROR_MESSAGE() NOT LIKE N'%TBX_REGEX_TIMEOUT%'
        THROW;
END CATCH;

PRINT N'Regex-Runtime-Contract erfolgreich.';
