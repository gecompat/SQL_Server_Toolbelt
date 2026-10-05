-- Installierter Baselinevertrag; ausführende Lifecycle-Negativfälle gehören dem eigenen CI-Adapter.
-- Keine Installation oder Änderung einer Datenbank, Konfiguration oder Berechtigung.
SET NOCOUNT ON;
DECLARE @Database sysname=NULLIF(N'$(ToolbeltDatabase)',N''),@Prefix nvarchar(520),@Sql nvarchar(max);
SET @Prefix=CASE WHEN @Database IS NULL THEN N'' ELSE QUOTENAME(@Database)+N'.' END;
SET @Sql=N'DECLARE @Expected TABLE(Name sysname NOT NULL PRIMARY KEY);
INSERT @Expected VALUES(N''TVF_TryCastBigInt''),(N''TVF_TryCastDecimal''),(N''TVF_TryCastDate''),(N''TVF_TryCastDateTime2''),(N''TVF_TryCastBit''),(N''TVF_TryCastUniqueIdentifier'');
IF EXISTS(SELECT 1 FROM @Expected e LEFT JOIN '+@Prefix+N'sys.objects o ON o.name=e.Name AND o.schema_id=(SELECT schema_id FROM '+@Prefix+N'sys.schemas WHERE name=N''toolbelt_conversion'') LEFT JOIN '+@Prefix+N'sys.sql_modules m ON m.object_id=o.object_id WHERE o.object_id IS NULL OR o.type<>''IF'' OR m.is_schema_bound<>1 OR (SELECT COUNT(*) FROM '+@Prefix+N'sys.parameters p WHERE p.object_id=o.object_id)<>2 OR (SELECT COUNT(*) FROM '+@Prefix+N'sys.columns c WHERE c.object_id=o.object_id)<>3)
 THROW 55492,N''Safe Cast: sechs schemagebundene IF-Slots mit zwei Parametern/drei Spalten erforderlich.'',1;
IF (SELECT COUNT(*) FROM '+@Prefix+N'sys.extended_properties ep JOIN '+@Prefix+N'sys.objects o ON o.object_id=ep.major_id WHERE ep.class=1 AND ep.minor_id=0 AND ep.name=N''Toolbelt.ModuleId'' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),ep.value))=CONVERT(varbinary(max),N''toolbelt.conversion.safe-cast''))<>6
 THROW 55492,N''Safe Cast: genau sechs markierte Moduleigentümer erforderlich.'',2;
SELECT N''PASS'' AS Status;';
EXEC sys.sp_executesql @Sql;
GO
