SET NOCOUNT ON;
DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a,'),9999)+N'a';
IF (SELECT COUNT_BIG(*) FROM toolbelt_string.TVF_SplitByCharactersStatus(@Value,N',',1) WHERE Status='OK')<>10000 THROW 52990,N'Split exact tokens.',1;
SET @Value+=N',a';
IF NOT EXISTS(SELECT 1 FROM toolbelt_string.TVF_SplitByCharactersStatus(@Value,N',',1) WHERE Status='LIMIT' AND Value IS NULL AND Ordinal IS NULL) THROW 52990,N'Split token limit.',2;
IF EXISTS(SELECT 1 FROM toolbelt_string.TVF_SplitByCharacters(@Value,N',',1)) THROW 52990,N'Split partial legacy output.',3;
SET @Value=REPLICATE(CONVERT(nvarchar(max),N'a'),32768);
IF NOT EXISTS(SELECT 1 FROM toolbelt_string.TVF_SplitByCharactersStatus(@Value,N',',1) WHERE Status='OK' AND Value=@Value) THROW 52990,N'Split exact input.',4;
SET @Value+=N'a';
IF NOT EXISTS(SELECT 1 FROM toolbelt_string.TVF_SplitByCharactersStatus(@Value,N',',1) WHERE Status='LIMIT') THROW 52990,N'Split input limit.',5;
DECLARE @Separators nvarchar(4000)=N'',@Index int=1000;
WHILE @Index<1064 BEGIN SET @Separators+=NCHAR(@Index); SET @Index+=1; END;
IF NOT EXISTS(SELECT 1 FROM toolbelt_string.TVF_SplitByCharactersStatus(N'a',@Separators+@Separators,1) WHERE Status='OK') THROW 52990,N'Split distinct separator limit.',6;
SET @Separators+=NCHAR(1064);
IF NOT EXISTS(SELECT 1 FROM toolbelt_string.TVF_SplitByCharactersStatus(N'a',@Separators,1) WHERE Status='LIMIT') THROW 52990,N'Split separator overflow.',7;
IF NOT EXISTS(SELECT 1 FROM toolbelt_string.TVF_SplitByCharactersStatus(N',,,',N',',0) WHERE Status='EMPTY') THROW 52990,N'Split empty status.',8;
GO
