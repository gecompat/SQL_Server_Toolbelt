-- ============================================================================
-- Contract-Tests für literal interpretierte einzelne Separatorzeichen
-- Daten: ausschließlich synthetisch
-- SQLCMD-Variable: CompatibilityLevel=150|160|170
-- ============================================================================

SET NOCOUNT ON;

DECLARE @CompatibilityLevel int =
    TRY_CONVERT(int, N'$(CompatibilityLevel)');

IF @CompatibilityLevel NOT IN (150, 160, 170)
BEGIN
    THROW 52600, N'CompatibilityLevel muss 150, 160 oder 170 sein.', 1;
END;

DECLARE @ActualCompatibilityLevel int =
(
    SELECT databases.compatibility_level
    FROM sys.databases AS databases
    WHERE databases.database_id = DB_ID()
);

IF @ActualCompatibilityLevel <> @CompatibilityLevel
BEGIN
    THROW 52601, N'Der Test muss in einer neuen Session mit dem erwarteten Compatibility Level gestartet werden.', 1;
END;

IF OBJECT_ID(N'toolbelt_core.TVF_GenerateSeriesBigInt', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_string.TVF_SplitByCharacters', N'IF') IS NULL
BEGIN
    THROW 52602, N'Die Dependency oder die öffentliche Split-Funktion fehlt.', 1;
END;

DECLARE @FunctionId int =
    OBJECT_ID(N'toolbelt_string.TVF_SplitByCharacters', N'IF');

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.parameters AS parameters
       WHERE parameters.object_id = @FunctionId
         AND parameters.parameter_id = 1
         AND parameters.name = N'@Input'
         AND TYPE_NAME(parameters.user_type_id) = N'nvarchar'
         AND parameters.max_length = -1
   )
   OR NOT EXISTS
      (
          SELECT 1
          FROM sys.parameters AS parameters
          WHERE parameters.object_id = @FunctionId
            AND parameters.parameter_id = 2
            AND parameters.name = N'@Separators'
            AND TYPE_NAME(parameters.user_type_id) = N'nvarchar'
            AND parameters.max_length = 8000
      )
   OR NOT EXISTS
      (
          SELECT 1
          FROM sys.parameters AS parameters
          WHERE parameters.object_id = @FunctionId
            AND parameters.parameter_id = 3
            AND parameters.name = N'@KeepEmpty'
            AND TYPE_NAME(parameters.user_type_id) = N'bit'
      )
   OR NOT EXISTS
      (
          SELECT 1
          FROM sys.columns AS columns
          WHERE columns.object_id = @FunctionId
            AND columns.column_id = 1
            AND columns.name = N'Value'
            AND TYPE_NAME(columns.user_type_id) = N'nvarchar'
            AND columns.max_length = -1
      )
   OR NOT EXISTS
      (
          SELECT 1
          FROM sys.columns AS columns
          WHERE columns.object_id = @FunctionId
            AND columns.column_id = 2
            AND columns.name = N'Ordinal'
            AND TYPE_NAME(columns.user_type_id) = N'bigint'
      )
   OR OBJECT_DEFINITION(@FunctionId) NOT LIKE N'%@KeepEmpty%=%1%'
BEGIN
    THROW 52603, N'Die öffentliche Signatur oder das Resultset weicht vom Vertrag ab.', 1;
END;

DECLARE @ExpectedBasic TABLE
(
      Value   nvarchar(max) NOT NULL
    , Ordinal bigint        NOT NULL PRIMARY KEY
);

INSERT INTO @ExpectedBasic (Value, Ordinal)
VALUES
      (N'A', 1)
    , (N'B', 2)
    , (N'C', 3)
    , (N'D', 4);

IF EXISTS
   (
       SELECT Value, Ordinal FROM @ExpectedBasic
       EXCEPT
       SELECT Value, Ordinal
       FROM toolbelt_string.TVF_SplitByCharacters
            (N'A,B;C|D', N',;|', DEFAULT)
   )
   OR EXISTS
      (
          SELECT Value, Ordinal
          FROM toolbelt_string.TVF_SplitByCharacters
               (N'A,B;C|D', N',;|', DEFAULT)
          EXCEPT
          SELECT Value, Ordinal FROM @ExpectedBasic
      )
BEGIN
    THROW 52604, N'Der grundlegende Multi-Separator-Vertrag ist fehlgeschlagen.', 1;
END;

DECLARE @ExpectedEmpty TABLE
(
      Value   nvarchar(max) NOT NULL
    , Ordinal bigint        NOT NULL PRIMARY KEY
);

INSERT INTO @ExpectedEmpty (Value, Ordinal)
VALUES
      (N'', 1)
    , (N'A', 2)
    , (N'', 3)
    , (N'', 4);

IF EXISTS
   (
       SELECT Value, Ordinal FROM @ExpectedEmpty
       EXCEPT
       SELECT Value, Ordinal
       FROM toolbelt_string.TVF_SplitByCharacters(N',A;;', N',;', 1)
   )
   OR EXISTS
      (
          SELECT Value, Ordinal
          FROM toolbelt_string.TVF_SplitByCharacters(N',A;;', N',;', 1)
          EXCEPT
          SELECT Value, Ordinal FROM @ExpectedEmpty
      )
BEGIN
    THROW 52605, N'Führende, aufeinanderfolgende oder nachfolgende leere Tokens sind falsch.', 1;
END;

IF (SELECT COUNT_BIG(*)
    FROM toolbelt_string.TVF_SplitByCharacters(N',A;;', N',;', 0)) <> 1
   OR (SELECT MAX(Value)
       FROM toolbelt_string.TVF_SplitByCharacters(N',A;;', N',;', 0))
          COLLATE Latin1_General_100_BIN2 <> N'A'
   OR (SELECT MAX(Ordinal)
       FROM toolbelt_string.TVF_SplitByCharacters(N',A;;', N',;', 0)) <> 1
BEGIN
    THROW 52606, N'KeepEmpty=0 entfernt oder nummeriert Tokens falsch.', 1;
END;

IF (SELECT COUNT_BIG(*)
    FROM toolbelt_string.TVF_SplitByCharacters(N'', N',', 1)) <> 1
   OR (SELECT COUNT_BIG(*)
       FROM toolbelt_string.TVF_SplitByCharacters(N'', N',', 0)) <> 0
   OR (SELECT COUNT_BIG(*)
       FROM toolbelt_string.TVF_SplitByCharacters(N'abc', N'', 1)) <> 1
   OR (SELECT MAX(Value)
       FROM toolbelt_string.TVF_SplitByCharacters(N'abc', N'', 1))
          COLLATE Latin1_General_100_BIN2 <> N'abc'
BEGIN
    THROW 52607, N'Leere Eingabe oder leere Separatorliste wird falsch behandelt.', 1;
END;

IF EXISTS
   (
       SELECT 1
       FROM toolbelt_string.TVF_SplitByCharacters(NULL, N',', 1)
   )
   OR EXISTS
      (
          SELECT 1
          FROM toolbelt_string.TVF_SplitByCharacters(N'abc', NULL, 1)
      )
BEGIN
    THROW 52608, N'NULL-Eingaben müssen eine leere Ergebnismenge liefern.', 1;
END;

DECLARE @NullSeparator nvarchar(2) = N',' + NCHAR(0);

IF EXISTS
   (
       SELECT 1
       FROM toolbelt_string.TVF_SplitByCharacters
            (N'A,B', @NullSeparator, 1)
   )
BEGIN
    THROW 52609, N'NUL in der Separatorliste muss eine leere Ergebnismenge liefern.', 1;
END;

DECLARE @ActualSingleSeparator TABLE
(
      Value   nvarchar(max) NOT NULL
    , Ordinal bigint        NOT NULL PRIMARY KEY
);
DECLARE @ActualDuplicateSeparators TABLE
(
      Value   nvarchar(max) NOT NULL
    , Ordinal bigint        NOT NULL PRIMARY KEY
);

INSERT INTO @ActualSingleSeparator (Value, Ordinal)
SELECT Value, Ordinal
FROM toolbelt_string.TVF_SplitByCharacters(N'A,B', N',', 1);

INSERT INTO @ActualDuplicateSeparators (Value, Ordinal)
SELECT Value, Ordinal
FROM toolbelt_string.TVF_SplitByCharacters(N'A,B', N',,,', 1);

IF EXISTS
   (
       SELECT Value, Ordinal FROM @ActualDuplicateSeparators
       EXCEPT
       SELECT Value, Ordinal FROM @ActualSingleSeparator
   )
   OR EXISTS
      (
          SELECT Value, Ordinal FROM @ActualSingleSeparator
          EXCEPT
          SELECT Value, Ordinal FROM @ActualDuplicateSeparators
      )
BEGIN
    THROW 52610, N'Doppelte Separatorzeichen dürfen das Ergebnis nicht ändern.', 1;
END;

DECLARE @ExpectedBinary TABLE
(
      Value   nvarchar(max) NOT NULL
    , Ordinal bigint        NOT NULL PRIMARY KEY
);

INSERT INTO @ExpectedBinary (Value, Ordinal)
VALUES (N'A', 1), (N'Á', 2), (N'', 3);

IF EXISTS
   (
       SELECT Value, Ordinal FROM @ExpectedBinary
       EXCEPT
       SELECT Value, Ordinal
       FROM toolbelt_string.TVF_SplitByCharacters(N'AaÁá', N'aá', 1)
   )
   OR EXISTS
      (
          SELECT Value, Ordinal
          FROM toolbelt_string.TVF_SplitByCharacters(N'AaÁá', N'aá', 1)
          EXCEPT
          SELECT Value, Ordinal FROM @ExpectedBinary
      )
BEGIN
    THROW 52611, N'Der binäre Separatorvergleich ist nicht stabil.', 1;
END;

IF (SELECT MAX(Value)
    FROM toolbelt_string.TVF_SplitByCharacters(N' A , B  ', N',', 1)
    WHERE Ordinal = 1) COLLATE Latin1_General_100_BIN2 <> N' A '
   OR (SELECT MAX(Value)
       FROM toolbelt_string.TVF_SplitByCharacters(N' A , B  ', N',', 1)
       WHERE Ordinal = 2) COLLATE Latin1_General_100_BIN2 <> N' B  '
BEGIN
    THROW 52612, N'Whitespace einschließlich nachfolgender Leerzeichen wurde verändert.', 1;
END;

IF (SELECT COUNT_BIG(*)
    FROM toolbelt_string.TVF_SplitByCharacters(N'A,B', N',', NULL)) <> 2
BEGIN
    THROW 52613, N'Explizites KeepEmpty=NULL muss dem Default 1 entsprechen.', 1;
END;

DECLARE @LargeInput nvarchar(max) =
    REPLICATE(CONVERT(nvarchar(max), N'x,'), 10000) + N'z';

IF (SELECT COUNT_BIG(*)
    FROM toolbelt_string.TVF_SplitByCharacters(@LargeInput, N',', 1)) <> 10001
   OR (SELECT MAX(Ordinal)
       FROM toolbelt_string.TVF_SplitByCharacters(@LargeInput, N',', 1)) <> 10001
BEGIN
    THROW 52614, N'Die LOB- oder Ordinalverarbeitung ist fehlgeschlagen.', 1;
END;

DECLARE @ApplyInput TABLE
(
      RowId int           NOT NULL PRIMARY KEY
    , Value nvarchar(100) NOT NULL
);

INSERT INTO @ApplyInput (RowId, Value)
VALUES (1, N'A,B'), (2, N'C;D');

IF (SELECT COUNT_BIG(*)
    FROM @ApplyInput AS inputs
    CROSS APPLY toolbelt_string.TVF_SplitByCharacters
    (
        inputs.Value,
        N',;',
        DEFAULT
    ) AS tokens) <> 4
BEGIN
    THROW 52615, N'Der CROSS-APPLY-Vertrag ist fehlgeschlagen.', 1;
END;

/*
 * Der native Regex-Operator wird nur unter Compatibility Level 170 dynamisch
 * kompiliert. Er dient ausschließlich als enges Oracle für einen einfachen
 * nicht überlappenden Fall und ist kein Runtime-Provider dieses Moduls.
 */
IF @CompatibilityLevel = 170
BEGIN
    CREATE TABLE #tbx_NativeSplit
    (
          Value   nvarchar(max) COLLATE DATABASE_DEFAULT NOT NULL
        , Ordinal bigint        NOT NULL
    );

    EXEC sys.sp_executesql
        N'INSERT INTO #tbx_NativeSplit (Value, Ordinal)
          SELECT value, ordinal
          FROM REGEXP_SPLIT_TO_TABLE(N''A,B;C'', N''[,;]'');';

    IF EXISTS
       (
           SELECT Value, Ordinal FROM #tbx_NativeSplit
           EXCEPT
           SELECT Value, Ordinal
           FROM toolbelt_string.TVF_SplitByCharacters
                (N'A,B;C', N',;', 1)
       )
       OR EXISTS
          (
              SELECT Value, Ordinal
              FROM toolbelt_string.TVF_SplitByCharacters
                   (N'A,B;C', N',;', 1)
              EXCEPT
              SELECT Value, Ordinal FROM #tbx_NativeSplit
          )
    BEGIN
        THROW 52616, N'Die enge Parität zum nativen Regex-Split ist fehlgeschlagen.', 1;
    END;
END;

PRINT N'Split-Characters Contract-Tests für Compatibility Level '
    + CONVERT(nvarchar(3), @CompatibilityLevel)
    + N': erfolgreich';
GO
