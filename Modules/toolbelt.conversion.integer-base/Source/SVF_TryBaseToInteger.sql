-- SQL Server Toolbelt
-- Objekt: toolbelt_conversion.SVF_TryBaseToInteger
-- Vertrag: Convenience-API zum relationalen Kern TVF_TryBaseToInteger.

CREATE OR ALTER FUNCTION [toolbelt_conversion].[SVF_TryBaseToInteger]
(
      @EncodedValue varchar(65)
    , @Alphabet varchar(93)
)
RETURNS bigint
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @DecodedValue bigint;

    SELECT @DecodedValue = decoded.DecodedValue
    FROM toolbelt_conversion.TVF_TryBaseToInteger
         (
               @EncodedValue
             , @Alphabet
         ) AS decoded;

    RETURN @DecodedValue;
END;
GO
