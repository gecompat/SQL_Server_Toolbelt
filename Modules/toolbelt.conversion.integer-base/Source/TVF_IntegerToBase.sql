-- SQL Server Toolbelt
-- Objekt: toolbelt_conversion.TVF_IntegerToBase
-- Vertrag: Kanonischer relationaler Kern für die bigint-Codierung.

CREATE OR ALTER FUNCTION [toolbelt_conversion].[TVF_IntegerToBase]
(
      @Value bigint
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
            , Magnitude =
                  CONVERT
                  (
                        decimal(38, 0)
                      , CASE
                            WHEN @Value < 0
                                THEN -CONVERT(decimal(38, 0), @Value)
                            ELSE CONVERT(decimal(38, 0), @Value)
                        END
                  )
    ),
    Validated AS
    (
        SELECT
              input.Base
            , input.Magnitude
            , IsValid =
                  CONVERT
                  (
                        bit
                      , CASE
                            WHEN @Value IS NULL
                              OR @Alphabet IS NULL
                              OR input.Base < 2
                              OR input.Base > 93
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
    Encoding AS
    (
        SELECT
              Step = CONVERT(int, 0)
            , validated.Base
            , validated.IsValid
            , Magnitude =
                  CONVERT
                  (
                        decimal(38, 0)
                      , CASE
                            WHEN validated.IsValid = 1
                                THEN validated.Magnitude
                            ELSE 0
                        END
                  )
            , EncodedValue = CONVERT(varchar(65), '')
        FROM Validated AS validated

        UNION ALL

        SELECT
              encoding.Step + 1
            , encoding.Base
            , encoding.IsValid
            , CONVERT
              (
                    decimal(38, 0)
                  , FLOOR(encoding.Magnitude / encoding.Base)
              )
            , CONVERT
              (
                    varchar(65)
                  , SUBSTRING
                    (
                          @Alphabet
                        , CONVERT(int, encoding.Magnitude % encoding.Base) + 1
                        , 1
                    )
                    + encoding.EncodedValue
              )
        FROM Encoding AS encoding
        WHERE encoding.IsValid = 1
          AND encoding.Magnitude > 0
    ),
    Completed AS
    (
        SELECT TOP (1)
            encoding.EncodedValue
        FROM Encoding AS encoding
        WHERE encoding.Magnitude = 0
        ORDER BY encoding.Step DESC
    )
    SELECT EncodedValue =
        CONVERT
        (
              varchar(65)
            , CASE
                  WHEN validated.IsValid = 0
                      THEN NULL
                  WHEN @Value = 0
                      THEN SUBSTRING(@Alphabet, 1, 1)
                  WHEN @Value < 0
                      THEN '-' + completed.EncodedValue
                  ELSE completed.EncodedValue
              END
        )
    FROM Validated AS validated
    CROSS JOIN Completed AS completed
);
GO
