-- Installierter Lifecycle-/USP-Vertrag; ausführende Deployment-/AppLock-/Uninstallfälle sind separate Adaptergruppen.
SET NOCOUNT ON;
IF (SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_file') AND name IN(N'USP_ParseCsv',N'USP_WriteCsv',N'TVF_InternalParseCsv',N'SVF_InternalMeasureCsvCell',N'SVF_InternalQuoteCsvCell'))<>5
 OR (SELECT COUNT(*) FROM sys.assembly_modules m JOIN sys.assemblies a ON a.assembly_id=m.assembly_id WHERE a.name=N'Toolbelt_File_CsvMemory')<>3
 OR NOT EXISTS(SELECT 1 FROM sys.assemblies WHERE name=N'Toolbelt_File_CsvMemory' AND permission_set=1)
 THROW 55392,N'CSV lifecycle: Slots oder SAFE-Bindungen fehlen.',1;
IF (SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_file.USP_ParseCsv') AND parameter_id>0)<>12
 OR (SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_file.USP_WriteCsv') AND parameter_id>0)<>14
 THROW 55392,N'CSV lifecycle: öffentliche Parameterzahl weicht ab.',2;
DECLARE @Tail TABLE(Name sysname NOT NULL,OffsetFromEnd int NOT NULL);
INSERT @Tail VALUES(N'@ResultTable',3),(N'@KeepData',2),(N'@Debug',1),(N'@Hilfe',0);
IF EXISTS(SELECT 1 FROM @Tail t CROSS JOIN(VALUES(N'USP_ParseCsv',12),(N'USP_WriteCsv',14)) o(Name,Count)
 WHERE NOT EXISTS(SELECT 1 FROM sys.parameters p WHERE p.object_id=OBJECT_ID(N'toolbelt_file.'+o.Name) AND p.parameter_id=o.Count-t.OffsetFromEnd AND p.name=t.Name))
 THROW 55392,N'CSV lifecycle: Standardtail weicht ab.',3;
-- Zielconstraintfehler bewahrt ursprüngliche Werte in einer gesunden Callertransaktion.
CREATE TABLE #CsvLifecycleTarget(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL CHECK([Value]<>N'bad'));
INSERT #CsvLifecycleTarget VALUES('DATA',1,1,N'original');
DECLARE @BeforeXactAbort bit=CASE WHEN (@@OPTIONS&16384)=16384 THEN 1 ELSE 0 END,@Caught bit=0;
SET XACT_ABORT OFF;
BEGIN TRANSACTION;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=N'bad',@ResultTable=N'#CsvLifecycleTarget'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>547 BEGIN IF XACT_STATE()<>0 ROLLBACK; IF @BeforeXactAbort=1 SET XACT_ABORT ON; THROW; END; SET @Caught=1; END CATCH;
IF @Caught=0 OR XACT_STATE()<>1 OR @@TRANCOUNT<>1 OR NOT EXISTS(SELECT 1 FROM #CsvLifecycleTarget WHERE [Value]=N'original') OR (SELECT COUNT(*) FROM #CsvLifecycleTarget)<>1
BEGIN IF XACT_STATE()<>0 ROLLBACK; IF @BeforeXactAbort=1 SET XACT_ABORT ON; THROW 55392,N'CSV lifecycle: Caller-Savepoint oder Zielerhalt fehlt.',4; END;
ROLLBACK;
IF @BeforeXactAbort=1 SET XACT_ABORT ON;
-- Der Caller erzeugt hier absichtlich einen doomed Zustand; beide USPs dürfen ihn nicht zurückrollen.
CREATE TABLE #CsvLifecycleDoomProbe(Value int CHECK(Value>0));
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY INSERT #CsvLifecycleDoomProbe VALUES(0); END TRY
BEGIN CATCH IF ERROR_NUMBER()<>547 BEGIN IF XACT_STATE()<>0 ROLLBACK; IF @BeforeXactAbort=0 SET XACT_ABORT OFF; THROW; END; END CATCH;
IF XACT_STATE()<>-1 BEGIN IF XACT_STATE()<>0 ROLLBACK; IF @BeforeXactAbort=0 SET XACT_ABORT OFF; THROW 55392,N'CSV lifecycle: doomed Vorzustand fehlt.',6; END;
SET @Caught=0;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=N'x'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55309 BEGIN IF XACT_STATE()<>0 ROLLBACK; IF @BeforeXactAbort=0 SET XACT_ABORT OFF; THROW; END; SET @Caught=1; END CATCH;
IF @Caught=0 OR XACT_STATE()<>-1 OR @@TRANCOUNT<>1 BEGIN IF XACT_STATE()<>0 ROLLBACK; IF @BeforeXactAbort=0 SET XACT_ABORT OFF; THROW 55392,N'CSV lifecycle: Parser hat doomed Caller verloren.',7; END;
SET @Caught=0;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#NoSourceNeededForDoomedGuard'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55309 BEGIN IF XACT_STATE()<>0 ROLLBACK; IF @BeforeXactAbort=0 SET XACT_ABORT OFF; THROW; END; SET @Caught=1; END CATCH;
IF @Caught=0 OR XACT_STATE()<>-1 OR @@TRANCOUNT<>1 BEGIN IF XACT_STATE()<>0 ROLLBACK; IF @BeforeXactAbort=0 SET XACT_ABORT OFF; THROW 55392,N'CSV lifecycle: Writer hat doomed Caller verloren.',8; END;
ROLLBACK;
IF @BeforeXactAbort=0 SET XACT_ABORT OFF;
DROP TABLE #CsvLifecycleDoomProbe;
-- Caller-private Temp-Kollision wird vor der fachlichen Workbatch-Kompilierung abgewiesen.
CREATE TABLE #tbx_CsvParse_Result(SyntheticMarker int);
INSERT #tbx_CsvParse_Result VALUES(73);
SET @Caught=0;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=N'x'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55304 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR NOT EXISTS(SELECT 1 FROM #tbx_CsvParse_Result WHERE SyntheticMarker=73)
 THROW 55392,N'CSV lifecycle: Caller-private Temp wurde eclipsed oder verändert.',5;
DROP TABLE #tbx_CsvParse_Result;
DROP TABLE #CsvLifecycleTarget;
SELECT N'PASS' AS Status;
GO
