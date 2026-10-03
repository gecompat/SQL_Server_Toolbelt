SET NOCOUNT ON;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0
 AND name=N'Toolbelt.Module.toolbelt.string.edit-distance.Version'
 AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'1.0.0'))
 THROW 55083,N'Genuine 1.0-Modulmarker fehlt.',10;
DECLARE @Slots TABLE(Name sysname COLLATE DATABASE_DEFAULT PRIMARY KEY,Kind char(2) COLLATE DATABASE_DEFAULT);
INSERT @Slots VALUES(N'TVF_LevenshteinDistance','IF'),(N'TVF_OsaDistance','IF'),
(N'TVF_LevenshteinDistanceCore','FT'),(N'TVF_OsaDistanceCore','FT');
IF EXISTS(SELECT 1 FROM @Slots s LEFT JOIN sys.objects o ON o.schema_id=SCHEMA_ID(N'toolbelt_string') AND o.name COLLATE DATABASE_DEFAULT=s.Name
 WHERE o.object_id IS NULL OR o.type COLLATE DATABASE_DEFAULT<>s.Kind
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0
 AND e.name=N'Toolbelt.ModuleVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),N'1.0.0')))
 THROW 55086,N'Genuine Vier-Slot-Zustand inkohärent.',10;
IF NOT EXISTS(SELECT 1 FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1
 WHERE a.name=N'Toolbelt_String_EditDistance' AND a.permission_set_desc=N'SAFE_ACCESS'
 AND HASHBYTES(N'SHA2_512',f.content)=CONVERT(varbinary(64),N'$(ExpectedInstalledAssemblyHash)',1))
 THROW 55084,N'Genuine Binarybindung verletzt.',10;
