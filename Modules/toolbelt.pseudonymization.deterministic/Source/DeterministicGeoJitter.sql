-- ============================================================================
-- Objekt:          toolbelt_pseudonymization.TVF_DeterministicGeoJitter
-- Typ:             Echte Inline Table-valued Function, portables T-SQL.
-- Zweck:           Begrenzte deterministische Verschiebung synthetischer 2D-Punkte.
-- Vertrag:         Documentation/Architecture/DETERMINISTIC_GEO_JITTER_CONTRACT.md
-- Parameter:       Value geography, Key varbinary(max), MappingVersion int positiv,
--                  Seed bigint = 0, RadiusMeters int = 100 (1..10000).
-- Resultset:       Genau eine Zeile: Value geography NULL, ErrorCode int NOT NULL.
-- Dependencies:    Zweimal vorhandener interner TVF_DeterministicRangeCore.
-- Rechte:          SELECT; keine Grants, Persistenz, I/O oder neue CLR-Assembly.
-- Versionen:       SQL Server 2019/2022/2025, Windows/Linux als Zielmatrix.
-- Collation:       Binärer EntityKey; keine Caller-Textvergleiche.
-- Fehler:          NULL zuerst 0; Version 1, Seed 2, Radius 14, Key 4, Punkt 15,
--                  unveränderter Kernfehler, numerische Nachbedingung 16.
-- Performance:     Geography höchstens 128 serialisierte Bytes, Key 8000 Bytes.
-- Einschränkungen: Konservative Kugelkappe; kein Clamp/Retry/MakeValid/Clipping,
--                  keine Anonymisierung oder bitweise Plattformgleichheit.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_pseudonymization].[TVF_DeterministicGeoJitter]
(
      @Value          geography
    , @Key            varbinary(max)
    , @MappingVersion int
    , @Seed           bigint = 0
    , @RadiusMeters   int = 100
)
RETURNS TABLE
AS
RETURN
(
    WITH Raw AS
    (
        SELECT RawPoint = @Value
            , PointBytes = DATALENGTH(CONVERT(varbinary(max), @Value))
            , KeyBytes = DATALENGTH(@Key)
    ), Sized AS
    (
        -- Die UDT selbst ersetzen; ein Filter wäre keine Auswertungsbarriere.
        SELECT raw.*
            , SizedPoint = CASE WHEN raw.RawPoint IS NOT NULL AND raw.PointBytes <= 128
                THEN raw.RawPoint ELSE geography::Point(0, 0, 4326) END
        FROM Raw AS raw
    ), Validity AS
    (
        SELECT sized.*, IsValid = sized.SizedPoint.STIsValid()
        FROM Sized AS sized
    ), Valid AS
    (
        -- Weitere Methoden dürfen keinen noch ungültigen Sized-Operanden lesen.
        SELECT validity.*
            , ValidPoint = CASE WHEN validity.IsValid = 1 THEN validity.SizedPoint
                ELSE geography::Point(0, 0, 4326) END
        FROM Validity AS validity
    ), PointFacts AS
    (
        SELECT valid.*, IsEmpty = valid.ValidPoint.STIsEmpty()
            , PointKind = valid.ValidPoint.STGeometryType(), PointSrid = valid.ValidPoint.STSrid
        FROM Valid AS valid
    ), Point AS
    (
        SELECT facts.*
            , PointOperand = CASE WHEN facts.IsValid = 1 AND facts.IsEmpty = 0
                AND facts.PointKind = N'Point' AND facts.PointSrid = 4326
                THEN facts.ValidPoint ELSE geography::Point(0, 0, 4326) END
        FROM PointFacts AS facts
    ), TwoD AS
    (
        SELECT point.*
            , TwoDPoint = CASE WHEN point.PointOperand.Z IS NULL AND point.PointOperand.M IS NULL
                THEN point.PointOperand ELSE geography::Point(0, 0, 4326) END
            , AcceptedPoint = CASE WHEN point.RawPoint IS NOT NULL AND point.PointBytes <= 128
                AND point.IsValid = 1 AND point.IsEmpty = 0 AND point.PointKind = N'Point'
                AND point.PointSrid = 4326 AND point.PointOperand.Z IS NULL
                AND point.PointOperand.M IS NULL THEN 1 ELSE 0 END
        FROM Point AS point
    ), Configuration AS
    (
        SELECT twoD.*
            , ConfigurationError = CONVERT(int, CASE
                WHEN @Value IS NULL OR @Key IS NULL THEN 0
                WHEN @MappingVersion IS NULL OR @MappingVersion <= 0 THEN 1
                WHEN @Seed IS NULL THEN 2
                WHEN @RadiusMeters IS NULL OR @RadiusMeters < 1 OR @RadiusMeters > 10000 THEN 14
                WHEN twoD.KeyBytes = 0 OR twoD.KeyBytes > 8000 THEN 4
                WHEN twoD.AcceptedPoint <> 1 THEN 15 ELSE 0 END)
        FROM TwoD AS twoD
    ), SafeConfiguration AS
    (
        -- Auch ein vorgezogener Hash-/Trigonometriepfad erhält endliche Operanden.
        SELECT configuration.*
            -- Der Hashoperand braucht nur sein eigenes Key-Bytebudget;
            -- Spatial-Validierung bleibt in der ursprünglichen Fehlerentscheidung.
            , SafeKey = CASE WHEN @Key IS NOT NULL AND configuration.KeyBytes BETWEEN 1 AND 8000
                THEN @Key ELSE CONVERT(varbinary(max), 0x00) END
            , SafeVersion = CASE WHEN @MappingVersion > 0 THEN @MappingVersion ELSE 1 END
            , SafeSeed = ISNULL(@Seed, CONVERT(bigint, 0))
            , SafeRadius = CONVERT(float, CASE WHEN @RadiusMeters BETWEEN 1 AND 10000
                THEN @RadiusMeters ELSE 100 END)
        FROM Configuration AS configuration
    ), Samples AS
    (
        -- Zwei Kernzeilen relational auf vier numerische Fakten reduzieren.
        -- Dies ist keine Materialisierungs- oder Auswertungsreihenfolgegarantie.
        SELECT safe.*, draws.AreaValue, draws.AreaError, draws.DirectionValue, draws.DirectionError
        FROM SafeConfiguration AS safe
        CROSS APPLY
        (
            SELECT AreaValue = MAX(CASE WHEN packet.Slot = 0 THEN packet.Value END)
                , AreaError = MAX(CASE WHEN packet.Slot = 0 THEN packet.ErrorCode END)
                , DirectionValue = MAX(CASE WHEN packet.Slot = 1 THEN packet.Value END)
                , DirectionError = MAX(CASE WHEN packet.Slot = 1 THEN packet.ErrorCode END)
            FROM
            (
                SELECT Slot = 0, area.Value, area.ErrorCode
                FROM [toolbelt_pseudonymization].[TVF_DeterministicRangeCore]
                    (CONVERT(binary(8), 0x5442584447454F31), CONVERT(bigint, 0), safe.SafeKey,
                     safe.SafeVersion, safe.SafeSeed, CONVERT(bigint, 0), CONVERT(bigint, 9007199254740991)) AS area
                UNION ALL
                SELECT Slot = 1, direction.Value, direction.ErrorCode
                FROM [toolbelt_pseudonymization].[TVF_DeterministicRangeCore]
                    (CONVERT(binary(8), 0x5442584447454F31), CONVERT(bigint, 1), safe.SafeKey,
                     safe.SafeVersion, safe.SafeSeed, CONVERT(bigint, 0), CONVERT(bigint, 9007199254740991)) AS direction
            ) AS packet
        ) AS draws
        -- Nur Zeilenpartitionierung; alle nativen und skalaren Operanden bleiben abgesichert.
        -- Dieses Praedikat garantiert weder Auswertungsreihenfolge noch Materialisierung.
        WHERE @Value IS NOT NULL AND @Key IS NOT NULL AND safe.ConfigurationError = 0
    ), Angles AS
    (
        SELECT samples.*
            , Phi = RADIANS(samples.TwoDPoint.Lat)
            , Lambda = RADIANS(CASE WHEN samples.TwoDPoint.Lat IN (-90, 90)
                THEN CONVERT(float, 0) ELSE samples.TwoDPoint.Long END)
            , U = CONVERT(float, CASE WHEN samples.AreaValue BETWEEN 0 AND 9007199254740991
                THEN samples.AreaValue ELSE 0 END) / CONVERT(float, 9007199254740992)
            , Theta = 2 * PI() * (CONVERT(float, CASE WHEN samples.DirectionValue BETWEEN 0 AND 9007199254740991
                THEN samples.DirectionValue ELSE 0 END) / CONVERT(float, 9007199254740992))
        FROM Samples AS samples
    ), Basis AS
    (
        SELECT angles.*
            , SinPhi = SIN(angles.Phi), CosPhi = COS(angles.Phi)
            , SinLambda = SIN(angles.Lambda), CosLambda = COS(angles.Lambda)
            , SinTheta = SIN(angles.Theta), CosTheta = COS(angles.Theta)
            , Delta = 2 * ASIN(SQRT(angles.U) * SIN(angles.SafeRadius / CONVERT(float, 6416001) / 2))
        FROM Angles AS angles
    ), Vector AS
    (
        SELECT basis.*
            , X = COS(basis.Delta) * basis.CosPhi * basis.CosLambda
                + SIN(basis.Delta) * (-basis.CosTheta * basis.SinPhi * basis.CosLambda - basis.SinTheta * basis.SinLambda)
            , Y = COS(basis.Delta) * basis.CosPhi * basis.SinLambda
                + SIN(basis.Delta) * (-basis.CosTheta * basis.SinPhi * basis.SinLambda + basis.SinTheta * basis.CosLambda)
            , Z = COS(basis.Delta) * basis.SinPhi + SIN(basis.Delta) * basis.CosTheta * basis.CosPhi
        FROM Basis AS basis
    ), Coordinates AS
    (
        SELECT vector.*
            , Latitude = DEGREES(ATN2(facts.Z, SQRT(facts.X * facts.X + facts.Y * facts.Y)))
            , RawLongitude = DEGREES(ATN2(facts.Y, CASE WHEN facts.X = 0 AND facts.Y = 0
                THEN CONVERT(float, 1) ELSE facts.X END))
        FROM Vector AS vector
        CROSS APPLY
        (
            -- Drei endliche Achsenwerte relational reduzieren; keine neue Mathematik.
            -- Keine Zusage einer Materialisierung oder Auswertungsreihenfolge.
            SELECT X = MAX(CASE WHEN packet.Axis = 0 THEN packet.Value END)
                , Y = MAX(CASE WHEN packet.Axis = 1 THEN packet.Value END)
                , Z = MAX(CASE WHEN packet.Axis = 2 THEN packet.Value END)
            FROM (VALUES (0, vector.X), (1, vector.Y), (2, vector.Z)) AS packet(Axis, Value)
        ) AS facts
    ), Normalized AS
    (
        SELECT coordinates.*
            , Longitude = CASE WHEN coordinates.RawLongitude >= 180
                THEN coordinates.RawLongitude - 360 ELSE coordinates.RawLongitude END
        FROM Coordinates AS coordinates
    ), Constructor AS
    (
        SELECT normalized.*
            , CoordinatesValid = CASE WHEN normalized.Latitude BETWEEN -90 AND 90
                AND normalized.Longitude >= -180 AND normalized.Longitude < 180 THEN 1 ELSE 0 END
            -- Ersatz nur für den gefährdeten Konstruktor; Fehlerflag bleibt erhalten.
            , TargetPoint = geography::Point(
                CASE WHEN normalized.Latitude BETWEEN -90 AND 90 THEN normalized.Latitude ELSE CONVERT(float, 0) END,
                CASE WHEN normalized.Longitude >= -180 AND normalized.Longitude < 180 THEN normalized.Longitude ELSE CONVERT(float, 0) END,
                4326)
        FROM Normalized AS normalized
    ), Measured AS
    (
        SELECT constructor.*
            , DistanceMeters = constructor.TwoDPoint.STDistance(constructor.TargetPoint)
        FROM Constructor AS constructor
    ), Resolved AS
    (
        SELECT measured.TargetPoint
            , ErrorCode = CONVERT(int, CASE
                WHEN @Value IS NULL OR @Key IS NULL THEN 0
                WHEN measured.ConfigurationError <> 0 THEN measured.ConfigurationError
                WHEN measured.AreaError <> 0 THEN measured.AreaError
                WHEN measured.DirectionError <> 0 THEN measured.DirectionError
                WHEN measured.CoordinatesValid <> 1 OR measured.TargetPoint.STIsValid() <> 1
                    OR measured.TargetPoint.STIsEmpty() <> 0 OR measured.TargetPoint.STGeometryType() <> N'Point'
                    OR measured.TargetPoint.STSrid <> 4326 OR measured.TargetPoint.Z IS NOT NULL
                    OR measured.TargetPoint.M IS NOT NULL OR measured.DistanceMeters IS NULL
                    OR NOT (measured.DistanceMeters >= 0 AND measured.DistanceMeters <= measured.SafeRadius) THEN 16
                ELSE 0 END)
        FROM Measured AS measured
    )
    SELECT Value = CASE WHEN @Value IS NULL OR @Key IS NULL OR resolved.ErrorCode <> 0
                THEN CONVERT(geography, NULL) ELSE resolved.TargetPoint END
        , ErrorCode = ISNULL(resolved.ErrorCode, CONVERT(int, 16))
    FROM Resolved AS resolved
    UNION ALL
    SELECT Value = CONVERT(geography, NULL)
        , ErrorCode = ISNULL(configuration.ConfigurationError, CONVERT(int, 16))
    FROM Configuration AS configuration
    WHERE @Value IS NULL OR @Key IS NULL OR configuration.ConfigurationError <> 0
);
GO
