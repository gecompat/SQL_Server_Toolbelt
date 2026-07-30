-- SQL Server Toolbelt
-- Objekt: toolbelt_conversion.TVF_TryBaseToInteger
-- Vertrag: Relationaler Kern für die strikt kanonische bigint-Decodierung.

CREATE OR ALTER FUNCTION [toolbelt_conversion].[TVF_TryBaseToInteger]
(
      @EncodedValue varchar(65)
    , @Alphabet varchar(93)
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    WITH
    Digits (Digit) AS
    (
        SELECT Digit
        FROM
        (
            VALUES
                  (0), (1), (2), (3), (4)
                , (5), (6), (7), (8), (9)
        ) AS values_0_to_9(Digit)
    ),
    Positions (Position) AS
    (
        SELECT tens.Digit * 10 + ones.Digit + 1
        FROM Digits AS tens
        CROSS JOIN Digits AS ones
        WHERE tens.Digit * 10 + ones.Digit + 1 <= 93
    ),
    Input AS
    (
        SELECT
              Base = DATALENGTH(@Alphabet)
            , InputLength = DATALENGTH(@EncodedValue)
            , IsNegative =
                  CONVERT
                  (
                        bit
                      , CASE WHEN LEFT(@EncodedValue, 1) = '-' THEN 1 ELSE 0 END
                  )
            , StartPosition =
                  CASE WHEN LEFT(@EncodedValue, 1) = '-' THEN 2 ELSE 1 END
    ),
    Validated AS
    (
        SELECT
              input.Base
            , input.InputLength
            , input.IsNegative
            , input.StartPosition
            , MagnitudeLimit =
                  CONVERT
                  (
                        decimal(38, 0)
                      , CASE
                            WHEN input.IsNegative = 1
                                THEN 9223372036854775808
                            ELSE 9223372036854775807
                        END
                  )
            , IsValid =
                  CONVERT
                  (
                        bit
                      , CASE
                            WHEN @EncodedValue IS NULL
                              OR @Alphabet IS NULL
                              OR input.Base < 2
                              OR input.Base > 93
                              OR input.InputLength = 0
                              OR LEFT(@EncodedValue, 1) = '+'
                              OR
                                 (
                                     input.IsNegative = 1
                                     AND input.InputLength = 1
                                 )
                              OR
                                 (
                                     input.InputLength - input.StartPosition + 1 > 1
                                     AND SUBSTRING
                                         (
                                               @EncodedValue
                                             , input.StartPosition
                                             , 1
                                         ) COLLATE Latin1_General_100_BIN2
                                         = SUBSTRING(@Alphabet, 1, 1)
                                             COLLATE Latin1_General_100_BIN2
                                 )
                              OR
                                 (
                                     input.IsNegative = 1
                                     AND input.InputLength
                                           - input.StartPosition + 1 = 1
                                     AND SUBSTRING
                                         (
                                               @EncodedValue
                                             , input.StartPosition
                                             , 1
                                         ) COLLATE Latin1_General_100_BIN2
                                         = SUBSTRING(@Alphabet, 1, 1)
                                             COLLATE Latin1_General_100_BIN2
                                 )
                              OR EXISTS
                                 (
                                     SELECT 1
                                     FROM Positions
                                     WHERE Position <= input.Base
                                       AND
                                       (
                                           DATALENGTH
                                           (
                                               SUBSTRING
                                               (
                                                     @Alphabet
                                                   , Position
                                                   , 1
                                               )
                                           ) <> 1
                                           OR ASCII
                                           (
                                               SUBSTRING
                                               (
                                                     @Alphabet
                                                   , Position
                                                   , 1
                                               )
                                           ) NOT BETWEEN 33 AND 126
                                           OR SUBSTRING
                                              (
                                                    @Alphabet
                                                  , Position
                                                  , 1
                                              ) = '-'
                                           OR CHARINDEX
                                              (
                                                  SUBSTRING
                                                  (
                                                        @Alphabet
                                                      , Position
                                                      , 1
                                                  ) COLLATE Latin1_General_100_BIN2
                                                , LEFT
                                                  (
                                                        @Alphabet
                                                      , Position - 1
                                                  ) COLLATE Latin1_General_100_BIN2
                                              ) > 0
                                       )
                                 )
                                THEN 0
                            ELSE 1
                        END
                  )
        FROM Input AS input
    ),
    Decoding AS
    (
        SELECT
              Position = CONVERT(int, validated.StartPosition)
            , validated.Base
            , validated.InputLength
            , validated.IsNegative
            , validated.MagnitudeLimit
            , IsValid = CONVERT(bit, validated.IsValid)
            , Accumulated = CONVERT(decimal(38, 0), 0)
        FROM Validated AS validated

        UNION ALL

        SELECT
              decoding.Position + 1
            , decoding.Base
            , decoding.InputLength
            , decoding.IsNegative
            , decoding.MagnitudeLimit
            , CONVERT
              (
                    bit
                  , CASE
                        WHEN digit.AlphabetPosition = 0
                          OR decoding.Accumulated
                             > FLOOR
                               (
                                   (
                                       decoding.MagnitudeLimit
                                       - digit.DigitValue
                                   ) / decoding.Base
                               )
                            THEN 0
                        ELSE 1
                    END
              )
            , CONVERT
              (
                    decimal(38, 0)
                  , CASE
                        WHEN digit.AlphabetPosition = 0
                          OR decoding.Accumulated
                             > FLOOR
                               (
                                   (
                                       decoding.MagnitudeLimit
                                       - digit.DigitValue
                                   ) / decoding.Base
                               )
                            THEN decoding.Accumulated
                        ELSE decoding.Accumulated * decoding.Base
                             + digit.DigitValue
                    END
              )
        FROM Decoding AS decoding
        CROSS APPLY
        (
            SELECT AlphabetPosition =
                CHARINDEX
                (
                    SUBSTRING(@EncodedValue, decoding.Position, 1)
                        COLLATE Latin1_General_100_BIN2
                  , @Alphabet COLLATE Latin1_General_100_BIN2
                )
        ) AS alphabet
        CROSS APPLY
        (
            SELECT
                  alphabet.AlphabetPosition
                , DigitValue =
                      CASE
                          WHEN alphabet.AlphabetPosition = 0 THEN 0
                          ELSE alphabet.AlphabetPosition - 1
                      END
        ) AS digit
        WHERE decoding.IsValid = 1
          AND decoding.Position <= decoding.InputLength
    ),
    Completed AS
    (
        SELECT TOP (1)
              decoding.Position
            , decoding.InputLength
            , decoding.IsNegative
            , decoding.IsValid
            , decoding.Accumulated
        FROM Decoding AS decoding
        WHERE decoding.IsValid = 0
           OR decoding.Position > decoding.InputLength
        ORDER BY decoding.Position DESC
    )
    SELECT DecodedValue =
        CONVERT
        (
              bigint
            , CASE
                  WHEN completed.IsValid = 0
                    OR completed.Position <= completed.InputLength
                      THEN NULL
                  WHEN completed.IsNegative = 1
                      THEN -completed.Accumulated
                  ELSE completed.Accumulated
              END
        )
    FROM Completed AS completed
);
GO
