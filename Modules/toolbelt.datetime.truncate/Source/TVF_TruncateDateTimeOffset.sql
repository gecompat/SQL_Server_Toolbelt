-- ============================================================================
-- Objekt:          toolbelt_datetime.TVF_TruncateDateTimeOffset
-- Zweck:           Portabler DATETRUNC-Kern für datetimeoffset(7).
-- Parameter:       @DatePart varchar(16), @Value datetimeoffset(7)
-- Resultset:       Value datetimeoffset(7), IsValid bit,
--                  ValidationCode tinyint
-- Dependencies:    keine Toolbelt-Module
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Inline TVF; geeignet für CROSS APPLY und OUTER APPLY
-- Collation:       Datepart wird als ASCII-Schlüssel binär verglichen.
-- Einschränkungen: Fester Rückgabetyp datetimeoffset(7); ungültige
--                  Parameter werden relational statt per THROW ausgewiesen.
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_datetime].[TVF_TruncateDateTimeOffset]
(
      @DatePart varchar(16)
    , @Value    datetimeoffset(7)
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
                     IN ('dayofyear', 'dy', 'y', 'day', 'dd', 'd') THEN 'day'
                WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                     IN ('week', 'wk', 'ww') THEN 'week'
                WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                     IN ('iso_week', 'isowk', 'isoww') THEN 'iso_week'
                WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                     IN ('hour', 'hh') THEN 'hour'
                WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                     IN ('minute', 'mi', 'n') THEN 'minute'
                WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                     IN ('second', 'ss', 's') THEN 'second'
                WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                     IN ('millisecond', 'ms') THEN 'millisecond'
                WHEN LOWER(@DatePart) COLLATE Latin1_General_100_BIN2
                     IN ('microsecond', 'mcs') THEN 'microsecond'
            END
    ),
    Parts AS
    (
        SELECT
              normalized.CanonicalDatePart
            , LocalDate = CONVERT(date, @Value)
            , OffsetMinutes = DATEPART(tzoffset, @Value)
            , WeekOffset = DATEPART(weekday, CONVERT(date, @Value)) - 1
            , IsoWeekOffset =
                (
                    (
                        DATEDIFF
                        (
                              day
                            , CONVERT(date, '19000101', 112)
                            , CONVERT(date, @Value)
                        ) % 7
                    ) + 7
                ) % 7
        FROM Normalized AS normalized
    ),
    Validated AS
    (
        SELECT
              parts.*
            , HasWeekUnderflow = CONVERT
              (
                  bit,
                  CASE
                      WHEN parts.CanonicalDatePart = 'week'
                       AND parts.WeekOffset >
                           DATEDIFF
                           (
                                 day
                               , CONVERT(date, '00010101', 112)
                               , parts.LocalDate
                           )
                          THEN 1
                      ELSE 0
                  END
              )
        FROM Parts AS parts
    ),
    TruncatedParts AS
    (
        SELECT
              validated.CanonicalDatePart
            , validated.HasWeekUnderflow
            , TruncatedDate =
                CASE validated.CanonicalDatePart
                    WHEN 'year'
                        THEN DATEFROMPARTS(YEAR(validated.LocalDate), 1, 1)
                    WHEN 'quarter'
                        THEN DATEFROMPARTS
                             (
                                   YEAR(validated.LocalDate)
                                 , ((MONTH(validated.LocalDate) - 1) / 3) * 3 + 1
                                 , 1
                             )
                    WHEN 'month'
                        THEN DATEFROMPARTS
                             (
                                   YEAR(validated.LocalDate)
                                 , MONTH(validated.LocalDate)
                                 , 1
                             )
                    WHEN 'week'
                        THEN DATEADD
                             (
                                   day
                                 , -CASE
                                       WHEN validated.HasWeekUnderflow = 1
                                           THEN 0
                                       ELSE validated.WeekOffset
                                    END
                                 , validated.LocalDate
                             )
                    WHEN 'iso_week'
                        THEN DATEADD
                             (
                                   day
                                 , -validated.IsoWeekOffset
                                 , validated.LocalDate
                             )
                    ELSE validated.LocalDate
                  END
            , TruncatedHour =
                CASE
                    WHEN validated.CanonicalDatePart IN
                         (
                             'hour', 'minute', 'second',
                             'millisecond', 'microsecond'
                         )
                        THEN DATEPART(hour, @Value)
                    ELSE 0
                END
            , TruncatedMinute =
                CASE
                    WHEN validated.CanonicalDatePart IN
                         ('minute', 'second', 'millisecond', 'microsecond')
                        THEN DATEPART(minute, @Value)
                    ELSE 0
                END
            , TruncatedSecond =
                CASE
                    WHEN validated.CanonicalDatePart IN
                         ('second', 'millisecond', 'microsecond')
                        THEN DATEPART(second, @Value)
                    ELSE 0
                END
            , TruncatedFraction =
                CASE validated.CanonicalDatePart
                    WHEN 'millisecond'
                        THEN (DATEPART(nanosecond, @Value) / 1000000) * 10000
                    WHEN 'microsecond'
                        THEN (DATEPART(nanosecond, @Value) / 1000) * 10
                    ELSE 0
                END
            , OffsetHour = validated.OffsetMinutes / 60
            , OffsetMinute = validated.OffsetMinutes % 60
        FROM Validated AS validated
    )
    SELECT
          Value = CONVERT
          (
              datetimeoffset(7),
              CASE
                  WHEN @Value IS NULL
                    OR @DatePart IS NULL
                    OR truncated.CanonicalDatePart IS NULL
                    OR truncated.HasWeekUnderflow = 1
                      THEN NULL
                  ELSE DATETIMEOFFSETFROMPARTS
                       (
                             YEAR(truncated.TruncatedDate)
                           , MONTH(truncated.TruncatedDate)
                           , DAY(truncated.TruncatedDate)
                           , truncated.TruncatedHour
                           , truncated.TruncatedMinute
                           , truncated.TruncatedSecond
                           , truncated.TruncatedFraction
                           , truncated.OffsetHour
                           , truncated.OffsetMinute
                           , 7
                       )
              END
          )
        , IsValid = CONVERT
          (
              bit,
              CASE
                  WHEN @Value IS NULL OR @DatePart IS NULL THEN NULL
                  WHEN truncated.CanonicalDatePart IS NULL
                    OR truncated.HasWeekUnderflow = 1 THEN 0
                  ELSE 1
              END
          )
        , ValidationCode = CONVERT
          (
              tinyint,
              CASE
                  WHEN @Value IS NULL OR @DatePart IS NULL THEN NULL
                  WHEN truncated.CanonicalDatePart IS NULL THEN 10
                  WHEN truncated.HasWeekUnderflow = 1 THEN 12
                  ELSE 0
              END
          )
    FROM TruncatedParts AS truncated
);
GO
