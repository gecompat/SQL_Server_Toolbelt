SET NOCOUNT ON;
DECLARE @A nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),4096),@B nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'b'),4096);
IF NOT EXISTS(SELECT 1 FROM toolbelt_string.TVF_LevenshteinDistance(@A,@B,NULL,N'large') WHERE Distance=4096 AND ExceedsMaxDistance=0 AND ErrorCode=0)
 THROW 55091,N'Levenshtein-16M-Grenze verletzt.',1;
IF NOT EXISTS(SELECT 1 FROM toolbelt_string.TVF_OsaDistance(@A,@B,NULL,N'large') WHERE Distance=4096 AND ExceedsMaxDistance=0 AND ErrorCode=0)
 THROW 55091,N'OSA-16M-Grenze verletzt.',2;
IF NOT EXISTS(SELECT 1 FROM toolbelt_string.TVF_OsaDistance(@A,@B+N'b',NULL,N'large') WHERE Distance IS NULL AND ExceedsMaxDistance IS NULL AND ErrorCode=6)
 THROW 55091,N'Above-16M-Priorität verletzt.',3;
SET @A=REPLICATE(CONVERT(nvarchar(max),N'a'),32766)+N'ab';SET @B=REPLICATE(CONVERT(nvarchar(max),N'a'),32766)+N'ba';
IF NOT EXISTS(SELECT 1 FROM toolbelt_string.TVF_OsaDistance(@A,@B,1,N'large') WHERE Distance=1 AND ErrorCode=0)
 THROW 55091,N'Large-OSA-Band verletzt.',4;
IF NOT EXISTS(SELECT 1 FROM toolbelt_string.TVF_LevenshteinDistance(@A,@B,2,N'large') WHERE Distance=2 AND ErrorCode=0)
 THROW 55091,N'Large-Levenshtein-Band verletzt.',5;
IF NOT EXISTS(SELECT 1 FROM toolbelt_string.TVF_OsaDistance(REPLICATE(CONVERT(nvarchar(max),N'a'),32769),N'',0,N'large') WHERE Distance IS NULL AND ExceedsMaxDistance IS NULL AND ErrorCode=5)
 THROW 55091,N'Scalarcap vor Threshold verletzt.',6;
IF NOT EXISTS(SELECT 1 FROM toolbelt_string.TVF_OsaDistance(REPLICATE(CONVERT(nvarchar(max),N'a'),65537),N'',0,N'large') WHERE ErrorCode=3)
 THROW 55091,N'Rawcap vor Threshold verletzt.',7;
SELECT N'PASS' AS Status;
