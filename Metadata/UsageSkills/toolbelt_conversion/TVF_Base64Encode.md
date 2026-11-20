---
name: "toolbelt-toolbelt-conversion-tvf-base64encode"
description: "Codiert Binärdaten als Base64 oder Base64URL."
skill_format_version: "1.0"
module_id: "toolbelt.conversion.base64"
schema_name: "toolbelt_conversion"
object_name: "TVF_Base64Encode"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Value", "sql_type": "varbinary(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Binärwert varbinary(max), etwa 0xCAFECAFE oder ein vom Client gebundener Bytepuffer; keine Text-Decodierung. Leer (0x) ist gültig. Maximal 16777216 Bytes; darüber Status LIMIT bzw. NULL in der Wertfassade. NULL ergibt SQL_NULL bzw. NULL."}, {"name": "@UrlSafe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ für den gebundenen bit-Wert: 0 erzeugt Standard-Base64 mit +, / und Padding = (Default); 1 erzeugt Base64URL mit -, _ und ohne Padding. NULL wird wie 0 behandelt."}]
source_paths: ["Modules/toolbelt.conversion.base64/Source/TVF_Base64Encode.sql"]
review_status: "verified"
source_module_version: "1.1.0"
---

# TVF_Base64Encode

## Zweck und Einsatzfälle

Binärdaten in eine Base64- oder Base64URL-Wertzeile umwandeln. Für maschinell unterscheidbare NULL-/Limitfälle die öffentliche Statusfunktion verwenden.

## Voraussetzungen

SQL Server 2019 oder neuer; Aufruf als Tabellenfunktion. Beide Argumentpositionen angeben; für einen deklarierten Default ist in einem Funktionsaufruf DEFAULT zu verwenden.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varbinary(max)` | `kein Default` | Input | Binärwert varbinary(max), etwa 0xCAFECAFE oder ein vom Client gebundener Bytepuffer; keine Text-Decodierung. Leer (0x) ist gültig. Maximal 16777216 Bytes; darüber Status LIMIT bzw. NULL in der Wertfassade. NULL ergibt SQL_NULL bzw. NULL. |
| `@UrlSafe` | `bit` | `0` | Input | Taxativ für den gebundenen bit-Wert: 0 erzeugt Standard-Base64 mit +, / und Padding = (Default); 1 erzeugt Base64URL mit -, _ und ohne Padding. NULL wird wie 0 behandelt. |

## Ergebnisse

Genau eine Zeile mit EncodedValue varchar(max). SQL-NULL-Eingabe ergibt NULL; leere Binärdaten ergeben einen leeren Text. Über 16777216 Eingabebytes wird NULL geliefert. Die Statusfunktion unterscheidet SQL_NULL, LIMIT und OK.

## Aufrufbeispiele

```sql
SELECT EncodedValue
FROM toolbelt_conversion.TVF_Base64Encode(0xCAFECAFE,0);
-- Erwartet: yv7K/g==
```

## Rechte

Vorhandenes SELECT auf der Funktion; keine automatische Rechtevergabe. Cross-Database-Zuordnung muss im gewählten Aufrufkontext bestehen.

## Ressourcenbedarf

Maximal 16777216 Eingabebytes. Base64 vergrößert die Ausgabe typischerweise auf vier Zeichen je drei Eingabebytes. Kanonischer begrenzter Statuskern; keine pauschale Inline-/Parallelitätsgarantie.

## Nebenwirkungen

Read-only; keine Tabellenänderung, Datei- oder Netzwerkoperation.

## Fehlerbehandlung

Die Wertfassade bildet SQL_NULL und LIMIT auf NULL ab. Für explizite Statusauswertung TVF_Base64EncodeStatus verwenden; unerwartete Enginefehler bleiben Enginefehler.

## Aussagegrenzen

Base64 ist Kodierung, keine Verschlüsselung. URL-safe wird nur bei gebundenem bit-Wert 1 aktiviert; NULL wirkt wie 0. Kein unbegrenzter Streamingencoder.
