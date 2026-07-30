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

IF toolbelt_conversion.SVF_IntegerToBase(0, @Decimal) <> '0'
   OR toolbelt_conversion.SVF_IntegerToBase(10, @Hex) <> 'A'
   OR toolbelt_conversion.SVF_IntegerToBase(255, @Hex) <> 'FF'
   OR toolbelt_conversion.SVF_IntegerToBase(-255, @Hex) <> '-FF'
   OR toolbelt_conversion.SVF_IntegerToBase(9223372036854775807, @Hex)
      <> '7FFFFFFFFFFFFFFF'
   OR toolbelt_conversion.SVF_IntegerToBase
      (
          CONVERT(bigint, -9223372036854775807) - 1,
          @Hex
      ) <> '-8000000000000000'
    THROW 52804, N'Die kanonischen Encode-Vektoren sind fehlgeschlagen.', 1;

IF toolbelt_conversion.SVF_TryBaseToInteger('0', @Decimal) <> 0
   OR toolbelt_conversion.SVF_TryBaseToInteger('FF', @Hex) <> 255
   OR toolbelt_conversion.SVF_TryBaseToInteger('-FF', @Hex) <> -255
   OR toolbelt_conversion.SVF_TryBaseToInteger
      (
          '7FFFFFFFFFFFFFFF',
          @Hex
      ) <> 9223372036854775807
   OR toolbelt_conversion.SVF_TryBaseToInteger
      (
          '-8000000000000000',
          @Hex
      ) <> CONVERT(bigint, -9223372036854775807) - 1
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

IF EXISTS
   (
       SELECT 1
       FROM @Values AS value_set
       CROSS JOIN @Alphabets AS alphabet_set
       WHERE toolbelt_conversion.SVF_TryBaseToInteger
             (
                 toolbelt_conversion.SVF_IntegerToBase
                 (
                     value_set.Value,
                     alphabet_set.Alphabet
                 ),
                 alphabet_set.Alphabet
             ) <> value_set.Value
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

IF toolbelt_conversion.SVF_IntegerToBase(1, 'aA') <> 'A'
   OR toolbelt_conversion.SVF_TryBaseToInteger('A', 'aA') <> 1
   OR toolbelt_conversion.SVF_TryBaseToInteger('a', 'aA') <> 0
    THROW 52811, N'Der binäre Case-Sensitivity-Vertrag ist fehlgeschlagen.', 1;

IF EXISTS
   (
       SELECT 1
       FROM @Values AS value_set
       CROSS JOIN @Alphabets AS alphabet_set
       CROSS APPLY toolbelt_conversion.TVF_IntegerToBase
                   (
                         value_set.Value
                       , alphabet_set.Alphabet
                   ) AS encoded
       CROSS APPLY toolbelt_conversion.TVF_TryBaseToInteger
                   (
                         encoded.EncodedValue
                       , alphabet_set.Alphabet
                   ) AS decoded
       WHERE encoded.EncodedValue
             <> toolbelt_conversion.SVF_IntegerToBase
                (
                      value_set.Value
                    , alphabet_set.Alphabet
                )
          OR decoded.DecodedValue <> value_set.Value
          OR decoded.DecodedValue
             <> toolbelt_conversion.SVF_TryBaseToInteger
                (
                      encoded.EncodedValue
                    , alphabet_set.Alphabet
                )
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

PRINT N'Integer-Base Contract-Tests für Compatibility Level '
    + CONVERT(nvarchar(3), @CompatibilityLevel) + N': erfolgreich';
GO
