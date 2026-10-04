-- Interne persistente Provideridentitäten; keine Rechteerteilung oder öffentlichen DML-Verträge.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'toolbelt_core.WorkerControlConfiguration',N'U') IS NULL
BEGIN
 CREATE TABLE toolbelt_core.WorkerControlConfiguration
 (ConfigurationId tinyint NOT NULL CONSTRAINT PK_WorkerControlConfiguration PRIMARY KEY,
 MaxConcurrentExecutions int NOT NULL,HeartbeatSeconds int NOT NULL,UnreachableSeconds int NOT NULL,
 ConfigVersion rowversion NOT NULL,
 CONSTRAINT CK_WorkerControlConfiguration_Id CHECK(ConfigurationId=1),
 CONSTRAINT CK_WorkerControlConfiguration_Limits CHECK(MaxConcurrentExecutions>=0 AND HeartbeatSeconds BETWEEN 1 AND 3600 AND UnreachableSeconds BETWEEN 3 AND 86400 AND UnreachableSeconds>=3*HeartbeatSeconds));
 INSERT toolbelt_core.WorkerControlConfiguration(ConfigurationId,MaxConcurrentExecutions,HeartbeatSeconds,UnreachableSeconds) VALUES(1,1,15,60);
END;
IF OBJECT_ID(N'toolbelt_core.WorkerRegistration',N'U') IS NULL
 CREATE TABLE toolbelt_core.WorkerRegistration
 (WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL,WorkerToken uniqueidentifier NOT NULL,
 OwnerPrincipalId int NOT NULL,ProviderKind varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,
 State varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,AdmissionPaused bit NOT NULL,Capacity int NOT NULL,
 RunMode varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,
 LastHeartbeatAtUtc datetime2(7) NOT NULL,HeartbeatSeconds int NOT NULL,UnreachableSeconds int NOT NULL,
 CONSTRAINT PK_WorkerRegistration PRIMARY KEY(WorkerId,WorkerGeneration),
 CONSTRAINT CK_WorkerRegistration_Generation CHECK(WorkerGeneration>0),
 CONSTRAINT CK_WorkerRegistration_State CHECK(State IN('ACTIVE','PAUSED','DRAINING','UNREACHABLE','CLOSED')),
 CONSTRAINT CK_WorkerRegistration_Capacity CHECK(Capacity>0),
 CONSTRAINT CK_WorkerRegistration_RunMode CHECK(RunMode IN('BOUNDED','CONTINUOUS')));
IF OBJECT_ID(N'toolbelt_core.WorkerSlotReservation',N'U') IS NULL
 CREATE TABLE toolbelt_core.WorkerSlotReservation
 (SlotReservationId uniqueidentifier NOT NULL CONSTRAINT PK_WorkerSlotReservation PRIMARY KEY,
 WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL,WorkItemId bigint NOT NULL,
 ClaimGeneration bigint NOT NULL,ClaimToken uniqueidentifier NOT NULL,ExecutionId uniqueidentifier NOT NULL,
 State varchar(24) COLLATE Latin1_General_100_BIN2 NOT NULL,IsOccupied bit NOT NULL,AttemptNonce uniqueidentifier NULL,
 BoundPrincipalId int NULL,CreatedAtUtc datetime2(7) NOT NULL,EndedAtUtc datetime2(7) NULL,
 CONSTRAINT UQ_WorkerSlotReservation_Execution UNIQUE(ExecutionId),
 CONSTRAINT UQ_WorkerSlotReservation_Claim UNIQUE(WorkItemId,ClaimGeneration),
 CONSTRAINT FK_WorkerSlotReservation_WorkerRegistration FOREIGN KEY(WorkerId,WorkerGeneration) REFERENCES toolbelt_core.WorkerRegistration(WorkerId,WorkerGeneration),
 CONSTRAINT FK_WorkerSlotReservation_WorkItem FOREIGN KEY(WorkItemId) REFERENCES toolbelt_core.WorkItem(WorkItemId),
 CONSTRAINT CK_WorkerSlotReservation_State CHECK(State IN('RESERVED','RUNNING','STOP_REQUESTED','STOPPING','UNKNOWN','COMMITTED','ROLLED_BACK','CLOSED')));
IF OBJECT_ID(N'toolbelt_core.WorkerExecutionDisposition',N'U') IS NULL
 CREATE TABLE toolbelt_core.WorkerExecutionDisposition
 (WorkItemId bigint NOT NULL CONSTRAINT PK_WorkerExecutionDisposition PRIMARY KEY,
 SlotReservationId uniqueidentifier NOT NULL,IsHeld bit NOT NULL,StopStatus varchar(24) COLLATE Latin1_General_100_BIN2 NOT NULL,
 HoldVersion rowversion NOT NULL,
 CONSTRAINT FK_WorkerExecutionDisposition_WorkItem FOREIGN KEY(WorkItemId) REFERENCES toolbelt_core.WorkItem(WorkItemId),
 CONSTRAINT FK_WorkerExecutionDisposition_Reservation FOREIGN KEY(SlotReservationId) REFERENCES toolbelt_core.WorkerSlotReservation(SlotReservationId),
 CONSTRAINT CK_WorkerExecutionDisposition_Stop CHECK(StopStatus IN('NONE','REQUESTED','STOPPING','ROLLED_BACK_HELD','ALREADY_COMMITTED','UNKNOWN')));
IF OBJECT_ID(N'toolbelt_core.WorkerExecutionCommitWitness',N'U') IS NULL
 CREATE TABLE toolbelt_core.WorkerExecutionCommitWitness
 (SlotReservationId uniqueidentifier NOT NULL CONSTRAINT PK_WorkerExecutionCommitWitness PRIMARY KEY,
 AttemptNonce uniqueidentifier NOT NULL,ExecutionId uniqueidentifier NOT NULL,
 ClaimGeneration bigint NOT NULL,RecordedAtUtc datetime2(7) NOT NULL,
 CONSTRAINT FK_WorkerExecutionCommitWitness_Reservation FOREIGN KEY(SlotReservationId) REFERENCES toolbelt_core.WorkerSlotReservation(SlotReservationId));
GO
