-- ============================================================================
-- Objekt:          toolbelt_tsql.TVF_ApplyTokenReplacements
-- Typ:             Inline Table-Valued Function (iTVF)
-- Zweck:           Baut aus einem Tokenstrom und einer Liste von Ersetzungen
--                  (TokenIndex -> ReplacementText) das finale SQL-Statement
--                  vollständig und verlustfrei wieder zusammen.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- Typdeklaration für Tabellenparameter der Ersetzungen
IF TYPE_ID(N'toolbelt_tsql.TT_TokenReplacement') IS NULL
    CREATE TYPE [toolbelt_tsql].[TT_TokenReplacement] AS TABLE
    (
          TokenIndex          int            NOT NULL PRIMARY KEY
        , ReplacementText     nvarchar(max)  NOT NULL
    );
GO
