-- ============================================================================
-- Objekt:          toolbelt_conversion.SVF_Base64Decode
-- Zweck:           Base64 oder Base64URL in Binärdaten decodieren
-- Parameter:       @Value varchar(max)
-- Rückgabewert:    varbinary(max); NULL bleibt NULL
-- Dependencies:    keine Toolbelt-Module; T-SQL/XML-Provider
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Convenience-Wrapper; für Mengen TVF_Base64Decode verwenden
-- Collation:       ASCII-Vertrag; Vergleiche sind nicht sprachabhängig
-- Einschränkungen: ignoriert nur Space, Tab, CR und LF
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_conversion].[SVF_Base64Decode]
(
    @Value varchar(max)
)
RETURNS varbinary(max)
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @DecodedValue varbinary(max);

    SELECT @DecodedValue = decoded.DecodedValue
    FROM toolbelt_conversion.TVF_Base64Decode(@Value) AS decoded;

    RETURN @DecodedValue;
END;
GO
