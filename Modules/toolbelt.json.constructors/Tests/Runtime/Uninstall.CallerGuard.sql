:On Error exit
-- Disposable Callerfixture; Adapter prüft 50000/1 und unveränderten eigenen Callerzustand.
SET XACT_ABORT $(Abort);
BEGIN TRANSACTION;
GO
:r Uninstall.sql
