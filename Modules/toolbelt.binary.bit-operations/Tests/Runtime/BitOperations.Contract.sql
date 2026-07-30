SET NOCOUNT ON;

DECLARE @CompatibilityLevel int = TRY_CONVERT(int, N'$(CompatibilityLevel)');
IF @CompatibilityLevel NOT IN (150, 160, 170)
    THROW 52860, N'CompatibilityLevel muss 150, 160 oder 170 sein.', 1;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id = DB_ID())
       <> @CompatibilityLevel
    THROW 52861, N'Falscher Compatibility Level.', 1;

IF OBJECT_ID(N'toolbelt_binary.TVF_LeftShiftBigInt', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_binary.TVF_RightShiftBigInt', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_binary.TVF_BitCountBigInt', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_binary.TVF_GetBitBigInt', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_binary.TVF_SetBitBigInt', N'IF') IS NULL
    THROW 52862, N'Die Bit-Operationen fehlen.', 1;

IF (SELECT Value FROM toolbelt_binary.TVF_LeftShiftBigInt(12345, 5)) <> 395040
    THROW 52863, N'Left Shift ist falsch.', 1;
IF (SELECT Value FROM toolbelt_binary.TVF_LeftShiftBigInt(8, -2)) <> 2
    THROW 52864, N'Negativer Left Shift ist falsch.', 1;
IF (SELECT Value FROM toolbelt_binary.TVF_RightShiftBigInt(-1, 1))
       <> CONVERT(bigint, 9223372036854775807)
    THROW 52865, N'Logischer Right Shift ist falsch.', 1;
IF (SELECT Value FROM toolbelt_binary.TVF_RightShiftBigInt(3, -2)) <> 12
    THROW 52866, N'Negativer Right Shift ist falsch.', 1;
IF (SELECT Value FROM toolbelt_binary.TVF_LeftShiftBigInt(-1, 64)) <> 0
   OR (SELECT Value FROM toolbelt_binary.TVF_RightShiftBigInt(-1, 64)) <> 0
    THROW 52867, N'Der Shift-Grenzvertrag ist falsch.', 1;

IF (SELECT Value FROM toolbelt_binary.TVF_BitCountBigInt(-1)) <> 64
   OR
   (
       SELECT Value
       FROM toolbelt_binary.TVF_BitCountBigInt
            (CONVERT(bigint, -9223372036854775808))
   ) <> 1
    THROW 52868, N'BIT_COUNT ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1 FROM toolbelt_binary.TVF_GetBitBigInt(4, 2)
       WHERE Value = 1 AND IsValid = 1 AND ValidationCode = 0
   )
    THROW 52869, N'GET_BIT ist falsch.', 1;
IF NOT EXISTS
   (
       SELECT 1 FROM toolbelt_binary.TVF_GetBitBigInt(-1, 63)
       WHERE Value = 1 AND IsValid = 1
   )
    THROW 52870, N'GET_BIT am Vorzeichenbit ist falsch.', 1;
IF NOT EXISTS
   (
       SELECT 1 FROM toolbelt_binary.TVF_GetBitBigInt(0, 64)
       WHERE Value IS NULL AND IsValid = 0 AND ValidationCode = 10
   )
    THROW 52871, N'Der GET_BIT-Offsetvertrag ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1 FROM toolbelt_binary.TVF_SetBitBigInt(0, 63, 1)
       WHERE Value = CONVERT(bigint, -9223372036854775808)
         AND IsValid = 1 AND ValidationCode = 0
   )
    THROW 52872, N'SET_BIT am Vorzeichenbit ist falsch.', 1;
IF NOT EXISTS
   (
       SELECT 1 FROM toolbelt_binary.TVF_SetBitBigInt(-1, 0, 0)
       WHERE Value = -2 AND IsValid = 1
   )
    THROW 52873, N'SET_BIT zum Löschen ist falsch.', 1;
IF NOT EXISTS
   (
       SELECT 1 FROM toolbelt_binary.TVF_SetBitBigInt(0, 1, 2)
       WHERE Value IS NULL AND IsValid = 0 AND ValidationCode = 11
   )
    THROW 52874, N'Der SET_BIT-Bitwertvertrag ist falsch.', 1;

IF EXISTS
   (
       SELECT 1 FROM toolbelt_binary.TVF_LeftShiftBigInt(NULL, NULL)
       WHERE Value IS NOT NULL
   )
    THROW 52875, N'NULL-Propagation ist falsch.', 1;

IF TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion')) >= 16
BEGIN
    DECLARE @Native bigint, @Portable bigint;
    EXEC sys.sp_executesql
          N'SELECT @Result = LEFT_SHIFT(CONVERT(bigint, -123456789), 9);'
        , N'@Result bigint OUTPUT'
        , @Result = @Native OUTPUT;
    SELECT @Portable = Value
    FROM toolbelt_binary.TVF_LeftShiftBigInt(-123456789, 9);
    IF @Native <> @Portable
        THROW 52878, N'Die native LEFT_SHIFT-Parität ist falsch.', 1;

    EXEC sys.sp_executesql
          N'SELECT @Result = RIGHT_SHIFT(CONVERT(bigint, -1), 7);'
        , N'@Result bigint OUTPUT'
        , @Result = @Native OUTPUT;
    SELECT @Portable = Value
    FROM toolbelt_binary.TVF_RightShiftBigInt(-1, 7);
    IF @Native <> @Portable
        THROW 52876, N'Die native Shift-Parität ist falsch.', 1;

    EXEC sys.sp_executesql
          N'SELECT @Result = BIT_COUNT(CONVERT(bigint, -123456789));'
        , N'@Result bigint OUTPUT'
        , @Result = @Native OUTPUT;
    SELECT @Portable = Value
    FROM toolbelt_binary.TVF_BitCountBigInt(-123456789);
    IF @Native <> @Portable
        THROW 52877, N'Die native BIT_COUNT-Parität ist falsch.', 1;

    DECLARE @NativeBit int, @PortableBit bit;
    EXEC sys.sp_executesql
          N'SELECT @Result = GET_BIT(CONVERT(bigint, -123456789), 37);'
        , N'@Result int OUTPUT'
        , @Result = @NativeBit OUTPUT;
    SELECT @PortableBit = Value
    FROM toolbelt_binary.TVF_GetBitBigInt(-123456789, 37);
    IF @NativeBit <> @PortableBit
        THROW 52879, N'Die native GET_BIT-Parität ist falsch.', 1;

    EXEC sys.sp_executesql
          N'SELECT @Result = SET_BIT(CONVERT(bigint, -123456789), 37, 1);'
        , N'@Result bigint OUTPUT'
        , @Result = @Native OUTPUT;
    SELECT @Portable = Value
    FROM toolbelt_binary.TVF_SetBitBigInt(-123456789, 37, 1);
    IF @Native <> @Portable
        THROW 52883, N'Die native SET_BIT-Parität ist falsch.', 1;
END;

PRINT N'Bigint Bit Operations Contract-Prüfung: erfolgreich';
GO
