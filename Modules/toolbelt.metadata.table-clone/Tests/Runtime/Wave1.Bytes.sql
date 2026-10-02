-- Native Bytegrenze mit begrenzten synthetischen Properties; keine neue APIquote.
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
CREATE TABLE dbo.SyntheticByteSource(Id int);
DECLARE @i int=1,@Name sysname,@Value nvarchar(3500)=N'',@Full nvarchar(3500)=REPLICATE(N'''',3000);
WHILE @i<=200
BEGIN
 SET @Name=N'Byte'+RIGHT(N'000'+CONVERT(nvarchar(3),@i),3);
 EXEC sys.sp_addextendedproperty @name=@Name,@value=@Value,@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'TABLE',@level1name=N'SyntheticByteSource';
 SET @i+=1;
END;
CREATE TABLE #BytePlan(Dummy int);
EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticByteSource',N'dbo',N'SyntheticByteTarget',0,1,@ResultTable=N'#BytePlan';
DECLARE @Base bigint=(SELECT SUM(CONVERT(bigint,DATALENGTH(ScriptText))) FROM #BytePlan),
 @Remaining bigint,@Filled int,@Tail int,@TailName sysname,@At nvarchar(3500),@Minus nvarchar(3500);
SET @Remaining=2097152-@Base;
IF @Remaining<=0 OR @Remaining>=200*12000 OR @Remaining%2<>0 THROW 54930,N'Byte fixture initial shape invalid.',30;
SET @Filled=CONVERT(int,@Remaining/12000);SET @Tail=CONVERT(int,@Remaining%12000);
SET @i=1;
WHILE @i<=@Filled
BEGIN
 SET @Name=N'Byte'+RIGHT(N'000'+CONVERT(nvarchar(3),@i),3);
 EXEC sys.sp_updateextendedproperty @name=@Name,@value=@Full,@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'TABLE',@level1name=N'SyntheticByteSource';
 SET @i+=1;
END;
SET @TailName=N'Byte'+RIGHT(N'000'+CONVERT(nvarchar(3),@i),3);
SET @At=REPLICATE(N'''',@Tail/4)+CASE WHEN @Tail%4=2 THEN N'X' ELSE N'' END;
-- Eine Quote (4Outputbytes) kann durch zwei normale Zeichen (je2) ersetzt werden.
IF @Tail%4=0 AND @Tail>=4 SET @At=LEFT(@At,LEN(@At)-1)+N'XX';
IF @Tail=0
BEGIN
 SET @TailName=N'Byte001';SET @At=LEFT(@Full,2999)+N'XX';
END;
SET @Minus=LEFT(@At,LEN(@At)-1);
SET @Value=@Minus;
EXEC sys.sp_updateextendedproperty @name=@TailName,@value=@Value,@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'TABLE',@level1name=N'SyntheticByteSource';
EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticByteSource',N'dbo',N'SyntheticByteTarget',0,1,@ResultTable=N'#BytePlan';
IF (SELECT SUM(CONVERT(bigint,DATALENGTH(ScriptText))) FROM #BytePlan)<>2097150 THROW 54930,N'Minus2 byte witness differs.',31;
SET @Value=@At;
EXEC sys.sp_updateextendedproperty @name=@TailName,@value=@Value,@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'TABLE',@level1name=N'SyntheticByteSource';
EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticByteSource',N'dbo',N'SyntheticByteTarget',0,1,@ResultTable=N'#BytePlan';
IF (SELECT SUM(CONVERT(bigint,DATALENGTH(ScriptText))) FROM #BytePlan)<>2097152 THROW 54930,N'Exact byte witness differs.',32;
SELECT * INTO #ByteSnapshot FROM #BytePlan;
SET @Value=@At+N'X';
EXEC sys.sp_updateextendedproperty @name=@TailName,@value=@Value,@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'TABLE',@level1name=N'SyntheticByteSource';
BEGIN TRY
 EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticByteSource',N'dbo',N'SyntheticByteTarget',0,1,@ResultTable=N'#BytePlan';
 THROW 54930,N'Plus2 byte witness accepted.',33;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>53906 OR ERROR_STATE()<>2 THROW; END CATCH;
IF EXISTS(SELECT Ordinal,ObjectKind,CONVERT(varbinary(max),TargetName),CONVERT(varbinary(max),ScriptText) FROM #BytePlan
 EXCEPT SELECT Ordinal,ObjectKind,CONVERT(varbinary(max),TargetName),CONVERT(varbinary(max),ScriptText) FROM #ByteSnapshot)
 OR EXISTS(SELECT Ordinal,ObjectKind,CONVERT(varbinary(max),TargetName),CONVERT(varbinary(max),ScriptText) FROM #ByteSnapshot
 EXCEPT SELECT Ordinal,ObjectKind,CONVERT(varbinary(max),TargetName),CONVERT(varbinary(max),ScriptText) FROM #BytePlan)
 THROW 54930,N'Byte rejection changed output.',34;
DROP TABLE dbo.SyntheticByteSource;
GO
