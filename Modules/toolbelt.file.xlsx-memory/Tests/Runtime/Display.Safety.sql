-- Öffentliche Grenzen: geerbte Typquote; keine unerreichbare 65472-@-Behauptung.
SET NOCOUNT ON;
DECLARE @Cases TABLE(Id int NOT NULL,Stored nvarchar(max) NULL,Present bit NULL,Raw nvarchar(max) NULL,
 TextValue nvarchar(max) NULL,Target nvarchar(max) NULL,Format nvarchar(max) NULL,D1904 bit NULL,Culture nvarchar(max) NULL,
 ExpectedStatus int NOT NULL,ExpectedLength int NULL);
INSERT @Cases VALUES
(1,N's',1,N'0',REPLICATE(CONVERT(nvarchar(max),N'a'),32733),N'text',N'@',NULL,N'en-US',0,32733),
(2,N's',1,N'0',REPLICATE(CONVERT(nvarchar(max),N'a'),32734),N'text',N'@',NULL,N'en-US',3,NULL),
(3,N'str',1,REPLICATE(CONVERT(nvarchar(max),N'a'),21821),REPLICATE(CONVERT(nvarchar(max),N'a'),21821),N'text',N'@',NULL,N'en-US',0,21821),
(4,N'str',1,REPLICATE(CONVERT(nvarchar(max),N'a'),21822),REPLICATE(CONVERT(nvarchar(max),N'a'),21822),N'text',N'@',NULL,N'en-US',3,NULL),
(5,NULL,NULL,NULL,NULL,NULL,NULL,NULL,REPLICATE(CONVERT(nvarchar(max),N'a'),33),3,NULL),
(6,NULL,NULL,NULL,NULL,NULL,NULL,NULL,CONVERT(nvarchar(1),0x00D8),4,NULL),
(7,N'n',1,REPLICATE(CONVERT(nvarchar(max),N'1'),65537),NULL,N'number',N'0',NULL,CONVERT(nvarchar(1),0x00D8),3,NULL),
(8,N'n',1,N'1',NULL,N'number',REPLICATE(CONVERT(nvarchar(max),N'a'),129),NULL,N'en-US',3,NULL),
(9,N'n',1,N'1',NULL,REPLICATE(CONVERT(nvarchar(max),N'a'),33),N'0',NULL,N'en-US',3,NULL),
(10,REPLICATE(CONVERT(nvarchar(max),N'a'),33),1,N'1',NULL,N'number',N'0',NULL,N'en-US',3,NULL);
DECLARE @Actual TABLE(Id int NOT NULL,DisplayText nvarchar(max) NULL,StatusCode int NULL);
INSERT @Actual SELECT c.Id,f.DisplayText,f.StatusCode FROM @Cases c OUTER APPLY toolbelt_file.TVF_FormatXlsxCell
(c.Stored,c.Present,c.Raw,c.TextValue,c.Target,c.Format,c.D1904,c.Culture) f;
IF (SELECT COUNT(*) FROM @Actual)<>10 OR EXISTS(SELECT Id FROM @Actual GROUP BY Id HAVING COUNT(*)<>1)
 OR EXISTS(SELECT a.Id FROM @Actual a JOIN @Cases c ON c.Id=a.Id WHERE a.StatusCode IS NULL OR a.StatusCode<>c.ExpectedStatus
 OR (c.ExpectedLength IS NULL AND a.DisplayText IS NOT NULL)
 OR (c.ExpectedLength IS NOT NULL AND (a.DisplayText IS NULL OR DATALENGTH(a.DisplayText)<>2*c.ExpectedLength
 OR CONVERT(varbinary(max),a.DisplayText)<>CONVERT(varbinary(max),c.TextValue))))
 THROW 51594,N'Anzeigegrenzen: Priorität, Atomik oder vollständiger Text weicht ab.',2;
SELECT N'PASS' AS Status;
GO
