SET NOCOUNT ON;

IF NOT EXISTS
   (
       SELECT 1
       FROM [$(ToolbeltDatabase)].toolbelt_datetime.TVF_TruncateDateTime2
            ('month', CONVERT(datetime2(7), '2026-07-30T12:34:56.1234567'))
       WHERE Value = CONVERT(datetime2(7), '2026-07-01T00:00:00')
         AND IsValid = 1
   )
    THROW 52822, N'Der zentrale Truncation-Aufruf ist fehlgeschlagen.', 1;

PRINT N'Date/Time Truncation Central-Contract-Prüfung: erfolgreich';
GO
