-- Ausschließlich synthetische unabhängige SQL-Orakel; keine Style-/Formelauswertung.
SET NOCOUNT ON;
DECLARE @Cases TABLE(Id int PRIMARY KEY,Stored nvarchar(max),Present bit,Raw nvarchar(max),TextValue nvarchar(max),Target nvarchar(max),FormatCode nvarchar(max),Date1904 bit,Status int,Resolved nvarchar(16));
INSERT @Cases VALUES
 (1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL),
 (2,N'n',1,N'1',NULL,NULL,NULL,NULL,0,N'number'),
 (3,N'n',1,N'60.999999',NULL,N'datetime',NULL,0,7,N'datetime'),
 (4,N'n',1,N'59.999999999999999999999999999999999',NULL,N'datetime',NULL,0,0,N'datetime'),
 (5,N'n',1,N'0',NULL,N'date',NULL,1,0,N'date'),
 (6,N'n',1,N'0',NULL,N'date',NULL,0,8,N'date'),
 (7,N'n',1,N'1.5',NULL,N'date',NULL,0,9,N'date'),
 (8,N'n',1,N'2',NULL,N'time',NULL,NULL,8,N'time'),
 (9,N'n',1,N'-2',NULL,N'duration',NULL,NULL,0,N'duration'),
 (10,N'b',1,N'1',NULL,NULL,NULL,NULL,0,N'boolean'),
 (11,N'b',1,N'True',NULL,NULL,NULL,NULL,4,N'boolean'),
 (12,N'inlineStr',0,NULL,N'',NULL,NULL,NULL,0,N'text'),
 (13,N'inlineStr',1,NULL,N'x',NULL,NULL,NULL,2,NULL),
 (14,N's',1,N'0',N'x',NULL,NULL,NULL,0,N'text'),
 (15,N's',1,N'-1',N'x',NULL,NULL,NULL,2,NULL),
 (16,N's',1,N'0',NULL,NULL,N'General',NULL,6,NULL),
 (17,N'str',1,N'a',N'a ',NULL,NULL,NULL,2,NULL),
 (18,N'n',1,NULL,NULL,NULL,N'General',NULL,6,NULL),
 (19,N'e',1,N'#N/A',NULL,NULL,NULL,NULL,10,N'text'),
 (20,N'e',1,N'#N/A',NULL,NULL,N'General',NULL,6,NULL),
 (21,N'n',1,N'10',NULL,NULL,N'0%',NULL,0,N'number'),
 (22,N'n',1,N'10',NULL,NULL,N'#',NULL,6,NULL),
 (23,N'n',1,N'1',NULL,N'NUMBER',NULL,NULL,2,NULL),
 (24,N'n',1,N'1',NULL,N'number ',NULL,NULL,2,NULL),
 (25,N'n',1,N'1',NULL,N'date',N'0',0,2,NULL),
 (26,N'd',1,N'0001-01-01',NULL,N'date',NULL,NULL,0,N'date'),
 (27,N'd',1,N'2024-02-29T00:00:00.0000001',NULL,NULL,NULL,NULL,0,N'datetime'),
 (28,N'd',1,N'2024-02-29T00:00:00Z',NULL,NULL,NULL,NULL,4,N'datetime'),
 (29,N'd',1,N'2023-02-29',NULL,N'date',NULL,NULL,4,N'date'),
 (30,N'n',1,N'0e-65',NULL,NULL,NULL,NULL,5,N'number');
SELECT c.Id,r.* INTO #TypesActual FROM @Cases c CROSS APPLY toolbelt_file.TVF_InterpretXlsxCell(c.Stored,c.Present,c.Raw,c.TextValue,c.Target,c.FormatCode,c.Date1904) r;
IF (SELECT COUNT(*) FROM #TypesActual)<>30 OR EXISTS(SELECT 1 FROM @Cases c LEFT JOIN #TypesActual a ON a.Id=c.Id WHERE a.StatusCode<>c.Status OR a.EchoPreserved<>1
 OR ISNULL(CONVERT(varbinary(max),a.ResolvedType),0x)<>ISNULL(CONVERT(varbinary(max),c.Resolved),0x))
 THROW 51590,N'Synthetische Typ-/Prioritätsfälle stimmen nicht.',1;
IF EXISTS(SELECT 1 FROM #TypesActual WHERE StatusCode<>0 AND (NumberValue IS NOT NULL OR BooleanValue IS NOT NULL OR DateValue IS NOT NULL OR DateTimeValue IS NOT NULL OR TimeValue IS NOT NULL OR DurationTicks IS NOT NULL OR TypedTextValue IS NOT NULL))
 THROW 51590,N'Typedwerte bei Fehler sind nicht NULL.',2;
IF (SELECT DateTimeValue FROM #TypesActual WHERE Id=4)<>CONVERT(datetime2(7),'1900-03-01T00:00:00')
 OR (SELECT DurationTicks FROM #TypesActual WHERE Id=9)<>-1728000000000
 OR (SELECT NumberValue FROM #TypesActual WHERE Id=21)<>CONVERT(decimal(2,0),10)
 OR (SELECT DateValue FROM #TypesActual WHERE Id=26)<>CONVERT(date,'0001-01-01')
 OR (SELECT DateTimeValue FROM #TypesActual WHERE Id=27)<>CONVERT(datetime2(7),'2024-02-29T00:00:00.0000001')
 THROW 51590,N'Exakte Temporal-/Zahlwerte stimmen nicht.',3;
DROP TABLE #TypesActual;
GO
-- Feste Input-/Gesamtgrenzen, NULL darf Quote nicht umgehen.
DECLARE @Limit TABLE(Id int,Stored nvarchar(max),Present bit,Raw nvarchar(max),TextValue nvarchar(max),Target nvarchar(max),Status int,Echo bit);
INSERT @Limit VALUES
 (1,REPLICATE(N'x',32),1,N'1',NULL,NULL,6,1),
 (2,REPLICATE(N'x',33),1,N'1',NULL,NULL,3,0),
 (3,N'n',1,REPLICATE(CONVERT(nvarchar(max),N'1'),129),NULL,NULL,3,0),
 (4,N's',1,N'0',REPLICATE(CONVERT(nvarchar(max),N'x'),32733),NULL,0,1),
 (5,N's',1,N'0',REPLICATE(CONVERT(nvarchar(max),N'x'),32734),NULL,3,0),
 (6,N'str',1,REPLICATE(CONVERT(nvarchar(max),N'x'),21821),REPLICATE(CONVERT(nvarchar(max),N'x'),21821),NULL,0,1),
 (7,N'str',1,REPLICATE(CONVERT(nvarchar(max),N'x'),21822),REPLICATE(CONVERT(nvarchar(max),N'x'),21822),NULL,3,0),
 (8,NULL,NULL,REPLICATE(CONVERT(nvarchar(max),N'x'),65537),NULL,NULL,3,0);
SELECT c.Id,r.* INTO #TypeLimits FROM @Limit c CROSS APPLY toolbelt_file.TVF_InterpretXlsxCell(c.Stored,c.Present,c.Raw,c.TextValue,c.Target,NULL,NULL) r;
IF (SELECT COUNT(*) FROM #TypeLimits)<>8 OR EXISTS(SELECT 1 FROM @Limit c JOIN #TypeLimits r ON r.Id=c.Id WHERE r.StatusCode<>c.Status OR r.EchoPreserved<>c.Echo)
 OR EXISTS(SELECT 1 FROM #TypeLimits WHERE EchoPreserved=0 AND (StoredType IS NOT NULL OR ValuePresent IS NOT NULL OR RawValue IS NOT NULL OR TextValue IS NOT NULL OR ResolvedType IS NOT NULL OR NumberValue IS NOT NULL OR BooleanValue IS NOT NULL OR DateValue IS NOT NULL OR DateTimeValue IS NOT NULL OR TimeValue IS NOT NULL OR DurationTicks IS NOT NULL OR TypedTextValue IS NOT NULL))
 THROW 51590,N'Input-/Echoquoten sind nicht atomar.',4;
DROP TABLE #TypeLimits;
GO
DECLARE @Numbers TABLE(Id int,Raw nvarchar(max));
INSERT @Numbers VALUES(1,REPLICATE(N'9',38)),(2,N'-'+REPLICATE(N'9',38)),(3,N'0.00000000000000000000000000000000000001');
SELECT c.Id,r.* INTO #TypeNumbers FROM @Numbers c CROSS APPLY toolbelt_file.TVF_InterpretXlsxCell(N'n',1,c.Raw,NULL,NULL,NULL,NULL) r;
IF (SELECT COUNT(*) FROM #TypeNumbers)<>3 OR EXISTS(SELECT 1 FROM #TypeNumbers WHERE StatusCode<>0 OR NumberValue IS NULL OR SQL_VARIANT_PROPERTY(NumberValue,'BaseType') NOT IN('decimal','numeric')
 OR CONVERT(int,SQL_VARIANT_PROPERTY(NumberValue,'Precision'))<>38 OR CONVERT(int,SQL_VARIANT_PROPERTY(NumberValue,'Scale'))<>CASE WHEN Id=3 THEN 38 ELSE 0 END)
 OR (SELECT NumberValue FROM #TypeNumbers WHERE Id=3)<>CONVERT(decimal(38,38),'0.00000000000000000000000000000000000001')
 THROW 51590,N'Exakter SqlDecimal-Varianttransport stimmt nicht.',5;
DROP TABLE #TypeNumbers;
GO
