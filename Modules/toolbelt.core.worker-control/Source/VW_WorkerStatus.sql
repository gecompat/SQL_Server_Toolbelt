-- Objekt: toolbelt_core.VW_WorkerStatus
-- Zweck: Öffentliche technische Statussicht; explizite Spalten, keine Tokens oder Payloads.
-- Version: 1.0.0; SQL Server 2019/2022/2025, Windows/Linux.
-- Parameter: keine. Ergebnis: WorkerId uniqueidentifier NOT NULL, WorkerGeneration bigint NOT NULL, ProviderKind varchar(16) NOT NULL, State varchar(16) NOT NULL, Capacity int NOT NULL, RunMode varchar(16) NOT NULL, LastHeartbeatAtUtc datetime2(7) NOT NULL, OccupiedSlots bigint NOT NULL, ConfigVersion binary(8) NOT NULL, HeartbeatSeconds int NOT NULL, UnreachableSeconds int NOT NULL.
-- Rechte: vorhandenes SELECT; keine Rechtevergabe. Datenzugriff nur lesend.
-- Abhängigkeiten: moduleigene Tabellen; kein Remotezugriff.
-- Beispiel: SELECT WorkerId,WorkerGeneration FROM toolbelt_core.VW_WorkerStatus;
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
-- Öffentliche Statussicht ohne Tokens, Principals oder Runtimeinventar.
CREATE OR ALTER VIEW toolbelt_core.VW_WorkerStatus AS
 SELECT w.WorkerId,w.WorkerGeneration,w.ProviderKind,w.State,w.Capacity,w.RunMode,w.LastHeartbeatAtUtc,
  ISNULL(CONVERT(bigint,(SELECT COUNT_BIG(*) FROM toolbelt_core.WorkerSlotReservation r WHERE r.WorkerId=w.WorkerId AND r.WorkerGeneration=w.WorkerGeneration AND r.IsOccupied=1)),CONVERT(bigint,0)) OccupiedSlots,
  ISNULL(CONVERT(binary(8),c.ConfigVersion),CONVERT(binary(8),0x0)) ConfigVersion,w.HeartbeatSeconds,w.UnreachableSeconds
 FROM toolbelt_core.WorkerRegistration w CROSS JOIN toolbelt_core.WorkerControlConfiguration c WHERE c.ConfigurationId=1;
GO
