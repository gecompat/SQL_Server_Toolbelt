# toolbelt.binary.bit-operations

Portabler `bigint`-Backport der SQL-Server-2022-Bitfunktionen für SQL Server
2019, 2022 und 2025.

## Objekte

| Objekt | Ergebnis |
|---|---|
| `toolbelt_binary.TVF_LeftShiftBigInt` | logischer Left Shift |
| `toolbelt_binary.TVF_RightShiftBigInt` | logischer Right Shift |
| `toolbelt_binary.TVF_BitCountBigInt` | Anzahl gesetzter Bits |
| `toolbelt_binary.TVF_GetBitBigInt` | Bit an Offset 0 bis 63 |
| `toolbelt_binary.TVF_SetBitBigInt` | gesetztes oder gelöschtes Bit |

```sql
SELECT source.FlagId, changed.Value
FROM dbo.SyntheticFlags AS source
CROSS APPLY toolbelt_binary.TVF_SetBitBigInt
            (source.FlagValue, 12, 1) AS changed
WHERE changed.IsValid = 1;
```

Negative Shiftweiten kehren die Richtung um; Beträge ab 64 liefern `0`.
Offset `0` ist das Least Significant Bit. V1 verarbeitet ausschließlich
`bigint`; `binary(n)` und `varbinary(n)` bleiben ein separater Slice.

## Deployment

Aus `Deployment/`:

```text
sqlcmd -S <server> -d <database> -i Deploy.sql -v DeploymentMode=local
```

## Dokumentation

- [Moduldesign](../../Documentation/Architecture/BIT_OPERATIONS_MODULE_DESIGN.md)
- [Contract-Testmatrix](./Tests/BIT_OPERATIONS_CONTRACT_TEST_MATRIX.md)
- [Runtime-Evidenz](./Tests/README.md)
- [W2a-Runtime-Workflow](https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/w2a-portable-runtime.yml)
