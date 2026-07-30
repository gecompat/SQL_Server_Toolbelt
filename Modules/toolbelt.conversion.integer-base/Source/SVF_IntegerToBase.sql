-- SQL Server Toolbelt
-- Objekt: toolbelt_conversion.SVF_IntegerToBase
-- Vertrag: Kanonische bigint-Codierung mit explizitem ASCII-Alphabet.

CREATE OR ALTER FUNCTION [toolbelt_conversion].[SVF_IntegerToBase]
(
      @Value bigint
    , @Alphabet varchar(93)
)
RETURNS varchar(65)
WITH SCHEMABINDING
AS
BEGIN
    IF @Value IS NULL OR @Alphabet IS NULL
        RETURN NULL;

    DECLARE @Base int = DATALENGTH(@Alphabet);

    IF @Base < 2 OR @Base > 93
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

    IF @Value = 0
        RETURN SUBSTRING(@Alphabet, 1, 1);

    DECLARE
          @Magnitude decimal(38, 0) =
              CASE
                  WHEN @Value < 0
                      THEN -CONVERT(decimal(38, 0), @Value)
                  ELSE CONVERT(decimal(38, 0), @Value)
              END
        , @Encoded varchar(65) = ''
        , @Digit int;

    WHILE @Magnitude > 0
    BEGIN
        SET @Digit = CONVERT(int, @Magnitude % @Base);
        SET @Encoded = SUBSTRING(@Alphabet, @Digit + 1, 1) + @Encoded;
        SET @Magnitude = FLOOR(@Magnitude / @Base);
    END;

    IF @Value < 0
        SET @Encoded = '-' + @Encoded;

    RETURN @Encoded;
END;
