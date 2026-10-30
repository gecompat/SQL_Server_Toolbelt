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
SET QUOTED_IDENTIFIER ON;

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

Die inline TVF ist die kompatible relationale Wertfassade über dem begrenzten MSTVF-Statuskern. Die SVF bleibt für
skalare Einzelaufrufe erhalten.

## Grenzen

Der ASCII-Vertrag wird mit `Latin1_General_100_BIN2` geprüft. Der begrenzte
MSTVF-Kern materialisiert die normalisierte Zeichenfolge einmal und übergibt
sie direkt per `sql:variable` an `xs:base64Binary`; er baut kein zusätzliches
XML-Dokument aus dem Base64-Text auf. Das Deployment bindet seine benötigten
SET-Optionen. Alte Plan-/Inlining- und Parallelitätsannahmen sind für den neuen
Statuskern nicht zugesagt. Gezielte Linux-2019-Grenz-/Roundtriptests bestanden;
die vollständige aktuelle Plattformmatrix bleibt offen.

## Aktueller Sicherheitsvertrag

SC-019: Der kanonische begrenzte MSTVF-Statuskern prüft vor Normalisierung/XML. Encode16 MiB Binary, Decode24 MiB Rohtext einschließlich Whitespace und16 MiB Ergebnis. Neue Statusoberflächen unterscheiden OK, SQL_NULL, INVALID, LIMIT; bestehende TVF-/SVF-Werte bei LIMIT NULL. Syntaxfehler unterhalb der Grenzen bleiben in bisherigen Fassaden. Inlinewrapper über MSTVF; keine bisherige Plan-/Inliningzusage übernehmen.

## Vollständiger Eingabevertrag

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varchar(max)` | `kein Default` | Input | ASCII-Base64-Text (A-Z, a-z, 0-9, +, /) oder Base64URL (-, _ statt +, /); beide Alphabete werden normalisiert. Nur Space, Tab, CR und LF werden entfernt. Optionales =-Padding nur am Ende in passender Länge; ohne Padding sind Restlängen 0, 2 oder 3 modulo 4 gültig. Leer/Whitespace-only ergibt leere Bytes. Höchstens 25165824 Rohtextbytes und 16777216 Ergebnisbytes; NULL ergibt SQL_NULL/NULL, Überschreitung LIMIT/NULL. Ungültige Syntax ergibt INVALID im Statuskern, einen Konvertierungsfehler in TVF/SVF-Wertfassaden. |
<!-- API_PARAMETERS:END -->


## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#base64).
