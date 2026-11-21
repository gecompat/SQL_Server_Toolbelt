---
name: "toolbelt-toolbelt-toolbelt-conversion-tvf-base64encodestatus"
description: "Codiert begrenzte Binärdaten als Base64 oder Base64URL mit explizitem NULL-/Limitstatus."
skill_format_version: "1.0"
module_id: "toolbelt.conversion.base64"
schema_name: "toolbelt_conversion"
object_name: "TVF_Base64EncodeStatus"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Value", "sql_type": "varbinary(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Binärwert varbinary(max), etwa 0xCAFECAFE oder ein vom Client gebundener Bytepuffer; keine Text-Decodierung. Leer (0x) ist gültig. Maximal 16777216 Bytes; darüber Status LIMIT bzw. NULL in der Wertfassade. NULL ergibt SQL_NULL bzw. NULL."}, {"name": "@UrlSafe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ für den gebundenen bit-Wert: 0 erzeugt Standard-Base64 mit +, / und Padding = (Default); 1 erzeugt Base64URL mit -, _ und ohne Padding. NULL wird wie 0 behandelt."}]
source_paths: ["Modules/toolbelt.conversion.base64/Source/TVF_Base64Encode.sql"]
review_status: "verified"
source_module_version: "1.1.0"
---

# TVF_Base64EncodeStatus

## Zweck und Einsatzfälle

Codiert begrenzte Binärdaten als Base64 oder Base64URL mit explizitem NULL-/Limitstatus. Öffentlicher Statuskern der Wertfassaden; kann SQL-NULL und Ausgabelimit unterscheiden.

## Voraussetzungen

SQL Server 2019 oder neuer; Aufruf als Tabellenfunktion. Beide Argumentpositionen angeben; für einen deklarierten Default ist in einem Funktionsaufruf DEFAULT zu verwenden.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varbinary(max)` | `kein Default` | Input | Binärwert varbinary(max), etwa 0xCAFECAFE oder ein vom Client gebundener Bytepuffer; keine Text-Decodierung. Leer (0x) ist gültig. Maximal 16777216 Bytes; darüber Status LIMIT bzw. NULL in der Wertfassade. NULL ergibt SQL_NULL bzw. NULL. |
| `@UrlSafe` | `bit` | `0` | Input | Taxativ für den gebundenen bit-Wert: 0 erzeugt Standard-Base64 mit +, / und Padding = (Default); 1 erzeugt Base64URL mit -, _ und ohne Padding. NULL wird wie 0 behandelt. |

## Ergebnisse

Genau eine Zeile mit EncodedValue varchar(max) NULL und Status varchar(16) NOT NULL. Taxativ SQL_NULL bei NULL-Eingabe und EncodedValue=NULL; LIMIT bei mehr als 16777216 Eingabebytes und EncodedValue=NULL; OK bei gültiger Eingabe einschließlich leerer Bytes. 0x ergibt leeren Text und OK. URL-safe kodiert nur bei gebundenem @UrlSafe=1.

## Aufrufbeispiele

```sql
SELECT EncodedValue,Status
FROM toolbelt_conversion.TVF_Base64EncodeStatus(0xCAFECAFE,0);
-- yv7K/g==, OK
SELECT EncodedValue,Status
FROM toolbelt_conversion.TVF_Base64EncodeStatus(NULL,1);
-- NULL, SQL_NULL
```

## Rechte

Vorhandenes SELECT auf der Funktion; keine automatische Rechtevergabe. Cross-Database-Zuordnung muss im gewählten Aufrufkontext bestehen.

## Ressourcenbedarf

Multistatement-TVF mit höchstens 16777216 Eingabebytes vor der XML-Kodierung. Standard-Base64 liefert 4*CEILING(Bytes/3) ASCII-Zeichen; URL-safe ersetzt + und / und entfernt bis zu zwei Paddingzeichen. Ausgabegröße bleibt trotz Eingabegrenze erheblich. Kein Streaming, keine pauschale Inline-, Parallelitäts- oder Laufzeitgarantie.

## Nebenwirkungen

Read-only; keine Tabellenänderung, Datei- oder Netzwerkoperation.

## Fehlerbehandlung

NULL- und Größenprüfungen liegen vor der XML-Kodierung. Diese fachlichen Fälle werden als SQL_NULL oder LIMIT zurückgegeben; Typbindung und unerwartete Engine-/XML-/Ressourcenfehler bleiben Fehler.

## Aussagegrenzen

Base64 ist Kodierung, keine Verschlüsselung. URL-safe wird nur bei gebundenem bit-Wert 1 aktiviert; NULL wirkt wie 0. Kein unbegrenzter Streamingencoder.
