SET NOCOUNT ON;

-- Ausschließlich Parserdaten: kein Statement des Korpus wird ausgeführt.
DECLARE @Corpus table (CaseId int IDENTITY PRIMARY KEY, SqlText nvarchar(max), ExpectedNodeType nvarchar(128));
INSERT @Corpus (SqlText, ExpectedNodeType) VALUES
 (N'WITH c AS (SELECT 1 AS x) SELECT x FROM c UNION ALL SELECT 2;', N'SelectStatement'),
 (N'SELECT a.x FROM (VALUES(1)) a(x) CROSS APPLY (SELECT a.x) b WHERE EXISTS(SELECT 1);', N'SelectStatement'),
 (N'INSERT dbo.ContosoTable(x) VALUES(1); UPDATE dbo.ContosoTable SET x=2; DELETE dbo.ContosoTable WHERE x=2;', N'InsertStatement'),
 (N'MERGE dbo.ContosoTable AS t USING(VALUES(1)) s(x) ON t.x=s.x WHEN MATCHED THEN UPDATE SET x=s.x WHEN NOT MATCHED THEN INSERT(x) VALUES(s.x);', N'MergeStatement'),
 (N'CREATE TABLE dbo.ContosoTable(x int NOT NULL CONSTRAINT PK_Contoso PRIMARY KEY,y int CONSTRAINT CK_Contoso CHECK(y>0));', N'CreateTableStatement'),
 (N'CREATE INDEX IX_Contoso ON dbo.ContosoTable(x); ALTER TABLE dbo.ContosoTable ADD z int; DROP INDEX IX_Contoso ON dbo.ContosoTable;', N'CreateIndexStatement'),
 (N'CREATE PROCEDURE dbo.ContosoProcedure @x int AS BEGIN SELECT @x; END;', N'CreateProcedureStatement'),
 (N'CREATE FUNCTION dbo.ContosoFunction(@x int) RETURNS int AS BEGIN RETURN @x; END;', N'CreateFunctionStatement'),
 (N'CREATE TRIGGER dbo.ContosoTrigger ON dbo.ContosoTable AFTER INSERT AS BEGIN SELECT x FROM inserted; END;', N'CreateTriggerStatement'),
 (N'BEGIN TRY BEGIN TRANSACTION; SAVE TRANSACTION ContosoSave; COMMIT TRANSACTION; END TRY BEGIN CATCH SELECT ERROR_NUMBER(); END CATCH;', N'TryCatchStatement'),
 (N'CREATE USER ContosoUser WITHOUT LOGIN; CREATE ROLE ContosoRole; ALTER ROLE ContosoRole ADD MEMBER ContosoUser; GRANT SELECT ON dbo.ContosoTable TO ContosoRole; DENY UPDATE ON dbo.ContosoTable TO ContosoRole; REVOKE SELECT ON dbo.ContosoTable FROM ContosoRole;', N'CreateUserStatement'),
 (N'SELECT N''ä😀'' AS [a]]b]; /* CASE BEGIN ( */' + NCHAR(10) + N'GO' + NCHAR(10) + N'SELECT ''zweite Zeile'';', N'SelectStatement');

DECLARE @Versions table (VersionId int PRIMARY KEY, TSqlVersion int);
INSERT @Versions VALUES (1,150),(2,160),(3,170);
DECLARE @VersionId int=1, @CaseId int, @Version int, @Text nvarchar(max), @Type nvarchar(128), @Roundtrip nvarchar(max);
WHILE @VersionId <= 3
BEGIN
    SELECT @Version=TSqlVersion FROM @Versions WHERE VersionId=@VersionId;
    SET @CaseId=1;
    WHILE @CaseId <= (SELECT COUNT(*) FROM @Corpus)
    BEGIN
        SELECT @Text=SqlText,@Type=ExpectedNodeType FROM @Corpus WHERE CaseId=@CaseId;
        IF EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptErrors(@Text,@Version,1,NULL,NULL))
            THROW 53132, N'Der repräsentative Syntaxkorpus lieferte unerwartete Diagnosen.',1;
        IF NOT EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptNodes(@Text,@Version,1,NULL,NULL)
                       WHERE NodeId=1 AND ParentNodeId IS NULL AND Depth=0 AND NodeType=N'TSqlScript' AND StartOffset=0)
            THROW 53132, N'Der AST-Wurzelvertrag ist verletzt.',2;
        IF NOT EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptNodes(@Text,@Version,1,NULL,NULL) WHERE NodeType=@Type)
            THROW 53132, N'Der erwartete Statement-Knotentyp fehlt.',3;
        IF EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptNodeProperties(@Text,@Version,1,NULL,NULL) AS p
                   LEFT JOIN toolbelt_tsql.TVF_ParseScriptNodes(@Text,@Version,1,NULL,NULL) AS n ON n.NodeId=p.NodeId
                   WHERE n.NodeId IS NULL)
            THROW 53132, N'Die Property-Knotenordinale sind nicht konsistent.',4;
        SET @Roundtrip=NULL;
        SELECT @Roundtrip=STRING_AGG(CONVERT(nvarchar(max),TokenText),N'') WITHIN GROUP(ORDER BY TokenIndex)
        FROM toolbelt_tsql.TVF_TokenizeScript(@Text,@Version,1,NULL,NULL);
        IF @Roundtrip IS NULL OR CONVERT(varbinary(max),@Roundtrip)<>CONVERT(varbinary(max),@Text)
            THROW 53132, N'Der Syntaxkorpus-Tokenstrom ist nicht verlustfrei.',5;
        SET @CaseId+=1;
    END;
    SET @VersionId+=1;
END;

IF NOT EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptNodeProperties(N'SELECT N''Contoso'' AS x;',160,1,NULL,NULL)
               WHERE PropertyName=N'Value' AND PropertyValue=N'Contoso')
    THROW 53132,N'Der erwartete skalare Literalwert fehlt.',6;

-- Am gepinnten Binary empirisch qualifizierte Versionsgrenze: benanntes WINDOW.
DECLARE @NamedWindow nvarchar(max)=N'SELECT SUM(x) OVER w FROM (VALUES(1))v(x) WINDOW w AS(ORDER BY x);';
IF NOT EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptErrors(@NamedWindow,150,1,NULL,NULL))
 OR EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptNodes(@NamedWindow,150,1,NULL,NULL))
 OR EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptErrors(@NamedWindow,160,1,NULL,NULL))
 OR NOT EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptNodes(@NamedWindow,160,1,NULL,NULL))
    THROW 53132,N'Die qualifizierte WINDOW-Versionsgrenze ist verletzt.',7;

-- Ebenfalls am gepinnten Binary geprüft; ein Produktversionslabel allein reicht nicht.
DECLARE @JsonAggregate nvarchar(max)=N'SELECT JSON_ARRAYAGG(x ORDER BY x) FROM(VALUES(1))v(x);';
IF NOT EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptErrors(@JsonAggregate,160,1,NULL,NULL))
 OR EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptNodes(@JsonAggregate,160,1,NULL,NULL))
 OR EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptErrors(@JsonAggregate,170,1,NULL,NULL))
 OR NOT EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptNodes(@JsonAggregate,170,1,NULL,NULL))
    THROW 53132,N'Die qualifizierte JSON_ARRAYAGG-Versionsgrenze ist verletzt.',8;

PRINT N'ScriptParser-Syntaxkorpus erfolgreich; repräsentative Abdeckung, keine Vollständigkeitsgarantie.';
