-- ============================================================================
-- Cross-database-Contract für zentrale Installation
-- SQLCMD-Variable: ToolbeltDatabase
-- ============================================================================

SET NOCOUNT ON;

IF NOT EXISTS
   (
       SELECT 1
       FROM [$(ToolbeltDatabase)].toolbelt_datetime.TVF_CalendarDifference
            (
                  CONVERT(date, '2020-02-29')
                , CONVERT(date, '2021-02-28')
            )
       WHERE Sign = 1
         AND Years = 1
         AND Months = 0
         AND Days = 0
   )
BEGIN
    THROW 52732, N'Der zentrale Calendar-Difference-Aufruf ist fehlgeschlagen.', 1;
END;

PRINT N'Calendar Difference Central-Contract-Prüfung: erfolgreich';
GO
