SET NOCOUNT ON;
DECLARE @Message nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),524288);
EXEC toolbelt_core.USP_WriteConsoleMessage @Message=@Message,@Hilfe=1;
EXEC toolbelt_core.USP_WriteConsoleMessage @Message=NULL;
EXEC toolbelt_core.USP_WriteConsoleMessage @Message=N'';
EXEC toolbelt_core.USP_WriteConsoleMessage @Message=@Message,@Immediate=0;
SET @Message+=N'a';
BEGIN TRY EXEC toolbelt_core.USP_WriteConsoleMessage @Message=@Message,@Immediate=1; THROW 52990,N'Console byte limit bypass.',1; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>52801 THROW; END CATCH;
GO
