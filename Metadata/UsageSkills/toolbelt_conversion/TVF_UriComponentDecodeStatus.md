---
name: "toolbelt-toolbelt-toolbelt-conversion-tvf-uricomponentd-ec85ccdb"
description: "Genau eine Zeile: OK, SQL_NULL, INVALID oder LIMIT. Strikte UTF-8-/Percent-/NUL-Regeln bleiben; bei LIMIT IsValid=0, ValidationCode=14, Wert NULL. Die Ausgabe ist durch den vor Series geprüften Eingang unter 1 MiB begrenzt. Altfassaden behalten ihre Spalten und liefern bei LIMIT NULL."
skill_format_version: "1.0"
module_id: "toolbelt.conversion.uri-component"
schema_name: "toolbelt_conversion"
object_name: "TVF_UriComponentDecodeStatus"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Value", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "ASCII-Text mit optionalen %HH-Triplets als UTF-8-Bytes, maximal 65536 UTF-16-Bytes. Genau eine Decodierrunde; + bleibt +, leerer Text ist gültig. Nicht-ASCII-Rohtext, fehlerhafte Triplets, ungültiges UTF-8 und decodiertes NUL sind ungültig (Codes 10..13). NULL ergibt NULL-Felder/SQL_NULL; Überschreitung Code 14/LIMIT, Wert NULL."}]
source_paths: ["Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentDecode.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# TVF_UriComponentDecodeStatus

## Zweck und Einsatzfälle

Genau eine Zeile: OK, SQL_NULL, INVALID oder LIMIT. Strikte UTF-8-/Percent-/NUL-Regeln bleiben; bei LIMIT IsValid=0, ValidationCode=14, Wert NULL. Die Ausgabe ist durch den vor Series geprüften Eingang unter 1 MiB begrenzt. Altfassaden behalten ihre Spalten und liefern bei LIMIT NULL.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | ASCII-Text mit optionalen %HH-Triplets als UTF-8-Bytes, maximal 65536 UTF-16-Bytes. Genau eine Decodierrunde; + bleibt +, leerer Text ist gültig. Nicht-ASCII-Rohtext, fehlerhafte Triplets, ungültiges UTF-8 und decodiertes NUL sind ungültig (Codes 10..13). NULL ergibt NULL-Felder/SQL_NULL; Überschreitung Code 14/LIMIT, Wert NULL. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(N'%E2%82%AC');
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
- `Modules/toolbelt.conversion.uri-component/Documentation/TVF_UriComponentDecodeStatus.md`

Keine Installations-, Definitions- oder Rechteattestation.

Offener Quellbefund aus der Skillprüfung: Die Hexkonstruktion bildet rohe Nicht-ASCII-Zeichen über zwei SUBSTRING-Nibbles ab, ohne vorab den Wertebereich zu schützen. Bei Codepunkten über 255 kann daraus ungerader Hextext entstehen; CONVERT(varbinary,...,1) besitzt hier keinen TRY-/Guardpfad. Ob die aktuelle Engineauswertung vor dem beabsichtigten INVALID/Code10 abbricht, ist noch nicht nativ geprüft. Bis zur Klärung kein allgemeines Nicht-ASCII-Fehlersicherheitsversprechen und keine Freigabe dieses Entwurfs.
