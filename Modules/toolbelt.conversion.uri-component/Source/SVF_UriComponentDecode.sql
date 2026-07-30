CREATE OR ALTER FUNCTION [toolbelt_conversion].[SVF_UriComponentDecode](@Value nvarchar(max))
RETURNS nvarchar(max)
AS
BEGIN
 DECLARE @Result nvarchar(max);
 SELECT @Result=decoded.DecodedValue FROM toolbelt_conversion.TVF_UriComponentDecode(@Value) AS decoded;
 RETURN @Result;
END;
GO
