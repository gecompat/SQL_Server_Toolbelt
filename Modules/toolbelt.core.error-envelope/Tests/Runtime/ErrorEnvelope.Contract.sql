SET NOCOUNT ON;

DECLARE @Direct TABLE
(
 CapturedAtUtc datetime2(7), ExecutionId uniqueidentifier NULL, ErrorClass varchar(16),
 ErrorNumber int, ErrorSeverity int, ErrorState int, ErrorProcedure nvarchar(776) NULL,
 ErrorLine int NULL, ErrorMessage nvarchar(4000), XactState smallint,
 TransactionCount int, DatabaseName sysname, SessionId int, AdditionalContext nvarchar(4000) NULL
);
INSERT INTO @Direct
EXEC toolbelt_core.USP_CaptureErrorEnvelope
 @ErrorNumber=8134, @ErrorSeverity=16, @ErrorState=1,
 @ErrorProcedure=N'tbx_test', @ErrorLine=7, @ErrorMessage=N'Divide by zero';
IF NOT EXISTS (SELECT 1 FROM @Direct WHERE ErrorClass='ENGINE' AND ErrorNumber=8134 AND SessionId=@@SPID)
 THROW 52400, N'ENGINE-Klassifikation fehlgeschlagen.', 1;

DELETE FROM @Direct;
INSERT INTO @Direct
EXEC toolbelt_core.USP_CaptureErrorEnvelope
 @ErrorNumber=51422, @ErrorSeverity=16, @ErrorState=1, @ErrorMessage=N'Toolbelt';
IF NOT EXISTS (SELECT 1 FROM @Direct WHERE ErrorClass='TOOLBELT')
 THROW 52401, N'TOOLBELT-Klassifikation fehlgeschlagen.', 1;

DELETE FROM @Direct;
INSERT INTO @Direct
EXEC toolbelt_core.USP_CaptureErrorEnvelope
 @ErrorNumber=60000, @ErrorSeverity=16, @ErrorState=1, @ErrorMessage=N'User';
IF NOT EXISTS (SELECT 1 FROM @Direct WHERE ErrorClass='USER')
 THROW 52402, N'USER-Klassifikation fehlgeschlagen.', 1;

CREATE TABLE #Envelope (Dummy int NULL);
EXEC toolbelt_core.USP_CaptureErrorEnvelope
 @ErrorNumber=50001, @ErrorSeverity=16, @ErrorState=2, @ErrorMessage=N'First',
 @ResultTable=N'#Envelope', @KeepData=0;
EXEC toolbelt_core.USP_CaptureErrorEnvelope
 @ErrorNumber=50002, @ErrorSeverity=16, @ErrorState=3, @ErrorMessage=N'Second',
 @ResultTable=N'#Envelope', @KeepData=1;
IF (SELECT COUNT(*) FROM #Envelope) <> 2
 THROW 52403, N'ResultTable-Integration fehlgeschlagen.', 1;

DECLARE @Help TABLE
(
 HelpContractVersion varchar(16), SchemaName sysname, ObjectName sysname,
 Section varchar(32), Ordinal int, ItemName sysname NULL, SqlDataType varchar(256) NULL,
 IsRequired bit NULL, IsNullable bit NULL, DefaultValue nvarchar(4000) NULL,
 Description nvarchar(max), ExampleSql nvarchar(max) NULL
);
INSERT INTO @Help EXEC toolbelt_core.USP_CaptureErrorEnvelope @Hilfe=1;
IF NOT EXISTS (SELECT 1 FROM @Help WHERE Section='DESCRIPTION')
 THROW 52404, N'Help-Vertrag fehlt.', 1;

BEGIN TRY
 EXEC toolbelt_core.USP_CaptureErrorEnvelope @ErrorNumber=NULL, @ErrorSeverity=16, @ErrorState=1, @ErrorMessage=N'x';
 THROW 52405, N'Fehler 51400 blieb aus.', 1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() <> 51400 THROW;
END CATCH;

DROP TABLE #Envelope;
PRINT N'Error Envelope Contract: erfolgreich';
