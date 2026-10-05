-- ============================================================================
-- Objekt:          toolbelt_conversion.TVF_TryCastBit
-- Typ:             Inline Table-valued Function mit SCHEMABINDING
-- Zweck:           Ausschließlich den ASCII-Einzelwert 0 oder 1 als bit übernehmen.
-- Vertrag:         Documentation/Architecture/SAFE_CAST_CONTRACT.md, 1.0.0
-- Parameter:       @Text nvarchar(max); @MaxInputBytes int = 8192 (positiv, nur absenkbar)
-- Resultset:       Value bit NULL; Status varchar(16) NOT NULL; ErrorCode varchar(32) NULL
-- Dependencies:    Keine Modul-, Tabellen- oder Helperabhängigkeit
-- Rechte:          SELECT auf der Funktion; keine Daten-/Servermutation
-- Versionen:       SQL Server 2019, 2022 und 2025; jeweilige native Abnahme separat
-- Plattformen:     Windows und Linux; native Abnahme separat
-- Fehlerverhalten: Genau eine Zeile; Statuspriorität NULL, Parameter, Limit, leer, Lexik,
--                  Bereich, Verlust, OK; kein Input-Echo und keine Enginefehlermeldung
-- Performance:     Relationaler Ausdruck; höchstens 4096 UTF-16-Codeeinheiten je Lexikscan
-- Einschränkungen: Andere Schreibweisen, Vorzeichen und native truthy-Werte sind ungültig.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE FUNCTION toolbelt_conversion.TVF_TryCastBit
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
            WHEN @Text IS NULL THEN 'SQL_NULL'
            WHEN @MaxInputBytes IS NULL OR @MaxInputBytes<1 OR @MaxInputBytes>8192 THEN 'INVALID_ARGUMENT'
            WHEN InputBytes>@MaxInputBytes THEN 'LIMIT'
            WHEN InputBytes=0 THEN 'EMPTY'
            WHEN LexicalValid=0 THEN 'INVALID_FORMAT'
            WHEN ConvertedValue IS NULL THEN 'OUT_OF_RANGE'
            ELSE 'OK' END),'INVALID_FORMAT') AS ResultStatus
        FROM Converted c
    )
    SELECT CASE WHEN ResultStatus='OK' THEN ConvertedValue ELSE CONVERT(bit,NULL) END AS [Value],
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
