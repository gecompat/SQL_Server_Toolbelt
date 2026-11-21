---
name: "toolbelt-tvf-deterministicrangecore"
description: "Interner V1-SHA256-Rejection-Sampler mit gebundener Domäne und Kontext."
skill_format_version: "1.0"
module_id: "toolbelt.pseudonymization.deterministic"
schema_name: "toolbelt_pseudonymization"
object_name: "TVF_DeterministicRangeCore"
object_type: "TVF"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@Domain", "sql_type": "binary(8)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Interne feste 8-Byte-Domäne des öffentlichen Verfahrens. NichtNULL, keine freie Fachcaller-Konfiguration; sonst Code6 nach vorgeordneten Prüfungen."}, {"name": "@Context", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Interner nichtNULL-Domänenkontext: Range0,LookuppositiveLookupVersion,GeoSlot0/1; sonst Code6."}, {"name": "@Key", "sql_type": "varbinary(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag."}, {"name": "@MappingVersion", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert."}, {"name": "@Seed", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad."}, {"name": "@Min", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Inklusive Untergrenze im gesamten bigint-Bereich; muss nicht NULL und <=Max sein. Min=Max ist gültig und liefert diesen Wert. NULL/vertauschte Grenzen ergeben Code 3 nach früheren NULL-/Konfigurationsprüfungen."}, {"name": "@Max", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Inklusive Obergrenze im gesamten bigint-Bereich; nicht NULL und >=Min. Auch der volle vorzeichenbehaftete 64-Bit-Bereich ist zulässig; kein exklusives Ende. NULL/vertauscht ergibt Code 3."}]
source_paths: ["Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicRangeCore.sql", "Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicIntegerBytes.sql"]
review_status: "verified"
source_module_version: "1.2.0"
public_entrypoints: ["toolbelt_pseudonymization.TVF_DeterministicRange"]
---

# TVF_DeterministicRangeCore

## Zweck und Einsatzfälle

Interner V1-SHA256-Rejection-Sampler mit gebundener Domäne und Kontext. Kein eigener öffentlicher Fachaufrufweg.

## Voraussetzungen

Modul 1.2.0 mit kanonischen T-SQL-Abhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Explizite Versionen und binäre Keys statt impliziter Textkodierung. Keine Fach- oder Systemkatalogabfrage für die Transformation erforderlich. Input- und Fehlercodes vor Weiterverwendung auswerten.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@Domain` | `binary(8)` | kein Default | Input | Interne feste 8-Byte-Domäne des öffentlichen Verfahrens. NichtNULL, keine freie Fachcaller-Konfiguration; sonst Code6 nach vorgeordneten Prüfungen. |
| `@Context` | `bigint` | kein Default | Input | Interner nichtNULL-Domänenkontext: Range0,LookuppositiveLookupVersion,GeoSlot0/1; sonst Code6. |
| `@Key` | `varbinary(max)` | kein Default | Input | Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag. |
| `@MappingVersion` | `int` | kein Default | Input | Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert. |
| `@Seed` | `bigint` | kein Default | Input | Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad. |
| `@Min` | `bigint` | kein Default | Input | Inklusive Untergrenze im gesamten bigint-Bereich; muss nicht NULL und <=Max sein. Min=Max ist gültig und liefert diesen Wert. NULL/vertauschte Grenzen ergeben Code 3 nach früheren NULL-/Konfigurationsprüfungen. |
| `@Max` | `bigint` | kein Default | Input | Inklusive Obergrenze im gesamten bigint-Bereich; nicht NULL und >=Min. Auch der volle vorzeichenbehaftete 64-Bit-Bereich ist zulässig; kein exklusives Ende. NULL/vertauscht ergibt Code 3. |

Bei TVF-Aufrufen alle Argumentpositionen angeben; DEFAULT nur bei tatsächlichem SQL-Default. NULL-Ergebnispriorität ist ein logischer Vertrag,keine Zusage über physische Optimizer-Auswertung. SQL-Typkonvertierung liegt vorher.

## Ergebnisse

| Spalte | SQL-Typ | Vertrag |
|---|---|---|
| `Value` | `bigint` | NULL beiNULLpfad oderFachfehler;Translate-AusgabeLatin1_General_100_BIN2 |
| `ErrorCode` | `int` | NOT NULL;logischerCode gemäßFehlerabschnitt |

Genau eine relationale Zeile,auch imNULL-/Fehlerpfad. Keine ResultTable,OUTPUT- oderHilfeparameter. ErrorCode ist kein SQL-Returncode.

## Aufrufbeispiele

```sql
-- Interner Helfer: öffentlichen Einstieg verwenden.
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicRange(0x010203,1,0,-10,10);
```

## Rechte

Vorhandenes SELECT auf die öffentliche TVF. Interne Encoder-/Rangehelfer nur über öffentliche Einstiegspunkte verwenden. Keine fachliche Tabellen- oder Systemkatalogabfrage, CLR-Assembly, Serverrolle oder Rechtevergabe für die Transformation. Zentrale Dreiteilnamen brauchen gültigen Datenbankzugriff und Identitätsmapping. Tatsächliche Ownership-Chains und Objektrechte bleiben maßgeblich.

## Ressourcenbedarf

Range verwendet bis zu 128 logische Hashkandidaten je Aufruf, Geo zwei Rangeziehungen. Keine physische Auswertungszahlgarantie einer Inline-TVF. Translate verwendet 36 logische Hashframes und begrenzte Input-/Separatoroperanden. Standard2MiB/large16MiB gelten nur für Translate; der Key hat 1..8000 Bytes. Die Geography-Serialisierung zur Größenmessung erfolgt vor der 128-Byte-Prüfung. Keine harte Zeit-, Peakheap-, Plan- oder Parallelitätsgarantie.

## Nebenwirkungen

Echte Inline-TVF: Konfigurationsfehler logisch priorisieren, sichere Operanden auch für vorgezogene Optimizer-Auswertung bilden. Explizite Big-endian-Zweierkomplementbytes, kein impliziter numeric-to-binary-Vertrag. Hashframe V1: Domain8,Context8,MappingVersion4,Seed8,Min8,Max8,KeyLength4,Key und Attempt4. SHA2_256; erste8Digestbytes explizit als unsigned64 in decimal(38,0) interpretieren. Bis128 Kandidaten in Attemptreihenfolge0..127; akzeptieren wenn Candidate<2^64-(2^64 modulo Span), dann Min+Candidate modulo Span. Span=Max-Min+1 in decimal erlaubt den ganzen bigint-Bereich. Nach128 Verwerfungen Code5, kein unbeschränkter Retry. Keine Uniqueness-/Kryptografie-/Privacy-Zusage. Kontext,Version,Seed,Grenzen und Keybytes binden das Mapping; Änderung muss nicht jeden Einzelwert ändern.

## Fehlerbehandlung

Logische Priorität: KeyNULL0/ValueNULL; Version1,Seed2,Grenzen3,Keybreite4,Domain/Context6; ansonsten nach128 nichtakzeptierten Kandidaten5. Keine fachliche Exception; ValueNULL beiFehler. Ursprüngliche SQL-Binder-/Engine-/Ressourcenfehler bleiben sichtbar; keine automatische Wiederholung.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Minimalrechte-/Callerzustands-/Installer-/Mapping-/Spatialabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. Ausschließlich für synthetische Datenzwecke; keine Anonymisierung, Eindeutigkeit, Kryptografie, Secretverwaltung oder Privacygarantie. Wiederholbarkeit verlangt denselben expliziten Kontext und bei Lookup denselben geordneten Pool. LookupVersion wird nicht automatisch gegen Drift geprüft. Keine pauschale bitweise Gleichheitszusage für Spatial-/Floatwerte zwischen Plattformen. Keine Installations- oder Rechteattestation. Reale Keys, Inputdaten und Runtimebefunde privat halten.
