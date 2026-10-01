SET NOCOUNT ON;
-- Synthetische, bytegenaue Oracles: NULL darf keine falschen Erfolge erzeugen.
DECLARE @Cases TABLE
(Id int IDENTITY,Input nvarchar(max),Qualifier nvarchar(max),Closing nvarchar(max),BackslashMode bit,
 Expected nvarchar(max),Code varchar(64),Position bigint);
INSERT @Cases VALUES
(NULL,N'long',N'',1,NULL,NULL,NULL),
(N'',NULL,NULL,0,N'',NULL,NULL),
(N'',N'"',NULL,0,NULL,'OUTER_PAIR_REQUIRED',NULL),
(N'"',NULL,NULL,0,N'"',NULL,NULL),
(N'"',N'"',NULL,0,NULL,'OUTER_PAIR_REQUIRED',1),
(N'""',NULL,NULL,0,N'',NULL,NULL),
(N'"""',NULL,NULL,0,NULL,'UNESCAPED_CLOSING_QUALIFIER',2),
(N'""""',NULL,NULL,0,N'"',NULL,NULL),
(N'"hallo""du"""',NULL,NULL,0,N'hallo"du"',NULL,NULL),
(N'[a]]b]',NULL,NULL,0,N'a]b',NULL,NULL),
(N'[a]b]',NULL,NULL,0,NULL,'UNESCAPED_CLOSING_QUALIFIER',3),
(N'[a]]b]',N']',NULL,0,N'a]b',NULL,NULL),
(N'“Hallo',NULL,NULL,0,N'“Hallo',NULL,NULL),
(N'“a”',NULL,NULL,0,N'a',NULL,NULL),
(N'„a“',NULL,NULL,0,N'a',NULL,NULL),
(N'“a”',N'”',NULL,0,N'a',NULL,NULL),
(N'“a“',N'“',N'“',0,N'a',NULL,NULL),
(N' a ',N' ',NULL,0,N'a',NULL,NULL),
(N'<a  >',N'<',N'>',0,N'a  ',NULL,NULL),
(N'"a\"',NULL,NULL,1,N'"a\"',NULL,NULL),
(N'"a\"',N'"',NULL,1,NULL,'OUTER_PAIR_REQUIRED',4),
(N'"a\\"',NULL,NULL,1,N'a\',NULL,NULL),
(N'"a\\\"',NULL,NULL,1,N'"a\\\"',NULL,NULL),
(N'"a\\\\b"',NULL,NULL,1,N'a\\b',NULL,NULL),
(N'[a\[b\]c]',NULL,NULL,1,N'a[b]c',NULL,NULL),
(N'"a\nb\tc\u0041"',NULL,NULL,1,N'a\nb\tc\u0041',NULL,NULL),
(N'"a\q"b"',NULL,NULL,1,NULL,'UNESCAPED_CLOSING_QUALIFIER',5),
(N'"a\"',NULL,NULL,0,N'a\',NULL,NULL),
(N' no quotes  ',NULL,NULL,1,N' no quotes  ',NULL,NULL),
(N'"a""b"',N'',NULL,1,N'"a""b"',NULL,NULL),
(N'x',NULL,N']',0,NULL,'INVALID_CONFIGURATION',NULL),
(N'x',N'',N'',0,NULL,'INVALID_CONFIGURATION',NULL),
(N'x',N'ab',NULL,0,NULL,'INVALID_CONFIGURATION',NULL),
(N'x',N'"',N'',0,NULL,'INVALID_CONFIGURATION',NULL),
(N'x',NCHAR(0),NULL,0,NULL,'INVALID_CONFIGURATION',NULL),
(N'x',N'"',NCHAR(0),0,NULL,'INVALID_CONFIGURATION',NULL),
(N'x',N'"',NULL,0,NULL,'OUTER_PAIR_REQUIRED',1),
(N'a'+NCHAR(0),N'',NULL,0,NULL,'NUL_NOT_ALLOWED',2),
(N'\a\',N'\',NULL,1,NULL,'INVALID_CONFIGURATION',NULL),
(N'\a\',N'\',NULL,0,N'a',NULL,NULL);
INSERT @Cases VALUES(N'''a''''b''',NULL,NULL,NULL,N'a''b',NULL,NULL);
DECLARE @Unicode nvarchar(max)=CONVERT(nvarchar(max),0x3DD800DE);
INSERT @Cases VALUES(N'"'+@Unicode+N'  "',NULL,NULL,0,@Unicode+N'  ',NULL,NULL),
(N'x',CONVERT(nvarchar(max),0x3DD8),NULL,0,NULL,'INVALID_CONFIGURATION',NULL),
(N'"'+@Unicode+N'"b"',NULL,NULL,0,NULL,'UNESCAPED_CLOSING_QUALIFIER',4),
(REPLICATE(CAST(N'x' AS nvarchar(max)),65536),NULL,NULL,0,REPLICATE(CAST(N'x' AS nvarchar(max)),65536),NULL,NULL),
(REPLICATE(CAST(N'x' AS nvarchar(max)),65537),NULL,NULL,0,NULL,'INPUT_LIMIT_EXCEEDED',NULL),
(REPLICATE(CAST(N'x' AS nvarchar(max)),65537),N'ab',NULL,0,NULL,'INVALID_CONFIGURATION',NULL),
(NCHAR(0)+REPLICATE(CAST(N'x' AS nvarchar(max)),65536),NULL,NULL,0,NULL,'INPUT_LIMIT_EXCEEDED',NULL),
(N'a'+NCHAR(0)+N'"',NULL,NULL,0,NULL,'NUL_NOT_ALLOWED',2);
-- Dichter worst-case: 65536 Codeeinheiten, 32767 Doubles innerhalb der Ränder.
INSERT @Cases VALUES(REPLICATE(CAST(N'"' AS nvarchar(max)),65536),NULL,NULL,0,
                     REPLICATE(CAST(N'"' AS nvarchar(max)),32767),NULL,NULL);
DECLARE @Id int=1,@Count int=(SELECT COUNT(*) FROM @Cases),
        @Input nvarchar(max),@Qualifier nvarchar(max),@Closing nvarchar(max),@Escape bit,
        @Expected nvarchar(max),@Code varchar(64),@Position bigint;
DECLARE @Actual TABLE(Value nvarchar(max),IsValid bit,ErrorCode varchar(64),ErrorPosition bigint);
WHILE @Id<=@Count
BEGIN
    SELECT @Input=Input,@Qualifier=Qualifier,@Closing=Closing,@Escape=BackslashMode,
           @Expected=Expected,@Code=Code,@Position=Position FROM @Cases WHERE Id=@Id;
    DELETE @Actual;
    INSERT @Actual SELECT * FROM toolbelt_string.TVF_UnquoteToken(@Input,@Qualifier,@Closing,@Escape);
    IF @Input IS NULL
    BEGIN
        IF EXISTS(SELECT 1 FROM @Actual) THROW 54550,N'Unquote NULL-No-op falsch.',1;
    END;
    ELSE
    BEGIN
        IF (SELECT COUNT(*) FROM @Actual)<>1 THROW 54551,N'Unquote atomare Zeilenanzahl falsch.',1;
        IF @Code IS NULL
        BEGIN
            IF EXISTS(SELECT 1 FROM @Actual WHERE IsValid IS NULL OR IsValid<>1 OR Value IS NULL
                OR CONVERT(varbinary(max),Value)<>CONVERT(varbinary(max),@Expected)
                OR ErrorCode IS NOT NULL OR ErrorPosition IS NOT NULL)
                THROW 54552,N'Unquote Erfolg/Bytes falsch.',1;
        END;
        ELSE IF EXISTS(SELECT 1 FROM @Actual WHERE IsValid IS NULL OR IsValid<>0 OR Value IS NOT NULL
             OR ErrorCode IS NULL OR ErrorCode<>@Code
             OR (ErrorPosition IS NULL AND @Position IS NOT NULL)
             OR (ErrorPosition IS NOT NULL AND @Position IS NULL)
             OR ErrorPosition<>@Position)
             THROW 54553,N'Unquote Errorrow/Priorität/Position falsch.',1;
    END;
    SET @Id+=1;
END;
DECLARE @ExpectedColumns TABLE(Id int,Name sysname,TypeName sysname,Length smallint,Nullable bit);
INSERT @ExpectedColumns VALUES(1,N'Value',N'nvarchar',-1,1),(2,N'IsValid',N'bit',1,0),
 (3,N'ErrorCode',N'varchar',64,1),(4,N'ErrorPosition',N'bigint',8,1);
IF EXISTS(SELECT Id,Name,TypeName,Length,Nullable FROM @ExpectedColumns EXCEPT
    SELECT column_id,name COLLATE DATABASE_DEFAULT,TYPE_NAME(system_type_id) COLLATE DATABASE_DEFAULT,max_length,is_nullable FROM sys.columns
    WHERE object_id=OBJECT_ID(N'toolbelt_string.TVF_UnquoteToken'))
    OR (SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID(N'toolbelt_string.TVF_UnquoteToken'))<>4
    THROW 54554,N'Unquote Resultmetadaten falsch.',1;
DECLARE @ExpectedParameters TABLE(Id int,Name sysname,TypeName sysname,Length smallint);
INSERT @ExpectedParameters VALUES(1,N'@Input',N'nvarchar',-1),(2,N'@Qualifier',N'nvarchar',-1),
 (3,N'@ClosingQualifier',N'nvarchar',-1),(4,N'@BackslashEscape',N'bit',1);
IF EXISTS(SELECT Id,Name,TypeName,Length FROM @ExpectedParameters EXCEPT
    SELECT parameter_id,name COLLATE DATABASE_DEFAULT,TYPE_NAME(system_type_id) COLLATE DATABASE_DEFAULT,max_length FROM sys.parameters
    WHERE object_id=OBJECT_ID(N'toolbelt_string.TVF_UnquoteToken'))
    OR (SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_string.TVF_UnquoteToken'))<>4
    THROW 54556,N'Unquote Parametermetadaten falsch.',1;
IF (SELECT COUNT(*) FROM @Cases c CROSS APPLY toolbelt_string.TVF_UnquoteToken(c.Input,c.Qualifier,c.Closing,c.BackslashMode) q)
   <>@Count-1 THROW 54555,N'Unquote APPLY falsch.',1;
PRINT N'UnquoteToken Contract: erfolgreich';
GO
