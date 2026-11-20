---
name: "toolbelt-toolbelt-toolbelt-conversion-tvf-integertobase"
description: "Codiert einen bigint-Wert in einem frei festgelegten Zahlensystem."
skill_format_version: "1.0"
module_id: "toolbelt.conversion.integer-base"
schema_name: "toolbelt_conversion"
object_name: "TVF_IntegerToBase"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Value", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "SQL-bigint im gesamten Bereich -9223372036854775808..9223372036854775807; negative Werte erhalten ein führendes -. 0 wird als erstes Alphabetzeichen ausgegeben. NULL ergibt NULL."}, {"name": "@Alphabet", "sql_type": "varchar(93)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "2..93 verschiedene einbyteige ASCII-Zeichen aus Codes 33..126, ohne Minuszeichen -. Reihenfolge definiert die Ziffernwerte ab 0; das erste Zeichen ist die Nullziffer. Binärer, case-sensitiver Vergleich; keine Duplikate oder Leerzeichen. NULL/ungültiges Alphabet ergibt NULL."}]
source_paths: ["Modules/toolbelt.conversion.integer-base/Source/TVF_IntegerToBase.sql"]
review_status: "verified"
source_module_version: "1.1.0"
---

# TVF_IntegerToBase

## Zweck und Einsatzfälle

Codiert einen bigint-Wert in einem frei festgelegten Zahlensystem. Hexadezimal ist ein gewähltes Alphabet wie 0123456789ABCDEF, kein eigener Binär-/0x-Parser. Für APPLY-basierte Verarbeitung und mengenorientierte Aufrufe.

## Voraussetzungen

SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. Modul installiert; reine T-SQL-Funktionen ohne CLR, externe Datenquelle oder Systemkatalogabfrage. Beide Argumente positionsbezogen übergeben. Keine SQL-Defaults.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@Value` | `bigint` | kein Default | SQL-bigint im gesamten Bereich -9223372036854775808..9223372036854775807; negative Werte erhalten ein führendes -. 0 wird als erstes Alphabetzeichen ausgegeben. NULL ergibt NULL. |
| `@Alphabet` | `varchar(93)` | kein Default | 2..93 verschiedene einbyteige ASCII-Zeichen aus Codes 33..126, ohne Minuszeichen -. Reihenfolge definiert die Ziffernwerte ab 0; das erste Zeichen ist die Nullziffer. Binärer, case-sensitiver Vergleich; keine Duplikate oder Leerzeichen. NULL/ungültiges Alphabet ergibt NULL. |

## Ergebnisse

Genau eine Zeile mit EncodedValue varchar(65). NULL bei NULL-Wert oder ungültigem Alphabet. 0 ergibt die erste Alphabetziffer. Negative Werte erhalten das feste Minuszeichen; der gesamte bigint-Bereich einschließlich -9223372036854775808 ist vorgesehen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_conversion.TVF_IntegerToBase(255,'0123456789ABCDEF');
-- FF
```

## Rechte

Vorhandenes SELECT für SELECT-Aufrufe; REFERENCES für entsprechende Referenzverwendungen. Keine Rechtevergabe oder Änderung der Ausführungsidentität. Cross-Database-Zuordnung bleibt beim Caller.

## Ressourcenbedarf

Alphabetprüfung auf höchstens 93 Positionen einschließlich binärer Eindeutigkeitsprüfung. Der relationale Kern nutzt eine rekursive CTE: höchstens 64 Ziffernschritte im kleinsten zulässigen Zahlensystem. decimal(38,0) hält Betrag und Zwischenwerte; wiederholte Division/Modulo erzeugt die Ziffern. Kein unbeschränktes Streaming; skalare Wrapper rufen die gleiche TVF auf.

## Nebenwirkungen

Rein lesend ohne Tabellen-, Datei-, Netzwerk-, Trust- oder Konfigurationsänderung. Keine Änderung von Caller-Transaktionen oder Daten.

## Fehlerbehandlung

Fachlich ungültige gebundene Argumente werden als NULL abgebildet. Nicht vorgesehene Engine-/Typbindungsfehler und vom Caller zu eng gewählte Rekursionsgrenzen bleiben Fehler. Kein Retry und kein automatischer Wechsel des Alphabets.

## Aussagegrenzen

ASCII-Alphabet mit Basis 2..93, feste Reihenfolge und binär verschiedener Ziffernidentität. Minus ist ausschließlich Vorzeichen, nicht Alphabetziffer. Ein Pluszeichen ist kein zusätzlich akzeptiertes Vorzeichen; es kann jedoch reguläre Ziffer sein, wenn im gewählten Alphabet enthalten. Keine Trimmung, keine Gruppierungszeichen und kein implizites 0x-Präfix. Decoder verlangt die kanonische Darstellung: nur die einzelne Nullziffer für 0, keine führenden Nullziffern und kein negatives Null. Vorzeichenabhängige Grenzwerte sind 9223372036854775807 bzw. Betrag 9223372036854775808. Der Vertrag betrifft gebundene SQL-Parameter; vor der Bindung konvertierte oder gekürzte Originaldaten werden nicht nachträglich erkannt.
