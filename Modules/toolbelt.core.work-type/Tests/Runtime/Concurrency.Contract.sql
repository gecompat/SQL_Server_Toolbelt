SET NOCOUNT ON;

DECLARE @Name varchar(128) = 'test.concurrent';
EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = @Name
    , @HandlerSchema = N'toolbelt_core'
    , @HandlerProcedure = N'USP_TestWorkTypeConcurrent'
    , @Description = N'synthetic concurrent';
WAITFOR DELAY '00:00:01';
