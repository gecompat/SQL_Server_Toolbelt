-- A deterministic scalar snapshot for before/after comparison on an owned
-- database. The runner uses the same connection and installer for both.
SELECT
(
    SELECT
        JSON_QUERY((
            SELECT o.object_id AS ObjectId, s.name AS SchemaName, o.name AS ObjectName,
                o.type AS ObjectType, o.modify_date AS Modified,
                CONVERT(varchar(64),HASHBYTES('SHA2_256',OBJECT_DEFINITION(o.object_id)),2) AS DefinitionHash
            FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id
            WHERE o.is_ms_shipped=0 AND s.name LIKE N'toolbelt[_]%'
            ORDER BY s.name,o.name,o.object_id
            FOR JSON PATH, INCLUDE_NULL_VALUES
        )) AS Objects,
        JSON_QUERY((
            SELECT a.assembly_id AS AssemblyId,a.name AS AssemblyName, a.modify_date AS Modified,
                f.file_id AS FileId, CONVERT(varchar(64),HASHBYTES('SHA2_256',f.content),2) AS FileHash
            FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id
            WHERE a.is_user_defined=1
            ORDER BY a.name,f.file_id
            FOR JSON PATH
        )) AS Assemblies,
        JSON_QUERY((
            SELECT RootAlias,RootPath,IsActive,AllowRead,AllowWrite,AllowServiceAccount,AllowZipOverwrite
            FROM toolbelt_filesystem.FileSystemRoot
            ORDER BY RootAlias
            FOR JSON PATH
        )) AS Roots
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
) AS Snapshot;
