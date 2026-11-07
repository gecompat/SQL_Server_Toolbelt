-- Benutzerfreigabe 2026-11-07: genau zwei einzelne EXECUTE-Rechte, nur eigene temporÃ¤re DB.
-- Session-/Owner-Marker sind technische Guards, keine eigenstÃ¤ndige AutoritÃ¤t.
SET NOCOUNT ON;
IF ISNULL(TRY_CONVERT(bit,SESSION_CONTEXT(N'Test.Constructor.AggregateRights.Approved')),0)<>1
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Test.Release.Owner'
 AND CONVERT(nvarchar(32),value)=TRY_CONVERT(nvarchar(32),SESSION_CONTEXT(N'Test.Constructor.AggregateRights.Owner')))
 THROW 53695,N'Own approved aggregate test scope required.',1;
IF USER_ID(N'ContosoAggregateCaller') IS NOT NULL OR @@TRANCOUNT<>0
 THROW 53695,N'Fresh caller and neutral session required.',2;
DECLARE @OriginalUser int=USER_ID(),@Positive int=0,@Denied int=0;
DECLARE @Profiles table(Id int PRIMARY KEY,GrantSql nvarchar(max),RevokeSql nvarchar(max),QuerySql nvarchar(max));
DECLARE @Array nvarchar(max)=N'
DECLARE @E table(G int,O int,K nvarchar(max),T nvarchar(max),V nvarchar(max),P tinyint);
INSERT @E VALUES(1,2,N''b'',N''number'',N''2'',1),(1,1,N''a'',N''string'',N''x'',1),
 (2,2,N''n'',N''null'',NULL,2),(2,1,N''j'',N''json'',N''[]'',2);
DECLARE @A table(G int,J nvarchar(max));
INSERT @A SELECT G,toolbelt_json.AGF_JsonArray(O,T,V,P) FROM @E GROUP BY G;
IF (SELECT COUNT(*) FROM @A)<>2 OR EXISTS(SELECT 1 FROM @A WHERE J IS NULL OR
 (G=1 AND CONVERT(varbinary(max),J)<>CONVERT(varbinary(max),N''["x",2]'')) OR
 (G=2 AND CONVERT(varbinary(max),J)<>CONVERT(varbinary(max),N''[[],null]'')))
 THROW 53695,N''Aggregate grouped values differ.'',3;
DELETE @E;DECLARE @Empty nvarchar(max);
SELECT @Empty=toolbelt_json.AGF_JsonArray(O,T,V,P) FROM @E;
IF @Empty IS NULL OR CONVERT(varbinary(max),@Empty)<>CONVERT(varbinary(max),N''[]'')
 THROW 53695,N''Aggregate empty value differs.'',4;';
DECLARE @Object nvarchar(max)=REPLACE(REPLACE(REPLACE(REPLACE(@Array,
 N'AGF_JsonArray(O,T,V,P)',N'AGF_JsonObject(O,K,T,V,P)'),
 N'N''["x",2]''',N'N''{"a":"x","b":2}'''),
 N'N''[[],null]''',N'N''{"j":[],"n":null}'''),
 N'CONVERT(varbinary(max),N''[]'')',N'CONVERT(varbinary(max),N''{}'')');
INSERT @Profiles VALUES
 (1,N'GRANT EXECUTE ON OBJECT::toolbelt_json.AGF_JsonArray TO [ContosoAggregateCaller];',
    N'REVOKE EXECUTE ON OBJECT::toolbelt_json.AGF_JsonArray FROM [ContosoAggregateCaller];',@Array),
 (2,N'GRANT EXECUTE ON OBJECT::toolbelt_json.AGF_JsonObject TO [ContosoAggregateCaller];',
    N'REVOKE EXECUTE ON OBJECT::toolbelt_json.AGF_JsonObject FROM [ContosoAggregateCaller];',@Object);
CREATE USER [ContosoAggregateCaller] WITHOUT LOGIN;
-- Eventuelle Engine-Defaults (z.B. CONNECT) erfassen, nicht als eigenen Grant zählen.
DECLARE @Baseline table(class tinyint,major_id int,minor_id int,grantor_principal_id int,type char(4),state char(1));
INSERT @Baseline SELECT class,major_id,minor_id,grantor_principal_id,type COLLATE DATABASE_DEFAULT,state COLLATE DATABASE_DEFAULT FROM sys.database_permissions
 WHERE grantee_principal_id=USER_ID(N'ContosoAggregateCaller');
IF EXISTS(SELECT 1 FROM @Baseline WHERE class<>0 OR type<>N'CO' OR state<>N'G')
 OR EXISTS(SELECT 1 FROM sys.database_role_members WHERE member_principal_id=USER_ID(N'ContosoAggregateCaller'))
 THROW 53695,N'Unexpected initial caller rights.',10;
BEGIN TRY
 DECLARE @I int=1,@Phase int,@Sql nvarchar(max),@Acl nvarchar(max),@Error int;
 WHILE @I<=2
 BEGIN
  SET @Phase=0;
  WHILE @Phase<=3
  BEGIN
   IF @Phase=1
   BEGIN
    SELECT @Acl=GrantSql FROM @Profiles WHERE Id=@I;EXEC sys.sp_executesql @Acl;
    IF (SELECT COUNT(*) FROM sys.database_permissions WHERE grantee_principal_id=USER_ID(N'ContosoAggregateCaller'))<>(SELECT COUNT(*)+1 FROM @Baseline)
     OR NOT EXISTS(SELECT 1 FROM sys.database_permissions WHERE grantee_principal_id=USER_ID(N'ContosoAggregateCaller')
      AND class=1 AND minor_id=0 AND permission_name=N'EXECUTE' AND state=N'G'
      AND major_id=OBJECT_ID(CASE WHEN @I=1 THEN N'toolbelt_json.AGF_JsonArray' ELSE N'toolbelt_json.AGF_JsonObject' END))
     THROW 53695,N'Exact isolated object grant required.',8;
   END;
   IF @Phase=3
   BEGIN
    SELECT @Acl=RevokeSql FROM @Profiles WHERE Id=@I;EXEC sys.sp_executesql @Acl;
    IF EXISTS(SELECT class,major_id,minor_id,grantor_principal_id,type COLLATE DATABASE_DEFAULT,state COLLATE DATABASE_DEFAULT FROM sys.database_permissions WHERE grantee_principal_id=USER_ID(N'ContosoAggregateCaller')
      EXCEPT SELECT * FROM @Baseline) OR EXISTS(SELECT * FROM @Baseline EXCEPT SELECT class,major_id,minor_id,grantor_principal_id,type COLLATE DATABASE_DEFAULT,state COLLATE DATABASE_DEFAULT FROM sys.database_permissions WHERE grantee_principal_id=USER_ID(N'ContosoAggregateCaller'))
     THROW 53695,N'Object grant remains after revoke.',9;
   END;
   SELECT @Sql=QuerySql FROM @Profiles WHERE Id=CASE WHEN @Phase=2 THEN 3-@I ELSE @I END;
   SET @Error=0;
   EXECUTE AS USER=N'ContosoAggregateCaller';
   BEGIN TRY EXEC sys.sp_executesql @Sql; END TRY
   BEGIN CATCH SET @Error=ERROR_NUMBER(); END CATCH;
   REVERT;
   IF @Phase=1
   BEGIN
    IF @Error<>0
    BEGIN
     DECLARE @Message nvarchar(2048)=CONCAT(N'Aggregate positive path failed with SQL error ',@Error,N'.');
     THROW 53695,@Message,5;
    END;
    SET @Positive+=1;
   END
   ELSE
   BEGIN
    IF @Error<>229 THROW 53695,N'Expected exact aggregate permission denial.',6;
    SET @Denied+=1;
   END;
   SET @Phase+=1;
  END;
  SET @I+=1;
 END;
 DROP USER [ContosoAggregateCaller];
 IF @Positive<>2 OR @Denied<>6 OR USER_ID()<>@OriginalUser OR @@TRANCOUNT<>0
  THROW 53695,N'Aggregate caller final balance differs.',7;
 SELECT @Positive Positive,@Denied Denied,CONVERT(int,CASE WHEN USER_ID(N'ContosoAggregateCaller') IS NULL THEN 1 ELSE 0 END) UserRemoved;
END TRY
BEGIN CATCH
 IF USER_NAME()=N'ContosoAggregateCaller' REVERT;
 THROW;
END CATCH;
