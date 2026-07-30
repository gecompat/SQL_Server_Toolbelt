-- SQLCMD-Variable: ToolbeltDatabase
SET NOCOUNT ON;

DECLARE @QuotedName nvarchar(1035);

SELECT @QuotedName =
    [$(ToolbeltDatabase)].toolbelt_metadata.SVF_QuoteMultipartName
    (
        N'[Archive.Db].dbo.[Order.Detail]'
    );

IF @QuotedName <> N'[Archive.Db].[dbo].[Order.Detail]'
BEGIN
    THROW 52530, N'Der zentrale dreiteilige Quote-Aufruf ist fehlgeschlagen.', 1;
END;

IF NOT EXISTS
   (
       SELECT 1
       FROM [$(ToolbeltDatabase)].toolbelt_metadata.TVF_ParseMultipartName
            (
                N'Server...Object'
            )
       WHERE IsValid = 1
         AND QuotedName = N'[Server]...[Object]'
   )
BEGIN
    THROW 52531, N'Der zentrale dreiteilige Parser-Aufruf ist fehlgeschlagen.', 1;
END;
