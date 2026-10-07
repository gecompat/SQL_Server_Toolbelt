-- Zwei unterschiedliche Work-Type-Orakel: beabsichtigte Reaktivierung, danach exakter No-op.
SET NOCOUNT ON;
DECLARE @Phase int = (SELECT Phase FROM #tbx_EventRepeat_State);
IF @Phase NOT IN (1, 2)
 OR (SELECT COUNT(*) FROM #tbx_EventRepeat_Snapshot WHERE Phase = @Phase) <> 5
 OR (SELECT COUNT(*) FROM #tbx_EventRepeat_Snapshot WHERE Phase = 0) <> 5
    THROW 52753, N'Der Event-Repeat-Snapshot ist unvollständig.', 1;
IF EXISTS
   (SELECT Category, Payload FROM #tbx_EventRepeat_Snapshot WHERE Phase = 0 AND Category <> 'work-type-current'
    EXCEPT SELECT Category, Payload FROM #tbx_EventRepeat_Snapshot WHERE Phase = @Phase AND Category <> 'work-type-current')
 OR EXISTS
   (SELECT Category, Payload FROM #tbx_EventRepeat_Snapshot WHERE Phase = @Phase AND Category <> 'work-type-current'
    EXCEPT SELECT Category, Payload FROM #tbx_EventRepeat_Snapshot WHERE Phase = 0 AND Category <> 'work-type-current')
    THROW 52754, N'Der Event-Repeat änderte Events, Identity, Katalog oder übrige Work Types.', 1;

IF @Phase = 1
BEGIN
    IF NOT EXISTS (SELECT 1 FROM #tbx_EventRepeat_WorkType WHERE Phase = 0
                   AND IsEnabled = 0 AND DefaultTimeoutSeconds = 31 AND IsIdempotent = 1
                   AND DisabledAtUtc IS NOT NULL AND DisabledBy IS NOT NULL
                   AND CONVERT(varbinary(max), DisabledReason) = CONVERT(varbinary(max), N'Synthetic pre-repeat disable'))
        THROW 52755, N'Der synthetische deaktivierte Work-Type-Vorzustand fehlt.', 1;
    IF NOT EXISTS
       (SELECT 1 FROM #tbx_EventRepeat_WorkType AS current_row
        JOIN #tbx_EventRepeat_WorkType AS previous_row ON previous_row.Phase = 0
        CROSS JOIN #tbx_EventRepeat_State AS state_row
        WHERE current_row.Phase = 1
          AND CONVERT(varbinary(max), current_row.HandlerSchema) = CONVERT(varbinary(max), N'toolbelt_core')
          AND CONVERT(varbinary(max), current_row.HandlerProcedure) = CONVERT(varbinary(max), N'USP_WriteEventInternal')
          AND CONVERT(varbinary(max), current_row.ParameterMode) = CONVERT(varbinary(max), 'JSON_PAYLOAD')
          AND CONVERT(varbinary(max), current_row.PayloadContractJson) = CONVERT(varbinary(max), N'{"type":"object"}')
          AND current_row.DefaultTimeoutSeconds = 30 AND current_row.IsIdempotent = 0 AND current_row.IsEnabled = 1
          AND CONVERT(varbinary(max), current_row.Description) =
              CONVERT(varbinary(max), N'Interner Handler für rollback-unabhängige Toolbelt-Events.')
          AND current_row.DisabledAtUtc IS NULL AND current_row.DisabledBy IS NULL AND current_row.DisabledReason IS NULL
          AND current_row.RowVersion <> previous_row.RowVersion
          AND current_row.ModifiedAtUtc >= state_row.DeployStartedAtUtc
          AND current_row.ModifiedAtUtc <= SYSUTCDATETIME()
          AND CONVERT(varbinary(max), current_row.ModifiedBy) = CONVERT(varbinary(max), state_row.DeployPrincipal))
        THROW 52755, N'Der Event-Repeat reaktivierte den eigenen Work Type nicht kanonisch.', 2;
END;
IF @Phase = 2
BEGIN
    IF (SELECT COUNT(*) FROM #tbx_EventRepeat_Snapshot WHERE Phase = 1) <> 5
        THROW 52753, N'Der erste Event-Repeat-Snapshot fehlt.', 2;
    IF EXISTS
       (SELECT Category, Payload FROM #tbx_EventRepeat_Snapshot WHERE Phase = 1
        EXCEPT SELECT Category, Payload FROM #tbx_EventRepeat_Snapshot WHERE Phase = 2)
     OR EXISTS
       (SELECT Category, Payload FROM #tbx_EventRepeat_Snapshot WHERE Phase = 2
        EXCEPT SELECT Category, Payload FROM #tbx_EventRepeat_Snapshot WHERE Phase = 1)
        THROW 52756, N'Der kanonische zweite Event-Repeat änderte Daten oder Work-Type-Rowversion.', 1;
END;
IF (SELECT COUNT(*) FROM toolbelt_core.EventLog AS e JOIN #tbx_EventRepeat_OwnEvents AS owned ON owned.EventId = e.EventId
    WHERE owned.Role = 'seed') <> 4
    THROW 52754, N'Die vier eigenen Repeat-Events fehlen.', 2;
IF NOT EXISTS (SELECT 1 FROM toolbelt_core.WorkType
               WHERE WorkTypeId = (SELECT SentinelId FROM #tbx_EventRepeat_State)
                 AND WorkTypeName = 'test.event-repeat.sentinel' AND IsEnabled = 0)
    THROW 52754, N'Der fremde eigene Work-Type-Sentinel wurde verändert.', 3;
IF @@TRANCOUNT <> 0 THROW 52759, N'Der Event-Repeat hinterließ eine Transaktion.', 1;
IF XACT_STATE() <> 0 THROW 52759, N'Der Event-Repeat hinterließ einen Transaktionszustand.', 2;
GO
