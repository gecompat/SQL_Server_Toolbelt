-- ============================================================================
-- Read-only Lifecycle-Contract-Prüfung nach Deploy.sql
-- ============================================================================

SET NOCOUNT ON;

DECLARE @ExpectedObjects TABLE
(
    ObjectName sysname NOT NULL PRIMARY KEY
);

INSERT INTO @ExpectedObjects (ObjectName)
VALUES (N'TVF_GenerateSeriesBigInt'), (N'TVF_GenerateSeriesInt');

IF SCHEMA_ID(N'toolbelt_core') IS NULL
   OR EXISTS
      (
          SELECT 1
          FROM @ExpectedObjects AS expected
          WHERE OBJECT_ID
                (
                    QUOTENAME(N'toolbelt_core')
                    + N'.'
                    + QUOTENAME(expected.ObjectName),
                    N'IF'
                ) IS NULL
      )
BEGIN
    THROW 52420, N'Schema oder Release-Funktion der Modulinstallation fehlt.', 1;
END;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties
       WHERE class = 0
         AND name =
             N'Toolbelt.Module.toolbelt.core.generate-series.Version'
         AND TRY_CONVERT(nvarchar(64), value) = N'1.0.0'
   )
   OR NOT EXISTS
      (
          SELECT 1
          FROM sys.extended_properties
          WHERE class = 0
            AND name =
                N'Toolbelt.Module.toolbelt.core.generate-series.DeploymentMode'
            AND TRY_CONVERT(nvarchar(16), value) IN (N'local', N'central')
      )
BEGIN
    THROW 52421, N'Die Modulmarker fehlen oder sind inkonsistent.', 1;
END;

IF EXISTS
   (
       SELECT 1
       FROM @ExpectedObjects AS expected
       CROSS APPLY
       (
           SELECT OBJECT_ID
           (
               QUOTENAME(N'toolbelt_core')
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
                         = N'toolbelt.core.generate-series'
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
    THROW 52422, N'Objektmarker oder diagnostischer Source-Hash sind inkonsistent.', 1;
END;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.sql_expression_dependencies AS dependencies
       WHERE dependencies.referencing_id =
             OBJECT_ID(N'toolbelt_core.TVF_GenerateSeriesInt', N'IF')
         AND dependencies.referenced_id =
             OBJECT_ID(N'toolbelt_core.TVF_GenerateSeriesBigInt', N'IF')
   )
BEGIN
    THROW 52423, N'Die interne Wrapper-Abhängigkeit zum bigint-Kern fehlt.', 1;
END;

PRINT N'Generate-Series Lifecycle-Contract-Prüfung: erfolgreich';
GO
