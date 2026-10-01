SET NOCOUNT ON;

IF ISNULL(toolbelt_string.SVF_RegexReplace(N'ab12cd34', N'[0-9]+', N'$1\x', DEFAULT, DEFAULT, DEFAULT, DEFAULT), N'#TBX_UNEXPECTED_NULL#') <> N'ab$1\xcd$1\x'
 OR ISNULL(toolbelt_string.SVF_RegexReplace(N'ab12cd34', N'[0-9]+', N'X', 1, 2, N'c', N'standard'), N'#TBX_UNEXPECTED_NULL#') <> N'ab12cdX'
 OR ISNULL(toolbelt_string.SVF_RegexReplace(N'ab12cd34', N'[0-9]+', N'X', 1, 3, N'c', N'standard'), N'#TBX_UNEXPECTED_NULL#') <> N'ab12cd34'
 OR ISNULL(toolbelt_string.SVF_RegexSubstring(N'ab12cd34', N'[0-9]+', 1, 2, N'c', N'standard'), N'#TBX_UNEXPECTED_NULL#') <> N'34'
 OR toolbelt_string.SVF_RegexSubstring(N'ab12cd34', N'[0-9]+', 1, 3, N'c', N'standard') IS NOT NULL
    THROW 52094, N'Literal Replacement, Occurrence oder Substring falsch.', 1;

IF ISNULL(toolbelt_string.SVF_RegexReplace(N'ab', N'', N'-', 1, 0, N'c', N'standard'), N'#TBX_UNEXPECTED_NULL#') <> N'-a-b-'
 OR ISNULL(toolbelt_string.SVF_RegexReplace(N'ab', N'$', N'-', 3, 0, N'c', N'standard'), N'#TBX_UNEXPECTED_NULL#') <> N'ab-'
 OR ISNULL(DATALENGTH(toolbelt_string.SVF_RegexSubstring(N'', N'', 1, 1, N'c', N'standard')), -1) <> 0
 OR toolbelt_string.SVF_RegexSubstring(N'', N'', 1, 2, N'c', N'standard') IS NOT NULL
 OR toolbelt_string.SVF_RegexSubstring(N'ab', N'a', 4, 1, N'c', N'standard') IS NOT NULL
 OR ISNULL(toolbelt_string.SVF_RegexReplace(N'ab', N'a', N'x', 4, 0, N'c', N'standard'), N'#TBX_UNEXPECTED_NULL#') <> N'ab'
    THROW 52094, N'Terminale/leere Treffer oder Startgrenze falsch.', 2;

IF ISNULL(toolbelt_string.SVF_RegexReplace(N'ab', N'^a', N'X', 2, 0, N'c', N'standard'), N'#TBX_UNEXPECTED_NULL#') <> N'ab'
 OR ISNULL(toolbelt_string.SVF_RegexSubstring(N'Ab', N'a', 1, 1, N'i', N'standard'), N'#TBX_UNEXPECTED_NULL#') <> N'A'
 OR ISNULL(toolbelt_string.SVF_RegexSubstring(N'x' + NCHAR(0xD83D) + NCHAR(0xDE00) + N'y', N'y', 4, 1, N'c', N'standard'), N'#TBX_UNEXPECTED_NULL#') <> N'y'
    THROW 52094, N'Anker, Flags oder UTF-16-Position falsch.', 3;

IF toolbelt_string.SVF_RegexReplace(NULL, N'(', N'x', NULL, NULL, NULL, NULL) IS NOT NULL
 OR toolbelt_string.SVF_RegexReplace(N'x', N'(', NULL, NULL, NULL, NULL, NULL) IS NOT NULL
 OR toolbelt_string.SVF_RegexSubstring(N'x', NULL, NULL, NULL, NULL, NULL) IS NOT NULL
    THROW 52094, N'NULL-Kurzschluss falsch.', 4;

-- Groß- und Grenzfälle sind synthetisch; keine Laufzeitmesswerte persistieren.
DECLARE @Standard nvarchar(max) = REPLICATE(CONVERT(nvarchar(max), N'a'), 1048576);
DECLARE @Large nvarchar(max) = REPLICATE(CONVERT(nvarchar(max), N'a'), 8388608);
IF ISNULL(DATALENGTH(toolbelt_string.SVF_RegexReplace(@Standard, N'Z', N'', 1, 0, N'c', N'standard')), -1) <> 2097152
 OR ISNULL(DATALENGTH(toolbelt_string.SVF_RegexReplace(@Large, N'Z', N'', 1, 0, N'c', N'large')), -1) <> 16777216
 OR ISNULL(DATALENGTH(toolbelt_string.SVF_RegexReplace(N'x', N'x', @Large, 1, 1, N'c', N'large')), -1) <> 16777216
 OR ISNULL(toolbelt_string.SVF_RegexSubstring(@Large, N'a{1000}', 1, 1, N'c', N'large'), N'#TBX_UNEXPECTED_NULL#') <> REPLICATE(N'a', 1000)
    THROW 52094, N'Profilgrenzen oder Large-Slice falsch.', 5;
DECLARE @Pattern nvarchar(max) = REPLICATE(CONVERT(nvarchar(max), N'a'), 8000);
IF ISNULL(DATALENGTH(toolbelt_string.SVF_RegexSubstring(@Pattern, @Pattern, 1, 1, N'c', N'standard')), -1) <> 16000
    THROW 52094, N'8000-Codeeinheiten-Pattern wurde nicht verarbeitet.', 6;
DECLARE @Depth64 nvarchar(max) = REPLICATE(N'(',64)+N'x'+REPLICATE(N')',64);
DECLARE @Alternations1024 nvarchar(max) = REPLICATE(CONVERT(nvarchar(max),N'x|'),1024)+N'x';
IF ISNULL(toolbelt_string.SVF_RegexSubstring(N'x', @Depth64, 1, 1, N'c', N'standard'), N'#TBX_UNEXPECTED_NULL#') <> N'x'
 OR ISNULL(toolbelt_string.SVF_RegexSubstring(N'x', @Alternations1024, 1, 1, N'c', N'standard'), N'#TBX_UNEXPECTED_NULL#') <> N'x'
 OR ISNULL(toolbelt_string.SVF_RegexSubstring(N'ab', N'', 1, 3, N'c', N'standard'), N'#TBX_UNEXPECTED_NULL#') <> N''
 OR toolbelt_string.SVF_RegexSubstring(N'ab', N'', 1, 4, N'c', N'standard') IS NOT NULL
    THROW 52094, N'Komplexitätsgrenze oder Empty-Occurrence falsch.', 8;

-- EXEC erlaubt skalare UDF-Defaults ohne DEFAULT-Platzhalter; SELECT verlangt
-- die expliziten DEFAULT-Argumente. Beide Aufrufwege tragen dieselbe Semantik.
DECLARE @DefaultResult nvarchar(max);
EXEC @DefaultResult = toolbelt_string.SVF_RegexSubstring N'a12', N'[0-9]+';
IF ISNULL(@DefaultResult, N'#TBX_UNEXPECTED_NULL#') <> N'12' THROW 52094, N'EXEC-Defaults falsch.', 9;

IF EXISTS (SELECT 1 FROM sys.parameters
    WHERE object_id IN (OBJECT_ID(N'toolbelt_string.SVF_RegexReplace'), OBJECT_ID(N'toolbelt_string.SVF_RegexSubstring'))
      AND name IN (N'@Input',N'@Pattern',N'@Replacement',N'@Flags',N'@Profile')
      AND (TYPE_NAME(user_type_id) <> N'nvarchar' OR max_length <> -1))
    THROW 52094, N'Max-Signatur wurde verkürzt.', 10;

DECLARE @Errors TABLE (Ordinal int IDENTITY, SqlText nvarchar(max), Prefix nvarchar(64));
INSERT @Errors (SqlText, Prefix) VALUES
(N'SELECT toolbelt_string.SVF_RegexSubstring(N''x'', N''x'', 1, 1, NULL, N''standard'');', N'TBX_REGEX_INVALID_FLAGS'),
(N'SELECT toolbelt_string.SVF_RegexSubstring(REPLICATE(CONVERT(nvarchar(max),N''a''),1048577),N''('',1,1,NULL,N''standard'');', N'TBX_REGEX_INVALID_FLAGS'),
(N'SELECT toolbelt_string.SVF_RegexReplace(N''a'',N''('',REPLICATE(CONVERT(nvarchar(max),N''a''),1048577),1,0,NULL,N''standard'');', N'TBX_REGEX_INVALID_FLAGS'),
(N'SELECT toolbelt_string.SVF_RegexSubstring(N''x'', N''x'', 1, 1, N''c    '', N''standard'');', N'TBX_REGEX_INVALID_FLAGS'),
(N'SELECT toolbelt_string.SVF_RegexSubstring(N''x'', N''x'', 1, 1, N''c'', N''STANDARD'');', N'TBX_REGEX_INVALID_ARGUMENT'),
(N'SELECT toolbelt_string.SVF_RegexSubstring(N''x'', N''x'', 1, 1, N''c'', N''standard '');', N'TBX_REGEX_INVALID_ARGUMENT'),
(N'SELECT toolbelt_string.SVF_RegexSubstring(N''x'', N''x'', 1, 1, N''c'', N''large-more'');', N'TBX_REGEX_INVALID_ARGUMENT'),
(N'SELECT toolbelt_string.SVF_RegexSubstring(N''x'', N''x'', 1, 1, N''c'', NULL);', N'TBX_REGEX_INVALID_ARGUMENT'),
(N'SELECT toolbelt_string.SVF_RegexSubstring(N''x'', N''('', 9, 1, N''c'', N''standard'');', N'TBX_REGEX_INVALID_PATTERN'),
(N'SELECT toolbelt_string.SVF_RegexSubstring(N''x'', N''x'', 0, 1, N''c'', N''standard'');', N'TBX_REGEX_INVALID_ARGUMENT'),
(N'SELECT toolbelt_string.SVF_RegexSubstring(N''x'', N''x'', 1, 0, N''c'', N''standard'');', N'TBX_REGEX_INVALID_ARGUMENT'),
(N'SELECT toolbelt_string.SVF_RegexReplace(N''x'', N''x'', N''y'', 1, -1, N''c'', N''standard'');', N'TBX_REGEX_INVALID_ARGUMENT'),
(N'SELECT toolbelt_string.SVF_RegexSubstring(REPLICATE(CONVERT(nvarchar(max),N''a''),1048577), N''x'', 1, 1, N''c'', N''standard'');', N'TBX_REGEX_INPUT_TOO_LARGE'),
(N'SELECT toolbelt_string.SVF_RegexSubstring(REPLICATE(CONVERT(nvarchar(max),N''a''),8388609), N''x'', 1, 1, N''c'', N''large'');', N'TBX_REGEX_INPUT_TOO_LARGE'),
(N'SELECT toolbelt_string.SVF_RegexReplace(N''x'', N''x'', REPLICATE(CONVERT(nvarchar(max),N''a''),1048577), 1, 0, N''c'', N''standard'');', N'TBX_REGEX_REPLACEMENT_TOO_LARGE'),
(N'SELECT toolbelt_string.SVF_RegexReplace(N''xx'', N''x'', REPLICATE(CONVERT(nvarchar(max),N''a''),1048576), 1, 0, N''c'', N''standard'');', N'TBX_REGEX_OUTPUT_TOO_LARGE'),
(N'SELECT toolbelt_string.SVF_RegexReplace(N''xx'', N''x'', REPLICATE(CONVERT(nvarchar(max),N''a''),8388608), 1, 0, N''c'', N''large'');', N'TBX_REGEX_OUTPUT_TOO_LARGE'),
(N'SELECT toolbelt_string.SVF_RegexSubstring(N''x'', REPLICATE(CONVERT(nvarchar(max),N''a''),8001), 1, 1, N''c'', N''standard'');', N'TBX_REGEX_PATTERN_TOO_LARGE'),
(N'SELECT toolbelt_string.SVF_RegexSubstring(N''x'', REPLICATE(N''('',65)+N''x''+REPLICATE(N'')'',65),1,1,N''c'',N''standard'');', N'TBX_REGEX_PATTERN_TOO_COMPLEX'),
(N'SELECT toolbelt_string.SVF_RegexSubstring(N''x'', REPLICATE(CONVERT(nvarchar(max),N''x|''),1025)+N''x'',1,1,N''c'',N''standard'');', N'TBX_REGEX_PATTERN_TOO_COMPLEX'),
(N'SELECT toolbelt_string.SVF_RegexSubstring(REPLICATE(CONVERT(nvarchar(max),N''a''),20000)+N''X'',N''^(a|aa)+$'',1,1,N''c'',N''standard'');', N'TBX_REGEX_TIMEOUT');
DECLARE @Ordinal int = 1, @Sql nvarchar(max), @Prefix nvarchar(64), @Caught bit;
WHILE @Ordinal <= (SELECT COUNT(*) FROM @Errors)
BEGIN
    SELECT @Sql = SqlText, @Prefix = Prefix FROM @Errors WHERE Ordinal = @Ordinal;
    SET @Caught = 0;
    BEGIN TRY
        EXEC sys.sp_executesql @Sql;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() <> 6522 OR CHARINDEX(@Prefix, ERROR_MESSAGE()) = 0
            THROW;
        SET @Caught = 1;
    END CATCH;
    IF @Caught = 0 THROW 52094, N'Erwarteter R2a-Vertragsfehler fehlt.', 7;
    SET @Ordinal += 1;
END;
PRINT N'Regex R2a Transformations-Contract erfolgreich.';
