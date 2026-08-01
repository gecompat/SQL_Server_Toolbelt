CREATE OR ALTER PROCEDURE dbo.USP_DemoNoop
AS
BEGIN
    SET NOCOUNT ON;
END;
GO

EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = 'demo.noop'
    , @HandlerSchema = N'dbo'
    , @HandlerProcedure = N'USP_DemoNoop'
    , @Description = N'Synthetisches Beispiel';

EXEC toolbelt_core.USP_ResolveWorkType
      @WorkTypeName = 'demo.noop';

EXEC toolbelt_core.USP_DisableWorkType
      @WorkTypeName = 'demo.noop'
    , @DisabledReason = N'Beispiel beendet';
