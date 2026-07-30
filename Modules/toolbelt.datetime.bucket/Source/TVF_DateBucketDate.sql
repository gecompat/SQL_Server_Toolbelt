-- ============================================================================
-- Objekt:          toolbelt_datetime.TVF_DateBucketDate
-- Zweck:           Portabler DATE_BUCKET-Vertrag für date.
-- Parameter:       @DatePart varchar(16), @Width int,
--                  @Value date, @Origin date = 1900-01-01
-- Resultset:       Value date, IsValid bit, ValidationCode tinyint
-- Dependencies:    keine Toolbelt-Module
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Inline TVF; eigener schlanker date-Ausdrucksbaum
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
    WITH Normalized AS
    (
        SELECT
              CanonicalDatePart =
                CASE
                    WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                         IN ('year', 'yy', 'yyyy') THEN 'year'
                    WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                         IN ('quarter', 'qq', 'q') THEN 'quarter'
                    WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                         IN ('month', 'mm', 'm') THEN 'month'
                    WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                         IN ('week', 'wk', 'ww') THEN 'week'
                    WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                         IN
                         (
                             'dayofyear', 'dy', 'y',
                             'day', 'dd', 'd',
                             'weekday', 'dw', 'w'
                         ) THEN 'day'
                END
            , IsTimeDatePart = CONVERT
              (
                  bit,
                  CASE
                      WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                           IN
                           (
                               'hour', 'hh',
                               'minute', 'mi', 'n',
                               'second', 'ss', 's',
                               'millisecond', 'ms'
                           )
                          THEN 1
                      ELSE 0
                  END
              )
    ),
    Distances AS
    (
        SELECT
              normalized.CanonicalDatePart
            , normalized.IsTimeDatePart
            , Distance = CONVERT
              (
                  bigint,
                  CASE normalized.CanonicalDatePart
                      WHEN 'year' THEN DATEDIFF_BIG(year, @Origin, @Value)
                      WHEN 'quarter'
                          THEN DATEDIFF_BIG(quarter, @Origin, @Value)
                      WHEN 'month' THEN DATEDIFF_BIG(month, @Origin, @Value)
                      WHEN 'week' THEN DATEDIFF_BIG(week, @Origin, @Value)
                      WHEN 'day' THEN DATEDIFF_BIG(day, @Origin, @Value)
                  END
              )
        FROM Normalized AS normalized
    ),
    BucketIndexes AS
    (
        SELECT
              distances.CanonicalDatePart
            , distances.IsTimeDatePart
            , BucketIndex =
                CASE
                    WHEN @Width > 0
                     AND distances.Distance < 0
                     AND distances.Distance % @Width <> 0
                        THEN distances.Distance / @Width - 1
                    WHEN @Width > 0 THEN distances.Distance / @Width
                END
        FROM Distances AS distances
    ),
    Candidates AS
    (
        SELECT
              indexes.CanonicalDatePart
            , indexes.IsTimeDatePart
            , Value = CONVERT
              (
                  date,
                  CASE indexes.CanonicalDatePart
                      WHEN 'year'
                          THEN DATEADD
                               (
                                   year,
                                   CONVERT(int, indexes.BucketIndex * @Width),
                                   @Origin
                               )
                      WHEN 'quarter'
                          THEN DATEADD
                               (
                                   quarter,
                                   CONVERT(int, indexes.BucketIndex * @Width),
                                   @Origin
                               )
                      WHEN 'month'
                          THEN DATEADD
                               (
                                   month,
                                   CONVERT(int, indexes.BucketIndex * @Width),
                                   @Origin
                               )
                      WHEN 'week'
                          THEN DATEADD
                               (
                                   week,
                                   CONVERT(int, indexes.BucketIndex * @Width),
                                   @Origin
                               )
                      WHEN 'day'
                          THEN DATEADD
                               (
                                   day,
                                   CONVERT(int, indexes.BucketIndex * @Width),
                                   @Origin
                               )
                  END
              )
        FROM BucketIndexes AS indexes
    ),
    Adjusted AS
    (
        SELECT
              candidates.CanonicalDatePart
            , candidates.IsTimeDatePart
            , Value = CONVERT
              (
                  date,
                  CASE
                      WHEN candidates.Value <= @Value THEN candidates.Value
                      WHEN candidates.CanonicalDatePart = 'year'
                          THEN DATEADD
                               (
                                   year,
                                   -CASE WHEN @Width > 0 THEN @Width ELSE 1 END,
                                   candidates.Value
                               )
                      WHEN candidates.CanonicalDatePart = 'quarter'
                          THEN DATEADD
                               (
                                   quarter,
                                   -CASE WHEN @Width > 0 THEN @Width ELSE 1 END,
                                   candidates.Value
                               )
                      WHEN candidates.CanonicalDatePart = 'month'
                          THEN DATEADD
                               (
                                   month,
                                   -CASE WHEN @Width > 0 THEN @Width ELSE 1 END,
                                   candidates.Value
                               )
                      WHEN candidates.CanonicalDatePart = 'week'
                          THEN DATEADD
                               (
                                   week,
                                   -CASE WHEN @Width > 0 THEN @Width ELSE 1 END,
                                   candidates.Value
                               )
                      WHEN candidates.CanonicalDatePart = 'day'
                          THEN DATEADD
                               (
                                   day,
                                   -CASE WHEN @Width > 0 THEN @Width ELSE 1 END,
                                   candidates.Value
                               )
                  END
              )
        FROM Candidates AS candidates
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
                    OR adjusted.CanonicalDatePart IS NULL
                    OR @Width <= 0
                      THEN NULL
                  ELSE adjusted.Value
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
                  WHEN adjusted.CanonicalDatePart IS NULL OR @Width <= 0 THEN 0
                  ELSE 1
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
                  WHEN adjusted.IsTimeDatePart = 1 THEN 12
                  WHEN adjusted.CanonicalDatePart IS NULL THEN 10
                  WHEN @Width <= 0 THEN 11
                  ELSE 0
              END
          )
    FROM Adjusted AS adjusted
);
GO
