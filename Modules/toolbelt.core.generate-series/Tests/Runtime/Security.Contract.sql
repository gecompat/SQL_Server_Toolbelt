SET NOCOUNT ON;
IF (SELECT COUNT_BIG(*) FROM toolbelt_core.TVF_GenerateSeriesBigIntStatus(1,1000000,1) WHERE Status='OK')<>1000000 THROW 52990,N'Series exact rows.',1;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.TVF_GenerateSeriesBigIntStatus(1,1000001,1) WHERE Status='LIMIT' AND Value IS NULL AND RequestedRows=1000001) THROW 52990,N'Series limit.',2;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.TVF_GenerateSeriesBigIntStatus(-9223372036854775808,9223372036854775807,1) WHERE Status='LIMIT' AND RequestedRows=18446744073709551616) THROW 52990,N'Series exact wide count.',3;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.TVF_GenerateSeriesBigIntStatus(9223372036854775807,-9223372036854775808,-9223372036854775808) WHERE Status='OK' AND RequestedRows=2) THROW 52990,N'Series minimum step.',4;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.TVF_GenerateSeriesBigIntStatus(1,1,0) WHERE Status='INVALID') THROW 52990,N'Series zero step status.',5;
GO
