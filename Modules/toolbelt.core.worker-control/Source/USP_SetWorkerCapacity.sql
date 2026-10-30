-- ============================================================================
-- Objekt: toolbelt_core.USP_SetWorkerCapacity
-- Zweck: Ändert die Live-Capacity einer exakten Workergeneration ohne Übernahme oder Abbruch laufender Arbeit.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene Rechte, keine Grants.
-- Sichtbarkeit: public
-- Transaktion: eigene kurze Steuertransaktion
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_SetWorkerCapacity
 @WorkerId uniqueidentifier=NULL,
 @WorkerGeneration bigint=NULL,
 @Capacity int=NULL,
 @ExpectedConfigVersion binary(8)=NULL,
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
            CAST(N'USP_SetWorkerCapacity' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Ändert die Live-Capacity einer exakten Workergeneration ohne Übernahme oder Abbruch laufender Arbeit.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'WorkerId', N'uniqueidentifier', 0, 0, NULL, CAST(N'WorkerId gemäß stabilem Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'WorkerGeneration', N'bigint', 0, 0, NULL, CAST(N'WorkerGeneration gemäß stabilem Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'Capacity', N'int', 0, 0, NULL, CAST(N'Capacity gemäß stabilem Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'ConfigVersion', N'binary(8)', 0, 0, NULL, CAST(N'ConfigVersion gemäß stabilem Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Ausschließlich synthetischer Help-Aufruf.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_SetWorkerCapacity @Hilfe=1;' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@WorkerId', N'uniqueidentifier', 1, 1, N'NULL', CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@WorkerGeneration', N'bigint', 1, 1, N'NULL', CAST(N'Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. Eine vorhandene nicht geschlossene Generation wird adressiert; der Aufruf übernimmt keine Generation.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@Capacity', N'int', 1, 1, N'NULL', CAST(N'Fachlich erforderliche Ganzzahl 1..2147483647 als lokale Live-Capacity genau dieser Generation. NULL/0/negativ ungültig. Eine Absenkung bricht laufende Arbeit nicht ab; neue Admission wartet auf freie Kapazität.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@ExpectedConfigVersion', N'binary(8)', 1, 1, N'NULL', CAST(N'Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
 CREATE TABLE #tbx_USP_SetWorkerCapacity_Result(WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL,Capacity int NOT NULL,ConfigVersion binary(8) NOT NULL);
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'Workersteuerung verlangt eine eigene kurze Transaktion.',1;
 BEGIN TRANSACTION;
 BEGIN TRY
 DECLARE @GateId tinyint,@SchedulerId int,@Config binary(8);
 SELECT @GateId=GateId FROM toolbelt_core.WorkQueueManagedGate WITH(UPDLOCK,HOLDLOCK) WHERE GateId=1;
 SELECT @SchedulerId=SchedulerId FROM toolbelt_core.WorkQueueScheduler WITH(UPDLOCK,HOLDLOCK) WHERE SchedulerId=1;
 SELECT @Config=ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WITH(UPDLOCK,HOLDLOCK) WHERE ConfigurationId=1;
 IF @GateId IS NULL OR @SchedulerId IS NULL OR @Config IS NULL THROW 54211,N'Der Worker-Control-Integrationsvertrag fehlt.',1;
 IF @ExpectedConfigVersion IS NULL OR @ExpectedConfigVersion<>@Config THROW 54212,N'Die erwartete Konfigurationsversion ist veraltet oder fehlt.',1;
 IF @Capacity IS NULL OR @Capacity<1 OR @WorkerId IS NULL OR @WorkerGeneration IS NULL THROW 54213,N'Die lokale Capacity ist ungültig.',4;
 UPDATE toolbelt_core.WorkerRegistration SET Capacity=@Capacity WHERE WorkerId=@WorkerId AND WorkerGeneration=@WorkerGeneration AND State<>'CLOSED';
 IF @@ROWCOUNT<>1 THROW 54215,N'Die gewählte Workergeneration existiert nicht.',3;
 UPDATE toolbelt_core.WorkerControlConfiguration SET MaxConcurrentExecutions=MaxConcurrentExecutions WHERE ConfigurationId=1;
 INSERT #tbx_USP_SetWorkerCapacity_Result SELECT w.WorkerId,w.WorkerGeneration,w.Capacity,c.ConfigVersion FROM toolbelt_core.WorkerRegistration w CROSS JOIN toolbelt_core.WorkerControlConfiguration c WHERE w.WorkerId=@WorkerId AND w.WorkerGeneration=@WorkerGeneration AND c.ConfigurationId=1;
 IF @ResultTable IS NOT NULL BEGIN
 EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_USP_SetWorkerCapacity_Result',@KeepData=@KeepData;
 DECLARE @PublishSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N'(WorkerId,WorkerGeneration,Capacity,ConfigVersion) SELECT WorkerId,WorkerGeneration,Capacity,ConfigVersion FROM #tbx_USP_SetWorkerCapacity_Result';
 EXEC sys.sp_executesql @PublishSql; END;
 COMMIT TRANSACTION;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;
 IF @ResultTable IS NULL SELECT WorkerId,WorkerGeneration,Capacity,ConfigVersion FROM #tbx_USP_SetWorkerCapacity_Result;
 RETURN 0;
END;
GO
