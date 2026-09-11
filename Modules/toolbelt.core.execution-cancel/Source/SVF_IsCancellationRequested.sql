SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION [toolbelt_core].[SVF_IsCancellationRequested]
(
    @ExecutionId uniqueidentifier
)
RETURNS bit
AS
BEGIN
    RETURN CONVERT(bit, CASE WHEN EXISTS
    (
        SELECT 1
        FROM toolbelt_core.TVF_ExecutionCancellationStatus(@ExecutionId)
    ) THEN 1 ELSE 0 END);
END;
GO
