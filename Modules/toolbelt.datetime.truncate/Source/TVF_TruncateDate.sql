-- ============================================================================
-- Objekt:          toolbelt_datetime.TVF_TruncateDate
-- Zweck:           Portabler DATETRUNC-Vertrag für date.
-- Parameter:       @DatePart varchar(16), @Value date
-- Resultset:       Value date, IsValid bit, ValidationCode tinyint
-- Dependencies:    TVF_TruncateDateTime2 im selben Modul
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Inline TVF; dünner relationaler Typ-Wrapper
-- Einschränkungen: Zeit-Dateparts sind für date ungültig.
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_datetime].[TVF_TruncateDate]
(
      @DatePart varchar(16)
    , @Value    date
)
RETURNS TABLE
AS
RETURN
(
    WITH InputContract AS
    (
        SELECT IsDatePartSupported = CONVERT
        (
            bit,
            CASE
                WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2 IN
                     (
                         'year', 'yy', 'yyyy',
                         'quarter', 'qq', 'q',
                         'month', 'mm', 'm',
                         'dayofyear', 'dy', 'y',
                         'day', 'dd', 'd',
                         'week', 'wk', 'ww',
                         'iso_week', 'isowk', 'isoww'
                     )
                    THEN 1
                ELSE 0
            END
        )
    )
    SELECT
          Value = CONVERT
          (
              date,
              CASE
                  WHEN @Value IS NULL OR @DatePart IS NULL
                    OR input.IsDatePartSupported = 0
                      THEN NULL
                  ELSE truncated.Value
              END
          )
        , IsValid = CONVERT
          (
              bit,
              CASE
                  WHEN @Value IS NULL OR @DatePart IS NULL THEN NULL
                  WHEN input.IsDatePartSupported = 0 THEN 0
                  ELSE truncated.IsValid
              END
          )
        , ValidationCode = CONVERT
          (
              tinyint,
              CASE
                  WHEN @Value IS NULL OR @DatePart IS NULL THEN NULL
                  WHEN truncated.ValidationCode = 10 THEN 10
                  WHEN input.IsDatePartSupported = 0 THEN 11
                  ELSE truncated.ValidationCode
              END
          )
    FROM InputContract AS input
    CROSS APPLY toolbelt_datetime.TVF_TruncateDateTime2
                (
                      @DatePart
                    , CONVERT(datetime2(7), @Value)
                ) AS truncated
);
GO
