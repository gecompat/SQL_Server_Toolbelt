-- Map64 ist unabhängig von1024/128 je Tabelle und global2048/2MiB; vor Ausführung kein Runtime-Nachweis.
SET NOCOUNT ON;
CREATE TABLE #W2Caps(MapOrdinal int NOT NULL,SourceSchema nvarchar(max) NOT NULL,SourceTable nvarchar(max) NOT NULL,TargetSchema nvarchar(max) NOT NULL,TargetTable nvarchar(max) NOT NULL);
DECLARE @i int=1,@Sql nvarchar(max);
WHILE @i<=64 BEGIN
 SET @Sql=N'CREATE TABLE dbo.'+QUOTENAME(N'SyntheticW2Cap'+CONVERT(nvarchar(3),@i))+N'(Id int NULL);';EXEC sys.sp_executesql @Sql;
 INSERT #W2Caps VALUES(@i,N'dbo',N'SyntheticW2Cap'+CONVERT(nvarchar(3),@i),N'dbo',N'SyntheticW2CapClone'+CONVERT(nvarchar(3),@i));SET @i+=1;
END;
CREATE TABLE #W2CapPlan(Dummy int);
EXEC toolbelt_metadata.USP_ScriptTableClone @TableMap=N'#W2Caps',@ResultTable=N'#W2CapPlan';
IF (SELECT COUNT(*) FROM #W2CapPlan)<>71 OR (SELECT COUNT(*) FROM #W2CapPlan WHERE ObjectKind='TABLE')<>64 THROW 54934,N'W2 Map64 oracle.',1;
INSERT #W2Caps VALUES(65,N'dbo',N'SyntheticW2Cap1',N'dbo',N'SyntheticW2CapClone65');
DECLARE @Number int,@State int;
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone @TableMap=N'#W2Caps',@ResultTable=N'#W2CapPlan'; END TRY BEGIN CATCH SELECT @Number=ERROR_NUMBER(),@State=ERROR_STATE(); END CATCH;
IF @Number IS NULL OR @Number<>53900 OR @State<>8 OR (SELECT COUNT(*) FROM #W2CapPlan)<>71 THROW 54934,N'W2 Map65 preserves plan.',2;
SET @i=1;WHILE @i<=64 BEGIN SET @Sql=N'DROP TABLE dbo.'+QUOTENAME(N'SyntheticW2Cap'+CONVERT(nvarchar(3),@i))+N';';EXEC sys.sp_executesql @Sql;SET @i+=1;END;


-- Zwei unabhängige Tabellen mit je1024 Spalten werden gemeinsam zugelassen: Spalten
-- belasten nicht die globale Objekt-/FK-Spaltentupelmenge. SQL Server verhindert eine normale
-- 1025te Spalte vor dieser API-Prüfung; kein erfundener API-Ablehnungsnachweis.
DECLARE @Columns nvarchar(max)=N'',@c int=1;
WHILE @c<=1024 BEGIN
 SET @Columns+=CASE WHEN @c=1 THEN N'' ELSE N',' END+QUOTENAME(N'C'+CONVERT(nvarchar(4),@c))+N' int NULL';SET @c+=1;
END;
SET @Sql=N'CREATE TABLE dbo.SyntheticW2ColumnsA('+@Columns+N');CREATE TABLE dbo.SyntheticW2ColumnsB('+@Columns+N');';EXEC sys.sp_executesql @Sql;
TRUNCATE TABLE #W2Caps;
INSERT #W2Caps VALUES(1,N'dbo',N'SyntheticW2ColumnsA',N'dbo',N'SyntheticW2ColumnsCloneA'),(2,N'dbo',N'SyntheticW2ColumnsB',N'dbo',N'SyntheticW2ColumnsCloneB');
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID(N'dbo.SyntheticW2ColumnsA'))<>1024
 OR (SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID(N'dbo.SyntheticW2ColumnsB'))<>1024 THROW 54934,N'W2 independent column setup.',3;
EXEC toolbelt_metadata.USP_ScriptTableClone @TableMap=N'#W2Caps',@ResultTable=N'#W2CapPlan';
IF (SELECT COUNT(*) FROM #W2CapPlan)<>9 OR (SELECT COUNT(*) FROM #W2CapPlan WHERE ObjectKind='TABLE')<>2 THROW 54934,N'W2 two1024column admission.',4;
DROP TABLE dbo.SyntheticW2ColumnsB,dbo.SyntheticW2ColumnsA;

-- Exakt2048: 2045 CHECK-Objekte + ein PK + ein FK-Objekt + dessen ein Spalten-
-- tupel. Ein FK zählt je unterschiedlicher Menge einmal, nicht zweimal als Objekt.
CREATE TABLE dbo.SyntheticW2CountA(Id int NOT NULL CONSTRAINT PK_SyntheticW2CountA PRIMARY KEY);
CREATE TABLE dbo.SyntheticW2CountB(Id int NULL,CONSTRAINT FK_SyntheticW2CountB FOREIGN KEY(Id) REFERENCES dbo.SyntheticW2CountA(Id));
SET @i=1;
WHILE @i<=2045 BEGIN
 SET @Sql=N'ALTER TABLE dbo.'+CASE WHEN @i<=1024 THEN N'SyntheticW2CountA' ELSE N'SyntheticW2CountB' END
   +N' ADD CONSTRAINT '+QUOTENAME(N'CK_SyntheticW2Count'+CONVERT(nvarchar(4),@i))+N' CHECK(Id>=0);';EXEC sys.sp_executesql @Sql;SET @i+=1;
END;
TRUNCATE TABLE #W2Caps;
INSERT #W2Caps VALUES(1,N'dbo',N'SyntheticW2CountA',N'dbo',N'SyntheticW2CountCloneA'),(2,N'dbo',N'SyntheticW2CountB',N'dbo',N'SyntheticW2CountCloneB');
IF (SELECT COUNT(*) FROM sys.objects WHERE parent_object_id IN(OBJECT_ID(N'dbo.SyntheticW2CountA'),OBJECT_ID(N'dbo.SyntheticW2CountB')))<>2047
 OR (SELECT COUNT(*) FROM sys.foreign_key_columns WHERE parent_object_id=OBJECT_ID(N'dbo.SyntheticW2CountB'))<>1 THROW 54934,N'W2 exact object/FK setup.',5;
EXEC toolbelt_metadata.USP_ScriptTableClone @TableMap=N'#W2Caps',@ResultTable=N'#W2CapPlan';
IF (SELECT COUNT(*) FROM #W2CapPlan WHERE ObjectKind='CHECK')<>2045
 OR (SELECT COUNT(*) FROM #W2CapPlan WHERE ObjectKind='PRIMARY_KEY')<>1
 OR (SELECT COUNT(*) FROM #W2CapPlan WHERE ObjectKind='FOREIGN_KEY')<>1
 OR (SELECT COUNT(*) FROM #W2CapPlan WHERE ObjectKind='FOREIGN_KEY_STATE')<>0 THROW 54934,N'W2 2048/FK-dedup admission.',6;
SELECT * INTO #W2CountPrior FROM #W2CapPlan;
ALTER TABLE dbo.SyntheticW2CountB ADD CONSTRAINT CK_SyntheticW2Count2046 CHECK(Id>=0);
SELECT @Number=NULL,@State=NULL;
BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone @TableMap=N'#W2Caps',@ResultTable=N'#W2CapPlan'; END TRY BEGIN CATCH SELECT @Number=ERROR_NUMBER(),@State=ERROR_STATE(); END CATCH;
IF @Number IS NULL OR @Number<>53906 OR @State<>1
 OR EXISTS(SELECT * FROM #W2CountPrior EXCEPT SELECT * FROM #W2CapPlan)
 OR EXISTS(SELECT * FROM #W2CapPlan EXCEPT SELECT * FROM #W2CountPrior) THROW 54934,N'W2 2049 preserves full plan.',7;
DROP TABLE dbo.SyntheticW2CountB,dbo.SyntheticW2CountA;
DROP TABLE #W2CountPrior;
PRINT N'PASS W2_CAPS';