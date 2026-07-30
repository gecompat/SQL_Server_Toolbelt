-- ============================================================================
-- Objekt: toolbelt_string.TVF_TrimDirectionalNvarchar
-- Zweck:  LEADING-, TRAILING- und BOTH-Trim für Unicode-Text.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_string].[TVF_TrimDirectionalNvarchar]
(
      @Value      nvarchar(max)
    , @Characters nvarchar(4000) = N' '
    , @Direction  varchar(8) = 'BOTH'
)
RETURNS TABLE
AS
RETURN
(
    WITH Parameters AS
    (
        SELECT
              InputLength = CONVERT(bigint, DATALENGTH(@Value) / 2)
            , Direction = UPPER(@Direction) COLLATE Latin1_General_100_BIN2
            , IsValid = CONVERT(bit, CASE WHEN UPPER(@Direction) COLLATE Latin1_General_100_BIN2 IN ('LEADING','TRAILING','BOTH') THEN 1 ELSE 0 END)
    ),
    NonTrimmed AS
    (
        SELECT positions.Value
        FROM Parameters AS parameters
        CROSS APPLY toolbelt_core.TVF_GenerateSeriesBigInt(1, parameters.InputLength, 1) AS positions
        WHERE CASE
            WHEN UNICODE(SUBSTRING(@Value COLLATE Latin1_General_100_BIN2, positions.Value, 1)) = 0 THEN 0
            ELSE CHARINDEX(SUBSTRING(@Value, positions.Value, 1), @Characters) END = 0
    ),
    Bounds AS
    (
        SELECT FirstValue = MIN(Value), LastValue = MAX(Value) FROM NonTrimmed
    )
    SELECT Value = CONVERT(nvarchar(max), CASE
        WHEN @Value IS NULL OR @Characters IS NULL THEN NULL
        WHEN parameters.IsValid = 0 THEN CONVERT(nvarchar(max), 1 / 0)
        WHEN parameters.InputLength = 0 THEN N''
        WHEN bounds.FirstValue IS NULL THEN N''
        WHEN parameters.Direction = 'LEADING' THEN SUBSTRING(@Value, bounds.FirstValue, parameters.InputLength - bounds.FirstValue + 1)
        WHEN parameters.Direction = 'TRAILING' THEN SUBSTRING(@Value, 1, bounds.LastValue)
        ELSE SUBSTRING(@Value, bounds.FirstValue, bounds.LastValue - bounds.FirstValue + 1) END)
    FROM Parameters AS parameters CROSS JOIN Bounds AS bounds
);
GO
