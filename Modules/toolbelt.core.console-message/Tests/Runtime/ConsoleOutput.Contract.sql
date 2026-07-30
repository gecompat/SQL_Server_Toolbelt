SET NOCOUNT ON;

DECLARE @Buffered nvarchar(max) =
      N'TBX-BUFFERED-BEGIN|'
    + REPLICATE(N'A', 3980)
    + N'🐼'
    + N'|TBX-BUFFERED-MIDDLE|'
    + REPLICATE(N'B', 4010)
    + N'|TBX-BUFFERED-END';

EXEC toolbelt_core.USP_WriteConsoleMessage
      @Message = @Buffered
    , @Immediate = 0;

DECLARE @Immediate nvarchar(max) =
      N'TBX-IMMEDIATE-100%-BEGIN|'
    + REPLICATE(N'C', 1974)
    + N'🐼'
    + N'|TBX-IMMEDIATE-MIDDLE|'
    + REPLICATE(N'D', 2050)
    + N'|TBX-IMMEDIATE-END';

EXEC toolbelt_core.USP_WriteConsoleMessage
      @Message = @Immediate
    , @Immediate = 1;

EXEC toolbelt_core.USP_WriteConsoleMessage
      @Message = N'TBX-LINE-A' + NCHAR(13) + NCHAR(10) + N'TBX-LINE-B'
    , @Immediate = 1;
GO
