SET NOCOUNT ON;
DECLARE @Cases TABLE(Id int,L nvarchar(max),R nvarchar(max),Profile nvarchar(max),Expected int);
INSERT @Cases VALUES
(1,N'x',N'x',NULL,1),(2,N'x',N'x',N'Standard',1),
(3,REPLICATE(CONVERT(nvarchar(max),N'x'),2049),N'x',N'standard',3),
(4,CONVERT(nvarchar(max),0x00D8),N'x',N'standard',4),
(5,REPLICATE(CONVERT(nvarchar(max),N'x'),1025),N'x',N'standard',5),
(6,REPLICATE(CONVERT(nvarchar(max),N'x'),5000),REPLICATE(CONVERT(nvarchar(max),N'x'),5000),N'large',6),
(7,CONVERT(nvarchar(max),0x00D8),REPLICATE(CONVERT(nvarchar(max),N'x'),2049),N'standard',3),
(8,CONVERT(nvarchar(max),0x00D8),REPLICATE(CONVERT(nvarchar(max),N'x'),1025),N'standard',4),
(9,REPLICATE(CONVERT(nvarchar(max),N'x'),65537),N'x',N'large',3),
(10,REPLICATE(CONVERT(nvarchar(max),N'x'),32769),N'x',N'large',5);
IF CONVERT(varbinary(max),CONVERT(nvarchar(max),0x00D8))<>0x00D8
 THROW 55091,N'Synthetischer UTF-16-Transport nicht bytegleich.',10;
DECLARE @Actual TABLE(Id int,Similarity float,ErrorCode int);
INSERT @Actual SELECT c.Id,f.Similarity,f.ErrorCode FROM @Cases c
CROSS APPLY toolbelt_string.TVF_JaroWinklerSimilarity(c.L,c.R,c.Profile)f;
IF (SELECT COUNT(*) FROM @Actual)<>10 OR EXISTS
(SELECT 1 FROM @Actual a JOIN @Cases c ON c.Id=a.Id
 WHERE a.Similarity IS NOT NULL OR a.ErrorCode IS NULL OR a.ErrorCode<>c.Expected)
 THROW 55091,N'Jaro-Ressourcen- oder Fehlerpriorität verletzt.',11;
PRINT N'PASS Jaro Boundaries';
