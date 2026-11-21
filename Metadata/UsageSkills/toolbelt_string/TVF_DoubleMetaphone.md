---
name: "toolbelt-phonetic-tvf-doublemetaphone"
description: "Vollständige begrenzte primäre und alternative Double-Metaphone-Codes."
skill_format_version: "1.0"
module_id: "toolbelt.string.phonetic"
schema_name: "toolbelt_string"
object_name: "TVF_DoubleMetaphone"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Text", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Unicode-Rohtext mit höchstens 4096 UTF-16-Codeunits vor jeder eigenen Textkopie. NULL liefert NULL-Code(s) und ErrorCode=0, leerer Text ist gültig und liefert leere Codes. Ungültige Surrogatfolge ergibt Code 1, Größenquote Code 2, Zeichen außerhalb des geschlossenen Alphabets Code 3. Ein gültiges Supplementary-Paar bleibt dennoch außerhalb dieses Alphabets und ergibt Code 3. Zusätzlich zu ASCII U+0000..U+007F ausschließlich ÇçÑñ. ASCII a..z wird zu A..Z, ç/ñ zu Ç/Ñ. Vor dem Scanner werden äußere ASCII-Codeunits <=U+0020 entfernt; innere Kontroll-/Satzzeichen bleiben im Kontext. Keine allgemeine Culture- oder Unicode-Normalisierung. Kein SQL-Default; Argument ausdrücklich übergeben."}]
source_paths: ["Modules/toolbelt.string.phonetic/Source/TVF_DoubleMetaphone.sql", "Modules/toolbelt.string.phonetic/Clr/PhoneticBridge.cs", "Modules/toolbelt.string.phonetic/Clr/PhoneticInput.cs", "Modules/toolbelt.string.phonetic/Clr/DoubleMetaphoneKernel.cs"]
review_status: "verified"
source_module_version: "1.0.0"
---

# TVF_DoubleMetaphone

## Zweck und Einsatzfälle

Vollständige begrenzte primäre und alternative Double-Metaphone-Codes. Öffentlicher relationaler Einstieg für SELECT/APPLY.

## Voraussetzungen

Installiertes Modul mit passender autorisierter SAFE-Assembly tlblt_String_Phonetic, SQL Server 2019/2022/2025 auf Windows/Linux gemäß Modulmatrix, lokal oder zentral. Keine Abhängigkeit von Distanz-/Jaro-Assembly, Daten-/Systemkatalog-, Datei- oder Netzwerkzugriff im Scanner. Der markierte Scannerport und sein Herkunfts-/Lizenzvertrag bleiben unverändert.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Unicode-Rohtext mit höchstens 4096 UTF-16-Codeunits vor jeder eigenen Textkopie. NULL liefert NULL-Code(s) und ErrorCode=0, leerer Text ist gültig und liefert leere Codes. Ungültige Surrogatfolge ergibt Code 1, Größenquote Code 2, Zeichen außerhalb des geschlossenen Alphabets Code 3. Ein gültiges Supplementary-Paar bleibt dennoch außerhalb dieses Alphabets und ergibt Code 3. Zusätzlich zu ASCII U+0000..U+007F ausschließlich ÇçÑñ. ASCII a..z wird zu A..Z, ç/ñ zu Ç/Ñ. Vor dem Scanner werden äußere ASCII-Codeunits <=U+0020 entfernt; innere Kontroll-/Satzzeichen bleiben im Kontext. Keine allgemeine Culture- oder Unicode-Normalisierung. Kein SQL-Default; Argument ausdrücklich übergeben. |

## Ergebnisse

Genau eine Zeile PrimaryCode varchar(max) NULL, AlternateCode varchar(max) NULL, ErrorCode int. ErrorCode ist logisch immer 0..3, auch wenn physische SQL-/Clientmetadaten Nullable erlauben. Code 0 bei NULL-Input hat NULL-Codefelder; bei nicht-NULL-Input sind alle Codefelder gesetzt und können leer sein. Codes 1..3 liefern ausschließlich NULL-Codefelder. Keine OUTPUT-Parameter oder zusätzlichen Statusresultsets. Kein Vierzeichen-Clamp und keine automatische Abkürzung der primären/alternativen Ausgabe. Ein terminaler J-Zweig kann im Alternativcode ein echtes Leerzeichen erzeugen; nicht RTRIMmen oder ausschließlich LEN als Bytevergleich verwenden. Gleiche/verschiedene phonetische Codes sind kein Beweis gleicher/verschiedener Personen oder Texte. Die SQL-Hülle konvertiert die ASCII-Codeausgabe nach varchar(max) und setzt Latin1_General_100_BIN2; der interne CLR-Core liefert nvarchar(max).

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_string.TVF_DoubleMetaphone(N'PH');
-- PrimaryCode=F, AlternateCode=F, ErrorCode=0.
SELECT * FROM toolbelt_string.TVF_DoubleMetaphone(NULL);
-- Genau eine NULL-Codezeile mit ErrorCode=0.
```

## Rechte

Vorhandenes SELECT auf dieser öffentlichen TVF und geeignete bestehende Ownership-/Abhängigkeitsrechte. Bestehende CLR-/Trustvoraussetzungen separat erfüllen. Kein Runtime-Assemblyhashlesen, keine Datenbank-VIEW-DEFINITION-/Serverstatusanforderung, kein Identitätswechsel und keine Rechteerteilung durch die Funktion.

## Ressourcenbedarf

Eager vollständige Auswertung einer festen Ergebniszeile vor Enumeration. Input maximal 4096 UTF-16-Codeunits, transformiert maximal 8192, je Code maximal 16384 Zeichen und Double-Metaphone-Paar maximal 32768 zusammen. Raw-Länge vor Kopie, Transformation/Append mit expliziten Quoten; kein erfolgreiches Abschneiden. Eigene char-/StringBuilder-/Ergebnisallokationen und feste Kontexttests, keine eigene CPU-/Heap-/Wallclockquote. Die inline SQL-Fassade verspricht kein relationales Inlining des CLR-Scanners.

## Nebenwirkungen

Deterministische speicherreine Berechnung aus dem Argument, keine persistenten Änderungen, Temp-Tabellen, Transaktionen, Session-Context-, Datei- oder Netzwerkoperationen. Kein optionaler Normalisierungsmodus, kein automatisches Laden oder Nachinstallieren von Libraries.

## Fehlerbehandlung

Priorität: SQL NULL kurzschließt erfolgreich; sonst Raw-Überlänge Code 2 vor Kopie; danach vollständige UTF-16-Prüfung Code 1 vor Alphabetprüfung Code 3; danach Transformation/Scanner-Outputquoten Code 2. Fachquoten liefern keine gekürzte Erfolgszeile. Unerwartete Transport-, Rowshape-, ASCII-Code- oder Enginefehler bleiben technische Exceptions und werden nicht pauschal in 0..3 umklassifiziert. Die Bridge prüft die fertige Zeile und erneut beim FillRow.

## Aussagegrenzen

Quellgeprüfter Vertrag des aktuellen unveränderten Fachkerns, keine neue native Gesamtqualifikation. Historische Framework-/Differential-/SQL-/Callerbelege behalten ihre ursprüngliche Bindung und ihren Scope. Kein universeller Unicode-, sprachlicher Ähnlichkeits-, Identitäts- oder Matchingdienst; Codekollisionen sind möglich. Codes sind vollständig innerhalb fester Grenzen, keine unbegrenzte Produktionskapazität oder Aussage zur Darstellung durch jeden Client.
