SET NOCOUNT ON;

DECLARE @CompatibilityLevel int = TRY_CONVERT(int, N'$(CompatibilityLevel)');
IF @CompatibilityLevel NOT IN (150, 160, 170)
    THROW 52900, N'CompatibilityLevel muss 150, 160 oder 170 sein.', 1;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id = DB_ID())
       <> @CompatibilityLevel
    THROW 52901, N'Falscher Compatibility Level.', 1;

IF OBJECT_ID(N'toolbelt_json.TVF_JsonPathExists', N'TF') IS NULL
    THROW 52902, N'TVF_JsonPathExists fehlt oder besitzt den falschen Typ.', 1;

DECLARE @Document nvarchar(max) =
    N'{
        "info": {
            "addresses": [
                {"town":"Wien"},
                {"city":"Graz"},
                {"town":null}
            ],
            "Name": 1,
            "name": 2,
            "key.with.dot": {"first name":"Ada"},
            "quote\"key": true,
            "\u00dcber": 3
        }
    }';

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_json.TVF_JsonPathExists
            (@Document, N'$.info.addresses[0].town')
       WHERE PathExists = 1
   )
    THROW 52903, N'Der verschachtelte Property-/Index-Pfad ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_json.TVF_JsonPathExists
            (@Document, N'$.info.addresses[1].town')
       WHERE PathExists = 0
   )
    THROW 52904, N'Der Missing-Pfad ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_json.TVF_JsonPathExists
            (@Document, N'$.info.addresses[*].town')
       WHERE PathExists = 1
   )
    THROW 52905, N'Der Wildcard-Any-Match ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_json.TVF_JsonPathExists
            (@Document, N'$.info.addresses[*].postcode')
       WHERE PathExists = 0
   )
    THROW 52906, N'Der leere Wildcard-Match ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_json.TVF_JsonPathExists
            (@Document, N'$."info"."key.with.dot"."first name"')
       WHERE PathExists = 1
   )
    THROW 52907, N'Der quotierte Schlüsselpfad ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_json.TVF_JsonPathExists
            (@Document, N'$.info."quote\"key"')
       WHERE PathExists = 1
   )
    THROW 52908, N'Der escaped Schlüsselpfad ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_json.TVF_JsonPathExists
            (@Document, N'$.info."\u00dcber"')
       WHERE PathExists = 1
   )
    THROW 52909, N'Der Unicode-Schlüsselpfad ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_json.TVF_JsonPathExists(@Document, N'$.info.Name')
       WHERE PathExists = 1
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_json.TVF_JsonPathExists(@Document, N'$.info.NAME')
       WHERE PathExists = 0
   )
    THROW 52910, N'Der case-sensitive BIN2-Vertrag ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_json.TVF_JsonPathExists
            (@Document, N'strict $.info.addresses[2].town')
       WHERE PathExists = 1
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_json.TVF_JsonPathExists
            (@Document, N'lax $.info.addresses[9]')
       WHERE PathExists = 0
   )
    THROW 52911, N'Der lax-/strict-Vertrag ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_json.TVF_JsonPathExists(N'null', N'$')
       WHERE PathExists = 1
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_json.TVF_JsonPathExists(N'"text"', N'$')
       WHERE PathExists = 1
   )
    THROW 52912, N'Der skalare Root-Vertrag ist falsch.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_json.TVF_JsonPathExists(N'{"value":null}', N'$.value')
       WHERE PathExists = 1
   )
    THROW 52913, N'JSON null muss als vorhandener Wert gelten.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_json.TVF_JsonPathExists(N'{"broken":', N'$.broken')
       WHERE PathExists = 0
   )
    THROW 52914, N'Ungültiges JSON muss fehlerfrei 0 liefern.', 1;

DECLARE @InvalidPaths TABLE (PathValue nvarchar(max) NOT NULL);
INSERT @InvalidPaths (PathValue)
VALUES
      (N'')
    , (N'info.name')
    , (N'$.')
    , (N'$."open')
    , (N'$."\q"')
    , (N'$[01]')
    , (N'$[last]')
    , (N'$[0 to 2]')
    , (N'$[0,1]');

IF EXISTS
   (
       SELECT 1
       FROM @InvalidPaths AS invalid_path
       CROSS APPLY toolbelt_json.TVF_JsonPathExists
                   (@Document, invalid_path.PathValue) AS path_result
       WHERE path_result.PathExists <> 0
          OR path_result.PathExists IS NULL
   )
    THROW 52915, N'Ein ungültiger V1-Pfad wurde angenommen.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_json.TVF_JsonPathExists(NULL, N'$.value')
       WHERE PathExists IS NULL
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_json.TVF_JsonPathExists(@Document, NULL)
       WHERE PathExists IS NULL
   )
    THROW 52916, N'Die SQL-NULL-Propagation ist falsch.', 1;

DECLARE @LongPath nvarchar(max) = N'$.' + REPLICATE(N'a', 4000);
IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_json.TVF_JsonPathExists(@Document, @LongPath)
       WHERE PathExists = 0
   )
    THROW 52917, N'Die Pfadlängengrenze ist falsch.', 1;

IF TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion')) >= 16
BEGIN
    DECLARE
          @Native int
        , @Portable int
        , @NativePath nvarchar(max) = N'$.info.addresses[0].town';

    EXEC sys.sp_executesql
          N'SELECT @Result = JSON_PATH_EXISTS(@Json, @Path);'
        , N'@Json nvarchar(max), @Path nvarchar(max), @Result int OUTPUT'
        , @Json = @Document
        , @Path = @NativePath
        , @Result = @Native OUTPUT;

    SELECT @Portable = PathExists
    FROM toolbelt_json.TVF_JsonPathExists(@Document, @NativePath);

    IF @Native <> @Portable
        THROW 52918, N'Die native JSON_PATH_EXISTS-Parität ist falsch.', 1;
END;

PRINT N'JSON Path Exists Contract-Prüfung: erfolgreich';
GO
