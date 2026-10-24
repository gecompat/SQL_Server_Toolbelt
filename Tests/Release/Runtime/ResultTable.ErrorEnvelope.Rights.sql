SET NOCOUNT ON;
SET XACT_ABORT OFF;

-- Ausschliesslich der vorhandene API-Harness mit eigener disposable Datenbank.
IF @@TRANCOUNT<>0 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WITH (NOLOCK)
 WHERE class=0 AND name=N'Test.Release.Owner' AND LEN(CONVERT(nvarchar(32),value))=32)
 THROW 52096,N'Der eigene markierte Datenbank-/Transaktionsscope fehlt.',1;
IF USER_ID(N'ContosoTableCaller') IS NOT NULL OR OBJECT_ID(N'dbo.ContosoRightsReference') IS NOT NULL
 THROW 52096,N'Vorhandene Principals oder Referenzobjekte werden nicht uebernommen.',2;

DECLARE @Shape nvarchar(max)=N'
 IF OBJECT_ID(N''tempdb..#ContosoRightsTarget'')<>@Before
  OR (SELECT COUNT(*) FROM tempdb.sys.columns WITH (NOLOCK) WHERE object_id=@Before)<>3
  OR (SELECT COUNT(*) FROM tempdb.sys.columns WITH (NOLOCK) WHERE object_id=@Before AND
   ((column_id=1 AND name=N''Id'' AND system_type_id=TYPE_ID(N''int'') AND is_nullable=0)
    OR (column_id=2 AND name=N''Label'' AND system_type_id=TYPE_ID(N''nvarchar'') AND max_length=32 AND is_nullable=1 AND collation_name=N''Latin1_General_100_BIN2'')
    OR (column_id=3 AND name=N''Amount'' AND system_type_id=TYPE_ID(N''decimal'') AND precision=12 AND scale=4 AND is_nullable=1)))<>3
  THROW 52096,N''Temp-Identitaet oder feste Schemametadaten verletzt.'',3;';
DECLARE @Profiles table(Id int PRIMARY KEY,Helper bit,Envelope bit,ViewDefinition bit,SqlText nvarchar(max));
INSERT @Profiles VALUES
(1,1,0,0,N'
 CREATE TABLE #ContosoRightsLike(Id int NOT NULL,Label nvarchar(16) COLLATE Latin1_General_100_BIN2 NULL,Amount decimal(12,4) NULL);
 INSERT #ContosoRightsLike VALUES(1,N''Contoso'',12.3400);
 CREATE TABLE #ContosoRightsTarget(Dummy int NULL);
 DECLARE @Before int=OBJECT_ID(N''tempdb..#ContosoRightsTarget''),@Rc int;
 EXEC @Rc=toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=N''#ContosoRightsTarget'',@LikeTable=N''#ContosoRightsLike'';
 IF @Rc<>0 OR EXISTS(SELECT 1 FROM #ContosoRightsTarget WITH (NOLOCK))
  THROW 52096,N''Helper-Temp-Ausgabe oder Returncode verletzt.'',4;'
 +@Shape+N'
 -- Nach dem Schemaumbau die neue Spaltenbindung separat kompilieren.
 EXEC sys.sp_executesql N''INSERT #ContosoRightsTarget(Id,Label,Amount) VALUES(7,N''''Fabrikam'''',45.6700);'';
 EXEC @Rc=toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=N''#ContosoRightsTarget'',@LikeTable=N''#ContosoRightsLike'',@KeepData=1;
 IF @Rc<>0 OR OBJECT_ID(N''tempdb..#ContosoRightsTarget'')<>@Before
  OR (SELECT COUNT(*) FROM #ContosoRightsTarget WITH (NOLOCK))<>1
  THROW 52096,N''KeepData-Wertorakel verletzt.'',5;
 EXEC sys.sp_executesql N''IF NOT EXISTS(SELECT 1 FROM #ContosoRightsTarget WITH (NOLOCK) WHERE Id=7 AND Label=N''''Fabrikam'''' AND Amount=45.6700)
  THROW 52096,N''''KeepData-Zeilenwert verletzt.'''',5;'';
 EXEC @Rc=toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=N''#ContosoRightsTarget'',@LikeTable=N''#ContosoRightsLike'',@KeepData=0;
 IF @Rc<>0 OR OBJECT_ID(N''tempdb..#ContosoRightsTarget'')<>@Before OR EXISTS(SELECT 1 FROM #ContosoRightsTarget WITH (NOLOCK))
  THROW 52096,N''Replace-Wertorakel verletzt.'',6;
 IF (SELECT COUNT(*) FROM #ContosoRightsLike WITH (NOLOCK))<>1
  THROW 52096,N''Eigene Referenzdaten wurden veraendert.'',7;'),
(2,1,0,1,N'
 CREATE TABLE #ContosoRightsTarget(Dummy int NULL);
 DECLARE @Before int=OBJECT_ID(N''tempdb..#ContosoRightsTarget''),@Rc int;
 EXEC @Rc=toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=N''#ContosoRightsTarget'',@LikeTable=N''dbo.ContosoRightsReference'';
 IF @Rc<>0 OR EXISTS(SELECT 1 FROM #ContosoRightsTarget WITH (NOLOCK))
  THROW 52096,N''Regulaere Metadatenquelle wurde nicht korrekt verarbeitet.'',8;'+@Shape),
(3,1,0,0,N'
 CREATE TABLE #ContosoRightsTarget(Dummy int NOT NULL);
 INSERT #ContosoRightsTarget VALUES(7);
 DECLARE @Before int=OBJECT_ID(N''tempdb..#ContosoRightsTarget''),@CaughtMeta bit=0;
 BEGIN TRY
  EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=N''#ContosoRightsTarget'',@LikeTable=N''dbo.ContosoRightsReference'';
 END TRY
 BEGIN CATCH
  IF ERROR_NUMBER()<>51023 THROW;
  SET @CaughtMeta=1;
 END CATCH;
 IF @CaughtMeta=0 OR OBJECT_ID(N''tempdb..#ContosoRightsTarget'')<>@Before
  OR (SELECT COUNT(*) FROM tempdb.sys.columns WITH (NOLOCK) WHERE object_id=@Before)<>1
  OR NOT EXISTS(SELECT 1 FROM tempdb.sys.columns WITH (NOLOCK) WHERE object_id=@Before AND name=N''Dummy'' AND system_type_id=TYPE_ID(N''int'') AND is_nullable=0)
  OR (SELECT COUNT(*) FROM #ContosoRightsTarget WITH (NOLOCK))<>1
  OR NOT EXISTS(SELECT 1 FROM #ContosoRightsTarget WITH (NOLOCK) WHERE Dummy=7)
  THROW 52096,N''Metadatensicht wurde nicht atomar mit SQL51023 abgewiesen.'',9;'),
(4,0,1,0,N'
 DECLARE @Rows table(CapturedAtUtc datetime2(7),ExecutionId uniqueidentifier,ErrorClass varchar(16),
  ErrorNumber int,ErrorSeverity int,ErrorState int,ErrorProcedure nvarchar(776),ErrorLine int,ErrorMessage nvarchar(4000),
  XactState smallint,TransactionCount int,DatabaseName sysname,SessionId int,AdditionalContext nvarchar(4000));
 INSERT @Rows EXEC toolbelt_core.USP_CaptureErrorEnvelope @ErrorNumber=8134,@ErrorSeverity=16,@ErrorState=1,
  @ErrorProcedure=N''ContosoProbe'',@ErrorLine=7,@ErrorMessage=N''Contoso synthetic error'',
  @ExecutionId=''11111111-1111-1111-1111-111111111111'',@AdditionalContext=N''Contoso context'';
 IF (SELECT COUNT(*) FROM @Rows)<>1 OR NOT EXISTS(SELECT 1 FROM @Rows
  WHERE CapturedAtUtc IS NOT NULL AND ExecutionId=''11111111-1111-1111-1111-111111111111'' AND ErrorClass=''ENGINE''
   AND ErrorNumber=8134 AND ErrorSeverity=16 AND ErrorState=1 AND ErrorProcedure=N''ContosoProbe'' AND ErrorLine=7
   AND CONVERT(varbinary(max),ErrorMessage)=CONVERT(varbinary(max),N''Contoso synthetic error'')
   AND XactState=0 AND TransactionCount=0 AND DatabaseName=DB_NAME() AND SessionId=@@SPID
   AND CONVERT(varbinary(max),AdditionalContext)=CONVERT(varbinary(max),N''Contoso context''))
  THROW 52096,N''Direktes Envelope-Wertorakel verletzt.'',10;'),
(5,1,1,0,N'
 CREATE TABLE #ContosoEnvelope(Dummy int NULL);
 DECLARE @Before int=OBJECT_ID(N''tempdb..#ContosoEnvelope''),@Rc int;
 EXEC @Rc=toolbelt_core.USP_CaptureErrorEnvelope @ErrorNumber=8134,@ErrorSeverity=16,@ErrorState=1,
  @ErrorMessage=N''Contoso first'',@ExecutionId=''11111111-1111-1111-1111-111111111111'',@ResultTable=N''#ContosoEnvelope'';
 IF @Rc<>0 THROW 52096,N''Envelope-Returncode verletzt.'',11;
 EXEC @Rc=toolbelt_core.USP_CaptureErrorEnvelope @ErrorNumber=60001,@ErrorSeverity=16,@ErrorState=2,
  @ErrorMessage=N''Contoso second'',@ExecutionId=''11111111-1111-1111-1111-111111111111'',@ResultTable=N''#ContosoEnvelope'',@KeepData=1;
 IF @Rc<>0 OR OBJECT_ID(N''tempdb..#ContosoEnvelope'')<>@Before
  OR (SELECT COUNT(*) FROM tempdb.sys.columns WITH (NOLOCK) WHERE object_id=@Before)<>14
  OR (SELECT COUNT(*) FROM #ContosoEnvelope WITH (NOLOCK))<>2
  THROW 52096,N''Envelope-ResultTable-/KeepData-Wertorakel verletzt.'',12;
 EXEC sys.sp_executesql N''IF NOT EXISTS(SELECT 1 FROM #ContosoEnvelope WITH (NOLOCK) WHERE ErrorClass=''''ENGINE'''' AND ErrorNumber=8134 AND ErrorState=1
    AND ExecutionId=''''11111111-1111-1111-1111-111111111111'''' AND CONVERT(varbinary(max),ErrorMessage)=CONVERT(varbinary(max),N''''Contoso first''''))
  OR NOT EXISTS(SELECT 1 FROM #ContosoEnvelope WITH (NOLOCK) WHERE ErrorClass=''''USER'''' AND ErrorNumber=60001 AND ErrorState=2
    AND ExecutionId=''''11111111-1111-1111-1111-111111111111'''' AND CONVERT(varbinary(max),ErrorMessage)=CONVERT(varbinary(max),N''''Contoso second''''))
  THROW 52096,N''''Envelope-Zeilenwerte verletzt.'''',12;'';');

DECLARE @Created bit=0,@ReferenceCreated bit=0,@Impersonated bit=0,@Call int=1,@Phase int,
 @NeedHelper bit,@NeedEnvelope bit,@NeedView bit,@Sql nvarchar(max),@ExpectedError int,@Caught bit,
 @ProfilesPassed int=0,@ValueProfiles int=0,@MetadataRejected int=0,@Denied int=0;
BEGIN TRY
 CREATE TABLE dbo.ContosoRightsReference(Id int NOT NULL,Label nvarchar(16) COLLATE Latin1_General_100_BIN2 NULL,Amount decimal(12,4) NULL);
 SET @ReferenceCreated=1;
 INSERT dbo.ContosoRightsReference VALUES(1,N'Contoso',12.3400);
 CREATE USER ContosoTableCaller WITHOUT LOGIN; SET @Created=1;
 WHILE @Call<=5
 BEGIN
  SELECT @NeedHelper=Helper,@NeedEnvelope=Envelope,@NeedView=ViewDefinition FROM @Profiles WHERE Id=@Call;
  SET @Phase=0;
  WHILE @Phase<=2
  BEGIN
   IF @Phase=1
   BEGIN
    IF @NeedHelper=1 GRANT EXECUTE ON OBJECT::toolbelt_core.USP_PrepareResultTable TO ContosoTableCaller;
    IF @NeedEnvelope=1 GRANT EXECUTE ON OBJECT::toolbelt_core.USP_CaptureErrorEnvelope TO ContosoTableCaller;
    IF @NeedView=1 GRANT VIEW DEFINITION ON OBJECT::dbo.ContosoRightsReference TO ContosoTableCaller;
   END;
   IF @Phase=2
   BEGIN
    REVOKE EXECUTE ON OBJECT::toolbelt_core.USP_PrepareResultTable FROM ContosoTableCaller;
    REVOKE EXECUTE ON OBJECT::toolbelt_core.USP_CaptureErrorEnvelope FROM ContosoTableCaller;
    REVOKE VIEW DEFINITION ON OBJECT::dbo.ContosoRightsReference FROM ContosoTableCaller;
   END;
   SELECT @Sql=SqlText FROM @Profiles WHERE Id=@Call;
   SET @ExpectedError=CASE WHEN @Phase=1 THEN 0 ELSE 229 END; SET @Caught=0;
   EXECUTE AS USER=N'ContosoTableCaller'; SET @Impersonated=1;
   IF ISNULL(IS_MEMBER(N'db_owner'),0)<>0 OR ISNULL(IS_MEMBER(N'db_ddladmin'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'EXECUTE'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'SELECT'),0)<>0
    THROW 52096,N'Unerwartete Rollen-, Datenbank- oder Schemarechte.',13;
   IF ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core.USP_PrepareResultTable',N'OBJECT',N'EXECUTE'),0)<>CASE WHEN @Phase=1 THEN @NeedHelper ELSE 0 END
    OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core.USP_CaptureErrorEnvelope',N'OBJECT',N'EXECUTE'),0)<>CASE WHEN @Phase=1 THEN @NeedEnvelope ELSE 0 END
    OR ISNULL(HAS_PERMS_BY_NAME(N'dbo.ContosoRightsReference',N'OBJECT',N'VIEW DEFINITION'),0)<>CASE WHEN @Phase=1 THEN @NeedView ELSE 0 END
    OR ISNULL(HAS_PERMS_BY_NAME(N'dbo.ContosoRightsReference',N'OBJECT',N'SELECT'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(N'dbo.ContosoRightsReference',N'OBJECT',N'ALTER'),0)<>0
    THROW 52096,N'Nicht exakt die vorgesehene Objektrechtkombination.',14;
   BEGIN TRY EXEC sys.sp_executesql @Sql; END TRY
   BEGIN CATCH
    IF @ExpectedError=0 OR ERROR_NUMBER()<>@ExpectedError THROW;
    SET @Caught=1; SET @Denied+=1;
   END CATCH;
   IF @ExpectedError<>0 AND @Caught=0 THROW 52096,N'Fehlendes Ausfuehrungsrecht wurde nicht abgewiesen.',15;
   IF @Phase=1
   BEGIN
    SET @ProfilesPassed+=1;
    IF @Call=3 SET @MetadataRejected+=1; ELSE SET @ValueProfiles+=1;
    IF @NeedEnvelope=0 OR @NeedHelper=0
    BEGIN
     SET @Sql=CASE WHEN @NeedEnvelope=0 THEN N'EXEC toolbelt_core.USP_CaptureErrorEnvelope @Hilfe=1;'
      ELSE N'EXEC toolbelt_core.USP_PrepareResultTable @Hilfe=1;' END;
     SET @Caught=0;
     BEGIN TRY EXEC sys.sp_executesql @Sql; END TRY
     BEGIN CATCH IF ERROR_NUMBER()<>229 THROW; SET @Caught=1; SET @Denied+=1; END CATCH;
     IF @Caught=0 THROW 52096,N'Fremdes API wurde mit unpassendem Objektrecht zugelassen.',16;
    END;
    IF @NeedView=1
    BEGIN
     SET @Caught=0;
     BEGIN TRY EXEC sys.sp_executesql N'SELECT Id FROM dbo.ContosoRightsReference WITH (NOLOCK);'; END TRY
     BEGIN CATCH IF ERROR_NUMBER()<>229 THROW; SET @Caught=1; SET @Denied+=1; END CATCH;
     IF @Caught=0 THROW 52096,N'Metadatensicht hat unerwartet Quelldatenleserechte.',17;
    END;
   END;
   REVERT; SET @Impersonated=0; SET @Phase+=1;
  END;
  SET @Call+=1;
 END;
 IF @ProfilesPassed<>5 OR @ValueProfiles<>4 OR @MetadataRejected<>1 OR @Denied<>15
  THROW 52096,N'Unvollstaendige Profil-/Rechteorakel.',18;
 IF (SELECT COUNT(*) FROM dbo.ContosoRightsReference WITH (NOLOCK))<>1
  OR NOT EXISTS(SELECT 1 FROM dbo.ContosoRightsReference WITH (NOLOCK) WHERE Id=1 AND Label=N'Contoso' AND Amount=12.3400)
  THROW 52096,N'Die eigene regulaere Referenz wurde veraendert.',20;
 DROP USER ContosoTableCaller; SET @Created=0;
 DROP TABLE dbo.ContosoRightsReference; SET @ReferenceCreated=0;
 IF USER_ID(N'ContosoTableCaller') IS NOT NULL OR OBJECT_ID(N'dbo.ContosoRightsReference') IS NOT NULL
  THROW 52096,N'Eigener Principal oder Referenzfixture wurde nicht entfernt.',19;
END TRY
BEGIN CATCH
 IF @Impersonated=1 REVERT;
 IF @Created=1 DROP USER ContosoTableCaller;
 IF @ReferenceCreated=1 DROP TABLE dbo.ContosoRightsReference;
 THROW;
END CATCH;
PRINT N'ResultTable/Envelope: vier Wertprofile, eine atomare Metadatenabweisung und fuenfzehn strikte SQL229-Abweisungen; eigene Fixtures bereinigt.';
