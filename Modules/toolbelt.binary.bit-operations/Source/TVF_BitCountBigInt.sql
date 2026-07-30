-- ============================================================================
-- Objekt:          toolbelt_binary.TVF_BitCountBigInt
-- Zweck:           Zählt gesetzte Bits im vollständigen bigint-Bitmuster.
-- Parameter:       @Value bigint
-- Resultset:       Value bigint
-- Dependencies:    keine Toolbelt-Module
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Inline TVF; acht Bytes werden set-basiert ausgewertet.
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_binary].[TVF_BitCountBigInt]
(
    @Value bigint
)
RETURNS TABLE
AS
RETURN
(
    WITH Bytes AS
    (
        SELECT ByteValue = CONVERT
        (
            int,
            SUBSTRING(CONVERT(binary(8), @Value), positions.BytePosition, 1)
        )
        FROM
        (
            VALUES (1), (2), (3), (4), (5), (6), (7), (8)
        ) AS positions(BytePosition)
    )
    SELECT Value = CONVERT
    (
        bigint,
        CASE
            WHEN @Value IS NULL THEN NULL
            ELSE SUM
                 (
                       (bytes.ByteValue & 1)
                     + ((bytes.ByteValue & 2) / 2)
                     + ((bytes.ByteValue & 4) / 4)
                     + ((bytes.ByteValue & 8) / 8)
                     + ((bytes.ByteValue & 16) / 16)
                     + ((bytes.ByteValue & 32) / 32)
                     + ((bytes.ByteValue & 64) / 64)
                     + ((bytes.ByteValue & 128) / 128)
                 )
        END
    )
    FROM Bytes AS bytes
);
GO
