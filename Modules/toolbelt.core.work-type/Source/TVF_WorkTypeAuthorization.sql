-- Interne inline TVF: exakt eine fail-closed Entscheidung im echten Callertoken.
-- Kein Actor-/Loginparameter und kein EXECUTE-AS-Wechsel.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER FUNCTION toolbelt_core.TVF_WorkTypeAuthorization
(@WorkTypeId bigint,@PermissionName varchar(32))
RETURNS TABLE
AS RETURN
(
    SELECT IsAllowed=CONVERT(bit,CASE
        WHEN COALESCE(MAX(CONVERT(int,p.IsDenied)),1)=0 THEN 1 ELSE 0 END)
    FROM toolbelt_core.WorkTypePermission p
    JOIN toolbelt_core.WorkType w ON w.WorkTypeId=p.WorkTypeId
        AND CONVERT(binary(8),w.RowVersion)=p.WorkTypeVersion
    JOIN sys.database_principals d ON d.principal_id=p.PrincipalId
        AND d.sid=p.PrincipalSid AND d.create_date=p.PrincipalCreatedAt
    JOIN sys.user_token t ON t.principal_id=d.principal_id AND t.sid=d.sid
    WHERE p.WorkTypeId=@WorkTypeId
        AND p.PermissionName=@PermissionName COLLATE Latin1_General_100_BIN2
);
GO
