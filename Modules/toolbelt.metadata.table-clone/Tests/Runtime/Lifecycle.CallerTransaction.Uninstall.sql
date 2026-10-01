:On Error exit
SET XACT_ABORT ON;
BEGIN TRANSACTION;
:r ../../Deployment/Uninstall.sql
THROW 54920,N'Lifecycle darf nach Caller-Tx-Ablehnung nicht fortfahren.',21;
