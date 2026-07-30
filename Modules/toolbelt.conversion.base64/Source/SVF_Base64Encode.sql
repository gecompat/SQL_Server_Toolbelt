-- ============================================================================
-- Objekt:          toolbelt_conversion.SVF_Base64Encode
-- Zweck:           Binärdaten als Base64 oder Base64URL codieren
-- Parameter:       @Value varbinary(max), @UrlSafe bit = 0
-- Rückgabewert:    varchar(max); NULL bleibt NULL
-- Dependencies:    keine Toolbelt-Module; T-SQL/XML-Provider
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Convenience-Wrapper; für Mengen TVF_Base64Encode verwenden
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
    DECLARE @EncodedValue varchar(max);

    SELECT @EncodedValue = encoded.EncodedValue
    FROM toolbelt_conversion.TVF_Base64Encode(@Value, @UrlSafe) AS encoded;

    RETURN @EncodedValue;
END;
GO
