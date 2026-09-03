-- ============================================================================
-- Objekt:          toolbelt_tsql.TVF_ParseScriptNodeProperties
-- Typ:             CLR Table-Valued Function
-- Zweck:           Liest skalare Eigenschaften (Identifier, Literale, Enums) der AST-Knoten.
-- Vertrag:         Gibt pro Knoten alle nicht-Fragment-Eigenschaften als Key-Value-Paare aus.
-- Parameter:       @SqlText nvarchar(max), @TSqlVersion int, @QuotedIdentifiers bit,
--                  @MaxInputBytes int, @MaxNestingDepth int
-- Resultset:       NodeId, PropertyName, PropertyKind, PropertyValue
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

CREATE FUNCTION [toolbelt_tsql].[TVF_ParseScriptNodeProperties]
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
    , PropertyName        nvarchar(128)  NULL
    , PropertyKind        nvarchar(32)   NULL
    , PropertyValue       nvarchar(max)  NULL
)
AS EXTERNAL NAME
    [Toolbelt_Tsql_ScriptParser]
    .[Toolbelt.Tsql.ScriptParser.ScriptParserProvider]
    .[ParseScriptNodeProperties];
GO
