-- SQL Server Toolbelt
-- Objekt: toolbelt_conversion.SVF_TryBaseToInteger
-- Vertrag: Strikte kanonische Decodierung in den vollständigen bigint-Bereich.

CREATE OR ALTER FUNCTION [toolbelt_conversion].[SVF_TryBaseToInteger]
(
      @EncodedValue varchar(65)
    , @Alphabet varchar(93)
)
RETURNS bigint
WITH SCHEMABINDING
AS
BEGIN
    IF @EncodedValue IS NULL OR @Alphabet IS NULL
        RETURN NULL;

    DECLARE
          @Base int = DATALENGTH(@Alphabet)
        , @InputLength int = DATALENGTH(@EncodedValue);

    IF @Base < 2 OR @Base > 93 OR @InputLength = 0
        RETURN NULL;

    DECLARE
          @AlphabetIndex int = 1
        , @Character varchar(1);

    WHILE @AlphabetIndex <= @Base
    BEGIN
        SET @Character = SUBSTRING(@Alphabet, @AlphabetIndex, 1);

        IF ASCII(@Character) < 33
           OR ASCII(@Character) > 126
           OR @Character = '-'
           OR CHARINDEX(
                  @Character COLLATE Latin1_General_100_BIN2
                , LEFT(@Alphabet, @AlphabetIndex - 1)
                    COLLATE Latin1_General_100_BIN2
              ) > 0
            RETURN NULL;

        SET @AlphabetIndex += 1;
    END;

    DECLARE
          @IsNegative bit = 0
        , @Position int = 1;

    IF LEFT(@EncodedValue, 1) = '+'
        RETURN NULL;

    IF LEFT(@EncodedValue, 1) = '-'
    BEGIN
        IF @InputLength = 1
            RETURN NULL;

        SET @IsNegative = 1;
        SET @Position = 2;
    END;

    DECLARE @DigitCount int = @InputLength - @Position + 1;
    DECLARE @ZeroCharacter varchar(1) = SUBSTRING(@Alphabet, 1, 1);

    IF @DigitCount > 1
       AND SUBSTRING(@EncodedValue, @Position, 1)
           COLLATE Latin1_General_100_BIN2
           = @ZeroCharacter COLLATE Latin1_General_100_BIN2
        RETURN NULL;

    IF @IsNegative = 1
       AND @DigitCount = 1
       AND SUBSTRING(@EncodedValue, @Position, 1)
           COLLATE Latin1_General_100_BIN2
           = @ZeroCharacter COLLATE Latin1_General_100_BIN2
        RETURN NULL;

    DECLARE
          @Limit decimal(38, 0) =
              CASE
                  WHEN @IsNegative = 1
                      THEN CONVERT(decimal(38, 0), 9223372036854775808)
                  ELSE CONVERT(decimal(38, 0), 9223372036854775807)
              END
        , @Accumulated decimal(38, 0) = 0
        , @AlphabetPosition int
        , @Digit int;

    WHILE @Position <= @InputLength
    BEGIN
        SET @Character = SUBSTRING(@EncodedValue, @Position, 1);
        SET @AlphabetPosition = CHARINDEX(
              @Character COLLATE Latin1_General_100_BIN2
            , @Alphabet COLLATE Latin1_General_100_BIN2
        );

        IF @AlphabetPosition = 0
            RETURN NULL;

        SET @Digit = @AlphabetPosition - 1;

        IF @Accumulated > FLOOR((@Limit - @Digit) / @Base)
            RETURN NULL;

        SET @Accumulated = (@Accumulated * @Base) + @Digit;
        SET @Position += 1;
    END;

    IF @IsNegative = 1
        RETURN CONVERT(bigint, -@Accumulated);

    RETURN CONVERT(bigint, @Accumulated);
END;
