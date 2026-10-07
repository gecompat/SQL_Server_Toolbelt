-- Bidirektionaler Bytevergleich: kein collation-/paddingabhängiger Zeilenvergleich.
SET NOCOUNT ON;
DECLARE @Phase int = (SELECT Phase FROM #tbx_CancellationRepeat_State);
IF (SELECT COUNT(*) FROM #tbx_CancellationRepeat_Snapshot WHERE Phase = @Phase) <> 2
    THROW 52742, N'Der Cancellation-Repeat-Snapshot ist unvollständig.', 1;
IF EXISTS
   (SELECT Category, Payload FROM #tbx_CancellationRepeat_Snapshot WHERE Phase = 0
    EXCEPT SELECT Category, Payload FROM #tbx_CancellationRepeat_Snapshot WHERE Phase = @Phase)
   OR EXISTS
   (SELECT Category, Payload FROM #tbx_CancellationRepeat_Snapshot WHERE Phase = @Phase
    EXCEPT SELECT Category, Payload FROM #tbx_CancellationRepeat_Snapshot WHERE Phase = 0)
    THROW 52743, N'Der Repeat hat Cancellation-Zeilen, Rowversions oder Katalogmetadaten verändert.', 1;
IF @@TRANCOUNT <> 0
    THROW 52746, N'Der Cancellation-Repeat hat eine offene Transaktion hinterlassen.', 1;
IF XACT_STATE() <> 0
    THROW 52746, N'Der Cancellation-Repeat hat einen unerwarteten Transaktionszustand hinterlassen.', 1;
GO
