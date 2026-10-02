-- Predicateinjektion im eigenen synthetischen Testscope, kein tatsächlicher Lowpriv-Nachweis.
DECLARE @EntryTransactionCount int,@EntryTransactionState int;
SET @EntryTransactionCount=@@TRANCOUNT;
SET @EntryTransactionState=XACT_STATE();
IF @EntryTransactionCount<>0 OR @EntryTransactionState<>0
 THROW 54930,N'Predicate fixture requires an independent healthy scope.',23;
SET NOCOUNT ON;
CREATE TABLE dbo.SyntheticGateComputed(Id int,Computed AS Id+1);
CREATE TABLE dbo.SyntheticGateNormal(Id int);
CREATE TABLE #Wave1GateOutput(Value int);
INSERT #Wave1GateOutput VALUES(73);
DECLARE @OriginalId int=OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableCloneInternal',N'P'),
 @Original nvarchar(max),@Ansi bit,@Quoted bit,@OriginalXactAbort bit=CASE WHEN(@@OPTIONS&16384)=0 THEN 0 ELSE 1 END,
 @Needle nvarchar(256)=N'HAS_PERMS_BY_NAME(N''sys.sql_expression_dependencies'',N''OBJECT'',N''SELECT'')',
 @Changed nvarchar(max),@Case int=0,@Status int,@OwnTransaction bit=0,
 @RestoreTransactionCount int,@RestoreTransactionState int;
SELECT @Original=definition,@Ansi=uses_ansi_nulls,@Quoted=uses_quoted_identifier FROM sys.sql_modules WHERE object_id=@OriginalId;
IF @OriginalId IS NULL OR @Original IS NULL OR @Ansi IS NULL OR @Quoted IS NULL
 OR (DATALENGTH(@Original)-DATALENGTH(REPLACE(@Original,@Needle,N'')))/DATALENGTH(@Needle)<>1
 THROW 54930,N'Computed predicate injection anchor invalid.',20;
DECLARE @OriginalProperties TABLE(Class int NOT NULL,MinorId int NOT NULL,NameBytes varbinary(256) NOT NULL,
 ValueBytes varbinary(max) NULL,BaseType sql_variant NULL,PrecisionValue sql_variant NULL,ScaleValue sql_variant NULL,
 MaxLengthValue sql_variant NULL,CollationValue sql_variant NULL);
INSERT @OriginalProperties
SELECT class,minor_id,CONVERT(varbinary(256),name),CONVERT(varbinary(max),value),
 SQL_VARIANT_PROPERTY(value,'BaseType'),SQL_VARIANT_PROPERTY(value,'Precision'),SQL_VARIANT_PROPERTY(value,'Scale'),
 SQL_VARIANT_PROPERTY(value,'MaxLength'),SQL_VARIANT_PROPERTY(value,'Collation')
FROM sys.extended_properties WHERE major_id=@OriginalId AND class IN(1,2);
IF (SELECT COUNT(*) FROM sys.extended_properties WHERE class=1 AND major_id=@OriginalId AND minor_id=0 AND name=N'Toolbelt.SourceHash')<>1
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@OriginalId AND minor_id=0 AND name=N'Toolbelt.SourceHash' AND value IS NOT NULL)
 THROW 54930,N'Predicate fixture source marker missing.',23;
-- Kein allgemeiner Kommentarparser: exakt bekannte Source-Prefixe und Header.
DECLARE @PrefixLf nvarchar(max)=N'-- Kanonischer Catalog-/Scriptkern; keine Ausführung des erzeugten Scripttexts.'+NCHAR(10)
 +N'-- Interner Aufruf ausschließlich über öffentliche Namespace-/Helpgrenze.'+NCHAR(10)
 +N'-- Definitionen werden wörtlich erhalten, kein Parser oder neue Scalar-Funktion.'+NCHAR(10),
 @Prefix nvarchar(max),@Eol nvarchar(2),@Header nvarchar(256),@HeaderPosition int,@AlterOriginal nvarchar(max);
DECLARE @ObservedPrefix nvarchar(max)=NCHAR(10)+NCHAR(10)+@PrefixLf,
 @ObservedHeader nvarchar(256)=N'CREATE   PROCEDURE toolbelt_metadata.USP_ScriptTableCloneInternal'+NCHAR(10);
-- Begrenzter Diagnose-Witness; bestehende Prefixannahme und Ablehnung bleiben unverändert.
DECLARE @KnownPrefixForms TABLE(FormCode varchar(32) NOT NULL,Signature nvarchar(max) NOT NULL);
INSERT @KnownPrefixForms(FormCode,Signature)
SELECT CONVERT(varchar(32),e.EolCode+'_L'+CONVERT(varchar(1),l.LeadingCount)+'_'+h.HeaderCode),
 REPLICATE(e.Eol,l.LeadingCount)+REPLACE(@PrefixLf,NCHAR(10),e.Eol)+h.HeaderText+e.Eol
FROM (VALUES('LF',CONVERT(nvarchar(2),NCHAR(10))),('CRLF',CONVERT(nvarchar(2),NCHAR(13)+NCHAR(10))))e(EolCode,Eol)
CROSS JOIN(VALUES(0),(1),(2))l(LeadingCount)
CROSS JOIN(VALUES
 ('CREATE',N'CREATE PROCEDURE toolbelt_metadata.USP_ScriptTableCloneInternal'),
 ('ORALTER',N'CREATE OR ALTER PROCEDURE toolbelt_metadata.USP_ScriptTableCloneInternal'),
 ('TRIPLE',N'CREATE   PROCEDURE toolbelt_metadata.USP_ScriptTableCloneInternal'))h(HeaderCode,HeaderText);
SELECT CONVERT(bit,CASE WHEN @Original IS NULL THEN 0 ELSE 1 END) AS WitnessPresent,
 CONVERT(int,COUNT(*)) AS KnownMatchCount,
 CONVERT(varchar(32),CASE WHEN COUNT(*)=1 THEN MAX(FormCode) WHEN COUNT(*)=0 THEN 'NONE' ELSE 'AMBIGUOUS' END) AS ClosedForm
FROM @KnownPrefixForms
WHERE DATALENGTH(@Original)>=DATALENGTH(Signature)
 AND SUBSTRING(CONVERT(varbinary(max),@Original),1,DATALENGTH(Signature))=CONVERT(varbinary(max),Signature);
IF DATALENGTH(@Original)>=DATALENGTH(@ObservedPrefix+@ObservedHeader)
 AND SUBSTRING(CONVERT(varbinary(max),@Original),1,DATALENGTH(@ObservedPrefix+@ObservedHeader))
 =CONVERT(varbinary(max),@ObservedPrefix+@ObservedHeader)
 SELECT @Prefix=@ObservedPrefix,@Eol=NCHAR(10),@Header=@ObservedHeader;
ELSE IF CONVERT(varbinary(max),LEFT(@Original,DATALENGTH(@PrefixLf)/2))=CONVERT(varbinary(max),@PrefixLf)
 SELECT @Prefix=@PrefixLf,@Eol=NCHAR(10);
ELSE IF CONVERT(varbinary(max),LEFT(@Original,DATALENGTH(REPLACE(@PrefixLf,NCHAR(10),NCHAR(13)+NCHAR(10)))/2))
 =CONVERT(varbinary(max),REPLACE(@PrefixLf,NCHAR(10),NCHAR(13)+NCHAR(10)))
 SELECT @Prefix=REPLACE(@PrefixLf,NCHAR(10),NCHAR(13)+NCHAR(10)),@Eol=NCHAR(13)+NCHAR(10);
ELSE THROW 54930,N'Predicate fixture definition prefix unsupported.',23;
SET @HeaderPosition=DATALENGTH(@Prefix)/2+1;
IF @Header IS NULL
BEGIN
SET @Header=N'CREATE PROCEDURE toolbelt_metadata.USP_ScriptTableCloneInternal'+@Eol;
IF CONVERT(varbinary(max),SUBSTRING(@Original,@HeaderPosition,DATALENGTH(@Header)/2))<>CONVERT(varbinary(max),@Header)
 SET @Header=N'CREATE OR ALTER PROCEDURE toolbelt_metadata.USP_ScriptTableCloneInternal'+@Eol;
END;
IF CONVERT(varbinary(max),SUBSTRING(@Original,@HeaderPosition,DATALENGTH(@Header)/2))<>CONVERT(varbinary(max),@Header)
 THROW 54930,N'Predicate fixture definition header unsupported.',23;
SET @AlterOriginal=STUFF(@Original,@HeaderPosition,DATALENGTH(@Header)/2,N'ALTER PROCEDURE toolbelt_metadata.USP_ScriptTableCloneInternal'+@Eol);
BEGIN TRY
 SET XACT_ABORT OFF;
 BEGIN TRANSACTION;
 SET @OwnTransaction=1;
 WHILE @Case<2
 BEGIN
  SET @Changed=REPLACE(@AlterOriginal,@Needle,CASE WHEN @Case=0 THEN N'CONVERT(int,0)' ELSE N'CONVERT(int,NULL)' END);
  EXEC sys.sp_executesql @Changed;
  SET @Status=NULL;
  BEGIN TRY
   EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticGateComputed',N'dbo',N'UnusedGate',@ResultTable=N'#Wave1GateOutput';
  END TRY BEGIN CATCH
   IF ERROR_NUMBER()<>53901 OR ERROR_STATE()<>3 THROW;
   SET @Status=1;
  END CATCH;
  IF @Status IS NULL OR @@TRANCOUNT<>1 OR XACT_STATE()<>1
   OR (SELECT COUNT(*) FROM #Wave1GateOutput)<>1
   OR NOT EXISTS(SELECT 1 FROM #Wave1GateOutput WHERE Value IS NOT NULL AND Value=73)
   THROW 54930,N'Computed missing/null proof did not preserve output.',21;
  -- Das zusätzliche Predicate gilt nicht für normale Tabellen.
  CREATE TABLE #Wave1Normal(Dummy int);
  EXEC toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticGateNormal',N'dbo',N'UnusedNormalGate',@ResultTable=N'#Wave1Normal';
  IF (SELECT COUNT(*) FROM #Wave1Normal)<>8 THROW 54930,N'Computed gate leaked into normal path.',22;
  DROP TABLE #Wave1Normal;
  SET @Case+=1;
 END;
 ROLLBACK TRANSACTION;
 SET @OwnTransaction=0;
 SET @RestoreTransactionCount=@@TRANCOUNT;
 SET @RestoreTransactionState=XACT_STATE();
 IF @RestoreTransactionCount<>0 OR @RestoreTransactionState<>0
  THROW 54930,N'Predicate fixture rollback changed original metadata.',23;
 IF OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableCloneInternal',N'P')<>@OriginalId
  OR OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableCloneInternal',N'P') IS NULL
  OR NOT EXISTS(SELECT 1 FROM sys.sql_modules WHERE object_id=@OriginalId
   AND CONVERT(varbinary(max),definition)=CONVERT(varbinary(max),@Original)
   AND uses_ansi_nulls=@Ansi AND uses_quoted_identifier=@Quoted)
  OR (SELECT COUNT(*) FROM sys.extended_properties WHERE major_id=@OriginalId AND class IN(1,2))<>(SELECT COUNT(*) FROM @OriginalProperties)
  OR EXISTS(SELECT Class,MinorId,NameBytes,ValueBytes,BaseType,PrecisionValue,ScaleValue,MaxLengthValue,CollationValue FROM @OriginalProperties
   EXCEPT SELECT class,minor_id,CONVERT(varbinary(256),name),CONVERT(varbinary(max),value),SQL_VARIANT_PROPERTY(value,'BaseType'),SQL_VARIANT_PROPERTY(value,'Precision'),SQL_VARIANT_PROPERTY(value,'Scale'),SQL_VARIANT_PROPERTY(value,'MaxLength'),SQL_VARIANT_PROPERTY(value,'Collation')
   FROM sys.extended_properties WHERE major_id=@OriginalId AND class IN(1,2))
  OR EXISTS(SELECT class,minor_id,CONVERT(varbinary(256),name),CONVERT(varbinary(max),value),SQL_VARIANT_PROPERTY(value,'BaseType'),SQL_VARIANT_PROPERTY(value,'Precision'),SQL_VARIANT_PROPERTY(value,'Scale'),SQL_VARIANT_PROPERTY(value,'MaxLength'),SQL_VARIANT_PROPERTY(value,'Collation')
   FROM sys.extended_properties WHERE major_id=@OriginalId AND class IN(1,2)
   EXCEPT SELECT Class,MinorId,NameBytes,ValueBytes,BaseType,PrecisionValue,ScaleValue,MaxLengthValue,CollationValue FROM @OriginalProperties)
  THROW 54930,N'Predicate fixture rollback changed original metadata.',23;
 IF @OriginalXactAbort=1 SET XACT_ABORT ON; ELSE SET XACT_ABORT OFF;
 IF CASE WHEN(@@OPTIONS&16384)=0 THEN 0 ELSE 1 END<>@OriginalXactAbort
  THROW 54930,N'Predicate fixture option restore differs.',23;
END TRY BEGIN CATCH
 IF @OwnTransaction=1 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION;
 IF @OriginalXactAbort=1 SET XACT_ABORT ON; ELSE SET XACT_ABORT OFF;
 THROW;
END CATCH;
DROP TABLE dbo.SyntheticGateComputed;
DROP TABLE dbo.SyntheticGateNormal;
GO
