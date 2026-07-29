-- ============================================================================
-- Cross-database-Contract für zentrale Installation
-- SQLCMD-Variable: ToolbeltDatabase
-- ============================================================================

SET NOCOUNT ON;

DECLARE
      @IntCount    bigint
    , @BigIntCount bigint
    , @BigIntMin   bigint
    , @BigIntMax   bigint;

SELECT @IntCount = COUNT_BIG(*)
FROM [$(ToolbeltDatabase)].toolbelt_core.TVF_GenerateSeriesInt
(
    1,
    5,
    DEFAULT
);

SELECT
      @BigIntCount = COUNT_BIG(*)
    , @BigIntMin = MIN(series.Value)
    , @BigIntMax = MAX(series.Value)
FROM [$(ToolbeltDatabase)].toolbelt_core.TVF_GenerateSeriesBigInt
(
    CONVERT(bigint, 10),
    CONVERT(bigint, 2),
    CONVERT(bigint, -2)
) AS series;

IF @IntCount <> 5
   OR @BigIntCount <> 5
   OR @BigIntMin <> 2
   OR @BigIntMax <> 10
BEGIN
    THROW 52430, N'Der zentrale dreiteilige Generate-Series-Aufruf ist fehlgeschlagen.', 1;
END;

PRINT N'Generate-Series Central-Contract-Prüfung: erfolgreich';
GO
