SET NOCOUNT ON;
DECLARE @Cases TABLE(Id int PRIMARY KEY,L nvarchar(max),R nvarchar(max),K int,Profile nvarchar(max),Lev int,Osa int,Exceeds bit,Code int);
INSERT @Cases VALUES
(1,N'kitten',N'sitting',NULL,N'standard',3,3,0,0),
(2,N'CA',N'AC',NULL,N'standard',2,1,0,0),
(3,N'CA',N'ABC',NULL,N'standard',3,3,0,0),
(4,N'A',N'a',NULL,N'standard',1,1,0,0),
(5,N'a ',N'a',NULL,N'standard',1,1,0,0),
(6,N'',N'',0,N'standard',0,0,0,0),
(7,N'a',N'bbb',1,N'standard',NULL,NULL,1,0),
(8,N'a',N'b',2147483647,N'standard',1,1,0,0),
(9,NULL,N'x',-1,N'invalid',NULL,NULL,NULL,0),
(10,N'x',N'x',-1,N'invalid',NULL,NULL,NULL,1),
(11,N'x',N'x',-1,N'standard',NULL,NULL,NULL,2),
(12,N'x',N'x',NULL,N'standard ',NULL,NULL,NULL,1),
(13,N'x',N'x',NULL,NULL,NULL,NULL,NULL,1);
DECLARE @Emoji nvarchar(max)=CONVERT(nvarchar(max),0x3DD800DE),@High nvarchar(max)=CONVERT(nvarchar(max),0x00D8);
INSERT @Cases VALUES
(14,@Emoji,N'',NULL,N'standard',1,1,0,0),
(15,N'e'+NCHAR(769),NCHAR(233),NULL,N'standard',2,2,0,0),
(16,NCHAR(0),N'',NULL,N'standard',1,1,0,0),
(17,@High,N'a',NULL,N'standard',NULL,NULL,NULL,4),
(18,REPLICATE(CONVERT(nvarchar(max),N'a'),1025),@High,NULL,N'standard',NULL,NULL,NULL,4),
(19,REPLICATE(CONVERT(nvarchar(max),N'a'),2049),@High,NULL,N'standard',NULL,NULL,NULL,3),
(20,REPLICATE(CONVERT(nvarchar(max),N'a'),1025),N'',NULL,N'standard',NULL,NULL,NULL,5);
IF EXISTS(SELECT 1 FROM @Cases c CROSS APPLY toolbelt_string.TVF_LevenshteinDistance(c.L,c.R,c.K,c.Profile) r
 WHERE r.ErrorCode IS NULL OR r.ErrorCode<>c.Code OR ISNULL(r.Distance,-1)<>ISNULL(c.Lev,-1) OR ISNULL(CONVERT(int,r.ExceedsMaxDistance),-1)<>ISNULL(CONVERT(int,c.Exceeds),-1))
 THROW 55090,N'Levenshtein-Vertragsoracle fehlgeschlagen.',1;
IF EXISTS(SELECT 1 FROM @Cases c CROSS APPLY toolbelt_string.TVF_OsaDistance(c.L,c.R,c.K,c.Profile) r
 WHERE r.ErrorCode IS NULL OR r.ErrorCode<>c.Code OR ISNULL(r.Distance,-1)<>ISNULL(c.Osa,-1) OR ISNULL(CONVERT(int,r.ExceedsMaxDistance),-1)<>ISNULL(CONVERT(int,c.Exceeds),-1))
 THROW 55090,N'OSA-Vertragsoracle fehlgeschlagen.',2;
IF (SELECT COUNT(*) FROM @Cases c CROSS APPLY toolbelt_string.TVF_LevenshteinDistance(c.L,c.R,c.K,c.Profile))<>20
 OR (SELECT COUNT(*) FROM @Cases c CROSS APPLY toolbelt_string.TVF_OsaDistance(c.L,c.R,c.K,c.Profile))<>20
 THROW 55090,N'Einzeilenvertrag verletzt.',3;
IF NOT EXISTS(SELECT 1 FROM toolbelt_string.TVF_LevenshteinDistance(N'CA',N'AC',DEFAULT,DEFAULT) WHERE Distance=2 AND ErrorCode=0)
 THROW 55090,N'Defaulttransport verletzt.',4;
IF NOT EXISTS(SELECT 1 FROM toolbelt_string.TVF_OsaDistance(N'CA',N'AC',DEFAULT,DEFAULT) WHERE Distance=1 AND ErrorCode=0)
 THROW 55090,N'OSA-Defaulttransport verletzt.',5;
-- 1000 unterschiedliche synthetische Paare; Outputorakel, keine Executioncountzusage.
DECLARE @Rows TABLE(Id int PRIMARY KEY,L nvarchar(16),R nvarchar(16),K int);
INSERT @Rows
SELECT n.Id,N'ab'+CONVERT(nvarchar(4),n.Id),N'ba'+CONVERT(nvarchar(4),n.Id),CASE WHEN n.Id%2=0 THEN 1 ELSE 2 END
FROM(SELECT a.n+10*b.n+100*c.n AS Id
 FROM(VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9))a(n)
 CROSS JOIN(VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9))b(n)
 CROSS JOIN(VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9))c(n))n;
IF (SELECT COUNT(*) FROM @Rows p CROSS APPLY toolbelt_string.TVF_LevenshteinDistance(p.L,p.R,p.K,N'standard'))<>1000
 OR EXISTS(SELECT 1 FROM @Rows p CROSS APPLY toolbelt_string.TVF_LevenshteinDistance(p.L,p.R,p.K,N'standard')r
 WHERE r.ErrorCode IS NULL OR r.ErrorCode<>0 OR (p.K=1 AND(r.Distance IS NOT NULL OR ISNULL(CONVERT(int,r.ExceedsMaxDistance),-1)<>1))
 OR(p.K=2 AND(ISNULL(r.Distance,-1)<>2 OR ISNULL(CONVERT(int,r.ExceedsMaxDistance),-1)<>0)))
 THROW 55090,N'Mengen-Levenshteinoracle verletzt.',6;
IF (SELECT COUNT(*) FROM @Rows p CROSS APPLY toolbelt_string.TVF_OsaDistance(p.L,p.R,p.K,N'standard'))<>1000
 OR EXISTS(SELECT 1 FROM @Rows p CROSS APPLY toolbelt_string.TVF_OsaDistance(p.L,p.R,p.K,N'standard')r
 WHERE r.ErrorCode IS NULL OR r.ErrorCode<>0 OR ISNULL(r.Distance,-1)<>1 OR ISNULL(CONVERT(int,r.ExceedsMaxDistance),-1)<>0)
 THROW 55090,N'Mengen-OSAoracle verletzt.',7;
SELECT N'PASS' AS Status;
