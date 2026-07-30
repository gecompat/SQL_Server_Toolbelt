-- ============================================================================
-- Objekt:          toolbelt_binary.TVF_RightShiftBigInt
-- Zweck:           Logischer 64-Bit-Right-Shift für bigint.
-- Parameter:       @Value bigint, @ShiftAmount bigint
-- Resultset:       Value bigint
-- Dependencies:    TVF_LeftShiftBigInt im selben Modul
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Inline TVF; relationale Wiederverwendung des Shift-Kerns
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_binary].[TVF_RightShiftBigInt]
(
      @Value       bigint
    , @ShiftAmount bigint
)
RETURNS TABLE
AS
RETURN
(
    SELECT shifted.Value
    FROM toolbelt_binary.TVF_LeftShiftBigInt
         (
               @Value
             , CASE
                   WHEN @ShiftAmount = CONVERT(bigint, -9223372036854775808)
                       THEN CONVERT(bigint, 64)
                   ELSE -@ShiftAmount
               END
         ) AS shifted
);
GO
