:on error exit
SET NOCOUNT ON;

IF (SELECT COUNT(*) FROM toolbelt_core.SecondSessionConcurrencyEvidence) <> 4
    THROW 52650, N'Es wurden nicht genau vier parallele Remote-Aufrufe persistiert.', 1;
IF (SELECT COUNT(DISTINCT WorkerId) FROM toolbelt_core.SecondSessionConcurrencyEvidence) <> 4
    THROW 52651, N'Die parallelen Worker-IDs sind nicht vollständig.', 1;
IF EXISTS
(
    SELECT 1
    FROM toolbelt_core.SecondSessionConcurrencyEvidence
    WHERE RemoteSessionId = CallerSessionId
)
    THROW 52652, N'Mindestens ein paralleler Aufruf lief nicht in einer zweiten Session.', 1;
IF (SELECT COUNT(DISTINCT RemoteSessionId) FROM toolbelt_core.SecondSessionConcurrencyEvidence) < 2
    THROW 52653, N'Die parallelen Aufrufe wurden nicht gleichzeitig über getrennte Remote-Sessions bedient.', 1;

DELETE FROM toolbelt_core.WorkType
WHERE WorkTypeName = 'test.second-session.concurrent';
DROP PROCEDURE toolbelt_core.USP_TestSecondSessionConcurrent;
DROP TABLE toolbelt_core.SecondSessionConcurrencyEvidence;

PRINT N'Second Session Concurrency: erfolgreich';
GO
