-- Synthetische Beispiele für toolbelt.conversion.integer-base
DECLARE @HexAlphabet varchar(93) = '0123456789ABCDEF';

SELECT
      toolbelt_conversion.SVF_IntegerToBase(255, @HexAlphabet) AS Encoded
    , toolbelt_conversion.SVF_TryBaseToInteger('FF', @HexAlphabet) AS Decoded;
GO

SELECT
      source.Value
    , encoded.EncodedValue
    , decoded.DecodedValue
FROM
(
    VALUES (CONVERT(bigint, -255)), (0), (255)
) AS source(Value)
OUTER APPLY
    toolbelt_conversion.TVF_IntegerToBase
    (
          source.Value
        , @HexAlphabet
    ) AS encoded
OUTER APPLY
    toolbelt_conversion.TVF_TryBaseToInteger
    (
          encoded.EncodedValue
        , @HexAlphabet
    ) AS decoded;
GO
