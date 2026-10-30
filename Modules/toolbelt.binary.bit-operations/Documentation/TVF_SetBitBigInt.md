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

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@BitOffset` | `bigint` | `kein Default` | Input | Nullbasierte Bitposition 0–63. |
| `@BitValue` | `int` | `1` | Input | 0 löscht, 1 setzt das Bit. |

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_SetBitBigInt.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
