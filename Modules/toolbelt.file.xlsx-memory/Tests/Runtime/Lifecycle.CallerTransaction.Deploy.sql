:On Error exit
SET XACT_ABORT ON;
BEGIN TRANSACTION;
:r ../../Deployment/Deploy.sql
THROW 54920,N'XLSX Deployment muss SQLCMD mit Fehler 50000 beenden.',1;
