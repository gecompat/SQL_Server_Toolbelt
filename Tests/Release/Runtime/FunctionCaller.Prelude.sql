SET NOCOUNT ON;
SET XACT_ABORT OFF;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULL_DFLT_ON ON;
DECLARE @Owner nvarchar(32)=(SELECT CONVERT(nvarchar(32),value) FROM sys.extended_properties
 WHERE class=0 AND name=N'Test.Release.Owner');
IF @Owner IS NULL OR LEN(@Owner)<>32 OR @Owner COLLATE Latin1_General_100_BIN2 LIKE N'%[^a-f0-9]%'
 OR DB_NAME() NOT IN(N'Toolbelt_Release_'+@Owner+N'_l',N'Toolbelt_Release_'+@Owner+N'_c') OR @@TRANCOUNT<>0
 THROW 52097,N'Markierter eigener Funktions-Testscope erforderlich.',1;
IF USER_ID(N'ContosoFunctionCaller') IS NOT NULL
 THROW 52097,N'Vorhandener Funktions-Principal wird nicht uebernommen.',2;
DECLARE @Apis table(Id int PRIMARY KEY,SchemaName sysname,Name sysname,PermissionName varchar(16),
 ProbeSql nvarchar(max),OracleSql nvarchar(max));
DECLARE @Denied table(Id int PRIMARY KEY,SchemaName sysname,Name sysname,PermissionName varchar(16),ProbeSql nvarchar(max));
