:On Error exit

-- ============================================================================
-- Zentraler Deployment-Contract über einen dreiteiligen Procedure-Aufruf
-- Daten: ausschließlich synthetisch
-- Status im Repository: SQL Server 2019 Linux am 2026-07-29 erfolgreich
-- ============================================================================

SET NOCOUNT ON;

CREATE TABLE #ResultTableCentral
(
    Dummy varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
);

CREATE TABLE dbo.tbx_ResultTableCentral_Source
(
      ItemOrdinal bigint       NOT NULL
    , ItemValue   varchar(100) COLLATE Latin1_General_100_CI_AS NULL
);

DECLARE @ConsumerDatabase sysname = DB_NAME();
DECLARE @ThreePartSource nvarchar(776) =
      QUOTENAME(@ConsumerDatabase)
    + N'.dbo.tbx_ResultTableCentral_Source';

EXEC [$(ToolbeltDatabase)].toolbelt_core.USP_PrepareResultTable
      @ResultTableToAlter = N'#ResultTableCentral'
    , @LikeTable          = @ThreePartSource
    , @KeepData           = 0;

IF NOT EXISTS
   (
       SELECT 1
       FROM tempdb.sys.columns AS c
       WHERE c.object_id = OBJECT_ID(N'tempdb..[#ResultTableCentral]', N'U')
         AND c.name COLLATE Latin1_General_100_BIN2 = N'ItemOrdinal'
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM tempdb.sys.columns AS c
       WHERE c.object_id = OBJECT_ID(N'tempdb..[#ResultTableCentral]', N'U')
         AND c.name COLLATE Latin1_General_100_BIN2 = N'ItemValue'
         AND c.collation_name COLLATE Latin1_General_100_BIN2
                 = N'Latin1_General_100_CI_AS'
   )
BEGIN
    THROW 52220, N'Der zentrale dreiteilige Aufruf bereitete Schema oder Collation nicht korrekt vor.', 1;
END;

DROP TABLE dbo.tbx_ResultTableCentral_Source;
DROP TABLE #ResultTableCentral;

PRINT N'USP_PrepareResultTable Central-Contract: erfolgreich';
GO
