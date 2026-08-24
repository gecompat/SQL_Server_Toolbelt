SET NOCOUNT ON;

IF OBJECT_ID(N'toolbelt_archive.USP_ExtractZipEntryFromBinary', N'P') IS NULL
    THROW 51380, N'Lifecycle-Voraussetzung fehlt: öffentliche Procedure ist nicht installiert.', 1;

IF OBJECT_ID(N'toolbelt_archive.TVF_InternalExtractZipEntryClr', N'FT') IS NULL
    THROW 51380, N'Lifecycle-Voraussetzung fehlt: interne CLR-Tabellefunktion ist nicht installiert.', 1;

IF OBJECT_ID(N'toolbelt_archive.USP_ListZipEntriesFromBinary', N'P') IS NULL
    THROW 51380, N'Lifecycle-Voraussetzung fehlt: öffentliche ZIP-Metadaten-Procedure ist nicht installiert.', 1;

IF OBJECT_ID(N'toolbelt_archive.TVF_InternalListZipEntriesClr', N'FT') IS NULL
    THROW 51380, N'Lifecycle-Voraussetzung fehlt: interner CLR-Metadatenprovider ist nicht installiert.', 1;

DECLARE @AssemblyId int =
    (
        SELECT assembly_id
        FROM sys.assemblies
        WHERE name = N'Toolbelt_Archive_ZipMemory'
          AND permission_set_desc = N'SAFE_ACCESS'
    );

IF @AssemblyId IS NULL
    THROW 51380, N'Lifecycle-Voraussetzung fehlt: SAFE-CLR-ZIP-Assembly ist nicht installiert.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties
       WHERE class = 0
         AND major_id = 0
         AND minor_id = 0
         AND name = N'Toolbelt.Module.toolbelt.archive.zip-memory.Version'
         AND TRY_CONVERT(nvarchar(64), value) = N'1.2.0'
   )
    THROW 51381, N'Der erwartete Modulversionsmarker 1.2.0 fehlt.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties
       WHERE class = 0
         AND major_id = 0
         AND minor_id = 0
         AND name = N'Toolbelt.Module.toolbelt.archive.zip-memory.DeploymentMode'
         AND TRY_CONVERT(nvarchar(16), value) IN (N'local', N'central')
   )
    THROW 51382, N'Der erwartete Deployment-Mode-Marker fehlt.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties
       WHERE class = 5
         AND major_id = @AssemblyId
         AND minor_id = 0
         AND name = N'Toolbelt.Managed'
         AND TRY_CONVERT(bit, value) = 1
   )
    THROW 51383, N'Die CLR-ZIP-Assembly besitzt keinen Toolbelt-Managed-Marker.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties
       WHERE class = 5
         AND major_id = @AssemblyId
         AND minor_id = 0
         AND name = N'Toolbelt.ModuleId'
         AND TRY_CONVERT(nvarchar(128), value) = N'toolbelt.archive.zip-memory'
   )
    THROW 51383, N'Die CLR-ZIP-Assembly besitzt keinen korrekten Modulmarker.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.assembly_modules
       WHERE assembly_id = @AssemblyId
         AND object_id = OBJECT_ID(N'toolbelt_archive.TVF_InternalExtractZipEntryClr')
   )
    THROW 51384, N'Die interne CLR-Tabellefunktion ist nicht mit der erwarteten Assembly verknüpft.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.assembly_modules
       WHERE assembly_id = @AssemblyId
         AND object_id = OBJECT_ID(N'toolbelt_archive.TVF_InternalListZipEntriesClr')
   )
    THROW 51384, N'Der interne CLR-Metadatenprovider ist nicht mit der erwarteten Assembly verknüpft.', 1;

IF EXISTS
   (
       SELECT 1
       FROM sys.assembly_references AS ar
       INNER JOIN sys.assemblies AS referenced_assembly
         ON referenced_assembly.assembly_id = ar.referenced_assembly_id
       WHERE ar.assembly_id = @AssemblyId
         AND referenced_assembly.name = N'System.IO.Compression'
   )
    THROW 51384, N'Die Assembly darf System.IO.Compression.dll nicht direkt referenzieren.', 1;

PRINT N'ZIP Memory CLR Lifecycle-Contract-Prüfung: erfolgreich';
GO

:r Encoding.Contract.sql
:r Metadata.Contract.sql
