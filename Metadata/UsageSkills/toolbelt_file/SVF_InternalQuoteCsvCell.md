---
name: "toolbelt-csv-svf-internalquotecsvcell"
description: "Internes CSV-Zellquoting ausschließlich nach vollständigem Budgetpreflight."
skill_format_version: "1.0"
module_id: "toolbelt.file.csv-memory"
schema_name: "toolbelt_file"
object_name: "SVF_InternalQuoteCsvCell"
object_type: "CLR_SVF"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@Value", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Unveränderter UTF-16-Zellwert, leer erlaubt. NULL nur bei IsHeader=0 und aktivem NullToken darstellbar. NUL und ungepaarte Surrogate in nicht-NULL-Zelltext bleiben erhalten. Vor eigener Textkopie höchstens 16777216 Bytes. Kein SQL-Default; Argument ausdrücklich übergeben."}, {"name": "@Separator", "sql_type": "nvarchar(2)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Separator genau eine UTF-16-Codeunit, nicht NULL/leer, keine Doppelquote, CR, LF, NUL oder Surrogate. NullToken NULL deaktiviert SQL-NULL; sonst 1..128 Codeunits, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate. Gültige Surrogatpaare im Token sind erlaubt. Tokenvergleich exakt nach Länge und Codeunits, nicht SQL-Padding. Kein SQL-Default; Argument ausdrücklich übergeben."}, {"name": "@NullToken", "sql_type": "nvarchar(128)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "NULL deaktiviert SQL-NULL-Token; sonst gültiges Token gemäß Dialekt. Exakter Codeunit-/Längenvergleich. Kein SQL-Default; Argument ausdrücklich übergeben."}, {"name": "@IsHeader", "sql_type": "bit", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "0 DATA-Zelle; 1 HEADER-Zelle. NULL ist ungültig. Kein SQL-Default; Argument ausdrücklich übergeben."}, {"name": "@MaxOutputBytes", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "1..16777216 UTF-16-Bytes. Nicht NULL; gemessene Zelle muss hineinpassen. Das ist nur ein Zellargument, keine globale Tabellen-/CSV-Budgetprüfung. Kein SQL-Default; Argument ausdrücklich übergeben."}]
source_paths: ["Modules/toolbelt.file.csv-memory/Source/SVF_InternalQuoteCsvCell.sql", "Modules/toolbelt.file.csv-memory/Clr/CsvEntryPoints.cs", "Modules/toolbelt.file.csv-memory/Clr/CsvKernel.cs"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_file.USP_WriteCsv"]
---

# SVF_InternalQuoteCsvCell

## Zweck und Einsatzfälle

Internes CSV-Zellquoting ausschließlich nach vollständigem Budgetpreflight. Internes Transportdetail, regulärer Einstieg toolbelt_file.USP_WriteCsv.

## Voraussetzungen

Installiertes Modul mit autorisierter SAFE-Assembly tlblt_File_CsvMemory, SQL Server 2019/2022/2025 auf Windows/Linux gemäß Modulmatrix, CL150/160/170 soweit zur Engine passend, lokal oder zentral. Kein Datei-, Netzwerk- oder Encodingprovider. Separator genau eine UTF-16-Codeunit, nicht NULL/leer, keine Doppelquote, CR, LF, NUL oder Surrogate. NullToken NULL deaktiviert SQL-NULL; sonst 1..128 Codeunits, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate. Gültige Surrogatpaare im Token sind erlaubt. Tokenvergleich exakt nach Länge und Codeunits, nicht SQL-Padding.

## Parameter und Zugriff

| Parameter | SQL-Typ | Vertrag |
|---|---|---|
| `@Value` | `nvarchar(max)` | Unveränderter UTF-16-Zellwert, leer erlaubt. NULL nur bei IsHeader=0 und aktivem NullToken darstellbar. NUL und ungepaarte Surrogate in nicht-NULL-Zelltext bleiben erhalten. Vor eigener Textkopie höchstens 16777216 Bytes. Kein SQL-Default; Argument ausdrücklich übergeben. |
| `@Separator` | `nvarchar(2)` | Separator genau eine UTF-16-Codeunit, nicht NULL/leer, keine Doppelquote, CR, LF, NUL oder Surrogate. NullToken NULL deaktiviert SQL-NULL; sonst 1..128 Codeunits, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate. Gültige Surrogatpaare im Token sind erlaubt. Tokenvergleich exakt nach Länge und Codeunits, nicht SQL-Padding. Kein SQL-Default; Argument ausdrücklich übergeben. |
| `@NullToken` | `nvarchar(128)` | NULL deaktiviert SQL-NULL-Token; sonst gültiges Token gemäß Dialekt. Exakter Codeunit-/Längenvergleich. Kein SQL-Default; Argument ausdrücklich übergeben. |
| `@IsHeader` | `bit` | 0 DATA-Zelle; 1 HEADER-Zelle. NULL ist ungültig. Kein SQL-Default; Argument ausdrücklich übergeben. |
| `@MaxOutputBytes` | `bigint` | 1..16777216 UTF-16-Bytes. Nicht NULL; gemessene Zelle muss hineinpassen. Das ist nur ein Zellargument, keine globale Tabellen-/CSV-Budgetprüfung. Kein SQL-Default; Argument ausdrücklich übergeben. |

## Ergebnisse

Ein nvarchar(max)-Fragment einschließlich gegebenenfalls äußerer Doppelquotes und verdoppelter innerer Quotes, ohne Separator oder Recordabschluss. Bei Erfolg nicht NULL; leere Zelle ergibt leeren Text. SQL-NULL wird bei aktivem Token als unquoted Token geschrieben. Ein wörtlich gleicher Text wird zur Unterscheidung quoted. Keine Statusspalte und keine negative Fehlerzahl.

## Aufrufbeispiele

```sql
DECLARE @Bytes bigint=toolbelt_file.SVF_InternalMeasureCsvCell(N'a,b',N',',NULL,CONVERT(bit,0));
IF @Bytes<>10 THROW 50000,N'Synthetischer Zellpreflight fehlgeschlagen.',1;
SELECT toolbelt_file.SVF_InternalQuoteCsvCell(N'a,b',N',',NULL,CONVERT(bit,0),10) AS Fragment;
-- Nur isolierte Einzelzellgegenprobe; vollständiges CSV über USP_WriteCsv.
```

## Rechte

Vorhandenes EXECUTE auf diesem internen skalaren CLR-Objekt nur im ausdrücklich autorisierten Implementierungs-/Testscope. Öffentliche Anwendungen folgen dem Callerprofil von toolbelt_file.USP_WriteCsv. CLR-/Assemblytrustvoraussetzungen separat erfüllen; diese Funktion erteilt keine Rechte, prüft keine Serveridentität und greift nicht auf Daten-/Systemkataloge zu.

## Ressourcenbedarf

AnalyzeCell kopiert den vollständigen nicht-NULL-Zelltext nach Prüfung der festen 16777216-Byte-Eingangsgrenze. Exaktes Maß = 2*(Text-Codeunits + innere Quoteanzahl + gegebenenfalls 2 Hüllquotes). NULL-Token kostet 2*Token-Codeunits. Quote allokiert danach exakt gemessene char[]-Ausgabe innerhalb MaxOutputBytes. Das feste Limit für MaxOutputBytes wird geprüft; öffentliche USP muss vorher auch alle anderen Zellen und Separatoren/Endings global messen. Keine erfolgreiche Kürzung.

## Nebenwirkungen

Deterministische speicherreine Berechnung aus expliziten Argumenten. Keine Datei-/Netzwerk-/Katalogoperation, Temp-Tabelle, Transaktion, Callerzustandsänderung oder persistente Mutation. Kein Hilfeschalter an dieser Funktion; vollständiger Skill in ausgelieferter DDL und künftig im gemeinsamen Skillkatalog.

## Fehlerbehandlung

IsHeader=NULL oder MaxOutputBytes=NULL sowie gemessenes Maß über MaxOutputBytes werfen InvalidOperationException CSV_QUOTE_PREVALIDATION_REQUIRED. Ungültiges Limit, Dialekt oder NULL-Darstellung werfen eigenen CsvFault als CLR-Exception, nicht negativen Status. CSV_QUOTE_INVARIANT bei unerwartet abweichender Allokation. Keine pauschale Fehlerübersetzung; öffentlicher Writer muss Vorprüfung und Nachvergleich übernehmen.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Gesamtqualifikation. Historische Fach-/Caller-/Paketnachweise behalten ihre ursprüngliche Bindung. Keine Installations- oder Rechteattestation, keine unbegrenzte Ausgabe, keine Datenbereinigung oder allgemeine RFC-/Spreadsheet-/Dateiimportgarantie.
