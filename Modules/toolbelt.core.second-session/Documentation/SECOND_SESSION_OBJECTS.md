# Öffentliche Second-Session-Objekte

## Einzelreferenzen

Die folgenden Seiten erläutern die einzelnen Aufrufe mit Parametern und
Beispielen. Die gemeinsamen Fachregeln auf dieser Seite gelten weiterhin.

- [`toolbelt_core.VW_SecondSessionProviders`](VW_SecondSessionProviders.md)
- [`toolbelt_core.USP_ConfigureSecondSessionLoopback`](USP_ConfigureSecondSessionLoopback.md)
- [`toolbelt_core.USP_ExecuteWorkTypeInNewSession`](USP_ExecuteWorkTypeInNewSession.md)

## `VW_SecondSessionProviders`

Zeigt die gespeicherte Providerkonfiguration und die aktuelle Drift gegenüber `master.sys.servers`: Existenz, `rpc out` und Remote-Transaction-Promotion. Der Vergleich des Linked-Server-Namens verwendet explizit eine binäre Collation und bleibt damit bei abweichenden Datenbank- und `master`-Collations funktionsfähig.

## `USP_ConfigureSecondSessionLoopback`

Konfiguriert ausschließlich den Namen eines bereits vorhandenen Loopback-Linked-Servers. Vor dem Speichern werden Serveroptionen und ein echter Remote-Probe geprüft. Der Probe muss dieselbe Datenbank in einer anderen `@@SPID` erreichen.

Die Procedure legt keinen Linked Server, kein Login-Mapping und keine Credentials an. Änderungen können optional mit `@ExpectedRowVersion` gegen Lost Updates geschützt werden.

## `USP_ExecuteWorkTypeInNewSession`

Löst den Work Type lokal auf, prüft Providerdrift und übergibt ausschließlich
gebundene Parameter an den internen Remote-Dispatcher. Explizite IDs haben
Vorrang vor Kontext-IDs; fehlt eine ExecutionId, wird NEWID erzeugt, fehlende
CorrelationId fällt auf die gewählte ExecutionId zurück.

Die Ergebniszeile enthält Caller- und Remote-Session-ID, Caller-Transaktionszustand,
Context-IDs, Handler-Returncode und Remote-Dauer. Geworfene Handler-/SQL-Fehler
werden weitergegeben. Ein nichtzero Handler-Returncode allein wird jedoch nicht
automatisch als Fehler interpretiert oder rollbackt.

`@ResultTable` folgt dem allgemeinen USP-Vertrag, ist aber bei `XACT_STATE() = -1` nicht zulässig. Die direkte Standardausgabe bleibt in diesem Zustand verfügbar.

## Resultsetfreie Infrastrukturaufrufe

`USP_ExecuteWorkTypeInNewSession` unterstützt `@SuppressResult = 1`. Der
Remote-Handler wird ausgeführt; auf 0 geprüft wird der Dispatcher-/Providercode,
nicht automatisch der separate Handlercode. Nur das lokale Infrastrukturresultset
entfällt. `@SuppressResult` und `@ResultTable` schließen einander aus.

Die internen `USP_DispatchWorkType`- und `USP_SecondSessionProbe`-Hilfen
beschreiben ihre OUTPUT-Werte und den fehlenden fachlichen Resultset-Vertrag.
`@Hilfe = 1` wird vor Remote-Session- oder Datenbankabfragen ausgewertet und
startet keinen Handler.

Der Dispatcher akzeptiert JSON-Handler grundsätzlich nur mit genau einem
`@PayloadJson nvarchar(max)`-Eingabeparameter. Eine eng gebundene Ausnahme gilt
für den registrierten `toolbelt.event-log.write`-Handler: Bei passender
kanonischer Work-Type-/Handlernamenskombination und exakt `@PayloadJson` plus technischem
`@Hilfe bit` führt der Dispatcher den Handler mit `@Hilfe = 0` aus. Andere
Work Types und Handler bleiben beim bestehenden Einparametervertrag.

Die vollständigen [kanonischen Skills](../../../Metadata/UsageSkills/README.md)
stehen in der DDL. Hilfe liefert nach dem vorhandenen Standardresultset genau
eine zusätzliche vier-spaltige Skillzeile; beim Dispatcher bleiben OUTPUT-Werte
unverändert. Dies ist keine neue native Hilfeabnahme. Die Konfigurationsprobe
belegt Rückgabewerte und getrennte Session, keine kryptografische Serveridentität.
