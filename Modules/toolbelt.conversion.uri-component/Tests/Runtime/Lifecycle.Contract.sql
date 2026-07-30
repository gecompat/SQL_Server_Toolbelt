-- ============================================================================
-- Read-only Lifecycle-Contract-Prüfung nach Deploy.sql
-- ============================================================================

SET NOCOUNT ON;

IF OBJECT_ID(N'toolbelt_conversion.TVF_UriComponentEncode', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_conversion.TVF_UriComponentDecode', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_conversion.SVF_UriComponentEncode', N'FN') IS NULL
   OR OBJECT_ID(N'toolbelt_conversion.SVF_UriComponentDecode', N'FN') IS NULL
BEGIN
    THROW 52736, N'Die URI-Component-Funktionen fehlen.', 1;
END;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties
       WHERE class = 0
         AND name =
             N'Toolbelt.Module.toolbelt.conversion.uri-component.Version'
         AND TRY_CONVERT(nvarchar(64), value) = N'1.0.0'
   )
   OR NOT EXISTS
      (
          SELECT 1
          FROM sys.extended_properties
          WHERE class = 0
            AND name =
                N'Toolbelt.Module.toolbelt.conversion.uri-component.DeploymentMode'
            AND TRY_CONVERT(nvarchar(16), value) IN (N'local', N'central')
      )
BEGIN
    THROW 52737, N'Die URI-Component-Modulmarker fehlen oder sind inkonsistent.', 1;
END;

PRINT N'URI Component Lifecycle-Contract-Prüfung: erfolgreich';
GO
