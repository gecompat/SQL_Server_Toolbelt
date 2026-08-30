:On Error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE
      @ConfirmNoExternalConsumers bit =
          TRY_CONVERT(bit, N'$(ConfirmNoExternalConsumers)')
    , @VersionProperty sysname =
          N'Toolbelt.Module.toolbelt.string.regex.Version'
    , @ModeProperty sysname =
          N'Toolbelt.Module.toolbelt.string.regex.DeploymentMode'
    , @DeploymentMode nvarchar(16)
    , @IsMatchId int = OBJECT_ID(N'toolbelt_string.SVF_RegexIsMatch')
    , @InstrId int = OBJECT_ID(N'toolbelt_string.SVF_RegexInstr')
    , @CountId int = OBJECT_ID(N'toolbelt_string.SVF_RegexCount')
    , @AssemblyId int =
          (SELECT assembly_id FROM sys.assemblies WHERE name = N'Toolbelt_String_Regex');

IF @ConfirmNoExternalConsumers IS NULL
    THROW 52036, N'ConfirmNoExternalConsumers muss 0 oder 1 sein.', 1;
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
    THROW 52036, N'Bei zentraler Installation ist ConfirmNoExternalConsumers=1 erforderlich.', 2;

IF EXISTS
   (
       SELECT 1 FROM sys.sql_expression_dependencies
       WHERE referenced_id IN (ISNULL(@IsMatchId, -1), ISNULL(@InstrId, -1), ISNULL(@CountId, -1))
         AND referencing_id NOT IN (ISNULL(@IsMatchId, -1), ISNULL(@InstrId, -1), ISNULL(@CountId, -1))
   )
    THROW 52038, N'Die Deinstallation wird durch eine same-database Dependency blockiert.', 1;

IF @AssemblyId IS NOT NULL
   AND EXISTS
       (
           SELECT 1 FROM sys.assembly_modules
           WHERE assembly_id = @AssemblyId
             AND object_id NOT IN (ISNULL(@IsMatchId, -1), ISNULL(@InstrId, -1), ISNULL(@CountId, -1))
       )
    THROW 52038, N'Die Regex-Assembly wird von einem fremden SQL-Objekt verwendet.', 2;
IF @AssemblyId IS NOT NULL
   AND EXISTS
       (SELECT 1 FROM sys.assembly_references WHERE referenced_assembly_id = @AssemblyId)
    THROW 52038, N'Die Regex-Assembly wird von einer anderen Assembly referenziert.', 3;

BEGIN TRY
    BEGIN TRANSACTION;
    DROP FUNCTION IF EXISTS [toolbelt_string].[SVF_RegexIsMatch];
    DROP FUNCTION IF EXISTS [toolbelt_string].[SVF_RegexInstr];
    DROP FUNCTION IF EXISTS [toolbelt_string].[SVF_RegexCount];
    IF EXISTS (SELECT 1 FROM sys.assemblies WHERE name = N'Toolbelt_String_Regex')
        DROP ASSEMBLY [Toolbelt_String_Regex];

    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @VersionProperty)
        EXEC sys.sp_dropextendedproperty @name = @VersionProperty;
    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @ModeProperty)
        EXEC sys.sp_dropextendedproperty @name = @ModeProperty;

    IF SCHEMA_ID(N'toolbelt_string') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.objects WHERE schema_id = SCHEMA_ID(N'toolbelt_string'))
       AND EXISTS
           (
               SELECT 1 FROM sys.extended_properties
               WHERE class = 3 AND major_id = SCHEMA_ID(N'toolbelt_string')
                 AND name = N'Toolbelt.Managed' AND TRY_CONVERT(bit, value) = 1
           )
        DROP SCHEMA [toolbelt_string];
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/* Der serverweite Hash-Trust bleibt ein separater administrativer Lifecycle. */
