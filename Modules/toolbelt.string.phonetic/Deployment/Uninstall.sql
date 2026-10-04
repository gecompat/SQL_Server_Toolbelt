:On Error exit
DECLARE @Install bit=0,@AssemblyBits varbinary(max)=NULL,@DeploymentMode nvarchar(max)=NULL,
        @ConfirmNoExternalConsumers bit=TRY_CONVERT(bit,N'$(ConfirmNoExternalConsumers)');
IF @ConfirmNoExternalConsumers IS NULL OR CONVERT(varbinary(max),N'$(ConfirmNoExternalConsumers)') NOT IN(CONVERT(varbinary(max),N'0'),CONVERT(varbinary(max),N'1'))
    THROW 55267,N'ConfirmNoExternalConsumers muss 0 oder 1 sein.',2;
:r ./Preflight.sql
GO
-- Serverweiter Assemblytrust bleibt unverändert.
