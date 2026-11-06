-- Tatsächliches Capture-/Assert-Orakel, drei jeweils zurückgerollte Mutationen.
-- Nur die Rowversiondifferenz im privaten Snapshot wird kompensiert, damit
-- jedes fehlende Principal-Feld trotz der automatischen Rowversion auffällt.
BEGIN TRANSACTION;
UPDATE #tbx_CancellationRepeat_State SET Phase = 10;
UPDATE toolbelt_core.ExecutionCancellation SET RequestedByPrincipalId = 1003
WHERE ExecutionId = '00000000-0000-0000-0000-000000000042';
GO
:r ../Tests/Runtime/RepeatCurrent.Capture.sql
:r ../Tests/Runtime/RepeatCurrent.NormalizeNegativeVersion.sql
:r ../Tests/Runtime/RepeatCurrent.Assert.sql

BEGIN TRANSACTION;
UPDATE #tbx_CancellationRepeat_State SET Phase = 11;
UPDATE toolbelt_core.ExecutionCancellation SET RequestedByPrincipalSid = 0x010204
WHERE ExecutionId = '00000000-0000-0000-0000-000000000042';
GO
:r ../Tests/Runtime/RepeatCurrent.Capture.sql
:r ../Tests/Runtime/RepeatCurrent.NormalizeNegativeVersion.sql
:r ../Tests/Runtime/RepeatCurrent.Assert.sql

BEGIN TRANSACTION;
UPDATE #tbx_CancellationRepeat_State SET Phase = 12;
UPDATE toolbelt_core.ExecutionCancellation SET RequestedByPrincipalCreatedAt = '2026-01-02T03:04:05.007'
WHERE ExecutionId = '00000000-0000-0000-0000-000000000042';
GO
:r ../Tests/Runtime/RepeatCurrent.Capture.sql
:r ../Tests/Runtime/RepeatCurrent.NormalizeNegativeVersion.sql
:r ../Tests/Runtime/RepeatCurrent.Assert.sql

IF @@TRANCOUNT <> 0 OR XACT_STATE() <> 0
    THROW 52748, N'Die Principalgegenproben haben ihre Transaktion nicht beendet.', 2;
IF (SELECT Phase FROM #tbx_CancellationRepeat_State) <> 0
 OR (SELECT COUNT(*) FROM #tbx_CancellationRepeat_Snapshot) <> 2
    THROW 52748, N'Die Principalgegenproben haben die Snapshotbaseline verändert.', 3;
GO
