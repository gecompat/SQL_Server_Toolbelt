SET NOCOUNT ON;

IF OBJECT_ID(N'toolbelt_datetime.TVF_TruncateDate', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_TruncateDateTime2', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_TruncateDateTimeOffset', N'IF') IS NULL
    THROW 52820, N'Die Truncation-Releaseobjekte fehlen.', 1;

IF NOT EXISTS
   (
       SELECT 1 FROM sys.extended_properties
       WHERE class = 0
         AND name = N'Toolbelt.Module.toolbelt.datetime.truncate.Version'
         AND TRY_CONVERT(nvarchar(64), value) = N'1.0.0'
   )
   OR NOT EXISTS
   (
       SELECT 1 FROM sys.extended_properties
       WHERE class = 0
         AND name =
             N'Toolbelt.Module.toolbelt.datetime.truncate.DeploymentMode'
         AND TRY_CONVERT(nvarchar(16), value) IN (N'local', N'central')
   )
    THROW 52821, N'Die Truncation-Modulmarker sind inkonsistent.', 1;

PRINT N'Date/Time Truncation Lifecycle-Contract-Prüfung: erfolgreich';
GO
