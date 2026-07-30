SET NOCOUNT ON;

IF OBJECT_ID(N'toolbelt_json.TVF_JsonPathExists', N'TF') IS NULL
    THROW 52920,
          N'TVF_JsonPathExists fehlt oder ist keine Multi-statement TVF.',
          1;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties
       WHERE class = 0
         AND name = N'Toolbelt.Module.toolbelt.json.path-exists.Version'
         AND TRY_CONVERT(nvarchar(64), value) = N'1.0.0'
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties
       WHERE class = 0
         AND name =
             N'Toolbelt.Module.toolbelt.json.path-exists.DeploymentMode'
         AND TRY_CONVERT(nvarchar(16), value) IN (N'local', N'central')
   )
    THROW 52921, N'Die JSON-Path-Modulmarker sind inkonsistent.', 1;

PRINT N'JSON Path Exists Lifecycle-Contract-Prüfung: erfolgreich';
GO
