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

Löst den Work Type lokal auf, prüft Providerdrift und übergibt ausschließlich gebundene Parameter an den internen Remote-Dispatcher. Execution- und Correlation-ID werden aus dem aktiven Execution Context übernommen oder deterministisch ergänzt.

Die Ergebniszeile enthält Caller- und Remote-Session-ID, Caller-Transaktionszustand, Context-IDs, Handler-Returncode und Remote-Dauer. Ein Handlerfehler wird nicht in Erfolg umgewandelt.

`@ResultTable` folgt dem allgemeinen USP-Vertrag, ist aber bei `XACT_STATE() = -1` nicht zulässig. Die direkte Standardausgabe bleibt in diesem Zustand verfügbar.

## Resultsetfreie Infrastrukturaufrufe

`USP_ExecuteWorkTypeInNewSession` unterstützt ab Version `1.1.0` `@SuppressResult = 1`. Der Remote-Handler und dessen Returncode werden vollständig ausgeführt und geprüft; lediglich das lokale Infrastruktur-Resultset entfällt. `@SuppressResult` und `@ResultTable` schließen einander aus.

Die internen `USP_DispatchWorkType`- und `USP_SecondSessionProbe`-Hilfen
beschreiben ihre OUTPUT-Werte und den fehlenden fachlichen Resultset-Vertrag.
`@Hilfe = 1` wird vor Remote-Session- oder Datenbankabfragen ausgewertet und
startet keinen Handler.

Der Dispatcher akzeptiert JSON-Handler grundsätzlich nur mit genau einem
`@PayloadJson nvarchar(max)`-Eingabeparameter. Eine eng gebundene Ausnahme gilt
für den registrierten `toolbelt.event-log.write`-Handler: Bei passender
Event-Log-Modulidentität und exakt `@PayloadJson` plus technischem
`@Hilfe bit` führt der Dispatcher den Handler mit `@Hilfe = 0` aus. Andere
Work Types und Handler bleiben beim bestehenden Einparametervertrag.
