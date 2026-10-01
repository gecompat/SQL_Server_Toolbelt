:On Error exit
SET XACT_ABORT $(Abort);
BEGIN TRANSACTION;
GO
:r Uninstall.sql
