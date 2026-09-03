SET NOCOUNT ON;

-- 1. NULL Input Contract
IF EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptNodes(NULL, 160, 1, 2097152, 256))
    THROW 53125, N'TVF_ParseScriptNodes lieferte Zeilen bei NULL-Eingabe.', 1;

IF EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptNodeProperties(NULL, 160, 1, 2097152, 256))
    THROW 53125, N'TVF_ParseScriptNodeProperties lieferte Zeilen bei NULL-Eingabe.', 1;

IF EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_TokenizeScript(NULL, 160, 1, 2097152, 256))
    THROW 53125, N'TVF_TokenizeScript lieferte Zeilen bei NULL-Eingabe.', 1;

IF EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptErrors(NULL, 160, 1, 2097152, 256))
    THROW 53125, N'TVF_ParseScriptErrors lieferte Zeilen bei NULL-Eingabe.', 1;

-- 2. Syntax Error Contract
DECLARE @BadSql nvarchar(max) = N'SELECT FROM WHERE;';
IF (SELECT COUNT(*) FROM toolbelt_tsql.TVF_ParseScriptErrors(@BadSql, 160, 1, 2097152, 256)) = 0
    THROW 53126, N'TVF_ParseScriptErrors erkannte fehlerhafte Syntax nicht.', 1;

-- 3. Clean SQL Tokenization & AST Parsing
DECLARE @GoodSql nvarchar(max) = N'SELECT ColA, ColB FROM dbo.Table1 AS t WHERE t.ColA > 100;';

IF (SELECT COUNT(*) FROM toolbelt_tsql.TVF_ParseScriptErrors(@GoodSql, 160, 1, 2097152, 256)) <> 0
    THROW 53127, N'TVF_ParseScriptErrors meldete Fehler bei gültigem SQL.', 1;

IF (SELECT COUNT(*) FROM toolbelt_tsql.TVF_ParseScriptNodes(@GoodSql, 160, 1, 2097152, 256)) < 5
    THROW 53128, N'TVF_ParseScriptNodes erzeugte zu wenige AST-Knoten.', 1;

IF NOT EXISTS (
    SELECT 1
    FROM toolbelt_tsql.TVF_TokenizeScript(@GoodSql, 160, 1, 2097152, 256)
    WHERE TokenType = N'Identifier' AND TokenText = N'Table1'
)
    THROW 53129, N'TVF_TokenizeScript extrahierte Tabellenbezeichner nicht korrekt.', 1;

PRINT N'ScriptParser-Feature-Contract erfolgreich.';
