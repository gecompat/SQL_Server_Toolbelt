-- ============================================================================
-- Objekt:          toolbelt_datetime.TVF_CalendarDifference
-- Zweck:           Zerlegt einen Datumsabstand in vollständige Kalenderjahre,
--                  -monate und Resttage.
-- Parameter:       @StartDate date, @EndDate date
-- Resultset:       Sign smallint, Years int, Months int, Days int
-- Dependencies:    keine Toolbelt-Module
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Inline TVF; geeignet für CROSS APPLY
-- Collation:       nicht anwendbar
-- Einschränkungen: Anniversary-Regel klammert nicht vorhandene Monatstage an
--                  den letzten Tag des Zielmonats.
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_datetime].[TVF_CalendarDifference]
(
      @StartDate date
    , @EndDate   date
)
RETURNS TABLE
AS
RETURN
(
    /* DATEADD klammert nicht vorhandene Monatstage an das Monatsende. */
    WITH OrderedDates AS
    (
        SELECT
              Sign = CONVERT(smallint, CASE
                  WHEN @StartDate IS NULL OR @EndDate IS NULL THEN NULL
                  WHEN @StartDate < @EndDate THEN 1
                  WHEN @StartDate > @EndDate THEN -1 ELSE 0 END)
            , EarlierDate = CASE WHEN @StartDate <= @EndDate THEN @StartDate ELSE @EndDate END
            , LaterDate = CASE WHEN @StartDate <= @EndDate THEN @EndDate ELSE @StartDate END
    ),
    Years AS
    (
        SELECT
              ordered.Sign, ordered.EarlierDate, ordered.LaterDate
            , Years = CASE
                WHEN DATEADD(year, DATEDIFF(year, ordered.EarlierDate, ordered.LaterDate), ordered.EarlierDate) > ordered.LaterDate
                    THEN DATEDIFF(year, ordered.EarlierDate, ordered.LaterDate) - 1
                ELSE DATEDIFF(year, ordered.EarlierDate, ordered.LaterDate) END
        FROM OrderedDates AS ordered
    ),
    Months AS
    (
        SELECT
              years.Sign, years.Years, years.LaterDate
            , YearAnchor = DATEADD(year, years.Years, years.EarlierDate)
        FROM Years AS years
    ),
    Resolved AS
    (
        SELECT
              months.Sign, months.Years, months.YearAnchor, months.LaterDate
            , Months = CASE
                WHEN DATEADD(month, DATEDIFF(month, months.YearAnchor, months.LaterDate), months.YearAnchor) > months.LaterDate
                    THEN DATEDIFF(month, months.YearAnchor, months.LaterDate) - 1
                ELSE DATEDIFF(month, months.YearAnchor, months.LaterDate) END
        FROM Months AS months
    )
    SELECT
          resolved.Sign, resolved.Years, resolved.Months
        , Days = DATEDIFF(day, DATEADD(month, resolved.Months, resolved.YearAnchor), resolved.LaterDate)
    FROM Resolved AS resolved
);
GO
