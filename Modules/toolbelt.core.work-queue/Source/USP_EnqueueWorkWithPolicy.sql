SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_EnqueueWorkWithPolicy]
      @WorkTypeName varchar(128)=NULL,@PayloadJson nvarchar(max)=NULL,@IdempotencyKey varchar(128)=NULL,
      @Priority tinyint=0,@ExecutionGroup varchar(128)='default',@MaxAttempts tinyint=3,
      @RetryBaseDelaySeconds int=60,@RetryMaxDelaySeconds int=3600,@ExecutionMode varchar(16)='SHARED',
      @ResultTable sysname=NULL,@KeepData bit=0,@Debug tinyint=0,@Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1
 BEGIN
  SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_EnqueueWorkWithPolicy' AS sysname) ObjectName,
         CAST('DESCRIPTION' AS varchar(32)) Section,1 Ordinal,CAST(NULL AS sysname) ItemName,CAST(NULL AS varchar(256)) SqlDataType,CAST(NULL AS bit) IsRequired,CAST(NULL AS bit) IsNullable,CAST(NULL AS nvarchar(4000)) DefaultValue,
         CAST(N'Reiht SHARED-Arbeit mit unveränderlicher Retry-Policy und optionalem Idempotency Key ein.' AS nvarchar(max)) Description,CAST(NULL AS nvarchar(max)) ExampleSql;
  RETURN 0;
 END;
 IF NULLIF(@WorkTypeName,'') IS NULL OR NULLIF(@ExecutionGroup,'') IS NULL THROW 51965,N'Work Type und ExecutionGroup sind erforderlich.',1;
 IF @ExecutionMode NOT IN('SHARED','DRAIN_BARRIER') OR @MaxAttempts NOT BETWEEN 1 AND 10 OR @RetryBaseDelaySeconds NOT BETWEEN 1 AND 86400 OR @RetryMaxDelaySeconds NOT BETWEEN @RetryBaseDelaySeconds AND 86400 THROW 51966,N'Die Queue-Policy ist ungültig.',1;
 IF DATALENGTH(@PayloadJson)>65536 THROW 51967,N'@PayloadJson darf höchstens 64 KiB umfassen.',1;
 IF @ResultTable IS NOT NULL THROW 51968,N'@ResultTable wird von dieser Version nicht unterstützt.',1;
 DECLARE @Initial int=@@TRANCOUNT,@WorkTypeId bigint,@Mode varchar(16),@Enabled bit,@Existing bigint,@Now datetime2(7)=SYSUTCDATETIME();
 IF @Initial=0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION TBX_WorkQueue_EnqueuePolicy;
 BEGIN TRY
  SELECT @WorkTypeId=WorkTypeId,@Mode=ParameterMode,@Enabled=IsEnabled FROM toolbelt_core.WorkType WITH(UPDLOCK,HOLDLOCK) WHERE WorkTypeName=@WorkTypeName;
  IF @WorkTypeId IS NULL OR @Enabled<>1 THROW 51969,N'Der Work Type ist nicht aktiv.',1;
  IF @Mode='NONE' AND @PayloadJson IS NOT NULL THROW 51970,N'NONE akzeptiert keine Payload.',1;
  IF @Mode='JSON_PAYLOAD' AND (@PayloadJson IS NULL OR ISJSON(@PayloadJson)<>1 OR LEFT(LTRIM(@PayloadJson),1)<>N'{') THROW 51971,N'JSON_PAYLOAD verlangt ein JSON-Objekt.',1;
  IF @ExecutionMode='DRAIN_BARRIER'
     SELECT SchedulerId FROM toolbelt_core.WorkQueueScheduler WITH(UPDLOCK,HOLDLOCK) WHERE SchedulerId=1;
  IF @IdempotencyKey IS NOT NULL
  BEGIN
   SELECT @Existing=WorkItemId FROM toolbelt_core.WorkItem WITH(UPDLOCK,HOLDLOCK) WHERE WorkTypeId=@WorkTypeId AND IdempotencyKey=@IdempotencyKey;
   IF @Existing IS NOT NULL
   BEGIN
    IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@Existing AND (ISNULL(PayloadJson,N'') COLLATE Latin1_General_100_BIN2<>ISNULL(@PayloadJson,N'') COLLATE Latin1_General_100_BIN2 OR Priority<>@Priority OR ExecutionGroup<>@ExecutionGroup OR ExecutionMode<>@ExecutionMode OR MaxAttempts<>@MaxAttempts OR RetryBaseDelaySeconds<>@RetryBaseDelaySeconds OR RetryMaxDelaySeconds<>@RetryMaxDelaySeconds)) THROW 51972,N'Der Idempotency Key gehört zu abweichender Arbeit.',1;
    IF @Initial=0 COMMIT TRANSACTION;
    SELECT CAST(0 AS bit) WasCreated,* FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId=@Existing; RETURN 0;
   END;
  END;
  INSERT toolbelt_core.WorkItem(WorkTypeId,PayloadJson,Status,ExecutionGroup,Priority,ExecutionMode,IdempotencyKey,MaxAttempts,RetryBaseDelaySeconds,RetryMaxDelaySeconds,RetryCycleNumber,CycleAttemptCount,BarrierEpoch)
  VALUES(@WorkTypeId,@PayloadJson,CASE WHEN @ExecutionMode='DRAIN_BARRIER' THEN 'BARRIER_WAIT' ELSE 'QUEUED' END,@ExecutionGroup,@Priority,@ExecutionMode,@IdempotencyKey,@MaxAttempts,@RetryBaseDelaySeconds,@RetryMaxDelaySeconds,1,0,CASE WHEN @ExecutionMode='DRAIN_BARRIER' THEN 1 ELSE 0 END);
  SET @Existing=SCOPE_IDENTITY();
  IF @ExecutionMode='DRAIN_BARRIER'
   INSERT toolbelt_core.WorkQueueBarrierBlocker(BarrierWorkItemId,BarrierEpoch,BlockingWorkItemId,BlockingClaimGeneration)
   SELECT @Existing,1,WorkItemId,ClaimGeneration FROM toolbelt_core.WorkItem WHERE Status='CLAIMED' AND ExecutionGroup=@ExecutionGroup AND NOT(ExecutionMode='DRAIN_BARRIER' AND Priority=@Priority);
  IF @Initial=0 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @Initial=0 AND XACT_STATE()<>0 ROLLBACK; ELSE IF @Initial>0 AND XACT_STATE()=1 ROLLBACK TRANSACTION TBX_WorkQueue_EnqueuePolicy; THROW;
 END CATCH;
 SELECT CAST(1 AS bit) WasCreated,* FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId=@Existing;
END;
GO
