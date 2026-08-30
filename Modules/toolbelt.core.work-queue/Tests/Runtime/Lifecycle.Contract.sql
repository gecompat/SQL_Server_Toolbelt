:On Error exit
SET NOCOUNT ON;
IF OBJECT_ID(N'toolbelt_core.WorkItem',N'U') IS NULL OR OBJECT_ID(N'toolbelt_core.VW_WorkQueue',N'V') IS NULL
 OR OBJECT_ID(N'toolbelt_core.USP_EnqueueWork',N'P') IS NULL OR OBJECT_ID(N'toolbelt_core.USP_ClaimWork',N'P') IS NULL
 OR OBJECT_ID(N'toolbelt_core.USP_RenewWorkLease',N'P') IS NULL OR OBJECT_ID(N'toolbelt_core.USP_RecoverExpiredWork',N'P') IS NULL
 OR OBJECT_ID(N'toolbelt_core.USP_CompleteWork',N'P') IS NULL OR OBJECT_ID(N'toolbelt_core.USP_FailWork',N'P') IS NULL
 OR OBJECT_ID(N'toolbelt_core.USP_GetWorkStatus',N'P') IS NULL THROW 52930,N'Der Work-Queue-Objektbestand ist unvollständig.',1;
IF NOT EXISTS(SELECT 1 FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID(N'toolbelt_core.WorkItem') AND name=N'PK_WorkItem')
 OR NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE parent_object_id=OBJECT_ID(N'toolbelt_core.WorkItem') AND name=N'FK_WorkItem_WorkType')
 OR NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'toolbelt_core.WorkItem') AND name=N'CK_WorkItem_StateMetadata')
 OR NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'toolbelt_core.WorkItem') AND name=N'CK_WorkItem_RecoveryMetadata')
 OR NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'toolbelt_core.WorkItem') AND name=N'IX_WorkItem_Status_WorkItemId')
 OR NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'toolbelt_core.WorkItem') AND name=N'IX_WorkItem_Status_LeaseUntilUtc_WorkItemId') THROW 52931,N'Benannte Tabellenartefakte fehlen.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.work-queue.Version' AND CONVERT(nvarchar(64),value)=N'1.1.0') THROW 52932,N'Der Modulmarker fehlt.',1;
IF EXISTS
(
 SELECT 1 FROM (VALUES(N'WorkItem'),(N'VW_WorkQueue'),(N'USP_EnqueueWork'),(N'USP_ClaimWork'),(N'USP_RenewWorkLease'),(N'USP_RecoverExpiredWork'),(N'USP_CompleteWork'),(N'USP_FailWork'),(N'USP_GetWorkStatus'))x(ObjectName)
 WHERE NOT EXISTS(SELECT 1 FROM sys.extended_properties ep WHERE ep.class=1 AND ep.major_id=OBJECT_ID(N'toolbelt_core.'+QUOTENAME(x.ObjectName)) AND ep.minor_id=0 AND ep.name=N'Toolbelt.ModuleId' AND CONVERT(nvarchar(256),ep.value)=N'toolbelt.core.work-queue')
) THROW 52933,N'Objektmarker fehlen.',1;
PRINT N'Work Queue Lifecycle: erfolgreich';
GO
