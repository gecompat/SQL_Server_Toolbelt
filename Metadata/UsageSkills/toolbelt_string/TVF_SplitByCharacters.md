---
name: "toolbelt-toolbelt-toolbelt-string-tvf-splitbycharacters"
description: "Teilt begrenzten Unicode-Text an einer Menge einzelner UTF-16-Separatoren."
skill_format_version: "1.0"
module_id: "toolbelt.string.split-characters"
schema_name: "toolbelt_string"
object_name: "TVF_SplitByCharacters"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Text mit maximal 65536 UTF-16-Bytes; leer ist gültig. NULL in Input oder Separators ergibt SQL_NULL im Statuskern und keine Zeilen in der Wertfassade. Höchstens 10000 Ausgabetokens, keine Teilveröffentlichung bei Überschreitung."}, {"name": "@Separators", "sql_type": "nvarchar(4000)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Menge einzelner UTF-16-Einheiten als nvarchar(4000), z.B. N',;'; keine Separatorstrings/JSON-/Quote-Syntax. Höchstens 64 verschiedene Einheiten, Duplikate zählen einmal, NUL verboten. Leer bedeutet keine Trennung; NULL ergibt SQL_NULL/keine Zeilen."}, {"name": "@KeepEmpty", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt."}]
source_paths: ["Modules/toolbelt.string.split-characters/Source/TVF_SplitByCharacters.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# TVF_SplitByCharacters

## Zweck und Einsatzfälle

Teilt begrenzten Unicode-Text an einer Menge einzelner UTF-16-Separatoren. Literal, ohne Quote-/CSV-/Regex-Interpretation. Wertfassade filtert ausschließlich erfolgreiche Tokenzeilen des Statuskerns.

## Voraussetzungen

SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. Modul und Generate-Series-Abhängigkeit installiert. Alle drei Argumentpositionen angeben; DEFAULT oder NULL bei KeepEmpty wirkt wie 1. Keine CLR-, Datei-, Netzwerk- oder Systemkatalogabhängigkeit.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Text mit maximal 65536 UTF-16-Bytes; leer ist gültig. NULL in Input oder Separators ergibt SQL_NULL im Statuskern und keine Zeilen in der Wertfassade. Höchstens 10000 Ausgabetokens, keine Teilveröffentlichung bei Überschreitung. |
| `@Separators` | `nvarchar(4000)` | `kein Default` | Menge einzelner UTF-16-Einheiten als nvarchar(4000), z.B. N',;'; keine Separatorstrings/JSON-/Quote-Syntax. Höchstens 64 verschiedene Einheiten, Duplikate zählen einmal, NUL verboten. Leer bedeutet keine Trennung; NULL ergibt SQL_NULL/keine Zeilen. |
| `@KeepEmpty` | `bit` | `1` | Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt. |

## Ergebnisse

Null bis mehrere Zeilen mit Value nvarchar(max) und Ordinal bigint. Nur Status OK wird veröffentlicht, bei LIMIT/INVALID/SQL_NULL/EMPTY keine Zeile. Erfolgreiche Ordinals beginnen bei 1 und sind nach Entfernung leerer Tokens lückenlos. KeepEmpty=1 erhält Rand-/Zwischenleeren einschließlich einer leeren Zeile für leeren Input; KeepEmpty=0 entfernt sie. Leere Separatormenge trennt nicht. Reihenfolge nur mit ORDER BY Ordinal.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_string.TVF_SplitByCharacters(N'a,,b',N',',DEFAULT)
ORDER BY Ordinal;
-- Value a / leer / b, Ordinal 1 / 2 / 3.
```

## Rechte

Vorhandenes SELECT für SELECT-Aufrufe; REFERENCES bei entsprechender Referenzverwendung. Kein Rechtegrant oder Identitätswechsel. Cross-Database-Zuordnung bleibt Caller-Voraussetzung.

## Ressourcenbedarf

Vorabgrenze 65536 UTF-16-Eingabebytes, Scan von höchstens 4000 Separator-Codeeinheiten und Aufnahme von höchstens 65 verschiedenen Codes als Grenzwächter. Der Inputscan hat höchstens 32769 Iterationen; zunächst bis zu 10000 Spans, erst nach vollständiger Prüfung Ergebnistokens. Bei Überlauf kein bereits ausgegebenes Tokenpräfix. Rückgabe-/Span-Tabellen sind lokale Funktionsvariablen, keine persistenten Objekte.

## Nebenwirkungen

Keine persistenten Daten-, Datei-, Netzwerk-, Trust-, Konfigurations- oder Caller-Transaktionsänderungen. Beschreibungen erteilen keine Ausführungsrechte.

## Fehlerbehandlung

Fachliche Fälle werden wie oben in Statusdaten beziehungsweise null Zeilen übersetzt. Die bis zu 65 aufgenommenen Codes werden erst auf NUL und dann auf Anzahl geprüft; bei mehr als 64 verschiedenen Codes mit zusätzlichem NUL ist kein Vorrang INVALID vor LIMIT zugesagt. Unerwartete Engine-/Bindungs-/Ressourcenfehler bleiben Fehler; kein Retry.

## Aussagegrenzen

BIN2-Codeeinheitenvergleich, keine sprachabhängige Case-/Accent-Äquivalenz und keine Unicode-Scalar-Separatoren. Ein Supplementary-Zeichen als Separator besteht aus zwei getrennten UTF-16-Einheiten und kann Surrogatpaare trennen. Duplikate zählen nur einmal; NUL ist als Separator verboten, im Input nicht allgemein verboten. Kein Tokenizer für mehrstellige Trenner, Quotes oder Escapes. Die Funktion sieht bereits gebundene Parameter; gekürzte ursprüngliche Separatorwerte werden nicht nachträglich erkannt.
