SET NOCOUNT ON;
-- Harte synthetische Bruchgoldens; keine nachgebildete Matchingreferenz.
DECLARE @Cases TABLE(Id int PRIMARY KEY,L nvarchar(max),R nvarchar(max),Expected float);
INSERT @Cases VALUES
(1,N'',N'',1),(2,N'A',N'',0),(3,N'A',N'A',1),(4,N'A',N'a',0),
(5,N'A',N'A ',CONVERT(float,17)/20),(6,N'ABC',N'ACB',CONVERT(float,5)/9),
(7,N'ABCA',N'ACBA',CONVERT(float,37)/40),(8,N'ABCDEF',N'ABDCEF',CONVERT(float,43)/45),
(9,N'AAAAABBBBB',N'AAAAACCCCC',CONVERT(float,2)/3),
(10,N'AAAAAABBBB',N'AAAAAACCCC',CONVERT(float,21)/25),
(11,N'ABCDEF',N'BDHECFGD',CONVERT(float,259)/360),
(12,REPLICATE(N'A',11)+REPLICATE(N'B',9),REPLICATE(N'A',11)+REPLICATE(N'C',9),CONVERT(float,7)/10);
DECLARE @Actual TABLE(Id int,Profile nvarchar(8),ReverseOrder bit,Similarity float,ErrorCode int);
INSERT @Actual
SELECT c.Id,p.Profile,r.ReverseOrder,f.Similarity,f.ErrorCode
FROM @Cases c CROSS JOIN(VALUES(N'standard'),(N'large'))p(Profile)
CROSS JOIN(VALUES(CONVERT(bit,0)),(CONVERT(bit,1)))r(ReverseOrder)
CROSS APPLY toolbelt_string.TVF_JaroWinklerSimilarity(
 CASE WHEN r.ReverseOrder=0 THEN c.L ELSE c.R END,
 CASE WHEN r.ReverseOrder=0 THEN c.R ELSE c.L END,p.Profile)f;
IF (SELECT COUNT(*) FROM @Actual)<>48 OR EXISTS
(SELECT 1 FROM @Actual a JOIN @Cases c ON c.Id=a.Id
 WHERE a.ErrorCode IS NULL OR a.ErrorCode<>0 OR a.Similarity IS NULL
 OR ABS(a.Similarity-c.Expected)>1e-12)
 THROW 55090,N'Jaro-Bruchgoldens verletzt.',10;
IF EXISTS(SELECT 1 FROM toolbelt_string.TVF_JaroWinklerSimilarity(NULL,N'x',N'invalid')
 WHERE Similarity IS NOT NULL OR ErrorCode IS NULL OR ErrorCode<>0)
 THROW 55090,N'Jaro-NULL-Priorität verletzt.',11;
IF NOT EXISTS(SELECT 1 FROM toolbelt_string.TVF_JaroWinklerSimilarity(N'A',N'A',DEFAULT)
 WHERE Similarity=1 AND ErrorCode=0)
 THROW 55090,N'Jaro-Standardprofil verletzt.',12;
PRINT N'PASS Jaro Contract';
