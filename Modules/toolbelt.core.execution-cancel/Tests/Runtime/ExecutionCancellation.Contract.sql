SET NOCOUNT ON;

IF toolbelt_core.SVF_IsCancellationRequested('00000000-0000-0000-0000-000000000001') <> 0
    THROW 52700, N'Ein unbekannter Status muss 0 liefern.', 1;

DECLARE @Help TABLE
(
    Section varchar(32), Ordinal int, ItemName sysname NULL, SqlDataType varchar(256) NULL,
    IsRequired bit NULL, IsNullable bit NULL, DefaultValue nvarchar(4000) NULL,
    Description nvarchar(max) NULL, ExampleSql nvarchar(max) NULL
);
INSERT INTO @Help EXEC toolbelt_core.USP_RequestExecutionCancellation @Hilfe=1;
IF NOT EXISTS(SELECT 1 FROM @Help WHERE Section='DESCRIPTION')
 OR NOT EXISTS(SELECT 1 FROM @Help WHERE Section='PARAMETER' AND ItemName=N'@ExecutionId')
 OR NOT EXISTS(SELECT 1 FROM @Help WHERE Section='RESULT_COLUMN')
    THROW 52701, N'Der Help-Vertrag ist unvollständig.', 1;

DECLARE @ExecutionId uniqueidentifier;
EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@ExecutionId OUTPUT, @AllowNested=0;
EXEC toolbelt_core.USP_RequestExecutionCancellation @CancellationReason=N'synthetic contract';
IF toolbelt_core.SVF_IsCancellationRequested(@ExecutionId) <> 1
    THROW 52702, N'Die aktuelle ExecutionId wurde nicht als abgebrochen markiert.', 1;
IF NOT EXISTS
(
    SELECT 1 FROM toolbelt_core.TVF_ExecutionCancellationStatus(@ExecutionId)
    WHERE IsCancellationRequested=1 AND RequestedAtUtc IS NOT NULL
)
    THROW 52703, N'Die sichere Status-TVF ist inkonsistent.', 1;
DECLARE @FirstTime datetime2(7)=(SELECT RequestedAtUtc FROM toolbelt_core.TVF_ExecutionCancellationStatus(@ExecutionId));
EXEC toolbelt_core.USP_RequestExecutionCancellation @ExecutionId=@ExecutionId,@CancellationReason=N'ignored retry';
IF (SELECT RequestedAtUtc FROM toolbelt_core.TVF_ExecutionCancellationStatus(@ExecutionId))<>@FirstTime
    THROW 52704, N'Wiederholte Anforderungen dürfen den ersten Auditzeitpunkt nicht ändern.', 1;
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@ExecutionId;

BEGIN TRY
    EXEC toolbelt_core.USP_RequestExecutionCancellation;
    THROW 52705, N'Ein fehlender Context muss abgewiesen werden.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (52601,52705) THROW;
END CATCH;

DECLARE @TransactionalId uniqueidentifier='00000000-0000-0000-0000-000000000011';
BEGIN TRANSACTION;
BEGIN TRY
    EXEC toolbelt_core.USP_RequestExecutionCancellation @ExecutionId=@TransactionalId;
    THROW 52706, N'Eine aktive Caller-Transaktion muss abgewiesen werden.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (52600,52706) BEGIN IF XACT_STATE()<>0 ROLLBACK; THROW; END;
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
IF toolbelt_core.SVF_IsCancellationRequested(@TransactionalId)<>0
    THROW 52707,N'Der abgewiesene Transaktionsaufruf darf keine Anforderung schreiben.',1;

CREATE TABLE #tbx_ExecutionCancellation_Parent (Id int NOT NULL PRIMARY KEY);
CREATE TABLE #tbx_ExecutionCancellation_Child
(
    Id int NOT NULL PRIMARY KEY,
    ParentId int NOT NULL REFERENCES #tbx_ExecutionCancellation_Parent(Id)
);
DECLARE @UncommittableId uniqueidentifier='00000000-0000-0000-0000-000000000012';
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    INSERT INTO #tbx_ExecutionCancellation_Child(Id,ParentId) VALUES(1,1);
END TRY
BEGIN CATCH
    IF XACT_STATE() <> -1
    BEGIN
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW 52712,N'Der Test konnte keine uncommittable Caller-Transaktion herstellen.',1;
    END;
END CATCH;
BEGIN TRY
    EXEC toolbelt_core.USP_RequestExecutionCancellation @ExecutionId=@UncommittableId;
    THROW 52713,N'Eine uncommittable Caller-Transaktion muss abgewiesen werden.',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (52600,52713)
    BEGIN
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END;
END CATCH;
IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
SET XACT_ABORT OFF;
IF toolbelt_core.SVF_IsCancellationRequested(@UncommittableId)<>0
    THROW 52714,N'Der uncommittable Aufruf darf keine Anforderung schreiben.',1;

PRINT N'Execution Cancellation Contract: erfolgreich';
