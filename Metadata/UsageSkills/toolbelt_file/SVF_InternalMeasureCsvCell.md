---
name: "toolbelt-csv-svf-internalmeasurecsvcell"
description: "Interne exakte UTF-16-Bytemessung einer CSV-Zelle mit negativem Fehlercode."
skill_format_version: "1.0"
module_id: "toolbelt.file.csv-memory"
schema_name: "toolbelt_file"
object_name: "SVF_InternalMeasureCsvCell"
object_type: "CLR_SVF"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@Value", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Unveränderter UTF-16-Zellwert, leer erlaubt. NULL nur bei IsHeader=0 und aktivem NullToken darstellbar. NUL und ungepaarte Surrogate in nicht-NULL-Zelltext bleiben erhalten. Vor eigener Textkopie höchstens 16777216 Bytes. Kein SQL-Default; Argument ausdrücklich übergeben."}, {"name": "@Separator", "sql_type": "nvarchar(2)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Separator genau eine UTF-16-Codeunit, nicht NULL/leer, keine Doppelquote, CR, LF, NUL oder Surrogate. NullToken NULL deaktiviert SQL-NULL; sonst 1..128 Codeunits, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate. Gültige Surrogatpaare im Token sind erlaubt. Tokenvergleich exakt nach Länge und Codeunits, nicht SQL-Padding. Kein SQL-Default; Argument ausdrücklich übergeben."}, {"name": "@NullToken", "sql_type": "nvarchar(128)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "NULL deaktiviert SQL-NULL-Token; sonst gültiges Token gemäß Dialekt. Exakter Codeunit-/Längenvergleich. Kein SQL-Default; Argument ausdrücklich übergeben."}, {"name": "@IsHeader", "sql_type": "bit", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "0 DATA-Zelle; 1 HEADER-Zelle. NULL ist ungültig. Kein SQL-Default; Argument ausdrücklich übergeben."}]
source_paths: ["Modules/toolbelt.file.csv-memory/Source/SVF_InternalMeasureCsvCell.sql", "Modules/toolbelt.file.csv-memory/Clr/CsvEntryPoints.cs", "Modules/toolbelt.file.csv-memory/Clr/CsvKernel.cs"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_file.USP_WriteCsv"]
---

# SVF_InternalMeasureCsvCell

## Zweck und Einsatzfälle

Interne exakte UTF-16-Bytemessung einer CSV-Zelle mit negativem Fehlercode. Internes Transportdetail, regulärer Einstieg toolbelt_file.USP_WriteCsv.

## Voraussetzungen

Installiertes Modul mit autorisierter SAFE-Assembly tlblt_File_CsvMemory, SQL Server 2019/2022/2025 auf Windows/Linux gemäß Modulmatrix, CL150/160/170 soweit zur Engine passend, lokal oder zentral. Kein Datei-, Netzwerk- oder Encodingprovider. Separator genau eine UTF-16-Codeunit, nicht NULL/leer, keine Doppelquote, CR, LF, NUL oder Surrogate. NullToken NULL deaktiviert SQL-NULL; sonst 1..128 Codeunits, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate. Gültige Surrogatpaare im Token sind erlaubt. Tokenvergleich exakt nach Länge und Codeunits, nicht SQL-Padding.

## Parameter und Zugriff

| Parameter | SQL-Typ | Vertrag |
|---|---|---|
| `@Value` | `nvarchar(max)` | Unveränderter UTF-16-Zellwert, leer erlaubt. NULL nur bei IsHeader=0 und aktivem NullToken darstellbar. NUL und ungepaarte Surrogate in nicht-NULL-Zelltext bleiben erhalten. Vor eigener Textkopie höchstens 16777216 Bytes. Kein SQL-Default; Argument ausdrücklich übergeben. |
| `@Separator` | `nvarchar(2)` | Separator genau eine UTF-16-Codeunit, nicht NULL/leer, keine Doppelquote, CR, LF, NUL oder Surrogate. NullToken NULL deaktiviert SQL-NULL; sonst 1..128 Codeunits, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate. Gültige Surrogatpaare im Token sind erlaubt. Tokenvergleich exakt nach Länge und Codeunits, nicht SQL-Padding. Kein SQL-Default; Argument ausdrücklich übergeben. |
| `@NullToken` | `nvarchar(128)` | NULL deaktiviert SQL-NULL-Token; sonst gültiges Token gemäß Dialekt. Exakter Codeunit-/Längenvergleich. Kein SQL-Default; Argument ausdrücklich übergeben. |
| `@IsHeader` | `bit` | 0 DATA-Zelle; 1 HEADER-Zelle. NULL ist ungültig. Kein SQL-Default; Argument ausdrücklich übergeben. |

## Ergebnisse

Ein bigint: nichtnegatives exaktes Maß in UTF-16-Bytes einschließlich Zellquotes und Quoteverdopplung, aber ohne Separator oder Recordabschluss; leere Zelle kann 0 ergeben. Eigener CsvFault wird als negativer Fehlercode -55300/-55303/-55307 geliefert, nicht SQL-NULL. Technische Exceptions werden nicht in Zahlen umklassifiziert.

## Aufrufbeispiele

```sql
SELECT toolbelt_file.SVF_InternalMeasureCsvCell(N'a,b',N',',NULL,CONVERT(bit,0)) AS CellBytes;
-- 10 Bytes: zwei Hüllquotes und drei Text-Codeunits.
```

## Rechte

Vorhandenes EXECUTE auf diesem internen skalaren CLR-Objekt nur im ausdrücklich autorisierten Implementierungs-/Testscope. Öffentliche Anwendungen folgen dem Callerprofil von toolbelt_file.USP_WriteCsv. CLR-/Assemblytrustvoraussetzungen separat erfüllen; diese Funktion erteilt keine Rechte, prüft keine Serveridentität und greift nicht auf Daten-/Systemkataloge zu.

## Ressourcenbedarf

AnalyzeCell kopiert den vollständigen nicht-NULL-Zelltext nach Prüfung der festen 16777216-Byte-Eingangsgrenze. Exaktes Maß = 2*(Text-Codeunits + innere Quoteanzahl + gegebenenfalls 2 Hüllquotes). NULL-Token kostet 2*Token-Codeunits. Kein escaped Fragment wird erzeugt; eigenes vollständiges char[] entsteht dennoch. Kein Tabellen-/Gesamtausgabebudget in dieser Funktion.

## Nebenwirkungen

Deterministische speicherreine Berechnung aus expliziten Argumenten. Keine Datei-/Netzwerk-/Katalogoperation, Temp-Tabelle, Transaktion, Callerzustandsänderung oder persistente Mutation. Kein Hilfeschalter an dieser Funktion; vollständiger Skill in ausgelieferter DDL und künftig im gemeinsamen Skillkatalog.

## Fehlerbehandlung

IsHeader=NULL, ungültiger Dialekt, nichtdarstellbares NULL oder zu große Rohzelle werden ausschließlich bei MeasureCell als negativer eigener CsvFault-Code zurückgegeben; sonst bleiben technische Exceptions erhalten.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Gesamtqualifikation. Historische Fach-/Caller-/Paketnachweise behalten ihre ursprüngliche Bindung. Keine Installations- oder Rechteattestation, keine unbegrenzte Ausgabe, keine Datenbereinigung oder allgemeine RFC-/Spreadsheet-/Dateiimportgarantie.
