-- ============================================================================
-- Objekt:          toolbelt_datetime.TVF_DateSpineIsoWeek
-- Typ:             Inline Table-valued Function
-- Zweck:           ISO-Wochen erzeugen, die einen halboffenen Bereich schneiden
-- Vertrag:         Documentation/TVF_DateSpineIsoWeek.md
-- Parameter:       @RangeStart date, @RangeEndExclusive date
-- Resultset:       Ordinal int, PeriodStart date (Montag)
-- Dependencies:    toolbelt_datetime.TVF_DateSpineCore
-- Rechte:          SELECT oder REFERENCES auf der Funktion
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Plattformen:     Windows und Linux
-- Fehlerverhalten: NULL-, leere und umgekehrte Bereiche liefern keine Zeilen.
-- Performance:     Inline TVF; linear zur Ergebnisgröße.
-- Einschränkungen: Keine garantierte Reihenfolge; DATEFIRST-unabhängig.
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_datetime].[TVF_DateSpineIsoWeek]
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
         (@RangeStart, @RangeEndExclusive, 'iso_week') AS spine
);
GO
