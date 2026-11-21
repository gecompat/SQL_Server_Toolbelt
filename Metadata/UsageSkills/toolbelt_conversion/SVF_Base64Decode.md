---
name: "toolbelt-toolbelt-toolbelt-conversion-svf-base64decode"
description: "Decodiert Base64-Text zu Binärdaten."
skill_format_version: "1.0"
module_id: "toolbelt.conversion.base64"
schema_name: "toolbelt_conversion"
object_name: "SVF_Base64Decode"
object_type: "SVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Value", "sql_type": "varchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "ASCII-Base64-Text (A-Z, a-z, 0-9, +, /) oder Base64URL (-, _ statt +, /); beide Alphabete werden normalisiert. Nur Space, Tab, CR und LF werden entfernt. Optionales =-Padding nur am Ende in passender Länge; ohne Padding sind Restlängen 0, 2 oder 3 modulo 4 gültig. Leer/Whitespace-only ergibt leere Bytes. Höchstens 25165824 Rohtextbytes und 16777216 Ergebnisbytes; NULL ergibt SQL_NULL/NULL, Überschreitung LIMIT/NULL. Ungültige Syntax ergibt INVALID im Statuskern, einen Konvertierungsfehler in TVF/SVF-Wertfassaden."}]
source_paths: ["Modules/toolbelt.conversion.base64/Source/SVF_Base64Decode.sql", "Modules/toolbelt.conversion.base64/Source/TVF_Base64Decode.sql"]
review_status: "verified"
source_module_version: "1.1.0"
---

# SVF_Base64Decode

## Zweck und Einsatzfälle

Decodiert Base64-Text zu Binärdaten. Skalarer Convenience-Wrapper; bei größeren Mengen die entsprechende TVF verwenden.

## Voraussetzungen

SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Base64-Modul installiert. Reiner T-SQL/XML-Provider ohne CLR oder Netzwerk. Funktionsargumente positionsbezogen angeben; bei deklariertem Default das Schlüsselwort DEFAULT oder den gewünschten Wert übergeben.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@Value` | `varchar(max)` | `kein Default` | ASCII-Base64-Text (A-Z, a-z, 0-9, +, /) oder Base64URL (-, _ statt +, /); beide Alphabete werden normalisiert. Nur Space, Tab, CR und LF werden entfernt. Optionales =-Padding nur am Ende in passender Länge; ohne Padding sind Restlängen 0, 2 oder 3 modulo 4 gültig. Leer/Whitespace-only ergibt leere Bytes. Höchstens 25165824 Rohtextbytes und 16777216 Ergebnisbytes; NULL ergibt SQL_NULL/NULL, Überschreitung LIMIT/NULL. Ungültige Syntax ergibt INVALID im Statuskern, einen Konvertierungsfehler in TVF/SVF-Wertfassaden. |

## Ergebnisse

Ein Skalarwert varbinary(max). NULL bleibt NULL; Eingabe-/Ausgabelimit wird auf NULL abgebildet. Leer oder ausschließlich Space/Tab/CR/LF ergibt 0x. Ungültige Formatstruktur löst einen SQL-Engine-Konvertierungsfehler aus, statt NULL als Erfolg vorzutäuschen.

## Aufrufbeispiele

```sql
SELECT toolbelt_conversion.SVF_Base64Decode('yv7K_g') AS Value;
-- 0xCAFECAFE
```

## Rechte

Vorhandenes EXECUTE für den skalaren Aufruf; REFERENCES für entsprechende Referenzverwendungen. Keine Rechtevergabe oder Identitätsänderung. Cross-Database-Mapping und Berechtigungen bleiben erforderlich.

## Ressourcenbedarf

Vor jeder Normalisierung höchstens 25165824 Original-Eingabebytes einschließlich später entfernter Leerzeichen. Der Statuskern materialisiert normalisierten Text einmal und prüft vor XML-Decodierung die erwartete Ausgabe gegen 16777216 Bytes. Mehrere lineare Stringoperationen und bis zu 16 MiB Ausgabe; kein Streaming. Keine pauschale Inline-/Parallelitäts- oder Laufzeitgarantie; skalare Wrapper führen eine weitere Funktionsabfrage aus.

## Nebenwirkungen

Keine persistenten Daten-, Datei-, Netzwerk-, Trust- oder Konfigurationsänderungen. Der Statuskern befüllt ausschließlich seine lokale Rückgabetabelle.

## Fehlerbehandlung

Im Statuskern gilt die Reihenfolge NULL, Original-Eingabelimit, Formatprüfung, erwartetes Ausgabelimit, XML-Decodierung. Wertfassaden erzeugen bei Status INVALID absichtlich einen Engine-Konvertierungsfehler. SQL_NULL und LIMIT werden dort auf NULL abgebildet; nur die Statusfunktion unterscheidet die Gründe. Typbindung, Ressourcenmangel und unerwartete Engine-/XML-Fehler bleiben Fehler; kein Retry.

## Aussagegrenzen

Akzeptiert ASCII-Zeichen aus Standard- und URL-safe-Alphabet; Die Zeichen `-` und `_` werden vor der binären Alphabetprüfung in `+` beziehungsweise `/` umgewandelt, auch bei gemischtem Alphabet. Nur Space (32), Tab (9), CR (13) und LF (10) werden ignoriert. Fehlendes Padding wird bei Restlängen 2/3 ergänzt; Restlänge 1 ist INVALID. Vorhandenes Padding muss aus genau einem oder zwei terminalen = bestehen und zur Viererblocklänge passen. Keine allgemeine Unicode-Whitespace-Bereinigung und keine Zusage einer Prüfung kanonischer Paddingbits über die tatsächlichen Strukturguards und den XML-Konverter hinaus. Keine Installations-, Rechte- oder Sicherheitsattestation durch diese Beschreibung.
