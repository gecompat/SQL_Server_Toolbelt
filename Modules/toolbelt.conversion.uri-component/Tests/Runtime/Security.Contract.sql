SET NOCOUNT ON;
DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),32768);
IF NOT EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_UriComponentEncodeStatus(@Value) WHERE Status='OK' AND EncodedValue=@Value) THROW 52990,N'URI exact encode.',1;
IF NOT EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(@Value) WHERE Status='OK' AND DecodedValue=@Value) THROW 52990,N'URI exact decode.',2;
SET @Value+=N'a';
IF NOT EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_UriComponentEncodeStatus(@Value) WHERE Status='LIMIT' AND EncodedValue IS NULL) THROW 52990,N'URI encode limit.',3;
IF toolbelt_conversion.SVF_UriComponentDecode(@Value) IS NOT NULL OR toolbelt_conversion.SVF_UriComponentEncode(@Value) IS NOT NULL THROW 52990,N'URI legacy limits.',4;
IF NOT EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(N'%FF') WHERE Status='INVALID' AND IsValid=0) THROW 52990,N'URI invalid status.',5;
GO
