-- Gemeinsamer read-only Snapshot in derselben SQLCMD-Session, ohne persistente Hilfsobjekte.
-- Binäre Textprojektionen bewahren NULL, Leerstring, Unicode und abschließende Leerzeichen.
SET NOCOUNT ON;
DECLARE @Phase int = (SELECT Phase FROM #tbx_EventRepeat_State);
DECLARE @EventTableId int = OBJECT_ID(N'toolbelt_core.EventLog', N'U');
DECLARE @WorkTypeTableId int = OBJECT_ID(N'toolbelt_core.WorkType', N'U');
DECLARE @CoreSchemaId int = SCHEMA_ID(N'toolbelt_core');
DECLARE @Objects TABLE (ObjectId int NOT NULL PRIMARY KEY);
INSERT @Objects (ObjectId)
SELECT o.object_id FROM sys.objects AS o
JOIN (VALUES (N'EventLog', N'U'), (N'VW_Events', N'V'), (N'USP_WriteEvent', N'P'),
             (N'USP_WriteEventInternal', N'P'), (N'USP_DeleteEventsBefore', N'P'), (N'WorkType', N'U')) AS expected(Name, Type)
  ON o.name = expected.Name AND o.type = expected.Type
WHERE o.schema_id = @CoreSchemaId;
IF @EventTableId IS NULL OR @WorkTypeTableId IS NULL OR (SELECT COUNT(*) FROM @Objects) <> 6
    THROW 52752, N'Der Event-Repeat-Objektbestand ist unvollständig.', 1;

INSERT #tbx_EventRepeat_Snapshot (Phase, Category, Payload)
SELECT @Phase, 'events', CONVERT(varbinary(max), CONVERT(nvarchar(max),
    (SELECT EventId, OccurredAtUtc, RecordedAtUtc,
            CONVERT(varbinary(max), EventName) AS EventNameBytes,
            CONVERT(varbinary(max), EventLevel) AS EventLevelBytes,
            CONVERT(varbinary(max), Category) AS CategoryBytes,
            CONVERT(varbinary(max), Message) AS MessageBytes,
            CONVERT(varbinary(max), DataJson) AS DataJsonBytes,
            CONVERT(binary(16), ExecutionId) AS ExecutionIdBytes,
            CONVERT(binary(16), CorrelationId) AS CorrelationIdBytes,
            CONVERT(varbinary(max), Actor) AS ActorBytes,
            CONVERT(varbinary(max), Tenant) AS TenantBytes,
            CONVERT(varbinary(max), SourceDatabaseName) AS SourceDatabaseNameBytes,
            CONVERT(varbinary(max), SourceSchemaName) AS SourceSchemaNameBytes,
            CONVERT(varbinary(max), SourceObjectName) AS SourceObjectNameBytes,
            CallerSessionId, CallerXactState, CallerTransactionCount, RemoteSessionId,
            ErrorNumber, ErrorSeverity, ErrorState,
            CONVERT(varbinary(max), ErrorProcedure) AS ErrorProcedureBytes, ErrorLine
     FROM toolbelt_core.EventLog ORDER BY EventId
     FOR XML PATH('event'), ELEMENTS XSINIL, TYPE)));

INSERT #tbx_EventRepeat_WorkType
    (Phase, WorkTypeId, WorkTypeName, HandlerSchema, HandlerProcedure, ParameterMode,
     PayloadContractJson, DefaultTimeoutSeconds, IsIdempotent, IsEnabled, Description,
     CreatedAtUtc, CreatedBy, ModifiedAtUtc, ModifiedBy, DisabledAtUtc, DisabledBy, DisabledReason, RowVersion)
SELECT @Phase, WorkTypeId, WorkTypeName, HandlerSchema, HandlerProcedure, ParameterMode,
       PayloadContractJson, DefaultTimeoutSeconds, IsIdempotent, IsEnabled, Description,
       CreatedAtUtc, CreatedBy, ModifiedAtUtc, ModifiedBy, DisabledAtUtc, DisabledBy, DisabledReason,
       CONVERT(binary(8), RowVersion)
FROM toolbelt_core.WorkType WHERE WorkTypeName = 'toolbelt.event-log.write';
IF (SELECT COUNT(*) FROM #tbx_EventRepeat_WorkType WHERE Phase = @Phase) <> 1
    THROW 52752, N'Die Event-Repeat-Registrierung ist nicht eindeutig.', 2;

INSERT #tbx_EventRepeat_Snapshot (Phase, Category, Payload)
SELECT @Phase, 'work-type-stable', CONVERT(varbinary(max), CONVERT(nvarchar(max),
    (SELECT WorkTypeId, CONVERT(varbinary(max), WorkTypeName) AS WorkTypeNameBytes,
            CreatedAtUtc, CONVERT(varbinary(max), CreatedBy) AS CreatedByBytes
     FROM #tbx_EventRepeat_WorkType WHERE Phase = @Phase
     FOR XML PATH('registration'), ELEMENTS XSINIL, TYPE)));

INSERT #tbx_EventRepeat_Snapshot (Phase, Category, Payload)
SELECT @Phase, 'work-type-current', CONVERT(varbinary(max), CONVERT(nvarchar(max),
    (SELECT WorkTypeId, CONVERT(varbinary(max), WorkTypeName) AS WorkTypeNameBytes,
            CONVERT(varbinary(max), HandlerSchema) AS HandlerSchemaBytes,
            CONVERT(varbinary(max), HandlerProcedure) AS HandlerProcedureBytes,
            CONVERT(varbinary(max), ParameterMode) AS ParameterModeBytes,
            CONVERT(varbinary(max), PayloadContractJson) AS PayloadContractJsonBytes,
            DefaultTimeoutSeconds, IsIdempotent, IsEnabled,
            CONVERT(varbinary(max), Description) AS DescriptionBytes,
            CreatedAtUtc, CONVERT(varbinary(max), CreatedBy) AS CreatedByBytes,
            ModifiedAtUtc, CONVERT(varbinary(max), ModifiedBy) AS ModifiedByBytes,
            DisabledAtUtc, CONVERT(varbinary(max), DisabledBy) AS DisabledByBytes,
            CONVERT(varbinary(max), DisabledReason) AS DisabledReasonBytes, RowVersion
     FROM #tbx_EventRepeat_WorkType WHERE Phase = @Phase
     FOR XML PATH('registration'), ELEMENTS XSINIL, TYPE)));

-- Alle übrigen Registrierungen einschließlich deaktiviertem eigenem Sentinel, nicht nur COUNT.
INSERT #tbx_EventRepeat_Snapshot (Phase, Category, Payload)
SELECT @Phase, 'other-work-types', CONVERT(varbinary(max), CONVERT(nvarchar(max),
    (SELECT WorkTypeId, CONVERT(varbinary(max), WorkTypeName) AS WorkTypeNameBytes,
            CONVERT(varbinary(max), HandlerSchema) AS HandlerSchemaBytes,
            CONVERT(varbinary(max), HandlerProcedure) AS HandlerProcedureBytes,
            CONVERT(varbinary(max), ParameterMode) AS ParameterModeBytes,
            CONVERT(varbinary(max), PayloadContractJson) AS PayloadContractJsonBytes,
            DefaultTimeoutSeconds, IsIdempotent, IsEnabled,
            CONVERT(varbinary(max), Description) AS DescriptionBytes,
            CreatedAtUtc, CONVERT(varbinary(max), CreatedBy) AS CreatedByBytes,
            ModifiedAtUtc, CONVERT(varbinary(max), ModifiedBy) AS ModifiedByBytes,
            DisabledAtUtc, CONVERT(varbinary(max), DisabledBy) AS DisabledByBytes,
            CONVERT(varbinary(max), DisabledReason) AS DisabledReasonBytes,
            CONVERT(binary(8), RowVersion) AS RowVersion
     FROM toolbelt_core.WorkType WHERE WorkTypeName <> 'toolbelt.event-log.write' ORDER BY WorkTypeId
     FOR XML PATH('registration'), ELEMENTS XSINIL, TYPE)));

-- Ausgewählte stabile Katalogwerte beider Tabellen und der fünf Event-Objekte.
-- modify_date und Laufzeit-/Statistikzähler gehören nicht zum Erhaltungsorakel.
INSERT #tbx_EventRepeat_Snapshot (Phase, Category, Payload)
SELECT @Phase, 'catalog', CONVERT(varbinary(max), CONVERT(nvarchar(max),
    (SELECT
        (SELECT object_id, schema_id, name, type, principal_id, parent_object_id
         FROM sys.objects WHERE object_id IN (SELECT ObjectId FROM @Objects)
            OR parent_object_id IN (@EventTableId, @WorkTypeTableId)
         ORDER BY object_id FOR XML PATH('object'), ELEMENTS XSINIL, TYPE),
        (SELECT schema_id, name, principal_id FROM sys.schemas WHERE schema_id = @CoreSchemaId
         FOR XML PATH('schema'), ELEMENTS XSINIL, TYPE),
        (SELECT object_id, lob_data_space_id, filestream_data_space_id, lock_on_bulk_load,
                uses_ansi_nulls, lock_escalation, is_memory_optimized, durability, temporal_type
         FROM sys.tables WHERE object_id IN (@EventTableId, @WorkTypeTableId)
         ORDER BY object_id FOR XML PATH('table'), ELEMENTS XSINIL, TYPE),
        (SELECT object_id, column_id, name, system_type_id, user_type_id, max_length,
                precision, scale, collation_name, is_nullable, is_ansi_padded, is_rowguidcol,
                is_identity, is_computed, default_object_id, rule_object_id, is_filestream,
                is_sparse, is_column_set, generated_always_type, is_hidden
         FROM sys.columns WHERE object_id IN (SELECT ObjectId FROM @Objects)
         ORDER BY object_id, column_id FOR XML PATH('column'), ELEMENTS XSINIL, TYPE),
        (SELECT object_id, column_id, CONVERT(decimal(38,0), seed_value) AS seed_value,
                CONVERT(decimal(38,0), increment_value) AS increment_value,
                CONVERT(decimal(38,0), last_value) AS last_value, is_not_for_replication
         FROM sys.identity_columns WHERE object_id IN (@EventTableId, @WorkTypeTableId)
         ORDER BY object_id FOR XML PATH('identity'), ELEMENTS XSINIL, TYPE),
        (SELECT IDENT_CURRENT(N'toolbelt_core.EventLog') AS EventIdentity,
                IDENT_CURRENT(N'toolbelt_core.WorkType') AS WorkTypeIdentity FOR XML PATH('current_identity'), TYPE),
        (SELECT object_id, index_id, name, type, is_unique, data_space_id, ignore_dup_key,
                is_primary_key, is_unique_constraint, fill_factor, is_padded, is_disabled,
                is_hypothetical, allow_row_locks, allow_page_locks, has_filter, filter_definition
         FROM sys.indexes WHERE object_id IN (@EventTableId, @WorkTypeTableId)
         ORDER BY object_id, index_id FOR XML PATH('index'), ELEMENTS XSINIL, TYPE),
        (SELECT object_id, index_id, index_column_id, column_id, key_ordinal,
                partition_ordinal, is_descending_key, is_included_column
         FROM sys.index_columns WHERE object_id IN (@EventTableId, @WorkTypeTableId)
         ORDER BY object_id, index_id, index_column_id FOR XML PATH('index_column'), ELEMENTS XSINIL, TYPE),
        (SELECT object_id, parent_object_id, name, type, unique_index_id, is_system_named
         FROM sys.key_constraints WHERE parent_object_id IN (@EventTableId, @WorkTypeTableId)
         ORDER BY object_id FOR XML PATH('key'), ELEMENTS XSINIL, TYPE),
        (SELECT object_id, parent_object_id, name, parent_column_id,
                CONVERT(varbinary(max), definition) AS definition_bytes, is_system_named
         FROM sys.default_constraints WHERE parent_object_id IN (@EventTableId, @WorkTypeTableId)
         ORDER BY object_id FOR XML PATH('default'), ELEMENTS XSINIL, TYPE),
        (SELECT object_id, parent_object_id, name, parent_column_id,
                CONVERT(varbinary(max), definition) AS definition_bytes, is_disabled,
                is_not_trusted, is_not_for_replication, is_system_named
         FROM sys.check_constraints WHERE parent_object_id IN (@EventTableId, @WorkTypeTableId)
         ORDER BY object_id FOR XML PATH('check'), ELEMENTS XSINIL, TYPE),
        (SELECT object_id, parent_object_id, name, referenced_object_id, key_index_id,
                is_disabled, is_not_trusted, delete_referential_action, update_referential_action,
                is_not_for_replication, is_system_named FROM sys.foreign_keys
         WHERE parent_object_id IN (@EventTableId, @WorkTypeTableId)
            OR referenced_object_id IN (@EventTableId, @WorkTypeTableId)
         ORDER BY object_id FOR XML PATH('foreign_key'), ELEMENTS XSINIL, TYPE),
        (SELECT constraint_object_id, constraint_column_id, parent_object_id,
                parent_column_id, referenced_object_id, referenced_column_id FROM sys.foreign_key_columns
         WHERE parent_object_id IN (@EventTableId, @WorkTypeTableId)
            OR referenced_object_id IN (@EventTableId, @WorkTypeTableId)
         ORDER BY constraint_object_id, constraint_column_id FOR XML PATH('foreign_key_column'), ELEMENTS XSINIL, TYPE),
        (SELECT object_id, parent_id, name, is_disabled, is_instead_of_trigger FROM sys.triggers
         WHERE parent_id IN (@EventTableId, @WorkTypeTableId)
         ORDER BY object_id FOR XML PATH('trigger'), ELEMENTS XSINIL, TYPE),
        (SELECT object_id, CONVERT(varbinary(max), definition) AS definition_bytes, uses_ansi_nulls,
                uses_quoted_identifier, is_schema_bound, uses_database_collation,
                is_recompiled, null_on_null_input, execute_as_principal_id
         FROM sys.sql_modules WHERE object_id IN (SELECT ObjectId FROM @Objects)
         ORDER BY object_id FOR XML PATH('module'), ELEMENTS XSINIL, TYPE),
        (SELECT object_id, parameter_id, name, system_type_id, user_type_id,
                max_length, precision, scale, is_output, is_cursor_ref, has_default_value,
                is_xml_document, xml_collection_id, is_readonly
         FROM sys.parameters WHERE object_id IN (SELECT ObjectId FROM @Objects)
         ORDER BY object_id, parameter_id FOR XML PATH('parameter'), ELEMENTS XSINIL, TYPE),
        (SELECT class, major_id, minor_id, grantee_principal_id, grantor_principal_id,
                type, permission_name, state FROM sys.database_permissions
         WHERE class = 0 OR (class = 3 AND major_id = @CoreSchemaId)
            OR (class = 1 AND major_id IN (SELECT ObjectId FROM @Objects))
         ORDER BY class, major_id, minor_id, grantee_principal_id, grantor_principal_id, type
         FOR XML PATH('permission'), ELEMENTS XSINIL, TYPE),
        (SELECT ep.class, ep.major_id, ep.minor_id, ep.name,
                CONVERT(nvarchar(128), SQL_VARIANT_PROPERTY(ep.value, 'BaseType')) AS value_type,
                CONVERT(int, SQL_VARIANT_PROPERTY(ep.value, 'MaxLength')) AS value_length,
                CONVERT(int, SQL_VARIANT_PROPERTY(ep.value, 'Precision')) AS value_precision,
                CONVERT(int, SQL_VARIANT_PROPERTY(ep.value, 'Scale')) AS value_scale,
                CONVERT(nvarchar(128), SQL_VARIANT_PROPERTY(ep.value, 'Collation')) AS value_collation,
                CONVERT(varbinary(8000), CONVERT(nvarchar(4000), ep.value)) AS value_bytes
         FROM sys.extended_properties AS ep
         WHERE (ep.class = 1 AND ep.major_id IN (SELECT ObjectId FROM @Objects))
            OR (ep.class = 3 AND ep.major_id = @CoreSchemaId)
            OR (ep.class = 0 AND ep.name IN
                (N'Toolbelt.Module.toolbelt.core.event-log.Version', N'Toolbelt.Module.toolbelt.core.event-log.DeploymentMode'))
         ORDER BY ep.class, ep.major_id, ep.minor_id, ep.name
         FOR XML PATH('property'), ELEMENTS XSINIL, TYPE)
     FOR XML PATH('catalog'), TYPE)));
GO
