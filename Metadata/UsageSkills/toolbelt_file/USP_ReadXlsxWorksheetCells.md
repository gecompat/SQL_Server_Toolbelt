---
name: "toolbelt-toolbelt-toolbelt-file-usp-readxlsxworksheetcells"
description: "Begrenzter SAFE Binary-XLSX-Reader; atomarer gewählter Snapshot, keine Datei-/Netzwerkzugriffe, Formelberechnung oder Typinferenz."
skill_format_version: "1.0"
module_id: "toolbelt.file.xlsx-memory"
schema_name: "toolbelt_file"
object_name: "USP_ReadXlsxWorksheetCells"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@XlsxBinary", "sql_type": "varbinary(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Vollständiger XLSX-Bytepuffer varbinary(max), kein Pfad/Base64text. Unterstützt Transitional-XLSX mit kanonischen Stored-/Deflate-ZIP-Parts, sicheren lokalen Relationships und XML ohne DTD/externe Auflösung; keine XLS/XLSB-/verschlüsselten Workbooks oder Makroausführung. Leer ist ungültig. NULL (Default) liefert keine Zeilen vor Sheet-/Limit-/Dependency-/Zielprüfung und lässt ResultTable unverändert."}, {"name": "@SheetOrdinal", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche positive int-Worksheetnummer aus USP_ListXlsxWorksheets, 1-basiert in Workbookreihenfolge; keine SheetId, kein Name und keine nullbasierte Position. Muss tatsächlich existieren. NULL (technischer Default)/0/negativ ungültig bei nicht-NULL-XlsxBinary; bei NULL-Binary ignoriert."}, {"name": "@MaxArchiveBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216, Default 16777216: komprimierte Bytes des vollständigen XLSX-Inputs. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung."}, {"name": "@MaxPartBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216, Default 16777216: unkomprimierte Bytes je ZIP-/XML-Part. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung."}, {"name": "@MaxTotalUncompressedBytes", "sql_type": "bigint", "sql_default": "67108864", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..67108864, Default 67108864: globale unkomprimierte ZIP-/Partbytes; zusätzliche gezählte XML-Materialisierung bleibt begrenzt. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung."}, {"name": "@MaxParts", "sql_type": "int", "sql_default": "256", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..256, Default 256: ZIP-Parts einschließlich nicht als Zelloutput gewählter Einträge. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung."}, {"name": "@MaxSheets", "sql_type": "int", "sql_default": "32", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..32, Default 32: Worksheet-Metadaten im Workbook, nicht nur der ausgewählte Sheet. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung."}, {"name": "@MaxCells", "sql_type": "int", "sql_default": "100000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..100000, Default 100000: vorhandene sparse Zellen des gelesenen Worksheets; keine aufgefüllten Rechteckzellen. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung."}, {"name": "@MaxSharedStrings", "sql_type": "int", "sql_default": "50000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..50000, Default 50000: Einträge der Shared-String-Tabelle. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung."}, {"name": "@MaxSharedStringBytes", "sql_type": "bigint", "sql_default": "8388608", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..8388608, Default 8388608: decodierte UTF-16-Bytes der Shared-String-Texte, nicht komprimierte XML-Bytes. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung."}, {"name": "@MaxXmlDepth", "sql_type": "int", "sql_default": "64", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..64, Default 64: XmlReader-Tiefe; XML-Root hat Depth 0. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung."}, {"name": "@MaxCompressionRatio", "sql_type": "decimal(18,4)", "sql_default": "200", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "decimal(18,4) im inklusiven Bereich 1..200, Default 200. Deklarierte Uncompressed-/Compressed-Byte-Ratio der ZIP-Einträge; Bruchteile sind zulässig. NULL/<1/>200 ungültig bei nicht-NULL-Binary. Kein Prozentsatz und keine globale Heapgarantie."}, {"name": "@BudgetMilliseconds", "sql_type": "int", "sql_default": "5000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..5000, Default 5000: Millisekunden kooperatives Verarbeitungsbudget; keine harte SQL-Marshalling-/Gesamtwallclock-Garantie. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix. XlsxBinary=NULL lässt das Ziel vollständig unverändert und prüft es nicht."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Keine Workbookinhalte; im Zielpfad zusätzlich Helperdiagnose."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.file.xlsx-memory/Source/USP_ReadXlsxWorksheetCells.sql"]
review_status: "draft"
source_module_version: "1.2.0"
---

# USP_ReadXlsxWorksheetCells

## Zweck und Einsatzfälle

Begrenzter SAFE Binary-XLSX-Reader; atomarer gewählter Snapshot, keine Datei-/Netzwerkzugriffe, Formelberechnung oder Typinferenz.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@XlsxBinary` | `varbinary(max)` | `NULL` | Input | Vollständiger XLSX-Bytepuffer varbinary(max), kein Pfad/Base64text. Unterstützt Transitional-XLSX mit kanonischen Stored-/Deflate-ZIP-Parts, sicheren lokalen Relationships und XML ohne DTD/externe Auflösung; keine XLS/XLSB-/verschlüsselten Workbooks oder Makroausführung. Leer ist ungültig. NULL (Default) liefert keine Zeilen vor Sheet-/Limit-/Dependency-/Zielprüfung und lässt ResultTable unverändert. |
| `@SheetOrdinal` | `int` | `NULL` | Input | Fachlich erforderliche positive int-Worksheetnummer aus USP_ListXlsxWorksheets, 1-basiert in Workbookreihenfolge; keine SheetId, kein Name und keine nullbasierte Position. Muss tatsächlich existieren. NULL (technischer Default)/0/negativ ungültig bei nicht-NULL-XlsxBinary; bei NULL-Binary ignoriert. |
| `@MaxArchiveBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216, Default 16777216: komprimierte Bytes des vollständigen XLSX-Inputs. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxPartBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216, Default 16777216: unkomprimierte Bytes je ZIP-/XML-Part. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxTotalUncompressedBytes` | `bigint` | `67108864` | Input | Ganzzahl 1..67108864, Default 67108864: globale unkomprimierte ZIP-/Partbytes; zusätzliche gezählte XML-Materialisierung bleibt begrenzt. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxParts` | `int` | `256` | Input | Ganzzahl 1..256, Default 256: ZIP-Parts einschließlich nicht als Zelloutput gewählter Einträge. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxSheets` | `int` | `32` | Input | Ganzzahl 1..32, Default 32: Worksheet-Metadaten im Workbook, nicht nur der ausgewählte Sheet. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxCells` | `int` | `100000` | Input | Ganzzahl 1..100000, Default 100000: vorhandene sparse Zellen des gelesenen Worksheets; keine aufgefüllten Rechteckzellen. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxSharedStrings` | `int` | `50000` | Input | Ganzzahl 1..50000, Default 50000: Einträge der Shared-String-Tabelle. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxSharedStringBytes` | `bigint` | `8388608` | Input | Ganzzahl 1..8388608, Default 8388608: decodierte UTF-16-Bytes der Shared-String-Texte, nicht komprimierte XML-Bytes. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxXmlDepth` | `int` | `64` | Input | Ganzzahl 1..64, Default 64: XmlReader-Tiefe; XML-Root hat Depth 0. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@MaxCompressionRatio` | `decimal(18,4)` | `200` | Input | decimal(18,4) im inklusiven Bereich 1..200, Default 200. Deklarierte Uncompressed-/Compressed-Byte-Ratio der ZIP-Einträge; Bruchteile sind zulässig. NULL/&lt;1/&gt;200 ungültig bei nicht-NULL-Binary. Kein Prozentsatz und keine globale Heapgarantie. |
| `@BudgetMilliseconds` | `int` | `5000` | Input | Ganzzahl 1..5000, Default 5000: Millisekunden kooperatives Verarbeitungsbudget; keine harte SQL-Marshalling-/Gesamtwallclock-Garantie. Explizites NULL/0/negativ/höher ungültig bei nicht-NULL-XlsxBinary. Nur absenkbar; ein früher NULL-Binary-Pfad überspringt die Prüfung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix. XlsxBinary=NULL lässt das Ziel vollständig unverändert und prüft es nicht. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Keine Workbookinhalte; im Zielpfad zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

Einsbasierte Zeile.

Einsbasierte Spalte.

Gespeicherter Zelltyp, keine Typinferenz.

Gespeichertes v-Element vorhanden, auch wenn leer.

Rohtext aus v, NULL bei fehlendem v.

Shared-/Inline-/str-Text, kein Excel-Anzeigeformat.

f-Element vorhanden.

Unveränderter Formeltext, keine Berechnung.

normal, shared, array oder dataTable.

Gespeichertes si, keine Formelrekonstruktion.

Formel und v-Element vorhanden.

Gespeicherter Formelcache-Rohtext.

## Aufrufbeispiele

```sql
EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @Hilfe = 1;
-- @SyntheticWorkbook stammt ausschließlich aus einem synthetischen Testfixture.
EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @XlsxBinary = @SyntheticWorkbook, @SheetOrdinal = 1;
```

## Rechte

EXECUTE auf USP; ResultTable zusätzlich Helper-EXECUTE und Sichtbarkeit der caller-lokalen Tabelle. Keine Rechteausweitung.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Begrenzte Kategorie eines erwarteten Input-/Container-/XML-/Feature-/Ressourcenfehlers; keine Teilausgabe.

Fehlende oder inkonsistente registrierte Dependency bzw. interner Providervertrag.

## Aussagegrenzen

Transitional XLSX, klassische Stored-/Deflate-ZIPs. Kein ZIP64, externe Beziehungen, Makros oder Strict Open XML. Unicode bleibt unverändert, Tabellen brauchen explizite Ordinals zum Sortieren.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.file.xlsx-memory/Documentation/USP_ReadXlsxWorksheetCells.md`

Keine Installations-, Definitions- oder Rechteattestation.
