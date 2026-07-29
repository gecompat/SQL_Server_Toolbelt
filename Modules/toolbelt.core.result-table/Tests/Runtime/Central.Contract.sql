:On Error exit

-- ============================================================================
-- Zentraler Deployment-Contract über einen dreiteiligen Procedure-Aufruf
-- Daten: ausschließlich synthetisch
-- Status im Repository: SQL Server 2019 Linux am 2026-07-29 erfolgreich
-- ============================================================================

SET NOCOUNT ON;

CREATE TABLE #ResultTableCentral
(
    Dummy int NULL
);

CREATE TABLE #tbx_ResultTableCentral_Shape
(
      ItemOrdinal bigint        NOT NULL
    , ItemValue   nvarchar(100) COLLATE Latin1_General_100_BIN2 NULL
);

EXEC [$(ToolbeltDatabase)].toolbelt_core.USP_PrepareResultTable
      @ResultTableToAlter = N'#ResultTableCentral'
    , @LikeTable          = N'#tbx_ResultTableCentral_Shape'
    , @KeepData           = 0;

IF NOT EXISTS
   (
       SELECT 1
       FROM tempdb.sys.columns AS c
       WHERE c.object_id = OBJECT_ID(N'tempdb..[#ResultTableCentral]', N'U')
         AND c.name COLLATE Latin1_General_100_BIN2 = N'ItemOrdinal'
   )
BEGIN
    THROW 52220, N'Der zentrale dreiteilige Aufruf bereitete die lokale Zieltable nicht vor.', 1;
END;

DROP TABLE #tbx_ResultTableCentral_Shape;
DROP TABLE #ResultTableCentral;

PRINT N'USP_PrepareResultTable Central-Contract: erfolgreich';
GO
