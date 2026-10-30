# toolbelt_binary.TVF_BitCountBigInt

Zählt die gesetzten Bits im vollständigen 64-Bit-Muster eines `bigint`.

```sql
SELECT Value
FROM toolbelt_binary.TVF_BitCountBigInt(-1);
```

Das Ergebnis ist `64`. Die Funktion konvertiert den Eingang vor dem Zählen
nicht in einen kleineren Integer-Typ. Das Resultset besitzt `Value bigint`;
`NULL` wird weitergegeben.

Details:
[BIT_OPERATIONS_MODULE_DESIGN.md](../../../Documentation/Architecture/BIT_OPERATIONS_MODULE_DESIGN.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | SQL-bigint als vorzeichenbehaftetes 64-Bit-Zweierkomplement (-9223372036854775808 bis 9223372036854775807); negative Werte sind gültige Bitmuster. NULL liefert einen NULL-Wert. Gezählt werden alle 64 Bits, einschließlich des Vorzeichenbits; -1 hat 64 gesetzte Bits. |
<!-- API_PARAMETERS:END -->

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_BitCountBigInt.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
