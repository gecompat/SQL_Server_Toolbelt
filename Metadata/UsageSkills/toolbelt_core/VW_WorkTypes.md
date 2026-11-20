---
name: "toolbelt-toolbelt-core-vw-worktypes"
description: "Liest den Work-Type-Katalog einschließlich Handlername und sichtbarer Handlerexistenz."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-type"
schema_name: "toolbelt_core"
object_name: "VW_WorkTypes"
object_type: "VIEW"
database_role: "toolbelt"
is_internal: false
parameters: []
source_paths: ["Modules/toolbelt.core.work-type/Source/VW_WorkTypes.sql"]
review_status: "verified"
source_module_version: "1.2.0"
---

# VW_WorkTypes

## Zweck und Einsatzfälle

Registrierte Work Types und ihre Konfiguration lesen, zum Beispiel um einen Handler für einen geplanten Work-Type-Aufruf auszuwählen. Kein Registrierungs- oder Ausführungsbefehl.

## Voraussetzungen

Work-Type-Modul in der gewählten Moduldatenbank installiert und lesbar. Bei zentraler Installation gegebenenfalls dreiteiligen Namen verwenden. Kein Aufrufparameter.

## Parameter und Zugriff

Keine Parameter. Filter und ORDER BY beim SELECT ausdrücklich angeben. Die View projiziert alle über ihre Zugriffsrechte erreichbaren Katalogzeilen; keine fachliche Zeilenautorisierung aus dem Ergebnis ableiten.

## Ergebnisse

WorkTypeId, WorkTypeName, HandlerSchema, HandlerProcedure, quotierter HandlerQualifiedName, ParameterMode, PayloadContractJson, DefaultTimeoutSeconds, IsIdempotent, IsEnabled, Description, Created-/Modified-/Disabled-Metadaten, RowVersion sowie HandlerExists bit. HandlerExists verwendet OBJECT_ID auf P/PC und kann bei eingeschränkter Metadatensicht falsch sein; es bestätigt weder Signatur noch Ausführungsrechte.

## Aufrufbeispiele

```sql
SELECT WorkTypeName,HandlerQualifiedName,ParameterMode,IsEnabled,HandlerExists
FROM toolbelt_core.VW_WorkTypes
ORDER BY WorkTypeName;
```

## Rechte

Vorhandenes SELECT auf der View. Metadata Visibility beeinflusst HandlerExists. Die View vergibt keine Handler-EXECUTE- oder Work-Type-Berechtigungen.

## Ressourcenbedarf

Lesezugriff auf WorkType plus Metadatenfunktion je betrachteter Zeile. Aufwand wächst mit dem Katalog; keine garantierte Reihenfolge ohne ORDER BY.

## Nebenwirkungen

Read-only; kein Handler wird ausgeführt, keine Registrierung verändert.

## Fehlerbehandlung

Fehlende Rechte/Objekte und unerwartete Enginefehler werden nicht als Erfolg maskiert. HandlerExists=0 ist kein Beweis fehlender Installation, wenn Sichtbarkeit eingeschränkt ist.

## Aussagegrenzen

Kein Gesundheits-, Autorisierungs-, Laufzeit- oder Idempotenznachweis eines Handlers. Betriebsmetadaten wie Principals sind echte Daten der gewählten Umgebung; Ausgaben privat behandeln.
