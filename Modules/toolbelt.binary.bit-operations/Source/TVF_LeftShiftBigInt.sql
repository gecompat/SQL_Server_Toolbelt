-- ============================================================================
-- Objekt:          toolbelt_binary.TVF_LeftShiftBigInt
-- Zweck:           Logischer 64-Bit-Left-Shift für bigint.
-- Parameter:       @Value bigint, @ShiftAmount bigint
-- Resultset:       Value bigint
-- Dependencies:    keine Toolbelt-Module
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Inline TVF; decimal(38,0)-Arithmetik ohne Loop
-- Einschränkungen: Ausschließlich bigint; Binary-Typen sind nicht Teil V1.
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_binary].[TVF_LeftShiftBigInt]
(
      @Value       bigint
    , @ShiftAmount bigint
)
RETURNS TABLE
AS
RETURN
(
    WITH Parameters AS
    (
        SELECT
              UnsignedValue =
                  CONVERT(decimal(38,0), @Value)
                  + CASE
                        WHEN @Value < 0
                            THEN CONVERT(decimal(38,0), 18446744073709551616)
                        ELSE CONVERT(decimal(38,0), 0)
                    END
            , EffectiveAmount = CONVERT
              (
                  int,
                  CASE
                      WHEN @ShiftAmount BETWEEN 0 AND 63 THEN @ShiftAmount
                      WHEN @ShiftAmount BETWEEN -63 AND -1
                          THEN -@ShiftAmount
                      ELSE 0
                  END
              )
            , IsLeft = CONVERT(bit, CASE WHEN @ShiftAmount >= 0 THEN 1 ELSE 0 END)
    ),
    Shifted AS
    (
        SELECT ShiftedUnsigned =
            CONVERT
            (
                decimal(38,0),
                CASE
                    WHEN @Value IS NULL OR @ShiftAmount IS NULL THEN NULL
                    WHEN @ShiftAmount NOT BETWEEN -63 AND 63 THEN 0
                    WHEN parameters.IsLeft = 1
                        THEN
                            (
                                parameters.UnsignedValue
                                % POWER
                                  (
                                      CONVERT(decimal(38,0), 2),
                                      64 - parameters.EffectiveAmount
                                  )
                            )
                            * POWER
                              (
                                  CONVERT(decimal(38,0), 2),
                                  parameters.EffectiveAmount
                              )
                    ELSE FLOOR
                         (
                             parameters.UnsignedValue
                             / POWER
                               (
                                   CONVERT(decimal(38,0), 2),
                                   parameters.EffectiveAmount
                               )
                         )
                END
            )
        FROM Parameters AS parameters
    )
    SELECT Value = CONVERT
    (
        bigint,
        CASE
            WHEN shifted.ShiftedUnsigned >=
                 CONVERT(decimal(38,0), 9223372036854775808)
                THEN shifted.ShiftedUnsigned
                     - CONVERT(decimal(38,0), 18446744073709551616)
            ELSE shifted.ShiftedUnsigned
        END
    )
    FROM Shifted AS shifted
);
GO
