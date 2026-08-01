SET NOCOUNT ON;

IF (SELECT COUNT(*) FROM toolbelt_core.WorkType WHERE WorkTypeName = 'test.concurrent') <> 1
    THROW 52520, N'Parallele Registrierung erzeugte nicht genau eine Zeile.', 1;

DELETE FROM toolbelt_core.WorkType WHERE WorkTypeName = 'test.concurrent';
DROP PROCEDURE toolbelt_core.USP_TestWorkTypeConcurrent;
PRINT N'Work Type Concurrency: erfolgreich';
