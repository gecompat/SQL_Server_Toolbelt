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

Die inline TVF ist die kompatible relationale Wertfassade über dem begrenzten MSTVF-Statuskern. Für mengenorientierte
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

## Aktueller Sicherheitsvertrag

SC-019: Der kanonische begrenzte MSTVF-Statuskern prüft vor Normalisierung/XML. Encode16 MiB Binary, Decode24 MiB Rohtext einschließlich Whitespace und16 MiB Ergebnis. Neue Statusoberflächen unterscheiden OK, SQL_NULL, INVALID, LIMIT; bestehende TVF-/SVF-Werte bei LIMIT NULL. Syntaxfehler unterhalb der Grenzen bleiben in bisherigen Fassaden. Inlinewrapper über MSTVF; keine bisherige Plan-/Inliningzusage übernehmen.

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varbinary(max)` | `kein Default` | Input | Binärwert varbinary(max), etwa 0xCAFECAFE oder ein vom Client gebundener Bytepuffer; keine Text-Decodierung. Leer (0x) ist gültig. Maximal 16777216 Bytes; darüber Status LIMIT bzw. NULL in der Wertfassade. NULL ergibt SQL_NULL bzw. NULL. |
| `@UrlSafe` | `bit` | `0` | Input | Taxativ für den gebundenen bit-Wert: 0 erzeugt Standard-Base64 mit +, / und Padding = (Default); 1 erzeugt Base64URL mit -, _ und ohne Padding. NULL wird wie 0 behandelt. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#base64).
