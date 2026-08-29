-- Interner Q1-Baustein: kanonischer Katalog-Snapshot einer isolierten
-- T-SQL-Modulinstallation. Die Datei wird zweimal aus dem Contract eingebunden.
SET NOCOUNT ON;

DECLARE @SnapshotOrdinal tinyint = TRY_CONVERT(tinyint, N'$(SnapshotOrdinal)');
IF @SnapshotOrdinal NOT IN (1, 2)
    THROW 52941, N'Der Snapshot-Ordinal muss 1 oder 2 sein.', 1;

INSERT INTO #tbx_MigrationSnapshot
(
      SnapshotOrdinal
    , ItemKind
    , ItemKey
    , ItemValue
)
SELECT
      @SnapshotOrdinal
    , N'SCHEMA'
    , schemas.name
    , CONCAT(N'owner=', schemas.principal_id)
FROM sys.schemas AS schemas
WHERE schemas.name COLLATE Latin1_General_100_BIN2
          LIKE N'toolbelt[_]%' COLLATE Latin1_General_100_BIN2
UNION ALL
SELECT
      @SnapshotOrdinal
    , N'OBJECT'
    , CONCAT(schemas.name, N'.', objects.name)
    , CONCAT(N'type=', objects.type, N';schema_bound=',
             TRY_CONVERT
             (
                 nvarchar(16),
                 OBJECTPROPERTYEX(objects.object_id, N'IsSchemaBound')
             ))
FROM sys.objects AS objects
JOIN sys.schemas AS schemas
  ON schemas.schema_id = objects.schema_id
WHERE schemas.name COLLATE Latin1_General_100_BIN2
          LIKE N'toolbelt[_]%' COLLATE Latin1_General_100_BIN2
  AND objects.is_ms_shipped = 0
UNION ALL
SELECT
      @SnapshotOrdinal
    , N'MODULE'
    , CONCAT(schemas.name, N'.', objects.name)
    , CONCAT
      (
          N'ansi=', modules.uses_ansi_nulls,
          N';quoted=', modules.uses_quoted_identifier,
          N';definition=', ISNULL(modules.definition, N'<encrypted>')
      )
FROM sys.objects AS objects
JOIN sys.schemas AS schemas
  ON schemas.schema_id = objects.schema_id
JOIN sys.sql_modules AS modules
  ON modules.object_id = objects.object_id
WHERE schemas.name COLLATE Latin1_General_100_BIN2
          LIKE N'toolbelt[_]%' COLLATE Latin1_General_100_BIN2
UNION ALL
SELECT
      @SnapshotOrdinal
    , N'COLUMN'
    , CONCAT(schemas.name, N'.', objects.name, N'#', columns.column_id)
    , CONCAT
      (
          N'name=', columns.name,
          N';system_type=', columns.system_type_id,
          N';user_type=', columns.user_type_id,
          N';max_length=', columns.max_length,
          N';precision=', columns.precision,
          N';scale=', columns.scale,
          N';collation=', ISNULL(columns.collation_name, N''),
          N';nullable=', columns.is_nullable,
          N';identity=', columns.is_identity,
          N';computed=', columns.is_computed
      )
FROM sys.objects AS objects
JOIN sys.schemas AS schemas
  ON schemas.schema_id = objects.schema_id
JOIN sys.columns AS columns
  ON columns.object_id = objects.object_id
WHERE schemas.name COLLATE Latin1_General_100_BIN2
          LIKE N'toolbelt[_]%' COLLATE Latin1_General_100_BIN2
UNION ALL
SELECT
      @SnapshotOrdinal
    , N'PARAMETER'
    , CONCAT(schemas.name, N'.', objects.name, N'#', parameters.parameter_id)
    , CONCAT
      (
          N'name=', parameters.name,
          N';system_type=', parameters.system_type_id,
          N';user_type=', parameters.user_type_id,
          N';max_length=', parameters.max_length,
          N';precision=', parameters.precision,
          N';scale=', parameters.scale,
          N';output=', parameters.is_output,
          N';readonly=', parameters.is_readonly
      )
FROM sys.objects AS objects
JOIN sys.schemas AS schemas
  ON schemas.schema_id = objects.schema_id
JOIN sys.parameters AS parameters
  ON parameters.object_id = objects.object_id
WHERE schemas.name COLLATE Latin1_General_100_BIN2
          LIKE N'toolbelt[_]%' COLLATE Latin1_General_100_BIN2
UNION ALL
SELECT
      @SnapshotOrdinal
    , N'DATABASE_PROPERTY'
    , properties.name
    , TRY_CONVERT(nvarchar(max), properties.value)
FROM sys.extended_properties AS properties
WHERE properties.class = 0
  AND properties.major_id = 0
  AND properties.minor_id = 0
  AND properties.name COLLATE Latin1_General_100_BIN2
        LIKE N'Toolbelt.%' COLLATE Latin1_General_100_BIN2
UNION ALL
SELECT
      @SnapshotOrdinal
    , N'OBJECT_PROPERTY'
    , CONCAT(schemas.name, N'.', objects.name, N'#', properties.name)
    , TRY_CONVERT(nvarchar(max), properties.value)
FROM sys.extended_properties AS properties
JOIN sys.objects AS objects
  ON properties.class = 1
 AND properties.major_id = objects.object_id
 AND properties.minor_id = 0
JOIN sys.schemas AS schemas
  ON schemas.schema_id = objects.schema_id
WHERE schemas.name COLLATE Latin1_General_100_BIN2
          LIKE N'toolbelt[_]%' COLLATE Latin1_General_100_BIN2
UNION ALL
SELECT
      @SnapshotOrdinal
    , N'SCHEMA_PROPERTY'
    , CONCAT(schemas.name, N'#', properties.name)
    , TRY_CONVERT(nvarchar(max), properties.value)
FROM sys.extended_properties AS properties
JOIN sys.schemas AS schemas
  ON properties.class = 3
 AND properties.major_id = schemas.schema_id
 AND properties.minor_id = 0
WHERE schemas.name COLLATE Latin1_General_100_BIN2
          LIKE N'toolbelt[_]%' COLLATE Latin1_General_100_BIN2
UNION ALL
SELECT
      @SnapshotOrdinal
    , N'PERMISSION'
    , CONCAT
      (
          permissions.class, N'#', permissions.major_id, N'#',
          permissions.minor_id, N'#', permissions.grantee_principal_id, N'#',
          permissions.permission_name
      )
    , permissions.state
FROM sys.database_permissions AS permissions
LEFT JOIN sys.objects AS objects
  ON permissions.class = 1
 AND permissions.major_id = objects.object_id
LEFT JOIN sys.schemas AS object_schemas
  ON object_schemas.schema_id = objects.schema_id
LEFT JOIN sys.schemas AS permission_schemas
  ON permissions.class = 3
 AND permissions.major_id = permission_schemas.schema_id
WHERE object_schemas.name COLLATE Latin1_General_100_BIN2
          LIKE N'toolbelt[_]%' COLLATE Latin1_General_100_BIN2
   OR permission_schemas.name COLLATE Latin1_General_100_BIN2
          LIKE N'toolbelt[_]%' COLLATE Latin1_General_100_BIN2;

GO
