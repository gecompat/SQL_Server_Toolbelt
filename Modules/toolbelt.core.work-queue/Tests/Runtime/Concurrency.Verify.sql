:On Error exit
SET NOCOUNT ON;
IF (SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE Status='CLAIMED')<>1
 OR (SELECT COUNT(DISTINCT ClaimToken) FROM toolbelt_core.WorkItem WHERE Status='CLAIMED')<>1
 THROW 52950,N'Konkurrierende Claims erzeugten keinen genau einmaligen Zustandsübergang.',1;
PRINT N'Work Queue Concurrency: erfolgreich';
GO
