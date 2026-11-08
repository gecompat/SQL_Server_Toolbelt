-- Bereits freigegebene vier Constructor-EXECUTE-Rechte, ausschließlich eigene DB.
SET NOCOUNT ON;
IF ISNULL(TRY_CONVERT(bit,SESSION_CONTEXT(N'Test.Constructor.AclProfile.Approved')),0)<>1
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Test.Release.Owner'
 AND CONVERT(nvarchar(32),value)=TRY_CONVERT(nvarchar(32),SESSION_CONTEXT(N'Test.Constructor.AclProfile.Owner')))
 THROW 53695,N'Own approved Constructor ACL fixture required.',1;
-- Katalogzugriff kann eine interne Autocommit-Transaktion öffnen; vorher skalar beobachten.
DECLARE @InitialTranCount int=@@TRANCOUNT,@InitialXactState int=XACT_STATE();
IF USER_ID(N'ContosoJsonCaller') IS NOT NULL OR @InitialTranCount<>0 OR @InitialXactState<>0
BEGIN
 DECLARE @AdmissionDiagnostic nvarchar(2048)=CONCAT(N'Fresh own Constructor caller required. trancount=',
  @InitialTranCount,N';xact=',@InitialXactState,N';callerPresent=',
  CASE WHEN USER_ID(N'ContosoJsonCaller') IS NULL THEN 0 ELSE 1 END);
 THROW 53695,@AdmissionDiagnostic,2;
END;
IF EXISTS(SELECT 1 FROM (VALUES(N'USP_JsonArray'),(N'USP_JsonObject'),(N'USP_JsonArraysByGroup'),(N'USP_JsonObjectsByGroup')) v(Name)
 WHERE OBJECT_ID(N'toolbelt_json.'+v.Name,N'P') IS NULL)
 THROW 53695,N'Genuine four public procedure slots required.',3;
CREATE USER ContosoJsonCaller WITHOUT LOGIN;
GRANT EXECUTE ON OBJECT::toolbelt_json.USP_JsonArray TO ContosoJsonCaller;
GRANT EXECUTE ON OBJECT::toolbelt_json.USP_JsonObject TO ContosoJsonCaller;
GRANT EXECUTE ON OBJECT::toolbelt_json.USP_JsonArraysByGroup TO ContosoJsonCaller;
GRANT EXECUTE ON OBJECT::toolbelt_json.USP_JsonObjectsByGroup TO ContosoJsonCaller;
IF (SELECT COUNT(*) FROM sys.database_permissions WHERE class=1 AND grantee_principal_id=USER_ID(N'ContosoJsonCaller'))<>4
 OR EXISTS(SELECT 1 FROM sys.database_permissions WHERE class=1 AND grantee_principal_id=USER_ID(N'ContosoJsonCaller')
 AND (minor_id<>0 OR type<>N'EX' OR state<>N'G' OR major_id NOT IN
 (OBJECT_ID(N'toolbelt_json.USP_JsonArray'),OBJECT_ID(N'toolbelt_json.USP_JsonObject'),OBJECT_ID(N'toolbelt_json.USP_JsonArraysByGroup'),OBJECT_ID(N'toolbelt_json.USP_JsonObjectsByGroup'))))
 THROW 53695,N'Exact nonempty four-object ACL required.',4;
SELECT principal_id,CONVERT(varchar(128),sid,2) Sid,CONVERT(varchar(32),CONVERT(varbinary(max),create_date),2) Created
 FROM sys.database_principals WHERE name=N'ContosoJsonCaller';
