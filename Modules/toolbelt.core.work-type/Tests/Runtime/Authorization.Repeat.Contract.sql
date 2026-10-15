-- Aus Modules/toolbelt.core.work-type/Deployment ausführen.
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO
CREATE OR ALTER PROCEDURE dbo.USP_SecurityRepeatNoop AS RETURN 0;
GO
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='security.repeat',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_SecurityRepeatNoop';
EXEC toolbelt_core.USP_SetWorkTypePermission 'security.repeat',N'dbo','ENQUEUE','ALLOW';
SELECT p.* INTO #SecurityPermissionSnapshot FROM toolbelt_core.WorkTypePermission p
JOIN toolbelt_core.WorkType w ON w.WorkTypeId=p.WorkTypeId WHERE w.WorkTypeName='security.repeat';
GO
:r Deploy.sql
GO
IF EXISTS(SELECT * FROM #SecurityPermissionSnapshot EXCEPT SELECT p.* FROM toolbelt_core.WorkTypePermission p
 JOIN toolbelt_core.WorkType w ON w.WorkTypeId=p.WorkTypeId WHERE w.WorkTypeName='security.repeat')
 OR EXISTS(SELECT p.* FROM toolbelt_core.WorkTypePermission p JOIN toolbelt_core.WorkType w ON w.WorkTypeId=p.WorkTypeId
 WHERE w.WorkTypeName='security.repeat' EXCEPT SELECT * FROM #SecurityPermissionSnapshot)
 THROW 52990,N'Repeat hat bestehende Policy verändert.',1;
DELETE toolbelt_core.WorkType WHERE WorkTypeName='security.repeat';
IF EXISTS(SELECT 1 FROM toolbelt_core.WorkTypePermission p JOIN #SecurityPermissionSnapshot s ON s.WorkTypeId=p.WorkTypeId)
 THROW 52990,N'Removal hat Policy verwaist.',1;
DROP PROCEDURE dbo.USP_SecurityRepeatNoop;
DROP TABLE #SecurityPermissionSnapshot;
PRINT N'Policy Repeat und Removal: erfolgreich';
GO
