-- Synthetische Vertragsfixture; gleiche Verbindung über GO. Kein Produkthelper.
CREATE PROCEDURE #ExecuteReferenceHash
    @MapMode bit,@ForeignKeyMode varchar(16),@Hash varbinary(32) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    -- Separate Feldfolgenreferenz für das dokumentierte Protokoll.
    DECLARE @Frames TABLE(Position int IDENTITY(1,1),Bytes varbinary(max) NOT NULL);
    INSERT @Frames VALUES(CONVERT(binary(4),DATALENGTH(N'Toolbelt.TableClone.Execute.Hash'))+CONVERT(varbinary(max),N'Toolbelt.TableClone.Execute.Hash')),
        (CONVERT(binary(4),CONVERT(int,1))),
        (CONVERT(binary(4),DATALENGTH(N'4.0.0'))+CONVERT(varbinary(max),N'4.0.0')),
        (CONVERT(binary(4),DB_ID())),
        (CONVERT(binary(4),DATALENGTH(DB_NAME()))+CONVERT(varbinary(max),DB_NAME())),
        (CONVERT(varbinary(max),0x0000)+CONVERT(binary(1),@MapMode)),
        (CONVERT(binary(4),CONVERT(int,12))+CONVERT(varbinary(max),N'REJECT')),
        (CONVERT(binary(4),DATALENGTH(CONVERT(nvarchar(max),@ForeignKeyMode)))+CONVERT(varbinary(max),CONVERT(nvarchar(max),@ForeignKeyMode))),
        (CONVERT(binary(4),(SELECT COUNT(*) FROM #ExecuteReferenceMap)));
    DECLARE @Ordinal int,@S nvarchar(max),@T nvarchar(max),@DS nvarchar(max),@DT nvarchar(max);
    DECLARE MapFrames CURSOR LOCAL FAST_FORWARD FOR SELECT MapOrdinal,SourceSchema,SourceTable,TargetSchema,TargetTable FROM #ExecuteReferenceMap ORDER BY MapOrdinal;
    OPEN MapFrames; FETCH NEXT FROM MapFrames INTO @Ordinal,@S,@T,@DS,@DT;
    WHILE @@FETCH_STATUS=0
    BEGIN
        INSERT @Frames VALUES(CONVERT(binary(4),@Ordinal)),
            (CONVERT(binary(4),DATALENGTH(@S))+CONVERT(varbinary(max),@S)),
            (CONVERT(binary(4),DATALENGTH(@T))+CONVERT(varbinary(max),@T)),
            (CONVERT(binary(4),DATALENGTH(@DS))+CONVERT(varbinary(max),@DS)),
            (CONVERT(binary(4),DATALENGTH(@DT))+CONVERT(varbinary(max),@DT));
        FETCH NEXT FROM MapFrames INTO @Ordinal,@S,@T,@DS,@DT;
    END;
    CLOSE MapFrames; DEALLOCATE MapFrames;
    DECLARE @Header varbinary(max)=0x,@Bytes varbinary(max),@Position int=1;
    WHILE @Position<=(SELECT COUNT(*) FROM @Frames)
    BEGIN
        SELECT @Bytes=Bytes FROM @Frames WHERE Position=@Position;
        SET @Header=@Header+@Bytes; SET @Position+=1;
    END;
    SET @Hash=HASHBYTES('SHA2_256',@Header);
    DECLARE PlanFrames CURSOR LOCAL FAST_FORWARD FOR SELECT Ordinal,CONVERT(nvarchar(max),ObjectKind),TargetName,ScriptText FROM #ExecuteReferencePlan ORDER BY Ordinal;
    OPEN PlanFrames; FETCH NEXT FROM PlanFrames INTO @Ordinal,@S,@T,@DS;
    WHILE @@FETCH_STATUS=0
    BEGIN
        SET @Hash=HASHBYTES('SHA2_256',CONVERT(varbinary(max),@Hash)+CONVERT(binary(4),@Ordinal)
            +CONVERT(binary(4),DATALENGTH(@S))+CONVERT(varbinary(max),@S)
            +CONVERT(binary(4),DATALENGTH(@T))+CONVERT(varbinary(max),@T)
            +CONVERT(binary(4),DATALENGTH(@DS))+CONVERT(varbinary(max),@DS));
        FETCH NEXT FROM PlanFrames INTO @Ordinal,@S,@T,@DS;
    END;
    CLOSE PlanFrames; DEALLOCATE PlanFrames;
    SET @Hash=HASHBYTES('SHA2_256',CONVERT(varbinary(max),@Hash)+CONVERT(binary(4),(SELECT COUNT(*) FROM #ExecuteReferencePlan))
        +CONVERT(binary(4),DATALENGTH(N'Toolbelt.TableClone.Execute.Final'))+CONVERT(varbinary(max),N'Toolbelt.TableClone.Execute.Final'));
END;
GO
SET NOCOUNT ON;
CREATE TABLE dbo.SyntheticExecuteSource(Id int NOT NULL,Payload nvarchar(30) NULL,
    CONSTRAINT CK_SyntheticExecuteSource CHECK(Id>=0));
CREATE TABLE #ExecuteReferenceMap(MapOrdinal int NOT NULL,SourceSchema nvarchar(max) NOT NULL,
    SourceTable nvarchar(max) NOT NULL,TargetSchema nvarchar(max) NOT NULL,TargetTable nvarchar(max) NOT NULL);
CREATE TABLE #ExecuteReferencePlan(Ordinal int NOT NULL,ObjectKind varchar(32) NOT NULL,TargetName nvarchar(776) NOT NULL,ScriptText nvarchar(max) NOT NULL);
CREATE TABLE #ExecuteResult(PlanHash varbinary(32) NOT NULL,TablesCreated int NOT NULL,StatementsExecuted int NOT NULL);
INSERT #ExecuteReferenceMap VALUES(1,N'dbo',N'SyntheticExecuteSource',N'dbo',N'SyntheticExecuteClone');
EXEC toolbelt_metadata.USP_ScriptTableClone @SourceSchema=N'dbo',@SourceTable=N'SyntheticExecuteSource',
    @TargetSchema=N'dbo',@TargetTable=N'SyntheticExecuteClone',@ResultTable=N'#ExecuteReferencePlan';
DECLARE @Hash varbinary(32),@MapHash varbinary(32),@OriginalOptions int=@@OPTIONS;
EXEC #ExecuteReferenceHash @MapMode=0,@ForeignKeyMode='CREATE',@Hash=@Hash OUTPUT;
EXEC #ExecuteReferenceHash @MapMode=1,@ForeignKeyMode='CREATE',@Hash=@MapHash OUTPUT;
IF @Hash=@MapHash THROW 54940,N'Single/map hash modes collapsed.',1;
-- Der Executor muss einen relevanten DDL-Trigger vor dessen Auslösung ablehnen.
EXEC sys.sp_executesql N'CREATE TRIGGER SyntheticExecuteDdlBlock ON DATABASE FOR CREATE_TABLE AS THROW 54942,N''Synthetic DDL trigger fired.'',1;';
DECLARE @GateError int=0;
BEGIN TRY
    EXEC toolbelt_metadata.USP_ExecuteTableClone @SourceSchema=N'dbo',@SourceTable=N'SyntheticExecuteSource',
        @TargetSchema=N'dbo',@TargetTable=N'SyntheticExecuteClone',@ExpectedPlanHash=@Hash;
END TRY
BEGIN CATCH SET @GateError=ERROR_NUMBER(); IF @GateError<>53933 THROW; END CATCH;
DROP TRIGGER SyntheticExecuteDdlBlock ON DATABASE;
IF @GateError<>53933 OR OBJECT_ID(N'dbo.SyntheticExecuteClone') IS NOT NULL OR @@TRANCOUNT<>0
    THROW 54940,N'DDL side effect gate failed.',7;
EXEC toolbelt_metadata.USP_ExecuteTableClone @SourceSchema=N'dbo',@SourceTable=N'SyntheticExecuteSource',
    @TargetSchema=N'dbo',@TargetTable=N'SyntheticExecuteClone',@ExpectedPlanHash=@Hash,@ResultTable=N'#ExecuteResult';
DECLARE @ObservedTC int,@ObservedXS int,@ObservedOptions int;
SET @ObservedTC=@@TRANCOUNT;
SET @ObservedXS=XACT_STATE();
SET @ObservedOptions=@@OPTIONS;
IF @ObservedTC<>0 THROW 54940,N'Executor transaction count contract failed.',20;
IF @ObservedXS<>0 THROW 54940,N'Executor transaction state contract failed.',21;
IF @ObservedOptions<>@OriginalOptions THROW 54940,N'Executor SET contract failed.',22;
IF OBJECT_ID(N'dbo.SyntheticExecuteClone',N'U') IS NULL THROW 54940,N'Executor target contract failed.',23;
IF (SELECT COUNT(*) FROM #ExecuteResult)<>1 THROW 54940,N'Executor result row count contract failed.',24;
IF NOT EXISTS(SELECT 1 FROM #ExecuteResult WHERE PlanHash=@Hash AND TablesCreated=1
        AND StatementsExecuted=(SELECT COUNT(*) FROM #ExecuteReferencePlan WHERE ObjectKind<>'SESSION_OPTION'))
    THROW 54940,N'Executor hash/counts contract failed.',25;
IF NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'dbo.SyntheticExecuteClone') AND is_disabled=0 AND is_not_trusted=0)
    THROW 54940,N'Executor check state contract failed.',26;

DROP TABLE dbo.SyntheticExecuteClone;
-- Gleicher gültiger Hash, absichtlich fehlerhaftes Ausgabe-INSERT: Ziel-DDL zurückrollen.
ALTER TABLE #ExecuteResult WITH NOCHECK ADD CONSTRAINT CK_ExecuteLateOutput CHECK(TablesCreated=0);
DECLARE @Number int=0;
BEGIN TRY
    EXEC toolbelt_metadata.USP_ExecuteTableClone @SourceSchema=N'dbo',@SourceTable=N'SyntheticExecuteSource',
        @TargetSchema=N'dbo',@TargetTable=N'SyntheticExecuteClone',@ExpectedPlanHash=@Hash,@ResultTable=N'#ExecuteResult',@KeepData=1;
END TRY
BEGIN CATCH SET @Number=ERROR_NUMBER(); END CATCH;
SET @ObservedTC=@@TRANCOUNT; SET @ObservedXS=XACT_STATE(); SET @ObservedOptions=@@OPTIONS;
IF @Number<>547 OR @ObservedTC<>0 OR @ObservedXS<>0 OR OBJECT_ID(N'dbo.SyntheticExecuteClone') IS NOT NULL
    OR (SELECT COUNT(*) FROM #ExecuteResult)<>1 OR @ObservedOptions<>@OriginalOptions
    THROW 54940,N'Late ResultTable failure failed own-DDL rollback.',3;
DROP TABLE #ExecuteResult;
DROP TABLE dbo.SyntheticExecuteSource;

-- Map/zyklische/Self-FKs: nur FK und Zustand aufschieben; vollständige Pläne hashgebunden.
CREATE TABLE dbo.SyntheticExecuteA(Id int NOT NULL PRIMARY KEY,BId int NULL);
CREATE TABLE dbo.SyntheticExecuteB(Id int NOT NULL PRIMARY KEY,AId int NULL);
ALTER TABLE dbo.SyntheticExecuteA ADD CONSTRAINT FK_SyntheticExecuteAB FOREIGN KEY(BId) REFERENCES dbo.SyntheticExecuteB(Id);
ALTER TABLE dbo.SyntheticExecuteB ADD CONSTRAINT FK_SyntheticExecuteBA FOREIGN KEY(AId) REFERENCES dbo.SyntheticExecuteA(Id);
ALTER TABLE dbo.SyntheticExecuteA ADD CONSTRAINT FK_SyntheticExecuteAA FOREIGN KEY(Id) REFERENCES dbo.SyntheticExecuteA(Id);
TRUNCATE TABLE #ExecuteReferenceMap;
INSERT #ExecuteReferenceMap VALUES(2,N'dbo',N'SyntheticExecuteA',N'dbo',N'SyntheticExecuteAClone'),
    (7,N'dbo',N'SyntheticExecuteB',N'dbo',N'SyntheticExecuteBClone');
EXEC toolbelt_metadata.USP_ScriptTableClone @TableMap=N'#ExecuteReferenceMap',@ResultTable=N'#ExecuteReferencePlan';
EXEC #ExecuteReferenceHash @MapMode=1,@ForeignKeyMode='DEFER',@Hash=@Hash OUTPUT;
EXEC #ExecuteReferenceHash @MapMode=1,@ForeignKeyMode='CREATE',@Hash=@MapHash OUTPUT;
IF @Hash=@MapHash OR (SELECT COUNT(*) FROM #ExecuteReferencePlan WHERE ObjectKind='FOREIGN_KEY')<>3
    THROW 54940,N'FK mode/hash/source fixture failed.',4;
EXEC toolbelt_metadata.USP_ExecuteTableClone @TableMap=N'#ExecuteReferenceMap',@ExpectedPlanHash=@Hash,@ForeignKeyMode='DEFER';
IF (SELECT COUNT(*) FROM sys.tables WHERE name IN(N'SyntheticExecuteAClone',N'SyntheticExecuteBClone'))<>2
    OR EXISTS(SELECT 1 FROM sys.foreign_keys WHERE parent_object_id IN(OBJECT_ID(N'dbo.SyntheticExecuteAClone'),OBJECT_ID(N'dbo.SyntheticExecuteBClone')))
    THROW 54940,N'DEFER did not create only FK-free target structures.',5;
DROP TABLE dbo.SyntheticExecuteAClone,dbo.SyntheticExecuteBClone;
EXEC toolbelt_metadata.USP_ExecuteTableClone @TableMap=N'#ExecuteReferenceMap',@ExpectedPlanHash=@MapHash,@ForeignKeyMode='CREATE';
SET @ObservedTC=@@TRANCOUNT; SET @ObservedXS=XACT_STATE(); SET @ObservedOptions=@@OPTIONS;
IF (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id IN(OBJECT_ID(N'dbo.SyntheticExecuteAClone'),OBJECT_ID(N'dbo.SyntheticExecuteBClone')))<>3
    OR @ObservedTC<>0 OR @ObservedXS<>0 OR @ObservedOptions<>@OriginalOptions
    THROW 54940,N'CREATE did not install cyclic/self foreign keys.',6;
-- Nur belegte eigene FK-Objekte entfernen, dann die exakten synthetischen Tabellen.
DECLARE @DropSql nvarchar(max)=N'';
SELECT @DropSql=STRING_AGG(CONVERT(nvarchar(max),N'ALTER TABLE '+QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id))+N'.'+QUOTENAME(OBJECT_NAME(parent_object_id))
    +N' DROP CONSTRAINT '+QUOTENAME(name)+N';'),NCHAR(10)) WITHIN GROUP(ORDER BY object_id)
FROM sys.foreign_keys WHERE parent_object_id IN(OBJECT_ID(N'dbo.SyntheticExecuteAClone'),OBJECT_ID(N'dbo.SyntheticExecuteBClone'),OBJECT_ID(N'dbo.SyntheticExecuteA'),OBJECT_ID(N'dbo.SyntheticExecuteB'));
EXEC sys.sp_executesql @DropSql;
DROP TABLE dbo.SyntheticExecuteAClone,dbo.SyntheticExecuteBClone,dbo.SyntheticExecuteA,dbo.SyntheticExecuteB;
-- Eine UDF-Dependency im DEFAULT ist durch diese Fassade nicht ausführbar.
EXEC sys.sp_executesql N'CREATE FUNCTION dbo.SyntheticExecuteDefault() RETURNS int AS BEGIN RETURN 1; END;';
CREATE TABLE dbo.SyntheticExecuteExpression(Id int NULL CONSTRAINT DF_SyntheticExecuteExpression DEFAULT dbo.SyntheticExecuteDefault());
TRUNCATE TABLE #ExecuteReferenceMap;
INSERT #ExecuteReferenceMap VALUES(1,N'dbo',N'SyntheticExecuteExpression',N'dbo',N'SyntheticExecuteExpressionClone');
EXEC toolbelt_metadata.USP_ScriptTableClone @SourceSchema=N'dbo',@SourceTable=N'SyntheticExecuteExpression',
    @TargetSchema=N'dbo',@TargetTable=N'SyntheticExecuteExpressionClone',@ResultTable=N'#ExecuteReferencePlan';
EXEC #ExecuteReferenceHash @MapMode=0,@ForeignKeyMode='CREATE',@Hash=@Hash OUTPUT;
SET @GateError=0;
BEGIN TRY
    EXEC toolbelt_metadata.USP_ExecuteTableClone @SourceSchema=N'dbo',@SourceTable=N'SyntheticExecuteExpression',
        @TargetSchema=N'dbo',@TargetTable=N'SyntheticExecuteExpressionClone',@ExpectedPlanHash=@Hash;
END TRY
BEGIN CATCH SET @GateError=ERROR_NUMBER(); END CATCH;
IF @GateError<>53935 OR OBJECT_ID(N'dbo.SyntheticExecuteExpressionClone') IS NOT NULL OR @@TRANCOUNT<>0
    THROW 54940,N'DEFAULT execution dependency gate failed.',8;
DROP TABLE dbo.SyntheticExecuteExpression;
DROP FUNCTION dbo.SyntheticExecuteDefault;
DROP TABLE #ExecuteReferencePlan,#ExecuteReferenceMap;
DROP PROCEDURE #ExecuteReferenceHash;
PRINT N'PASS TABLE_CLONE_EXECUTE_CONTRACT';
GO
