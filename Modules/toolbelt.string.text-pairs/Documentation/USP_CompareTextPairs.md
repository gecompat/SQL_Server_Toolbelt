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

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@PairsTable` | `sysname` | `NULL` | Input | Lokale #Temp mit PairOrdinal bigint, LeftText und RightText nvarchar(max). Ordinals nicht NULL und eindeutig, inklusive negativer Werte. |
| `@Algorithm` | `nvarchar(max)` | `NULL` | Input | Bytegenau levenshtein, osa oder jaro-winkler; global für alle Paare. |
| `@MaxDistance` | `int` | `NULL` | Input | Unveränderte Distanzschwelle; bei Jaro ausschließlich NULL. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | standard oder large; genaue Limits stehen im Objektvertrag. |
| `@MaxPairs` | `int` | `10000` | Input | 1..100000, alle Inputzeilen zählen. |
| `@MaxTotalTextBytes` | `bigint` | `2097152` | Input | 1..16777216, beide DATALENGTH-Textseiten auch bei NULL-Gegenseite. |
| `@MaxTotalWork` | `bigint` | `16777216` | Input | 1..67108864 konservative UTF16-Produktcharge mit kanonischem Paircap; keine tatsächliche CPU-Zählung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL liefert sortierten SELECT; vorhandene lokale #Temp empfängt atomaren Helper+Insert. |
| `@KeepData` | `bit` | `0` | Input | 0 Replace, 1 Append nach ResultTable-Vertrag. NULL bedeutet 0. |
| `@Debug` | `tinyint` | `0` | Input | Messages ohne Textpayload; NULL bedeutet 0. |
| `@Hilfe` | `bit` | `0` | Input | 1 ausschließlich Help, ohne Tabellen-/Dependency-/Transaktionsprüfung. |

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
