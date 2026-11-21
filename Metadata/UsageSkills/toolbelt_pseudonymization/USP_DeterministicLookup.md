---
name: "toolbelt-usp-deterministiclookup"
description: "Deterministischer synthetischer Lookup; explizite Poolversion, kein Anonymisierungs- oder Eins-zu-eins-Schutz."
skill_format_version: "1.0"
module_id: "toolbelt.pseudonymization.deterministic"
schema_name: "toolbelt_pseudonymization"
object_name: "USP_DeterministicLookup"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@InputTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandene sichtbare caller-lokale #Temp, kein ##-/mehrteiliger Name oder #tbx_-Präfix. Erforderliche bytegenaue nicht-computed Basisspalten ohne Aliastyp; Zusatzspalten erlaubt. Ordinal bigint muss positiv, nicht NULL und innerhalb der Tabelle eindeutig sein, Lücken erlaubt. NULL ist nur technischer Help-Default; keine parallele Mutation. Zusätzlich Key varbinary(max): NULL wird als NULL-Ergebnis weitergeführt, sonst 1..8000 Bytes. Leere Eingabe zulässig. Kein ResultTable-Identitätsoverlap."}, {"name": "@LookupTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandene sichtbare caller-lokale #Temp, kein ##-/mehrteiliger Name oder #tbx_-Präfix. Erforderliche bytegenaue nicht-computed Basisspalten ohne Aliastyp; Zusatzspalten erlaubt. Ordinal bigint muss positiv, nicht NULL und innerhalb der Tabelle eindeutig sein, Lücken erlaubt. NULL ist nur technischer Help-Default; keine parallele Mutation. Zusätzlich Value nvarchar(max), auch NULL/leer ist als Poolwert zulässig. Pool muss mindestens eine Zeile enthalten. Auswahlposition folgt der Ordinalsortierung, nicht dem konkreten lückenhaften Ordinalwert. Nicht dieselbe tatsächliche Tabelle wie ResultTable."}, {"name": "@MappingVersion", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche positive int-Kontextversion 1..2147483647; NULL/0/negativ wirft 54000. Zusammen mit Seed und LookupVersion deterministischer Mappingkontext."}, {"name": "@Seed", "sql_type": "bigint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Jeder nicht-NULL-bigint im gesamten 64-Bit-Bereich, Default 0; NULL wirft 54000. Deterministischer Variantenkontext, kein Secret/Zufallsaufruf."}, {"name": "@LookupVersion", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche positive bigint-Poolversion 1..9223372036854775807; NULL/0/negativ wirft 54000. Caller muss sie bei Pooländerungen ändern; keine automatische Hash-/Versionsableitung."}, {"name": "@MaxInputRows", "sql_type": "int", "sql_default": "10000", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Ganzzahl 1..100000 Inputzeilen, Default 10000; NULL/außerhalb ungültig. Kein Teilresultat bei Überschreitung."}, {"name": "@MaxLookupRows", "sql_type": "int", "sql_default": "10000", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Ganzzahl 1..100000 Poolzeilen, Default 10000; NULL/außerhalb ungültig. Pool muss unabhängig davon nicht leer sein."}, {"name": "@MaxLookupTextBytes", "sql_type": "bigint", "sql_default": "2097152", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Ganzzahl 1..16777216 Bytes als Summe DATALENGTH(Value) im Pool, Default 2097152; NULL-Werte zählen 0. NULL/außerhalb beim Budget ungültig."}, {"name": "@MaxResultBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Ganzzahl 1..16777216 Bytes als Summe DATALENGTH der zugeordneten Ergebniswerte, Default 16777216. Wiederholte Poolwerte zählen pro Ergebniszeile erneut; NULL zählt 0. NULL/außerhalb ungültig."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf keine der beiden Eingabetabellen sein."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0, NULL wirkt wie 0: 0 still; 1 Phasenmessages; 2 zusätzlich Zeilen-/Bytezahlen; 3..255 zusätzlich Temp-Objektmetadaten. Keine Keys, Werte, Seeds oder Hashes; bei ResultTable zusätzlich Helperdiagnose."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.pseudonymization.deterministic/Source/USP_DeterministicLookup.sql", "Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicIntegerBytes.sql", "Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicRangeCore.sql", "Modules/toolbelt.pseudonymization.deterministic/Source/USP_DeterministicLookupCore.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "1.2.0"
---

# USP_DeterministicLookup

## Zweck und Einsatzfälle

Deterministischer synthetischer Lookup; explizite Poolversion, kein Anonymisierungs- oder Eins-zu-eins-Schutz.

## Voraussetzungen

Modul 1.2.0 mit kanonischen T-SQL-Abhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Explizite Versionen und binäre Keys statt impliziter Textkodierung. Eigene Caller-Temps ohne parallele Mutation; Fassade vor Core verwenden. Ein gesunder Caller-TX mit Savepoint ist möglich. Kein eigener Reparaturvertrag für doomed Caller-TX.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@InputTable` | `sysname` | `NULL` | Input | Vorhandene sichtbare caller-lokale #Temp, kein ##-/mehrteiliger Name oder #tbx_-Präfix. Erforderliche bytegenaue nicht-computed Basisspalten ohne Aliastyp; Zusatzspalten erlaubt. Ordinal bigint muss positiv, nicht NULL und innerhalb der Tabelle eindeutig sein, Lücken erlaubt. NULL ist nur technischer Help-Default; keine parallele Mutation. Zusätzlich Key varbinary(max): NULL wird als NULL-Ergebnis weitergeführt, sonst 1..8000 Bytes. Leere Eingabe zulässig. Kein ResultTable-Identitätsoverlap. |
| `@LookupTable` | `sysname` | `NULL` | Input | Vorhandene sichtbare caller-lokale #Temp, kein ##-/mehrteiliger Name oder #tbx_-Präfix. Erforderliche bytegenaue nicht-computed Basisspalten ohne Aliastyp; Zusatzspalten erlaubt. Ordinal bigint muss positiv, nicht NULL und innerhalb der Tabelle eindeutig sein, Lücken erlaubt. NULL ist nur technischer Help-Default; keine parallele Mutation. Zusätzlich Value nvarchar(max), auch NULL/leer ist als Poolwert zulässig. Pool muss mindestens eine Zeile enthalten. Auswahlposition folgt der Ordinalsortierung, nicht dem konkreten lückenhaften Ordinalwert. Nicht dieselbe tatsächliche Tabelle wie ResultTable. |
| `@MappingVersion` | `int` | `NULL` | Input | Fachlich erforderliche positive int-Kontextversion 1..2147483647; NULL/0/negativ wirft 54000. Zusammen mit Seed und LookupVersion deterministischer Mappingkontext. |
| `@Seed` | `bigint` | `0` | Input | Jeder nicht-NULL-bigint im gesamten 64-Bit-Bereich, Default 0; NULL wirft 54000. Deterministischer Variantenkontext, kein Secret/Zufallsaufruf. |
| `@LookupVersion` | `bigint` | `NULL` | Input | Fachlich erforderliche positive bigint-Poolversion 1..9223372036854775807; NULL/0/negativ wirft 54000. Caller muss sie bei Pooländerungen ändern; keine automatische Hash-/Versionsableitung. |
| `@MaxInputRows` | `int` | `10000` | Input | Ganzzahl 1..100000 Inputzeilen, Default 10000; NULL/außerhalb ungültig. Kein Teilresultat bei Überschreitung. |
| `@MaxLookupRows` | `int` | `10000` | Input | Ganzzahl 1..100000 Poolzeilen, Default 10000; NULL/außerhalb ungültig. Pool muss unabhängig davon nicht leer sein. |
| `@MaxLookupTextBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 Bytes als Summe DATALENGTH(Value) im Pool, Default 2097152; NULL-Werte zählen 0. NULL/außerhalb beim Budget ungültig. |
| `@MaxResultBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216 Bytes als Summe DATALENGTH der zugeordneten Ergebniswerte, Default 16777216. Wiederholte Poolwerte zählen pro Ergebniszeile erneut; NULL zählt 0. NULL/außerhalb ungültig. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Darf keine der beiden Eingabetabellen sein. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0, NULL wirkt wie 0: 0 still; 1 Phasenmessages; 2 zusätzlich Zeilen-/Bytezahlen; 3..255 zusätzlich Temp-Objektmetadaten. Keine Keys, Werte, Seeds oder Hashes; bei ResultTable zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Alle technischen Defaults dienen auch der frühen Hilfe; fachliche Pflichtwerte bleiben erforderlich. Core-Objekt-IDs sind Diagnosebindungen,kein weiterer Sicherheitsnachweis.

## Ergebnisse

| Spalte | SQL-Typ | Vertrag |
|---|---|---|
| `InputOrdinal` | `bigint` | NOT NULL;je Inputordinal |
| `LookupOrdinal` | `bigint` | NULL beiNULLKey,sonst gewählter tatsächlicher Poolordinal |
| `Value` | `nvarchar(max)` | Latin1_General_100_BIN2;Poolwert unverändert,auchNULL/leer |

Direkte Ausgabe geordnet InputOrdinal oder geroutet in lokales ResultTable,ohne zusätzlichen Fachresultset. Je Input genau eine Zuordnung;leererInput nullZeilen,leererPool Fehler. Hilfe liefert bisherige zwölfspaltige Standardhilfe plus genau eine Skillzeile:SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max). FrüherHelp- und normalerReturn0. Beide Prozeduren haben eigene frühe Hilfe; kein delegierter fachlicher Corelauf im Hilfepfad.

## Aufrufbeispiele

```sql
EXEC toolbelt_pseudonymization.USP_DeterministicLookup @Hilfe=1;
CREATE TABLE #ContosoInput(Ordinal bigint,[Key] varbinary(max));
CREATE TABLE #ContosoPool(Ordinal bigint,[Value] nvarchar(max));
INSERT #ContosoInput VALUES(1,0x010203),(2,NULL);
INSERT #ContosoPool VALUES(10,N'Contoso alpha'),(30,N'Contoso beta');
EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#ContosoInput',@LookupTable=N'#ContosoPool',@MappingVersion=1,@LookupVersion=1;
DROP TABLE #ContosoInput;DROP TABLE #ContosoPool;
```

## Rechte

Vorhandenes EXECUTE auf die öffentliche Lookup-Fassade, bei ResultTable zusätzlich Helper-EXECUTE. Caller muss seine eigenen #Temps lesen können und deren Metadaten über tempdb.sys.columns sehen. Die optionale Helperschnittstelle wird über sys.parameters geprüft. Dynamisches SQL greift nur auf QUOTENAME-gebundene Caller-Temps zu; der interne Rangeaufruf ist statisch für die reguläre Ownership-Chain. Keine direkten Fachcallergrants auf den Core. Zentrale Dreiteilnamen brauchen gültigen Datenbankzugriff und Identitätsmapping. Tatsächliche Ownership-Chains und Objektrechte bleiben maßgeblich.

## Ressourcenbedarf

Input und Pool sind auf je 1..100000 Zeilen begrenzt. Textbudgets je 1..16777216 Bytes, Pooldefault2097152, Ergebnisdefault16777216. MaxInputRows*8000 begrenzt private Keynutzdaten, nicht Peak-RAM. TOP(limit+1)-Preflight erfolgt vor privater LOB-Kopie. Gruppierungen, Sortierungen, TABLOCK/HOLDLOCK, tempdb, Log und die Locklebensdauer im Caller-TX verursachen weiterhin Aufwand. Keine harte Zeit-, CPU- oder Gesamtheapquote.

## Nebenwirkungen

Die öffentliche Fassade normalisiert KeepData/Debug/HilfeNULL zu0 und liefert frühe Hilfe. Danach positive MappingVersion/LookupVersion,nichtNULL Seed und Ressourcenlimits prüfen. Caller-lokale #Tabellennamen sichtbar,einzeln QUOTENAME-gebunden,höchstens116UTF-16-Einheiten,kein ## oder case-insensitives #tbx_-Präfix. tempdb.sys.columns muss bytegenaue Basisspalten ohne Alias-/Computedtyp zeigen: Input Ordinal bigint/Key varbinary(max),Pool Ordinal bigint/Value nvarchar(max); Zusatzspalten zulässig. ResultTable darf nicht mit einer Eingabetabelle identisch sein. Vier reservierte private #tbx_DeterministicLookup_-Namen dürfen noch nicht sichtbar sein. Erst danach genau ein Aufruf des Kerns hinter eigener Compilergrenze. Die beiden Eingabe-Objekt-IDs dienen dort nur Diagnose,keiner erneuten Autorisierung. Nicht direkt am Core vorbei aufrufen.

Core: eigene Transaktion oder zufällig benannter Savepoint im Caller-TX. Keine eigene XACT_ABORT-Umschaltung; doomed/distributed Caller können an Engine-/Savepointregeln scheitern. TOP(limit+1)-Preflight zählt Input/Pool,prüft positive/eindeutige Ordinals und nichtNULL Keys1..8000Bytes; leerer Pool unzulässig,leerer Input zulässig. TABLOCK/HOLDLOCK hält einen stabilen Lesescope,unter Caller-TX bis dessen Abschluss. Pooltextsumme vor privater Textkopie prüfen. Pool nach Ordinal ordnen und lückenlose PoolPosition bilden; danach begrenzte Keykopie. Statischer RangeCore-Aufruf mit DomainTBXDLKP1,ContextLookupVersion und Bereich1..PoolCount erhält reguläre Ownership-Chain. NULLKey ergibt NULL-Zuordnung. Map vollständig prüfen und private Keykopie sofort droppen. Ergebnistextsumme zählt wiederholte Pooltexte je Input erneut. Erst danach Value-LOBs in eigene Ergebnistabelle kopieren.

Optionales ResultTable: bestehende fünfparametrige PrepareResultTable-Schnittstelle im Katalog exakt prüfen,vorbereiten und alle Ergebniszeilen innerhalb derselben Transaktion einfügen. Eigener COMMIT beziehungsweise Caller-TX erhalten,erst danach direkterSELECT geordnet InputOrdinal. Im CATCH eigener ROLLBACK oder committable eigener Savepointrollback. Keine erfolgreiche Teilausgabe. Debug1 Phasen,2 zusätzlich Zeilen/Bytes,3..255 zusätzlich Temp-Objekt-IDs; keine Keys/Values/Seed-/Hashausgabe. Der Code besitzt keine persistent gespeicherte Poolhistorie oder Driftprüfung; Caller muss LookupVersion bei Pooländerung pflegen.

## Fehlerbehandlung

THROW54000 Konfiguration;54001 ungültige Limits oder Input-/Poolzeilengrenze;54002 fehlende/unzulässige Tabellen,Shape oder ResultTable-Overlap;54003 unzulässige/duplizierte Ordinals;54004 Keybreite;54005 leererPool;54006 Pool-/Ergebnistextsumme;54007 Range-Mappingfehler;54008 fehlende/abweichende ResultTable-Schnittstelle;54009 reservierter privater Tempname sichtbar. Engine-/Lock-/Savepoint-/Rollback-/Binderfehler unverändert. Keine automatische Wiederholung oder erfolgreiche Teilausgabe. Ursprüngliche SQL-Binder-/Engine-/Ressourcenfehler bleiben sichtbar; keine automatische Wiederholung.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Minimalrechte-/Callerzustands-/Installer-/Mapping-/Spatialabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. Ausschließlich für synthetische Datenzwecke; keine Anonymisierung, Eindeutigkeit, Kryptografie, Secretverwaltung oder Privacygarantie. Wiederholbarkeit verlangt denselben expliziten Kontext und bei Lookup denselben geordneten Pool. LookupVersion wird nicht automatisch gegen Drift geprüft. Keine pauschale bitweise Gleichheitszusage für Spatial-/Floatwerte zwischen Plattformen. Keine Installations- oder Rechteattestation. Reale Keys, Inputdaten und Runtimebefunde privat halten.
