SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_DispatchWorkType]
(
      @WorkTypeName       varchar(128) = NULL
    , @PayloadJson        nvarchar(max) = NULL
    , @ExecutionId        uniqueidentifier = NULL
    , @CorrelationId      uniqueidentifier = NULL
    , @Actor              nvarchar(256) = NULL
    , @Tenant             nvarchar(256) = NULL
    , @RemoteSessionId    int = NULL OUTPUT
    , @HandlerReturnCode  int = NULL OUTPUT
    , @StartedAtUtc       datetime2(7) = NULL OUTPUT
    , @CompletedAtUtc     datetime2(7) = NULL OUTPUT
    , @Hilfe              bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF ISNULL(@Hilfe,0)=1
    BEGIN
        SELECT CONVERT(varchar(16),'1.0') HelpContractVersion,CONVERT(sysname,N'toolbelt_core') SchemaName,
            CONVERT(sysname,N'USP_DispatchWorkType') ObjectName,v.Section,v.Ordinal,v.ItemName,v.SqlDataType,
            v.IsRequired,v.IsNullable,v.DefaultValue,v.Description,v.ExampleSql
        FROM (VALUES
          (CAST('DESCRIPTION' AS varchar(32)),1,CAST(NULL AS sysname),CAST(NULL AS varchar(256)),CAST(NULL AS bit),CAST(NULL AS bit),CAST(NULL AS nvarchar(4000)),CAST(N'Interner Second-Session-Dispatcher. Führt den registrierten Handler mit gebundenem Execution-Kontext aus; Hilfe liest keine Work-Type- oder Sessiondaten.' AS nvarchar(max)),CAST(NULL AS nvarchar(max))),
          ('PARAMETER',1,N'@WorkTypeName','varchar(128)',1,0,N'NULL',N'Exakter registrierter Work Type.',NULL),
          ('PARAMETER',2,N'@PayloadJson','nvarchar(max)',0,1,N'NULL',N'JSON-Objekt nur bei ParameterMode JSON_PAYLOAD.',NULL),
          ('PARAMETER',3,N'@ExecutionId','uniqueidentifier',1,0,N'NULL',N'Vom Caller gebundene Ausführungs-ID.',NULL),
          ('PARAMETER',4,N'@CorrelationId','uniqueidentifier',1,0,N'NULL',N'Vom Caller gebundene Korrelations-ID.',NULL),
          ('PARAMETER',5,N'@Actor','nvarchar(256)',0,1,N'NULL',N'Optionaler Actor des Remote-Kontexts.',NULL),
          ('PARAMETER',6,N'@Tenant','nvarchar(256)',0,1,N'NULL',N'Optionaler Tenant des Remote-Kontexts.',NULL),
          ('PARAMETER',7,N'@RemoteSessionId','int OUTPUT',0,1,N'NULL',N'OUTPUT-SPID der zweiten Session.',NULL),
          ('PARAMETER',8,N'@HandlerReturnCode','int OUTPUT',0,1,N'NULL',N'Returncode des registrierten Handlers.',NULL),
          ('PARAMETER',9,N'@StartedAtUtc','datetime2(7) OUTPUT',0,1,N'NULL',N'Startzeit des Remote-Kontexts in UTC.',NULL),
          ('PARAMETER',10,N'@CompletedAtUtc','datetime2(7) OUTPUT',0,1,N'NULL',N'Abschlusszeit nach erfolgreicher Handlerausführung.',NULL),
          ('PARAMETER',11,N'@Hilfe','bit',0,0,N'0',N'1 liefert ausschließlich diese Hilfe; alle OUTPUT-Werte bleiben unberührt.',NULL),
          ('RESULT_COLUMN',1,NULL,NULL,NULL,NULL,NULL,N'Kein fachliches Resultset; Status und Zeitwerte werden über OUTPUT-Parameter geliefert.',NULL),
          ('ERROR',1,N'51628-51638',NULL,NULL,NULL,NULL,N'Payload-, Work-Type-, Berechtigungs- oder Handlervertrag ist ungültig.',NULL),
          ('PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'Nur über den autorisierten Dispatchpfad; Handler-EXECUTE wird vor Ausführung geprüft.',NULL),
          ('LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'Payload höchstens 1 MiB; ParameterMode ist NONE oder JSON_PAYLOAD.',NULL),
          ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Fachlicher Aufruf über die öffentliche Fassade; registrierter JSON-Work-Type und konfigurierter Loopback sind Voraussetzung.',N'EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @WorkTypeName=''registered-json-type'',@PayloadJson=N''{"value":1}'';')
        )v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1 WHEN 'RESULT_COLUMN' THEN 2 ELSE 3 END,v.Ordinal;
        RETURN 0;
    END;

    SET @RemoteSessionId = @@SPID;
    SET @HandlerReturnCode = NULL;
    SET @StartedAtUtc = SYSUTCDATETIME();
    SET @CompletedAtUtc = NULL;

    IF @ExecutionId IS NULL OR @CorrelationId IS NULL
        THROW 51630, N'ExecutionId und CorrelationId sind für den Remote-Dispatcher erforderlich.', 1;

    DECLARE
          @HandlerSchema sysname
        , @HandlerProcedure sysname
        , @ParameterMode varchar(16)
        , @IsEnabled bit;

    SELECT
          @HandlerSchema = wt.HandlerSchema
        , @HandlerProcedure = wt.HandlerProcedure
        , @ParameterMode = wt.ParameterMode
        , @IsEnabled = wt.IsEnabled
    FROM toolbelt_core.WorkType AS wt
    WHERE wt.WorkTypeName = @WorkTypeName;

    IF @HandlerSchema IS NULL
        THROW 51631, N'Der Work Type ist in der Remote-Datenbank nicht registriert.', 1;
    IF @IsEnabled = 0
        THROW 51632, N'Der Work Type ist in der Remote-Datenbank deaktiviert.', 1;

    IF DATALENGTH(@PayloadJson)>1048576 THROW 51628,N'Payload überschreitet 1 MiB.',1;
    IF @ParameterMode = 'NONE' AND @PayloadJson IS NOT NULL
        THROW 51633, N'Der Work Type akzeptiert keine JSON-Payload.', 1;
    IF @ParameterMode = 'JSON_PAYLOAD'
       AND
       (
           @PayloadJson IS NULL
           OR ISJSON(@PayloadJson) <> 1
           OR LEFT(LTRIM(@PayloadJson), 1) <> N'{'
       )
        THROW 51634, N'Der Work Type benötigt eine JSON-Objekt-Payload.', 1;

    DECLARE @WorkTypeId bigint=(SELECT WorkTypeId FROM toolbelt_core.WorkType WHERE WorkTypeName=@WorkTypeName);
    IF NOT EXISTS(SELECT 1 FROM toolbelt_core.TVF_WorkTypeAuthorization(@WorkTypeId,'EXECUTE_NEW_SESSION') WHERE IsAllowed=1)
        THROW 51629,N'Keine Remote-Startberechtigung für diesen Work Type.',1;
    DECLARE @HandlerQualifiedName nvarchar(517) =
        QUOTENAME(@HandlerSchema) + N'.' + QUOTENAME(@HandlerProcedure);
    DECLARE @HandlerObjectId int = COALESCE
    (
          OBJECT_ID(@HandlerQualifiedName, N'P')
        , OBJECT_ID(@HandlerQualifiedName, N'PC')
    );

    IF @HandlerObjectId IS NULL
        THROW 51635, N'Die registrierte Remote-Zielprocedure existiert nicht.', 1;
    IF ISNULL(HAS_PERMS_BY_NAME(@HandlerQualifiedName, N'OBJECT', N'EXECUTE'), 0) <> 1
        THROW 51636, N'Der Remote-Principal besitzt kein EXECUTE auf die Zielprocedure.', 1;

    DECLARE @InputParameterCount int =
    (
        SELECT COUNT(*)
        FROM sys.parameters AS p
        WHERE p.object_id = @HandlerObjectId
          AND p.parameter_id > 0
    );

    DECLARE @IsCanonicalEventLogHandler bit = 0;
    IF @WorkTypeName COLLATE Latin1_General_100_BIN2 = 'toolbelt.event-log.write'
       AND @HandlerSchema COLLATE Latin1_General_100_BIN2 = N'toolbelt_core'
       AND @HandlerProcedure COLLATE Latin1_General_100_BIN2 = N'USP_WriteEventInternal'
       AND @ParameterMode COLLATE Latin1_General_100_BIN2 = 'JSON_PAYLOAD'
       AND @InputParameterCount = 2
       AND EXISTS
       (
           SELECT 1
           FROM sys.parameters AS p
           WHERE p.object_id = @HandlerObjectId
             AND p.parameter_id = 1
             AND p.name COLLATE Latin1_General_100_BIN2 = N'@PayloadJson'
             AND TYPE_NAME(p.user_type_id) COLLATE Latin1_General_100_BIN2 = N'nvarchar'
             AND p.max_length = -1
             AND p.is_output = 0
       )
       AND EXISTS
       (
           SELECT 1
           FROM sys.parameters AS p
           WHERE p.object_id = @HandlerObjectId
             AND p.parameter_id = 2
             AND p.name COLLATE Latin1_General_100_BIN2 = N'@Hilfe'
             AND TYPE_NAME(p.user_type_id) COLLATE Latin1_General_100_BIN2 = N'bit'
             AND p.max_length = 1
             AND p.is_output = 0
       )
       AND EXISTS
       (
           SELECT 1
           FROM sys.extended_properties AS ep
           WHERE ep.class = 1
             AND ep.major_id = @HandlerObjectId
             AND ep.minor_id = 0
             AND ep.name COLLATE Latin1_General_100_BIN2 = N'Toolbelt.ModuleId'
             AND CONVERT(nvarchar(256), ep.value) COLLATE Latin1_General_100_BIN2 = N'toolbelt.core.event-log'
       )
       AND EXISTS
       (
           SELECT 1
           FROM sys.extended_properties AS ep
           WHERE ep.class = 1
             AND ep.major_id = @HandlerObjectId
             AND ep.minor_id = 0
             AND ep.name COLLATE Latin1_General_100_BIN2 = N'Toolbelt.ModuleVersion'
             AND CONVERT(nvarchar(32), ep.value) COLLATE Latin1_General_100_BIN2 = N'1.0.0'
       )
       AND EXISTS
       (
           SELECT 1
           FROM sys.extended_properties AS ep
           WHERE ep.class = 0
             AND ep.major_id = 0
             AND ep.minor_id = 0
             AND ep.name COLLATE Latin1_General_100_BIN2 = N'Toolbelt.Module.toolbelt.core.event-log.Version'
             AND CONVERT(nvarchar(32), ep.value) COLLATE Latin1_General_100_BIN2 = N'1.0.0'
       )
        SET @IsCanonicalEventLogHandler = 1;

    IF @ParameterMode = 'NONE' AND @InputParameterCount <> 0
        THROW 51637, N'Ein NONE-Handler darf keine Eingabe- oder Ausgabeparameter besitzen.', 1;

    IF @ParameterMode = 'JSON_PAYLOAD'
       AND @IsCanonicalEventLogHandler = 0
       AND
       (
           @InputParameterCount <> 1
           OR NOT EXISTS
              (
                  SELECT 1
                  FROM sys.parameters AS p
                  WHERE p.object_id = @HandlerObjectId
                    AND p.parameter_id = 1
                    AND p.name = N'@PayloadJson'
                    AND TYPE_NAME(p.user_type_id) = N'nvarchar'
                    AND p.max_length = -1
                    AND p.is_output = 0
              )
       )
        THROW 51638, N'Ein JSON_PAYLOAD-Handler muss exakt @PayloadJson nvarchar(max) als einzigen Eingabeparameter besitzen.', 1;

    DECLARE @RemoteExecutionId uniqueidentifier = @ExecutionId;
    DECLARE @ContextStarted bit = 0;

    BEGIN TRY
        EXEC toolbelt_core.USP_BeginExecution
              @ExecutionId = @RemoteExecutionId OUTPUT
            , @CorrelationId = @CorrelationId
            , @Actor = @Actor
            , @Tenant = @Tenant
            , @AllowNested = 0;
        SET @ContextStarted = 1;

        BEGIN TRANSACTION;

        DECLARE @HandlerSql nvarchar(max);
        IF @ParameterMode = 'NONE'
            SET @HandlerSql =
                N'EXEC @HandlerReturnCode = ' + @HandlerQualifiedName
                + N' WITH RESULT SETS NONE;';
        ELSE IF @IsCanonicalEventLogHandler = 1
            SET @HandlerSql =
                N'EXEC @HandlerReturnCode = ' + @HandlerQualifiedName
                + N' @PayloadJson = @PayloadJson, @Hilfe = 0 WITH RESULT SETS NONE;';
        ELSE
            SET @HandlerSql =
                N'EXEC @HandlerReturnCode = ' + @HandlerQualifiedName
                + N' @PayloadJson = @PayloadJson WITH RESULT SETS NONE;';

        EXEC sys.sp_executesql
              @HandlerSql
            , N'@PayloadJson nvarchar(max), @HandlerReturnCode int OUTPUT'
            , @PayloadJson = @PayloadJson
            , @HandlerReturnCode = @HandlerReturnCode OUTPUT;

        COMMIT TRANSACTION;
        SET @CompletedAtUtc = SYSUTCDATETIME();

        EXEC toolbelt_core.USP_EndExecution
            @ExpectedExecutionId = @ExecutionId;
        SET @ContextStarted = 0;

        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        IF @ContextStarted = 1
        BEGIN
            BEGIN TRY
                EXEC toolbelt_core.USP_EndExecution
                    @ExpectedExecutionId = @ExecutionId;
            END TRY
            BEGIN CATCH
                -- Der ursprüngliche Handler-/Providerfehler behält Vorrang.
            END CATCH;
        END;

        THROW;
    END CATCH;
END;
GO
