-- Installierte Pointer-Baseline; ausführende Negativfälle gehören dem eigenen Labadapter.
SET NOCOUNT ON;
DECLARE @Database sysname=NULLIF(N'$(ToolbeltDatabase)',N''),@Prefix nvarchar(520),@Sql nvarchar(max);
SET @Prefix=CASE WHEN @Database IS NULL THEN N'' ELSE QUOTENAME(@Database)+N'.' END;
SET @Sql=N'DECLARE @Id int=(SELECT o.object_id FROM '+@Prefix+N'sys.objects o JOIN '+@Prefix+N'sys.schemas s ON s.schema_id=o.schema_id WHERE s.name=N''toolbelt_json'' AND o.name=N''TVF_ResolveJsonPointer'');
IF @Id IS NULL OR NOT EXISTS(SELECT 1 FROM '+@Prefix+N'sys.objects WHERE object_id=@Id AND type=''TF'')
 OR (SELECT COUNT(*) FROM '+@Prefix+N'sys.parameters WHERE object_id=@Id)<>4
 OR (SELECT COUNT(*) FROM '+@Prefix+N'sys.columns WHERE object_id=@Id)<>4
 THROW 55592,N''Pointer: genau ein TF-Slot mit vier Parametern/vier Spalten erforderlich.'',1;
IF (SELECT COUNT(*) FROM '+@Prefix+N'sys.extended_properties p JOIN '+@Prefix+N'sys.objects o ON o.object_id=p.major_id WHERE p.class=1 AND p.minor_id=0 AND p.name=N''Toolbelt.ModuleId'' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),p.value))=CONVERT(varbinary(max),N''toolbelt.json.pointer''))<>1
 OR NOT EXISTS(SELECT 1 FROM '+@Prefix+N'sys.extended_properties WHERE class=1 AND major_id=@Id AND minor_id=0 AND name=N''Toolbelt.Managed'' AND SQL_VARIANT_PROPERTY(value,N''BaseType'')=N''bit'' AND TRY_CONVERT(bit,value)=1)
 THROW 55592,N''Pointer: typisierte eigene Slotmarker fehlen.'',2;
IF EXISTS(SELECT 1 FROM '+@Prefix+N'sys.assembly_modules WHERE object_id=@Id)
 THROW 55592,N''Pointer: keine CLR-Bindung zulässig.'',3;
SELECT N''PASS'' Status;';
EXEC sys.sp_executesql @Sql;
GO
