-- ============================================================================
-- Objekt: toolbelt_json.USP_ValidateJsonSchema; Typ: Stored Procedure
-- Zweck: Read-only Schemaurteil im begrenzten Profil toolbelt-2020-12-v1.
-- Vertrag: Documentation/Architecture/JSON_SCHEMA_CONTRACT.md; USP 1.0.
-- Parameter: zwei JSON-Inputs, explizites Profil, nur absenkbare Ressourcen.
-- Resultset: SUMMARY plus bis MaxErrors ERROR; zehn typisierte Spalten.
-- Dependencies: SAFE JsonCore/JsonSchema; ResultTable >=1.0.0, same_database.
-- Rechte: bestehende EXECUTE-/SELECT-Rechte; keine Rechteausweitung.
-- Versionen: SQL Server 2019/2022/2025, Compatibility >=150; Windows/Linux.
-- Fehler: 55600/1 Argument, 55601/1 Bridge; Engine-/Helperfehler unverändert.
-- Performance: iterativer, global budgetierter CLR-Pfad ohne SQL-Kontextzugriff.
-- Grenzen: kein volles Draftprofil; kein Download, Coercion oder Datenänderung.
-- ============================================================================
CREATE OR ALTER PROCEDURE toolbelt_json.USP_ValidateJsonSchema
 @Json nvarchar(max)=NULL,
 @Schema nvarchar(max)=NULL,
 @Profile varchar(32)='toolbelt-2020-12-v1',
 @MaxDocumentBytes bigint=16777216,
 @MaxSchemaBytes bigint=1048576,
 @MaxDepth int=128,
 @MaxEvaluationSteps bigint=1000000,
 @MaxErrors int=100,
 @ResultTable sysname=NULL,
 @KeepData bit=0,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @KeepData=COALESCE(@KeepData,0),@Debug=COALESCE(@Debug,0),@Hilfe=COALESCE(@Hilfe,0);
 IF @Hilfe=1
 BEGIN
  DECLARE @Help TABLE(Section varchar(32) NOT NULL,Ordinal int NOT NULL,ItemName sysname NULL,SqlDataType varchar(256) NULL,IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,Description nvarchar(max) NOT NULL,ExampleSql nvarchar(max) NULL);
  INSERT @Help VALUES
  ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Vollständiges Urteil im begrenzten Profil; Diagnosekürzung beendet die Evaluation nicht. LIMIT hat kein Boolurteil.',NULL),
  ('PARAMETER',1,N'@Json','nvarchar(max)',0,1,N'NULL',N'Instanz; SQL-NULL liefert SQL_NULL.',NULL),
  ('PARAMETER',2,N'@Schema','nvarchar(max)',0,1,N'NULL',N'Schema; vollständiger Preflight vor der Instanz, auch unbenutzte Definitionen.',NULL),
  ('PARAMETER',3,N'@Profile','varchar(32)',0,0,N'toolbelt-2020-12-v1',N'Exakte ASCII-Identität einschließlich Länge; kein Trim oder Casefold.',NULL),
  ('PARAMETER',4,N'@MaxDocumentBytes','bigint',0,0,N'16777216',N'UTF16-Bytes: 1..16777216; Überschreitung LIMIT/DOCUMENT_BYTES.',NULL),
  ('PARAMETER',5,N'@MaxSchemaBytes','bigint',0,0,N'1048576',N'UTF16-Bytes: 1..1048576; Überschreitung LIMIT/SCHEMA_BYTES.',NULL),
  ('PARAMETER',6,N'@MaxDepth','int',0,0,N'128',N'1..128 offene Container; begrenzter Parser stoppt beim Überschreiten.',NULL),
  ('PARAMETER',7,N'@MaxEvaluationSteps','bigint',0,0,N'1000000',N'1..1000000 abstrakte Arbeitseinheiten für alle Phasen; keine CPUzeitgarantie.',NULL),
  ('PARAMETER',8,N'@MaxErrors','int',0,0,N'100',N'0..100 Diagnosen; SUMMARY bleibt erhalten, Urteil erfordert vollständige Evaluation.',NULL),
  ('PARAMETER',9,N'@ResultTable','sysname',0,1,N'NULL',N'NULL: SELECT; sonst vorhandene caller-lokale #Temp gemäß ResultTable-Vertrag.',NULL),
  ('PARAMETER',10,N'@KeepData','bit',0,1,N'0',N'Replace=0, Append=1; NULL entspricht 0.',NULL),
  ('PARAMETER',11,N'@Debug','tinyint',0,1,N'0',N'Nur Messages ohne Payload/Endpoint; NULL entspricht 0.',NULL),
  ('PARAMETER',12,N'@Hilfe','bit',0,1,N'0',N'Help zuerst ohne Argument-/Dependency-/Tempprüfung oder Seiteneffekte.',NULL),
  ('RESULT_COLUMN',1,N'RowKind','varchar(8)',1,0,NULL,N'SUMMARY oder ERROR.',NULL),
  ('RESULT_COLUMN',2,N'ErrorOrdinal','int',1,0,NULL,N'SUMMARY=0, ERROR=1..N; explizite Ergebnisordnung.',NULL),
  ('RESULT_COLUMN',3,N'Status','varchar(24)',1,0,NULL,N'VALID/INVALID_INSTANCE/INVALID_SCHEMA/INVALID_JSON/UNSUPPORTED/SQL_NULL/LIMIT.',NULL),
  ('RESULT_COLUMN',4,N'Profile','varchar(32)',1,0,NULL,N'Exaktes angewandtes Profil.',NULL),
  ('RESULT_COLUMN',5,N'IsValid','bit',0,1,NULL,N'1 bei VALID, 0 bei vollständigem INVALID_INSTANCE; sonst NULL.',NULL),
  ('RESULT_COLUMN',6,N'DocumentPointer','nvarchar(max)',0,1,NULL,N'RFC6901-Ort in der Instanz; leer=root, NULL=unbekannt/nicht betroffen.',NULL),
  ('RESULT_COLUMN',7,N'SchemaPointer','nvarchar(max)',0,1,NULL,N'RFC6901-Ort im Schema; vollständige unveränderte decoded Keys.',NULL),
  ('RESULT_COLUMN',8,N'Keyword','nvarchar(128)',0,1,NULL,N'Zuständiges Keyword; NULL wenn nicht bekannt oder länger als 128 Einheiten.',NULL),
  ('RESULT_COLUMN',9,N'ErrorCode','varchar(32)',0,1,NULL,N'Kanonischer Fehlercode; VALID-SUMMARY ohne Code.',NULL),
  ('RESULT_COLUMN',10,N'ErrorsTruncated','bit',1,0,NULL,N'Unterdrückte Diagnosen; auf allen Zeilen gleicher Endzustand.',NULL),
  ('ERROR',1,N'55600/1',NULL,NULL,NULL,NULL,N'Ungültiges Profil oder Ressourcenargument.',NULL),
  ('ERROR',2,N'55601/1',NULL,NULL,NULL,NULL,N'Interner Transport-/Namespace-/Dependencyvertrag verletzt; kein Fachurteil.',NULL),
  ('LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'Kein volles Draft2020-12; lokale nichtrekursive Refs, exakte Zahlen/Unicode, kein externer Zugriff.',NULL),
  ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Synthetische Instanz mit einfachem Schema.',N'EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N''42'',@Schema=N''{"type":"integer"}'';');
  SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_json' AS sysname) SchemaName,
   CAST(N'USP_ValidateJsonSchema' AS sysname) ObjectName,Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql
  FROM @Help ORDER BY CASE Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4 WHEN 'LIMITATION' THEN 5 ELSE 6 END,Ordinal;
  RETURN;
 END;
 IF @Profile IS NULL OR CONVERT(varbinary(max),@Profile)<>CONVERT(varbinary(max),'toolbelt-2020-12-v1')
 OR @MaxDocumentBytes IS NULL OR @MaxDocumentBytes NOT BETWEEN 1 AND 16777216
 OR @MaxSchemaBytes IS NULL OR @MaxSchemaBytes NOT BETWEEN 1 AND 1048576
 OR @MaxDepth IS NULL OR @MaxDepth NOT BETWEEN 1 AND 128
 OR @MaxEvaluationSteps IS NULL OR @MaxEvaluationSteps NOT BETWEEN 1 AND 1000000
 OR @MaxErrors IS NULL OR @MaxErrors NOT BETWEEN 0 AND 100
 THROW 55600,N'JSON Schema: ungültiges Profil oder Ressourcenargument.',1;
 -- Guard vor der separaten Batchcompilation verhindert Temp-Eclipsing.
 IF OBJECT_ID(N'tempdb..#tbx_JsonSchema_Result',N'U') IS NOT NULL
 OR LEFT(LOWER(@ResultTable COLLATE Latin1_General_100_BIN2),5) COLLATE Latin1_General_100_BIN2=N'#tbx_'
 THROW 55601,N'JSON Schema: reservierter interner Temp-Namespace ist belegt.',1;
 DECLARE @Dependency int=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P'),@Version nvarchar(64),@Major int,@Minor int,@Patch int;
 SELECT @Version=TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.result-table.Version';
 SELECT @Major=TRY_CONVERT(int,PARSENAME(@Version,3)),@Minor=TRY_CONVERT(int,PARSENAME(@Version,2)),@Patch=TRY_CONVERT(int,PARSENAME(@Version,1));
 IF @Dependency IS NULL OR @Major IS NULL OR @Major<1 OR @Minor IS NULL OR @Minor<0 OR @Patch IS NULL OR @Patch<0
 OR CONVERT(varbinary(max),@Version)<>CONVERT(varbinary(max),CONCAT(@Major,N'.',@Minor,N'.',@Patch))
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@Dependency AND minor_id=0 AND name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),value))=CONVERT(varbinary(max),N'toolbelt.core.result-table'))
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@Dependency AND minor_id=0 AND name=N'Toolbelt.ModuleVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(64),value))=CONVERT(varbinary(max),@Version))
 THROW 55601,N'JSON Schema: registrierte ResultTable-Dependency >=1.0.0 fehlt oder ist ungeeignet.',1;
 DECLARE @Sql nvarchar(max)=N'
 SET NOCOUNT ON;
 DECLARE @Bridge TABLE(RowKind varchar(8) COLLATE Latin1_General_100_BIN2,ErrorOrdinal int,
 Status varchar(24) COLLATE Latin1_General_100_BIN2,Profile varchar(32) COLLATE Latin1_General_100_BIN2,
 IsValid bit,DocumentPointer nvarchar(max) COLLATE Latin1_General_100_BIN2,SchemaPointer nvarchar(max) COLLATE Latin1_General_100_BIN2,
 Keyword nvarchar(128) COLLATE Latin1_General_100_BIN2,ErrorCode varchar(32) COLLATE Latin1_General_100_BIN2,ErrorsTruncated bit);
 INSERT @Bridge(RowKind,ErrorOrdinal,Status,Profile,IsValid,DocumentPointer,SchemaPointer,Keyword,ErrorCode,ErrorsTruncated)
 SELECT RowKind,ErrorOrdinal,Status,Profile,IsValid,DocumentPointer,SchemaPointer,Keyword,ErrorCode,ErrorsTruncated
 FROM toolbelt_json.FT_ValidateJsonSchemaInternal(@Json,@Schema,@Profile,@MaxDocumentBytes,@MaxSchemaBytes,@MaxDepth,@MaxEvaluationSteps,@MaxErrors);
 DECLARE @Count int=(SELECT COUNT(*) FROM @Bridge),@Status varchar(24),@Truncated bit;
 SELECT @Status=Status,@Truncated=ErrorsTruncated FROM @Bridge WHERE RowKind=''SUMMARY'' AND ErrorOrdinal=0;
 IF @Count NOT BETWEEN 1 AND @MaxErrors+1
 OR (SELECT COUNT(*) FROM @Bridge WHERE RowKind=''SUMMARY'' AND ErrorOrdinal=0)<>1
 OR EXISTS(SELECT 1 FROM @Bridge WHERE RowKind IS NULL OR ErrorOrdinal IS NULL OR Status IS NULL OR Profile IS NULL OR ErrorsTruncated IS NULL
  OR CONVERT(varbinary(max),Profile)<>CONVERT(varbinary(max),@Profile)
  OR Status NOT IN (''VALID'',''INVALID_INSTANCE'',''INVALID_SCHEMA'',''INVALID_JSON'',''UNSUPPORTED'',''SQL_NULL'',''LIMIT'')
  OR DATALENGTH(Status)<>CASE Status WHEN ''VALID'' THEN 5 WHEN ''INVALID_INSTANCE'' THEN 16 WHEN ''INVALID_SCHEMA'' THEN 14 WHEN ''INVALID_JSON'' THEN 12 WHEN ''UNSUPPORTED'' THEN 11 WHEN ''SQL_NULL'' THEN 8 WHEN ''LIMIT'' THEN 5 END
  OR CONVERT(varbinary(max),Status)<>CONVERT(varbinary(max),@Status) OR ErrorsTruncated<>@Truncated
  OR (Status=''VALID'' AND (IsValid IS NULL OR IsValid<>1))
  OR (Status=''INVALID_INSTANCE'' AND (IsValid IS NULL OR IsValid<>0))
  OR (Status NOT IN (''VALID'',''INVALID_INSTANCE'') AND IsValid IS NOT NULL)
  OR (ErrorOrdinal=0 AND RowKind<>''SUMMARY'') OR (ErrorOrdinal>0 AND RowKind<>''ERROR'')
  OR DATALENGTH(RowKind)<>CASE WHEN ErrorOrdinal=0 THEN 7 ELSE 5 END
  OR ErrorOrdinal NOT BETWEEN 0 AND @Count-1)
 OR EXISTS(SELECT ErrorOrdinal FROM @Bridge GROUP BY ErrorOrdinal HAVING COUNT(*)<>1)
 THROW 55601,N''JSON Schema: interner Bridgevertrag verletzt.'',1;
 CREATE TABLE #tbx_JsonSchema_Result(RowKind varchar(8) COLLATE Latin1_General_100_BIN2 NOT NULL,ErrorOrdinal int NOT NULL,
 Status varchar(24) COLLATE Latin1_General_100_BIN2 NOT NULL,Profile varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,
 IsValid bit NULL,DocumentPointer nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,SchemaPointer nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
 Keyword nvarchar(128) COLLATE Latin1_General_100_BIN2 NULL,ErrorCode varchar(32) COLLATE Latin1_General_100_BIN2 NULL,ErrorsTruncated bit NOT NULL);
 INSERT #tbx_JsonSchema_Result(RowKind,ErrorOrdinal,Status,Profile,IsValid,DocumentPointer,SchemaPointer,Keyword,ErrorCode,ErrorsTruncated)
 SELECT RowKind,ErrorOrdinal,Status,Profile,IsValid,DocumentPointer,SchemaPointer,Keyword,ErrorCode,ErrorsTruncated FROM @Bridge;
 IF @Debug>0 RAISERROR(N''JSON Schema: vollständige Antwort materialisiert; Routing folgt.'',10,1) WITH NOWAIT;
 IF @ResultTable IS NULL
 BEGIN
  SELECT RowKind,ErrorOrdinal,Status,Profile,IsValid,DocumentPointer,SchemaPointer,Keyword,ErrorCode,ErrorsTruncated
  FROM #tbx_JsonSchema_Result ORDER BY ErrorOrdinal;
  RETURN;
 END;
 DECLARE @Own bit=CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END,@Saved bit=0,
 @Savepoint varchar(32)=REPLACE(CONVERT(varchar(36),NEWID()),''-'',''''),@Insert nvarchar(max);
 BEGIN TRY
  IF @Own=1 BEGIN TRANSACTION;
  ELSE BEGIN SAVE TRANSACTION @Savepoint; SET @Saved=1; END;
  EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N''#tbx_JsonSchema_Result'',@KeepData=@KeepData,@Debug=@Debug;
  SET @Insert=N''INSERT ''+QUOTENAME(@ResultTable)+N''(RowKind,ErrorOrdinal,Status,Profile,IsValid,DocumentPointer,SchemaPointer,Keyword,ErrorCode,ErrorsTruncated)
  SELECT RowKind,ErrorOrdinal,Status,Profile,IsValid,DocumentPointer,SchemaPointer,Keyword,ErrorCode,ErrorsTruncated FROM #tbx_JsonSchema_Result;'';
  EXEC sys.sp_executesql @Insert;
  IF @Own=1 COMMIT;
 END TRY
 BEGIN CATCH
  IF @Own=1 AND XACT_STATE()<>0 ROLLBACK;
  ELSE IF @Saved=1 AND XACT_STATE()=1 ROLLBACK TRANSACTION @Savepoint;
  THROW;
 END CATCH;';
 EXEC sys.sp_executesql @Sql,N'@Json nvarchar(max),@Schema nvarchar(max),@Profile varchar(32),@MaxDocumentBytes bigint,@MaxSchemaBytes bigint,@MaxDepth int,@MaxEvaluationSteps bigint,@MaxErrors int,@ResultTable sysname,@KeepData bit,@Debug tinyint',
 @Json,@Schema,@Profile,@MaxDocumentBytes,@MaxSchemaBytes,@MaxDepth,@MaxEvaluationSteps,@MaxErrors,@ResultTable,@KeepData,@Debug;
END;
GO
