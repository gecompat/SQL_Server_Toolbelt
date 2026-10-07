:On Error exit
SET NOCOUNT ON;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54961,N'Controlrepeat ließ eine Transaktion offen.',1;
IF (SELECT COUNT(*) FROM #tbx_ControlRepeatRows)<>(SELECT COUNT(*) FROM #tbx_ControlRepeatActualRows)
 OR EXISTS(SELECT * FROM #tbx_ControlRepeatRows EXCEPT SELECT * FROM #tbx_ControlRepeatActualRows)
 OR EXISTS(SELECT * FROM #tbx_ControlRepeatActualRows EXCEPT SELECT * FROM #tbx_ControlRepeatRows)
 THROW 54961,N'Repeat änderte Zeilen, History, Token, Rowversion oder Payloadbytes.',2;
IF (SELECT COUNT(*) FROM #tbx_ControlRepeatCatalog)<>(SELECT COUNT(*) FROM #tbx_ControlRepeatActualCatalog)
 OR EXISTS(SELECT * FROM #tbx_ControlRepeatCatalog EXCEPT SELECT * FROM #tbx_ControlRepeatActualCatalog)
 OR EXISTS(SELECT * FROM #tbx_ControlRepeatActualCatalog EXCEPT SELECT * FROM #tbx_ControlRepeatCatalog)
 THROW 54961,N'Repeat änderte Objektidentität, Identity, Katalog, Marker oder vorhandene Rechte.',3;
GO
