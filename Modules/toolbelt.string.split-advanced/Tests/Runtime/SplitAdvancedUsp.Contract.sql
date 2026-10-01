SET NOCOUNT ON;
SET XACT_ABORT OFF;
CREATE TABLE #SplitUsp_Test(Value nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,Ordinal bigint NOT NULL);
EXEC toolbelt_string.USP_SplitAdvanced @Input=N'a;"b;c";d',@SeparatorsJson=N'[";"]',@ResultTable=N'#SplitUsp_Test';
IF (SELECT COUNT(*) FROM #SplitUsp_Test)<>3
   OR NOT EXISTS(SELECT 1 FROM #SplitUsp_Test WHERE Ordinal=2 AND CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N'"b;c"'))
    THROW 54560,N'USP Originaltoken/TVF-Parität falsch.',1;
EXEC toolbelt_string.USP_SplitAdvanced @Input=N'x',@SeparatorsJson=N'[";"]',@ResultTable=N'#SplitUsp_Test',@KeepData=1;
IF (SELECT COUNT(*) FROM #SplitUsp_Test)<>4 THROW 54561,N'USP Append falsch.',1;
EXEC toolbelt_string.USP_SplitAdvanced @Input=NULL,@SeparatorsJson=NULL,@ResultTable=N'#SplitUsp_Test',@KeepData=0;
IF (SELECT COUNT(*) FROM #SplitUsp_Test)<>4 THROW 54562,N'USP NULL-No-op veränderte Ziel.',1;
EXEC toolbelt_string.USP_SplitAdvanced @Input=NULL,@ResultTable=N'permanent-is-ignored';
BEGIN TRY
    EXEC toolbelt_string.USP_SplitAdvanced @Input=N'a;"bad',@SeparatorsJson=N'[";"]',@ResultTable=N'#SplitUsp_Test';
    THROW 54563,N'USP akzeptierte Parserfehler.',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>51680 OR ERROR_MESSAGE() NOT LIKE N'%UNTERMINATED_QUOTE%'
        THROW;
END CATCH;
IF (SELECT COUNT(*) FROM #SplitUsp_Test)<>4 THROW 54564,N'USP Parserfehler mutierte Ziel.',1;
EXEC toolbelt_string.USP_SplitAdvanced @Input=N'',@SeparatorsJson=N'[";"]',@KeepEmpty=0,@ResultTable=N'#SplitUsp_Test';
IF EXISTS(SELECT 1 FROM #SplitUsp_Test) THROW 54565,N'USP nicht-NULL-leeres Resultat ersetzte nicht.',1;
CREATE INDEX IX_tbx_SplitUsp_Test ON #SplitUsp_Test(Ordinal);
EXEC toolbelt_string.USP_SplitAdvanced @Input=N'z',@SeparatorsJson=N'[";"]',@ResultTable=N'#SplitUsp_Test';
IF NOT EXISTS(SELECT 1 FROM tempdb.sys.indexes WHERE object_id=OBJECT_ID(N'tempdb..#SplitUsp_Test') AND name=N'IX_tbx_SplitUsp_Test')
    THROW 54566,N'USP entfernte passenden Callerindex.',1;
CREATE TABLE #SplitUsp_Dummy(Anything uniqueidentifier NULL);
EXEC toolbelt_string.USP_SplitAdvanced @Input=N'a;b',@SeparatorsJson=N'[";"]',@Quote=N'',@Escape=N'',@ResultTable=N'#SplitUsp_Dummy',@KeepData=1;
IF (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#SplitUsp_Dummy'))<>2
    THROW 54567,N'USP leeres Dummyschema nicht angepasst.',1;
CREATE TABLE #SplitUsp_Bad(Anything int NULL);
INSERT #SplitUsp_Bad VALUES(17);
BEGIN TRY
    EXEC toolbelt_string.USP_SplitAdvanced @Input=N'a',@SeparatorsJson=N'[";"]',@ResultTable=N'#SplitUsp_Bad',@KeepData=1;
    THROW 54568,N'USP akzeptierte Append in befüllt-unpassendes Schema.',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>51025 THROW;
END CATCH;
IF (SELECT COUNT(*) FROM #SplitUsp_Bad WHERE Anything=17)<>1 THROW 54569,N'USP Preflight mutierte Ziel.',1;
EXEC toolbelt_string.USP_SplitAdvanced @Input=N'a;b',@SeparatorsJson=N'[";"]',@ResultTable=N'#SplitUsp_Bad',@KeepData=0;
IF (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#SplitUsp_Bad'))<>2
    OR EXISTS(SELECT 1 FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#SplitUsp_Bad') AND name=N'Anything')
    THROW 54578,N'USP befüllt-unpassender Replace falsch.',1;
CREATE TABLE #SplitUsp_Blocked(Anything int NULL CHECK(Anything>0));
INSERT #SplitUsp_Blocked VALUES(17);
BEGIN TRY
    EXEC toolbelt_string.USP_SplitAdvanced @Input=N'a',@SeparatorsJson=N'[";"]',@ResultTable=N'#SplitUsp_Blocked';
    THROW 54570,N'USP akzeptierte Schema-Blocker.',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>51026 THROW;
END CATCH;
IF (SELECT COUNT(*) FROM #SplitUsp_Blocked WHERE Anything=17)<>1 THROW 54571,N'USP Blocker mutierte Ziel.',1;
-- Caller-Scope erhalten; Replace+Insertfehler werden im committable Savepoint zurückgerollt.
ALTER TABLE #SplitUsp_Test ADD CHECK(Ordinal<2);
IF (SELECT COUNT(*) FROM #SplitUsp_Test)<>1 OR NOT EXISTS
    (SELECT 1 FROM #SplitUsp_Test WHERE Ordinal=1 AND CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N'z'))
    THROW 54584,N'OwnTransaction-Fixturezustand falsch.',1;
BEGIN TRY
    EXEC toolbelt_string.USP_SplitAdvanced @Input=N'a;b',@SeparatorsJson=N'[";"]',@ResultTable=N'#SplitUsp_Test';
    THROW 54579,N'USP eigener Constraintfehler fehlt.',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>547 THROW;
END CATCH;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0
    THROW 54583,N'USP eigener Rollback ließ Transaktion zurück.',1;
IF (SELECT COUNT(*) FROM #SplitUsp_Test)<>1 OR NOT EXISTS
    (SELECT 1 FROM #SplitUsp_Test WHERE Ordinal=1 AND CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N'z'))
    THROW 54580,N'USP eigener Rollback restaurierte Ziel nicht.',1;
BEGIN TRANSACTION;
BEGIN TRY
    EXEC toolbelt_string.USP_SplitAdvanced @Input=N'a;b',@SeparatorsJson=N'[";"]',@ResultTable=N'#SplitUsp_Test';
    THROW 54572,N'USP erwarteter Constraintfehler fehlt.',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>547 THROW;
END CATCH;
IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 OR NOT EXISTS(SELECT 1 FROM #SplitUsp_Test WHERE Value=N'z')
    THROW 54573,N'USP Savepoint/Callerzustand falsch.',1;
ROLLBACK TRANSACTION;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    EXEC toolbelt_string.USP_SplitAdvanced @Input=N'a;b',@SeparatorsJson=N'[";"]',@ResultTable=N'#SplitUsp_Test';
    THROW 54576,N'USP doomed-Constraintfehler fehlt.',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>547 THROW;
END CATCH;
IF @@TRANCOUNT<>1 OR XACT_STATE()<>-1 THROW 54577,N'USP zerstörte doomed Caller-Scope.',1;
ROLLBACK TRANSACTION;
SET XACT_ABORT OFF;
CREATE TABLE #SplitUsp_Help
(HelpContractVersion varchar(16) NOT NULL,SchemaName sysname NOT NULL,ObjectName sysname NOT NULL,
 Section varchar(32) NOT NULL,Ordinal int NOT NULL,ItemName sysname NULL,SqlDataType varchar(256) NULL,
 IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,Description nvarchar(max) NOT NULL,ExampleSql nvarchar(max) NULL);
-- INSERT EXEC nur Test-Capture, niemals Runtime-/Wrapperarchitektur.
INSERT #SplitUsp_Help EXEC toolbelt_string.USP_SplitAdvanced
    @Hilfe=1,@Input=N'bad',@SeparatorsJson=N'bad',@ResultTable=N'bad',@Debug=255;
IF (SELECT COUNT(*) FROM #SplitUsp_Help WHERE Section='PARAMETER')<>9
   OR (SELECT COUNT(*) FROM #SplitUsp_Help WHERE Section='RESULT_COLUMN' AND IsNullable=0)<>2
   OR NOT EXISTS(SELECT 1 FROM #SplitUsp_Help WHERE Section='DESCRIPTION')
   OR NOT EXISTS(SELECT 1 FROM #SplitUsp_Help WHERE Section='EXAMPLE')
    THROW 54574,N'USP Helpvertrag falsch.',1;
-- Beide SELECT-Pfade und NULL-Steuerdefaults ausführen, ohne künstliche ResultTable.
EXEC toolbelt_string.USP_SplitAdvanced @Input=NULL;
EXEC toolbelt_string.USP_SplitAdvanced @Input=N'a;b',@SeparatorsJson=N'[";"]',@KeepData=NULL,@Debug=NULL,@Hilfe=NULL;
DECLARE @Parameters TABLE(Id int,Name sysname,TypeName sysname,Length smallint,DefaultText nvarchar(4000));
INSERT @Parameters VALUES(1,N'@Input',N'nvarchar',-1,N'NULL'),
 (2,N'@SeparatorsJson',N'nvarchar',-1,N'NULL'),(3,N'@Quote',N'nvarchar',-1,N'N''"'''),
 (4,N'@Escape',N'nvarchar',-1,N'N''\'''),(5,N'@KeepEmpty',N'bit',1,N'1'),
 (6,N'@ResultTable',N'nvarchar',256,N'NULL'),(7,N'@KeepData',N'bit',1,N'0'),
 (8,N'@Debug',N'tinyint',1,N'0'),(9,N'@Hilfe',N'bit',1,N'0');
IF EXISTS(SELECT Id,Name,TypeName,Length FROM @Parameters EXCEPT
   SELECT parameter_id,name COLLATE DATABASE_DEFAULT,TYPE_NAME(system_type_id) COLLATE DATABASE_DEFAULT,max_length FROM sys.parameters
   WHERE object_id=OBJECT_ID(N'toolbelt_string.USP_SplitAdvanced'))
   OR (SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_string.USP_SplitAdvanced'))<>9
   OR EXISTS(SELECT Id,Name,DefaultText FROM @Parameters EXCEPT
      SELECT Ordinal,ItemName COLLATE DATABASE_DEFAULT,DefaultValue COLLATE DATABASE_DEFAULT FROM #SplitUsp_Help WHERE Section='PARAMETER')
    THROW 54575,N'USP Parametervetrag falsch.',1;
DROP TABLE #SplitUsp_Help,#SplitUsp_Blocked,#SplitUsp_Bad,#SplitUsp_Dummy,#SplitUsp_Test;
PRINT N'SplitAdvanced USP Contract: erfolgreich';
GO
