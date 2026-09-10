SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER VIEW [toolbelt_core].[VW_WorkQueueBarrierBlockers]
AS
SELECT b.BarrierWorkItemId,b.BarrierEpoch,b.BlockingWorkItemId,b.BlockingClaimGeneration,b.CapturedAtUtc,
       CONVERT(bit,CASE WHEN wi.Status='CLAIMED' AND wi.ClaimGeneration=b.BlockingClaimGeneration THEN 0 ELSE 1 END) AS IsResolved
FROM toolbelt_core.WorkQueueBarrierBlocker b
JOIN toolbelt_core.WorkItem wi ON wi.WorkItemId=b.BlockingWorkItemId;
GO
