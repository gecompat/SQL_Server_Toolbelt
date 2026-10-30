-- Objekt: toolbelt_core.USP_StopWorkerExecution
-- Zweck: Persistiert generationgebunden Stop und Hold vor Providerabbruch; Completiongewinner bleibt committed.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene EXECUTE-Rechte, keine Grants.
-- Sichtbarkeit: public; Version:1.0.0, SQL2019+/Windows/Linux.
-- Resultset und Parameter: explizit im gekoppelten Help definiert.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_StopWorkerExecution
 @SlotReservationId uniqueidentifier=NULL,
 @ExpectedClaimGeneration bigint=NULL,
 @ResultTable sysname=NULL,
 @KeepData bit=0,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_StopWorkerExecution' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Persistiert generationgebunden Stop und Hold vor Providerabbruch; Completiongewinner bleibt committed.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'SlotReservationId', N'uniqueidentifier', 0, 0, NULL, CAST(N'SlotReservationId gemäß Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'ExecutionId', N'uniqueidentifier', 0, 0, NULL, CAST(N'ExecutionId gemäß Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'StopStatus', N'varchar(24)', 0, 0, NULL, CAST(N'StopStatus gemäß Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'HoldVersion', N'binary(8)', 0, 0, NULL, CAST(N'HoldVersion gemäß Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Help-Aufruf.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_StopWorkerExecution @Hilfe=1;' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@SlotReservationId', N'uniqueidentifier', 1, 0, N'NULL', CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche SlotReservationId eines tatsächlich reservierten Versuchs, unverändert aus ClaimWorkerWork/Status übernehmen. Keine frei gewählte UUID, SPID oder WorkItemId; NULL/fehlende Reservation ist ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@ExpectedClaimGeneration', N'bigint', 1, 0, N'NULL', CAST(N'Fachlich erforderliche exakte positive bigint-ClaimGeneration der ausgewählten Reservation, aus ihrer Ausführungs-/Claimstatuszeile übernehmen. Kein WorkerGeneration-Wert; NULL oder Abweichung wird abgewiesen. Ein bereits gewinnender Commit wird nicht durch Retry wiederholt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
 CREATE TABLE #tbx_USP_StopWorkerExecution_Result(SlotReservationId uniqueidentifier NOT NULL,ExecutionId uniqueidentifier NOT NULL,StopStatus varchar(24) NOT NULL,HoldVersion binary(8) NOT NULL);
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'Workersteuerung verlangt eine eigene kurze Transaktion.',1;
 BEGIN TRANSACTION;
 BEGIN TRY
 DECLARE @DispositionResource nvarchar(255)=N'Toolbelt.Worker.Disposition.'+CONVERT(nvarchar(36),@SlotReservationId),@Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource=@DispositionResource,@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=5000,@DbPrincipal=N'public';
 IF @Lock<0 THROW 54222,N'Der private Disposition-Gate ist nicht verfügbar.',2;
 DECLARE @Item bigint,@Execution uniqueidentifier,@Generation bigint,@Outcome varchar(24),@State varchar(24),@Occupied bit,@Held bit;
 SELECT @Item=WorkItemId,@Execution=ExecutionId,@Generation=ClaimGeneration,@State=State,@Occupied=IsOccupied FROM toolbelt_core.WorkerSlotReservation WITH(UPDLOCK,HOLDLOCK) WHERE SlotReservationId=@SlotReservationId;
 IF @Item IS NULL OR @ExpectedClaimGeneration IS NULL OR @ExpectedClaimGeneration<>@Generation THROW 54224,N'Die ausgewählte Reservation oder Claimgeneration ist ungültig.',1;
 SELECT @Held=IsHeld FROM toolbelt_core.WorkerExecutionDisposition WITH(UPDLOCK,HOLDLOCK) WHERE SlotReservationId=@SlotReservationId;
 IF @Held IS NULL THROW 54224,N'Die aktuelle Disposition gehört nicht mehr zu dieser Reservation.',2;
 DECLARE @IsCompleted bit=0,@CommitWitness bit=0;
 -- Erst separat committed Queuezustand prüfen; laufender Witness bleibt uncommitted
 -- und darf unter dem Stopgate niemals gelesen werden.
 IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@Item AND Status='COMPLETED' AND ManagedReservationId=@SlotReservationId AND ClaimGeneration=@Generation) SET @IsCompleted=1;
 IF @IsCompleted=1
 BEGIN
 IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionCommitWitness WITH(READCOMMITTEDLOCK) WHERE SlotReservationId=@SlotReservationId AND ExecutionId=@Execution AND ClaimGeneration=@Generation) SET @CommitWitness=1;
 END;
 IF @Occupied=0 AND @State='ROLLED_BACK' AND @Held=0
 BEGIN
 -- Bewiesene freie Terminalhistory bleibt unverändert; kein neuer Hold für Retry.
 SET @Outcome='NONE';
 END
 ELSE IF @IsCompleted=1 AND @CommitWitness=1
 BEGIN
  UPDATE toolbelt_core.WorkerSlotReservation SET State='COMMITTED',IsOccupied=0,EndedAtUtc=ISNULL(EndedAtUtc,SYSUTCDATETIME()) WHERE SlotReservationId=@SlotReservationId;
  UPDATE toolbelt_core.WorkerExecutionDisposition SET IsHeld=0,StopStatus='ALREADY_COMMITTED' WHERE SlotReservationId=@SlotReservationId;
 END
 ELSE
 BEGIN
  UPDATE toolbelt_core.WorkerExecutionDisposition SET IsHeld=1,StopStatus=CASE WHEN @State='ROLLED_BACK' THEN 'ROLLED_BACK_HELD' ELSE 'REQUESTED' END WHERE SlotReservationId=@SlotReservationId;
  UPDATE toolbelt_core.WorkItem SET ManagedHold=1 WHERE WorkItemId=@Item AND ManagedReservationId=@SlotReservationId;
  UPDATE toolbelt_core.WorkerSlotReservation SET State=CASE WHEN State='ROLLED_BACK' THEN State ELSE 'STOP_REQUESTED' END WHERE SlotReservationId=@SlotReservationId AND IsOccupied=1;
 END;
 INSERT #tbx_USP_StopWorkerExecution_Result SELECT r.SlotReservationId,r.ExecutionId,d.StopStatus,d.HoldVersion FROM toolbelt_core.WorkerSlotReservation r JOIN toolbelt_core.WorkerExecutionDisposition d ON d.SlotReservationId=r.SlotReservationId WHERE r.SlotReservationId=@SlotReservationId;
 IF @ResultTable IS NOT NULL BEGIN
 EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_USP_StopWorkerExecution_Result',@KeepData=@KeepData;
 DECLARE @PublishSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N'(SlotReservationId,ExecutionId,StopStatus,HoldVersion) SELECT SlotReservationId,ExecutionId,StopStatus,HoldVersion FROM #tbx_USP_StopWorkerExecution_Result'; EXEC sys.sp_executesql @PublishSql; END;
 COMMIT TRANSACTION;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;
 IF @ResultTable IS NULL SELECT SlotReservationId,ExecutionId,StopStatus,HoldVersion FROM #tbx_USP_StopWorkerExecution_Result;
 RETURN 0;
END;
GO
