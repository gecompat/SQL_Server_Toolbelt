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
    Canonical AS
    (
        SELECT CanonicalValue =
            CONVERT
            (
                  varchar(max)
                , CASE
                      WHEN @Value IS NULL
                          THEN ''
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
                          /*
                           * Der Sentinel erzwingt für fachlich ungültige
                           * Eingaben einen unveränderten XML-Enginefehler,
                           * ohne den Eingabewert offenzulegen.
                           */
                          THEN 'toolbelt.invalid.base64'
                      WHEN FirstPadding IS NULL AND LengthRemainder = 2
                          THEN NormalizedValue + '=='
                      WHEN FirstPadding IS NULL AND LengthRemainder = 3
                          THEN NormalizedValue + '='
                      ELSE NormalizedValue
                  END
            )
        FROM Validation
    )
    SELECT DecodedValue =
        CONVERT
        (
              varbinary(max)
            , CASE
                  WHEN @Value IS NULL
                      THEN NULL
                  ELSE CAST(N'' AS xml).value
                       (
                           N'xs:base64Binary(sql:column("Canonical.CanonicalValue"))'
                         , N'varbinary(max)'
                       )
              END
        )
    FROM Canonical
);
GO
