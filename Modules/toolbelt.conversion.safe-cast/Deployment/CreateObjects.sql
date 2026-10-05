-- Generiert mit Scripts/generate-deployment.py --write; niemals Fachlogik hier editieren.
-- Source-Hashes sind rein diagnostisch, kein installierter Lifecycle-Gate.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
-- TVF_TryCastBigInt.sql; SHA256(normalisierter Payload)=B3A6F96DD9EFBB743A20ECA085309296C1706C91ADAE574162F905706AEFA894
EXEC sys.sp_executesql N'CREATE FUNCTION toolbelt_conversion.TVF_TryCastBigInt
(
    @Text nvarchar(max),
    @MaxInputBytes int=8192
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    WITH
    Digit AS
    (
        SELECT n FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15)) d(n)
    ),
    Position AS
    (
        SELECT 1+a.n+16*b.n+256*c.n AS n
        FROM Digit a CROSS JOIN Digit b CROSS JOIN Digit c
    ),
    Input AS
    (
        -- DATALENGTH erhält trailing spaces; alle späteren Slices bleiben auf 4096 Einheiten begrenzt.
        SELECT DATALENGTH(@Text) AS InputBytes,
               LEFT(@Text COLLATE Latin1_General_100_BIN2,4096) AS ScanText
    ),
    Bounded AS
    (
        SELECT InputBytes,ScanText,CONVERT(int,ISNULL(DATALENGTH(ScanText)/2,0)) AS ScanLength
        FROM Input
    ),
    CodeUnit AS
    (
        -- Non-SC-BIN2 plus UNICODE prüft ASCII exakt, einschließlich NUL und einzelner Surrogate.
        SELECT p.n,ISNULL(UNICODE(SUBSTRING(b.ScanText,p.n,1)),-1) AS Code
        FROM Position p CROSS JOIN Bounded b WHERE p.n<=b.ScanLength
    ),
    Signed AS
    (
        SELECT InputBytes,ScanText,ScanLength,CASE WHEN UNICODE(SUBSTRING(ScanText,1,1)) IN(43,45) THEN 2 ELSE 1 END AS DigitStart,
               CASE WHEN UNICODE(SUBSTRING(ScanText,1,1))=45 THEN 1 ELSE 0 END AS IsNegative
        FROM Bounded
    ),
    Lexical AS
    (
        SELECT ISNULL(MAX(CASE WHEN u.n>=s.DigitStart AND (u.Code<48 OR u.Code>57) THEN 1 ELSE 0 END),0) AS BadDigit,
               NULLIF(MIN(CASE WHEN u.n>=s.DigitStart AND u.Code BETWEEN 49 AND 57 THEN u.n ELSE 4097 END),4097) AS FirstNonzero
        FROM CodeUnit u CROSS JOIN Signed s
    ),
    Normalized AS
    (
        SELECT s.InputBytes,s.ScanText,s.ScanLength,s.DigitStart,s.IsNegative,l.BadDigit,
               CASE WHEN l.FirstNonzero IS NULL THEN N''0'' ELSE SUBSTRING(s.ScanText,l.FirstNonzero,4096) END AS Magnitude
        FROM Signed s CROSS JOIN Lexical l
    ),
    Validated AS
    (
        SELECT InputBytes,ScanText,ScanLength,DigitStart,IsNegative,BadDigit,Magnitude,CASE WHEN ScanLength>=DigitStart AND BadDigit=0 THEN 1 ELSE 0 END AS LexicalValid,
               DATALENGTH(Magnitude)/2 AS MagnitudeLength
        FROM Normalized
    ),
    Converted AS
    (
        -- Nur erlaubte TRY_CONVERT-Typpaare; auch vorgezogene Auswertung ist kein THROW-Pfad.
        SELECT v.InputBytes,v.ScanText,v.ScanLength,v.DigitStart,v.IsNegative,v.BadDigit,v.Magnitude,v.LexicalValid,v.MagnitudeLength,TRY_CONVERT(bigint,(CASE WHEN IsNegative=1 THEN N''-'' ELSE N'''' END)+
            CASE WHEN MagnitudeLength<=19 THEN Magnitude ELSE N''0'' END) AS ConvertedValue FROM Validated v
    ),
    Verdict AS
    (
        SELECT c.InputBytes,c.ScanText,c.ScanLength,c.DigitStart,c.IsNegative,c.BadDigit,c.Magnitude,c.LexicalValid,c.MagnitudeLength,c.ConvertedValue,ISNULL(CONVERT(varchar(16),CASE
            WHEN @Text IS NULL THEN ''SQL_NULL''
            WHEN @MaxInputBytes IS NULL OR @MaxInputBytes<1 OR @MaxInputBytes>8192 THEN ''INVALID_ARGUMENT''
            WHEN InputBytes>@MaxInputBytes THEN ''LIMIT''
            WHEN InputBytes=0 THEN ''EMPTY''
            WHEN LexicalValid=0 THEN ''INVALID_FORMAT''
            WHEN MagnitudeLength>19 OR (MagnitudeLength=19 AND Magnitude COLLATE Latin1_General_100_BIN2>
                CASE WHEN IsNegative=1 THEN N''9223372036854775808'' ELSE N''9223372036854775807'' END)
                OR ConvertedValue IS NULL THEN ''OUT_OF_RANGE''
            ELSE ''OK'' END),''INVALID_FORMAT'') AS ResultStatus
        FROM Converted c
    )
    SELECT CASE WHEN ResultStatus=''OK'' THEN ConvertedValue ELSE CONVERT(bigint,NULL) END AS [Value],
           ISNULL(CONVERT(varchar(16),ResultStatus),''INVALID_FORMAT'') COLLATE Latin1_General_100_BIN2 AS [Status],
           CONVERT(varchar(32),CASE ResultStatus
             WHEN ''INVALID_ARGUMENT'' THEN ''PARAMETER''
             WHEN ''LIMIT'' THEN ''INPUT_LIMIT''
             WHEN ''EMPTY'' THEN ''EMPTY''
             WHEN ''INVALID_FORMAT'' THEN ''FORMAT''
             WHEN ''OUT_OF_RANGE'' THEN ''RANGE''
             WHEN ''LOSSY'' THEN ''SCALE''
             ELSE NULL END) COLLATE Latin1_General_100_BIN2 AS ErrorCode
    FROM Verdict
);
';
-- TVF_TryCastDecimal.sql; SHA256(normalisierter Payload)=E0F61FF2384A64C4E82A2EB1D03002F1FCDB4CDD0C12ABD661265BC5779E3488
EXEC sys.sp_executesql N'CREATE FUNCTION toolbelt_conversion.TVF_TryCastDecimal
(
    @Text nvarchar(max),
    @MaxInputBytes int=8192
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    WITH
    Digit AS
    (
        SELECT n FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15)) d(n)
    ),
    Position AS
    (
        SELECT 1+a.n+16*b.n+256*c.n AS n
        FROM Digit a CROSS JOIN Digit b CROSS JOIN Digit c
    ),
    Input AS
    (
        -- DATALENGTH erhält trailing spaces; alle späteren Slices bleiben auf 4096 Einheiten begrenzt.
        SELECT DATALENGTH(@Text) AS InputBytes,
               LEFT(@Text COLLATE Latin1_General_100_BIN2,4096) AS ScanText
    ),
    Bounded AS
    (
        SELECT InputBytes,ScanText,CONVERT(int,ISNULL(DATALENGTH(ScanText)/2,0)) AS ScanLength
        FROM Input
    ),
    CodeUnit AS
    (
        -- Non-SC-BIN2 plus UNICODE prüft ASCII exakt, einschließlich NUL und einzelner Surrogate.
        SELECT p.n,ISNULL(UNICODE(SUBSTRING(b.ScanText,p.n,1)),-1) AS Code
        FROM Position p CROSS JOIN Bounded b WHERE p.n<=b.ScanLength
    ),
    Signed AS
    (
        SELECT InputBytes,ScanText,ScanLength,CASE WHEN UNICODE(SUBSTRING(ScanText,1,1)) IN(43,45) THEN 2 ELSE 1 END AS DigitStart,
               CASE WHEN UNICODE(SUBSTRING(ScanText,1,1))=45 THEN 1 ELSE 0 END AS IsNegative
        FROM Bounded
    ),
    Lexical AS
    (
        SELECT ISNULL(MAX(CASE WHEN u.n>=s.DigitStart AND NOT(u.Code BETWEEN 48 AND 57 OR u.Code=46) THEN 1 ELSE 0 END),0) AS BadDigit,
               ISNULL(SUM(CASE WHEN u.n>=s.DigitStart AND u.Code=46 THEN 1 ELSE 0 END),0) AS DotCount,
               NULLIF(MIN(CASE WHEN u.n>=s.DigitStart AND u.Code=46 THEN u.n ELSE 4097 END),4097) AS DotPosition
        FROM CodeUnit u CROSS JOIN Signed s
    ),
    Parts AS
    (
        SELECT s.InputBytes,s.ScanText,s.ScanLength,s.DigitStart,s.IsNegative,l.BadDigit,l.DotCount,l.DotPosition,ISNULL(l.DotPosition,s.ScanLength+1) AS IntegerEnd
        FROM Signed s CROSS JOIN Lexical l
    ),
    Significant AS
    (
        SELECT NULLIF(MIN(CASE WHEN u.n>=p.DigitStart AND u.n<p.IntegerEnd AND u.Code BETWEEN 49 AND 57 THEN u.n ELSE 4097 END),4097) AS FirstNonzero,
               ISNULL(MAX(CASE WHEN u.n>p.DotPosition+18 AND u.Code BETWEEN 49 AND 57 THEN 1 ELSE 0 END),0) AS NonzeroTail
        FROM CodeUnit u CROSS JOIN Parts p
    ),
    Normalized AS
    (
        -- Führende Ganzzahlnullen und exakt entfernbare Fractionnullen werden vor Konversion gekürzt.
        SELECT p.InputBytes,p.ScanText,p.ScanLength,p.DigitStart,p.IsNegative,p.BadDigit,p.DotCount,p.DotPosition,p.IntegerEnd,s.NonzeroTail,
               CASE WHEN s.FirstNonzero IS NULL THEN N''0''
                    ELSE SUBSTRING(p.ScanText,s.FirstNonzero,CASE WHEN p.IntegerEnd>=s.FirstNonzero THEN p.IntegerEnd-s.FirstNonzero ELSE 0 END) END AS Magnitude,
               LEFT((CASE WHEN p.DotPosition IS NULL THEN N'''' ELSE SUBSTRING(p.ScanText,p.DotPosition+1,18) END)+REPLICATE(N''0'',18),18) AS Fraction18
        FROM Parts p CROSS JOIN Significant s
    ),
    Validated AS
    (
        SELECT InputBytes,ScanText,ScanLength,DigitStart,IsNegative,BadDigit,DotCount,DotPosition,IntegerEnd,NonzeroTail,Magnitude,Fraction18,DATALENGTH(Magnitude)/2 AS MagnitudeLength,
               CASE WHEN ScanLength>=DigitStart AND BadDigit=0 AND DotCount<=1
                    AND (DotPosition IS NULL OR (DotPosition>DigitStart AND DotPosition<ScanLength)) THEN 1 ELSE 0 END AS LexicalValid
        FROM Normalized
    ),
    Converted AS
    (
        -- Nur erlaubte TRY_CONVERT-Typpaare; auch vorgezogene Auswertung ist kein THROW-Pfad.
        SELECT v.InputBytes,v.ScanText,v.ScanLength,v.DigitStart,v.IsNegative,v.BadDigit,v.DotCount,v.DotPosition,v.IntegerEnd,v.NonzeroTail,v.Magnitude,v.Fraction18,v.MagnitudeLength,v.LexicalValid,TRY_CONVERT(decimal(38,18),(CASE WHEN IsNegative=1 THEN N''-'' ELSE N'''' END)+
            CASE WHEN MagnitudeLength<=20 THEN Magnitude ELSE N''0'' END+N''.''+Fraction18) AS ConvertedValue FROM Validated v
    ),
    Verdict AS
    (
        SELECT c.InputBytes,c.ScanText,c.ScanLength,c.DigitStart,c.IsNegative,c.BadDigit,c.DotCount,c.DotPosition,c.IntegerEnd,c.NonzeroTail,c.Magnitude,c.Fraction18,c.MagnitudeLength,c.LexicalValid,c.ConvertedValue,ISNULL(CONVERT(varchar(16),CASE
            WHEN @Text IS NULL THEN ''SQL_NULL''
            WHEN @MaxInputBytes IS NULL OR @MaxInputBytes<1 OR @MaxInputBytes>8192 THEN ''INVALID_ARGUMENT''
            WHEN InputBytes>@MaxInputBytes THEN ''LIMIT''
            WHEN InputBytes=0 THEN ''EMPTY''
            WHEN LexicalValid=0 THEN ''INVALID_FORMAT''
            WHEN MagnitudeLength>20 OR (MagnitudeLength=20 AND Magnitude COLLATE Latin1_General_100_BIN2=N''99999999999999999999''
                AND Fraction18 COLLATE Latin1_General_100_BIN2=N''999999999999999999'' AND NonzeroTail=1)
                OR ConvertedValue IS NULL THEN ''OUT_OF_RANGE''
            WHEN NonzeroTail=1 THEN ''LOSSY''
            ELSE ''OK'' END),''INVALID_FORMAT'') AS ResultStatus
        FROM Converted c
    )
    SELECT CASE WHEN ResultStatus=''OK'' THEN ConvertedValue ELSE CONVERT(decimal(38,18),NULL) END AS [Value],
           ISNULL(CONVERT(varchar(16),ResultStatus),''INVALID_FORMAT'') COLLATE Latin1_General_100_BIN2 AS [Status],
           CONVERT(varchar(32),CASE ResultStatus
             WHEN ''INVALID_ARGUMENT'' THEN ''PARAMETER''
             WHEN ''LIMIT'' THEN ''INPUT_LIMIT''
             WHEN ''EMPTY'' THEN ''EMPTY''
             WHEN ''INVALID_FORMAT'' THEN ''FORMAT''
             WHEN ''OUT_OF_RANGE'' THEN ''RANGE''
             WHEN ''LOSSY'' THEN ''SCALE''
             ELSE NULL END) COLLATE Latin1_General_100_BIN2 AS ErrorCode
    FROM Verdict
);
';
-- TVF_TryCastDate.sql; SHA256(normalisierter Payload)=FE1497096E5BBC6C683B11E0D07ADF74FE29E2C467830E8735365EAA121D4812
EXEC sys.sp_executesql N'CREATE FUNCTION toolbelt_conversion.TVF_TryCastDate
(
    @Text nvarchar(max),
    @MaxInputBytes int=8192
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    WITH
    Digit AS
    (
        SELECT n FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15)) d(n)
    ),
    Position AS
    (
        SELECT 1+a.n+16*b.n+256*c.n AS n
        FROM Digit a CROSS JOIN Digit b CROSS JOIN Digit c
    ),
    Input AS
    (
        -- DATALENGTH erhält trailing spaces; alle späteren Slices bleiben auf 4096 Einheiten begrenzt.
        SELECT DATALENGTH(@Text) AS InputBytes,
               LEFT(@Text COLLATE Latin1_General_100_BIN2,4096) AS ScanText
    ),
    Bounded AS
    (
        SELECT InputBytes,ScanText,CONVERT(int,ISNULL(DATALENGTH(ScanText)/2,0)) AS ScanLength
        FROM Input
    ),
    CodeUnit AS
    (
        -- Non-SC-BIN2 plus UNICODE prüft ASCII exakt, einschließlich NUL und einzelner Surrogate.
        SELECT p.n,ISNULL(UNICODE(SUBSTRING(b.ScanText,p.n,1)),-1) AS Code
        FROM Position p CROSS JOIN Bounded b WHERE p.n<=b.ScanLength
    ),
    Lexical AS
    (
        SELECT ISNULL(MAX(CASE WHEN (n IN(5,8) AND Code<>45)
              OR (n NOT IN(5,8) AND (Code<48 OR Code>57)) THEN 1 ELSE 0 END),0) AS BadCode
        FROM CodeUnit
    ),
    Validated AS
    (
        SELECT b.InputBytes,b.ScanText,b.ScanLength,CASE WHEN ScanLength=10 AND l.BadCode=0 THEN 1 ELSE 0 END AS LexicalValid
        FROM Bounded b CROSS JOIN Lexical l
    ),
    Converted AS
    (
        -- Nur erlaubte TRY_CONVERT-Typpaare; auch vorgezogene Auswertung ist kein THROW-Pfad.
        SELECT v.InputBytes,v.ScanText,v.ScanLength,v.LexicalValid,TRY_CONVERT(date,LEFT(ScanText,10),23) AS ConvertedValue FROM Validated v
    ),
    Verdict AS
    (
        SELECT c.InputBytes,c.ScanText,c.ScanLength,c.LexicalValid,c.ConvertedValue,ISNULL(CONVERT(varchar(16),CASE
            WHEN @Text IS NULL THEN ''SQL_NULL''
            WHEN @MaxInputBytes IS NULL OR @MaxInputBytes<1 OR @MaxInputBytes>8192 THEN ''INVALID_ARGUMENT''
            WHEN InputBytes>@MaxInputBytes THEN ''LIMIT''
            WHEN InputBytes=0 THEN ''EMPTY''
            WHEN LexicalValid=0 THEN ''INVALID_FORMAT''
            WHEN ConvertedValue IS NULL THEN ''OUT_OF_RANGE''
            ELSE ''OK'' END),''INVALID_FORMAT'') AS ResultStatus
        FROM Converted c
    )
    SELECT CASE WHEN ResultStatus=''OK'' THEN ConvertedValue ELSE CONVERT(date,NULL) END AS [Value],
           ISNULL(CONVERT(varchar(16),ResultStatus),''INVALID_FORMAT'') COLLATE Latin1_General_100_BIN2 AS [Status],
           CONVERT(varchar(32),CASE ResultStatus
             WHEN ''INVALID_ARGUMENT'' THEN ''PARAMETER''
             WHEN ''LIMIT'' THEN ''INPUT_LIMIT''
             WHEN ''EMPTY'' THEN ''EMPTY''
             WHEN ''INVALID_FORMAT'' THEN ''FORMAT''
             WHEN ''OUT_OF_RANGE'' THEN ''RANGE''
             WHEN ''LOSSY'' THEN ''SCALE''
             ELSE NULL END) COLLATE Latin1_General_100_BIN2 AS ErrorCode
    FROM Verdict
);
';
-- TVF_TryCastDateTime2.sql; SHA256(normalisierter Payload)=4764613FD8A8D72F320DF1A5D2A05D890341F1239265D3C047246D2712BBDE95
EXEC sys.sp_executesql N'CREATE FUNCTION toolbelt_conversion.TVF_TryCastDateTime2
(
    @Text nvarchar(max),
    @MaxInputBytes int=8192
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    WITH
    Digit AS
    (
        SELECT n FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15)) d(n)
    ),
    Position AS
    (
        SELECT 1+a.n+16*b.n+256*c.n AS n
        FROM Digit a CROSS JOIN Digit b CROSS JOIN Digit c
    ),
    Input AS
    (
        -- DATALENGTH erhält trailing spaces; alle späteren Slices bleiben auf 4096 Einheiten begrenzt.
        SELECT DATALENGTH(@Text) AS InputBytes,
               LEFT(@Text COLLATE Latin1_General_100_BIN2,4096) AS ScanText
    ),
    Bounded AS
    (
        SELECT InputBytes,ScanText,CONVERT(int,ISNULL(DATALENGTH(ScanText)/2,0)) AS ScanLength
        FROM Input
    ),
    CodeUnit AS
    (
        -- Non-SC-BIN2 plus UNICODE prüft ASCII exakt, einschließlich NUL und einzelner Surrogate.
        SELECT p.n,ISNULL(UNICODE(SUBSTRING(b.ScanText,p.n,1)),-1) AS Code
        FROM Position p CROSS JOIN Bounded b WHERE p.n<=b.ScanLength
    ),
    Lexical AS
    (
        SELECT ISNULL(MAX(CASE WHEN (n IN(5,8) AND Code<>45) OR (n=11 AND Code<>84)
              OR (n IN(14,17) AND Code<>58) OR (n=20 AND Code<>46)
              OR (n NOT IN(5,8,11,14,17,20) AND (Code<48 OR Code>57)) THEN 1 ELSE 0 END),0) AS BadCode
        FROM CodeUnit
    ),
    Validated AS
    (
        SELECT b.InputBytes,b.ScanText,b.ScanLength,CASE WHEN (ScanLength=19 OR ScanLength BETWEEN 21 AND 27) AND l.BadCode=0 THEN 1 ELSE 0 END AS LexicalValid
        FROM Bounded b CROSS JOIN Lexical l
    ),
    Converted AS
    (
        -- Nur erlaubte TRY_CONVERT-Typpaare; auch vorgezogene Auswertung ist kein THROW-Pfad.
        SELECT v.InputBytes,v.ScanText,v.ScanLength,v.LexicalValid,TRY_CONVERT(datetime2(7),LEFT(ScanText,27),126) AS ConvertedValue FROM Validated v
    ),
    Verdict AS
    (
        SELECT c.InputBytes,c.ScanText,c.ScanLength,c.LexicalValid,c.ConvertedValue,ISNULL(CONVERT(varchar(16),CASE
            WHEN @Text IS NULL THEN ''SQL_NULL''
            WHEN @MaxInputBytes IS NULL OR @MaxInputBytes<1 OR @MaxInputBytes>8192 THEN ''INVALID_ARGUMENT''
            WHEN InputBytes>@MaxInputBytes THEN ''LIMIT''
            WHEN InputBytes=0 THEN ''EMPTY''
            WHEN LexicalValid=0 THEN ''INVALID_FORMAT''
            WHEN ConvertedValue IS NULL OR TRY_CONVERT(int,SUBSTRING(ScanText,12,2))>23
                OR TRY_CONVERT(int,SUBSTRING(ScanText,15,2))>59 OR TRY_CONVERT(int,SUBSTRING(ScanText,18,2))>59 THEN ''OUT_OF_RANGE''
            ELSE ''OK'' END),''INVALID_FORMAT'') AS ResultStatus
        FROM Converted c
    )
    SELECT CASE WHEN ResultStatus=''OK'' THEN ConvertedValue ELSE CONVERT(datetime2(7),NULL) END AS [Value],
           ISNULL(CONVERT(varchar(16),ResultStatus),''INVALID_FORMAT'') COLLATE Latin1_General_100_BIN2 AS [Status],
           CONVERT(varchar(32),CASE ResultStatus
             WHEN ''INVALID_ARGUMENT'' THEN ''PARAMETER''
             WHEN ''LIMIT'' THEN ''INPUT_LIMIT''
             WHEN ''EMPTY'' THEN ''EMPTY''
             WHEN ''INVALID_FORMAT'' THEN ''FORMAT''
             WHEN ''OUT_OF_RANGE'' THEN ''RANGE''
             WHEN ''LOSSY'' THEN ''SCALE''
             ELSE NULL END) COLLATE Latin1_General_100_BIN2 AS ErrorCode
    FROM Verdict
);
';
-- TVF_TryCastBit.sql; SHA256(normalisierter Payload)=DD1033CEBC4F5159BF1C5590D006F87E6D08283958F6E76D2C783231BC768D53
EXEC sys.sp_executesql N'CREATE FUNCTION toolbelt_conversion.TVF_TryCastBit
(
    @Text nvarchar(max),
    @MaxInputBytes int=8192
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    WITH
    Digit AS
    (
        SELECT n FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15)) d(n)
    ),
    Position AS
    (
        SELECT 1+a.n+16*b.n+256*c.n AS n
        FROM Digit a CROSS JOIN Digit b CROSS JOIN Digit c
    ),
    Input AS
    (
        -- DATALENGTH erhält trailing spaces; alle späteren Slices bleiben auf 4096 Einheiten begrenzt.
        SELECT DATALENGTH(@Text) AS InputBytes,
               LEFT(@Text COLLATE Latin1_General_100_BIN2,4096) AS ScanText
    ),
    Bounded AS
    (
        SELECT InputBytes,ScanText,CONVERT(int,ISNULL(DATALENGTH(ScanText)/2,0)) AS ScanLength
        FROM Input
    ),
    CodeUnit AS
    (
        -- Non-SC-BIN2 plus UNICODE prüft ASCII exakt, einschließlich NUL und einzelner Surrogate.
        SELECT p.n,ISNULL(UNICODE(SUBSTRING(b.ScanText,p.n,1)),-1) AS Code
        FROM Position p CROSS JOIN Bounded b WHERE p.n<=b.ScanLength
    ),
    Validated AS
    (
        SELECT InputBytes,ScanText,ScanLength,CASE WHEN ScanLength=1 AND UNICODE(SUBSTRING(ScanText,1,1)) IN(48,49) THEN 1 ELSE 0 END AS LexicalValid
        FROM Bounded
    ),
    Converted AS
    (
        -- Nur erlaubte TRY_CONVERT-Typpaare; auch vorgezogene Auswertung ist kein THROW-Pfad.
        SELECT v.InputBytes,v.ScanText,v.ScanLength,v.LexicalValid,CONVERT(bit,CASE WHEN UNICODE(SUBSTRING(ScanText,1,1))=49 THEN 1 ELSE 0 END) AS ConvertedValue FROM Validated v
    ),
    Verdict AS
    (
        SELECT c.InputBytes,c.ScanText,c.ScanLength,c.LexicalValid,c.ConvertedValue,ISNULL(CONVERT(varchar(16),CASE
            WHEN @Text IS NULL THEN ''SQL_NULL''
            WHEN @MaxInputBytes IS NULL OR @MaxInputBytes<1 OR @MaxInputBytes>8192 THEN ''INVALID_ARGUMENT''
            WHEN InputBytes>@MaxInputBytes THEN ''LIMIT''
            WHEN InputBytes=0 THEN ''EMPTY''
            WHEN LexicalValid=0 THEN ''INVALID_FORMAT''
            WHEN ConvertedValue IS NULL THEN ''OUT_OF_RANGE''
            ELSE ''OK'' END),''INVALID_FORMAT'') AS ResultStatus
        FROM Converted c
    )
    SELECT CASE WHEN ResultStatus=''OK'' THEN ConvertedValue ELSE CONVERT(bit,NULL) END AS [Value],
           ISNULL(CONVERT(varchar(16),ResultStatus),''INVALID_FORMAT'') COLLATE Latin1_General_100_BIN2 AS [Status],
           CONVERT(varchar(32),CASE ResultStatus
             WHEN ''INVALID_ARGUMENT'' THEN ''PARAMETER''
             WHEN ''LIMIT'' THEN ''INPUT_LIMIT''
             WHEN ''EMPTY'' THEN ''EMPTY''
             WHEN ''INVALID_FORMAT'' THEN ''FORMAT''
             WHEN ''OUT_OF_RANGE'' THEN ''RANGE''
             WHEN ''LOSSY'' THEN ''SCALE''
             ELSE NULL END) COLLATE Latin1_General_100_BIN2 AS ErrorCode
    FROM Verdict
);
';
-- TVF_TryCastUniqueIdentifier.sql; SHA256(normalisierter Payload)=83F31E3A53E05A9FC75E1E9BB8959933FC735BC87BE249E2C7A2B02B97341B8D
EXEC sys.sp_executesql N'CREATE FUNCTION toolbelt_conversion.TVF_TryCastUniqueIdentifier
(
    @Text nvarchar(max),
    @MaxInputBytes int=8192
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    WITH
    Digit AS
    (
        SELECT n FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15)) d(n)
    ),
    Position AS
    (
        SELECT 1+a.n+16*b.n+256*c.n AS n
        FROM Digit a CROSS JOIN Digit b CROSS JOIN Digit c
    ),
    Input AS
    (
        -- DATALENGTH erhält trailing spaces; alle späteren Slices bleiben auf 4096 Einheiten begrenzt.
        SELECT DATALENGTH(@Text) AS InputBytes,
               LEFT(@Text COLLATE Latin1_General_100_BIN2,4096) AS ScanText
    ),
    Bounded AS
    (
        SELECT InputBytes,ScanText,CONVERT(int,ISNULL(DATALENGTH(ScanText)/2,0)) AS ScanLength
        FROM Input
    ),
    CodeUnit AS
    (
        -- Non-SC-BIN2 plus UNICODE prüft ASCII exakt, einschließlich NUL und einzelner Surrogate.
        SELECT p.n,ISNULL(UNICODE(SUBSTRING(b.ScanText,p.n,1)),-1) AS Code
        FROM Position p CROSS JOIN Bounded b WHERE p.n<=b.ScanLength
    ),
    Lexical AS
    (
        SELECT ISNULL(MAX(CASE WHEN (n IN(9,14,19,24) AND Code<>45)
              OR (n NOT IN(9,14,19,24) AND NOT(Code BETWEEN 48 AND 57 OR Code BETWEEN 65 AND 70 OR Code BETWEEN 97 AND 102))
              THEN 1 ELSE 0 END),0) AS BadCode
        FROM CodeUnit
    ),
    Validated AS
    (
        SELECT b.InputBytes,b.ScanText,b.ScanLength,CASE WHEN ScanLength=36 AND l.BadCode=0 THEN 1 ELSE 0 END AS LexicalValid
        FROM Bounded b CROSS JOIN Lexical l
    ),
    Converted AS
    (
        -- Nur erlaubte TRY_CONVERT-Typpaare; auch vorgezogene Auswertung ist kein THROW-Pfad.
        SELECT v.InputBytes,v.ScanText,v.ScanLength,v.LexicalValid,TRY_CONVERT(uniqueidentifier,LEFT(ScanText,36)) AS ConvertedValue FROM Validated v
    ),
    Verdict AS
    (
        SELECT c.InputBytes,c.ScanText,c.ScanLength,c.LexicalValid,c.ConvertedValue,ISNULL(CONVERT(varchar(16),CASE
            WHEN @Text IS NULL THEN ''SQL_NULL''
            WHEN @MaxInputBytes IS NULL OR @MaxInputBytes<1 OR @MaxInputBytes>8192 THEN ''INVALID_ARGUMENT''
            WHEN InputBytes>@MaxInputBytes THEN ''LIMIT''
            WHEN InputBytes=0 THEN ''EMPTY''
            WHEN LexicalValid=0 THEN ''INVALID_FORMAT''
            WHEN ConvertedValue IS NULL THEN ''OUT_OF_RANGE''
            ELSE ''OK'' END),''INVALID_FORMAT'') AS ResultStatus
        FROM Converted c
    )
    SELECT CASE WHEN ResultStatus=''OK'' THEN ConvertedValue ELSE CONVERT(uniqueidentifier,NULL) END AS [Value],
           ISNULL(CONVERT(varchar(16),ResultStatus),''INVALID_FORMAT'') COLLATE Latin1_General_100_BIN2 AS [Status],
           CONVERT(varchar(32),CASE ResultStatus
             WHEN ''INVALID_ARGUMENT'' THEN ''PARAMETER''
             WHEN ''LIMIT'' THEN ''INPUT_LIMIT''
             WHEN ''EMPTY'' THEN ''EMPTY''
             WHEN ''INVALID_FORMAT'' THEN ''FORMAT''
             WHEN ''OUT_OF_RANGE'' THEN ''RANGE''
             WHEN ''LOSSY'' THEN ''SCALE''
             ELSE NULL END) COLLATE Latin1_General_100_BIN2 AS ErrorCode
    FROM Verdict
);
';
