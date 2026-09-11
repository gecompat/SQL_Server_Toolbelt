SET NOCOUNT ON;
DECLARE @ExecutionId uniqueidentifier='00000000-0000-0000-0000-000000000021';
IF (SELECT COUNT(*) FROM toolbelt_core.TVF_ExecutionCancellationStatus(@ExecutionId))<>1
    THROW 52708,N'Parallele Anforderungen müssen genau eine Statuszeile erzeugen.',1;
PRINT N'Execution Cancellation Concurrency: erfolgreich';
