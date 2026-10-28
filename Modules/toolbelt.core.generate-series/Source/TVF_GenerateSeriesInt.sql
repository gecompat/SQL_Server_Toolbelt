-- ============================================================================
-- Objekt:          toolbelt_core.TVF_GenerateSeriesInt
-- Zweck:           Typstabile int-Zahlenreihe einschließlich Startwert
-- Parameter:       @Start int, @Stop int, @Step int = NULL
-- Resultset:       Value int
-- Dependencies:    TVF_GenerateSeriesBigInt im selben Modul
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     dünne Inline-TVF über dem gemeinsamen bigint-Kern
-- Collation:       nicht anwendbar
-- Einschränkungen: keine garantierte Reihenfolge
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_core].[TVF_GenerateSeriesInt]
(
      @Start int
    , @Stop  int
    , @Step  int = NULL
)
RETURNS TABLE
AS
RETURN
(
    /*
     * DDL-Hilfe: Erzeugt eine typstabile int-Reihe ohne internes Zeilenlimit.
     * Parameter: @Start int NULL, @Stop int NULL, @Step int NULL
     * (Default NULL). NULL oder DEFAULT für @Step wählt +1 bei Start <= Stop,
     * sonst -1. Der Start ist enthalten; Stop nur, wenn die Schrittfolge ihn
     * erreicht. Eine falsche Schrittrichtung oder NULL bei Start/Stop
     * keine Zeile. Schritt 0 bleibt der
     * unveränderte Enginefehler, auch wenn eine Grenze NULL ist. Sehr große
     * gültige Reihen werden nicht gekürzt und können erhebliche Ressourcen
     * beanspruchen. Ergebnis: Value int; keine Reihenfolge ohne ORDER BY.
     * Für SELECT-Aufrufe ist SELECT auf der Funktion erforderlich.
     * Beispiel: SELECT Value FROM toolbelt_core.TVF_GenerateSeriesInt(2,10,3)
     * ORDER BY Value;
     * Erwartete Werte: 2, 5, 8.
     */
    /*
     * Die gesamte Reihenlogik liegt im bigint-Kern. Die Rückkonvertierung
     * erhält einen int-typisierten Join- und APPLY-Vertrag ohne zweite
     * Fachimplementierung.
     */
    SELECT Value = CONVERT(int, series.Value)
    FROM [toolbelt_core].[TVF_GenerateSeriesBigInt]
    (
          CONVERT(bigint, @Start)
        , CONVERT(bigint, @Stop)
        , CONVERT(bigint, @Step)
    ) AS series
);
GO
