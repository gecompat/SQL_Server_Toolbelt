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
