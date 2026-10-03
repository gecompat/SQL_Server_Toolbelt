SET NOCOUNT ON;
-- Nur im genuine 1.0-Testzustand verwenden. Beide reservierten 1.1-Slots einzeln.
DECLARE @Slot sysname=N'$(FutureSlot)',@Imitate bit=CONVERT(bit,N'$(ImitateMarkers)');
IF @Slot NOT IN(N'TVF_JaroWinklerSimilarity',N'TVF_JaroWinklerSimilarityCore')
 THROW 55093,N'Unbekannter synthetischer Zukunftsslot.',2;
IF OBJECT_ID(N'toolbelt_string.'+@Slot) IS NOT NULL
 THROW 55093,N'Synthetischer Zukunftsslot ist bereits belegt.',3;
DECLARE @Sql nvarchar(max)=N'CREATE FUNCTION toolbelt_string.'+QUOTENAME(@Slot)+
 N'() RETURNS TABLE AS RETURN SELECT CONVERT(int,37) AS SyntheticValue;';
EXEC sys.sp_executesql @Sql;
IF @Imitate=1
BEGIN
 EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Managed',@value=1,@level0type=N'SCHEMA',@level0name=N'toolbelt_string',@level1type=N'FUNCTION',@level1name=@Slot;
 EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.string.edit-distance',@level0type=N'SCHEMA',@level0name=N'toolbelt_string',@level1type=N'FUNCTION',@level1name=@Slot;
 EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleVersion',@value=N'1.0.0',@level0type=N'SCHEMA',@level0name=N'toolbelt_string',@level1type=N'FUNCTION',@level1name=@Slot;
END;
-- Rootadapter bindet Definition/Marker vor Upgrade-Reject und historischem
-- Uninstall; kein stiller Drop dieses fremden Zukunftsslots durch den Installer.
