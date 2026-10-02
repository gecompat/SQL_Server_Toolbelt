:On Error exit
-- Disposable Callerfixture; Adapter prüft 50000/1 und unveränderten eigenen Callerzustand.
-- Abweichende Callerstruktur darf nicht vor dem Transaktionsguard gebunden werden.
CREATE TABLE #tbx_JsonConstructorDeployState(SyntheticForeign int NOT NULL, SyntheticOther int NOT NULL);
INSERT #tbx_JsonConstructorDeployState VALUES(73,91);
SET XACT_ABORT $(Abort);
BEGIN TRANSACTION;
GO
:r Deploy.sql
