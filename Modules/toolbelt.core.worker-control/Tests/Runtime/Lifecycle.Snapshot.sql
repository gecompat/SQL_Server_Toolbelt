:On Error exit
SET NOCOUNT ON;
-- Nur lokale Sessiontemps; keine privaten Daten als Repository-/Evidenzartefakte.
DROP TABLE IF EXISTS #LifeBeforeWorkItem;
SELECT [WorkItemId],[WorkTypeId],[PayloadJson],[Status],[EnqueuedAtUtc],[EnqueuedBy],[ClaimedAtUtc],[ClaimedBy],[ClaimToken],[ClaimGeneration],[LeaseDurationSeconds],[LeaseUntilUtc],[LastHeartbeatAtUtc],[RecoveryCount],[LastRecoveredAtUtc],[LastRecoveredBy],[CompletedAtUtc],[CompletedBy],[FailedAtUtc],[FailedBy],[FailureCode],[FailureMessage],[RowVersion],[ExecutionGroup],[Priority],[ExecutionMode],[IdempotencyKey],[MaxAttempts],[RetryBaseDelaySeconds],[RetryMaxDelaySeconds],[RetryCycleNumber],[CycleAttemptCount],[NextAttemptAtUtc],[LastErrorCode],[LastErrorMessage],[LastRetryScheduledAtUtc],[LastRetryScheduledBy],[DeadLetteredAtUtc],[DeadLetteredBy],[LastRequeuedAtUtc],[LastRequeuedBy],[LastRequeueReason],[BarrierEpoch],[ManagedReservationId],[ManagedHold],[ManagedCompletionNonce] INTO #LifeBeforeWorkItem FROM toolbelt_core.WorkItem;
DROP TABLE IF EXISTS #LifeBeforeWorkQueueManagedGate;
SELECT GateId,ManagedEnabled,AdmissionToken,PendingReservationId INTO #LifeBeforeWorkQueueManagedGate FROM toolbelt_core.WorkQueueManagedGate;
DROP TABLE IF EXISTS #LifeBeforeWorkerControlConfiguration;
SELECT ConfigurationId,MaxConcurrentExecutions,HeartbeatSeconds,UnreachableSeconds,CONVERT(binary(8),ConfigVersion) ConfigVersion INTO #LifeBeforeWorkerControlConfiguration FROM toolbelt_core.WorkerControlConfiguration;
DROP TABLE IF EXISTS #LifeBeforeWorkerRegistration;
SELECT WorkerId,WorkerGeneration,WorkerToken,OwnerPrincipalId,ProviderKind,State,AdmissionPaused,Capacity,RunMode,LastHeartbeatAtUtc,HeartbeatSeconds,UnreachableSeconds INTO #LifeBeforeWorkerRegistration FROM toolbelt_core.WorkerRegistration;
DROP TABLE IF EXISTS #LifeBeforeWorkerSlotReservation;
SELECT SlotReservationId,WorkerId,WorkerGeneration,WorkItemId,ClaimGeneration,ClaimToken,ExecutionId,State,IsOccupied,AttemptNonce,BoundPrincipalId,CreatedAtUtc,EndedAtUtc INTO #LifeBeforeWorkerSlotReservation FROM toolbelt_core.WorkerSlotReservation;
DROP TABLE IF EXISTS #LifeBeforeWorkerExecutionDisposition;
SELECT WorkItemId,SlotReservationId,IsHeld,StopStatus,CONVERT(binary(8),HoldVersion) HoldVersion INTO #LifeBeforeWorkerExecutionDisposition FROM toolbelt_core.WorkerExecutionDisposition;
DROP TABLE IF EXISTS #LifeBeforeWorkerExecutionCommitWitness;
SELECT SlotReservationId,AttemptNonce,ExecutionId,ClaimGeneration,RecordedAtUtc INTO #LifeBeforeWorkerExecutionCommitWitness FROM toolbelt_core.WorkerExecutionCommitWitness;
