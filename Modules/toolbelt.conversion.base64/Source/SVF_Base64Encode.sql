-- ============================================================================
-- Objekt:          toolbelt_conversion.SVF_Base64Encode
-- Zweck:           Binärdaten als Base64 oder Base64URL codieren
-- Parameter:       @Value varbinary(max), @UrlSafe bit = 0
-- Rückgabewert:    varchar(max); NULL bleibt NULL
-- Dependencies:    keine Toolbelt-Module; T-SQL/XML-Provider
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     synchrone LOB-Konvertierung; keine Inlining-Zusage
-- Collation:       Rückgabewert verwendet die Datenbank-Default-Collation
-- Einschränkungen: Base64URL wird ohne Padding ausgegeben
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_conversion].[SVF_Base64Encode]
(
      @Value   varbinary(max)
    , @UrlSafe bit = 0
)
RETURNS varchar(max)
AS
BEGIN
    IF @Value IS NULL
    BEGIN
        RETURN NULL;
    END;

    DECLARE @EncodedValue varchar(max) =
        CAST(N'' AS xml).value
        (
              N'xs:base64Binary(sql:variable("@Value"))'
            , N'varchar(max)'
        );

    IF @UrlSafe = 1
    BEGIN
        SET @EncodedValue = REPLACE
        (
              REPLACE(@EncodedValue, '+', '-')
            , '/'
            , '_'
        );

        WHILE RIGHT(@EncodedValue, 1) = '='
        BEGIN
            SET @EncodedValue = LEFT
            (
                  @EncodedValue
                , DATALENGTH(@EncodedValue) - 1
            );
        END;
    END;

    RETURN @EncodedValue;
END;
GO
