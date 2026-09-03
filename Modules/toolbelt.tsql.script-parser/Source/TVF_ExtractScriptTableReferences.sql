-- ============================================================================
-- Objekt:          toolbelt_tsql.TVF_ExtractScriptTableReferences
-- Typ:             Inline Table-Valued Function (iTVF)
-- Zweck:           Extrahiert alle Tabellen-, View- und Synonymreferenzen samt Alias
--                  und Token-Indizes aus dem T-SQL-AST.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION [toolbelt_tsql].[TVF_ExtractScriptTableReferences]
(
      @SqlText            nvarchar(max)
    , @TSqlVersion        int = NULL
    , @QuotedIdentifiers  bit = 1
    , @MaxInputBytes      int = NULL
    , @MaxNestingDepth    int = 100
)
RETURNS TABLE
AS
RETURN
WITH Nodes AS (
    SELECT
          NodeId
        , ParentNodeId
        , Depth
        , SiblingOrdinal
        , PropertyName
        , PropertyIndex
        , NodeType
        , StartOffset
        , StartLine
        , StartColumn
        , FragmentLength
        , FirstTokenIndex
        , LastTokenIndex
    FROM toolbelt_tsql.TVF_ParseScriptNodes(@SqlText, @TSqlVersion, @QuotedIdentifiers, @MaxInputBytes, @MaxNestingDepth)
),
Props AS (
    SELECT
          NodeId
        , PropertyName
        , PropertyKind
        , PropertyValue
    FROM toolbelt_tsql.TVF_ParseScriptNodeProperties(@SqlText, @TSqlVersion, @QuotedIdentifiers, @MaxInputBytes, @MaxNestingDepth)
),
TableNodes AS (
    SELECT
          n.NodeId AS TableNodeId
        , n.StartOffset
        , n.FragmentLength
        , n.FirstTokenIndex
        , n.LastTokenIndex
    FROM Nodes AS n
    WHERE n.NodeType = N'NamedTableReference'
),
AliasNodes AS (
    SELECT
          n.ParentNodeId AS TableNodeId
        , p.PropertyValue AS AliasName
        , pQuote.PropertyValue AS AliasQuoteType
        , n.FirstTokenIndex AS AliasTokenIndex
    FROM Nodes AS n
    INNER JOIN Props AS p
        ON p.NodeId = n.NodeId AND p.PropertyName = N'Value'
    LEFT JOIN Props AS pQuote
        ON pQuote.NodeId = n.NodeId AND pQuote.PropertyName = N'QuoteType'
    WHERE n.NodeType = N'Identifier'
      AND n.PropertyName = N'Alias'
),
SchemaObjectNodes AS (
    SELECT
          n.ParentNodeId AS TableNodeId
        , n.NodeId AS SchemaObjectId
        , n.FirstTokenIndex AS SchemaObjectFirstTokenIndex
        , n.LastTokenIndex AS SchemaObjectLastTokenIndex
    FROM Nodes AS n
    WHERE n.NodeType = N'SchemaObjectName'
),
Identifiers AS (
    SELECT
          n.ParentNodeId AS SchemaObjectId
        , n.PropertyName AS IdentifierRole
        , p.PropertyValue AS IdentifierName
        , pQuote.PropertyValue AS QuoteType
        , n.FirstTokenIndex AS TokenIndex
        , n.StartOffset
        , n.FragmentLength
    FROM Nodes AS n
    INNER JOIN Props AS p
        ON p.NodeId = n.NodeId AND p.PropertyName = N'Value'
    LEFT JOIN Props AS pQuote
        ON pQuote.NodeId = n.NodeId AND pQuote.PropertyName = N'QuoteType'
    WHERE n.NodeType = N'Identifier'
      AND n.PropertyName IN (N'ServerIdentifier', N'DatabaseIdentifier', N'SchemaIdentifier', N'BaseIdentifier')
)
SELECT
      tn.TableNodeId
    , srv.IdentifierName AS ServerName
    , db.IdentifierName AS DatabaseName
    , sch.IdentifierName AS SchemaName
    , base.IdentifierName AS ObjectName
    , COALESCE(
          CONCAT(
                CASE WHEN srv.IdentifierName IS NOT NULL THEN CONCAT(N'[', srv.IdentifierName, N'].') ELSE N'' END
              , CASE WHEN db.IdentifierName IS NOT NULL OR srv.IdentifierName IS NOT NULL THEN CONCAT(N'[', ISNULL(db.IdentifierName, N''), N'].') ELSE N'' END
              , CASE WHEN sch.IdentifierName IS NOT NULL THEN CONCAT(N'[', sch.IdentifierName, N'].') ELSE N'' END
              , N'[', base.IdentifierName, N']'
          ),
          base.IdentifierName
      ) AS FormattedObjectNameQuoted
    , COALESCE(
          CONCAT(
                CASE WHEN srv.IdentifierName IS NOT NULL THEN CONCAT(srv.IdentifierName, N'.') ELSE N'' END
              , CASE WHEN db.IdentifierName IS NOT NULL OR srv.IdentifierName IS NOT NULL THEN CONCAT(ISNULL(db.IdentifierName, N''), N'.') ELSE N'' END
              , CASE WHEN sch.IdentifierName IS NOT NULL THEN CONCAT(sch.IdentifierName, N'.') ELSE N'' END
              , base.IdentifierName
          ),
          base.IdentifierName
      ) AS FormattedObjectNameUnquoted
    , al.AliasName
    , al.AliasQuoteType
    , al.AliasTokenIndex
    , son.SchemaObjectFirstTokenIndex
    , son.SchemaObjectLastTokenIndex
    , db.TokenIndex AS DatabaseTokenIndex
    , sch.TokenIndex AS SchemaTokenIndex
    , base.TokenIndex AS ObjectTokenIndex
FROM TableNodes AS tn
INNER JOIN SchemaObjectNodes AS son
    ON son.TableNodeId = tn.TableNodeId
LEFT JOIN Identifiers AS srv
    ON srv.SchemaObjectId = son.SchemaObjectId AND srv.IdentifierRole = N'ServerIdentifier'
LEFT JOIN Identifiers AS db
    ON db.SchemaObjectId = son.SchemaObjectId AND db.IdentifierRole = N'DatabaseIdentifier'
LEFT JOIN Identifiers AS sch
    ON sch.SchemaObjectId = son.SchemaObjectId AND sch.IdentifierRole = N'SchemaIdentifier'
LEFT JOIN Identifiers AS base
    ON base.SchemaObjectId = son.SchemaObjectId AND base.IdentifierRole = N'BaseIdentifier'
LEFT JOIN AliasNodes AS al
    ON al.TableNodeId = tn.TableNodeId;
GO
