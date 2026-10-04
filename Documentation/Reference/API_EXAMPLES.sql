-- Generiert aus Repositoryquellen; Beispiele einzeln auswählen, nicht gesammelt ausführen.
-- Kein Installationsziel wird fest vorgegeben. In der gewünschten Toolbelt-Datenbank verwenden.

-- toolbelt_archive.USP_CreateZipFileFromEntries
-- Bereitet vollständiges ZIP/Entry-Binary vor und veröffentlicht über WriteBinaryFile. Datei und SQL-Ausgabe sind nicht gemeinsam atomar.
-- Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.
/* Separat auswählen und ausführen:
CREATE TABLE #Entries(Ordinal int,EntryName nvarchar(max),Payload varbinary(max)); INSERT #Entries VALUES(1,N'hello.txt',0x4869); EXEC toolbelt_archive.USP_CreateZipFileFromEntries @EntryTable=N'#Entries',@RootAlias=N'ContosoOutput',@RelativePath=N'hello.zip';
*/

-- toolbelt_archive.USP_ExtractZipEntryToFile
-- Bereitet vollständiges ZIP/Entry-Binary vor und veröffentlicht über WriteBinaryFile. Datei und SQL-Ausgabe sind nicht gemeinsam atomar.
-- Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.
/* Separat auswählen und ausführen:
EXEC toolbelt_archive.USP_ExtractZipEntryToFile @ZipArchive=0x504B03041400000000000000210000000000000000000000000009000000656D7074792E747874504B0102140014000000000000002100000000000000000000000000090000000000000000000000000000000000656D7074792E747874504B0506000000000100010037000000270000000000,@EntryName=N'empty.txt',@RootAlias=N'ContosoOutput',@RelativePath=N'empty.txt';
*/

-- toolbelt_archive.USP_CreateZipFromEntries
-- Erzeugt ein begrenztes ZIP aus Ordinal int, EntryName nvarchar(max), Payload varbinary(max) einer vorhandenen caller-lokalen Temp-Tabelle.
/* Separat auswählen und ausführen:
CREATE TABLE #ZipInput(Ordinal int, EntryName nvarchar(max), Payload varbinary(max)); INSERT #ZipInput VALUES(1,N'hello.txt',0x4869); EXEC toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipInput';
*/

-- toolbelt_archive.USP_ExtractZipEntryFromBinary
-- Extrahiert einen einzelnen benannten ZIP-Entry aus einem varbinary(max)-Archiv im Speicher. Der interne SAFE-CLR-Provider unterstützt ZIP Methods 0 und 8 und prüft die CRC32 des tatsächlichen Payloads.
/* Separat auswählen und ausführen:
-- Vollständiges synthetisches ZIP mit hello.txt und dem Text Hi.
DECLARE @ZipArchive varbinary(max)=0x504B0304140000000000000021580E0E174D02000000020000000900000068656C6C6F2E7478744869504B01021400140000000000000021580E0E174D020000000200000009000000000000000000000080010000000068656C6C6F2E747874504B0506000000000100010037000000290000000000;
EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary @ZipArchive=@ZipArchive, @EntryName=N'hello.txt';
*/

-- toolbelt_archive.USP_ListZipEntriesFromBinary
-- Listet deklarierte Metadaten aller Central-Directory-Entries eines klassischen Single-Disk-ZIP aus varbinary(max), ohne Payloads zu lesen oder zu dekomprimieren.
/* Separat auswählen und ausführen:
-- Vollständiges synthetisches ZIP mit hello.txt und dem Text Hi.
DECLARE @ZipArchive varbinary(max)=0x504B0304140000000000000021580E0E174D02000000020000000900000068656C6C6F2E7478744869504B01021400140000000000000021580E0E174D020000000200000009000000000000000000000080010000000068656C6C6F2E747874504B0506000000000100010037000000290000000000;
EXEC toolbelt_archive.USP_ListZipEntriesFromBinary @ZipArchive=@ZipArchive;
*/

-- toolbelt_binary.TVF_LeftShiftBigInt
-- Verschiebt die Bits eines bigint-Werts nach links.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_binary.TVF_LeftShiftBigInt(255, 2);
*/

-- toolbelt_binary.TVF_RightShiftBigInt
-- Verschiebt die Bits eines bigint-Werts logisch nach rechts.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_binary.TVF_RightShiftBigInt(255, 2);
*/

-- toolbelt_binary.TVF_BitCountBigInt
-- Zählt gesetzte Bits im bigint-Wert.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_binary.TVF_BitCountBigInt(255);
*/

-- toolbelt_binary.TVF_GetBitBigInt
-- Liest das Bit an einer nullbasierten Position.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_binary.TVF_GetBitBigInt(255, 3);
*/

-- toolbelt_binary.TVF_SetBitBigInt
-- Setzt oder löscht ein Bit an einer nullbasierten Position.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_binary.TVF_SetBitBigInt(255, 3, 1);
*/

-- toolbelt_conversion.TVF_Base64Encode
-- Codiert Binärdaten als Base64 oder Base64URL.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_conversion.TVF_Base64Encode(0x4869, 0);
*/

-- toolbelt_conversion.TVF_Base64Decode
-- Decodiert Base64-Text zu Binärdaten.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_conversion.TVF_Base64Decode(N'SGk=');
*/

-- toolbelt_conversion.SVF_Base64Encode
-- Codiert Binärdaten als Base64 oder Base64URL.
/* Separat auswählen und ausführen:
SELECT toolbelt_conversion.SVF_Base64Encode(0x4869, 0) AS ResultValue;
*/

-- toolbelt_conversion.SVF_Base64Decode
-- Decodiert Base64-Text zu Binärdaten.
/* Separat auswählen und ausführen:
SELECT toolbelt_conversion.SVF_Base64Decode(N'SGk=') AS ResultValue;
*/

-- toolbelt_conversion.TVF_IntegerToBase
-- Codiert einen bigint-Wert in einem frei festgelegten Zahlensystem.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_conversion.TVF_IntegerToBase(255, '0123456789ABCDEF');
*/

-- toolbelt_conversion.TVF_TryBaseToInteger
-- Decodiert einen Text anhand des angegebenen Alphabets in bigint.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_conversion.TVF_TryBaseToInteger('FF', '0123456789ABCDEF');
*/

-- toolbelt_conversion.SVF_IntegerToBase
-- Codiert einen bigint-Wert in einem frei festgelegten Zahlensystem.
/* Separat auswählen und ausführen:
SELECT toolbelt_conversion.SVF_IntegerToBase(255, '0123456789ABCDEF') AS ResultValue;
*/

-- toolbelt_conversion.SVF_TryBaseToInteger
-- Decodiert einen Text anhand des angegebenen Alphabets in bigint.
/* Separat auswählen und ausführen:
SELECT toolbelt_conversion.SVF_TryBaseToInteger('FF', '0123456789ABCDEF') AS ResultValue;
*/

-- toolbelt_conversion.TVF_UriComponentEncode
-- Codiert eine URI-Komponente mit UTF-8 und Prozent-Escapes nach RFC 3986.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_conversion.TVF_UriComponentEncode(N'a b/ä');
*/

-- toolbelt_conversion.TVF_UriComponentDecode
-- Decodiert eine Runde von Prozent-Escapes und prüft die UTF-8-Sequenz.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_conversion.TVF_UriComponentDecode(N'a%20b%2F%C3%A4');
*/

-- toolbelt_conversion.SVF_UriComponentEncode
-- Codiert eine URI-Komponente mit UTF-8 und Prozent-Escapes nach RFC 3986.
/* Separat auswählen und ausführen:
SELECT toolbelt_conversion.SVF_UriComponentEncode(N'a b/ä') AS ResultValue;
*/

-- toolbelt_conversion.SVF_UriComponentDecode
-- Decodiert eine Runde von Prozent-Escapes und prüft die UTF-8-Sequenz.
/* Separat auswählen und ausführen:
SELECT toolbelt_conversion.SVF_UriComponentDecode(N'a%20b%2F%C3%A4') AS ResultValue;
*/

-- toolbelt_core.USP_WriteConsoleMessage
-- Gibt einen langen Unicode-Text vollständig im Messages-Kanal aus. Gepufferte Ausgabe verwendet PRINT; unmittelbare Ausgabe verwendet RAISERROR mit Severity 0 und NOWAIT.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_WriteConsoleMessage
      @Message = N'Schritt 1 abgeschlossen.'
    , @Immediate = 1;
*/

/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_WriteConsoleMessage
      @Message = N'Gepufferte Ausgabe'
    , @Immediate = 0;

EXEC toolbelt_core.USP_WriteConsoleMessage
      @Message = N'Fortschritt: 100 %'
    , @Immediate = 1;

EXEC toolbelt_core.USP_WriteConsoleMessage @Hilfe = 1;
*/

-- toolbelt_core.USP_CaptureErrorEnvelope
-- Erzeugt aus explizit im aufrufenden CATCH gelesenen ERROR_*-Werten genau eine standardisierte Fehlerzeile. Die Procedure führt keinen Rethrow aus; der Aufrufer verwendet anschließend THROW; im ursprünglichen CATCH.
/* Separat auswählen und ausführen:
BEGIN TRY
    THROW 50000,N'Synthetischer Beispielfehler',1;
END TRY
BEGIN CATCH
    DECLARE @Number int=ERROR_NUMBER(), @Severity int=ERROR_SEVERITY(),
            @State int=ERROR_STATE(), @Line int=ERROR_LINE(),
            @Procedure nvarchar(128)=ERROR_PROCEDURE(),
            @Message nvarchar(4000)=ERROR_MESSAGE();
    EXEC toolbelt_core.USP_CaptureErrorEnvelope
      @ErrorNumber=@Number, @ErrorSeverity=@Severity, @ErrorState=@State,
      @ErrorProcedure=@Procedure, @ErrorLine=@Line, @ErrorMessage=@Message;
END CATCH;
*/

-- toolbelt_core.VW_Events
-- Zeigt protokollierte Toolbelt-Events.
/* Separat auswählen und ausführen:
SELECT TOP (20) * FROM toolbelt_core.VW_Events;
*/

-- toolbelt_core.USP_WriteEvent
-- Schreibt ein strukturiertes Event synchron über toolbelt.core.second-session. Der Remote-Commit ist unabhängig von Commit oder Rollback der Caller-Transaktion.
-- Voraussetzung: Für Second-Session-Ausführung und rollback-unabhängiges Schreiben: administrativ angelegter Loopback-Linked-Server und konfigurierter Provider. Löschen von Events verändert persistente Daten.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_WriteEvent @EventName='demo.completed', @Message=N'Synthetic example';
*/

-- toolbelt_core.USP_DeleteEventsBefore
-- Löscht alte Events in explizit begrenzten Batches. Die Procedure führt keine automatische Zeitplanung aus.
-- Voraussetzung: Für Second-Session-Ausführung und rollback-unabhängiges Schreiben: administrativ angelegter Loopback-Linked-Server und konfigurierter Provider. Löschen von Events verändert persistente Daten.
/* Separat auswählen und ausführen:
DECLARE @n bigint; EXEC toolbelt_core.USP_DeleteEventsBefore @BeforeOccurredAtUtc='2026-01-01', @BatchSize=1000, @MaxBatches=5, @DeletedRows=@n OUTPUT;
*/

-- toolbelt_core.TVF_ExecutionCancellationStatus
-- Liest den registrierten kooperativen Abbruchstatus einer Ausführung.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_core.TVF_ExecutionCancellationStatus(NULL);
*/

-- toolbelt_core.SVF_IsCancellationRequested
-- Prüft, ob für eine Ausführung ein kooperativer Abbruch angefordert wurde.
/* Separat auswählen und ausführen:
SELECT toolbelt_core.SVF_IsCancellationRequested(NULL) AS ResultValue;
*/

-- toolbelt_core.USP_RequestExecutionCancellation
-- Persistiert eine irreversible kooperative Cancellation-Anforderung. Die Procedure beendet keine Session und verändert keine Work-Queue-Einträge.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_RequestExecutionCancellation @CancellationReason=N'planned maintenance';
*/

/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_RequestExecutionCancellation
    @CancellationReason = N'planned maintenance';

SELECT *
FROM toolbelt_core.TVF_ExecutionCancellationStatus
    (toolbelt_core.SVF_CurrentExecutionId());
*/

-- toolbelt_core.TVF_CurrentExecutionContext
-- Liest den Toolbelt-Ausführungskontext der aktuellen Session.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_core.TVF_CurrentExecutionContext();
*/

-- toolbelt_core.SVF_CurrentExecutionId
-- Liest die Execution-ID der aktuellen Session.
/* Separat auswählen und ausführen:
SELECT toolbelt_core.SVF_CurrentExecutionId() AS ResultValue;
*/

-- toolbelt_core.USP_BeginExecution
-- Beginnt einen sessiongebundenen Toolbelt Execution Context oder erhöht bei erlaubter Verschachtelung dessen ScopeDepth. Die Execution-ID wird als OUTPUT zurückgegeben.
/* Separat auswählen und ausführen:
DECLARE @Id uniqueidentifier; EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT;
*/

-- toolbelt_core.USP_SetExecutionContext
-- Ändert Correlation-ID, Actor oder Tenant eines aktiven Contexts. Die erwartete Execution-ID verhindert Änderungen an einem fremden oder veralteten Sessionzustand.
/* Separat auswählen und ausführen:
-- Voraussetzung: in derselben Session zuvor USP_BeginExecution aufrufen.
DECLARE @Id uniqueidentifier=toolbelt_core.SVF_CurrentExecutionId();
EXEC toolbelt_core.USP_SetExecutionContext @ExpectedExecutionId=@Id, @Actor=N'Contoso example', @Tenant=N'Fabrikam';
*/

-- toolbelt_core.USP_EndExecution
-- Verringert den ScopeDepth eines aktiven Contexts und löscht bei Tiefe 1 alle Toolbelt-Sessionwerte.
/* Separat auswählen und ausführen:
-- Voraussetzung: aktiver Context in derselben Session.
DECLARE @Id uniqueidentifier=toolbelt_core.SVF_CurrentExecutionId();
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Id;
*/

-- toolbelt_core.TVF_GenerateSeriesBigInt
-- Erzeugt eine Folge von bigint-Werten einschließlich erreichbarem Endwert.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_core.TVF_GenerateSeriesBigInt(1, 5, 1);
*/

-- toolbelt_core.TVF_GenerateSeriesInt
-- Erzeugt eine Folge von int-Werten einschließlich erreichbarem Endwert.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_core.TVF_GenerateSeriesInt(1, 5, 1);
*/

-- toolbelt_core.USP_PrepareResultTable
-- Bereitet eine vorhandene lokale Temp-Tabelle anhand des Spaltenschemas einer vorhandenen Referenztabelle vor. Die Procedure fügt keine fachlichen Resultzeilen ein.
/* Separat auswählen und ausführen:
CREATE TABLE #Result (Dummy int NULL);
CREATE TABLE #ResultShape (ItemOrdinal bigint NOT NULL, ItemValue varchar(100) NULL);

EXEC toolbelt_core.USP_PrepareResultTable
      @ResultTableToAlter = N'#Result'
    , @LikeTable          = N'#ResultShape'
    , @KeepData           = 0;
DROP TABLE #Result, #ResultShape;
*/

-- toolbelt_core.VW_SecondSessionProviders
-- Zeigt konfigurierte Second-Session-Provider.
/* Separat auswählen und ausführen:
SELECT TOP (20) * FROM toolbelt_core.VW_SecondSessionProviders;
*/

-- toolbelt_core.USP_ConfigureSecondSessionLoopback
-- Verknüpft das Modul mit einem bereits administrativ eingerichteten Loopback-Linked-Server. Das Modul legt weder Linked Server noch Login-Mappings oder Credentials an.
-- Voraussetzung: Für Second-Session-Ausführung und rollback-unabhängiges Schreiben: administrativ angelegter Loopback-Linked-Server und konfigurierter Provider. Löschen von Events verändert persistente Daten.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @LinkedServerName=N'TBX_LOOPBACK';
*/

-- toolbelt_core.USP_ExecuteWorkTypeInNewSession
-- Führt einen registrierten Work Type synchron in einer getrennten SQL-Server-Session aus. Raw SQL ist ausgeschlossen; der Provider muss rpc out aktiv und Remote-Transaction-Promotion deaktiviert haben.
-- Voraussetzung: Für Second-Session-Ausführung und rollback-unabhängiges Schreiben: administrativ angelegter Loopback-Linked-Server und konfigurierter Provider. Löschen von Events verändert persistente Daten.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @WorkTypeName='demo.noop';
*/

-- toolbelt_core.VW_WorkQueue
-- Zeigt Queue-Status und Auditmetadaten ohne Payload und ClaimToken.
/* Separat auswählen und ausführen:
SELECT TOP (20) * FROM toolbelt_core.VW_WorkQueue;
*/

-- toolbelt_core.VW_WorkQueueBarrierBlockers
-- Zeigt aktive Claim-Generationen, die eine Gruppenbarriere blockieren.
/* Separat auswählen und ausführen:
SELECT TOP (20) * FROM toolbelt_core.VW_WorkQueueBarrierBlockers;
*/

-- toolbelt_core.USP_EnqueueWork
-- Reiht genau ein Work Item für einen registrierten, aktiven Work Type ein. Es wird niemals SQL-Text entgegengenommen oder ausgeführt.
-- Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='demo.json', @PayloadJson=N'{"value":1}';
*/

-- toolbelt_core.USP_EnqueueWorkWithPolicy
-- Reiht je nach ExecutionMode SHARED- oder DRAIN_BARRIER-Arbeit mit unveränderlicher Retry-Policy und optionalem Idempotency Key ein.
-- Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.
/* Separat auswählen und ausführen:
-- Voraussetzung: aktiver, ausführbarer Work Type demo.noop.
EXEC toolbelt_core.USP_EnqueueWorkWithPolicy
 @WorkTypeName='demo.noop', @PayloadJson=NULL, @IdempotencyKey=N'example-1',
 @Priority=10, @ExecutionGroup=N'example-group', @MaxAttempts=3,
 @RetryBaseDelaySeconds=60, @RetryMaxDelaySeconds=3600, @ExecutionMode='SHARED';
*/

-- toolbelt_core.USP_EnqueueBarrierWork
-- Reiht DRAIN_BARRIER-Arbeit ein, die vor ihrem exklusiven Claim die relevanten aktiven Claims derselben ExecutionGroup abwartet; Retry-Policy und optionaler Idempotency Key bleiben gebunden.
-- Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.
/* Separat auswählen und ausführen:
-- Voraussetzung: registrierter passender Handler; Barrier hat Seiteneffekte auf Claims.
EXEC toolbelt_core.USP_EnqueueBarrierWork
 @WorkTypeName='demo.noop', @PayloadJson=NULL, @ExecutionGroup=N'example-group', @Priority=10;
*/

-- toolbelt_core.USP_ClaimWork
-- Beansprucht atomar höchstens das älteste beanspruchbare Work Item und eröffnet eine zeitlich begrenzte Lease. Abgelaufene Claims werden nicht implizit übernommen.
-- Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds=300;
*/

-- toolbelt_core.USP_RenewWorkLease
-- Verlängert eine noch aktive Lease mit passendem ClaimToken um ihre beim Claim festgelegte Dauer ab Engine-Zeit. Eine abgelaufene Lease wird nicht wiederbelebt.
-- Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.
/* Separat auswählen und ausführen:
-- WorkItemId und ClaimToken durch den eigenen aktuellen Claim ersetzen;
-- Beispielkonstanten sind keine gültige Claim-Berechtigung.
EXEC toolbelt_core.USP_RenewWorkLease @WorkItemId=1,@ClaimToken='00000000-0000-0000-0000-000000000001';
*/

-- toolbelt_core.USP_RecoverExpiredWork
-- Plant für abgelaufene Claims nach der gespeicherten Retry-Policy RETRY_WAIT oder DEAD_LETTER. Alte ClaimTokens werden atomar invalidiert.
-- Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_RecoverExpiredWork @MaxItems=100;
*/

-- toolbelt_core.USP_CompleteWork
-- Schließt genau ein CLAIMED Work Item mit dem passenden ClaimToken als COMPLETED ab. Ein fachliches Arbeitsergebnis wird in E1a nicht gespeichert.
-- Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.
/* Separat auswählen und ausführen:
-- WorkItemId und ClaimToken durch den eigenen aktuellen Claim ersetzen;
-- Beispielkonstanten sind keine gültige Claim-Berechtigung.
EXEC toolbelt_core.USP_CompleteWork @WorkItemId=1, @ClaimToken='00000000-0000-0000-0000-000000000001';
*/

-- toolbelt_core.USP_FailWork
-- Schließt genau ein CLAIMED Work Item mit passendem ClaimToken als FAILED ab. Gespeichert werden nur ein stabiler Code und eine optionale bereinigte Kurzmeldung.
-- Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.
/* Separat auswählen und ausführen:
-- WorkItemId und ClaimToken durch den eigenen aktuellen Claim ersetzen;
-- Beispielkonstanten sind keine gültige Claim-Berechtigung.
EXEC toolbelt_core.USP_FailWork @WorkItemId=1,@ClaimToken='00000000-0000-0000-0000-000000000001',@FailureCode='DEMO.ERROR';
*/

-- toolbelt_core.USP_ScheduleWorkRetry
-- Plant einen tokengebundenen Retry oder verschiebt nach Dead Letter.
-- Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.
/* Separat auswählen und ausführen:
-- ID und Token stammen aus dem eigenen aktuellen Claim.
DECLARE @WorkItemId bigint=NULL, @ClaimToken uniqueidentifier=NULL; -- tatsächliche Claimwerte einsetzen
EXEC toolbelt_core.USP_ScheduleWorkRetry @WorkItemId=@WorkItemId, @ClaimToken=@ClaimToken,
 @FailureCode='EXAMPLE_RETRY', @FailureMessage=N'Synthetischer Testfehler';
*/

-- toolbelt_core.USP_RequeueDeadLetter
-- Beginnt für ein Dead-Letter-Item einen neuen Retry-Zyklus.
-- Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.
/* Separat auswählen und ausführen:
-- Eine tatsächliche eigene DEAD_LETTER-ID einsetzen.
DECLARE @WorkItemId bigint=NULL;
EXEC toolbelt_core.USP_RequeueDeadLetter @WorkItemId=@WorkItemId, @RequeueReason=N'Synthetischer Wiederholungsversuch';
*/

-- toolbelt_core.USP_GetWorkStatus
-- Liefert genau eine Statuszeile für ein Work Item. Payload und ClaimToken werden bewusst nicht offengelegt.
-- Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_GetWorkStatus @WorkItemId=1;
*/

-- toolbelt_core.VW_WorkTypes
-- Zeigt registrierte Work Types und deren Konfiguration.
/* Separat auswählen und ausführen:
SELECT TOP (20) * FROM toolbelt_core.VW_WorkTypes;
*/

-- toolbelt_core.USP_RegisterWorkType
-- Registriert ausschließlich eine vorhandene Stored Procedure als benannten Work Type. SQL-Text wird weder angenommen noch gespeichert.
-- Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='demo.noop', @HandlerSchema=N'dbo', @HandlerProcedure=N'USP_DemoNoop';
*/

-- toolbelt_core.USP_DisableWorkType
-- Deaktiviert einen registrierten Work Type idempotent und erhält seine Konfiguration.
-- Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_DisableWorkType @WorkTypeName='demo.noop';
*/

-- toolbelt_core.USP_RemoveWorkType
-- Entfernt ausschließlich einen bereits deaktivierten Work Type. Die explizite Datenverlustfreigabe und optionale RowVersion-Prüfung verhindern versehentliche oder konkurrierende Löschungen.
-- Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_RemoveWorkType @WorkTypeName='demo.noop', @AllowDelete=1;
*/

-- toolbelt_core.USP_ResolveWorkType
-- Löst einen registrierten Work Type auf und kann Enabled-, Existenz- und Caller-EXECUTE-Vertrag erzwingen.
-- Voraussetzung: Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.
/* Separat auswählen und ausführen:
EXEC toolbelt_core.USP_ResolveWorkType @WorkTypeName='demo.noop';
*/

-- toolbelt_datetime.TVF_DateBucketDate
-- Ordnet einen date-Wert einem originbezogenen Zeit-Bucket zu.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_datetime.TVF_DateBucketDate('day', 7, CONVERT(date,'2024-07-19'), CONVERT(date,'2024-01-01'));
*/

-- toolbelt_datetime.TVF_DateBucketDateTime2
-- Ordnet einen datetime2-Wert einem originbezogenen Zeit-Bucket zu.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_datetime.TVF_DateBucketDateTime2('day', 7, CONVERT(datetime2(7),'2024-07-19T14:35:42'), CONVERT(datetime2(7),'2024-01-01'));
*/

-- toolbelt_datetime.TVF_DateBucketDateTimeOffset
-- Ordnet einen datetimeoffset-Wert einem originbezogenen Zeit-Bucket zu.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_datetime.TVF_DateBucketDateTimeOffset('day', 7, CONVERT(datetimeoffset(7),'2024-07-19T14:35:42+02:00'), CONVERT(datetimeoffset(7),'2024-01-01'));
*/

-- toolbelt_datetime.TVF_CalendarDifference
-- Zerlegt ein Datumsintervall nach der Anniversary-Regel in Kalenderjahre, Monate und Tage.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_datetime.TVF_CalendarDifference(CONVERT(date,'2024-01-31'), CONVERT(date,'2025-03-02'));
*/

-- toolbelt_datetime.TVF_DateSpineDay
-- Liefert alle Tage, die einen halboffenen Zeitraum schneiden.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_datetime.TVF_DateSpineDay(CONVERT(date,'2024-01-15'), CONVERT(date,'2024-03-01'));
*/

-- toolbelt_datetime.TVF_DateSpineIsoWeek
-- Liefert alle ISO-Wochen, die einen halboffenen Zeitraum schneiden.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_datetime.TVF_DateSpineIsoWeek(CONVERT(date,'2024-01-15'), CONVERT(date,'2024-03-01'));
*/

-- toolbelt_datetime.TVF_DateSpineMonth
-- Liefert alle Monate, die einen halboffenen Zeitraum schneiden.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_datetime.TVF_DateSpineMonth(CONVERT(date,'2024-01-15'), CONVERT(date,'2024-03-01'));
*/

-- toolbelt_datetime.TVF_TruncateDate
-- Kürzt einen date-Wert auf den Beginn der ausgewählten Kalenderperiode.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_datetime.TVF_TruncateDate('day', CONVERT(date,'2024-07-19'));
*/

-- toolbelt_datetime.TVF_TruncateDateTime2
-- Kürzt einen datetime2-Wert auf den Beginn der gewählten Zeiteinheit.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_datetime.TVF_TruncateDateTime2('day', CONVERT(datetime2(7),'2024-07-19T14:35:42'));
*/

-- toolbelt_datetime.TVF_TruncateDateTimeOffset
-- Kürzt einen datetimeoffset-Wert auf die gewählte Zeiteinheit und erhält den Offset.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_datetime.TVF_TruncateDateTimeOffset('day', CONVERT(datetimeoffset(7),'2024-07-19T14:35:42+02:00'));
*/

-- toolbelt_file.USP_LoadBinaryFile
-- Liest eine Datei als varbinary(max) über OPENROWSET(BULK...). Der Pfad muss unter einem Eintrag der Root-Allowlist liegen.
-- Voraussetzung: Vorhandene Datei unter einem konfigurierten Allowlist-Root und passende SQL-/Dateirechte.
/* Separat auswählen und ausführen:
-- Voraussetzung: passende Allowlist und eigene synthetische Datei.
EXEC toolbelt_file.USP_LoadBinaryFile @FilePath=N'C:\ExampleRoot\sample.bin', @MaxBytes=1048576;
*/

-- toolbelt_file.USP_LoadTextFile
-- Liest eine Textdatei als nvarchar(max) über OPENROWSET(BULK...). Erkennt BOM und decodiert entsprechend; Inhalt ohne BOM wird mit @FallbackEncoding gelesen.
-- Voraussetzung: Vorhandene Datei unter einem konfigurierten Allowlist-Root und passende SQL-/Dateirechte.
/* Separat auswählen und ausführen:
-- Voraussetzung: passende Allowlist und eigene synthetische Datei.
EXEC toolbelt_file.USP_LoadTextFile @FilePath=N'C:\ExampleRoot\sample.txt', @MaxBytes=1048576;
*/

-- toolbelt_file.USP_ListXlsxWorksheets
-- Begrenzter SAFE Binary-XLSX-Reader; atomarer gewählter Snapshot, keine Datei-/Netzwerkzugriffe, Formelberechnung oder Typinferenz.
/* Separat auswählen und ausführen:
EXEC toolbelt_file.USP_ListXlsxWorksheets @Hilfe = 1;
-- @SyntheticWorkbook stammt ausschließlich aus einem synthetischen Testfixture.
EXEC toolbelt_file.USP_ListXlsxWorksheets @XlsxBinary = @SyntheticWorkbook;
*/

-- toolbelt_file.USP_ReadXlsxWorksheetCells
-- Begrenzter SAFE Binary-XLSX-Reader; atomarer gewählter Snapshot, keine Datei-/Netzwerkzugriffe, Formelberechnung oder Typinferenz.
/* Separat auswählen und ausführen:
EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @Hilfe = 1;
-- @SyntheticWorkbook stammt ausschließlich aus einem synthetischen Testfixture.
EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @XlsxBinary = @SyntheticWorkbook, @SheetOrdinal = 1;
*/

-- toolbelt_file.TVF_InterpretXlsxCell
-- Interpretiert den zuvor gelesenen Rohwert einer XLSX-Zelle als begrenzten, typisierten Wert.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_file.TVF_InterpretXlsxCell(N'n', 1, N'1.235', NULL, N'number', N'0.00', 0);
*/

-- toolbelt_file.TVF_FormatXlsxCell
-- Formatiert eine XLSX-Einzelzelle mit den unterstützten Literalformaten und Kulturen.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_file.TVF_FormatXlsxCell(N'n', 1, N'1.235', NULL, N'number', N'0.00', 0, N'de-DE');
*/

-- toolbelt_filesystem.USP_ReadBinaryFileChunk
-- Liest einen begrenzten Binär-Chunk aus einer per RootAlias freigegebenen Datei.
-- Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.
/* Separat auswählen und ausführen:
-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk
 @RootAlias=N'ExampleRoot', @RelativePath=N'example.bin', @ByteOffset=0, @MaxBytes=1024, @ExecutionIdentity=N'Caller';
*/

-- toolbelt_filesystem.USP_ReadTextFileChunk
-- Liest einen begrenzten Text-Chunk mit expliziter Codepage und liefert die nächste Byte-Position.
-- Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.
/* Separat auswählen und ausführen:
-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_ReadTextFileChunk
 @RootAlias=N'ExampleRoot', @RelativePath=N'example.txt', @ByteOffset=0, @MaxBytes=1024, @EncodingName=N'utf-8', @ExecutionIdentity=N'Caller';
*/

-- toolbelt_filesystem.USP_WriteBinaryFile
-- Schreibt Binärdaten gestreamt in eine atomar veröffentlichte Zieldatei.
-- Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.
/* Separat auswählen und ausführen:
-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_WriteBinaryFile
 @RootAlias=N'ExampleRoot', @RelativePath=N'example.bin', @Content=0x4869, @Overwrite=0, @ExecutionIdentity=N'Caller';
*/

-- toolbelt_filesystem.USP_WriteTextFile
-- Schreibt Text gestreamt mit expliziter Codepage und optionalem BOM.
-- Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.
/* Separat auswählen und ausführen:
-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_WriteTextFile
 @RootAlias=N'ExampleRoot', @RelativePath=N'example.txt', @Content=N'Contoso', @EncodingName=N'utf-8', @WriteBom=0, @Overwrite=0, @ExecutionIdentity=N'Caller';
*/

-- toolbelt_filesystem.USP_TranscodeTextFile
-- Konvertiert eine Textdatei gestreamt zwischen zwei expliziten Codepages.
-- Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.
/* Separat auswählen und ausführen:
-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_TranscodeTextFile
 @SourceRootAlias=N'ExampleRoot', @SourceRelativePath=N'input.txt', @SourceEncodingName=N'utf-8', @TargetRootAlias=N'ExampleRoot', @TargetRelativePath=N'output.txt', @TargetEncodingName=N'utf-16', @Overwrite=0, @ExecutionIdentity=N'Caller';
*/

-- toolbelt_filesystem.USP_ListDirectory
-- Listet Verzeichniseinträge unter einem freigegebenen Root mit harten Grenzen.
-- Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.
/* Separat auswählen und ausführen:
-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_ListDirectory
 @RootAlias=N'ExampleRoot', @RelativePath=N'', @Recursive=0, @MaxEntries=100, @ExecutionIdentity=N'Caller';
*/

-- toolbelt_filesystem.USP_CreateDirectory
-- Erstellt ein Verzeichnis unter einem freigegebenen Root.
-- Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.
/* Separat auswählen und ausführen:
-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_CreateDirectory
 @RootAlias=N'ExampleRoot', @RelativePath=N'example-dir', @ExecutionIdentity=N'Caller';
*/

-- toolbelt_filesystem.USP_RemoveFile
-- Entfernt eine Datei unter einem freigegebenen Root.
-- Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.
/* Separat auswählen und ausführen:
-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_RemoveFile
 @RootAlias=N'ExampleRoot', @RelativePath=N'own-example.bin', @ExecutionIdentity=N'Caller';
*/

-- toolbelt_filesystem.USP_RemoveDirectory
-- Entfernt ein Verzeichnis; rekursives Entfernen ist explizit und begrenzt.
-- Voraussetzung: Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.
/* Separat auswählen und ausführen:
-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_RemoveDirectory
 @RootAlias=N'ExampleRoot', @RelativePath=N'own-example-dir', @Recursive=0, @ExecutionIdentity=N'Caller';
*/

-- toolbelt_json.USP_JsonArray
-- JSON-Array aus Ordinal/ValueKind/Value; vollständig validiert und atomar geroutet.
/* Separat auswählen und ausführen:
CREATE TABLE #Entries(Ordinal int,ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #Entries VALUES(1,N'string',N'Contoso'),(2,N'number',N'42');
EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#Entries';
DROP TABLE #Entries;
*/

-- toolbelt_json.USP_JsonObject
-- JSON-Object aus Ordinal/ValueKind/Value/Key; vollständig validiert und atomar geroutet.
/* Separat auswählen und ausführen:
CREATE TABLE #Entries(Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #Entries VALUES(1,N'name',N'string',N'Contoso'),(2,N'count',N'number',N'42');
EXEC toolbelt_json.USP_JsonObject @EntriesTable=N'#Entries';
DROP TABLE #Entries;
*/

-- toolbelt_json.USP_JsonArraysByGroup
-- JSON-Array aus GroupOrdinal/Ordinal/ValueKind/Value; vollständig validiert und atomar geroutet.
/* Separat auswählen und ausführen:
CREATE TABLE #Entries(GroupOrdinal int,Ordinal int,ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #Entries VALUES(1,1,N'string',N'Contoso'),(2,1,N'number',N'42');
EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N'#Entries';
DROP TABLE #Entries;
*/

/* Separat auswählen und ausführen:
CREATE TABLE #Entries(GroupOrdinal int,Ordinal int,ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #Entries VALUES(1,1,N'string',N'Contoso'),(2,1,N'number',N'42');
EXEC toolbelt_json.USP_JsonArraysByGroup
 @EntriesTable = N'#Entries', @MaxEntries = 10000,
 @MaxTotalValueBytes = 2097152, @MaxResultBytes = 2097152,
 @ResultTable = NULL, @KeepData = 0, @Debug = 0, @Hilfe = 0;
DROP TABLE #Entries;
*/

-- toolbelt_json.USP_JsonObjectsByGroup
-- JSON-Object aus GroupOrdinal/Ordinal/ValueKind/Value/Key; vollständig validiert und atomar geroutet.
/* Separat auswählen und ausführen:
CREATE TABLE #Entries(GroupOrdinal int,Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #Entries VALUES(1,1,N'name',N'string',N'Contoso'),(2,1,N'count',N'number',N'42');
EXEC toolbelt_json.USP_JsonObjectsByGroup @EntriesTable=N'#Entries';
DROP TABLE #Entries;
*/

/* Separat auswählen und ausführen:
CREATE TABLE #Entries(GroupOrdinal int,Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #Entries VALUES(1,1,N'name',N'string',N'Contoso'),(2,1,N'count',N'number',N'42');
EXEC toolbelt_json.USP_JsonObjectsByGroup
 @EntriesTable = N'#Entries', @MaxEntries = 10000,
 @MaxTotalValueBytes = 2097152, @MaxResultBytes = 2097152,
 @ResultTable = NULL, @KeepData = 0, @Debug = 0, @Hilfe = 0;
DROP TABLE #Entries;
*/

-- toolbelt_json.AGF_JsonArray
-- Aggregiert typisierte JSON-Einträge in Ordinal-Reihenfolge zu einem JSON-Array.
/* Separat auswählen und ausführen:
DECLARE @Entries TABLE(Ordinal int,ValueKind nvarchar(max),[Value] nvarchar(max),Profile tinyint);
INSERT @Entries VALUES(2,N'number',N'2',1),(1,N'string',N'Contoso',1);
SELECT toolbelt_json.AGF_JsonArray(Ordinal,ValueKind,[Value],Profile) AS JsonValue FROM @Entries;
*/

-- toolbelt_json.AGF_JsonObject
-- Aggregiert typisierte Einträge mit eindeutigen Schlüsseln zu einem JSON-Objekt.
/* Separat auswählen und ausführen:
DECLARE @Entries TABLE(Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max),Profile tinyint);
INSERT @Entries VALUES(1,N'name',N'string',N'Contoso',1),(2,N'count',N'number',N'2',1);
SELECT toolbelt_json.AGF_JsonObject(Ordinal,[Key],ValueKind,[Value],Profile) AS JsonValue FROM @Entries;
*/

-- toolbelt_json.TVF_JsonPathExists
-- Prüft, ob ein unterstützter Pfad in einem JSON-Dokument existiert.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_json.TVF_JsonPathExists(N'{"items":[1,2]}', N'$.items[0]');
*/

-- toolbelt_metadata.VW_ModuleCapabilities
-- Zeigt installierte Modulversionen und Deployment-Modi und kennzeichnet unvollständige oder ungültige Modulmarker.
/* Separat auswählen und ausführen:
SELECT ModuleId, ModuleVersion, DeploymentMode, MetadataStatus
FROM toolbelt_metadata.VW_ModuleCapabilities
ORDER BY ModuleId;
*/

-- toolbelt_metadata.TVF_ParseMultipartName
-- Zerlegt und validiert ein- bis vierteilige SQL-Identifier.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_metadata.TVF_ParseMultipartName(N'dbo.[Order Items]');
*/

-- toolbelt_metadata.SVF_QuoteMultipartName
-- Validiert einen mehrteiligen SQL-Namen und quotiert seine Komponenten.
/* Separat auswählen und ausführen:
SELECT toolbelt_metadata.SVF_QuoteMultipartName(N'dbo.[Order Items]') AS ResultValue;
*/

-- toolbelt_metadata.USP_ScriptTableClone
-- Vollständige DDL-Vorschau innerhalb des begrenzten unterstützten Strukturumfangs; niemals DDL-Ausführung oder Datenkopie. Unsupported führt zum Abbruch.
-- Voraussetzung: Vorhandene synthetische Quelltabelle und sichtbares Zielschema; Zielname darf noch nicht existieren. IncludeTriggers=1 verlangt Windows und den separat installierten Parser 2.0.
/* Separat auswählen und ausführen:
EXEC toolbelt_metadata.USP_ScriptTableClone @SourceSchema=N'dbo',@SourceTable=N'SyntheticSource',@TargetSchema=N'dbo',@TargetTable=N'SyntheticClone';
*/

/* Separat auswählen und ausführen:
EXEC toolbelt_metadata.USP_ScriptTableClone @SourceSchema=N'dbo',@SourceTable=N'SyntheticSource',@TargetSchema=N'dbo',@TargetTable=N'SyntheticClone',@IncludeTriggers=1;
*/

-- toolbelt_metadata.USP_ExecuteTableClone
-- Erzeugt den V3-Plan neu und führt nur dessen hashgebundene DDL für neue same-database Ziele aus; keine Datenkopie.
-- Voraussetzung: Erzeugt neue Tabellen. @CalculatedPlanHash ist ein notwendiger Platzhalter für die externe kanonische Hashberechnung; der Beispielaufruf ist bis dahin nicht ausführbar.
/* Separat auswählen und ausführen:
-- Voraussetzung: eigene Quelltabelle und neues Ziel in vorhandenen Schemas.
-- Den Vorschauplan mit identischen Optionen erzeugen und seinen Hash
-- nach dem kanonischen Client-Framing berechnen; keine Konstante erfinden.
DECLARE @CalculatedPlanHash varbinary(max)=NULL; -- berechneten 32-Byte-Hash einsetzen
EXEC toolbelt_metadata.USP_ExecuteTableClone
 @SourceSchema=N'dbo', @SourceTable=N'SyntheticSource',
 @TargetSchema=N'dbo', @TargetTable=N'SyntheticClone',
 @ExpectedPlanHash=@CalculatedPlanHash, @ForeignKeyMode='CREATE';
*/

-- toolbelt_metadata.USP_CopyTableCloneData
-- Kopiert einen begrenzten SameDB-Tabellenverbund atomar in bereits vorhandene leere formgleiche Ziele; keine Strukturkopie oder Rechtevergabe.
-- Voraussetzung: Vorhandene reguläre SameDB-Quellen und leere formgleiche Ziele, keine aktive Callertransaktion. SERIALIZABLE hält Quellsperren; SNAPSHOT benötigt eine bereits aktivierte Datenbankoption.
-- Voraussetzung: Vorhandene DB-Metadatensicht und Source-/Target-Rechte; fehlende FKs verlangen zusätzlich Server-DDL-Sicht und DDL-Rechte. KEEP benötigt vorhandenes Identity-ALTER. Aktive Targettrigger, RLS und nicht tabellenlokale Ausführung blockieren.
-- Voraussetzung: Verändert Zielinhalte und kann fehlende gemappte FKs erzeugen. Identity-Zähler können trotz Rollback fortgeschritten bleiben; kein RESEED oder Identitätszuordnungsversprechen.
/* Separat auswählen und ausführen:
CREATE TABLE #CopyMap
(
 MapOrdinal int NOT NULL,
 SourceSchema nvarchar(max) NOT NULL, SourceTable nvarchar(max) NOT NULL,
 TargetSchema nvarchar(max) NOT NULL, TargetTable nvarchar(max) NOT NULL
);
-- Eigene synthetische Tabellen bestehen bereits; SyntheticClone ist leer und formgleich.
INSERT #CopyMap VALUES (1,N'dbo',N'SyntheticSource',N'dbo',N'SyntheticClone');
EXEC toolbelt_metadata.USP_CopyTableCloneData
 @TableMap=N'#CopyMap', @IdentityMode='KEEP', @ConsistencyMode='SERIALIZABLE';
DROP TABLE #CopyMap;
*/

-- toolbelt_pseudonymization.TVF_DeterministicGeoJitter
-- Verschiebt einen synthetischen 2D-Geography-Point im SRID 4326 deterministisch innerhalb eines Radius.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicGeoJitter(geography::Point(48.2,16.3,4326), 0x01020304, 1, 42, 25);
*/

-- toolbelt_pseudonymization.TVF_DeterministicTranslate
-- Übersetzt ASCII-Buchstaben und Ziffern deterministisch über eine bijektive Abbildung.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(N'  Contoso-123  ', 1, 42, N'- ', N'standard');
*/

-- toolbelt_pseudonymization.TVF_DeterministicRange
-- Ordnet einen Schlüssel deterministisch einem ganzzahligen Zielbereich zu.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicRange(0x01020304, 1, 42, 1, 100);
*/

-- toolbelt_pseudonymization.TVF_DeterministicDateShift
-- Verschiebt ein Datum deterministisch um eine begrenzte Anzahl Tage.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicDateShift(CONVERT(datetime2(7),'2024-07-19T14:35:42'), 0x01020304, 1, 42, 7);
*/

-- toolbelt_pseudonymization.USP_DeterministicLookup
-- Deterministischer synthetischer Lookup; explizite Poolversion, kein Anonymisierungs- oder Eins-zu-eins-Schutz.
/* Separat auswählen und ausführen:
CREATE TABLE #Input(Ordinal bigint, [Key] varbinary(max)); CREATE TABLE #Pool(Ordinal bigint, [Value] nvarchar(max)); INSERT #Input VALUES(10,0x010203); INSERT #Pool VALUES(20,N'synthetic'); EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#Input',@LookupTable=N'#Pool',@MappingVersion=1,@LookupVersion=1;
DROP TABLE #Input, #Pool;
*/

-- toolbelt_string.TVF_TrimDirectionalNvarchar
-- Entfernt ausgewählte Zeichen links, rechts oder beidseitig aus einem Unicode-Text.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_TrimDirectionalNvarchar(N'  Contoso-123  ', N' ', 'BOTH');
*/

-- toolbelt_string.TVF_TrimDirectionalVarchar
-- Entfernt ausgewählte Zeichen links, rechts oder beidseitig aus einem varchar-Text.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_TrimDirectionalVarchar('  Contoso  ', N' ', 'BOTH');
*/

-- toolbelt_string.TVF_JaroWinklerSimilarity
-- Berechnet einen Jaro-Winkler-Ähnlichkeitsscore zwischen 0 und 1 über Unicode Scalars.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_JaroWinklerSimilarity(N'kitten', N'sitting', N'standard');
*/

-- toolbelt_string.TVF_LevenshteinDistance
-- Berechnet die begrenzte Levenshtein-Editierdistanz zweier Unicode-Texte.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_LevenshteinDistance(N'kitten', N'sitting', NULL, N'standard');
*/

-- toolbelt_string.TVF_OsaDistance
-- Berechnet die begrenzte Optimal-String-Alignment-Distanz mit benachbarten Transpositionen.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_OsaDistance(N'kitten', N'sitting', NULL, N'standard');
*/

-- toolbelt_string.TVF_ColognePhonetic
-- Berechnet den vollständigen begrenzten Kölner Phonetikcode.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_ColognePhonetic(N'Contoso');
*/

-- toolbelt_string.TVF_DoubleMetaphone
-- Berechnet den primären und alternativen Double-Metaphone-Code.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_DoubleMetaphone(N'Contoso');
*/

-- toolbelt_string.TVF_RegexCaptures
-- Liefert Gruppen-Captures einschließlich wiederholter Captures.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_RegexCaptures(N'abc123 def456', N'[0-9]+', 1, N'c', N'standard', 1000);
*/

-- toolbelt_string.SVF_RegexReplaceGroups
-- Ersetzt Regex-Treffer mit dem getrennten Gruppen-Ersatzvertrag.
/* Separat auswählen und ausführen:
SELECT toolbelt_string.SVF_RegexReplaceGroups(N'abc123 def456', N'(?<Digits>[0-9]+)', N'[${Digits}]', 1, 0, N'c', N'standard') AS ResultValue;
*/

-- toolbelt_string.TVF_RegexMatches
-- Liefert vollständige Regex-Treffer mit Ordinals und Positionen.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_RegexMatches(N'abc123 def456', N'[0-9]+', 1, N'c', N'standard', 1000);
*/

-- toolbelt_string.TVF_RegexSplit
-- Zerlegt einen Text an Regex-Treffern.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_RegexSplit(N'a,b;;c', N'[0-9]+', N'c', N'standard', 1000);
*/

-- toolbelt_string.SVF_RegexIsMatch
-- Prüft, ob ein regulärer Ausdruck im Text trifft.
/* Separat auswählen und ausführen:
SELECT toolbelt_string.SVF_RegexIsMatch(N'abc123 def456', N'[0-9]+', N'c') AS ResultValue;
*/

-- toolbelt_string.SVF_RegexInstr
-- Liefert eine UTF-16-Position eines ausgewählten Regex-Treffers.
/* Separat auswählen und ausführen:
SELECT toolbelt_string.SVF_RegexInstr(N'abc123 def456', N'[0-9]+', 1, 1, 0, N'c') AS ResultValue;
*/

-- toolbelt_string.SVF_RegexCount
-- Zählt Regex-Treffer ab der angegebenen Startposition.
/* Separat auswählen und ausführen:
SELECT toolbelt_string.SVF_RegexCount(N'abc123 def456', N'[0-9]+', 1, N'c') AS ResultValue;
*/

-- toolbelt_string.SVF_RegexReplace
-- Ersetzt ganze Regex-Treffer durch einen literalen Ersatztext.
/* Separat auswählen und ausführen:
SELECT toolbelt_string.SVF_RegexReplace(N'abc123 def456', N'[0-9]+', N'X', 1, 1, N'c', N'standard') AS ResultValue;
*/

-- toolbelt_string.SVF_RegexSubstring
-- Liefert den ausgewählten vollständigen Regex-Treffer.
/* Separat auswählen und ausführen:
SELECT toolbelt_string.SVF_RegexSubstring(N'abc123 def456', N'[0-9]+', 1, 1, N'c', N'standard') AS ResultValue;
*/

-- toolbelt_string.TVF_SplitAdvanced
-- Zerlegt Originaltokens mit mehreren Separatoren, Quotes und Escape-Regeln; entquotiert sie nicht.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_SplitAdvanced(N'a,b;;c', N'[",",";"]', N'"', N'\', 1);
*/

-- toolbelt_string.TVF_UnquoteToken
-- Entfernt ein unterstütztes äußeres Quote-Paar und decodiert dessen Escapes.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_UnquoteToken(N'[a]]b]', NULL, NULL, 0);
*/

-- toolbelt_string.USP_SplitAdvanced
-- Originaltokens aus kanonischer TVF; Geschäftsfehler vor Zielmutation, kein Unquoting.
/* Separat auswählen und ausführen:
EXEC toolbelt_string.USP_SplitAdvanced @Input=N'a;b', @SeparatorsJson=N'[";"]', @Quote=N'', @Escape=N'';
*/

/* Separat auswählen und ausführen:
EXEC toolbelt_string.USP_SplitAdvanced
    @Input=N'a;"b;c";d', @SeparatorsJson=N'[";"]';
EXEC toolbelt_string.USP_SplitAdvanced @Hilfe=1;
*/

-- toolbelt_string.TVF_SplitByCharacters
-- Zerlegt einen Text an jedem Zeichen der angegebenen Separatormenge.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_string.TVF_SplitByCharacters(N'a,b;;c', N',;', 1);
*/

-- toolbelt_string.USP_CompareTextPairs
-- Begrenzt vergleicht vorhandene lokale Textpaare mit den kanonischen Distanz-/Jaro-TVFs. Globale Fehler veröffentlichen keine Teilresultate.
/* Separat auswählen und ausführen:
CREATE TABLE #Pairs(PairOrdinal bigint,LeftText nvarchar(max),RightText nvarchar(max)); INSERT #Pairs VALUES(1,N'kitten',N'sitting'); EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'levenshtein';
*/

-- toolbelt_tsql.TVF_ParseScriptNodes
-- Liefert die AST-Knoten eines begrenzten T-SQL-Skripts.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_tsql.TVF_ParseScriptNodes(N'SELECT 1 AS SyntheticValue;', 160, 1, 2097152, 256);
*/

-- toolbelt_tsql.TVF_ParseScriptNodeProperties
-- Liefert Eigenschaften der geparsten T-SQL-AST-Knoten.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_tsql.TVF_ParseScriptNodeProperties(N'SELECT 1 AS SyntheticValue;', 160, 1, 2097152, 256);
*/

-- toolbelt_tsql.TVF_TokenizeScript
-- Liefert Tokens eines T-SQL-Skripts.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_tsql.TVF_TokenizeScript(N'SELECT 1 AS SyntheticValue;', 160, 1, 2097152, 256);
*/

-- toolbelt_tsql.TVF_ParseScriptErrors
-- Liefert Parserfehler eines T-SQL-Skripts, ohne das Skript auszuführen.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_tsql.TVF_ParseScriptErrors(N'SELECT 1 AS SyntheticValue;', 160, 1, 2097152, 256);
*/

-- toolbelt_validation.TVF_ParseSemanticVersion
-- Prüft und zerlegt eine Version nach SemVer 2.0.0.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_validation.TVF_ParseSemanticVersion(N'1.2.3-alpha.1+build.7');
*/

-- toolbelt_validation.TVF_CompareSemanticVersion
-- Vergleicht zwei SemVer-Versionen; Build-Metadaten ändern die fachliche Rangfolge nicht.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_validation.TVF_CompareSemanticVersion(N'1.2.3', N'2.0.0');
*/

-- toolbelt_validation.TVF_SemanticVersionSortKey
-- Erzeugt einen binären Sortierschlüssel für eine gültige SemVer-Version.
/* Separat auswählen und ausführen:
SELECT * FROM toolbelt_validation.TVF_SemanticVersionSortKey(N'1.2.3-alpha.1+build.7');
*/

-- toolbelt_validation.SVF_CompareSemanticVersion
-- Vergleicht zwei SemVer-Versionen; Build-Metadaten ändern die fachliche Rangfolge nicht.
/* Separat auswählen und ausführen:
SELECT toolbelt_validation.SVF_CompareSemanticVersion(N'1.2.3', N'2.0.0') AS ResultValue;
*/

-- toolbelt_validation.SVF_SemanticVersionSortKey
-- Erzeugt einen binären Sortierschlüssel für eine gültige SemVer-Version.
/* Separat auswählen und ausführen:
SELECT toolbelt_validation.SVF_SemanticVersionSortKey(N'1.2.3-alpha.1+build.7') AS ResultValue;
*/
