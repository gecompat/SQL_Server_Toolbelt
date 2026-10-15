-- ============================================================================
-- Objekt: toolbelt_core.USP_SetWorkTypePermission; Typ: Stored Procedure
-- Zweck: Explizite Delegation pro Work Type, Datenbankprincipal und Aktion.
-- Vertrag: Documentation/USP_SetWorkTypePermission.md; kein Datenresultset.
-- Rechte: EXECUTE und CONTROL auf WorkTypePermission; keine Rechtevergabe.
-- Plattform: SQL Server 2019/2022/2025 Windows/Linux; lokaler Katalog.
-- Fehler: 51590-51594; Help ohne Seiteneffekt; Caller-Savepoint bei Mutation.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_SetWorkTypePermission
    @WorkTypeName varchar(128)=NULL,
    @Principal sysname=NULL,
    @PermissionName varchar(32)=NULL,
    @PermissionState varchar(8)='ALLOW',
    @Debug tinyint=0,
    @Hilfe bit=0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;
    IF ISNULL(@Hilfe,0)=1
    BEGIN
        SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) SchemaName,
            CAST(N'USP_SetWorkTypePermission' AS sysname) ObjectName,
            v.Section,v.Ordinal,v.ItemName,v.SqlDataType,v.IsRequired,v.IsNullable,
            v.DefaultValue,v.Description,v.ExampleSql
        FROM (VALUES
            (CAST('DESCRIPTION' AS varchar(32)),1,CAST(NULL AS sysname),CAST(NULL AS varchar(256)),CAST(NULL AS bit),CAST(NULL AS bit),CAST(NULL AS nvarchar(4000)),CAST(N'Bindet ALLOW/DENY an den aktuellen Work Type und Datenbankprincipal; REMOVE entfernt den Eintrag.' AS nvarchar(max)),CAST(NULL AS nvarchar(max))),
            ('PARAMETER',1,N'@WorkTypeName','varchar(128)',1,0,NULL,N'Vorhandener kanonischer Work Type.',NULL),
            ('PARAMETER',2,N'@Principal','sysname',1,0,NULL,N'Vorhandener Datenbankbenutzer oder Datenbankrolle.',NULL),
            ('PARAMETER',3,N'@PermissionName','varchar(32)',1,0,NULL,N'ENQUEUE, CLAIM oder EXECUTE_NEW_SESSION.',NULL),
            ('PARAMETER',4,N'@PermissionState','varchar(8)',0,0,N'ALLOW',N'ALLOW, DENY oder REMOVE; DENY hat Vorrang.',NULL),
            ('PARAMETER',5,N'@Debug','tinyint',0,0,N'0',N'Optionale nicht sensible Fortschrittsmeldung.',NULL),
            ('PARAMETER',6,N'@Hilfe','bit',0,0,N'0',N'Nur diesen Hilfevertrag ausgeben.',NULL),
            ('RESULT_COLUMN',1,NULL,NULL,NULL,NULL,NULL,N'Kein fachliches Resultset.',NULL),
            ('ERROR',1,N'51590-51594',NULL,NULL,NULL,NULL,N'Parameter, Autorität, Principal, Work Type oder Transaktionszustand ungültig.',NULL),
            ('PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'EXECUTE und CONTROL auf toolbelt_core.WorkTypePermission.',NULL),
            ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Konfiguriert einen vorhandenen synthetischen Producerprincipal.',N'EXEC toolbelt_core.USP_SetWorkTypePermission @WorkTypeName=''demo.noop'',@Principal=N''ContosoProducer'',@PermissionName=''ENQUEUE'';')
        )v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2
            WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4 WHEN 'PERMISSION' THEN 5 ELSE 6 END,v.Ordinal;
        RETURN 0;
    END;
    IF @WorkTypeName IS NULL OR @Principal IS NULL OR @PermissionName IS NULL
        OR @PermissionName COLLATE Latin1_General_100_BIN2 NOT IN('ENQUEUE','CLAIM','EXECUTE_NEW_SESSION')
        OR @PermissionState IS NULL OR @PermissionState COLLATE Latin1_General_100_BIN2 NOT IN('ALLOW','DENY','REMOVE')
        THROW 51590,N'Work Type, Principal, Aktion und Zustand müssen gültig angegeben sein.',1;
    IF ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core.WorkTypePermission',N'OBJECT',N'CONTROL'),0)<>1
        THROW 51591,N'CONTROL auf der Work-Type-Policy fehlt.',1;
    IF XACT_STATE()=-1 THROW 51594,N'Policyänderung ist in einer uncommittable Transaktion nicht möglich.',1;
    DECLARE @PrincipalId int,@Sid varbinary(85),@Created datetime;
    SELECT @PrincipalId=principal_id,@Sid=sid,@Created=create_date
    FROM sys.database_principals
    WHERE name=@Principal AND type IN('S','U','G','R','E','X') AND principal_id<>0;
    IF @PrincipalId IS NULL THROW 51592,N'Der Datenbankprincipal ist nicht verfügbar.',1;
    DECLARE @Initial int=@@TRANCOUNT,@WorkTypeId bigint,@Version binary(8);
    IF @Initial=0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION TBX_WorkType_Permission;
    BEGIN TRY
        SELECT @WorkTypeId=WorkTypeId,@Version=CONVERT(binary(8),RowVersion)
        FROM toolbelt_core.WorkType WITH(UPDLOCK,HOLDLOCK) WHERE WorkTypeName=@WorkTypeName;
        IF @WorkTypeId IS NULL THROW 51593,N'Der Work Type ist nicht registriert.',1;
        DELETE toolbelt_core.WorkTypePermission
        WHERE WorkTypeId=@WorkTypeId AND PrincipalId=@PrincipalId AND PermissionName=@PermissionName;
        IF @PermissionState<>'REMOVE'
            INSERT toolbelt_core.WorkTypePermission
            (WorkTypeId,PrincipalId,PermissionName,PrincipalSid,PrincipalCreatedAt,WorkTypeVersion,IsDenied)
            VALUES(@WorkTypeId,@PrincipalId,@PermissionName,@Sid,@Created,@Version,
                CASE WHEN @PermissionState='DENY' THEN 1 ELSE 0 END);
        IF @Initial=0 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @Initial=0 AND XACT_STATE()<>0 ROLLBACK;
        ELSE IF @Initial>0 AND XACT_STATE()=1 ROLLBACK TRANSACTION TBX_WorkType_Permission;
        THROW;
    END CATCH;
    IF ISNULL(@Debug,0)>0 RAISERROR(N'Work-Type-Policy aktualisiert.',10,1) WITH NOWAIT;
    RETURN 0;
END;
GO
