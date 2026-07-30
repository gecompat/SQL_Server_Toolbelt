SET NOCOUNT ON;
DECLARE @Expected TABLE (ObjectName sysname NOT NULL, ObjectType char(2) NOT NULL);
INSERT INTO @Expected VALUES
 ('TVF_ParseSemanticVersion', 'TF'),
 ('TVF_CompareSemanticVersion', 'IF'),
 ('TVF_SemanticVersionSortKey', 'IF'),
 ('SVF_CompareSemanticVersion', 'FN'),
 ('SVF_SemanticVersionSortKey', 'FN');

IF EXISTS
(
    SELECT 1 FROM @Expected AS expected
    WHERE OBJECT_ID
      (N'toolbelt_validation.' + expected.ObjectName, expected.ObjectType) IS NULL
)
    THROW 52720, N'Ein SemVer-Release-Objekt fehlt.', 1;

IF NOT EXISTS
(
    SELECT 1 FROM sys.extended_properties
    WHERE class = 0
      AND name = N'Toolbelt.Module.toolbelt.validation.semantic-version.Version'
      AND TRY_CONVERT(nvarchar(64), value) = N'1.1.0'
)
    THROW 52721, N'Der SemVer-Modulmarker fehlt.', 1;

IF EXISTS
(
    SELECT 1
    FROM @Expected AS expected
    CROSS APPLY
    (
        SELECT OBJECT_ID(N'toolbelt_validation.' + expected.ObjectName) AS ObjectId
    ) AS resolved
    WHERE NOT EXISTS
    (
        SELECT 1 FROM sys.extended_properties AS properties
        WHERE properties.class = 1 AND properties.major_id = resolved.ObjectId
          AND properties.name = N'Toolbelt.ModuleId'
          AND TRY_CONVERT(nvarchar(256), properties.value)
                = N'toolbelt.validation.semantic-version'
    )
)
    THROW 52722, N'Ein SemVer-Objektmarker fehlt.', 1;

IF NOT EXISTS
(
    SELECT 1 FROM sys.sql_expression_dependencies
    WHERE referencing_id =
          OBJECT_ID(N'toolbelt_validation.SVF_CompareSemanticVersion')
      AND referenced_id =
          OBJECT_ID(N'toolbelt_validation.TVF_CompareSemanticVersion')
)
 OR NOT EXISTS
(
    SELECT 1 FROM sys.sql_expression_dependencies
    WHERE referencing_id =
          OBJECT_ID(N'toolbelt_validation.SVF_SemanticVersionSortKey')
      AND referenced_id =
          OBJECT_ID(N'toolbelt_validation.TVF_SemanticVersionSortKey')
)
    THROW 52723, N'Die interne SVF-zu-TVF-Dependency fehlt.', 1;

IF NOT EXISTS
(
    SELECT 1 FROM sys.sql_expression_dependencies
    WHERE referencing_id =
          OBJECT_ID(N'toolbelt_validation.TVF_CompareSemanticVersion')
      AND referenced_id =
          OBJECT_ID(N'toolbelt_validation.TVF_ParseSemanticVersion')
)
 OR NOT EXISTS
(
    SELECT 1 FROM sys.sql_expression_dependencies
    WHERE referencing_id =
          OBJECT_ID(N'toolbelt_validation.TVF_SemanticVersionSortKey')
      AND referenced_id =
          OBJECT_ID(N'toolbelt_validation.TVF_ParseSemanticVersion')
)
    THROW 52724, N'Die interne Parser-Dependency der inline TVFs fehlt.', 1;

PRINT N'Semantic-Version Lifecycle-Contract-Prüfung: erfolgreich';
GO
