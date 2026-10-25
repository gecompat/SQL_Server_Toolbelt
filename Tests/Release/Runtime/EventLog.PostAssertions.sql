-- Nach dem gemeinsamen REVERT und Principal-Cleanup exakt den Ursprungszustand prüfen.
-- Transaktionszustand vor Metadatenfunktionen in einem eigenen Statement lesen.
-- Die gebündelte Prüfung wurde im nativen Statementkontext falschpositiv.
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0
 THROW 52097,N'EventLog transaction postcondition.',15;
IF USER_ID()<>@EventLogRootUserId OR USER_ID(N'ContosoFunctionCaller') IS NOT NULL
 THROW 52097,N'EventLog root context postcondition.',15;
DECLARE @EventLogAfter nvarchar(max)=CONVERT(nvarchar(max),
 (SELECT * FROM toolbelt_core.EventLog ORDER BY EventId FOR XML PATH('event'),ROOT('events'),TYPE));
IF DATALENGTH(@EventLogAfter)<>DATALENGTH(@EventLogRootSnapshot)
 OR @EventLogAfter COLLATE Latin1_General_100_BIN2<>@EventLogRootSnapshot COLLATE Latin1_General_100_BIN2
 OR (SELECT COUNT(*) FROM toolbelt_core.EventLog)<>4
 THROW 52097,N'EventLog exact rollback rowset postcondition.',15;
