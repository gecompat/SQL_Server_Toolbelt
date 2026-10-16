SET QUOTED_IDENTIFIER ON;
-- Ausschließlich disposable Tests: explizite dbo-Policy für alte Fachfixtures.
-- Kein Deploymentinclude. Neue Sicherheits-Negativfälle deaktivieren diesen
-- Trigger; Anwendungsprincipals erhalten hier niemals Freigaben.
SET NOCOUNT ON;
GO
CREATE OR ALTER TRIGGER toolbelt_core.TR_TbxSecurityFixtureWorkTypes
ON toolbelt_core.WorkType AFTER INSERT,UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 DELETE p FROM toolbelt_core.WorkTypePermission p JOIN inserted i ON i.WorkTypeId=p.WorkTypeId WHERE p.PrincipalId=1;
 INSERT toolbelt_core.WorkTypePermission
 (WorkTypeId,PrincipalId,PermissionName,PrincipalSid,PrincipalCreatedAt,WorkTypeVersion,IsDenied)
 SELECT i.WorkTypeId,d.principal_id,a.PermissionName,d.sid,d.create_date,CONVERT(binary(8),i.RowVersion),0
 FROM inserted i CROSS JOIN sys.database_principals d
 CROSS JOIN (VALUES('ENQUEUE'),('CLAIM'),('EXECUTE_NEW_SESSION'))a(PermissionName)
 WHERE d.principal_id=1;
END;
GO
