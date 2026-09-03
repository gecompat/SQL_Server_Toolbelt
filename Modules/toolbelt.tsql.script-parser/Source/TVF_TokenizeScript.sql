-- ============================================================================
-- Objekt:          toolbelt_tsql.TVF_TokenizeScript
-- Typ:             CLR Table-Valued Function
-- Zweck:           Zerlegt T-SQL-Code in einen lückenlosen, verlustfreien Tokenstrom.
-- Vertrag:         Gibt alle Tokens (Identifier, Keywords, Literale, Kommentare, Whitespace) mit Offsets zurück.
-- Parameter:       @SqlText nvarchar(max), @TSqlVersion int, @QuotedIdentifiers bit,
--                  @MaxInputBytes int, @MaxNestingDepth int
-- Resultset:       TokenIndex, TokenType, TokenText, StartOffset, StartLine, StartColumn
-- Dependencies:    Assembly Toolbelt_Tsql_ScriptParser
-- Rechte:          SELECT auf die Funktion
-- Versionen:       SQL Server 2019, 2022, 2025
-- Plattformen:     Windows
-- Fehlerverhalten: Limits werfen TBX_TSQLPARSE_*
-- Performance:     In-Memory Streaming
-- Einschränkungen: CLR UNSAFE erforderlich; Windows-only.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE FUNCTION [toolbelt_tsql].[TVF_TokenizeScript]
(
      @SqlText            nvarchar(max)
    , @TSqlVersion        int = NULL
    , @QuotedIdentifiers  bit = 1
    , @MaxInputBytes      int = NULL
    , @MaxNestingDepth    int = 100
)
RETURNS TABLE
(
      TokenIndex          int            NULL
    , TokenType           nvarchar(64)   NULL
    , TokenText           nvarchar(max)  NULL
    , StartOffset         int            NULL
    , StartLine           int            NULL
    , StartColumn         int            NULL
)
AS EXTERNAL NAME
    [Toolbelt_Tsql_ScriptParser]
    .[Toolbelt.Tsql.ScriptParser.ScriptParserProvider]
    .[TokenizeScript];
GO
