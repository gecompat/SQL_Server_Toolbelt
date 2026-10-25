SET NOCOUNT ON;
SET XACT_ABORT OFF;
DECLARE @Owner nvarchar(32)=(SELECT CONVERT(nvarchar(32),value) FROM sys.extended_properties
 WHERE class=0 AND name=N'Test.Release.Owner');
IF @Owner IS NULL OR LEN(@Owner)<>32 OR @Owner COLLATE Latin1_General_100_BIN2 LIKE N'%[^a-f0-9]%'
 OR DB_NAME() NOT IN(N'Toolbelt_Release_'+@Owner+N'_l',N'Toolbelt_Release_'+@Owner+N'_c') OR @@TRANCOUNT<>0
 OR SESSION_CONTEXT(N'toolbelt.execution.id') IS NOT NULL
 THROW 52098,N'Markierter eigener frischer Cancellation-Testscope erforderlich.',1;
DECLARE @Known uniqueidentifier='11111111-1111-1111-1111-111111111111',
 @Current uniqueidentifier='22222222-2222-2222-2222-222222222222',
 @Unknown uniqueidentifier='33333333-3333-3333-3333-333333333333';
IF USER_ID(N'ContosoCancelCaller') IS NOT NULL OR EXISTS(SELECT 1 FROM toolbelt_core.ExecutionCancellation WHERE ExecutionId IN(@Known,@Current,@Unknown))
 THROW 52098,N'Vorhandene Cancellationfixture wird nicht uebernommen.',2;
DECLARE @Apis table(Id int PRIMARY KEY,Name sysname,PermissionName varchar(16),SqlText nvarchar(max));
INSERT @Apis VALUES
 (1,N'USP_RequestExecutionCancellation','EXECUTE',N'
  DECLARE @Rc int;
  EXEC @Rc=toolbelt_core.USP_RequestExecutionCancellation @ExecutionId=@Known,@CancellationReason=N''first'';
  IF @Rc<>0 THROW 52098,N''Request-Rueckgabecode verletzt.'',3;
  EXEC sys.sp_set_session_context @key=N''toolbelt.execution.id'',@value=N''22222222-2222-2222-2222-222222222222'';
  EXEC @Rc=toolbelt_core.USP_RequestExecutionCancellation @CancellationReason=N''context'';
  EXEC sys.sp_set_session_context @key=N''toolbelt.execution.id'',@value=NULL;
  IF @Rc<>0 THROW 52098,N''Context-Request-Rueckgabecode verletzt.'',4;'),
 (2,N'TVF_ExecutionCancellationStatus','SELECT',N'
  DECLARE @Rows table(ExecutionId uniqueidentifier NULL,IsCancellationRequested bit NULL,RequestedAtUtc datetime2(7) NULL);
  INSERT @Rows SELECT * FROM toolbelt_core.TVF_ExecutionCancellationStatus(@Known);
  IF (SELECT COUNT(*) FROM @Rows)<>1 OR NOT EXISTS(SELECT 1 FROM @Rows WHERE ExecutionId=@Known AND IsCancellationRequested=1 AND RequestedAtUtc IS NOT NULL)
   THROW 52098,N''Cancellation-TVF-Wertorakel verletzt.'',5;
  IF EXISTS(SELECT 1 FROM toolbelt_core.TVF_ExecutionCancellationStatus(@Unknown)) OR EXISTS(SELECT 1 FROM toolbelt_core.TVF_ExecutionCancellationStatus(NULL))
   THROW 52098,N''Unbekannter oder NULL-Status ist nicht leer.'',6;'),
 (3,N'SVF_IsCancellationRequested','EXECUTE',N'
  IF ISNULL(toolbelt_core.SVF_IsCancellationRequested(@Known),0)<>1
   OR ISNULL(toolbelt_core.SVF_IsCancellationRequested(@Unknown),1)<>0
   OR ISNULL(toolbelt_core.SVF_IsCancellationRequested(NULL),1)<>0
   THROW 52098,N''Cancellation-SVF-Wertorakel verletzt.'',7;');
DECLARE @Call int=1,@Phase int,@Other int,@Name sysname,@Permission varchar(16),@Sql nvarchar(max),@Grant nvarchar(max),@Probe nvarchar(max),
 @Caught bit,@Created bit=0,@Impersonated bit=0,@Positive int=0,@Denied int=0,@FirstTime datetime2(7),@FirstVersion binary(8);
BEGIN TRY
 CREATE USER ContosoCancelCaller WITHOUT LOGIN; SET @Created=1;
 WHILE @Call<=3
 BEGIN
  SELECT @Name=Name,@Permission=PermissionName,@Sql=SqlText FROM @Apis WHERE Id=@Call;
  SET @Phase=0;
  WHILE @Phase<=2
  BEGIN
   DELETE toolbelt_core.ExecutionCancellation WHERE ExecutionId IN(@Known,@Current);
   IF @Call<>1 EXEC toolbelt_core.USP_RequestExecutionCancellation @ExecutionId=@Known,@CancellationReason=N'seed';
   SET @Grant=CASE @Phase WHEN 1 THEN N'GRANT '+@Permission+N' ON OBJECT::toolbelt_core.'+QUOTENAME(@Name)+N' TO ContosoCancelCaller;'
    WHEN 2 THEN N'REVOKE '+@Permission+N' ON OBJECT::toolbelt_core.'+QUOTENAME(@Name)+N' FROM ContosoCancelCaller;' END;
   IF @Grant IS NOT NULL EXEC sys.sp_executesql @Grant;
   EXECUTE AS USER=N'ContosoCancelCaller'; SET @Impersonated=1;
   IF ISNULL(IS_MEMBER(N'db_owner'),0)<>0 OR ISNULL(IS_MEMBER(N'db_datareader'),0)<>0 OR ISNULL(IS_MEMBER(N'db_datawriter'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'EXECUTE'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'SELECT'),0)<>0
    THROW 52098,N'Unerwartete breite Cancellation-Callerrechte.',8;
   IF EXISTS(SELECT 1 FROM @Apis WHERE ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core.'+Name,N'OBJECT',PermissionName),0)
    <>CASE WHEN @Phase=1 AND Id=@Call THEN 1 ELSE 0 END)
    THROW 52098,N'Nicht exakt das einzelne Cancellation-Objektrecht.',9;
   SET @Caught=0;
   BEGIN TRY EXEC sys.sp_executesql @Sql,N'@Known uniqueidentifier,@Current uniqueidentifier,@Unknown uniqueidentifier',@Known,@Current,@Unknown; END TRY
   BEGIN CATCH IF @Phase=1 OR ERROR_NUMBER()<>229 THROW; SET @Caught=1; SET @Denied+=1; END CATCH;
   IF @Phase<>1 AND @Caught=0 THROW 52098,N'Fehlendes Cancellation-Recht wurde zugelassen.',10;
   IF @Phase=1
   BEGIN
    SET @Positive+=1;
    IF @Call=1
    BEGIN
     REVERT; SET @Impersonated=0;
     IF (SELECT COUNT(*) FROM toolbelt_core.ExecutionCancellation WHERE ExecutionId IN(@Known,@Current))<>2
      OR EXISTS(SELECT 1 FROM toolbelt_core.ExecutionCancellation WHERE ExecutionId IN(@Known,@Current) AND RequestedByPrincipalId<>USER_ID(N'ContosoCancelCaller'))
      OR NOT EXISTS(SELECT 1 FROM toolbelt_core.ExecutionCancellation WHERE ExecutionId=@Known AND CancellationReason=N'first')
      OR NOT EXISTS(SELECT 1 FROM toolbelt_core.ExecutionCancellation WHERE ExecutionId=@Current AND CancellationReason=N'context')
      THROW 52098,N'Request-/Context-/Principal-Wertorakel verletzt.',11;
     SELECT @FirstTime=RequestedAtUtc,@FirstVersion=CONVERT(binary(8),RowVersion) FROM toolbelt_core.ExecutionCancellation WHERE ExecutionId=@Known;
     EXECUTE AS USER=N'ContosoCancelCaller'; SET @Impersonated=1;
     EXEC toolbelt_core.USP_RequestExecutionCancellation @ExecutionId=@Known,@CancellationReason=N'ignored';
     REVERT; SET @Impersonated=0;
     IF NOT EXISTS(SELECT 1 FROM toolbelt_core.ExecutionCancellation WHERE ExecutionId=@Known AND RequestedAtUtc=@FirstTime AND CONVERT(binary(8),RowVersion)=@FirstVersion AND CancellationReason=N'first')
      THROW 52098,N'Request-Idempotenz veraenderte den Erstzustand.',12;
     EXECUTE AS USER=N'ContosoCancelCaller'; SET @Impersonated=1;
    END;
    SET @Other=1;
    WHILE @Other<=5
    BEGIN
     IF @Other<>@Call
     BEGIN
      SET @Probe=CASE @Other WHEN 1 THEN N'EXEC toolbelt_core.USP_RequestExecutionCancellation @Hilfe=1;'
       WHEN 2 THEN N'SELECT * FROM toolbelt_core.TVF_ExecutionCancellationStatus(''11111111-1111-1111-1111-111111111111'');'
       WHEN 3 THEN N'SELECT toolbelt_core.SVF_IsCancellationRequested(''11111111-1111-1111-1111-111111111111'');'
       WHEN 4 THEN N'SELECT TOP(0) * FROM toolbelt_core.ExecutionCancellation;'
       ELSE N'UPDATE toolbelt_core.ExecutionCancellation SET CancellationReason=CancellationReason WHERE 1=0;' END;
      SET @Caught=0;
      BEGIN TRY EXEC sys.sp_executesql @Probe; END TRY
      BEGIN CATCH IF ERROR_NUMBER()<>229 THROW; SET @Caught=1; SET @Denied+=1; END CATCH;
      IF @Caught=0 THROW 52098,N'Fremdes Cancellation-API oder interne Tabelle war zugaenglich.',13;
     END;
     SET @Other+=1;
    END;
   END;
   REVERT; SET @Impersonated=0; SET @Phase+=1;
  END;
  SET @Call+=1;
 END;
 IF @Positive<>3 OR @Denied<>18 THROW 52098,N'Unvollstaendige Cancellation-Probenzahl.',14;
 DELETE toolbelt_core.ExecutionCancellation WHERE ExecutionId IN(@Known,@Current);
 DROP USER ContosoCancelCaller; SET @Created=0;
END TRY
BEGIN CATCH
 IF @Impersonated=1 REVERT;
 IF XACT_STATE()<>0 ROLLBACK;
 IF TRY_CONVERT(uniqueidentifier,SESSION_CONTEXT(N'toolbelt.execution.id'))=@Current EXEC sys.sp_set_session_context @key=N'toolbelt.execution.id',@value=NULL;
 DELETE toolbelt_core.ExecutionCancellation WHERE ExecutionId IN(@Known,@Current);
 IF @Created=1 DROP USER ContosoCancelCaller;
 THROW;
END CATCH;
IF USER_ID(N'ContosoCancelCaller') IS NOT NULL OR SESSION_CONTEXT(N'toolbelt.execution.id') IS NOT NULL
 OR EXISTS(SELECT 1 FROM toolbelt_core.ExecutionCancellation WHERE ExecutionId IN(@Known,@Current,@Unknown))
 THROW 52098,N'Eigene Cancellationfixture nicht entfernt.',15;
PRINT N'Cancellation-Rechte: drei isolierte API-Profile und18 strikte SQL229-Abweisungen; eigener Principal/Context/Zeilen bereinigt.';
