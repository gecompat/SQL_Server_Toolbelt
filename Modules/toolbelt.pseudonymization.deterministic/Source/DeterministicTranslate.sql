-- ============================================================================
-- Objekt:          toolbelt_pseudonymization.TVF_DeterministicTranslate
-- Typ:             Echte Inline Table-valued Function, portables T-SQL.
-- Zweck:           Formaterhaltende Vorwärtstransformation synthetischer Kennungen.
-- Vertrag:         Documentation/Architecture/DETERMINISTIC_TRANSLATE_CONTRACT.md
-- Parameter:       Value nvarchar(max), MappingVersion int positiv, Seed bigint=0,
--                  AllowedSeparators nvarchar(max)=N'', Profile=N'standard'.
-- Resultset:       Genau eine Zeile: Value nvarchar(max) NULL, ErrorCode int NOT NULL.
-- Dependencies:    Vorhandener interner TVF_DeterministicIntegerBytes-Encoder.
-- Rechte:          SELECT; keine Rechteausweitung, I/O, CLR oder Persistenz.
-- Versionen:       SQL Server 2019/2022/2025, Windows und Linux als Zielmatrix.
-- Collation:       Latin1_General_100_BIN2 an allen TRANSLATE-Operanden und Output.
-- Fehler:          NULL-Value zuerst0; Version1, Seed2, Profile10, Separatoren11,
--                  Inputbudget12, unbekanntes Zeichen13; kein Teilwert bei Fehler.
-- Performance:     36 logische Hashframes, kleine Ränge; Input2/16MiB UTF-16.
-- Einschränkungen: Rückführbare Bijektion, kein Decode/Secret/Sicherheitsversprechen;
--                  Länge, Case, Muster und Häufigkeit bleiben sichtbar.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_pseudonymization].[TVF_DeterministicTranslate]
(
      @Value             nvarchar(max)
    , @MappingVersion    int
    , @Seed              bigint = 0
    , @AllowedSeparators nvarchar(max) = N''
    , @Profile           nvarchar(max) = N'standard'
)
RETURNS TABLE
AS
RETURN
(
    WITH Parameters AS
    (
        SELECT InputBytes = DATALENGTH(@Value), SeparatorBytes = DATALENGTH(@AllowedSeparators)
            -- SQL-Textgleichheit ignoriert trailing Spaces auch unter BIN2.
            , ByteLimit = CONVERT(bigint, CASE
                WHEN DATALENGTH(@Profile) = 16 AND CONVERT(varbinary(max), @Profile) = CONVERT(varbinary(max), N'standard') THEN 2097152
                WHEN DATALENGTH(@Profile) = 10 AND CONVERT(varbinary(max), @Profile) = CONVERT(varbinary(max), N'large') THEN 16777216
                ELSE 0 END)
    ), Positions AS
    (
        SELECT n FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),
            (12),(13),(14),(15),(16),(17),(18),(19),(20),(21),(22),(23),(24),
            (25),(26),(27),(28),(29),(30),(31),(32),(33)) AS positions(n)
    ), SeparatorCharacters AS
    (
        SELECT positions.n, CodeUnit = UNICODE(SUBSTRING(
            CASE WHEN parameters.SeparatorBytes BETWEEN 0 AND 66
                THEN ISNULL(@AllowedSeparators, N'') ELSE CONVERT(nvarchar(max), N'') END
                COLLATE Latin1_General_100_BIN2, positions.n, 1))
        FROM Parameters AS parameters
        CROSS JOIN Positions AS positions
        WHERE positions.n <= parameters.SeparatorBytes / 2
    ), SeparatorValidation AS
    (
        SELECT InvalidCharacters = ISNULL(MAX(CASE
                WHEN CodeUnit BETWEEN 32 AND 126
                    AND CodeUnit NOT BETWEEN 48 AND 57
                    AND CodeUnit NOT BETWEEN 65 AND 90
                    AND CodeUnit NOT BETWEEN 97 AND 122 THEN 0 ELSE 1 END), 0)
            , CharacterCount = COUNT(*), DistinctCount = COUNT(DISTINCT CodeUnit)
        FROM SeparatorCharacters
    ), Configuration AS
    (
        SELECT parameters.InputBytes, parameters.ByteLimit
            , ConfigurationError = CONVERT(int, CASE
                WHEN @Value IS NULL THEN 0
                WHEN @MappingVersion IS NULL OR @MappingVersion <= 0 THEN 1
                WHEN @Seed IS NULL THEN 2
                WHEN parameters.ByteLimit = 0 THEN 10
                WHEN parameters.SeparatorBytes IS NULL OR parameters.SeparatorBytes > 66
                    OR validation.InvalidCharacters <> 0
                    OR validation.CharacterCount <> validation.DistinctCount THEN 11
                WHEN parameters.InputBytes > parameters.ByteLimit THEN 12
                ELSE 0 END)
            , SafeSeparators = CONVERT(nvarchar(max), CASE
                WHEN parameters.SeparatorBytes BETWEEN 0 AND 66
                    AND validation.InvalidCharacters = 0
                    AND validation.CharacterCount = validation.DistinctCount
                THEN @AllowedSeparators ELSE N'' END) COLLATE Latin1_General_100_BIN2
        FROM Parameters AS parameters
        CROSS JOIN SeparatorValidation AS validation
    ), SafeConfiguration AS
    (
        -- WHERE/CASE am Ergebnis sind keine Optimizerbarriere. Jeder native
        -- Operand wird daher bereits vor TRANSLATE/REPLICATE sicher begrenzt.
        SELECT configuration.ConfigurationError, configuration.SafeSeparators
            , SafeValue = CONVERT(nvarchar(max), CASE
                WHEN configuration.ConfigurationError = 0 AND @Value IS NOT NULL
                    AND configuration.InputBytes BETWEEN 0 AND configuration.ByteLimit
                THEN @Value ELSE N'' END) COLLATE Latin1_General_100_BIN2
            , SafeCount = CONVERT(int, CASE
                WHEN configuration.ConfigurationError = 0 AND @Value IS NOT NULL
                    AND configuration.InputBytes BETWEEN 0 AND configuration.ByteLimit
                    AND configuration.InputBytes <= 16777216
                THEN configuration.InputBytes / 2 ELSE 0 END)
        FROM Configuration AS configuration
    ), Alphabet AS
    (
        SELECT kind.n AS AlphabetKind, positions.n - 1 AS OriginalOrdinal
        FROM (VALUES (0),(1)) AS kind(n)
        CROSS JOIN Positions AS positions
        WHERE positions.n <= CASE WHEN kind.n = 0 THEN 26 ELSE 10 END
    ), HashFrames AS
    (
        SELECT alphabet.AlphabetKind, alphabet.OriginalOrdinal
            , Digest = HASHBYTES('SHA2_256', CONVERT(varbinary(max), 0x5442584454524E31)
                + SUBSTRING(versionBytes.Bytes, 5, 4) + seedBytes.Bytes
                + SUBSTRING(kindBytes.Bytes, 8, 1) + SUBSTRING(ordinalBytes.Bytes, 8, 1))
        FROM Alphabet AS alphabet
        CROSS APPLY [toolbelt_pseudonymization].[TVF_DeterministicIntegerBytes](ISNULL(@MappingVersion, 0)) AS versionBytes
        CROSS APPLY [toolbelt_pseudonymization].[TVF_DeterministicIntegerBytes](ISNULL(@Seed, 0)) AS seedBytes
        CROSS APPLY [toolbelt_pseudonymization].[TVF_DeterministicIntegerBytes](alphabet.AlphabetKind) AS kindBytes
        CROSS APPLY [toolbelt_pseudonymization].[TVF_DeterministicIntegerBytes](alphabet.OriginalOrdinal) AS ordinalBytes
    ), Ranked AS
    (
        SELECT AlphabetKind, OriginalOrdinal
            , MappingOrdinal = ROW_NUMBER() OVER (PARTITION BY AlphabetKind ORDER BY Digest, OriginalOrdinal)
        FROM HashFrames
    ), Mapping AS
    (
        SELECT AlphabetKind
            , Targets = STRING_AGG(CONVERT(nvarchar(max), SUBSTRING(
                CASE WHEN AlphabetKind = 0 THEN N'abcdefghijklmnopqrstuvwxyz' ELSE N'0123456789' END,
                OriginalOrdinal + 1, 1)), N'') WITHIN GROUP (ORDER BY MappingOrdinal)
        FROM Ranked
        GROUP BY AlphabetKind
    ), MappingStrings AS
    (
        SELECT Letters = MAX(CASE WHEN AlphabetKind = 0 THEN Targets END)
            , Digits = MAX(CASE WHEN AlphabetKind = 1 THEN Targets END)
        FROM Mapping
    ), Translated AS
    (
        SELECT safe.ConfigurationError
            , Value = TRANSLATE(safe.SafeValue COLLATE Latin1_General_100_BIN2,
                CONVERT(nvarchar(max), N'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789') COLLATE Latin1_General_100_BIN2,
                (ISNULL(mapping.Letters, N'abcdefghijklmnopqrstuvwxyz')
                    + UPPER(ISNULL(mapping.Letters, N'abcdefghijklmnopqrstuvwxyz') COLLATE Latin1_General_100_BIN2)
                    + ISNULL(mapping.Digits, N'0123456789')) COLLATE Latin1_General_100_BIN2)
            , Unknown = CONVERT(bit, CASE WHEN CONVERT(varbinary(max),
                TRANSLATE(safe.SafeValue COLLATE Latin1_General_100_BIN2,
                    (CONVERT(nvarchar(max), N'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789')
                        + safe.SafeSeparators) COLLATE Latin1_General_100_BIN2,
                    REPLICATE(CONVERT(nvarchar(max), N'A'), 62 + DATALENGTH(safe.SafeSeparators) / 2)
                        COLLATE Latin1_General_100_BIN2))
                = CONVERT(varbinary(max), REPLICATE(CONVERT(nvarchar(max), N'A'), safe.SafeCount))
                THEN 0 ELSE 1 END)
        FROM SafeConfiguration AS safe
        CROSS JOIN MappingStrings AS mapping
    )
    SELECT Value = CONVERT(nvarchar(max), CASE
            WHEN @Value IS NULL OR translated.ConfigurationError <> 0 OR translated.Unknown = 1 THEN NULL
            ELSE translated.Value END) COLLATE Latin1_General_100_BIN2
        , ErrorCode = ISNULL(CONVERT(int, CASE
            WHEN @Value IS NULL THEN 0
            WHEN translated.ConfigurationError <> 0 THEN translated.ConfigurationError
            WHEN translated.Unknown = 1 THEN 13 ELSE 0 END), 13)
    FROM Translated AS translated
);
GO
