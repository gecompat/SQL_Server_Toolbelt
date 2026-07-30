CREATE OR ALTER FUNCTION [toolbelt_validation].[SVF_CompareSemanticVersion]
(
      @LeftVersion  varchar(8000)
    , @RightVersion varchar(8000)
)
RETURNS smallint
AS
BEGIN
    DECLARE @ComparisonResult smallint;

    SELECT @ComparisonResult = compared.ComparisonResult
    FROM toolbelt_validation.TVF_CompareSemanticVersion
         (
               @LeftVersion
             , @RightVersion
         ) AS compared;

    RETURN @ComparisonResult;
END;
GO
