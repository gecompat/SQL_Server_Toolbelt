SET NOCOUNT ON;
DECLARE @CompatibilityLevel int=TRY_CONVERT(int,N'$(CompatibilityLevel)');
IF @CompatibilityLevel NOT IN(150,160,170) OR (SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID())<>@CompatibilityLevel
 THROW 52940,N'Falscher Compatibility Level.',1;
IF OBJECT_ID(N'toolbelt_metadata.VW_ModuleCapabilities',N'V') IS NULL
 THROW 52942,N'Capability-View fehlt.',1;
IF NOT EXISTS(SELECT 1 FROM toolbelt_metadata.VW_ModuleCapabilities WHERE ModuleId=N'toolbelt.metadata.capability-catalog')
 THROW 52943,N'Die sichtbare eigene Schnittstelle muss als Kandidat erscheinen.',1;
IF EXISTS(SELECT 1 FROM toolbelt_metadata.VW_ModuleCapabilities WHERE ModuleVersion IS NOT NULL OR DeploymentMode IS NOT NULL OR MetadataStatus<>'incomplete')
 THROW 52944,N'Unbelegte Version, Installationsart oder gesundes Ergebnis wurde erfunden.',1;
IF EXISTS(SELECT ModuleId FROM toolbelt_metadata.VW_ModuleCapabilities GROUP BY ModuleId HAVING COUNT(*)<>1)
 THROW 52945,N'Modulkandidaten müssen eindeutig sein.',1;
PRINT N'CAPABILITY_CANDIDATE_CONTRACT_PASS';
GO
