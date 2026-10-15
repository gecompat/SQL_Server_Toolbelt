SET NOCOUNT ON;
IF (SELECT COUNT_BIG(*) FROM toolbelt_core.ExecutionCancellation)>5000 THROW 52990,N'Quota fixture requires its own small disposable database.',1;
DECLARE @Own TABLE(ExecutionId uniqueidentifier NOT NULL PRIMARY KEY);
DECLARE @Pid int=USER_ID(),@Sid varbinary(85),@Created datetime,@Existing uniqueidentifier,@New uniqueidentifier=NEWID(),@Before binary(8),@Needed bigint;
SELECT @Sid=sid,@Created=create_date FROM sys.database_principals WHERE principal_id=@Pid;
SET @Needed=10000-(SELECT COUNT_BIG(*) FROM toolbelt_core.ExecutionCancellation WHERE RequestedByPrincipalId=@Pid AND RequestedByPrincipalSid=@Sid AND RequestedByPrincipalCreatedAt=@Created);
INSERT toolbelt_core.ExecutionCancellation(ExecutionId,RequestedBy,CancellationReason,RequestedByPrincipalId,RequestedByPrincipalSid,RequestedByPrincipalCreatedAt)
OUTPUT inserted.ExecutionId INTO @Own
SELECT NEWID(),N'Contoso synthetic',N'first',@Pid,@Sid,@Created FROM toolbelt_core.TVF_GenerateSeriesBigInt(1,@Needed,1);
SELECT TOP(1) @Existing=o.ExecutionId,@Before=CONVERT(binary(8),c.RowVersion) FROM @Own o JOIN toolbelt_core.ExecutionCancellation c ON c.ExecutionId=o.ExecutionId;
SET @Needed=100000-(SELECT COUNT_BIG(*) FROM toolbelt_core.ExecutionCancellation);
INSERT toolbelt_core.ExecutionCancellation(ExecutionId,RequestedBy,CancellationReason)
OUTPUT inserted.ExecutionId INTO @Own
SELECT NEWID(),N'Contoso legacy',N'first' FROM toolbelt_core.TVF_GenerateSeriesBigInt(1,@Needed,1);
EXEC toolbelt_core.USP_RequestExecutionCancellation @ExecutionId=@Existing,@CancellationReason=N'changed';
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.ExecutionCancellation WHERE ExecutionId=@Existing AND RowVersion=@Before AND CancellationReason=N'first') THROW 52990,N'Quota idempotency altered request.',2;
BEGIN TRY EXEC toolbelt_core.USP_RequestExecutionCancellation @ExecutionId=@New; THROW 52990,N'Database quota bypass.',3; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>52605 THROW; END CATCH;
DELETE TOP(1) c FROM toolbelt_core.ExecutionCancellation c JOIN @Own o ON o.ExecutionId=c.ExecutionId WHERE c.RequestedBy=N'Contoso legacy';
BEGIN TRY EXEC toolbelt_core.USP_RequestExecutionCancellation @ExecutionId=@New; THROW 52990,N'Principal quota bypass.',4; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>52606 THROW; END CATCH;
CREATE USER ContosoSecurityCancellation WITHOUT LOGIN;
GRANT EXECUTE ON toolbelt_core.USP_RequestExecutionCancellation TO ContosoSecurityCancellation;
EXECUTE AS USER=N'ContosoSecurityCancellation';
BEGIN TRY EXEC toolbelt_core.USP_RequestExecutionCancellation @ExecutionId=@New; END TRY
BEGIN CATCH REVERT; THROW; END CATCH;
REVERT;
INSERT @Own VALUES(@New);
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.ExecutionCancellation WHERE ExecutionId=@New AND RequestedByPrincipalId=USER_ID(N'ContosoSecurityCancellation')) THROW 52990,N'Quota principal binding.',5;
DROP USER ContosoSecurityCancellation;
-- Cleanup only requests explicitly inserted/created by this synthetic fixture.
DELETE c FROM toolbelt_core.ExecutionCancellation c JOIN @Own o ON o.ExecutionId=c.ExecutionId;
GO
