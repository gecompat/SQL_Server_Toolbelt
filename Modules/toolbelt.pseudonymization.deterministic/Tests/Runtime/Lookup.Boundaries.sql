-- Fachliche Fehler müssen vor ResultTable-Mutation kommen; kleine synthetische
-- Grenzen statt nicht qualifiziertem Durchsatzbenchmark. Caller-Temps gehören Test.
SET NOCOUNT ON;
CREATE TABLE #Input(Ordinal bigint NULL,[Key] varbinary(max) NULL);
CREATE TABLE #Pool(Ordinal bigint NULL,[Value] nvarchar(max) NULL);
CREATE TABLE #Result(Dummy int);
INSERT #Input VALUES(10,0x010203);
INSERT #Pool VALUES(20,N'A  ');
INSERT #Result VALUES(71);
DECLARE @Cases TABLE(Ordinal int,Arguments nvarchar(max),Expected int,ExpectedState int);
INSERT @Cases VALUES
(1,N'@MappingVersion=0,@LookupVersion=0,@InputTable=N''missing'',@MaxInputRows=0',54000,1),
(2,N'@MappingVersion=1,@LookupVersion=1,@Seed=NULL',54000,1),
(3,N'@MappingVersion=1,@LookupVersion=1,@MaxInputRows=0',54001,1),
(4,N'@MappingVersion=1,@LookupVersion=1,@MaxLookupRows=100001',54001,1),
(5,N'@MappingVersion=1,@LookupVersion=1,@MaxLookupTextBytes=NULL',54001,1),
(6,N'@MappingVersion=1,@LookupVersion=1,@MaxResultBytes=16777217',54001,1);
DECLARE @Ordinal int=1,@Args nvarchar(max),@Expected int,@State int,@Caught int,@CaughtState int,@Sql nvarchar(max);
WHILE @Ordinal<=6
BEGIN
    SELECT @Args=Arguments,@Expected=Expected,@State=ExpectedState FROM @Cases WHERE Ordinal=@Ordinal;
    SET @Sql=N'EXEC toolbelt_pseudonymization.USP_DeterministicLookup @LookupTable=N''#Pool'',@ResultTable=N''#Result'','+@Args+N';';
    SET @Caught=0; SET @CaughtState=0;
    BEGIN TRY EXEC sys.sp_executesql @Sql; END TRY
    BEGIN CATCH SELECT @Caught=ERROR_NUMBER(),@CaughtState=ERROR_STATE(); END CATCH;
    IF @Caught<>@Expected OR @CaughtState<>@State OR @@TRANCOUNT<>0
        OR (SELECT COUNT_BIG(*) FROM #Result)<>1 OR NOT EXISTS(SELECT 1 FROM #Result WHERE Dummy=71)
        THROW 54090,N'Lookup: Konfigurationspriorität, exakte Fehlersignatur oder Zielatomarität verletzt.',1;
    SET @Ordinal+=1;
END;
-- Teilweise gefüllte schemafremde Tabelle: Append darf nicht umbauen/löschen.
SET @Caught=0;
BEGIN TRY EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#Input',@LookupTable=N'#Pool',@MappingVersion=1,@LookupVersion=1,@ResultTable=N'#Result',@KeepData=1; END TRY
BEGIN CATCH SET @Caught=ERROR_NUMBER(); END CATCH;
IF @Caught<>51025 OR (SELECT COUNT_BIG(*) FROM #Result)<>1 OR NOT EXISTS(SELECT 1 FROM #Result WHERE Dummy=71) OR @@TRANCOUNT<>0
    THROW 54090,N'Lookup: befülltes schemafremdes Append muss atomar scheitern.',1;
-- Replace muss denselben Zustand ausdrücklich anpassen und trailing Spaces erhalten.
EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#Input',@LookupTable=N'#Pool',@MappingVersion=1,@LookupVersion=1,@ResultTable=N'#Result',@KeepData=0;
IF (SELECT COUNT_BIG(*) FROM #Result)<>1 OR NOT EXISTS(SELECT 1 FROM #Result WHERE InputOrdinal=10 AND LookupOrdinal=20 AND DATALENGTH(Value)=6 AND CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N'A  '))
    THROW 54090,N'Lookup: befülltes schemafremdes Replace oder Textbytes verletzt.',1;
CREATE INDEX IX_Synthetic_Result ON #Result(InputOrdinal);
EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#Input',@LookupTable=N'#Pool',@MappingVersion=1,@LookupVersion=1,@ResultTable=N'#Result',@KeepData=1;
IF (SELECT COUNT_BIG(*) FROM #Result)<>2 OR NOT EXISTS(SELECT 1 FROM tempdb.sys.indexes WHERE object_id=OBJECT_ID(N'tempdb..#Result') AND name=N'IX_Synthetic_Result')
    THROW 54090,N'Lookup: Append muss passenden Index bewahren.',1;
-- Fachlicher Fehler innerhalb einer Callertransaktion: Savepoint, kein Targettouch.
BEGIN TRANSACTION;
DECLARE @BeforeTran int=@@TRANCOUNT;
UPDATE #Input SET [Key]=CONVERT(varbinary(max),REPLICATE(CONVERT(varchar(max),'x'),8001));
SET @Caught=0; SET @CaughtState=0;
BEGIN TRY EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#Input',@LookupTable=N'#Pool',@MappingVersion=1,@LookupVersion=1,@ResultTable=N'#Result'; END TRY
BEGIN CATCH SELECT @Caught=ERROR_NUMBER(),@CaughtState=ERROR_STATE(); END CATCH;
IF @Caught<>54004 OR @CaughtState<>1 OR @@TRANCOUNT<>@BeforeTran OR XACT_STATE()<>1 OR (SELECT COUNT_BIG(*) FROM #Result)<>2
    THROW 54090,N'Lookup: fachlicher Callerfehler/Savepoint verletzt.',1;
ROLLBACK TRANSACTION;
-- 8000 Bytes sind gültig; 8001 wurde oben ohne Keykopie abgewiesen.
UPDATE #Input SET [Key]=CONVERT(varbinary(max),REPLICATE(CONVERT(varchar(max),'x'),8000));
EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#Input',@LookupTable=N'#Pool',@MappingVersion=1,@LookupVersion=1,@ResultTable=N'#Result';
IF (SELECT COUNT_BIG(*) FROM #Result)<>1 OR NOT EXISTS(SELECT 1 FROM #Result WHERE LookupOrdinal=20)
    THROW 54090,N'Lookup: 8000-Byte-Key wurde nicht vollständig verarbeitet.',1;
-- Exaktes Poolbudget6 Bytes und Ergebnisbudget6 Bytes bestehen; Budget5 scheitert.
EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#Input',@LookupTable=N'#Pool',@MappingVersion=1,@LookupVersion=1,@MaxLookupTextBytes=6,@MaxResultBytes=6,@ResultTable=N'#Result';
SET @Caught=0; SET @CaughtState=0;
BEGIN TRY EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#Input',@LookupTable=N'#Pool',@MappingVersion=1,@LookupVersion=1,@MaxLookupTextBytes=5,@ResultTable=N'#Result'; END TRY
BEGIN CATCH SELECT @Caught=ERROR_NUMBER(),@CaughtState=ERROR_STATE(); END CATCH;
IF @Caught<>54006 OR @CaughtState<>1 OR (SELECT COUNT_BIG(*) FROM #Result)<>1
    THROW 54090,N'Lookup: exaktes Poolbudget verletzt.',1;
-- Tatsächlicher Insertfehler unter passendem Schema: Replace wird zurückgerollt.
CREATE UNIQUE INDEX UQ_Synthetic_Result ON #Result(InputOrdinal);
INSERT #Input VALUES(30,0x02);
ALTER TABLE #Result ADD CHECK (InputOrdinal=10);
SET @Caught=0;
BEGIN TRY EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#Input',@LookupTable=N'#Pool',@MappingVersion=1,@LookupVersion=1,@ResultTable=N'#Result'; END TRY
BEGIN CATCH SET @Caught=ERROR_NUMBER(); END CATCH;
IF @Caught<>547 OR @@TRANCOUNT<>0 OR (SELECT COUNT_BIG(*) FROM #Result)<>1 OR NOT EXISTS(SELECT 1 FROM #Result WHERE InputOrdinal=10 AND LookupOrdinal=20)
    THROW 54090,N'Lookup: Engineconstraintfehler muss Originalnummer/Ziel erhalten.',1;
PRINT N'PASS: Lookup kleine Grenzen, ResultTable-Konstellationen und Fehleratomarität';
GO
