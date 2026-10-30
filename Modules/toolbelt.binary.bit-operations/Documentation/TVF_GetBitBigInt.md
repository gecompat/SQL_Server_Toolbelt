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

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@BitOffset` | `bigint` | `kein Default` | Input | Nullbasierte Bitposition 0–63. |

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_GetBitBigInt.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
