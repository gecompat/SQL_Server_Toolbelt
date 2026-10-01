-- ============================================================================
-- Objekt:          toolbelt_pseudonymization.TVF_DeterministicRangeCore
-- Zweck:           Interner, relationaler SHA256/Range-Kern mit Format V1.
-- Parameter:       Domain binary(8), Context bigint; Key varbinary(max),
--                  MappingVersion int, Seed bigint, Min bigint, Max bigint.
-- Resultset:       Value bigint NULL, ErrorCode int NOT NULL.
-- Dependencies:    interner IntegerBytes-Encoder; keine Scalar-UDF oder Assembly.
-- Versionen:       SQL Server 2019/2022/2025, Windows und Linux.
-- Performance:     Inline TVF; maximal 128 Hashkandidaten je Eingabe.
-- Collation:       ausschließlich binäre Eingabe und feste Hashbytes.
-- Einschränkungen: Interne Implementierung; keine Anonymisierung oder Sicherheit.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_pseudonymization].[TVF_DeterministicRangeCore]
(
      @Domain         binary(8)
    , @Context        bigint
    , @Key            varbinary(max)
    , @MappingVersion int
    , @Seed           bigint
    , @Min            bigint
    , @Max            bigint
)
RETURNS TABLE
AS
RETURN
(
    WITH Configuration AS
    (
        SELECT ConfigurationError = CONVERT(int, CASE
            WHEN @Key IS NULL THEN 0
            WHEN @MappingVersion IS NULL OR @MappingVersion <= 0 THEN 1
            WHEN @Seed IS NULL THEN 2
            WHEN @Min IS NULL OR @Max IS NULL OR @Min > @Max THEN 3
            WHEN DATALENGTH(@Key) = 0 OR DATALENGTH(@Key) > 8000 THEN 4
            WHEN @Domain IS NULL OR @Context IS NULL THEN 6
            ELSE 0 END)
    ), SafeConfiguration AS
    (
            -- Sichere Operanden auch bei Optimizer-Auswertung vor Filter/CASE:
            -- kein Nullnenner und kein außerhalb bigint liegender Cast.
        SELECT configuration.ConfigurationError
            , Span = CONVERT(decimal(38,0), CASE
                WHEN configuration.ConfigurationError = 0 AND @Key IS NOT NULL
                    THEN CONVERT(decimal(38,0), @Max) - CONVERT(decimal(38,0), @Min) + 1
                ELSE CONVERT(decimal(38,0), 1) END)
            , SafeMin = CONVERT(decimal(38,0), CASE
                WHEN configuration.ConfigurationError = 0 AND @Key IS NOT NULL THEN @Min ELSE 0 END)
            , Frame = CONVERT(varbinary(max), ISNULL(@Domain, 0x0000000000000000))
                + contextBytes.Bytes + SUBSTRING(versionBytes.Bytes, 5, 4)
                + seedBytes.Bytes + minBytes.Bytes + maxBytes.Bytes
                + SUBSTRING(lengthBytes.Bytes, 5, 4)
                + CASE WHEN configuration.ConfigurationError = 0 AND @Key IS NOT NULL THEN @Key ELSE CONVERT(varbinary(max), 0x00) END
        FROM Configuration AS configuration
        CROSS APPLY [toolbelt_pseudonymization].[TVF_DeterministicIntegerBytes](ISNULL(@Context, 0)) AS contextBytes
        CROSS APPLY [toolbelt_pseudonymization].[TVF_DeterministicIntegerBytes](ISNULL(@MappingVersion, 0)) AS versionBytes
        CROSS APPLY [toolbelt_pseudonymization].[TVF_DeterministicIntegerBytes](ISNULL(@Seed, 0)) AS seedBytes
        CROSS APPLY [toolbelt_pseudonymization].[TVF_DeterministicIntegerBytes](ISNULL(@Min, 0)) AS minBytes
        CROSS APPLY [toolbelt_pseudonymization].[TVF_DeterministicIntegerBytes](ISNULL(@Max, 0)) AS maxBytes
        CROSS APPLY [toolbelt_pseudonymization].[TVF_DeterministicIntegerBytes]
            (CASE WHEN configuration.ConfigurationError = 0 AND @Key IS NOT NULL THEN DATALENGTH(@Key) ELSE 1 END) AS lengthBytes
    ), Limits AS
    (
        SELECT safe.ConfigurationError, safe.Span, safe.SafeMin, safe.Frame
            -- U = 2^64. Modulo vermeidet gerundete Division bei großen Spans.
            , AcceptanceLimit = CONVERT(decimal(38,0), 18446744073709551616)
                - CONVERT(decimal(38,0), 18446744073709551616) % safe.Span
        FROM SafeConfiguration AS safe
    )
    SELECT Value = CONVERT(bigint, CASE
            WHEN limits.ConfigurationError = 0 AND @Key IS NOT NULL AND chosen.Candidate IS NOT NULL
                THEN limits.SafeMin + chosen.Candidate % limits.Span
            ELSE NULL END)
        , ErrorCode = ISNULL(CONVERT(int, CASE
            WHEN @Key IS NULL THEN 0
            WHEN limits.ConfigurationError <> 0 THEN limits.ConfigurationError
            WHEN chosen.Candidate IS NULL THEN 5
            ELSE 0 END), 5)
    FROM Limits AS limits
    OUTER APPLY
    (
        SELECT TOP (1) candidate.Candidate
        FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7)) AS highDigit(n)
        CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15)) AS lowDigit(n)
        CROSS APPLY (SELECT Attempt = highDigit.n * 16 + lowDigit.n) AS counter
        CROSS APPLY [toolbelt_pseudonymization].[TVF_DeterministicIntegerBytes](counter.Attempt) AS attemptBytes
        CROSS APPLY (SELECT Digest = HASHBYTES('SHA2_256', limits.Frame + SUBSTRING(attemptBytes.Bytes, 5, 4))) AS hashValue
        CROSS APPLY (SELECT HexValue = CONVERT(varchar(16), SUBSTRING(hashValue.Digest, 1, 8), 2)) AS digestHex
        CROSS APPLY
        (
            -- Explizite Hexinterpretation statt nativer Binary-to-integer-Konvertierung.
            SELECT Candidate =
                   CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 1, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 1152921504606846976)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 2, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 72057594037927936)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 3, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 4503599627370496)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 4, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 281474976710656)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 5, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 17592186044416)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 6, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 1099511627776)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 7, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 68719476736)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 8, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 4294967296)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 9, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 268435456)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 10, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 16777216)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 11, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 1048576)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 12, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 65536)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 13, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 4096)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 14, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 256)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 15, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 16)
                 + CONVERT(decimal(38,0), CHARINDEX(SUBSTRING(digestHex.HexValue, 16, 1) COLLATE Latin1_General_100_BIN2, '0123456789ABCDEF' COLLATE Latin1_General_100_BIN2) - 1) * CONVERT(decimal(38,0), 1)
        ) AS candidate
        WHERE limits.ConfigurationError = 0 AND @Key IS NOT NULL
          AND candidate.Candidate < limits.AcceptanceLimit
        ORDER BY counter.Attempt
    ) AS chosen
);
GO
