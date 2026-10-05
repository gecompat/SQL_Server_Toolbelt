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
DROP TABLE #SchemaAnswer;
PRINT N'PASS JSON_SCHEMA_NATIVE_CONTRACT CASES 26';
GO
