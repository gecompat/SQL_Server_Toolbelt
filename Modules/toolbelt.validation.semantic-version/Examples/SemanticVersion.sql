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
