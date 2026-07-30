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
