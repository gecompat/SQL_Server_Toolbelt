-- ============================================================================
-- Objekt:       toolbelt_validation.TVF_CompareSemanticVersion
-- Zweck:        Zwei strikte Semantic-Version-2.0.0-Werte vergleichen
-- Resultset:    genau eine Zeile; ComparisonResult smallint
-- Fehlerwert:   NULL, wenn mindestens eine Eingabe ungültig ist
-- Performance:  kanonischer relationaler Kern für APPLY
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_validation].[TVF_CompareSemanticVersion]
(
      @LeftVersion  varchar(8000)
    , @RightVersion varchar(8000)
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
    LeftParsed AS
    (
        SELECT *
        FROM toolbelt_validation.TVF_ParseSemanticVersion(@LeftVersion)
    ),
    RightParsed AS
    (
        SELECT *
        FROM toolbelt_validation.TVF_ParseSemanticVersion(@RightVersion)
    ),
    Parsed AS
    (
        SELECT
              LeftIsValid = left_version.IsValid
            , LeftMajor = left_version.Major
            , LeftMinor = left_version.Minor
            , LeftPatch = left_version.Patch
            , LeftPreRelease = left_version.PreRelease
            , RightIsValid = right_version.IsValid
            , RightMajor = right_version.Major
            , RightMinor = right_version.Minor
            , RightPatch = right_version.Patch
            , RightPreRelease = right_version.PreRelease
        FROM LeftParsed AS left_version
        CROSS JOIN RightParsed AS right_version
    ),
    CoreComparison AS
    (
        SELECT
              parsed.*
            , CoreResult =
                  CONVERT
                  (
                        smallint
                      , CASE
                            WHEN DATALENGTH(LeftMajor)
                                   < DATALENGTH(RightMajor) THEN -1
                            WHEN DATALENGTH(LeftMajor)
                                   > DATALENGTH(RightMajor) THEN 1
                            WHEN LeftMajor COLLATE Latin1_General_100_BIN2
                                   < RightMajor COLLATE Latin1_General_100_BIN2
                                THEN -1
                            WHEN LeftMajor COLLATE Latin1_General_100_BIN2
                                   > RightMajor COLLATE Latin1_General_100_BIN2
                                THEN 1
                            WHEN DATALENGTH(LeftMinor)
                                   < DATALENGTH(RightMinor) THEN -1
                            WHEN DATALENGTH(LeftMinor)
                                   > DATALENGTH(RightMinor) THEN 1
                            WHEN LeftMinor COLLATE Latin1_General_100_BIN2
                                   < RightMinor COLLATE Latin1_General_100_BIN2
                                THEN -1
                            WHEN LeftMinor COLLATE Latin1_General_100_BIN2
                                   > RightMinor COLLATE Latin1_General_100_BIN2
                                THEN 1
                            WHEN DATALENGTH(LeftPatch)
                                   < DATALENGTH(RightPatch) THEN -1
                            WHEN DATALENGTH(LeftPatch)
                                   > DATALENGTH(RightPatch) THEN 1
                            WHEN LeftPatch COLLATE Latin1_General_100_BIN2
                                   < RightPatch COLLATE Latin1_General_100_BIN2
                                THEN -1
                            WHEN LeftPatch COLLATE Latin1_General_100_BIN2
                                   > RightPatch COLLATE Latin1_General_100_BIN2
                                THEN 1
                            ELSE 0
                        END
                  )
        FROM Parsed AS parsed
    ),
    LeftTokens AS
    (
        SELECT
              Ordinal = ROW_NUMBER() OVER (ORDER BY positions.Position)
            , Identifier = token.Identifier
            , IsNumeric =
                  CONVERT
                  (
                        bit
                      , CASE
                            WHEN token.Identifier
                                     COLLATE Latin1_General_100_BIN2
                                     NOT LIKE '%[^0-9]%'
                                     COLLATE Latin1_General_100_BIN2
                                THEN 1
                            ELSE 0
                        END
                  )
        FROM CoreComparison AS compared
        CROSS JOIN Positions AS positions
        CROSS APPLY
        (
            SELECT NextDot = CHARINDEX
            (
                  '.'
                , compared.LeftPreRelease
                      COLLATE Latin1_General_100_BIN2
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
                                   compared.LeftPreRelease
                                 , positions.Position
                                 , DATALENGTH(compared.LeftPreRelease)
                                   - positions.Position + 1
                             )
                    ELSE SUBSTRING
                         (
                               compared.LeftPreRelease
                             , positions.Position
                             , boundary.NextDot - positions.Position
                         )
                END
        ) AS token
        WHERE compared.LeftPreRelease IS NOT NULL
          AND positions.Position <= DATALENGTH(compared.LeftPreRelease)
          AND
          (
              positions.Position = 1
              OR SUBSTRING
                 (
                       compared.LeftPreRelease
                     , positions.Position - 1
                     , 1
                 ) = '.'
          )
    ),
    RightTokens AS
    (
        SELECT
              Ordinal = ROW_NUMBER() OVER (ORDER BY positions.Position)
            , Identifier = token.Identifier
            , IsNumeric =
                  CONVERT
                  (
                        bit
                      , CASE
                            WHEN token.Identifier
                                     COLLATE Latin1_General_100_BIN2
                                     NOT LIKE '%[^0-9]%'
                                     COLLATE Latin1_General_100_BIN2
                                THEN 1
                            ELSE 0
                        END
                  )
        FROM CoreComparison AS compared
        CROSS JOIN Positions AS positions
        CROSS APPLY
        (
            SELECT NextDot = CHARINDEX
            (
                  '.'
                , compared.RightPreRelease
                      COLLATE Latin1_General_100_BIN2
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
                                   compared.RightPreRelease
                                 , positions.Position
                                 , DATALENGTH(compared.RightPreRelease)
                                   - positions.Position + 1
                             )
                    ELSE SUBSTRING
                         (
                               compared.RightPreRelease
                             , positions.Position
                             , boundary.NextDot - positions.Position
                         )
                END
        ) AS token
        WHERE compared.RightPreRelease IS NOT NULL
          AND positions.Position <= DATALENGTH(compared.RightPreRelease)
          AND
          (
              positions.Position = 1
              OR SUBSTRING
                 (
                       compared.RightPreRelease
                     , positions.Position - 1
                     , 1
                 ) = '.'
          )
    ),
    TokenPairs AS
    (
        SELECT
              Ordinal = COALESCE(left_token.Ordinal, right_token.Ordinal)
            , TokenResult =
                  CONVERT
                  (
                        smallint
                      , CASE
                            WHEN left_token.Ordinal IS NULL THEN -1
                            WHEN right_token.Ordinal IS NULL THEN 1
                            WHEN left_token.IsNumeric = 1
                             AND right_token.IsNumeric = 0 THEN -1
                            WHEN left_token.IsNumeric = 0
                             AND right_token.IsNumeric = 1 THEN 1
                            WHEN left_token.IsNumeric = 1
                             AND DATALENGTH(left_token.Identifier)
                                   < DATALENGTH(right_token.Identifier) THEN -1
                            WHEN left_token.IsNumeric = 1
                             AND DATALENGTH(left_token.Identifier)
                                   > DATALENGTH(right_token.Identifier) THEN 1
                            WHEN left_token.Identifier
                                     COLLATE Latin1_General_100_BIN2
                                   < right_token.Identifier
                                     COLLATE Latin1_General_100_BIN2 THEN -1
                            WHEN left_token.Identifier
                                     COLLATE Latin1_General_100_BIN2
                                   > right_token.Identifier
                                     COLLATE Latin1_General_100_BIN2 THEN 1
                            ELSE 0
                        END
                  )
        FROM LeftTokens AS left_token
        FULL OUTER JOIN RightTokens AS right_token
            ON right_token.Ordinal = left_token.Ordinal
    ),
    FirstTokenDifference AS
    (
        SELECT TOP (1) TokenResult
        FROM TokenPairs
        WHERE TokenResult <> 0
        ORDER BY Ordinal
    )
    SELECT ComparisonResult =
        CONVERT
        (
              smallint
            , CASE
                  WHEN compared.LeftIsValid = 0
                    OR compared.RightIsValid = 0
                      THEN NULL
                  WHEN compared.CoreResult <> 0
                      THEN compared.CoreResult
                  WHEN compared.LeftPreRelease IS NULL
                   AND compared.RightPreRelease IS NULL
                      THEN 0
                  WHEN compared.LeftPreRelease IS NULL
                      THEN 1
                  WHEN compared.RightPreRelease IS NULL
                      THEN -1
                  ELSE COALESCE(difference.TokenResult, 0)
              END
        )
    FROM CoreComparison AS compared
    OUTER APPLY
    (
        SELECT TokenResult
        FROM FirstTokenDifference
    ) AS difference
);
GO
