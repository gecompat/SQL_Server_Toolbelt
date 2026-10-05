-- ============================================================================
-- Objekt:          toolbelt_conversion.TVF_TryCastDecimal
-- Typ:             Inline Table-valued Function mit SCHEMABINDING
-- Zweck:           Dezimaltext anhand exakter Betrags- und Verlustgrenzen klassifizieren.
-- Vertrag:         Documentation/Architecture/SAFE_CAST_CONTRACT.md, 1.0.0
-- Parameter:       @Text nvarchar(max); @MaxInputBytes int = 8192 (positiv, nur absenkbar)
-- Resultset:       Value decimal(38,18) NULL; Status varchar(16) NOT NULL; ErrorCode varchar(32) NULL
-- Dependencies:    Keine Modul-, Tabellen- oder Helperabhängigkeit
-- Rechte:          SELECT auf der Funktion; keine Daten-/Servermutation
-- Versionen:       SQL Server 2019, 2022 und 2025; jeweilige native Abnahme separat
-- Plattformen:     Windows und Linux; native Abnahme separat
-- Fehlerverhalten: Genau eine Zeile; Statuspriorität NULL, Parameter, Limit, leer, Lexik,
--                  Bereich, Verlust, OK; kein Input-Echo und keine Enginefehlermeldung
-- Performance:     Relationaler Ausdruck; höchstens 4096 UTF-16-Codeeinheiten je Lexikscan
-- Einschränkungen: Optionales Vorzeichen; Punkt nur mit Ziffern davor/dahinter; keine Rundung.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE FUNCTION toolbelt_conversion.TVF_TryCastDecimal
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
               CASE WHEN s.FirstNonzero IS NULL THEN N'0'
                    ELSE SUBSTRING(p.ScanText,s.FirstNonzero,CASE WHEN p.IntegerEnd>=s.FirstNonzero THEN p.IntegerEnd-s.FirstNonzero ELSE 0 END) END AS Magnitude,
               LEFT((CASE WHEN p.DotPosition IS NULL THEN N'' ELSE SUBSTRING(p.ScanText,p.DotPosition+1,18) END)+REPLICATE(N'0',18),18) AS Fraction18
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
        SELECT v.InputBytes,v.ScanText,v.ScanLength,v.DigitStart,v.IsNegative,v.BadDigit,v.DotCount,v.DotPosition,v.IntegerEnd,v.NonzeroTail,v.Magnitude,v.Fraction18,v.MagnitudeLength,v.LexicalValid,TRY_CONVERT(decimal(38,18),(CASE WHEN IsNegative=1 THEN N'-' ELSE N'' END)+
            CASE WHEN MagnitudeLength<=20 THEN Magnitude ELSE N'0' END+N'.'+Fraction18) AS ConvertedValue FROM Validated v
    ),
    Verdict AS
    (
        SELECT c.InputBytes,c.ScanText,c.ScanLength,c.DigitStart,c.IsNegative,c.BadDigit,c.DotCount,c.DotPosition,c.IntegerEnd,c.NonzeroTail,c.Magnitude,c.Fraction18,c.MagnitudeLength,c.LexicalValid,c.ConvertedValue,ISNULL(CONVERT(varchar(16),CASE
            WHEN @Text IS NULL THEN 'SQL_NULL'
            WHEN @MaxInputBytes IS NULL OR @MaxInputBytes<1 OR @MaxInputBytes>8192 THEN 'INVALID_ARGUMENT'
            WHEN InputBytes>@MaxInputBytes THEN 'LIMIT'
            WHEN InputBytes=0 THEN 'EMPTY'
            WHEN LexicalValid=0 THEN 'INVALID_FORMAT'
            WHEN MagnitudeLength>20 OR (MagnitudeLength=20 AND Magnitude COLLATE Latin1_General_100_BIN2=N'99999999999999999999'
                AND Fraction18 COLLATE Latin1_General_100_BIN2=N'999999999999999999' AND NonzeroTail=1)
                OR ConvertedValue IS NULL THEN 'OUT_OF_RANGE'
            WHEN NonzeroTail=1 THEN 'LOSSY'
            ELSE 'OK' END),'INVALID_FORMAT') AS ResultStatus
        FROM Converted c
    )
    SELECT CASE WHEN ResultStatus='OK' THEN ConvertedValue ELSE CONVERT(decimal(38,18),NULL) END AS [Value],
           ISNULL(CONVERT(varchar(16),ResultStatus),'INVALID_FORMAT') COLLATE Latin1_General_100_BIN2 AS [Status],
           CONVERT(varchar(32),CASE ResultStatus
             WHEN 'INVALID_ARGUMENT' THEN 'PARAMETER'
             WHEN 'LIMIT' THEN 'INPUT_LIMIT'
             WHEN 'EMPTY' THEN 'EMPTY'
             WHEN 'INVALID_FORMAT' THEN 'FORMAT'
             WHEN 'OUT_OF_RANGE' THEN 'RANGE'
             WHEN 'LOSSY' THEN 'SCALE'
             ELSE NULL END) COLLATE Latin1_General_100_BIN2 AS ErrorCode
    FROM Verdict
);
GO
