---
name: "toolbelt-toolbelt-toolbelt-string-tvf-unquotetoken"
description: "Entfernt ein unterstütztes äußeres Quote-Paar und decodiert dessen Escapes."
skill_format_version: "1.0"
module_id: "toolbelt.string.split-advanced"
schema_name: "toolbelt_string"
object_name: "TVF_UnquoteToken"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Ein Token mit maximal 65536 UTF-16-Einheiten; leer ist gültig, NUL verboten. NULL liefert vor jeder Konfigurationsprüfung keine Zeile. Erkannte/explicit verlangte äußere Qualifier werden entfernt; ein unescaped inneres Closing-Zeichen ergibt eine ungültige Ergebniszeile."}, {"name": "@Qualifier", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "NULL (Default) erkennt nur direkt am Rand die Paare Doppelquote/Doppelquote, Apostroph/Apostroph, [/], “/” oder „/“; keine Rand-Whitespacebereinigung. Kein erkanntes Paar lässt den Token unverändert. Leer deaktiviert Unquote und verlangt ClosingQualifier=NULL. Explizit genau eine UTF-16-Einheit, weder NUL noch Surrogat; mit ClosingQualifier=NULL werden [ und ] zu [/], “ und ” zu “/”, „ zu „/“, andere Zeichen zu identischen Öffnern/Schließern normalisiert."}, {"name": "@ClosingQualifier", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "NULL (Default) verwendet das aus Qualifier abgeleitete Paar beziehungsweise die automatische Erkennung. Andernfalls genau eine nicht-NUL-/nicht-Surrogat-UTF-16-Einheit, nur zusammen mit einem expliziten nicht leeren Qualifier. Erfordert genau dieses Außenpaar; bei BackslashEscape=1 darf kein Qualifier Backslash sein."}, {"name": "@BackslashEscape", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ im gebundenen bit: 0 erkennt nur verdoppelte Closing-Zeichen (Default); 1 erkennt zusätzlich Backslash vor Öffner, Schließer oder Backslash. NULL wirkt wie 0. Keine JSON-/C-Interpretation von \\n, \\t usw.; Backslash darf im aktiven Modus kein Qualifier sein."}]
source_paths: ["Modules/toolbelt.string.split-advanced/Source/TVF_UnquoteToken.sql"]
review_status: "verified"
source_module_version: "1.1.0"
---

# TVF_UnquoteToken

## Zweck und Einsatzfälle

Entfernt genau ein erkanntes oder explizit verlangtes Außenpaar und dekodiert innere verdoppelte Closing-Zeichen sowie optional die festgelegten Backslash-Escapes. Eigenständiger Token-Transformator nach einem Split, kein Eingriff in den Split-Tokenizer.

## Voraussetzungen

SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. Split-Advanced-Modul installiert; diese Funktion selbst hat keine Tabellen-/Helper-/CLR-/Netzwerkabhängigkeit. Alle vier Argumentpositionen angeben, DEFAULT für die gewünschten technischen Defaults.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Ein Token mit maximal 65536 UTF-16-Einheiten; leer ist gültig, NUL verboten. NULL liefert vor jeder Konfigurationsprüfung keine Zeile. Erkannte/explicit verlangte äußere Qualifier werden entfernt; ein unescaped inneres Closing-Zeichen ergibt eine ungültige Ergebniszeile. |
| `@Qualifier` | `nvarchar(max)` | `NULL` | NULL (Default) erkennt nur direkt am Rand die Paare Doppelquote/Doppelquote, Apostroph/Apostroph, [/], “/” oder „/“; keine Rand-Whitespacebereinigung. Kein erkanntes Paar lässt den Token unverändert. Leer deaktiviert Unquote und verlangt ClosingQualifier=NULL. Explizit genau eine UTF-16-Einheit, weder NUL noch Surrogat; mit ClosingQualifier=NULL werden [ und ] zu [/], “ und ” zu “/”, „ zu „/“, andere Zeichen zu identischen Öffnern/Schließern normalisiert. |
| `@ClosingQualifier` | `nvarchar(max)` | `NULL` | NULL (Default) verwendet das aus Qualifier abgeleitete Paar beziehungsweise die automatische Erkennung. Andernfalls genau eine nicht-NUL-/nicht-Surrogat-UTF-16-Einheit, nur zusammen mit einem expliziten nicht leeren Qualifier. Erfordert genau dieses Außenpaar; bei BackslashEscape=1 darf kein Qualifier Backslash sein. |
| `@BackslashEscape` | `bit` | `0` | Taxativ im gebundenen bit: 0 erkennt nur verdoppelte Closing-Zeichen (Default); 1 erkennt zusätzlich Backslash vor Öffner, Schließer oder Backslash. NULL wirkt wie 0. Keine JSON-/C-Interpretation von \n, \t usw.; Backslash darf im aktiven Modus kein Qualifier sein. |

## Ergebnisse

Input=NULL liefert vor jeder Konfigurationsprüfung null Zeilen. Sonst genau eine atomare Zeile: Value nvarchar(max), IsValid bit NOT NULL, ErrorCode varchar(64), ErrorPosition bigint. Erfolg hat IsValid=1, Fehlerfelder NULL; fachlicher Fehler hat Value=NULL, IsValid=0 und einen der unten genannten Codes. Auto ohne vollständiges unterstütztes Außenpaar oder Qualifier=leer liefert den Token unverändert; es wird vorher nicht getrimmt. Bei erfolgreichem Unquote ist nur ein Außenpaar entfernt, kein rekursives Unquote.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_string.TVF_UnquoteToken
 (N'[a]]b]',DEFAULT,DEFAULT,DEFAULT);
-- Value=a]b, IsValid=1, ErrorCode/ErrorPosition=NULL.
SELECT * FROM toolbelt_string.TVF_UnquoteToken
 (NULL,DEFAULT,DEFAULT,DEFAULT);
-- Keine Zeile.
```

## Rechte

Vorhandenes SELECT auf der TVF für SELECT-Aufrufe; REFERENCES bei entsprechender Referenzverwendung. Kein Rechtegrant oder Identitätswechsel. Cross-Database-Zuordnung bleibt beim Caller.

## Ressourcenbedarf

Input höchstens 65536 UTF-16-Codeeinheiten, also 131072 Bytes; dies ist ausdrücklich nicht die 65536-Byte-Grenze des einfachen Splitters. Konfigurations-/NUL-/Rand-/Innenscans sind begrenzt. Unveränderte Spans werden gesammelt und am Ende geordnet per STRING_AGG kopiert, statt die Ausgabe nach jedem Zeichen zu verlängern. Keine Streaming-/Parallelitäts- oder Laufzeitgarantie.

## Nebenwirkungen

Rein lesend ohne persistente DML-, Datei-, Netzwerk-, Trust-, Konfigurations- oder Transaktionsänderung. Die Span-/Rückgabetabellen sind nur lokale Funktionsvariablen.

## Fehlerbehandlung

Nach Input-NULL hat ungültige Qualifierkonfiguration Vorrang (INVALID_CONFIGURATION, Position=NULL), danach Inputlänge (INPUT_LIMIT_EXCEEDED, Position=NULL), dann erstes NUL (NUL_NOT_ALLOWED, einbasierte Originalposition). Expliziter Modus ohne gültiges Außenpaar ergibt OUTER_PAIR_REQUIRED: leer Position=NULL, Länge1 Position1, falscher Öffner Position1, sonst letzte Position. Ein im aktiven Innenbereich nicht escaptes Closing ergibt UNESCAPED_CLOSING_QUALIFIER an dessen Originalposition. Unerwartete Enginefehler bleiben Fehler; keine Teilstrings als Fehlerergebnis.

## Aussagegrenzen

Qualifier sind einzelne nicht-NUL-/nicht-Surrogat-UTF-16-Einheiten; der Input ist kein allgemeiner Unicode-Scalar-Validator. Auto erkennt nur am ersten Zeichen Doppelquote, Apostroph, [, “ oder „ mit den zugehörigen Schließern. Ein escaptes letztes Closing gilt nicht als Außenende: explizit Fehler, automatisch unverändert. Backslash-Escape hat innen Vorrang vor doubled closing; das reservierte letzte Außenzeichen kann nicht zweite Hälfte eines inneren Double sein. Andere Backslashfolgen wie \n bleiben unverändert; kein JSON-/C-/CSV-Parser. Fehlerpositionen sind einbasierte BIN2-UTF-16-Originalpositionen.
