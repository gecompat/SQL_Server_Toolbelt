:On Error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE
      @ConfirmNoExternalConsumers bit =
          TRY_CONVERT(bit, N'$(ConfirmNoExternalConsumers)')
    , @VersionProperty sysname =
          N'Toolbelt.Module.toolbelt.datetime.bucket.Version'
    , @ModeProperty sysname =
          N'Toolbelt.Module.toolbelt.datetime.bucket.DeploymentMode'
    , @DeploymentMode nvarchar(16);

IF @ConfirmNoExternalConsumers IS NULL
    THROW 51245, N'ConfirmNoExternalConsumers muss 0 oder 1 sein.', 1;
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
    THROW 51245, N'Bei zentraler Installation ist ConfirmNoExternalConsumers=1 erforderlich.', 1;

IF EXISTS
   (
       SELECT 1
       FROM sys.sql_expression_dependencies
       WHERE referenced_id IN
             (
                   OBJECT_ID(N'toolbelt_datetime.TVF_DateBucketDate')
                 , OBJECT_ID(N'toolbelt_datetime.TVF_DateBucketDateTime2')
                 , OBJECT_ID(N'toolbelt_datetime.TVF_DateBucketDateTimeOffset')
                 , OBJECT_ID(N'toolbelt_datetime.TVF_DateBucketCore')
             )
         AND referencing_id NOT IN
             (
                   OBJECT_ID(N'toolbelt_datetime.TVF_DateBucketDate')
                 , OBJECT_ID(N'toolbelt_datetime.TVF_DateBucketDateTime2')
                 , OBJECT_ID(N'toolbelt_datetime.TVF_DateBucketDateTimeOffset')
                 , OBJECT_ID(N'toolbelt_datetime.TVF_DateBucketCore')
             )
   )
    THROW 51246, N'Die Deinstallation wird durch eine same-database Dependency blockiert.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
    DROP FUNCTION IF EXISTS [toolbelt_datetime].[TVF_DateBucketDate];
    DROP FUNCTION IF EXISTS [toolbelt_datetime].[TVF_DateBucketDateTime2];
    DROP FUNCTION IF EXISTS [toolbelt_datetime].[TVF_DateBucketDateTimeOffset];
    DROP FUNCTION IF EXISTS [toolbelt_datetime].[TVF_DateBucketCore];
    EXEC sys.sp_dropextendedproperty @name = @VersionProperty;
    EXEC sys.sp_dropextendedproperty @name = @ModeProperty;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
