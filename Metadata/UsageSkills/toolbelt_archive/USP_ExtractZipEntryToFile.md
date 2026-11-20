---
name: "toolbelt-toolbelt-toolbelt-archive-usp-extractzipentrytofile"
description: "Bereitet vollständiges ZIP/Entry-Binary vor und veröffentlicht über WriteBinaryFile. Datei und SQL-Ausgabe sind nicht gemeinsam atomar."
skill_format_version: "1.0"
module_id: "toolbelt.archive.zip-files"
schema_name: "toolbelt_archive"
object_name: "USP_ExtractZipEntryToFile"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@ZipArchive", "sql_type": "varbinary(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vollständiger nicht leerer ZIP-Bytepuffer varbinary(max), kein Pfad/Base64text. NULL (technischer Help-Default)/0x ungültig. Harte Readergrenze 268435456 Archivbytes, höchstens 10000 Entries, Namen höchstens 1024 UTF-16-Einheiten; keine ZIP64-/Multi-Disk-Unterstützung. Namen werden nach Flag11 als UTF-8, sonst CP437 decodiert. Metadatenlisting ist keine CRC-/Payloadvalidierung aller Einträge."}, {"name": "@EntryName", "sql_type": "nvarchar(1024)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakter nicht leerer Entryname aus dem Central Directory, nvarchar(1024), ordinal/case- und längensensitiv einschließlich trailing Spaces. Keine Wildcards, Normalisierung oder automatische Pfad-/Casekorrektur. NULL ungültig, kein Treffer 51322, mehrfach gleicher gesuchter Name 51323. Das Binary-API extrahiert Bytes und benutzt diesen Namen nicht als Dateisystemziel; ToFile verwendet ausschließlich RelativePath."}, {"name": "@RootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. Ziel benötigt AllowWrite."}, {"name": "@RelativePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Nicht leer; Zielverzeichnis muss bestehen. Kein Entpacken mehrerer Entries oder automatisches mkdir."}, {"name": "@MaxEntryBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..67108864 unkomprimierte Bytes des ausgewählten Entries, Default 16777216. NULL/0/negativ/höher ungültig. Prüfung der Deklaration und tatsächlichen Dekompression; unabhängig davon harte Grenze 134217728 komprimierte Bytes. Readergrenze unterscheidet sich von der Writer-Entrygrenze."}, {"name": "@MaxCompressionRatio", "sql_type": "decimal(9,2)", "sql_default": "200.00", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "decimal(9,2) im Bereich 1.00..9999999.99, Default 200.00; unkomprimierte/komprimierte Bytes als Faktor, kein Prozentwert. NULL/<1 ungültig. Deklarierte und tatsächliche Expansionsprüfung; nicht leere Ausgabe aus 0 komprimierten Bytes ist ungültig. Gilt für tatsächliche Extraktion, nicht den erlaubten verschlüsselten Metadatenpfad."}, {"name": "@Overwrite", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ im gebundenen bit: 0 lehnt ein vorhandenes Ziel ab (Default); 1 erlaubt dessen atomare Ersetzung durch den vollständig geschriebenen Staginginhalt. Kein Append. NULL ist für den nativen CLR-bool ungültig und wird nicht zu 0 normalisiert. Dateipublikation ist kein gemeinsam mit späterer SQL-Resultausgabe rückrollbarer Effekt."}, {"name": "@ExecutionIdentity", "sql_type": "varchar(16)", "sql_default": "'Caller'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Name 2..116 UTF-16-Einheiten ohne Punkt/#tbx_ oder eigene #ZipFiles_*Stage-Namen. Datei wird vor SQL-Ausgabe publiziert und bleibt bei späterem Routingfehler bestehen."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wirkt wie 0. 0 still, 1..255 kurze Abschlussmessage ohne Pfade/Entrynamen/Payloads. Interner Reader/Writer laufen mit Debug=0, die optionale endgültige ResultTable erhält Helperdiagnose."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.archive.zip-files/Source/USP_ExtractZipEntryToFile.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# USP_ExtractZipEntryToFile

## Zweck und Einsatzfälle

Bereitet vollständiges ZIP/Entry-Binary vor und veröffentlicht über WriteBinaryFile. Datei und SQL-Ausgabe sind nicht gemeinsam atomar.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ZipArchive` | `varbinary(max)` | `NULL` | Input | Vollständiger nicht leerer ZIP-Bytepuffer varbinary(max), kein Pfad/Base64text. NULL (technischer Help-Default)/0x ungültig. Harte Readergrenze 268435456 Archivbytes, höchstens 10000 Entries, Namen höchstens 1024 UTF-16-Einheiten; keine ZIP64-/Multi-Disk-Unterstützung. Namen werden nach Flag11 als UTF-8, sonst CP437 decodiert. Metadatenlisting ist keine CRC-/Payloadvalidierung aller Einträge. |
| `@EntryName` | `nvarchar(1024)` | `NULL` | Input | Exakter nicht leerer Entryname aus dem Central Directory, nvarchar(1024), ordinal/case- und längensensitiv einschließlich trailing Spaces. Keine Wildcards, Normalisierung oder automatische Pfad-/Casekorrektur. NULL ungültig, kein Treffer 51322, mehrfach gleicher gesuchter Name 51323. Das Binary-API extrahiert Bytes und benutzt diesen Namen nicht als Dateisystemziel; ToFile verwendet ausschließlich RelativePath. |
| `@RootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. Ziel benötigt AllowWrite. |
| `@RelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Nicht leer; Zielverzeichnis muss bestehen. Kein Entpacken mehrerer Entries oder automatisches mkdir. |
| `@MaxEntryBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..67108864 unkomprimierte Bytes des ausgewählten Entries, Default 16777216. NULL/0/negativ/höher ungültig. Prüfung der Deklaration und tatsächlichen Dekompression; unabhängig davon harte Grenze 134217728 komprimierte Bytes. Readergrenze unterscheidet sich von der Writer-Entrygrenze. |
| `@MaxCompressionRatio` | `decimal(9,2)` | `200.00` | Input | decimal(9,2) im Bereich 1.00..9999999.99, Default 200.00; unkomprimierte/komprimierte Bytes als Faktor, kein Prozentwert. NULL/&lt;1 ungültig. Deklarierte und tatsächliche Expansionsprüfung; nicht leere Ausgabe aus 0 komprimierten Bytes ist ungültig. Gilt für tatsächliche Extraktion, nicht den erlaubten verschlüsselten Metadatenpfad. |
| `@Overwrite` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lehnt ein vorhandenes Ziel ab (Default); 1 erlaubt dessen atomare Ersetzung durch den vollständig geschriebenen Staginginhalt. Kein Append. NULL ist für den nativen CLR-bool ungültig und wird nicht zu 0 normalisiert. Dateipublikation ist kein gemeinsam mit späterer SQL-Resultausgabe rückrollbarer Effekt. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit dem Namen einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Name 2..116 UTF-16-Einheiten ohne Punkt/#tbx_ oder eigene #ZipFiles_*Stage-Namen. Datei wird vor SQL-Ausgabe publiziert und bleibt bei späterem Routingfehler bestehen. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. 0 still, 1..255 kurze Abschlussmessage ohne Pfade/Entrynamen/Payloads. Interner Reader/Writer laufen mit Debug=0, die optionale endgültige ResultTable erhält Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

Tatsächlich veröffentlichte Payloadbytes.

Root-Alias aus dem Filesystemresultat.

Relativer Zielpfad aus dem Filesystemresultat.

Unveränderter Filesystemstatus completed.

## Aufrufbeispiele

```sql
EXEC toolbelt_archive.USP_ExtractZipEntryToFile @ZipArchive=0x504B03041400000000000000210000000000000000000000000009000000656D7074792E747874504B0102140014000000000000002100000000000000000000000000090000000000000000000000000000000000656D7074792E747874504B0506000000000100010037000000270000000000,@EntryName=N'empty.txt',@RootAlias=N'ContosoOutput',@RelativePath=N'empty.txt';
```

## Rechte

Bestehende EXECUTE-/Ownershipchain-, Alias- und NTFS-Rechte; keine Rechtevergabe oder Identitätsfallback.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

54620-54624 TBX_ZIP_FILE_*; vorhandene ZIP-/Filesystem-/Helper- und Enginefehler unverändert.

## Aussagegrenzen

Nach Publish kann SQL-Ausgabe scheitern; Datei bleibt bestehen. Vor Retry eigenen Zielzustand klären. Keine SQL-/Dateisystematomarität.

Ein erfolgreicher unverschlüsselter leerer Entry wird als 0-Byte-Datei geschrieben; NULL oder Encryption wird niemals zu 0x umgedeutet.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.archive.zip-files/Documentation/USP_ExtractZipEntryToFile.md`

Keine Installations-, Definitions- oder Rechteattestation.
