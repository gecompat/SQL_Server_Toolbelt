SET NOCOUNT ON;
-- Synthetische, ausschließlich dem aktuellen Release zugeordnete Testdatenbank.
IF TRY_CONVERT(nvarchar(64), DATABASEPROPERTYEX(DB_NAME(), N'Updateability')) <> N'READ_WRITE'
    THROW 55082, N'Die Testdatenbank ist nicht schreibbar.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0
    AND name = N'Toolbelt.Module.toolbelt.string.edit-distance.Version'
    AND CONVERT(varbinary(max), TRY_CONVERT(nvarchar(max), value)) = CONVERT(varbinary(max), N'1.1.0'))
    THROW 55083, N'Der exakte Modulversionsmarker fehlt.', 1;
DECLARE @Expected TABLE (Name sysname COLLATE DATABASE_DEFAULT PRIMARY KEY, Kind char(2) COLLATE DATABASE_DEFAULT);
INSERT @Expected VALUES
 (N'TVF_LevenshteinDistance','IF'),(N'TVF_OsaDistance','IF'),
 (N'TVF_LevenshteinDistanceCore','FT'),(N'TVF_OsaDistanceCore','FT'),(N'TVF_JaroWinklerSimilarity','IF'),(N'TVF_JaroWinklerSimilarityCore','FT');
IF EXISTS (SELECT 1 FROM @Expected x LEFT JOIN sys.objects o
    ON o.schema_id = SCHEMA_ID(N'toolbelt_string') AND o.name COLLATE DATABASE_DEFAULT = x.Name COLLATE DATABASE_DEFAULT
    WHERE o.object_id IS NULL OR o.type COLLATE DATABASE_DEFAULT <> x.Kind COLLATE DATABASE_DEFAULT
      OR NOT EXISTS (SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0
          AND e.name=N'Toolbelt.Managed' AND TRY_CONVERT(int,e.value)=1)
      OR NOT EXISTS (SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0
          AND e.name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),N'toolbelt.string.edit-distance'))
      OR NOT EXISTS (SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0
          AND e.name=N'Toolbelt.ModuleVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),N'1.1.0'))
      OR NOT EXISTS (SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0
          AND e.name=N'Toolbelt.Visibility' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=
              CONVERT(varbinary(max),CASE WHEN RIGHT(x.Name,4)=N'Core' THEN N'internal' ELSE N'public' END)))
    THROW 55086, N'Das vollständige 6-Slot-Manifest oder seine Marker sind nicht kohärent.', 1;
DECLARE @AssemblyId int=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_String_EditDistance'
 AND permission_set_desc=N'SAFE_ACCESS' AND is_user_defined=1);
IF @AssemblyId IS NULL OR EXISTS (SELECT 1 FROM sys.assembly_modules m JOIN @Expected x
 ON OBJECT_ID(N'toolbelt_string.'+x.Name)=m.object_id WHERE m.assembly_id<>@AssemblyId)
 OR NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=5 AND major_id=@AssemblyId AND minor_id=0
 AND name=N'Toolbelt.Managed' AND TRY_CONVERT(int,value)=1)
 OR NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=5 AND major_id=@AssemblyId AND minor_id=0
 AND name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'toolbelt.string.edit-distance'))
 OR NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=5 AND major_id=@AssemblyId AND minor_id=0
 AND name=N'Toolbelt.ModuleVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'1.1.0'))
 THROW 55084,N'Die SAFE-Assembly oder ihre Zuordnung ist nicht kohärent.',1;
IF NOT EXISTS (SELECT 1 FROM sys.assembly_files WHERE assembly_id=@AssemblyId AND file_id=1
 AND HASHBYTES(N'SHA2_512',content)=CONVERT(varbinary(64),N'$(ExpectedInstalledAssemblyHash)',1))
 THROW 55084,N'Die installierten Assemblybytes entsprechen nicht dem qualifizierten Releasebinary.',2;
PRINT N'Editierdistanz-Lifecycle-Contract erfolgreich.';
