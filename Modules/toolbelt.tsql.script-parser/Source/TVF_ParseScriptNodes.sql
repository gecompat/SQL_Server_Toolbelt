-- ============================================================================
-- Objekt:          toolbelt_tsql.TVF_ParseScriptNodes
-- Typ:             CLR Table-Valued Function
-- Zweck:           Zerlegt T-SQL-Code in einen hierarchischen Abstract Syntax Tree (AST).
-- Vertrag:         Gibt alle AST-Knoten in Pre-Order-Reihenfolge mit Parent-Bezug zurück.
-- Parameter:       @SqlText nvarchar(max), @TSqlVersion int, @QuotedIdentifiers bit,
--                  @MaxInputBytes int, @MaxNestingDepth int
-- Resultset:       NodeId, ParentNodeId, Depth, SiblingOrdinal, PropertyName, PropertyIndex,
--                  NodeType, StartOffset, StartLine, StartColumn, FragmentLength,
--                  FirstTokenIndex, LastTokenIndex
-- Dependencies:    Assembly Toolbelt_Tsql_ScriptParser
-- Rechte:          SELECT auf die Funktion
-- Versionen:       SQL Server 2019, 2022, 2025
-- Plattformen:     Windows
-- Fehlerverhalten: Syntaxfehler liefern keinen partiellen AST; Limits werfen TBX_TSQLPARSE_*
-- Performance:     Begrenzte atomare Materialisierung im Speicher ohne Zwischenpersistenz
-- Einschränkungen: CLR UNSAFE erforderlich; Windows-only; konservativer Rohtextwächter.
-- NULL/Defaults:   NULL-Text ergibt null Zeilen; Version NULL=160, Bytes NULL=2097152, Tiefe NULL=100.
-- Grenzen:         Versionen 80,90,100,110,120,130,140,150,160,170; Bytes 1..2097152; Tiefe 1..256; kein Versionsfallback.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE FUNCTION [toolbelt_tsql].[TVF_ParseScriptNodes]
(
      @SqlText            nvarchar(max)
    , @TSqlVersion        int = 160
    , @QuotedIdentifiers  bit = 1
    , @MaxInputBytes      int = 2097152
    , @MaxNestingDepth    int = 100
)
RETURNS TABLE
(
      NodeId              int            NULL
    , ParentNodeId        int            NULL
    , Depth               int            NULL
    , SiblingOrdinal      int            NULL
    , PropertyName        nvarchar(128)  NULL
    , PropertyIndex       int            NULL
    , NodeType            nvarchar(128)  NULL
    , StartOffset         int            NULL
    , StartLine           int            NULL
    , StartColumn         int            NULL
    , FragmentLength      int            NULL
    , FirstTokenIndex     int            NULL
    , LastTokenIndex      int            NULL
)
AS EXTERNAL NAME
    [Toolbelt_Tsql_ScriptParser]
    .[Toolbelt.Tsql.ScriptParser.ScriptParserProvider]
    .[ParseScriptNodes];
GO
