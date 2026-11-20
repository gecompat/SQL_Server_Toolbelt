---
name: "toolbelt-toolbelt-toolbelt-file-tvf-formatxlsxcell"
description: "Formatiert eine XLSX-Einzelzelle mit den unterstützten Literalformaten und Kulturen."
skill_format_version: "1.0"
module_id: "toolbelt.file.xlsx-memory"
schema_name: "toolbelt_file"
object_name: "TVF_FormatXlsxCell"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@StoredType", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ, ordinal/case- und trailing-space-sensitiv: n = numerischer Rawwert; b = Booleanraw 0/1; s = Shared-String-Index in Raw plus bereits aufgelöster Text; inlineStr = Inline-Text ohne v/Raw; str = gespeicherter Stringcache, Raw und Text exakt gleich; d = ISO-Datum/-Datetime ohne Offset; e = gespeicherter Excelzellfehler, Status 10. NULL ergibt Absent/Status 1 nach allgemeinen Längen-/Unicodeprüfungen; leer/andere Werte Status 6. Höchstens 32 UTF-16-Einheiten, keine Normalisierung."}, {"name": "@ValuePresent", "sql_type": "bit", "sql_default": "NULL", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ im gebundenen bit: 1 bedeutet XML-v-Element vorhanden, nicht allgemein Zellinhalt vorhanden; 0 bedeutet kein v. NULL ergibt Status 1. inlineStr verlangt 0 und RawValue=NULL, sonst Status 2. Bei anderen StoredTypes bedeutet 0 nur dann absent, wenn RawValue und TextValue beide NULL sind; widersprüchliche Inhalte ergeben Status 2."}, {"name": "@RawValue", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Unveränderter Inhalt des gespeicherten v-Elements, maximal 65536 UTF-16-Einheiten; NULL bedeutet fehlendes v, leer bleibt von NULL verschieden. n akzeptiert ASCII-Zahlen mit optional +/- sowie Punkt/Exponent e/E, auch .5/1., ohne Spaces; für Number-/Serialparsing zusätzlich höchstens 128 Einheiten, exakter SqlDecimal-Bereich bis 38 Ziffern ohne Rundung. b verlangt exakt 0 oder 1; s einen nichtnegativen Int32-ASCII-Dezimalindex (führende Nullen erlaubt); str exakte Gleichheit zu TextValue; d ISO YYYY-MM-DD oder YYYY-MM-DDTHH:mm:ss[.1..7 Ziffern] passend zum Ziel, ohne Z/Offset. inlineStr verlangt NULL. Gespeicherter Formelcache kann übergeben werden, keine Formelberechnung. Allgemeine strikte UTF-16-Prüfung und atomare Ausgabequote gelten auch bei später ungenutztem Wert."}, {"name": "@TextValue", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Bereits aufgelöster Shared-/Inline-/Stringcache-Text, maximal 65536 wohlgeformte UTF-16-Einheiten; leer ist gültiger Text, NULL bedeutet kein Text. s benötigt ihn im Textzweig, inlineStr benötigt ihn zusammen mit Presence=0/Raw=NULL; str muss bytegenau mit RawValue übereinstimmen. Kein erneuter SST-/Workbookzugriff oder Trim. Der feste Outputcharge zählt Echos/Typedtext mehrfach und kann vor diesem einzelnen Inputmaximum greifen."}, {"name": "@TargetType", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ, ordinal ohne Trim: number = exakte SqlDecimal-Zahl; boolean = bit aus b; text = Stringtext beziehungsweise Rawdarstellung; date = Datum; datetime = datetime2(7); time = Uhrzeit unter 24h; duration = vorzeichenbehaftete 100ns-Ticks, auch über 24h. Maximal 32 UTF-16-Einheiten. NULL (Default) wählt zuerst die Formatklasse, ohne Format n→number, b→boolean, d→datetime, s/str/inlineStr→text. Leer/andere Werte oder Widerspruch zu Formatklasse ergeben Status 2. Kompatibilität mit StoredType bleibt erforderlich, keine allgemeine Cast-API. Die Anzeige unterstützt keinen eigenen Boolean-/Dauerformatrenderer."}, {"name": "@FormatCode", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ und exakt: 0 = Zahl ganzzahlig; 0.00 = Zahl mit zwei Dezimalstellen; #,##0.00 = Zahl mit Gruppierung/zwei Stellen; 0% = Prozent ganzzahlig; 0.00% = Prozent mit zwei Stellen; 0.00E+00 = wissenschaftliche Zahl mit zwei Mantissenstellen; yyyy-mm-dd = date; yyyy-mm-dd hh:mm:ss = datetime; hh:mm:ss = time; @ = text. Keine Excel-General-/Farb-/Locale-/Mehrsektionsgrammatik, kein Trim/Casefold; höchstens 128 UTF-16-Einheiten. NULL (Default) ergibt nach erfolgreicher Typinterpretation Status 2; unbekannt/leer Status 6. [h]:mm:ss wird vom geerbten Typkern erkannt, bleibt als Anzeigeformat unsupported/Status 6. Keine automatische Formatwahl; numerische Rundung half-away-from-zero, @ übernimmt Text unverändert."}, {"name": "@Date1904", "sql_type": "bit", "sql_default": "NULL", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ im gebundenen bit: 0 = Excel1900-Datumssystem, 1 = Excel1904-Datumssystem. NULL (Default) ist nur bei numerischem date-/datetime-Ziel ungültig (Status 2); sonst kein implizites Workbookauslesen. Im 1900-System ist ursprüngliches Serialintervall [60,61) der fiktive Schalttag und ergibt Status 7 vor Rundung. Zeit-/Dauerwerte benötigen keinen Datumssystemdefault."}, {"name": "@CultureName", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ und exakt: en-US = Dezimalpunkt/Gruppierungskomma; de-DE = Dezimalkomma/Gruppierungspunkt; tr-TR = Dezimalkomma/Gruppierungspunkt. Auch bei @-/Temporalformaten explizit erforderlich nach erfolgreicher Typinterpretation; NULL/leer/Aliase/andere Schreibweisen ergeben Status 2. Höchstens 32 UTF-16-Einheiten; keine CurrentCulture/OS-Overrides, Culture beeinflusst keine Inputlexik/Typwahl."}]
source_paths: ["Modules/toolbelt.file.xlsx-memory/Source/TVF_FormatXlsxCell.sql"]
review_status: "draft"
source_module_version: "1.2.0"
---

# TVF_FormatXlsxCell

## Zweck und Einsatzfälle

Formatiert eine XLSX-Einzelzelle mit den unterstützten Literalformaten und Kulturen.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@StoredType` | `nvarchar(max)` | `NULL` | Input | Taxativ, ordinal/case- und trailing-space-sensitiv: n = numerischer Rawwert; b = Booleanraw 0/1; s = Shared-String-Index in Raw plus bereits aufgelöster Text; inlineStr = Inline-Text ohne v/Raw; str = gespeicherter Stringcache, Raw und Text exakt gleich; d = ISO-Datum/-Datetime ohne Offset; e = gespeicherter Excelzellfehler, Status 10. NULL ergibt Absent/Status 1 nach allgemeinen Längen-/Unicodeprüfungen; leer/andere Werte Status 6. Höchstens 32 UTF-16-Einheiten, keine Normalisierung. |
| `@ValuePresent` | `bit` | `NULL` | Input | Taxativ im gebundenen bit: 1 bedeutet XML-v-Element vorhanden, nicht allgemein Zellinhalt vorhanden; 0 bedeutet kein v. NULL ergibt Status 1. inlineStr verlangt 0 und RawValue=NULL, sonst Status 2. Bei anderen StoredTypes bedeutet 0 nur dann absent, wenn RawValue und TextValue beide NULL sind; widersprüchliche Inhalte ergeben Status 2. |
| `@RawValue` | `nvarchar(max)` | `NULL` | Input | Unveränderter Inhalt des gespeicherten v-Elements, maximal 65536 UTF-16-Einheiten; NULL bedeutet fehlendes v, leer bleibt von NULL verschieden. n akzeptiert ASCII-Zahlen mit optional +/- sowie Punkt/Exponent e/E, auch .5/1., ohne Spaces; für Number-/Serialparsing zusätzlich höchstens 128 Einheiten, exakter SqlDecimal-Bereich bis 38 Ziffern ohne Rundung. b verlangt exakt 0 oder 1; s einen nichtnegativen Int32-ASCII-Dezimalindex (führende Nullen erlaubt); str exakte Gleichheit zu TextValue; d ISO YYYY-MM-DD oder YYYY-MM-DDTHH:mm:ss[.1..7 Ziffern] passend zum Ziel, ohne Z/Offset. inlineStr verlangt NULL. Gespeicherter Formelcache kann übergeben werden, keine Formelberechnung. Allgemeine strikte UTF-16-Prüfung und atomare Ausgabequote gelten auch bei später ungenutztem Wert. |
| `@TextValue` | `nvarchar(max)` | `NULL` | Input | Bereits aufgelöster Shared-/Inline-/Stringcache-Text, maximal 65536 wohlgeformte UTF-16-Einheiten; leer ist gültiger Text, NULL bedeutet kein Text. s benötigt ihn im Textzweig, inlineStr benötigt ihn zusammen mit Presence=0/Raw=NULL; str muss bytegenau mit RawValue übereinstimmen. Kein erneuter SST-/Workbookzugriff oder Trim. Der feste Outputcharge zählt Echos/Typedtext mehrfach und kann vor diesem einzelnen Inputmaximum greifen. |
| `@TargetType` | `nvarchar(max)` | `NULL` | Input | Taxativ, ordinal ohne Trim: number = exakte SqlDecimal-Zahl; boolean = bit aus b; text = Stringtext beziehungsweise Rawdarstellung; date = Datum; datetime = datetime2(7); time = Uhrzeit unter 24h; duration = vorzeichenbehaftete 100ns-Ticks, auch über 24h. Maximal 32 UTF-16-Einheiten. NULL (Default) wählt zuerst die Formatklasse, ohne Format n→number, b→boolean, d→datetime, s/str/inlineStr→text. Leer/andere Werte oder Widerspruch zu Formatklasse ergeben Status 2. Kompatibilität mit StoredType bleibt erforderlich, keine allgemeine Cast-API. Die Anzeige unterstützt keinen eigenen Boolean-/Dauerformatrenderer. |
| `@FormatCode` | `nvarchar(max)` | `NULL` | Input | Taxativ und exakt: 0 = Zahl ganzzahlig; 0.00 = Zahl mit zwei Dezimalstellen; #,##0.00 = Zahl mit Gruppierung/zwei Stellen; 0% = Prozent ganzzahlig; 0.00% = Prozent mit zwei Stellen; 0.00E+00 = wissenschaftliche Zahl mit zwei Mantissenstellen; yyyy-mm-dd = date; yyyy-mm-dd hh:mm:ss = datetime; hh:mm:ss = time; @ = text. Keine Excel-General-/Farb-/Locale-/Mehrsektionsgrammatik, kein Trim/Casefold; höchstens 128 UTF-16-Einheiten. NULL (Default) ergibt nach erfolgreicher Typinterpretation Status 2; unbekannt/leer Status 6. [h]:mm:ss wird vom geerbten Typkern erkannt, bleibt als Anzeigeformat unsupported/Status 6. Keine automatische Formatwahl; numerische Rundung half-away-from-zero, @ übernimmt Text unverändert. |
| `@Date1904` | `bit` | `NULL` | Input | Taxativ im gebundenen bit: 0 = Excel1900-Datumssystem, 1 = Excel1904-Datumssystem. NULL (Default) ist nur bei numerischem date-/datetime-Ziel ungültig (Status 2); sonst kein implizites Workbookauslesen. Im 1900-System ist ursprüngliches Serialintervall [60,61) der fiktive Schalttag und ergibt Status 7 vor Rundung. Zeit-/Dauerwerte benötigen keinen Datumssystemdefault. |
| `@CultureName` | `nvarchar(max)` | `NULL` | Input | Taxativ und exakt: en-US = Dezimalpunkt/Gruppierungskomma; de-DE = Dezimalkomma/Gruppierungspunkt; tr-TR = Dezimalkomma/Gruppierungspunkt. Auch bei @-/Temporalformaten explizit erforderlich nach erfolgreicher Typinterpretation; NULL/leer/Aliase/andere Schreibweisen ergeben Status 2. Höchstens 32 UTF-16-Einheiten; keine CurrentCulture/OS-Overrides, Culture beeinflusst keine Inputlexik/Typwahl. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_file.TVF_FormatXlsxCell(N'n', 1, N'1.235', NULL, N'number', N'0.00', 0, N'de-DE');
```

## Rechte

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aussagegrenzen

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.file.xlsx-memory/Documentation/TVF_FormatXlsxCell.md`

Keine Installations-, Definitions- oder Rechteattestation.
