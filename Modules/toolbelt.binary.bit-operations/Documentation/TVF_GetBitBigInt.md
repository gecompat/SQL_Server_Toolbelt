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
