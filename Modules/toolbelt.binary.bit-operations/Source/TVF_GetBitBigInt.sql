-- ============================================================================
-- Objekt:          toolbelt_binary.TVF_GetBitBigInt
-- Zweck:           Liest ein Bit aus einem bigint-Bitmuster.
-- Parameter:       @Value bigint, @BitOffset bigint
-- Resultset:       Value bit, IsValid bit, ValidationCode tinyint
-- Dependencies:    keine Toolbelt-Module
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Inline TVF; konstante decimal(38,0)-Arithmetik
-- Einschränkungen: Offset 0 bezeichnet das Least Significant Bit.
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_binary].[TVF_GetBitBigInt]
(
      @Value     bigint
    , @BitOffset bigint
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
            , SafeOffset = CONVERT
              (
                  int,
                  CASE
                      WHEN @BitOffset BETWEEN 0 AND 63 THEN @BitOffset
                      ELSE 0
                  END
              )
    )
    SELECT
          Value = CONVERT
          (
              bit,
              CASE
                  WHEN @Value IS NULL OR @BitOffset IS NULL
                    OR @BitOffset NOT BETWEEN 0 AND 63
                      THEN NULL
                  ELSE FLOOR
                       (
                           parameters.UnsignedValue
                           / POWER
                             (
                                 CONVERT(decimal(38,0), 2),
                                 parameters.SafeOffset
                             )
                       ) % 2
              END
          )
        , IsValid = CONVERT
          (
              bit,
              CASE
                  WHEN @Value IS NULL OR @BitOffset IS NULL THEN NULL
                  WHEN @BitOffset NOT BETWEEN 0 AND 63 THEN 0
                  ELSE 1
              END
          )
        , ValidationCode = CONVERT
          (
              tinyint,
              CASE
                  WHEN @Value IS NULL OR @BitOffset IS NULL THEN NULL
                  WHEN @BitOffset NOT BETWEEN 0 AND 63 THEN 10
                  ELSE 0
              END
          )
    FROM Parameters AS parameters
);
GO
