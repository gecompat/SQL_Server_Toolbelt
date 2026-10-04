-- Interner Terminalkern; fachliche Logik genau einmal.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_ScheduleWorkRetryCore]
      @EmitResult bit=1,@WorkItemId bigint=NULL,@ClaimToken uniqueidentifier=NULL,@FailureCode varchar(64)=NULL,@FailureMessage nvarchar(1000)=NULL,
      @ResultTable sysname=NULL,@KeepData bit=0,@Debug tinyint=0,@Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
 SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_ScheduleWorkRetryCore' AS sysname) ObjectName,
 CAST(v.Section AS varchar(32)) Section,v.Ordinal,CAST(v.ItemName AS sysname) ItemName,CAST(v.SqlDataType AS varchar(256)) SqlDataType,CAST(v.IsRequired AS bit) IsRequired,CAST(v.IsNullable AS bit) IsNullable,CAST(v.DefaultValue AS nvarchar(4000)) DefaultValue,CAST(v.Description AS nvarchar(max)) Description,CAST(v.ExampleSql AS nvarchar(max)) ExampleSql
 FROM(VALUES ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Privater tokengebundener Retrykern; vorhandene Queuepolicy entscheidet Retry oder Dead Letter.',NULL),
('PARAMETER',1,N'@EmitResult',N'bit',0,0,N'1',N'0 unterdrückt das Fachresultset; keine neue Autorität.',NULL),
('PARAMETER',2,N'@WorkItemId',N'bigint',1,0,N'NULL',N'Exakter Queueclaim.',NULL),
('PARAMETER',3,N'@ClaimToken',N'uniqueidentifier',1,0,N'NULL',N'Exaktes Ownershiptoken.',NULL),
('PARAMETER',4,N'@FailureCode',N'varchar(64)',1,0,N'NULL',N'Stabiler synthetischer Fehlercode.',NULL),
('PARAMETER',5,N'@FailureMessage',N'nvarchar(1000)',0,1,N'NULL',N'Optionale bereinigte Fehlermeldung.',NULL),
('PARAMETER',6,N'@ResultTable',N'sysname',0,1,N'NULL',N'In dieser kanonischen Retryversion nicht unterstützt.',NULL),
('PARAMETER',7,N'@KeepData',N'bit',0,0,N'0',N'Standardparameter.',NULL),
('PARAMETER',8,N'@Debug',N'tinyint',0,0,N'0',N'Abstrakte Debugmeldung.',NULL),
('PARAMETER',9,N'@Hilfe',N'bit',0,0,N'0',N'1 liefert ausschließlich Help.',NULL),
('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Synthetischer Helpaufruf.',N'EXEC toolbelt_core.USP_ScheduleWorkRetryCore @Hilfe=1;')
 )v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql); RETURN 0;END;
    IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@WorkItemId AND
       (ManagedHold=1 OR (ManagedReservationId IS NOT NULL AND
        (ManagedCompletionNonce IS NULL OR TRY_CONVERT(uniqueidentifier,SESSION_CONTEXT(N'toolbelt.worker.completion_nonce')) IS NULL
         OR ManagedCompletionNonce<>TRY_CONVERT(uniqueidentifier,SESSION_CONTEXT(N'toolbelt.worker.completion_nonce'))
         OR APPLOCK_MODE(N'public',N'Toolbelt.Worker.Disposition.'+CONVERT(nvarchar(36),ManagedReservationId),N'Transaction')<>N'Exclusive'))))
        THROW 54201,N'Gehaltene oder verwaltete Arbeit verlangt den geschützten Abschluss-/Freigabepfad.',1;
 IF @WorkItemId IS NULL OR @ClaimToken IS NULL OR @FailureCode IS NULL THROW 51985,N'Work Item, ClaimToken und FailureCode sind erforderlich.',1;
 IF @FailureCode NOT LIKE '[A-Za-z]%' COLLATE Latin1_General_100_BIN2 OR @FailureCode LIKE '%[^A-Za-z0-9._-]%' COLLATE Latin1_General_100_BIN2 OR DATALENGTH(@FailureMessage)>2000 THROW 51986,N'Die Fehlerdaten sind ungültig.',1;
 IF @ResultTable IS NOT NULL THROW 51989,N'@ResultTable wird von dieser Version nicht unterstützt.',1;
 DECLARE @Initial int=@@TRANCOUNT,@Now datetime2(7)=SYSUTCDATETIME(),@Attempt bigint,@Max tinyint,@Base int,@Cap int,@Mode varchar(16),@Status varchar(16),@Token uniqueidentifier,@Lease datetime2(7),@Delay int,@Next datetime2(7);
 IF @Initial=0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION TBX_WorkQueue_Retry;
 BEGIN TRY
  SELECT @Status=Status,@Token=ClaimToken,@Lease=LeaseUntilUtc,@Attempt=CycleAttemptCount,@Max=MaxAttempts,@Base=RetryBaseDelaySeconds,@Cap=RetryMaxDelaySeconds,@Mode=ExecutionMode FROM toolbelt_core.WorkItem WITH(UPDLOCK,HOLDLOCK) WHERE WorkItemId=@WorkItemId;
    IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@WorkItemId AND
       (ManagedHold=1 OR (ManagedReservationId IS NOT NULL AND
        (ManagedCompletionNonce IS NULL OR TRY_CONVERT(uniqueidentifier,SESSION_CONTEXT(N'toolbelt.worker.completion_nonce')) IS NULL
         OR ManagedCompletionNonce<>TRY_CONVERT(uniqueidentifier,SESSION_CONTEXT(N'toolbelt.worker.completion_nonce'))
         OR APPLOCK_MODE(N'public',N'Toolbelt.Worker.Disposition.'+CONVERT(nvarchar(36),ManagedReservationId),N'Transaction')<>N'Exclusive'))))
        THROW 54201,N'Gehaltene oder verwaltete Arbeit verlangt den geschützten Abschluss-/Freigabepfad.',1;
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
 IF @EmitResult=1 SELECT * FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId=@WorkItemId;
END;
GO
