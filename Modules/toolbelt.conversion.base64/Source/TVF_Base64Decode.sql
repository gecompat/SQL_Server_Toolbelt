-- ============================================================================
-- Objekt:          toolbelt_conversion.TVF_Base64Decode
-- Zweck:           Base64 oder Base64URL in Binärdaten decodieren
-- Parameter:       @Value varchar(max)
-- Resultset:       genau eine Zeile; DecodedValue varbinary(max)
-- Dependencies:    keine Toolbelt-Module; T-SQL/XML-Provider
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     kanonischer relationaler Kern für APPLY
-- Collation:       ASCII-Vertrag; Syntaxprüfung ist binär
-- Einschränkungen: ignoriert nur Space, Tab, CR und LF
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_conversion].[TVF_Base64Decode]
(
    @Value varchar(max)
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    WITH Normalized AS
    (
        SELECT NormalizedValue =
            REPLACE
            (
                REPLACE
                (
                    REPLACE
                    (
                        REPLACE
                        (
                            REPLACE
                            (
                                REPLACE(@Value, '-', '+')
                              , '_'
                              , '/'
                            )
                          , CHAR(32)
                          , ''
                        )
                      , CHAR(9)
                      , ''
                    )
                  , CHAR(13)
                  , ''
                )
              , CHAR(10)
              , ''
            )
    ),
    Shape AS
    (
        SELECT
              NormalizedValue
            , ValueLength = DATALENGTH(NormalizedValue)
            , FirstPadding = NULLIF
              (
                  CHARINDEX
                  (
                        '='
                      , NormalizedValue COLLATE Latin1_General_100_BIN2
                  )
                , 0
              )
        FROM Normalized
    ),
    Validation AS
    (
        SELECT
              NormalizedValue
            , ValueLength
            , FirstPadding
            , PaddingCount =
                  CASE
                      WHEN FirstPadding IS NULL THEN 0
                      ELSE ValueLength - FirstPadding + 1
                  END
            , LengthRemainder =
                  ISNULL(FirstPadding - 1, ValueLength) % 4
            , HasInvalidCharacter =
                  CASE
                      WHEN NormalizedValue COLLATE Latin1_General_100_BIN2
                               LIKE '%[^A-Za-z0-9+/=]%'
                          THEN 1
                      ELSE 0
                  END
        FROM Shape
    ),
    FormatCheck AS
    (
        SELECT
              NormalizedValue
            , FirstPadding
            , LengthRemainder
            , InvalidFormat =
              CASE
                  WHEN @Value IS NULL
                      THEN 0
                  WHEN HasInvalidCharacter = 1
                    OR
                    (
                        FirstPadding IS NOT NULL
                        AND
                        (
                            PaddingCount NOT IN (1, 2)
                            OR REPLACE
                               (
                                   SUBSTRING
                                   (
                                         NormalizedValue
                                       , FirstPadding
                                       , PaddingCount
                                   )
                                 , '='
                                 , ''
                               ) <> ''
                            OR ValueLength % 4 <> 0
                            OR
                               (
                                   PaddingCount = 1
                                   AND (FirstPadding - 1) % 4 <> 3
                               )
                            OR
                               (
                                   PaddingCount = 2
                                   AND (FirstPadding - 1) % 4 <> 2
                               )
                        )
                    )
                    OR (FirstPadding IS NULL AND LengthRemainder = 1)
                      THEN 1
                  ELSE 0
              END
        FROM Validation
    ),
    Canonical AS
    (
        SELECT
              NormalizedValue
            , InvalidFormat
            , CanonicalValue =
              CASE
                  WHEN @Value IS NULL OR InvalidFormat = 1
                      THEN ''
                  WHEN FirstPadding IS NULL AND LengthRemainder = 2
                      THEN NormalizedValue + '=='
                  WHEN FirstPadding IS NULL AND LengthRemainder = 3
                      THEN NormalizedValue + '='
                  ELSE NormalizedValue
              END
        FROM FormatCheck
    )
    SELECT DecodedValue =
        CONVERT
        (
              varbinary(max)
            , CASE
                  WHEN @Value IS NULL
                      THEN NULL
                  WHEN InvalidFormat = 1
                      /*
                       * Derselbe feste, eingabewertfreie Fehlerpfad wie in
                       * der bisherigen SVF: varchar -> int muss scheitern.
                       */
                      THEN CONVERT
                           (
                                 varbinary(max)
                               , CONVERT
                                 (
                                       int
                                     , LEFT
                                       (
                                           'toolbelt.invalid.base64'
                                           + ISNULL(NormalizedValue, '')
                                         , 23
                                       )
                                 )
                           )
                  ELSE CONVERT
                       (
                           xml
                         , '<base64>'
                           + CanonicalValue
                           + '</base64>'
                       ).value
                       (
                           N'xs:base64Binary((/base64/text())[1])'
                         , N'varbinary(max)'
                       )
              END
        )
    FROM Canonical
);
GO
