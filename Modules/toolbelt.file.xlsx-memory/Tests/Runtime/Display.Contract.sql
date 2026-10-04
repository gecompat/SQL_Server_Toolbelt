-- Synthetischer Anzeigevertrag; keine Formelberechnung und keine Styleinferenz.
SET NOCOUNT ON;
DECLARE @Cases TABLE(Id int NOT NULL PRIMARY KEY,Stored nvarchar(max) NULL,Present bit NULL,Raw nvarchar(max) NULL,
 TextValue nvarchar(max) NULL,Target nvarchar(max) NULL,Format nvarchar(max) NULL,D1904 bit NULL,Culture nvarchar(max) NULL,
 ExpectedText nvarchar(max) NULL,ExpectedStatus int NOT NULL);
INSERT @Cases VALUES
(1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1),
(2,N'n',1,N'0',NULL,N'number',N'0%',NULL,N'en-US',N'0%',0),
(3,N'n',1,N'1.235',NULL,N'number',N'0.00',NULL,N'en-US',N'1.24',0),
(4,N'n',1,N'-1.235',NULL,N'number',N'0.00',NULL,N'de-DE',N'-1,24',0),
(5,N'n',1,N'-0.49',NULL,N'number',N'0',NULL,N'tr-TR',N'0',0),
(6,N'n',1,N'1234567.895',NULL,N'number',N'#,##0.00',NULL,N'de-DE',N'1.234.567,90',0),
(7,N'n',1,N'0.001235',NULL,N'number',N'0.00%',NULL,N'en-US',N'0.12%',0),
(8,N'n',1,N'9.995',NULL,N'number',N'0.00E+00',NULL,N'en-US',N'1.00E+01',0),
(9,N'n',1,N'0',NULL,N'number',N'0.00E+00',NULL,N'tr-TR',N'0,00E+00',0),
(10,N'n',1,N'0.00000000000000000000000000000000000001',NULL,N'number',N'0.00E+00',NULL,N'en-US',N'1.00E-38',0),
(11,N'n',1,N'99999999999999999999999999999999999999',NULL,N'number',N'0%',NULL,N'en-US',N'9999999999999999999999999999999999999900%',0),
(12,N'inlineStr',0,NULL,N'',NULL,N'@',NULL,N'tr-TR',N'',0),
(13,N's',1,N'0',N'tail ä😀 ',N'text',N'@',NULL,N'en-US',N'tail ä😀 ',0),
(14,N'str',1,N'a'+NCHAR(0)+N'b',N'a'+NCHAR(0)+N'b',N'text',N'@',NULL,N'de-DE',N'a'+NCHAR(0)+N'b',0),
(15,N'b',1,N'1',NULL,N'text',N'@',NULL,N'en-US',N'1',0),
(16,N'n',1,N'59',NULL,N'date',N'yyyy-mm-dd',0,N'en-US',N'1900-02-28',0),
(17,N'n',1,N'60.5',NULL,N'datetime',N'yyyy-mm-dd hh:mm:ss',0,N'en-US',NULL,7),
(18,N'n',1,N'61',NULL,N'date',N'yyyy-mm-dd',0,N'en-US',N'1900-03-01',0),
(19,N'n',1,N'0',NULL,N'date',N'yyyy-mm-dd',1,N'tr-TR',N'1904-01-01',0),
(20,N'd',1,N'2020-12-31T23:59:59.5000000',NULL,N'datetime',N'yyyy-mm-dd hh:mm:ss',NULL,N'de-DE',N'2021-01-01 00:00:00',0),
(21,N'd',1,N'2020-12-31T23:59:59.4999999',NULL,N'datetime',N'yyyy-mm-dd hh:mm:ss',NULL,N'en-US',N'2020-12-31 23:59:59',0),
(22,N'd',1,N'9999-12-31T23:59:59.5000000',NULL,N'datetime',N'yyyy-mm-dd hh:mm:ss',NULL,N'en-US',NULL,8),
(23,N'n',1,N'0.999994212962963',NULL,N'time',N'hh:mm:ss',NULL,N'en-US',NULL,8),
(24,N'n',1,N'0.5',NULL,N'time',N'hh:mm:ss',NULL,N'en-US',N'12:00:00',0),
(25,N'n',1,N'1',NULL,N'duration',N'[h]:mm:ss',NULL,N'en-US',NULL,6),
(26,N'n',1,N'1',NULL,N'number',N'0',NULL,NULL,NULL,2),
(27,N'n',1,N'1',NULL,N'number',N'0',NULL,N'en-US ',NULL,2),
(28,N'n',1,N'1',NULL,N'number',N'0',NULL,N'EN-US',NULL,2),
(29,N'n',1,N'bad',NULL,N'number',N'0',NULL,NULL,NULL,4),
(30,N'n',1,N'1',NULL,N'number',N'General',NULL,N'en-US',NULL,6),
(31,N'n',1,N'1',NULL,N'number',N'0.00e+00',NULL,N'en-US',NULL,6),
(32,N'n',1,N'1',NULL,N'number',N'0 ',NULL,N'en-US',NULL,6),
(33,N'e',1,N'#DIV/0!',NULL,NULL,N'@',NULL,N'en-US',NULL,10),
(34,N'n',1,N'59.5',NULL,N'date',N'yyyy-mm-dd',0,N'en-US',NULL,9),
(35,N'n',1,N'1e39',NULL,N'number',N'0',NULL,N'en-US',NULL,5),
(36,N'n',1,N'1',NULL,N'date',N'0',0,N'en-US',NULL,2);
DECLARE @Actual TABLE(Id int NOT NULL,DisplayText nvarchar(max) NULL,StatusCode int NULL);
INSERT @Actual SELECT c.Id,f.DisplayText,f.StatusCode FROM @Cases c
OUTER APPLY toolbelt_file.TVF_FormatXlsxCell(c.Stored,c.Present,c.Raw,c.TextValue,c.Target,c.Format,c.D1904,c.Culture) f;
IF (SELECT COUNT(*) FROM @Actual)<>36 OR EXISTS(SELECT Id FROM @Actual GROUP BY Id HAVING COUNT(*)<>1)
 OR EXISTS(SELECT Id,CONVERT(varbinary(max),DisplayText),StatusCode FROM @Actual
 EXCEPT SELECT Id,CONVERT(varbinary(max),ExpectedText),ExpectedStatus FROM @Cases)
 OR EXISTS(SELECT Id,CONVERT(varbinary(max),ExpectedText),ExpectedStatus FROM @Cases
 EXCEPT SELECT Id,CONVERT(varbinary(max),DisplayText),StatusCode FROM @Actual)
 THROW 51594,N'Anzeigevertrag: Zeilenform, Status oder exakte Anzeigebytes weichen ab.',1;
SELECT N'PASS' AS Status;
GO
