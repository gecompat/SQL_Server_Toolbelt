-- Reguläre DML erst nach beiden vollständig verglichenen Snapshotfenstern.
SET NOCOUNT ON;
DECLARE @FileLast decimal(38,0)=IDENT_CURRENT(N'toolbelt_file.FileContentRootAllowlist'),
 @EventLast decimal(38,0)=IDENT_CURRENT(N'toolbelt_core.EventLog');
IF @FileLast<=(SELECT MAX(RootPathId) FROM toolbelt_file.FileContentRootAllowlist)
 OR @EventLast<=(SELECT MAX(EventId) FROM toolbelt_core.EventLog)
 THROW 54983,N'Verbrauchte synthetische Identityzeugen fehlen.',1;
INSERT toolbelt_file.FileContentRootAllowlist(RootPath) VALUES(N'/synthetic/export/next');
IF CONVERT(decimal(38,0),SCOPE_IDENTITY())<>@FileLast+1 THROW 54983,N'File-Identity wurde verändert.',2;
INSERT toolbelt_core.EventLog(OccurredAtUtc,EventName,EventLevel,ExecutionId,CorrelationId,SourceDatabaseName,CallerSessionId,CallerXactState,CallerTransactionCount,RemoteSessionId)
 VALUES('2026-06-07T08:09:10.0000001','test.export.next','INFO','00000000-0000-0000-0000-000000008205','00000000-0000-0000-0000-000000008215',N'Contoso',9,0,0,10);
IF CONVERT(decimal(38,0),SCOPE_IDENTITY())<>@EventLast+1 THROW 54983,N'Event-Identity wurde verändert.',3;
IF @@TRANCOUNT<>0 THROW 54983,N'Identityzeuge hinterließ eine Transaktion.',4;
IF XACT_STATE()<>0 THROW 54983,N'Identityzeuge hinterließ eine Transaktion.',4;
-- Ganze DB gehört ausschließlich diesem Adapter. Die frische Cleanupverbindung
-- prüft ihre Identität und fremde Sessions, bevor sie diese eigenen Zeugen entfernt.
