-- Neutrale Queueintegration ohne Rückabhängigkeit zum Controlprovider.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'toolbelt_core.WorkQueueManagedGate',N'U') IS NULL
BEGIN
 CREATE TABLE toolbelt_core.WorkQueueManagedGate
 (GateId tinyint NOT NULL CONSTRAINT PK_WorkQueueManagedGate PRIMARY KEY,
  ManagedEnabled bit NOT NULL,AdmissionToken uniqueidentifier NOT NULL,PendingReservationId uniqueidentifier NULL,
  CONSTRAINT CK_WorkQueueManagedGate_Id CHECK(GateId=1));
 INSERT toolbelt_core.WorkQueueManagedGate VALUES(1,0,NEWID(),NULL);
END;
-- Additiver Upgrade: alle bisherigen Aufträge, Claims und History bleiben erhalten.
IF COL_LENGTH(N'toolbelt_core.WorkItem',N'ManagedReservationId') IS NULL
 ALTER TABLE toolbelt_core.WorkItem ADD ManagedReservationId uniqueidentifier NULL,
  ManagedHold bit NOT NULL CONSTRAINT DF_WorkItem_ManagedHold DEFAULT(0),
  ManagedCompletionNonce uniqueidentifier NULL;
GO
