SET NOCOUNT ON;

IF NOT EXISTS
   (
       SELECT 1
       FROM [$(ToolbeltDatabase)].toolbelt_datetime.TVF_DateBucketDateTime2
            (
                  'minute'
                , 15
                , CONVERT(datetime2(7), '2026-07-30T12:34:56')
                , CONVERT(datetime2(7), '2026-07-30T00:00:00')
            )
       WHERE Value = CONVERT(datetime2(7), '2026-07-30T12:30:00')
         AND IsValid = 1
   )
    THROW 52852, N'Der zentrale Bucket-Aufruf ist fehlgeschlagen.', 1;

PRINT N'Date/Time Bucket Central-Contract-Prüfung: erfolgreich';
GO
