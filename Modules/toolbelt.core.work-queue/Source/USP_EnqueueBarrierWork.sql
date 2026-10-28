SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_EnqueueBarrierWork]
      @WorkTypeName varchar(128)=NULL,@PayloadJson nvarchar(max)=NULL,@ExecutionGroup varchar(128)=NULL,@Priority tinyint=NULL,@IdempotencyKey varchar(128)=NULL,
      @MaxAttempts tinyint=3,@RetryBaseDelaySeconds int=60,@RetryMaxDelaySeconds int=3600,@ResultTable sysname=NULL,@KeepData bit=0,@Debug tinyint=0,@Hilfe bit=0
AS
BEGIN
 IF ISNULL(@Hilfe,0)=1
 BEGIN
  DECLARE @Help TABLE(HelpContractVersion varchar(16) NOT NULL,SchemaName sysname NOT NULL,ObjectName sysname NOT NULL,Section varchar(32) NOT NULL,Ordinal int NOT NULL,ItemName sysname NULL,SqlDataType varchar(256) NULL,IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,Description nvarchar(max) NOT NULL,ExampleSql nvarchar(max) NULL);
  INSERT @Help VALUES
  ('1.0',N'toolbelt_core',N'USP_EnqueueBarrierWork','DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Reiht eine DRAIN_BARRIER-Arbeit ein. @Priority muss fachlich angegeben werden; Barrier-Enqueue ist außerhalb einer Callertransaktion erforderlich.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueBarrierWork','PARAMETER',1,N'@WorkTypeName','varchar(128)',1,0,N'NULL',N'Registrierter und aktivierter Work Type.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueBarrierWork','PARAMETER',2,N'@PayloadJson','nvarchar(max)',0,1,N'NULL',N'Payload gemäß ParameterMode des Work Types.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueBarrierWork','PARAMETER',3,N'@ExecutionGroup','varchar(128)',1,1,N'NULL',N'Nichtleere Barrier-Gruppe.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueBarrierWork','PARAMETER',4,N'@Priority','tinyint',1,0,N'NULL',N'Erforderliche Priorität der Barrier-Arbeit.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueBarrierWork','PARAMETER',5,N'@IdempotencyKey','varchar(128)',0,1,N'NULL',N'Optionaler Idempotency Key.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueBarrierWork','PARAMETER',6,N'@MaxAttempts','tinyint',0,0,N'3',N'1 bis 10 Versuche pro Zyklus.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueBarrierWork','PARAMETER',7,N'@RetryBaseDelaySeconds','int',0,0,N'60',N'Basisverzögerung von 1 bis 86400 Sekunden.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueBarrierWork','PARAMETER',8,N'@RetryMaxDelaySeconds','int',0,0,N'3600',N'Begrenzung der Retry-Verzögerung.',NULL),
   ('1.0',N'toolbelt_core',N'USP_EnqueueBarrierWork','PARAMETER',9,N'@ResultTable','sysname',0,1,N'NULL',N'Optionaler lokaler Temp-Tabellenname für das Queue-Ergebnis.',NULL),
   ('1.0',N'toolbelt_core',N'USP_EnqueueBarrierWork','PARAMETER',10,N'@KeepData','bit',0,0,N'0',N'Bei ResultTable-Routing bleiben vorhandene Zielzeilen erhalten, wenn 1.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueBarrierWork','PARAMETER',11,N'@Debug','tinyint',0,0,N'0',N'Beim ResultTable-Routing Diagnosemeldungen des kanonischen Helpers; keine zusätzlichen fachlichen Resultsets.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueBarrierWork','PARAMETER',12,N'@Hilfe','bit',0,0,N'0',N'1 gibt ausschließlich diese objektspezifische Hilfe aus.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueBarrierWork','ERROR',1,N'51908,51975,51997-51998',NULL,NULL,NULL,NULL,N'Fehlende ResultTable-Dependency, fehlende Priority, Callertransaktion oder fehlende ENQUEUE-Autorisierung.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueBarrierWork','PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'EXECUTE und explizite ENQUEUE-Autorisierung für den Work Type; für @ResultTable zusätzlich EXECUTE auf USP_PrepareResultTable.',NULL),
   ('1.0',N'toolbelt_core',N'USP_EnqueueBarrierWork','LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'DRAIN_BARRIER kann nicht innerhalb einer Callertransaktion eingereiht werden.',NULL),
  ('1.0',N'toolbelt_core',N'USP_EnqueueBarrierWork','EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Barrier mit expliziter Gruppe und Priorität; der Work Type muss registriert und autorisiert sein.',N'EXEC toolbelt_core.USP_EnqueueBarrierWork @WorkTypeName=''registered-type'',@ExecutionGroup=''default'',@Priority=10;');
  INSERT @Help VALUES('1.0',N'toolbelt_core',N'USP_EnqueueBarrierWork','RESULT_COLUMN',1,N'WasCreated','bit',1,0,NULL,N'1 bei Neuanlage, 0 bei idempotenter Wiederverwendung.',NULL);
  INSERT @Help SELECT '1.0',N'toolbelt_core',N'USP_EnqueueBarrierWork','RESULT_COLUMN',ROW_NUMBER() OVER(ORDER BY c.column_id)+1,c.name,TYPE_NAME(c.user_type_id),1,c.is_nullable,NULL,N'Wert aus toolbelt_core.VW_WorkQueue.',NULL FROM sys.columns c WHERE c.object_id=OBJECT_ID(N'toolbelt_core.VW_WorkQueue',N'V');
  SELECT HelpContractVersion,SchemaName,ObjectName,Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql FROM @Help
  ORDER BY CASE Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1 WHEN 'RESULT_COLUMN' THEN 2 ELSE 3 END,CASE WHEN ItemName=N'WasCreated' THEN 0 ELSE 1 END,Ordinal,ItemName;
  RETURN 0;
 END;
 IF @Priority IS NULL THROW 51975,N'@Priority ist für eine Barrier erforderlich.',1;
 EXEC toolbelt_core.USP_EnqueueWorkWithPolicy @WorkTypeName,@PayloadJson,@IdempotencyKey,@Priority,@ExecutionGroup,@MaxAttempts,@RetryBaseDelaySeconds,@RetryMaxDelaySeconds,'DRAIN_BARRIER',@ResultTable,@KeepData,@Debug,@Hilfe;
END;
GO
