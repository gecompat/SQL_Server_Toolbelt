-- ============================================================================
-- Objekt:          toolbelt_datetime.TVF_DateBucketCore
-- Zweck:           Interner prozeduraler Bucket-Kern für datetimeoffset(7).
-- Parameter:       @DatePart varchar(16), @Width int,
--                  @Value datetimeoffset(7), @Origin datetimeoffset(7)
-- Resultset:       Value datetimeoffset(7), IsValid bit,
--                  ValidationCode tinyint
-- Dependencies:    keine Toolbelt-Module
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Sichtbarkeit:    intern; öffentliche Aufrufe verwenden die Inline-TVFs
-- Performance:     Einzeilige MSTVF als bewusste Optimizer-Grenze gegen 8632
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_datetime].[TVF_DateBucketCore]
(
      @DatePart varchar(16)
    , @Width    int
    , @Value    datetimeoffset(7)
    , @Origin   datetimeoffset(7)
)
RETURNS @Result TABLE
(
      Value          datetimeoffset(7) NULL
    , IsValid       bit               NULL
    , ValidationCode tinyint          NULL
)
AS
BEGIN
    IF @DatePart IS NULL
       OR @Width IS NULL
       OR @Value IS NULL
       OR @Origin IS NULL
    BEGIN
        INSERT INTO @Result (Value, IsValid, ValidationCode)
        VALUES (NULL, NULL, NULL);
        RETURN;
    END;

    DECLARE @CanonicalDatePart varchar(16) =
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
        END;

    IF @CanonicalDatePart IS NULL
    BEGIN
        INSERT INTO @Result (Value, IsValid, ValidationCode)
        VALUES (NULL, 0, 10);
        RETURN;
    END;

    IF @Width <= 0
    BEGIN
        INSERT INTO @Result (Value, IsValid, ValidationCode)
        VALUES (NULL, 0, 11);
        RETURN;
    END;

    DECLARE @Distance bigint =
        CASE @CanonicalDatePart
            WHEN 'year' THEN DATEDIFF_BIG(year, @Origin, @Value)
            WHEN 'quarter' THEN DATEDIFF_BIG(quarter, @Origin, @Value)
            WHEN 'month' THEN DATEDIFF_BIG(month, @Origin, @Value)
            WHEN 'week' THEN DATEDIFF_BIG(week, @Origin, @Value)
            WHEN 'day' THEN DATEDIFF_BIG(day, @Origin, @Value)
            WHEN 'hour' THEN DATEDIFF_BIG(hour, @Origin, @Value)
            WHEN 'minute' THEN DATEDIFF_BIG(minute, @Origin, @Value)
            WHEN 'second' THEN DATEDIFF_BIG(second, @Origin, @Value)
            WHEN 'millisecond'
                THEN DATEDIFF_BIG(millisecond, @Origin, @Value)
        END;
    DECLARE @BucketIndex bigint = @Distance / CONVERT(bigint, @Width);

    IF @Distance < 0 AND @Distance % @Width <> 0
        SET @BucketIndex -= 1;

    DECLARE
          @UnitOffset bigint = @BucketIndex * CONVERT(bigint, @Width)
        , @DayOffset int = 0
        , @Remainder int = 0
        , @Candidate datetimeoffset(7);

    IF @CanonicalDatePart = 'hour'
    BEGIN
        SET @DayOffset = CONVERT
        (
            int,
            @UnitOffset / 24
            - CASE
                  WHEN @UnitOffset < 0 AND @UnitOffset % 24 <> 0 THEN 1
                  ELSE 0
              END
        );
        SET @Remainder =
            CONVERT(int, @UnitOffset - CONVERT(bigint, @DayOffset) * 24);
        SET @Candidate =
            DATEADD(hour, @Remainder, DATEADD(day, @DayOffset, @Origin));
    END;
    ELSE IF @CanonicalDatePart = 'minute'
    BEGIN
        SET @DayOffset = CONVERT
        (
            int,
            @UnitOffset / 1440
            - CASE
                  WHEN @UnitOffset < 0 AND @UnitOffset % 1440 <> 0 THEN 1
                  ELSE 0
              END
        );
        SET @Remainder =
            CONVERT(int, @UnitOffset - CONVERT(bigint, @DayOffset) * 1440);
        SET @Candidate =
            DATEADD(minute, @Remainder, DATEADD(day, @DayOffset, @Origin));
    END;
    ELSE IF @CanonicalDatePart = 'second'
    BEGIN
        SET @DayOffset = CONVERT
        (
            int,
            @UnitOffset / 86400
            - CASE
                  WHEN @UnitOffset < 0 AND @UnitOffset % 86400 <> 0 THEN 1
                  ELSE 0
              END
        );
        SET @Remainder =
            CONVERT(int, @UnitOffset - CONVERT(bigint, @DayOffset) * 86400);
        SET @Candidate =
            DATEADD(second, @Remainder, DATEADD(day, @DayOffset, @Origin));
    END;
    ELSE IF @CanonicalDatePart = 'millisecond'
    BEGIN
        SET @DayOffset = CONVERT
        (
            int,
            @UnitOffset / 86400000
            - CASE
                  WHEN @UnitOffset < 0
                   AND @UnitOffset % 86400000 <> 0 THEN 1
                  ELSE 0
              END
        );
        SET @Remainder = CONVERT
        (
            int,
            @UnitOffset - CONVERT(bigint, @DayOffset) * 86400000
        );
        SET @Candidate =
            DATEADD(millisecond, @Remainder, DATEADD(day, @DayOffset, @Origin));
    END;
    ELSE
        SET @Candidate =
            CASE @CanonicalDatePart
                WHEN 'year'
                    THEN DATEADD(year, CONVERT(int, @UnitOffset), @Origin)
                WHEN 'quarter'
                    THEN DATEADD(quarter, CONVERT(int, @UnitOffset), @Origin)
                WHEN 'month'
                    THEN DATEADD(month, CONVERT(int, @UnitOffset), @Origin)
                WHEN 'week'
                    THEN DATEADD(week, CONVERT(int, @UnitOffset), @Origin)
                WHEN 'day'
                    THEN DATEADD(day, CONVERT(int, @UnitOffset), @Origin)
            END;

    IF @Candidate > @Value
        SET @Candidate =
            CASE @CanonicalDatePart
                WHEN 'year' THEN DATEADD(year, -@Width, @Candidate)
                WHEN 'quarter' THEN DATEADD(quarter, -@Width, @Candidate)
                WHEN 'month' THEN DATEADD(month, -@Width, @Candidate)
                WHEN 'week' THEN DATEADD(week, -@Width, @Candidate)
                WHEN 'day' THEN DATEADD(day, -@Width, @Candidate)
                WHEN 'hour' THEN DATEADD(hour, -@Width, @Candidate)
                WHEN 'minute' THEN DATEADD(minute, -@Width, @Candidate)
                WHEN 'second' THEN DATEADD(second, -@Width, @Candidate)
                WHEN 'millisecond'
                    THEN DATEADD(millisecond, -@Width, @Candidate)
            END;

    INSERT INTO @Result (Value, IsValid, ValidationCode)
    VALUES (@Candidate, 1, 0);
    RETURN;
END;
GO
