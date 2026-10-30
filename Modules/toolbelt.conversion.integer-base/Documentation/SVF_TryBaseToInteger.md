# toolbelt_conversion.SVF_TryBaseToInteger

Die SVF ist die skalare Convenience-API zu
[`TVF_TryBaseToInteger`](./TVF_TryBaseToInteger.md). Für Mengenaufrufe ist
die inline TVF mit `CROSS APPLY` oder `OUTER APPLY` zu bevorzugen.

Decodiert `@EncodedValue varchar(65)` mit `@Alphabet varchar(93)` in
`bigint`. Ungültige Eingabe, ungültiges Alphabet, nicht kanonische Darstellung,
Overflow und `NULL` liefern `NULL`.

Die Decodierung ist strikt: Ein zusätzliches positives Vorzeichen, Whitespace,
Präfixe, führende Nullzeichen und `-0` werden nicht akzeptiert. `+` ist hingegen
eine reguläre Ziffer des gewählten Alphabets; mit dem Dezimalalphabet bleibt
`+1` ungültig. Alphabet und Eingabe werden binär verglichen.

```sql
SELECT toolbelt_conversion.SVF_TryBaseToInteger
(
    '-FF',
    '0123456789ABCDEF'
); -- -255
```

Aktuelle Evidenz:
https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377860

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@EncodedValue` | `varchar(65)` | `kein Default` | Input | Zahlentext im gewählten Alphabet. |
| `@Alphabet` | `varchar(93)` | `kein Default` | Input | 2–93 binär eindeutige ASCII-Zeichen; Minus ist für das Vorzeichen reserviert. |

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#zahlensysteme).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/SVF_TryBaseToInteger.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
