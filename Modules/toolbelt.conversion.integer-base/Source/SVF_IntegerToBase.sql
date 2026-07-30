-- SQL Server Toolbelt
-- Objekt: toolbelt_conversion.SVF_IntegerToBase
-- Vertrag: Convenience-API zum relationalen Kern TVF_IntegerToBase.

CREATE OR ALTER FUNCTION [toolbelt_conversion].[SVF_IntegerToBase]
(
      @Value bigint
    , @Alphabet varchar(93)
)
RETURNS varchar(65)
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @EncodedValue varchar(65);

    SELECT @EncodedValue = encoded.EncodedValue
    FROM toolbelt_conversion.TVF_IntegerToBase(@Value, @Alphabet) AS encoded;

    RETURN @EncodedValue;
END;
GO
