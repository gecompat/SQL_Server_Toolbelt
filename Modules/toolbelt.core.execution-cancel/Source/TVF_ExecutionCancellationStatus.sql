SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION [toolbelt_core].[TVF_ExecutionCancellationStatus]
(
    @ExecutionId uniqueidentifier
)
RETURNS TABLE
AS
RETURN
(
    SELECT
          c.ExecutionId
        , CAST(1 AS bit) AS IsCancellationRequested
        , c.RequestedAtUtc
    FROM toolbelt_core.ExecutionCancellation AS c
    WHERE c.ExecutionId = @ExecutionId
);
GO
