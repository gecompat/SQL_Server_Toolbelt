---
name: "toolbelt-fs-clr-transcode-text-file"
description: "Interner Windows-CLR-Provider zum gestreamten Umcodieren zwischen zwei autorisierten Dateipfaden."
skill_format_version: "1.0"
module_id: "toolbelt.filesystem.windows"
schema_name: "toolbelt_filesystem"
object_name: "CLR_TranscodeTextFile"
object_type: "CLR_USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@SourceRootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Aktiver Quell-Rootalias mit AllowRead; NULL/leer unzulässig. Kein physischer Pfad."}, {"name": "@SourceRelativePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Nichtleerer relativer Quelldateipfad innerhalb des Quellroots; NULL, absolute Pfade, Doppelpunkt und Rootausbruch unzulässig."}, {"name": "@SourceEncodingName", "sql_type": "nvarchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Expliziter unterstützter .NET-Quellencodingname. NULL/leer/unbekannt unzulässig. StreamReader verwendet detectEncodingFromByteOrderMarks=false; kein automatischer Encodingwechsel anhand der BOM."}, {"name": "@TargetRootAlias", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Aktiver Ziel-Rootalias mit AllowWrite; NULL/leer unzulässig. Kein physischer Pfad."}, {"name": "@TargetRelativePath", "sql_type": "nvarchar(4000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Nichtleerer relativer Zieldateipfad innerhalb des Zielroots; NULL, absolute Pfade, Doppelpunkt und Rootausbruch unzulässig."}, {"name": "@TargetEncodingName", "sql_type": "nvarchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Expliziter unterstützter .NET-Zielencodingname. NULL/leer/unbekannt unzulässig. Strikte Encoderfehler statt Ersatzzeichen; WriteBom steuert die zusätzliche Präambel."}, {"name": "@WriteBom", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "bit, Default 0: keine zusätzliche Präambel schreiben. 1 schreibt GetPreamble() des gewählten Ausgabeencodings, falls dieses eine besitzt. Keine Garantie einer BOM für jedes Encoding. NULL ist für CLR-bool nicht unterstützt."}, {"name": "@Overwrite", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "bit, Default 0: bestehendes Ziel nicht ersetzen. 1 erlaubt das Ersetzen durch den nativen Publishpfad; vorhandene Ziel-DACL wird übernommen. NULL ist für CLR-bool nicht unterstützt. Keine automatische Verzeichnisanlage."}, {"name": "@ExecutionIdentity", "sql_type": "nvarchar(16)", "sql_default": "N'Caller'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler abschließender bit, Default 0. 1 liefert genau eine konstante vierkolumnige Skillzeile und kehrt vor Bereichs-, Inhalts-, Identitäts-, Root- und Dateiprüfung zurück. 0 oder NULL führt den unveränderten Fachpfad aus. Vorhandene Pflichtargumente wie Content bleiben syntaktisch erforderlich; SQL-Typbindung insbesondere der primitiven CLR-int/long/bool-Parameter erfolgt weiterhin vor dem Methodenaufruf."}]
source_paths: ["Modules/toolbelt.filesystem.windows/Source/Procedures.sql", "Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_filesystem.USP_TranscodeTextFile"]
---

# CLR_TranscodeTextFile

## Zweck und Einsatzfälle

Interner Windows-CLR-Provider zum gestreamten Umcodieren zwischen zwei autorisierten Dateipfaden. Internes Implementierungsdetail. Regulär die öffentliche USP_TranscodeTextFile mit frühem Hilfe-, Validierungs- und ResultTable-Vertrag verwenden; keine Empfehlung, die Facade zu umgehen.

## Voraussetzungen

Installiertes Windows-Dateisystemmodul mit passender UNSAFE-CLR-Binary auf Windows SQL Server 2019/2022/2025. Nur lokaler Modulpfad, nicht Linux oder zentrale Cross-DB-Verwendung. Aktiver konfigurierter Root und AllowRead und AllowWrite erforderlich. Native Provider akzeptieren nur unterstützte lokale Laufwerks-/Handlepfade; UNC-/Netzwerkpfade sind kein zugesicherter Weg. Konfiguration, Trust und Rechte werden nicht automatisch angelegt. Die frühe Hilfe benötigt weder konfigurierte Roots noch Windowsidentität oder NTFS-Zugriff; vorhandenes SQL-EXECUTE und eine geladene passende CLR-Binary bleiben erforderlich.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@SourceRootAlias` | `sysname` | `NULL` | Aktiver Quell-Rootalias mit AllowRead; NULL/leer unzulässig. Kein physischer Pfad. |
| `@SourceRelativePath` | `nvarchar(4000)` | `NULL` | Nichtleerer relativer Quelldateipfad innerhalb des Quellroots; NULL, absolute Pfade, Doppelpunkt und Rootausbruch unzulässig. |
| `@SourceEncodingName` | `nvarchar(128)` | `NULL` | Expliziter unterstützter .NET-Quellencodingname. NULL/leer/unbekannt unzulässig. StreamReader verwendet detectEncodingFromByteOrderMarks=false; kein automatischer Encodingwechsel anhand der BOM. |
| `@TargetRootAlias` | `sysname` | `NULL` | Aktiver Ziel-Rootalias mit AllowWrite; NULL/leer unzulässig. Kein physischer Pfad. |
| `@TargetRelativePath` | `nvarchar(4000)` | `NULL` | Nichtleerer relativer Zieldateipfad innerhalb des Zielroots; NULL, absolute Pfade, Doppelpunkt und Rootausbruch unzulässig. |
| `@TargetEncodingName` | `nvarchar(128)` | `NULL` | Expliziter unterstützter .NET-Zielencodingname. NULL/leer/unbekannt unzulässig. Strikte Encoderfehler statt Ersatzzeichen; WriteBom steuert die zusätzliche Präambel. |
| `@WriteBom` | `bit` | `0` | bit, Default 0: keine zusätzliche Präambel schreiben. 1 schreibt GetPreamble() des gewählten Ausgabeencodings, falls dieses eine besitzt. Keine Garantie einer BOM für jedes Encoding. NULL ist für CLR-bool nicht unterstützt. |
| `@Overwrite` | `bit` | `0` | bit, Default 0: bestehendes Ziel nicht ersetzen. 1 erlaubt das Ersetzen durch den nativen Publishpfad; vorhandene Ziel-DACL wird übernommen. NULL ist für CLR-bool nicht unterstützt. Keine automatische Verzeichnisanlage. |
| `@ExecutionIdentity` | `nvarchar(16)` | `N'Caller'` | Exakt ordinal 'Caller' (Default) oder 'ServiceAccount'. Caller benötigt Windows-Anmeldung und erfasste Windowsidentität; ServiceAccount benötigt die explizite Datenbankrolle und AllowServiceAccount am Root. NULL, leer und andere Schreibweisen sind unzulässig. Kein automatischer Identitätsfallback. |
| `@Hilfe` | `bit` | `0` | Optionaler abschließender bit, Default 0. 1 liefert genau eine konstante vierkolumnige Skillzeile und kehrt vor Bereichs-, Inhalts-, Identitäts-, Root- und Dateiprüfung zurück. 0 oder NULL führt den unveränderten Fachpfad aus. Vorhandene Pflichtargumente wie Content bleiben syntaktisch erforderlich; SQL-Typbindung insbesondere der primitiven CLR-int/long/bool-Parameter erfolgt weiterhin vor dem Methodenaufruf. |

Die fachlichen Regeln der übrigen Parameter gelten bei Hilfe=0. Bei Hilfe=1 sind NULL für String-/LOB-Argumente und fachlich ungültige, aber SQL-typgültige Bereichswerte möglich; primitive CLR-Wertargumente bleiben typgerecht zu binden.

## Ergebnisse

Eine Erfolgszeile: BytesWritten bigint, RootAlias nvarchar(128) und RelativePath nvarchar(4000) des Ziels, State varchar(16)=completed. BytesWritten zählt Ausgabepräambel und encodierte Daten. Keine OUTPUT-Parameter. Bei @Hilfe=1 stattdessen genau eine Zeile: SkillFormatVersion varchar(16), SchemaName nvarchar(128), ObjectName nvarchar(128), SkillMarkdown nvarchar(max). Keine vorherige zwölfspaltige Standardhilfe am internen CLR-Einstieg. Keine ResultTable-/KeepData-/Debug-Steuerung.

## Aufrufbeispiele

```sql
-- Reine interne Skillhilfe, Pflichtargumente weiterhin angeben:
EXEC toolbelt_filesystem.CLR_TranscodeTextFile @Hilfe=1;
-- Für Facharbeit den öffentlichen Einstieg verwenden:
EXEC toolbelt_filesystem.USP_TranscodeTextFile @Hilfe=1;
```

## Rechte

Vorhandene EXECUTE-Rechte auf den internen Einstieg, CLR-Ausführungs-/Trustvoraussetzungen und SELECT auf toolbelt_filesystem.FileSystemRoot im tatsächlichen SQL-Kontext. Direkter Aufruf ist keine Rechteabkürzung. Caller: Windows-Authentifizierung und NTFS-Rechte der erfassten Windowsidentität. ServiceAccount: Mitgliedschaft in dbo-eigener Datenbankrolle toolbelt_filesystem_service_account, AllowServiceAccount am Root und NTFS-Rechte des SQL-Dienstkontos. Keine automatische Rechtevergabe oder Identitätsumschaltung.

## Ressourcenbedarf

StreamReader und 32768-Zeichen-Blöcke mit Encoding-Ausgabepuffer; keine feste kleine Gesamtdateiquote. Je Block getrennte GetBytes-Aufrufe, daher keine pauschale Zusage über zustandsbehaftete Encodings oder Surrogatpaare an Blockgrenzen.

## Nebenwirkungen

Liest Quellfile und publiziert Ziel über Staging. Keine automatische Verzeichnisanlage oder SQL-Rollback-Garantie. Eingangs-BOM bewirkt keinen automatischen Encodingwechsel; WriteBom steuert nur die zusätzliche Ausgabepräambel. Bei Hilfe=1 ausschließlich konstante Skill-Ausgabe über die SQL-CLR-Pipe; keine Datei-, Identitäts-, Konfigurations- oder Fachoperation.

## Fehlerbehandlung

Providerfehler werden als .NET-Ausnahmen mit TBXFS:-Codes beziehungsweise als SQL-CLR-Enginefehler sichtbar; unter anderem RootAliasRequired, RootNotAuthorized, InvalidExecutionIdentity, CallerWindowsAuthenticationRequired, ServiceAccountNotAuthorized, InvalidPath/PathOutsideRoot und native Handlefehler. Operationabhängig zusätzlich InvalidChunkRange, OffsetBeyondEnd, InvalidListLimit, EntryLimitExceeded, DepthLimitExceeded, EncodingRequired/UnsupportedEncoding, ContentRequired. Reparse Points und Hardlinks werden im nativen Prüfpfad abgewiesen; keine Fallbackoperation nach Fehler. Betriebssystem-/Encodingausnahmen können zusätzlich auftreten. Fehlertexte und Dateiresultate können vertrauliche Informationen enthalten und gehören nicht in öffentliche Logs.

## Aussagegrenzen

Neue Signatur und früher CLR-Hilfezweig sind separat von alten Fachartefakten zu qualifizieren. Die vollständige konstante Recordausgabe ist offline prüfbar; SQL-Pipe, native Binder-/Minimalrechte-/Callerzustands- und Nebenwirkungsabnahme sind dadurch nicht belegt. Bei Hilfe=0 bleibt der Fachpfad erhalten. Dateiaktionen unterliegen nicht SQL-ROLLBACK; keine automatische Root-, Trust-, Rechte- oder Infrastrukturänderung. Ein Skill attestiert weder Installation noch Aufruferrechte.
