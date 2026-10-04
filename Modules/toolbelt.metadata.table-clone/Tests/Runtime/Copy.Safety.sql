-- Zwei gruppierte Negativ-/Atomikorakel, kein Testhelper im Produkt.
CREATE PROCEDURE #CopyExpectFailure
 @Number int,@State int,@Rows bigint=100000,@Bytes bigint=16777216
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Error int=0,@ActualState int=0,@TC int,@XS int;
 BEGIN TRY
  EXEC toolbelt_metadata.USP_CopyTableCloneData @TableMap=N'#CopySafetyMap',@IdentityMode='KEEP',@ConsistencyMode='SERIALIZABLE',@RowLimit=@Rows,@PayloadByteLimit=@Bytes,@ResultTable=N'#CopySafetyOutput';
 END TRY BEGIN CATCH SET @Error=ERROR_NUMBER();SET @ActualState=ERROR_STATE();END CATCH;
 SET @TC=@@TRANCOUNT;SET @XS=XACT_STATE();
 IF @Error<>@Number OR @ActualState<>@State OR @TC<>0 OR @XS<>0
  THROW 54951,N'Copy group4 strict failure/state/transaction failed.',1;
 IF (SELECT COUNT(*) FROM #CopySafetyOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #CopySafetyOutput WHERE MappedTables=73 AND CopiedRows=73 AND PayloadBytes=73 AND CreatedForeignKeys=73 AND Status='SENTINEL')
  THROW 54951,N'Copy group4 failure changed output sentinel.',2;
END;
GO
SET NOCOUNT ON;
SET XACT_ABORT OFF;
-- Gruppe4: Input-, Budget-, Form-/FK-Ablehnungen und Help-/Caller-/Tempgrenzen.
CREATE TABLE #CopySafetyMap(MapOrdinal int NOT NULL,SourceSchema nvarchar(max) NOT NULL,SourceTable nvarchar(max) NOT NULL,TargetSchema nvarchar(max) NOT NULL,TargetTable nvarchar(max) NOT NULL);
CREATE TABLE #CopySafetyOutput(MappedTables int NOT NULL,CopiedRows bigint NOT NULL,PayloadBytes bigint NOT NULL,CreatedForeignKeys int NOT NULL,Status varchar(16) NOT NULL);
INSERT #CopySafetyOutput VALUES(73,73,73,73,'SENTINEL');
CREATE TABLE dbo.SyntheticCopySafetySource(Id int NOT NULL,Value nvarchar(10) NULL);
CREATE TABLE dbo.SyntheticCopySafetyTarget(Id int NOT NULL,Value nvarchar(10) NULL);
INSERT dbo.SyntheticCopySafetySource VALUES(1,N'ab'),(2,NULL);
INSERT #CopySafetyMap VALUES(1,N'dbo',N'SyntheticCopySafetySource',N'dbo',N'SyntheticCopySafetyTarget');
EXEC #CopyExpectFailure @Number=53943,@State=1,@Rows=1;
EXEC #CopyExpectFailure @Number=53943,@State=2,@Bytes=11;
IF EXISTS(SELECT 1 FROM dbo.SyntheticCopySafetyTarget) THROW 54951,N'Copy group4 admission wrote target.',3;
INSERT dbo.SyntheticCopySafetyTarget VALUES(79,NULL);
EXEC #CopyExpectFailure @Number=53944,@State=1;
IF (SELECT COUNT(*) FROM dbo.SyntheticCopySafetyTarget)<>1 OR NOT EXISTS(SELECT 1 FROM dbo.SyntheticCopySafetyTarget WHERE Id=79)
 THROW 54951,N'Copy group4 nonempty target changed.',4;
DELETE dbo.SyntheticCopySafetyTarget;
ALTER TABLE dbo.SyntheticCopySafetyTarget ADD Extra int NULL;
EXEC #CopyExpectFailure @Number=53941,@State=3;
ALTER TABLE dbo.SyntheticCopySafetyTarget DROP COLUMN Extra;
CREATE TABLE dbo.SyntheticCopyExtraParent(Id int NOT NULL PRIMARY KEY);
ALTER TABLE dbo.SyntheticCopySafetyTarget ADD CONSTRAINT FK_SyntheticCopyExtra FOREIGN KEY(Id) REFERENCES dbo.SyntheticCopyExtraParent(Id);
EXEC #CopyExpectFailure @Number=53903,@State=23;
ALTER TABLE dbo.SyntheticCopySafetyTarget DROP CONSTRAINT FK_SyntheticCopyExtra;
DROP TABLE dbo.SyntheticCopyExtraParent;
CREATE TABLE #tbx_TableClone_Plan(ForeignSentinel int NOT NULL);
INSERT #tbx_TableClone_Plan VALUES(79);
EXEC #CopyExpectFailure @Number=53940,@State=4;
IF (SELECT COUNT(*) FROM #tbx_TableClone_Plan)<>1 OR NOT EXISTS(SELECT 1 FROM #tbx_TableClone_Plan WHERE ForeignSentinel=79)
 THROW 54951,N'Copy group4 foreign Core temp changed.',5;
DROP TABLE #tbx_TableClone_Plan;
-- Die ResultTable-kompatible private FK-Brücke darf keine fremde Temp-Tabelle überschatten.
CREATE TABLE #Toolbelt_TableClone_CopyFkStage(ForeignSentinel int NOT NULL);
INSERT #Toolbelt_TableClone_CopyFkStage VALUES(80);
EXEC #CopyExpectFailure @Number=53940,@State=4;
IF (SELECT COUNT(*) FROM #Toolbelt_TableClone_CopyFkStage)<>1 OR NOT EXISTS(SELECT 1 FROM #Toolbelt_TableClone_CopyFkStage WHERE ForeignSentinel=80)
 THROW 54951,N'Copy group4 foreign FK bridge changed.',11;
DROP TABLE #Toolbelt_TableClone_CopyFkStage;
-- Help bleibt auch in einer gesunden Caller-TX vor ungültigen Parametern und Ausgabe-Routing.
CREATE TABLE #CopyHelp(HelpContractVersion varchar(16) NOT NULL,SchemaName sysname NOT NULL,ObjectName sysname NOT NULL,Section varchar(32) NOT NULL,Ordinal int NOT NULL,ItemName sysname NULL,SqlDataType varchar(256) NULL,IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,Description nvarchar(max) NOT NULL,ExampleSql nvarchar(max) NULL);
DECLARE @OriginalOptions int,@BeforeOptions int,@AfterOptions int,@TC int,@XS int,@Error int=0,@State int=0;
SET @OriginalOptions=@@OPTIONS;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
SET @TC=@@TRANCOUNT;SET @XS=XACT_STATE();SET @BeforeOptions=@@OPTIONS;
IF @TC<>1 OR @XS<>1 THROW 54951,N'Copy group4 caller baseline not healthy.',6;
-- Die alleinige INSERT-EXEC-Ausnahme ist hier die Testaufnahme des standardisierten Help-Resultsets.
INSERT #CopyHelp EXEC toolbelt_metadata.USP_CopyTableCloneData @TableMap=N'invalid',@IdentityMode=NULL,@ConsistencyMode=NULL,@ResultTable=N'#CopySafetyOutput',@Debug=255,@Hilfe=1;
BEGIN TRY EXEC toolbelt_metadata.USP_CopyTableCloneData @TableMap=N'#CopySafetyMap',@IdentityMode='KEEP',@ConsistencyMode='SERIALIZABLE';
END TRY BEGIN CATCH SET @Error=ERROR_NUMBER();SET @State=ERROR_STATE();END CATCH;
SET @TC=@@TRANCOUNT;SET @XS=XACT_STATE();SET @AfterOptions=@@OPTIONS;
IF @Error<>50000 OR @State<>1 OR @TC<>1 OR @XS<>1 OR @BeforeOptions<>@AfterOptions OR (@AfterOptions&16384)=0
BEGIN IF XACT_STATE()<>0 ROLLBACK TRANSACTION;THROW 54951,N'Copy group4 caller guard/state/SET restore failed.',7;END;
IF (SELECT COUNT(*) FROM #CopyHelp WHERE Section='PARAMETER')<>9
 OR (SELECT COUNT(*) FROM #CopyHelp WHERE Section='RESULT_COLUMN')<>5
 OR EXISTS(SELECT Required.Section FROM(VALUES('DESCRIPTION'),('EXAMPLE')) Required(Section) WHERE NOT EXISTS(SELECT 1 FROM #CopyHelp h WHERE h.Section=Required.Section))
BEGIN ROLLBACK TRANSACTION;THROW 54951,N'Copy group4 Help schema/sections failed.',8;END;
COMMIT TRANSACTION;
IF (@OriginalOptions&16384)=0 SET XACT_ABORT OFF;
IF (SELECT COUNT(*) FROM #CopySafetyOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #CopySafetyOutput WHERE Status='SENTINEL') OR EXISTS(SELECT 1 FROM dbo.SyntheticCopySafetyTarget)
 THROW 54951,N'Copy group4 Help/caller caused writes.',9;
DROP TABLE #CopyHelp,#CopySafetyOutput,#CopySafetyMap;
DROP PROCEDURE #CopyExpectFailure;
DROP TABLE dbo.SyntheticCopySafetyTarget,dbo.SyntheticCopySafetySource;
PRINT 'PASS TABLE_CLONE_COPY_GROUP4';
GO
-- Gruppe5: spätes ResultTable-CHECK scheitert nach Inserts/FK-DDL; alles eigene SQL rollt zurück.
SET NOCOUNT ON;
SET XACT_ABORT OFF;
CREATE TABLE dbo.SyntheticCopyLateParent(Id int NOT NULL PRIMARY KEY);
CREATE TABLE dbo.SyntheticCopyLateParentTarget(Id int NOT NULL PRIMARY KEY);
CREATE TABLE dbo.SyntheticCopyLateChild(Id int NOT NULL,ParentId int NOT NULL);
CREATE TABLE dbo.SyntheticCopyLateChildTarget(Id int NOT NULL,ParentId int NOT NULL);
ALTER TABLE dbo.SyntheticCopyLateChild ADD CONSTRAINT FK_SyntheticCopyLate FOREIGN KEY(ParentId) REFERENCES dbo.SyntheticCopyLateParent(Id);
INSERT dbo.SyntheticCopyLateParent VALUES(1);
INSERT dbo.SyntheticCopyLateChild VALUES(2,1),(3,1);
CREATE TABLE #CopyLateMap(MapOrdinal int NOT NULL,SourceSchema nvarchar(max) NOT NULL,SourceTable nvarchar(max) NOT NULL,TargetSchema nvarchar(max) NOT NULL,TargetTable nvarchar(max) NOT NULL);
INSERT #CopyLateMap VALUES(1,N'dbo',N'SyntheticCopyLateParent',N'dbo',N'SyntheticCopyLateParentTarget'),(2,N'dbo',N'SyntheticCopyLateChild',N'dbo',N'SyntheticCopyLateChildTarget');
CREATE TABLE #CopyLateOutput(MappedTables int NOT NULL,CopiedRows bigint NOT NULL CHECK(CopiedRows=73),PayloadBytes bigint NOT NULL,CreatedForeignKeys int NOT NULL,Status varchar(16) NOT NULL);
INSERT #CopyLateOutput VALUES(73,73,73,73,'SENTINEL');
DECLARE @Error int=0,@TC int,@XS int,@BeforeOptions int,@AfterOptions int;
SET @BeforeOptions=@@OPTIONS;
BEGIN TRY EXEC toolbelt_metadata.USP_CopyTableCloneData @TableMap=N'#CopyLateMap',@IdentityMode='KEEP',@ConsistencyMode='SERIALIZABLE',@ResultTable=N'#CopyLateOutput';
END TRY BEGIN CATCH SET @Error=ERROR_NUMBER();END CATCH;
SET @TC=@@TRANCOUNT;SET @XS=XACT_STATE();SET @AfterOptions=@@OPTIONS;
IF @Error<>547 OR @TC<>0 OR @XS<>0 OR @BeforeOptions<>@AfterOptions
 OR EXISTS(SELECT 1 FROM dbo.SyntheticCopyLateParentTarget) OR EXISTS(SELECT 1 FROM dbo.SyntheticCopyLateChildTarget)
 OR EXISTS(SELECT 1 FROM sys.foreign_keys WHERE parent_object_id=OBJECT_ID(N'dbo.SyntheticCopyLateChildTarget'))
 OR (SELECT COUNT(*) FROM #CopyLateOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #CopyLateOutput WHERE CopiedRows=73 AND Status='SENTINEL')
 OR (SELECT COUNT(*) FROM dbo.SyntheticCopyLateParent)<>1 OR (SELECT COUNT(*) FROM dbo.SyntheticCopyLateChild)<>2
 THROW 54951,N'Copy group5 late result error did not rollback data/FK/output.',10;
DROP TABLE #CopyLateMap,#CopyLateOutput;
DROP TABLE dbo.SyntheticCopyLateChild,dbo.SyntheticCopyLateChildTarget,dbo.SyntheticCopyLateParent,dbo.SyntheticCopyLateParentTarget;
PRINT 'PASS TABLE_CLONE_COPY_GROUP5';
GO
