-- Drei gruppierte synthetische Kopierorakel; alle GO-Batches auf derselben Verbindung.
SET NOCOUNT ON;
CREATE TABLE #CopyMap(MapOrdinal int NOT NULL,SourceSchema nvarchar(max) NOT NULL,SourceTable nvarchar(max) NOT NULL,TargetSchema nvarchar(max) NOT NULL,TargetTable nvarchar(max) NOT NULL);
CREATE TABLE #CopyOutput(MappedTables int NOT NULL,CopiedRows bigint NOT NULL,PayloadBytes bigint NOT NULL,CreatedForeignKeys int NOT NULL,Status varchar(16) NOT NULL);
-- Gruppe1: geordnete Spalten statt physischer column_id, NULL/Bytes und passende bestehende FKs.
CREATE TABLE dbo.SyntheticCopyParent(Id int NOT NULL PRIMARY KEY);
CREATE TABLE dbo.SyntheticCopyParentTarget(Id int NOT NULL PRIMARY KEY);
CREATE TABLE dbo.SyntheticCopyChild(Id int NOT NULL PRIMARY KEY,Unused int NULL,ParentId int NULL,TextValue nvarchar(10) NULL,BytesValue varbinary(3) NULL,Derived AS Id+1);
ALTER TABLE dbo.SyntheticCopyChild DROP COLUMN Unused;
CREATE TABLE dbo.SyntheticCopyChildTarget(Unused int NULL,Id int NOT NULL PRIMARY KEY,ParentId int NULL,TextValue nvarchar(10) NULL,BytesValue varbinary(3) NULL,Derived AS Id+1);
ALTER TABLE dbo.SyntheticCopyChildTarget DROP COLUMN Unused;
ALTER TABLE dbo.SyntheticCopyChild ADD CONSTRAINT FK_SyntheticCopySource FOREIGN KEY(ParentId) REFERENCES dbo.SyntheticCopyParent(Id);
ALTER TABLE dbo.SyntheticCopyChildTarget ADD CONSTRAINT FK_SyntheticCopyExisting FOREIGN KEY(ParentId) REFERENCES dbo.SyntheticCopyParentTarget(Id);
INSERT dbo.SyntheticCopyParent VALUES(1),(2);
INSERT dbo.SyntheticCopyChild(Id,ParentId,TextValue,BytesValue) VALUES(3,1,N'ä😀',0x010203),(4,NULL,NULL,NULL);
INSERT #CopyMap VALUES(1,N'dbo',N'SyntheticCopyParent',N'dbo',N'SyntheticCopyParentTarget'),(2,N'dbo',N'SyntheticCopyChild',N'dbo',N'SyntheticCopyChildTarget');
EXEC toolbelt_metadata.USP_CopyTableCloneData @TableMap=N'#CopyMap',@IdentityMode='KEEP',@ConsistencyMode='SERIALIZABLE',@ResultTable=N'#CopyOutput';
DECLARE @TC int,@XS int;
SET @TC=@@TRANCOUNT; SET @XS=XACT_STATE();
IF @TC<>0 OR @XS<>0 OR (SELECT COUNT(*) FROM #CopyOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CopyOutput WHERE MappedTables=2 AND CopiedRows=4 AND PayloadBytes=29 AND CreatedForeignKeys=0 AND Status='COPIED')
 OR EXISTS(SELECT Id,ParentId,TextValue,BytesValue,Derived FROM dbo.SyntheticCopyChild EXCEPT SELECT Id,ParentId,TextValue,BytesValue,Derived FROM dbo.SyntheticCopyChildTarget)
 OR EXISTS(SELECT Id,ParentId,TextValue,BytesValue,Derived FROM dbo.SyntheticCopyChildTarget EXCEPT SELECT Id,ParentId,TextValue,BytesValue,Derived FROM dbo.SyntheticCopyChild)
 OR NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_SyntheticCopyExisting' AND is_disabled=0 AND is_not_trusted=0)
 THROW 54950,N'Copy group1 ordered columns/NULL/bytes/existing FK failed.',1;
DROP TABLE dbo.SyntheticCopyChildTarget,dbo.SyntheticCopyChild,dbo.SyntheticCopyParentTarget,dbo.SyntheticCopyParent;
PRINT 'PASS TABLE_CLONE_COPY_GROUP1';
GO
-- Gruppe2: ohne transportierte Spalten DEFAULT VALUES; normale neue Identitäten und Self-FK-Ablehnung.
DELETE #CopyMap; DELETE #CopyOutput;
CREATE TABLE dbo.SyntheticCopyIdentityOnly(Id int IDENTITY(1,1) NOT NULL);
CREATE TABLE dbo.SyntheticCopyIdentityOnlyTarget(Id int IDENTITY(1,1) NOT NULL);
INSERT dbo.SyntheticCopyIdentityOnly DEFAULT VALUES;
INSERT dbo.SyntheticCopyIdentityOnly DEFAULT VALUES;
INSERT dbo.SyntheticCopyIdentityOnly DEFAULT VALUES;
INSERT #CopyMap VALUES(1,N'dbo',N'SyntheticCopyIdentityOnly',N'dbo',N'SyntheticCopyIdentityOnlyTarget');
EXEC toolbelt_metadata.USP_CopyTableCloneData @TableMap=N'#CopyMap',@IdentityMode='REGENERATE',@ConsistencyMode='SERIALIZABLE',@ResultTable=N'#CopyOutput';
IF NOT EXISTS(SELECT 1 FROM #CopyOutput WHERE CopiedRows=3 AND PayloadBytes=0 AND CreatedForeignKeys=0 AND Status='COPIED')
 OR (SELECT COUNT(*) FROM dbo.SyntheticCopyIdentityOnlyTarget)<>3
 THROW 54950,N'Copy group2 identity-only DEFAULT VALUES failed.',2;
DROP TABLE dbo.SyntheticCopyIdentityOnlyTarget,dbo.SyntheticCopyIdentityOnly;
DELETE #CopyMap;
CREATE TABLE dbo.SyntheticCopyRegenerate(Id int IDENTITY(10,2) NOT NULL,Value int NULL);
CREATE TABLE dbo.SyntheticCopyRegenerateTarget(Id int IDENTITY(10,2) NOT NULL,Value int NULL);
SET IDENTITY_INSERT dbo.SyntheticCopyRegenerate ON;
INSERT dbo.SyntheticCopyRegenerate(Id,Value) VALUES(100,7),(102,9);
SET IDENTITY_INSERT dbo.SyntheticCopyRegenerate OFF;
INSERT #CopyMap VALUES(1,N'dbo',N'SyntheticCopyRegenerate',N'dbo',N'SyntheticCopyRegenerateTarget');
EXEC toolbelt_metadata.USP_CopyTableCloneData @TableMap=N'#CopyMap',@IdentityMode='REGENERATE',@ConsistencyMode='SERIALIZABLE',@ResultTable=N'#CopyOutput';
IF NOT EXISTS(SELECT 1 FROM #CopyOutput WHERE CopiedRows=2 AND PayloadBytes=8 AND Status='COPIED')
 OR (SELECT MIN(Id) FROM dbo.SyntheticCopyRegenerateTarget)<>10 OR (SELECT MAX(Id) FROM dbo.SyntheticCopyRegenerateTarget)<>12
 OR EXISTS(SELECT Value FROM dbo.SyntheticCopyRegenerate EXCEPT SELECT Value FROM dbo.SyntheticCopyRegenerateTarget)
 THROW 54950,N'Copy group2 regenerated identity failed.',3;
DROP TABLE dbo.SyntheticCopyRegenerateTarget,dbo.SyntheticCopyRegenerate;
DELETE #CopyMap;
CREATE TABLE dbo.SyntheticCopySelf(Id int IDENTITY(1,1) NOT NULL PRIMARY KEY,ParentId int NULL);
CREATE TABLE dbo.SyntheticCopySelfTarget(Id int IDENTITY(1,1) NOT NULL PRIMARY KEY,ParentId int NULL);
ALTER TABLE dbo.SyntheticCopySelf ADD CONSTRAINT FK_SyntheticCopySelf FOREIGN KEY(ParentId) REFERENCES dbo.SyntheticCopySelf(Id);
ALTER TABLE dbo.SyntheticCopySelfTarget ADD CONSTRAINT FK_SyntheticCopySelfTarget FOREIGN KEY(ParentId) REFERENCES dbo.SyntheticCopySelfTarget(Id);
INSERT dbo.SyntheticCopySelf(ParentId) VALUES(NULL),(1);
INSERT #CopyMap VALUES(1,N'dbo',N'SyntheticCopySelf',N'dbo',N'SyntheticCopySelfTarget');
DECLARE @Error int=0,@State int=0,@TC int,@XS int;
BEGIN TRY
 EXEC toolbelt_metadata.USP_CopyTableCloneData @TableMap=N'#CopyMap',@IdentityMode='REGENERATE',@ConsistencyMode='SERIALIZABLE',@ResultTable=N'#CopyOutput';
END TRY BEGIN CATCH SET @Error=ERROR_NUMBER();SET @State=ERROR_STATE();END CATCH;
SET @TC=@@TRANCOUNT;SET @XS=XACT_STATE();
IF @Error<>53944 OR @State<>3 OR @TC<>0 OR @XS<>0 OR EXISTS(SELECT 1 FROM dbo.SyntheticCopySelfTarget)
 THROW 54950,N'Copy group2 identity relationship rejection failed.',4;
EXEC toolbelt_metadata.USP_CopyTableCloneData @TableMap=N'#CopyMap',@IdentityMode='KEEP',@ConsistencyMode='SERIALIZABLE',@ResultTable=N'#CopyOutput';
IF NOT EXISTS(SELECT 1 FROM #CopyOutput WHERE CopiedRows=2 AND PayloadBytes=12 AND CreatedForeignKeys=0 AND Status='COPIED')
 OR (SELECT COUNT(*) FROM dbo.SyntheticCopySelfTarget)<>2
 OR NOT EXISTS(SELECT 1 FROM dbo.SyntheticCopySelfTarget WHERE Id=1 AND ParentId IS NULL)
 OR NOT EXISTS(SELECT 1 FROM dbo.SyntheticCopySelfTarget WHERE Id=2 AND ParentId=1)
 THROW 54950,N'Copy group2 KEEP self-FK failed.',7;
DROP TABLE dbo.SyntheticCopySelfTarget,dbo.SyntheticCopySelf;
PRINT 'PASS TABLE_CLONE_COPY_GROUP2';
GO
-- Gruppe3: fehlender zyklischer FK-Plan erst nach Datenkopie; Zustände bleiben erhalten.
DELETE #CopyMap;DELETE #CopyOutput;
CREATE TABLE dbo.SyntheticCopyCycleA(Id int NOT NULL PRIMARY KEY,BId int NULL);
CREATE TABLE dbo.SyntheticCopyCycleB(Id int NOT NULL PRIMARY KEY,AId int NULL);
CREATE TABLE dbo.SyntheticCopyCycleATarget(Id int NOT NULL PRIMARY KEY,BId int NULL);
CREATE TABLE dbo.SyntheticCopyCycleBTarget(Id int NOT NULL PRIMARY KEY,AId int NULL);
ALTER TABLE dbo.SyntheticCopyCycleA ADD CONSTRAINT FK_SyntheticCopyA FOREIGN KEY(BId) REFERENCES dbo.SyntheticCopyCycleB(Id);
ALTER TABLE dbo.SyntheticCopyCycleB ADD CONSTRAINT FK_SyntheticCopyB FOREIGN KEY(AId) REFERENCES dbo.SyntheticCopyCycleA(Id);
ALTER TABLE dbo.SyntheticCopyCycleA NOCHECK CONSTRAINT FK_SyntheticCopyA;
ALTER TABLE dbo.SyntheticCopyCycleB NOCHECK CONSTRAINT FK_SyntheticCopyB;
INSERT dbo.SyntheticCopyCycleA VALUES(1,2);INSERT dbo.SyntheticCopyCycleB VALUES(2,1);
ALTER TABLE dbo.SyntheticCopyCycleB CHECK CONSTRAINT FK_SyntheticCopyB;
INSERT #CopyMap VALUES(1,N'dbo',N'SyntheticCopyCycleA',N'dbo',N'SyntheticCopyCycleATarget'),(2,N'dbo',N'SyntheticCopyCycleB',N'dbo',N'SyntheticCopyCycleBTarget');
EXEC toolbelt_metadata.USP_CopyTableCloneData @TableMap=N'#CopyMap',@IdentityMode='KEEP',@ConsistencyMode='SERIALIZABLE',@ResultTable=N'#CopyOutput';
IF NOT EXISTS(SELECT 1 FROM #CopyOutput WHERE MappedTables=2 AND CopiedRows=2 AND PayloadBytes=16 AND CreatedForeignKeys=2 AND Status='COPIED')
 OR (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id=OBJECT_ID(N'dbo.SyntheticCopyCycleATarget') AND is_disabled=1 AND is_not_trusted=1)<>1
 OR (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id=OBJECT_ID(N'dbo.SyntheticCopyCycleBTarget') AND is_disabled=0 AND is_not_trusted=1)<>1
 THROW 54950,N'Copy group3 missing cyclic FK/state publication failed.',5;
-- Nur eigene Fixture-FKs entfernen; keine heimliche Deaktivierung im Produktpfad.
DECLARE @Drop nvarchar(max)=N'';
SELECT @Drop=@Drop+N'ALTER TABLE '+QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id))+N'.'+QUOTENAME(OBJECT_NAME(parent_object_id))+N' DROP CONSTRAINT '+QUOTENAME(name)+N';'
 FROM sys.foreign_keys WHERE parent_object_id IN(OBJECT_ID(N'dbo.SyntheticCopyCycleA'),OBJECT_ID(N'dbo.SyntheticCopyCycleB'),OBJECT_ID(N'dbo.SyntheticCopyCycleATarget'),OBJECT_ID(N'dbo.SyntheticCopyCycleBTarget'));
EXEC sys.sp_executesql @Drop;
DELETE dbo.SyntheticCopyCycleA;DELETE dbo.SyntheticCopyCycleB;
DELETE dbo.SyntheticCopyCycleATarget;DELETE dbo.SyntheticCopyCycleBTarget;
ALTER TABLE dbo.SyntheticCopyCycleA ADD CONSTRAINT FK_SyntheticCopyA FOREIGN KEY(BId) REFERENCES dbo.SyntheticCopyCycleB(Id);
ALTER TABLE dbo.SyntheticCopyCycleB ADD CONSTRAINT FK_SyntheticCopyB FOREIGN KEY(AId) REFERENCES dbo.SyntheticCopyCycleA(Id);
ALTER TABLE dbo.SyntheticCopyCycleATarget ADD CONSTRAINT FK_SyntheticCopyATarget FOREIGN KEY(BId) REFERENCES dbo.SyntheticCopyCycleBTarget(Id);
ALTER TABLE dbo.SyntheticCopyCycleBTarget ADD CONSTRAINT FK_SyntheticCopyBTarget FOREIGN KEY(AId) REFERENCES dbo.SyntheticCopyCycleATarget(Id);
-- Leere Targets mit semantisch passenden aktiven FKs bilden nun einen bestehenden Zyklus.
DECLARE @Error int=0,@State int=0,@TC int,@XS int;
BEGIN TRY EXEC toolbelt_metadata.USP_CopyTableCloneData @TableMap=N'#CopyMap',@IdentityMode='KEEP',@ConsistencyMode='SERIALIZABLE',@ResultTable=N'#CopyOutput';
END TRY BEGIN CATCH SET @Error=ERROR_NUMBER();SET @State=ERROR_STATE();END CATCH;
SET @TC=@@TRANCOUNT;SET @XS=XACT_STATE();
IF @Error<>53944 OR @State<>4 OR @TC<>0 OR @XS<>0 THROW 54950,N'Copy group3 existing active cycle failed.',6;
DELETE #CopyMap WHERE MapOrdinal=2;
SET @Error=0;SET @State=0;
BEGIN TRY EXEC toolbelt_metadata.USP_CopyTableCloneData @TableMap=N'#CopyMap',@IdentityMode='KEEP',@ConsistencyMode='SERIALIZABLE',@ResultTable=N'#CopyOutput';
END TRY BEGIN CATCH SET @Error=ERROR_NUMBER();SET @State=ERROR_STATE();END CATCH;
SET @TC=@@TRANCOUNT;SET @XS=XACT_STATE();
IF @Error<>53903 OR @State<>13 OR @TC<>0 OR @XS<>0
 THROW 54950,N'Copy group3 outgoing external FK rejection failed.',8;
-- Nur eigene Fixture-FKs entfernen, damit die synthetischen Tabellen getrennt abbaubar sind.
SET @Drop=N'';
SELECT @Drop=@Drop+N'ALTER TABLE '+QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id))+N'.'+QUOTENAME(OBJECT_NAME(parent_object_id))+N' DROP CONSTRAINT '+QUOTENAME(name)+N';'
 FROM sys.foreign_keys WHERE parent_object_id IN(OBJECT_ID(N'dbo.SyntheticCopyCycleA'),OBJECT_ID(N'dbo.SyntheticCopyCycleB'),OBJECT_ID(N'dbo.SyntheticCopyCycleATarget'),OBJECT_ID(N'dbo.SyntheticCopyCycleBTarget'));
EXEC sys.sp_executesql @Drop;
DROP TABLE dbo.SyntheticCopyCycleA,dbo.SyntheticCopyCycleB,dbo.SyntheticCopyCycleATarget,dbo.SyntheticCopyCycleBTarget;
DROP TABLE #CopyMap,#CopyOutput;
PRINT 'PASS TABLE_CLONE_COPY_GROUP3';
GO
