-- ============================================================================
-- Synthetische Beispiele für toolbelt.conversion.base64
-- Keine Zeichenkodierung, Secrets oder Originaldaten
-- ============================================================================

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
