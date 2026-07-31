:On Error exit
SET NOCOUNT ON;

IF DB_NAME() <> N'$(TestDatabase)'
    THROW 51472, N'Dieses Skript muss mit der angegebenen Testdatenbank als SQLCMD-Datenbank ausgefuehrt werden.', 1;

IF OBJECT_ID(N'toolbelt_spike.USP_ProbeDeflatePrimitive', N'PC') IS NOT NULL
    DROP PROCEDURE toolbelt_spike.USP_ProbeDeflatePrimitive;
GO

IF EXISTS (SELECT 1 FROM sys.assemblies WHERE name = N'Toolbelt_ZipClr_Spike')
    DROP ASSEMBLY [Toolbelt_ZipClr_Spike] WITH NO DEPENDENTS;
GO

IF SCHEMA_ID(N'toolbelt_spike') IS NOT NULL
   AND NOT EXISTS
       (
           SELECT 1
           FROM sys.objects
           WHERE schema_id = SCHEMA_ID(N'toolbelt_spike')
       )
    EXEC sys.sp_executesql N'DROP SCHEMA toolbelt_spike;';
GO

-- Ein Trust-Eintrag wird nicht entfernt. Er kann gemeinsam verwendet werden und
-- muss vom zuständigen Administrator gezielt anhand des konkreten SHA2-512-
-- Hashes verwaltet werden.
