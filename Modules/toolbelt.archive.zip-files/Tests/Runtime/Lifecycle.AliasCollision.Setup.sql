-- Ausschließlich synthetische eigene Test-DB mit installiertem Archivschema.
-- Vorhandene ZIP2-Slots sind unzulässig: keine Adoption oder Änderung fremder Objekte.
-- Dies ist SETUP, kein Lifecycle-PASS. Koordinierter Runner muss danach die originalen
-- ersten GO-Bodies von Deploy und Uninstall jeweils ausführen, strikt 54634/state1
-- und denselben vollständigen Objekt-/Marker-/Definition-/Ownerzustand prüfen.
-- Cleanup ausschließlich mit frisch bestätigter eigener Fixture-Objektidentität.
SET NOCOUNT ON;
IF SCHEMA_ID(N'toolbelt_archive') IS NULL
    THROW 54690,N'ZIP_FILES_ALIAS_FIXTURE_SCHEMA',1;
IF N'usp_CreateZipFileFromEntries' COLLATE DATABASE_DEFAULT<>N'USP_CreateZipFileFromEntries' COLLATE DATABASE_DEFAULT
    THROW 54690,N'ZIP_FILES_ALIAS_FIXTURE_COLLATION',1;
IF OBJECT_ID(N'toolbelt_archive.usp_CreateZipFileFromEntries') IS NOT NULL
   OR OBJECT_ID(N'toolbelt_archive.usp_ExtractZipEntryToFile') IS NOT NULL
    THROW 54690,N'ZIP_FILES_ALIAS_FIXTURE_PRESTATE',1;
EXEC sys.sp_executesql N'CREATE PROCEDURE toolbelt_archive.usp_CreateZipFileFromEntries AS SELECT CONVERT(int,17) AS SyntheticForeignFixture;';
EXEC sys.sp_executesql N'CREATE PROCEDURE toolbelt_archive.usp_ExtractZipEntryToFile AS SELECT CONVERT(int,19) AS SyntheticForeignFixture;';
PRINT N'READY ZIP_FILES_ALIAS_COLLISION_FIXTURE';
GO
