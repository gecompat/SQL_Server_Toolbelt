:On Error exit
IF @@TRANCOUNT<>0
BEGIN
 RAISERROR(N'TBX_CSV_LIFECYCLE_CALLER_TRANSACTION: Ein eigener Transaktionsscope ist erforderlich.',16,1);
 RETURN;
END;
DECLARE @Install bit=0,@Bits varbinary(max)=NULL,@Mode nvarchar(max)=NULL,@Confirm bit=TRY_CONVERT(bit,N'$(ConfirmNoExternalConsumers)');
IF CONVERT(varbinary(max),N'$(ConfirmNoExternalConsumers)') NOT IN(CONVERT(varbinary(max),N'0'),CONVERT(varbinary(max),N'1'))
 THROW 55326,N'ConfirmNoExternalConsumers muss exakt 0 oder 1 sein.',2;
:r ./Preflight.sql
GO
