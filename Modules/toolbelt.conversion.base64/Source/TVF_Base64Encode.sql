-- ============================================================================
-- Objekt:          toolbelt_conversion.TVF_Base64Encode
-- Zweck:           Binärdaten als Base64 oder Base64URL codieren
-- Parameter:       @Value varbinary(max), @UrlSafe bit = 0
-- Resultset:       genau eine Zeile; EncodedValue varchar(max)
-- Dependencies:    keine Toolbelt-Module; T-SQL/XML-Provider
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     kanonischer relationaler Kern für APPLY
-- Collation:       Rückgabewert verwendet die Datenbank-Default-Collation
-- Einschränkungen: Base64URL wird ohne Padding ausgegeben
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_conversion].[TVF_Base64Encode]
(
      @Value   varbinary(max)
    , @UrlSafe bit = 0
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    WITH Encoded AS
    (
        SELECT EncodedValue =
            CASE
                WHEN @Value IS NULL
                    THEN CONVERT(varchar(max), NULL)
                ELSE
                    CAST(N'' AS xml).value
                    (
                          N'xs:base64Binary(sql:variable("@Value"))'
                        , N'varchar(max)'
                    )
            END
    ),
    UrlSafe AS
    (
        SELECT
              EncodedValue
            , TransformedValue =
                  REPLACE(REPLACE(EncodedValue, '+', '-'), '/', '_')
        FROM Encoded
    )
    SELECT EncodedValue =
        CONVERT
        (
              varchar(max)
            , CASE
                  WHEN ISNULL(@UrlSafe, 0) <> 1 OR EncodedValue IS NULL
                      THEN EncodedValue
                  ELSE LEFT
                       (
                             TransformedValue
                           , DATALENGTH(TransformedValue)
                             - CASE
                                   WHEN RIGHT(TransformedValue, 2) = '=='
                                       THEN 2
                                   WHEN RIGHT(TransformedValue, 1) = '='
                                       THEN 1
                                   ELSE 0
                               END
                       )
              END
        )
    FROM UrlSafe
);
GO
