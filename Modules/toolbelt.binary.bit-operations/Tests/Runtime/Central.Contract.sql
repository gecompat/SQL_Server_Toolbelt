SET NOCOUNT ON;

IF
   (
       SELECT Value
       FROM [$(ToolbeltDatabase)].toolbelt_binary.TVF_RightShiftBigInt(-1, 1)
   ) <> CONVERT(bigint, 9223372036854775807)
    THROW 52882, N'Der zentrale Bit-Aufruf ist fehlgeschlagen.', 1;

PRINT N'Bigint Bit Operations Central-Contract-Prüfung: erfolgreich';
GO
