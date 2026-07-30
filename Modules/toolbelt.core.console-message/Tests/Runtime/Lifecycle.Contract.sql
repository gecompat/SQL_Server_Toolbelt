SET NOCOUNT ON;

IF OBJECT_ID(N'toolbelt_core.USP_WriteConsoleMessage', N'P') IS NULL
    THROW 52939, N'USP_WriteConsoleMessage fehlt.', 1;

IF NOT EXISTS
   (
       SELECT 1 FROM sys.extended_properties
       WHERE class = 0 AND major_id = 0 AND minor_id = 0
         AND name =
             N'Toolbelt.Module.toolbelt.core.console-message.Version'
         AND TRY_CONVERT(nvarchar(64), value) = N'1.0.0'
   )
   OR NOT EXISTS
   (
       SELECT 1 FROM sys.extended_properties
       WHERE class = 0 AND major_id = 0 AND minor_id = 0
         AND name =
             N'Toolbelt.Module.toolbelt.core.console-message.DeploymentMode'
         AND TRY_CONVERT(nvarchar(16), value) IN (N'local', N'central')
   )
    THROW 52939, N'Die Console-Message-Modulmarker sind inkonsistent.', 1;

PRINT N'Console Message Lifecycle-Contract-Prüfung: erfolgreich';
GO
