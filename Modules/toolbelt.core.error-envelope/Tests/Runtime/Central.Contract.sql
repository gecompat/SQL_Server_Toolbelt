DECLARE @Sql nvarchar(max) = N'EXEC ' + QUOTENAME(N'$(ToolbeltDatabase)') + N'.toolbelt_core.USP_CaptureErrorEnvelope @ErrorNumber=8134, @ErrorSeverity=16, @ErrorState=1, @ErrorMessage=N''Central'';';
EXEC sys.sp_executesql @Sql;
PRINT N'Error Envelope Central: erfolgreich';
