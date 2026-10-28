-- ============================================================================
-- Objekt:          toolbelt_datetime.TVF_DateSpineDay
-- Typ:             Inline Table-valued Function
-- Zweck:           Tagesperioden erzeugen, die einen halboffenen Bereich schneiden
-- Vertrag:         Documentation/TVF_DateSpineDay.md
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

CREATE OR ALTER FUNCTION [toolbelt_datetime].[TVF_DateSpineDay]
(
      @RangeStart        date
    , @RangeEndExclusive date
)
RETURNS TABLE
AS
RETURN
(
    /*
     * DDL-Hilfe: Liefert jeden Kalendertag, der den halboffenen Bereich
     * [@RangeStart,@RangeEndExclusive) schneidet. Pflichtparameter:
     * @RangeStart date und @RangeEndExclusive date; beide ohne Default.
     * NULL, gleiche oder umgekehrte
     * Grenzen liefern keine Zeilen. Das Resultset ist Ordinal int
     * (nullfrei, ab 0) und PeriodStart date (nullfrei, Tagesanfang).
     * Für eine Reihenfolge ist ORDER BY Ordinal erforderlich. Für SELECT-
     * Aufrufe wird SELECT auf der Funktion benötigt.
     * Beispiel: SELECT Ordinal,PeriodStart
     * FROM toolbelt_datetime.TVF_DateSpineDay('20260227','20260303')
     * ORDER BY Ordinal;
     * Erwartet: (0,2026-02-27),(1,2026-02-28),(2,2026-03-01),(3,2026-03-02).
     */
    SELECT spine.Ordinal, spine.PeriodStart
    FROM toolbelt_datetime.TVF_DateSpineCore
         (@RangeStart, @RangeEndExclusive, 'day') AS spine
);
GO
