-- ============================================================================
-- Read-only Lifecycle-Contract-Prüfung nach Deploy.sql
-- ============================================================================

SET NOCOUNT ON;

DECLARE @ExpectedObjects TABLE
(
      ObjectName sysname NOT NULL PRIMARY KEY
    , ObjectType char(2) NOT NULL
);

INSERT INTO @ExpectedObjects (ObjectName, ObjectType)
VALUES
      (N'TVF_IntegerToBase', 'IF')
    , (N'TVF_TryBaseToInteger', 'IF')
    , (N'SVF_IntegerToBase', 'FN')
    , (N'SVF_TryBaseToInteger', 'FN');

IF SCHEMA_ID(N'toolbelt_conversion') IS NULL
   OR EXISTS
      (
          SELECT 1
          FROM @ExpectedObjects AS expected
          WHERE OBJECT_ID
                (
                    QUOTENAME(N'toolbelt_conversion')
                    + N'.'
                    + QUOTENAME(expected.ObjectName),
                    expected.ObjectType
                ) IS NULL
      )
BEGIN
    THROW 52820, N'Schema oder Release-Funktion der Modulinstallation fehlt.', 1;
END;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties
       WHERE class = 0
         AND name =
             N'Toolbelt.Module.toolbelt.conversion.integer-base.Version'
         AND TRY_CONVERT(nvarchar(64), value) = N'1.1.0'
   )
   OR NOT EXISTS
      (
          SELECT 1
          FROM sys.extended_properties
          WHERE class = 0
            AND name =
                N'Toolbelt.Module.toolbelt.conversion.integer-base.DeploymentMode'
            AND TRY_CONVERT(nvarchar(16), value) IN (N'local', N'central')
      )
BEGIN
    THROW 52821, N'Die Modulmarker fehlen oder sind inkonsistent.', 1;
END;

IF EXISTS
   (
       SELECT 1
       FROM @ExpectedObjects AS expected
       CROSS APPLY
       (
           SELECT OBJECT_ID
           (
               QUOTENAME(N'toolbelt_conversion')
               + N'.'
               + QUOTENAME(expected.ObjectName)
           ) AS ObjectId
       ) AS resolved
       WHERE NOT EXISTS
             (
                 SELECT 1
                 FROM sys.extended_properties AS properties
                 WHERE properties.class = 1
                   AND properties.major_id = resolved.ObjectId
                   AND properties.name = N'Toolbelt.ModuleId'
                   AND TRY_CONVERT(nvarchar(256), properties.value)
                         = N'toolbelt.conversion.integer-base'
             )
          OR NOT EXISTS
             (
                 SELECT 1
                 FROM sys.extended_properties AS properties
                 WHERE properties.class = 1
                   AND properties.major_id = resolved.ObjectId
                   AND properties.name = N'Toolbelt.SourceHash'
                   AND TRY_CONVERT(varchar(64), properties.value) =
                       CONVERT
                       (
                           varchar(64),
                           HASHBYTES
                           (
                               N'SHA2_256',
                               CONVERT
                               (
                                   varbinary(max),
                                   OBJECT_DEFINITION(resolved.ObjectId)
                               )
                           ),
                           2
                       )
             )
   )
BEGIN
    THROW 52822, N'Objektmarker oder diagnostischer Source-Hash sind inkonsistent.', 1;
END;

PRINT N'IntegerBase Lifecycle-Contract-Prüfung: erfolgreich';
GO
