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
-- Fehlerverhalten: Lexikalische Fehler ergeben null Zeilen; keine AST-Prüfung; Limits werfen TBX_TSQLPARSE_*
-- Performance:     Begrenzte atomare Materialisierung im Speicher
-- Einschränkungen: CLR UNSAFE erforderlich; Windows-only; konservativer Rohtextwächter.
-- NULL/Defaults:   NULL-Text ergibt null Zeilen; Version NULL=160, Bytes NULL=2097152, Tiefe NULL=100.
-- Grenzen:         Versionen 80,90,100,110,120,130,140,150,160,170; Bytes 1..2097152; Tiefe 1..256; kein Versionsfallback.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE FUNCTION [toolbelt_tsql].[TVF_TokenizeScript]
(
      @SqlText            nvarchar(max)
    , @TSqlVersion        int = 160
    , @QuotedIdentifiers  bit = 1
    , @MaxInputBytes      int = 2097152
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
