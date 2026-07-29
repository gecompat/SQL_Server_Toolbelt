-- ============================================================================
-- Reduzierter Compatibility-Smoke für SQL Server 2022 und 2025
-- Daten: ausschließlich synthetisch
-- Status im Repository: not executed
-- ============================================================================

SET NOCOUNT ON;

CREATE TABLE #ResultTableCompatibility
(
    Dummy int NULL
);

CREATE TABLE #tbx_ResultTableCompatibility_Shape
(
      ItemOrdinal bigint       NOT NULL
    , ItemValue   varchar(100) COLLATE Latin1_General_100_BIN2 NULL
);

BEGIN TRY
    EXEC toolbelt_core.USP_PrepareResultTable
          @ResultTableToAlter = N'#ResultTableCompatibility'
        , @LikeTable          = N'#ResultTableCompatibility'
        , @KeepData           = 0;
    THROW 52210, N'Erwarteter Selbstbezugsfehler 51022 wurde nicht ausgelöst.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51022
    BEGIN
        THROW;
    END;
END CATCH;

EXEC toolbelt_core.USP_PrepareResultTable
      @ResultTableToAlter = N'#ResultTableCompatibility'
    , @LikeTable          = N'#tbx_ResultTableCompatibility_Shape'
    , @KeepData           = 0;

IF NOT EXISTS
   (
       SELECT 1
       FROM tempdb.sys.columns AS c
       WHERE c.object_id = OBJECT_ID(N'tempdb..[#ResultTableCompatibility]', N'U')
         AND c.name COLLATE Latin1_General_100_BIN2 = N'ItemOrdinal'
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM tempdb.sys.columns AS c
       WHERE c.object_id = OBJECT_ID(N'tempdb..[#ResultTableCompatibility]', N'U')
         AND c.name COLLATE Latin1_General_100_BIN2 = N'ItemValue'
   )
BEGIN
    THROW 52211, N'Der Compatibility-Smoke erzeugte nicht das erwartete Zielschema.', 1;
END;

DROP TABLE #tbx_ResultTableCompatibility_Shape;
DROP TABLE #ResultTableCompatibility;

PRINT N'USP_PrepareResultTable Compatibility-Smoke: erfolgreich';
GO
