-- Objekt: toolbelt_core.USP_ClaimWorkerWork
-- Zweck: Fachliche Fassade der privaten atomaren Managed-Admission.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene EXECUTE-Rechte, keine Grants.
-- Sichtbarkeit: public; Version:1.0.0, SQL2019+/Windows/Linux.
-- Resultset und Parameter: explizit im gekoppelten Help definiert.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_ClaimWorkerWork
 @WorkerId uniqueidentifier=NULL,
 @WorkerGeneration bigint=NULL,
 @WorkerToken uniqueidentifier=NULL,
 @ResultTable sysname=NULL,
 @KeepData bit=0,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
 SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_ClaimWorkerWork' AS sysname) ObjectName,
 CAST(v.Section AS varchar(32)) Section,v.Ordinal,CAST(v.ItemName AS sysname) ItemName,CAST(v.SqlDataType AS varchar(256)) SqlDataType,CAST(v.IsRequired AS bit) IsRequired,CAST(v.IsNullable AS bit) IsNullable,CAST(v.DefaultValue AS nvarchar(4000)) DefaultValue,CAST(v.Description AS nvarchar(max)) Description,CAST(v.ExampleSql AS nvarchar(max)) ExampleSql
 FROM(VALUES ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Fachliche Fassade der privaten atomaren Managed-Admission.',NULL),
 ('PARAMETER',1,N'@WorkerId',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: WorkerId',NULL),
 ('PARAMETER',2,N'@WorkerGeneration',N'bigint',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: WorkerGeneration',NULL),
 ('PARAMETER',3,N'@WorkerToken',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: WorkerToken',NULL),
 ('PARAMETER',4,N'@ResultTable',N'sysname',0,1,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ResultTable',NULL),
 ('PARAMETER',5,N'@KeepData',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: KeepData',NULL),
 ('PARAMETER',6,N'@Debug',N'tinyint',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Debug',NULL),
 ('PARAMETER',7,N'@Hilfe',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Hilfe',NULL),
 ('RESULT_COLUMN',1,N'WorkItemId',N'bigint',0,0,NULL,N'WorkItemId gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',2,N'WorkTypeName',N'varchar(128)',0,0,NULL,N'WorkTypeName gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',3,N'PayloadJson',N'nvarchar(max)',0,1,NULL,N'PayloadJson gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',4,N'ClaimToken',N'uniqueidentifier',0,0,NULL,N'ClaimToken gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',5,N'ClaimedAtUtc',N'datetime2(7)',0,0,NULL,N'ClaimedAtUtc gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',6,N'ClaimGeneration',N'bigint',0,0,NULL,N'ClaimGeneration gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',7,N'LeaseUntilUtc',N'datetime2(7)',0,0,NULL,N'LeaseUntilUtc gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',8,N'LastHeartbeatAtUtc',N'datetime2(7)',0,0,NULL,N'LastHeartbeatAtUtc gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',9,N'SlotReservationId',N'uniqueidentifier',0,0,NULL,N'SlotReservationId gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',10,N'ExecutionId',N'uniqueidentifier',0,0,NULL,N'ExecutionId gemäß Ergebnisvertrag.',NULL),
 ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Synthetischer Help-Aufruf.',N'EXEC toolbelt_core.USP_ClaimWorkerWork @Hilfe=1;'))v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql); RETURN 0; END;
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'ManagedClaim verlangt eine eigene Admissiontransaktion.',2;
 EXEC toolbelt_core.USP_ReserveWorkerExecution @WorkerId=@WorkerId,@WorkerGeneration=@WorkerGeneration,@WorkerToken=@WorkerToken,@ResultTable=@ResultTable,@KeepData=@KeepData,@Debug=@Debug;
 RETURN 0;
END;
GO
