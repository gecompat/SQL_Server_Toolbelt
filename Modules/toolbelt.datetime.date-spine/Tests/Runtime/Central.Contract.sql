SET NOCOUNT ON;

IF NOT EXISTS
   (
       SELECT 1
       FROM [$(ToolbeltDatabase)].toolbelt_datetime.TVF_DateSpineMonth
            ('20260115', '20260402')
       WHERE Ordinal = 3 AND PeriodStart = CONVERT(date, '20260401', 112)
   )
   OR (SELECT COUNT(*)
       FROM [$(ToolbeltDatabase)].toolbelt_datetime.TVF_DateSpineIsoWeek
            ('20251231', '20260108')) <> 2
    THROW 52967, N'Der zentrale Date-Spine-Aufruf ist fehlgeschlagen.', 1;

PRINT N'Date-Spine Central-Contract-Prüfung: erfolgreich';
GO
