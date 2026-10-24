-- Ergänzt die alte Fachfixture: eine selbst geworfene Assertion darf niemals
-- als erwarteter Produktfehler gelten. Echte FK-Verletzung in eigenen Tabellen;
-- temporäre Tabellen eignen sich nicht als verlässlicher FK-Zeuge.
SET NOCOUNT ON;
SET XACT_ABORT OFF;
DECLARE @Caught bit=0;
BEGIN TRY
 EXEC toolbelt_core.USP_RequestExecutionCancellation;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>52601 THROW;
 SET @Caught=1;
END CATCH;
IF @Caught<>1 THROW 52790,N'Cancellation: fehlender Kontext wurde nicht abgewiesen.',1;

DECLARE @Id uniqueidentifier='00000000-0000-0000-0000-000000000071';
SET @Caught=0;
BEGIN TRANSACTION;
BEGIN TRY
 EXEC toolbelt_core.USP_RequestExecutionCancellation @ExecutionId=@Id;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>52600 BEGIN ROLLBACK; THROW; END;
 SET @Caught=1;
END CATCH;
-- Der öffentliche Vertrag verspricht Ablehnung, keine committable-Garantie:
-- der vorhandene XACT_ABORT-ON-Guard darf den Caller doomed markieren.
IF @Caught<>1 OR @@TRANCOUNT<>1 OR XACT_STATE()=0
BEGIN
 IF @@TRANCOUNT<>0 ROLLBACK;
 THROW 52790,N'Cancellation: Caller-Transaktionsguard ist falsch.',2;
END;
ROLLBACK;
IF toolbelt_core.SVF_IsCancellationRequested(@Id)<>0
 THROW 52790,N'Cancellation: abgewiesener Caller hinterließ einen Eintrag.',3;

IF OBJECT_ID(N'dbo.ApiCancelParent') IS NOT NULL OR OBJECT_ID(N'dbo.ApiCancelChild') IS NOT NULL
 THROW 52790,N'Cancellation: eigene Fixture kollidiert.',4;
CREATE TABLE dbo.ApiCancelParent(Id int NOT NULL PRIMARY KEY);
CREATE TABLE dbo.ApiCancelChild(Id int NOT NULL,ParentId int NOT NULL
 REFERENCES dbo.ApiCancelParent(Id));
SET @Caught=0;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
 INSERT dbo.ApiCancelChild VALUES(1,999);
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>547 BEGIN IF @@TRANCOUNT<>0 ROLLBACK; THROW; END;
 SET @Caught=1;
END CATCH;
IF @Caught<>1 OR XACT_STATE()<>-1
BEGIN
 IF @@TRANCOUNT<>0 ROLLBACK;
 THROW 52790,N'Cancellation: kein echter uncommittable FK-Zeuge.',5;
END;
SET @Caught=0;
BEGIN TRY
 EXEC toolbelt_core.USP_RequestExecutionCancellation @ExecutionId=@Id;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>52600 BEGIN ROLLBACK; THROW; END;
 SET @Caught=1;
END CATCH;
IF @Caught<>1 OR XACT_STATE()<>-1
BEGIN
 IF @@TRANCOUNT<>0 ROLLBACK;
 THROW 52790,N'Cancellation: doomed Caller wurde nicht unverändert abgewiesen.',6;
END;
ROLLBACK;
SET XACT_ABORT OFF;
IF toolbelt_core.SVF_IsCancellationRequested(@Id)<>0
 THROW 52790,N'Cancellation: doomed Caller hinterließ einen Eintrag.',7;
DROP TABLE dbo.ApiCancelChild;
DROP TABLE dbo.ApiCancelParent;
IF @@TRANCOUNT<>0 THROW 52790,N'Cancellation: Transaktion blieb offen.',8;
