BEGIN TRY
    SELECT 1 / 0;
END TRY
BEGIN CATCH
    EXEC toolbelt_core.USP_CaptureErrorEnvelope
          @ErrorNumber = ERROR_NUMBER()
        , @ErrorSeverity = ERROR_SEVERITY()
        , @ErrorState = ERROR_STATE()
        , @ErrorProcedure = ERROR_PROCEDURE()
        , @ErrorLine = ERROR_LINE()
        , @ErrorMessage = ERROR_MESSAGE();
    THROW;
END CATCH;
