# toolbelt_conversion.TVF_Base64Decode

**Typ:** Inline Table-valued Function

**Status:** `implemented`

## Zweck und Vertrag

Decodiert `@Value varchar(max)` aus Standard-Base64 oder Base64URL und liefert
immer genau eine Zeile mit `DecodedValue varbinary(max)`. `NULL` ergibt eine
Zeile mit `NULL`.

Fehlendes Padding wird ergänzt. Ausschließlich Space, Tab, CR und LF werden
ignoriert. Ungültige Zeichen, Längen oder Paddingformen erzeugen unverändert
einen SQL-Enginefehler des XML-Providers; Eingabewerte werden nicht in eigene
Fehlermeldungen übernommen.

## Mengenorientierte Verwendung

```sql
SELECT
      source.ItemOrdinal
    , decoded.DecodedValue
FROM
(
    VALUES (1, CONVERT(varchar(max), 'yv7K_g'))
) AS source(ItemOrdinal, EncodedValue)
OUTER APPLY
    toolbelt_conversion.TVF_Base64Decode(source.EncodedValue) AS decoded;
```

Die inline TVF ist der kanonische relationale Kern. Die SVF bleibt für
skalare Einzelaufrufe erhalten.

## Grenzen

Der ASCII-Vertrag wird mit `Latin1_General_100_BIN2` geprüft. Große LOBs
werden synchron materialisiert. Physische SQL-Server-2019-/2022- und
Windows-Läufe bleiben bis zur Releasevalidierung `not executed`.
