# toolbelt_core.USP_ExecuteWorkTypeInNewSession

## Zweck

Führt einen registrierten Work Type synchron in einer getrennten SQL-Server-Session aus. Raw SQL ist ausgeschlossen; der Provider muss rpc out aktiv und Remote-Transaction-Promotion deaktiviert haben.

## Verhalten und Ergebnis

Löst den Work Type lokal auf, prüft Providerdrift und übergibt ausschließlich gebundene Parameter an den internen Remote-Dispatcher. Execution- und Correlation-ID werden aus dem aktiven Execution Context übernommen oder deterministisch ergänzt.

Die Ergebniszeile enthält Caller- und Remote-Session-ID, Caller-Transaktionszustand, Context-IDs, Handler-Returncode und Remote-Dauer. Ein Handlerfehler wird nicht in Erfolg umgewandelt.

`@ResultTable` folgt dem allgemeinen USP-Vertrag, ist aber bei `XACT_STATE() = -1` nicht zulässig. Die direkte Standardausgabe bleibt in diesem Zustand verfügbar.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [SECOND_SESSION_OBJECTS](SECOND_SESSION_OBJECTS.md).

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer Name aus toolbelt.core.work-type. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | JSON-Objekt nur für Work Types mit ParameterMode JSON_PAYLOAD. |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | Explizite Execution-ID; sonst aktiver Context oder neue ID. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | Explizite Correlation-ID; sonst aktiver Context oder Execution-ID. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Expliziter Actor; sonst aktiver Context oder ORIGINAL_LOGIN(). |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Optionaler Tenant-Kontext. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale lokale Temp-Tabelle; in uncommittable Transaktionen nicht zulässig. |
| `@KeepData` | `bit` | `0` | Input | 0 = Ergebnis ersetzen, 1 = an vorhandene kompatible Ergebnisdaten anhängen. |
| `@SuppressResult` | `bit` | `0` | Input | Bei 1 wird nach erfolgreicher Ausführung kein Infrastruktur-Resultset ausgegeben; nicht mit @ResultTable kombinierbar. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

## Voraussetzungen für den Aufruf

- Für Second-Session-Ausführung und rollback-unabhängiges Schreiben: administrativ angelegter Loopback-Linked-Server und konfigurierter Provider. Löschen von Events verändert persistente Daten.

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @WorkTypeName='demo.noop';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#zweite-session).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_ExecuteWorkTypeInNewSession.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
