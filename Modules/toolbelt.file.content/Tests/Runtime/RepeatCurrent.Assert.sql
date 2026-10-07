-- Mengenvergleich in beide Richtungen, einschließlich exakter Bytes und NULLs.
SET NOCOUNT ON;
DECLARE @Phase int = (SELECT Phase FROM #tbx_FileContentRepeat_State);
IF (SELECT COUNT(*) FROM #tbx_FileContentRepeat_Snapshot WHERE Phase = @Phase) <> 2
    THROW 52941, N'Der Repeat-Snapshot ist unvollständig.', 1;
IF EXISTS
   (SELECT Category, Payload FROM #tbx_FileContentRepeat_Snapshot WHERE Phase = 0
    EXCEPT SELECT Category, Payload FROM #tbx_FileContentRepeat_Snapshot WHERE Phase = @Phase)
   OR EXISTS
   (SELECT Category, Payload FROM #tbx_FileContentRepeat_Snapshot WHERE Phase = @Phase
    EXCEPT SELECT Category, Payload FROM #tbx_FileContentRepeat_Snapshot WHERE Phase = 0)
    THROW 52942, N'Der Repeat hat Allowlist-Daten, Identity oder Katalogmetadaten verändert.', 1;

IF NOT EXISTS
   (SELECT 1 FROM sys.extended_properties
    WHERE class = 1 AND major_id = OBJECT_ID(N'toolbelt_file.FileContentRootAllowlist', N'U')
      AND minor_id = 0 AND name = N'MS_Description'
      AND CONVERT(varbinary(8000), CONVERT(nvarchar(4000), value)) =
          CONVERT(varbinary(8000), N'Allowlist der Root-Pfade für toolbelt.file.content. Pfade müssen absolut sein; UNC-Pfade sind erlaubt.'))
    THROW 52943, N'Der Repeat hat die kanonische Tabellenbeschreibung nicht aktualisiert.', 1;
IF @@TRANCOUNT <> 0
    THROW 52944, N'Der Repeat hat eine offene Transaktion hinterlassen.', 1;
IF XACT_STATE() <> 0
    THROW 52944, N'Der Repeat hat einen unerwarteten Transaktionszustand hinterlassen.', 1;
GO
