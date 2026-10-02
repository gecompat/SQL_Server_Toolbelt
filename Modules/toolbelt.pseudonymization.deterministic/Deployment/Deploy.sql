:On Error exit
-- RAISERROR ignoriert XACT_ABORT: Callerarbeit und SET-Zustand bleiben intakt.
-- Vor jedem SET, Manifest-/Temp-DDL und jeder fachlichen Prüfung abbrechen.
IF @@TRANCOUNT <> 0
BEGIN
    RAISERROR(N'DETERMINISTIC_LIFECYCLE_CALLER_TRANSACTION: aktive Callertransaktion wird vor Mutation abgelehnt.',16,1);
    RETURN;
END;
-- SQLCMD aus diesem Deployment-Verzeichnis; DeploymentMode=local|central.
-- Sourcehashes bleiben diagnostisch; Upgrade nur aus den bekannten Releases.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
:r ReleaseManifest.sql
DECLARE @Mode nvarchar(16)=N'$(DeploymentMode)', @Version nvarchar(64),
    @VersionProperty sysname=N'Toolbelt.Module.toolbelt.pseudonymization.deterministic.Version',
    @ModeProperty sysname=N'Toolbelt.Module.toolbelt.pseudonymization.deterministic.DeploymentMode',
    @Installed bit=0, @Phase int=0, @LockResult int, @Release int=0, @OwnTransaction bit=0;
BEGIN TRY
IF ISNULL(TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion')),0) NOT IN (15,16,17)
    OR ISNULL((SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID()),0)<150
    THROW 54020,N'Deterministic requires SQL Server 2019/2022/2025 and compatibility >=150.',2;
IF CONVERT(varbinary(max),@Mode) NOT IN (CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central'))
    THROW 54021,N'DeploymentMode must be exactly local or central.',1;
IF ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE FUNCTION'),0)<>1
    OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE PROCEDURE'),0)<>1
    OR (SCHEMA_ID(N'toolbelt_pseudonymization') IS NULL AND ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE SCHEMA'),0)<>1)
    OR (SCHEMA_ID(N'toolbelt_pseudonymization') IS NOT NULL AND ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_pseudonymization',N'SCHEMA',N'ALTER'),0)<>1)
    THROW 54022,N'Deterministic lifecycle DDL permissions are missing.',1;
DECLARE @DependencyId int,@DependencyVersion nvarchar(64),@Major int,@Minor int,@Patch int;
-- Read-only-Prüfungen unter transaktionalem Application Lock wiederholen.
WHILE @Phase<2
BEGIN
    SELECT @DependencyId=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P'),@DependencyVersion=NULL;
SELECT @DependencyVersion=TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties
WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.result-table.Version';
SELECT @Major=TRY_CONVERT(int,PARSENAME(@DependencyVersion,3)),@Minor=TRY_CONVERT(int,PARSENAME(@DependencyVersion,2)),@Patch=TRY_CONVERT(int,PARSENAME(@DependencyVersion,1));
IF @DependencyId IS NULL OR @Major IS NULL OR @Major<1 OR @Minor IS NULL OR @Minor<0 OR @Patch IS NULL OR @Patch<0
    OR CONVERT(varbinary(max),@DependencyVersion)<>CONVERT(varbinary(max),CONCAT(@Major,N'.',@Minor,N'.',@Patch))
    OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@DependencyId AND minor_id=0 AND name=N'Toolbelt.ModuleId'
        AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),value))=CONVERT(varbinary(max),N'toolbelt.core.result-table'))
    OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@DependencyId AND minor_id=0 AND name=N'Toolbelt.ModuleVersion'
        AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(64),value))=CONVERT(varbinary(max),@DependencyVersion))
    OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@DependencyId AND minor_id=0 AND name=N'Toolbelt.ContractVersion'
        AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(64),value))=CONVERT(varbinary(max),N'1.0'))
    THROW 54028,N'Deterministic: registrierte same-database ResultTable-Dependency >=1.0.0 / Contract 1.0 fehlt oder ist ungeeignet.',1;
    SELECT @Version=NULL,@Installed=0;
    SELECT @Version=TRY_CONVERT(nvarchar(64),value),@Installed=1 FROM sys.extended_properties
    WHERE class=0 AND major_id=0 AND minor_id=0 AND name=@VersionProperty;
    IF @Installed=1 AND (@Version IS NULL OR CONVERT(varbinary(max),@Version) NOT IN (CONVERT(varbinary(max),N'1.0.0'),CONVERT(varbinary(max),N'1.1.0')))
        THROW 54023,N'Deterministic installed release is unknown or malformed.',1;
    SET @Release=CASE CONVERT(varbinary(max),@Version) WHEN CONVERT(varbinary(max),N'1.0.0') THEN 10 WHEN CONVERT(varbinary(max),N'1.1.0') THEN 11 ELSE 0 END;
    IF @Installed=1 AND NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@ModeProperty
        AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(16),value)) IN (CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central')))
        THROW 54023,N'Deterministic installed mode is missing or malformed.',2;
    IF @Installed=0 AND EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@ModeProperty)
        THROW 54023,N'Deterministic orphaned mode marker requires operator reconciliation.',3;
    IF EXISTS (SELECT 1 FROM #tbx_Deterministic_Release AS release
        JOIN sys.objects AS actual ON actual.object_id=OBJECT_ID(N'toolbelt_pseudonymization.'+QUOTENAME(release.ObjectName))
        WHERE @Installed=0 OR release.FirstRelease>@Release
            OR (release.ObjectType='IF' AND actual.type NOT IN ('IF','TF','FN'))
            OR (release.ObjectType='P' AND actual.type<>'P')
            OR NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=actual.object_id AND minor_id=0 AND name=N'Toolbelt.ModuleId'
                AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),value))=CONVERT(varbinary(max),N'toolbelt.pseudonymization.deterministic'))
            OR NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=actual.object_id AND minor_id=0 AND name=N'Toolbelt.ModuleVersion'
                AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(64),value))=CONVERT(varbinary(max),@Version)))
        THROW 54024,N'Deterministic name collision, type or ownership marker is not this known release.',2;
    IF @Phase=0
    BEGIN
        BEGIN TRANSACTION;
        SET @OwnTransaction=1;
        EXEC @LockResult=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.pseudonymization.deterministic',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
        IF @LockResult<0 THROW 54025,N'Deterministic lifecycle application lock unavailable.',1;
    END;
    SET @Phase+=1;
END;
IF SCHEMA_ID(N'toolbelt_pseudonymization') IS NULL
BEGIN
    EXEC(N'CREATE SCHEMA [toolbelt_pseudonymization];');
    EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Managed',@value=1,@level0type=N'SCHEMA',@level0name=N'toolbelt_pseudonymization';
    EXEC sys.sp_addextendedproperty @name=N'Toolbelt.SchemaCategory',@value=N'pseudonymization',@level0type=N'SCHEMA',@level0name=N'toolbelt_pseudonymization';
END;
-- Nur bekannte eigene Releaseobjekte dürfen Function-kind-Drift reparieren.
DECLARE @DropSql nvarchar(max)=N'';
SELECT @DropSql=@DropSql+N'DROP FUNCTION [toolbelt_pseudonymization].'+QUOTENAME(release.ObjectName)+N';'
FROM #tbx_Deterministic_Release AS release JOIN sys.objects AS actual
    ON actual.object_id=OBJECT_ID(N'toolbelt_pseudonymization.'+QUOTENAME(release.ObjectName))
WHERE release.ObjectType='IF' AND actual.type IN ('TF','FN');
IF @DropSql<>N'' EXEC sys.sp_executesql @DropSql;
END TRY
BEGIN CATCH
    IF @OwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
    DROP TABLE #tbx_Deterministic_Release;
    THROW;
END CATCH;
GO
:r ../Source/TVF_DeterministicIntegerBytes.sql
:r ../Source/TVF_DeterministicRangeCore.sql
:r ../Source/TVF_DeterministicRange.sql
:r ../Source/TVF_DeterministicDateShift.sql
:r ../Source/USP_DeterministicLookupCore.sql
:r ../Source/USP_DeterministicLookup.sql
:r ../Source/DeterministicTranslate.sql
BEGIN TRY
    IF @@TRANCOUNT<>1 THROW 54029,N'Deterministic: eigene Deploymenttransaktion fehlt oder wurde verschachtelt.',1;
    DECLARE @ObjectOrdinal int=1,@ObjectName sysname,@Visibility nvarchar(16),@ObjectLevelType varchar(16),@Property sysname,@Value sql_variant,
        @ModuleId nvarchar(128)=N'toolbelt.pseudonymization.deterministic',@Mode nvarchar(16)=N'$(DeploymentMode)',@ObjectId int;
    WHILE @ObjectOrdinal<=7
    BEGIN
        SELECT @ObjectName=ObjectName,@Visibility=Visibility FROM #tbx_Deterministic_Release WHERE ObjectOrdinal=@ObjectOrdinal;
        SET @ObjectLevelType=CASE WHEN @ObjectName IN(N'USP_DeterministicLookup',N'USP_DeterministicLookupCore') THEN 'PROCEDURE' ELSE 'FUNCTION' END;
        SET @ObjectId=OBJECT_ID(N'toolbelt_pseudonymization.'+QUOTENAME(@ObjectName));
        DECLARE @Properties TABLE(PropertyOrdinal int,PropertyName sysname,PropertyValue sql_variant);
        INSERT @Properties VALUES (1,N'Toolbelt.ModuleId',@ModuleId),(2,N'Toolbelt.ModuleVersion',N'1.1.0'),
            (3,N'Toolbelt.ContractVersion',N'1.0'),(4,N'Toolbelt.DeploymentMode',@Mode),(5,N'Toolbelt.Visibility',@Visibility),
            (6,N'Toolbelt.SourceHash',CONVERT(varchar(64),HASHBYTES('SHA2_256',OBJECT_DEFINITION(@ObjectId)),2));
        DECLARE @PropertyOrdinal int=1;
        WHILE @PropertyOrdinal<=6
        BEGIN
            SELECT @Property=PropertyName,@Value=PropertyValue FROM @Properties WHERE PropertyOrdinal=@PropertyOrdinal;
            IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@ObjectId AND minor_id=0 AND name=@Property)
                EXEC sys.sp_updateextendedproperty @name=@Property,@value=@Value,@level0type=N'SCHEMA',@level0name=N'toolbelt_pseudonymization',@level1type=@ObjectLevelType,@level1name=@ObjectName;
            ELSE EXEC sys.sp_addextendedproperty @name=@Property,@value=@Value,@level0type=N'SCHEMA',@level0name=N'toolbelt_pseudonymization',@level1type=@ObjectLevelType,@level1name=@ObjectName;
            SET @PropertyOrdinal+=1;
        END;
        DELETE @Properties;
        SET @ObjectOrdinal+=1;
    END;
    DECLARE @VersionProperty sysname=N'Toolbelt.Module.toolbelt.pseudonymization.deterministic.Version',@ModeProperty sysname=N'Toolbelt.Module.toolbelt.pseudonymization.deterministic.DeploymentMode';
    IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@VersionProperty)
        EXEC sys.sp_updateextendedproperty @name=@VersionProperty,@value=N'1.1.0';
    ELSE EXEC sys.sp_addextendedproperty @name=@VersionProperty,@value=N'1.1.0';
    IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@ModeProperty)
        EXEC sys.sp_updateextendedproperty @name=@ModeProperty,@value=@Mode;
    ELSE EXEC sys.sp_addextendedproperty @name=@ModeProperty,@value=@Mode;
    COMMIT TRANSACTION;
    DROP TABLE #tbx_Deterministic_Release;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    IF OBJECT_ID(N'tempdb..#tbx_Deterministic_Release',N'U') IS NOT NULL DROP TABLE #tbx_Deterministic_Release;
    THROW;
END CATCH;
GO
