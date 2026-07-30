-- ============================================================================
-- Cross-database-Contract für zentrale Installation
-- SQLCMD-Variable: ToolbeltDatabase
-- ============================================================================

SET NOCOUNT ON;

DECLARE @Encoded nvarchar(max);
DECLARE @Decoded nvarchar(max);

SELECT @Encoded =
    [$(ToolbeltDatabase)].toolbelt_conversion.SVF_UriComponentEncode
    (
        N'Kaffee & Tee'
    );

SELECT @Decoded =
    [$(ToolbeltDatabase)].toolbelt_conversion.SVF_UriComponentDecode
    (
        @Encoded
    );

IF @Encoded <> N'Kaffee%20%26%20Tee'
   OR @Decoded <> N'Kaffee & Tee'
BEGIN
    THROW 52738, N'Der zentrale URI-Component-Aufruf ist fehlgeschlagen.', 1;
END;

PRINT N'URI Component Central-Contract-Prüfung: erfolgreich';
GO
