---
name: "toolbelt-toolbelt-toolbelt-conversion-svf-base64encode"
description: "Codiert Binärdaten als Base64 oder Base64URL."
skill_format_version: "1.0"
module_id: "toolbelt.conversion.base64"
schema_name: "toolbelt_conversion"
object_name: "SVF_Base64Encode"
object_type: "SVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Value", "sql_type": "varbinary(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Binärwert varbinary(max), etwa 0xCAFECAFE oder ein vom Client gebundener Bytepuffer; keine Text-Decodierung. Leer (0x) ist gültig. Maximal 16777216 Bytes; darüber Status LIMIT bzw. NULL in der Wertfassade. NULL ergibt SQL_NULL bzw. NULL."}, {"name": "@UrlSafe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ für den gebundenen bit-Wert: 0 erzeugt Standard-Base64 mit +, / und Padding = (Default); 1 erzeugt Base64URL mit -, _ und ohne Padding. NULL wird wie 0 behandelt."}]
source_paths: ["Modules/toolbelt.conversion.base64/Source/SVF_Base64Encode.sql", "Modules/toolbelt.conversion.base64/Source/TVF_Base64Encode.sql"]
review_status: "verified"
source_module_version: "1.1.0"
---

# SVF_Base64Encode

## Zweck und Einsatzfälle

Codiert Binärdaten als Base64 oder Base64URL. Skalarer Convenience-Wrapper; bei größeren Mengen die entsprechende TVF verwenden.

## Voraussetzungen

SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Base64-Modul installiert. Reiner T-SQL/XML-Provider ohne CLR oder Netzwerk. Funktionsargumente positionsbezogen angeben; bei deklariertem Default das Schlüsselwort DEFAULT oder den gewünschten Wert übergeben.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@Value` | `varbinary(max)` | `kein Default` | Binärwert varbinary(max), etwa 0xCAFECAFE oder ein vom Client gebundener Bytepuffer; keine Text-Decodierung. Leer (0x) ist gültig. Maximal 16777216 Bytes; darüber Status LIMIT bzw. NULL in der Wertfassade. NULL ergibt SQL_NULL bzw. NULL. |
| `@UrlSafe` | `bit` | `0` | Taxativ für den gebundenen bit-Wert: 0 erzeugt Standard-Base64 mit +, / und Padding = (Default); 1 erzeugt Base64URL mit -, _ und ohne Padding. NULL wird wie 0 behandelt. |

## Ergebnisse

Ein Skalarwert varchar(max). NULL bei NULL-Eingabe oder mehr als 16777216 Eingabebytes. Leere Binärdaten ergeben leeren Text. @UrlSafe=1 ersetzt +/ durch -_ und entfernt Padding; 0/NULL liefert Standard-Base64.

## Aufrufbeispiele

```sql
SELECT toolbelt_conversion.SVF_Base64Encode(0xCAFECAFE,0) AS Value;
-- yv7K/g==
```

## Rechte

Vorhandenes EXECUTE für den skalaren Aufruf; REFERENCES für entsprechende Referenzverwendungen. Keine Rechtevergabe oder Identitätsänderung. Cross-Database-Mapping und Berechtigungen bleiben erforderlich.

## Ressourcenbedarf

Vorprüfung auf höchstens 16777216 Binärbytes; XML-Kodierung vergrößert die Ausgabe auf bis zu vier Zeichen je drei Bytes. Keine pauschale Inline-/Parallelitäts- oder Laufzeitgarantie; skalare Wrapper führen eine weitere Funktionsabfrage aus.

## Nebenwirkungen

Keine persistenten Daten-, Datei-, Netzwerk-, Trust- oder Konfigurationsänderungen. Der Statuskern befüllt ausschließlich seine lokale Rückgabetabelle.

## Fehlerbehandlung

Die Wertfassade bildet SQL_NULL und LIMIT des Statuskerns auf NULL ab. Für eine Unterscheidung TVF_Base64EncodeStatus verwenden. Typbindung, Ressourcenmangel und unerwartete Engine-/XML-Fehler bleiben Fehler; kein Retry.

## Aussagegrenzen

Base64 ist Kodierung, keine Verschlüsselung. URL-safe wird nur für den gebundenen bit-Wert 1 aktiviert; NULL wie 0. Keine Installations-, Rechte- oder Sicherheitsattestation durch diese Beschreibung.
