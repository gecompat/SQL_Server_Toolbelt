CREATE OR ALTER FUNCTION [toolbelt_validation].[SVF_SemanticVersionSortKey]
(
    @Version varchar(8000)
)
RETURNS varbinary(max)
AS
BEGIN
    DECLARE @SortKey varbinary(max);

    SELECT @SortKey = sort_key.SortKey
    FROM toolbelt_validation.TVF_SemanticVersionSortKey(@Version) AS sort_key;

    RETURN @SortKey;
END;
GO
