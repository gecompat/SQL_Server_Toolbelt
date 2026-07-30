:On Error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE
      @ConfirmNoExternalConsumers bit =
          TRY_CONVERT(bit, N'$(ConfirmNoExternalConsumers)')
    , @VersionProperty sysname =
          N'Toolbelt.Module.toolbelt.binary.bit-operations.Version'
    , @ModeProperty sysname =
          N'Toolbelt.Module.toolbelt.binary.bit-operations.DeploymentMode'
    , @DeploymentMode nvarchar(16);

IF @ConfirmNoExternalConsumers IS NULL
    THROW 51255, N'ConfirmNoExternalConsumers muss 0 oder 1 sein.', 1;
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
    THROW 51255, N'Bei zentraler Installation ist ConfirmNoExternalConsumers=1 erforderlich.', 1;

IF EXISTS
   (
       SELECT 1
       FROM sys.sql_expression_dependencies
       WHERE referenced_id IN
             (
                   OBJECT_ID(N'toolbelt_binary.TVF_LeftShiftBigInt')
                 , OBJECT_ID(N'toolbelt_binary.TVF_RightShiftBigInt')
                 , OBJECT_ID(N'toolbelt_binary.TVF_BitCountBigInt')
                 , OBJECT_ID(N'toolbelt_binary.TVF_GetBitBigInt')
                 , OBJECT_ID(N'toolbelt_binary.TVF_SetBitBigInt')
             )
         AND referencing_id NOT IN
             (
                   OBJECT_ID(N'toolbelt_binary.TVF_LeftShiftBigInt')
                 , OBJECT_ID(N'toolbelt_binary.TVF_RightShiftBigInt')
                 , OBJECT_ID(N'toolbelt_binary.TVF_BitCountBigInt')
                 , OBJECT_ID(N'toolbelt_binary.TVF_GetBitBigInt')
                 , OBJECT_ID(N'toolbelt_binary.TVF_SetBitBigInt')
             )
   )
    THROW 51256, N'Die Deinstallation wird durch eine same-database Dependency blockiert.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
    DROP FUNCTION IF EXISTS [toolbelt_binary].[TVF_RightShiftBigInt];
    DROP FUNCTION IF EXISTS [toolbelt_binary].[TVF_LeftShiftBigInt];
    DROP FUNCTION IF EXISTS [toolbelt_binary].[TVF_BitCountBigInt];
    DROP FUNCTION IF EXISTS [toolbelt_binary].[TVF_GetBitBigInt];
    DROP FUNCTION IF EXISTS [toolbelt_binary].[TVF_SetBitBigInt];
    EXEC sys.sp_dropextendedproperty @name = @VersionProperty;
    EXEC sys.sp_dropextendedproperty @name = @ModeProperty;

    IF NOT EXISTS
       (
           SELECT 1
           FROM sys.objects
           WHERE schema_id = SCHEMA_ID(N'toolbelt_binary')
       )
       AND EXISTS
       (
           SELECT 1
           FROM sys.extended_properties
           WHERE class = 3
             AND major_id = SCHEMA_ID(N'toolbelt_binary')
             AND name = N'Toolbelt.Managed'
             AND TRY_CONVERT(bit, value) = 1
       )
        DROP SCHEMA [toolbelt_binary];

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
