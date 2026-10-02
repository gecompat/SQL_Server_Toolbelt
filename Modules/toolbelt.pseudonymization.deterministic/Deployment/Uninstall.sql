:On Error exit
-- Transaktionsneutraler frühester Guard, bevor XACT_ABORT oder Temp-DDL gelten.
IF @@TRANCOUNT <> 0
BEGIN
    RAISERROR(N'DETERMINISTIC_LIFECYCLE_CALLER_TRANSACTION: aktive Callertransaktion wird vor Mutation abgelehnt.',16,1);
    RETURN;
END;
-- SQLCMD: ConfirmNoExternalConsumers=0|1. Fremdes Schema wird nie adoptiert.
SET NOCOUNT ON;
SET XACT_ABORT ON;
:r ReleaseManifest.sql
DECLARE @VersionProperty sysname=N'Toolbelt.Module.toolbelt.pseudonymization.deterministic.Version',
    @ModeProperty sysname=N'Toolbelt.Module.toolbelt.pseudonymization.deterministic.DeploymentMode',
    @Version nvarchar(64),@Mode nvarchar(16),@Installed bit=0,
    @Release int=0,@OwnTransaction bit=0,
    @Confirm nvarchar(8)=N'$(ConfirmNoExternalConsumers)',@Phase int=0,@LockResult int;
BEGIN TRY
IF CONVERT(varbinary(max),@Confirm) NOT IN (CONVERT(varbinary(max),N'0'),CONVERT(varbinary(max),N'1'))
    THROW 54026,N'ConfirmNoExternalConsumers must be exactly 0 or 1.',1;
WHILE @Phase<2
BEGIN
    SELECT @Version=NULL,@Mode=NULL,@Installed=0;
    SELECT @Version=TRY_CONVERT(nvarchar(64),value),@Installed=1 FROM sys.extended_properties WHERE class=0 AND name=@VersionProperty;
    SELECT @Mode=TRY_CONVERT(nvarchar(16),value) FROM sys.extended_properties WHERE class=0 AND name=@ModeProperty;
    IF @Installed=0
    BEGIN
        IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@ModeProperty)
            THROW 54023,N'Deterministic orphaned mode marker requires operator reconciliation.',1;
        IF @Phase=1 COMMIT TRANSACTION;
        DROP TABLE #tbx_Deterministic_Release;
        RETURN;
    END;
    IF @Version IS NULL OR CONVERT(varbinary(max),@Version) NOT IN (CONVERT(varbinary(max),N'1.0.0'),CONVERT(varbinary(max),N'1.1.0'))
        OR @Mode IS NULL OR CONVERT(varbinary(max),@Mode) NOT IN (CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central'))
        THROW 54023,N'Deterministic registered release/mode is unknown or malformed.',1;
    SET @Release=CASE CONVERT(varbinary(max),@Version) WHEN CONVERT(varbinary(max),N'1.0.0') THEN 10 ELSE 11 END;
    IF @Mode=N'central' AND @Confirm<>N'1'
        THROW 54026,N'Central uninstall requires explicit external-consumer confirmation.',2;
    IF SCHEMA_ID(N'toolbelt_pseudonymization') IS NOT NULL AND ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_pseudonymization',N'SCHEMA',N'ALTER'),0)<>1
        THROW 54022,N'Deterministic uninstall DDL permissions are missing.',1;
    IF EXISTS (SELECT 1 FROM #tbx_Deterministic_Release AS release JOIN sys.objects AS actual
        ON actual.object_id=OBJECT_ID(N'toolbelt_pseudonymization.'+QUOTENAME(release.ObjectName))
        WHERE release.FirstRelease<=@Release AND ((release.ObjectType='IF' AND actual.type NOT IN ('IF','TF','FN')) OR (release.ObjectType='P' AND actual.type<>'P')
        OR NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=actual.object_id AND minor_id=0 AND name=N'Toolbelt.ModuleId'
            AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),value))=CONVERT(varbinary(max),N'toolbelt.pseudonymization.deterministic'))
        OR NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=actual.object_id AND minor_id=0 AND name=N'Toolbelt.ModuleVersion'
            AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(64),value))=CONVERT(varbinary(max),@Version))))
        THROW 54024,N'Deterministic uninstall type/ownership differs from known release.',1;
    IF EXISTS (SELECT 1 FROM sys.sql_expression_dependencies AS dependency
        WHERE dependency.referenced_id IN (SELECT OBJECT_ID(N'toolbelt_pseudonymization.'+QUOTENAME(ObjectName)) FROM #tbx_Deterministic_Release WHERE FirstRelease<=@Release)
        AND NOT EXISTS (SELECT 1 FROM #tbx_Deterministic_Release AS own
            WHERE own.FirstRelease<=@Release AND OBJECT_ID(N'toolbelt_pseudonymization.'+QUOTENAME(own.ObjectName))=dependency.referencing_id))
        THROW 54027,N'Deterministic uninstall blocked by same-database dependent; no foreign object removed.',1;
    IF @Phase=0
    BEGIN
        BEGIN TRANSACTION;
        SET @OwnTransaction=1;
        EXEC @LockResult=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.pseudonymization.deterministic',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
        IF @LockResult<0 THROW 54025,N'Deterministic lifecycle application lock unavailable.',1;
    END;
    SET @Phase+=1;
END;
    DECLARE @Ordinal int=(SELECT MAX(ObjectOrdinal) FROM #tbx_Deterministic_Release WHERE FirstRelease<=@Release),@Name sysname,@Type char(2),@Drop nvarchar(max);
    WHILE @Ordinal>0
    BEGIN
        SELECT @Name=ObjectName,@Type=ObjectType FROM #tbx_Deterministic_Release WHERE ObjectOrdinal=@Ordinal;
        IF OBJECT_ID(N'toolbelt_pseudonymization.'+QUOTENAME(@Name)) IS NOT NULL
        BEGIN
            SET @Drop=N'DROP '+CASE WHEN @Type='P' THEN N'PROCEDURE ' ELSE N'FUNCTION ' END+N'[toolbelt_pseudonymization].'+QUOTENAME(@Name)+N';';
            EXEC sys.sp_executesql @Drop;
        END;
        SET @Ordinal-=1;
    END;
    EXEC sys.sp_dropextendedproperty @name=@VersionProperty;
    EXEC sys.sp_dropextendedproperty @name=@ModeProperty;
    DECLARE @SchemaId int=SCHEMA_ID(N'toolbelt_pseudonymization');
    IF @SchemaId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM sys.objects WHERE schema_id=@SchemaId)
        AND NOT EXISTS(SELECT 1 FROM sys.types WHERE schema_id=@SchemaId)
        AND NOT EXISTS(SELECT 1 FROM sys.xml_schema_collections WHERE schema_id=@SchemaId)
        AND EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=3 AND major_id=@SchemaId AND minor_id=0 AND name=N'Toolbelt.Managed' AND TRY_CONVERT(int,value)=1)
        AND EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=3 AND major_id=@SchemaId AND minor_id=0 AND name=N'Toolbelt.SchemaCategory'
            AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(64),value))=CONVERT(varbinary(max),N'pseudonymization'))
        EXEC(N'DROP SCHEMA [toolbelt_pseudonymization];');
    COMMIT TRANSACTION;
    DROP TABLE #tbx_Deterministic_Release;
END TRY
BEGIN CATCH
    IF @OwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
    IF OBJECT_ID(N'tempdb..#tbx_Deterministic_Release',N'U') IS NOT NULL DROP TABLE #tbx_Deterministic_Release;
    THROW;
END CATCH;
GO
