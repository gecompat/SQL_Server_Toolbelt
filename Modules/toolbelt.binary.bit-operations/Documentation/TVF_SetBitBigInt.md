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
