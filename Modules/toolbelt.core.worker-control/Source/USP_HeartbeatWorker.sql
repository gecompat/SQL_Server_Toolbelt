-- ============================================================================
-- Objekt: toolbelt_core.USP_HeartbeatWorker
-- Zweck: Erneuert ausschließlich die aktuelle lebende Workergeneration ohne Claims zu übernehmen.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene Rechte, keine Grants.
-- Sichtbarkeit: public
-- Transaktion: eigene kurze Steuertransaktion
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_HeartbeatWorker
 @WorkerId uniqueidentifier=NULL,
 @WorkerGeneration bigint=NULL,
 @WorkerToken uniqueidentifier=NULL,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
 SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_HeartbeatWorker' AS sysname) ObjectName,
 CAST(v.Section AS varchar(32)) Section,v.Ordinal,CAST(v.ItemName AS sysname) ItemName,CAST(v.SqlDataType AS varchar(256)) SqlDataType,
 CAST(v.IsRequired AS bit) IsRequired,CAST(v.IsNullable AS bit) IsNullable,CAST(v.DefaultValue AS nvarchar(4000)) DefaultValue,
 CAST(v.Description AS nvarchar(max)) Description,CAST(v.ExampleSql AS nvarchar(max)) ExampleSql
 FROM(VALUES ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Erneuert ausschließlich die aktuelle lebende Workergeneration ohne Claims zu übernehmen.',NULL),
 ('PARAMETER',1,N'@WorkerId',N'uniqueidentifier',1,1,N'NULL',N'Technischer Parameter gemäß Worker-Control-Vertrag: WorkerId',NULL),
 ('PARAMETER',2,N'@WorkerGeneration',N'bigint',1,1,N'NULL',N'Technischer Parameter gemäß Worker-Control-Vertrag: WorkerGeneration',NULL),
 ('PARAMETER',3,N'@WorkerToken',N'uniqueidentifier',1,1,N'NULL',N'Technischer Parameter gemäß Worker-Control-Vertrag: WorkerToken',NULL),
 ('PARAMETER',4,N'@Debug',N'tinyint',0,1,N'0',N'Technischer Parameter gemäß Worker-Control-Vertrag: Debug',NULL),
 ('PARAMETER',5,N'@Hilfe',N'bit',0,1,N'0',N'Technischer Parameter gemäß Worker-Control-Vertrag: Hilfe',NULL),
 ('RESULT_COLUMN',1,NULL,NULL,NULL,NULL,NULL,N'Kein fachliches Resultset; OUTPUT-Parameter und Returncode siehe Parametervertrag.',NULL),
 ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Ausschließlich synthetischer Help-Aufruf.',N'EXEC toolbelt_core.USP_HeartbeatWorker @Hilfe=1;'))v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql);
 RETURN 0; END;
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'Workersteuerung verlangt eine eigene kurze Transaktion.',1;
 BEGIN TRANSACTION;
 BEGIN TRY
 DECLARE @GateId tinyint,@SchedulerId int,@Config binary(8);
 SELECT @GateId=GateId FROM toolbelt_core.WorkQueueManagedGate WITH(UPDLOCK,HOLDLOCK) WHERE GateId=1;
 SELECT @SchedulerId=SchedulerId FROM toolbelt_core.WorkQueueScheduler WITH(UPDLOCK,HOLDLOCK) WHERE SchedulerId=1;
 SELECT @Config=ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WITH(UPDLOCK,HOLDLOCK) WHERE ConfigurationId=1;
 IF @GateId IS NULL OR @SchedulerId IS NULL OR @Config IS NULL THROW 54211,N'Der Worker-Control-Integrationsvertrag fehlt.',1;
 IF @WorkerId IS NULL OR @WorkerGeneration IS NULL OR @WorkerToken IS NULL OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration WITH(UPDLOCK,HOLDLOCK) WHERE WorkerId=@WorkerId AND WorkerGeneration=@WorkerGeneration AND WorkerToken=@WorkerToken AND OwnerPrincipalId=USER_ID() AND State<>'CLOSED') THROW 54215,N'Die Workergeneration besitzt keine gültige Autorität.',1;
 IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration WHERE WorkerId=@WorkerId AND WorkerGeneration=@WorkerGeneration AND (State='UNREACHABLE' OR DATEADD(SECOND,UnreachableSeconds,LastHeartbeatAtUtc)<=SYSUTCDATETIME())) THROW 54215,N'Die abgelaufene Workergeneration darf nicht wiederbelebt werden.',2;
 UPDATE toolbelt_core.WorkerRegistration SET LastHeartbeatAtUtc=SYSUTCDATETIME() WHERE WorkerId=@WorkerId AND WorkerGeneration=@WorkerGeneration;
 COMMIT TRANSACTION;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;
 RETURN 0;
END;
GO
