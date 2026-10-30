# toolbelt_binary.TVF_SetBitBigInt

Setzt oder löscht ein Bit in einem `bigint`-Muster.

```sql
SELECT Value, IsValid, ValidationCode
FROM toolbelt_binary.TVF_SetBitBigInt(0, 63, 1);
```

Das Beispiel liefert `-9223372036854775808`. `@BitValue int` akzeptiert
ausschließlich `0` und `1`; der Default ist `1`.

| Validation Code | Bedeutung |
|---:|---|
| `0` | gültig |
| `10` | Offset außerhalb `0` bis `63` |
| `11` | Bit-Wert ist nicht `0` oder `1` |

Details:
[BIT_OPERATIONS_MODULE_DESIGN.md](../../../Documentation/Architecture/BIT_OPERATIONS_MODULE_DESIGN.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | SQL-bigint als vorzeichenbehaftetes 64-Bit-Zweierkomplement (-9223372036854775808 bis 9223372036854775807); negative Werte sind gültige Bitmuster. NULL liefert einen NULL-Wert. |
| `@BitOffset` | `bigint` | `kein Default` | Input | Ganzzahl 0..63, inklusive: 0 ist das niederwertigste Bit, 63 das Vorzeichenbit. Andere Werte ergeben IsValid=0/ValidationCode=10; NULL ergibt NULL in Wert und Validierungsfeldern. |
| `@BitValue` | `int` | `1` | Input | Taxativ: 0 löscht das ausgewählte Bit; 1 setzt es (Default). Andere int-Werte ergeben IsValid=0/ValidationCode=11, sofern der Offset gültig ist. NULL ergibt NULL in Wert und Validierungsfeldern. |
<!-- API_PARAMETERS:END -->

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_SetBitBigInt.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
