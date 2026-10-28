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
    /*
     * DDL-Hilfe: Liefert Kalendermonate, die den halboffenen Bereich
     * [@RangeStart,@RangeEndExclusive) schneiden. Pflichtparameter:
     * @RangeStart date und @RangeEndExclusive date; beide ohne Default.
     * NULL, gleiche oder umgekehrte
     * Grenzen liefern keine Zeilen. PeriodStart ist der Monatserste
     * des geschnittenen Monats und kann vor @RangeStart liegen. Das Resultset
     * ist Ordinal int (nullfrei, ab 0) und PeriodStart date (nullfrei).
     * Für Reihenfolge ORDER BY Ordinal verwenden. Für SELECT-Aufrufe wird
     * SELECT auf der Funktion benötigt.
     * Beispiel: SELECT Ordinal,PeriodStart
     * FROM toolbelt_datetime.TVF_DateSpineMonth('20260115','20260402')
     * ORDER BY Ordinal;
     * Erwartet: (0,2026-01-01),(1,2026-02-01),(2,2026-03-01),(3,2026-04-01).
     */
    SELECT spine.Ordinal, spine.PeriodStart
    FROM toolbelt_datetime.TVF_DateSpineCore
         (@RangeStart, @RangeEndExclusive, 'month') AS spine
);
GO
