-- Cross-database-Contract für zentrale Installation
-- SQLCMD-Variable: ToolbeltDatabase

SET NOCOUNT ON;

DECLARE @Alphabet varchar(93) = '0123456789ABCDEF';
DECLARE @Encoded varchar(65);
DECLARE @Decoded bigint;

SELECT @Encoded =
    [$(ToolbeltDatabase)].toolbelt_conversion.SVF_IntegerToBase(-255, @Alphabet);
SELECT @Decoded =
    [$(ToolbeltDatabase)].toolbelt_conversion.SVF_TryBaseToInteger(@Encoded, @Alphabet);

IF @Encoded <> '-FF' OR @Decoded <> -255
    THROW 52830, N'Der zentrale dreiteilige Integer-Base-Aufruf ist fehlgeschlagen.', 1;

PRINT N'Integer-Base Central-Contract-Prüfung: erfolgreich';
GO
