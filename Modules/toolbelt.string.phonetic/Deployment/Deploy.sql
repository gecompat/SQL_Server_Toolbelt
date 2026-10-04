:On Error exit
-- SQLCMD-Parameter: vollständige AssemblyBits, explizite installierte
-- SHA2-512-Erwartung (0x nur für Abwesenheit), DeploymentMode local/central.
DECLARE @Install bit=1,@AssemblyBits varbinary(max)=$(AssemblyBits),
        @DeploymentMode nvarchar(max)=N'$(DeploymentMode)',@ConfirmNoExternalConsumers bit=0;
:r ./Preflight.sql
GO
:r ../Source/TVF_ColognePhoneticCore.sql
:r ../Source/TVF_DoubleMetaphoneCore.sql
:r ../Source/TVF_ColognePhonetic.sql
:r ../Source/TVF_DoubleMetaphone.sql
:r ./MarkRelease.sql
