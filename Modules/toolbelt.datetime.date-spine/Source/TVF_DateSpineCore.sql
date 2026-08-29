-- ============================================================================
-- Objekt:          toolbelt_datetime.TVF_DateSpineCore
-- Typ:             Inline Table-valued Function (intern)
-- Zweck:           Gemeinsamer relationaler Kern für periodische Date Spines
-- Vertrag:         Documentation/Architecture/DATE_SPINE_MODULE_DESIGN.md
-- Parameter:       @RangeStart date, @RangeEndExclusive date,
--                  @Grain varchar(16)
-- Resultset:       Ordinal int, PeriodStart date
-- Dependencies:    toolbelt.core.generate-series 1.0.0;
--                  toolbelt.datetime.truncate 1.0.0
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Plattformen:     Windows und Linux
-- Fehlerverhalten: Ungültiger Grain sowie NULL-, leere und umgekehrte
--                  Bereiche liefern keine Zeilen.
-- Performance:     Inline TVF; Aufwand und Ergebnisgröße wachsen linear mit
--                  der Zahl der geschnittenen Perioden.
-- Einschränkungen: Internes Objekt; keine garantierte Reihenfolge.
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_datetime].[TVF_DateSpineCore]
(
      @RangeStart        date
    , @RangeEndExclusive date
    , @Grain             varchar(16)
)
RETURNS TABLE
AS
RETURN
(
    /*
     * Der Ersatzwert schützt DATEADD bei einer ungültigen minimalen
     * Exklusivgrenze. Die ValidRange-CTE entfernt diesen Pfad vollständig aus
     * dem Ergebnis; sie vermeidet zugleich eine optimizerabhängige
     * Kurzschlussannahme für den date-Unterlauf.
     */
    WITH InputContract AS
    (
        SELECT
              IsValidRange = CONVERT
              (
                  bit,
                  CASE
                      WHEN @RangeStart IS NOT NULL
                       AND @RangeEndExclusive IS NOT NULL
                       AND @RangeStart < @RangeEndExclusive
                       AND @Grain COLLATE Latin1_General_100_BIN2
                           IN ('day', 'iso_week', 'month')
                          THEN 1
                      ELSE 0
                  END
              )
            , LastIncludedDate = DATEADD
              (
                  day,
                  -1,
                  CASE
                      WHEN @RangeStart IS NOT NULL
                       AND @RangeEndExclusive IS NOT NULL
                       AND @RangeStart < @RangeEndExclusive
                          THEN @RangeEndExclusive
                      ELSE CONVERT(date, '00010102', 112)
                  END
              )
    ),
    Boundaries AS
    (
        SELECT
              FirstPeriodStart = CONVERT
              (
                  date,
                  CASE @Grain COLLATE Latin1_General_100_BIN2
                      WHEN 'day' THEN @RangeStart
                      WHEN 'iso_week' THEN first_iso_week.Value
                      WHEN 'month' THEN first_month.Value
                  END
              )
            , LastPeriodStart = CONVERT
              (
                  date,
                  CASE @Grain COLLATE Latin1_General_100_BIN2
                      WHEN 'day' THEN input.LastIncludedDate
                      WHEN 'iso_week' THEN last_iso_week.Value
                      WHEN 'month' THEN last_month.Value
                  END
              )
        FROM InputContract AS input
        CROSS APPLY toolbelt_datetime.TVF_TruncateDate
                    ('iso_week', @RangeStart) AS first_iso_week
        CROSS APPLY toolbelt_datetime.TVF_TruncateDate
                    ('month', @RangeStart) AS first_month
        CROSS APPLY toolbelt_datetime.TVF_TruncateDate
                    ('iso_week', input.LastIncludedDate) AS last_iso_week
        CROSS APPLY toolbelt_datetime.TVF_TruncateDate
                    ('month', input.LastIncludedDate) AS last_month
        WHERE input.IsValidRange = 1
    ),
    CountedBoundaries AS
    (
        SELECT
              boundaries.FirstPeriodStart
            , LastOrdinal = CONVERT
              (
                  int,
                  CASE @Grain COLLATE Latin1_General_100_BIN2
                      WHEN 'day' THEN DATEDIFF
                           (day, boundaries.FirstPeriodStart,
                            boundaries.LastPeriodStart)
                      WHEN 'iso_week' THEN DATEDIFF
                           (day, boundaries.FirstPeriodStart,
                            boundaries.LastPeriodStart) / 7
                      WHEN 'month' THEN DATEDIFF
                           (month, boundaries.FirstPeriodStart,
                            boundaries.LastPeriodStart)
                  END
              )
        FROM Boundaries AS boundaries
    )
    SELECT
          Ordinal = series.Value
        , PeriodStart = CONVERT
          (
              date,
              CASE @Grain COLLATE Latin1_General_100_BIN2
                  WHEN 'day' THEN DATEADD
                       (day, series.Value, counted.FirstPeriodStart)
                  WHEN 'iso_week' THEN DATEADD
                       (day, series.Value * 7, counted.FirstPeriodStart)
                  WHEN 'month' THEN DATEADD
                       (month, series.Value, counted.FirstPeriodStart)
              END
          )
    FROM CountedBoundaries AS counted
    CROSS APPLY toolbelt_core.TVF_GenerateSeriesInt
                (0, counted.LastOrdinal, 1) AS series
);
GO
