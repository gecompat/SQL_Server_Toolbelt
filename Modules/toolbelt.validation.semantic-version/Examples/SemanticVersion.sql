SELECT *
FROM toolbelt_validation.TVF_ParseSemanticVersion
     ('1.2.3-alpha.1+build.7');
GO

SELECT toolbelt_validation.SVF_CompareSemanticVersion
       ('1.2.3-alpha', '1.2.3') AS Comparison;
GO

SELECT toolbelt_validation.SVF_SemanticVersionSortKey
       ('1.2.3-alpha') AS SortKey;
GO

SELECT
      source.VersionValue
    , compared.ComparisonResult
    , sort_key.SortKey
FROM
(
    VALUES ('1.0.0-alpha'), ('1.0.0-rc.1'), ('1.0.0')
) AS source(VersionValue)
OUTER APPLY
    toolbelt_validation.TVF_CompareSemanticVersion
    (
          source.VersionValue
        , '1.0.0'
    ) AS compared
OUTER APPLY
    toolbelt_validation.TVF_SemanticVersionSortKey
    (
        source.VersionValue
    ) AS sort_key;
GO
