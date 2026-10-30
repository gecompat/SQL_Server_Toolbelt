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

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | SQL-bigint als vorzeichenbehaftetes 64-Bit-Zweierkomplement (-9223372036854775808 bis 9223372036854775807); negative Werte sind gültige Bitmuster. NULL liefert einen NULL-Wert. |
| `@ShiftAmount` | `bigint` | `kein Default` | Input | Ganzzahlige Bitanzahl: 0 lässt das Muster unverändert; 1..63 verschiebt links; -1..-63 kehrt die Richtung um. Beträge ab 64 liefern 0, auch der kleinste bigint. NULL ergibt NULL. |
<!-- API_PARAMETERS:END -->

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_LeftShiftBigInt.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
