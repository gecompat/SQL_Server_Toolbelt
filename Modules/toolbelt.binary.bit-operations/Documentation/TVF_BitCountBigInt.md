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
