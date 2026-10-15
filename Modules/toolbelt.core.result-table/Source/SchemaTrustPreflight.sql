-- SQLCMD-Preflightfragment, keine dauerhafte Mutation und kein Batchseparator.
-- Nur dbo sowie explizit vertrauenswürdige DBowner-/Installerrollen dürfen
-- das gemeinsame Schema kontrollieren. Fehlende Metadatensicht ist kein PASS.
IF ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1
    THROW 51032,N'Für die Schematrustprüfung fehlt vollständige Datenbank-Metadatensicht.',2;
IF SCHEMA_ID(N'toolbelt_core') IS NOT NULL
   AND (SELECT principal_id FROM sys.schemas WHERE name=N'toolbelt_core')<>1
    THROW 51032,N'Der Owner von toolbelt_core muss dbo sein; kein automatischer Ownertransfer.',2;

DECLARE @tbx_TrustedSchemaPrincipals TABLE(PrincipalId int PRIMARY KEY);
;WITH Trusted AS
(
    SELECT principal_id FROM sys.database_principals
    WHERE principal_id=1 OR (type='R' AND name IN(N'db_owner',N'toolbelt_core_installer'))
    UNION ALL
    SELECT m.member_principal_id FROM sys.database_role_members m JOIN Trusted t ON t.principal_id=m.role_principal_id
)
INSERT @tbx_TrustedSchemaPrincipals SELECT DISTINCT principal_id FROM Trusted OPTION(MAXRECURSION 32);

IF EXISTS
(
    SELECT 1 FROM sys.database_permissions p
    WHERE p.state IN('G','W')
      AND NOT EXISTS(SELECT 1 FROM @tbx_TrustedSchemaPrincipals t WHERE t.PrincipalId=p.grantee_principal_id)
      AND
      (
        (p.class=3 AND p.major_id=SCHEMA_ID(N'toolbelt_core') AND p.permission_name IN(N'ALTER',N'CONTROL',N'TAKE OWNERSHIP'))
        OR (p.class=0 AND p.permission_name IN(N'CONTROL',N'ALTER ANY SCHEMA'))
        OR (p.class=1 AND p.major_id=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable') AND p.permission_name IN(N'ALTER',N'CONTROL',N'TAKE OWNERSHIP'))
      )
)
    THROW 51032,N'Nicht freigegebene Principals besitzen Schema- oder Helperkontrollrechte.',2;

-- Feste Rollenrechte stehen nicht vollständig in sys.database_permissions.
IF EXISTS
(
    SELECT 1 FROM sys.database_role_members m JOIN sys.database_principals r ON r.principal_id=m.role_principal_id
    WHERE r.name=N'db_ddladmin'
      AND NOT EXISTS(SELECT 1 FROM @tbx_TrustedSchemaPrincipals t WHERE t.PrincipalId=m.member_principal_id)
)
    THROW 51032,N'Nicht freigegebene DDL-Administrationsmitgliedschaft verhindert die Schematrustfreigabe.',2;
