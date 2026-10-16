SET QUOTED_IDENTIFIER ON;
-- Ausschließlich eigene disposable Testdatenbank; keine Serverrechte.
SET NOCOUNT ON;
IF OBJECT_ID(N'toolbelt_core.TR_TbxSecurityFixtureWorkTypes',N'TR') IS NOT NULL DISABLE TRIGGER toolbelt_core.TR_TbxSecurityFixtureWorkTypes ON toolbelt_core.WorkType;
GO
CREATE OR ALTER PROCEDURE dbo.USP_SecurityNoop AS RETURN 0;
GO
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='security.noop',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_SecurityNoop';
GO
CREATE USER SecurityProducer WITHOUT LOGIN;
CREATE USER SecurityWorker WITHOUT LOGIN;
CREATE ROLE SecurityAllowRole;
CREATE ROLE SecurityDenyRole;
ALTER ROLE SecurityAllowRole ADD MEMBER SecurityProducer;
ALTER ROLE SecurityDenyRole ADD MEMBER SecurityProducer;
GRANT EXECUTE ON toolbelt_core.USP_SetWorkTypePermission TO SecurityProducer;
GRANT EXECUTE ON toolbelt_core.USP_ResolveWorkType TO SecurityProducer;
GRANT VIEW DEFINITION ON dbo.USP_SecurityNoop TO SecurityProducer;
GRANT SELECT ON toolbelt_core.TVF_WorkTypeAuthorization TO SecurityProducer,SecurityWorker;
-- Die direkte Entscheidungsprobe braucht Leserechte wegen durchbrochener
-- Ownership-Chain zu Katalogviews nicht; keine Schreibrechte auf die Policy.
GO
DECLARE @id bigint=(SELECT WorkTypeId FROM toolbelt_core.WorkType WHERE WorkTypeName='security.noop');
IF (SELECT IsAllowed FROM toolbelt_core.TVF_WorkTypeAuthorization(@id,'ENQUEUE'))<>0
 THROW 52990,N'Leere Policy muss auch dbo abweisen.',1;
EXEC toolbelt_core.USP_SetWorkTypePermission @Hilfe=1;
IF EXISTS(SELECT 1 FROM toolbelt_core.WorkTypePermission WHERE WorkTypeId=@id)
 THROW 52990,N'Help hat Policy verändert.',1;
EXEC toolbelt_core.USP_SetWorkTypePermission 'security.noop',N'SecurityAllowRole','ENQUEUE','ALLOW';
EXECUTE AS USER='SecurityProducer';
IF (SELECT IsAllowed FROM toolbelt_core.TVF_WorkTypeAuthorization(@id,'ENQUEUE'))<>1
 BEGIN REVERT; THROW 52990,N'Rollenfreigabe fehlt.',1; END;
IF (SELECT IsAllowed FROM toolbelt_core.TVF_WorkTypeAuthorization(@id,'CLAIM'))<>0
 BEGIN REVERT; THROW 52990,N'Aktionen sind nicht getrennt.',1; END;
BEGIN TRY
 EXEC toolbelt_core.USP_SetWorkTypePermission 'security.noop',N'SecurityProducer','CLAIM','ALLOW';

 REVERT; THROW 52990,N'EXECUTE allein darf keine Policyverwaltung erlauben.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>51591 BEGIN REVERT; THROW; END;
END CATCH;
REVERT;
EXEC toolbelt_core.USP_SetWorkTypePermission 'security.noop',N'SecurityDenyRole','ENQUEUE','DENY';
EXECUTE AS USER='SecurityProducer';
IF (SELECT IsAllowed FROM toolbelt_core.TVF_WorkTypeAuthorization(@id,'ENQUEUE'))<>0
 BEGIN REVERT; THROW 52990,N'DENY muss Rollen-ALLOW überstimmen.',1; END;
REVERT;
EXEC toolbelt_core.USP_SetWorkTypePermission 'security.noop',N'SecurityDenyRole','ENQUEUE','REMOVE';
EXEC toolbelt_core.USP_SetWorkTypePermission 'security.noop',N'SecurityProducer','CLAIM','ALLOW';
EXECUTE AS USER='SecurityProducer';
EXEC toolbelt_core.USP_ResolveWorkType @WorkTypeName='security.noop',@RequireExecutableByCaller=0,@RequiredPermission='CLAIM',@SuppressResult=1 WITH RESULT SETS NONE;
BEGIN TRY
 EXEC toolbelt_core.USP_ResolveWorkType @WorkTypeName='security.noop',@RequireExecutableByCaller=1,@RequiredPermission='CLAIM',@SuppressResult=1;
 REVERT; THROW 52990,N'Resolverdelegation ersetzte Handler-EXECUTE.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>51534 BEGIN REVERT; THROW; END;
END CATCH;
REVERT;

-- Registrierung muss alte Freigaben invalidieren, ohne sie heimlich zu löschen.
UPDATE toolbelt_core.WorkType SET Description=N'new revision' WHERE WorkTypeId=@id;
EXECUTE AS USER='SecurityProducer';
IF (SELECT IsAllowed FROM toolbelt_core.TVF_WorkTypeAuthorization(@id,'CLAIM'))<>0
 BEGIN REVERT; THROW 52990,N'Veraltete Work-Type-Freigabe wurde übernommen.',1; END;
REVERT;
EXEC toolbelt_core.USP_SetWorkTypePermission 'security.noop',N'SecurityWorker','CLAIM','ALLOW';
DROP USER SecurityWorker;
CREATE USER SecurityWorker WITHOUT LOGIN;
GRANT SELECT ON toolbelt_core.TVF_WorkTypeAuthorization TO SecurityWorker;
EXECUTE AS USER='SecurityWorker';
IF (SELECT IsAllowed FROM toolbelt_core.TVF_WorkTypeAuthorization(@id,'CLAIM'))<>0
 BEGIN REVERT; THROW 52990,N'Neuer Principal hat alte Freigabe geerbt.',1; END;
REVERT;
-- Callerrollback muss die eigene Policyänderung vollständig zurücknehmen.
BEGIN TRANSACTION;
EXEC toolbelt_core.USP_SetWorkTypePermission 'security.noop',N'SecurityProducer','CLAIM','ALLOW';
ROLLBACK;
EXECUTE AS USER='SecurityProducer';
IF (SELECT IsAllowed FROM toolbelt_core.TVF_WorkTypeAuthorization(@id,'CLAIM'))<>0
 BEGIN REVERT; THROW 52990,N'Callerrollback hat Policy nicht restauriert.',1; END;
REVERT;
DELETE toolbelt_core.WorkTypePermission WHERE WorkTypeId=@id;
DELETE toolbelt_core.WorkType WHERE WorkTypeId=@id;
ALTER ROLE SecurityAllowRole DROP MEMBER SecurityProducer;
ALTER ROLE SecurityDenyRole DROP MEMBER SecurityProducer;
DROP USER SecurityProducer;
DROP USER SecurityWorker;
DROP ROLE SecurityAllowRole;
DROP ROLE SecurityDenyRole;
DROP PROCEDURE dbo.USP_SecurityNoop;
IF OBJECT_ID(N'toolbelt_core.TR_TbxSecurityFixtureWorkTypes',N'TR') IS NOT NULL ENABLE TRIGGER toolbelt_core.TR_TbxSecurityFixtureWorkTypes ON toolbelt_core.WorkType;
PRINT N'Work-Type-Autorisierungsvertrag: erfolgreich';
GO
