SET NOCOUNT ON;

DECLARE @CompatibilityLevel int = TRY_CONVERT(int, N'$(CompatibilityLevel)');
IF @CompatibilityLevel NOT IN (150, 160, 170)
    THROW 52700, N'CompatibilityLevel muss 150, 160 oder 170 sein.', 1;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id = DB_ID())
      <> @CompatibilityLevel
    THROW 52701, N'Unerwarteter Compatibility Level.', 1;

IF OBJECT_ID(N'toolbelt_validation.TVF_ParseSemanticVersion', N'TF') IS NULL
 OR OBJECT_ID(N'toolbelt_validation.SVF_CompareSemanticVersion', N'FN') IS NULL
 OR OBJECT_ID(N'toolbelt_validation.SVF_SemanticVersionSortKey', N'FN') IS NULL
    THROW 52702, N'Öffentliche SemVer-Funktionen fehlen.', 1;

IF NOT EXISTS
(
    SELECT 1
    FROM toolbelt_validation.TVF_ParseSemanticVersion
         ('1.2.3-alpha.1+build.7')
    WHERE IsValid = 1 AND ValidationCode = 'VALID'
      AND Major = '1' AND Minor = '2' AND Patch = '3'
      AND PreRelease = 'alpha.1' AND BuildMetadata = 'build.7'
      AND CanonicalVersion = '1.2.3-alpha.1+build.7'
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
    CROSS APPLY toolbelt_validation.TVF_ParseSemanticVersion(cases.VersionValue) AS parsed
    WHERE parsed.IsValid <> 0
       OR parsed.ValidationCode <> cases.ExpectedCode
       OR parsed.CanonicalVersion IS NOT NULL
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

IF EXISTS
(
    SELECT 1
    FROM @Precedence AS current_version
    JOIN @Precedence AS next_version
      ON next_version.ExpectedOrdinal = current_version.ExpectedOrdinal + 1
    WHERE toolbelt_validation.SVF_CompareSemanticVersion
          (current_version.VersionValue, next_version.VersionValue) <> -1
)
    THROW 52705, N'Die offizielle SemVer-Präzedenzfolge ist falsch.', 1;

IF toolbelt_validation.SVF_CompareSemanticVersion
   ('1.0.0+build1', '1.0.0+build2') <> 0
 OR toolbelt_validation.SVF_SemanticVersionSortKey('1.0.0+build1')
       <> toolbelt_validation.SVF_SemanticVersionSortKey('1.0.0+build2')
    THROW 52706, N'Build Metadata beeinflusst die Präzedenz.', 1;

DECLARE @Huge varchar(8000) = REPLICATE('9', 2000) + '.0.0';
IF toolbelt_validation.SVF_CompareSemanticVersion(@Huge, '2.0.0') <> 1
    THROW 52707, N'Beliebig lange numerische Komponenten werden falsch verglichen.', 1;

IF toolbelt_validation.SVF_CompareSemanticVersion
   ('1.0.0-alpha', '1.0.0-Alpha') <> 1
    THROW 52708, N'Der ASCII-binäre Identifiervergleich ist falsch.', 1;

IF toolbelt_validation.SVF_CompareSemanticVersion('invalid', '1.0.0') IS NOT NULL
 OR toolbelt_validation.SVF_SemanticVersionSortKey('invalid') IS NOT NULL
    THROW 52709, N'Ungültige Eingaben müssen NULL liefern.', 1;

IF EXISTS
(
    SELECT 1
    FROM
    (
        SELECT
              ExpectedOrdinal
            , SortKey =
                  toolbelt_validation.SVF_SemanticVersionSortKey(VersionValue)
            , PreviousKey = LAG
              (
                  toolbelt_validation.SVF_SemanticVersionSortKey(VersionValue)
              ) OVER (ORDER BY ExpectedOrdinal)
        FROM @Precedence
    ) AS ordered_versions
    WHERE PreviousKey IS NOT NULL AND SortKey <= PreviousKey
)
    THROW 52710, N'Der binäre Sort Key folgt nicht dem Comparator.', 1;

PRINT N'Semantic-Version Contract-Tests für Compatibility Level '
    + CONVERT(nvarchar(3), @CompatibilityLevel) + N': erfolgreich';
GO
