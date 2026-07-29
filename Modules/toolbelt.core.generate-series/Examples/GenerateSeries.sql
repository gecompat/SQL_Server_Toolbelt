-- ============================================================================
-- Synthetische Beispiele für toolbelt.core.generate-series
-- Erfordert ein erfolgreiches Deployment des Moduls.
-- ============================================================================

-- Aufsteigende int-Reihe mit Defaultschritt.
SELECT Value
FROM toolbelt_core.TVF_GenerateSeriesInt(1, 5, DEFAULT)
ORDER BY Value;

-- Absteigende bigint-Reihe; Stop wird nur bei Erreichbarkeit ausgegeben.
SELECT Value
FROM toolbelt_core.TVF_GenerateSeriesBigInt
(
    CONVERT(bigint, 10),
    CONVERT(bigint, 1),
    CONVERT(bigint, -4)
)
ORDER BY Value DESC;

-- Typstabile Verwendung in CROSS APPLY.
DECLARE @Ranges TABLE
(
      RangeId    int NOT NULL PRIMARY KEY
    , StartValue int NOT NULL
    , StopValue  int NOT NULL
);

INSERT INTO @Ranges (RangeId, StartValue, StopValue)
VALUES (1, 1, 3), (2, 5, 6);

SELECT ranges.RangeId, series.Value
FROM @Ranges AS ranges
CROSS APPLY toolbelt_core.TVF_GenerateSeriesInt
(
    ranges.StartValue,
    ranges.StopValue,
    DEFAULT
) AS series
ORDER BY ranges.RangeId, series.Value;
