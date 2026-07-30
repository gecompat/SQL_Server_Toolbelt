-- ============================================================================
-- Synthetische Beispiele für toolbelt.conversion.base64
-- Keine Zeichenkodierung, Secrets oder Originaldaten
-- ============================================================================

SET QUOTED_IDENTIFIER ON;

DECLARE @SyntheticValue varbinary(max) = 0xCAFECAFE;

SELECT
      toolbelt_conversion.SVF_Base64Encode(@SyntheticValue, DEFAULT)
          AS StandardBase64
    , toolbelt_conversion.SVF_Base64Encode(@SyntheticValue, 1)
          AS Base64Url;

SELECT
      toolbelt_conversion.SVF_Base64Decode('yv7K/g==')
          AS StandardDecoded
    , toolbelt_conversion.SVF_Base64Decode('yv7K_g')
          AS UrlSafeDecoded;
GO

SELECT
      source.ItemOrdinal
    , encoded.EncodedValue
    , decoded.DecodedValue
FROM
(
    VALUES
          (1, CONVERT(varbinary(max), 0xCAFECAFE))
        , (2, CONVERT(varbinary(max), NULL))
) AS source(ItemOrdinal, BinaryValue)
OUTER APPLY
    toolbelt_conversion.TVF_Base64Encode(source.BinaryValue, 1) AS encoded
OUTER APPLY
    toolbelt_conversion.TVF_Base64Decode(encoded.EncodedValue) AS decoded;
GO
