-- Fixed EXECUTE caller profile; message rendering is a separate client contract.
DECLARE @ExpectedApiCount int=1;
INSERT @Apis VALUES
(1,N'toolbelt_core',N'USP_WriteConsoleMessage','EXECUTE',N'EXEC toolbelt_core.USP_WriteConsoleMessage @Message=NULL;',N'DECLARE @Rc int,@Before int=@@TRANCOUNT;
EXEC @Rc=toolbelt_core.USP_WriteConsoleMessage @Message=NULL,@Immediate=NULL,@Debug=NULL,@Hilfe=NULL;
IF @Rc<>0 THROW 52097,N''Console return oracle NULL.'',12;
EXEC @Rc=toolbelt_core.USP_WriteConsoleMessage @Message=N'''',@Immediate=1;
IF @Rc<>0 THROW 52097,N''Console return oracle empty.'',12;
EXEC @Rc=toolbelt_core.USP_WriteConsoleMessage @Message=N''Contoso buffered 100 % alpha'',@Immediate=0;
IF @Rc<>0 THROW 52097,N''Console return oracle PRINT.'',12;
BEGIN TRANSACTION;
BEGIN TRY
 EXEC @Rc=toolbelt_core.USP_WriteConsoleMessage @Message=N''Contoso immediate 100 % beta'',@Immediate=1;
 IF @Rc<>0 OR @@TRANCOUNT<>@Before+1 THROW 52097,N''Console transaction oracle.'',12;
 ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>@Before ROLLBACK TRANSACTION;
 THROW;
END CATCH;
IF @@TRANCOUNT<>@Before THROW 52097,N''Console transaction cleanup oracle.'',12;
DECLARE @TooLong nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N''X''),524289),@Caught bit=0;
BEGIN TRY
 EXEC toolbelt_core.USP_WriteConsoleMessage @Message=@TooLong,@Immediate=1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>52801 THROW;
 SET @Caught=1;
END CATCH;
IF @Caught=0 THROW 52097,N''Console size rejection oracle.'',12;
');
INSERT @Denied VALUES
(1,N'toolbelt_core',N'USP_PrepareResultTable','EXECUTE',N'EXEC toolbelt_core.USP_PrepareResultTable @Hilfe=1;');
