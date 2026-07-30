SET NOCOUNT ON;

DECLARE @ReturnCode int;
EXEC @ReturnCode =
    [$(ToolbeltDatabase)].toolbelt_core.USP_WriteConsoleMessage
          @Message = N'TBX-CENTRAL-CONSOLE'
        , @Immediate = 1;

IF @ReturnCode <> 0
    THROW 52939, N'Der zentrale Console-Message-Aufruf ist fehlgeschlagen.', 1;

PRINT N'Console Message Central-Contract-Prüfung: erfolgreich';
GO
