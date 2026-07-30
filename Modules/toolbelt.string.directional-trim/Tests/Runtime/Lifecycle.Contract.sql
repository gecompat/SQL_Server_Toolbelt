-- ============================================================================
-- Read-only Lifecycle-Contract-Prüfung nach Deploy.sql
-- ============================================================================

SET NOCOUNT ON;

IF OBJECT_ID(N'toolbelt_string.TVF_TrimDirectionalNvarchar', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_string.TVF_TrimDirectionalVarchar', N'IF') IS NULL
BEGIN
    THROW 52733, N'Die Directional-TRIM-Funktionen fehlen.', 1;
END;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties
       WHERE class = 0
         AND name =
             N'Toolbelt.Module.toolbelt.string.directional-trim.Version'
         AND TRY_CONVERT(nvarchar(64), value) = N'1.0.0'
   )
   OR NOT EXISTS
      (
          SELECT 1
          FROM sys.extended_properties
          WHERE class = 0
            AND name =
                N'Toolbelt.Module.toolbelt.string.directional-trim.DeploymentMode'
            AND TRY_CONVERT(nvarchar(16), value) IN (N'local', N'central')
      )
BEGIN
    THROW 52734, N'Die Directional-TRIM-Modulmarker fehlen oder sind inkonsistent.', 1;
END;

PRINT N'Directional TRIM Lifecycle-Contract-Prüfung: erfolgreich';
GO
