-- ============================================================================
-- Contract-Tests für Base64/Base64URL
-- Daten: ausschließlich synthetisch
-- SQLCMD-Variable: CompatibilityLevel=150|160|170
-- ============================================================================

SET NOCOUNT ON;

DECLARE @CompatibilityLevel int =
    TRY_CONVERT(int, N'$(CompatibilityLevel)');

IF @CompatibilityLevel NOT IN (150, 160, 170)
BEGIN
    THROW 52300, N'CompatibilityLevel muss 150, 160 oder 170 sein.', 1;
END;

DECLARE @SetCompatibilitySql nvarchar(max) =
    N'ALTER DATABASE '
    + QUOTENAME(DB_NAME())
    + N' SET COMPATIBILITY_LEVEL = '
    + CONVERT(nvarchar(3), @CompatibilityLevel)
    + N';';
EXEC sys.sp_executesql @SetCompatibilitySql;

IF OBJECT_ID(N'toolbelt_conversion.SVF_Base64Encode', N'FN') IS NULL
   OR OBJECT_ID(N'toolbelt_conversion.SVF_Base64Decode', N'FN') IS NULL
BEGIN
    THROW 52301, N'Die öffentlichen Base64-Funktionen fehlen.', 1;
END;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.parameters
       WHERE object_id =
             OBJECT_ID(N'toolbelt_conversion.SVF_Base64Encode', N'FN')
         AND parameter_id = 0
         AND TYPE_NAME(user_type_id) = N'varchar'
         AND max_length = -1
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM sys.parameters
       WHERE object_id =
             OBJECT_ID(N'toolbelt_conversion.SVF_Base64Encode', N'FN')
         AND parameter_id = 1
         AND name = N'@Value'
         AND TYPE_NAME(user_type_id) = N'varbinary'
         AND max_length = -1
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM sys.parameters
       WHERE object_id =
             OBJECT_ID(N'toolbelt_conversion.SVF_Base64Decode', N'FN')
         AND parameter_id = 0
         AND TYPE_NAME(user_type_id) = N'varbinary'
         AND max_length = -1
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM sys.parameters
       WHERE object_id =
             OBJECT_ID(N'toolbelt_conversion.SVF_Base64Encode', N'FN')
         AND parameter_id = 2
         AND name = N'@UrlSafe'
         AND TYPE_NAME(user_type_id) = N'bit'
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM sys.parameters
       WHERE object_id =
             OBJECT_ID(N'toolbelt_conversion.SVF_Base64Decode', N'FN')
         AND parameter_id = 1
         AND name = N'@Value'
         AND TYPE_NAME(user_type_id) = N'varchar'
         AND max_length = -1
   )
   OR OBJECT_DEFINITION
      (
          OBJECT_ID(N'toolbelt_conversion.SVF_Base64Encode', N'FN')
      ) NOT LIKE N'%@UrlSafe bit = 0%'
BEGIN
    THROW 52302, N'Die öffentliche Parametersignatur weicht vom Vertrag ab.', 1;
END;

DECLARE @Vectors TABLE
(
      ItemOrdinal    int            NOT NULL PRIMARY KEY
    , BinaryValue    varbinary(max) NOT NULL
    , StandardBase64 varchar(max)   NOT NULL
);

INSERT INTO @Vectors (ItemOrdinal, BinaryValue, StandardBase64)
VALUES
      (1, 0x,             '')
    , (2, 0x66,           'Zg==')
    , (3, 0x666F,         'Zm8=')
    , (4, 0x666F6F,       'Zm9v')
    , (5, 0x666F6F62,     'Zm9vYg==')
    , (6, 0x666F6F6261,   'Zm9vYmE=')
    , (7, 0x666F6F626172, 'Zm9vYmFy');

IF EXISTS
   (
       SELECT 1
       FROM @Vectors AS vectors
       WHERE toolbelt_conversion.SVF_Base64Encode
             (
                 vectors.BinaryValue,
                 DEFAULT
             ) <> vectors.StandardBase64
          OR toolbelt_conversion.SVF_Base64Decode
             (
                 vectors.StandardBase64
             ) <> vectors.BinaryValue
   )
BEGIN
    THROW 52303, N'Ein RFC-4648-Standardvektor ist fehlgeschlagen.', 1;
END;

IF toolbelt_conversion.SVF_Base64Encode(NULL, 0) IS NOT NULL
   OR toolbelt_conversion.SVF_Base64Decode(NULL) IS NOT NULL
BEGIN
    THROW 52304, N'NULL wird nicht vertragsgemäß weitergegeben.', 1;
END;

IF toolbelt_conversion.SVF_Base64Encode(0xCAFECAFE, 0) <> 'yv7K/g=='
   OR toolbelt_conversion.SVF_Base64Encode(0xCAFECAFE, 1) <> 'yv7K_g'
   OR toolbelt_conversion.SVF_Base64Decode('yv7K/g==') <> 0xCAFECAFE
   OR toolbelt_conversion.SVF_Base64Decode('yv7K/g') <> 0xCAFECAFE
   OR toolbelt_conversion.SVF_Base64Decode('yv7K_g') <> 0xCAFECAFE
BEGIN
    THROW 52305, N'Alphabet- oder Paddingvertrag ist fehlgeschlagen.', 1;
END;

DECLARE @WhitespaceValue varchar(max) =
    CHAR(32) + 'yv' + CHAR(9) + '7K' + CHAR(13) + '/' + CHAR(10) + 'g==';

IF toolbelt_conversion.SVF_Base64Decode(@WhitespaceValue) <> 0xCAFECAFE
BEGIN
    THROW 52306, N'Der freigegebene Whitespace-Vertrag ist fehlgeschlagen.', 1;
END;

DECLARE @ExpectedErrorObserved bit;

SET @ExpectedErrorObserved = 0;
BEGIN TRY
    DECLARE @InvalidCharacter varbinary(max) =
        toolbelt_conversion.SVF_Base64Decode('qQ!!');
END TRY
BEGIN CATCH
    SET @ExpectedErrorObserved = 1;
END CATCH;
IF @ExpectedErrorObserved = 0
BEGIN
    THROW 52307, N'Ein ungültiges Zeichen wurde akzeptiert.', 1;
END;

SET @ExpectedErrorObserved = 0;
BEGIN TRY
    DECLARE @InvalidLength varbinary(max) =
        toolbelt_conversion.SVF_Base64Decode('A');
END TRY
BEGIN CATCH
    SET @ExpectedErrorObserved = 1;
END CATCH;
IF @ExpectedErrorObserved = 0
BEGIN
    THROW 52308, N'Eine ungültige Base64-Länge wurde akzeptiert.', 1;
END;

SET @ExpectedErrorObserved = 0;
BEGIN TRY
    DECLARE @InvalidPadding varbinary(max) =
        toolbelt_conversion.SVF_Base64Decode('qQ===A');
END TRY
BEGIN CATCH
    SET @ExpectedErrorObserved = 1;
END CATCH;
IF @ExpectedErrorObserved = 0
BEGIN
    THROW 52309, N'Ungültiges Padding wurde akzeptiert.', 1;
END;

SET @ExpectedErrorObserved = 0;
BEGIN TRY
    DECLARE @InvalidWhitespace varbinary(max) =
        toolbelt_conversion.SVF_Base64Decode('q' + CHAR(11) + 'Q==');
END TRY
BEGIN CATCH
    SET @ExpectedErrorObserved = 1;
END CATCH;
IF @ExpectedErrorObserved = 0
BEGIN
    THROW 52310, N'Nicht freigegebener Whitespace wurde akzeptiert.', 1;
END;

DECLARE @Sizes TABLE
(
    ByteCount int NOT NULL PRIMARY KEY
);

INSERT INTO @Sizes (ByteCount)
VALUES (6000), (6001), (65536), (1048576);

DECLARE
      @ByteCount    int
    , @Synthetic    varbinary(max)
    , @Encoded      varchar(max)
    , @Decoded      varbinary(max);

DECLARE SizeCursor CURSOR LOCAL FAST_FORWARD
FOR SELECT ByteCount FROM @Sizes ORDER BY ByteCount;

OPEN SizeCursor;
FETCH NEXT FROM SizeCursor INTO @ByteCount;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @Synthetic = CONVERT
    (
          varbinary(max)
        , REPLICATE(CONVERT(varchar(max), 'A'), @ByteCount)
    );
    SET @Encoded =
        toolbelt_conversion.SVF_Base64Encode(@Synthetic, 0);
    SET @Decoded =
        toolbelt_conversion.SVF_Base64Decode(@Encoded);

    IF DATALENGTH(@Synthetic) <> @ByteCount
       OR DATALENGTH(@Decoded) <> @ByteCount
       OR @Decoded <> @Synthetic
    BEGIN
        CLOSE SizeCursor;
        DEALLOCATE SizeCursor;
        THROW 52311, N'Ein synthetischer Größen-Roundtrip ist fehlgeschlagen.', 1;
    END;

    FETCH NEXT FROM SizeCursor INTO @ByteCount;
END;

CLOSE SizeCursor;
DEALLOCATE SizeCursor;

/*
 * Native SQL-Server-2025-Funktionen werden dynamisch kompiliert, damit der
 * portable Modulcode selbst keine Versionsabhängigkeit erhält.
 */
DECLARE
      @ReferenceValue varbinary(max) = 0xCAFECAFE
    , @NativeStandard varchar(max)
    , @NativeUrlSafe  varchar(max)
    , @NativeDecoded  varbinary(max);

EXEC sys.sp_executesql
      N'SELECT
              @Standard = BASE64_ENCODE(@Value, 0),
              @UrlSafe = BASE64_ENCODE(@Value, 1);'
    , N'@Value varbinary(max), @Standard varchar(max) OUTPUT, @UrlSafe varchar(max) OUTPUT'
    , @Value = @ReferenceValue
    , @Standard = @NativeStandard OUTPUT
    , @UrlSafe = @NativeUrlSafe OUTPUT;

EXEC sys.sp_executesql
      N'SELECT @Decoded = BASE64_DECODE(@Value);'
    , N'@Value varchar(max), @Decoded varbinary(max) OUTPUT'
    , @Value = @NativeUrlSafe
    , @Decoded = @NativeDecoded OUTPUT;

IF @NativeStandard <>
       toolbelt_conversion.SVF_Base64Encode(@ReferenceValue, 0)
   OR @NativeUrlSafe <>
       toolbelt_conversion.SVF_Base64Encode(@ReferenceValue, 1)
   OR @NativeDecoded <> @ReferenceValue
BEGIN
    THROW 52312, N'Die semantische Parität zum nativen SQL-Server-2025-Provider ist fehlgeschlagen.', 1;
END;

PRINT N'Base64 Contract-Tests für Compatibility Level '
    + CONVERT(nvarchar(3), @CompatibilityLevel)
    + N': erfolgreich';
GO
