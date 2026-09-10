SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_EnqueueBarrierWork]
      @WorkTypeName varchar(128)=NULL,@PayloadJson nvarchar(max)=NULL,@ExecutionGroup varchar(128)=NULL,@Priority tinyint=NULL,@IdempotencyKey varchar(128)=NULL,
      @MaxAttempts tinyint=3,@RetryBaseDelaySeconds int=60,@RetryMaxDelaySeconds int=3600,@ResultTable sysname=NULL,@KeepData bit=0,@Debug tinyint=0,@Hilfe bit=0
AS
BEGIN
 IF ISNULL(@Hilfe,0)=1 BEGIN EXEC toolbelt_core.USP_EnqueueWorkWithPolicy @Hilfe=1; RETURN 0; END;
 IF @Priority IS NULL THROW 51975,N'@Priority ist für eine Barrier erforderlich.',1;
 EXEC toolbelt_core.USP_EnqueueWorkWithPolicy @WorkTypeName,@PayloadJson,@IdempotencyKey,@Priority,@ExecutionGroup,@MaxAttempts,@RetryBaseDelaySeconds,@RetryMaxDelaySeconds,'DRAIN_BARRIER',@ResultTable,@KeepData,@Debug,@Hilfe;
END;
GO
