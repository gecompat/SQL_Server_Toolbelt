---
name: "toolbelt-tvf-deterministicgeojitter"
description: "Verschiebt einen synthetischen 2D-Geography-Point im SRID 4326 deterministisch innerhalb eines Radius."
skill_format_version: "1.0"
module_id: "toolbelt.pseudonymization.deterministic"
schema_name: "toolbelt_pseudonymization"
object_name: "TVF_DeterministicGeoJitter"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Value", "sql_type": "geography", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Gültiger nicht leerer zweidimensionaler geography-Point mit SRID 4326, ohne Z/M, serialisierte Größe höchstens 128 Bytes; keine Linien/Polygone/anderen SRIDs. Beispielsweise geography::Point(48.2,16.3,4326). Value=NULL oder Key=NULL liefert NULL/Code 0 vor anderen Fehlern; ungeeignete Geometrie Code 15. Ausgabe ist ein deterministisch versetzter Punkt, kein Anonymisierungsnachweis."}, {"name": "@Key", "sql_type": "varbinary(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag."}, {"name": "@MappingVersion", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert."}, {"name": "@Seed", "sql_type": "bigint", "sql_default": "0", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad."}, {"name": "@RadiusMeters", "sql_type": "int", "sql_default": "100", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Ganzzahl 1..10000 Meter, Default 100. Obergrenze des radialen Jitters; Richtung und flächentreuer Radius werden aus dem Mappingkontext abgeleitet. NULL/0/negativ/größer ergibt Code 14. Keine Nullverschiebungsoption mit Radius 0."}]
source_paths: ["Modules/toolbelt.pseudonymization.deterministic/Source/DeterministicGeoJitter.sql", "Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicIntegerBytes.sql", "Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicRangeCore.sql"]
review_status: "verified"
source_module_version: "1.2.0"
---

# TVF_DeterministicGeoJitter

## Zweck und Einsatzfälle

Verschiebt einen synthetischen 2D-Geography-Point im SRID 4326 deterministisch innerhalb eines Radius.

## Voraussetzungen

Modul 1.2.0 mit kanonischen T-SQL-Abhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Explizite Versionen und binäre Keys statt impliziter Textkodierung. Keine Fach- oder Systemkatalogabfrage für die Transformation erforderlich. Input- und Fehlercodes vor Weiterverwendung auswerten.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@Value` | `geography` | kein Default | Input | Gültiger nicht leerer zweidimensionaler geography-Point mit SRID 4326, ohne Z/M, serialisierte Größe höchstens 128 Bytes; keine Linien/Polygone/anderen SRIDs. Beispielsweise geography::Point(48.2,16.3,4326). Value=NULL oder Key=NULL liefert NULL/Code 0 vor anderen Fehlern; ungeeignete Geometrie Code 15. Ausgabe ist ein deterministisch versetzter Punkt, kein Anonymisierungsnachweis. |
| `@Key` | `varbinary(max)` | kein Default | Input | Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag. |
| `@MappingVersion` | `int` | kein Default | Input | Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert. |
| `@Seed` | `bigint` | `0` | Input | Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad. |
| `@RadiusMeters` | `int` | `100` | Input | Ganzzahl 1..10000 Meter, Default 100. Obergrenze des radialen Jitters; Richtung und flächentreuer Radius werden aus dem Mappingkontext abgeleitet. NULL/0/negativ/größer ergibt Code 14. Keine Nullverschiebungsoption mit Radius 0. |

Bei TVF-Aufrufen alle Argumentpositionen angeben; DEFAULT nur bei tatsächlichem SQL-Default. NULL-Ergebnispriorität ist ein logischer Vertrag,keine Zusage über physische Optimizer-Auswertung. SQL-Typkonvertierung liegt vorher.

## Ergebnisse

| Spalte | SQL-Typ | Vertrag |
|---|---|---|
| `Value` | `geography` | NULL beiNULLpfad oderFachfehler;Translate-AusgabeLatin1_General_100_BIN2 |
| `ErrorCode` | `int` | NOT NULL;logischerCode gemäßFehlerabschnitt |

Genau eine relationale Zeile,auch imNULL-/Fehlerpfad. Keine ResultTable,OUTPUT- oderHilfeparameter. ErrorCode ist kein SQL-Returncode.

## Aufrufbeispiele

```sql
DECLARE @Point geography=geography::Point(0,0,4326);
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicGeoJitter(@Point,0x010203,1,0,100);
```

## Rechte

Vorhandenes SELECT auf die öffentliche TVF. Interne Encoder-/Rangehelfer nur über öffentliche Einstiegspunkte verwenden. Keine fachliche Tabellen- oder Systemkatalogabfrage, CLR-Assembly, Serverrolle oder Rechtevergabe für die Transformation. Zentrale Dreiteilnamen brauchen gültigen Datenbankzugriff und Identitätsmapping. Tatsächliche Ownership-Chains und Objektrechte bleiben maßgeblich.

## Ressourcenbedarf

Range verwendet bis zu 128 logische Hashkandidaten je Aufruf, Geo zwei Rangeziehungen. Keine physische Auswertungszahlgarantie einer Inline-TVF. Translate verwendet 36 logische Hashframes und begrenzte Input-/Separatoroperanden. Standard2MiB/large16MiB gelten nur für Translate; der Key hat 1..8000 Bytes. Die Geography-Serialisierung zur Größenmessung erfolgt vor der 128-Byte-Prüfung. Keine harte Zeit-, Peakheap-, Plan- oder Parallelitätsgarantie.

## Nebenwirkungen

Inline-TVF mit gestaffelt sicheren geography-Operanden. DATALENGTH(CONVERT(varbinary(max),Value)) ermittelt zunächst die serialisierte Größe; die128Byte-Grenze ist kein Vorab-Lobintakelimit dieser Konvertierung. Nur gültiger,nichtleerer zweidimensionaler Point SRID4326 ohneZ/M. Logische Fehlerpriorität bleibt erhalten; CASE/WHERE sind keine Materialisierungs-/Auswertungsbarriere. Zwei RangeCore-Ziehungen mit DomainTBXDGEO1,Kontext0/1 und Bereich0..9007199254740991 ergeben Flächen-/Richtungswerte. Sichere Kugelkappenrechnung mit konservativem Radius6416001; Pol-Längengrad kanonisch0,Longitude in[-180,180). geography::Point nur mit abgesicherten Koordinaten konstruieren. Nachbedingungen für Typ/SRID/2D/Validität und STDistance zwischen0 und Radius prüfen; sonstCode16/ValueNULL. Kein Clamp,MakeValid,Clipping oder Wiederholungsversuch. Keine bitweise Float-/Spatialgleichheit zwischen Plattformen behaupten.

## Fehlerbehandlung

Eine Zeile: ValueNULL oderKeyNULL zuerst0/ValueNULL; Version1,Seed2,Radius14,Keybreite4,Point15; anschließend unveränderte Rangefehler und numerische/spatiale Nachbedingung16. Kein fachlicher THROW oder Ersatzpunkt als Erfolg. Ursprüngliche SQL-Binder-/Engine-/Ressourcenfehler bleiben sichtbar; keine automatische Wiederholung.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Minimalrechte-/Callerzustands-/Installer-/Mapping-/Spatialabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. Ausschließlich für synthetische Datenzwecke; keine Anonymisierung, Eindeutigkeit, Kryptografie, Secretverwaltung oder Privacygarantie. Wiederholbarkeit verlangt denselben expliziten Kontext und bei Lookup denselben geordneten Pool. LookupVersion wird nicht automatisch gegen Drift geprüft. Keine pauschale bitweise Gleichheitszusage für Spatial-/Floatwerte zwischen Plattformen. Keine Installations- oder Rechteattestation. Reale Keys, Inputdaten und Runtimebefunde privat halten.
