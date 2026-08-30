:On Error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

CREATE TABLE toolbelt_core.WorkItem
(
      WorkItemId bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_WorkItem PRIMARY KEY
    , WorkTypeId bigint NOT NULL CONSTRAINT FK_WorkItem_WorkType REFERENCES toolbelt_core.WorkType(WorkTypeId)
    , PayloadJson nvarchar(max) NULL
    , Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL CONSTRAINT DF_WorkItem_Status DEFAULT('QUEUED')
    , EnqueuedAtUtc datetime2(7) NOT NULL CONSTRAINT DF_WorkItem_EnqueuedAtUtc DEFAULT(SYSUTCDATETIME())
    , EnqueuedBy sysname NOT NULL CONSTRAINT DF_WorkItem_EnqueuedBy DEFAULT(ORIGINAL_LOGIN())
    , ClaimedAtUtc datetime2(7) NULL
    , ClaimedBy sysname NULL
    , ClaimToken uniqueidentifier NULL
    , CompletedAtUtc datetime2(7) NULL
    , CompletedBy sysname NULL
    , FailedAtUtc datetime2(7) NULL
    , FailedBy sysname NULL
    , FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL
    , FailureMessage nvarchar(1000) NULL
    , RowVersion rowversion NOT NULL
    , CONSTRAINT CK_WorkItem_Status CHECK(Status IN('QUEUED','CLAIMED','COMPLETED','FAILED'))
    , CONSTRAINT CK_WorkItem_PayloadJson CHECK(PayloadJson IS NULL OR(DATALENGTH(PayloadJson)<=65536 AND ISJSON(PayloadJson)=1 AND LEFT(LTRIM(PayloadJson),1)=N'{'))
    , CONSTRAINT CK_WorkItem_FailureCode CHECK(FailureCode IS NULL OR(LEN(FailureCode) BETWEEN 1 AND 64 AND FailureCode LIKE '[A-Za-z]%' COLLATE Latin1_General_100_BIN2 AND FailureCode NOT LIKE '%[^A-Za-z0-9._-]%' COLLATE Latin1_General_100_BIN2))
    , CONSTRAINT CK_WorkItem_StateMetadata CHECK
      ((Status='QUEUED' AND ClaimedAtUtc IS NULL AND ClaimedBy IS NULL AND ClaimToken IS NULL AND CompletedAtUtc IS NULL AND CompletedBy IS NULL AND FailedAtUtc IS NULL AND FailedBy IS NULL AND FailureCode IS NULL AND FailureMessage IS NULL)
       OR(Status='CLAIMED' AND ClaimedAtUtc IS NOT NULL AND ClaimedBy IS NOT NULL AND ClaimToken IS NOT NULL AND CompletedAtUtc IS NULL AND CompletedBy IS NULL AND FailedAtUtc IS NULL AND FailedBy IS NULL AND FailureCode IS NULL AND FailureMessage IS NULL)
       OR(Status='COMPLETED' AND ClaimedAtUtc IS NOT NULL AND ClaimedBy IS NOT NULL AND ClaimToken IS NOT NULL AND CompletedAtUtc IS NOT NULL AND CompletedBy IS NOT NULL AND FailedAtUtc IS NULL AND FailedBy IS NULL AND FailureCode IS NULL AND FailureMessage IS NULL)
       OR(Status='FAILED' AND ClaimedAtUtc IS NOT NULL AND ClaimedBy IS NOT NULL AND ClaimToken IS NOT NULL AND CompletedAtUtc IS NULL AND CompletedBy IS NULL AND FailedAtUtc IS NOT NULL AND FailedBy IS NOT NULL AND FailureCode IS NOT NULL))
);
CREATE INDEX IX_WorkItem_Status_WorkItemId ON toolbelt_core.WorkItem(Status,WorkItemId) INCLUDE(WorkTypeId);
CREATE INDEX IX_WorkItem_WorkTypeId_Status_WorkItemId ON toolbelt_core.WorkItem(WorkTypeId,Status,WorkItemId);
GO
CREATE VIEW toolbelt_core.VW_WorkQueue AS SELECT WorkItemId FROM toolbelt_core.WorkItem;
GO
CREATE PROCEDURE toolbelt_core.USP_EnqueueWork AS RETURN 0;
GO
CREATE PROCEDURE toolbelt_core.USP_ClaimWork AS RETURN 0;
GO
CREATE PROCEDURE toolbelt_core.USP_CompleteWork AS RETURN 0;
GO
CREATE PROCEDURE toolbelt_core.USP_FailWork AS RETURN 0;
GO
CREATE PROCEDURE toolbelt_core.USP_GetWorkStatus AS RETURN 0;
GO

DECLARE @ObjectName sysname,@LevelType nvarchar(16);
DECLARE marker_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT ObjectName,LevelType FROM(VALUES
 (N'WorkItem',N'TABLE'),(N'VW_WorkQueue',N'VIEW'),(N'USP_EnqueueWork',N'PROCEDURE'),
 (N'USP_ClaimWork',N'PROCEDURE'),(N'USP_CompleteWork',N'PROCEDURE'),
 (N'USP_FailWork',N'PROCEDURE'),(N'USP_GetWorkStatus',N'PROCEDURE'))v(ObjectName,LevelType);
OPEN marker_cursor; FETCH NEXT FROM marker_cursor INTO @ObjectName,@LevelType;
WHILE @@FETCH_STATUS=0
BEGIN
    EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.core.work-queue',
         @level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=@LevelType,@level1name=@ObjectName;
    FETCH NEXT FROM marker_cursor INTO @ObjectName,@LevelType;
END;
CLOSE marker_cursor; DEALLOCATE marker_cursor;
EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.core.work-queue.Version',@value=N'1.0.0';
EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.core.work-queue.DeploymentMode',@value=N'local';
GO

CREATE OR ALTER PROCEDURE dbo.USP_TbxQueueUpgrade AS BEGIN SET NOCOUNT ON; END;
GO
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.queue.upgrade',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxQueueUpgrade',@ParameterMode='NONE';
DECLARE @WorkTypeId bigint=(SELECT WorkTypeId FROM toolbelt_core.WorkType WHERE WorkTypeName='test.queue.upgrade');
INSERT toolbelt_core.WorkItem(WorkTypeId) VALUES(@WorkTypeId);
INSERT toolbelt_core.WorkItem(WorkTypeId,Status,ClaimedAtUtc,ClaimedBy,ClaimToken,CompletedAtUtc,CompletedBy)
VALUES(@WorkTypeId,'COMPLETED',DATEADD(MINUTE,-2,SYSUTCDATETIME()),N'synthetic-worker','00000000-0000-0000-0000-000000000101',DATEADD(MINUTE,-1,SYSUTCDATETIME()),N'synthetic-worker');
GO
