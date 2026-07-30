CREATE OR ALTER FUNCTION [toolbelt_conversion].[SVF_UriComponentEncode](@Value nvarchar(max))
RETURNS nvarchar(max)
AS
BEGIN
 DECLARE @Result nvarchar(max);
 SELECT @Result=encoded.EncodedValue FROM toolbelt_conversion.TVF_UriComponentEncode(@Value) AS encoded;
 RETURN @Result;
END;
GO
