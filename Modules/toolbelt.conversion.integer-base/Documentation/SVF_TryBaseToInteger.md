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

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EncodedValue` | `varchar(65)` | `kein Default` | Input | Zahlentext aus dem angegebenen Alphabet, höchstens 65 varchar-Bytes; optional genau ein führendes - als Vorzeichen. Keine führenden Nullziffern bei mehrstelligen Werten, kein negatives Null und keine Leerzeichen-Normalisierung. Alle Zeichen müssen Alphabetziffern sein; Betrag muss in bigint passen. Leer, NULL, ungültige Lexik oder Überlauf ergibt NULL. |
| `@Alphabet` | `varchar(93)` | `kein Default` | Input | 2..93 verschiedene einbyteige ASCII-Zeichen aus Codes 33..126, ohne Minuszeichen -. Reihenfolge definiert die Ziffernwerte ab 0; das erste Zeichen ist die Nullziffer. Binärer, case-sensitiver Vergleich; keine Duplikate oder Leerzeichen. NULL/ungültiges Alphabet ergibt NULL. |
<!-- API_PARAMETERS:END -->

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#zahlensysteme).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/SVF_TryBaseToInteger.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
