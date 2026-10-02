-- Ausschließlich synthetische externe DDL-Qualifikation; die API führt nichts aus.
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
CREATE TABLE dbo.SyntheticWave1Source
 (Id int NOT NULL, Note nvarchar(20) NULL,
  Computed AS Id+1, Persisted AS Id*2 PERSISTED,
  Required AS ISNULL(Id,0)+3 PERSISTED NOT NULL,
  Amount decimal(38,0) NULL CONSTRAINT DF_SyntheticWave1 DEFAULT(0),
  CONSTRAINT PK_SyntheticWave1 PRIMARY KEY(Id),
  CONSTRAINT UQ_SyntheticWave1 UNIQUE(Note),
  CONSTRAINT CK_SyntheticWave1 CHECK(Id>=0));
CREATE INDEX IX_SyntheticWave1Computed ON dbo.SyntheticWave1Source(Persisted);
CREATE UNIQUE INDEX IX_SyntheticWave1Filtered ON dbo.SyntheticWave1Source(Id DESC) INCLUDE(Note) WHERE Id>0;
DECLARE @Values TABLE(Name sysname,Value sql_variant);
INSERT @Values VALUES
 (N'bit',CONVERT(sql_variant,CONVERT(bit,1))),
 (N'tinyint',CONVERT(sql_variant,CONVERT(tinyint,255))),
 (N'smallint',CONVERT(sql_variant,CONVERT(smallint,-32768))),
 (N'int',CONVERT(sql_variant,CONVERT(int,-2147483648))),
 (N'bigint',CONVERT(sql_variant,CONVERT(bigint,-9223372036854775808))),
 (N'decimal38',CONVERT(sql_variant,CONVERT(decimal(38,0),N'99999999999999999999999999999999999999'))),
 (N'scale38',CONVERT(sql_variant,CONVERT(numeric(38,38),N'0.00000000000000000000000000000000000001'))),
 (N'money',CONVERT(sql_variant,CONVERT(money,-1.2345))),
 (N'smallmoney',CONVERT(sql_variant,CONVERT(smallmoney,-1.2345))),
 (N'float',CONVERT(sql_variant,CONVERT(float,1.2345678901234567))),
 (N'floatzero',CONVERT(sql_variant,CONVERT(float,N'-0'))),
 (N'real',CONVERT(sql_variant,CONVERT(real,1.234567))),
 (N'date',CONVERT(sql_variant,CONVERT(date,N'2001-02-03'))),
 (N'time',CONVERT(sql_variant,CONVERT(time(7),N'12:34:56.1234567'))),
 (N'datetime',CONVERT(sql_variant,CONVERT(datetime,N'2001-02-03T12:34:56.997'))),
 (N'smalldatetime',CONVERT(sql_variant,CONVERT(smalldatetime,N'2001-02-03T12:34:00'))),
 (N'datetime2',CONVERT(sql_variant,CONVERT(datetime2(7),N'2001-02-03T12:34:56.1234567'))),
 (N'datetimeoffset',CONVERT(sql_variant,CONVERT(datetimeoffset(7),N'2001-02-03T12:34:56.1234567+05:30'))),
 (N'char',CONVERT(sql_variant,CONVERT(char(8),'abc  ') COLLATE Latin1_General_100_CS_AS)),
 (N'varchar',CONVERT(sql_variant,CONVERT(varchar(12),'quote'' ') COLLATE Latin1_General_100_CI_AS)),
 (N'nchar',CONVERT(sql_variant,CONVERT(nchar(8),N'ä  ') COLLATE Latin1_General_100_BIN2)),
 (N'nvarchar',CONVERT(sql_variant,CONVERT(nvarchar(12),N'quote'' ') COLLATE Latin1_General_100_CS_AS)),
 (N'binary',CONVERT(sql_variant,CONVERT(binary(8),0x0001FF))),
 (N'varbinary',CONVERT(sql_variant,CONVERT(varbinary(8),0x0001FF00))),
 (N'utf8',CONVERT(sql_variant,CONVERT(varchar(12),N'ä ' COLLATE Latin1_General_100_CI_AS_SC_UTF8))),
 (N'guid',CONVERT(sql_variant,CONVERT(uniqueidentifier,N'00000000-0000-0000-0000-000000000001'))),
 (N'NULL',CONVERT(sql_variant,NULL));
-- Jede Originaltypinstanz wird separat aufgebaut: keine VALUES-Spaltentyp-Promotion.
DECLARE @OriginalValues TABLE(Name sysname,Value sql_variant);
INSERT @OriginalValues VALUES(N'bit',CONVERT(sql_variant,CONVERT(bit,1)));
INSERT @OriginalValues VALUES(N'tinyint',CONVERT(sql_variant,CONVERT(tinyint,255)));
INSERT @OriginalValues VALUES(N'smallint',CONVERT(sql_variant,CONVERT(smallint,-32768)));
INSERT @OriginalValues VALUES(N'int',CONVERT(sql_variant,CONVERT(int,-2147483648)));
INSERT @OriginalValues VALUES(N'bigint',CONVERT(sql_variant,CONVERT(bigint,-9223372036854775808)));
INSERT @OriginalValues VALUES(N'decimal38',CONVERT(sql_variant,CONVERT(decimal(38,0),N'99999999999999999999999999999999999999')));
INSERT @OriginalValues VALUES(N'scale38',CONVERT(sql_variant,CONVERT(numeric(38,38),N'0.00000000000000000000000000000000000001')));
INSERT @OriginalValues VALUES(N'money',CONVERT(sql_variant,CONVERT(money,-1.2345)));
INSERT @OriginalValues VALUES(N'smallmoney',CONVERT(sql_variant,CONVERT(smallmoney,-1.2345)));
INSERT @OriginalValues VALUES(N'float',CONVERT(sql_variant,CONVERT(float,1.2345678901234567)));
INSERT @OriginalValues VALUES(N'floatzero',CONVERT(sql_variant,CONVERT(float,N'-0')));
INSERT @OriginalValues VALUES(N'real',CONVERT(sql_variant,CONVERT(real,1.234567)));
INSERT @OriginalValues VALUES(N'date',CONVERT(sql_variant,CONVERT(date,N'2001-02-03')));
INSERT @OriginalValues VALUES(N'time',CONVERT(sql_variant,CONVERT(time(7),N'12:34:56.1234567')));
INSERT @OriginalValues VALUES(N'datetime',CONVERT(sql_variant,CONVERT(datetime,N'2001-02-03T12:34:56.997')));
INSERT @OriginalValues VALUES(N'smalldatetime',CONVERT(sql_variant,CONVERT(smalldatetime,N'2001-02-03T12:34:00')));
INSERT @OriginalValues VALUES(N'datetime2',CONVERT(sql_variant,CONVERT(datetime2(7),N'2001-02-03T12:34:56.1234567')));
INSERT @OriginalValues VALUES(N'datetimeoffset',CONVERT(sql_variant,CONVERT(datetimeoffset(7),N'2001-02-03T12:34:56.1234567+05:30')));
INSERT @OriginalValues VALUES(N'char',CONVERT(sql_variant,CONVERT(char(8),'abc  ') COLLATE Latin1_General_100_CS_AS));
INSERT @OriginalValues VALUES(N'varchar',CONVERT(sql_variant,CONVERT(varchar(12),'quote'' ') COLLATE Latin1_General_100_CI_AS));
INSERT @OriginalValues VALUES(N'nchar',CONVERT(sql_variant,CONVERT(nchar(8),N'ä  ') COLLATE Latin1_General_100_BIN2));
INSERT @OriginalValues VALUES(N'nvarchar',CONVERT(sql_variant,CONVERT(nvarchar(12),N'quote'' ') COLLATE Latin1_General_100_CS_AS));
INSERT @OriginalValues VALUES(N'binary',CONVERT(sql_variant,CONVERT(binary(8),0x0001FF)));
INSERT @OriginalValues VALUES(N'varbinary',CONVERT(sql_variant,CONVERT(varbinary(8),0x0001FF00)));
INSERT @OriginalValues VALUES(N'utf8',CONVERT(sql_variant,CONVERT(varchar(12),N'ä ' COLLATE Latin1_General_100_CI_AS_SC_UTF8)));
INSERT @OriginalValues VALUES(N'guid',CONVERT(sql_variant,CONVERT(uniqueidentifier,N'00000000-0000-0000-0000-000000000001')));
INSERT @OriginalValues VALUES(N'NULL',CONVERT(sql_variant,NULL));
IF(SELECT COUNT(*) FROM @Values)<>27 OR(SELECT COUNT(*) FROM @OriginalValues)<>27
 OR EXISTS(SELECT Name,CONVERT(varbinary(max),Value),SQL_VARIANT_PROPERTY(Value,'BaseType'),SQL_VARIANT_PROPERTY(Value,'Precision'),SQL_VARIANT_PROPERTY(Value,'Scale'),SQL_VARIANT_PROPERTY(Value,'MaxLength'),SQL_VARIANT_PROPERTY(Value,'Collation') FROM @Values
 EXCEPT SELECT Name,CONVERT(varbinary(max),Value),SQL_VARIANT_PROPERTY(Value,'BaseType'),SQL_VARIANT_PROPERTY(Value,'Precision'),SQL_VARIANT_PROPERTY(Value,'Scale'),SQL_VARIANT_PROPERTY(Value,'MaxLength'),SQL_VARIANT_PROPERTY(Value,'Collation') FROM @OriginalValues)
 OR EXISTS(SELECT Name,CONVERT(varbinary(max),Value),SQL_VARIANT_PROPERTY(Value,'BaseType'),SQL_VARIANT_PROPERTY(Value,'Precision'),SQL_VARIANT_PROPERTY(Value,'Scale'),SQL_VARIANT_PROPERTY(Value,'MaxLength'),SQL_VARIANT_PROPERTY(Value,'Collation') FROM @OriginalValues
 EXCEPT SELECT Name,CONVERT(varbinary(max),Value),SQL_VARIANT_PROPERTY(Value,'BaseType'),SQL_VARIANT_PROPERTY(Value,'Precision'),SQL_VARIANT_PROPERTY(Value,'Scale'),SQL_VARIANT_PROPERTY(Value,'MaxLength'),SQL_VARIANT_PROPERTY(Value,'Collation') FROM @Values)
 THROW 54930,N'Wave1: Originale Property-Typinstanzen nicht erhalten.',12;
DECLARE @Name sysname,@Value sql_variant;
DECLARE ValueCursor CURSOR LOCAL FAST_FORWARD FOR SELECT Name,Value FROM @Values;
OPEN ValueCursor; FETCH NEXT FROM ValueCursor INTO @Name,@Value;
WHILE @@FETCH_STATUS=0
BEGIN
 EXEC sys.sp_addextendedproperty @name=@Name,@value=@Value,@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'TABLE',@level1name=N'SyntheticWave1Source';
 FETCH NEXT FROM ValueCursor INTO @Name,@Value;
END;
CLOSE ValueCursor; DEALLOCATE ValueCursor;
EXEC sys.sp_addextendedproperty @name=N'column quote'' ',@value=N'column',@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'TABLE',@level1name=N'SyntheticWave1Source',@level2type=N'COLUMN',@level2name=N'Note';
EXEC sys.sp_addextendedproperty @name=N'default',@value=N'default',@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'TABLE',@level1name=N'SyntheticWave1Source',@level2type=N'CONSTRAINT',@level2name=N'DF_SyntheticWave1';
EXEC sys.sp_addextendedproperty @name=N'check',@value=N'check',@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'TABLE',@level1name=N'SyntheticWave1Source',@level2type=N'CONSTRAINT',@level2name=N'CK_SyntheticWave1';
EXEC sys.sp_addextendedproperty @name=N'key',@value=N'key',@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'TABLE',@level1name=N'SyntheticWave1Source',@level2type=N'CONSTRAINT',@level2name=N'PK_SyntheticWave1';
EXEC sys.sp_addextendedproperty @name=N'unique',@value=N'unique',@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'TABLE',@level1name=N'SyntheticWave1Source',@level2type=N'CONSTRAINT',@level2name=N'UQ_SyntheticWave1';
EXEC sys.sp_addextendedproperty @name=N'index',@value=N'index',@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'TABLE',@level1name=N'SyntheticWave1Source',@level2type=N'INDEX',@level2name=N'IX_SyntheticWave1Filtered';
CREATE TABLE #Wave1Plan(Dummy int);
INSERT #Wave1Plan VALUES(37);
BEGIN TRY
 EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticWave1Source',N'dbo',N'SyntheticWave1Target',@ResultTable=N'#Wave1Plan';
 THROW 54930,N'EP opt-in missing rejection.',1;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>53903 THROW; END CATCH;
IF (SELECT Dummy FROM #Wave1Plan)<>37 THROW 54930,N'Late failure changed output.',2;
EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticWave1Source',N'dbo',N'SyntheticWave1Target',0,1,@ResultTable=N'#Wave1Plan';
IF (SELECT COUNT(*) FROM #Wave1Plan WHERE ObjectKind='SESSION_OPTION')<>7 OR NOT EXISTS(SELECT 1 FROM #Wave1Plan WHERE Ordinal=8 AND ObjectKind='TABLE')
 THROW 54930,N'SET/TABLE ordinal contract.',3;
DECLARE @Script nvarchar(max);
-- Ein äußerer Batch erhält SET-Wirkung und eindeutige EP-Variablennamen.
SELECT @Script=STRING_AGG(CONVERT(nvarchar(max),ScriptText),NCHAR(10)) WITHIN GROUP(ORDER BY Ordinal) FROM #Wave1Plan;
EXEC sys.sp_executesql @Script;
DECLARE @Source int=OBJECT_ID(N'dbo.SyntheticWave1Source'),@Target int=OBJECT_ID(N'dbo.SyntheticWave1Target');
IF EXISTS(SELECT name,CONVERT(varbinary(max),definition),is_persisted,is_nullable FROM sys.computed_columns WHERE object_id=@Source
 EXCEPT SELECT name,CONVERT(varbinary(max),definition),is_persisted,is_nullable FROM sys.computed_columns WHERE object_id=@Target)
 THROW 54930,N'Computed definition/PERSISTED/NULL differs.',4;
IF EXISTS(SELECT is_unique,CONVERT(varbinary(max),filter_definition) FROM sys.indexes WHERE object_id=@Source AND has_filter=1
 EXCEPT SELECT is_unique,CONVERT(varbinary(max),filter_definition) FROM sys.indexes WHERE object_id=@Target AND has_filter=1)
 THROW 54930,N'Filter differs.',5;
IF EXISTS(SELECT CONVERT(varbinary(256),name),CONVERT(varbinary(max),value),SQL_VARIANT_PROPERTY(value,'BaseType'),SQL_VARIANT_PROPERTY(value,'Precision'),SQL_VARIANT_PROPERTY(value,'Scale'),SQL_VARIANT_PROPERTY(value,'MaxLength'),SQL_VARIANT_PROPERTY(value,'Collation')
 FROM sys.extended_properties WHERE class=1 AND major_id=@Source AND minor_id=0
 EXCEPT SELECT CONVERT(varbinary(256),name),CONVERT(varbinary(max),value),SQL_VARIANT_PROPERTY(value,'BaseType'),SQL_VARIANT_PROPERTY(value,'Precision'),SQL_VARIANT_PROPERTY(value,'Scale'),SQL_VARIANT_PROPERTY(value,'MaxLength'),SQL_VARIANT_PROPERTY(value,'Collation')
 FROM sys.extended_properties WHERE class=1 AND major_id=@Target AND minor_id=0)
 OR (SELECT COUNT(*) FROM sys.extended_properties WHERE class=1 AND major_id=@Source AND minor_id=0)<>(SELECT COUNT(*) FROM sys.extended_properties WHERE class=1 AND major_id=@Target AND minor_id=0)
 THROW 54930,N'Property exact value/type metadata differs.',6;
IF (SELECT COUNT(*) FROM sys.extended_properties WHERE (class=1 AND major_id=@Target AND minor_id<>0) OR(class=1 AND major_id IN(SELECT object_id FROM sys.objects WHERE parent_object_id=@Target)) OR(class=7 AND major_id=@Target))<>6
 THROW 54930,N'Renamed owner properties missing.',7;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties e JOIN sys.columns c ON c.object_id=e.major_id AND c.column_id=e.minor_id WHERE e.class=1 AND e.major_id=@Target AND e.name=N'column quote'' ' AND c.name=N'Note' AND CONVERT(varbinary(max),e.value)=CONVERT(varbinary(max),N'column'))
 OR EXISTS(SELECT 1 FROM (VALUES(N'default','D'),(N'check','C'),(N'key','PK'),(N'unique','UQ')) expected(Name,Kind)
   WHERE NOT EXISTS(SELECT 1 FROM sys.extended_properties e JOIN sys.objects o ON o.object_id=e.major_id WHERE e.class=1 AND o.parent_object_id=@Target AND o.type=expected.Kind COLLATE DATABASE_DEFAULT AND e.name=expected.Name COLLATE DATABASE_DEFAULT AND CONVERT(varbinary(max),e.value)=CONVERT(varbinary(max),expected.Name)))
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e JOIN sys.indexes i ON i.object_id=e.major_id AND i.index_id=e.minor_id WHERE e.class=7 AND e.major_id=@Target AND e.name=N'index' AND i.has_filter=1 AND CONVERT(varbinary(max),e.value)=CONVERT(varbinary(max),N'index'))
 THROW 54930,N'Property owner mapping differs.',10;
EXEC sys.sp_addextendedproperty @name=N'tOoLbElT.Foreign',@value=N'foreign',@level0type=N'SCHEMA',@level0name=N'dbo',@level1type=N'TABLE',@level1name=N'SyntheticWave1Source';
BEGIN TRY
 EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticWave1Source',N'dbo',N'UnusedWave1',0,1,@ResultTable=N'#Wave1Plan';
 THROW 54930,N'Ownership property accepted.',8;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>53903 THROW; END CATCH;
IF NOT EXISTS(SELECT 1 FROM #Wave1Plan WHERE Ordinal=8 AND ObjectKind='TABLE') THROW 54930,N'Ownership rejection changed output.',9;
DROP TABLE dbo.SyntheticWave1Target;
DROP TABLE dbo.SyntheticWave1Source;
GO
-- UDF-Dependencies sind trotz sichtbarer Definition kein W1-Computedpfad.
SET NOCOUNT ON;
EXEC sys.sp_executesql N'CREATE FUNCTION dbo.SyntheticWave1Udf(@n int) RETURNS int AS BEGIN RETURN @n+1; END;';
EXEC sys.sp_executesql N'CREATE TABLE dbo.SyntheticWave1UdfSource(Id int,Computed AS dbo.SyntheticWave1Udf(Id));';
CREATE TABLE #Wave1Rejected(Value int);
INSERT #Wave1Rejected VALUES(73);
BEGIN TRY
 EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticWave1UdfSource',N'dbo',N'UnusedWave1Udf',@ResultTable=N'#Wave1Rejected';
 THROW 54930,N'UDF Computed accepted.',11;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>53903 THROW; END CATCH;
IF (SELECT Value FROM #Wave1Rejected)<>73 THROW 54930,N'UDF rejection changed output.',12;
BEGIN TRY
 EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticWave1UdfSource',N'dbo',N'UnusedWave1Udf',@IncludeExtendedProperties=NULL,@ResultTable=N'#Wave1Rejected';
 THROW 54930,N'NULL EP argument accepted.',13;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>53900 THROW; END CATCH;
DROP TABLE dbo.SyntheticWave1UdfSource;
DROP FUNCTION dbo.SyntheticWave1Udf;
GO
