:On Error exit
DECLARE @Install bit=1,@Bits varbinary(max)=$(AssemblyBits),@Mode nvarchar(max)=N'$(DeploymentMode)',@Confirm bit=0;
:r ./Preflight.sql
GO
:r ../Source/TVF_InternalParseCsv.sql
:r ../Source/SVF_InternalMeasureCsvCell.sql
:r ../Source/SVF_InternalQuoteCsvCell.sql
:r ../Source/USP_ParseCsv.sql
:r ../Source/USP_WriteCsv.sql
:r ./MarkRelease.sql
