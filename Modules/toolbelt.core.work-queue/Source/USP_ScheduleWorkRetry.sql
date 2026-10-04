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
    EXEC toolbelt_core.USP_ScheduleWorkRetryCore @WorkItemId=@WorkItemId,@ClaimToken=@ClaimToken,@FailureCode=@FailureCode,@FailureMessage=@FailureMessage,@ResultTable=@ResultTable,@KeepData=@KeepData,@Debug=@Debug;
    RETURN 0;
END;
GO
