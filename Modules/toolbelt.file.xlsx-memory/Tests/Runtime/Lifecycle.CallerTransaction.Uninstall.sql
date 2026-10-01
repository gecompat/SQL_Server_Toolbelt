:On Error exit
SET XACT_ABORT ON;
BEGIN TRANSACTION;
:r ../../Deployment/Uninstall.sql
THROW 54920,N'XLSX Uninstall muss SQLCMD mit Fehler 50000 beenden.',1;
