SET NOCOUNT ON;
SET XACT_ABORT OFF;
SET ANSI_NULL_DFLT_ON ON;
DECLARE @Owner nvarchar(32)=(SELECT CONVERT(nvarchar(32),value) FROM sys.extended_properties
 WHERE class=0 AND name=N'Test.Release.Owner');
IF @Owner IS NULL OR LEN(@Owner)<>32 OR @Owner COLLATE Latin1_General_100_BIN2 LIKE N'%[^a-f0-9]%'
 OR DB_NAME() NOT IN(N'Toolbelt_Release_'+@Owner+N'_l',N'Toolbelt_Release_'+@Owner+N'_c')
 OR @@TRANCOUNT<>0
 THROW 52092,N'Markierter eigener frischer T-SQL-Vertragstestscope erforderlich.',1;
