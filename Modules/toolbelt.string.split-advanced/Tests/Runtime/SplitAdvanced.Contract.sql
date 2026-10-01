-- Synthetischer S2-Verhaltensvertrag; Ausgabe nur abstraktes Gesamtergebnis.
SET NOCOUNT ON;
DECLARE @ObjectId int = OBJECT_ID(N'toolbelt_string.TVF_SplitAdvanced', N'TF');
IF @ObjectId IS NULL THROW 54500, N'Die öffentliche Multi-statement-TVF fehlt.', 1;
IF (SELECT COUNT(*) FROM sys.parameters WHERE object_id = @ObjectId) <> 5
   OR (SELECT COUNT(*) FROM sys.columns WHERE object_id = @ObjectId) <> 5
   OR EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@ObjectId
       AND is_nullable<>CASE WHEN name=N'IsValid' THEN 0 ELSE 1 END)
   OR EXISTS
   (
       SELECT 1 FROM (VALUES (1,N'Value',231,-1),(2,N'Ordinal',127,8),
          (3,N'IsValid',104,1),(4,N'ErrorCode',167,64),(5,N'ErrorPosition',127,8))
          expected(Ordinal,Name,TypeId,Length)
       LEFT JOIN sys.columns actual ON actual.object_id=@ObjectId AND actual.column_id=expected.Ordinal
       WHERE actual.name<>expected.Name OR actual.system_type_id<>expected.TypeId OR actual.max_length<>expected.Length
   )
   OR EXISTS
   (
       SELECT 1 FROM (VALUES (1,N'@Input',231,-1),(2,N'@SeparatorsJson',231,-1),
         (3,N'@Quote',231,-1),(4,N'@Escape',231,-1),(5,N'@KeepEmpty',104,1))
         expected(Ordinal,Name,TypeId,Length)
       LEFT JOIN sys.parameters actual ON actual.object_id=@ObjectId AND actual.parameter_id=expected.Ordinal
       WHERE actual.name<>expected.Name OR actual.system_type_id<>expected.TypeId OR actual.max_length<>expected.Length
   )
    THROW 54501, N'Signatur oder Resultset stimmt nicht mit S2 überein.', 1;

DECLARE @Cases TABLE
(
    CaseOrdinal int IDENTITY PRIMARY KEY, Input nvarchar(max), Separators nvarchar(max),
    Quote nvarchar(max), EscapeCharacter nvarchar(max), KeepEmpty bit,
    ExpectedTokens nvarchar(max), ErrorCode varchar(64), ErrorPosition bigint
);
INSERT @Cases (Input,Separators,Quote,EscapeCharacter,KeepEmpty,ExpectedTokens,ErrorCode,ErrorPosition)
VALUES
 (NULL,NULL,NULL,NULL,NULL,N'[]',NULL,NULL),
 (N'',N'[";"]',N'"',N'\',1,N'[""]',NULL,NULL),
 (N'',N'[";"]',N'"',N'\',0,N'[]',NULL,NULL),
 (N'',N'[";"]',N'',N'',NULL,N'[""]',NULL,NULL),
 (N'a  b c',N'[" ","  "]',N'',N'',1,N'["a","b","c"]',NULL,NULL),
 (N'a',N'"scalar"',N'',N'',1,NULL,'INVALID_SEPARATOR_JSON',NULL),
 (N'a',N'[[";"]]',N'',N'',1,NULL,'INVALID_CONFIGURATION',NULL),
 (N'a'+NCHAR(0)+N'\',N'[";"]',N'"',N'\',1,NULL,'NUL_NOT_ALLOWED',2),
 (N';a;;b;',N'[";"]',N'"',N'\',0,N'["a","b"]',NULL,NULL),
 (N'a;"b;c";d',N'[";"]',N'"',N'\',1,N'["a","\"b;c\"","d"]',NULL,NULL),
 (N'a"b;c"d;e',N'[";"]',N'"',N'\',1,N'["a\"b;c\"d","e"]',NULL,NULL),
 (N'a\;b;c',N'[";"]',N'"',N'\',1,N'["a\\;b","c"]',NULL,NULL),
 (N'a\xb;c',N'[";"]',N'"',N'\',1,N'["a\\xb","c"]',NULL,NULL),
 (N'a::b:c',N'[":","::"]',N'',N'',1,N'["a","b","c"]',NULL,NULL),
 (N' A ; B  ',N'[";"]',N'',N'',NULL,N'[" A "," B  "]',NULL,NULL),
 (N'a;b',N'["A",";"]',N'',N'',1,N'["a","b"]',NULL,NULL),
 (N'a;b',N'[";","; "]',N'',N'',1,N'["a","b"]',NULL,NULL),
 (N'a; b',N'[";","; "]',N'',N'',1,N'["a","b"]',NULL,NULL),
 (N'a;',N'[";"]',N'',N'',1,N'["a",""]',NULL,NULL),
 (N'a',NULL,N'',N'',1,NULL,'INVALID_CONFIGURATION',NULL),
 (N'a',N'[";"]',NULL,N'',1,NULL,'INVALID_CONFIGURATION',NULL),
 (N'a',N'[";"]',N'',NULL,1,NULL,'INVALID_CONFIGURATION',NULL),
 (N'a',N'{"x":";"}',N'',N'',1,NULL,'INVALID_SEPARATOR_JSON',NULL),
 (N'a',N'[',N'',N'',1,NULL,'INVALID_SEPARATOR_JSON',NULL),
 (N'a',N'[]',N'',N'',1,NULL,'INVALID_CONFIGURATION',NULL),
 (N'a',N'[null]',N'',N'',1,NULL,'INVALID_CONFIGURATION',NULL),
 (N'a',N'[1]',N'',N'',1,NULL,'INVALID_CONFIGURATION',NULL),
 (N'a',N'[""]',N'',N'',1,NULL,'EMPTY_SEPARATOR',NULL),
 (N'a',N'[";",";"]',N'',N'',1,NULL,'DUPLICATE_SEPARATOR',NULL),
 (N'a',N'[";"]',N'xx',N'',1,NULL,'INVALID_CONFIGURATION',NULL),
 (N'a',N'[";"]',N'"',N'"',1,NULL,'INVALID_CONFIGURATION',NULL),
 (N'a',N'["x\"y"]',N'"',N'',1,NULL,'INVALID_CONFIGURATION',NULL),
 (N'a',N'["\\"]',N'',N'\',1,NULL,'INVALID_CONFIGURATION',NULL),
 (N'a;"b',N'[";"]',N'"',N'\',1,NULL,'UNTERMINATED_QUOTE',3),
 (N'a;b\',N'[";"]',N'"',N'\',1,NULL,'DANGLING_ESCAPE',4),
 (N'a;"b\',N'[";"]',N'"',N'\',1,NULL,'DANGLING_ESCAPE',5),
 (N'a',N'["\u0000"]',N'',N'',1,NULL,'NUL_NOT_ALLOWED',NULL),
 (N'a'+NCHAR(0),N'[";"]',N'',N'',1,NULL,'NUL_NOT_ALLOWED',2),
 (N'a'+NCHAR(0),N'[]',N'',N'',1,NULL,'INVALID_CONFIGURATION',NULL),
 (N'a',N'["","\u0000"]',NCHAR(0),N'',1,NULL,'EMPTY_SEPARATOR',NULL),
 (N'a',N'[";"]',NCHAR(0),N'',1,NULL,'NUL_NOT_ALLOWED',NULL),
 (N'a',N'[";"]',CONVERT(nvarchar(max),0x3DD8),N'',1,NULL,'INVALID_CONFIGURATION',NULL),
 (REPLICATE(CONVERT(nvarchar(max),N'x'),65537),N'[";"]',N'',N'',1,NULL,'INPUT_LIMIT_EXCEEDED',NULL),
 (REPLICATE(CONVERT(nvarchar(max),N'x'),65537),NULL,N'',N'',1,NULL,'INVALID_CONFIGURATION',NULL),
 (N'a',REPLICATE(CONVERT(nvarchar(max),N' '),16385),N'',N'',1,NULL,'JSON_LIMIT_EXCEEDED',NULL),
 (N'a',N'["'+REPLICATE(N'x',65)+N'"]',N'',N'',1,NULL,'SEPARATOR_LIMIT_EXCEEDED',NULL),
 (N'a',N'["1","2","3","4","5","6","7","8","9","a","b","c","d","e","f","g","h"]',N'',N'',1,NULL,'SEPARATOR_LIMIT_EXCEEDED',NULL);

DECLARE @Unicode nvarchar(max)=CONVERT(nvarchar(max),0x3DD800DE);
INSERT @Cases (Input,Separators,Quote,EscapeCharacter,KeepEmpty,ExpectedTokens,ErrorCode,ErrorPosition)
VALUES (N'\'+@Unicode+N';z',N'[";"]',N'"',N'\',1,N'["\\'+@Unicode+N'","z"]',NULL,NULL),
       (@Unicode+N';x',N'[";"]',N'',N'',1,N'["'+@Unicode+N'","x"]',NULL,NULL),
       (N'a'+@Unicode+N'b',N'["'+@Unicode+N'"]',N'',N'',1,N'["a","b"]',NULL,NULL),
       (REPLICATE(CONVERT(nvarchar(max),N'x'),65536),N'[";"]',N'',N'',1,N'["'+REPLICATE(CONVERT(nvarchar(max),N'x'),65536)+N'"]',NULL,NULL),
       (N'a',REPLICATE(CONVERT(nvarchar(max),N' '),16379)+N'[";"]',N'',N'',1,N'["a"]',NULL,NULL),
       (N'a',N'["'+REPLICATE(N'x',64)+N'"]',N'',N'',1,N'["a"]',NULL,NULL),
       (N'a',N'["1","2","3","4","5","6","7","8","9","b","c","d","e","f","g","h"]',N'',N'',1,N'["a"]',NULL,NULL);

DECLARE @Actual TABLE (Value nvarchar(max),Ordinal bigint,IsValid bit,ErrorCode varchar(64),ErrorPosition bigint);
DECLARE @Case int=1,@Count int=(SELECT COUNT(*) FROM @Cases),@Input nvarchar(max),@Separators nvarchar(max),
        @Quote nvarchar(max),@EscapeCharacter nvarchar(max),@KeepEmpty bit,@ExpectedTokens nvarchar(max),@Error varchar(64),@Position bigint;
WHILE @Case<=@Count
BEGIN
    SELECT @Input=Input,@Separators=Separators,@Quote=Quote,@EscapeCharacter=EscapeCharacter,@KeepEmpty=KeepEmpty,
           @ExpectedTokens=ExpectedTokens,@Error=ErrorCode,@Position=ErrorPosition FROM @Cases WHERE CaseOrdinal=@Case;
    DELETE @Actual;
    INSERT @Actual SELECT * FROM toolbelt_string.TVF_SplitAdvanced(@Input,@Separators,@Quote,@EscapeCharacter,@KeepEmpty);
    IF @Error IS NOT NULL
    BEGIN
        IF (SELECT COUNT(*) FROM @Actual)<>1 OR NOT EXISTS
        (SELECT 1 FROM @Actual WHERE Value IS NULL AND Ordinal IS NULL AND IsValid=0
          AND ErrorCode=@Error AND (ErrorPosition=@Position OR (ErrorPosition IS NULL AND @Position IS NULL)))
            THROW 54502,N'Geschäftsfehlercode, Position oder atomare Fehlerausgabe falsch.',1;
    END;
    ELSE
    BEGIN
        IF EXISTS(SELECT 1 FROM @Actual WHERE IsValid IS NULL OR IsValid<>1 OR ErrorCode IS NOT NULL OR ErrorPosition IS NOT NULL OR Value IS NULL)
           OR EXISTS(SELECT CONVERT(varbinary(max),Value),Ordinal FROM @Actual EXCEPT
                     SELECT CONVERT(varbinary(max),value),CONVERT(bigint,[key])+1 FROM OPENJSON(@ExpectedTokens))
           OR EXISTS(SELECT CONVERT(varbinary(max),value),CONVERT(bigint,[key])+1 FROM OPENJSON(@ExpectedTokens) EXCEPT
                     SELECT CONVERT(varbinary(max),Value),Ordinal FROM @Actual)
            THROW 54503,N'Originaltoken oder lückenloser Ordinal falsch.',1;
    END;
    SET @Case+=1;
END;
IF (SELECT COUNT(*) FROM toolbelt_string.TVF_SplitAdvanced(N'a;"b;c"',N'[";"]',DEFAULT,DEFAULT,DEFAULT))<>2
    THROW 54504,N'Die Defaultparameter sind falsch.',1;
IF (SELECT COUNT(*) FROM (VALUES(N'a;b'),(N'x')) input(Value)
    CROSS APPLY toolbelt_string.TVF_SplitAdvanced(input.Value,N'[";"]',N'',N'',1) tokens)<>3
    THROW 54505,N'Der relationale APPLY-Vertrag ist falsch.',1;
PRINT N'Split-Advanced Contract: erfolgreich';
GO
