SET NOCOUNT ON;
DECLARE @Json nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'{"a":'),40)+N'"'+REPLICATE(CONVERT(nvarchar(max),N'a'),1000000)+N'"'+REPLICATE(N'}',40);
IF NOT EXISTS(SELECT 1 FROM toolbelt_json.TVF_ResolveJsonPointer(@Json,REPLICATE(N'/a',40),DEFAULT,DEFAULT) WHERE Status='INVALID' AND ErrorCode='WORK_LIMIT' AND Value IS NULL) THROW 52990,N'JSON Pointer parser work.',1;
IF NOT EXISTS(SELECT 1 FROM toolbelt_json.TVF_ResolveJsonPointer(N'{"a":null}',N'/a',DEFAULT,DEFAULT) WHERE Status='JSON_NULL') THROW 52990,N'JSON Pointer null.',2;
GO
