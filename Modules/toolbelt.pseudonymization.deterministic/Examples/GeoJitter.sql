-- Nur synthetische 2D-Punkte, keine realen Geodaten.
-- Gleicher EntityKey/MappingVersion/Seed liefert dieselbe Modellstichprobe.
-- Ausgabe genau Value/ErrorCode; Distanz hier ausschließlich als Callerdiagnose.
SELECT synthetic.EntityKey, shifted.Value, shifted.ErrorCode
    , synthetic.Origin.STDistance(shifted.Value) AS CallerDistanceMeters
FROM (VALUES
      (CONVERT(varbinary(max), 0x010203), geography::Point(45, 179.99, 4326))
    , (CONVERT(varbinary(max), 0x040506), geography::Point(90, 0, 4326))
    , (CONVERT(varbinary(max), 0x070809), geography::Point(-90, 0, 4326))
) AS synthetic(EntityKey, Origin)
CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicGeoJitter
    (synthetic.Origin, synthetic.EntityKey, 1, DEFAULT, DEFAULT) AS shifted;
GO

-- Radius 0 ist kein Identity-Modus; Value NULL und ErrorCode 14.
SELECT Value, ErrorCode
FROM toolbelt_pseudonymization.TVF_DeterministicGeoJitter
    (geography::Point(0, 0, 4326), 0x010203, 1, 0, 0);
GO
