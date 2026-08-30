SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW [toolbelt_core].[VW_WorkQueue]
AS
    SELECT
          wi.WorkItemId
        , wt.WorkTypeName
        , wi.Status
        , wi.EnqueuedAtUtc
        , wi.EnqueuedBy
        , wi.ClaimedAtUtc
        , wi.ClaimedBy
        , wi.CompletedAtUtc
        , wi.CompletedBy
        , wi.FailedAtUtc
        , wi.FailedBy
        , wi.FailureCode
        , wi.FailureMessage
        , CONVERT(binary(8), wi.RowVersion) AS RowVersion
    FROM toolbelt_core.WorkItem AS wi
    JOIN toolbelt_core.WorkType AS wt
      ON wt.WorkTypeId = wi.WorkTypeId;
GO
