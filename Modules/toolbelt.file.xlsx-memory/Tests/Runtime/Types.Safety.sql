-- Konstante, APPLY und äußere CASE-Auswertung; sämtliche Inputs sind synthetisch.
SET NOCOUNT ON;
IF NOT EXISTS(SELECT 1 FROM toolbelt_file.TVF_InterpretXlsxCell(N'n',1,N'1',CONVERT(nvarchar(max),0x00D8),NULL,NULL,NULL) WHERE StatusCode=4 AND EchoPreserved=1 AND NumberValue IS NULL)
 THROW 51590,N'UTF-16-Gate muss auch ungenutzten Text prüfen.',6;
GO
DECLARE @Inputs TABLE(Id int,Raw nvarchar(max),FormatCode nvarchar(max),Expected int);
INSERT @Inputs VALUES(1,N'1',N'0 ',6),(2,N'1',N'GENERAL',6),(3,N'1',CONVERT(nvarchar(max),0x00D8),4),
 (4,N'1'+NCHAR(0),NULL,4),(5,N'1,5',NULL,4),(6,N'1 ',NULL,4),(7,N'0x01',NULL,4),
 (8,N'NaN',NULL,4),(9,N'Infinity',NULL,4),(10,N'1e65',NULL,5),(11,N'1e-39',NULL,5);
SELECT c.Id,r.* INTO #TypeSafety FROM @Inputs c CROSS APPLY toolbelt_file.TVF_InterpretXlsxCell(N'n',1,c.Raw,NULL,NULL,c.FormatCode,NULL) r;
IF (SELECT COUNT(*) FROM #TypeSafety)<>11 OR EXISTS(SELECT 1 FROM @Inputs c JOIN #TypeSafety r ON r.Id=c.Id WHERE r.StatusCode<>c.Expected OR r.EchoPreserved<>1)
 THROW 51590,N'Endliche Grammatik-/UTF-16-/Prioritätsorakel stimmen nicht.',7;
DROP TABLE #TypeSafety;
GO
DECLARE @Large nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),65537);
IF NOT EXISTS(SELECT 1 FROM toolbelt_file.TVF_InterpretXlsxCell(N'n',1,@Large,NULL,NULL,N'General',NULL)
 WHERE CASE WHEN StatusCode=3 THEN CONVERT(int,EchoPreserved) ELSE 99 END=0 AND RawValue IS NULL AND NumberValue IS NULL)
 THROW 51590,N'Äußere CASE darf Inputgrenzen nicht ändern.',8;
GO
-- Caller-Collation verändert die ordinale Ziel-/Formatklassifikation nicht.
IF NOT EXISTS(SELECT 1 FROM toolbelt_file.TVF_InterpretXlsxCell(N'n' COLLATE Latin1_General_100_CI_AS,1,N'1',NULL,N'NUMBER' COLLATE Latin1_General_100_CI_AS,NULL,NULL) WHERE StatusCode=2)
 THROW 51590,N'Case-sensitive Typzielsemantik ging verloren.',9;
GO
IF NOT EXISTS(SELECT 1 FROM toolbelt_file.TVF_InterpretXlsxCell(N'n' COLLATE Latin1_General_100_BIN2,1,N'1',NULL,N'number ',NULL,NULL) WHERE StatusCode=2)
 THROW 51590,N'Trailing-Space-Zielsemantik ging verloren.',10;
GO
