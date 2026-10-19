-- Nur in einer eigenen disposable Testdatenbank ausführen, nachdem Series,
-- Base64, Split Characters, URI Component und JSON Path installiert wurden.
-- Keine Serverlogins oder Serverrechte; die Testidentität lebt nur in der DB.
SET NOCOUNT ON;
IF USER_ID(N'TBX_V0StatusReader') IS NOT NULL
    THROW 52998, N'Die synthetische Testidentität ist bereits belegt.', 1;

CREATE USER TBX_V0StatusReader WITHOUT LOGIN;
BEGIN TRY
    GRANT SELECT ON OBJECT::toolbelt_core.TVF_GenerateSeriesBigIntStatus TO TBX_V0StatusReader;
    GRANT SELECT ON OBJECT::toolbelt_conversion.TVF_Base64EncodeStatus TO TBX_V0StatusReader;
    GRANT SELECT ON OBJECT::toolbelt_conversion.TVF_Base64DecodeStatus TO TBX_V0StatusReader;
    GRANT SELECT ON OBJECT::toolbelt_string.TVF_SplitByCharactersStatus TO TBX_V0StatusReader;
    GRANT SELECT ON OBJECT::toolbelt_conversion.TVF_UriComponentEncodeStatus TO TBX_V0StatusReader;
    GRANT SELECT ON OBJECT::toolbelt_conversion.TVF_UriComponentDecodeStatus TO TBX_V0StatusReader;
    GRANT SELECT ON OBJECT::toolbelt_json.TVF_JsonPathExistsStatus TO TBX_V0StatusReader;
    DENY SELECT ON OBJECT::toolbelt_core.TVF_GenerateSeriesBigInt TO TBX_V0StatusReader;
    DENY SELECT ON OBJECT::toolbelt_core.TVF_GenerateSeriesInt TO TBX_V0StatusReader;

    EXECUTE AS USER = N'TBX_V0StatusReader';
    IF ISNULL(HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CONTROL'), 1) <> 0
       OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core.TVF_GenerateSeriesBigInt', N'OBJECT', N'SELECT'), 1) <> 0
       OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core.TVF_GenerateSeriesInt', N'OBJECT', N'SELECT'), 1) <> 0
        THROW 52998, N'Die Testidentität besitzt unerwartete Rechte.', 2;

    IF (SELECT COUNT(*) FROM toolbelt_core.TVF_GenerateSeriesBigIntStatus(1, 3, 1)
        WHERE Status = 'OK' AND Value BETWEEN 1 AND 3) <> 3
        THROW 52998, N'Series-Status mit Minimalrechten fehlgeschlagen.', 3;
    IF NOT EXISTS (SELECT 1 FROM toolbelt_core.TVF_GenerateSeriesBigIntStatus(1, 1000001, 1)
                   WHERE Status = 'LIMIT' AND Value IS NULL)
        THROW 52998, N'Series-Limit mit Minimalrechten fehlgeschlagen.', 4;
    IF NOT EXISTS (SELECT 1 FROM toolbelt_conversion.TVF_Base64EncodeStatus(0x61, 0)
                   WHERE Status = 'OK' AND EncodedValue = 'YQ==')
        THROW 52998, N'Base64-Encode mit Minimalrechten fehlgeschlagen.', 5;
    IF NOT EXISTS (SELECT 1 FROM toolbelt_conversion.TVF_Base64DecodeStatus('YQ==')
                   WHERE Status = 'OK' AND DecodedValue = 0x61)
        THROW 52998, N'Base64-Decode mit Minimalrechten fehlgeschlagen.', 6;
    IF (SELECT COUNT(*) FROM toolbelt_string.TVF_SplitByCharactersStatus(N'a,b', N',', 1)
        WHERE Status = 'OK' AND ((Ordinal = 1 AND Value = N'a') OR (Ordinal = 2 AND Value = N'b'))) <> 2
        THROW 52998, N'Split mit Minimalrechten fehlgeschlagen.', 7;
    IF NOT EXISTS (SELECT 1 FROM toolbelt_conversion.TVF_UriComponentEncodeStatus(N'a b')
                   WHERE Status = 'OK' AND EncodedValue = N'a%20b')
        THROW 52998, N'URI-Encode mit Minimalrechten fehlgeschlagen.', 8;
    IF NOT EXISTS (SELECT 1 FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(N'a%20b')
                   WHERE Status = 'OK' AND DecodedValue = N'a b')
        THROW 52998, N'URI-Decode mit Minimalrechten fehlgeschlagen.', 9;
    IF NOT EXISTS (SELECT 1 FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{"a":null}', N'$.a')
                   WHERE Status = 'FOUND' AND PathExists = 1)
        THROW 52998, N'JSON Path mit Minimalrechten fehlgeschlagen.', 10;
    REVERT;
END TRY
BEGIN CATCH
    IF USER_NAME() = N'TBX_V0StatusReader' REVERT;
    DROP USER TBX_V0StatusReader;
    THROW;
END CATCH;
DROP USER TBX_V0StatusReader;
PRINT N'V0C_STATUS_MINIMUM_PERMISSIONS_PASS';
GO
