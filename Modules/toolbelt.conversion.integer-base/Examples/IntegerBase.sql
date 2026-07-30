-- Synthetische Beispiele für toolbelt.conversion.integer-base
DECLARE @HexAlphabet varchar(93) = '0123456789ABCDEF';

SELECT
      toolbelt_conversion.SVF_IntegerToBase(255, @HexAlphabet) AS Encoded
    , toolbelt_conversion.SVF_TryBaseToInteger('FF', @HexAlphabet) AS Decoded;
GO
