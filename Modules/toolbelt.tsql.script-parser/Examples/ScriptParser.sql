-- ============================================================================
-- Beispiel: T-SQL Script Parser und Token-Extraktion
-- ============================================================================

DECLARE @Sql nvarchar(max) = N'
SELECT ColA, ColB
FROM dbo.Table1 AS t
WHERE t.ColA > 100;
';

-- 1. Syntaxprüfung
SELECT *
FROM toolbelt_tsql.TVF_ParseScriptErrors(@Sql, 160, 1, 2097152, 256);

-- 2. Vollständiger AST-Knotenbaum
SELECT
      NodeId
    , ParentNodeId
    , Depth
    , SiblingOrdinal
    , PropertyName
    , NodeType
    , StartOffset
    , FragmentLength
    , SUBSTRING(@Sql, StartOffset + 1, FragmentLength) AS FragmentText
FROM toolbelt_tsql.TVF_ParseScriptNodes(@Sql, 160, 1, 2097152, 256)
ORDER BY NodeId;

-- 3. Skalare Knoteneigenschaften (z. B. Bezeichnernamen)
SELECT
      p.NodeId
    , n.NodeType
    , p.PropertyName
    , p.PropertyKind
    , p.PropertyValue
FROM toolbelt_tsql.TVF_ParseScriptNodes(@Sql, 160, 1, 2097152, 256) AS n
INNER JOIN toolbelt_tsql.TVF_ParseScriptNodeProperties(@Sql, 160, 1, 2097152, 256) AS p
    ON p.NodeId = n.NodeId
ORDER BY p.NodeId, p.PropertyName;

-- 4. Verlustfreier Tokenstrom (Grundlage für GUID-Rewriting)
SELECT
      TokenIndex
    , TokenType
    , TokenText
    , StartOffset
    , StartLine
    , StartColumn
FROM toolbelt_tsql.TVF_TokenizeScript(@Sql, 160, 1, 2097152, 256)
ORDER BY TokenIndex;
GO
