:On Error exit
SET NOCOUNT ON;

IF DB_NAME() <> N'$(TestDatabase)'
    THROW 51469, N'Dieses Skript muss mit der angegebenen Testdatenbank als SQLCMD-Datenbank ausgefuehrt werden.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.assemblies
       WHERE name = N'Toolbelt_ZipClr_Spike'
         AND permission_set_desc = N'SAFE_ACCESS'
   )
    THROW 51470, N'Die erwartete SAFE-Assembly fehlt.', 1;

IF OBJECT_ID(N'toolbelt_spike.USP_ProbeDeflatePrimitive', N'PC') IS NULL
    THROW 51471, N'Die erwartete CLR-Probe-Procedure fehlt.', 1;

CREATE TABLE #ProbeResult
(
      ProviderAssembly nvarchar(512) NOT NULL
    , PayloadLength int NOT NULL
    , PayloadCrc32 char(8) NOT NULL
    , PayloadText nvarchar(128) NOT NULL
);

INSERT #ProbeResult
EXEC toolbelt_spike.USP_ProbeDeflatePrimitive;

IF (SELECT COUNT_BIG(*) FROM #ProbeResult) <> 1
    THROW 51473, N'Die CLR-Probe muss genau eine Ergebniszeile liefern.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM #ProbeResult
       WHERE ProviderAssembly LIKE N'System, Version=4.0.0.0,%'
         AND PayloadLength = 33
         AND PayloadCrc32 = 'BD97DF6A'
         AND PayloadText = N'SQL Server Toolbelt CLR ZIP probe'
   )
    THROW 51474, N'Deflate-Provider, Payload oder CRC32 entsprechen nicht dem erwarteten Probevertrag.', 1;

SELECT
      ProviderAssembly
    , PayloadLength
    , PayloadCrc32
    , PayloadText
FROM #ProbeResult;
GO
