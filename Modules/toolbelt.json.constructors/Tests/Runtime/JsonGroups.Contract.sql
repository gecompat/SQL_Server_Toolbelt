-- Gruppierungs-/Budget-/Atomaritätsorakel; alle Werte synthetisch.
SET NOCOUNT ON;
-- Committable Caller-savepoint wird ausdrücklich mit XACT_ABORT OFF geprüft.
SET XACT_ABORT OFF;
CREATE TABLE #GroupEntries(GroupOrdinal int,Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max));
CREATE TABLE #GroupOutput(Dummy varbinary(8));
INSERT #GroupEntries VALUES(9,8,N'b',N'boolean',N'true'),(2,3,N'b',N'null',NULL),(9,1,N'a',N'number',N'1'),(2,1,N'a',N'string',N'Contoso');
EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N'#GroupEntries',@ResultTable=N'#GroupOutput';
IF (SELECT COUNT_BIG(*) FROM #GroupOutput)<>2
 OR NOT EXISTS(SELECT 1 FROM #GroupOutput WHERE GroupOrdinal=2 AND CONVERT(varbinary(max),JsonValue)=CONVERT(varbinary(max),N'["Contoso",null]'))
 OR NOT EXISTS(SELECT 1 FROM #GroupOutput WHERE GroupOrdinal=9 AND CONVERT(varbinary(max),JsonValue)=CONVERT(varbinary(max),N'[1,true]'))
 THROW 53690,N'Group array values/order incorrect.',1;
EXEC toolbelt_json.USP_JsonObjectsByGroup @EntriesTable=N'#GroupEntries',@ResultTable=N'#GroupOutput';
IF (SELECT COUNT_BIG(*) FROM #GroupOutput)<>2
 OR NOT EXISTS(SELECT 1 FROM #GroupOutput WHERE GroupOrdinal=2 AND CONVERT(varbinary(max),JsonValue)=CONVERT(varbinary(max),N'{"a":"Contoso","b":null}'))
 OR NOT EXISTS(SELECT 1 FROM #GroupOutput WHERE GroupOrdinal=9 AND CONVERT(varbinary(max),JsonValue)=CONVERT(varbinary(max),N'{"a":1,"b":true}'))
 THROW 53690,N'Group object values/order incorrect.',1;
-- Gleiche Keys/Entryordinals in verschiedenen Gruppen erlaubt, Padding/Case bleiben Identität.
TRUNCATE TABLE #GroupEntries;
INSERT #GroupEntries VALUES(1,1,N'a',N'number',N'1'),(1,2,N'a ',N'number',N'2'),(1,3,N'A',N'number',N'3'),(2,1,N'a',N'number',N'4');
EXEC toolbelt_json.USP_JsonObjectsByGroup @EntriesTable=N'#GroupEntries',@ResultTable=N'#GroupOutput';
IF NOT EXISTS(SELECT 1 FROM #GroupOutput WHERE GroupOrdinal=1 AND CONVERT(varbinary(max),JsonValue)=CONVERT(varbinary(max),N'{"a":1,"a ":2,"A":3}'))
 THROW 53690,N'Group key byte identity incorrect.',1;
CREATE TABLE #GroupBefore(GroupOrdinal int,JsonValue nvarchar(max));
INSERT #GroupBefore SELECT GroupOrdinal,JsonValue FROM #GroupOutput;
INSERT #GroupEntries VALUES(1,4,N'a',N'null',NULL);
BEGIN TRY
 EXEC toolbelt_json.USP_JsonObjectsByGroup @EntriesTable=N'#GroupEntries',@ResultTable=N'#GroupOutput';
 THROW 53690,N'Group duplicate key failure missing.',1;
END TRY BEGIN CATCH
 IF ERROR_NUMBER()<>53604 OR ERROR_STATE()<>1 THROW;
END CATCH;
IF EXISTS(SELECT GroupOrdinal,CONVERT(varbinary(max),JsonValue) FROM #GroupBefore EXCEPT SELECT GroupOrdinal,CONVERT(varbinary(max),JsonValue) FROM #GroupOutput)
 OR EXISTS(SELECT GroupOrdinal,CONVERT(varbinary(max),JsonValue) FROM #GroupOutput EXCEPT SELECT GroupOrdinal,CONVERT(varbinary(max),JsonValue) FROM #GroupBefore)
 THROW 53690,N'Group duplicate changed target.',1;
-- Kombinierter Gruppen-/Entryfehler: Gruppengrenze hat Vorrang.
TRUNCATE TABLE #GroupEntries;
INSERT #GroupEntries VALUES(NULL,0,NULL,N'null',NULL);
BEGIN TRY
 EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N'#GroupEntries',@ResultTable=N'#GroupOutput';
 THROW 53690,N'Invalid group failure missing.',1;
END TRY BEGIN CATCH
 IF ERROR_NUMBER()<>53602 OR ERROR_STATE()<>2 THROW;
END CATCH;
UPDATE #GroupEntries SET GroupOrdinal=1,Ordinal=1;
INSERT #GroupEntries VALUES(1,1,NULL,N'null',NULL);
BEGIN TRY
 EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N'#GroupEntries',@ResultTable=N'#GroupOutput';
 THROW 53690,N'Composite ordinal failure missing.',1;
END TRY BEGIN CATCH
 IF ERROR_NUMBER()<>53602 OR ERROR_STATE()<>1 THROW;
END CATCH;
-- Ein später Literalfehler darf auch mit Callertransaktion keine Gruppe publizieren.
TRUNCATE TABLE #GroupEntries;
INSERT #GroupEntries VALUES(1,1,NULL,N'null',NULL),(99,1,NULL,N'number',N'01');
DECLARE @count int=@@TRANCOUNT;
BEGIN TRANSACTION;
CREATE TABLE #GroupCallerMarker(Value int);
INSERT #GroupCallerMarker VALUES(73);
BEGIN TRY
 EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N'#GroupEntries',@ResultTable=N'#GroupOutput',@KeepData=1;
 THROW 53690,N'Late group failure missing.',1;
END TRY BEGIN CATCH
 IF ERROR_NUMBER()<>53608 OR @@TRANCOUNT<>@count+1 OR XACT_STATE()<>1 THROW;
END CATCH;
IF NOT EXISTS(SELECT 1 FROM #GroupCallerMarker WHERE Value=73)
 OR EXISTS(SELECT GroupOrdinal,CONVERT(varbinary(max),JsonValue) FROM #GroupOutput EXCEPT SELECT GroupOrdinal,CONVERT(varbinary(max),JsonValue) FROM #GroupBefore)
 OR EXISTS(SELECT GroupOrdinal,CONVERT(varbinary(max),JsonValue) FROM #GroupBefore EXCEPT SELECT GroupOrdinal,CONVERT(varbinary(max),JsonValue) FROM #GroupOutput)
 THROW 53690,N'Late group failure changed caller/target.',1;
ROLLBACK TRANSACTION;
-- Gesamtgrenzen gelten über Gruppen, nicht je Gruppe.
TRUNCATE TABLE #GroupEntries;
INSERT #GroupEntries VALUES(1,1,NULL,N'number',N'1'),(2,1,NULL,N'number',N'2');
BEGIN TRY
 EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N'#GroupEntries',@MaxEntries=1;
 THROW 53690,N'Global count failure missing.',1;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>53609 OR ERROR_STATE()<>1 THROW; END CATCH;
BEGIN TRY
 EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N'#GroupEntries',@MaxTotalValueBytes=3;
 THROW 53690,N'Global value failure missing.',1;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>53609 OR ERROR_STATE()<>2 THROW; END CATCH;
BEGIN TRY
 EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N'#GroupEntries',@MaxResultBytes=11;
 THROW 53690,N'Global output failure missing.',1;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>53609 OR ERROR_STATE()<>4 THROW; END CATCH;
EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N'#GroupEntries',@MaxResultBytes=12,@ResultTable=N'#GroupOutput';
IF (SELECT SUM(CONVERT(bigint,DATALENGTH(JsonValue))) FROM #GroupOutput)<>12 THROW 53690,N'Exact group syntax budget wrong.',1;
-- Escapewachstum wird erst durch das finale gemeinsame Budget bewiesen.
TRUNCATE TABLE #GroupEntries;
INSERT #GroupEntries VALUES(1,1,NULL,N'string',NCHAR(1)),(2,1,NULL,N'string',NCHAR(1));
BEGIN TRY
 EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N'#GroupEntries',@MaxResultBytes=20,@ResultTable=N'#GroupOutput';
 THROW 53690,N'Global escaped result failure missing.',1;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>53609 OR ERROR_STATE()<>3 THROW; END CATCH;
-- Leere Gruppenmenge: Append bewahrt, Replace leert und hat weiterhin zwei Spalten.
TRUNCATE TABLE #GroupEntries;
EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N'#GroupEntries',@ResultTable=N'#GroupOutput',@KeepData=1;
IF (SELECT COUNT_BIG(*) FROM #GroupOutput)<>2 THROW 53690,N'Empty append changed rows.',1;
EXEC toolbelt_json.USP_JsonObjectsByGroup @EntriesTable=N'#GroupEntries',@ResultTable=N'#GroupOutput';
IF EXISTS(SELECT 1 FROM #GroupOutput) THROW 53690,N'Empty grouped result created phantom row.',1;
CREATE TABLE #GroupIncompatible(Dummy int);
INSERT #GroupIncompatible VALUES(73);
BEGIN TRY
 EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N'#GroupEntries',@ResultTable=N'#GroupIncompatible',@KeepData=1;
 THROW 53690,N'Empty incompatible append failure missing.',1;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>51025 THROW; END CATCH;
IF NOT EXISTS(SELECT 1 FROM #GroupIncompatible WHERE Dummy=73) THROW 53690,N'Append changed incompatible target.',1;
EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N'#GroupEntries',@ResultTable=N'#GroupIncompatible';
IF EXISTS(SELECT 1 FROM #GroupIncompatible) THROW 53690,N'Empty replace did not clear target.',1;
-- Alte Fassaden ignorieren die Zusatzspalte und bleiben genau einspaltig/eine Zeile.
CREATE TABLE #OldOutput(Dummy int);
EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#GroupEntries',@ResultTable=N'#OldOutput';
IF (SELECT COUNT_BIG(*) FROM #OldOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #OldOutput WHERE JsonValue=N'[]') THROW 53690,N'Old array empty contract changed.',1;
EXEC toolbelt_json.USP_JsonObject @EntriesTable=N'#GroupEntries',@ResultTable=N'#OldOutput';
IF (SELECT COUNT_BIG(*) FROM #OldOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #OldOutput WHERE JsonValue=N'{}') THROW 53690,N'Old object empty contract changed.',1;
DROP TABLE #OldOutput; DROP TABLE #GroupIncompatible; DROP TABLE #GroupBefore; DROP TABLE #GroupOutput; DROP TABLE #GroupEntries;
GO
-- Der neue feste interne Resultname wird vor Core-Kompilierung geschützt.
CREATE TABLE #tbx_JsonConstructor_GroupResult(SyntheticForeign int);
BEGIN TRY
 EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N'#missing';
 THROW 53690,N'Group temp eclipsing failure missing.',1;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>53601 OR ERROR_STATE()<>5 THROW; END CATCH;
BEGIN TRY
 EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#missing';
 THROW 53690,N'Old temp eclipsing failure missing.',1;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>53601 OR ERROR_STATE()<>5 THROW; END CATCH;
BEGIN TRY
 EXEC toolbelt_json.USP_JsonObjectsByGroup @EntriesTable=N'#missing';
 THROW 53690,N'Grouped object temp eclipsing failure missing.',1;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>53601 OR ERROR_STATE()<>5 THROW; END CATCH;
BEGIN TRY
 EXEC toolbelt_json.USP_JsonObject @EntriesTable=N'#missing';
 THROW 53690,N'Old object temp eclipsing failure missing.',1;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>53601 OR ERROR_STATE()<>5 THROW; END CATCH;
DROP TABLE #tbx_JsonConstructor_GroupResult;
GO
