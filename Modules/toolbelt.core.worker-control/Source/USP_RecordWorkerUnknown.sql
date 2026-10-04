-- Objekt: toolbelt_core.USP_RecordWorkerUnknown
-- Zweck: Persistiert Unsicherheit und lässt die Reservation belegt; kein Replay oder Slotfreigabe.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene EXECUTE-Rechte, keine Grants.
-- Sichtbarkeit: internal; Version:1.0.0, SQL2019+/Windows/Linux.
-- Resultset und Parameter: explizit im gekoppelten Help definiert.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_RecordWorkerUnknown
 @SlotReservationId uniqueidentifier=NULL,
 @WorkerToken uniqueidentifier=NULL,
 @ExecutionId uniqueidentifier=NULL,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
 SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_RecordWorkerUnknown' AS sysname) ObjectName,
 CAST(v.Section AS varchar(32)) Section,v.Ordinal,CAST(v.ItemName AS sysname) ItemName,CAST(v.SqlDataType AS varchar(256)) SqlDataType,CAST(v.IsRequired AS bit) IsRequired,CAST(v.IsNullable AS bit) IsNullable,CAST(v.DefaultValue AS nvarchar(4000)) DefaultValue,CAST(v.Description AS nvarchar(max)) Description,CAST(v.ExampleSql AS nvarchar(max)) ExampleSql
 FROM(VALUES ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Persistiert Unsicherheit und lässt die Reservation belegt; kein Replay oder Slotfreigabe.',NULL),
 ('PARAMETER',1,N'@SlotReservationId',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: SlotReservationId',NULL),
 ('PARAMETER',2,N'@WorkerToken',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: WorkerToken',NULL),
 ('PARAMETER',3,N'@ExecutionId',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ExecutionId',NULL),
 ('PARAMETER',4,N'@Debug',N'tinyint',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Debug',NULL),
 ('PARAMETER',5,N'@Hilfe',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Hilfe',NULL),
 ('RESULT_COLUMN',1,NULL,NULL,NULL,NULL,NULL,N'Kein fachliches Resultset; OUTPUT und Returncode siehe Parametervertrag.',NULL),
 ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Synthetischer Help-Aufruf.',N'EXEC toolbelt_core.USP_RecordWorkerUnknown @Hilfe=1;'))v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql); RETURN 0; END;
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'Workersteuerung verlangt eine eigene kurze Transaktion.',1;
 BEGIN TRANSACTION;
 BEGIN TRY
 IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation r JOIN toolbelt_core.WorkerRegistration w ON w.WorkerId=r.WorkerId AND w.WorkerGeneration=r.WorkerGeneration WHERE r.SlotReservationId=@SlotReservationId AND r.ExecutionId=@ExecutionId AND w.WorkerToken=@WorkerToken AND w.OwnerPrincipalId=USER_ID() AND r.IsOccupied=1) THROW 54220,N'Der Unknownpfad besitzt keine Attemptautorität.',4;
 UPDATE toolbelt_core.WorkerSlotReservation SET State='UNKNOWN' WHERE SlotReservationId=@SlotReservationId AND IsOccupied=1;
 COMMIT TRANSACTION;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;
 RETURN 0;
END;
GO
