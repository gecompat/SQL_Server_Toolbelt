---
name: "toolbelt-toolbelt-toolbelt-conversion-tvf-uricomponentdecode"
description: "Decodiert eine Runde von Prozent-Escapes und prüft die UTF-8-Sequenz."
skill_format_version: "1.0"
module_id: "toolbelt.conversion.uri-component"
schema_name: "toolbelt_conversion"
object_name: "TVF_UriComponentDecode"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Value", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "ASCII-Text mit optionalen %HH-Triplets als UTF-8-Bytes, maximal 65536 UTF-16-Bytes. Genau eine Decodierrunde; + bleibt +, leerer Text ist gültig. Nicht-ASCII-Rohtext, fehlerhafte Triplets, ungültiges UTF-8 und decodiertes NUL sind ungültig (Codes 10..13). NULL ergibt NULL-Felder/SQL_NULL; Überschreitung Code 14/LIMIT, Wert NULL."}]
source_paths: ["Modules/toolbelt.conversion.uri-component/Source/TVF_UriComponentDecode.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# TVF_UriComponentDecode

## Zweck und Einsatzfälle

Decodiert eine Runde von Prozent-Escapes und prüft die UTF-8-Sequenz.

## Voraussetzungen

URIcomponent-Modul mit demselben kanonischen GenerateSeries-Kern. TSQL auf Windows/Linux SQL2019/2022/2025, zulässiges CL150/160/170. Keine Datei-, Netzwerk-, CLR-, Katalog- oder Trustabhängigkeit.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | kein Default | Input | ASCII-Text mit optionalen %HH-Triplets als UTF-8-Bytes, maximal 65536 UTF-16-Bytes. Genau eine Decodierrunde; + bleibt +, leerer Text ist gültig. Nicht-ASCII-Rohtext, fehlerhafte Triplets, ungültiges UTF-8 und decodiertes NUL sind ungültig (Codes 10..13). NULL ergibt NULL-Felder/SQL_NULL; Überschreitung Code 14/LIMIT, Wert NULL. |

Alle Positionen beim SELECT-Aufruf angeben; DEFAULT verwendet einen deklarierten Funktionsdefault, NULL bleibt ein eigener Wert. SQL-Typbindung und eine mögliche Kürzung auf feste Parameterbreite liegen vor dem Funktionskörper.

## Ergebnisse

Genau eine Zeile mit DecodedValue nvarchar(max) NULL,IsValid bit NULL,ValidationCode tinyint NULL; die Statusspalte entfällt, übrige Werte bleiben exakt vom Statuskern erhalten.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(N'Contoso%20A%2BB');
SELECT * FROM toolbelt_conversion.TVF_UriComponentDecodeStatus(NCHAR(256));
SELECT toolbelt_conversion.SVF_UriComponentDecode(N'%F0%9F%98%80');
```

## Rechte

Vorhandenes SELECT/gegebenenfalls REFERENCES für TVFs, EXECUTE für die skalare Funktion und benötigte normale Ownershipchain/Dependencyrechte. Keine Metadatenvollsicht, Serverrechte oder Rechteerteilung aus diesem Vertrag.

## Ressourcenbedarf

MSTVF-Statuskern mit65536UTF16-Inputbyteguard und1048576Outputbyteguard; Wertfassaden übernehmen diese Grenzen. Serien-/Validierungs-/Hex-/Binary-/Octet-/Unicode-Zwischenkopien und zusätzlicher früher ASCIIscan kosten CPU/Speicher. Kein Streaming-, Parallelitäts-, gesamter Heap-/Memorygrant- oder Wallclockvertrag. Die Outputgrenze ist ein konservativer eigener Guard, kein Nachweis eines öffentlich erreichbaren Grenzfalls.

## Nebenwirkungen

Statuskern: NULL zuerst ->SQL_NULL, anschließend65536UTF16-Inputbytes ->LIMIT. Vor jeder Hex-/Binary-CTE-Auswertung prozedural jede physische UTF16-Einheit auf NichtASCII prüfen und gegebenenfalls10/INVALID zurückgeben. Damit kann beispielsweise Codepunkt256 nicht mehr in eine ungerade Hexdarstellung gelangen; ein späterer CASE-Status allein wäre kein CONVERT-Guard. Für übriges ASCIIinput die Prozenttriplets validieren und genau einmal zu Bytes zusammensetzen; + bleibt +, %25 wird Prozent und kein zweiter Decode folgt. Ungültiges Prozent wird nur zu sicherem Dummy00 hexgebaut, Status11 hat Vorrang vor folgendem UTF8-/NUL-Status.

UTF8-Folgen strikt anhand Lead-/Continuationranges prüfen: keine Overlongs, isolierten Fortsetzungen, Surrogateskalarwerte oder Codepunkte>10FFFF. Gültige BMP-/Supplementarywerte in ursprünglicher Reihenfolge zusammensetzen; vollständige Byteabdeckung verlangen. Decodiertes NUL wird13 stattFachtext. Fehlerpriorität nach frühen Guards:10NichtASCII,11Percent,12UTF8,13NUL. Physische Outputbytes zuletzt auf1048576 begrenzen. Wert-TVF delegiert einmal und liefert drei Felder; Scalarwrapper delegiert an die Wert-TVF und liefert nur DecodedValue. Keine Datenabfrage oder Mutation, keine eigene Transaktion.

## Fehlerbehandlung

Erwartete Eingabefehler sind Status10 NichtASCIIrohtext,11Percenttriplet,12UTF8,13NUL,14Limit; kein Teiltext. SQLNULL ist kein INVALID. Wertfassaden behalten ihre beschriebenen Informationsverluste. Typbindungs-, Ressourcen- und unerwartete Enginefehler werden nicht pauschal abgefangen.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag. Die ausdrücklich deklarierten funktionalen Korrekturen in diesem Modul benötigen neue native Gegenproben; historische Nachweise qualifizieren nur ihre ursprünglichen Bytes. Noch kein aktuelles natives API-/SC-/UTF8-/Caller-/Gesamtinstaller-PASS. Keine Installations-/Rechteattestation. Nur synthetische Beispiele; reale Eingaben/Runtimeausgaben privat halten.
