---
name: "toolbelt-toolbelt-toolbelt-string-usp-comparetextpairs"
description: "Begrenzt vergleicht vorhandene lokale Textpaare mit den kanonischen Distanz-/Jaro-TVFs. Globale Fehler veröffentlichen keine Teilresultate."
skill_format_version: "1.0"
module_id: "toolbelt.string.text-pairs"
schema_name: "toolbelt_string"
object_name: "USP_CompareTextPairs"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@PairsTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vorhandene sichtbare lokale #Temp, Name 2..116 UTF-16-Einheiten, kein ##-/mehrteiliger Name und kein reserviertes #tbx_-Präfix. Drei bytegenau benannte Basisspalten: PairOrdinal bigint, LeftText nvarchar(max), RightText nvarchar(max); zusätzliche Spalten sind erlaubt, Alias-/computed-/hidden-/generated-/verschlüsselte Vertragsspalten nicht. PairOrdinal muss pro Zeile nicht NULL und eindeutig sein (auch negative Werte erlaubt); Text-NULL und leere Tabelle sind erlaubt. NULL ist nur Help-Default, fachlich ungültig. Keine parallele Mutation."}, {"name": "@Algorithm", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Taxativ, bytegenau ohne Trim: levenshtein = Einfügen/Löschen/Ersetzen; osa = zusätzlich eingeschränkte benachbarte Transposition; jaro-winkler = Ähnlichkeit mit Präfixbonus. NULL/leer/andere Schreibweisen ungültig. Bei jaro-winkler muss MaxDistance NULL sein."}, {"name": "@MaxDistance", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) berechnet ohne Distanzschwelle. Ganzzahl 0..2147483647 begrenzt die gesuchte Distanz; 0 verlangt Gleichheit. Bei Überschreitung ExceedsMaxDistance auswerten, keinen exakten Vollabstand unterstellen. Negative Werte ergeben ErrorCode 2, sofern kein früher NULL-Textpfad greift. Bei jaro-winkler ausschließlich NULL, jeder nicht-NULL-Wert wird bereits vor der Paarberechnung abgewiesen. Bei Distanzverfahren erfolgt die Schwellenvalidierung je Paar."}, {"name": "@Profile", "sql_type": "nvarchar(max)", "sql_default": "N'standard'", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) = höchstens 2048 UTF-16-Einheiten, 1024 Skalare pro Text und 1048576 geplante Arbeitseinheiten; large = 65536 Einheiten, 32768 Skalare und 16777216 Arbeitseinheiten. NULL/leer/andere Schreibweisen ergeben ErrorCode 1, außer beim frühen NULL-Textpfad. Größeres Profil hebt die endlichen Worklimits nicht auf. Wird je Paar vom Provider ausgewertet; eine leere Tabelle erzwingt keinen Profilfehler."}, {"name": "@MaxPairs", "sql_type": "int", "sql_default": "10000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..100000 Paare, Default 10000; NULL/andere Werte ungültig. Mehr Inputzeilen werden vor Berechnung atomar abgewiesen."}, {"name": "@MaxTotalTextBytes", "sql_type": "bigint", "sql_default": "2097152", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216 Bytes für die Summe DATALENGTH(LeftText)+DATALENGTH(RightText) über alle Paare, Default 2097152. NULL/andere Werte ungültig. Ein nicht-NULL-Text zählt auch bei NULL-Gegenstück; keine Zeichenanzahl."}, {"name": "@MaxTotalWork", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..67108864 konservative Admission-Arbeitseinheiten, Default 16777216. Pro Paar min(UTF-16-Länge links * Länge rechts, Profilcap 1048576 bzw. 16777216); bei einem NULL-Text 0. NULL/andere Werte ungültig. Zusätzlich gelten weiterhin die tatsächlichen Providerlimits je Paar."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Zusätzlich Name 2..116 UTF-16-Einheiten, kein #tbx_-Präfix und nicht dieselbe Tabelle wie PairsTable."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.string.text-pairs/Source/USP_CompareTextPairs.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# USP_CompareTextPairs

## Zweck und Einsatzfälle

Begrenzt vergleicht vorhandene lokale Textpaare mit den kanonischen Distanz-/Jaro-TVFs. Globale Fehler veröffentlichen keine Teilresultate.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@PairsTable` | `sysname` | `NULL` | Input | Vorhandene sichtbare lokale #Temp, Name 2..116 UTF-16-Einheiten, kein ##-/mehrteiliger Name und kein reserviertes #tbx_-Präfix. Drei bytegenau benannte Basisspalten: PairOrdinal bigint, LeftText nvarchar(max), RightText nvarchar(max); zusätzliche Spalten sind erlaubt, Alias-/computed-/hidden-/generated-/verschlüsselte Vertragsspalten nicht. PairOrdinal muss pro Zeile nicht NULL und eindeutig sein (auch negative Werte erlaubt); Text-NULL und leere Tabelle sind erlaubt. NULL ist nur Help-Default, fachlich ungültig. Keine parallele Mutation. |
| `@Algorithm` | `nvarchar(max)` | `NULL` | Input | Taxativ, bytegenau ohne Trim: levenshtein = Einfügen/Löschen/Ersetzen; osa = zusätzlich eingeschränkte benachbarte Transposition; jaro-winkler = Ähnlichkeit mit Präfixbonus. NULL/leer/andere Schreibweisen ungültig. Bei jaro-winkler muss MaxDistance NULL sein. |
| `@MaxDistance` | `int` | `NULL` | Input | NULL (Default) berechnet ohne Distanzschwelle. Ganzzahl 0..2147483647 begrenzt die gesuchte Distanz; 0 verlangt Gleichheit. Bei Überschreitung ExceedsMaxDistance auswerten, keinen exakten Vollabstand unterstellen. Negative Werte ergeben ErrorCode 2, sofern kein früher NULL-Textpfad greift. Bei jaro-winkler ausschließlich NULL, jeder nicht-NULL-Wert wird bereits vor der Paarberechnung abgewiesen. Bei Distanzverfahren erfolgt die Schwellenvalidierung je Paar. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) = höchstens 2048 UTF-16-Einheiten, 1024 Skalare pro Text und 1048576 geplante Arbeitseinheiten; large = 65536 Einheiten, 32768 Skalare und 16777216 Arbeitseinheiten. NULL/leer/andere Schreibweisen ergeben ErrorCode 1, außer beim frühen NULL-Textpfad. Größeres Profil hebt die endlichen Worklimits nicht auf. Wird je Paar vom Provider ausgewertet; eine leere Tabelle erzwingt keinen Profilfehler. |
| `@MaxPairs` | `int` | `10000` | Input | Ganzzahl 1..100000 Paare, Default 10000; NULL/andere Werte ungültig. Mehr Inputzeilen werden vor Berechnung atomar abgewiesen. |
| `@MaxTotalTextBytes` | `bigint` | `2097152` | Input | Ganzzahl 1..16777216 Bytes für die Summe DATALENGTH(LeftText)+DATALENGTH(RightText) über alle Paare, Default 2097152. NULL/andere Werte ungültig. Ein nicht-NULL-Text zählt auch bei NULL-Gegenstück; keine Zeichenanzahl. |
| `@MaxTotalWork` | `bigint` | `16777216` | Input | Ganzzahl 1..67108864 konservative Admission-Arbeitseinheiten, Default 16777216. Pro Paar min(UTF-16-Länge links * Länge rechts, Profilcap 1048576 bzw. 16777216); bei einem NULL-Text 0. NULL/andere Werte ungültig. Zusätzlich gelten weiterhin die tatsächlichen Providerlimits je Paar. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Zusätzlich Name 2..116 UTF-16-Einheiten, kein #tbx_-Präfix und nicht dieselbe Tabelle wie PairsTable. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

Unveränderte Inputidentität; SELECT ordinal sortiert.

Distanzwert oder NULL; bei Jaro immer NULL.

Distanz-Thresholdnachweis oder NULL; bei Jaro immer NULL.

Jaro-Winkler 0..1 oder NULL; bei Distanz immer NULL.

Kanonischer Fachcode 0..6; Jaro verwendet keinen Code 2.

## Aufrufbeispiele

```sql
CREATE TABLE #Pairs(PairOrdinal bigint,LeftText nvarchar(max),RightText nvarchar(max)); INSERT #Pairs VALUES(1,N'kitten',N'sitting'); EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'levenshtein';
```

## Rechte

Vorhandenes EXECUTE und bestehende TVF-/Helper-Rechte beziehungsweise Ownershipchain; caller-eigene Tempmetadaten. Keine Rechteerteilung und keine Runtime-Assemblyhash-/DB-VIEW-DEFINITION-Pflicht.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Algorithmus, globale Parameter, lokale Namen/Shape oder interne Tempkollision ungültig; kein fachliches Resultat.

Admission/Stabilität/Ordinals/Work oder Providerkohärenz verletzt; keine Teilveröffentlichung. Engine-/Helperfehler bleiben erhalten.

## Aussagegrenzen

Keine MARS-/parallele Mutation, keine globale/permanente Inputtable. Distributed Caller-Savepoints sind nicht unterstützt. Technische Fehler verwerfen den gesamten Aufruf.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.string.text-pairs/Documentation/USP_CompareTextPairs.md`

Keine Installations-, Definitions- oder Rechteattestation.
