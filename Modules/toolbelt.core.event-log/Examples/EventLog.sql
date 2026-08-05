EXEC toolbelt_core.USP_WriteEvent
      @EventName = 'demo.completed'
    , @EventLevel = 'INFO'
    , @Category = 'example'
    , @Message = N'Synthetic example completed.'
    , @DataJson = N'{"rows":42}';

SELECT TOP (20) *
FROM toolbelt_core.VW_Events
ORDER BY EventId DESC;
