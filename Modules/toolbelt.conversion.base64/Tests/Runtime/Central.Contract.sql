-- ============================================================================
-- Cross-database-Contract für zentrale Installation
-- SQLCMD-Variable: ToolbeltDatabase
-- ============================================================================

SET NOCOUNT ON;

DECLARE @Source varbinary(max) = 0xCAFECAFE;
DECLARE @Encoded varchar(max);
DECLARE @Decoded varbinary(max);

SELECT @Encoded =
    [$(ToolbeltDatabase)].toolbelt_conversion.SVF_Base64Encode(@Source, 1);

SELECT @Decoded =
    [$(ToolbeltDatabase)].toolbelt_conversion.SVF_Base64Decode(@Encoded);

IF @Encoded <> 'yv7K_g' OR @Decoded <> @Source
BEGIN
    THROW 52330, N'Der zentrale dreiteilige Base64-Aufruf ist fehlgeschlagen.', 1;
END;

IF NOT EXISTS
   (
       SELECT 1
       FROM [$(ToolbeltDatabase)].toolbelt_conversion.TVF_Base64Encode
            (
                  @Source
                , 1
            ) AS encoded
       CROSS APPLY
            [$(ToolbeltDatabase)].toolbelt_conversion.TVF_Base64Decode
            (
                encoded.EncodedValue
            ) AS decoded
       WHERE encoded.EncodedValue = 'yv7K_g'
         AND decoded.DecodedValue = @Source
   )
BEGIN
    THROW 52331, N'Der zentrale relationale Base64-Aufruf ist fehlgeschlagen.', 1;
END;

PRINT N'Base64 Central-Contract-Prüfung: erfolgreich';
GO
