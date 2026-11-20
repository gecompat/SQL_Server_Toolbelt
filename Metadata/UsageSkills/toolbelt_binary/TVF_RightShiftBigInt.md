---
name: "toolbelt-toolbelt-toolbelt-binary-tvf-rightshiftbigint"
description: "Verschiebt die Bits eines bigint-Werts logisch nach rechts."
skill_format_version: "1.0"
module_id: "toolbelt.binary.bit-operations"
schema_name: "toolbelt_binary"
object_name: "TVF_RightShiftBigInt"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Value", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "SQL-bigint als vorzeichenbehaftetes 64-Bit-Zweierkomplement (-9223372036854775808 bis 9223372036854775807); negative Werte sind gültige Bitmuster. NULL liefert einen NULL-Wert."}, {"name": "@ShiftAmount", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Ganzzahlige Bitanzahl: 0 lässt das Muster unverändert; 1..63 verschiebt logisch rechts, ohne Vorzeichenerweiterung; -1..-63 kehrt die Richtung um. Beträge ab 64 liefern 0, auch der kleinste bigint. NULL ergibt NULL."}]
source_paths: ["Modules/toolbelt.binary.bit-operations/Source/TVF_RightShiftBigInt.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# TVF_RightShiftBigInt

## Zweck und Einsatzfälle

Verschiebt die Bits eines bigint-Werts logisch nach rechts. Der Vertrag wird aus der bigint-/decimal-Arithmetik und den CASE-Guards der jeweiligen Source abgeleitet.

## Voraussetzungen

SQL Server 2019 oder neuer. Alle Funktionsargumente positionsbezogen angeben; für einen deklarierten Default ist DEFAULT anzugeben. Kein CLR oder externer Provider erforderlich.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | SQL-bigint als vorzeichenbehaftetes 64-Bit-Zweierkomplement (-9223372036854775808 bis 9223372036854775807); negative Werte sind gültige Bitmuster. NULL liefert einen NULL-Wert. |
| `@ShiftAmount` | `bigint` | `kein Default` | Input | Ganzzahlige Bitanzahl: 0 lässt das Muster unverändert; 1..63 verschiebt logisch rechts, ohne Vorzeichenerweiterung; -1..-63 kehrt die Richtung um. Beträge ab 64 liefern 0, auch der kleinste bigint. NULL ergibt NULL. |

## Ergebnisse

Genau eine Zeile mit Value bigint. NULL in einem Argument ergibt NULL. Logischer 64-Bit-Shift mit Nullauffüllung; herausgeschobene Bits gehen verloren, das Ergebnis wird als vorzeichenbehaftetes Zweierkomplement-bigint zurückgegeben. Negativer Shiftbetrag kehrt die Richtung um; Betrag ab 64 liefert 0. RightShift behandelt bigint-Minimum explizit ohne Negationsüberlauf.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_binary.TVF_RightShiftBigInt(255, 2);
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

Kein arithmetischer Shift mit Vorzeichenerweiterung, keine beliebige Binärbreite und keine Ganzzahlmultiplikation mit Überlaufmeldung. Rechtsverschiebung negativer Zahlen kann einen positiven Wert ergeben.
