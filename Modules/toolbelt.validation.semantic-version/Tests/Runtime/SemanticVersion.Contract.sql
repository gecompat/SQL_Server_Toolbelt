SET NOCOUNT ON;

DECLARE @CompatibilityLevel int = TRY_CONVERT(int, N'$(CompatibilityLevel)');
IF @CompatibilityLevel NOT IN (150, 160, 170)
    THROW 52700, N'CompatibilityLevel muss 150, 160 oder 170 sein.', 1;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id = DB_ID())
      <> @CompatibilityLevel
    THROW 52701, N'Unerwarteter Compatibility Level.', 1;

IF OBJECT_ID(N'toolbelt_validation.TVF_ParseSemanticVersion', N'TF') IS NULL
 OR OBJECT_ID(N'toolbelt_validation.TVF_CompareSemanticVersion', N'IF') IS NULL
 OR OBJECT_ID(N'toolbelt_validation.TVF_SemanticVersionSortKey', N'IF') IS NULL
 OR OBJECT_ID(N'toolbelt_validation.SVF_CompareSemanticVersion', N'FN') IS NULL
 OR OBJECT_ID(N'toolbelt_validation.SVF_SemanticVersionSortKey', N'FN') IS NULL
    THROW 52702, N'Öffentliche SemVer-Funktionen fehlen.', 1;

-- Direkte Aggregation weist fehlende, zusätzliche und NULL-offene Ergebniszeilen ab.
IF EXISTS
(
    SELECT 1
    FROM
    (
        SELECT ResultCount = COUNT_BIG(*), MatchingCount = COUNT_BIG
        (
            CASE WHEN IsValid = 1 AND ValidationCode = 'VALID'
              AND Major = '1' AND Minor = '2' AND Patch = '3'
              AND PreRelease = 'alpha.1' AND BuildMetadata = 'build.7'
              AND CanonicalVersion = '1.2.3-alpha.1+build.7' THEN 1 END
        )
        FROM toolbelt_validation.TVF_ParseSemanticVersion
             ('1.2.3-alpha.1+build.7')
    ) AS observed
    WHERE ResultCount <> 1 OR MatchingCount <> 1
)
    THROW 52703, N'Der vollständige Parserfall ist falsch.', 1;

DECLARE @Invalid TABLE
(
      VersionValue varchar(8000) NULL
    , ExpectedCode varchar(32) NOT NULL
);
INSERT INTO @Invalid VALUES
 (NULL, 'NULL_INPUT'), ('', 'EMPTY_INPUT'), ('v1.2.3', 'CORE_FORMAT'),
 ('1.2', 'CORE_FORMAT'), ('01.2.3', 'CORE_LEADING_ZERO'),
 ('1.2.3-', 'EMPTY_PRERELEASE'), ('1.2.3+', 'EMPTY_BUILD'),
 ('1.2.3-alpha..1', 'PRERELEASE_FORMAT'),
 ('1.2.3-alpha.', 'PRERELEASE_FORMAT'),
 ('1.2.3-alpha.01', 'PRERELEASE_LEADING_ZERO'),
 ('1.2.3+build..1', 'BUILD_FORMAT'), ('1.2.3+build.', 'BUILD_FORMAT'),
 ('1.2.3 alpha', 'INVALID_CHARACTER');

IF EXISTS
(
    SELECT 1
    FROM @Invalid AS cases
    CROSS APPLY
    (
        SELECT ResultCount = COUNT_BIG(*), MatchingCount = COUNT_BIG(matched.IsMatch)
        FROM
        (
            SELECT IsMatch = CASE WHEN parsed.IsValid = 0
                     AND parsed.ValidationCode = cases.ExpectedCode
                     AND parsed.CanonicalVersion IS NULL THEN 1 END
            FROM toolbelt_validation.TVF_ParseSemanticVersion(cases.VersionValue) AS parsed
        ) AS matched
    ) AS observed
    WHERE observed.ResultCount <> 1 OR observed.MatchingCount <> 1
)
    THROW 52704, N'Ein ungültiger Parserfall weicht ab.', 1;

DECLARE @Precedence TABLE
(
      ExpectedOrdinal int NOT NULL PRIMARY KEY
    , VersionValue varchar(8000) NOT NULL
);
INSERT INTO @Precedence VALUES
 (1, '1.0.0-alpha'), (2, '1.0.0-alpha.1'),
 (3, '1.0.0-alpha.beta'), (4, '1.0.0-beta'),
 (5, '1.0.0-beta.2'), (6, '1.0.0-beta.11'),
 (7, '1.0.0-rc.1'), (8, '1.0.0');

-- Vorhandene positive SVF-Werte aufnehmen; NULL ist kein gültiges Vergleichsorakel.
DECLARE @PrecedenceComparisons TABLE
(
      ExpectedOrdinal int NOT NULL PRIMARY KEY
    , ComparisonResult smallint NULL
);
INSERT INTO @PrecedenceComparisons
SELECT current_version.ExpectedOrdinal,
       toolbelt_validation.SVF_CompareSemanticVersion
       (current_version.VersionValue, next_version.VersionValue)
FROM @Precedence AS current_version
JOIN @Precedence AS next_version
  ON next_version.ExpectedOrdinal = current_version.ExpectedOrdinal + 1;

DECLARE @PrecedenceKeys TABLE
(
      ExpectedOrdinal int NOT NULL PRIMARY KEY
    , SortKey varbinary(max) NULL
    , TvfResultCount bigint NULL
    , TvfMatchingCount bigint NULL
);
INSERT INTO @PrecedenceKeys (ExpectedOrdinal, SortKey)
SELECT ExpectedOrdinal, toolbelt_validation.SVF_SemanticVersionSortKey(VersionValue)
FROM @Precedence;

UPDATE captured
SET TvfResultCount = observed.ResultCount,
    TvfMatchingCount = observed.MatchingCount
FROM @PrecedenceKeys AS captured
JOIN @Precedence AS cases ON cases.ExpectedOrdinal = captured.ExpectedOrdinal
CROSS APPLY
(
    SELECT ResultCount = COUNT_BIG(*), MatchingCount = COUNT_BIG(matched.IsMatch)
    FROM
    (
        SELECT IsMatch = CASE WHEN sort_key.SortKey IS NOT NULL
                 AND sort_key.SortKey = captured.SortKey THEN 1 END
        FROM toolbelt_validation.TVF_SemanticVersionSortKey(cases.VersionValue) AS sort_key
    ) AS matched
) AS observed;

IF EXISTS
(
    SELECT 1
    FROM @PrecedenceComparisons
    WHERE ComparisonResult IS NULL OR ComparisonResult <> -1
)
    THROW 52705, N'Die offizielle SemVer-Präzedenzfolge ist falsch.', 1;

DECLARE @BuildComparison smallint = toolbelt_validation.SVF_CompareSemanticVersion
        ('1.0.0+build1', '1.0.0+build2'),
        @BuildKey1 varbinary(max) = toolbelt_validation.SVF_SemanticVersionSortKey('1.0.0+build1'),
        @BuildKey2 varbinary(max) = toolbelt_validation.SVF_SemanticVersionSortKey('1.0.0+build2');
IF @BuildComparison IS NULL OR @BuildComparison <> 0
 OR @BuildKey1 IS NULL OR @BuildKey2 IS NULL OR @BuildKey1 <> @BuildKey2
    THROW 52706, N'Build Metadata beeinflusst die Präzedenz.', 1;

DECLARE @Huge varchar(8000) = REPLICATE('9', 2000) + '.0.0';
DECLARE @HugeComparison smallint = toolbelt_validation.SVF_CompareSemanticVersion(@Huge, '2.0.0');
IF @HugeComparison IS NULL OR @HugeComparison <> 1
    THROW 52707, N'Beliebig lange numerische Komponenten werden falsch verglichen.', 1;

DECLARE @AsciiComparison smallint = toolbelt_validation.SVF_CompareSemanticVersion
        ('1.0.0-alpha', '1.0.0-Alpha');
IF @AsciiComparison IS NULL OR @AsciiComparison <> 1
    THROW 52708, N'Der ASCII-binäre Identifiervergleich ist falsch.', 1;

IF toolbelt_validation.SVF_CompareSemanticVersion('invalid', '1.0.0') IS NOT NULL
 OR toolbelt_validation.SVF_SemanticVersionSortKey('invalid') IS NOT NULL
    THROW 52709, N'Ungültige Eingaben müssen NULL liefern.', 1;

IF EXISTS
(
    SELECT 1
    FROM
    (
        SELECT ExpectedOrdinal, SortKey,
               PreviousKey = LAG(SortKey) OVER (ORDER BY ExpectedOrdinal)
        FROM @PrecedenceKeys
    ) AS ordered_versions
    WHERE SortKey IS NULL
       OR (ExpectedOrdinal > 1 AND (PreviousKey IS NULL OR SortKey <= PreviousKey))
)
    THROW 52710, N'Der binäre Sort Key folgt nicht dem Comparator.', 1;

IF EXISTS
(
    SELECT 1
    FROM @Precedence AS current_version
    JOIN @Precedence AS next_version
      ON next_version.ExpectedOrdinal = current_version.ExpectedOrdinal + 1
    JOIN @PrecedenceComparisons AS captured
      ON captured.ExpectedOrdinal = current_version.ExpectedOrdinal
    CROSS APPLY
    (
        SELECT ResultCount = COUNT_BIG(*), MatchingCount = COUNT_BIG(matched.IsMatch)
        FROM
        (
            SELECT IsMatch = CASE WHEN compared.ComparisonResult IS NOT NULL
                     AND compared.ComparisonResult = captured.ComparisonResult THEN 1 END
            FROM toolbelt_validation.TVF_CompareSemanticVersion
                 (current_version.VersionValue, next_version.VersionValue) AS compared
        ) AS matched
    ) AS observed
    WHERE observed.ResultCount <> 1 OR observed.MatchingCount <> 1
)
 OR EXISTS
(
    SELECT 1
    FROM @PrecedenceKeys
    WHERE TvfResultCount IS NULL OR TvfResultCount <> 1
       OR TvfMatchingCount IS NULL OR TvfMatchingCount <> 1
)
    THROW 52711, N'Die SVF-/inline-TVF-Parität ist fehlgeschlagen.', 1;

IF (SELECT COUNT(*)
    FROM toolbelt_validation.TVF_CompareSemanticVersion
         ('invalid', '1.0.0')) <> 1
 OR EXISTS
(
    SELECT 1
    FROM toolbelt_validation.TVF_CompareSemanticVersion
         ('invalid', '1.0.0')
    WHERE ComparisonResult IS NOT NULL
)
 OR (SELECT COUNT(*)
     FROM toolbelt_validation.TVF_SemanticVersionSortKey('invalid')) <> 1
 OR EXISTS
(
    SELECT 1
    FROM toolbelt_validation.TVF_SemanticVersionSortKey('invalid')
    WHERE SortKey IS NOT NULL
)
    THROW 52712, N'Der einzeilige NULL-Vertrag der inline TVFs ist fehlgeschlagen.', 1;

IF (SELECT COUNT(*)
    FROM @Precedence AS source
    OUTER APPLY toolbelt_validation.TVF_SemanticVersionSortKey
                (
                    source.VersionValue
                ) AS sort_key) <> (SELECT COUNT(*) FROM @Precedence)
    THROW 52713, N'OUTER APPLY erhält die äußeren Zeilen nicht vollständig.', 1;

PRINT N'Semantic-Version Contract-Tests für Compatibility Level '
    + CONVERT(nvarchar(3), @CompatibilityLevel) + N': erfolgreich';
GO
