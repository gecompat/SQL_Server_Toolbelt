SET NOCOUNT ON;

IF SCHEMA_ID(N'toolbelt_metadata') IS NULL
   OR OBJECT_ID(N'toolbelt_metadata.TVF_ParseMultipartName', N'TF') IS NULL
   OR OBJECT_ID(N'toolbelt_metadata.SVF_QuoteMultipartName', N'FN') IS NULL
BEGIN
    THROW 52520, N'Schema oder Release-Funktion der Modulinstallation fehlt.', 1;
END;

IF
(
    SELECT TRY_CONVERT(nvarchar(64), value)
    FROM sys.extended_properties
    WHERE class = 0
      AND name = N'Toolbelt.Module.toolbelt.metadata.identifier.Version'
) <> N'1.0.0'
   OR
(
    SELECT TRY_CONVERT(nvarchar(16), value)
    FROM sys.extended_properties
    WHERE class = 0
      AND name =
          N'Toolbelt.Module.toolbelt.metadata.identifier.DeploymentMode'
) NOT IN (N'local', N'central')
BEGIN
    THROW 52521, N'Die Modulmarker fehlen oder sind inkonsistent.', 1;
END;

IF EXISTS
   (
       SELECT objects.object_id
       FROM
       (
           VALUES
               (N'TVF_ParseMultipartName'),
               (N'SVF_QuoteMultipartName')
       ) AS expected(ObjectName)
       CROSS APPLY
       (
           SELECT OBJECT_ID
           (
               N'toolbelt_metadata.' + expected.ObjectName
           ) AS object_id
       ) AS objects
       WHERE objects.object_id IS NULL
          OR NOT EXISTS
             (
                 SELECT 1
                 FROM sys.extended_properties AS properties
                 WHERE properties.class = 1
                   AND properties.major_id = objects.object_id
                   AND properties.name = N'Toolbelt.ModuleId'
                   AND TRY_CONVERT(nvarchar(128), properties.value)
                       = N'toolbelt.metadata.identifier'
             )
          OR NOT EXISTS
             (
                 SELECT 1
                 FROM sys.extended_properties AS properties
                 WHERE properties.class = 1
                   AND properties.major_id = objects.object_id
                   AND properties.name = N'Toolbelt.SourceHash'
                   AND LEN(TRY_CONVERT(varchar(64), properties.value)) = 64
             )
   )
BEGIN
    THROW 52522, N'Objektmarker oder diagnostischer Source-Hash sind inkonsistent.', 1;
END;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.sql_expression_dependencies
       WHERE referencing_id =
             OBJECT_ID(N'toolbelt_metadata.SVF_QuoteMultipartName', N'FN')
         AND referenced_id =
             OBJECT_ID(N'toolbelt_metadata.TVF_ParseMultipartName', N'TF')
   )
BEGIN
    THROW 52523, N'Die interne Dependency vom Quote-Wrapper zum Parser fehlt.', 1;
END;
