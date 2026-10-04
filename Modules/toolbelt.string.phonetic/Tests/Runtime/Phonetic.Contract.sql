SET NOCOUNT ON;
DECLARE @Cologne TABLE(Text nvarchar(max) NULL,Code varchar(max) NULL);
INSERT @Cologne VALUES(NULL,NULL),(N'', ''),(N'x','48'),(N'ax','048'),(N'cx','48'),(N'mn','6'),(N'ß','8'),(N'H',''),(N'BABABABAB','11111');
IF EXISTS(SELECT 1 FROM @Cologne c CROSS APPLY toolbelt_string.TVF_ColognePhonetic(c.Text) a WHERE a.ErrorCode<>0 OR a.ErrorCode IS NULL
 OR (c.Code IS NULL AND a.PhoneticCode IS NOT NULL) OR (c.Code IS NOT NULL AND(a.PhoneticCode IS NULL OR CONVERT(varbinary(max),c.Code)<>CONVERT(varbinary(max),a.PhoneticCode))))
 THROW 55280,N'Cologne-Hardgoldens stimmen nicht.',1;
IF(SELECT COUNT(*) FROM @Cologne c CROSS APPLY toolbelt_string.TVF_ColognePhonetic(c.Text) a)<>9 THROW 55280,N'Cologne-Kardinalität stimmt nicht.',2;
DECLARE @Double TABLE(Text nvarchar(max) NULL,PrimaryCode varchar(max) NULL,AlternateCode varchar(max) NULL);
INSERT @Double VALUES(NULL,NULL,NULL),(N'','',''),(N'the','0','T'),(N'quick','KK','KK'),(N'brown','PRN','PRN'),(N'AJ','AJ','A '),(N'BABABABAB','PPPPP','PPPPP');
IF EXISTS(SELECT 1 FROM @Double c CROSS APPLY toolbelt_string.TVF_DoubleMetaphone(c.Text) a WHERE a.ErrorCode<>0 OR a.ErrorCode IS NULL
 OR (c.PrimaryCode IS NULL AND(a.PrimaryCode IS NOT NULL OR a.AlternateCode IS NOT NULL))
 OR (c.PrimaryCode IS NOT NULL AND(a.PrimaryCode IS NULL OR a.AlternateCode IS NULL OR CONVERT(varbinary(max),c.PrimaryCode)<>CONVERT(varbinary(max),a.PrimaryCode) OR CONVERT(varbinary(max),c.AlternateCode)<>CONVERT(varbinary(max),a.AlternateCode))))
 THROW 55281,N'Double-Metaphone-Hardgoldens stimmen nicht.',1;
IF(SELECT COUNT(*) FROM @Double c CROSS APPLY toolbelt_string.TVF_DoubleMetaphone(c.Text) a)<>7 THROW 55281,N'Double-Kardinalität stimmt nicht.',2;
PRINT 'PASS PHONETIC_CONTRACT';
GO