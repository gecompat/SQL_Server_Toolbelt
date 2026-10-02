-- Vergleich vor/nach abgewiesenem Lifecycle: nur deterministische Katalog-Digests.
DECLARE @Objects nvarchar(max), @Properties nvarchar(max), @Assemblies nvarchar(max), @Dependencies nvarchar(max);
SELECT @Objects=CONVERT(nvarchar(max),(SELECT o.object_id AS id,o.name,o.type,
 HASHBYTES('SHA2_256',CONVERT(varbinary(max),m.definition)) AS definitionHash
 FROM sys.objects o LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id
 WHERE o.schema_id=SCHEMA_ID(N'toolbelt_string') OR o.name LIKE N'ToolbeltRegexFixture%'
 ORDER BY o.object_id FOR XML RAW, BINARY BASE64));
SELECT @Properties=CONVERT(nvarchar(max),(SELECT e.class,e.major_id,e.minor_id,e.name,
 CONVERT(nvarchar(max),e.value) AS value,SQL_VARIANT_PROPERTY(e.value,'BaseType') AS baseType
 FROM sys.extended_properties e
 WHERE (e.class=0 AND e.name LIKE N'Toolbelt.Module.toolbelt.string.regex.%')
 OR (e.class=3 AND e.major_id=SCHEMA_ID(N'toolbelt_string'))
 OR (e.class=1 AND EXISTS(SELECT 1 FROM sys.objects o WHERE o.object_id=e.major_id AND o.schema_id=SCHEMA_ID(N'toolbelt_string')))
 OR (e.class=5 AND EXISTS(SELECT 1 FROM sys.assemblies a WHERE a.assembly_id=e.major_id AND a.name=N'Toolbelt_String_Regex'))
 ORDER BY e.class,e.major_id,e.minor_id,e.name FOR XML RAW));
SELECT @Assemblies=CONVERT(nvarchar(max),(SELECT a.assembly_id,a.name,a.clr_name,a.permission_set_desc,
 HASHBYTES('SHA2_512',f.content) AS assemblyHash
 FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1
 WHERE a.name=N'Toolbelt_String_Regex' ORDER BY a.assembly_id FOR XML RAW,BINARY BASE64));
SELECT @Dependencies=CONVERT(nvarchar(max),(SELECT d.referencing_id,d.referenced_id,d.is_schema_bound_reference
 FROM sys.sql_expression_dependencies d
 WHERE EXISTS(SELECT 1 FROM sys.objects o WHERE o.object_id IN(d.referencing_id,d.referenced_id)
 AND o.schema_id=SCHEMA_ID(N'toolbelt_string'))
 ORDER BY d.referencing_id,d.referenced_id,d.is_schema_bound_reference FOR XML RAW));
SELECT CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@Objects)),2) AS ObjectsSha256,
 CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@Properties)),2) AS PropertiesSha256,
 CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@Assemblies)),2) AS AssembliesSha256,
 CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@Dependencies)),2) AS DependenciesSha256,
 SCHEMA_ID(N'toolbelt_string') AS SchemaId;
