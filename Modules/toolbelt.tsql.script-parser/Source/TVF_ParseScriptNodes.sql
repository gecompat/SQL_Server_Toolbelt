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
-- Fehlerverhalten: Syntaxfehler unterdrücken den Baum nicht zwingend; Limits werfen TBX_TSQLPARSE_*
-- Performance:     In-Memory Streaming ohne Zwischenpersistenz
-- Einschränkungen: CLR UNSAFE erforderlich; Windows-only.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE FUNCTION [toolbelt_tsql].[TVF_ParseScriptNodes]
(
      @SqlText            nvarchar(max)
    , @TSqlVersion        int = NULL
    , @QuotedIdentifiers  bit = 1
    , @MaxInputBytes      int = NULL
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
