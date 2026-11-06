-- Genau sechs freigegebene Objektrechte; ausschließlich eigene Testdatenbank.
SET NOCOUNT ON;
SET XACT_ABORT OFF;
DECLARE @Owner nvarchar(32)=(SELECT CONVERT(nvarchar(32),value) FROM sys.extended_properties
 WHERE class=0 AND name=N'Test.Release.Owner');
IF @Owner IS NULL OR LEN(@Owner)<>32 OR @Owner COLLATE Latin1_General_100_BIN2 LIKE N'%[^a-f0-9]%'
 OR DB_NAME() NOT IN(N'Toolbelt_Release_'+@Owner+N'_l',N'Toolbelt_Release_'+@Owner+N'_c') OR @@TRANCOUNT<>0
 THROW 52098,N'Eigener markierter Constructor-Testscope erforderlich.',1;
IF USER_ID(N'ContosoJsonCaller') IS NOT NULL
 THROW 52098,N'Vorhandenen Testprincipal nicht übernehmen.',2;
DECLARE @Created bit=0,@Impersonated bit=0,@Api int,@Caught bit,@Positive int=0,@Denied int=0,@Phase int=0;
-- Eigene Temp-Tabellen unter dem Prüfling; feste binäre Wertorakel.
DECLARE @Oracle nvarchar(max)=N'
CREATE TABLE #EntriesOne(Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #EntriesOne VALUES(1,N''name'',N''string'',N''Contoso''),(2,N''active'',N''boolean'',N''true'');
CREATE TABLE #Entries(GroupOrdinal int,Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #Entries VALUES(7,1,N''name'',N''string'',N''Contoso''),(7,2,N''active'',N''boolean'',N''true''),(19,1,N''name'',N''string'',N''Fabrikam'');
CREATE TABLE #Flat(JsonValue nvarchar(max) NOT NULL);
CREATE TABLE #Grouped(GroupOrdinal int NOT NULL,JsonValue nvarchar(max) NOT NULL);
CREATE TABLE #Destination(Sentinel int);
IF @Route=0 INSERT #Flat EXEC toolbelt_json.USP_JsonArray @EntriesTable=N''#EntriesOne'';
ELSE BEGIN
 EXEC toolbelt_json.USP_JsonArray @EntriesTable=N''#EntriesOne'',@ResultTable=N''#Destination'';
 DECLARE @FlatId int=OBJECT_ID(N''tempdb..#Destination'',N''U'');
 IF @FlatId IS NULL OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=@FlatId)<>1
  OR NOT EXISTS(SELECT 1 FROM tempdb.sys.columns WHERE object_id=@FlatId AND name=N''JsonValue'' AND system_type_id=231 AND max_length=-1 AND is_nullable=0 AND collation_name=N''Latin1_General_100_BIN2'')
  THROW 52098,N''Einfaches ResultTable-Schema.'',15;
 EXEC sys.sp_executesql N''INSERT #Flat SELECT JsonValue FROM #Destination;'';
END;
IF (SELECT COUNT(*) FROM #Flat)<>1 OR NOT EXISTS(SELECT 1 FROM #Flat WHERE CONVERT(varbinary(max),JsonValue)=CONVERT(varbinary(max),N''["Contoso",true]'')) THROW 52098,N''Arrayoracle.'',10;
DELETE #Flat;
IF @Route=0 INSERT #Flat EXEC toolbelt_json.USP_JsonObject @EntriesTable=N''#EntriesOne'';
ELSE BEGIN
 EXEC toolbelt_json.USP_JsonObject @EntriesTable=N''#EntriesOne'',@ResultTable=N''#Destination'';
 EXEC sys.sp_executesql N''INSERT #Flat SELECT JsonValue FROM #Destination;'';
END;
IF (SELECT COUNT(*) FROM #Flat)<>1 OR NOT EXISTS(SELECT 1 FROM #Flat WHERE CONVERT(varbinary(max),JsonValue)=CONVERT(varbinary(max),N''{"name":"Contoso","active":true}'')) THROW 52098,N''Objectoracle.'',11;
IF @Route=0 INSERT #Grouped EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N''#Entries'';
ELSE BEGIN
 EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N''#Entries'',@ResultTable=N''#Destination'';
 EXEC sys.sp_executesql N''INSERT #Grouped SELECT GroupOrdinal,JsonValue FROM #Destination;'';
END;
IF (SELECT COUNT(*) FROM #Grouped)<>2 OR NOT EXISTS(SELECT 1 FROM #Grouped WHERE GroupOrdinal=7 AND CONVERT(varbinary(max),JsonValue)=CONVERT(varbinary(max),N''["Contoso",true]'')) OR NOT EXISTS(SELECT 1 FROM #Grouped WHERE GroupOrdinal=19 AND CONVERT(varbinary(max),JsonValue)=CONVERT(varbinary(max),N''["Fabrikam"]'')) THROW 52098,N''Grouped arrayoracle.'',12;
DELETE #Grouped;
IF @Route=0 INSERT #Grouped EXEC toolbelt_json.USP_JsonObjectsByGroup @EntriesTable=N''#Entries'';
ELSE BEGIN
 EXEC toolbelt_json.USP_JsonObjectsByGroup @EntriesTable=N''#Entries'',@ResultTable=N''#Destination'';
 EXEC sys.sp_executesql N''INSERT #Grouped SELECT GroupOrdinal,JsonValue FROM #Destination;'';
END;
IF (SELECT COUNT(*) FROM #Grouped)<>2 OR NOT EXISTS(SELECT 1 FROM #Grouped WHERE GroupOrdinal=7 AND CONVERT(varbinary(max),JsonValue)=CONVERT(varbinary(max),N''{"name":"Contoso","active":true}'')) OR NOT EXISTS(SELECT 1 FROM #Grouped WHERE GroupOrdinal=19 AND CONVERT(varbinary(max),JsonValue)=CONVERT(varbinary(max),N''{"name":"Fabrikam"}'')) THROW 52098,N''Grouped objectoracle.'',13;
IF @Route=1
BEGIN
 DECLARE @Id int=OBJECT_ID(N''tempdb..#Destination'',N''U'');
 IF @Id IS NULL OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=@Id)<>2
  OR NOT EXISTS(SELECT 1 FROM tempdb.sys.columns WHERE object_id=@Id AND name=N''GroupOrdinal'' AND system_type_id=56 AND max_length=4 AND is_nullable=0)
  OR NOT EXISTS(SELECT 1 FROM tempdb.sys.columns WHERE object_id=@Id AND name=N''JsonValue'' AND system_type_id=231 AND max_length=-1 AND is_nullable=0 AND collation_name=N''Latin1_General_100_BIN2'')
  OR (SELECT column_id FROM tempdb.sys.columns WHERE object_id=@Id AND name=N''GroupOrdinal'')>=(SELECT column_id FROM tempdb.sys.columns WHERE object_id=@Id AND name=N''JsonValue'')
  THROW 52098,N''Gruppiertes ResultTable-Schema.'',14;
END;
';
BEGIN TRY
 CREATE USER ContosoJsonCaller WITHOUT LOGIN; SET @Created=1;
 -- Ohne Objektfreigaben muss jede öffentliche API bereits vor ihrem Body scheitern.
 EXECUTE AS USER=N'ContosoJsonCaller'; SET @Impersonated=1;
 SET @Api=0;
 WHILE @Api<4
 BEGIN
  SET @Caught=0;
  BEGIN TRY
   IF @Api=0 EXEC toolbelt_json.USP_JsonArray @Hilfe=1;
   IF @Api=1 EXEC toolbelt_json.USP_JsonObject @Hilfe=1;
   IF @Api=2 EXEC toolbelt_json.USP_JsonArraysByGroup @Hilfe=1;
   IF @Api=3 EXEC toolbelt_json.USP_JsonObjectsByGroup @Hilfe=1;
  END TRY
  BEGIN CATCH IF ERROR_NUMBER()<>229 THROW; SET @Caught=1; SET @Denied+=1; END CATCH;
  IF @Caught<>1 THROW 52098,N'API ohne EXECUTE zugänglich.',3;
  SET @Api+=1;
 END;
 REVERT; SET @Impersonated=0;
 GRANT EXECUTE ON OBJECT::toolbelt_json.USP_JsonArray TO ContosoJsonCaller;
 GRANT EXECUTE ON OBJECT::toolbelt_json.USP_JsonObject TO ContosoJsonCaller;
 GRANT EXECUTE ON OBJECT::toolbelt_json.USP_JsonArraysByGroup TO ContosoJsonCaller;
 GRANT EXECUTE ON OBJECT::toolbelt_json.USP_JsonObjectsByGroup TO ContosoJsonCaller;
 GRANT VIEW DEFINITION ON OBJECT::toolbelt_core.USP_PrepareResultTable TO ContosoJsonCaller;
 WHILE @Phase<2
 BEGIN
  IF @Phase=1 GRANT EXECUTE ON OBJECT::toolbelt_core.USP_PrepareResultTable TO ContosoJsonCaller;
  EXECUTE AS USER=N'ContosoJsonCaller'; SET @Impersonated=1;
  IF USER_NAME()<>N'ContosoJsonCaller' OR ISNULL(IS_MEMBER(N'db_owner'),0)<>0
   OR ISNULL(IS_MEMBER(N'db_datareader'),0)<>0 OR ISNULL(IS_MEMBER(N'db_datawriter'),0)<>0
   OR ISNULL(IS_MEMBER(N'db_ddladmin'),0)<>0 OR ISNULL(IS_MEMBER(N'db_securityadmin'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'EXECUTE'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_json',N'SCHEMA',N'EXECUTE'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_json.USP_JsonConstructInternal',N'OBJECT',N'EXECUTE'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_json.FT_JsonEntryEvaluateInternal',N'OBJECT',N'SELECT'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core.USP_PrepareResultTable',N'OBJECT',N'VIEW DEFINITION'),0)<>1
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core.USP_PrepareResultTable',N'OBJECT',N'EXECUTE'),0)<>@Phase
   THROW 52098,N'Breite oder interne Callerrechte.',4;
  EXEC sys.sp_executesql @Oracle,N'@Route int',@Route=0; SET @Positive+=4;
  IF @Phase=1 BEGIN EXEC sys.sp_executesql @Oracle,N'@Route int',@Route=1; SET @Positive+=4; END;
  SET @Caught=0;
  BEGIN TRY EXEC toolbelt_json.USP_JsonConstructInternal @Hilfe=1; END TRY
  BEGIN CATCH IF ERROR_NUMBER()<>229 THROW; SET @Caught=1; SET @Denied+=1; END CATCH;
  IF @Caught<>1 THROW 52098,N'Interner Einstieg offen.',5;
  SET @Caught=0;
  BEGIN TRY DECLARE @BridgeCount int; SELECT @BridgeCount=COUNT(*) FROM toolbelt_json.FT_JsonEntryEvaluateInternal(0,NULL,N'string',N'Contoso',0,0); END TRY
  BEGIN CATCH IF ERROR_NUMBER()<>229 THROW; SET @Caught=1; SET @Denied+=1; END CATCH;
  IF @Caught<>1 THROW 52098,N'Interne Bridge offen.',8;
  REVERT; SET @Impersonated=0; SET @Phase+=1;
 END;
 -- Jeder öffentliche EXECUTE-Grant wird separat zurückgenommen und erneut geprüft.
 SET @Api=0;
 WHILE @Api<4
 BEGIN
  IF @Api=0 REVOKE EXECUTE ON OBJECT::toolbelt_json.USP_JsonArray FROM ContosoJsonCaller;
  IF @Api=1 REVOKE EXECUTE ON OBJECT::toolbelt_json.USP_JsonObject FROM ContosoJsonCaller;
  IF @Api=2 REVOKE EXECUTE ON OBJECT::toolbelt_json.USP_JsonArraysByGroup FROM ContosoJsonCaller;
  IF @Api=3 REVOKE EXECUTE ON OBJECT::toolbelt_json.USP_JsonObjectsByGroup FROM ContosoJsonCaller;
  EXECUTE AS USER=N'ContosoJsonCaller'; SET @Impersonated=1; SET @Caught=0;
  BEGIN TRY
   IF @Api=0 EXEC toolbelt_json.USP_JsonArray @Hilfe=1;
   IF @Api=1 EXEC toolbelt_json.USP_JsonObject @Hilfe=1;
   IF @Api=2 EXEC toolbelt_json.USP_JsonArraysByGroup @Hilfe=1;
   IF @Api=3 EXEC toolbelt_json.USP_JsonObjectsByGroup @Hilfe=1;
  END TRY
  BEGIN CATCH IF ERROR_NUMBER()<>229 THROW; SET @Caught=1; SET @Denied+=1; END CATCH;
  IF @Caught<>1 THROW 52098,N'Widerruf wirkungslos.',7;
  REVERT; SET @Impersonated=0; SET @Api+=1;
 END;
 DROP USER ContosoJsonCaller; SET @Created=0;
END TRY
BEGIN CATCH
 IF @Impersonated=1 REVERT;
 IF @Created=1 DROP USER ContosoJsonCaller;
 THROW;
END CATCH;
-- Den Sitzungszustand ohne Katalogzugriff erfassen: dessen interne Autocommit-
-- Transaktion kann im selben Ausdruck XACT_STATE=1 bei @@TRANCOUNT=0 liefern.
DECLARE @FinalTranCount int=@@TRANCOUNT,@FinalXactState int=XACT_STATE();
IF @Positive<>12 OR @Denied<>12 OR USER_ID(N'ContosoJsonCaller') IS NOT NULL OR @FinalTranCount<>0 OR @FinalXactState<>0
BEGIN
 DECLARE @Diagnostic nvarchar(2048)=CONCAT(N'Constructor-Rechtefixture unvollständig: positive=',@Positive,
  N';denied=',@Denied,N';trancount=',@FinalTranCount,N';xact=',@FinalXactState,
  N';userAbsent=',CASE WHEN USER_ID(N'ContosoJsonCaller') IS NULL THEN 1 ELSE 0 END);
 THROW 52098,@Diagnostic,6;
END;
SELECT 'CONSTRUCTOR_CALLER_PASS' Witness,@Positive PositiveProfiles,@Denied Denials;
