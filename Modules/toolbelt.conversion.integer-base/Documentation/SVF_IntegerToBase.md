# toolbelt_conversion.SVF_IntegerToBase

Codiert `@Value bigint` mit `@Alphabet varchar(93)` und liefert
`varchar(65)`. Basis und Ziffernzuordnung ergeben sich aus dem Alphabet; das
erste Zeichen steht für Null.

Die SVF ist die skalare Convenience-API zu
[`TVF_IntegerToBase`](./TVF_IntegerToBase.md). Für Mengenaufrufe ist die
inline TVF mit `CROSS APPLY` oder `OUTER APPLY` zu bevorzugen.

Ungültige oder `NULL`-Alphabete und `NULL`-Werte liefern `NULL`. Ein Alphabet
muss 2 bis 93 binär eindeutige Zeichen aus ASCII `!` bis `~` enthalten; `-`
ist ausgeschlossen. Negative Werte erhalten ein führendes `-`.

```sql
SELECT toolbelt_conversion.SVF_IntegerToBase
(
    -255,
    '0123456789ABCDEF'
); -- -FF
```

Aktuelle Evidenz:
https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377860

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | Zu verarbeitender Wert im ausgewiesenen SQL-Typ. |
| `@Alphabet` | `varchar(93)` | `kein Default` | Input | 2–93 binär eindeutige ASCII-Zeichen; Minus ist für das Vorzeichen reserviert. |

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#zahlensysteme).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/SVF_IntegerToBase.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
