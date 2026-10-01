-- ============================================================================
-- Read-only Lifecycle-Contract-Prüfung nach Deploy.sql
-- ============================================================================

SET NOCOUNT ON;

IF SCHEMA_ID(N'toolbelt_string') IS NULL
   OR OBJECT_ID(N'toolbelt_string.TVF_SplitAdvanced', N'TF') IS NULL
   OR OBJECT_ID(N'toolbelt_string.TVF_UnquoteToken',N'TF') IS NULL
   OR OBJECT_ID(N'toolbelt_string.USP_SplitAdvanced',N'P') IS NULL
BEGIN
    THROW 54520, N'Schema oder Release-Funktion der Modulinstallation fehlt.', 1;
END;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties
       WHERE class = 0
         AND name =
             N'Toolbelt.Module.toolbelt.string.split-advanced.Version'
         AND TRY_CONVERT(nvarchar(64), value) = N'1.1.0'
   )
   OR NOT EXISTS
      (
          SELECT 1
          FROM sys.extended_properties
          WHERE class = 0
            AND name =
                N'Toolbelt.Module.toolbelt.string.split-advanced.DeploymentMode'
            AND TRY_CONVERT(nvarchar(16), value) IN (N'local', N'central')
      )
BEGIN
    THROW 54521, N'Die Modulmarker fehlen oder sind inkonsistent.', 1;
END;

DECLARE @ObjectId int =
    OBJECT_ID(N'toolbelt_string.TVF_SplitAdvanced', N'TF');

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties AS properties
       WHERE properties.class = 1
         AND properties.major_id = @ObjectId
         AND properties.name = N'Toolbelt.ModuleId'
         AND TRY_CONVERT(nvarchar(256), properties.value)
               = N'toolbelt.string.split-advanced'
   )
   OR NOT EXISTS
      (
          SELECT 1
          FROM sys.extended_properties AS properties
          WHERE properties.class = 1
            AND properties.major_id = @ObjectId
            AND properties.name = N'Toolbelt.SourceHash'
            AND TRY_CONVERT(varchar(64), properties.value) =
                CONVERT
                (
                    varchar(64),
                    HASHBYTES
                    (
                        N'SHA2_256',
                        CONVERT(varbinary(max), OBJECT_DEFINITION(@ObjectId))
                    ),
                    2
                )
      )
BEGIN
    THROW 54522, N'Objektmarker oder diagnostischer Source-Hash sind inkonsistent.', 1;
END;

PRINT N'Split-Advanced Lifecycle-Contract-Prüfung: erfolgreich';
DECLARE @Release TABLE(Name sysname,Type char(2));
INSERT @Release VALUES(N'TVF_UnquoteToken','TF'),(N'USP_SplitAdvanced','P');
IF EXISTS(SELECT 1 FROM @Release r LEFT JOIN sys.objects o
       ON o.object_id=OBJECT_ID(N'toolbelt_string.'+r.Name) AND o.type COLLATE DATABASE_DEFAULT=r.Type
       WHERE o.object_id IS NULL
       OR NOT EXISTS(SELECT 1 FROM sys.extended_properties ep WHERE ep.class=1 AND ep.major_id=o.object_id
          AND ep.name=N'Toolbelt.ModuleId' AND CONVERT(nvarchar(128),ep.value)=N'toolbelt.string.split-advanced')
       OR NOT EXISTS(SELECT 1 FROM sys.extended_properties ep WHERE ep.class=1 AND ep.major_id=o.object_id
          AND ep.name=N'Toolbelt.ModuleVersion' AND CONVERT(nvarchar(64),ep.value)=N'1.1.0')
       OR NOT EXISTS(SELECT 1 FROM sys.extended_properties ep WHERE ep.class=1 AND ep.major_id=o.object_id
          AND ep.name=N'Toolbelt.SourceHash' AND CONVERT(varchar(64),ep.value)=
          CONVERT(varchar(64),HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(o.object_id))),2)))
    THROW 54523,N'Neue API-Lifecyclemarker/SourceHash falsch.',1;
GO
