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
AS
BEGIN
    /* DDL-Hilfe: Decodiert einen einzelnen Base64/Base64URL-Wert.
       Parameter: @Value varchar(max), NULL erlaubt; Space, Tab, CR und LF
       werden ignoriert. Eingabegrenze 25165824 Bytes, Ausgabegrenze 16777216.
       Rückgabe: varbinary(max), NULL bleibt NULL; bei Größenüberschreitung NULL;
       ungültige Eingabe löst einen SQL-Engine-Konvertierungsfehler aus.
       EXECUTE erforderlich.
       Beispiel: SELECT toolbelt_conversion.SVF_Base64Decode('yv7K_g');
       Erwartet: 0xCAFECAFE. Für Mengen die TVF verwenden. */
    DECLARE @DecodedValue varbinary(max);

    SELECT @DecodedValue = decoded.DecodedValue
    FROM toolbelt_conversion.TVF_Base64Decode(@Value) AS decoded;

    RETURN @DecodedValue;
END;
GO
