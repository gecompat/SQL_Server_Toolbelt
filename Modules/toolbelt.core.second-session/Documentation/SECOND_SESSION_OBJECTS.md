# Öffentliche Second-Session-Objekte

## `VW_SecondSessionProviders`

Zeigt die gespeicherte Providerkonfiguration und die aktuelle Drift gegenüber `master.sys.servers`: Existenz, `rpc out` und Remote-Transaction-Promotion.

## `USP_ConfigureSecondSessionLoopback`

Konfiguriert ausschließlich den Namen eines bereits vorhandenen Loopback-Linked-Servers. Vor dem Speichern werden Serveroptionen und ein echter Remote-Probe geprüft. Der Probe muss dieselbe Datenbank in einer anderen `@@SPID` erreichen.

Die Procedure legt keinen Linked Server, kein Login-Mapping und keine Credentials an. Änderungen können optional mit `@ExpectedRowVersion` gegen Lost Updates geschützt werden.

## `USP_ExecuteWorkTypeInNewSession`

Löst den Work Type lokal auf, prüft Providerdrift und übergibt ausschließlich gebundene Parameter an den internen Remote-Dispatcher. Execution- und Correlation-ID werden aus dem aktiven Execution Context übernommen oder deterministisch ergänzt.

Die Ergebniszeile enthält Caller- und Remote-Session-ID, Caller-Transaktionszustand, Context-IDs, Handler-Returncode und Remote-Dauer. Ein Handlerfehler wird nicht in Erfolg umgewandelt.

`@ResultTable` folgt dem allgemeinen USP-Vertrag, ist aber bei `XACT_STATE() = -1` nicht zulässig. Die direkte Standardausgabe bleibt in diesem Zustand verfügbar.

## Resultsetfreie Infrastrukturaufrufe

`USP_ExecuteWorkTypeInNewSession` unterstützt ab Version `1.1.0` `@SuppressResult = 1`. Der Remote-Handler und dessen Returncode werden vollständig ausgeführt und geprüft; lediglich das lokale Infrastruktur-Resultset entfällt. `@SuppressResult` und `@ResultTable` schließen einander aus.
