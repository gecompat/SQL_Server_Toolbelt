-- ============================================================================
-- Objekt:          toolbelt_datetime.TVF_DateBucketDate
-- Zweck:           Portabler DATE_BUCKET-Vertrag für date.
-- Parameter:       @DatePart varchar(16), @Width int,
--                  @Value date, @Origin date = 1900-01-01
-- Resultset:       Value date, IsValid bit, ValidationCode tinyint
-- Dependencies:    TVF_DateBucketDateTime2 im selben Modul
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Inline TVF; dünner relationaler Typ-Wrapper
-- Einschränkungen: Zeit-Dateparts sind für date ungültig.
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_datetime].[TVF_DateBucketDate]
(
      @DatePart varchar(16)
    , @Width    int
    , @Value    date
    , @Origin   date = '19000101'
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
                         'week', 'wk', 'ww',
                         'dayofyear', 'dy', 'y',
                         'day', 'dd', 'd',
                         'weekday', 'dw', 'w'
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
                  WHEN @DatePart IS NULL
                    OR @Width IS NULL
                    OR @Value IS NULL
                    OR @Origin IS NULL
                    OR input.IsDatePartSupported = 0
                      THEN NULL
                  ELSE bucket.Value
              END
          )
        , IsValid = CONVERT
          (
              bit,
              CASE
                  WHEN @DatePart IS NULL
                    OR @Width IS NULL
                    OR @Value IS NULL
                    OR @Origin IS NULL
                      THEN NULL
                  WHEN input.IsDatePartSupported = 0 THEN 0
                  ELSE bucket.IsValid
              END
          )
        , ValidationCode = CONVERT
          (
              tinyint,
              CASE
                  WHEN @DatePart IS NULL
                    OR @Width IS NULL
                    OR @Value IS NULL
                    OR @Origin IS NULL
                      THEN NULL
                  WHEN bucket.ValidationCode = 10 THEN 10
                  WHEN input.IsDatePartSupported = 0 THEN 12
                  ELSE bucket.ValidationCode
              END
          )
    FROM InputContract AS input
    CROSS APPLY toolbelt_datetime.TVF_DateBucketDateTime2
                (
                      @DatePart
                    , @Width
                    , CONVERT(datetime2(7), @Value)
                    , CONVERT(datetime2(7), @Origin)
                ) AS bucket
);
GO
