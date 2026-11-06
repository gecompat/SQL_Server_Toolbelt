-- Bidirektionaler Bytevergleich: kein collation-/paddingabhängiger Zeilenvergleich.
SET NOCOUNT ON;
DECLARE @Phase int = (SELECT Phase FROM #tbx_CancellationRepeat_State);
IF (SELECT COUNT(*) FROM #tbx_CancellationRepeat_Snapshot WHERE Phase = @Phase) <> 2
    THROW 52742, N'Der Cancellation-Repeat-Snapshot ist unvollständig.', 1;
BEGIN TRY
 IF EXISTS
   (SELECT Category, Payload FROM #tbx_CancellationRepeat_Snapshot WHERE Phase = 0
    EXCEPT SELECT Category, Payload FROM #tbx_CancellationRepeat_Snapshot WHERE Phase = @Phase)
   OR EXISTS
   (SELECT Category, Payload FROM #tbx_CancellationRepeat_Snapshot WHERE Phase = @Phase
    EXCEPT SELECT Category, Payload FROM #tbx_CancellationRepeat_Snapshot WHERE Phase = 0)
    THROW 52743, N'Der Repeat hat Cancellation-Zeilen, Rowversions oder Katalogmetadaten verändert.', 1;
 IF @Phase IN (10, 11, 12)
    THROW 52747, N'Das tatsächliche Repeat-Orakel hat die isolierte Principaländerung nicht erkannt.', 1;
END TRY
BEGIN CATCH
 IF @Phase IN (10, 11, 12) AND ERROR_NUMBER() = 52743 AND ERROR_STATE() = 1
 BEGIN
    -- THROW unter XACT_ABORT ON darf die eigene TX uncommittable machen.
    IF @@TRANCOUNT <> 1 OR XACT_STATE() NOT IN (-1, 1)
        THROW 52748, N'Die Gegenprobe besitzt keine eigene Rollbacktransaktion.', 1;
    ROLLBACK TRANSACTION;
    PRINT N'Execution Cancellation owner-field counterexample: ' + CONVERT(nvarchar(2), @Phase) + N' successful';
    RETURN;
 END;
 THROW;
END CATCH;
IF @@TRANCOUNT <> 0
    THROW 52746, N'Der Cancellation-Repeat hat eine offene Transaktion hinterlassen.', 1;
IF XACT_STATE() <> 0
    THROW 52746, N'Der Cancellation-Repeat hat einen unerwarteten Transaktionszustand hinterlassen.', 1;
GO
