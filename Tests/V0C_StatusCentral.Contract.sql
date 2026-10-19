-- SQLCMD: ToolbeltDatabase bezeichnet die separat zentral installierten
-- fünf Statusmodule. Diesen Test in einer anderen, eigenen Consumer-DB starten.
SET NOCOUNT ON;
IF DB_NAME() = N'$(ToolbeltDatabase)'
    THROW 52998, N'Der Statusvertrag muss datenbankübergreifend geprüft werden.', 11;
IF (SELECT COUNT(*) FROM [$(ToolbeltDatabase)].toolbelt_core.TVF_GenerateSeriesBigIntStatus(1, 3, 1)
    WHERE Status = 'OK' AND Value BETWEEN 1 AND 3) <> 3
    THROW 52998, N'Zentraler Series-Status fehlgeschlagen.', 12;
IF NOT EXISTS (SELECT 1 FROM [$(ToolbeltDatabase)].toolbelt_core.TVF_GenerateSeriesBigIntStatus(1, 1000001, 1)
               WHERE Status = 'LIMIT' AND Value IS NULL)
    THROW 52998, N'Zentrales Series-Limit fehlgeschlagen.', 13;
IF NOT EXISTS (SELECT 1 FROM [$(ToolbeltDatabase)].toolbelt_conversion.TVF_Base64EncodeStatus(0x61, 0)
               WHERE Status = 'OK' AND EncodedValue = 'YQ==')
    THROW 52998, N'Zentrales Base64-Encode fehlgeschlagen.', 14;
IF NOT EXISTS (SELECT 1 FROM [$(ToolbeltDatabase)].toolbelt_conversion.TVF_Base64DecodeStatus('YQ==')
               WHERE Status = 'OK' AND DecodedValue = 0x61)
    THROW 52998, N'Zentrales Base64-Decode fehlgeschlagen.', 15;
IF (SELECT COUNT(*) FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_SplitByCharactersStatus(N'a,b', N',', 1)
    WHERE Status = 'OK' AND ((Ordinal = 1 AND Value = N'a') OR (Ordinal = 2 AND Value = N'b'))) <> 2
    THROW 52998, N'Zentraler Split fehlgeschlagen.', 16;
IF NOT EXISTS (SELECT 1 FROM [$(ToolbeltDatabase)].toolbelt_conversion.TVF_UriComponentEncodeStatus(N'a b')
               WHERE Status = 'OK' AND EncodedValue = N'a%20b')
    THROW 52998, N'Zentrales URI-Encode fehlgeschlagen.', 17;
IF NOT EXISTS (SELECT 1 FROM [$(ToolbeltDatabase)].toolbelt_conversion.TVF_UriComponentDecodeStatus(N'a%20b')
               WHERE Status = 'OK' AND DecodedValue = N'a b')
    THROW 52998, N'Zentrales URI-Decode fehlgeschlagen.', 18;
IF NOT EXISTS (SELECT 1 FROM [$(ToolbeltDatabase)].toolbelt_json.TVF_JsonPathExistsStatus(N'{"a":null}', N'$.a')
               WHERE Status = 'FOUND' AND PathExists = 1)
    THROW 52998, N'Zentraler JSON Path fehlgeschlagen.', 19;
PRINT N'V0C_STATUS_CROSS_DATABASE_PASS';
GO
