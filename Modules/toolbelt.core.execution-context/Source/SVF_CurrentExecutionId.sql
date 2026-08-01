SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION [toolbelt_core].[SVF_CurrentExecutionId]()
RETURNS uniqueidentifier
AS
BEGIN
    DECLARE @ExecutionId uniqueidentifier;
    SELECT @ExecutionId = c.ExecutionId
    FROM toolbelt_core.TVF_CurrentExecutionContext() AS c;
    RETURN @ExecutionId;
END;
GO
