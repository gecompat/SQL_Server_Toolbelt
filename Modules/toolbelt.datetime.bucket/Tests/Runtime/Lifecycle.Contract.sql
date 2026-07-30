SET NOCOUNT ON;

IF OBJECT_ID(N'toolbelt_datetime.TVF_DateBucketDate', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_DateBucketDateTime2', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_DateBucketDateTimeOffset', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_DateBucketCore', N'TF') IS NULL
    THROW 52850, N'Die Bucket-Releaseobjekte fehlen.', 1;

IF NOT EXISTS
   (
       SELECT 1 FROM sys.extended_properties
       WHERE class = 0
         AND name = N'Toolbelt.Module.toolbelt.datetime.bucket.Version'
         AND TRY_CONVERT(nvarchar(64), value) = N'1.0.0'
   )
   OR NOT EXISTS
   (
       SELECT 1 FROM sys.extended_properties
       WHERE class = 0
         AND name =
             N'Toolbelt.Module.toolbelt.datetime.bucket.DeploymentMode'
         AND TRY_CONVERT(nvarchar(16), value) IN (N'local', N'central')
   )
    THROW 52851, N'Die Bucket-Modulmarker sind inkonsistent.', 1;

PRINT N'Date/Time Bucket Lifecycle-Contract-Prüfung: erfolgreich';
GO
