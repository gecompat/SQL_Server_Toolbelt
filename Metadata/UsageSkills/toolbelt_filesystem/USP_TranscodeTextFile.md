---
name: "toolbelt-toolbelt-toolbelt-filesystem-usp-transcodetextfile"
description: "Konvertiert eine Textdatei gestreamt zwischen zwei expliziten Codepages."
skill_format_version: "1.0"
module_id: "toolbelt.filesystem.windows"
schema_name: "toolbelt_filesystem"
object_name: "USP_TranscodeTextFile"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@SourceRootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. Quelle benötigt AllowRead."}, {"name": "@SourceRelativePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Nicht leer; vorhandene Quelldatei."}, {"name": "@SourceEncodingName", "sql_type": "nvarchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Fachlich erforderlicher Encodingname nvarchar(128) für striktes .NET-Framework-Encoding.GetEncoding(name), z.B. utf-8, utf-16, utf-16BE oder windows-1252. Die Menge ist provider-/plattformabhängig und keine geschlossene Toolbelt-Enum; verfügbare Namen mit System.Text.Encoding.GetEncodings() in der passenden Frameworkumgebung ermitteln (Name/WebName), nicht aus einer anderen .NET-Laufzeit ableiten. NULL/leer/Whitespace-only/unbekannt ungültig. Decoder-/Encoderfehler werden nicht durch Ersatzzeichen verborgen; keine automatische BOM-/Codepageerkennung. Explizites Sourceencoding; keine BOM-Autoerkennung. StreamReader entfernt gegebenenfalls eine zu diesem Encoding passende Präambel."}, {"name": "@TargetRootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. Ziel benötigt AllowWrite."}, {"name": "@TargetRelativePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Nicht leer; Zielverzeichnis muss bestehen. Ausgabe erfolgt über Staging/Publish."}, {"name": "@TargetEncodingName", "sql_type": "nvarchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Fachlich erforderlicher Encodingname nvarchar(128) für striktes .NET-Framework-Encoding.GetEncoding(name), z.B. utf-8, utf-16, utf-16BE oder windows-1252. Die Menge ist provider-/plattformabhängig und keine geschlossene Toolbelt-Enum; verfügbare Namen mit System.Text.Encoding.GetEncodings() in der passenden Frameworkumgebung ermitteln (Name/WebName), nicht aus einer anderen .NET-Laufzeit ableiten. NULL/leer/Whitespace-only/unbekannt ungültig. Decoder-/Encoderfehler werden nicht durch Ersatzzeichen verborgen; keine automatische BOM-/Codepageerkennung. Bestimmt ausschließlich die Ausgabeencoding."}, {"name": "@WriteBom", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ im gebundenen bit: 0 schreibt keine zusätzliche Encodingpräambel (Default); 1 schreibt Encoding.GetPreamble() vor den Daten. Bei einer Codepage ohne Präambel bleiben auch bei 1 keine zusätzlichen Bytes. NULL ist für CLR-bool ungültig. Bereits im Content vorhandenes U+FEFF wird dadurch nicht entfernt."}, {"name": "@Overwrite", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ im gebundenen bit: 0 lehnt ein vorhandenes Ziel ab (Default); 1 erlaubt dessen atomare Ersetzung durch den vollständig geschriebenen Staginginhalt. Kein Append. NULL ist für den nativen CLR-bool ungültig und wird nicht zu 0 normalisiert. Dateipublikation ist kein gemeinsam mit späterer SQL-Resultausgabe rückrollbarer Effekt."}, {"name": "@ExecutionIdentity", "sql_type": "varchar(16)", "sql_default": "'Caller'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.filesystem.windows/Source/Procedures.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# USP_TranscodeTextFile

## Zweck und Einsatzfälle

Konvertiert eine Textdatei gestreamt zwischen zwei expliziten Codepages.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Konfigurierter Root-Alias und passende NTFS-Rechte. Caller verlangt Windows Authentication; SQL-Login sa benötigt bei bewusster Wahl ServiceAccount. Datei-Schreib-/Löschaufrufe haben reale Seiteneffekte.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SourceRootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. Quelle benötigt AllowRead. |
| `@SourceRelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Nicht leer; vorhandene Quelldatei. |
| `@SourceEncodingName` | `nvarchar(128)` | `NULL` | Input | Fachlich erforderlicher Encodingname nvarchar(128) für striktes .NET-Framework-Encoding.GetEncoding(name), z.B. utf-8, utf-16, utf-16BE oder windows-1252. Die Menge ist provider-/plattformabhängig und keine geschlossene Toolbelt-Enum; verfügbare Namen mit System.Text.Encoding.GetEncodings() in der passenden Frameworkumgebung ermitteln (Name/WebName), nicht aus einer anderen .NET-Laufzeit ableiten. NULL/leer/Whitespace-only/unbekannt ungültig. Decoder-/Encoderfehler werden nicht durch Ersatzzeichen verborgen; keine automatische BOM-/Codepageerkennung. Explizites Sourceencoding; keine BOM-Autoerkennung. StreamReader entfernt gegebenenfalls eine zu diesem Encoding passende Präambel. |
| `@TargetRootAlias` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener aktiver RootAlias aus toolbelt_filesystem.FileSystemRoot, maximal sysname/128 UTF-16-Einheiten; keine Pfadangabe. NULL/leer/Whitespace-only ungültig. Der Root muss die jeweilige Operation AllowRead/AllowWrite/AllowList/AllowCreateDirectory/AllowDelete erlauben und bei ServiceAccount zusätzlich AllowServiceAccount=1. Verfügbare Werte hängen von vorhandener administrativer Konfiguration/Rechten ab; keine festen eingebauten Aliase und keine automatische Rootanlage. Ziel benötigt AllowWrite. |
| `@TargetRelativePath` | `nvarchar(4000)` | `NULL` | Input | Relativer Pfad unter dem freigegebenen Root, nvarchar(4000), z.B. N'inbox\sample.txt'; kein absoluter/Laufwerks-/UNC-/Devicepfad und kein Doppelpunkt/ADS. Normalisierung mit Path.GetFullPath darf die Rootgrenze nicht verlassen; gültige Win32-Komponenten, keine abschließenden Punkte/Spaces an gebundenen Eltern. Reparse Points werden abgewiesen. NULL ungültig; kein SQL-/Glob-/URL-Text. Nicht leer; Zielverzeichnis muss bestehen. Ausgabe erfolgt über Staging/Publish. |
| `@TargetEncodingName` | `nvarchar(128)` | `NULL` | Input | Fachlich erforderlicher Encodingname nvarchar(128) für striktes .NET-Framework-Encoding.GetEncoding(name), z.B. utf-8, utf-16, utf-16BE oder windows-1252. Die Menge ist provider-/plattformabhängig und keine geschlossene Toolbelt-Enum; verfügbare Namen mit System.Text.Encoding.GetEncodings() in der passenden Frameworkumgebung ermitteln (Name/WebName), nicht aus einer anderen .NET-Laufzeit ableiten. NULL/leer/Whitespace-only/unbekannt ungültig. Decoder-/Encoderfehler werden nicht durch Ersatzzeichen verborgen; keine automatische BOM-/Codepageerkennung. Bestimmt ausschließlich die Ausgabeencoding. |
| `@WriteBom` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 schreibt keine zusätzliche Encodingpräambel (Default); 1 schreibt Encoding.GetPreamble() vor den Daten. Bei einer Codepage ohne Präambel bleiben auch bei 1 keine zusätzlichen Bytes. NULL ist für CLR-bool ungültig. Bereits im Content vorhandenes U+FEFF wird dadurch nicht entfernt. |
| `@Overwrite` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lehnt ein vorhandenes Ziel ab (Default); 1 erlaubt dessen atomare Ersetzung durch den vollständig geschriebenen Staginginhalt. Kein Append. NULL ist für den nativen CLR-bool ungültig und wird nicht zu 0 normalisiert. Dateipublikation ist kein gemeinsam mit späterer SQL-Resultausgabe rückrollbarer Effekt. |
| `@ExecutionIdentity` | `varchar(16)` | `'Caller'` | Input | Taxativ, ordinal/case- und whitespace-sensitiv: Caller (Default) nutzt die erfasste Windows-Identität des authentifizierten Callers; SQL-Login allein genügt nicht. ServiceAccount nutzt ausdrücklich die SQL-Dienstidentität, nur mit vorhandener Mitgliedschaft in der kanonischen Rolle toolbelt_filesystem_service_account und Root-AllowServiceAccount=1. NULL/leer/andere Werte ungültig. Kein automatischer Fallback oder Rechteerteilung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Dateisystemarbeit erfolgt vor diesem SQL-Routing; ein späterer Zielfehler rollt bereits publizierte Dateieffekte nicht zurück. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Windows-Filesystem-Wrapper nicht ausgewertet und auch nicht an den ResultTable-Helper weitergegeben; erzeugt keine zusätzlichen Messages. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

BytesWritten.

RootAlias.

RelativePath.

State.

## Aufrufbeispiele

```sql
-- Voraussetzung: bewusst konfigurierter ExampleRoot und NTFS-Rechte.
-- Caller erfordert Windows Authentication; bei SQL-Authentifizierung
-- ServiceAccount nur bewusst und mit passenden Dienstkonto-Rechten wählen.
EXEC toolbelt_filesystem.USP_TranscodeTextFile
 @SourceRootAlias=N'ExampleRoot', @SourceRelativePath=N'input.txt', @SourceEncodingName=N'utf-8', @TargetRootAlias=N'ExampleRoot', @TargetRelativePath=N'output.txt', @TargetEncodingName=N'utf-16', @Overwrite=0, @ExecutionIdentity=N'Caller';
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

Windows-Dateisystem; Rootfreigaben, ExecutionIdentity und Betriebssystemrechte bleiben erforderlich. Hilfe führt keine Dateioperation und keine Rootprüfung aus.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.filesystem.windows/Documentation/USP_TranscodeTextFile.md`

Keine Installations-, Definitions- oder Rechteattestation.
