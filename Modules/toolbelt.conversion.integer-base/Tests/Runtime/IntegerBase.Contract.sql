-- Contract-Tests für frei definierbare Zahlensysteme
-- Daten: ausschließlich synthetisch
-- SQLCMD-Variable: CompatibilityLevel=150|160|170

SET NOCOUNT ON;

DECLARE @CompatibilityLevel int = TRY_CONVERT(int, N'$(CompatibilityLevel)');

IF @CompatibilityLevel NOT IN (150, 160, 170)
    THROW 52800, N'CompatibilityLevel muss 150, 160 oder 170 sein.', 1;

DECLARE @SetCompatibilitySql nvarchar(max) =
    N'ALTER DATABASE ' + QUOTENAME(DB_NAME())
    + N' SET COMPATIBILITY_LEVEL = '
    + CONVERT(nvarchar(3), @CompatibilityLevel) + N';';
EXEC sys.sp_executesql @SetCompatibilitySql;

IF OBJECT_ID(N'toolbelt_conversion.TVF_IntegerToBase', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_conversion.TVF_TryBaseToInteger', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_conversion.SVF_IntegerToBase', N'FN') IS NULL
   OR OBJECT_ID(N'toolbelt_conversion.SVF_TryBaseToInteger', N'FN') IS NULL
    THROW 52801, N'Die öffentlichen Integer-Base-Funktionen fehlen.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.parameters
       WHERE object_id = OBJECT_ID(N'toolbelt_conversion.SVF_IntegerToBase', N'FN')
         AND parameter_id = 0
         AND TYPE_NAME(user_type_id) = N'varchar'
         AND max_length = 65
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM sys.parameters
       WHERE object_id = OBJECT_ID(N'toolbelt_conversion.SVF_IntegerToBase', N'FN')
         AND parameter_id = 1
         AND name = N'@Value'
         AND TYPE_NAME(user_type_id) = N'bigint'
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM sys.parameters
       WHERE object_id = OBJECT_ID(N'toolbelt_conversion.SVF_IntegerToBase', N'FN')
         AND parameter_id = 2
         AND name = N'@Alphabet'
         AND TYPE_NAME(user_type_id) = N'varchar'
         AND max_length = 93
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM sys.parameters
       WHERE object_id = OBJECT_ID(N'toolbelt_conversion.SVF_TryBaseToInteger', N'FN')
         AND parameter_id = 0
         AND TYPE_NAME(user_type_id) = N'bigint'
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM sys.parameters
       WHERE object_id = OBJECT_ID(N'toolbelt_conversion.SVF_TryBaseToInteger', N'FN')
         AND parameter_id = 1
         AND name = N'@EncodedValue'
         AND TYPE_NAME(user_type_id) = N'varchar'
         AND max_length = 65
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM sys.parameters
       WHERE object_id = OBJECT_ID(N'toolbelt_conversion.SVF_TryBaseToInteger', N'FN')
         AND parameter_id = 2
         AND name = N'@Alphabet'
         AND TYPE_NAME(user_type_id) = N'varchar'
         AND max_length = 93
   )
    THROW 52802, N'Die öffentliche Parametersignatur weicht vom Vertrag ab.', 1;

DECLARE
      @Binary varchar(93) = '01'
    , @Octal varchar(93) = '01234567'
    , @Decimal varchar(93) = '0123456789'
    , @Hex varchar(93) = '0123456789ABCDEF'
    , @Base36 varchar(93) = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    , @Base62 varchar(93) =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
    , @Base93 varchar(93) = ''
    , @Ascii int = 33;

WHILE @Ascii <= 126
BEGIN
    IF @Ascii <> 45
        SET @Base93 += CHAR(@Ascii);
    SET @Ascii += 1;
END;

IF DATALENGTH(@Base93) <> 93
    THROW 52803, N'Das synthetische Basis-93-Alphabet ist inkonsistent.', 1;

-- Werte und direkte TVF-Zeilenanzahlen werden je Eingabe getrennt aufgenommen.
DECLARE @PositiveCases TABLE
(
    CaseId int NOT NULL PRIMARY KEY,
    CaseGroup int NOT NULL,
    Value bigint NOT NULL,
    Alphabet varchar(93) NOT NULL,
    ExpectedEncoded varchar(65) NOT NULL,
    CheckEncode bit NOT NULL,
    CheckDecode bit NOT NULL
);
INSERT INTO @PositiveCases
    (CaseId, CaseGroup, Value, Alphabet, ExpectedEncoded, CheckEncode, CheckDecode)
VALUES
      (1, 0, 0, @Decimal, '0', 1, 1)
    , (2, 0, 10, @Hex, 'A', 1, 0)
    , (3, 0, 255, @Hex, 'FF', 1, 1)
    , (4, 0, -255, @Hex, '-FF', 1, 1)
    , (5, 0, 9223372036854775807, @Hex, '7FFFFFFFFFFFFFFF', 1, 1)
    , (6, 0, CONVERT(bigint, -9223372036854775807) - 1,
       @Hex, '-8000000000000000', 1, 1)
    , (7, 1, 1, 'aA', 'A', 1, 1)
    , (8, 1, 0, 'aA', 'a', 0, 1)
    , (9, 2, 0, '+1', '+', 1, 1)
    , (10, 2, 2, '+1', '1+', 1, 1)
    , (11, 2, -2, '+1', '-1+', 1, 1)
    , (12, 2, 1, '0+1', '+', 1, 1)
    , (13, 2, 5, '0+1', '+1', 1, 1)
    , (14, 2, -1, '0+1', '-+', 1, 1)
    , (15, 2, 0, '1+', '1', 1, 1)
    , (16, 2, 2, '1+', '+1', 1, 1)
    , (17, 2, 10, @Base93, '+', 1, 1)
    , (18, 2, 9223372036854775807, '1+', REPLICATE('+', 63), 1, 1)
    , (19, 2, CONVERT(bigint, -9223372036854775807) - 1,
       '1+', '-+' + REPLICATE('1', 63), 1, 1);

DECLARE @PositiveResults TABLE
(
    CaseId int NOT NULL PRIMARY KEY,
    ScalarEncoded varchar(65) NULL,
    ScalarDecoded bigint NULL,
    EncodeRows bigint NULL,
    EncodedValue varchar(65) NULL,
    DecodeRows bigint NULL,
    DecodedValue bigint NULL
);
INSERT INTO @PositiveResults (CaseId, ScalarEncoded, EncodeRows, EncodedValue)
SELECT cases.CaseId,
       toolbelt_conversion.SVF_IntegerToBase(cases.Value, cases.Alphabet),
       encoded.ActualRows, encoded.EncodedValue
FROM @PositiveCases AS cases
OUTER APPLY
(
    SELECT COUNT_BIG(*) AS ActualRows, MAX(EncodedValue) AS EncodedValue
    FROM toolbelt_conversion.TVF_IntegerToBase(cases.Value, cases.Alphabet)
) AS encoded
WHERE cases.CheckEncode = 1;
INSERT INTO @PositiveResults (CaseId)
SELECT CaseId FROM @PositiveCases WHERE CheckEncode = 0;
UPDATE results
SET ScalarDecoded = toolbelt_conversion.SVF_TryBaseToInteger
                    (cases.ExpectedEncoded, cases.Alphabet),
    DecodeRows = decoded.ActualRows,
    DecodedValue = decoded.DecodedValue
FROM @PositiveResults AS results
INNER JOIN @PositiveCases AS cases ON cases.CaseId = results.CaseId
OUTER APPLY
(
    SELECT COUNT_BIG(*) AS ActualRows, MAX(DecodedValue) AS DecodedValue
    FROM toolbelt_conversion.TVF_TryBaseToInteger
         (cases.ExpectedEncoded, cases.Alphabet)
) AS decoded
WHERE cases.CheckDecode = 1;

IF EXISTS
   (
       SELECT 1 FROM @PositiveCases AS cases
       INNER JOIN @PositiveResults AS results ON results.CaseId = cases.CaseId
       WHERE cases.CaseGroup = 0 AND cases.CheckEncode = 1
         AND (results.ScalarEncoded IS NULL
              OR CONVERT(varbinary(65), results.ScalarEncoded)
                 <> CONVERT(varbinary(65), cases.ExpectedEncoded)
              OR DATALENGTH(results.ScalarEncoded) <> DATALENGTH(cases.ExpectedEncoded))
   )
    THROW 52804, N'Die kanonischen Encode-Vektoren sind fehlgeschlagen.', 1;

IF EXISTS
   (
       SELECT 1 FROM @PositiveCases AS cases
       INNER JOIN @PositiveResults AS results ON results.CaseId = cases.CaseId
       WHERE cases.CaseGroup = 0 AND cases.CheckDecode = 1
         AND (results.ScalarDecoded IS NULL OR results.ScalarDecoded <> cases.Value)
   )
    THROW 52805, N'Die kanonischen Decode-Vektoren sind fehlgeschlagen.', 1;

DECLARE @Values TABLE (Value bigint NOT NULL PRIMARY KEY);
INSERT INTO @Values (Value)
VALUES
      (CONVERT(bigint, -9223372036854775807) - 1)
    , (-123456789)
    , (-1)
    , (0)
    , (1)
    , (123456789)
    , (9223372036854775807);

DECLARE @Alphabets TABLE (Alphabet varchar(93) NOT NULL PRIMARY KEY);
INSERT INTO @Alphabets (Alphabet)
VALUES (@Binary), (@Octal), (@Decimal), (@Hex), (@Base36), (@Base62), (@Base93);

DECLARE @RoundtripResults TABLE
(
    Value bigint NOT NULL,
    Alphabet varchar(93) NOT NULL,
    ScalarEncoded varchar(65) NULL,
    EncodedValue varchar(65) NULL,
    EncodeRows bigint NOT NULL,
    ScalarDecoded bigint NULL,
    DecodedValue bigint NULL,
    DecodeRows bigint NULL
);
INSERT INTO @RoundtripResults (Value, Alphabet, ScalarEncoded, EncodedValue, EncodeRows)
SELECT value_set.Value, alphabet_set.Alphabet,
       toolbelt_conversion.SVF_IntegerToBase(value_set.Value, alphabet_set.Alphabet),
       encoded.EncodedValue, encoded.ActualRows
FROM @Values AS value_set
CROSS JOIN @Alphabets AS alphabet_set
OUTER APPLY
(
    SELECT COUNT_BIG(*) AS ActualRows, MAX(EncodedValue) AS EncodedValue
    FROM toolbelt_conversion.TVF_IntegerToBase(value_set.Value, alphabet_set.Alphabet)
) AS encoded;
UPDATE results
SET ScalarDecoded = toolbelt_conversion.SVF_TryBaseToInteger
                    (results.ScalarEncoded, results.Alphabet),
    DecodedValue = decoded.DecodedValue,
    DecodeRows = decoded.ActualRows
FROM @RoundtripResults AS results
OUTER APPLY
(
    SELECT COUNT_BIG(*) AS ActualRows, MAX(DecodedValue) AS DecodedValue
    FROM toolbelt_conversion.TVF_TryBaseToInteger(results.EncodedValue, results.Alphabet)
) AS decoded;

IF EXISTS
   (
       SELECT 1 FROM @RoundtripResults
       WHERE ScalarEncoded IS NULL OR ScalarDecoded IS NULL OR ScalarDecoded <> Value
   )
    THROW 52806, N'Ein Roundtrip über eine freigegebene Basis ist fehlgeschlagen.', 1;

IF toolbelt_conversion.SVF_IntegerToBase(NULL, @Decimal) IS NOT NULL
   OR toolbelt_conversion.SVF_IntegerToBase(1, NULL) IS NOT NULL
   OR toolbelt_conversion.SVF_TryBaseToInteger(NULL, @Decimal) IS NOT NULL
   OR toolbelt_conversion.SVF_TryBaseToInteger('1', NULL) IS NOT NULL
    THROW 52807, N'Der NULL-Vertrag ist fehlgeschlagen.', 1;

IF toolbelt_conversion.SVF_IntegerToBase(1, '0') IS NOT NULL
   OR toolbelt_conversion.SVF_IntegerToBase(1, '001') IS NOT NULL
   OR toolbelt_conversion.SVF_IntegerToBase(1, '0-1') IS NOT NULL
   OR toolbelt_conversion.SVF_IntegerToBase(1, '0 1') IS NOT NULL
   OR toolbelt_conversion.SVF_IntegerToBase(1, '0' + CHAR(31)) IS NOT NULL
    THROW 52808, N'Ein ungültiges Alphabet wurde beim Encode akzeptiert.', 1;

IF toolbelt_conversion.SVF_TryBaseToInteger('', @Decimal) IS NOT NULL
   OR toolbelt_conversion.SVF_TryBaseToInteger('+1', @Decimal) IS NOT NULL
   OR toolbelt_conversion.SVF_TryBaseToInteger('00', @Decimal) IS NOT NULL
   OR toolbelt_conversion.SVF_TryBaseToInteger('01', @Decimal) IS NOT NULL
   OR toolbelt_conversion.SVF_TryBaseToInteger('-0', @Decimal) IS NOT NULL
   OR toolbelt_conversion.SVF_TryBaseToInteger(' 1', @Decimal) IS NOT NULL
   OR toolbelt_conversion.SVF_TryBaseToInteger('1 ', @Decimal) IS NOT NULL
   OR toolbelt_conversion.SVF_TryBaseToInteger('G', @Hex) IS NOT NULL
    THROW 52809, N'Eine nicht kanonische Darstellung wurde akzeptiert.', 1;

IF toolbelt_conversion.SVF_TryBaseToInteger
   (
       '9223372036854775808',
       @Decimal
   ) IS NOT NULL
   OR toolbelt_conversion.SVF_TryBaseToInteger
      (
          '-9223372036854775809',
          @Decimal
      ) IS NOT NULL
    THROW 52810, N'Decode-Overflow wurde nicht als NULL abgelehnt.', 1;

IF EXISTS
   (
       SELECT 1 FROM @PositiveCases AS cases
       INNER JOIN @PositiveResults AS results ON results.CaseId = cases.CaseId
       WHERE cases.CaseGroup = 1
         AND ((cases.CheckEncode = 1
               AND (results.ScalarEncoded IS NULL
                    OR CONVERT(varbinary(65), results.ScalarEncoded)
                       <> CONVERT(varbinary(65), cases.ExpectedEncoded)
                    OR DATALENGTH(results.ScalarEncoded) <> DATALENGTH(cases.ExpectedEncoded)))
              OR results.ScalarDecoded IS NULL OR results.ScalarDecoded <> cases.Value)
   )
    THROW 52811, N'Der binäre Case-Sensitivity-Vertrag ist fehlgeschlagen.', 1;

IF EXISTS
   (
       SELECT 1 FROM @RoundtripResults
       WHERE EncodeRows <> 1 OR DecodeRows IS NULL OR DecodeRows <> 1
          OR EncodedValue IS NULL OR DecodedValue IS NULL
          OR CONVERT(varbinary(65), EncodedValue) <> CONVERT(varbinary(65), ScalarEncoded)
          OR DATALENGTH(EncodedValue) <> DATALENGTH(ScalarEncoded)
          OR DecodedValue <> Value OR DecodedValue <> ScalarDecoded
   )
    THROW 52812, N'Die SVF-/inline-TVF-Parität ist fehlgeschlagen.', 1;

IF (SELECT COUNT(*)
    FROM toolbelt_conversion.TVF_IntegerToBase(NULL, @Decimal)) <> 1
   OR EXISTS
      (
          SELECT 1
          FROM toolbelt_conversion.TVF_IntegerToBase(NULL, @Decimal)
          WHERE EncodedValue IS NOT NULL
      )
   OR (SELECT COUNT(*)
       FROM toolbelt_conversion.TVF_TryBaseToInteger(NULL, @Decimal)) <> 1
   OR EXISTS
      (
          SELECT 1
          FROM toolbelt_conversion.TVF_TryBaseToInteger(NULL, @Decimal)
          WHERE DecodedValue IS NOT NULL
      )
    THROW 52813, N'Der einzeilige NULL-Vertrag der inline TVFs ist fehlgeschlagen.', 1;

IF (SELECT COUNT(*)
    FROM @Values AS source
    OUTER APPLY toolbelt_conversion.TVF_IntegerToBase
                (
                      source.Value
                    , @Hex
                ) AS encoded) <> (SELECT COUNT(*) FROM @Values)
    THROW 52814, N'OUTER APPLY erhält die äußeren Zeilen nicht vollständig.', 1;

IF EXISTS
   (
       SELECT 1 FROM @PositiveCases AS cases
       INNER JOIN @PositiveResults AS results ON results.CaseId = cases.CaseId
       WHERE (cases.CheckEncode = 1
              AND (results.EncodeRows IS NULL OR results.EncodeRows <> 1
                   OR results.EncodedValue IS NULL
                   OR CONVERT(varbinary(65), results.EncodedValue)
                      <> CONVERT(varbinary(65), cases.ExpectedEncoded)
                   OR DATALENGTH(results.EncodedValue) <> DATALENGTH(cases.ExpectedEncoded)))
          OR (cases.CheckDecode = 1
              AND (results.DecodeRows IS NULL OR results.DecodeRows <> 1
                   OR results.DecodedValue IS NULL OR results.DecodedValue <> cases.Value))
   )
    THROW 52815, N'Der einzeilige positive TVF-Vertrag ist fehlgeschlagen.', 1;

IF EXISTS
   (
       SELECT 1 FROM @PositiveCases AS cases
       INNER JOIN @PositiveResults AS results ON results.CaseId = cases.CaseId
       WHERE cases.CaseGroup = 2
         AND (results.ScalarEncoded IS NULL OR results.ScalarDecoded IS NULL
              OR CONVERT(varbinary(65), results.ScalarEncoded)
                 <> CONVERT(varbinary(65), cases.ExpectedEncoded)
              OR DATALENGTH(results.ScalarEncoded) <> DATALENGTH(cases.ExpectedEncoded)
              OR results.ScalarDecoded <> cases.Value)
   )
    THROW 52816, N'Die Plusziffer-Vektoren sind fehlgeschlagen.', 1;

DECLARE @RejectedEncode TABLE (Value bigint NULL, Alphabet varchar(93) NULL);
INSERT INTO @RejectedEncode (Value, Alphabet)
VALUES (NULL, @Decimal), (1, NULL), (1, '0'), (1, '001'),
       (1, '0-1'), (1, '0 1'), (1, '0' + CHAR(31));
IF EXISTS
   (
       SELECT 1 FROM @RejectedEncode AS cases
       OUTER APPLY
       (
           SELECT COUNT_BIG(*) AS ActualRows, MAX(EncodedValue) AS EncodedValue
           FROM toolbelt_conversion.TVF_IntegerToBase(cases.Value, cases.Alphabet)
       ) AS actual
       WHERE actual.ActualRows <> 1 OR actual.EncodedValue IS NOT NULL
   )
    THROW 52817, N'Der einzeilige Encode-Ablehnungsvertrag ist fehlgeschlagen.', 1;

DECLARE @RejectedDecode TABLE (EncodedValue varchar(65) NULL, Alphabet varchar(93) NULL);
INSERT INTO @RejectedDecode (EncodedValue, Alphabet)
VALUES (NULL, @Decimal), ('1', NULL),
       ('1', '0'), ('1', '001'), ('1', '0-1'), ('1', '0 1'), ('1', '0' + CHAR(31)),
       ('', @Decimal), ('+1', @Decimal), ('00', @Decimal), ('01', @Decimal),
       ('-0', @Decimal), (' 1', @Decimal), ('1 ', @Decimal), ('G', @Hex),
       ('9223372036854775808', @Decimal), ('-9223372036854775809', @Decimal);
IF EXISTS
   (
       SELECT 1 FROM @RejectedDecode AS cases
       OUTER APPLY
       (
           SELECT COUNT_BIG(*) AS ActualRows, MAX(DecodedValue) AS DecodedValue
           FROM toolbelt_conversion.TVF_TryBaseToInteger(cases.EncodedValue, cases.Alphabet)
       ) AS actual
       WHERE actual.ActualRows <> 1 OR actual.DecodedValue IS NOT NULL
   )
    THROW 52818, N'Der einzeilige Decode-Ablehnungsvertrag ist fehlgeschlagen.', 1;

DECLARE @PlusRejected TABLE (EncodedValue varchar(65) NOT NULL, Alphabet varchar(93) NOT NULL);
INSERT INTO @PlusRejected (EncodedValue, Alphabet)
VALUES ('+1', '+1'), ('1+', '1+'), ('-+', '+1'), ('-1', '1+'),
       ('+' + REPLICATE('1', 63), '1+');
DECLARE @PlusRejectedResults TABLE
    (ScalarDecoded bigint NULL, DecodeRows bigint NOT NULL, DecodedValue bigint NULL);
INSERT INTO @PlusRejectedResults (ScalarDecoded, DecodeRows, DecodedValue)
SELECT toolbelt_conversion.SVF_TryBaseToInteger(cases.EncodedValue, cases.Alphabet),
       actual.ActualRows, actual.DecodedValue
FROM @PlusRejected AS cases
OUTER APPLY
(
    SELECT COUNT_BIG(*) AS ActualRows, MAX(DecodedValue) AS DecodedValue
    FROM toolbelt_conversion.TVF_TryBaseToInteger(cases.EncodedValue, cases.Alphabet)
) AS actual;
IF EXISTS
   (
       SELECT 1 FROM @PlusRejectedResults
       WHERE ScalarDecoded IS NOT NULL OR DecodeRows <> 1 OR DecodedValue IS NOT NULL
   )
    THROW 52819, N'Der Plusziffer-Ablehnungsvertrag ist fehlgeschlagen.', 1;

PRINT N'Integer-Base Contract-Tests für Compatibility Level '
    + CONVERT(nvarchar(3), @CompatibilityLevel) + N': erfolgreich';
GO
