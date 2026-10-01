-- ============================================================================
-- Objekt:          toolbelt_pseudonymization.TVF_DeterministicIntegerBytes
-- Zweck:           Interne explizite bigint-Big-endian-Zweierkomplementkodierung.
-- Parameter:       Value bigint; Resultset: Bytes binary(8) NULL.
-- Dependencies:    keine; echte Inline TVF, keine Scalar-UDF.
-- Versionen:       SQL Server 2019/2022/2025; Windows/Linux.
-- Performance:     16 feste Hexziffern, keine Schleife oder Aggregation.
-- Collation:       feste ASCII-Hexzeichen; kein Vergleich von Caller-Text.
-- Einschränkungen: Intern; NULL ergibt NULL. Keine Numeric-to-binary-Kodierung.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_pseudonymization].[TVF_DeterministicIntegerBytes]
(
    @Value bigint
)
RETURNS TABLE
AS
RETURN
(
    SELECT Bytes = CONVERT(binary(8),
          SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 8070450532247928832)) / CONVERT(bigint, 1152921504606846976)) + CASE WHEN @Value < 0 THEN 8 ELSE 0 END + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 1080863910568919040)) / CONVERT(bigint, 72057594037927936)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 67553994410557440)) / CONVERT(bigint, 4503599627370496)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 4222124650659840)) / CONVERT(bigint, 281474976710656)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 263882790666240)) / CONVERT(bigint, 17592186044416)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 16492674416640)) / CONVERT(bigint, 1099511627776)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 1030792151040)) / CONVERT(bigint, 68719476736)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 64424509440)) / CONVERT(bigint, 4294967296)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 4026531840)) / CONVERT(bigint, 268435456)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 251658240)) / CONVERT(bigint, 16777216)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 15728640)) / CONVERT(bigint, 1048576)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 983040)) / CONVERT(bigint, 65536)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 61440)) / CONVERT(bigint, 4096)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 3840)) / CONVERT(bigint, 256)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 240)) / CONVERT(bigint, 16)) + 1, 1)
        + SUBSTRING('0123456789ABCDEF', ((@Value & CONVERT(bigint, 15)) / CONVERT(bigint, 1)) + 1, 1)
        , 2)
);
GO
