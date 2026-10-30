# toolbelt_binary.TVF_LeftShiftBigInt

Führt einen logischen Left Shift auf dem 64-Bit-Muster eines `bigint` aus.

```sql
SELECT Value
FROM toolbelt_binary.TVF_LeftShiftBigInt(12345, 5);
```

`@ShiftAmount bigint` darf negativ sein; dann wird nach rechts verschoben.
Ein Betrag ab 64 liefert `0`. Freie Bits werden mit null gefüllt und Bits
außerhalb der 64 Stellen verworfen. `NULL` wird weitergegeben.

Das Resultset besitzt genau `Value bigint`.

Details:
[BIT_OPERATIONS_MODULE_DESIGN.md](../../../Documentation/Architecture/BIT_OPERATIONS_MODULE_DESIGN.md).

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@ShiftAmount` | `bigint` | `kein Default` | Input | Anzahl der Bitpositionen der Verschiebung. |

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_LeftShiftBigInt.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
