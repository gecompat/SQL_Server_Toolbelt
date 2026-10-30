# toolbelt_core.USP_EnqueueWorkWithPolicy

## Zweck

Reiht je nach ExecutionMode SHARED- oder DRAIN_BARRIER-Arbeit mit unveränderlicher Retry-Policy und optionalem Idempotency Key ein.

## Verhalten und Ergebnis

Das ältere `USP_EnqueueWork` benötigt neben seinem EXECUTE und der expliziten
ENQUEUE-Policy Metadatensicht auf den registrierten Handler, etwa ein enges
VIEW DEFINITION auf genau diese Procedure. Ohne Sicht kann seine
`OBJECT_ID`-Prüfung mit 51902 abbrechen, auch wenn der Handler existiert.
Handler-EXECUTE ist hierfür nicht erforderlich. Policy-/Barrier-Enqueue
haben diese zusätzliche Handler-Metadatenprüfung nicht; Claim verlangt
weiterhin Handler-EXECUTE. Rechte müssen dem tatsächlichen Aufrufpfad entsprechen.

`USP_EnqueueWork` behält den V1-Vertrag und reiht mit Gruppe `default`, Priorität `0`, Modus `SHARED` und der Retry-Policy drei Versuche, 60 Sekunden Basis- sowie 3.600 Sekunden Maximalverzögerung ein. Der erweiterte öffentliche Vertrag `USP_EnqueueWorkWithPolicy` ergänzt Idempotency Key, Priority, ExecutionGroup, Retry-Policy und ExecutionMode. Gruppen und Keys werden binär verglichen; ein Key ist je Work Type eindeutig, solange das Item existiert. Gleiche Payload und Policy liefern das vorhandene Item, Abweichungen werden abgewiesen.

`USP_EnqueueBarrierWork` ist die getrennt berechtigte Kurzform für `DRAIN_BARRIER`. Beim Enqueue speichert sie unter dem Scheduler-Mutex die zugehörigen aktiven Claim-Generationen als Blocker-Snapshot. Die öffentliche Sicht `VW_WorkQueueBarrierBlockers` zeigt diese Blocker ohne Payload oder Claim-Token.

Beide Prozeduren liefern über `@Hilfe = 1` einen eigenen Help-Vertrag mit
Objektname, Parametern, Queue-Resultspalten, Berechtigung und Beispiel.
`USP_EnqueueBarrierWork` dokumentiert `@Priority` als fachlich erforderlich,
obwohl der technische Default `NULL` einen reinen Help-Aufruf ermöglicht.
`USP_EnqueueWorkWithPolicy` und die Barrier-Kurzform unterstützen
`@ResultTable` über `toolbelt.core.result-table`. Die Shape-Änderung, die
Queue-Mutation und das Einfügen der Statuszeile liegen in derselben
Transaktion; ein Fehler rollt die Änderung zum eigenen Transaktionsanfang
oder Savepoint zurück. `@KeepData = 1` erhält bestehende Zielzeilen.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [WORK_QUEUE_OBJECTS](WORK_QUEUE_OBJECTS.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Muss aktiviert und für ENQUEUE autorisiert sein. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | Bei Work-Type-ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD erforderlicher JSON-Objekttext gemäß konkretem Handlervertrag, z.B. N'{"value":1}'. Höchstens 65536 UTF-16-Bytes (64 KiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keine führenden Tabs/CR/LF. Leer/ungültig wird abgewiesen; keine allgemeine automatische Prüfung der deklarativen PayloadContractJson-Felder. |
| `@IdempotencyKey` | `varchar(128)` | `NULL` | Input | Optionaler varchar(128)-Schlüssel innerhalb genau eines Work Types; NULL (Default) deaktiviert Idempotency-Key-Wiederverwendung. Leerer Text ist ein expliziter Schlüssel, kein NULL-Ersatz. Vergleich gemäß binärer SQL-Collation, kein Normalisieren. Solange das Item besteht, liefert dieselbe Payload-/Policykonfiguration das bestehende Item; abweichende Konfiguration wird abgewiesen. Kein Beweis einer Exactly-once-Handlerwirkung. |
| `@Priority` | `tinyint` | `0` | Input | Ganzzahl 0..255 als tinyint, Default 0; höhere Werte werden bevorzugt. Explizites NULL ist unzulässig. Keine Zusage einer global strikt seriellen FIFO-Reihenfolge unter Konkurrenz. |
| `@ExecutionGroup` | `varchar(128)` | `'default'` | Input | Nichtleerer varchar(128)-Gruppenname, binär/case-sensitiv gemäß SQL-Namensvergleich; keine feste Werteliste und keine separate Gruppenregistrierung. NULL/leer/reine Spaces ungültig; keine automatische Normalisierung. Die Gruppe bestimmt den Geltungsbereich der Barriers. Default ist der konkrete Name default. |
| `@MaxAttempts` | `tinyint` | `3` | Input | Ganzzahl 1..10 Versuche pro Retryzyklus einschließlich, Default 3; explizites NULL ist kein Default und unzulässig. Die Policy wird am Item gespeichert und später nicht aus einer geänderten Konfiguration nachgelesen. |
| `@RetryBaseDelaySeconds` | `int` | `60` | Input | Ganzzahl 1..86400 Sekunden einschließlich, Default 60; NULL/0/negativ/zu groß unzulässig. Basis des exponentiellen Retry-Backoffs; muss &lt;= RetryMaxDelaySeconds sein. |
| `@RetryMaxDelaySeconds` | `int` | `3600` | Input | Ganzzahl von RetryBaseDelaySeconds bis 86400 Sekunden einschließlich, Default 3600; NULL oder kleiner als Basis unzulässig. Begrenzt den exponentiellen Backoff; keine Zufallsstreuung. |
| `@ExecutionMode` | `varchar(16)` | `'SHARED'` | Input | Taxativ in kanonischer Schreibweise: SHARED = normale Queuearbeit (Default); DRAIN_BARRIER = gruppengebundene Barrierarbeit mit Blocker-Snapshot und zusätzlichen Schedulerregeln. DRAIN_BARRIER verlangt @@TRANCOUNT=0. Kein automatisches UPPER; NULL/leer/andere Modi unzulässig. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |
<!-- API_PARAMETERS:END -->

## Voraussetzungen für den Aufruf

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Beispielaufruf

```sql
-- Voraussetzung: aktiver, ausführbarer Work Type demo.noop.
EXEC toolbelt_core.USP_EnqueueWorkWithPolicy
 @WorkTypeName='demo.noop', @PayloadJson=NULL, @IdempotencyKey=N'example-1',
 @Priority=10, @ExecutionGroup=N'example-group', @MaxAttempts=3,
 @RetryBaseDelaySeconds=60, @RetryMaxDelaySeconds=3600, @ExecutionMode='SHARED';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_EnqueueWorkWithPolicy @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#queue).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_EnqueueWorkWithPolicy.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
