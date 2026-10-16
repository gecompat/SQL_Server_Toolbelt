SET NOCOUNT ON;
IF NOT EXISTS(SELECT 1 FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{"a":null}',N'$.a') WHERE Status='FOUND' AND PathExists=1) THROW 52990,N'JSON Path found.',1;
DECLARE @Json nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'['),129)+N'0'+REPLICATE(N']',129);
IF NOT EXISTS(SELECT 1 FROM toolbelt_json.TVF_JsonPathExistsStatus(@Json,N'$') WHERE Status='LIMIT' AND PathExists IS NULL) THROW 52990,N'JSON Path depth.',2;
IF NOT EXISTS(SELECT 1 FROM toolbelt_json.TVF_JsonPathExists(@Json,N'$') WHERE PathExists IS NULL) THROW 52990,N'JSON Path legacy unknown.',3;
SET @Json=N'['+REPLICATE(CONVERT(nvarchar(max),N'0,'),10000)+N'0]';
IF NOT EXISTS(SELECT 1 FROM toolbelt_json.TVF_JsonPathExistsStatus(@Json,N'$[*]') WHERE Status='LIMIT' AND PathExists IS NULL) THROW 52990,N'JSON Path frontier.',4;
SET @Json=REPLICATE(CONVERT(nvarchar(max),N'{"a":'),40)+N'"'+REPLICATE(CONVERT(nvarchar(max),N'a'),1000000)+N'"'+REPLICATE(N'}',40);
IF NOT EXISTS(SELECT 1 FROM toolbelt_json.TVF_JsonPathExistsStatus(@Json,N'$'+REPLICATE(N'.a',40)) WHERE Status='LIMIT' AND PathExists IS NULL) THROW 52990,N'JSON Path parser work.',5;
GO
