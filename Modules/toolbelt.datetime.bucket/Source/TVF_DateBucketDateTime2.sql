-- ============================================================================
-- Objekt:          toolbelt_datetime.TVF_DateBucketDateTime2
-- Zweck:           Portabler DATE_BUCKET-Vertrag für datetime2(7).
-- Parameter:       @DatePart varchar(16), @Width int,
--                  @Value datetime2(7), @Origin datetime2(7) = 1900-01-01
-- Resultset:       Value datetime2(7), IsValid bit, ValidationCode tinyint
-- Dependencies:    keine Toolbelt-Module
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Inline TVF; eigener datetime2-Ausdrucksbaum
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_datetime].[TVF_DateBucketDateTime2]
(
      @DatePart varchar(16)
    , @Width    int
    , @Value    datetime2(7)
    , @Origin   datetime2(7) = '19000101'
)
RETURNS TABLE
AS
RETURN
(
    WITH Normalized AS
    (
        SELECT CanonicalDatePart =
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
                WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                     IN ('hour', 'hh') THEN 'hour'
                WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                     IN ('minute', 'mi', 'n') THEN 'minute'
                WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                     IN ('second', 'ss', 's') THEN 'second'
                WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                     IN ('millisecond', 'ms') THEN 'millisecond'
            END
    ),
    Distances AS
    (
        SELECT
              normalized.CanonicalDatePart
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
                      WHEN 'hour' THEN DATEDIFF_BIG(hour, @Origin, @Value)
                      WHEN 'minute' THEN DATEDIFF_BIG(minute, @Origin, @Value)
                      WHEN 'second' THEN DATEDIFF_BIG(second, @Origin, @Value)
                      WHEN 'millisecond'
                          THEN DATEDIFF_BIG(millisecond, @Origin, @Value)
                  END
              )
        FROM Normalized AS normalized
    ),
    BucketIndexes AS
    (
        SELECT
              distances.CanonicalDatePart
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
    UnitOffsets AS
    (
        SELECT
              indexes.CanonicalDatePart
            , UnitOffset = indexes.BucketIndex * CONVERT(bigint, @Width)
        FROM BucketIndexes AS indexes
    ),
    SplitOffsets AS
    (
        SELECT
              unit_offsets.CanonicalDatePart
            , unit_offsets.UnitOffset
            , DayOffset = CONVERT
              (
                  int,
                  CASE unit_offsets.CanonicalDatePart
                      WHEN 'hour' THEN
                          unit_offsets.UnitOffset / 24
                          - CASE
                                WHEN unit_offsets.UnitOffset < 0
                                 AND unit_offsets.UnitOffset % 24 <> 0 THEN 1
                                ELSE 0
                            END
                      WHEN 'minute' THEN
                          unit_offsets.UnitOffset / 1440
                          - CASE
                                WHEN unit_offsets.UnitOffset < 0
                                 AND unit_offsets.UnitOffset % 1440 <> 0 THEN 1
                                ELSE 0
                            END
                      WHEN 'second' THEN
                          unit_offsets.UnitOffset / 86400
                          - CASE
                                WHEN unit_offsets.UnitOffset < 0
                                 AND unit_offsets.UnitOffset % 86400 <> 0 THEN 1
                                ELSE 0
                            END
                      WHEN 'millisecond' THEN
                          unit_offsets.UnitOffset / 86400000
                          - CASE
                                WHEN unit_offsets.UnitOffset < 0
                                 AND unit_offsets.UnitOffset % 86400000 <> 0
                                    THEN 1
                                ELSE 0
                            END
                      ELSE 0
                  END
              )
        FROM UnitOffsets AS unit_offsets
    ),
    Candidates AS
    (
        SELECT
              split.CanonicalDatePart
            , Value = CONVERT
              (
                  datetime2(7),
                  CASE split.CanonicalDatePart
                      WHEN 'year'
                          THEN DATEADD
                               (year, CONVERT(int, split.UnitOffset), @Origin)
                      WHEN 'quarter'
                          THEN DATEADD
                               (quarter, CONVERT(int, split.UnitOffset), @Origin)
                      WHEN 'month'
                          THEN DATEADD
                               (month, CONVERT(int, split.UnitOffset), @Origin)
                      WHEN 'week'
                          THEN DATEADD
                               (week, CONVERT(int, split.UnitOffset), @Origin)
                      WHEN 'day'
                          THEN DATEADD
                               (day, CONVERT(int, split.UnitOffset), @Origin)
                      WHEN 'hour'
                          THEN DATEADD
                               (
                                   hour,
                                   CONVERT
                                   (
                                       int,
                                       split.UnitOffset
                                       - CONVERT(bigint, split.DayOffset) * 24
                                   ),
                                   DATEADD(day, split.DayOffset, @Origin)
                               )
                      WHEN 'minute'
                          THEN DATEADD
                               (
                                   minute,
                                   CONVERT
                                   (
                                       int,
                                       split.UnitOffset
                                       - CONVERT(bigint, split.DayOffset) * 1440
                                   ),
                                   DATEADD(day, split.DayOffset, @Origin)
                               )
                      WHEN 'second'
                          THEN DATEADD
                               (
                                   second,
                                   CONVERT
                                   (
                                       int,
                                       split.UnitOffset
                                       - CONVERT(bigint, split.DayOffset) * 86400
                                   ),
                                   DATEADD(day, split.DayOffset, @Origin)
                               )
                      WHEN 'millisecond'
                          THEN DATEADD
                               (
                                   millisecond,
                                   CONVERT
                                   (
                                       int,
                                       split.UnitOffset
                                       - CONVERT(bigint, split.DayOffset) * 86400000
                                   ),
                                   DATEADD(day, split.DayOffset, @Origin)
                               )
                  END
              )
        FROM SplitOffsets AS split
    ),
    Adjusted AS
    (
        SELECT
              candidates.CanonicalDatePart
            , Value = CONVERT
              (
                  datetime2(7),
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
                      WHEN candidates.CanonicalDatePart = 'hour'
                          THEN DATEADD
                               (
                                   hour,
                                   -CASE WHEN @Width > 0 THEN @Width ELSE 1 END,
                                   candidates.Value
                               )
                      WHEN candidates.CanonicalDatePart = 'minute'
                          THEN DATEADD
                               (
                                   minute,
                                   -CASE WHEN @Width > 0 THEN @Width ELSE 1 END,
                                   candidates.Value
                               )
                      WHEN candidates.CanonicalDatePart = 'second'
                          THEN DATEADD
                               (
                                   second,
                                   -CASE WHEN @Width > 0 THEN @Width ELSE 1 END,
                                   candidates.Value
                               )
                      WHEN candidates.CanonicalDatePart = 'millisecond'
                          THEN DATEADD
                               (
                                   millisecond,
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
              datetime2(7),
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
                  WHEN adjusted.CanonicalDatePart IS NULL THEN 10
                  WHEN @Width <= 0 THEN 11
                  ELSE 0
              END
          )
    FROM Adjusted AS adjusted
);
GO
