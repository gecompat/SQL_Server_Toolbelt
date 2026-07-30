# toolbelt_conversion.TVF_Base64Encode

**Typ:** Inline Table-valued Function

**Status:** `implemented`

## Zweck und Vertrag

Codiert `@Value varbinary(max)` als Standard-Base64 oder als ungepaddetes
Base64URL. Die Funktion liefert immer genau eine Zeile mit
`EncodedValue varchar(max)`. `NULL` ergibt eine Zeile mit `NULL`.

`@UrlSafe bit = 0` wählt Standard-Base64. Der Wert `1` ersetzt `+` und `/`
durch `-` und `_` und entfernt das Padding. `NULL` für `@UrlSafe` verhält sich
wie `0`, entsprechend der bestehenden SVF.

## Mengenorientierte Verwendung

```sql
SET QUOTED_IDENTIFIER ON;

SELECT
      source.ItemOrdinal
    , encoded.EncodedValue
FROM
(
    VALUES (1, CONVERT(varbinary(max), 0xCAFECAFE))
) AS source(ItemOrdinal, BinaryValue)
OUTER APPLY
    toolbelt_conversion.TVF_Base64Encode(source.BinaryValue, 1) AS encoded;
```

Die inline TVF ist der kanonische relationale Kern. Für mengenorientierte
Aufrufe ist sie gegenüber `SVF_Base64Encode` zu bevorzugen. Ein
Parallelitätsvorteil wird nur für den konkreten Ausführungsplan bewertet und
nicht pauschal zugesagt.

Wegen der inline expandierten XML-Methode muss in der aufrufenden Sitzung
`QUOTED_IDENTIFIER` eingeschaltet sein. Das Deployment setzt die Option für
die Objekterstellung; der direkte TVF-Aufruf muss sie für seinen eigenen
Batch ebenfalls einschalten.

## Grenzen

Der T-SQL/XML-Provider materialisiert LOB-Werte synchron. Base64 ist keine
Verschlüsselung und kein Integritätsschutz. Physische SQL-Server-2019-/2022-
und Windows-Läufe bleiben bis zur Releasevalidierung `not executed`.
