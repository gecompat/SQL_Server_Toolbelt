SET NOCOUNT ON;
DECLARE @Slots TABLE(Name sysname COLLATE DATABASE_DEFAULT,Kind char(2) COLLATE DATABASE_DEFAULT);INSERT @Slots VALUES
(N'TVF_LevenshteinDistance','IF'),(N'TVF_OsaDistance','IF'),(N'TVF_LevenshteinDistanceCore','FT'),(N'TVF_OsaDistanceCore','FT');
IF EXISTS(SELECT 1 FROM @Slots s LEFT JOIN sys.objects o ON o.schema_id=SCHEMA_ID(N'toolbelt_string') AND o.name COLLATE DATABASE_DEFAULT=s.Name COLLATE DATABASE_DEFAULT WHERE o.object_id IS NULL OR o.type COLLATE DATABASE_DEFAULT<>s.Kind COLLATE DATABASE_DEFAULT)
 THROW 55092,N'Vier-Slot-Metadatenvertrag verletzt.',1;
IF EXISTS(SELECT 1 FROM @Slots s JOIN sys.objects o ON o.schema_id=SCHEMA_ID(N'toolbelt_string') AND o.name COLLATE DATABASE_DEFAULT=s.Name COLLATE DATABASE_DEFAULT
 WHERE (SELECT COUNT(*) FROM sys.parameters p WHERE p.object_id=o.object_id AND p.parameter_id>0)<>4)
 THROW 55092,N'Parameteranzahl verletzt.',2;
IF EXISTS(SELECT 1 FROM @Slots s JOIN sys.objects o ON o.schema_id=SCHEMA_ID(N'toolbelt_string') AND o.name COLLATE DATABASE_DEFAULT=s.Name COLLATE DATABASE_DEFAULT
 WHERE (SELECT COUNT(*) FROM sys.columns c WHERE c.object_id=o.object_id)<>3)
 THROW 55092,N'Resultspaltenanzahl verletzt.',3;
IF EXISTS(SELECT 1 FROM @Slots s JOIN sys.objects o ON o.schema_id=SCHEMA_ID(N'toolbelt_string') AND o.name COLLATE DATABASE_DEFAULT=s.Name COLLATE DATABASE_DEFAULT JOIN sys.columns c ON c.object_id=o.object_id
 WHERE c.user_type_id<>c.system_type_id OR(c.column_id IN(1,3) AND c.max_length<>4) OR(c.column_id=2 AND c.max_length<>1) OR (c.column_id=1 AND (c.name<>N'Distance' OR TYPE_NAME(c.system_type_id)<>N'int'))
 OR(c.column_id=2 AND(c.name<>N'ExceedsMaxDistance' OR TYPE_NAME(c.system_type_id)<>N'bit'))
 OR(c.column_id=3 AND(c.name<>N'ErrorCode' OR TYPE_NAME(c.system_type_id)<>N'int')))
 THROW 55092,N'Resulttypen oder Ordinals verletzt.',4;
IF NOT EXISTS(SELECT 1 FROM sys.assemblies WHERE name=N'Toolbelt_String_EditDistance' AND permission_set_desc=N'SAFE_ACCESS')
 THROW 55092,N'SAFE-Provider fehlt.',5;
IF EXISTS(SELECT 1 FROM @Slots s JOIN sys.objects o ON o.schema_id=SCHEMA_ID(N'toolbelt_string') AND o.name COLLATE DATABASE_DEFAULT=s.Name COLLATE DATABASE_DEFAULT JOIN sys.parameters p ON p.object_id=o.object_id
 WHERE p.user_type_id<>p.system_type_id OR(p.parameter_id=3 AND p.max_length<>4) OR (p.parameter_id=1 AND(p.name<>N'@LeftText' OR TYPE_NAME(p.system_type_id)<>N'nvarchar' OR p.max_length<>-1))
 OR(p.parameter_id=2 AND(p.name<>N'@RightText' OR TYPE_NAME(p.system_type_id)<>N'nvarchar' OR p.max_length<>-1))
 OR(p.parameter_id=3 AND(p.name<>N'@MaxDistance' OR TYPE_NAME(p.system_type_id)<>N'int'))
 OR(p.parameter_id=4 AND(p.name<>N'@Profile' OR TYPE_NAME(p.system_type_id)<>N'nvarchar' OR p.max_length<>-1)))
 THROW 55092,N'Parametertyp oder Ordinal verletzt.',6;
SELECT N'PASS' AS Status;
