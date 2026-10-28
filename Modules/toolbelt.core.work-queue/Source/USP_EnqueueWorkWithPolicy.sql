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
  DECLARE @Help TABLE(HelpContractVersion varchar(16) NOT NULL,SchemaName sysname NOT NULL,ObjectName sysname NOT NULL,Section varchar(32) NOT NULL,Ordinal int NOT NULL,ItemName sysname NULL,SqlDataType varchar(256) NULL,IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,Description nvarchar(max) NOT NULL,ExampleSql nvarchar(max) NULL);
  INSERT @Help VALUES
  ('1.0',N'toolbelt_core',N'USP_EnqueueWorkWithPolicy','DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Reiht Arbeit mit SHARED- oder DRAIN_BARRIER-Modus und unveränderlicher Retry-Policy ein. ENQUEUE-Autorisierung ist erforderlich; Barrier-Aufrufe sind außerhalb einer Callertransaktion.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueWorkWithPolicy','PARAMETER',1,N'@WorkTypeName','varchar(128)',1,0,N'NULL',N'Registrierter und aktivierter Work Type.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueWorkWithPolicy','PARAMETER',2,N'@PayloadJson','nvarchar(max)',0,1,N'NULL',N'Abhängig vom ParameterMode: NONE oder JSON_PAYLOAD.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueWorkWithPolicy','PARAMETER',3,N'@IdempotencyKey','varchar(128)',0,1,N'NULL',N'Optionaler Idempotency Key innerhalb des Work Types.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueWorkWithPolicy','PARAMETER',4,N'@Priority','tinyint',0,0,N'0',N'Priorität; Barrier-Arbeit blockiert niedrigere aktive Arbeit gemäß Queuevertrag.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueWorkWithPolicy','PARAMETER',5,N'@ExecutionGroup','varchar(128)',0,0,N'default',N'Nichtleere Ausführungsgruppe.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueWorkWithPolicy','PARAMETER',6,N'@MaxAttempts','tinyint',0,0,N'3',N'1 bis 10 Versuche pro Zyklus.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueWorkWithPolicy','PARAMETER',7,N'@RetryBaseDelaySeconds','int',0,0,N'60',N'Basisverzögerung von 1 bis 86400 Sekunden.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueWorkWithPolicy','PARAMETER',8,N'@RetryMaxDelaySeconds','int',0,0,N'3600',N'Begrenzung der exponentiellen Retry-Verzögerung.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueWorkWithPolicy','PARAMETER',9,N'@ExecutionMode','varchar(16)',0,0,N'SHARED',N'Exakt SHARED oder DRAIN_BARRIER.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueWorkWithPolicy','PARAMETER',10,N'@ResultTable','sysname',0,1,N'NULL',N'Optionaler lokaler Temp-Tabellenname für das Queue-Ergebnis.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueWorkWithPolicy','PARAMETER',11,N'@KeepData','bit',0,0,N'0',N'Bei ResultTable-Routing bleiben vorhandene Zielzeilen erhalten, wenn 1.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueWorkWithPolicy','PARAMETER',12,N'@Debug','tinyint',0,0,N'0',N'Beim ResultTable-Routing Diagnosemeldungen des kanonischen Helpers; keine zusätzlichen fachlichen Resultsets.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueWorkWithPolicy','PARAMETER',13,N'@Hilfe','bit',0,0,N'0',N'1 gibt ausschließlich Hilfe aus.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueWorkWithPolicy','ERROR',1,N'51908,51965-51998',NULL,NULL,NULL,NULL,N'Fehlende ResultTable-Dependency, ungültige Policy oder Payload, inaktiver Work Type oder fehlende ENQUEUE-Autorisierung.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueWorkWithPolicy','PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'EXECUTE und explizite ENQUEUE-Autorisierung für den registrierten Work Type; für @ResultTable zusätzlich EXECUTE auf USP_PrepareResultTable.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueWorkWithPolicy','LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'Payload höchstens 64 KiB. Ein Barrier-Aufruf benötigt @@TRANCOUNT=0.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueWorkWithPolicy','EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Einreihung eines registrierten JSON-Work-Types.',N'EXEC toolbelt_core.USP_EnqueueWorkWithPolicy @WorkTypeName=''registered-json-type'',@PayloadJson=N''{"value":1}'';');
  INSERT @Help VALUES('1.0',N'toolbelt_core',N'USP_EnqueueWorkWithPolicy','RESULT_COLUMN',1,N'WasCreated','bit',1,0,NULL,N'1 bei neu angelegter Arbeit, 0 bei idempotenter Wiederverwendung.',NULL);
  INSERT @Help
  SELECT '1.0',N'toolbelt_core',N'USP_EnqueueWorkWithPolicy','RESULT_COLUMN',ROW_NUMBER() OVER(ORDER BY c.column_id)+1,c.name,TYPE_NAME(c.user_type_id),1,c.is_nullable,NULL,N'Wert aus toolbelt_core.VW_WorkQueue.',NULL FROM sys.columns c WHERE c.object_id=OBJECT_ID(N'toolbelt_core.VW_WorkQueue',N'V');
  SELECT HelpContractVersion,SchemaName,ObjectName,Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql FROM @Help
  ORDER BY CASE Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1 WHEN 'RESULT_COLUMN' THEN 2 ELSE 3 END,CASE WHEN ItemName=N'WasCreated' THEN 0 ELSE 1 END,Ordinal,ItemName;
  RETURN 0;
 END;
 IF NULLIF(@WorkTypeName,'') IS NULL OR NULLIF(@ExecutionGroup,'') IS NULL THROW 51965,N'Work Type und ExecutionGroup sind erforderlich.',1;
 IF @ExecutionMode NOT IN('SHARED','DRAIN_BARRIER') OR @MaxAttempts NOT BETWEEN 1 AND 10 OR @RetryBaseDelaySeconds NOT BETWEEN 1 AND 86400 OR @RetryMaxDelaySeconds NOT BETWEEN @RetryBaseDelaySeconds AND 86400 THROW 51966,N'Die Queue-Policy ist ungültig.',1;
 IF @ExecutionMode='DRAIN_BARRIER' AND @@TRANCOUNT<>0 THROW 51997,N'Barrier-Enqueue benötigt eine Session ohne Callertransaktion.',1;
 IF DATALENGTH(@PayloadJson)>65536 THROW 51967,N'@PayloadJson darf höchstens 64 KiB umfassen.',1;
 DECLARE @Initial int=@@TRANCOUNT,@WorkTypeId bigint,@Mode varchar(16),@Enabled bit,@Existing bigint,@Now datetime2(7)=SYSUTCDATETIME(),@WasCreated bit,@InsertResultSql nvarchar(max);
 SELECT TOP (0) CAST(0 AS bit) AS WasCreated,v.* INTO #tbx_WorkQueue_EnqueuePolicyResult FROM toolbelt_core.VW_WorkQueue AS v;
 IF @Initial=0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION TBX_WorkQueue_EnqueuePolicy;
 BEGIN TRY
  IF @ResultTable IS NOT NULL
  BEGIN
   IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P') IS NULL THROW 51908,N'Für @ResultTable fehlt toolbelt.core.result-table.',1;
   EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_WorkQueue_EnqueuePolicyResult',@KeepData=@KeepData,@Debug=@Debug;
  END;
  SELECT @WorkTypeId=WorkTypeId,@Mode=ParameterMode,@Enabled=IsEnabled FROM toolbelt_core.WorkType WITH(UPDLOCK,HOLDLOCK) WHERE WorkTypeName=@WorkTypeName;
  IF @WorkTypeId IS NULL OR @Enabled<>1 THROW 51969,N'Der Work Type ist nicht aktiv.',1;
  IF NOT EXISTS(SELECT 1 FROM toolbelt_core.TVF_WorkTypeAuthorization(@WorkTypeId,'ENQUEUE') WHERE IsAllowed=1)
            THROW 51998,N'Keine Einreihberechtigung für diesen Work Type.',1;
  IF @Mode='NONE' AND @PayloadJson IS NOT NULL THROW 51970,N'NONE akzeptiert keine Payload.',1;
  IF @Mode='JSON_PAYLOAD' AND (@PayloadJson IS NULL OR ISJSON(@PayloadJson)<>1 OR LEFT(LTRIM(@PayloadJson),1)<>N'{') THROW 51971,N'JSON_PAYLOAD verlangt ein JSON-Objekt.',1;
  IF @ExecutionMode='DRAIN_BARRIER'
     SELECT @Existing=SchedulerId FROM toolbelt_core.WorkQueueScheduler WITH(UPDLOCK,HOLDLOCK) WHERE SchedulerId=1;
  SET @Existing=NULL;
  IF @IdempotencyKey IS NOT NULL
  BEGIN
   SELECT @Existing=WorkItemId FROM toolbelt_core.WorkItem WITH(UPDLOCK,HOLDLOCK) WHERE WorkTypeId=@WorkTypeId AND IdempotencyKey=@IdempotencyKey;
   IF @Existing IS NOT NULL
   BEGIN
    IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@Existing AND (ISNULL(PayloadJson,N'') COLLATE Latin1_General_100_BIN2<>ISNULL(@PayloadJson,N'') COLLATE Latin1_General_100_BIN2 OR Priority<>@Priority OR ExecutionGroup<>@ExecutionGroup OR ExecutionMode<>@ExecutionMode OR MaxAttempts<>@MaxAttempts OR RetryBaseDelaySeconds<>@RetryBaseDelaySeconds OR RetryMaxDelaySeconds<>@RetryMaxDelaySeconds)) THROW 51972,N'Der Idempotency Key gehört zu abweichender Arbeit.',1;
    SET @WasCreated=0;
   END;
  END;
  IF @Existing IS NULL
  BEGIN
   INSERT toolbelt_core.WorkItem(WorkTypeId,PayloadJson,Status,ExecutionGroup,Priority,ExecutionMode,IdempotencyKey,MaxAttempts,RetryBaseDelaySeconds,RetryMaxDelaySeconds,RetryCycleNumber,CycleAttemptCount,BarrierEpoch)
   VALUES(@WorkTypeId,@PayloadJson,CASE WHEN @ExecutionMode='DRAIN_BARRIER' THEN 'BARRIER_WAIT' ELSE 'QUEUED' END,@ExecutionGroup,@Priority,@ExecutionMode,@IdempotencyKey,@MaxAttempts,@RetryBaseDelaySeconds,@RetryMaxDelaySeconds,1,0,CASE WHEN @ExecutionMode='DRAIN_BARRIER' THEN 1 ELSE 0 END);
   SET @Existing=SCOPE_IDENTITY(); SET @WasCreated=1;
   IF @ExecutionMode='DRAIN_BARRIER'
    INSERT toolbelt_core.WorkQueueBarrierBlocker(BarrierWorkItemId,BarrierEpoch,BlockingWorkItemId,BlockingClaimGeneration)
    SELECT @Existing,1,WorkItemId,ClaimGeneration FROM toolbelt_core.WorkItem WHERE Status='CLAIMED' AND ExecutionGroup=@ExecutionGroup AND NOT(ExecutionMode='DRAIN_BARRIER' AND Priority=@Priority);
  END;
  IF @ResultTable IS NOT NULL
  BEGIN
   INSERT #tbx_WorkQueue_EnqueuePolicyResult SELECT @WasCreated,v.* FROM toolbelt_core.VW_WorkQueue AS v WHERE v.WorkItemId=@Existing;
   SET @InsertResultSql=N'INSERT INTO '+QUOTENAME(@ResultTable)+N' SELECT * FROM #tbx_WorkQueue_EnqueuePolicyResult;';
   EXEC sys.sp_executesql @InsertResultSql;
  END;
  IF @Initial=0 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @Initial=0 AND XACT_STATE()<>0 ROLLBACK; ELSE IF @Initial>0 AND XACT_STATE()=1 ROLLBACK TRANSACTION TBX_WorkQueue_EnqueuePolicy; THROW;
 END CATCH;
 IF @ResultTable IS NULL SELECT @WasCreated AS WasCreated,* FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId=@Existing;
END;
GO
