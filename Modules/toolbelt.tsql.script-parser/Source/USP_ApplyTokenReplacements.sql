-- ============================================================================
-- Objekt:          toolbelt_tsql.USP_ApplyTokenReplacements
-- Typ:             Stored Procedure
-- Zweck:           Baut aus @SqlText und einer Tabelle von Ersetzungen
--                  (TokenIndex -> ReplacementText) das finale SQL-Statement
--                  vollständig und verlustfrei wieder zusammen.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_tsql].[USP_ApplyTokenReplacements]
(
      @SqlText            nvarchar(max)
    , @Replacements       [toolbelt_tsql].[TT_TokenReplacement] READONLY
    , @TSqlVersion        int = NULL
    , @QuotedIdentifiers  bit = 1
    , @MaxInputBytes      int = NULL
    , @MaxNestingDepth    int = 100
    , @RewrittenSql       nvarchar(max) = NULL OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @RewrittenSql = STRING_AGG(
        CONVERT(nvarchar(max), COALESCE(r.ReplacementText, t.TokenText)), N''
    ) WITHIN GROUP (ORDER BY t.TokenIndex)
    FROM toolbelt_tsql.TVF_TokenizeScript(@SqlText, @TSqlVersion, @QuotedIdentifiers, @MaxInputBytes, @MaxNestingDepth) AS t
    LEFT JOIN @Replacements AS r
        ON r.TokenIndex = t.TokenIndex;

    RETURN 0;
END;
GO
