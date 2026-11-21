---
name: "toolbelt-toolbelt-toolbelt-string-tvf-splitadvanced"
description: "Zerlegt Originaltokens mit mehreren Separatoren, Quotes und Escape-Regeln; entquotiert sie nicht."
skill_format_version: "1.0"
module_id: "toolbelt.string.split-advanced"
schema_name: "toolbelt_string"
object_name: "TVF_SplitAdvanced"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Text mit maximal 65536 UTF-16-Einheiten, NUL verboten; leer ist gültig. NULL ist ein früher No-op ohne Zeilen, selbst bei ungültiger Konfiguration. Tokens bleiben im Original einschließlich Quotes/Escapes; zum Entfernen TVF_UnquoteToken verwenden. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments."}, {"name": "@SeparatorsJson", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "JSON-Array aus 1..16 verschiedenen nicht leeren Strings, z.B. [\"::\",\",\"]; kein Objekt, keine JSON-null-/Zahlen-/Boolean-Elemente. Je Separator 1..64 UTF-16-Einheiten, Gesamt-JSON höchstens 16384 Einheiten. Binäre Gleichheit einschließlich Spaces; NUL und die aktivierten Quote-/Escape-Zeichen verboten. Längster passender Separator gewinnt. NULL ist außerhalb des frühen Input-NULL-Pfads ungültig. Fachlich nur bei nicht-NULL Input erforderlich; der frühe NULL-No-op prüft diesen Wert nicht. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments."}, {"name": "@Quote", "sql_type": "nvarchar(max)", "sql_default": "N'\"'", "is_output": false, "argument_required": true, "business_required": false, "nullable": false, "description": "Genau eine UTF-16-Einheit (Default Doppelquote) aktiviert Quotegruppen; leer deaktiviert sie. NULL, NUL und Surrogate ungültig. Muss sich vom aktiven Escape unterscheiden und darf in keinem Separator vorkommen; keine automatische mehrzeichige Quote-Syntax. Diese Konfiguration wird bei Input=NULL nicht ausgewertet; sonst ist NULL ungültig. Es werden keine Unicode-Scalars oder Grapheme gescannt. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments."}, {"name": "@Escape", "sql_type": "nvarchar(max)", "sql_default": "N'\\'", "is_output": false, "argument_required": true, "business_required": false, "nullable": false, "description": "Genau eine UTF-16-Einheit (Default Backslash) schützt das nächste Zeichen vor Parserwirkung; leer deaktiviert Escaping. NULL, NUL und Surrogate ungültig. Darf weder aktives Quote noch Bestandteil eines Separators sein. Ein finales Escape ohne Folgezeichen ist ein Parserfehler; Ausgabe bleibt unentschlüsselt. Diese Konfiguration wird bei Input=NULL nicht ausgewertet; sonst ist NULL ungültig. Es werden keine Unicode-Scalars oder Grapheme gescannt. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments."}, {"name": "@KeepEmpty", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments."}]
source_paths: ["Modules/toolbelt.string.split-advanced/Source/TVF_SplitAdvanced.sql"]
review_status: "verified"
source_module_version: "1.1.0"
---

# TVF_SplitAdvanced

## Zweck und Einsatzfälle

Zerlegt Originaltokens mit mehreren Separatoren, Quotes und Escape-Regeln; entquotiert sie nicht. Unveränderte Originaltokens einschließlich Quotes, Escapes und Spaces. Außerhalb Quotes gewinnt am Cursor der längste passende Separator; kein Arrayprioritätsmodus. Quote öffnet/schließt überall im Text, keine Verschachtelung und kein CSV-Qualifiervertrag. Escape schützt überall genau die nächste UTF-16-Codeunit vor Parserwirkung und bleibt selbst im Ergebnis. Vor einem Supplementary-Paar wird nur die erste Codeunit übersprungen. Kein Unquoting; dafür den getrennten öffentlichen Einstieg TVF_UnquoteToken verwenden.

## Voraussetzungen

Reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, unterstützter Compatibility Level mindestens 150. OPENJSON liest ausschließlich übergebenes JSON, keine Quelldaten oder externen Systeme. Lokal/zentral dieselbe Fachquelle. Separatoren müssen ein nichtleeres JSON-Array von Strings sein; NUL und aktive Quote-/Escapezeichen darin verboten. Quote und Escape leer unabhängig deaktiviert, sonst jeweils genau eine unterschiedliche Nicht-Surrogate-Codeunit; NULL ist bei nicht-NULL Input ungültig. Separatorstrings selbst sind keine Unicode-Normalisierungsfunktion.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@Input` | `nvarchar(max)` | `None` | Text mit maximal 65536 UTF-16-Einheiten, NUL verboten; leer ist gültig. NULL ist ein früher No-op ohne Zeilen, selbst bei ungültiger Konfiguration. Tokens bleiben im Original einschließlich Quotes/Escapes; zum Entfernen TVF_UnquoteToken verwenden. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments. |
| `@SeparatorsJson` | `nvarchar(max)` | `None` | JSON-Array aus 1..16 verschiedenen nicht leeren Strings, z.B. ["::",","]; kein Objekt, keine JSON-null-/Zahlen-/Boolean-Elemente. Je Separator 1..64 UTF-16-Einheiten, Gesamt-JSON höchstens 16384 Einheiten. Binäre Gleichheit einschließlich Spaces; NUL und die aktivierten Quote-/Escape-Zeichen verboten. Längster passender Separator gewinnt. NULL ist außerhalb des frühen Input-NULL-Pfads ungültig. Fachlich nur bei nicht-NULL Input erforderlich; der frühe NULL-No-op prüft diesen Wert nicht. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments. |
| `@Quote` | `nvarchar(max)` | `N'"'` | Genau eine UTF-16-Einheit (Default Doppelquote) aktiviert Quotegruppen; leer deaktiviert sie. NULL, NUL und Surrogate ungültig. Muss sich vom aktiven Escape unterscheiden und darf in keinem Separator vorkommen; keine automatische mehrzeichige Quote-Syntax. Diese Konfiguration wird bei Input=NULL nicht ausgewertet; sonst ist NULL ungültig. Es werden keine Unicode-Scalars oder Grapheme gescannt. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments. |
| `@Escape` | `nvarchar(max)` | `N'\'` | Genau eine UTF-16-Einheit (Default Backslash) schützt das nächste Zeichen vor Parserwirkung; leer deaktiviert Escaping. NULL, NUL und Surrogate ungültig. Darf weder aktives Quote noch Bestandteil eines Separators sein. Ein finales Escape ohne Folgezeichen ist ein Parserfehler; Ausgabe bleibt unentschlüsselt. Diese Konfiguration wird bei Input=NULL nicht ausgewertet; sonst ist NULL ungültig. Es werden keine Unicode-Scalars oder Grapheme gescannt. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments. |
| `@KeepEmpty` | `bit` | `1` | Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments. |

## Ergebnisse

Value nvarchar(max) NULL, Ordinal bigint NULL, IsValid bit NOT NULL, ErrorCode varchar(64) NULL, ErrorPosition bigint NULL. Erfolg: IsValid=1, nicht-NULL Value/Ordinal, Fehlerfelder NULL. Geschäftsfehler: genau eine Zeile mit Value/Ordinal NULL, IsValid=0 und symbolischem Code; keine Teiltokens. Die Rückgabetabelle garantiert keine Zeilenreihenfolge, deshalb ORDER BY Ordinal. Scannvergleiche sind BIN2, der Value-Rückgabespaltentyp deklariert keine eigene BIN2-Collation. Input=NULL: null Zeilen auch bei ungültiger Konfiguration. Ordinal wird nach Leerfilterung lückenlos ab 1 neu vergeben. Leerer Input liefert bei KeepEmpty=1 oder NULL genau ein leeres Token, bei 0 keine Zeilen. Kein automatisches Entfernen von Steuerzeichen oder Tokenquotes.

## Aufrufbeispiele

```sql
SELECT Value,Ordinal,IsValid,ErrorCode,ErrorPosition
FROM toolbelt_string.TVF_SplitAdvanced(N'a;"b;c";d',N'[";"]',DEFAULT,DEFAULT,DEFAULT)
ORDER BY Ordinal;
-- Drei Originaltokens; IsValid=1, Fehlerfelder NULL.
SELECT * FROM toolbelt_string.TVF_SplitAdvanced(NULL,NULL,NULL,NULL,NULL);
-- Keine Zeilen, wegen frühem NULL-No-op.
```

## Rechte

Vorhandenes SELECT auf dieser TVF genügt im passenden Installationskontext. Kein Dateizugriff, Serverstatusrecht oder VIEW ANY DEFINITION erforderlich. Zentraler Dreiteilname allein ersetzt keine gültige Datenbankauthentifizierung, gemappte Identität oder erforderlichen Objektrechte. Kein automatisches Aktivieren von TRUSTWORTHY/Ownership-Chaining und keine Rechteerteilung.

## Ressourcenbedarf

Maximal 65536 Input-, 16384 JSON-Rohtext-Codeunits, 16 Separatoren mit je höchstens 64 Codeunits, einschließlich aller trailing Spaces nach DATALENGTH/2. Begrenzter sequenzieller zustandsbasierter Scan mit mehreren Konfigurations-/NUL-Durchläufen und bis zu 16 Separatorprüfungen pro ungeschützter Position. Tokenpositionen werden zunächst in Tabellenvariablen materialisiert; Originaltext erst nach vollständigem Parse-PASS als Ergebnistokens gesliced. Multi-statement-TVF, keine Behauptung von inline TVF, Streaming, Parallelität, festem Grant/Heap oder Produktionsdurchsatz.

## Nebenwirkungen

Keine persistenten oder caller-sichtbaren Änderungen, Transaktionen, Datei-/Netzwerk-/Katalogabfragen. Nur eigene Tabellenvariablen; NULL-No-op ist vor Konfigurationsprüfung. Keine automatische Installation oder Reparatur von Abhängigkeiten.

## Fehlerbehandlung

Fachfehler liefern eine Statuszeile, keine SQL-Exception. Nicht allein WHERE IsValid=1 verwenden, sonst werden Fehler still verworfen; bei APPLY Status je Input prüfen. Taxative symbolische Kerncodes: INVALID_CONFIGURATION (fehlende Konfiguration, Steuerzeichenfehler/-konflikt, Nichtstring oder leeres Array); INPUT_LIMIT_EXCEEDED (Input >65536); JSON_LIMIT_EXCEEDED (JSON >16384); INVALID_SEPARATOR_JSON (Syntax/Root nicht Array); SEPARATOR_LIMIT_EXCEEDED (>16 Separatoren oder Länge >64); EMPTY_SEPARATOR; DUPLICATE_SEPARATOR (exakte Bytes); NUL_NOT_ALLOWED; DANGLING_ESCAPE; UNTERMINATED_QUOTE. Priorität: Input NULL kurzschließt alles; danach fehlende JSON-/Quote-/Escape-Konfiguration, Inputlimit, JSONlimit, Quote-/Escapelänge; JSONsyntax/Root/Anzahl; pro Separator in Arrayreihenfolge Typ, leer, Länge, NUL, Duplikat; aktive Steuerzeichen NUL/Surrogate/Identität und Separator-Konflikte; vollständiger erster Input-NUL-Befund vor Parserfehlern; dann sequenzieller Scan. Terminaler Escape gewinnt vor einer am EOF offenen Quote. Fehlerposition nur bei Input-NUL, terminalem Escape oder offener Quote, einsbasiert auf ursprüngliche UTF-16-Codeunits; sonst NULL. Unerwartete Enginefehler werden nicht pauschal als Fachstatus maskiert.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, kein neuer nativer Hilfe-/Installer-/CrossDB-Gesamtnachweis. Historische Nachweise behalten ihre ursprünglichen Bytes und ihren Scope. Kein CSV-Parser, kein Unquoting, keine allgemeine UTF-16-Surrogatvalidierung oder Graphem-/Unicode-Scalar-Semantik. Alle Angaben beschreiben bekannte Implementierung, keine Installations- oder Rechteattestation.
