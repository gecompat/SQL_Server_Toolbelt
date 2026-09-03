:On Error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE
      @ConfirmNoExternalConsumers bit =
          TRY_CONVERT(bit, N'$(ConfirmNoExternalConsumers)')
    , @VersionProperty sysname =
          N'Toolbelt.Module.toolbelt.tsql.script-parser.Version'
    , @ModeProperty sysname =
          N'Toolbelt.Module.toolbelt.tsql.script-parser.DeploymentMode'
    , @DeploymentMode nvarchar(16)
    , @NodesId int = OBJECT_ID(N'toolbelt_tsql.TVF_ParseScriptNodes')
    , @PropsId int = OBJECT_ID(N'toolbelt_tsql.TVF_ParseScriptNodeProperties')
    , @TokensId int = OBJECT_ID(N'toolbelt_tsql.TVF_TokenizeScript')
    , @ErrorsId int = OBJECT_ID(N'toolbelt_tsql.TVF_ParseScriptErrors')
    , @AssemblyId int =
          (SELECT assembly_id FROM sys.assemblies WHERE name = N'Toolbelt_Tsql_ScriptParser');

IF @ConfirmNoExternalConsumers IS NULL
    THROW 53106, N'ConfirmNoExternalConsumers muss 0 oder 1 sein.', 1;

IF NOT EXISTS
   (
       SELECT 1 FROM sys.extended_properties
       WHERE class = 0 AND major_id = 0 AND minor_id = 0
         AND name = @VersionProperty
   )
    RETURN;

SELECT @DeploymentMode = TRY_CONVERT(nvarchar(16), value)
FROM sys.extended_properties
WHERE class = 0 AND major_id = 0 AND minor_id = 0
  AND name = @ModeProperty;

IF @DeploymentMode = N'central' AND @ConfirmNoExternalConsumers <> 1
    THROW 53106, N'Bei zentraler Installation ist ConfirmNoExternalConsumers=1 erforderlich.', 2;

IF EXISTS
   (
       SELECT 1 FROM sys.sql_expression_dependencies
       WHERE referenced_id IN (ISNULL(@NodesId, -1), ISNULL(@PropsId, -1), ISNULL(@TokensId, -1), ISNULL(@ErrorsId, -1))
         AND referencing_id NOT IN (ISNULL(@NodesId, -1), ISNULL(@PropsId, -1), ISNULL(@TokensId, -1), ISNULL(@ErrorsId, -1))
   )
    THROW 53108, N'Die Deinstallation wird durch eine same-database Dependency blockiert.', 1;

IF @AssemblyId IS NOT NULL
   AND EXISTS
       (
           SELECT 1 FROM sys.assembly_modules
           WHERE assembly_id = @AssemblyId
             AND object_id NOT IN (ISNULL(@NodesId, -1), ISNULL(@PropsId, -1), ISNULL(@TokensId, -1), ISNULL(@ErrorsId, -1))
       )
    THROW 53108, N'Die ScriptParser-Assembly wird von einem fremden SQL-Objekt verwendet.', 2;

IF @AssemblyId IS NOT NULL
   AND EXISTS
       (SELECT 1 FROM sys.assembly_references WHERE referenced_assembly_id = @AssemblyId)
    THROW 53108, N'Die ScriptParser-Assembly wird von einer anderen Assembly referenziert.', 3;

BEGIN TRY
    BEGIN TRANSACTION;

    DROP FUNCTION IF EXISTS [toolbelt_tsql].[TVF_ParseScriptNodes];
    DROP FUNCTION IF EXISTS [toolbelt_tsql].[TVF_ParseScriptNodeProperties];
    DROP FUNCTION IF EXISTS [toolbelt_tsql].[TVF_TokenizeScript];
    DROP FUNCTION IF EXISTS [toolbelt_tsql].[TVF_ParseScriptErrors];

    IF EXISTS (SELECT 1 FROM sys.assemblies WHERE name = N'Toolbelt_Tsql_ScriptParser')
        DROP ASSEMBLY [Toolbelt_Tsql_ScriptParser];

    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @VersionProperty)
        EXEC sys.sp_dropextendedproperty @name = @VersionProperty;

    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @ModeProperty)
        EXEC sys.sp_dropextendedproperty @name = @ModeProperty;

    IF SCHEMA_ID(N'toolbelt_tsql') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.objects WHERE schema_id = SCHEMA_ID(N'toolbelt_tsql'))
       AND EXISTS
           (
               SELECT 1 FROM sys.extended_properties
               WHERE class = 3 AND major_id = SCHEMA_ID(N'toolbelt_tsql')
                 AND name = N'Toolbelt.Managed' AND TRY_CONVERT(bit, value) = 1
           )
        DROP SCHEMA [toolbelt_tsql];

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/* Der serverweite Hash-Trust bleibt ein separater administrativer Lifecycle. */
