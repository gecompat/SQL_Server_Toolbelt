---
name: "toolbelt-toolbelt-toolbelt-conversion-tvf-base64decodestatus"
description: "Genau eine Zeile: OK, SQL_NULL, INVALID oder LIMIT. Rohtextprüfung vor REPLACE, berechnete Ergebnisgröße vor XML. Standard-/URL-Alphabet und definierter Whitespace bleiben. Die bisherige TVF/SVF behält Syntaxfehler unterhalb der Grenzen und liefert bei LIMIT NULL."
skill_format_version: "1.0"
module_id: "toolbelt.conversion.base64"
schema_name: "toolbelt_conversion"
object_name: "TVF_Base64DecodeStatus"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Value", "sql_type": "varchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "ASCII-Base64-Text (A-Z, a-z, 0-9, +, /) oder Base64URL (-, _ statt +, /); beide Alphabete werden normalisiert. Nur Space, Tab, CR und LF werden entfernt. Optionales =-Padding nur am Ende in passender Länge; ohne Padding sind Restlängen 0, 2 oder 3 modulo 4 gültig. Leer/Whitespace-only ergibt leere Bytes. Höchstens 25165824 Rohtextbytes und 16777216 Ergebnisbytes; NULL ergibt SQL_NULL/NULL, Überschreitung LIMIT/NULL. Ungültige Syntax ergibt INVALID im Statuskern, einen Konvertierungsfehler in TVF/SVF-Wertfassaden."}]
source_paths: ["Modules/toolbelt.conversion.base64/Source/TVF_Base64Decode.sql"]
review_status: "verified"
source_module_version: "1.1.0"
---

# TVF_Base64DecodeStatus

## Zweck und Einsatzfälle

Genau eine Zeile: OK, SQL_NULL, INVALID oder LIMIT. Rohtextprüfung vor REPLACE, berechnete Ergebnisgröße vor XML. Standard-/URL-Alphabet und definierter Whitespace bleiben. Die bisherige TVF/SVF behält Syntaxfehler unterhalb der Grenzen und liefert bei LIMIT NULL. Für APPLY-basierte Verarbeitung mit expliziter Ergebniszeile.

## Voraussetzungen

SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170; Base64-Modul installiert. Reiner T-SQL/XML-Provider ohne CLR oder Netzwerk. Funktionsargumente positionsbezogen angeben; bei deklariertem Default das Schlüsselwort DEFAULT oder den gewünschten Wert übergeben.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@Value` | `varchar(max)` | `kein Default` | ASCII-Base64-Text (A-Z, a-z, 0-9, +, /) oder Base64URL (-, _ statt +, /); beide Alphabete werden normalisiert. Nur Space, Tab, CR und LF werden entfernt. Optionales =-Padding nur am Ende in passender Länge; ohne Padding sind Restlängen 0, 2 oder 3 modulo 4 gültig. Leer/Whitespace-only ergibt leere Bytes. Höchstens 25165824 Rohtextbytes und 16777216 Ergebnisbytes; NULL ergibt SQL_NULL/NULL, Überschreitung LIMIT/NULL. Ungültige Syntax ergibt INVALID im Statuskern, einen Konvertierungsfehler in TVF/SVF-Wertfassaden. |

## Ergebnisse

Genau eine Zeile mit DecodedValue varbinary(max) NULL und Status varchar(16) NOT NULL. Taxativ SQL_NULL bei NULL-Eingabe, LIMIT bei Überschreitung einer Größenprüfung, INVALID bei ungültigen Zeichen/Längen/Paddingstrukturen und OK bei erfolgreicher Decodierung einschließlich leerer Eingabe. Bei SQL_NULL/LIMIT/INVALID ist DecodedValue NULL.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_conversion.TVF_Base64DecodeStatus('yv7K_g');
-- 0xCAFECAFE, Status=OK
```

## Rechte

Vorhandenes SELECT für SELECT-Aufrufe; REFERENCES für entsprechende Referenzverwendungen. Keine Rechtevergabe oder Identitätsänderung. Cross-Database-Mapping und Berechtigungen bleiben erforderlich.

## Ressourcenbedarf

Vor jeder Normalisierung höchstens 25165824 Original-Eingabebytes einschließlich später entfernter Leerzeichen. Der Statuskern materialisiert normalisierten Text einmal und prüft vor XML-Decodierung die erwartete Ausgabe gegen 16777216 Bytes. Mehrere lineare Stringoperationen und bis zu 16 MiB Ausgabe; kein Streaming. Keine pauschale Inline-/Parallelitäts- oder Laufzeitgarantie; skalare Wrapper führen eine weitere Funktionsabfrage aus.

## Nebenwirkungen

Keine persistenten Daten-, Datei-, Netzwerk-, Trust- oder Konfigurationsänderungen. Der Statuskern befüllt ausschließlich seine lokale Rückgabetabelle.

## Fehlerbehandlung

Im Statuskern gilt die Reihenfolge NULL, Original-Eingabelimit, Formatprüfung, erwartetes Ausgabelimit, XML-Decodierung. Wertfassaden erzeugen bei Status INVALID absichtlich einen Engine-Konvertierungsfehler. SQL_NULL und LIMIT werden dort auf NULL abgebildet; nur die Statusfunktion unterscheidet die Gründe. Typbindung, Ressourcenmangel und unerwartete Engine-/XML-Fehler bleiben Fehler; kein Retry.

## Aussagegrenzen

Akzeptiert ASCII-Zeichen aus Standard- und URL-safe-Alphabet; Die Zeichen `-` und `_` werden vor der binären Alphabetprüfung in `+` beziehungsweise `/` umgewandelt, auch bei gemischtem Alphabet. Nur Space (32), Tab (9), CR (13) und LF (10) werden ignoriert. Fehlendes Padding wird bei Restlängen 2/3 ergänzt; Restlänge 1 ist INVALID. Vorhandenes Padding muss aus genau einem oder zwei terminalen = bestehen und zur Viererblocklänge passen. Keine allgemeine Unicode-Whitespace-Bereinigung und keine Zusage einer Prüfung kanonischer Paddingbits über die tatsächlichen Strukturguards und den XML-Konverter hinaus. Keine Installations-, Rechte- oder Sicherheitsattestation durch diese Beschreibung.
