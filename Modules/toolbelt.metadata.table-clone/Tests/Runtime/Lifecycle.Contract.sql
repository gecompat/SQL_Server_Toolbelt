SET NOCOUNT ON;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0
    AND name=N'Toolbelt.Module.toolbelt.metadata.table-clone.Version' AND CONVERT(nvarchar(64),value)=N'4.0.0')
    THROW 54920,N'Module marker missing.',1;
DECLARE @Release TABLE(Name sysname NOT NULL);
INSERT @Release VALUES(N'USP_ScriptTableClone'),(N'USP_ScriptTableCloneInternal'),(N'USP_ExecuteTableClone');
IF EXISTS(SELECT 1 FROM @Release r LEFT JOIN sys.objects o ON o.object_id=OBJECT_ID(N'toolbelt_metadata.'+r.Name,N'P')
    WHERE o.object_id IS NULL
    OR NOT EXISTS(SELECT 1 FROM sys.extended_properties ep WHERE ep.class=1 AND ep.major_id=o.object_id
        AND ep.name=N'Toolbelt.ModuleId' AND CONVERT(nvarchar(128),ep.value)=N'toolbelt.metadata.table-clone')
    OR NOT EXISTS(SELECT 1 FROM sys.extended_properties ep WHERE ep.class=1 AND ep.major_id=o.object_id
        AND ep.name=N'Toolbelt.ModuleVersion' AND CONVERT(nvarchar(64),ep.value)=N'4.0.0')
    OR NOT EXISTS(SELECT 1 FROM sys.extended_properties ep WHERE ep.class=1 AND ep.major_id=o.object_id
        AND ep.name=N'Toolbelt.SourceHash' AND CONVERT(varchar(64),ep.value)=CONVERT(varchar(64),
            HASHBYTES('SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(o.object_id))),2)))
    THROW 54920,N'Release marker/type/hash contract failed.',2;
DECLARE @Expected TABLE(Ordinal int,Name sysname,TypeName sysname,MaxLength smallint);
INSERT @Expected VALUES(1,N'@SourceSchema',N'nvarchar',-1),(2,N'@SourceTable',N'nvarchar',-1),
    (3,N'@TargetSchema',N'nvarchar',-1),(4,N'@TargetTable',N'nvarchar',-1),(5,N'@IncludeIdentity',N'bit',1),
    (6,N'@IncludeExtendedProperties',N'bit',1),(7,N'@TableMap',N'sysname',256),(8,N'@ExternalReferenceRule',N'varchar',16),(9,N'@IncludeTriggers',N'bit',1),(10,N'@ResultTable',N'sysname',256),(11,N'@KeepData',N'bit',1),(12,N'@Debug',N'tinyint',1),(13,N'@Hilfe',N'bit',1);
IF (SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableClone'))<>13
   OR EXISTS(SELECT Ordinal,Name,TypeName,MaxLength FROM @Expected
      EXCEPT SELECT p.parameter_id,p.name,t.name,p.max_length FROM sys.parameters p JOIN sys.types t ON t.user_type_id=p.user_type_id
      WHERE p.object_id=OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableClone'))
    THROW 54920,N'Public parameter metadata failed.',3;

-- Beide Planner besitzen die gekoppelte 13-Parameterform von Release 4.0.
IF (SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableCloneInternal'))<>13
   OR EXISTS(SELECT Ordinal,Name,TypeName,MaxLength FROM @Expected
      EXCEPT SELECT p.parameter_id,p.name,t.name,p.max_length FROM sys.parameters p JOIN sys.types t ON t.user_type_id=p.user_type_id
      WHERE p.object_id=OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableCloneInternal'))
    THROW 54920,N'Internal parameter metadata failed.',5;

-- Die Executor-Signatur bleibt unverändert bei 14 Parametern.
DELETE @Expected;
INSERT @Expected VALUES(1,N'@SourceSchema',N'nvarchar',-1),(2,N'@SourceTable',N'nvarchar',-1),
    (3,N'@TargetSchema',N'nvarchar',-1),(4,N'@TargetTable',N'nvarchar',-1),(5,N'@IncludeIdentity',N'bit',1),
    (6,N'@IncludeExtendedProperties',N'bit',1),(7,N'@TableMap',N'sysname',256),(8,N'@ExternalReferenceRule',N'varchar',16),
    (9,N'@ExpectedPlanHash',N'varbinary',-1),(10,N'@ForeignKeyMode',N'varchar',16),
    (11,N'@ResultTable',N'sysname',256),(12,N'@KeepData',N'bit',1),(13,N'@Debug',N'tinyint',1),(14,N'@Hilfe',N'bit',1);
IF (SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_metadata.USP_ExecuteTableClone'))<>14
   OR EXISTS(SELECT Ordinal,Name,TypeName,MaxLength FROM @Expected
      EXCEPT SELECT p.parameter_id,p.name,t.name,p.max_length FROM sys.parameters p JOIN sys.types t ON t.user_type_id=p.user_type_id
      WHERE p.object_id=OBJECT_ID(N'toolbelt_metadata.USP_ExecuteTableClone'))
    THROW 54920,N'Executor parameter metadata failed.',4;