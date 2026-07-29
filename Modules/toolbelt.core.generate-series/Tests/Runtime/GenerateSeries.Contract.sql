-- ============================================================================
-- Contract-Tests für portable int- und bigint-Zahlenreihen
-- Daten: ausschließlich synthetisch
-- SQLCMD-Variable: CompatibilityLevel=150|160|170
-- ============================================================================

SET NOCOUNT ON;

DECLARE @CompatibilityLevel int =
    TRY_CONVERT(int, N'$(CompatibilityLevel)');

IF @CompatibilityLevel NOT IN (150, 160, 170)
BEGIN
    THROW 52400, N'CompatibilityLevel muss 150, 160 oder 170 sein.', 1;
END;

DECLARE @SetCompatibilitySql nvarchar(max) =
    N'ALTER DATABASE '
    + QUOTENAME(DB_NAME())
    + N' SET COMPATIBILITY_LEVEL = '
    + CONVERT(nvarchar(3), @CompatibilityLevel)
    + N';';
EXEC sys.sp_executesql @SetCompatibilitySql;

IF OBJECT_ID(N'toolbelt_core.TVF_GenerateSeriesBigInt', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_core.TVF_GenerateSeriesInt', N'IF') IS NULL
BEGIN
    THROW 52401, N'Die öffentlichen Generate-Series-Funktionen fehlen.', 1;
END;

IF EXISTS
   (
       SELECT expected.ObjectName
       FROM
       (
           VALUES
               (N'TVF_GenerateSeriesBigInt', N'bigint')
             , (N'TVF_GenerateSeriesInt', N'int')
       ) AS expected(ObjectName, TypeName)
       WHERE NOT EXISTS
             (
                 SELECT 1
                 FROM sys.parameters AS parameters
                 WHERE parameters.object_id = OBJECT_ID
                       (
                           N'toolbelt_core.' + expected.ObjectName,
                           N'IF'
                       )
                   AND parameters.parameter_id = 1
                   AND parameters.name = N'@Start'
                   AND TYPE_NAME(parameters.user_type_id) = expected.TypeName
             )
          OR NOT EXISTS
             (
                 SELECT 1
                 FROM sys.parameters AS parameters
                 WHERE parameters.object_id = OBJECT_ID
                       (
                           N'toolbelt_core.' + expected.ObjectName,
                           N'IF'
                       )
                   AND parameters.parameter_id = 2
                   AND parameters.name = N'@Stop'
                   AND TYPE_NAME(parameters.user_type_id) = expected.TypeName
             )
          OR NOT EXISTS
             (
                 SELECT 1
                 FROM sys.parameters AS parameters
                 WHERE parameters.object_id = OBJECT_ID
                       (
                           N'toolbelt_core.' + expected.ObjectName,
                           N'IF'
                       )
                   AND parameters.parameter_id = 3
                   AND parameters.name = N'@Step'
                   AND TYPE_NAME(parameters.user_type_id) = expected.TypeName
             )
          OR NOT EXISTS
             (
                 SELECT 1
                 FROM sys.columns AS columns
                 WHERE columns.object_id = OBJECT_ID
                       (
                           N'toolbelt_core.' + expected.ObjectName,
                           N'IF'
                       )
                   AND columns.column_id = 1
                   AND columns.name = N'Value'
                   AND TYPE_NAME(columns.user_type_id) = expected.TypeName
             )
          OR OBJECT_DEFINITION
             (
                 OBJECT_ID(N'toolbelt_core.' + expected.ObjectName, N'IF')
             ) NOT LIKE N'%@Step%=%NULL%'
   )
BEGIN
    THROW 52402, N'Die öffentliche Signatur oder Resultspalte weicht vom Vertrag ab.', 1;
END;

DECLARE @ExpectedInt TABLE
(
    Value int NOT NULL PRIMARY KEY
);

INSERT INTO @ExpectedInt (Value)
VALUES (1), (2), (3), (4), (5);

IF EXISTS
   (
       SELECT Value FROM @ExpectedInt
       EXCEPT
       SELECT Value
       FROM toolbelt_core.TVF_GenerateSeriesInt(1, 5, DEFAULT)
   )
   OR EXISTS
      (
          SELECT Value
          FROM toolbelt_core.TVF_GenerateSeriesInt(1, 5, DEFAULT)
          EXCEPT
          SELECT Value FROM @ExpectedInt
      )
BEGIN
    THROW 52403, N'Die aufsteigende int-Defaultreihe ist falsch.', 1;
END;

IF EXISTS
   (
       SELECT Value FROM @ExpectedInt
       EXCEPT
       SELECT Value
       FROM toolbelt_core.TVF_GenerateSeriesInt(5, 1, DEFAULT)
   )
   OR EXISTS
      (
          SELECT Value
          FROM toolbelt_core.TVF_GenerateSeriesInt(5, 1, DEFAULT)
          EXCEPT
          SELECT Value FROM @ExpectedInt
      )
BEGIN
    THROW 52404, N'Die absteigende int-Defaultreihe ist falsch.', 1;
END;

DECLARE @ExpectedStep TABLE
(
    Value int NOT NULL PRIMARY KEY
);

INSERT INTO @ExpectedStep (Value)
VALUES (2), (5), (8);

IF EXISTS
   (
       SELECT Value FROM @ExpectedStep
       EXCEPT
       SELECT Value
       FROM toolbelt_core.TVF_GenerateSeriesInt(2, 10, 3)
   )
   OR EXISTS
      (
          SELECT Value
          FROM toolbelt_core.TVF_GenerateSeriesInt(2, 10, 3)
          EXCEPT
          SELECT Value FROM @ExpectedStep
      )
BEGIN
    THROW 52405, N'Der nicht erreichbare Stopwert wird falsch behandelt.', 1;
END;

IF EXISTS
   (
       SELECT 1 FROM toolbelt_core.TVF_GenerateSeriesInt(1, 5, -1)
   )
   OR EXISTS
      (
          SELECT 1 FROM toolbelt_core.TVF_GenerateSeriesInt(5, 1, 1)
      )
   OR EXISTS
      (
          SELECT 1
          FROM toolbelt_core.TVF_GenerateSeriesInt(NULL, 1, DEFAULT)
      )
   OR EXISTS
      (
          SELECT 1
          FROM toolbelt_core.TVF_GenerateSeriesBigInt
          (
              CONVERT(bigint, 1),
              CONVERT(bigint, NULL),
              DEFAULT
          )
      )
BEGIN
    THROW 52406, N'Falsche Richtung oder NULL-Grenzen liefern keine leere Menge.', 1;
END;

DECLARE @ExpectedErrorObserved bit = 0;

BEGIN TRY
    DECLARE @ZeroStepCount bigint;
    SELECT @ZeroStepCount = COUNT_BIG(*)
    FROM toolbelt_core.TVF_GenerateSeriesBigInt
    (
        CONVERT(bigint, 1),
        CONVERT(bigint, 5),
        CONVERT(bigint, 0)
    );
END TRY
BEGIN CATCH
    SET @ExpectedErrorObserved = 1;
END CATCH;

IF @ExpectedErrorObserved = 0
BEGIN
    THROW 52407, N'Schrittweite 0 hat keinen Enginefehler erzeugt.', 1;
END;

SET @ExpectedErrorObserved = 0;

BEGIN TRY
    DECLARE @NullZeroStepCount bigint;
    SELECT @NullZeroStepCount = COUNT_BIG(*)
    FROM toolbelt_core.TVF_GenerateSeriesInt(NULL, 5, 0);
END TRY
BEGIN CATCH
    SET @ExpectedErrorObserved = 1;
END CATCH;

IF @ExpectedErrorObserved = 0
BEGIN
    THROW 52408, N'Der Schrittfehler hat nicht den dokumentierten Vorrang.', 1;
END;

DECLARE @ExpectedBigInt TABLE
(
    Value bigint NOT NULL PRIMARY KEY
);

INSERT INTO @ExpectedBigInt (Value)
VALUES
      (CONVERT(bigint, -9223372036854775807) - 1)
    , (CONVERT(bigint, -1))
    , (CONVERT(bigint, 9223372036854775806));

IF EXISTS
   (
       SELECT Value FROM @ExpectedBigInt
       EXCEPT
       SELECT Value
       FROM toolbelt_core.TVF_GenerateSeriesBigInt
       (
           CONVERT(bigint, -9223372036854775807) - 1,
           CONVERT(bigint, 9223372036854775807),
           CONVERT(bigint, 9223372036854775807)
       )
   )
   OR EXISTS
      (
          SELECT Value
          FROM toolbelt_core.TVF_GenerateSeriesBigInt
          (
              CONVERT(bigint, -9223372036854775807) - 1,
              CONVERT(bigint, 9223372036854775807),
              CONVERT(bigint, 9223372036854775807)
          )
          EXCEPT
          SELECT Value FROM @ExpectedBigInt
      )
BEGIN
    THROW 52409, N'Die bigint-Grenzarithmetik ist falsch.', 1;
END;

SET @ExpectedErrorObserved = 0;

BEGIN TRY
    DECLARE @OverflowCount bigint;
    SELECT @OverflowCount = COUNT_BIG(*)
    FROM toolbelt_core.TVF_GenerateSeriesBigInt
    (
        CONVERT(bigint, -9223372036854775807) - 1,
        CONVERT(bigint, 9223372036854775807),
        CONVERT(bigint, 1)
    );
END TRY
BEGIN CATCH
    SET @ExpectedErrorObserved = 1;
END CATCH;

IF @ExpectedErrorObserved = 0
BEGIN
    THROW 52410, N'Eine nicht bigint-fähige Zeilenzahl wurde still gekürzt.', 1;
END;

DECLARE
      @MillionCount bigint
    , @MillionMin   int
    , @MillionMax   int;

SELECT
      @MillionCount = COUNT_BIG(*)
    , @MillionMin = MIN(series.Value)
    , @MillionMax = MAX(series.Value)
FROM toolbelt_core.TVF_GenerateSeriesInt(1, 1000000, DEFAULT) AS series;

IF @MillionCount <> 1000000
   OR @MillionMin <> 1
   OR @MillionMax <> 1000000
BEGIN
    THROW 52411, N'Die synthetische Eine-Million-Reihe ist falsch.', 1;
END;

CREATE TABLE #tbx_GenerateSeriesRowGoal
(
    Value bigint NOT NULL
);

INSERT INTO #tbx_GenerateSeriesRowGoal (Value)
SELECT TOP (10) series.Value
FROM toolbelt_core.TVF_GenerateSeriesBigInt
(
    CONVERT(bigint, 0),
    CONVERT(bigint, 9223372036854775806),
    CONVERT(bigint, 1)
) AS series;

IF (SELECT COUNT_BIG(*) FROM #tbx_GenerateSeriesRowGoal) <> 10
BEGIN
    THROW 52412, N'Der TOP-Aufrufer erhielt nicht zehn Werte.', 1;
END;

DECLARE @JoinInput TABLE
(
    Value int NOT NULL PRIMARY KEY
);

INSERT INTO @JoinInput (Value)
VALUES (1), (3), (5);

IF
(
    SELECT COUNT_BIG(*)
    FROM @JoinInput AS input
    INNER JOIN toolbelt_core.TVF_GenerateSeriesInt(1, 5, DEFAULT) AS series
        ON series.Value = input.Value
) <> 3
BEGIN
    THROW 52413, N'Der typstabile int-Join ist fehlgeschlagen.', 1;
END;

DECLARE @Ranges TABLE
(
      RangeId    int NOT NULL PRIMARY KEY
    , StartValue int NOT NULL
    , StopValue  int NOT NULL
);

INSERT INTO @Ranges (RangeId, StartValue, StopValue)
VALUES (1, 1, 3), (2, 10, 11);

IF
(
    SELECT COUNT_BIG(*)
    FROM @Ranges AS ranges
    CROSS APPLY toolbelt_core.TVF_GenerateSeriesInt
    (
        ranges.StartValue,
        ranges.StopValue,
        DEFAULT
    ) AS series
) <> 5
BEGIN
    THROW 52414, N'Der CROSS-APPLY-Vertrag ist fehlgeschlagen.', 1;
END;

/*
 * Die native Funktion wird nur bei verfügbarem Compatibility Level dynamisch
 * kompiliert. Der portable Source-Code bleibt versionsunabhängig.
 */
IF @CompatibilityLevel IN (160, 170)
BEGIN
    CREATE TABLE #tbx_NativeSeries
    (
        Value bigint NOT NULL
    );

    CREATE TABLE #tbx_PortableSeries
    (
        Value bigint NOT NULL
    );

    DECLARE @NativeCases TABLE
    (
          CaseOrdinal int    NOT NULL PRIMARY KEY
        , StartValue  bigint NOT NULL
        , StopValue   bigint NOT NULL
        , StepValue   bigint NOT NULL
    );

    INSERT INTO @NativeCases
    (
          CaseOrdinal
        , StartValue
        , StopValue
        , StepValue
    )
    VALUES
          (1, 1, 10, 1)
        , (2, 10, 1, -2)
        , (3, 2, 10, 3)
        , (4, 1, 10, -1);

    DECLARE
          @CaseOrdinal int = 1
        , @CaseCount   int = (SELECT COUNT(*) FROM @NativeCases)
        , @NativeStart bigint
        , @NativeStop  bigint
        , @NativeStep  bigint;

    WHILE @CaseOrdinal <= @CaseCount
    BEGIN
        SELECT
              @NativeStart = StartValue
            , @NativeStop = StopValue
            , @NativeStep = StepValue
        FROM @NativeCases
        WHERE CaseOrdinal = @CaseOrdinal;

        TRUNCATE TABLE #tbx_NativeSeries;
        TRUNCATE TABLE #tbx_PortableSeries;

        EXEC sys.sp_executesql
              N'INSERT INTO #tbx_NativeSeries (Value)
                SELECT value
                FROM GENERATE_SERIES(@Start, @Stop, @Step);'
            , N'@Start bigint, @Stop bigint, @Step bigint'
            , @Start = @NativeStart
            , @Stop = @NativeStop
            , @Step = @NativeStep;

        INSERT INTO #tbx_PortableSeries (Value)
        SELECT Value
        FROM toolbelt_core.TVF_GenerateSeriesBigInt
        (
            @NativeStart,
            @NativeStop,
            @NativeStep
        );

        IF EXISTS
           (
               SELECT Value FROM #tbx_NativeSeries
               EXCEPT
               SELECT Value FROM #tbx_PortableSeries
           )
           OR EXISTS
              (
                  SELECT Value FROM #tbx_PortableSeries
                  EXCEPT
                  SELECT Value FROM #tbx_NativeSeries
              )
        BEGIN
            THROW 52415, N'Die Parität zum nativen GENERATE_SERIES ist fehlgeschlagen.', 1;
        END;

        SET @CaseOrdinal += 1;
    END;
END;

PRINT N'Generate-Series Contract-Tests für Compatibility Level '
    + CONVERT(nvarchar(3), @CompatibilityLevel)
    + N': erfolgreich';
GO
