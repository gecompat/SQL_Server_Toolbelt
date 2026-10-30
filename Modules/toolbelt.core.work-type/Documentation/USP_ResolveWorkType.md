# toolbelt_core.USP_ResolveWorkType

## Zweck

Löst einen registrierten Work Type auf und kann Enabled-, Existenz- und Caller-EXECUTE-Vertrag erzwingen.

## Verhalten und Ergebnis

Löst genau einen Work Type auf. Standardmäßig müssen der Eintrag enabled, die Zielprocedure vorhanden und für den aktuellen Principal ausführbar sein.

Der gemeinsame Vertrag mit weiteren Ergebnis-, Fehler- und Betriebsregeln steht in [WORK_TYPE_OBJECTS](WORK_TYPE_OBJECTS.md).

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Name eines vorhandenen, passenden registrierten Work Types. |
| `@RequireEnabled` | `bit` | `1` | Input | 1 verlangt einen aktiven Work Type. |
| `@RequireExecutableByCaller` | `bit` | `1` | Input | 1 prüft die vorhandene Ausführbarkeit des Handlers. |
| `@RequiredPermission` | `varchar(32)` | `NULL` | Input | Optionale Work-Type-Policyaktion; NULL prüft keine zusätzliche Policy. |
| `@SuppressResult` | `bit` | `0` | Input | 1 prüft ohne Fachresultset; nicht mit ResultTable kombinieren. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL = Resultset; sonst Name einer vorhandenen lokalen #Temp-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | 0 = Ergebnis ersetzen, 1 = an vorhandene kompatible Ergebnisdaten anhängen. |
| `@Debug` | `tinyint` | `0` | Input | Diagnostikstufe; 0 deaktiviert Debug. Siehe Objektvertrag für weitere Stufen. |
| `@Hilfe` | `bit` | `0` | Input | 1 = ausschließlich Hilfe, 0 = fachlicher Aufruf. |

## Voraussetzungen für den Aufruf

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Beispielaufruf

```sql
EXEC toolbelt_core.USP_ResolveWorkType @WorkTypeName='demo.noop';
```

## Hilfe und Fehlerklärung

```sql
EXEC toolbelt_core.USP_ResolveWorkType @Hilfe=1;
```

Die Hilfe beschreibt Parameter, Ergebnis und Fehlervertrag. Bei Abweichungen zuerst die Voraussetzungen und den verlinkten Fachvertrag prüfen.

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_ResolveWorkType.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
