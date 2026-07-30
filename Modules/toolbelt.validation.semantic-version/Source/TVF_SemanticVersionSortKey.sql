-- ============================================================================
-- Objekt:       toolbelt_validation.TVF_SemanticVersionSortKey
-- Zweck:        Binären Sort Key für Semantic-Version-2.0.0 erzeugen
-- Resultset:    genau eine Zeile; SortKey varbinary(max)
-- Fehlerwert:   NULL bei ungültiger Eingabe
-- Performance:  kanonischer relationaler Kern für APPLY
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_validation].[TVF_SemanticVersionSortKey]
(
    @Version varchar(8000)
)
RETURNS TABLE
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
        SELECT
            thousands.Digit * 1000
            + hundreds.Digit * 100
            + tens.Digit * 10
            + ones.Digit
            + 1
        FROM Digits AS thousands
        CROSS JOIN Digits AS hundreds
        CROSS JOIN Digits AS tens
        CROSS JOIN Digits AS ones
        WHERE thousands.Digit * 1000
              + hundreds.Digit * 100
              + tens.Digit * 10
              + ones.Digit < 8000
    ),
    Parsed AS
    (
        SELECT *
        FROM toolbelt_validation.TVF_ParseSemanticVersion(@Version)
    ),
    Tokens AS
    (
        SELECT
              Ordinal = ROW_NUMBER() OVER (ORDER BY positions.Position)
            , FragmentHex =
                  CONVERT
                  (
                        varchar(max)
                      , CASE
                            WHEN token.Identifier
                                     COLLATE Latin1_General_100_BIN2
                                     NOT LIKE '%[^0-9]%'
                                     COLLATE Latin1_General_100_BIN2
                                THEN
                                    '01'
                                    + CONVERT
                                      (
                                            varchar(4)
                                          , CONVERT
                                            (
                                                  binary(2)
                                                , CONVERT
                                                  (
                                                        smallint
                                                      , DATALENGTH
                                                        (
                                                            token.Identifier
                                                        )
                                                  )
                                            )
                                          , 2
                                      )
                                    + CONVERT
                                      (
                                            varchar(max)
                                          , CONVERT
                                            (
                                                  varbinary(max)
                                                , token.Identifier
                                            )
                                          , 2
                                      )
                                    + '00'
                            ELSE
                                '02'
                                + CONVERT
                                  (
                                        varchar(max)
                                      , CONVERT
                                        (
                                              varbinary(max)
                                            , token.Identifier
                                        )
                                      , 2
                                  )
                                + '00'
                        END
                  )
        FROM Parsed AS parsed
        CROSS JOIN Positions AS positions
        CROSS APPLY
        (
            SELECT NextDot = CHARINDEX
            (
                  '.'
                , parsed.PreRelease COLLATE Latin1_General_100_BIN2
                , positions.Position
            )
        ) AS boundary
        CROSS APPLY
        (
            SELECT Identifier =
                CASE
                    WHEN boundary.NextDot = 0
                        THEN SUBSTRING
                             (
                                   parsed.PreRelease
                                 , positions.Position
                                 , DATALENGTH(parsed.PreRelease)
                                   - positions.Position + 1
                             )
                    ELSE SUBSTRING
                         (
                               parsed.PreRelease
                             , positions.Position
                             , boundary.NextDot - positions.Position
                         )
                END
        ) AS token
        WHERE parsed.IsValid = 1
          AND parsed.PreRelease IS NOT NULL
          AND positions.Position <= DATALENGTH(parsed.PreRelease)
          AND
          (
              positions.Position = 1
              OR SUBSTRING
                 (
                       parsed.PreRelease
                     , positions.Position - 1
                     , 1
                 ) = '.'
          )
    ),
    TokenAggregate AS
    (
        SELECT TokenHex =
            STRING_AGG
            (
                  CONVERT(varchar(max), FragmentHex)
                , ''
            ) WITHIN GROUP (ORDER BY Ordinal)
        FROM Tokens
    ),
    KeyText AS
    (
        SELECT
              parsed.IsValid
            , KeyHex =
                  CONVERT
                  (
                        varchar(max)
                      , '01'
                        + CONVERT
                          (
                                varchar(4)
                              , CONVERT
                                (
                                      binary(2)
                                    , CONVERT
                                      (
                                            smallint
                                          , DATALENGTH(parsed.Major)
                                      )
                                )
                              , 2
                          )
                        + CONVERT
                          (
                                varchar(max)
                              , CONVERT(varbinary(max), parsed.Major)
                              , 2
                          )
                        + '00'
                        + '01'
                        + CONVERT
                          (
                                varchar(4)
                              , CONVERT
                                (
                                      binary(2)
                                    , CONVERT
                                      (
                                            smallint
                                          , DATALENGTH(parsed.Minor)
                                      )
                                )
                              , 2
                          )
                        + CONVERT
                          (
                                varchar(max)
                              , CONVERT(varbinary(max), parsed.Minor)
                              , 2
                          )
                        + '00'
                        + '01'
                        + CONVERT
                          (
                                varchar(4)
                              , CONVERT
                                (
                                      binary(2)
                                    , CONVERT
                                      (
                                            smallint
                                          , DATALENGTH(parsed.Patch)
                                      )
                                )
                              , 2
                          )
                        + CONVERT
                          (
                                varchar(max)
                              , CONVERT(varbinary(max), parsed.Patch)
                              , 2
                          )
                        + '00'
                        + CASE
                              WHEN parsed.PreRelease IS NULL
                                  THEN '02'
                              ELSE '01'
                                   + COALESCE(aggregate.TokenHex, '')
                                   + '00'
                          END
                  )
        FROM Parsed AS parsed
        CROSS JOIN TokenAggregate AS aggregate
    )
    SELECT SortKey =
        CASE
            WHEN IsValid = 0
                THEN CONVERT(varbinary(max), NULL)
            ELSE CONVERT(varbinary(max), KeyHex, 2)
        END
    FROM KeyText
);
GO
