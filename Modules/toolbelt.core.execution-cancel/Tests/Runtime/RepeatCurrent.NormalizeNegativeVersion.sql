-- Ausschließlich Gegenproben: positiver Deployvergleich benutzt diese Datei nie.
SET NOCOUNT ON;
DECLARE @Phase int = (SELECT Phase FROM #tbx_CancellationRepeat_State);
IF @Phase NOT IN (10, 11, 12) OR @@TRANCOUNT <> 1 OR XACT_STATE() <> 1
    THROW 52748, N'Die isolierte Gegenprobe benötigt ihren eigenen Transaktionsscope.', 4;
DECLARE @Reference xml, @Changed xml, @Version nvarchar(32);
SELECT @Reference = CONVERT(xml, CONVERT(nvarchar(max), Payload))
FROM #tbx_CancellationRepeat_Snapshot WHERE Phase = 0 AND Category = 'rows';
SELECT @Changed = CONVERT(xml, CONVERT(nvarchar(max), Payload))
FROM #tbx_CancellationRepeat_Snapshot WHERE Phase = @Phase AND Category = 'rows';
IF @Reference.exist('/row[ExecutionId="00000000-0000-0000-0000-000000000042"]/RowVersionBytes/text()') <> 1
 OR @Changed.exist('/row[ExecutionId="00000000-0000-0000-0000-000000000042"]/RowVersionBytes/text()') <> 1
    THROW 52748, N'Der exakte synthetische Rowversionzeuge fehlt.', 5;
SET @Version = @Reference.value('(/row[ExecutionId="00000000-0000-0000-0000-000000000042"]/RowVersionBytes/text())[1]', 'nvarchar(32)');
IF DATALENGTH(@Version) <> 24
    THROW 52748, N'Der synthetische Rowversionzeuge ist nicht acht Bytes lang.', 6;
SET @Changed.modify('replace value of (/row[ExecutionId="00000000-0000-0000-0000-000000000042"]/RowVersionBytes/text())[1] with sql:variable("@Version")');
-- Beide XML-Werte gleich serialisieren; jede andere Payload bleibt unverändert.
-- Der erwartete52743-Catch rollt diese Änderungen samt persistenter Mutation zurück.
UPDATE #tbx_CancellationRepeat_Snapshot SET Payload = CONVERT(varbinary(max), CONVERT(nvarchar(max), @Reference))
WHERE Phase = 0 AND Category = 'rows';
UPDATE #tbx_CancellationRepeat_Snapshot SET Payload = CONVERT(varbinary(max), CONVERT(nvarchar(max), @Changed))
WHERE Phase = @Phase AND Category = 'rows';
GO
