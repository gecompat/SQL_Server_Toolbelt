:On Error exit
SET NOCOUNT ON;

IF EXISTS
   (
       SELECT 1
       FROM sys.objects AS objects
       JOIN sys.schemas AS schemas
         ON schemas.schema_id = objects.schema_id
       WHERE schemas.name COLLATE Latin1_General_100_BIN2
                 LIKE N'toolbelt[_]%' COLLATE Latin1_General_100_BIN2
         AND objects.is_ms_shipped = 0
   )
    THROW 52946, N'Das wiederholte Uninstall ließ Toolbelt-Objekte zurück.', 1;

IF EXISTS
   (
       SELECT 1
       FROM sys.extended_properties
       WHERE class = 0
         AND major_id = 0
         AND minor_id = 0
         AND name COLLATE Latin1_General_100_BIN2
               LIKE N'Toolbelt.Module.$(ModuleId).%'
                    COLLATE Latin1_General_100_BIN2
   )
    THROW 52946, N'Das wiederholte Uninstall ließ Modulmarker zurück.', 1;

PRINT N'Migration-Idempotency wiederholtes Uninstall: erfolgreich';
GO
