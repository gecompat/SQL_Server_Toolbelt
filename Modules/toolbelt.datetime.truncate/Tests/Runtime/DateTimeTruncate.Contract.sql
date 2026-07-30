SET NOCOUNT ON;

DECLARE @CompatibilityLevel int = TRY_CONVERT(int, N'$(CompatibilityLevel)');
IF @CompatibilityLevel NOT IN (150, 160, 170)
    THROW 52800, N'CompatibilityLevel muss 150, 160 oder 170 sein.', 1;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id = DB_ID())
       <> @CompatibilityLevel
    THROW 52801, N'Falscher Compatibility Level.', 1;

IF OBJECT_ID(N'toolbelt_datetime.TVF_TruncateDate', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_TruncateDateTime2', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_TruncateDateTimeOffset', N'IF') IS NULL
    THROW 52802, N'Die Truncation-Funktionen fehlen.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_datetime.TVF_TruncateDate('month', '20260730')
       WHERE Value = CONVERT(date, '20260701', 112)
         AND IsValid = 1 AND ValidationCode = 0
   )
    THROW 52803, N'Month-Truncation für date ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_datetime.TVF_TruncateDateTime2
            ('millisecond', '2026-07-30T12:34:56.1234567')
       WHERE Value = CONVERT(datetime2(7), '2026-07-30T12:34:56.1230000')
         AND IsValid = 1
   )
    THROW 52804, N'Millisecond-Truncation ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_datetime.TVF_TruncateDateTime2
            ('mcs', '2026-07-30T12:34:56.1234567')
       WHERE Value = CONVERT(datetime2(7), '2026-07-30T12:34:56.1234560')
         AND IsValid = 1
   )
    THROW 52805, N'Microsecond-Truncation oder Alias ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_datetime.TVF_TruncateDateTimeOffset
            ('hour', '2026-07-30T12:34:56.1234567+05:30')
       WHERE Value =
             CONVERT(datetimeoffset(7), '2026-07-30T12:00:00.0000000+05:30')
         AND IsValid = 1
   )
    THROW 52806, N'Datetimeoffset-Truncation erhält den Offset nicht.', 1;

SET DATEFIRST 7;
IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_datetime.TVF_TruncateDate('week', '20211111')
       WHERE Value = CONVERT(date, '20211107', 112)
   )
    THROW 52807, N'week folgt DATEFIRST 7 nicht.', 1;

SET DATEFIRST 3;
IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_datetime.TVF_TruncateDate('wk', '20211111')
       WHERE Value = CONVERT(date, '20211110', 112)
   )
    THROW 52808, N'week folgt DATEFIRST 3 oder dem Alias nicht.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_datetime.TVF_TruncateDate('iso_week', '20211111')
       WHERE Value = CONVERT(date, '20211108', 112)
   )
    THROW 52809, N'iso_week ist falsch.', 1;

SET DATEFIRST 7;
IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_datetime.TVF_TruncateDate('week', '00010101')
       WHERE Value IS NULL AND IsValid = 0 AND ValidationCode = 12
   )
    THROW 52810, N'Der week-Unterlaufvertrag ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_datetime.TVF_TruncateDate('hour', '20260730')
       WHERE Value IS NULL AND IsValid = 0 AND ValidationCode = 11
   )
    THROW 52811, N'Der date-Datepart-Vertrag ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_datetime.TVF_TruncateDateTime2
            ('timezoneoffset', '2026-07-30T12:34:56')
       WHERE Value IS NULL AND IsValid = 0 AND ValidationCode = 10
   )
    THROW 52812, N'Der unbekannte Datepart-Vertrag ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_datetime.TVF_TruncateDateTime2(NULL, NULL)
       WHERE Value IS NULL AND IsValid IS NULL AND ValidationCode IS NULL
   )
    THROW 52813, N'NULL-Propagation ist falsch.', 1;

IF TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion')) >= 16
BEGIN
    DECLARE
          @Input datetime2(7) = '2026-07-30T12:34:56.1234567'
        , @Native datetime2(7)
        , @Portable datetime2(7);

    EXEC sys.sp_executesql
          N'SELECT @Result = DATETRUNC(quarter, @Value);'
        , N'@Value datetime2(7), @Result datetime2(7) OUTPUT'
        , @Value = @Input, @Result = @Native OUTPUT;

    SELECT @Portable = Value
    FROM toolbelt_datetime.TVF_TruncateDateTime2('quarter', @Input);

    IF @Native <> @Portable
        THROW 52814, N'Die native DATETRUNC-Parität ist falsch.', 1;
END;

PRINT N'Date/Time Truncation Contract-Prüfung: erfolgreich';
GO
