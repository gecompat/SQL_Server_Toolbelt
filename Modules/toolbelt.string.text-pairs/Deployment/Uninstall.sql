:On Error exit
-- SQLCMD: ConfirmNoExternalConsumers=0|1. Nur eigenes bekanntes Release.
IF @@TRANCOUNT>0
BEGIN
    RAISERROR(N'TBX_TEXT_PAIRS_CALLER_TRANSACTION: Lifecycle erfordert keine aktive Caller-Transaktion.',16,1);
    RETURN;
END;
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @Confirmation nvarchar(max)=N'$(ConfirmNoExternalConsumers)',@Pass int=1,
        @ObjectId int,@Version nvarchar(max),@Mode nvarchar(max),@LockResult int;
IF CONVERT(varbinary(max),@Confirmation) NOT IN(CONVERT(varbinary(max),N'0'),CONVERT(varbinary(max),N'1'))
    THROW 55121,N'ConfirmNoExternalConsumers muss bytegenau 0 oder 1 sein.',4;
BEGIN TRY
    WHILE @Pass<=2
    BEGIN
        IF COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1
           OR COALESCE(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1
            THROW 55122,N'Vollständige Lifecycle-Metadatensicht fehlt.',1;
        SET @ObjectId=OBJECT_ID(N'toolbelt_string.USP_CompareTextPairs');
        SET @Version=NULL; SET @Mode=NULL;
        SELECT @Version=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=N'Toolbelt.Module.toolbelt.string.text-pairs.Version';
        SELECT @Mode=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=N'Toolbelt.Module.toolbelt.string.text-pairs.DeploymentMode';
        IF @ObjectId IS NULL AND @Version IS NULL AND @Mode IS NULL
           AND NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name IN(N'Toolbelt.Module.toolbelt.string.text-pairs.Version',N'Toolbelt.Module.toolbelt.string.text-pairs.DeploymentMode'))
        BEGIN
            IF @Pass=2 COMMIT TRANSACTION;
            PRINT N'toolbelt.string.text-pairs ist nicht installiert; keine Änderung erforderlich.';
            RETURN;
        END;
        IF @ObjectId IS NULL OR NOT EXISTS(SELECT 1 FROM sys.objects WHERE object_id=@ObjectId AND type=N'P') OR @Version IS NULL OR @Mode IS NULL
           OR CONVERT(varbinary(max),@Version)<>CONVERT(varbinary(max),N'1.0.0')
           OR CONVERT(varbinary(max),@Mode) NOT IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central'))
           OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=@ObjectId AND e.minor_id=0 AND e.name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),N'toolbelt.string.text-pairs'))
           OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=@ObjectId AND e.minor_id=0 AND e.name=N'Toolbelt.ModuleVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),N'1.0.0'))
           OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=@ObjectId AND e.minor_id=0 AND e.name=N'Toolbelt.DeploymentMode' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),@Mode))
            THROW 55125,N'Eigener Release-/Objektzustand ist unbekannt oder kollidiert.',1;
        IF CONVERT(varbinary(max),@Mode)=CONVERT(varbinary(max),N'central') AND @Confirmation<>N'1'
            THROW 55128,N'Central benötigt die ausdrückliche Bestätigung fehlender externer Consumers.',1;
        IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d WHERE d.referencing_id<>@ObjectId AND
           (d.referenced_id=@ObjectId OR (d.referenced_server_name IS NULL AND
            (d.referenced_database_name IS NULL OR CONVERT(varbinary(max),d.referenced_database_name)=CONVERT(varbinary(max),DB_NAME()))
            AND CONVERT(varbinary(max),d.referenced_schema_name)=CONVERT(varbinary(max),N'toolbelt_string')
            AND CONVERT(varbinary(max),d.referenced_entity_name)=CONVERT(varbinary(max),N'USP_CompareTextPairs'))))
            THROW 55128,N'Sichtbare same-database Consumer blockieren die Deinstallation.',2;
        IF EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.minor_id=0 AND e.name=N'Toolbelt.ModuleId'
           AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),N'toolbelt.string.text-pairs') AND e.major_id<>@ObjectId)
            THROW 55125,N'Zusätzliche unbekannte Modulobjekte bleiben erhalten.',2;
        IF @Pass=1
        BEGIN
            BEGIN TRANSACTION;
            EXEC @LockResult=sys.sp_getapplock @Resource=N'Toolbelt.Module.toolbelt.string.text-pairs',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=15000;
            IF @LockResult<0 THROW 55126,N'Lifecycle-AppLock konnte nicht erworben werden.',1;
        END;
        SET @Pass+=1;
    END;
    DROP PROCEDURE toolbelt_string.USP_CompareTextPairs;
    EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.string.text-pairs.Version';
    EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.string.text-pairs.DeploymentMode';
    -- Das Dependency-Schema gehörte diesem Wrapper nie; kein Schema-DROP.
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
