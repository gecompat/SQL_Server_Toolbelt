SET NOCOUNT ON;

EXEC toolbelt_core.USP_WriteConsoleMessage
      @Message = N'Gepufferte synthetische Ausgabe.'
    , @Immediate = 0;

EXEC toolbelt_core.USP_WriteConsoleMessage
      @Message = N'Unmittelbare synthetische Ausgabe: 100 %'
    , @Immediate = 1;

DECLARE @LongMessage nvarchar(max) =
    N'BEGIN|' + REPLICATE(N'α', 5000) + N'|END';

EXEC toolbelt_core.USP_WriteConsoleMessage
      @Message = @LongMessage
    , @Immediate = 0;

EXEC toolbelt_core.USP_WriteConsoleMessage @Hilfe = 1;
GO
