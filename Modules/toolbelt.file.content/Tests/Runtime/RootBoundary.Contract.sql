-- Kleine native Root-Grenzmatrix; aus Tests/Runtime mit SQLCMD ausführen.
-- Kein Hilfsobjekt wird deployed. Die echte Allowlist wird exklusiv innerhalb
-- einer eigenen Transaktion isoliert und ihre Zeilen auch bei Fehler rollbackt.
-- Providerfehler sind Testfehler: nur die exakte fachliche Abweisung zählt.
SET NOCOUNT ON;

IF @@TRANCOUNT <> 0
    THROW 52937, N'Root-Grenztests benötigen eine Session ohne offene Transaktion.', 1;

DECLARE @BoundaryCases TABLE
(
      CaseId int NOT NULL PRIMARY KEY
    , CaseName nvarchar(128) NOT NULL
    , RootPath nvarchar(4000) NOT NULL
    , IsActive bit NOT NULL
    , Candidate nvarchar(4000) NULL
    , Expected bit NOT NULL
);
-- UTF-16-Paar aus festen Bytes: unabhängig von Quellencoding und DB-SC-Modus.
DECLARE @BoundarySupplement nvarchar(2) = CONVERT(nvarchar(2), 0x3DD800DE);
INSERT INTO @BoundaryCases VALUES
  (1, N'Linux ohne Root-Slash', N'/Contoso/root', 1, N'/Contoso/root/file.bin', 1)
, (2, N'Linux mit Root-Slash', N'/Contoso/root/', 1, N'/Contoso/root/file.bin', 1)
, (3, N'Exakter Root ohne Slash', N'/Contoso/root', 1, N'/Contoso/root', 1)
, (4, N'Exakter Root mit Slash', N'/Contoso/root/', 1, N'/Contoso/root/', 1)
, (5, N'Slash-Root ist nicht Parent', N'/Contoso/root/', 1, N'/Contoso/root', 0)
, (6, N'Sibling mit Bindestrich', N'/Contoso/root', 1, N'/Contoso/root-old/file.bin', 0)
, (7, N'Sibling mit weiterem Zeichen', N'/Contoso/root', 1, N'/Contoso/roots/file.bin', 0)
, (8, N'Sibling bei Slash-Root', N'/Contoso/root/', 1, N'/Contoso/root-old/file.bin', 0)
, (9, N'BIN2 Groß-/Kleinschreibung', N'/Contoso/root', 1, N'/Contoso/ROOT/file.bin', 0)
, (10, N'Mehrere Unterverzeichnisse', N'/Contoso/root', 1, N'/Contoso/root/a/b/file.bin', 1)
, (11, N'Prozent ist literal', N'/Contoso/r%ot', 1, N'/Contoso/r%ot/file.bin', 1)
, (12, N'Prozent ist keine Wildcard', N'/Contoso/r%ot', 1, N'/Contoso/remote/file.bin', 0)
, (13, N'Unterstrich ist literal', N'/Contoso/r_ot', 1, N'/Contoso/r_ot/file.bin', 1)
, (14, N'Unterstrich ist keine Wildcard', N'/Contoso/r_ot', 1, N'/Contoso/root/file.bin', 0)
, (15, N'Klammern sind literal', N'/Contoso/r[ab]ot', 1, N'/Contoso/r[ab]ot/file.bin', 1)
, (16, N'Klammern sind keine Zeichenklasse', N'/Contoso/r[ab]ot', 1, N'/Contoso/raot/file.bin', 0)
, (17, N'Offene Klammer ist literal', N'/Contoso/r[ot', 1, N'/Contoso/r[ot/file.bin', 1)
, (18, N'Exakter Prozent-Root', N'/Contoso/%', 1, N'/Contoso/%', 1)
, (19, N'Root-Endspace fehlt im Candidate', N'/Contoso/root ', 1, N'/Contoso/root', 0)
, (20, N'Exakter Root-Endspace', N'/Contoso/root ', 1, N'/Contoso/root ', 1)
, (21, N'Unter Root mit Endspace', N'/Contoso/root ', 1, N'/Contoso/root /file.bin', 1)
, (22, N'Candidate-Endspace ist nicht exakter Root', N'/Contoso/root', 1, N'/Contoso/root ', 0)
, (23, N'Windows-Root normalisiert', N'C:\Contoso\root', 1, N'C:/Contoso/root/file.bin', 1)
, (24, N'Windows-Candidate normalisiert', N'C:\Contoso\root', 1, N'C:\Contoso\root\file.bin', 1)
, (25, N'Windows mit abschließendem Backslash', N'C:\Contoso\root\', 1, N'C:\Contoso\root\file.bin', 1)
, (26, N'Windows-Sibling abgewiesen', N'C:\Contoso\root', 1, N'C:\Contoso\root-old\file.bin', 0)
, (27, N'Drive-BIN2 unverändert', N'C:\Contoso\root', 1, N'c:\Contoso\root\file.bin', 0)
, (28, N'UNC beidseitig normalisiert', N'\\Contoso\share', 1, N'\\Contoso\share\file.bin', 1)
, (29, N'UNC mit Slash', N'//Contoso/share/', 1, N'//Contoso/share/file.bin', 1)
, (30, N'UNC-Sibling abgewiesen', N'\\Contoso\share', 1, N'\\Contoso\share-old\file.bin', 0)
, (31, N'Unicode-BMP literal', N'/Contoso/' + NCHAR(28450), 1, N'/Contoso/' + NCHAR(28450) + N'/file.bin', 1)
, (32, N'Unicode-BMP verschieden', N'/Contoso/' + NCHAR(28450), 1, N'/Contoso/' + NCHAR(23383) + N'/file.bin', 0)
, (33, N'Supplementary-Paar unter Root', N'/Contoso/' + @BoundarySupplement, 1, N'/Contoso/' + @BoundarySupplement + N'/file.bin', 1)
, (34, N'Supplementary-Paar vor Sibling', N'/Contoso/' + @BoundarySupplement, 1, N'/Contoso/' + @BoundarySupplement + N'x/file.bin', 0)
, (35, N'Supplementary-Paar exakter Root', N'/Contoso/' + @BoundarySupplement, 1, N'/Contoso/' + @BoundarySupplement, 1)
, (36, N'Keine Unicode-Normalisierung', N'/Contoso/' + NCHAR(233), 1, N'/Contoso/e' + NCHAR(769) + N'/file.bin', 0)
, (37, N'Leerer Root erlaubt nichts', N'', 1, N'/Contoso/file.bin', 0)
, (38, N'Inaktiver Root erlaubt nichts', N'/Contoso/root', 0, N'/Contoso/root/file.bin', 0)
, (39, N'NULL-Candidate', N'/Contoso/root', 1, NULL, 0)
, (40, N'Filesystem-Root Slash', N'/', 1, N'/Contoso/file.bin', 1)
, (41, N'Exakter Filesystem-Root', N'/', 1, N'/', 1)
, (42, N'Leerer Candidate', N'/Contoso/root', 1, N'', 0)
, (43, N'4000-Unit-Candidate unter kurzem Root', N'/Contoso/root', 1, N'/Contoso/root/' + REPLICATE(N'x', 3986), 1)
, (44, N'4000-Unit-Sibling', N'/Contoso/root', 1, N'/Contoso/root-old/' + REPLICATE(N'x', 3982), 0)
, (45, N'Mehrfach-Slash bleibt literal', N'/Contoso/root//', 1, N'/Contoso/root/file.bin', 0)
, (46, N'Space-Root erlaubt Absolutpfad nicht', N' ', 1, N'/Contoso/file.bin', 0)
, (47, N'Windows exakter normalisierter Root', N'C:\Contoso\root', 1, N'C:/Contoso/root', 1);

IF (SELECT COUNT(*) FROM @BoundaryCases) <> 47
   OR EXISTS (SELECT 1 FROM @BoundaryCases WHERE CaseId IN (43, 44) AND DATALENGTH(Candidate) <> 8000)
    THROW 52937, N'Root-Grenzmatrix ist unvollständig oder nicht exakt 4000 UTF-16-Units lang.', 1;

-- Separate Ausdrucksassertion, kein kopiertes Prädikat: 4000-Unit-Roots passen
-- wegen des bestehenden UNIQUE-Index-Keylimits nicht in die echte Allowlist.
DECLARE @BoundaryLongRoot nvarchar(4000) = N'/' + REPLICATE(N'x', 3999);
DECLARE @BoundaryLongPrefix nvarchar(max) = CAST(@BoundaryLongRoot AS nvarchar(max)) + N'/';
IF DATALENGTH(@BoundaryLongPrefix) <> 8002 OR RIGHT(@BoundaryLongPrefix, 1) <> N'/'
    THROW 52937, N'Root-Prefix-Konkatenation wurde bei 4000 UTF-16-Units abgeschnitten.', 1;

DECLARE @BoundaryOriginal TABLE
(
      RootPathId int, RootPath nvarchar(4000), Description nvarchar(4000)
    , IsActive bit, CreatedAt datetime2(0)
);
DECLARE @BoundaryBinary TABLE
(
      Content varbinary(max) NULL, BytesRead bigint NOT NULL, IsValid bit NOT NULL
    , ValidationCode int NULL, ValidationMessage nvarchar(4000) NULL
);
DECLARE @BoundaryText TABLE
(
      Content nvarchar(max) NULL, BytesRead bigint NOT NULL, EncodingDetected nvarchar(128) NULL
    , BomPresent bit NOT NULL, IsValid bit NOT NULL
    , ValidationCode int NULL, ValidationMessage nvarchar(4000) NULL
);
DECLARE @BoundaryCaseId int = 1, @BoundaryActual bit, @BoundaryExpected bit;
DECLARE @BoundaryRoot nvarchar(4000), @NormalizedPath nvarchar(4000);
DECLARE @BoundaryActive bit, @BoundaryCaseName nvarchar(128), @BoundaryMessage nvarchar(2048);
DECLARE @BoundaryReturn int, @BoundaryDenialCalls int = 0;
DECLARE @BoundaryRootPathId int;
DECLARE @BoundaryFixtureRoot nvarchar(4000) = N'$(FixtureRoot)';
DECLARE @BoundaryFixturePath nvarchar(4000);
SET @BoundaryFixtureRoot = REPLACE(REPLACE(@BoundaryFixtureRoot, N'\\', N'/'), N'\', N'/');
WHILE RIGHT(@BoundaryFixtureRoot, 1) = N'/'
    SET @BoundaryFixtureRoot = LEFT(@BoundaryFixtureRoot, LEN(@BoundaryFixtureRoot) - 1);
IF DATALENGTH(@BoundaryFixtureRoot) = 0
    THROW 52937, N'FixtureRoot muss ein nichtleerer vorbereiteter Fixture-Root sein.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO @BoundaryOriginal
    SELECT RootPathId, RootPath, Description, IsActive, CreatedAt
    FROM [toolbelt_file].[FileContentRootAllowlist] WITH (TABLOCKX, HOLDLOCK);
    SELECT @BoundaryRootPathId = MIN(RootPathId) FROM @BoundaryOriginal;
    IF @BoundaryRootPathId IS NULL
        THROW 52937, N'Vorbereitete Fixture-Allowlist fehlt.', 1;
    -- Eine vorhandene Zeile wiederverwenden statt INSERT: selbst der nicht
    -- rollbackbare IDENTITY-Zähler bleibt dadurch unverändert. Andere Roots
    -- können die isolierten Denialfälle nicht versehentlich freigeben.
    DELETE FROM [toolbelt_file].[FileContentRootAllowlist] WHERE RootPathId <> @BoundaryRootPathId;

    WHILE @BoundaryCaseId <= 47
    BEGIN
        SELECT @BoundaryRoot = RootPath, @BoundaryActive = IsActive,
               @NormalizedPath = Candidate, @BoundaryExpected = Expected,
               @BoundaryCaseName = CaseName
        FROM @BoundaryCases WHERE CaseId = @BoundaryCaseId;
        UPDATE [toolbelt_file].[FileContentRootAllowlist]
        SET RootPath = @BoundaryRoot, IsActive = @BoundaryActive
        WHERE RootPathId = @BoundaryRootPathId;
        SET @NormalizedPath = REPLACE(REPLACE(@NormalizedPath, N'\\', N'/'), N'\', N'/');
        SET @BoundaryActual = 0;
        IF EXISTS
        (
:r ../../Source/FileContentRootPredicate.sql
        )
            SET @BoundaryActual = 1;
        IF @BoundaryActual <> @BoundaryExpected
        BEGIN
            SET @BoundaryMessage = N'Root-Grenzmatrix fehlgeschlagen: ' + @BoundaryCaseName;
            THROW 52937, @BoundaryMessage, 1;
        END;

        -- Absolute, nicht existente synthetische Pfade. Falls ein Wrapper bis
        -- OPENROWSET gelangt, propagiert dessen Providerfehler in den CATCH;
        -- er kann niemals als erfolgreiche 51321-Abweisung gezählt werden.
        IF @BoundaryCaseId IN (6, 12, 14, 16, 26, 38)
        BEGIN
            DECLARE @BoundaryDeniedPath nvarchar(4000);
            SELECT @BoundaryDeniedPath = Candidate FROM @BoundaryCases WHERE CaseId = @BoundaryCaseId;
            DELETE FROM @BoundaryBinary;
            SET @BoundaryReturn = -1;
            INSERT INTO @BoundaryBinary
            EXEC @BoundaryReturn = toolbelt_file.USP_LoadBinaryFile @FilePath = @BoundaryDeniedPath;
            IF ISNULL(@BoundaryReturn, -1) <> 0 OR (SELECT COUNT(*) FROM @BoundaryBinary) <> 1
               OR NOT EXISTS (SELECT 1 FROM @BoundaryBinary WHERE Content IS NULL AND BytesRead = 0
                              AND IsValid = 0 AND ISNULL(ValidationCode, -1) = 51321 AND ValidationMessage IS NOT NULL)
                THROW 52938, N'Binary-Wrapper muss exakt eine 51321-Abweisung mit neutralem Ergebnis liefern.', 1;
            DELETE FROM @BoundaryText;
            SET @BoundaryReturn = -1;
            INSERT INTO @BoundaryText
            EXEC @BoundaryReturn = toolbelt_file.USP_LoadTextFile @FilePath = @BoundaryDeniedPath;
            IF ISNULL(@BoundaryReturn, -1) <> 0 OR (SELECT COUNT(*) FROM @BoundaryText) <> 1
               OR NOT EXISTS (SELECT 1 FROM @BoundaryText WHERE Content IS NULL AND BytesRead = 0
                              AND EncodingDetected IS NULL AND BomPresent = 0
                              AND IsValid = 0 AND ISNULL(ValidationCode, -1) = 51321 AND ValidationMessage IS NOT NULL)
                THROW 52938, N'Text-Wrapper muss exakt eine 51321-Abweisung mit neutralen Metadaten liefern.', 1;
            SET @BoundaryDenialCalls += 2;
        END;
        SET @BoundaryCaseId += 1;
    END;

    -- Beide vorhandenen kleinen Fixtures unter genau einem Root ohne Endslash.
    UPDATE [toolbelt_file].[FileContentRootAllowlist]
    SET RootPath = @BoundaryFixtureRoot, IsActive = 1
    WHERE RootPathId = @BoundaryRootPathId;
    DELETE FROM @BoundaryBinary;
    SET @BoundaryFixturePath = @BoundaryFixtureRoot + N'/sample.bin';
    SET @BoundaryReturn = -1;
    INSERT INTO @BoundaryBinary
    EXEC @BoundaryReturn = toolbelt_file.USP_LoadBinaryFile @FilePath = @BoundaryFixturePath;
    IF ISNULL(@BoundaryReturn, -1) <> 0 OR (SELECT COUNT(*) FROM @BoundaryBinary) <> 1
       OR NOT EXISTS (SELECT 1 FROM @BoundaryBinary WHERE IsValid = 1 AND BytesRead = 7
                      AND Content = 0x000102FFFE1020 AND DATALENGTH(Content) = 7
                      AND ValidationCode IS NULL AND ValidationMessage IS NULL)
        THROW 52938, N'Kleine Binary-Fixture unter Root ohne Endslash ist fehlgeschlagen.', 1;
    DELETE FROM @BoundaryText;
    SET @BoundaryFixturePath = @BoundaryFixtureRoot + N'/ansi.txt';
    SET @BoundaryReturn = -1;
    INSERT INTO @BoundaryText
    EXEC @BoundaryReturn = toolbelt_file.USP_LoadTextFile @FilePath = @BoundaryFixturePath;
    IF ISNULL(@BoundaryReturn, -1) <> 0 OR (SELECT COUNT(*) FROM @BoundaryText) <> 1
       OR NOT EXISTS (SELECT 1 FROM @BoundaryText WHERE IsValid = 1 AND BytesRead = 26
                      AND Content COLLATE Latin1_General_100_BIN2
                          = (N'Hallo, Welt!' + NCHAR(13) + NCHAR(10) + N'ANSI-Test.' + NCHAR(13) + NCHAR(10))
                      AND DATALENGTH(Content) = 52
                      AND EncodingDetected = N'Windows-1252' AND BomPresent = 0
                      AND ValidationCode IS NULL AND ValidationMessage IS NULL)
        THROW 52938, N'Kleine Text-Fixture unter Root ohne Endslash ist fehlgeschlagen.', 1;
    IF @BoundaryDenialCalls <> 12
        THROW 52938, N'Wrapper-Abweisungsmatrix ist unvollständig.', 1;
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

IF @@TRANCOUNT <> 0 OR XACT_STATE() <> 0
    THROW 52939, N'Root-Grenztests hinterlassen einen nichtneutralen Transaktionszustand.', 1;
IF EXISTS
(
    SELECT RootPathId, RootPath COLLATE Latin1_General_100_BIN2, DATALENGTH(RootPath),
           Description COLLATE Latin1_General_100_BIN2, DATALENGTH(Description), IsActive, CreatedAt
    FROM @BoundaryOriginal
    EXCEPT
    SELECT RootPathId, RootPath COLLATE Latin1_General_100_BIN2, DATALENGTH(RootPath),
           Description COLLATE Latin1_General_100_BIN2, DATALENGTH(Description), IsActive, CreatedAt
    FROM [toolbelt_file].[FileContentRootAllowlist]
)
OR EXISTS
(
    SELECT RootPathId, RootPath COLLATE Latin1_General_100_BIN2, DATALENGTH(RootPath),
           Description COLLATE Latin1_General_100_BIN2, DATALENGTH(Description), IsActive, CreatedAt
    FROM [toolbelt_file].[FileContentRootAllowlist]
    EXCEPT
    SELECT RootPathId, RootPath COLLATE Latin1_General_100_BIN2, DATALENGTH(RootPath),
           Description COLLATE Latin1_General_100_BIN2, DATALENGTH(Description), IsActive, CreatedAt
    FROM @BoundaryOriginal
)
    THROW 52939, N'Root-Allowlistzeilen wurden nicht vollständig restauriert.', 1;
PRINT N'File Content Root Boundary: 47 Predicatecases, 12 Wrapperdenials, 2 Fixturepositives, 1 Longprefixassertion erfolgreich';
