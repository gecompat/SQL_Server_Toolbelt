SET NOCOUNT ON;
-- Synthetische, ausschließlich dem aktuellen Release zugeordnete Testdatenbank.
IF TRY_CONVERT(nvarchar(64), DATABASEPROPERTYEX(DB_NAME(), N'Updateability')) <> N'READ_WRITE'
    THROW 52082, N'Die Testdatenbank ist nicht schreibbar.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0
    AND name = N'Toolbelt.Module.toolbelt.string.regex.Version'
    AND CONVERT(varbinary(max), TRY_CONVERT(nvarchar(max), value)) = CONVERT(varbinary(max), N'1.3.0'))
    THROW 52083, N'Der exakte Modulversionsmarker fehlt.', 1;
DECLARE @Expected TABLE (Name sysname COLLATE DATABASE_DEFAULT PRIMARY KEY, Kind char(2) COLLATE DATABASE_DEFAULT);
INSERT @Expected VALUES
 (N'SVF_RegexIsMatch','FS'),
 (N'SVF_RegexInstr','FS'),
 (N'SVF_RegexCount','FS'),
 (N'SVF_RegexReplace','FN'),
 (N'SVF_RegexSubstring','FN'),
 (N'SVF_RegexReplaceCore','FS'),
 (N'SVF_RegexSubstringCore','FS'),
 (N'TVF_RegexMatches','IF'),
 (N'TVF_RegexSplit','IF'),
 (N'TVF_RegexMatchesCore','FT'),
 (N'TVF_RegexSplitCore','FT'),
 (N'TVF_RegexCaptures','IF'),
 (N'SVF_RegexReplaceGroups','FN'),
 (N'TVF_RegexCapturesCore','FT'),
 (N'SVF_RegexReplaceGroupsCore','FS');
IF EXISTS (SELECT 1 FROM @Expected x LEFT JOIN sys.objects o
    ON o.schema_id = SCHEMA_ID(N'toolbelt_string') AND o.name COLLATE DATABASE_DEFAULT = x.Name COLLATE DATABASE_DEFAULT
    WHERE o.object_id IS NULL OR o.type COLLATE DATABASE_DEFAULT <> x.Kind COLLATE DATABASE_DEFAULT
      OR NOT EXISTS (SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0
          AND e.name=N'Toolbelt.Managed' AND TRY_CONVERT(int,e.value)=1)
      OR NOT EXISTS (SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0
          AND e.name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),N'toolbelt.string.regex'))
      OR NOT EXISTS (SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0
          AND e.name=N'Toolbelt.ModuleVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),N'1.3.0'))
      OR NOT EXISTS (SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0
          AND e.name=N'Toolbelt.Visibility' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=
              CONVERT(varbinary(max),CASE WHEN RIGHT(x.Name,4)=N'Core' THEN N'internal' ELSE N'public' END)))
    THROW 52086, N'Das vollständige 15-Slot-Manifest oder seine Marker sind nicht kohärent.', 1;
DECLARE @AssemblyId int=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_String_Regex'
 AND permission_set_desc=N'SAFE_ACCESS' AND LOWER(clr_name) LIKE N'toolbelt.string.regex, version=1.3.0.0,%');
IF @AssemblyId IS NULL OR EXISTS (SELECT 1 FROM sys.assembly_modules m JOIN @Expected x
 ON OBJECT_ID(N'toolbelt_string.'+x.Name)=m.object_id WHERE m.assembly_id<>@AssemblyId)
 OR NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=5 AND major_id=@AssemblyId AND minor_id=0
 AND name=N'Toolbelt.Managed' AND TRY_CONVERT(int,value)=1)
 OR NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=5 AND major_id=@AssemblyId AND minor_id=0
 AND name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'toolbelt.string.regex'))
 OR NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=5 AND major_id=@AssemblyId AND minor_id=0
 AND name=N'Toolbelt.ModuleVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'1.3.0'))
 THROW 52084,N'Die SAFE-Assembly oder ihre Zuordnung ist nicht kohärent.',1;
PRINT N'Regex-Lifecycle-Contract erfolgreich.';
