SET NOCOUNT ON;
DECLARE @Slots TABLE(Name sysname COLLATE DATABASE_DEFAULT,Kind char(2) COLLATE DATABASE_DEFAULT);INSERT @Slots VALUES
(N'TVF_LevenshteinDistance','IF'),(N'TVF_OsaDistance','IF'),(N'TVF_LevenshteinDistanceCore','FT'),(N'TVF_OsaDistanceCore','FT'),(N'TVF_JaroWinklerSimilarity','IF'),(N'TVF_JaroWinklerSimilarityCore','FT');
IF EXISTS(SELECT 1 FROM @Slots s LEFT JOIN sys.objects o ON o.schema_id=SCHEMA_ID(N'toolbelt_string') AND o.name COLLATE DATABASE_DEFAULT=s.Name COLLATE DATABASE_DEFAULT WHERE o.object_id IS NULL OR o.type COLLATE DATABASE_DEFAULT<>s.Kind COLLATE DATABASE_DEFAULT)
 THROW 55092,N'Sechs-Slot-Metadatenvertrag verletzt.',1;
IF EXISTS(SELECT 1 FROM @Slots s JOIN sys.objects o ON o.schema_id=SCHEMA_ID(N'toolbelt_string') AND o.name COLLATE DATABASE_DEFAULT=s.Name COLLATE DATABASE_DEFAULT
 WHERE (SELECT COUNT(*) FROM sys.parameters p WHERE p.object_id=o.object_id AND p.parameter_id>0)<>CASE WHEN s.Name LIKE N'TVF_Jaro%' THEN 3 ELSE 4 END)
 THROW 55092,N'Parameteranzahl verletzt.',2;
IF EXISTS(SELECT 1 FROM @Slots s JOIN sys.objects o ON o.schema_id=SCHEMA_ID(N'toolbelt_string') AND o.name COLLATE DATABASE_DEFAULT=s.Name COLLATE DATABASE_DEFAULT
 WHERE (SELECT COUNT(*) FROM sys.columns c WHERE c.object_id=o.object_id)<>CASE WHEN s.Name LIKE N'TVF_Jaro%' THEN 2 ELSE 3 END)
 THROW 55092,N'Resultspaltenanzahl verletzt.',3;
IF EXISTS(SELECT 1 FROM @Slots s JOIN sys.objects o ON o.schema_id=SCHEMA_ID(N'toolbelt_string') AND o.name COLLATE DATABASE_DEFAULT=s.Name COLLATE DATABASE_DEFAULT JOIN sys.columns c ON c.object_id=o.object_id
 WHERE s.Name NOT LIKE N'TVF_Jaro%' AND (c.user_type_id<>c.system_type_id OR(c.column_id IN(1,3) AND c.max_length<>4) OR(c.column_id=2 AND c.max_length<>1) OR (c.column_id=1 AND (c.name<>N'Distance' OR TYPE_NAME(c.system_type_id)<>N'int'))
 OR(c.column_id=2 AND(c.name<>N'ExceedsMaxDistance' OR TYPE_NAME(c.system_type_id)<>N'bit'))
 OR(c.column_id=3 AND(c.name<>N'ErrorCode' OR TYPE_NAME(c.system_type_id)<>N'int'))))
 THROW 55092,N'Resulttypen oder Ordinals verletzt.',4;
IF NOT EXISTS(SELECT 1 FROM sys.assemblies WHERE name=N'Toolbelt_String_EditDistance' AND permission_set_desc=N'SAFE_ACCESS')
 THROW 55092,N'SAFE-Provider fehlt.',5;
IF EXISTS(SELECT 1 FROM @Slots s JOIN sys.objects o ON o.schema_id=SCHEMA_ID(N'toolbelt_string') AND o.name COLLATE DATABASE_DEFAULT=s.Name COLLATE DATABASE_DEFAULT JOIN sys.parameters p ON p.object_id=o.object_id
 WHERE s.Name NOT LIKE N'TVF_Jaro%' AND (p.user_type_id<>p.system_type_id OR(p.parameter_id=3 AND p.max_length<>4) OR (p.parameter_id=1 AND(p.name<>N'@LeftText' OR TYPE_NAME(p.system_type_id)<>N'nvarchar' OR p.max_length<>-1))
 OR(p.parameter_id=2 AND(p.name<>N'@RightText' OR TYPE_NAME(p.system_type_id)<>N'nvarchar' OR p.max_length<>-1))
 OR(p.parameter_id=3 AND(p.name<>N'@MaxDistance' OR TYPE_NAME(p.system_type_id)<>N'int'))
 OR(p.parameter_id=4 AND(p.name<>N'@Profile' OR TYPE_NAME(p.system_type_id)<>N'nvarchar' OR p.max_length<>-1))))
 THROW 55092,N'Parametertyp oder Ordinal verletzt.',6;
IF EXISTS(SELECT 1 FROM @Slots s JOIN sys.objects o ON o.schema_id=SCHEMA_ID(N'toolbelt_string') AND o.name COLLATE DATABASE_DEFAULT=s.Name COLLATE DATABASE_DEFAULT
 JOIN sys.parameters p ON p.object_id=o.object_id WHERE s.Name LIKE N'TVF_Jaro%' AND
 (p.user_type_id<>p.system_type_id OR TYPE_NAME(p.system_type_id)<>N'nvarchar' OR p.max_length<>-1
 OR CONVERT(varbinary(max),p.name)<>CONVERT(varbinary(max),CASE p.parameter_id WHEN 1 THEN N'@LeftText' WHEN 2 THEN N'@RightText' WHEN 3 THEN N'@Profile' END)))
 THROW 55092,N'Jaro-Parametervertrag verletzt.',7;
IF EXISTS(SELECT 1 FROM @Slots s JOIN sys.objects o ON o.schema_id=SCHEMA_ID(N'toolbelt_string') AND o.name COLLATE DATABASE_DEFAULT=s.Name COLLATE DATABASE_DEFAULT
 JOIN sys.columns c ON c.object_id=o.object_id WHERE s.Name LIKE N'TVF_Jaro%' AND
 (c.user_type_id<>c.system_type_id OR(c.column_id=1 AND(CONVERT(varbinary(max),c.name)<>CONVERT(varbinary(max),N'Similarity') OR TYPE_NAME(c.system_type_id)<>N'float' OR c.max_length<>8 OR c.precision<>53))
 OR(c.column_id=2 AND(CONVERT(varbinary(max),c.name)<>CONVERT(varbinary(max),N'ErrorCode') OR TYPE_NAME(c.system_type_id)<>N'int' OR c.max_length<>4))))
 THROW 55092,N'Jaro-Resultvertrag verletzt.',8;
IF EXISTS(SELECT 1 FROM sys.assembly_modules m JOIN sys.objects o ON o.object_id=m.object_id
 WHERE o.schema_id=SCHEMA_ID(N'toolbelt_string') AND o.name=N'TVF_JaroWinklerSimilarityCore' AND
 (CONVERT(varbinary(max),m.assembly_class)<>CONVERT(varbinary(max),N'Toolbelt.String.EditDistance.JaroProvider')
 OR CONVERT(varbinary(max),m.assembly_method)<>CONVERT(varbinary(max),N'Evaluate')))
 THROW 55092,N'Jaro-EntryPoint verletzt.',9;
SELECT N'PASS' AS Status;
