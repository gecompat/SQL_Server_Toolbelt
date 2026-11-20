---
name: "toolbelt-toolbelt-toolbelt-conversion-tvf-uricomponente-f665768c"
description: "Genau eine Zeile: OK, SQL_NULL oder LIMIT. Eingang vor UTF-8-Konvertierung/Series prüfen. Aus höchstens 32768 Codeeinheiten entstehen selbst bei drei UTF-8-Bytes und drei Escapezeichen je Byte höchstens 589824 UTF-16-Ausgabebytes; die 1-MiB-Grenze ist damit schon vor Aggregation abgesichert. Altfassaden liefern bei LIMIT NULL."
skill_format_version: "1.0"
module_id: "toolbelt.conversion.uri-component"
schema_name: "toolbelt_conversion"
object_name: "TVF_UriComponentEncodeStatus"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Value", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Eine Unicode-URI-Komponente als nvarchar(max), kein vollständiger URI-Vertrag. Maximal 65536 UTF-16-Bytes vor SQL-UTF-8-Konvertierung; keine separate UTF-16-Validierung im Encoder. Leerer Text ist gültig; vorhandenes % wird erneut codiert. NULL ergibt SQL_NULL/NULL; Überschreitung LIMIT/NULL. Nicht-unreserved UTF-8-Bytes werden %HH, Leerzeichen %20 und nicht +."}]
source_paths: ["Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentEncode.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# TVF_UriComponentEncodeStatus

## Zweck und Einsatzfälle

Genau eine Zeile: OK, SQL_NULL oder LIMIT. Eingang vor UTF-8-Konvertierung/Series prüfen. Aus höchstens 32768 Codeeinheiten entstehen selbst bei drei UTF-8-Bytes und drei Escapezeichen je Byte höchstens 589824 UTF-16-Ausgabebytes; die 1-MiB-Grenze ist damit schon vor Aggregation abgesichert. Altfassaden liefern bei LIMIT NULL.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Eine Unicode-URI-Komponente als nvarchar(max), kein vollständiger URI-Vertrag. Maximal 65536 UTF-16-Bytes vor SQL-UTF-8-Konvertierung; keine separate UTF-16-Validierung im Encoder. Leerer Text ist gültig; vorhandenes % wird erneut codiert. NULL ergibt SQL_NULL/NULL; Überschreitung LIMIT/NULL. Nicht-unreserved UTF-8-Bytes werden %HH, Leerzeichen %20 und nicht +. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_conversion.TVF_UriComponentEncodeStatus(N'Contoso €');
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
- `Modules/toolbelt.conversion.uri-component/Documentation/TVF_UriComponentEncodeStatus.md`

Keine Installations-, Definitions- oder Rechteattestation.
