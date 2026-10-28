SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_ScheduleWorkRetry]
      @WorkItemId bigint=NULL,@ClaimToken uniqueidentifier=NULL,@FailureCode varchar(64)=NULL,@FailureMessage nvarchar(1000)=NULL,
      @ResultTable sysname=NULL,@KeepData bit=0,@Debug tinyint=0,@Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
 DECLARE @Help TABLE(HelpContractVersion varchar(16) NOT NULL,SchemaName sysname NOT NULL,ObjectName sysname NOT NULL,Section varchar(32) NOT NULL,Ordinal int NOT NULL,ItemName sysname NULL,SqlDataType varchar(256) NULL,IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,Description nvarchar(max) NOT NULL,ExampleSql nvarchar(max) NULL);
 INSERT @Help
 SELECT CAST('1.0' AS varchar(16)),CAST(N'toolbelt_core' AS sysname),CAST(N'USP_ScheduleWorkRetry' AS sysname),CAST(v.Section AS varchar(32)),v.Ordinal,CAST(v.ItemName AS sysname),CAST(v.SqlDataType AS varchar(256)),CAST(v.IsRequired AS bit),CAST(v.IsNullable AS bit),CAST(v.DefaultValue AS nvarchar(4000)),CAST(v.Description AS nvarchar(max)),CAST(v.ExampleSql AS nvarchar(max))
 FROM(VALUES
 ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Plant anhand eines aktiven Claim-Tokens den nächsten Retry oder verschiebt nach ausgeschöpften Versuchen in Dead Letter.',NULL),
 ('PARAMETER',1,N'@WorkItemId',N'bigint',1,0,N'NULL',N'ID des beanspruchten Work Items.',NULL),
 ('PARAMETER',2,N'@ClaimToken',N'uniqueidentifier',1,0,N'NULL',N'Unverändertes Token des aktiven Claims.',NULL),
 ('PARAMETER',3,N'@FailureCode',N'varchar(64)',1,0,N'NULL',N'Synthetischer stabiler Code mit zulässigem alphanumerischem Start.',NULL),
 ('PARAMETER',4,N'@FailureMessage',N'nvarchar(1000)',0,1,N'NULL',N'Optionale Fehlermeldung; Nutzdaten vermeiden.',NULL),
 ('PARAMETER',5,N'@ResultTable',N'sysname',0,1,N'NULL',N'In dieser Version nicht unterstützt; Fehler 51989 bei Nicht-NULL.',NULL),
 ('PARAMETER',6,N'@KeepData',N'bit',0,0,N'0',N'Standardparameter; ohne ResultTable-Routing wirkungslos.',NULL),
 ('PARAMETER',7,N'@Debug',N'tinyint',0,0,N'0',N'Standardparameter.',NULL),
 ('PARAMETER',8,N'@Hilfe',N'bit',0,0,N'0',N'1 gibt ausschließlich Hilfe aus.',NULL),
 ('ERROR',1,N'51985-51989',NULL,NULL,NULL,NULL,N'Fehlende Argumente, ungültige Fehlerdaten, inaktiver Claim oder nicht unterstütztes ResultTable.',NULL),
 ('PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'EXECUTE sowie die Queue-Claim-Autorisierung des aufrufenden Pfades.',NULL),
 ('LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'Diese Version unterstützt kein ResultTable-Routing; der Aufruf gibt eine Statuszeile aus toolbelt_core.VW_WorkQueue zurück.',NULL),
 ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Beispielaufruf nach einem gültigen Claim.',N'EXEC toolbelt_core.USP_ScheduleWorkRetry @WorkItemId=42,@ClaimToken=''00000000-0000-0000-0000-000000000001'',@FailureCode=''Transient'';')
 )v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql);
 INSERT @Help SELECT '1.0',N'toolbelt_core',N'USP_ScheduleWorkRetry','RESULT_COLUMN',ROW_NUMBER() OVER(ORDER BY c.column_id),c.name,TYPE_NAME(c.user_type_id),1,c.is_nullable,NULL,N'Wert aus toolbelt_core.VW_WorkQueue.',NULL FROM sys.columns c WHERE c.object_id=OBJECT_ID(N'toolbelt_core.VW_WorkQueue',N'V');
 SELECT HelpContractVersion,SchemaName,ObjectName,Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql FROM @Help
 ORDER BY CASE Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1 WHEN 'RESULT_COLUMN' THEN 2 ELSE 3 END,Ordinal,ItemName; RETURN 0; END;
    EXEC toolbelt_core.USP_ScheduleWorkRetryCore @WorkItemId=@WorkItemId,@ClaimToken=@ClaimToken,@FailureCode=@FailureCode,@FailureMessage=@FailureMessage,@ResultTable=@ResultTable,@KeepData=@KeepData,@Debug=@Debug;
    RETURN 0;
END;
GO
