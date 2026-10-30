# toolbelt_core.USP_RemoveWorkType

## Zweck

Entfernt ausschließlich einen bereits deaktivierten Work Type. Die explizite Datenverlustfreigabe und optionale RowVersion-Prüfung verhindern versehentliche oder konkurrierende Löschungen.

## Verhalten und Ergebnis

Entfernt genau einen bereits deaktivierten Work Type. Der irreversible Vorgang benötigt ausdrücklich `@AllowDelete = 1`; ein aktiver Eintrag wird mit Fehler `51526` abgelehnt. `@ExpectedRowVersion` schützt vor Lost Updates beziehungsweise dem Löschen einer inzwischen geänderten Registrierung.

Die Procedure verwendet bei vorhandener Caller-Transaktion einen Modul-Savepoint. Ein Fehler rollt nur die eigenen Änderungen zurück. Bei `XACT_STATE() = -1` ist eine Entfernung nicht möglich und wird vor der ersten Mutation abgelehnt. Die entfernte Katalogzeile wird direkt oder über `@ResultTable` zurückgegeben.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [WORK_TYPE_OBJECTS](WORK_TYPE_OBJECTS.md).

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer Name des zu entfernenden Work Types. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionale Optimistic-Concurrency-Prüfung. |
| `@AllowDelete` | `bit` | `0` | Input | Muss für die irreversible Entfernung ausdrücklich 1 sein. |
| `@ResultTable` | `sysname` | `NULL` | Input | Optionale lokale Temp-Tabelle für die entfernte Katalogzeile. |
| `@KeepData` | `bit` | `0` | Input | 0 = Ergebnis ersetzen, 1 = an vorhandene kompatible Ergebnisdaten anhängen. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

## Voraussetzungen für den Aufruf

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_RemoveWorkType @WorkTypeName='demo.noop', @AllowDelete=1;
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_RemoveWorkType @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_RemoveWorkType.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
