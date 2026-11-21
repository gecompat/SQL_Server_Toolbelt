---
name: "toolbelt-tvf-deterministicdateshift"
description: "Verschiebt ein Datum deterministisch um eine begrenzte Anzahl Tage."
skill_format_version: "1.0"
module_id: "toolbelt.pseudonymization.deterministic"
schema_name: "toolbelt_pseudonymization"
object_name: "TVF_DeterministicDateShift"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Value", "sql_type": "datetime2(7)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "datetime2(7) im nativen Bereich 0001-01-01..9999-12-31; Uhrzeit/Präzision bleiben beim ganzzahligen Tagesoffset erhalten. Keine Zeitzone/DST-Konvertierung. Value=NULL oder Key=NULL liefert NULL/Code 0 vor anderen Konfigurationsfehlern. Überlauf des gezogenen Offsets ergibt Code 8, kein Clamp/Wrap."}, {"name": "@Key", "sql_type": "varbinary(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag."}, {"name": "@MappingVersion", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert."}, {"name": "@Seed", "sql_type": "bigint", "sql_default": "0", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad."}, {"name": "@MaxDays", "sql_type": "int", "sql_default": "365", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Ganzzahl 0..3652058 Tage, Default 365. Offset wird deterministisch aus dem geschlossenen Intervall [-MaxDays,+MaxDays] gewählt; 0 lässt das Datum unverändert. NULL/außerhalb ergibt Code 7; Datumsoverflow wird zusätzlich geprüft."}]
source_paths: ["Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicDateShift.sql", "Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicIntegerBytes.sql", "Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicRangeCore.sql", "Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicRange.sql"]
review_status: "verified"
source_module_version: "1.2.0"
---

# TVF_DeterministicDateShift

## Zweck und Einsatzfälle

Verschiebt ein Datum deterministisch um eine begrenzte Anzahl Tage.

## Voraussetzungen

Modul 1.2.0 mit kanonischen T-SQL-Abhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Explizite Versionen und binäre Keys statt impliziter Textkodierung. Keine Fach- oder Systemkatalogabfrage für die Transformation erforderlich. Input- und Fehlercodes vor Weiterverwendung auswerten.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@Value` | `datetime2(7)` | kein Default | Input | datetime2(7) im nativen Bereich 0001-01-01..9999-12-31; Uhrzeit/Präzision bleiben beim ganzzahligen Tagesoffset erhalten. Keine Zeitzone/DST-Konvertierung. Value=NULL oder Key=NULL liefert NULL/Code 0 vor anderen Konfigurationsfehlern. Überlauf des gezogenen Offsets ergibt Code 8, kein Clamp/Wrap. |
| `@Key` | `varbinary(max)` | kein Default | Input | Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag. |
| `@MappingVersion` | `int` | kein Default | Input | Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert. |
| `@Seed` | `bigint` | `0` | Input | Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad. |
| `@MaxDays` | `int` | `365` | Input | Ganzzahl 0..3652058 Tage, Default 365. Offset wird deterministisch aus dem geschlossenen Intervall [-MaxDays,+MaxDays] gewählt; 0 lässt das Datum unverändert. NULL/außerhalb ergibt Code 7; Datumsoverflow wird zusätzlich geprüft. |

Bei TVF-Aufrufen alle Argumentpositionen angeben; DEFAULT nur bei tatsächlichem SQL-Default. NULL-Ergebnispriorität ist ein logischer Vertrag,keine Zusage über physische Optimizer-Auswertung. SQL-Typkonvertierung liegt vorher.

## Ergebnisse

| Spalte | SQL-Typ | Vertrag |
|---|---|---|
| `Value` | `datetime2(7)` | NULL beiNULLpfad oderFachfehler;Translate-AusgabeLatin1_General_100_BIN2 |
| `ErrorCode` | `int` | NOT NULL;logischerCode gemäßFehlerabschnitt |

Genau eine relationale Zeile,auch imNULL-/Fehlerpfad. Keine ResultTable,OUTPUT- oderHilfeparameter. ErrorCode ist kein SQL-Returncode.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicDateShift(CONVERT(datetime2(7),'2026-01-15T12:34:56'),0x010203,1,0,30);
```

## Rechte

Vorhandenes SELECT auf die öffentliche TVF. Interne Encoder-/Rangehelfer nur über öffentliche Einstiegspunkte verwenden. Keine fachliche Tabellen- oder Systemkatalogabfrage, CLR-Assembly, Serverrolle oder Rechtevergabe für die Transformation. Zentrale Dreiteilnamen brauchen gültigen Datenbankzugriff und Identitätsmapping. Tatsächliche Ownership-Chains und Objektrechte bleiben maßgeblich.

## Ressourcenbedarf

Range verwendet bis zu 128 logische Hashkandidaten je Aufruf, Geo zwei Rangeziehungen. Keine physische Auswertungszahlgarantie einer Inline-TVF. Translate verwendet 36 logische Hashframes und begrenzte Input-/Separatoroperanden. Standard2MiB/large16MiB gelten nur für Translate; der Key hat 1..8000 Bytes. Die Geography-Serialisierung zur Größenmessung erfolgt vor der 128-Byte-Prüfung. Keine harte Zeit-, Peakheap-, Plan- oder Parallelitätsgarantie.

## Nebenwirkungen

Inline-TVF,keine zweite Hashimplementierung. MaxDays wird vor potentiell vorgezogener Auswertung abgesichert; öffentlicher Range mit Bereich[-MaxDays,+MaxDays] und gleichem Key/Version/Seed. Gleicher Kontext ergibt gleichen Offset unabhängig vom Eingabedatum. Fehler logisch priorisieren; Datumsspielraum zu0001-01-01/9999-12-31 vor DATEADD prüfen. Ganzzahliger Tagesoffset erhält Uhrzeit und datetime2(7)-Präzision. Kein Clamp,Wrap,Zeitzonen-/DST-Vertrag oder separat ausgegebener Offset. NULLValue/Key ergibt ValueNULL/ErrorCode0,ohne Auswertungsreihenfolgegarantie des Optimizers.

## Fehlerbehandlung

Eine Zeile: ValueNULL oderKeyNULL zuerstCode0/ValueNULL; danach Version1,Seed2,MaxDays7,Rangefehler4/5 sowie Datumsoverflow8. Keine fachliche Exception und kein Clamp. Ursprüngliche SQL-Binder-/Engine-/Ressourcenfehler bleiben sichtbar; keine automatische Wiederholung.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Minimalrechte-/Callerzustands-/Installer-/Mapping-/Spatialabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. Ausschließlich für synthetische Datenzwecke; keine Anonymisierung, Eindeutigkeit, Kryptografie, Secretverwaltung oder Privacygarantie. Wiederholbarkeit verlangt denselben expliziten Kontext und bei Lookup denselben geordneten Pool. LookupVersion wird nicht automatisch gegen Drift geprüft. Keine pauschale bitweise Gleichheitszusage für Spatial-/Floatwerte zwischen Plattformen. Keine Installations- oder Rechteattestation. Reale Keys, Inputdaten und Runtimebefunde privat halten.
