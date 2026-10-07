-- Gemeinsamer read-only Snapshot vor/nach dem echten Deploy. Kein SQL-Objekt.
-- Textbytes verhindern Collation-/Paddinggleichheit bei den Nutzdaten.
SET NOCOUNT ON;
DECLARE @TableId int = OBJECT_ID(N'toolbelt_core.SecondSessionProvider', N'U');
DECLARE @Phase int = (SELECT Phase FROM #tbx_SecondSessionRepeat_State);
DECLARE @Objects TABLE (ObjectId int NOT NULL PRIMARY KEY);
INSERT @Objects (ObjectId)
SELECT object_id FROM sys.objects
WHERE schema_id = SCHEMA_ID(N'toolbelt_core')
  AND name IN (N'SecondSessionProvider', N'VW_SecondSessionProviders',
               N'USP_ConfigureSecondSessionLoopback', N'USP_ExecuteWorkTypeInNewSession',
               N'USP_SecondSessionProbe', N'USP_DispatchWorkType');
IF (SELECT COUNT(*) FROM @Objects) <> 6
    THROW 52670, N'Die sechs Second-Session-Modulobjekte fehlen beim Repeat-Snapshot.', 1;
IF @TableId IS NULL
    THROW 52670, N'Second-Session-Tabelle fehlt beim Repeat-Snapshot.', 1;

INSERT #tbx_SecondSessionRepeat_Snapshot (Phase, Category, Payload)
SELECT @Phase, 'rows', CONVERT(varbinary(max), CONVERT(nvarchar(max),
    (SELECT CONVERT(varbinary(max), ProviderName) AS ProviderNameBytes,
            CONVERT(varbinary(max), LinkedServerName) AS LinkedServerNameBytes,
            IsEnabled, CreatedAtUtc,
            CONVERT(varbinary(max), CreatedBy) AS CreatedByBytes,
            ModifiedAtUtc, CONVERT(varbinary(max), ModifiedBy) AS ModifiedByBytes,
            CONVERT(binary(8), RowVersion) AS RowVersionBytes
     FROM toolbelt_core.SecondSessionProvider ORDER BY ProviderName
     FOR XML PATH('row'), ELEMENTS XSINIL, TYPE)));

INSERT #tbx_SecondSessionRepeat_Snapshot (Phase, Category, Payload)
SELECT @Phase, 'catalog', CONVERT(varbinary(max), CONVERT(nvarchar(max),
    (SELECT
        (SELECT object_id, schema_id, name, type, principal_id
         FROM sys.objects WHERE object_id IN (SELECT ObjectId FROM @Objects) OR parent_object_id = @TableId
         ORDER BY object_id FOR XML PATH('object'), ELEMENTS XSINIL, TYPE),
        (SELECT schema_id, name, principal_id FROM sys.schemas
         WHERE schema_id = SCHEMA_ID(N'toolbelt_core')
         FOR XML PATH('schema'), ELEMENTS XSINIL, TYPE),
        (SELECT object_id, lob_data_space_id, filestream_data_space_id,
                lock_on_bulk_load, uses_ansi_nulls, lock_escalation,
                is_memory_optimized, durability, temporal_type
         FROM sys.tables WHERE object_id = @TableId
         FOR XML PATH('table'), ELEMENTS XSINIL, TYPE),
        (SELECT column_id, name, system_type_id, user_type_id, max_length,
                precision, scale, collation_name, is_nullable, is_ansi_padded,
                is_rowguidcol, is_identity, is_computed, default_object_id,
                rule_object_id, is_filestream, is_sparse, is_column_set,
                generated_always_type, is_hidden
         FROM sys.columns WHERE object_id = @TableId ORDER BY column_id
         FOR XML PATH('column'), ELEMENTS XSINIL, TYPE),
        (SELECT index_id, name, type, is_unique, data_space_id,
                ignore_dup_key, is_primary_key, is_unique_constraint,
                fill_factor, is_padded, is_disabled, is_hypothetical,
                allow_row_locks, allow_page_locks, has_filter, filter_definition
         FROM sys.indexes WHERE object_id = @TableId ORDER BY index_id
         FOR XML PATH('index'), ELEMENTS XSINIL, TYPE),
        (SELECT index_id, index_column_id, column_id, key_ordinal,
                partition_ordinal, is_descending_key, is_included_column
         FROM sys.index_columns WHERE object_id = @TableId
         ORDER BY index_id, index_column_id
         FOR XML PATH('index_column'), ELEMENTS XSINIL, TYPE),
        (SELECT object_id, name, type, unique_index_id, is_system_named
         FROM sys.key_constraints WHERE parent_object_id = @TableId ORDER BY object_id
         FOR XML PATH('key'), ELEMENTS XSINIL, TYPE),
        (SELECT object_id, name, parent_column_id, definition, is_system_named
         FROM sys.default_constraints WHERE parent_object_id = @TableId ORDER BY object_id
         FOR XML PATH('default'), ELEMENTS XSINIL, TYPE),
        (SELECT object_id, name, parent_column_id, definition, is_disabled,
                is_not_trusted, is_not_for_replication, is_system_named
         FROM sys.check_constraints WHERE parent_object_id = @TableId ORDER BY object_id
         FOR XML PATH('check'), ELEMENTS XSINIL, TYPE),
        (SELECT object_id, name, referenced_object_id, key_index_id,
                is_disabled, is_not_trusted, delete_referential_action,
                update_referential_action, is_not_for_replication, is_system_named
         FROM sys.foreign_keys WHERE parent_object_id = @TableId OR referenced_object_id = @TableId
         ORDER BY object_id FOR XML PATH('foreign_key'), ELEMENTS XSINIL, TYPE),
        (SELECT constraint_object_id, constraint_column_id, parent_object_id,
                parent_column_id, referenced_object_id, referenced_column_id
         FROM sys.foreign_key_columns WHERE parent_object_id = @TableId OR referenced_object_id = @TableId
         ORDER BY constraint_object_id, constraint_column_id
         FOR XML PATH('foreign_key_column'), ELEMENTS XSINIL, TYPE),
        (SELECT object_id, name, is_disabled, is_instead_of_trigger
         FROM sys.triggers WHERE parent_id = @TableId ORDER BY object_id
         FOR XML PATH('trigger'), ELEMENTS XSINIL, TYPE),
        (SELECT p.class, p.major_id, p.minor_id, p.grantee_principal_id,
                p.grantor_principal_id, p.type, p.permission_name, p.state
         FROM sys.database_permissions AS p
         WHERE p.class = 0
            OR (p.class = 3 AND p.major_id = SCHEMA_ID(N'toolbelt_core'))
            OR (p.class = 1 AND p.major_id IN
                (SELECT ObjectId FROM @Objects))
         ORDER BY p.class, p.major_id, p.minor_id, p.grantee_principal_id, p.grantor_principal_id, p.type
         FOR XML PATH('permission'), ELEMENTS XSINIL, TYPE),
        (SELECT ep.class, ep.major_id, ep.minor_id, ep.name,
                SQL_VARIANT_PROPERTY(ep.value, 'BaseType') AS value_type,
                SQL_VARIANT_PROPERTY(ep.value, 'MaxLength') AS value_length,
                CONVERT(varbinary(8000), CONVERT(nvarchar(4000), ep.value)) AS value_bytes
         FROM sys.extended_properties AS ep
         WHERE ((ep.class = 1 AND ep.major_id IN
                     (SELECT ObjectId FROM @Objects))
             OR (ep.class = 3 AND ep.major_id = SCHEMA_ID(N'toolbelt_core'))
             OR (ep.class = 0 AND ep.name IN
                 (N'Toolbelt.Module.toolbelt.core.second-session.Version',
                  N'Toolbelt.Module.toolbelt.core.second-session.DeploymentMode')))
         ORDER BY ep.class, ep.major_id, ep.minor_id, ep.name
         FOR XML PATH('property'), ELEMENTS XSINIL, TYPE)
     FOR XML PATH('catalog'), TYPE)));
GO
