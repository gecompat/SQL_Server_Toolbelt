SET NOCOUNT ON;
-- Deterministische Katalog-Digests vor/nach abgewiesener Lifecycle-Mutation.
DECLARE @Objects nvarchar(max),@Properties nvarchar(max),@Dependencies nvarchar(max);
SELECT @Objects=CONVERT(nvarchar(max),(SELECT o.object_id,o.name,o.type,
 HASHBYTES('SHA2_256',CONVERT(varbinary(max),m.definition)) AS definitionHash
 FROM sys.objects o LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id
 WHERE o.schema_id=SCHEMA_ID(N'toolbelt_pseudonymization')
 ORDER BY o.object_id FOR XML RAW,BINARY BASE64));
SELECT @Properties=CONVERT(nvarchar(max),(SELECT e.class,e.major_id,e.minor_id,e.name,
 CONVERT(nvarchar(max),e.value) AS value,SQL_VARIANT_PROPERTY(e.value,'BaseType') AS baseType
 FROM sys.extended_properties e WHERE
 (e.class=0 AND e.name LIKE N'Toolbelt.Module.toolbelt.pseudonymization.deterministic.%')
 OR (e.class=3 AND e.major_id=SCHEMA_ID(N'toolbelt_pseudonymization'))
 OR (e.class=1 AND EXISTS(SELECT 1 FROM sys.objects o WHERE o.object_id=e.major_id
 AND o.schema_id=SCHEMA_ID(N'toolbelt_pseudonymization')))
 ORDER BY e.class,e.major_id,e.minor_id,e.name FOR XML RAW));
SELECT @Dependencies=CONVERT(nvarchar(max),(SELECT d.referencing_id,d.referenced_id,d.is_schema_bound_reference
 FROM sys.sql_expression_dependencies d WHERE EXISTS(SELECT 1 FROM sys.objects o
 WHERE o.object_id IN(d.referencing_id,d.referenced_id) AND o.schema_id=SCHEMA_ID(N'toolbelt_pseudonymization'))
 ORDER BY d.referencing_id,d.referenced_id,d.is_schema_bound_reference FOR XML RAW));
SELECT CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@Objects)),2) AS ObjectsSha256,
 CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@Properties)),2) AS PropertiesSha256,
 CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@Dependencies)),2) AS DependenciesSha256,
 SCHEMA_ID(N'toolbelt_pseudonymization') AS SchemaId;
