:On Error exit
SET NOCOUNT ON;

IF DB_ID(N'$(TestDatabase)') IS NULL
    THROW 51465, N'Die angegebene disposable Testdatenbank existiert nicht.', 1;
IF DB_NAME() <> N'$(TestDatabase)'
    THROW 51466, N'Dieses Skript muss mit der angegebenen Testdatenbank als SQLCMD-Datenbank ausgefuehrt werden.', 1;
IF IS_SRVROLEMEMBER(N'sysadmin') <> 1
    THROW 51467, N'CREATE ASSEMBLY fuer diesen Spike erfordert sysadmin.', 1;

IF EXISTS
   (
       SELECT 1
       FROM sys.assemblies
       WHERE name = N'Toolbelt_ZipClr_Spike'
   )
    THROW 51468, N'Die Spike-Assembly ist bereits vorhanden. Zuerst Uninstall-TestDatabase.sql ausfuehren.', 1;

IF SCHEMA_ID(N'toolbelt_spike') IS NULL
    EXEC sys.sp_executesql N'CREATE SCHEMA toolbelt_spike;';
GO

-- Das aufrufende Skript ersetzt den AssemblyBits-Platzhalter in einer temporaeren Kopie
-- durch das 0x-Hexliteral des exakt gehashten Binaries. Dadurch ist kein
-- serverlokaler Dateipfad und kein Dateisystemzugriff des SQL-Server-Diensts
-- erforderlich.
CREATE ASSEMBLY [Toolbelt_ZipClr_Spike]
FROM $(AssemblyBits)
WITH PERMISSION_SET = SAFE;
GO

CREATE PROCEDURE toolbelt_spike.USP_ProbeDeflatePrimitive
AS EXTERNAL NAME [Toolbelt_ZipClr_Spike].[Toolbelt.ZipClr.Spike.ZipClrProbe].[ProbeDeflatePrimitive];
GO
