-- ============================================================================
-- Objekt:          toolbelt_datetime.TVF_DateSpineMonth
-- Typ:             Inline Table-valued Function
-- Zweck:           Kalendermonate erzeugen, die einen halboffenen Bereich schneiden
-- Vertrag:         Documentation/TVF_DateSpineMonth.md
-- Parameter:       @RangeStart date, @RangeEndExclusive date
-- Resultset:       Ordinal int, PeriodStart date
-- Dependencies:    toolbelt_datetime.TVF_DateSpineCore
-- Rechte:          SELECT oder REFERENCES auf der Funktion
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Plattformen:     Windows und Linux
-- Fehlerverhalten: NULL-, leere und umgekehrte Bereiche liefern keine Zeilen.
-- Performance:     Inline TVF; linear zur Ergebnisgröße.
-- Einschränkungen: Keine garantierte Reihenfolge.
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_datetime].[TVF_DateSpineMonth]
(
      @RangeStart        date
    , @RangeEndExclusive date
)
RETURNS TABLE
AS
RETURN
(
    SELECT spine.Ordinal, spine.PeriodStart
    FROM toolbelt_datetime.TVF_DateSpineCore
         (@RangeStart, @RangeEndExclusive, 'month') AS spine
);
GO
