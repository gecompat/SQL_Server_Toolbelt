SET NOCOUNT ON;

IF OBJECT_ID(N'toolbelt_core.WorkType', N'U') IS NULL
 OR OBJECT_ID(N'toolbelt_core.VW_WorkTypes', N'V') IS NULL
 OR OBJECT_ID(N'toolbelt_core.USP_RegisterWorkType', N'P') IS NULL
 OR OBJECT_ID(N'toolbelt_core.USP_DisableWorkType', N'P') IS NULL
 OR OBJECT_ID(N'toolbelt_core.USP_ResolveWorkType', N'P') IS NULL
    THROW 52530, N'Work-Type-Objektbestand ist unvollständig.', 1;

IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID(N'toolbelt_core.WorkType') AND name=N'PK_WorkType')
 OR NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID(N'toolbelt_core.WorkType') AND name=N'UQ_WorkType_WorkTypeName')
 OR NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'toolbelt_core.WorkType') AND name=N'IX_WorkType_IsEnabled_WorkTypeName')
    THROW 52531, N'Benannte Tabellenartefakte fehlen.', 1;

IF NOT EXISTS
(
    SELECT 1 FROM sys.extended_properties
    WHERE class=0
      AND name=N'Toolbelt.Module.toolbelt.core.work-type.Version'
      AND CONVERT(nvarchar(32), value)=N'1.0.0'
)
    THROW 52532, N'Modulmarker fehlt.', 1;

PRINT N'Work Type Lifecycle: erfolgreich';
