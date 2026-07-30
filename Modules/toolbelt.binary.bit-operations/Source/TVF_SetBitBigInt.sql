-- ============================================================================
-- Objekt:          toolbelt_binary.TVF_SetBitBigInt
-- Zweck:           Setzt oder löscht ein Bit in einem bigint-Bitmuster.
-- Parameter:       @Value bigint, @BitOffset bigint, @BitValue int = 1
-- Resultset:       Value bigint, IsValid bit, ValidationCode tinyint
-- Dependencies:    keine Toolbelt-Module
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Inline TVF; konstante decimal(38,0)-Arithmetik
-- Einschränkungen: Offset 0 bezeichnet das Least Significant Bit.
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_binary].[TVF_SetBitBigInt]
(
      @Value     bigint
    , @BitOffset bigint
    , @BitValue  int = 1
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
            , BitPower = POWER
              (
                  CONVERT(decimal(38,0), 2),
                  CONVERT
                  (
                      int,
                      CASE
                          WHEN @BitOffset BETWEEN 0 AND 63 THEN @BitOffset
                          ELSE 0
                      END
                  )
              )
    ),
    Resolved AS
    (
        SELECT ResultUnsigned =
            parameters.UnsignedValue
            + (
                  CONVERT(decimal(38,0), @BitValue)
                  - FLOOR(parameters.UnsignedValue / parameters.BitPower) % 2
              ) * parameters.BitPower
        FROM Parameters AS parameters
    )
    SELECT
          Value = CONVERT
          (
              bigint,
              CASE
                  WHEN @Value IS NULL
                    OR @BitOffset IS NULL
                    OR @BitValue IS NULL
                    OR @BitOffset NOT BETWEEN 0 AND 63
                    OR @BitValue NOT IN (0, 1)
                      THEN NULL
                  WHEN resolved.ResultUnsigned >=
                       CONVERT(decimal(38,0), 9223372036854775808)
                      THEN resolved.ResultUnsigned
                           - CONVERT
                             (
                                 decimal(38,0),
                                 18446744073709551616
                             )
                  ELSE resolved.ResultUnsigned
              END
          )
        , IsValid = CONVERT
          (
              bit,
              CASE
                  WHEN @Value IS NULL
                    OR @BitOffset IS NULL
                    OR @BitValue IS NULL
                      THEN NULL
                  WHEN @BitOffset NOT BETWEEN 0 AND 63
                    OR @BitValue NOT IN (0, 1)
                      THEN 0
                  ELSE 1
              END
          )
        , ValidationCode = CONVERT
          (
              tinyint,
              CASE
                  WHEN @Value IS NULL
                    OR @BitOffset IS NULL
                    OR @BitValue IS NULL
                      THEN NULL
                  WHEN @BitOffset NOT BETWEEN 0 AND 63 THEN 10
                  WHEN @BitValue NOT IN (0, 1) THEN 11
                  ELSE 0
              END
          )
    FROM Resolved AS resolved
);
GO
