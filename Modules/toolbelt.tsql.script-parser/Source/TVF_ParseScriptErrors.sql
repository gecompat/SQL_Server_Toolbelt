-- ============================================================================
-- Objekt:          toolbelt_tsql.TVF_ParseScriptErrors
-- Typ:             CLR Table-Valued Function
-- Zweck:           Liefert die vom ScriptDom-Parser erkannten Syntaxfehler als strukturierte Zeilen.
-- Vertrag:         Gibt 0 Zeilen bei syntaktisch korrektem SQL, sonst jede Fehlermeldung mit Position zurück.
-- Parameter:       @SqlText nvarchar(max), @TSqlVersion int, @QuotedIdentifiers bit,
--                  @MaxInputBytes int, @MaxNestingDepth int
-- Resultset:       ErrorOrdinal, Number, Message, StartOffset, StartLine, StartColumn
-- Dependencies:    Assembly Toolbelt_Tsql_ScriptParser
-- Rechte:          SELECT auf die Funktion
-- Versionen:       SQL Server 2019, 2022, 2025
-- Plattformen:     Windows
-- Fehlerverhalten: Syntaxfehler werden als Zeilen geliefert (kein THROW); Limits werfen TBX_TSQLPARSE_*
-- Performance:     In-Memory Streaming
-- Einschränkungen: CLR UNSAFE erforderlich; Windows-only.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE FUNCTION [toolbelt_tsql].[TVF_ParseScriptErrors]
(
      @SqlText            nvarchar(max)
    , @TSqlVersion        int = NULL
    , @QuotedIdentifiers  bit = 1
    , @MaxInputBytes      int = NULL
    , @MaxNestingDepth    int = 100
)
RETURNS TABLE
(
      ErrorOrdinal        int            NULL
    , Number              int            NULL
    , Message             nvarchar(4000) NULL
    , StartOffset         int            NULL
    , StartLine           int            NULL
    , StartColumn         int            NULL
)
AS EXTERNAL NAME
    [Toolbelt_Tsql_ScriptParser]
    .[Toolbelt.Tsql.ScriptParser.ScriptParserProvider]
    .[ParseScriptErrors];
GO
