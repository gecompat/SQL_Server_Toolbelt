SET NOCOUNT ON;
IF OBJECT_ID(N'toolbelt_core.ExecutionCancellation',N'U') IS NULL
 OR OBJECT_ID(N'toolbelt_core.TVF_ExecutionCancellationStatus',N'IF') IS NULL
 OR OBJECT_ID(N'toolbelt_core.SVF_IsCancellationRequested',N'FN') IS NULL
 OR OBJECT_ID(N'toolbelt_core.USP_RequestExecutionCancellation',N'P') IS NULL
    THROW 52709,N'Das lokale Deployment ist unvollständig.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.execution-cancel.Version' AND CONVERT(nvarchar(16),value)=N'1.0.0')
    THROW 52710,N'Die Modulversion fehlt.',1;
PRINT N'Execution Cancellation Lifecycle: erfolgreich';
