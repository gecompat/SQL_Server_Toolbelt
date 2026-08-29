SET NOCOUNT ON;

DECLARE @CompatibilityLevel int = TRY_CONVERT(int, N'$(CompatibilityLevel)');
IF @CompatibilityLevel NOT IN (150, 160, 170)
    THROW 52950, N'CompatibilityLevel muss 150, 160 oder 170 sein.', 1;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id = DB_ID())
       <> @CompatibilityLevel
    THROW 52951, N'Falscher Compatibility Level.', 1;

IF OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineCore', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineDay', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineIsoWeek', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineMonth', N'IF') IS NULL
    THROW 52952, N'Die Date-Spine-Inline-TVFs fehlen.', 1;

IF EXISTS
   (
       SELECT expected.ObjectName
       FROM (VALUES
             (N'TVF_DateSpineDay'),
             (N'TVF_DateSpineIsoWeek'),
             (N'TVF_DateSpineMonth')) AS expected(ObjectName)
       WHERE NOT EXISTS
       (
           SELECT 1
           FROM sys.parameters AS parameters
           JOIN sys.objects AS objects ON objects.object_id = parameters.object_id
           JOIN sys.schemas AS schemas ON schemas.schema_id = objects.schema_id
           JOIN sys.types AS types ON types.user_type_id = parameters.user_type_id
           WHERE schemas.name = N'toolbelt_datetime'
             AND objects.name = expected.ObjectName
             AND parameters.parameter_id = 1
             AND parameters.name = N'@RangeStart'
             AND types.name = N'date'
       )
       OR NOT EXISTS
       (
           SELECT 1
           FROM sys.parameters AS parameters
           JOIN sys.objects AS objects ON objects.object_id = parameters.object_id
           JOIN sys.schemas AS schemas ON schemas.schema_id = objects.schema_id
           JOIN sys.types AS types ON types.user_type_id = parameters.user_type_id
           WHERE schemas.name = N'toolbelt_datetime'
             AND objects.name = expected.ObjectName
             AND parameters.parameter_id = 2
             AND parameters.name = N'@RangeEndExclusive'
             AND types.name = N'date'
       )
   )
    THROW 52953, N'Der öffentliche Parametervertrag ist falsch.', 1;

DECLARE @ExpectedDay TABLE
(
      Ordinal int NOT NULL
    , PeriodStart date NOT NULL
);
INSERT INTO @ExpectedDay VALUES
      (0, '20260227'), (1, '20260228'), (2, '20260301'), (3, '20260302');

IF EXISTS
   (
       SELECT Ordinal, PeriodStart FROM @ExpectedDay
       EXCEPT
       SELECT Ordinal, PeriodStart
       FROM toolbelt_datetime.TVF_DateSpineDay('20260227', '20260303')
   )
   OR EXISTS
   (
       SELECT Ordinal, PeriodStart
       FROM toolbelt_datetime.TVF_DateSpineDay('20260227', '20260303')
       EXCEPT
       SELECT Ordinal, PeriodStart FROM @ExpectedDay
   )
    THROW 52954, N'Der Tagesvertrag oder die exklusive Endgrenze ist falsch.', 1;

IF (SELECT COUNT(*)
    FROM toolbelt_datetime.TVF_DateSpineDay('20240228', '20240302')) <> 3
    THROW 52955, N'Der Schaltjahrvertrag ist falsch.', 1;

DECLARE @ExpectedWeek TABLE
(
      Ordinal int NOT NULL
    , PeriodStart date NOT NULL
);
INSERT INTO @ExpectedWeek VALUES (0, '20251229'), (1, '20260105');

SET DATEFIRST 7;
IF EXISTS
   (
       SELECT Ordinal, PeriodStart FROM @ExpectedWeek
       EXCEPT
       SELECT Ordinal, PeriodStart
       FROM toolbelt_datetime.TVF_DateSpineIsoWeek('20251231', '20260108')
   )
   OR EXISTS
   (
       SELECT Ordinal, PeriodStart
       FROM toolbelt_datetime.TVF_DateSpineIsoWeek('20251231', '20260108')
       EXCEPT
       SELECT Ordinal, PeriodStart FROM @ExpectedWeek
   )
    THROW 52956, N'Der ISO-Wochenvertrag bei DATEFIRST 7 ist falsch.', 1;

SET DATEFIRST 3;
IF EXISTS
   (
       SELECT Ordinal, PeriodStart FROM @ExpectedWeek
       EXCEPT
       SELECT Ordinal, PeriodStart
       FROM toolbelt_datetime.TVF_DateSpineIsoWeek('20251231', '20260108')
   )
   OR EXISTS
   (
       SELECT Ordinal, PeriodStart
       FROM toolbelt_datetime.TVF_DateSpineIsoWeek('20251231', '20260108')
       EXCEPT
       SELECT Ordinal, PeriodStart FROM @ExpectedWeek
   )
    THROW 52957, N'Die ISO-Woche ist von DATEFIRST abhängig.', 1;

DECLARE @ExpectedMonth TABLE
(
      Ordinal int NOT NULL
    , PeriodStart date NOT NULL
);
INSERT INTO @ExpectedMonth VALUES
      (0, '20260101'), (1, '20260201'), (2, '20260301'), (3, '20260401');

IF EXISTS
   (
       SELECT Ordinal, PeriodStart FROM @ExpectedMonth
       EXCEPT
       SELECT Ordinal, PeriodStart
       FROM toolbelt_datetime.TVF_DateSpineMonth('20260115', '20260402')
   )
   OR EXISTS
   (
       SELECT Ordinal, PeriodStart
       FROM toolbelt_datetime.TVF_DateSpineMonth('20260115', '20260402')
       EXCEPT
       SELECT Ordinal, PeriodStart FROM @ExpectedMonth
   )
    THROW 52958, N'Der Monats- oder Randperiodenvertrag ist falsch.', 1;

IF EXISTS (SELECT 1 FROM toolbelt_datetime.TVF_DateSpineDay(NULL, '20260101'))
   OR EXISTS (SELECT 1 FROM toolbelt_datetime.TVF_DateSpineDay('20260101', NULL))
   OR EXISTS (SELECT 1 FROM toolbelt_datetime.TVF_DateSpineDay('20260101', '20260101'))
   OR EXISTS (SELECT 1 FROM toolbelt_datetime.TVF_DateSpineDay('20260102', '20260101'))
   OR EXISTS (SELECT 1 FROM toolbelt_datetime.TVF_DateSpineIsoWeek(NULL, NULL))
   OR EXISTS (SELECT 1 FROM toolbelt_datetime.TVF_DateSpineMonth('20260102', '20260101'))
    THROW 52959, N'Der NULL-, Leer- oder Umkehrbereichsvertrag ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_datetime.TVF_DateSpineDay('00010101', '00010102')
       WHERE Ordinal = 0 AND PeriodStart = CONVERT(date, '00010101', 112)
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_datetime.TVF_DateSpineIsoWeek('00010101', '00010102')
       WHERE Ordinal = 0 AND PeriodStart = CONVERT(date, '00010101', 112)
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_datetime.TVF_DateSpineMonth('99991230', '99991231')
       WHERE Ordinal = 0 AND PeriodStart = CONVERT(date, '99991201', 112)
   )
    THROW 52960, N'Der date-Grenzwertvertrag ist falsch.', 1;

DECLARE @ScaleEnd date = DATEADD(day, 100000, CONVERT(date, '20000101', 112));
IF NOT EXISTS
   (
       SELECT 1
       FROM
       (
           SELECT
                 GeneratedRows = COUNT_BIG(*)
               , MinimumOrdinal = MIN(Ordinal)
               , MaximumOrdinal = MAX(Ordinal)
           FROM toolbelt_datetime.TVF_DateSpineDay('20000101', @ScaleEnd)
       ) AS scale
       WHERE scale.GeneratedRows = 100000
         AND scale.MinimumOrdinal = 0
         AND scale.MaximumOrdinal = 99999
   )
    THROW 52961, N'Der Skalierungs- oder Ordinalvertrag ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM (VALUES
             (CONVERT(date, '20260102', 112), CONVERT(date, '20260105', 112)))
            AS ranges(RangeStart, RangeEndExclusive)
       CROSS APPLY toolbelt_datetime.TVF_DateSpineDay
                   (ranges.RangeStart, ranges.RangeEndExclusive) AS spine
       GROUP BY ranges.RangeStart, ranges.RangeEndExclusive
       HAVING COUNT(*) = 3
   )
    THROW 52962, N'Der mengenorientierte APPLY-Vertrag ist falsch.', 1;

PRINT N'Date-Spine Contract-Prüfung: erfolgreich';
GO
