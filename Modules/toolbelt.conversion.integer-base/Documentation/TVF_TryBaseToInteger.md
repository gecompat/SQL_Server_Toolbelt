# toolbelt_conversion.TVF_TryBaseToInteger

**Typ:** Inline Table-valued Function

Decodiert `@EncodedValue varchar(65)` mit `@Alphabet varchar(93)` und liefert
genau eine Zeile mit `DecodedValue bigint`. Ungültige Alphabete, nicht
kanonische Darstellungen, unbekannte Zeichen, `NULL` oder Overflow ergeben
eine Zeile mit `NULL`.

Führende Nullzeichen, `+`, `-0`, Whitespace, Präfixe und Gruppierungszeichen
werden abgelehnt. Groß- und Kleinschreibung bleiben durch den binären
Vergleich verschieden.

```sql
SELECT source.EncodedValue, decoded.DecodedValue
FROM (VALUES ('FF'), ('-FF'), ('invalid')) AS source(EncodedValue)
OUTER APPLY
    toolbelt_conversion.TVF_TryBaseToInteger
    (
          source.EncodedValue
        , '0123456789ABCDEF'
    ) AS decoded;
```

Die inline TVF ist der kanonische relationale Kern; die SVF bleibt als
Convenience-API verfügbar.
