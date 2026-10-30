# toolbelt_binary.TVF_GetBitBigInt

Liest ein Bit aus einem `bigint`-Muster.

```sql
SELECT Value, IsValid, ValidationCode
FROM toolbelt_binary.TVF_GetBitBigInt(4, 2);
```

Offset `0` bezeichnet das Least Significant Bit; `63` bezeichnet das
Vorzeichenbit. Offsets außerhalb `0` bis `63` liefern `Value = NULL`,
`IsValid = 0` und `ValidationCode = 10`.

Erforderliche NULL-Parameter werden mit einem vollständig typisierten
NULL-Resultset weitergegeben.

Details:
[BIT_OPERATIONS_MODULE_DESIGN.md](../../../Documentation/Architecture/BIT_OPERATIONS_MODULE_DESIGN.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | SQL-bigint als vorzeichenbehaftetes 64-Bit-Zweierkomplement (-9223372036854775808 bis 9223372036854775807); negative Werte sind gültige Bitmuster. NULL liefert einen NULL-Wert. |
| `@BitOffset` | `bigint` | `kein Default` | Input | Ganzzahl 0..63, inklusive: 0 ist das niederwertigste Bit, 63 das Vorzeichenbit. Andere Werte ergeben IsValid=0/ValidationCode=10; NULL ergibt NULL in Wert und Validierungsfeldern. |
<!-- API_PARAMETERS:END -->

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_GetBitBigInt.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
