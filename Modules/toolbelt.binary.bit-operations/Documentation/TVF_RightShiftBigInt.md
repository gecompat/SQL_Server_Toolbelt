# toolbelt_binary.TVF_RightShiftBigInt

Führt einen logischen Right Shift auf dem 64-Bit-Muster eines `bigint` aus.

```sql
SELECT Value
FROM toolbelt_binary.TVF_RightShiftBigInt(-1, 1);
```

Das Beispiel liefert `9223372036854775807`, weil der Shift logisch und nicht
arithmetisch ist. Ein negativer Betrag kehrt die Richtung um; Beträge ab 64
liefern `0`. Das Resultset besitzt `Value bigint`.

Die Funktion ist ein Inline-TVF-Wrapper über den gemeinsamen Left-Shift-Kern.

Details:
[BIT_OPERATIONS_MODULE_DESIGN.md](../../../Documentation/Architecture/BIT_OPERATIONS_MODULE_DESIGN.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | SQL-bigint als vorzeichenbehaftetes 64-Bit-Zweierkomplement (-9223372036854775808 bis 9223372036854775807); negative Werte sind gültige Bitmuster. NULL liefert einen NULL-Wert. |
| `@ShiftAmount` | `bigint` | `kein Default` | Input | Ganzzahlige Bitanzahl: 0 lässt das Muster unverändert; 1..63 verschiebt logisch rechts, ohne Vorzeichenerweiterung; -1..-63 kehrt die Richtung um. Beträge ab 64 liefern 0, auch der kleinste bigint. NULL ergibt NULL. |
<!-- API_PARAMETERS:END -->

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_RightShiftBigInt.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
