SET NOCOUNT ON;
DECLARE @Exact varbinary(max)=CONVERT(varbinary(max),REPLICATE(CONVERT(varchar(max),'a'),16777216)),@Text varchar(max);
IF NOT EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_Base64EncodeStatus(NULL,0) WHERE Status='SQL_NULL' AND EncodedValue IS NULL) THROW 52990,N'Base64 NULL status.',1;
SELECT @Text=EncodedValue FROM toolbelt_conversion.TVF_Base64EncodeStatus(@Exact,0) WHERE Status='OK';
IF @Text IS NULL THROW 52990,N'Base64 encode exact limit.',2;
IF NOT EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_Base64DecodeStatus(@Text) WHERE Status='OK' AND DecodedValue=@Exact) THROW 52990,N'Base64 exact roundtrip.',3;
SET @Exact=@Exact+0x61;
IF NOT EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_Base64EncodeStatus(@Exact,0) WHERE Status='LIMIT' AND EncodedValue IS NULL) THROW 52990,N'Base64 encode limit.',4;
IF toolbelt_conversion.SVF_Base64Encode(@Exact,0) IS NOT NULL THROW 52990,N'Base64 legacy oversize.',5;
SET @Text=REPLICATE(CONVERT(varchar(max),' '),25165824);
IF NOT EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_Base64DecodeStatus(@Text) WHERE Status='OK' AND DecodedValue=0x) THROW 52990,N'Base64 raw exact limit.',6;
SET @Text=@Text+' ';
IF NOT EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_Base64DecodeStatus(@Text) WHERE Status='LIMIT' AND DecodedValue IS NULL) THROW 52990,N'Base64 raw limit.',7;
SET @Text=REPLICATE(CONVERT(varchar(max),'A'),22369624);
IF NOT EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_Base64DecodeStatus(@Text) WHERE Status='LIMIT' AND DecodedValue IS NULL) THROW 52990,N'Base64 decoded limit.',8;
IF NOT EXISTS(SELECT 1 FROM toolbelt_conversion.TVF_Base64DecodeStatus('!') WHERE Status='INVALID') THROW 52990,N'Base64 invalid status.',9;
GO
