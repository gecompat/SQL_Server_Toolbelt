# Queue verwenden: vom ersten Auftrag zum Workerbetrieb

Die Work Queue speichert Aufträge in SQL Server, verteilt sie über zeitlich
begrenzte Claims und hält Erfolg, Fehler und Wiederholungen fest. Ein Auftrag
enthält einen registrierten **Work Type** und gegebenenfalls JSON-Daten.
Der **Handler** ist die dazu registrierte Stored Procedure. Ein **Worker**
beansprucht einen Auftrag, führt den Handler aus und meldet den Abschluss.
**Einreihen und Claim allein führen keinen Handler aus.**

Diese Anleitung beschreibt Work Queue 2.1, Work Type 1.2 und die optionale
Workersteuerung 1.0 anhand der aktuellen Quellen. Die Module sind
unveröffentlicht und teilweise validiert. Die [Modulbeschreibung](../README.md)
und die [Worker-Nachweise](../../../Workers/ExternalQueue/Tests/README.md)
grenzen belegte Plattformen und offene Betriebsfälle ab. Beispiele erläutern
den Vertrag; sie sind keine zusätzliche Plattformqualifikation.

## Leseweg

1. [Wann einsetzen?](#einsatzfälle-und-auswahl)
2. [Installation und Rechte](#vorbereitung-und-installation)
3. [Vollständiges SSMS-Beispiel](#erstes-vollständiges-ssms-beispiel)
4. [Alle Queue-Funktionen](#alle-öffentlichen-queue-funktionen)
5. [Retry, Dead Letter und Recovery](#retry-dead-letter-und-recovery)
6. [Gruppen, Prioritäten und Barriers](#gruppen-prioritäten-und-barriers)
7. [Work Types und Berechtigungen](#work-types-und-berechtigungen)
8. [Externer Worker und zentrale Steuerung](#workerbetrieb)
9. [Status, Fehlerklärung und Bereinigung](#status-und-fehlerklärung)

## Einsatzfälle und Auswahl

| Bedarf | Passende Möglichkeit | Wirkung und Grenze |
|---|---|---|
| Eine Anwendung soll schnell einen Auftrag ablegen; Verarbeitung darf später erfolgen | Enqueue und separater Worker | Auftrag bleibt persistent. Ohne gestarteten Worker bleibt er liegen. |
| Mehrere unabhängige SQL-Arbeitspakete verteilen | `SHARED`, mehrere Worker/Slots | Atomarer Claim verhindert gleichzeitige Vergabe derselben Claim-Generation. Keine Exactly-once-Garantie für fachliche Wirkungen. |
| Einen Import auch nach vorübergehenden Fehlern fortsetzen | Expliziter Retry mit Backoff | Nur als wiederholbar eingestufte Arbeit erneut starten; Fehlerklassifikation gehört zum Worker/Betreiber. |
| Doppelte Einreichung nach verlorenem Client-Ack vermeiden | `IdempotencyKey` | Gleiche Einreichung liefert dieselbe WorkItemId. Der Handler braucht gegebenenfalls zusätzlich fachliche Idempotenz. |
| Innerhalb einer Gruppe einen Wartungs- oder Übergangsschritt einziehen | `DRAIN_BARRIER` | Wartet auf gespeicherte laufende Claim-Generationen und sperrt normale neue Claims dieser Gruppe. Kein allgemeiner DAG- oder Batchabschluss. |
| Mehrere Worker gemeinsam begrenzen, pausieren oder stoppen | Managed Worker Control | Zentrale Zulassung, Status, Stop/Hold und bewiesene Wiederfreigabe; eigener Betriebs- und Nachweisumfang. |
| Ergebnis muss synchron im selben Aufruf vorliegen | Handler direkt aufrufen | Queue-Complete speichert keine fachlichen Ergebnisdaten und liefert sie nicht an den ursprünglichen Producer zurück. |
| E-Mails, Dateischreiben, HTTP oder DTSX unmittelbar ausführen | Nicht der hier beschriebene externe Provider | Seine Handlerzulassung schließt externe Seiteneffekte aus. Eine Queue-Payload ist kein ausführbares SQL, PowerShell oder DTSX. |

Auch ein wiederholter Handler darf nicht unkontrolliert doppelt buchen. Für
SQL-Seiteneffekte können Fachschlüssel, eindeutige Constraints und eine gemeinsame
Transaktion mit Complete helfen. `IsIdempotent=1` ist nur eine Deklaration.
Zeitpläne, Dienste, Service Broker, SQL Server Agent und automatische
Systemzustandsreaktionen installiert die Queue nicht.

## Vorbereitung und Installation

Benötigt werden SQL Server 2019 oder neuer gemäß Modulmatrix sowie Rechte für
die gewählte Installation. Queue und Katalog sind T-SQL-Module; für diese
Anleitung sind keine CLR-Assembly und kein eigener Build erforderlich.
Queue, Work-Type-Katalog und Handler befinden sich in derselben Datenbank.

Für den Lernweg eine **neue, ausschließlich dafür bestimmte** Datenbank
`ToolbeltQueueDemo` verwenden. Es dürfen keine fremden Aufträge oder Worker
darauf zugreifen. Der Name allein macht eine vorhandene Datenbank nicht zur Demo.
Die vollständige SQL-Datei lässt sich aus einem aktuellen Checkout ohne
Serververbindung erzeugen:

```powershell
# Im Repository-Hauptverzeichnis, PowerShell 7:
./Deployment/Deploy-All.ps1 -DeploymentMode local `
    -ModuleId toolbelt.core.work-queue -PlanOnly
./Deployment/Deploy-All.ps1 -DeploymentMode local `
    -ModuleId toolbelt.core.work-queue -OutputSqlFile ./Queue-Demo-Install.sql
```

Der Plan ergänzt die benötigten Dependencies. Die Ausgabedatei darf noch
nicht existieren. In SSMS zunächst in einer eigenen Verbindung erstellen:

```sql
USE master;
GO
IF DB_ID(N'ToolbeltQueueDemo') IS NOT NULL
    THROW 50000, N'Datenbank existiert bereits. Eigentum/Inhalt zuerst prüfen.', 1;
CREATE DATABASE ToolbeltQueueDemo;
GO
```

Danach eine **neue** SSMS-Abfrage mit Datenbank `ToolbeltQueueDemo` öffnen,
SQLCMD-Modus einschalten, `Queue-Demo-Install.sql` öffnen und ausführen.
Nach der Installation diese Verbindung schließen. Der Export enthält
SQLCMD-Fehlerabbruch; bei einem Fehler zuerst dessen Ursache klären.
[Deploymentdetails und Wiederholung](../../../Deployment/README.md).

Für die folgenden Lernskripte eine neue gewöhnliche SSMS-Abfrage verwenden.
Der ausführende Demo-Administrator benötigt CREATE TABLE/PROCEDURE und die
aufgerufenen Objekt-/Policyrechte; ein Datenbankowner in der eigenen Demo hat
diese Voraussetzungen. Das ist **keine Empfehlung für die Produktionsrolle**.
Die SQL-Installation vergibt keine ENQUEUE-/CLAIM-Policy automatisch.

Zentrale Nutzung: `-DeploymentMode central` für eine ausdrücklich gewählte
Toolbelt-Datenbank verwenden und den Handler dort bereitstellen. Dreiteilige
Aufrufe wie `Toolbelt.toolbelt_core.USP_EnqueueWorkWithPolicy` adressieren diese
Queue; sie erzeugen keine Queue in der aufrufenden Datenbank. SQL-Rechte und
Policy gelten im tatsächlichen Kontext der zentralen Datenbank. Kein
automatisches Synonymdeployment und keine pauschale CrossDB-Rechtezusage.

## Erstes vollständiges SSMS-Beispiel

1. Datenbank `ToolbeltQueueDemo` auswählen und einmal
   [Setup.sql](../Examples/Setup.sql) ausführen. Es erstellt die synthetische
   Tabelle `dbo.QueueGuideEffect`, den Handler `dbo.USP_QueueGuideHandler`,
   den Work Type `demo.queue-guide` und ENQUEUE/CLAIM-Policies für den aktuellen
   Datenbankbenutzer. Bestehende gleichnamige Objekte werden nicht überschrieben.
2. [WorkQueue.sql](../Examples/WorkQueue.sql) öffnen. Oben
   `@Scenario='success'` belassen und den gesamten Batch ausführen.
3. Die erste Einreichung zeigt `WasCreated=1`, die identische Wiederholung
   `WasCreated=0` und dieselbe `WorkItemId`. Danach sind `Status=COMPLETED`
   und `BusinessEffects=1` zu erwarten.
4. Andere Szenarien jeweils als vollständigen Batch ausführen. Jeder Lauf
   erzeugt einen neuen synthetischen Fachschlüssel. Ein vollständig beendeter
   Lauf kann wiederholt werden; bei offener Arbeit bricht der Preflight ab.

| `@Scenario` | Gezeigter Ablauf | Erwartetes Endergebnis |
|---|---|---|
| `success` | Enqueue → Claim → Heartbeat → Handler und Complete in einer Transaktion | `COMPLETED`, Generation 1, ein fachlicher Effekt |
| `retry` | Erster Claim → expliziter Retry → ein Sekunden-Backoff → neuer Claim | `COMPLETED`, Generation 2, Zyklus 1, ein Effekt |
| `dead-letter` | `MaxAttempts=1`, Retrywunsch → Dead Letter → bewusstes Requeue → neuer Claim | `COMPLETED`, Generation 2, Zyklus 2, ein Effekt |
| `fail` | Aktiven Claim terminal fehlschlagen lassen | `FAILED`, kein Effekt, kein automatischer Retry |
| `recovery` | Fünf-Sekunden-Lease ohne Handlerstart auslaufen lassen → Recovery → neuer Claim | Zunächst `CLAIMED`/`IsLeaseExpired=1`, schließlich `COMPLETED`, `RecoveryCount=1`, ein Effekt |

Die kurzen Verzögerungen dienen ausschließlich dem Lernbeispiel. Keine
Produktionsempfehlung für Retry-Intervalle. Während dieses Beispiels keine
weiteren Aufträge oder Worker in der Demodatenbank starten: Claim und Recovery
haben keinen Work-Type-, Gruppen- oder WorkItemId-Auswahlparameter.

Das Beispiel enthält absichtlich keinen allgemeinen Dispatcher. Es prüft die
erhaltene ID und den Work Type und ruft nur den bekannten Demo-Handler auf.
Ein eigener dauerhafter Worker braucht zusätzlich sichere Handlerauflösung,
unabhängige Heartbeats, Fehlereinordnung und Behandlung unbekannter Ausgänge.
Dafür gibt es den [externen Provider](../../../Workers/ExternalQueue/README.md).

### Resultsets weiterverarbeiten

`@ResultTable=NULL` liefert die API-Ausgabe direkt. Eine vorher angelegte lokale
`#Temp`-Tabelle kann stattdessen durch den ResultTable-Helper passend geformt und
befüllt werden. Bei dynamischer Formänderung nachgelagerte Spaltenzugriffe erst
danach kompilieren, wie im vollständigen Beispiel:

```sql
CREATE TABLE #QueueResult (Placeholder bit);
EXEC toolbelt_core.USP_EnqueueWorkWithPolicy
    @WorkTypeName='demo.queue-guide',
    @PayloadJson=N'{"businessKey":"11111111-1111-4111-8111-111111111111"}',
    @IdempotencyKey='guide-result-table', @ResultTable=N'#QueueResult';
EXEC(N'SELECT WasCreated, WorkItemId, Status FROM #QueueResult;');
DROP TABLE #QueueResult;
```

Dieser separate Aufruf **lässt einen Auftrag in der Queue**. Ihn vor dem
nächsten isolierten Lernlauf durch einen geeigneten Worker abschließen.
`@KeepData=0` ersetzt Zielzeilen, `1` hängt bei kompatibler Form an.
Der Caller benötigt außerdem EXECUTE auf `USP_PrepareResultTable`.
`USP_ScheduleWorkRetry` unterstützt ausschließlich `@ResultTable=NULL`.
Resultsets der APIs sind nicht untereinander austauschbar: Die älteren Status-
USPs liefern ihren festen Vertrag, Policy-Enqueue zusätzlich `WasCreated`
und die erweiterten Statusfelder. Deshalb nicht eine beliebige Tabellenvariable
für alle Aufrufe mit `INSERT EXEC` wiederverwenden.

## Alle öffentlichen Queue-Funktionen

Alle Namen liegen in `toolbelt_core`. Die verlinkten Einzelreferenzen listen
sämtliche Parameter einschließlich Defaults, NULL, Wertebereichen und Hilfe.

| API | Wirkung und sinnvoller Einsatz |
|---|---|
| [USP_EnqueueWork](USP_EnqueueWork.md) | Einfache Einreichung: Gruppe `default`, Priorität 0, `SHARED`, drei Versuche, Backoff 60 bis 3600 Sekunden. Ohne Idempotency Key. |
| [USP_EnqueueWorkWithPolicy](USP_EnqueueWorkWithPolicy.md) | Einreichung mit expliziter Gruppe, Priorität, Modus, Retry-Policy und optionalem Duplikatschutz. Bevorzugter Einstieg, wenn diese Eigenschaften benötigt werden. |
| [USP_EnqueueBarrierWork](USP_EnqueueBarrierWork.md) | Kurzform für `DRAIN_BARRIER`; Gruppe und Priorität bewusst angeben. |
| [USP_ClaimWork](USP_ClaimWork.md) | Atomar null oder einen verfügbaren Auftrag übernehmen; Payload und geheimes Token erhalten. Kein Handlerstart. Im Managedbetrieb gesperrt. |
| [USP_RenewWorkLease](USP_RenewWorkLease.md) | Noch aktive Lease mit aktuellem Token um die ursprünglich gewählte Dauer ab aktueller Serverzeit verlängern. |
| [USP_CompleteWork](USP_CompleteWork.md) | Aktiven eigenen Claim als `COMPLETED` markieren. Fachliches Ergebnis separat speichern. |
| [USP_FailWork](USP_FailWork.md) | Aktiven Claim terminal als `FAILED` markieren, etwa bei dauerhaft ungültiger Arbeit. Kein Retry. |
| [USP_ScheduleWorkRetry](USP_ScheduleWorkRetry.md) | Nach bekanntem fehlgeschlagenem Versuch explizit Retry oder Dead Letter gemäß gespeicherter Policy wählen. |
| [USP_RecoverExpiredWork](USP_RecoverExpiredWork.md) | Explizite Supervisor-Recovery eines begrenzten Batches abgelaufener, nicht verwalteter und nicht gehaltener Claims. |
| [USP_RequeueDeadLetter](USP_RequeueDeadLetter.md) | Nach Fehlerbehebung einen neuen Versuchszyklus desselben Dead-Letter-Items beginnen; optional gegen alte RowVersion schützen. |
| [USP_GetWorkStatus](USP_GetWorkStatus.md) | Eine bekannte eigene WorkItemId nachschlagen. Keine Payload und kein Token. |
| [VW_WorkQueue](VW_WorkQueue.md) | Aufträge nach Status, Gruppe, Fälligkeit und Versuchszählern beobachten. Keine Payload und kein Token. |
| [VW_WorkQueueBarrierBlockers](VW_WorkQueueBarrierBlockers.md) | Erkennen, welche gespeicherten Claim-Generationen eine Barrier noch aufhalten. `IsResolved=1` bedeutet, dass genau diese Generation nicht mehr aktiv geclaimt ist. |

### Zustände und Ownership

| Queuezustand | Bedeutung / nächster regulärer Schritt |
|---|---|
| `QUEUED` | Normale eingereihte Arbeit; Claim möglich, soweit Rechte, Handler und Gruppengates passen |
| `BARRIER_WAIT` | Barrier wartet auf ihre Blocker und die Prioritätsregeln |
| `CLAIMED` | Ein Worker besitzt die Generation; aktive Lease für Heartbeat/Complete/Fail/Retry nötig |
| `RETRY_WAIT` | Retry bereits geplant; vor `NextAttemptAtUtc` kein erneuter Claim |
| `COMPLETED` | Erfolgreich abgeschlossen; kein allgemeiner Wiederöffnen-Aufruf |
| `FAILED` | Terminal fehlgeschlagen; kein automatischer Wechsel zu Retry/Dead Letter |
| `DEAD_LETTER` | Retryzyklus ausgeschöpft; nur ausdrückliches Requeue beginnt einen neuen Zyklus |

Normale fällige `RETRY_WAIT`-Arbeit kann unmittelbar wieder `CLAIMED` werden;
ein beobachtbarer Zwischenschritt `QUEUED` ist nicht erforderlich. Bei Barriers
wird beim erneuten Fälligwerden ein neuer Blocker-Snapshot angelegt.

`ClaimToken` ist eine geheime Berechtigung für genau den aktuellen Claim,
`ClaimGeneration` sein monoton steigender Zähler. Die Lease wird vom SQL Server
berechnet; Standard 300, erlaubt 5 bis 86400 Sekunden. Ab `LeaseUntilUtc`
ist sie abgelaufen. Auch dann kann der alte Handler noch laufen. Weder
Leaseablauf noch eine leere Claimantwort beweisen einen beendeten Handler.

Enqueue (`SHARED`), Complete und Fail dürfen in einer gesunden
Callertransaktion laufen. Claim, Renew, Recovery, Retry, Requeue und
Barrier-Enqueue verlangen eine eigene kurze Transaktion ohne äußere
Callertransaktion. Lange Handler brauchen Heartbeats auf separater Verbindung;
eine Heartbeat-Prozedur im blockierten Handlerbatch hilft dann nicht.

## Retry, Dead Letter und Recovery

Die Policy wird beim Einreihen gespeichert: `MaxAttempts` 1–10 inklusive
Erstversuch, `RetryBaseDelaySeconds` 1–86400 und
`RetryMaxDelaySeconds` mindestens Basis, höchstens 86400. Standard: 3/60/3600.
Backoff: `min(Basis × 2^(CycleAttemptCount−1), Maximum)`, ohne Jitter.
Eine geänderte Anwendungskonfiguration schreibt vorhandene Items nicht um.

Vor einem Retry muss feststehen, dass der alte Versuch beendet ist und der
fachliche Vorgang sicher wiederholt werden kann. Ein Verbindungsfehler beim
Commit lässt dessen Ergebnis möglicherweise unbekannt. Dann erst klären;
nicht aufgrund des Timers erneut ausführen.

Die Szenarien `retry`, `dead-letter` und `recovery` im
[vollständigen Skript](../Examples/WorkQueue.sql) beschaffen ihre IDs und Tokens
aus den tatsächlichen vorherigen Aufrufen. Recovery ist auch unabhängig davon
ein ausdrücklicher Supervisoraufruf:

```sql
-- Nur nach Prüfung der betroffenen Worker/Seiteneffekte ausführen!
-- Wirkt datenbankweit auf bis zu 100 geeignete Claims, nicht nur einen Work Type.
EXEC toolbelt_core.USP_RecoverExpiredWork @MaxItems=100;
```

Erwartet werden null bis 100 Recoveryzeilen mit `RETRY_WAIT` oder
`DEAD_LETTER`, ohne Token/Payload. Maximum des Parameters ist 1000.
Managedclaims und Holds werden nicht über diesen Weg übernommen.

Requeue erhält die `WorkItemId`, den Idempotency Key, Lifetime-Claimzähler und
letzte Fehlerhistorie, erhöht `RetryCycleNumber` und setzt `CycleAttemptCount`
auf 0. Eine Wiederholung des ursprünglichen Enqueue mit demselben Key
öffnet ein terminales Item dagegen nicht neu. JSON wird bei der
Idempotency-Prüfung als Text verglichen; semantisch gleiches, anders
formatiertes JSON ist keine zugesagte Gleichheit.

## Gruppen, Prioritäten und Barriers

`Priority` ist 0–255; größere Werte werden vorgezogen. Bei gleicher Priorität
sortiert der Claimkern nach Einreihzeit beziehungsweise Retryfälligkeit und ID.
Konkurrierende Locks und neue hochpriorisierte Arbeit verhindern eine absolute
FIFO-/Fairnesszusage. `ExecutionGroup` ist ein frei gewählter, nichtleerer,
binär verglichener Name; keine separate Registrierung und kein Workerfilter.

Eine Barrier:

1. speichert beim Enqueue die zu diesem Zeitpunkt `CLAIMED`-Generationen ihrer
   Gruppe; bereits wartende `QUEUED`-Arbeit ist kein solcher Blocker;
2. sperrt neue normale Claims dieser Gruppe, bis die Barrier erledigt ist
   beziehungsweise für einen Retry wieder wartet;
3. wartet auf das Ende der gespeicherten Generationen durch Complete, Fail,
   Retry oder zulässige Recovery; Leaseablauf allein reicht nicht;
4. lässt andere Gruppen weiterlaufen. Laufende Arbeit wird nicht abgebrochen.

Gleichpriorisierte Barriers derselben Gruppe können parallel laufen und werden
gegenseitig nicht als gleichpriorige Barrierblocker aufgenommen. Ungleich
priorisierte Barriers laufen in dieser Gruppe nicht gleichzeitig. Wer eine
streng einzelne exklusive Wartungsoperation benötigt, darf daraus keine
generische globale Exklusivitätsgarantie ableiten.

Ein vollständiger überschaubarer Barrier-Versuch nach `Setup.sql`:

```sql
-- Eigene ansonsten ruhende Demoqueue, Managed aus, keine Callertransaktion.
IF DB_NAME()<>N'ToolbeltQueueDemo' OR @@TRANCOUNT<>0 OR (2 & @@OPTIONS)=2
    THROW 50000,N'Frische Sitzung in der eigenen Demodatenbank erforderlich.',1;
IF EXISTS (SELECT 1 FROM toolbelt_core.VW_WorkQueue
           WHERE Status NOT IN ('COMPLETED','FAILED','DEAD_LETTER'))
    THROW 50000,N'Zuerst vorhandene offene Demoarbeit klären.',1;
CREATE TABLE #Normal (Placeholder bit);
CREATE TABLE #Barrier (Placeholder bit);
CREATE TABLE #ClaimA (Placeholder bit);
CREATE TABLE #ClaimB (Placeholder bit);
DECLARE @Group varchar(128)=CONVERT(varchar(36),NEWID());
DECLARE @A bigint, @B bigint, @NormalId bigint,
        @AToken uniqueidentifier, @BToken uniqueidentifier;
EXEC toolbelt_core.USP_EnqueueWorkWithPolicy
    @WorkTypeName='demo.queue-guide',
    @PayloadJson=N'{"businessKey":"22222222-2222-4222-8222-222222222222"}',
    @ExecutionGroup=@Group, @ResultTable=N'#Normal';
EXEC sys.sp_executesql N'SELECT @Id=WorkItemId FROM #Normal;',
    N'@Id bigint OUTPUT', @Id=@NormalId OUTPUT;
EXEC toolbelt_core.USP_ClaimWork @ResultTable=N'#ClaimA';
EXEC sys.sp_executesql
    N'SELECT @Id=WorkItemId,@Token=ClaimToken FROM #ClaimA;',
    N'@Id bigint OUTPUT,@Token uniqueidentifier OUTPUT', @Id=@A OUTPUT,@Token=@AToken OUTPUT;
IF @A IS NULL OR @A<>@NormalId THROW 50000,N'Unerwarteter Claim; nichts abschließen.',1;
EXEC toolbelt_core.USP_EnqueueBarrierWork
    @WorkTypeName='demo.queue-guide',
    @PayloadJson=N'{"businessKey":"33333333-3333-4333-8333-333333333333"}',
    @ExecutionGroup=@Group, @Priority=20, @ResultTable=N'#Barrier';
EXEC sys.sp_executesql N'SELECT @Id=WorkItemId FROM #Barrier;',
    N'@Id bigint OUTPUT', @Id=@B OUTPUT;
SELECT * FROM toolbelt_core.VW_WorkQueueBarrierBlockers WHERE BarrierWorkItemId=@B;
-- IsResolved=0. Im isolierten Beispiel bleibt dieser zweite Claim leer:
EXEC toolbelt_core.USP_ClaimWork @ResultTable=N'#ClaimB';
EXEC(N'SELECT COUNT(*) AS ClaimsBeforeBlockerEnd FROM #ClaimB;');
EXEC(N'IF EXISTS(SELECT 1 FROM #ClaimB) THROW 50000,N''Unerwarteter zweiter Claim.'',1;');
-- Nur Scheduler-Demo: kein fachlicher Handler gestartet; Blocker bewusst beenden.
EXEC toolbelt_core.USP_FailWork @WorkItemId=@A,@ClaimToken=@AToken,@FailureCode='DEMO.BLOCKER_END';
SET @A=NULL;
EXEC toolbelt_core.USP_ClaimWork @ResultTable=N'#ClaimB';
EXEC sys.sp_executesql
    N'SELECT @Id=WorkItemId,@Token=ClaimToken FROM #ClaimB;',
    N'@Id bigint OUTPUT,@Token uniqueidentifier OUTPUT', @Id=@A OUTPUT,@Token=@BToken OUTPUT;
IF @A IS NULL OR @A<>@B THROW 50000,N'Erwartete Barrier nicht beansprucht.',1;
EXEC toolbelt_core.USP_FailWork @WorkItemId=@B,@ClaimToken=@BToken,@FailureCode='DEMO.BARRIER_END';
SELECT * FROM toolbelt_core.VW_WorkQueueBarrierBlockers WHERE BarrierWorkItemId=@B;
DROP TABLE #ClaimB;
DROP TABLE #ClaimA;
DROP TABLE #Barrier;
DROP TABLE #Normal;
```

Erwartung: erst kein zweiter Claim, nach Blockerende genau die Barrier;
abschließend beide Items absichtlich `FAILED`, Blocker `IsResolved=1`.
Dieses Schedulerbeispiel erzeugt keine fachlichen Effekte. Barriers sind
insbesondere kein „warte, bis alle bisher eingereihten Jobs erledigt sind“.

## Work Types und Berechtigungen

| Katalogfunktion | Wann / Wirkung |
|---|---|
| [RegisterWorkType](../../toolbelt.core.work-type/Documentation/USP_RegisterWorkType.md) | Vorhandenen Handler registrieren. Exakte Wiederholung idempotent; Änderung nur mit `AllowUpdate=1`, Reaktivierung mit `Reactivate=1`; optional RowVersion prüfen. |
| [ResolveWorkType](../../toolbelt.core.work-type/Documentation/USP_ResolveWorkType.md) | Registrierung/Handler prüfen, vor Ausführung mit `RequiredPermission='CLAIM'`; `SuppressResult=1` für reine Prüfung. Führt nicht selbst aus. |
| [DisableWorkType](../../toolbelt.core.work-type/Documentation/USP_DisableWorkType.md) | Neue Einreihung/Claims dieses Typs sperren; bestehende Ausführung wird dadurch nicht gestoppt. |
| [RemoveWorkType](../../toolbelt.core.work-type/Documentation/USP_RemoveWorkType.md) | Bewusst deaktivierte Registrierung mit `AllowDelete=1` entfernen; bestehende Referenzen/Queuehistorie können das verhindern. Kein Queue-Purge. |
| [SetWorkTypePermission](../../toolbelt.core.work-type/Documentation/USP_SetWorkTypePermission.md) | Explizite ALLOW/DENY/REMOVE-Policy je vorhandenem DBprincipal und Aktion verwalten. |
| [VW_WorkTypes](../../toolbelt.core.work-type/Documentation/VW_WorkTypes.md) | Namen, Handler, ParameterMode, Aktivzustand und RowVersion nachschlagen. |

`NONE` bedeutet Handler ohne Payload, `JSON_PAYLOAD` einen JSON-Objekttext bis
65536 UTF-16-Bytes, kein Array/Skalar. Die benötigten Felder prüft der Handler;
`PayloadContractJson` ist deklarative Beschreibung, kein ausgeführtes Schema.
Namen wie `demo.queue-guide` sind kanonisch klein geschrieben (3–128 Zeichen;
Details in RegisterWorkType). Keine Handlernamen oder SQL-Befehle aus Payload
zusammenbauen.

**Zwei Rechteebenen sind erforderlich:**

| Rolle | SQL-Rechte / zusätzliche Work-Type-Policy |
|---|---|
| Producer | EXECUTE auf benötigter Enqueue-USP plus `ENQUEUE=ALLOW`; das einfache `USP_EnqueueWork` braucht zusätzlich Handler-Metadatensicht, etwa gezieltes VIEW DEFINITION |
| Worker | EXECUTE auf benötigten Queue-/Resolver-/Provider-APIs und Handler plus `CLAIM=ALLOW` |
| Statusleser | SELECT auf jeweiliger View beziehungsweise EXECUTE auf GetWorkStatus; keine Token-/Payloadauskunft |
| Policyadministrator | EXECUTE auf SetWorkTypePermission und CONTROL auf der Policytabelle gemäß Referenz; keine Producerrolle |

Zum Beispiel für die **bereits vorhandene** Datenbankrolle `ContosoProducer`:

```sql
EXEC toolbelt_core.USP_SetWorkTypePermission
    @WorkTypeName='demo.queue-guide', @Principal=N'ContosoProducer',
    @PermissionName='ENQUEUE', @PermissionState='ALLOW';
```

`DENY` überstimmt passende `ALLOW`s aus dem Datenbanktoken einschließlich
Rollen. `REMOVE` entfernt nur diese Zuordnung. Ohne gültiges ALLOW wird auch
dbo abgewiesen. `EXECUTE_NEW_SESSION` ist die dritte zulässige Aktion und gilt
für den getrennten Second-Session-Provider, nicht als Queue-CLAIM-Ersatz.
Policy ist an Work-Type-RowVersion und Principalidentität gebunden; nach
Registrierungsänderungen ausdrücklich neu konfigurieren. Kein automatisches
Übernehmen früherer Grants. [Sicherheitsvertrag](../../../Documentation/Architecture/SECURITY_HARDENING_2026_10.md).

## Workerbetrieb

Der [Worker-Leitfaden](../../../Workers/ExternalQueue/USAGE.md) zeigt:

- einen begrenzten PowerShell-Lauf mit zugelassenen Handlern;
- explizite Retryzulassung und Interpretation der Abschlusszähler;
- Managedbetrieb mit globaler Parallelität und Kapazität je Worker;
- Pause gegenüber Drain gegenüber Stop/Hold;
- Reconciliation ungeklärter Ergebnisse und bewusste Wiederfreigabe.

## Status und Fehlerklärung

```sql
SELECT Status, COUNT_BIG(*) AS Items
FROM toolbelt_core.VW_WorkQueue GROUP BY Status;
SELECT WorkItemId, WorkTypeName, Status, ExecutionGroup, Priority,
       ClaimGeneration, LeaseUntilUtc, IsLeaseExpired, NextAttemptAtUtc,
       CycleAttemptCount, MaxAttempts, LastErrorCode
FROM toolbelt_core.VW_WorkQueue
WHERE Status NOT IN ('COMPLETED','FAILED') ORDER BY WorkItemId;
EXEC toolbelt_core.USP_EnqueueWorkWithPolicy @Hilfe=1;
```

Die Statusabfragen verwenden bewusst keine Dirty Reads: Queuezustände,
Blocker und Versionen sollen aus committed Daten beurteilt werden. Ein
`WITH (NOLOCK)` eignet sich nicht als Grundlage für Claim-/Recoveryentscheidungen.

| Beobachtung | Bedeutung / nächster Schritt |
|---|---|
| Auftrag bleibt `QUEUED` | Worker gestartet? Work Type aktiv? Handler vorhanden/ausführbar? CLAIM-Policy gültig? Gruppe durch Barrier oder Managed-Hold blockiert? |
| Claim liefert null Zeilen | Aktuell kein für diesen Caller beanspruchbares Item; nicht automatisch „Queue leer“ |
| 51998 / 51596 | ENQUEUE- bzw. geforderte Work-Type-Autorität fehlt; aktuelle Registrierung und Policy prüfen |
| 51902 trotz vorhandenem Handler | Beim einfachen Enqueue fehlt möglicherweise Metadatensicht |
| 51972 | Idempotency Key wird mit anderer Payload/Policy wiederverwendet; ursprünglichen Auftrag prüfen |
| 51910 / 51960 / 51993 / 51997 | Aufruf verlangt eine Session ohne Callertransaktion; bestehenden Geschäftsvorgang nicht blind committen/rollbacken |
| Lease abgelaufen, Complete abgewiesen | Altes Token nicht mehr zur Disposition verwenden; Workerwirkung klären, danach gegebenenfalls explizite Recovery |
| Barrier bleibt stehen | Blockerview lesen; abgelaufene, noch `CLAIMED`-Generation blockiert weiterhin; auch Holds beachten |
| 51989 | ScheduleWorkRetry unterstützt kein ResultTable-Routing |
| 54200 / 54201 | Managedgate/geschützte Disposition betroffen; den Managedpfad verwenden, keine interne Tabelle ändern |

Payloads, Tokens und reale Fehlermeldungen privat halten. `FailureMessage`
wird nicht automatisch bereinigt; nur bereits bereinigten Text übergeben.
`@Debug` ersetzt keine fachliche Auswertung; die konkrete Unterstützung steht
in der Objektseite, `@Hilfe=1` liest den Vertrag ohne fachliche Mutation.

## Bereinigung und Wartung

Die Beispiele lassen die synthetische Queuehistorie und Fachtabelle zur
Inspektion bestehen. Es gibt keine öffentliche allgemeine Purge-API.
Nach dem Lernlauf alle Demo-Worker beenden, SSMS-Verbindungen zur Demo schließen
und ausschließlich die dafür neu angelegte `ToolbeltQueueDemo` nach eigener
Eigentumsprüfung entfernen. Keine interne Queue-Tabelle leeren, keine fremde
Datenbank löschen und keinen laufenden Worker durch KILL „bereinigen“.

In einer echten Installation vor Upgrade/Repeat/Uninstall die
[Lifecyclegrenzen](../README.md) prüfen: aktive Claims, Managedreservations,
Holds und Consumer können Wartung verhindern. Historische Versionen haben
unterschiedliche Upgradevoraussetzungen. Die Anleitungen ersetzen weder
Backups noch den zur installierten Version passenden Migrationsvertrag.

Die [ältere gemeinsame Objektreferenz](WORK_QUEUE_OBJECTS.md) ist bytegenau
an historische Release-Nachweise gebunden und bleibt deshalb unverändert.
Ihr Zustandsdiagramm und ihre frühen Managed-Nachweisangaben beschreiben
nicht durchgehend den aktuellen Stand. Für die aktuelle Anwendung dienen
dieser Leitfaden, die oben verlinkten Einzelparameterreferenzen und die
Nachweisabgrenzung in der Modul-README.

Technische Vertiefung: [Claim-/Schedulermechanik](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#queue)
und [SQL-Quellen](../Source).
