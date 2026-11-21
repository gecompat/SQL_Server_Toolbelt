---
name: "toolbelt-tvf-internalinterpretxlsxcell"
description: "Interner datenzugriffsfreier CLR-Typkern für eine gespeicherte XLSX-Zelle."
skill_format_version: "1.0"
module_id: "toolbelt.file.xlsx-memory"
schema_name: "toolbelt_file"
object_name: "TVF_InternalInterpretXlsxCell"
object_type: "CLR_TVF"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@StoredType", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ, ordinal/case- und trailing-space-sensitiv: n = numerischer Rawwert; b = Booleanraw 0/1; s = Shared-String-Index in Raw plus bereits aufgelöster Text; inlineStr = Inline-Text ohne v/Raw; str = gespeicherter Stringcache, Raw und Text exakt gleich; d = ISO-Datum/-Datetime ohne Offset; e = gespeicherter Excelzellfehler, Status 10. NULL ergibt Absent/Status 1 nach allgemeinen Längen-/Unicodeprüfungen; leer/andere Werte Status 6. Höchstens 32 UTF-16-Einheiten, keine Normalisierung."}, {"name": "@ValuePresent", "sql_type": "bit", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ im gebundenen bit: 1 bedeutet XML-v-Element vorhanden, nicht allgemein Zellinhalt vorhanden; 0 bedeutet kein v. NULL ergibt Status 1. inlineStr verlangt 0 und RawValue=NULL, sonst Status 2. Bei anderen StoredTypes bedeutet 0 nur dann absent, wenn RawValue und TextValue beide NULL sind; widersprüchliche Inhalte ergeben Status 2."}, {"name": "@RawValue", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Unveränderter Inhalt des gespeicherten v-Elements, maximal 65536 UTF-16-Einheiten; NULL bedeutet fehlendes v, leer bleibt von NULL verschieden. n akzeptiert ASCII-Zahlen mit optional +/- sowie Punkt/Exponent e/E, auch .5/1., ohne Spaces; für Number-/Serialparsing zusätzlich höchstens 128 Einheiten, exakter SqlDecimal-Bereich bis 38 Ziffern ohne Rundung. b verlangt exakt 0 oder 1; s einen nichtnegativen Int32-ASCII-Dezimalindex (führende Nullen erlaubt); str exakte Gleichheit zu TextValue; d ISO YYYY-MM-DD oder YYYY-MM-DDTHH:mm:ss[.1..7 Ziffern] passend zum Ziel, ohne Z/Offset. inlineStr verlangt NULL. Gespeicherter Formelcache kann übergeben werden, keine Formelberechnung. Allgemeine strikte UTF-16-Prüfung und atomare Ausgabequote gelten auch bei später ungenutztem Wert."}, {"name": "@TextValue", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Bereits aufgelöster Shared-/Inline-/Stringcache-Text, maximal 65536 wohlgeformte UTF-16-Einheiten; leer ist gültiger Text, NULL bedeutet kein Text. s benötigt ihn im Textzweig, inlineStr benötigt ihn zusammen mit Presence=0/Raw=NULL; str muss bytegenau mit RawValue übereinstimmen. Kein erneuter SST-/Workbookzugriff oder Trim. Der feste Outputcharge zählt Echos/Typedtext mehrfach und kann vor diesem einzelnen Inputmaximum greifen."}, {"name": "@TargetType", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ, ordinal ohne Trim: number = exakte SqlDecimal-Zahl; boolean = bit aus b; text = Stringtext beziehungsweise Rawdarstellung; date = Datum; datetime = datetime2(7); time = Uhrzeit unter 24h; duration = vorzeichenbehaftete 100ns-Ticks, auch über 24h. Maximal 32 UTF-16-Einheiten. NULL (Default) wählt zuerst die Formatklasse, ohne Format n→number, b→boolean, d→datetime, s/str/inlineStr→text. Leer/andere Werte oder Widerspruch zu Formatklasse ergeben Status 2. Kompatibilität mit StoredType bleibt erforderlich, keine allgemeine Cast-API."}, {"name": "@FormatCode", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Exakte endliche Klassifikation: 0,0.00,#,##0.00,0%,0.00%,0.00E+00 -> number; yyyy-mm-dd -> date; yyyy-mm-dd hh:mm:ss -> datetime; hh:mm:ss -> time; [h]:mm:ss -> duration; @ -> text. Höchstens128 UTF16-Einheiten. NULL klassifiziert nicht und erlaubt Ziel-/StoredType-Default; leer/unbekannt Status6, Widerspruch zum expliziten Target Status2. Dieser Typkern rendert kein Anzeigeformat und liest keine Styles."}, {"name": "@Date1904", "sql_type": "bit", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ im gebundenen bit: 0 = Excel1900-Datumssystem, 1 = Excel1904-Datumssystem. NULL (Default) ist nur bei numerischem date-/datetime-Ziel ungültig (Status 2); sonst kein implizites Workbookauslesen. Im 1900-System ist ursprüngliches Serialintervall [60,61) der fiktive Schalttag und ergibt Status 7 vor Rundung. Zeit-/Dauerwerte benötigen keinen Datumssystemdefault."}]
source_paths: ["Modules/toolbelt.file.xlsx-memory/Source/TVF_InternalInterpretXlsxCell.sql"]
review_status: "verified"
source_module_version: "1.2.0"
public_entrypoints: ["toolbelt_file.TVF_InterpretXlsxCell"]
---

# TVF_InternalInterpretXlsxCell

## Zweck und Einsatzfälle

Interner datenzugriffsfreier CLR-Typkern für eine gespeicherte XLSX-Zelle.

## Voraussetzungen

Modul XLSXmemory1.2.0 mit SAFE-Assembly tlblt_File_XlsxMemory, ZIPmemory>=1.4.0 und ResultTable>=1.0.0 gemäß Modulabhängigkeiten. Unterstützte SQL2019/2022/2025 Windows/Linux-Kontexte gemäß Modulmatrix, vorhandene CLR-/Trustvoraussetzungen. Keine Installation, Rechteerteilung, Labänderung oder Datenquelle wird durch diesen Aufruf vorbereitet.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@StoredType` | `nvarchar(max)` | kein Default | Input | Taxativ, ordinal/case- und trailing-space-sensitiv: n = numerischer Rawwert; b = Booleanraw 0/1; s = Shared-String-Index in Raw plus bereits aufgelöster Text; inlineStr = Inline-Text ohne v/Raw; str = gespeicherter Stringcache, Raw und Text exakt gleich; d = ISO-Datum/-Datetime ohne Offset; e = gespeicherter Excelzellfehler, Status 10. NULL ergibt Absent/Status 1 nach allgemeinen Längen-/Unicodeprüfungen; leer/andere Werte Status 6. Höchstens 32 UTF-16-Einheiten, keine Normalisierung. |
| `@ValuePresent` | `bit` | kein Default | Input | Taxativ im gebundenen bit: 1 bedeutet XML-v-Element vorhanden, nicht allgemein Zellinhalt vorhanden; 0 bedeutet kein v. NULL ergibt Status 1. inlineStr verlangt 0 und RawValue=NULL, sonst Status 2. Bei anderen StoredTypes bedeutet 0 nur dann absent, wenn RawValue und TextValue beide NULL sind; widersprüchliche Inhalte ergeben Status 2. |
| `@RawValue` | `nvarchar(max)` | kein Default | Input | Unveränderter Inhalt des gespeicherten v-Elements, maximal 65536 UTF-16-Einheiten; NULL bedeutet fehlendes v, leer bleibt von NULL verschieden. n akzeptiert ASCII-Zahlen mit optional +/- sowie Punkt/Exponent e/E, auch .5/1., ohne Spaces; für Number-/Serialparsing zusätzlich höchstens 128 Einheiten, exakter SqlDecimal-Bereich bis 38 Ziffern ohne Rundung. b verlangt exakt 0 oder 1; s einen nichtnegativen Int32-ASCII-Dezimalindex (führende Nullen erlaubt); str exakte Gleichheit zu TextValue; d ISO YYYY-MM-DD oder YYYY-MM-DDTHH:mm:ss[.1..7 Ziffern] passend zum Ziel, ohne Z/Offset. inlineStr verlangt NULL. Gespeicherter Formelcache kann übergeben werden, keine Formelberechnung. Allgemeine strikte UTF-16-Prüfung und atomare Ausgabequote gelten auch bei später ungenutztem Wert. |
| `@TextValue` | `nvarchar(max)` | kein Default | Input | Bereits aufgelöster Shared-/Inline-/Stringcache-Text, maximal 65536 wohlgeformte UTF-16-Einheiten; leer ist gültiger Text, NULL bedeutet kein Text. s benötigt ihn im Textzweig, inlineStr benötigt ihn zusammen mit Presence=0/Raw=NULL; str muss bytegenau mit RawValue übereinstimmen. Kein erneuter SST-/Workbookzugriff oder Trim. Der feste Outputcharge zählt Echos/Typedtext mehrfach und kann vor diesem einzelnen Inputmaximum greifen. |
| `@TargetType` | `nvarchar(max)` | kein Default | Input | Taxativ, ordinal ohne Trim: number = exakte SqlDecimal-Zahl; boolean = bit aus b; text = Stringtext beziehungsweise Rawdarstellung; date = Datum; datetime = datetime2(7); time = Uhrzeit unter 24h; duration = vorzeichenbehaftete 100ns-Ticks, auch über 24h. Maximal 32 UTF-16-Einheiten. NULL (Default) wählt zuerst die Formatklasse, ohne Format n→number, b→boolean, d→datetime, s/str/inlineStr→text. Leer/andere Werte oder Widerspruch zu Formatklasse ergeben Status 2. Kompatibilität mit StoredType bleibt erforderlich, keine allgemeine Cast-API. |
| `@FormatCode` | `nvarchar(max)` | kein Default | Input | Exakte endliche Klassifikation: 0,0.00,#,##0.00,0%,0.00%,0.00E+00 -> number; yyyy-mm-dd -> date; yyyy-mm-dd hh:mm:ss -> datetime; hh:mm:ss -> time; [h]:mm:ss -> duration; @ -> text. Höchstens128 UTF16-Einheiten. NULL klassifiziert nicht und erlaubt Ziel-/StoredType-Default; leer/unbekannt Status6, Widerspruch zum expliziten Target Status2. Dieser Typkern rendert kein Anzeigeformat und liest keine Styles. |
| `@Date1904` | `bit` | kein Default | Input | Taxativ im gebundenen bit: 0 = Excel1900-Datumssystem, 1 = Excel1904-Datumssystem. NULL (Default) ist nur bei numerischem date-/datetime-Ziel ungültig (Status 2); sonst kein implizites Workbookauslesen. Im 1900-System ist ursprüngliches Serialintervall [60,61) der fiktive Schalttag und ergibt Status 7 vor Rundung. Zeit-/Dauerwerte benötigen keinen Datumssystemdefault. |

CLR-FT:alle Argumente explizit,keine SQL-Defaults.

## Ergebnisse

Genau eine Zeile mit14Feldern in dieser Reihenfolge: StoredType nvarchar(32) NULL, ValuePresent bit NULL, RawValue nvarchar(max) NULL, TextValue nvarchar(max) NULL, EchoPreserved bit, ResolvedType nvarchar(16) NULL, NumberValue sql_variant NULL (tatsächlich exakter SqlDecimal mit höchstens38 Stellen), BooleanValue bit NULL, DateValue date NULL, DateTimeValue datetime2(7) NULL, TimeValue time(7) NULL, DurationTicks bigint NULL, TypedTextValue nvarchar(max) NULL, StatusCode int. Öffentlich EchoPreserved und StatusCode logisch immer gesetzt; interne FT deklariert auch diese nullable. FehlertypedwerteNULL; Status3 verwirft Echos atomar.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_file.TVF_InterpretXlsxCell(N'n',1,N'1.235',NULL,N'number',NULL,NULL);
```

## Rechte

Vorhandenes SELECT auf öffentliche TVF und gegebenenfalls gezielte interne Providerrechte entsprechend tatsächlicher Ownershipchain. Interne Direktrechte sind keine Empfehlung für eine öffentliche Neben-API. DataAccess/SystemDataAccess=None im CLR; kein Datenbankkatalog-, Datei- oder Netzwerkzugriff für die Zellberechnung. Keine Rechte werden erteilt.

## Ressourcenbedarf

Inputgrenzen vor Kopie:StoredType32,TargetType32,FormatCode128,RawValue/TextValue je65536 UTF16-Einheiten; bei Number-/Serialparsing Raw zusätzlich128. Anzeige zusätzlich CultureName32. Atomarer Typ-Ausgabecharge262144=256+4*(Stored+Raw+Text+Resolved+TypedText-Einheiten), zählt identische/Echo-/SST-Strings mehrfach. Dadurch kann Status3 bereits unter dem einzelnen65536-Inputmaximum entstehen und andere erwartete Fehler überlagern. Display zusätzlich256+4*DisplayText.Length<=262144. Keine harte Laufzeit-, gesamte CLR-Heap- oder SQL-Marshallingquote.

## Nebenwirkungen

Längenprüfung vor Stringkopie, dann striktes UTF16 aller Argumente vor späterer Typauswahl. StoredType oder PresenceNULL ->Absent1. InlineStr verlangt Presence0/RawNULL/Text vorhanden. Andere Presence0 ist nur ohne Raw/Text absent; s verlangt nichtnegativen ASCII-Int32-Index und bereits aufgelösten Text im Textzweig, str Raw/Text ordinal gleich. Unbekannter StoredType6, unbekanntes Target2, unbekanntes Format6, Target-/Formatklassenwiderspruch2. Stored e ->ExcelError10. Ziel explizit oder Formatklasse oder n:number/b:boolean/d:datetime/sonst:text. Keine allgemeine SQL-Konvertierung. ASCII-Zahlen mit optionalem Vorzeichen/Punkt/Exponent, auch .5/1., ohne Spaces/Gruppierung;128Zeichen, Exponent -64..64, SqlDecimal p/scale<=38 ohne Double-/System.Decimal-Rundung. d nur exakte ISO-Datum-/Datetimeformen ohne Offset/Z. Datumssystem nur für numerisches date/datetime nötig. 1900-Intervall[60,61) ergibt7 vor Rundung;1900-Serial<1 und Datumsüberlauf8;1904 beginnt bei0. date lehnt Bruchteile mit9 ab. time in[0,1)Tagen und nach Rundung unter24h. datetime/time/duration auf100ns half-away-from-zero; duration vorzeichenbehaftete Tage zu Ticks, absolute Grenze Int64max, kein Wrap/Clamp. Bei jedem erwarteten Fehler alle TypedwerteNULL; Echos bleiben außer Limit-/Bindingverwerfung. Kein Workbook-, SST-, Style- oder Formelzugriff.

## Fehlerbehandlung

Status0 OK,1 Absent,2 Argumentkombination,3 Input-/Ausgabegrenze,4 Lexik/UTF16,5 NumberRange,6 Unsupported,7 Serial60,8 TemporalRange,9 Precision,10 ExcelError,11 NullBinding. Erwartete Zellfehler als Status, unerwartete CLR-/SQL-Enginefehler original. SQL-Hülle normalisiert NULL-Providerstatus zu11, DisplayText beziehungsweise Typed/Echo-Felder werden dabei verworfen; dies ist keine Ersatzzeile für einen hypothetischen leeren Provider. Tatsächlicher CLR-Vertrag liefert genau eine Zeile, auch bei ausschließlich NULL-Argumenten.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/XLSX-Gesamtabnahme. Historische Nachweise bleiben an ihre ursprünglichen Artefakte gebunden. Keine Installations-/Rechteattestation oder volle Excel-/SSIS-Runtimeparität. Workbookinhalte, Formeln und Runtimebefunde privat halten.
