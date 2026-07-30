-- ============================================================================
-- Cross-database-Contract für zentrale Installation
-- SQLCMD-Variable: ToolbeltDatabase
-- ============================================================================

SET NOCOUNT ON;

IF NOT EXISTS
   (
       SELECT 1
       FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_TrimDirectionalNvarchar
            (
                  N'..A..'
                , N'.'
                , 'BOTH'
            )
       WHERE Value = N'A'
   )
   OR NOT EXISTS
      (
          SELECT 1
          FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_TrimDirectionalVarchar
               (
                     '..A..'
                   , '.'
                   , 'TRAILING'
               )
          WHERE Value = '..A'
      )
BEGIN
    THROW 52735, N'Der zentrale Directional-TRIM-Aufruf ist fehlgeschlagen.', 1;
END;

PRINT N'Directional TRIM Central-Contract-Prüfung: erfolgreich';
GO
