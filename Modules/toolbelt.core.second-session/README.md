# Second Session

## Status

`toolbelt.core.second-session` Version `1.1.0` ist implementiert. Der Loopback-RPC-Provider ist auf SQL Server 2025 Linux technisch validiert; die vollständige Modulmatrix wird getrennt nachgeführt.

Die manuelle Windows-Validierung über `System.Data.SqlClient` war am 2026-08-04 auf SQL Server 2025 erfolgreich; sie umfasste lokale und zentrale Bereitstellung, den Collation-übergreifenden Abgleich mit `master.sys.servers`, Provider-Probe, Contract-, Concurrency-, Central- und Lifecycle-Tests sowie geschützten und vollständigen Uninstall.

## Zweck

Das Modul führt einen registrierten Work Type synchron in einer getrennten SQL-Server-Session aus. Dadurch kann ein Remote-Commit einen späteren Rollback oder einen bereits uncommittable Zustand der Caller-Transaktion überleben.

Die öffentliche Oberfläche akzeptiert ausschließlich einen Namen aus `toolbelt.core.work-type` und optional eine JSON-Objekt-Payload. Raw SQL, Batch-Text und frei zusammengesetzte Commands sind ausgeschlossen.

## Providervertrag

Der Linked Server wird administrativ außerhalb des Moduls angelegt. Er muss:

- auf dieselbe SQL-Server-Instanz zurückführen;
- `rpc out = true` verwenden;
- `remote proc transaction promotion = false` verwenden;
- ein explizit administriertes Login-Mapping besitzen.

Das Modul speichert nur den Linked-Server-Namen. Credentials und Login-Mappings werden weder erzeugt noch gespeichert oder entfernt.

## Work-Type-Signaturen

- `NONE`: Handler ohne Parameter.
- `JSON_PAYLOAD`: exakt `@PayloadJson nvarchar(max)` als einziger Parameter.

Handler-Resultsets werden mit `WITH RESULT SETS NONE` abgelehnt. Der Remote-Dispatcher führt den Handler in einer eigenen Transaktion aus und überträgt Execution-ID, Correlation-ID, Actor und Tenant in den Remote-`SESSION_CONTEXT`.

## Uncommittable Caller

Die Standardausgabe ist auch bei `XACT_STATE() = -1` zulässig, weil die lokale Procedure nur liest und den nicht promovierten RPC ausführt. `@ResultTable` wird in diesem Zustand abgelehnt, da lokale Tabellenänderungen den Vertrag verletzen würden.

Provider-Spike-Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30703841095

Version `1.1.0` ergänzt `@SuppressResult = 1` für erfolgreiche Infrastrukturaufrufe ohne lokales Resultset. Die Option ist insbesondere für rollback-unabhängige Side-Effect-Handler vorgesehen und kann nicht mit `@ResultTable` kombiniert werden.

Evidenz Version `1.1.0`: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31018284410
