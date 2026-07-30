SET NOCOUNT ON;

DECLARE @CompatibilityLevel int = TRY_CONVERT(int, N'$(CompatibilityLevel)');
IF @CompatibilityLevel NOT IN (150, 160, 170)
    THROW 52830, N'CompatibilityLevel muss 150, 160 oder 170 sein.', 1;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id = DB_ID())
       <> @CompatibilityLevel
    THROW 52831, N'Falscher Compatibility Level.', 1;

IF OBJECT_ID(N'toolbelt_datetime.TVF_DateBucketDate', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_DateBucketDateTime2', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_DateBucketDateTimeOffset', N'IF') IS NULL
    THROW 52832, N'Die Bucket-Funktionen fehlen.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_datetime.TVF_DateBucketDate
            ('month', 3, '2026-07-30', DEFAULT)
       WHERE Value = CONVERT(date, '20260701', 112)
         AND IsValid = 1 AND ValidationCode = 0
   )
    THROW 52833, N'Der Default-Origin- oder Month-Bucket ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_datetime.TVF_DateBucketDateTime2
            (
                  'minute'
                , 15
                , '2026-07-30T12:34:56.1234567'
                , '2026-07-30T00:00:00'
            )
       WHERE Value = CONVERT(datetime2(7), '2026-07-30T12:30:00')
         AND IsValid = 1
   )
    THROW 52834, N'Der Fifteen-Minute-Bucket ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_datetime.TVF_DateBucketDateTime2
            (
                  'day'
                , 1
                , '2019-12-31T10:00:00'
                , '2020-01-01T12:00:00'
            )
       WHERE Value = CONVERT(datetime2(7), '2019-12-30T12:00:00')
   )
    THROW 52835, N'Die negative Floor-Semantik ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_datetime.TVF_DateBucketDateTime2
            (
                  'day'
                , 1
                , '2020-01-02T10:00:00'
                , '2020-01-01T12:00:00'
            )
       WHERE Value = CONVERT(datetime2(7), '2020-01-01T12:00:00')
   )
    THROW 52836, N'Die Origin-Zeitanteil-Korrektur ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_datetime.TVF_DateBucketDateTimeOffset
            (
                  'hour'
                , 6
                , '2026-07-30T12:34:56+05:30'
                , '2026-07-30T00:00:00+05:30'
            )
       WHERE Value =
             CONVERT(datetimeoffset(7), '2026-07-30T12:00:00+05:30')
   )
    THROW 52837, N'Der datetimeoffset-Bucket ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_datetime.TVF_DateBucketDate
            ('hour', 1, '20260730', DEFAULT)
       WHERE Value IS NULL AND IsValid = 0 AND ValidationCode = 12
   )
    THROW 52838, N'Der date-Datepart-Vertrag ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_datetime.TVF_DateBucketDateTime2
            ('microsecond', 1, '2026-07-30T12:00:00', DEFAULT)
       WHERE Value IS NULL AND IsValid = 0 AND ValidationCode = 10
   )
    THROW 52839, N'Der unbekannte Datepart-Vertrag ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_datetime.TVF_DateBucketDateTime2
            ('day', 0, '2026-07-30T12:00:00', DEFAULT)
       WHERE Value IS NULL AND IsValid = 0 AND ValidationCode = 11
   )
    THROW 52840, N'Der Width-Vertrag ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_datetime.TVF_DateBucketDateTime2
            (NULL, NULL, NULL, NULL)
       WHERE Value IS NULL AND IsValid IS NULL AND ValidationCode IS NULL
   )
    THROW 52841, N'NULL-Propagation ist falsch.', 1;

IF TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion')) >= 16
BEGIN
    DECLARE
          @Input datetime2(7) = '2026-07-30T12:34:56.1234567'
        , @Origin datetime2(7) = '2026-01-01T00:00:00'
        , @Native datetime2(7)
        , @Portable datetime2(7);

    EXEC sys.sp_executesql
          N'SELECT @Result = DATE_BUCKET(hour, 6, @Value, @BucketOrigin);'
        , N'@Value datetime2(7), @BucketOrigin datetime2(7), @Result datetime2(7) OUTPUT'
        , @Value = @Input, @BucketOrigin = @Origin
        , @Result = @Native OUTPUT;

    SELECT @Portable = Value
    FROM toolbelt_datetime.TVF_DateBucketDateTime2
         ('hour', 6, @Input, @Origin);

    IF @Native <> @Portable
        THROW 52842, N'Die native DATE_BUCKET-Parität ist falsch.', 1;
END;

PRINT N'Date/Time Bucket Contract-Prüfung: erfolgreich';
GO
