SET NOCOUNT ON;
DECLARE @Assembly int=(SELECT assembly_id FROM sys.assemblies WHERE CONVERT(varbinary(max),name)=CONVERT(varbinary(max),N'Toolbelt_String_Phonetic'));
IF @Assembly IS NULL OR NOT EXISTS(SELECT 1 FROM sys.assemblies WHERE assembly_id=@Assembly AND permission_set=1 AND is_user_defined=1)
 THROW 55283,N'Die eigene SAFE-Assembly fehlt.',1;
DECLARE @Slots TABLE(Name sysname,Kind char(2),Method sysname NULL,CodeColumns int);
INSERT @Slots VALUES(N'TVF_ColognePhonetic','IF',NULL,1),(N'TVF_DoubleMetaphone','IF',NULL,2),(N'TVF_ColognePhoneticCore','FT',N'EvaluateCologne',1),(N'TVF_DoubleMetaphoneCore','FT',N'EvaluateDoubleMetaphone',2);
IF EXISTS(SELECT 1 FROM @Slots s LEFT JOIN sys.objects o ON o.schema_id=SCHEMA_ID(N'toolbelt_string') AND CONVERT(varbinary(max),o.name)=CONVERT(varbinary(max),s.Name)
 WHERE o.object_id IS NULL OR CONVERT(varbinary(2),o.type)<>CONVERT(varbinary(2),s.Kind)
 OR(SELECT COUNT(*) FROM sys.parameters WHERE object_id=o.object_id AND parameter_id>0)<>1
 OR NOT EXISTS(SELECT 1 FROM sys.parameters WHERE object_id=o.object_id AND parameter_id=1 AND system_type_id=231 AND user_type_id=231 AND max_length=-1 AND has_default_value=0)
 OR(SELECT COUNT(*) FROM sys.columns WHERE object_id=o.object_id)<>s.CodeColumns+1
 OR(s.Kind='FT' AND NOT EXISTS(SELECT 1 FROM sys.assembly_modules m WHERE m.object_id=o.object_id AND m.assembly_id=@Assembly AND m.null_on_null_input=0 AND CONVERT(varbinary(max),m.assembly_class)=CONVERT(varbinary(max),N'Toolbelt.String.Phonetic.PhoneticBridge') AND CONVERT(varbinary(max),m.assembly_method)=CONVERT(varbinary(max),s.Method)))
 OR EXISTS(SELECT 1 FROM sys.columns c WHERE c.object_id=o.object_id AND(c.user_type_id<>c.system_type_id OR(c.column_id<=s.CodeColumns AND(c.system_type_id<>CASE WHEN s.Kind='FT' THEN 231 ELSE 167 END OR c.max_length<>-1 OR c.is_nullable<>1)) OR(c.column_id=s.CodeColumns+1 AND(c.system_type_id<>56 OR c.max_length<>4)))))
 THROW 55283,N'Die vier typgenauen Slotbindungen stimmen nicht.',2;
IF EXISTS(SELECT 1 FROM @Slots s JOIN sys.objects o ON o.schema_id=SCHEMA_ID(N'toolbelt_string') AND o.name=s.Name COLLATE DATABASE_DEFAULT JOIN sys.columns c ON c.object_id=o.object_id WHERE s.Kind='IF' AND c.column_id<=s.CodeColumns AND CONVERT(varbinary(max),c.collation_name)<>CONVERT(varbinary(max),N'Latin1_General_100_BIN2'))
 THROW 55283,N'Die öffentlichen Code-Collations stimmen nicht.',3;
PRINT 'PASS PHONETIC_INSTALLED_METADATA';
GO