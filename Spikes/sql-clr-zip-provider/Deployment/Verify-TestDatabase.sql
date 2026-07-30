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

IF OBJECT_ID(N'toolbelt_spike.USP_ProbeZipArchive', N'P') IS NULL
    THROW 51471, N'Die erwartete Probe-Procedure fehlt.', 1;

EXEC toolbelt_spike.USP_ProbeZipArchive;
GO
