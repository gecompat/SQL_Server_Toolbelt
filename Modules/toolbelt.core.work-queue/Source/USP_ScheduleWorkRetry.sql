SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_ScheduleWorkRetry]
      @WorkItemId bigint=NULL,@ClaimToken uniqueidentifier=NULL,@FailureCode varchar(64)=NULL,@FailureMessage nvarchar(1000)=NULL,
      @ResultTable sysname=NULL,@KeepData bit=0,@Debug tinyint=0,@Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_ScheduleWorkRetry' AS sysname) ObjectName,CAST('DESCRIPTION' AS varchar(32)) Section,1 Ordinal,CAST(NULL AS sysname) ItemName,CAST(NULL AS varchar(256)) SqlDataType,CAST(NULL AS bit) IsRequired,CAST(NULL AS bit) IsNullable,CAST(NULL AS nvarchar(4000)) DefaultValue,CAST(N'Plant einen tokengebundenen Retry oder verschiebt nach Dead Letter.' AS nvarchar(max)) Description,CAST(NULL AS nvarchar(max)) ExampleSql; RETURN 0; END;
 IF @WorkItemId IS NULL OR @ClaimToken IS NULL OR @FailureCode IS NULL THROW 51985,N'Work Item, ClaimToken und FailureCode sind erforderlich.',1;
 IF @FailureCode NOT LIKE '[A-Za-z]%' COLLATE Latin1_General_100_BIN2 OR @FailureCode LIKE '%[^A-Za-z0-9._-]%' COLLATE Latin1_General_100_BIN2 OR DATALENGTH(@FailureMessage)>2000 THROW 51986,N'Die Fehlerdaten sind ungültig.',1;
 IF @ResultTable IS NOT NULL THROW 51989,N'@ResultTable wird von dieser Version nicht unterstützt.',1;
 DECLARE @Initial int=@@TRANCOUNT,@Now datetime2(7)=SYSUTCDATETIME(),@Attempt bigint,@Max tinyint,@Base int,@Cap int,@Mode varchar(16),@Status varchar(16),@Token uniqueidentifier,@Lease datetime2(7),@Delay int,@Next datetime2(7);
 IF @Initial=0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION TBX_WorkQueue_Retry;
 BEGIN TRY
  SELECT @Status=Status,@Token=ClaimToken,@Lease=LeaseUntilUtc,@Attempt=CycleAttemptCount,@Max=MaxAttempts,@Base=RetryBaseDelaySeconds,@Cap=RetryMaxDelaySeconds,@Mode=ExecutionMode FROM toolbelt_core.WorkItem WITH(UPDLOCK,HOLDLOCK) WHERE WorkItemId=@WorkItemId;
  IF @Status<>'CLAIMED' OR @Token<>@ClaimToken OR @Lease<=@Now THROW 51987,N'Der Claim ist nicht aktiv.',1;
  IF @Attempt>=@Max
   UPDATE toolbelt_core.WorkItem SET Status='DEAD_LETTER',FailureCode=@FailureCode,FailureMessage=@FailureMessage,LastErrorCode=@FailureCode,LastErrorMessage=@FailureMessage,DeadLetteredAtUtc=@Now,DeadLetteredBy=ORIGINAL_LOGIN() WHERE WorkItemId=@WorkItemId;
  ELSE
  BEGIN
   SET @Delay=CONVERT(int,CASE WHEN @Attempt>=31 THEN @Cap WHEN POWER(CONVERT(float,2),@Attempt-1)*@Base>@Cap THEN @Cap ELSE POWER(CONVERT(float,2),@Attempt-1)*@Base END);
   SET @Next=DATEADD(SECOND,@Delay,@Now);
   UPDATE toolbelt_core.WorkItem SET Status='RETRY_WAIT',ClaimedAtUtc=NULL,ClaimedBy=NULL,ClaimToken=NULL,LeaseDurationSeconds=NULL,LeaseUntilUtc=NULL,LastHeartbeatAtUtc=NULL,NextAttemptAtUtc=@Next,LastErrorCode=@FailureCode,LastErrorMessage=@FailureMessage,LastRetryScheduledAtUtc=@Now,LastRetryScheduledBy=ORIGINAL_LOGIN() WHERE WorkItemId=@WorkItemId;
  END;
  IF @Initial=0 COMMIT;
 END TRY BEGIN CATCH IF @Initial=0 AND XACT_STATE()<>0 ROLLBACK; ELSE IF @Initial>0 AND XACT_STATE()=1 ROLLBACK TRANSACTION TBX_WorkQueue_Retry; THROW; END CATCH;
 SELECT * FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId=@WorkItemId;
END;
GO
