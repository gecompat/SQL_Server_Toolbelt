SET NOCOUNT ON;

CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestRemoveWorkType
AS
BEGIN
    SET NOCOUNT ON;
END;

EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = 'test.remove'
    , @HandlerSchema = N'toolbelt_core'
    , @HandlerProcedure = N'USP_TestRemoveWorkType';

BEGIN TRY
    EXEC toolbelt_core.USP_RemoveWorkType
          @WorkTypeName = 'test.remove'
        , @AllowDelete = 1;
    THROW 52560, N'Ein aktiver Work Type durfte nicht entfernt werden.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 52560 OR ERROR_NUMBER() <> 51526
        THROW;
END CATCH;

IF NOT EXISTS (SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName = 'test.remove' AND IsEnabled = 1)
    THROW 52561, N'Der abgelehnte Remove-Aufruf veränderte den aktiven Work Type.', 1;
IF @@TRANCOUNT <> 0 OR XACT_STATE() <> 0
    THROW 52562, N'Der abgelehnte Remove-Aufruf hinterließ einen Transaktionszustand.', 1;

EXEC toolbelt_core.USP_DisableWorkType
      @WorkTypeName = 'test.remove'
    , @DisabledReason = N'synthetic removal test';

DECLARE @CurrentRowVersion binary(8) =
(
    SELECT CONVERT(binary(8), RowVersion)
    FROM toolbelt_core.WorkType
    WHERE WorkTypeName = 'test.remove'
);

BEGIN TRY
    EXEC toolbelt_core.USP_RemoveWorkType
          @WorkTypeName = 'test.remove'
        , @ExpectedRowVersion = @CurrentRowVersion
        , @AllowDelete = 0;
    THROW 52563, N'@AllowDelete = 0 hätte die Entfernung ablehnen müssen.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 52563 OR ERROR_NUMBER() <> 51527
        THROW;
END CATCH;

BEGIN TRY
    EXEC toolbelt_core.USP_RemoveWorkType
          @WorkTypeName = 'test.remove'
        , @ExpectedRowVersion = 0x0000000000000000
        , @AllowDelete = 1;
    THROW 52564, N'Eine veraltete RowVersion hätte die Entfernung ablehnen müssen.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 52564 OR ERROR_NUMBER() <> 51525
        THROW;
END CATCH;

BEGIN TRANSACTION;
EXEC toolbelt_core.USP_RemoveWorkType
      @WorkTypeName = 'test.remove'
    , @ExpectedRowVersion = @CurrentRowVersion
    , @AllowDelete = 1;
IF EXISTS (SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName = 'test.remove')
BEGIN
    ROLLBACK TRANSACTION;
    THROW 52565, N'Der Work Type wurde innerhalb der Caller-Transaktion nicht entfernt.', 1;
END;
ROLLBACK TRANSACTION;

IF NOT EXISTS (SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName = 'test.remove' AND IsEnabled = 0)
    THROW 52566, N'Caller-Rollback stellte den entfernten Work Type nicht wieder her.', 1;

CREATE TABLE dbo.TbxRemoveParent(Id int NOT NULL CONSTRAINT PK_TbxRemoveParent PRIMARY KEY);
CREATE TABLE dbo.TbxRemoveChild
(
      Id int NOT NULL
    , ParentId int NOT NULL
    , CONSTRAINT FK_TbxRemoveChild_Parent FOREIGN KEY(ParentId) REFERENCES dbo.TbxRemoveParent(Id)
);

SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.TbxRemoveChild(Id, ParentId) VALUES (1, 999);
    THROW 52567, N'Der synthetische Foreign-Key-Fehler blieb aus.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 52567
        THROW;
    IF XACT_STATE() <> -1
        THROW 52568, N'Die Caller-Transaktion ist nicht uncommittable.', 1;

    BEGIN TRY
        EXEC toolbelt_core.USP_RemoveWorkType
              @WorkTypeName = 'test.remove'
            , @AllowDelete = 1;
        THROW 52569, N'Remove hätte im uncommittable Caller abgelehnt werden müssen.', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 52569 OR ERROR_NUMBER() <> 51528
            THROW;
    END CATCH;

    ROLLBACK TRANSACTION;
END CATCH;
SET XACT_ABORT OFF;

DROP TABLE dbo.TbxRemoveChild;
DROP TABLE dbo.TbxRemoveParent;

CREATE TABLE #Removed
(
    Dummy int NULL
);
EXEC toolbelt_core.USP_RemoveWorkType
      @WorkTypeName = 'test.remove'
    , @ExpectedRowVersion = @CurrentRowVersion
    , @AllowDelete = 1
    , @ResultTable = N'#Removed'
    , @KeepData = 0;

IF EXISTS (SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName = 'test.remove')
    THROW 52570, N'Der deaktivierte Work Type wurde nicht endgültig entfernt.', 1;
IF NOT EXISTS (SELECT 1 FROM #Removed WHERE WorkTypeName = 'test.remove' AND IsEnabled = 0)
    THROW 52571, N'Die ResultTable enthält nicht die entfernte Work-Type-Zeile.', 1;

BEGIN TRY
    EXEC toolbelt_core.USP_RemoveWorkType
          @WorkTypeName = 'test.remove'
        , @AllowDelete = 1;
    THROW 52572, N'Ein nicht registrierter Work Type hätte abgelehnt werden müssen.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 52572 OR ERROR_NUMBER() <> 51524
        THROW;
END CATCH;

DROP PROCEDURE toolbelt_core.USP_TestRemoveWorkType;
PRINT N'Work Type Remove Contract: erfolgreich';
