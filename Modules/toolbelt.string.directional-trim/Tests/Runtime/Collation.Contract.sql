:on error exit
SET NOCOUNT ON;

DECLARE @ExpectedCaseMode varchar(3) = '$(ExpectedCaseMode)';
IF @ExpectedCaseMode NOT IN ('CI', 'CS')
    THROW 52728, N'ExpectedCaseMode muss CI oder CS sein.', 1;

DECLARE @ExpectedNvarchar nvarchar(max) =
    CASE WHEN @ExpectedCaseMode = 'CI' THEN N'' ELSE N'A' END;
DECLARE @ExpectedVarchar varchar(max) =
    CASE WHEN @ExpectedCaseMode = 'CI' THEN '' ELSE 'A' END;

IF (SELECT Value
    FROM toolbelt_string.TVF_TrimDirectionalNvarchar(N'aAa', N'a', 'BOTH'))
       COLLATE Latin1_General_100_BIN2
   <> @ExpectedNvarchar COLLATE Latin1_General_100_BIN2
    THROW 52729, N'Die nvarchar-Collation-Semantik ist inkonsistent.', 1;

IF (SELECT Value
    FROM toolbelt_string.TVF_TrimDirectionalVarchar('aAa', 'a', 'BOTH'))
       COLLATE Latin1_General_100_BIN2
   <> @ExpectedVarchar COLLATE Latin1_General_100_BIN2
    THROW 52730, N'Die varchar-Collation-Semantik ist inkonsistent.', 1;

PRINT N'Directional TRIM Collation-Contract: erfolgreich';
GO
