---
name: "toolbelt-core-usp-writeconsolemessage"
description: "Gibt begrenzten Unicode-Text in den SQL-Messages-Kanal aus, wahlweise mit NOWAIT."
skill_format_version: "1.0"
module_id: "toolbelt.core.console-message"
schema_name: "toolbelt_core"
object_name: "USP_WriteConsoleMessage"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Message", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Auszugebender Unicode-Text als nvarchar(max), maximal 1048576 UTF-16-Bytes und höchstens 512 berechnete Frames. CR/LF und Prozentzeichen sind Inhalt, kein Formatstring. Default/NULL und leerer Text erzeugen keine Ausgabe; Überschreitung wird vor erster Ausgabe abgewiesen."}, {"name": "@Immediate", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 puffert über PRINT mit bis 4000 Codeeinheiten je Frame (Default); 1 nutzt RAISERROR Severity 0 WITH NOWAIT mit bis 2000 Codeeinheiten je Frame. NULL entspricht 0; konkrete Clientpufferung bleibt vom Client abhängig."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255 oder NULL, Default 0; in dieser Procedure haben alle diese Werte bewusst keine Wirkung und erzeugen keine zusätzliche Diagnose."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe plus genau ein vierkolumniges Skill-Resultset und kehrt vor Fachprüfungen und Fachausgabe zurück. 0 oder NULL führt den Normalpfad aus. Alle übrigen Parameter werden bei Hilfe fachlich ignoriert; ihre SQL-Typbindung gilt weiterhin."}]
source_paths: ["Modules/toolbelt.core.console-message/Source/USP_WriteConsoleMessage.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_WriteConsoleMessage

## Zweck und Einsatzfälle

Lange Unicode-Nachrichten ohne Toolbelt-Präfix oder Zeitstempel in den Messages-Kanal senden. PRINT ist der Standard; Immediate=1 fordert sofortige serverseitige Übertragung mit RAISERROR Severity 0 WITH NOWAIT an. Keine persistente Protokollierung und kein zusätzlicher Resultset für Fachtext.

## Voraussetzungen

Installierte reine T-SQL-Prozedur auf SQL Server 2019/2022/2025, Windows oder Linux, lokal/zentral gemäß Modulvertrag. Client/Treiber muss Informationsnachrichten entgegennehmen; NOWAIT ist keine Zusage sofortiger UI-Darstellung. Keine CLR-, Datei-, Netzwerk- oder Tabellenabhängigkeit.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@Message` | `nvarchar(max)` | `NULL` | Auszugebender Unicode-Text als nvarchar(max), maximal 1048576 UTF-16-Bytes und höchstens 512 berechnete Frames. CR/LF und Prozentzeichen sind Inhalt, kein Formatstring. Default/NULL und leerer Text erzeugen keine Ausgabe; Überschreitung wird vor erster Ausgabe abgewiesen. |
| `@Immediate` | `bit` | `0` | Taxativ für bit: 0 puffert über PRINT mit bis 4000 Codeeinheiten je Frame (Default); 1 nutzt RAISERROR Severity 0 WITH NOWAIT mit bis 2000 Codeeinheiten je Frame. NULL entspricht 0; konkrete Clientpufferung bleibt vom Client abhängig. |
| `@Debug` | `tinyint` | `0` | tinyint 0..255 oder NULL, Default 0; in dieser Procedure haben alle diese Werte bewusst keine Wirkung und erzeugen keine zusätzliche Diagnose. |
| `@Hilfe` | `bit` | `0` | Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe plus genau ein vierkolumniges Skill-Resultset und kehrt vor Fachprüfungen und Fachausgabe zurück. 0 oder NULL führt den Normalpfad aus. Alle übrigen Parameter werden bei Hilfe fachlich ignoriert; ihre SQL-Typbindung gilt weiterhin. |

## Ergebnisse

Kein fachlicher Resultset und keine OUTPUT-Parameter. NULL/leer ergibt RETURN 0 ohne Nachricht. Sonst PRINT-Frames bis 4000 oder Immediate-Frames bis 2000 UTF-16-Codeunits. Gültige Surrogatpaare an einer Chunkgrenze werden zusammengehalten; isolierte Surrogate werden nicht validiert oder repariert. CR/LF und Prozentzeichen sind Payload; das feste RAISERROR-Format %s verhindert Formatinjektion. Framing und Clientdarstellung können zusätzliche Zeilenumbrüche/Pufferung mitbringen; keine pauschale Ende-zu-Ende-Bytegleichheit behaupten. Erfolgreicher Fachpfad RETURN 0. Bei Hilfe=1 stattdessen bisherige Standardhilfe und zusätzlich genau eine Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max); RETURN 0. Keine fachliche Message-/Fehlerausgabe oder ResultTable-Verarbeitung in diesem Zweig.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_WriteConsoleMessage @Message=N'Example progress: 25%',@Immediate=1;
EXEC toolbelt_core.USP_WriteConsoleMessage @Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf dieser Prozedur; keine Tabellen-, Serverstatus-, Dateisystem- oder zusätzlichen Identitätsrechte. Keine automatische Rechtevergabe. Caller soll nur für den Empfänger zulässige Texte und keine Secrets übergeben; der Provider maskiert Inhalte nicht automatisch.

## Ressourcenbedarf

Vorab maximal 1048576 UTF-16-Bytes und höchstens 512 konservativ berechnete Frames. Überschreitung wird vor erster Fachausgabe abgewiesen. Chunkpuffer nvarchar(4000), laufende Positionsberechnung in BIN2-Codeunits. Aufwand abhängig von Textmenge/Framing und Client; kein Timeout, Hot-Path- oder Transportdurchsatzversprechen.

## Nebenwirkungen

Sendet nicht persistente Informationsnachrichten; diese werden nicht durch ein späteres SQL-ROLLBACK zurückgenommen. Kein Datenbank-DML, keine Session-Context-Schreiboperation und keine eigene Transaktion. Debug wird nur lokal auf 0 normalisiert und hat sonst bewusst keine Wirkung. SET NOCOUNT ON gehört zum vorhandenen Prozedurpfad.

## Fehlerbehandlung

THROW 52801 bei mehr als 1 MiB UTF-16-Payload, 52802 beim Framebudget. Keine Teilnachricht aus diesen beiden Vorabfehlern. Engine-, Konvertierungs- und Client-/Transportfehler werden nicht umklassifiziert; Ausgabefehler während des Sendens können bereits sichtbare Frames nicht zurücknehmen. Die optionale Severity-0-Nachricht ist kein fachlicher Fehlerwurf.

## Aussagegrenzen

Quellgeprüfter Vertrag des unveränderten Fachpfads und seiner neuen konstanten Skillhilfe. Neue native Skill-/Clientabnahme bleibt separat; historische Fachnachweise gelten nur für ihre Bindungen. Kein persistenter Logger, keine Redigierung vertraulicher Texte, keine Garantie der UI-Pufferung oder Rekonstruktion durch beliebige Clients.
