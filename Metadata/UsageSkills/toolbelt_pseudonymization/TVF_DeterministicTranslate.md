---
name: "toolbelt-tvf-deterministictranslate"
description: "Übersetzt ASCII-Buchstaben und Ziffern deterministisch über eine bijektive Abbildung."
skill_format_version: "1.0"
module_id: "toolbelt.pseudonymization.deterministic"
schema_name: "toolbelt_pseudonymization"
object_name: "TVF_DeterministicTranslate"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Value", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "ASCII-Kennung: Buchstaben a-z/A-Z und Ziffern 0-9 werden bijektiv substituiert, ausdrücklich erlaubte Separatoren bleiben unverändert. Leer ist gültig; NULL ergibt NULL/Code 0 vor jeder Konfigurationsprüfung. Kein Trim/Unicode-Transliterieren; Akzente, NUL, Controls, DEL und Surrogate ergeben Code 13. Bytebudget durch Profile, Output exakt gleiche Länge."}, {"name": "@MappingVersion", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert."}, {"name": "@Seed", "sql_type": "bigint", "sql_default": "0", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad."}, {"name": "@AllowedSeparators", "sql_type": "nvarchar(max)", "sql_default": "N''", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Explizite Menge von höchstens 33 verschiedenen druckbaren ASCII-Nichtalnum-Zeichen aus Codes 32..126, z.B. N'-/ '; jedes bleibt unverändert. Leer (Default) erlaubt keine Separatoren. Duplikate, Buchstaben/Ziffern, Controls/NUL/DEL/Unicode und NULL ergeben Code 11; trailing Spaces sind relevant. Keine mehrzeichige Separatorgrammatik."}, {"name": "@Profile", "sql_type": "nvarchar(max)", "sql_default": "N'standard'", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Taxativ, bytegenau ohne Trim: standard (Default) = höchstens 2097152 UTF-16-Inputbytes; large = höchstens 16777216. NULL/leer/andere Schreibweisen ergeben Code 10; Überschreitung Code 12. Profil ändert nur das Budget, nicht die Mappingpermutation."}]
source_paths: ["Modules/toolbelt.pseudonymization.deterministic/Source/DeterministicTranslate.sql", "Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicIntegerBytes.sql"]
review_status: "verified"
source_module_version: "1.2.0"
---

# TVF_DeterministicTranslate

## Zweck und Einsatzfälle

Übersetzt ASCII-Buchstaben und Ziffern deterministisch über eine bijektive Abbildung.

## Voraussetzungen

Modul 1.2.0 mit kanonischen T-SQL-Abhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Explizite Versionen und binäre Keys statt impliziter Textkodierung. Keine Fach- oder Systemkatalogabfrage für die Transformation erforderlich. Input- und Fehlercodes vor Weiterverwendung auswerten.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | kein Default | Input | ASCII-Kennung: Buchstaben a-z/A-Z und Ziffern 0-9 werden bijektiv substituiert, ausdrücklich erlaubte Separatoren bleiben unverändert. Leer ist gültig; NULL ergibt NULL/Code 0 vor jeder Konfigurationsprüfung. Kein Trim/Unicode-Transliterieren; Akzente, NUL, Controls, DEL und Surrogate ergeben Code 13. Bytebudget durch Profile, Output exakt gleiche Länge. |
| `@MappingVersion` | `int` | kein Default | Input | Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert. |
| `@Seed` | `bigint` | `0` | Input | Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad. |
| `@AllowedSeparators` | `nvarchar(max)` | `N''` | Input | Explizite Menge von höchstens 33 verschiedenen druckbaren ASCII-Nichtalnum-Zeichen aus Codes 32..126, z.B. N'-/ '; jedes bleibt unverändert. Leer (Default) erlaubt keine Separatoren. Duplikate, Buchstaben/Ziffern, Controls/NUL/DEL/Unicode und NULL ergeben Code 11; trailing Spaces sind relevant. Keine mehrzeichige Separatorgrammatik. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, bytegenau ohne Trim: standard (Default) = höchstens 2097152 UTF-16-Inputbytes; large = höchstens 16777216. NULL/leer/andere Schreibweisen ergeben Code 10; Überschreitung Code 12. Profil ändert nur das Budget, nicht die Mappingpermutation. |

Bei TVF-Aufrufen alle Argumentpositionen angeben; DEFAULT nur bei tatsächlichem SQL-Default. NULL-Ergebnispriorität ist ein logischer Vertrag,keine Zusage über physische Optimizer-Auswertung. SQL-Typkonvertierung liegt vorher.

## Ergebnisse

| Spalte | SQL-Typ | Vertrag |
|---|---|---|
| `Value` | `nvarchar(max)` | NULL beiNULLpfad oderFachfehler;Translate-AusgabeLatin1_General_100_BIN2 |
| `ErrorCode` | `int` | NOT NULL;logischerCode gemäßFehlerabschnitt |

Genau eine relationale Zeile,auch imNULL-/Fehlerpfad. Keine ResultTable,OUTPUT- oderHilfeparameter. ErrorCode ist kein SQL-Returncode.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(N'Contoso-123',1,0,N'-',N'standard');
```

## Rechte

Vorhandenes SELECT auf die öffentliche TVF. Interne Encoder-/Rangehelfer nur über öffentliche Einstiegspunkte verwenden. Keine fachliche Tabellen- oder Systemkatalogabfrage, CLR-Assembly, Serverrolle oder Rechtevergabe für die Transformation. Zentrale Dreiteilnamen brauchen gültigen Datenbankzugriff und Identitätsmapping. Tatsächliche Ownership-Chains und Objektrechte bleiben maßgeblich.

## Ressourcenbedarf

Range verwendet bis zu 128 logische Hashkandidaten je Aufruf, Geo zwei Rangeziehungen. Keine physische Auswertungszahlgarantie einer Inline-TVF. Translate verwendet 36 logische Hashframes und begrenzte Input-/Separatoroperanden. Standard2MiB/large16MiB gelten nur für Translate; der Key hat 1..8000 Bytes. Die Geography-Serialisierung zur Größenmessung erfolgt vor der 128-Byte-Prüfung. Keine harte Zeit-, Peakheap-, Plan- oder Parallelitätsgarantie.

## Nebenwirkungen

Inline-TVF mit sicheren Operanden vor TRANSLATE/REPLICATE. Profil per DATALENGTH und varbinary bytegenau prüfen; Separatoren höchstens33 verschiedene druckbare ASCII-Nichtalnumzeichen.36 logische SHA2_256-Frames:26Buchstaben und10Ziffern aus DomainTBXDTRN1,Version,Seed,Alphabetkind und ursprünglichem Ordinal. Digest/Ordinalsortierung bestimmt stabile Permutation; Großbuchstaben verwenden dieselbe Buchstabenpermutation in Großschreibung. TRANSLATE unter Latin1_General_100_BIN2 ersetzt a-z/A-Z/0-9 und lässt erlaubte Separatoren unverändert. Zweite abgesicherte Übersetzung auf A mit exaktem varbinary-Vergleich erkennt jedes unbekannte Zeichen. Länge,Case,Zeichenklasse,Muster und Häufigkeiten bleiben sichtbar. Profil ändert nur Budget,nicht Permutation. Kein Decoderangebot oder kryptografisches Schutzversprechen.

## Fehlerbehandlung

Eine Zeile: ValueNULL zuerst0/ValueNULL; Version1,Seed2,Profil10,Separatoren11,Inputbudget12,unbekanntes Zeichen13. ValueNULL beiFehler,kein Teiltext. Keine fachliche Exception. Ursprüngliche SQL-Binder-/Engine-/Ressourcenfehler bleiben sichtbar; keine automatische Wiederholung.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Minimalrechte-/Callerzustands-/Installer-/Mapping-/Spatialabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. Ausschließlich für synthetische Datenzwecke; keine Anonymisierung, Eindeutigkeit, Kryptografie, Secretverwaltung oder Privacygarantie. Wiederholbarkeit verlangt denselben expliziten Kontext und bei Lookup denselben geordneten Pool. LookupVersion wird nicht automatisch gegen Drift geprüft. Keine pauschale bitweise Gleichheitszusage für Spatial-/Floatwerte zwischen Plattformen. Keine Installations- oder Rechteattestation. Reale Keys, Inputdaten und Runtimebefunde privat halten.
