# toolbelt_string.USP_CompareTextPairs

Öffentlicher Vertrag 1.0.0: [kanonische Signatur, Grenzen und Freigabe](../../../Documentation/Architecture/TEXT_PAIRS_CONTRACT.md). Elf Parameter; die letzten vier sind ResultTable, KeepData, Debug, Hilfe. `EXEC toolbelt_string.USP_CompareTextPairs @Hilfe=1;` liefert ausschließlich Help1.0.

Die [aktuelle Callerqualifikation](../../../Releases/1.0.0/TEXT-PAIRS-CALLER-QUALIFICATION.md) belegt im gebunden installierten Ownershipstand genau ein EXECUTE auf `toolbelt_string.USP_CompareTextPairs` für alle drei Algorithmen über direkte Ausgabe und ResultTable. Separate SELECT-Rechte auf Vergleichs-TVFs oder EXECUTE auf dem Helper werden dabei nicht erteilt; direkte Dependencyaufrufe bleiben mit SQL229 gesperrt. Andere Owner-/Client-/Grenz-/Lifecyclekontexte bleiben getrennt.

Input: vorhandene lokale #Temp mit exakt benannten Systemspalten `PairOrdinal bigint`, `LeftText nvarchar(max)`, `RightText nvarchar(max)`. Ordinals dürfen negative Werte und 0 enthalten, dürfen nicht NULL sein und müssen eindeutig sein; zusätzliche Spalten werden ignoriert. Keine Alias-/computed-/hidden-/encrypted Fachspalten. Keine Normalisierung oder Kürzung. Parallele Mutation/MARS ist nicht unterstützt.

Algorithmus bytegenau `levenshtein`, `osa` oder `jaro-winkler`. Profil/Distanzschwelle gehen unverändert an bestehende TVFs; Jaro unterstützt nur NULL-Schwelle. Batchadmission: maximal 100000 Paare, 16777216 Textbytes und 67108864 konservative Workeinheiten; kleinere positive Callerbudgets zulässig. Textbytes zählen beide Seiten auch bei NULL-Gegenseite, Work bei NULL-Paar 0; sonst UTF16-Längenprodukt mit Paircap 1048576 bei standard und 16777216 sonst. Keine tatsächliche CPU-/Heap-/Hardwallzusage.

Ein vollständiges Resultat pro Ordinal: `PairOrdinal bigint NOT NULL`, `Distance int NULL`, `ExceedsMaxDistance bit NULL`, `Similarity float(53) NULL`, `ErrorCode int NOT NULL`. Direkter SELECT sortiert Ordinals; Tempdaten sind ungeordnet. Kerncodes 0..6 bleiben normale Pairresultate. Distanz setzt Similarity NULL; Jaro setzt Distance/Exceeds NULL und verwendet keinen Code2. NULL-Textpaar liefert NULL-Fachwerte/Code0. Fachwerte, Relation und Zeilenzahl werden vor Veröffentlichung geprüft.

ResultTableNULL liefert genau einen fachlichen SELECT; sonst keine fachliche SELECT-Ausgabe. `USP_PrepareResultTable` und finaler Insert teilen OwnTX/Caller-Savepoint. Leerer Input und alle KeepDatafälle folgen dem Helper. Constraints bleiben und können Insert blockieren; dann eigenes Rollback bzw. Caller-Savepointrollback, niemals Caller-Commit/Outerrollback. Doomed Caller wird vor eigener Temp-DDL mit RAISERROR50000/1 und RETURN abgewiesen; Hilfe gewinnt. Distributed Savepointpfad nicht unterstützt; keine dauerhafte SET-Änderung.

Runtimefehler: 55100 Algorithmus/Schwelle; 55101 Budgetparameter; 55102 lokale Input-/Outputidentität; 55103 Inputshape; 55104 interne Tempkollision; 55105 Row-/Byteadmission/Stabilität; 55106 Ordinals; 55107 Workadmission; 55108 Providerkohärenz. Engine-/Helperfehler bleiben erhalten; Cleanupfehler sekundär. Lifecycle 55120..55129 separat im Deploy/Uninstall.

Rechte: vorhandenes EXECUTE und bestehende TVF-/Helper-SELECT-/Ownershipchain sowie eigene Tempmetadaten. Keine Runtime-Assemblyhashabfrage oder DB-VIEW-DEFINITION-Anforderung. Weitere Rechteprofile außerhalb der aktuell gebundenen Callerqualifikation bleiben offen. Separat central sind drei direkte Algorithmusconsumer mit fünf typgenauen Feldern und EOF/noNext sowie drei ResultTable-Aufrufe ohne Resultset nachgewiesen; weitere Client-/Zielkombinationen bleiben offen. Help bei später fehlenden statischen Dependencies bleibt ein konkretes Compile-/Nativegate.

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
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
<!-- API_PARAMETERS:END -->

## Beispielaufruf

```sql
CREATE TABLE #Pairs(PairOrdinal bigint,LeftText nvarchar(max),RightText nvarchar(max)); INSERT #Pairs VALUES(1,N'kitten',N'sitting'); EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'#Pairs',@Algorithm=N'levenshtein';
```

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#textdistanz).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/USP_CompareTextPairs.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
