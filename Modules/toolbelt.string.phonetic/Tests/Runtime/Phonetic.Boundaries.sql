SET NOCOUNT ON;
DECLARE @Cases TABLE(Text nvarchar(max),Expected int);
INSERT @Cases VALUES(CONVERT(nvarchar(max),0x00D8),1),(CONVERT(nvarchar(max),0x00DC),1),
 (N'é'+CONVERT(nvarchar(max),0x00D8),1),(N'é',3),(CONVERT(nvarchar(max),0x3DD800DE),3),
 (REPLICATE(CONVERT(nvarchar(max),N'A'),4097)+CONVERT(nvarchar(max),0x00D8),2);
IF EXISTS(SELECT 1 FROM @Cases c CROSS APPLY toolbelt_string.TVF_ColognePhonetic(c.Text) a WHERE a.ErrorCode IS NULL OR a.ErrorCode<>c.Expected OR a.PhoneticCode IS NOT NULL)
 THROW 55282,N'Cologne-UTF16-/Alphabet-/Quotepriorität stimmt nicht.',1;
IF EXISTS(SELECT 1 FROM @Cases c CROSS APPLY toolbelt_string.TVF_DoubleMetaphone(c.Text) a WHERE a.ErrorCode IS NULL OR a.ErrorCode<>c.Expected OR a.PrimaryCode IS NOT NULL OR a.AlternateCode IS NOT NULL)
 THROW 55282,N'Double-UTF16-/Alphabet-/Quotepriorität stimmt nicht.',2;
IF(SELECT COUNT(*) FROM @Cases c CROSS APPLY toolbelt_string.TVF_ColognePhonetic(c.Text) a)<>6
 OR(SELECT COUNT(*) FROM @Cases c CROSS APPLY toolbelt_string.TVF_DoubleMetaphone(c.Text) a)<>6 THROW 55282,N'Boundary-Kardinalität stimmt nicht.',3;
IF NOT EXISTS(SELECT 1 FROM toolbelt_string.TVF_ColognePhonetic(REPLICATE(CONVERT(nvarchar(max),N'ß'),4096)) WHERE ErrorCode=0 AND CONVERT(varbinary(max),PhoneticCode)=0x38)
 THROW 55282,N'Zulässige maximale rohe Eingabe wurde gekürzt oder abgelehnt.',4;
IF NOT EXISTS(SELECT 1 FROM toolbelt_string.TVF_DoubleMetaphone(NCHAR(0)+NCHAR(9)+N'AJ'+NCHAR(13)+NCHAR(10)) WHERE ErrorCode=0 AND CONVERT(varbinary(max),PrimaryCode)=0x414A AND CONVERT(varbinary(max),AlternateCode)=0x4120)
 THROW 55282,N'Java-Trim/terminales J-Leerzeichen stimmt nicht.',5;
PRINT 'PASS PHONETIC_BOUNDARIES';
GO