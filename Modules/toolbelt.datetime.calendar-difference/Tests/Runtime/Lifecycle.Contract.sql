-- ============================================================================
-- Read-only Lifecycle-Contract-Prüfung nach Deploy.sql
-- ============================================================================

SET NOCOUNT ON;

IF OBJECT_ID(N'toolbelt_datetime.TVF_CalendarDifference', N'IF') IS NULL
BEGIN
    THROW 52730, N'Die Calendar-Difference-Funktion fehlt.', 1;
END;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties
       WHERE class = 0
         AND name =
             N'Toolbelt.Module.toolbelt.datetime.calendar-difference.Version'
         AND TRY_CONVERT(nvarchar(64), value) = N'1.0.0'
   )
   OR NOT EXISTS
      (
          SELECT 1
          FROM sys.extended_properties
          WHERE class = 0
            AND name =
                N'Toolbelt.Module.toolbelt.datetime.calendar-difference.DeploymentMode'
            AND TRY_CONVERT(nvarchar(16), value) IN (N'local', N'central')
      )
BEGIN
    THROW 52731, N'Die Calendar-Difference-Modulmarker fehlen oder sind inkonsistent.', 1;
END;

PRINT N'Calendar Difference Lifecycle-Contract-Prüfung: erfolgreich';
GO
