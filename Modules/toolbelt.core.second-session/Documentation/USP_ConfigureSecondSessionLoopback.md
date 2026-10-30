# toolbelt_core.USP_ConfigureSecondSessionLoopback

## Zweck

Verknüpft das Modul mit einem bereits administrativ eingerichteten Loopback-Linked-Server. Das Modul legt weder Linked Server noch Login-Mappings oder Credentials an.

## Verhalten und Ergebnis

Konfiguriert ausschließlich den Namen eines bereits vorhandenen Loopback-Linked-Servers. Vor dem Speichern werden Serveroptionen und ein echter Remote-Probe geprüft. Der Probe muss dieselbe Datenbank in einer anderen `@@SPID` erreichen.

Die Procedure legt keinen Linked Server, kein Login-Mapping und keine Credentials an. Änderungen können optional mit `@ExpectedRowVersion` gegen Lost Updates geschützt werden.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [SECOND_SESSION_OBJECTS](SECOND_SESSION_OBJECTS.md).

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@LinkedServerName` | `sysname` | `NULL` | Input | Vorhandener Linked Server mit rpc out und deaktivierter Remote-Transaction-Promotion. |
| `@Enabled` | `bit` | `1` | Input | Aktiviert oder deaktiviert den Provider. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionale Optimistic-Concurrency-Prüfung. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale lokale Temp-Tabelle für die Konfigurationszeile. |
| `@KeepData` | `bit` | `0` | Input | 0 = Ergebnis ersetzen, 1 = an vorhandene kompatible Ergebnisdaten anhängen. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

## Voraussetzungen für den Aufruf

- Für Second-Session-Ausführung und rollback-unabhängiges Schreiben: administrativ angelegter Loopback-Linked-Server und konfigurierter Provider. Löschen von Events verändert persistente Daten.

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @LinkedServerName=N'TBX_LOOPBACK';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_ConfigureSecondSessionLoopback.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
