-- ============================================================================
-- Objekt:          toolbelt_tsql.TVF_ResolveSynonyms
-- Typ:             CLR Table-Valued Function
-- Zweck:           Löst ein Synonym dynamisch in einer angegebenen Datenbank
--                  (oder der aktuellen Datenbank) gegen sys.synonyms auf.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION [toolbelt_tsql].[TVF_ResolveSynonyms]
(
      @DatabaseName       sysname = NULL
    , @SchemaName         sysname = NULL
    , @ObjectName         sysname
    , @Recursive          bit     = 1
)
RETURNS TABLE
(
      SourceDatabaseName   sysname        NULL
    , SynonymSchemaName    sysname        NULL
    , SynonymName          sysname        NULL
    , IsSynonym            bit            NULL
    , BaseServerName       sysname        NULL
    , BaseDatabaseName     sysname        NULL
    , BaseSchemaName       sysname        NULL
    , BaseObjectNameOnly   sysname        NULL
    , BaseObjectNameQuoted nvarchar(512)  NULL
    , BaseObjectNameUnquoted nvarchar(512) NULL
    , HopsCount            int            NULL
)
AS EXTERNAL NAME
    [Toolbelt_Tsql_ScriptParser]
    .[Toolbelt.Tsql.ScriptParser.ScriptParserProvider]
    .[ResolveSynonyms];
GO
GO
