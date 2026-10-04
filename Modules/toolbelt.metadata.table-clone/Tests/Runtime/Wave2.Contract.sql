-- Synthetische externe Test-DDL, niemals Produkt-Ausführung des Plans.
SET NOCOUNT ON;
SET XACT_ABORT OFF;
CREATE TABLE dbo.SyntheticW2Parent(A int NOT NULL,B int NOT NULL,CONSTRAINT PK_SyntheticW2Parent PRIMARY KEY(A,B));
CREATE TABLE dbo.SyntheticW2Child(Id int NOT NULL PRIMARY KEY,A int NULL,B int NULL,SelfId int NULL,
    CONSTRAINT FK_SyntheticW2Composite FOREIGN KEY(A,B) REFERENCES dbo.SyntheticW2Parent(A,B) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT FK_SyntheticW2Self FOREIGN KEY(SelfId) REFERENCES dbo.SyntheticW2Child(Id));
ALTER TABLE dbo.SyntheticW2Parent ADD ChildId int NULL;
ALTER TABLE dbo.SyntheticW2Parent ADD CONSTRAINT FK_SyntheticW2Cycle FOREIGN KEY(ChildId) REFERENCES dbo.SyntheticW2Child(Id);
CREATE TABLE dbo.SyntheticW2External(Id int NOT NULL PRIMARY KEY);
ALTER TABLE dbo.SyntheticW2Child WITH NOCHECK ADD CONSTRAINT FK_SyntheticW2External FOREIGN KEY(SelfId) REFERENCES dbo.SyntheticW2External(Id) NOT FOR REPLICATION;
ALTER TABLE dbo.SyntheticW2Child NOCHECK CONSTRAINT FK_SyntheticW2Self;
DECLARE @SyntheticOriginalVariant decimal(12,3)=12.345;
EXEC sys.sp_addextendedproperty @name=N'OriginalVariant',@value=@SyntheticOriginalVariant,@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'TABLE',@level1name=N'SyntheticW2Child';
CREATE TABLE #W2Map(MapOrdinal int NOT NULL,SourceSchema nvarchar(max) NOT NULL,SourceTable nvarchar(max) NOT NULL,TargetSchema nvarchar(max) NOT NULL,TargetTable nvarchar(max) NOT NULL);
INSERT #W2Map VALUES(20,N'dbo',N'SyntheticW2Child',N'dbo',N'SyntheticW2ChildClone'),(10,N'dbo',N'SyntheticW2Parent',N'dbo',N'SyntheticW2ParentClone');
CREATE TABLE #W2Plan(Dummy int);
EXEC toolbelt_metadata.USP_ScriptTableClone @TableMap=N'#W2Map',@ExternalReferenceRule='KEEP',@IncludeExtendedProperties=1,@ResultTable=N'#W2Plan';
IF (SELECT COUNT(*) FROM #W2Plan WHERE ObjectKind='SESSION_OPTION')<>7 OR (SELECT MIN(Ordinal) FROM #W2Plan)<>1
   OR (SELECT MAX(Ordinal) FROM #W2Plan)<>(SELECT COUNT(*) FROM #W2Plan) THROW 54932,N'W2 ordinal/session shape.',1;
IF NOT EXISTS(SELECT 1 FROM #W2Plan WHERE Ordinal=8 AND ObjectKind='TABLE' AND TargetName=N'[dbo].[SyntheticW2ParentClone]')
   OR NOT EXISTS(SELECT 1 FROM #W2Plan WHERE Ordinal=9 AND ObjectKind='TABLE' AND TargetName=N'[dbo].[SyntheticW2ChildClone]') THROW 54932,N'W2 global table order.',2;
IF (SELECT COUNT(*) FROM #W2Plan WHERE ObjectKind='FOREIGN_KEY')<>4 OR (SELECT COUNT(*) FROM #W2Plan WHERE ObjectKind='FOREIGN_KEY_STATE')<>1
   OR (SELECT MAX(Ordinal) FROM #W2Plan WHERE ObjectKind='EXTENDED_PROPERTY')>(SELECT MIN(Ordinal) FROM #W2Plan WHERE ObjectKind='FOREIGN_KEY')
   OR (SELECT MAX(Ordinal) FROM #W2Plan WHERE ObjectKind='FOREIGN_KEY')>(SELECT MIN(Ordinal) FROM #W2Plan WHERE ObjectKind='FOREIGN_KEY_STATE') THROW 54932,N'W2 phase order.',3;
DECLARE @Script nvarchar(max);
DECLARE ExecuteSyntheticPlan CURSOR LOCAL FAST_FORWARD FOR SELECT ScriptText FROM #W2Plan ORDER BY Ordinal;
OPEN ExecuteSyntheticPlan; FETCH NEXT FROM ExecuteSyntheticPlan INTO @Script;
WHILE @@FETCH_STATUS=0 BEGIN EXEC sys.sp_executesql @Script; FETCH NEXT FROM ExecuteSyntheticPlan INTO @Script; END;
CLOSE ExecuteSyntheticPlan; DEALLOCATE ExecuteSyntheticPlan;
-- Independent catalog oracle: flags, actions, ordered FK columns and redirected identities.
DECLARE @SourceId int=OBJECT_ID(N'dbo.SyntheticW2Child'),@CloneId int=OBJECT_ID(N'dbo.SyntheticW2ChildClone');
IF (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id=@CloneId)<>3 THROW 54932,N'W2 FK count.',4;
IF EXISTS(SELECT f.is_disabled,f.is_not_trusted,f.is_not_for_replication,f.delete_referential_action,f.update_referential_action,
      CASE WHEN f.referenced_object_id=@SourceId THEN @CloneId WHEN f.referenced_object_id=OBJECT_ID(N'dbo.SyntheticW2Parent') THEN OBJECT_ID(N'dbo.SyntheticW2ParentClone') ELSE f.referenced_object_id END RefId,
      c.constraint_column_id,pc.name,rc.name FROM sys.foreign_keys f JOIN sys.foreign_key_columns c ON c.constraint_object_id=f.object_id
      JOIN sys.columns pc ON pc.object_id=c.parent_object_id AND pc.column_id=c.parent_column_id JOIN sys.columns rc ON rc.object_id=c.referenced_object_id AND rc.column_id=c.referenced_column_id WHERE f.parent_object_id=@SourceId
    EXCEPT SELECT f.is_disabled,f.is_not_trusted,f.is_not_for_replication,f.delete_referential_action,f.update_referential_action,f.referenced_object_id,c.constraint_column_id,pc.name,rc.name
      FROM sys.foreign_keys f JOIN sys.foreign_key_columns c ON c.constraint_object_id=f.object_id
      JOIN sys.columns pc ON pc.object_id=c.parent_object_id AND pc.column_id=c.parent_column_id JOIN sys.columns rc ON rc.object_id=c.referenced_object_id AND rc.column_id=c.referenced_column_id WHERE f.parent_object_id=@CloneId) THROW 54932,N'W2 FK catalog semantics.',5;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@CloneId AND minor_id=0 AND name=N'OriginalVariant'
    AND SQL_VARIANT_PROPERTY(value,'BaseType')=N'decimal' AND SQL_VARIANT_PROPERTY(value,'Precision')=12 AND SQL_VARIANT_PROPERTY(value,'Scale')=3
    AND CONVERT(varbinary(max),value)=CONVERT(varbinary(max),CAST(12.345 AS decimal(12,3)))) THROW 54932,N'W2 original variant.',6;
IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE parent_object_id=OBJECT_ID(N'dbo.SyntheticW2ParentClone') AND referenced_object_id=@CloneId AND is_disabled=0 AND is_not_trusted=0) THROW 54932,N'W2 cycle redirected.',7;
DECLARE @DropFk nvarchar(max);
SELECT @DropFk=STRING_AGG(CONVERT(nvarchar(max),N'ALTER TABLE '+QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id))+N'.'+QUOTENAME(OBJECT_NAME(parent_object_id))+N' DROP CONSTRAINT '+QUOTENAME(name)+N';'),NCHAR(10))
FROM sys.foreign_keys WHERE parent_object_id IN(@CloneId,OBJECT_ID(N'dbo.SyntheticW2ParentClone'),@SourceId,OBJECT_ID(N'dbo.SyntheticW2Parent'));
EXEC sys.sp_executesql @DropFk;
DROP TABLE dbo.SyntheticW2ChildClone; DROP TABLE dbo.SyntheticW2ParentClone;
DROP TABLE dbo.SyntheticW2Child; DROP TABLE dbo.SyntheticW2Parent; DROP TABLE dbo.SyntheticW2External;
PRINT N'PASS W2_CONTRACT';
