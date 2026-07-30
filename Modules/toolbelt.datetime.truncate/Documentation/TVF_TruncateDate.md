# toolbelt_datetime.TVF_TruncateDate

Trunkiert einen `date`-Wert nach dem portablen W2a-Vertrag.

```sql
SELECT Value, IsValid, ValidationCode
FROM toolbelt_datetime.TVF_TruncateDate('month', '2026-07-30');
```

## Parameter

| Parameter | Typ | Beschreibung |
|---|---|---|
| `@DatePart` | `varchar(16)` | Jahr, Quartal, Monat, Tag, `week` oder `iso_week`, jeweils einschließlich dokumentierter nativer Aliasse |
| `@Value` | `date` | Eingabedatum |

## Ergebnis

| Spalte | Typ | Beschreibung |
|---|---|---|
| `Value` | `date` | truncierter Wert oder `NULL` |
| `IsValid` | `bit` | `1`, `0` oder bei NULL-Propagation `NULL` |
| `ValidationCode` | `tinyint` | `0`, `10`, `11`, `12` oder `NULL` |

Zeit-Dateparts liefern Code `11`. `week` folgt `@@DATEFIRST`; `iso_week`
beginnt am Montag. Details und Codes stehen im
[Moduldesign](../../../Documentation/Architecture/DATETIME_TRUNCATE_MODULE_DESIGN.md).
