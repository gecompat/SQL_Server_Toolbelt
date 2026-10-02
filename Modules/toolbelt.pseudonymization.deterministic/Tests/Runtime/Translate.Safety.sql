SET NOCOUNT ON;
-- Unabhängige synthetische Orakel. Nur nach Installation in einer eigenen
-- Testdatenbank ausführen; dieser Text ist allein kein Runtime-Nachweis.
-- SQLCMD: ToolbeltDatabase. Keine Rechte-, Instanz- oder Truständerung.
DECLARE @Cases TABLE
(
    CaseId int PRIMARY KEY, Input nvarchar(max), MappingVersion int,
    Seed bigint, Separators nvarchar(max), Profile nvarchar(max),
    ExpectedCode int NOT NULL, ExpectedValue nvarchar(max)
);
DECLARE @High nvarchar(max)=CONVERT(nvarchar(max),0x00D8),
        @Pair nvarchar(max)=CONVERT(nvarchar(max),0x3DD800DE);
INSERT @Cases VALUES
 (1,NULL,NULL,NULL,NULL,NULL,0,NULL),
 (2,NULL,0,0,N'aa',N'standard ',0,NULL),
 (3,N'x',NULL,NULL,NULL,NULL,1,NULL),
 (4,N'x',0,NULL,NULL,NULL,1,NULL),
 (5,N'x',-1,0,N'',N'standard',1,NULL),
 (6,N'x',1,NULL,NULL,NULL,2,NULL),
 (7,N'x',1,0,NULL,NULL,10,NULL),
 (8,N'x',1,0,NULL,N'standard ',10,NULL),
 (9,N'x',1,0,N'',N'STANDARD',10,NULL),
 (10,N'x',1,0,N'',N'large ',10,NULL),
 (11,N'x',1,0,N'',N'standard'+NCHAR(0),10,NULL),
 (12,N'x',1,0,NULL,N'standard',11,NULL),
 (13,N'x',1,0,N'--',N'standard',11,NULL),
 (14,N'x',1,0,N'  ',N'standard',11,NULL),
 (15,N'x',1,0,NCHAR(0),N'standard',11,NULL),
 (16,N'x',1,0,NCHAR(9),N'standard',11,NULL),
 (17,N'x',1,0,NCHAR(127),N'standard',11,NULL),
 (18,N'x',1,0,@High,N'standard',11,NULL),
 (19,N'x',1,0,@Pair,N'standard',11,NULL),
 (20,N'x',1,0,N'A',N'standard',11,NULL),
 (21,N'x',1,0,N'0',N'standard',11,NULL),
 (22,N'x',1,0,NCHAR(228),N'standard',11,NULL),
 (23,N'',1,0,N'',N'standard',0,N''),
 (24,N'aA0',1,0,N'',N'standard',0,N'sS6'),
 (25,N'aA0 - ',1,0,N' -',N'standard',0,N'sS6 - '),
 (26,N'aA0 - ',1,0,N'- ',N'large',0,N'sS6 - '),
 (27,N' ',1,0,N'',N'standard',13,NULL),
 (28,N'a'+NCHAR(0),1,0,N'',N'standard',13,NULL),
 (29,N'a'+@High,1,0,N'',N'standard',13,NULL),
 (30,N'a'+@Pair,1,0,N'',N'standard',13,NULL),
 (31,N'a'+NCHAR(228),1,0,N'',N'standard',13,NULL),
 (32,N'a'+NCHAR(8490),1,0,N'',N'standard',13,NULL),
 (33,N'a'+NCHAR(65313),1,0,N'',N'standard',13,NULL);

DECLARE @Actual TABLE
    (CaseId int, RepeatId int, Value nvarchar(max), ErrorCode int);
-- APPLY mit mehreren Callerzeilen und konstantem CROSS JOIN: finale Filter
-- oder CASE dürfen nicht als sichere Auswertungsbarriere vorausgesetzt werden.
INSERT @Actual
SELECT c.CaseId,r.RepeatId,t.Value,t.ErrorCode
FROM @Cases c CROSS JOIN (VALUES(1),(2),(3),(4)) r(RepeatId)
CROSS APPLY [$(ToolbeltDatabase)].toolbelt_pseudonymization.TVF_DeterministicTranslate
    (c.Input,c.MappingVersion,c.Seed,c.Separators,c.Profile) t
OPTION(RECOMPILE);
IF (SELECT COUNT_BIG(*) FROM @Actual)<>132
 OR EXISTS(SELECT 1 FROM @Actual a JOIN @Cases c ON c.CaseId=a.CaseId
    WHERE a.ErrorCode IS NULL OR a.ErrorCode<>c.ExpectedCode
       OR (a.Value IS NULL AND c.ExpectedValue IS NOT NULL)
       OR (a.Value IS NOT NULL AND c.ExpectedValue IS NULL)
       OR CONVERT(varbinary(max),a.Value)<>CONVERT(varbinary(max),c.ExpectedValue))
 OR EXISTS(SELECT 1 FROM @Actual GROUP BY CaseId,RepeatId HAVING COUNT_BIG(*)<>1)
    THROW 54090,N'Translate Safety: APPLY/NULL/Fehlervorrang oder Byteergebnis abweichend.',1;

GO
-- Separater Konstanten-Compile-Oracle, eine integrierte TVF je Batch.
SET NOCOUNT ON;
DECLARE @Constant TABLE(Value nvarchar(max),ErrorCode int);
INSERT @Constant SELECT * FROM [$(ToolbeltDatabase)].toolbelt_pseudonymization.TVF_DeterministicTranslate
 (N'a',1,0,NCHAR(0),N'standard ') OPTION(RECOMPILE);
IF (SELECT COUNT_BIG(*) FROM @Constant)<>1
 OR EXISTS(SELECT 1 FROM @Constant WHERE Value IS NOT NULL OR ErrorCode IS NULL OR ErrorCode<>10)
    THROW 54090,N'Translate Safety: separate Konstantenpriorität abweichend.',1;
GO
-- Separater Konstanten-Compile-Oracle, eine integrierte TVF je Batch.
SET NOCOUNT ON;
DECLARE @Constant TABLE(Value nvarchar(max),ErrorCode int);
INSERT @Constant SELECT * FROM [$(ToolbeltDatabase)].toolbelt_pseudonymization.TVF_DeterministicTranslate
 (NULL,NULL,NULL,CONVERT(nvarchar(max),0x00D8),N'bad') OPTION(RECOMPILE);
IF (SELECT COUNT_BIG(*) FROM @Constant)<>1
 OR EXISTS(SELECT 1 FROM @Constant WHERE Value IS NOT NULL OR ErrorCode IS NULL OR ErrorCode<>0)
    THROW 54090,N'Translate Safety: separate Konstantenpriorität abweichend.',1;
GO
-- Separater Konstanten-Compile-Oracle, eine integrierte TVF je Batch.
SET NOCOUNT ON;
DECLARE @Constant TABLE(Value nvarchar(max),ErrorCode int);
INSERT @Constant SELECT * FROM [$(ToolbeltDatabase)].toolbelt_pseudonymization.TVF_DeterministicTranslate
 (N'a',1,0,CONVERT(nvarchar(max),0x00D8),N'standard') OPTION(RECOMPILE);
IF (SELECT COUNT_BIG(*) FROM @Constant)<>1
 OR EXISTS(SELECT 1 FROM @Constant WHERE Value IS NOT NULL OR ErrorCode IS NULL OR ErrorCode<>11)
    THROW 54090,N'Translate Safety: separate Konstantenpriorität abweichend.',1;
GO
SET NOCOUNT ON;
DECLARE @Cases TABLE
(
    CaseId int PRIMARY KEY, Input nvarchar(max), MappingVersion int,
    Seed bigint, Separators nvarchar(max), Profile nvarchar(max),
    ExpectedCode int NOT NULL, ExpectedValue nvarchar(max)
);
DECLARE @High nvarchar(max)=CONVERT(nvarchar(max),0x00D8),
        @Pair nvarchar(max)=CONVERT(nvarchar(max),0x3DD800DE);
INSERT @Cases VALUES
 (1,NULL,NULL,NULL,NULL,NULL,0,NULL),
 (2,NULL,0,0,N'aa',N'standard ',0,NULL),
 (3,N'x',NULL,NULL,NULL,NULL,1,NULL),
 (4,N'x',0,NULL,NULL,NULL,1,NULL),
 (5,N'x',-1,0,N'',N'standard',1,NULL),
 (6,N'x',1,NULL,NULL,NULL,2,NULL),
 (7,N'x',1,0,NULL,NULL,10,NULL),
 (8,N'x',1,0,NULL,N'standard ',10,NULL),
 (9,N'x',1,0,N'',N'STANDARD',10,NULL),
 (10,N'x',1,0,N'',N'large ',10,NULL),
 (11,N'x',1,0,N'',N'standard'+NCHAR(0),10,NULL),
 (12,N'x',1,0,NULL,N'standard',11,NULL),
 (13,N'x',1,0,N'--',N'standard',11,NULL),
 (14,N'x',1,0,N'  ',N'standard',11,NULL),
 (15,N'x',1,0,NCHAR(0),N'standard',11,NULL),
 (16,N'x',1,0,NCHAR(9),N'standard',11,NULL),
 (17,N'x',1,0,NCHAR(127),N'standard',11,NULL),
 (18,N'x',1,0,@High,N'standard',11,NULL),
 (19,N'x',1,0,@Pair,N'standard',11,NULL),
 (20,N'x',1,0,N'A',N'standard',11,NULL),
 (21,N'x',1,0,N'0',N'standard',11,NULL),
 (22,N'x',1,0,NCHAR(228),N'standard',11,NULL),
 (23,N'',1,0,N'',N'standard',0,N''),
 (24,N'aA0',1,0,N'',N'standard',0,N'sS6'),
 (25,N'aA0 - ',1,0,N' -',N'standard',0,N'sS6 - '),
 (26,N'aA0 - ',1,0,N'- ',N'large',0,N'sS6 - '),
 (27,N' ',1,0,N'',N'standard',13,NULL),
 (28,N'a'+NCHAR(0),1,0,N'',N'standard',13,NULL),
 (29,N'a'+@High,1,0,N'',N'standard',13,NULL),
 (30,N'a'+@Pair,1,0,N'',N'standard',13,NULL),
 (31,N'a'+NCHAR(228),1,0,N'',N'standard',13,NULL),
 (32,N'a'+NCHAR(8490),1,0,N'',N'standard',13,NULL),
 (33,N'a'+NCHAR(65313),1,0,N'',N'standard',13,NULL);

-- Ein äußerer CASE kann den inneren TVF-Ausdruck nicht zuverlässig schützen.
-- Auch dann muss der Kern selbst keine native Exception auslösen.
DECLARE @Projected TABLE(CaseId int,Code int,Bytes bigint);
INSERT @Projected
SELECT c.CaseId,t.ErrorCode,
       CASE WHEN t.ErrorCode=0 THEN DATALENGTH(t.Value) ELSE CONVERT(bigint,-1) END
FROM @Cases c CROSS APPLY [$(ToolbeltDatabase)].toolbelt_pseudonymization.TVF_DeterministicTranslate
 (c.Input,c.MappingVersion,c.Seed,c.Separators,c.Profile) t
OPTION(RECOMPILE);
IF (SELECT COUNT_BIG(*) FROM @Projected)<>33
 OR EXISTS(SELECT 1 FROM @Projected p JOIN @Cases c ON c.CaseId=p.CaseId
    WHERE p.Code IS NULL OR p.Code<>c.ExpectedCode
       OR (c.ExpectedCode<>0 AND p.Bytes<>-1))
    THROW 54090,N'Translate Safety: äußere CASE-Projektion abweichend.',1;

GO
SET NOCOUNT ON;
-- Von der Kandidatimplementierung unabhängig erzeugte SHA256-Vektoren:
-- PowerShell/.NET BitConverter, explizit umgedrehte signed Bytes und 22-Byte-
-- ASCII-Frames; Digesthexsortierung plus Originalordinal. Keine Runtimewerte.
DECLARE @Alphabet nvarchar(max)=N'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
DECLARE @Vectors TABLE(MappingVersion int,Seed bigint,Expected nvarchar(max));
INSERT @Vectors VALUES
 (1,0,N'simvxkhroqdtbwnlguyzpefacjSIMVXKHROQDTBWNLGUYZPEFACJ6301725984'),
 (2147483647,CONVERT(bigint,N'-9223372036854775808'),N'lfahyntkmjvgdsocbzwxeruqipLFAHYNTKMJVGDSOCBZWXERUQIP3540129867'),
 (42,CONVERT(bigint,N'9223372036854775807'),N'pvqgjascyhidxnbouklzwfrtemPVQGJASCYHIDXNBOUKLZWFRTEM6978024315');
DECLARE @VectorActual TABLE(Expected nvarchar(max),Value nvarchar(max),ErrorCode int);
INSERT @VectorActual SELECT v.Expected,t.Value,t.ErrorCode FROM @Vectors v
CROSS APPLY [$(ToolbeltDatabase)].toolbelt_pseudonymization.TVF_DeterministicTranslate
 (@Alphabet,v.MappingVersion,v.Seed,N'',N'standard') t OPTION(RECOMPILE);
IF (SELECT COUNT_BIG(*) FROM @VectorActual)<>3
 OR EXISTS(SELECT 1 FROM @VectorActual WHERE Value IS NULL OR ErrorCode IS NULL
    OR ErrorCode<>0 OR CONVERT(varbinary(max),Value)<>CONVERT(varbinary(max),Expected))
    THROW 54090,N'Translate Safety: unabhängiger signed Frame-/Mappingvektor abweichend.',1;

GO
-- Integrierter Caller-Collation-Oracle: Latin1_General_100_BIN2
SET NOCOUNT ON;
DECLARE @CallerCases TABLE(Id int PRIMARY KEY,Input nvarchar(max),Separators nvarchar(max),ExpectedCode int,ExpectedValue nvarchar(max));
INSERT @CallerCases VALUES
 (1,N'Aa09 - ',N'- ',0,N'Ss64 - '),
 (2,N'Aa09'+NCHAR(0),N'- ',13,NULL),
 (3,N'Aa09'+CONVERT(nvarchar(max),0x3DD800DE),N'- ',13,NULL),
 (4,N'Aa09 ',N'-',13,NULL),
 (5,N'Aa09 ',N' ',0,N'Ss64 ');
DECLARE @CallerActual TABLE(Id int,Value nvarchar(max),ErrorCode int);
INSERT @CallerActual SELECT c.Id,t.Value,t.ErrorCode FROM @CallerCases c
CROSS APPLY [$(ToolbeltDatabase)].toolbelt_pseudonymization.TVF_DeterministicTranslate
 (c.Input COLLATE Latin1_General_100_BIN2,1,0,c.Separators COLLATE Latin1_General_100_BIN2,N'standard' COLLATE Latin1_General_100_BIN2) t;
IF (SELECT COUNT_BIG(*) FROM @CallerActual)<>5
 OR EXISTS(SELECT 1 FROM @CallerActual GROUP BY Id HAVING COUNT_BIG(*)<>1)
 OR EXISTS(SELECT 1 FROM @CallerActual a JOIN @CallerCases c ON c.Id=a.Id
    WHERE a.ErrorCode IS NULL OR a.ErrorCode<>c.ExpectedCode
       OR (a.Value IS NULL AND c.ExpectedValue IS NOT NULL)
       OR (a.Value IS NOT NULL AND c.ExpectedValue IS NULL)
       OR CONVERT(varbinary(max),a.Value)<>CONVERT(varbinary(max),c.ExpectedValue))
    THROW 54090,N'Translate Safety: Caller-Collation Latin1_General_100_BIN2 abweichend.',1;
GO
-- Integrierter Caller-Collation-Oracle: Latin1_General_100_CS_AS
SET NOCOUNT ON;
DECLARE @CallerCases TABLE(Id int PRIMARY KEY,Input nvarchar(max),Separators nvarchar(max),ExpectedCode int,ExpectedValue nvarchar(max));
INSERT @CallerCases VALUES
 (1,N'Aa09 - ',N'- ',0,N'Ss64 - '),
 (2,N'Aa09'+NCHAR(0),N'- ',13,NULL),
 (3,N'Aa09'+CONVERT(nvarchar(max),0x3DD800DE),N'- ',13,NULL),
 (4,N'Aa09 ',N'-',13,NULL),
 (5,N'Aa09 ',N' ',0,N'Ss64 ');
DECLARE @CallerActual TABLE(Id int,Value nvarchar(max),ErrorCode int);
INSERT @CallerActual SELECT c.Id,t.Value,t.ErrorCode FROM @CallerCases c
CROSS APPLY [$(ToolbeltDatabase)].toolbelt_pseudonymization.TVF_DeterministicTranslate
 (c.Input COLLATE Latin1_General_100_CS_AS,1,0,c.Separators COLLATE Latin1_General_100_CS_AS,N'standard' COLLATE Latin1_General_100_CS_AS) t;
IF (SELECT COUNT_BIG(*) FROM @CallerActual)<>5
 OR EXISTS(SELECT 1 FROM @CallerActual GROUP BY Id HAVING COUNT_BIG(*)<>1)
 OR EXISTS(SELECT 1 FROM @CallerActual a JOIN @CallerCases c ON c.Id=a.Id
    WHERE a.ErrorCode IS NULL OR a.ErrorCode<>c.ExpectedCode
       OR (a.Value IS NULL AND c.ExpectedValue IS NOT NULL)
       OR (a.Value IS NOT NULL AND c.ExpectedValue IS NULL)
       OR CONVERT(varbinary(max),a.Value)<>CONVERT(varbinary(max),c.ExpectedValue))
    THROW 54090,N'Translate Safety: Caller-Collation Latin1_General_100_CS_AS abweichend.',1;
GO
-- Integrierter Caller-Collation-Oracle: Latin1_General_100_CI_AS_SC
SET NOCOUNT ON;
DECLARE @CallerCases TABLE(Id int PRIMARY KEY,Input nvarchar(max),Separators nvarchar(max),ExpectedCode int,ExpectedValue nvarchar(max));
INSERT @CallerCases VALUES
 (1,N'Aa09 - ',N'- ',0,N'Ss64 - '),
 (2,N'Aa09'+NCHAR(0),N'- ',13,NULL),
 (3,N'Aa09'+CONVERT(nvarchar(max),0x3DD800DE),N'- ',13,NULL),
 (4,N'Aa09 ',N'-',13,NULL),
 (5,N'Aa09 ',N' ',0,N'Ss64 ');
DECLARE @CallerActual TABLE(Id int,Value nvarchar(max),ErrorCode int);
INSERT @CallerActual SELECT c.Id,t.Value,t.ErrorCode FROM @CallerCases c
CROSS APPLY [$(ToolbeltDatabase)].toolbelt_pseudonymization.TVF_DeterministicTranslate
 (c.Input COLLATE Latin1_General_100_CI_AS_SC,1,0,c.Separators COLLATE Latin1_General_100_CI_AS_SC,N'standard' COLLATE Latin1_General_100_CI_AS_SC) t;
IF (SELECT COUNT_BIG(*) FROM @CallerActual)<>5
 OR EXISTS(SELECT 1 FROM @CallerActual GROUP BY Id HAVING COUNT_BIG(*)<>1)
 OR EXISTS(SELECT 1 FROM @CallerActual a JOIN @CallerCases c ON c.Id=a.Id
    WHERE a.ErrorCode IS NULL OR a.ErrorCode<>c.ExpectedCode
       OR (a.Value IS NULL AND c.ExpectedValue IS NOT NULL)
       OR (a.Value IS NOT NULL AND c.ExpectedValue IS NULL)
       OR CONVERT(varbinary(max),a.Value)<>CONVERT(varbinary(max),c.ExpectedValue))
    THROW 54090,N'Translate Safety: Caller-Collation Latin1_General_100_CI_AS_SC abweichend.',1;
GO
-- Integrierter Caller-Collation-Oracle: Latin1_General_100_CI_AS_SC_UTF8
SET NOCOUNT ON;
DECLARE @CallerCases TABLE(Id int PRIMARY KEY,Input nvarchar(max),Separators nvarchar(max),ExpectedCode int,ExpectedValue nvarchar(max));
INSERT @CallerCases VALUES
 (1,N'Aa09 - ',N'- ',0,N'Ss64 - '),
 (2,N'Aa09'+NCHAR(0),N'- ',13,NULL),
 (3,N'Aa09'+CONVERT(nvarchar(max),0x3DD800DE),N'- ',13,NULL),
 (4,N'Aa09 ',N'-',13,NULL),
 (5,N'Aa09 ',N' ',0,N'Ss64 ');
DECLARE @CallerActual TABLE(Id int,Value nvarchar(max),ErrorCode int);
INSERT @CallerActual SELECT c.Id,t.Value,t.ErrorCode FROM @CallerCases c
CROSS APPLY [$(ToolbeltDatabase)].toolbelt_pseudonymization.TVF_DeterministicTranslate
 (c.Input COLLATE Latin1_General_100_CI_AS_SC_UTF8,1,0,c.Separators COLLATE Latin1_General_100_CI_AS_SC_UTF8,N'standard' COLLATE Latin1_General_100_CI_AS_SC_UTF8) t;
IF (SELECT COUNT_BIG(*) FROM @CallerActual)<>5
 OR EXISTS(SELECT 1 FROM @CallerActual GROUP BY Id HAVING COUNT_BIG(*)<>1)
 OR EXISTS(SELECT 1 FROM @CallerActual a JOIN @CallerCases c ON c.Id=a.Id
    WHERE a.ErrorCode IS NULL OR a.ErrorCode<>c.ExpectedCode
       OR (a.Value IS NULL AND c.ExpectedValue IS NOT NULL)
       OR (a.Value IS NOT NULL AND c.ExpectedValue IS NULL)
       OR CONVERT(varbinary(max),a.Value)<>CONVERT(varbinary(max),c.ExpectedValue))
    THROW 54090,N'Translate Safety: Caller-Collation Latin1_General_100_CI_AS_SC_UTF8 abweichend.',1;
-- Große Operanden: eigener Batch je Fall, keine LOB-APPLY-Gesamtrelation.
-- Pro Call nur Länge/Hash speichern. Jeder Operand bleibt höchstens 16 MiB;
-- keine Heap-/Zeitgarantie, kein erhöhtes Testtimeout und keine Oraclelockerung.
GO
-- Safety Large Case 1
SET NOCOUNT ON;
DECLARE @Input nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),8388608),
        @Separators nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'-'),8388608),
        @Profile nvarchar(max)=N'standard',
        @ExpectedBytes bigint=NULL,
        @ExpectedHash varbinary(32)=HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),NULL));
DECLARE @Actual TABLE(Bytes bigint NULL,Digest varbinary(32) NULL,ErrorCode int NULL);
INSERT @Actual SELECT DATALENGTH(t.Value),HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),t.Value)),t.ErrorCode
FROM [$(ToolbeltDatabase)].toolbelt_pseudonymization.TVF_DeterministicTranslate
 (@Input,1,0,@Separators,@Profile) t;
IF (SELECT COUNT_BIG(*) FROM @Actual)<>1
 OR EXISTS(SELECT 1 FROM @Actual WHERE ErrorCode IS NULL OR ErrorCode<>11
    OR (@ExpectedBytes IS NULL AND (Bytes IS NOT NULL OR Digest IS NOT NULL))
    OR (@ExpectedBytes IS NOT NULL AND (Bytes IS NULL OR Bytes<>@ExpectedBytes
        OR Digest IS NULL OR Digest<>@ExpectedHash)))
    THROW 54090,N'Translate Safety: Large Case 1 abweichend.',1;
GO
-- Safety Large Case 2
SET NOCOUNT ON;
DECLARE @Input nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),8388608),
        @Separators nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'-'),8388608),
        @Profile nvarchar(max)=N'standard ',
        @ExpectedBytes bigint=NULL,
        @ExpectedHash varbinary(32)=HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),NULL));
DECLARE @Actual TABLE(Bytes bigint NULL,Digest varbinary(32) NULL,ErrorCode int NULL);
INSERT @Actual SELECT DATALENGTH(t.Value),HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),t.Value)),t.ErrorCode
FROM [$(ToolbeltDatabase)].toolbelt_pseudonymization.TVF_DeterministicTranslate
 (@Input,1,0,@Separators,@Profile) t;
IF (SELECT COUNT_BIG(*) FROM @Actual)<>1
 OR EXISTS(SELECT 1 FROM @Actual WHERE ErrorCode IS NULL OR ErrorCode<>10
    OR (@ExpectedBytes IS NULL AND (Bytes IS NOT NULL OR Digest IS NOT NULL))
    OR (@ExpectedBytes IS NOT NULL AND (Bytes IS NULL OR Bytes<>@ExpectedBytes
        OR Digest IS NULL OR Digest<>@ExpectedHash)))
    THROW 54090,N'Translate Safety: Large Case 2 abweichend.',1;
GO
-- Safety Large Case 3
SET NOCOUNT ON;
DECLARE @Input nvarchar(max)=NULL,
        @Separators nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'-'),8388608),
        @Profile nvarchar(max)=NULL,
        @ExpectedBytes bigint=NULL,
        @ExpectedHash varbinary(32)=HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),NULL));
DECLARE @Actual TABLE(Bytes bigint NULL,Digest varbinary(32) NULL,ErrorCode int NULL);
INSERT @Actual SELECT DATALENGTH(t.Value),HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),t.Value)),t.ErrorCode
FROM [$(ToolbeltDatabase)].toolbelt_pseudonymization.TVF_DeterministicTranslate
 (@Input,NULL,NULL,@Separators,@Profile) t;
IF (SELECT COUNT_BIG(*) FROM @Actual)<>1
 OR EXISTS(SELECT 1 FROM @Actual WHERE ErrorCode IS NULL OR ErrorCode<>0
    OR (@ExpectedBytes IS NULL AND (Bytes IS NOT NULL OR Digest IS NOT NULL))
    OR (@ExpectedBytes IS NOT NULL AND (Bytes IS NULL OR Bytes<>@ExpectedBytes
        OR Digest IS NULL OR Digest<>@ExpectedHash)))
    THROW 54090,N'Translate Safety: Large Case 3 abweichend.',1;
GO
-- Safety Large Case 4
SET NOCOUNT ON;
DECLARE @Input nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),8388608),
        @Separators nvarchar(max)=N'',
        @Profile nvarchar(max)=N'standard',
        @ExpectedBytes bigint=NULL,
        @ExpectedHash varbinary(32)=HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),NULL));
DECLARE @Actual TABLE(Bytes bigint NULL,Digest varbinary(32) NULL,ErrorCode int NULL);
INSERT @Actual SELECT DATALENGTH(t.Value),HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),t.Value)),t.ErrorCode
FROM [$(ToolbeltDatabase)].toolbelt_pseudonymization.TVF_DeterministicTranslate
 (@Input,1,0,@Separators,@Profile) t;
IF (SELECT COUNT_BIG(*) FROM @Actual)<>1
 OR EXISTS(SELECT 1 FROM @Actual WHERE ErrorCode IS NULL OR ErrorCode<>12
    OR (@ExpectedBytes IS NULL AND (Bytes IS NOT NULL OR Digest IS NOT NULL))
    OR (@ExpectedBytes IS NOT NULL AND (Bytes IS NULL OR Bytes<>@ExpectedBytes
        OR Digest IS NULL OR Digest<>@ExpectedHash)))
    THROW 54090,N'Translate Safety: Large Case 4 abweichend.',1;
GO
-- Safety Large Case 5
SET NOCOUNT ON;
DECLARE @Input nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),1048577),
        @Separators nvarchar(max)=N'',
        @Profile nvarchar(max)=N'standard',
        @ExpectedBytes bigint=NULL,
        @ExpectedHash varbinary(32)=HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),NULL));
DECLARE @Actual TABLE(Bytes bigint NULL,Digest varbinary(32) NULL,ErrorCode int NULL);
INSERT @Actual SELECT DATALENGTH(t.Value),HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),t.Value)),t.ErrorCode
FROM [$(ToolbeltDatabase)].toolbelt_pseudonymization.TVF_DeterministicTranslate
 (@Input,1,0,@Separators,@Profile) t;
IF (SELECT COUNT_BIG(*) FROM @Actual)<>1
 OR EXISTS(SELECT 1 FROM @Actual WHERE ErrorCode IS NULL OR ErrorCode<>12
    OR (@ExpectedBytes IS NULL AND (Bytes IS NOT NULL OR Digest IS NOT NULL))
    OR (@ExpectedBytes IS NOT NULL AND (Bytes IS NULL OR Bytes<>@ExpectedBytes
        OR Digest IS NULL OR Digest<>@ExpectedHash)))
    THROW 54090,N'Translate Safety: Large Case 5 abweichend.',1;
GO
-- Safety Large Case 6
SET NOCOUNT ON;
DECLARE @Input nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),1048576),
        @Separators nvarchar(max)=N'',
        @Profile nvarchar(max)=N'standard',
        @ExpectedBytes bigint=2097152,
        @ExpectedHash varbinary(32)=HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),REPLICATE(CONVERT(nvarchar(max),N's'),1048576)));
DECLARE @Actual TABLE(Bytes bigint NULL,Digest varbinary(32) NULL,ErrorCode int NULL);
INSERT @Actual SELECT DATALENGTH(t.Value),HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),t.Value)),t.ErrorCode
FROM [$(ToolbeltDatabase)].toolbelt_pseudonymization.TVF_DeterministicTranslate
 (@Input,1,0,@Separators,@Profile) t;
IF (SELECT COUNT_BIG(*) FROM @Actual)<>1
 OR EXISTS(SELECT 1 FROM @Actual WHERE ErrorCode IS NULL OR ErrorCode<>0
    OR (@ExpectedBytes IS NULL AND (Bytes IS NOT NULL OR Digest IS NOT NULL))
    OR (@ExpectedBytes IS NOT NULL AND (Bytes IS NULL OR Bytes<>@ExpectedBytes
        OR Digest IS NULL OR Digest<>@ExpectedHash)))
    THROW 54090,N'Translate Safety: Large Case 6 abweichend.',1;
GO
-- Safety Large Case 7
SET NOCOUNT ON;
DECLARE @Input nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),1048575)+NCHAR(0),
        @Separators nvarchar(max)=N'',
        @Profile nvarchar(max)=N'standard',
        @ExpectedBytes bigint=NULL,
        @ExpectedHash varbinary(32)=HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),NULL));
DECLARE @Actual TABLE(Bytes bigint NULL,Digest varbinary(32) NULL,ErrorCode int NULL);
INSERT @Actual SELECT DATALENGTH(t.Value),HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),t.Value)),t.ErrorCode
FROM [$(ToolbeltDatabase)].toolbelt_pseudonymization.TVF_DeterministicTranslate
 (@Input,1,0,@Separators,@Profile) t;
IF (SELECT COUNT_BIG(*) FROM @Actual)<>1
 OR EXISTS(SELECT 1 FROM @Actual WHERE ErrorCode IS NULL OR ErrorCode<>13
    OR (@ExpectedBytes IS NULL AND (Bytes IS NOT NULL OR Digest IS NOT NULL))
    OR (@ExpectedBytes IS NOT NULL AND (Bytes IS NULL OR Bytes<>@ExpectedBytes
        OR Digest IS NULL OR Digest<>@ExpectedHash)))
    THROW 54090,N'Translate Safety: Large Case 7 abweichend.',1;
GO
-- Safety Large Case 8
SET NOCOUNT ON;
DECLARE @Input nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),1048575)+N' ',
        @Separators nvarchar(max)=N'',
        @Profile nvarchar(max)=N'standard',
        @ExpectedBytes bigint=NULL,
        @ExpectedHash varbinary(32)=HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),NULL));
DECLARE @Actual TABLE(Bytes bigint NULL,Digest varbinary(32) NULL,ErrorCode int NULL);
INSERT @Actual SELECT DATALENGTH(t.Value),HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),t.Value)),t.ErrorCode
FROM [$(ToolbeltDatabase)].toolbelt_pseudonymization.TVF_DeterministicTranslate
 (@Input,1,0,@Separators,@Profile) t;
IF (SELECT COUNT_BIG(*) FROM @Actual)<>1
 OR EXISTS(SELECT 1 FROM @Actual WHERE ErrorCode IS NULL OR ErrorCode<>13
    OR (@ExpectedBytes IS NULL AND (Bytes IS NOT NULL OR Digest IS NOT NULL))
    OR (@ExpectedBytes IS NOT NULL AND (Bytes IS NULL OR Bytes<>@ExpectedBytes
        OR Digest IS NULL OR Digest<>@ExpectedHash)))
    THROW 54090,N'Translate Safety: Large Case 8 abweichend.',1;
GO
-- Safety Large Case 9
SET NOCOUNT ON;
DECLARE @Input nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),8388608),
        @Separators nvarchar(max)=N'',
        @Profile nvarchar(max)=N'large',
        @ExpectedBytes bigint=16777216,
        @ExpectedHash varbinary(32)=HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),REPLICATE(CONVERT(nvarchar(max),N's'),8388608)));
DECLARE @Actual TABLE(Bytes bigint NULL,Digest varbinary(32) NULL,ErrorCode int NULL);
INSERT @Actual SELECT DATALENGTH(t.Value),HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),t.Value)),t.ErrorCode
FROM [$(ToolbeltDatabase)].toolbelt_pseudonymization.TVF_DeterministicTranslate
 (@Input,1,0,@Separators,@Profile) t;
IF (SELECT COUNT_BIG(*) FROM @Actual)<>1
 OR EXISTS(SELECT 1 FROM @Actual WHERE ErrorCode IS NULL OR ErrorCode<>0
    OR (@ExpectedBytes IS NULL AND (Bytes IS NOT NULL OR Digest IS NOT NULL))
    OR (@ExpectedBytes IS NOT NULL AND (Bytes IS NULL OR Bytes<>@ExpectedBytes
        OR Digest IS NULL OR Digest<>@ExpectedHash)))
    THROW 54090,N'Translate Safety: Large Case 9 abweichend.',1;
GO
-- Safety Large Case 10
SET NOCOUNT ON;
DECLARE @Input nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),8388607)+NCHAR(0),
        @Separators nvarchar(max)=N'',
        @Profile nvarchar(max)=N'large',
        @ExpectedBytes bigint=NULL,
        @ExpectedHash varbinary(32)=HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),NULL));
DECLARE @Actual TABLE(Bytes bigint NULL,Digest varbinary(32) NULL,ErrorCode int NULL);
INSERT @Actual SELECT DATALENGTH(t.Value),HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),t.Value)),t.ErrorCode
FROM [$(ToolbeltDatabase)].toolbelt_pseudonymization.TVF_DeterministicTranslate
 (@Input,1,0,@Separators,@Profile) t;
IF (SELECT COUNT_BIG(*) FROM @Actual)<>1
 OR EXISTS(SELECT 1 FROM @Actual WHERE ErrorCode IS NULL OR ErrorCode<>13
    OR (@ExpectedBytes IS NULL AND (Bytes IS NOT NULL OR Digest IS NOT NULL))
    OR (@ExpectedBytes IS NOT NULL AND (Bytes IS NULL OR Bytes<>@ExpectedBytes
        OR Digest IS NULL OR Digest<>@ExpectedHash)))
    THROW 54090,N'Translate Safety: Large Case 10 abweichend.',1;
GO
-- Safety Large Case 11
SET NOCOUNT ON;
DECLARE @Input nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),8388606)+N'- ',
        @Separators nvarchar(max)=N' -',
        @Profile nvarchar(max)=N'large',
        @ExpectedBytes bigint=16777216,
        @ExpectedHash varbinary(32)=HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),REPLICATE(CONVERT(nvarchar(max),N's'),8388606)+N'- '));
DECLARE @Actual TABLE(Bytes bigint NULL,Digest varbinary(32) NULL,ErrorCode int NULL);
INSERT @Actual SELECT DATALENGTH(t.Value),HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),t.Value)),t.ErrorCode
FROM [$(ToolbeltDatabase)].toolbelt_pseudonymization.TVF_DeterministicTranslate
 (@Input,1,0,@Separators,@Profile) t;
IF (SELECT COUNT_BIG(*) FROM @Actual)<>1
 OR EXISTS(SELECT 1 FROM @Actual WHERE ErrorCode IS NULL OR ErrorCode<>0
    OR (@ExpectedBytes IS NULL AND (Bytes IS NOT NULL OR Digest IS NOT NULL))
    OR (@ExpectedBytes IS NOT NULL AND (Bytes IS NULL OR Bytes<>@ExpectedBytes
        OR Digest IS NULL OR Digest<>@ExpectedHash)))
    THROW 54090,N'Translate Safety: Large Case 11 abweichend.',1;
PRINT N'PASS: Translate unabhängige Safety-Orakel.';
