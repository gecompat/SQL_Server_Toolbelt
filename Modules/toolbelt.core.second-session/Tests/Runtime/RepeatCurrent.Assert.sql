-- Bidirektionaler Bytevergleich: kein collation-/paddingabhängiger Zeilenvergleich.
SET NOCOUNT ON;
DECLARE @Phase int = (SELECT Phase FROM #tbx_SecondSessionRepeat_State);
IF (SELECT COUNT(*) FROM #tbx_SecondSessionRepeat_Snapshot WHERE Phase = @Phase) <> 2
    THROW 52671, N'Der Second-Session-Repeat-Snapshot ist unvollständig.', 1;
IF EXISTS
   (SELECT Category, Payload FROM #tbx_SecondSessionRepeat_Snapshot WHERE Phase = 0
    EXCEPT SELECT Category, Payload FROM #tbx_SecondSessionRepeat_Snapshot WHERE Phase = @Phase)
   OR EXISTS
   (SELECT Category, Payload FROM #tbx_SecondSessionRepeat_Snapshot WHERE Phase = @Phase
    EXCEPT SELECT Category, Payload FROM #tbx_SecondSessionRepeat_Snapshot WHERE Phase = 0)
    THROW 52672, N'Der Repeat hat Second-Session-Zeilen, Rowversions oder Katalogmetadaten verändert.', 1;
IF @@TRANCOUNT <> 0
    THROW 52673, N'Der Second-Session-Repeat hat eine offene Transaktion hinterlassen.', 1;
IF XACT_STATE() <> 0
    THROW 52673, N'Der Second-Session-Repeat hat einen unerwarteten Transaktionszustand hinterlassen.', 1;
GO
