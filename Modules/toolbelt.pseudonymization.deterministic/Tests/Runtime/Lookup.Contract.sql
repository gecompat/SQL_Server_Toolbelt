-- Synthetische Caller-Temps; keine INSERT-EXEC-Kaskade, Oracles NULL-sicher.
SET NOCOUNT ON;
CREATE TABLE #Input(Ordinal bigint NULL,[Key] varbinary(max) NULL);
CREATE TABLE #Pool(Ordinal bigint NULL,[Value] nvarchar(max) NULL);
CREATE TABLE #Result(Dummy int);
INSERT #Input VALUES(10,0x010203),(30,NULL),(90,0x010203);
INSERT #Pool VALUES(20,N'synthetic alpha'),(80,N'synthetic beta');
EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#Input',@LookupTable=N'#Pool',@MappingVersion=1,@LookupVersion=1,@ResultTable=N'#Result';
IF (SELECT COUNT_BIG(*) FROM #Result)<>3
    THROW 54090,N'Lookup: Ergebniszeilenanzahl verletzt.',1;
IF NOT EXISTS(SELECT 1 FROM #Result WHERE InputOrdinal=30 AND LookupOrdinal IS NULL AND Value IS NULL)
    THROW 54090,N'Lookup: NULL-Key-Zuordnung verletzt.',1;
IF EXISTS(SELECT 1 FROM #Result WHERE InputOrdinal IN(10,90) AND (LookupOrdinal IS NULL OR Value IS NULL))
    OR NOT EXISTS(SELECT 1 FROM #Result a JOIN #Result b ON a.InputOrdinal=10 AND b.InputOrdinal=90 AND a.LookupOrdinal=b.LookupOrdinal AND CONVERT(varbinary(max),a.Value)=CONVERT(varbinary(max),b.Value))
    THROW 54090,N'Lookup: gleiche Keys oder Poolzuordnung verletzt.',1;
-- Unabhängiger Python-SHA256-Vektor des dokumentierten Lookupdomain-Frames:
-- Kontext1, Key010203, Version1, Seed0, Positionen1..2 -> Position2/Ordinal80.
IF NOT EXISTS(SELECT 1 FROM #Result WHERE InputOrdinal=10 AND LookupOrdinal=80
    AND CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N'synthetic beta'))
    THROW 54090,N'Lookup: unabhängiger Lookupdomain-/Poolreihenfolgevektor verletzt.',1;
DECLARE @BeforeOrdinal bigint=(SELECT LookupOrdinal FROM #Result WHERE InputOrdinal=10);
-- Physische Reihenfolge ändern; gleiche explizite Ordinals erhalten Mapping.
TRUNCATE TABLE #Pool;
INSERT #Pool VALUES(80,N'synthetic beta'),(20,N'synthetic alpha');
EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#Input',@LookupTable=N'#Pool',@MappingVersion=1,@LookupVersion=1,@ResultTable=N'#Result',@KeepData=0;
IF @BeforeOrdinal IS NULL OR NOT EXISTS(SELECT 1 FROM #Result WHERE InputOrdinal=10 AND LookupOrdinal=@BeforeOrdinal)
    THROW 54090,N'Lookup: physische Poolreihenfolge beeinflusst Mapping.',1;
EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#Input',@LookupTable=N'#Pool',@MappingVersion=1,@LookupVersion=1,@ResultTable=N'#Result',@KeepData=1;
IF (SELECT COUNT_BIG(*) FROM #Result)<>6 THROW 54090,N'Lookup: passendes Append verletzt.',1;
EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#Input',@LookupTable=N'#Pool',@MappingVersion=1,@LookupVersion=1,@ResultTable=N'#Result',@KeepData=NULL;
IF (SELECT COUNT_BIG(*) FROM #Result)<>3 THROW 54090,N'Lookup: NULL-KeepData-Replace verletzt.',1;
DECLARE @Caught int=0;
BEGIN TRY
    EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#Input',@LookupTable=N'#Pool',@MappingVersion=1,@LookupVersion=1,@MaxInputRows=2,@ResultTable=N'#Result';
END TRY BEGIN CATCH SET @Caught=ERROR_NUMBER(); END CATCH;
IF @Caught<>54001 OR (SELECT COUNT_BIG(*) FROM #Result)<>3
    THROW 54090,N'Lookup: Rowlimit muss vor Zielmutation scheitern.',1;
SET @Caught=0;
BEGIN TRY
    EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#Input',@LookupTable=N'#Pool',@MappingVersion=1,@LookupVersion=1,@MaxResultBytes=1,@ResultTable=N'#Result';
END TRY BEGIN CATCH SET @Caught=ERROR_NUMBER(); END CATCH;
IF @Caught<>54006 OR (SELECT COUNT_BIG(*) FROM #Result)<>3
    THROW 54090,N'Lookup: Ergebnisbudget muss vor Zielmutation scheitern.',1;
INSERT #Input VALUES(10,0xAA);
SET @Caught=0;
BEGIN TRY
    EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#Input',@LookupTable=N'#Pool',@MappingVersion=1,@LookupVersion=1,@ResultTable=N'#Result';
END TRY BEGIN CATCH SET @Caught=ERROR_NUMBER(); END CATCH;
IF @Caught<>54003 OR (SELECT COUNT_BIG(*) FROM #Result)<>3
    THROW 54090,N'Lookup: doppelte Ordinals müssen Ziel erhalten.',1;
DELETE #Input WHERE [Key]=0xAA;
INSERT #Input VALUES(110,0x);
SET @Caught=0;
BEGIN TRY
    EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#Input',@LookupTable=N'#Pool',@MappingVersion=1,@LookupVersion=1,@ResultTable=N'#Result';
END TRY BEGIN CATCH SET @Caught=ERROR_NUMBER(); END CATCH;
IF @Caught<>54004 OR (SELECT COUNT_BIG(*) FROM #Result)<>3
    THROW 54090,N'Lookup: ungültiger Key muss Ziel erhalten.',1;
DELETE #Input WHERE Ordinal=110;
TRUNCATE TABLE #Pool;
SET @Caught=0;
BEGIN TRY
    EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#Input',@LookupTable=N'#Pool',@MappingVersion=1,@LookupVersion=1,@ResultTable=N'#Result';
END TRY BEGIN CATCH SET @Caught=ERROR_NUMBER(); END CATCH;
IF @Caught<>54005 OR (SELECT COUNT_BIG(*) FROM #Result)<>3
    THROW 54090,N'Lookup: leerer Pool muss Ziel erhalten.',1;
INSERT #Pool VALUES(77,NULL);
EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#Input',@LookupTable=N'#Pool',@MappingVersion=1,@LookupVersion=1,@ResultTable=N'#Result';
IF (SELECT COUNT_BIG(*) FROM #Result)<>3 OR EXISTS(SELECT 1 FROM #Result WHERE Value IS NOT NULL)
    OR NOT EXISTS(SELECT 1 FROM #Result WHERE InputOrdinal=10 AND LookupOrdinal=77)
    THROW 54090,N'Lookup: NULL-Poolwert ist nicht NULL-Key.',1;
TRUNCATE TABLE #Input;
EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#Input',@LookupTable=N'#Pool',@MappingVersion=1,@LookupVersion=1,@ResultTable=N'#Result';
IF EXISTS(SELECT 1 FROM #Result) THROW 54090,N'Lookup: leerer Input muss Replace leeren.',1;
INSERT #Input VALUES(10,0x01);
INSERT #Pool VALUES(90,N'last');
BEGIN TRANSACTION;
DECLARE @BeforeCount int=@@TRANCOUNT;
EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#Input',@LookupTable=N'#Pool',@MappingVersion=1,@LookupVersion=1,@ResultTable=N'#Result';
IF @@TRANCOUNT<>@BeforeCount OR XACT_STATE()<>1 OR (SELECT COUNT_BIG(*) FROM #Result)<>1
    THROW 54090,N'Lookup: Callertransaktion oder Erfolg verletzt.',1;
ROLLBACK TRANSACTION;
IF @@TRANCOUNT<>0 OR EXISTS(SELECT 1 FROM #Result)
    THROW 54090,N'Lookup: Callerrollback muss eigene Callerarbeit rückgängig machen.',1;
DECLARE @ResultColumns TABLE (Ordinal int,ColumnName sysname,TypeId int,MaxLength int,IsNullable bit,CollationName sysname NULL);
INSERT @ResultColumns SELECT ROW_NUMBER() OVER(ORDER BY column_id),name,system_type_id,max_length,is_nullable,collation_name
FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#Result');
IF (SELECT COUNT(*) FROM @ResultColumns)<>3
    OR NOT EXISTS(SELECT 1 FROM @ResultColumns WHERE Ordinal=1 AND ColumnName=N'InputOrdinal' AND TypeId=127 AND IsNullable=0)
    OR NOT EXISTS(SELECT 1 FROM @ResultColumns WHERE Ordinal=2 AND ColumnName=N'LookupOrdinal' AND TypeId=127 AND IsNullable=1)
    OR NOT EXISTS(SELECT 1 FROM @ResultColumns WHERE Ordinal=3 AND ColumnName=N'Value' AND TypeId=231 AND MaxLength=-1 AND IsNullable=1 AND CollationName=N'Latin1_General_100_BIN2')
    THROW 54090,N'Lookup: ResultTable-Metadaten verletzt.',1;
PRINT N'PASS: Lookup synthetischer Vertrag';
GO
