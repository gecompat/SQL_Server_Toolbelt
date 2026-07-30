# Moduldesign: Bigint Bit Operations

## Entscheidung

`toolbelt.binary.bit-operations` implementiert `TC-2026-007` im freigegebenen
W2a-Scope ausschließlich für `bigint`:

- `TVF_LeftShiftBigInt`;
- `TVF_RightShiftBigInt`;
- `TVF_BitCountBigInt`;
- `TVF_GetBitBigInt`;
- `TVF_SetBitBigInt`.

Die Funktionen sind kanonische Inline TVFs. Scalar UDFs sind in Version 1
nicht erforderlich. `binary(n)` und `varbinary(n)` bleiben ein eigener,
später zu besprechender Provider-Slice.

## Bitvertrag

Das `bigint`-Bitmuster wird als 64-Bit-Zweierkomplement verarbeitet. Für
Berechnungen, die ein vorzeichenloses Zwischenbild benötigen, verwendet der
Kern `decimal(38,0)` im Bereich `0` bis `2^64-1`.

- Shift-Operationen sind logisch und füllen freie Bits mit null.
- Ein negativer Shift kehrt die Richtung um.
- Ein Betrag ab 64 liefert null als numerischen Wert `0`.
- Offset `0` bezeichnet das Least Significant Bit, Offset `63` das
  Vorzeichenbit.
- `BIT_COUNT` zählt bei negativen Werten auch das gesetzte Vorzeichenbit.

## Validation Contract

Shift und Bit Count besitzen für alle typisierten Parameterwerte einen
definierten Vertrag und liefern nur `Value`. `NULL` wird weitergegeben.

`GET_BIT` und `SET_BIT` liefern zusätzlich `IsValid` und `ValidationCode`:

| Code | Bedeutung |
|---:|---|
| `0` | gültig |
| `10` | Bit-Offset liegt nicht zwischen `0` und `63` |
| `11` | Bit-Wert ist weder `0` noch `1` |
| `NULL` | mindestens ein erforderlicher Parameter ist `NULL` |

`TVF_SetBitBigInt` verwendet `@BitValue int = 1`, damit Werte außerhalb
`0`/`1` nicht vor der Vertragsprüfung still nach `bit` konvertiert werden.

## Performance und Alternativen

Die Shift- und Offset-Funktionen verwenden konstante
`decimal(38,0)`-Arithmetik ohne Loop. `BIT_COUNT` zerlegt genau acht Bytes und
wertet diese set-basiert aus. CLR ist für den begrenzten `bigint`-Scope nicht
gerechtfertigt.

Eine generische `varbinary(max)`-Funktion wurde verworfen: Die native
SQL-Server-Familie unterstützt keine LOBs, und ein Binary-Provider benötigt
eigene Längen-, Byte-Reihenfolge- und Benchmarkentscheidungen.

## Quellen

- [Bit manipulation functions](https://learn.microsoft.com/en-us/sql/t-sql/functions/bit-manipulation-functions-overview?view=sql-server-ver17)
- [LEFT_SHIFT](https://learn.microsoft.com/en-us/sql/t-sql/functions/left-shift-transact-sql?view=sql-server-ver17)
- [RIGHT_SHIFT](https://learn.microsoft.com/en-us/sql/t-sql/functions/right-shift-transact-sql?view=sql-server-ver17)
- [BIT_COUNT](https://learn.microsoft.com/en-us/sql/t-sql/functions/bit-count-transact-sql?view=sql-server-ver17)
- [GET_BIT](https://learn.microsoft.com/en-us/sql/t-sql/functions/get-bit-transact-sql?view=sql-server-ver17)
- [SET_BIT](https://learn.microsoft.com/en-us/sql/t-sql/functions/set-bit-transact-sql?view=sql-server-ver17)
