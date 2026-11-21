---
name: "toolbelt-toolbelt-toolbelt-binary-tvf-getbitbigint"
description: "Liest das Bit an einer nullbasierten Position."
skill_format_version: "1.0"
module_id: "toolbelt.binary.bit-operations"
schema_name: "toolbelt_binary"
object_name: "TVF_GetBitBigInt"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Value", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "SQL-bigint als vorzeichenbehaftetes 64-Bit-Zweierkomplement (-9223372036854775808 bis 9223372036854775807); negative Werte sind gültige Bitmuster. NULL liefert einen NULL-Wert."}, {"name": "@BitOffset", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Ganzzahl 0..63, inklusive: 0 ist das niederwertigste Bit, 63 das Vorzeichenbit. Andere Werte ergeben IsValid=0/ValidationCode=10; NULL ergibt NULL in Wert und Validierungsfeldern."}]
source_paths: ["Modules/toolbelt.binary.bit-operations/Source/TVF_GetBitBigInt.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# TVF_GetBitBigInt

## Zweck und Einsatzfälle

Liest das Bit an einer nullbasierten Position. Der Vertrag wird aus der bigint-/decimal-Arithmetik und den CASE-Guards der jeweiligen Source abgeleitet.

## Voraussetzungen

SQL Server 2019 oder neuer. Alle Funktionsargumente positionsbezogen angeben; für einen deklarierten Default ist DEFAULT anzugeben. Kein CLR oder externer Provider erforderlich.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | SQL-bigint als vorzeichenbehaftetes 64-Bit-Zweierkomplement (-9223372036854775808 bis 9223372036854775807); negative Werte sind gültige Bitmuster. NULL liefert einen NULL-Wert. |
| `@BitOffset` | `bigint` | `kein Default` | Input | Ganzzahl 0..63, inklusive: 0 ist das niederwertigste Bit, 63 das Vorzeichenbit. Andere Werte ergeben IsValid=0/ValidationCode=10; NULL ergibt NULL in Wert und Validierungsfeldern. |

## Ergebnisse

Genau eine Zeile mit Value bit, IsValid bit und ValidationCode tinyint. NULL in Value oder BitOffset ergibt drei NULL-Werte. Offset außerhalb 0..63 ergibt Value=NULL, IsValid=0, ValidationCode=10; gültiger Aufruf liefert das Bit, IsValid=1, ValidationCode=0.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_binary.TVF_GetBitBigInt(255, 3);
```

## Rechte

Vorhandenes SELECT oder REFERENCES auf der Funktion; Cross-Database-Zuordnung und Aufrufrechte gelten unverändert. Keine Rechtevergabe oder Ausführungsidentitätsänderung.

## Ressourcenbedarf

Inline-TVF ohne persistente Zustandsänderung. Konstante begrenzte 64-Bit-/decimal(38,0)-Arithmetik; BitCount wertet acht Bytes set-basiert aus. Keine unbeschränkten Schleifen und keine pauschale Plan-/Laufzeitgarantie.

## Nebenwirkungen

Read-only; keine Datei-, Netzwerk-, Tabellen- oder Konfigurationsänderung.

## Fehlerbehandlung

NULL und fachlich ungültige Werte werden wie unten beschrieben als Ergebniswerte/Status abgebildet. SQL-Typbindung und unerwartete Enginefehler bleiben reguläre Enginefehler; keine automatische Umdeutung.

## Aussagegrenzen

Offset 0 ist das Least Significant Bit, 63 das Vorzeichenbit des 64-Bit-Musters. Kein Offset ab 64 und keine variable Binärbreite; IsValid=NULL ist von IsValid=0 zu unterscheiden.
