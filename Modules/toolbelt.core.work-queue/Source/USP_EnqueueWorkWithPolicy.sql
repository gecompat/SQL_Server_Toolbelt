SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_EnqueueWorkWithPolicy]
      @WorkTypeName varchar(128)=NULL,@PayloadJson nvarchar(max)=NULL,@IdempotencyKey varchar(128)=NULL,
      @Priority tinyint=0,@ExecutionGroup varchar(128)='default',@MaxAttempts tinyint=3,
      @RetryBaseDelaySeconds int=60,@RetryMaxDelaySeconds int=3600,@ExecutionMode varchar(16)='SHARED',
      @ResultTable sysname=NULL,@KeepData bit=0,@Debug tinyint=0,@Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1
 BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_EnqueueWorkWithPolicy' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Reiht Arbeit mit SHARED- oder DRAIN_BARRIER-Modus und unveränderlicher Retry-Policy ein. ENQUEUE-Autorisierung ist erforderlich; Barrier-Aufrufe sind außerhalb einer Callertransaktion.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51908,51965-51998', NULL, NULL, NULL, NULL, CAST(N'Fehlende ResultTable-Dependency, ungültige Policy oder Payload, inaktiver Work Type oder fehlende ENQUEUE-Autorisierung.' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'EXECUTE und explizite ENQUEUE-Autorisierung für den registrierten Work Type; für @ResultTable zusätzlich EXECUTE auf USP_PrepareResultTable.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Payload höchstens 64 KiB. Ein Barrier-Aufruf benötigt @@TRANCOUNT=0.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Einreihung eines registrierten JSON-Work-Types.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_EnqueueWorkWithPolicy @WorkTypeName=''registered-json-type'',@PayloadJson=N''{"value":1}'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'WasCreated', N'bit', 1, 0, NULL, CAST(N'1 bei neu angelegter Arbeit, 0 bei idempotenter Wiederverwendung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@WorkTypeName', N'varchar(128)', 1, 0, N'NULL', CAST(N'Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Muss aktiviert und für ENQUEUE autorisiert sein.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@PayloadJson', N'nvarchar(max)', 0, 1, N'NULL', CAST(N'Bei Work-Type-ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD erforderlicher JSON-Objekttext gemäß konkretem Handlervertrag, z.B. N''{"value":1}''. Höchstens 65536 UTF-16-Bytes (64 KiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keine führenden Tabs/CR/LF. Leer/ungültig wird abgewiesen; keine allgemeine automatische Prüfung der deklarativen PayloadContractJson-Felder.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@IdempotencyKey', N'varchar(128)', 0, 1, N'NULL', CAST(N'Optionaler varchar(128)-Schlüssel innerhalb genau eines Work Types; NULL (Default) deaktiviert Idempotency-Key-Wiederverwendung. Leerer Text ist ein expliziter Schlüssel, kein NULL-Ersatz. Vergleich gemäß binärer SQL-Collation, kein Normalisieren. Solange das Item besteht, liefert dieselbe Payload-/Policykonfiguration das bestehende Item; abweichende Konfiguration wird abgewiesen. Kein Beweis einer Exactly-once-Handlerwirkung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@Priority', N'tinyint', 0, 0, N'0', CAST(N'Ganzzahl 0..255 als tinyint, Default 0; höhere Werte werden bevorzugt. Explizites NULL ist unzulässig. Keine Zusage einer global strikt seriellen FIFO-Reihenfolge unter Konkurrenz.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@ExecutionGroup', N'varchar(128)', 0, 0, N'''default''', CAST(N'Nichtleerer varchar(128)-Gruppenname, binär/case-sensitiv gemäß SQL-Namensvergleich; keine feste Werteliste und keine separate Gruppenregistrierung. NULL/leer/reine Spaces ungültig; keine automatische Normalisierung. Die Gruppe bestimmt den Geltungsbereich der Barriers. Default ist der konkrete Name default.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@MaxAttempts', N'tinyint', 0, 0, N'3', CAST(N'Ganzzahl 1..10 Versuche pro Retryzyklus einschließlich, Default 3; explizites NULL ist kein Default und unzulässig. Die Policy wird am Item gespeichert und später nicht aus einer geänderten Konfiguration nachgelesen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@RetryBaseDelaySeconds', N'int', 0, 0, N'60', CAST(N'Ganzzahl 1..86400 Sekunden einschließlich, Default 60; NULL/0/negativ/zu groß unzulässig. Basis des exponentiellen Retry-Backoffs; muss <= RetryMaxDelaySeconds sein.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@RetryMaxDelaySeconds', N'int', 0, 0, N'3600', CAST(N'Ganzzahl von RetryBaseDelaySeconds bis 86400 Sekunden einschließlich, Default 3600; NULL oder kleiner als Basis unzulässig. Begrenzt den exponentiellen Backoff; keine Zufallsstreuung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@ExecutionMode', N'varchar(16)', 0, 0, N'''SHARED''', CAST(N'Taxativ in kanonischer Schreibweise: SHARED = normale Queuearbeit (Default); DRAIN_BARRIER = gruppengebundene Barrierarbeit mit Blocker-Snapshot und zusätzlichen Schedulerregeln. DRAIN_BARRIER verlangt @@TRANCOUNT=0. Kein automatisches UPPER; NULL/leer/andere Modi unzulässig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 12, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 13, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
 IF NULLIF(@WorkTypeName,'') IS NULL OR NULLIF(@ExecutionGroup,'') IS NULL THROW 51965,N'Work Type und ExecutionGroup sind erforderlich.',1;
 IF @ExecutionMode NOT IN('SHARED','DRAIN_BARRIER') OR @MaxAttempts NOT BETWEEN 1 AND 10 OR @RetryBaseDelaySeconds NOT BETWEEN 1 AND 86400 OR @RetryMaxDelaySeconds NOT BETWEEN @RetryBaseDelaySeconds AND 86400 THROW 51966,N'Die Queue-Policy ist ungültig.',1;
 IF @ExecutionMode='DRAIN_BARRIER' AND @@TRANCOUNT<>0 THROW 51997,N'Barrier-Enqueue benötigt eine Session ohne Callertransaktion.',1;
 IF DATALENGTH(@PayloadJson)>65536 THROW 51967,N'@PayloadJson darf höchstens 64 KiB umfassen.',1;
 DECLARE @Initial int=@@TRANCOUNT,@WorkTypeId bigint,@Mode varchar(16),@Enabled bit,@Existing bigint,@Now datetime2(7)=SYSUTCDATETIME(),@WasCreated bit,@InsertResultSql nvarchar(max);
 SELECT TOP (0) CAST(0 AS bit) AS WasCreated,v.* INTO #tbx_WorkQueue_EnqueuePolicyResult FROM toolbelt_core.VW_WorkQueue AS v;
 IF @Initial=0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION TBX_WorkQueue_EnqueuePolicy;
 BEGIN TRY
  IF @ResultTable IS NOT NULL
  BEGIN
   IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P') IS NULL THROW 51908,N'Für @ResultTable fehlt toolbelt.core.result-table.',1;
   EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_WorkQueue_EnqueuePolicyResult',@KeepData=@KeepData,@Debug=@Debug;
  END;
  SELECT @WorkTypeId=WorkTypeId,@Mode=ParameterMode,@Enabled=IsEnabled FROM toolbelt_core.WorkType WITH(UPDLOCK,HOLDLOCK) WHERE WorkTypeName=@WorkTypeName;
  IF @WorkTypeId IS NULL OR @Enabled<>1 THROW 51969,N'Der Work Type ist nicht aktiv.',1;
  IF NOT EXISTS(SELECT 1 FROM toolbelt_core.TVF_WorkTypeAuthorization(@WorkTypeId,'ENQUEUE') WHERE IsAllowed=1)
            THROW 51998,N'Keine Einreihberechtigung für diesen Work Type.',1;
  IF @Mode='NONE' AND @PayloadJson IS NOT NULL THROW 51970,N'NONE akzeptiert keine Payload.',1;
  IF @Mode='JSON_PAYLOAD' AND (@PayloadJson IS NULL OR ISJSON(@PayloadJson)<>1 OR LEFT(LTRIM(@PayloadJson),1)<>N'{') THROW 51971,N'JSON_PAYLOAD verlangt ein JSON-Objekt.',1;
  IF @ExecutionMode='DRAIN_BARRIER'
     SELECT @Existing=SchedulerId FROM toolbelt_core.WorkQueueScheduler WITH(UPDLOCK,HOLDLOCK) WHERE SchedulerId=1;
  SET @Existing=NULL;
  IF @IdempotencyKey IS NOT NULL
  BEGIN
   SELECT @Existing=WorkItemId FROM toolbelt_core.WorkItem WITH(UPDLOCK,HOLDLOCK) WHERE WorkTypeId=@WorkTypeId AND IdempotencyKey=@IdempotencyKey;
   IF @Existing IS NOT NULL
   BEGIN
    IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@Existing AND (ISNULL(PayloadJson,N'') COLLATE Latin1_General_100_BIN2<>ISNULL(@PayloadJson,N'') COLLATE Latin1_General_100_BIN2 OR Priority<>@Priority OR ExecutionGroup<>@ExecutionGroup OR ExecutionMode<>@ExecutionMode OR MaxAttempts<>@MaxAttempts OR RetryBaseDelaySeconds<>@RetryBaseDelaySeconds OR RetryMaxDelaySeconds<>@RetryMaxDelaySeconds)) THROW 51972,N'Der Idempotency Key gehört zu abweichender Arbeit.',1;
    SET @WasCreated=0;
   END;
  END;
  IF @Existing IS NULL
  BEGIN
   INSERT toolbelt_core.WorkItem(WorkTypeId,PayloadJson,Status,ExecutionGroup,Priority,ExecutionMode,IdempotencyKey,MaxAttempts,RetryBaseDelaySeconds,RetryMaxDelaySeconds,RetryCycleNumber,CycleAttemptCount,BarrierEpoch)
   VALUES(@WorkTypeId,@PayloadJson,CASE WHEN @ExecutionMode='DRAIN_BARRIER' THEN 'BARRIER_WAIT' ELSE 'QUEUED' END,@ExecutionGroup,@Priority,@ExecutionMode,@IdempotencyKey,@MaxAttempts,@RetryBaseDelaySeconds,@RetryMaxDelaySeconds,1,0,CASE WHEN @ExecutionMode='DRAIN_BARRIER' THEN 1 ELSE 0 END);
   SET @Existing=SCOPE_IDENTITY(); SET @WasCreated=1;
   IF @ExecutionMode='DRAIN_BARRIER'
    INSERT toolbelt_core.WorkQueueBarrierBlocker(BarrierWorkItemId,BarrierEpoch,BlockingWorkItemId,BlockingClaimGeneration)
    SELECT @Existing,1,WorkItemId,ClaimGeneration FROM toolbelt_core.WorkItem WHERE Status='CLAIMED' AND ExecutionGroup=@ExecutionGroup AND NOT(ExecutionMode='DRAIN_BARRIER' AND Priority=@Priority);
  END;
  IF @ResultTable IS NOT NULL
  BEGIN
   INSERT #tbx_WorkQueue_EnqueuePolicyResult SELECT @WasCreated,v.* FROM toolbelt_core.VW_WorkQueue AS v WHERE v.WorkItemId=@Existing;
   SET @InsertResultSql=N'INSERT INTO '+QUOTENAME(@ResultTable)+N' SELECT * FROM #tbx_WorkQueue_EnqueuePolicyResult;';
   EXEC sys.sp_executesql @InsertResultSql;
  END;
  IF @Initial=0 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @Initial=0 AND XACT_STATE()<>0 ROLLBACK; ELSE IF @Initial>0 AND XACT_STATE()=1 ROLLBACK TRANSACTION TBX_WorkQueue_EnqueuePolicy; THROW;
 END CATCH;
 IF @ResultTable IS NULL SELECT @WasCreated AS WasCreated,* FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId=@Existing;
END;
GO
