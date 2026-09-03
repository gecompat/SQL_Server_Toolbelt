-- ============================================================================
-- Objekt:          toolbelt_tsql.TVF_ExtractScriptColumnReferences
-- Typ:             Inline Table-Valued Function (iTVF)
-- Zweck:           Extrahiert alle Spaltenreferenzen samt Prefix/Qualifier,
--                  Spaltenname, QuoteType und Token-Indizes aus dem T-SQL-AST.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION [toolbelt_tsql].[TVF_ExtractScriptColumnReferences]
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
ColRefNodes AS (
    SELECT
          n.NodeId AS ColRefNodeId
        , n.StartOffset
        , n.FragmentLength
        , n.FirstTokenIndex
        , n.LastTokenIndex
    FROM Nodes AS n
    WHERE n.NodeType = N'ColumnReferenceExpression'
),
MultiPartNodes AS (
    SELECT
          n.ParentNodeId AS ColRefNodeId
        , n.NodeId AS MultiPartId
    FROM Nodes AS n
    WHERE n.NodeType = N'MultiPartIdentifier'
),
Identifiers AS (
    SELECT
          n.ParentNodeId AS MultiPartId
        , n.NodeId
        , p.PropertyValue AS IdentifierName
        , pQuote.PropertyValue AS QuoteType
        , n.FirstTokenIndex AS TokenIndex
        , n.StartOffset
        , n.FragmentLength
        , ROW_NUMBER() OVER (PARTITION BY n.ParentNodeId ORDER BY n.NodeId) AS PartIndex
    FROM Nodes AS n
    INNER JOIN Props AS p
        ON p.NodeId = n.NodeId AND p.PropertyName = N'Value'
    LEFT JOIN Props AS pQuote
        ON pQuote.NodeId = n.NodeId AND pQuote.PropertyName = N'QuoteType'
    WHERE n.NodeType = N'Identifier'
      AND n.PropertyName = N'Identifiers'
),
PartCounts AS (
    SELECT
          MultiPartId
        , COUNT(*) AS TotalParts
    FROM Identifiers
    GROUP BY MultiPartId
)
SELECT
      cr.ColRefNodeId
    , pc.TotalParts
    , CASE WHEN pc.TotalParts >= 2 THEN p1.IdentifierName ELSE NULL END AS TableOrAliasQualifier
    , pLast.IdentifierName AS ColumnName
    , pLast.QuoteType AS ColumnQuoteType
    , pLast.TokenIndex AS ColumnTokenIndex
    , p1.TokenIndex AS QualifierTokenIndex
    , cr.StartOffset
    , cr.FragmentLength
    , cr.FirstTokenIndex
    , cr.LastTokenIndex
FROM ColRefNodes AS cr
INNER JOIN MultiPartNodes AS mp
    ON mp.ColRefNodeId = cr.ColRefNodeId
INNER JOIN PartCounts AS pc
    ON pc.MultiPartId = mp.MultiPartId
INNER JOIN Identifiers AS pLast
    ON pLast.MultiPartId = mp.MultiPartId AND pLast.PartIndex = pc.TotalParts
LEFT JOIN Identifiers AS p1
    ON p1.MultiPartId = mp.MultiPartId AND p1.PartIndex = 1 AND pc.TotalParts >= 2;
GO
