-- Synthetischer nativer API-Vertrag; keine realen Payloads oder Runtimeartefakte.
SET NOCOUNT ON;
DECLARE @Cases TABLE(Id int IDENTITY(1,1),Json nvarchar(max),[Schema] nvarchar(max),
 ExpectedStatus varchar(24),ExpectedValid bit,ExpectedCode varchar(32),MaxErrors int);
INSERT @Cases VALUES
(N'1',N'true','VALID',1,NULL,100),
(N'1',N'false','INVALID_INSTANCE',0,'INSTANCE_VIOLATION',100),
(NULL,N'true','SQL_NULL',NULL,'SQL_NULL',100),
(N'{',NULL,'SQL_NULL',NULL,'SQL_NULL',100),
(N'{',N'{','INVALID_SCHEMA',NULL,'JSON_SYNTAX',100),
(N'{',N'true','INVALID_JSON',NULL,'JSON_SYNTAX',100),
(N'1',N'{"type":"integer","minimum":1,"maximum":1}','VALID',1,NULL,100),
(N'1.000',N'{"type":"integer"}','VALID',1,NULL,100),
(N'0.1',N'{"type":"integer"}','INVALID_INSTANCE',0,'INSTANCE_VIOLATION',100),
(N'12345678901234567890123456789012345678901',N'{"minimum":12345678901234567890123456789012345678900}','VALID',1,NULL,100),
(N'1e999999999999999999999999999999999999999',N'{"maximum":1e999999999999999999999999999999999999998}','INVALID_INSTANCE',0,'INSTANCE_VIOLATION',100),
(N'0',N'{"minimum":2,"maximum":1}','INVALID_INSTANCE',0,'INSTANCE_VIOLATION',0),
(N'{}',N'{"required":["a","b"]}','INVALID_INSTANCE',0,'INSTANCE_VIOLATION',1),
(N'{"a":1,"\u0061":2}',N'true','INVALID_JSON',NULL,'DUPLICATE_KEY',100),
(N'1',N'{"title":"a","\u0074itle":"b"}','INVALID_SCHEMA',NULL,'DUPLICATE_KEY',100),
(N'1',N'{"$defs":{"unused":{"format":"date"}}}','UNSUPPORTED',NULL,'KEYWORD_UNSUPPORTED',100),
(N'1',N'{"$ref":"#"}','UNSUPPORTED',NULL,'REF_CYCLE',100),
(N'1',N'{"$ref":"https://example.com/schema"}','UNSUPPORTED',NULL,'EXTERNAL_REF',100),
(N'1',N'{"$defs":{"integer":{"type":"integer"}},"$ref":"#/$defs/integer","minimum":1}','VALID',1,NULL,100),
(N'"\ud800"',N'true','UNSUPPORTED',NULL,'UNPAIRED_SURROGATE',100),
(N'"\ud83d\ude00"',N'{"minLength":1,"maxLength":1}','VALID',1,NULL,100),
(N'"\u0000"',N'{"maxLength":1}','VALID',1,NULL,100),
(N'[1,"a"]',N'{"prefixItems":[{"type":"integer"}],"items":{"type":"string"}}','VALID',1,NULL,100),
(N'{"type":1}',N'{"properties":{"type":{"type":"integer"}},"additionalProperties":false}','VALID',1,NULL,100);
CREATE TABLE #SchemaAnswer(RowKind varchar(8) NOT NULL,ErrorOrdinal int NOT NULL,Status varchar(24) NOT NULL,
 Profile varchar(32) NOT NULL,IsValid bit NULL,DocumentPointer nvarchar(max) NULL,SchemaPointer nvarchar(max) NULL,
 Keyword nvarchar(128) NULL,ErrorCode varchar(32) NULL,ErrorsTruncated bit NOT NULL);
DECLARE @Id int=1,@Count int=(SELECT COUNT(*) FROM @Cases),@Json nvarchar(max),@Schema nvarchar(max),
 @Status varchar(24),@Valid bit,@Code varchar(32),@Errors int;
WHILE @Id<=@Count
BEGIN
 SELECT @Json=Json,@Schema=[Schema],@Status=ExpectedStatus,@Valid=ExpectedValid,@Code=ExpectedCode,@Errors=MaxErrors FROM @Cases WHERE Id=@Id;
 DELETE #SchemaAnswer;
 INSERT #SchemaAnswer EXEC toolbelt_json.USP_ValidateJsonSchema @Json=@Json,@Schema=@Schema,@MaxErrors=@Errors;
 IF (SELECT COUNT(*) FROM #SchemaAnswer WHERE RowKind='SUMMARY' AND ErrorOrdinal=0)<>1
  OR NOT EXISTS(SELECT 1 FROM #SchemaAnswer WHERE RowKind='SUMMARY' AND Status=@Status
   AND (IsValid=@Valid OR (IsValid IS NULL AND @Valid IS NULL))
   AND (ErrorCode=@Code OR (ErrorCode IS NULL AND @Code IS NULL)))
  OR EXISTS(SELECT 1 FROM #SchemaAnswer WHERE Status<>@Status OR Profile<>'toolbelt-2020-12-v1'
   OR (IsValid<>@Valid) OR (IsValid IS NULL AND @Valid IS NOT NULL) OR (IsValid IS NOT NULL AND @Valid IS NULL))
  OR (SELECT COUNT(*) FROM #SchemaAnswer)>@Errors+1
  THROW 55690,N'Synthetic schema status/shape oracle failed.',1;
 IF @Id IN(12,13) AND EXISTS(SELECT 1 FROM #SchemaAnswer WHERE ErrorsTruncated<>1)
  THROW 55690,N'Diagnostic cap changed complete verdict or truncation.',2;
 SET @Id+=1;
END;
DELETE #SchemaAnswer;
INSERT #SchemaAnswer EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'1',@Schema=N'true',@MaxEvaluationSteps=1;
IF NOT EXISTS(SELECT 1 FROM #SchemaAnswer WHERE ErrorOrdinal=0 AND Status='LIMIT' AND IsValid IS NULL AND ErrorCode='EVALUATION_LIMIT')
 THROW 55690,N'Synthetic global budget oracle failed.',3;
DELETE #SchemaAnswer;
DECLARE @Deep nvarchar(max)=REPLICATE(N'[',129)+N'0'+REPLICATE(N']',129);
INSERT #SchemaAnswer EXEC toolbelt_json.USP_ValidateJsonSchema @Json=@Deep,@Schema=N'true';
IF NOT EXISTS(SELECT 1 FROM #SchemaAnswer WHERE ErrorOrdinal=0 AND Status='LIMIT' AND IsValid IS NULL AND ErrorCode='DEPTH_LIMIT')
 THROW 55690,N'Synthetic depth oracle failed.',4;
DELETE #SchemaAnswer;
DECLARE @LongPrefix nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),4001),
 @LongJson nvarchar(max),@LongSchema nvarchar(max),@ExpectedDocumentPointer nvarchar(max),@ExpectedSchemaPointer nvarchar(max);
SELECT @LongJson=N'{"'+@LongPrefix+N'/~\u0000":1}',
 @LongSchema=N'{"properties":{"'+@LongPrefix+N'/~\u0000":false}}',
 @ExpectedDocumentPointer=N'/'+@LongPrefix+N'~1~0'+NCHAR(0),
 @ExpectedSchemaPointer=N'/properties/'+@LongPrefix+N'~1~0'+NCHAR(0);
INSERT #SchemaAnswer EXEC toolbelt_json.USP_ValidateJsonSchema @Json=@LongJson,@Schema=@LongSchema;
IF (SELECT COUNT(*) FROM #SchemaAnswer)<>2 OR NOT EXISTS(SELECT 1 FROM #SchemaAnswer
 WHERE RowKind='ERROR' AND ErrorOrdinal=1 AND Status='INVALID_INSTANCE' AND IsValid=0
 AND CONVERT(varbinary(max),DocumentPointer)=CONVERT(varbinary(max),@ExpectedDocumentPointer)
 AND CONVERT(varbinary(max),SchemaPointer)=CONVERT(varbinary(max),@ExpectedSchemaPointer))
 THROW 55690,N'Long escaped NUL pointer was truncated or changed.',5;
DELETE #SchemaAnswer;
INSERT #SchemaAnswer EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'{',@Schema=N'true',@MaxSchemaBytes=7;
IF NOT EXISTS(SELECT 1 FROM #SchemaAnswer WHERE ErrorOrdinal=0 AND Status='LIMIT' AND IsValid IS NULL AND ErrorCode='SCHEMA_BYTES')
 THROW 55690,N'Schema byte limit priority changed.',6;
DELETE #SchemaAnswer;
INSERT #SchemaAnswer EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'null',@Schema=N'true',@MaxDocumentBytes=7;
IF NOT EXISTS(SELECT 1 FROM #SchemaAnswer WHERE ErrorOrdinal=0 AND Status='LIMIT' AND IsValid IS NULL AND ErrorCode='DOCUMENT_BYTES')
 THROW 55690,N'Document byte limit changed.',7;
DELETE #SchemaAnswer;
INSERT #SchemaAnswer EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'null',@Schema=N'{',@MaxDocumentBytes=1;
IF NOT EXISTS(SELECT 1 FROM #SchemaAnswer WHERE ErrorOrdinal=0 AND Status='INVALID_SCHEMA' AND IsValid IS NULL AND ErrorCode='JSON_SYNTAX')
 THROW 55690,N'Schema syntax must precede document byte limit.',8;
-- Schema-/Graphorte nach codiertem Pointer, auch vor frühen Formfehlern.
DECLARE @OrderCases TABLE(Id int IDENTITY(1,1),[Schema] nvarchar(max),
 ExpectedStatus varchar(24),ExpectedCode varchar(32),ExpectedPointer nvarchar(max));
INSERT @OrderCases VALUES
(N'{"$defs":{"/":1,"~":[],"z":null}}','INVALID_SCHEMA','SCHEMA_FORM',N'/$defs/z'),
(N'{"$defs":{"/":{"pattern":"x"},"~":{"pattern":"x"},"z":{"pattern":"x"}}}','UNSUPPORTED','KEYWORD_UNSUPPORTED',N'/$defs/z/pattern'),
(N'{"$defs":{"/":1,"z":{"pattern":"x"}}}','UNSUPPORTED','KEYWORD_UNSUPPORTED',N'/$defs/z/pattern'),
(N'{"prefixItems":[true,true,1,true,true,true,true,true,true,true,null]}','INVALID_SCHEMA','SCHEMA_FORM',N'/prefixItems/10'),
(N'{"$defs":{"/":{"$ref":"#/$defs/~1"},"~":{"$ref":"#/$defs/~0"},"z":{"$ref":"#/$defs/z"}}}','UNSUPPORTED','REF_CYCLE',N'/$defs/z/$ref'),
(N'{"prefixItems":[true,true,{"$ref":"#/prefixItems/2"},true,true,true,true,true,true,true,{"$ref":"#/prefixItems/10"}]}','UNSUPPORTED','REF_CYCLE',N'/prefixItems/10/$ref');
DECLARE @OrderId int=1,@OrderCount int=(SELECT COUNT(*) FROM @OrderCases),@OrderPointer nvarchar(max);
WHILE @OrderId<=@OrderCount
BEGIN
 SELECT @Schema=[Schema],@Status=ExpectedStatus,@Code=ExpectedCode,@OrderPointer=ExpectedPointer FROM @OrderCases WHERE Id=@OrderId;
 DELETE #SchemaAnswer;
 INSERT #SchemaAnswer EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'null',@Schema=@Schema;
 IF (SELECT COUNT(*) FROM #SchemaAnswer)<>2 OR EXISTS(SELECT 1 FROM #SchemaAnswer
  WHERE Status<>@Status OR IsValid IS NOT NULL OR ErrorCode<>@Code OR ErrorsTruncated<>0
   OR SchemaPointer IS NULL OR CONVERT(varbinary(max),SchemaPointer)<>CONVERT(varbinary(max),@OrderPointer))
  OR NOT EXISTS(SELECT 1 FROM #SchemaAnswer WHERE RowKind='SUMMARY' AND ErrorOrdinal=0)
  OR NOT EXISTS(SELECT 1 FROM #SchemaAnswer WHERE RowKind='ERROR' AND ErrorOrdinal=1)
  THROW 55690,N'Encoded schema or graph pointer order changed.',9;
 SET @OrderId+=1;
END;
-- Instanzmember bleiben decodiert ordinal; Arrayevaluation bleibt numerisch.
DECLARE @MemberMode int=0;
WHILE @MemberMode<2
BEGIN
 DELETE #SchemaAnswer;
 SET @Schema=CASE @MemberMode WHEN 0 THEN N'{"properties":{"z":false,"/":false,"~":false}}' ELSE N'{"additionalProperties":false}' END;
 INSERT #SchemaAnswer EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'{"~":1,"z":1,"/":1}',@Schema=@Schema;
 IF (SELECT COUNT(*) FROM #SchemaAnswer)<>4
  OR NOT EXISTS(SELECT 1 FROM #SchemaAnswer WHERE RowKind='SUMMARY' AND ErrorOrdinal=0 AND Status='INVALID_INSTANCE' AND IsValid=0)
  OR (SELECT COUNT(*) FROM #SchemaAnswer WHERE RowKind='ERROR' AND Status='INVALID_INSTANCE' AND IsValid=0
   AND ((ErrorOrdinal=1 AND CONVERT(varbinary(max),DocumentPointer)=CONVERT(varbinary(max),N'/~1'))
    OR (ErrorOrdinal=2 AND CONVERT(varbinary(max),DocumentPointer)=CONVERT(varbinary(max),N'/z'))
    OR (ErrorOrdinal=3 AND CONVERT(varbinary(max),DocumentPointer)=CONVERT(varbinary(max),N'/~0'))))<>3
  THROW 55690,N'Decoded instance member order changed.',10;
 SET @MemberMode+=1;
END;
DELETE #SchemaAnswer;
INSERT #SchemaAnswer EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'[0,0,0,0,0,0,0,0,0,0,0]',
 @Schema=N'{"prefixItems":[true,true,false,true,true,true,true,true,true,true,false]}';
IF (SELECT COUNT(*) FROM #SchemaAnswer)<>3
 OR (SELECT COUNT(*) FROM #SchemaAnswer WHERE RowKind='ERROR' AND Status='INVALID_INSTANCE' AND IsValid=0
  AND ((ErrorOrdinal=1 AND CONVERT(varbinary(max),DocumentPointer)=CONVERT(varbinary(max),N'/2'))
   OR (ErrorOrdinal=2 AND CONVERT(varbinary(max),DocumentPointer)=CONVERT(varbinary(max),N'/10'))))<>2
 THROW 55690,N'Numeric instance array order changed.',11;
DELETE #SchemaAnswer;
INSERT #SchemaAnswer EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'null',
 @Schema=N'{"$defs":{"/":true,"~":true,"z":true}}',@MaxEvaluationSteps=200;
IF (SELECT COUNT(*) FROM #SchemaAnswer)<>1 OR NOT EXISTS(SELECT 1 FROM #SchemaAnswer
 WHERE RowKind='SUMMARY' AND ErrorOrdinal=0 AND Status='LIMIT' AND IsValid IS NULL AND ErrorCode='EVALUATION_LIMIT')
 THROW 55690,N'Encoded schema ordering must preserve bounded work failure.',12;
DROP TABLE #SchemaAnswer;
PRINT N'PASS JSON_SCHEMA_NATIVE_CONTRACT CASES 40';
GO
