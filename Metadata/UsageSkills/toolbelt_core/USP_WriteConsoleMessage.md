---
name: "toolbelt-toolbelt-toolbelt-core-usp-writeconsolemessage"
description: "Gibt einen langen Unicode-Text vollständig im Messages-Kanal aus. Gepufferte Ausgabe verwendet PRINT; unmittelbare Ausgabe verwendet RAISERROR mit Severity 0 und NOWAIT."
skill_format_version: "1.0"
module_id: "toolbelt.core.console-message"
schema_name: "toolbelt_core"
object_name: "USP_WriteConsoleMessage"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Message", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Auszugebender Unicode-Text als nvarchar(max), maximal 1048576 UTF-16-Bytes und höchstens 512 berechnete Frames. CR/LF und Prozentzeichen sind Inhalt, kein Formatstring. Default/NULL und leerer Text erzeugen keine Ausgabe; Überschreitung wird vor erster Ausgabe abgewiesen."}, {"name": "@Immediate", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 puffert über PRINT mit bis 4000 Codeeinheiten je Frame (Default); 1 nutzt RAISERROR Severity 0 WITH NOWAIT mit bis 2000 Codeeinheiten je Frame. NULL entspricht 0; konkrete Clientpufferung bleibt vom Client abhängig."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255 oder NULL, Default 0; in dieser Procedure haben alle diese Werte bewusst keine Wirkung und erzeugen keine zusätzliche Diagnose."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert ausschließlich Hilfe und ignoriert alle anderen Argumente; 0 führt die Messageausgabe aus (Default). NULL wird wie 0 behandelt."}]
source_paths: ["Modules/toolbelt.core.console-message/Source/USP_WriteConsoleMessage.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# USP_WriteConsoleMessage

## Zweck und Einsatzfälle

Gibt einen langen Unicode-Text vollständig im Messages-Kanal aus. Gepufferte Ausgabe verwendet PRINT; unmittelbare Ausgabe verwendet RAISERROR mit Severity 0 und NOWAIT.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Message` | `nvarchar(max)` | `NULL` | Input | Auszugebender Unicode-Text als nvarchar(max), maximal 1048576 UTF-16-Bytes und höchstens 512 berechnete Frames. CR/LF und Prozentzeichen sind Inhalt, kein Formatstring. Default/NULL und leerer Text erzeugen keine Ausgabe; Überschreitung wird vor erster Ausgabe abgewiesen. |
| `@Immediate` | `bit` | `0` | Input | Taxativ für bit: 0 puffert über PRINT mit bis 4000 Codeeinheiten je Frame (Default); 1 nutzt RAISERROR Severity 0 WITH NOWAIT mit bis 2000 Codeeinheiten je Frame. NULL entspricht 0; konkrete Clientpufferung bleibt vom Client abhängig. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0; in dieser Procedure haben alle diese Werte bewusst keine Wirkung und erzeugen keine zusätzliche Diagnose. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert ausschließlich Hilfe und ignoriert alle anderen Argumente; 0 führt die Messageausgabe aus (Default). NULL wird wie 0 behandelt. |

## Ergebnisse

Die Procedure besitzt kein fachliches Resultset. Text wird ausschließlich als Messages ausgegeben.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_WriteConsoleMessage
      @Message = N'Schritt 1 abgeschlossen.'
    , @Immediate = 1;
```

```sql
EXEC toolbelt_core.USP_WriteConsoleMessage
      @Message = N'Gepufferte Ausgabe'
    , @Immediate = 0;

EXEC toolbelt_core.USP_WriteConsoleMessage
      @Message = N'Fortschritt: 100 %'
    , @Immediate = 1;

EXEC toolbelt_core.USP_WriteConsoleMessage @Hilfe = 1;
```

## Rechte

Erforderlich ist EXECUTE auf toolbelt_core.USP_WriteConsoleMessage. Die Procedure erweitert keine Rechte.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

52801: über 1 MiB UTF-16; 52802: über 512 Frames. Ablehnung vor erster Ausgabe, keine Kürzung.

## Aussagegrenzen

Client und Treiber bestimmen Pufferung, Präfixe und Darstellung von Message-Frame-Grenzen. Die Procedure garantiert Reihenfolge und vollständige Payload-Chunks, aber keine byteidentische Clientformatierung.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.core.console-message/Documentation/USP_WriteConsoleMessage.md`

Keine Installations-, Definitions- oder Rechteattestation.
