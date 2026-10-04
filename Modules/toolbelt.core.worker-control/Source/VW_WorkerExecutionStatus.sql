-- Objekt: toolbelt_core.VW_WorkerExecutionStatus
-- Zweck: Öffentliche technische Statussicht; explizite Spalten, keine Tokens oder Payloads.
-- Version: 1.0.0; SQL Server 2019/2022/2025, Windows/Linux.
-- Parameter: keine. Ergebnis: SlotReservationId uniqueidentifier NOT NULL, WorkItemId bigint NOT NULL, ClaimGeneration bigint NOT NULL, ExecutionId uniqueidentifier NOT NULL, WorkerId uniqueidentifier NOT NULL, WorkerGeneration bigint NOT NULL, State varchar(24) NOT NULL, IsHeld bit NOT NULL, HoldVersion binary(8) NULL, StopStatus varchar(24) NOT NULL.
-- Rechte: vorhandenes SELECT; keine Rechtevergabe. Datenzugriff nur lesend.
-- Abhängigkeiten: moduleigene Tabellen; kein Remotezugriff.
-- Beispiel: SELECT SlotReservationId,State FROM toolbelt_core.VW_WorkerExecutionStatus;
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
-- Monotone Attemptstatussicht; Hold und Tokens bleiben getrennt.
CREATE OR ALTER VIEW toolbelt_core.VW_WorkerExecutionStatus AS
 SELECT r.SlotReservationId,r.WorkItemId,r.ClaimGeneration,r.ExecutionId,r.WorkerId,r.WorkerGeneration,r.State,
 ISNULL(d.IsHeld,CONVERT(bit,0)) IsHeld,CONVERT(binary(8),d.HoldVersion) HoldVersion,
 ISNULL(d.StopStatus,CASE WHEN r.State='COMMITTED' THEN 'ALREADY_COMMITTED' ELSE 'NONE' END) StopStatus
 FROM toolbelt_core.WorkerSlotReservation r LEFT JOIN toolbelt_core.WorkerExecutionDisposition d
 ON d.WorkItemId=r.WorkItemId AND d.SlotReservationId=r.SlotReservationId;
GO
