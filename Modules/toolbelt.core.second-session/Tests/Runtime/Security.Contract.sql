SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO
CREATE TABLE dbo.SecuritySessionCalls(Id int IDENTITY PRIMARY KEY,PayloadBytes bigint NOT NULL);
GO
CREATE OR ALTER PROCEDURE dbo.USP_SecuritySessionJson @PayloadJson nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON;
 INSERT dbo.SecuritySessionCalls(PayloadBytes) VALUES(DATALENGTH(@PayloadJson));
END;
GO
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='security.session',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_SecuritySessionJson',@ParameterMode='JSON_PAYLOAD',@PayloadContractJson=N'{"type":"object"}';
EXEC toolbelt_core.USP_SetWorkTypePermission 'security.session',N'dbo','EXECUTE_NEW_SESSION','ALLOW';
CREATE USER SecuritySessionCaller WITHOUT LOGIN;
GRANT EXECUTE ON toolbelt_core.USP_ExecuteWorkTypeInNewSession TO SecuritySessionCaller;
GRANT EXECUTE ON toolbelt_core.USP_DispatchWorkType TO SecuritySessionCaller;
GRANT VIEW DEFINITION ON dbo.USP_SecuritySessionJson TO SecuritySessionCaller;
GO
DECLARE @Id uniqueidentifier=NEWID(),@Correlation uniqueidentifier=NEWID(),@Remote int,@Code int,@Started datetime2(7),@Completed datetime2(7);
DECLARE @Payload nvarchar(max)=N'{"v":"'+REPLICATE(CAST(N'x' AS nvarchar(max)),524280)+N'"}';
IF DATALENGTH(@Payload)<>1048576 THROW 52993,N'Payloadorakel ist nicht exakt 1 MiB.',1;
DECLARE @TooLarge nvarchar(max)=@Payload+N' ';
BEGIN TRY
 EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @WorkTypeName='security.session',@PayloadJson=@TooLarge;
 THROW 52993,N'Lokale Payloadgrenze wurde umgangen.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>51628 THROW;
END CATCH;
BEGIN TRY
 EXEC toolbelt_core.USP_DispatchWorkType 'security.session',@TooLarge,@Id,@Correlation,NULL,NULL,@Remote OUTPUT,@Code OUTPUT,@Started OUTPUT,@Completed OUTPUT;
 THROW 52993,N'Direkte Dispatcher-Payloadgrenze wurde umgangen.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>51628 THROW;
END CATCH;
IF EXISTS(SELECT 1 FROM dbo.SecuritySessionCalls) THROW 52993,N'Oversize hat Handler erreicht.',1;
EXECUTE AS USER='SecuritySessionCaller';
BEGIN TRY
 EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @WorkTypeName='security.session',@PayloadJson=N'{}',@Actor=N'dbo';
 REVERT; THROW 52993,N'Actor hat lokale Autorität ersetzt.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>51629 BEGIN REVERT; THROW; END;
END CATCH;
REVERT;
EXEC toolbelt_core.USP_SetWorkTypePermission 'security.session',N'SecuritySessionCaller','EXECUTE_NEW_SESSION','ALLOW';
EXECUTE AS USER='SecuritySessionCaller';
BEGIN TRY
 EXEC toolbelt_core.USP_DispatchWorkType 'security.session',N'{}',@Id,@Correlation,NULL,NULL,@Remote OUTPUT,@Code OUTPUT,@Started OUTPUT,@Completed OUTPUT;
 REVERT; THROW 52993,N'Delegation hat fehlendes Remote-EXECUTE ersetzt.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>51636 BEGIN REVERT; THROW; END;
END CATCH;
REVERT;
EXEC toolbelt_core.USP_DispatchWorkType 'security.session',@Payload,@Id,@Correlation,NULL,NULL,@Remote OUTPUT,@Code OUTPUT,@Started OUTPUT,@Completed OUTPUT;
IF (SELECT COUNT(*) FROM dbo.SecuritySessionCalls WHERE PayloadBytes=1048576)<>1
 THROW 52993,N'Exakte Grenze wurde nicht erfolgreich ausgeführt.',1;
IF EXISTS(SELECT 1 FROM toolbelt_core.SecondSessionProvider WHERE IsEnabled=1)
BEGIN
 EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @WorkTypeName='security.session',@PayloadJson=@Payload;
 IF (SELECT COUNT(*) FROM dbo.SecuritySessionCalls WHERE PayloadBytes=1048576)<>2
  THROW 52993,N'Exakte RPC-Payloadgrenze wurde nicht erfolgreich ausgeführt.',1;
 PRINT N'Second-Session-Security-RPC: erfolgreich';
END
ELSE PRINT N'Second-Session-Security-RPC: NOT_EXECUTED (kein Testprovider)';
DELETE toolbelt_core.WorkType WHERE WorkTypeName='security.session';
DROP USER SecuritySessionCaller;
DROP PROCEDURE dbo.USP_SecuritySessionJson;
DROP TABLE dbo.SecuritySessionCalls;
PRINT N'Second-Session-Securityvertrag: erfolgreich';
GO
