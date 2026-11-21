---
name: "toolbelt-toolbelt-toolbelt-json-tvf-resolvejsonpointer"
description: "Löst einen RFC6901-Pointer mit exakten Keys und unterscheidet FOUND, MISSING, JSON_NULL, SQL_NULL und INVALID. Der freigegebene feste128er-Guard gibt darüber DEPTH_LIMIT vor JSON_SYNTAX zurück."
skill_format_version: "1.0"
module_id: "toolbelt.json.pointer"
schema_name: "toolbelt_json"
object_name: "TVF_ResolveJsonPointer"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Json", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Vollständiger JSON-Wert einschließlich Skalar/root-null, wohlgeformtes Unicode auch in decodierten Escapes. Leer ist ungültig; DATALENGTH darf MaxInputBytes nicht überschreiten. Vor nativer Prüfung gilt die absolute Containertiefengrenze 128, danach das abgesenkte MaxDepth. NULL in Json oder Pointer ergibt SQL_NULL vor Parameterprüfung. Kein partiell gültiges Dokument und keine Mutation. Argumentposition ausdrücklich angeben; nur bei den beiden vorhandenen SQL-Budgetdefaults ist DEFAULT zulässig. SQL-NULL in Json oder Pointer kurzschließt auch ungültige Budgets."}, {"name": "@Pointer", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "RFC6901-Stringpointer, keine URIfragmentform #/...: leer bezeichnet Root, sonst beginnt der Text mit /. Segmente sind exakte binäre/case-sensitive Objektkeys; ~0 decodiert einmal zu ~, ~1 zu /. Kein anderes ~-Escape oder Percentdecoding. Arrayindizes sind nullbasiert kanonische nicht negative ASCII-Dezimalzahlen ohne führende Nullen; - ist kein Appendindex, Wildcards fehlen. Maximal 4000 UTF-16-Einheiten, wohlgeformtes Unicode; / bezeichnet einen leeren Key. NULL ergibt SQL_NULL. Argumentposition ausdrücklich angeben; nur bei den beiden vorhandenen SQL-Budgetdefaults ist DEFAULT zulässig. SQL-NULL in Json oder Pointer kurzschließt auch ungültige Budgets."}, {"name": "@MaxInputBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": true, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216 UTF-16-Bytes des JSON-Dokuments, Default 16777216; keine Zeichenanzahl. NULL/außerhalb ergibt INVALID/PARAMETER, Überschreitung INVALID/INPUT_LIMIT. Nur absenkbar; früher Json-/Pointer-NULL-Pfad hat Vorrang. Argumentposition ausdrücklich angeben; nur bei den beiden vorhandenen SQL-Budgetdefaults ist DEFAULT zulässig. SQL-NULL in Json oder Pointer kurzschließt auch ungültige Budgets."}, {"name": "@MaxDepth", "sql_type": "int", "sql_default": "128", "is_output": false, "argument_required": true, "business_required": false, "nullable": false, "description": "Ganzzahl 1..128 gleichzeitig offene JSON-Container, Default 128. Gilt für das gesamte Dokument, auch nicht traversierte Teile. NULL/außerhalb ergibt INVALID/PARAMETER; vor nativer JSON-Prüfung bleibt zusätzlich die absolute Schutzgrenze 128 wirksam. Argumentposition ausdrücklich angeben; nur bei den beiden vorhandenen SQL-Budgetdefaults ist DEFAULT zulässig. SQL-NULL in Json oder Pointer kurzschließt auch ungültige Budgets."}]
source_paths: ["Modules/toolbelt.json.pointer/Source/TVF_ResolveJsonPointer.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# TVF_ResolveJsonPointer

## Zweck und Einsatzfälle

Löst genau einen RFC6901-Stringpointer gegen einen vollständigen JSON-Wert auf, einschließlich Scalarroot und JSON-null. Rein lesende native T-SQL-Multi-statement-TVF; kein JSON-Patch, kein URIfragment, keine SQL-Ausführung aus dem Eingabetext.

## Voraussetzungen

SQL Server2019/2022/2025 Windows/Linux gemäß Modulmatrix, unterstützter Compatibility Level mindestens150 auch im zentralen Aufrufkontext. Ausschließlich native ISJSON-/OPENJSON-Grammatik und begrenzter UTF16-Policywalker; keine CLR-Assembly, Daten-/Systemkatalogtabelle, Serveroption oder Abhängigkeit eines anderen Moduls. Der gesamte Input muss gültige Syntax, Tiefen- und Unicodepolicy erfüllen, auch nicht traversierte Teile.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@Json` | `nvarchar(max)` | `kein Default` | Vollständiger JSON-Wert einschließlich Skalar/root-null, wohlgeformtes Unicode auch in decodierten Escapes. Leer ist ungültig; DATALENGTH darf MaxInputBytes nicht überschreiten. Vor nativer Prüfung gilt die absolute Containertiefengrenze 128, danach das abgesenkte MaxDepth. NULL in Json oder Pointer ergibt SQL_NULL vor Parameterprüfung. Kein partiell gültiges Dokument und keine Mutation. Argumentposition ausdrücklich angeben; nur bei den beiden vorhandenen SQL-Budgetdefaults ist DEFAULT zulässig. SQL-NULL in Json oder Pointer kurzschließt auch ungültige Budgets. |
| `@Pointer` | `nvarchar(max)` | `kein Default` | RFC6901-Stringpointer, keine URIfragmentform #/...: leer bezeichnet Root, sonst beginnt der Text mit /. Segmente sind exakte binäre/case-sensitive Objektkeys; ~0 decodiert einmal zu ~, ~1 zu /. Kein anderes ~-Escape oder Percentdecoding. Arrayindizes sind nullbasiert kanonische nicht negative ASCII-Dezimalzahlen ohne führende Nullen; - ist kein Appendindex, Wildcards fehlen. Maximal 4000 UTF-16-Einheiten, wohlgeformtes Unicode; / bezeichnet einen leeren Key. NULL ergibt SQL_NULL. Argumentposition ausdrücklich angeben; nur bei den beiden vorhandenen SQL-Budgetdefaults ist DEFAULT zulässig. SQL-NULL in Json oder Pointer kurzschließt auch ungültige Budgets. |
| `@MaxInputBytes` | `bigint` | `16777216` | Ganzzahl 1..16777216 UTF-16-Bytes des JSON-Dokuments, Default 16777216; keine Zeichenanzahl. NULL/außerhalb ergibt INVALID/PARAMETER, Überschreitung INVALID/INPUT_LIMIT. Nur absenkbar; früher Json-/Pointer-NULL-Pfad hat Vorrang. Argumentposition ausdrücklich angeben; nur bei den beiden vorhandenen SQL-Budgetdefaults ist DEFAULT zulässig. SQL-NULL in Json oder Pointer kurzschließt auch ungültige Budgets. |
| `@MaxDepth` | `int` | `128` | Ganzzahl 1..128 gleichzeitig offene JSON-Container, Default 128. Gilt für das gesamte Dokument, auch nicht traversierte Teile. NULL/außerhalb ergibt INVALID/PARAMETER; vor nativer JSON-Prüfung bleibt zusätzlich die absolute Schutzgrenze 128 wirksam. Argumentposition ausdrücklich angeben; nur bei den beiden vorhandenen SQL-Budgetdefaults ist DEFAULT zulässig. SQL-NULL in Json oder Pointer kurzschließt auch ungültige Budgets. |

## Ergebnisse

Genau eine Zeile: Status varchar(16) NOT NULL, JsonType varchar(8) NULL, Value nvarchar(max) NULL, ErrorCode varchar(32) NULL; alle vier Spalten Latin1_General_100_BIN2. Taxative Statussemantik:

| Status | JsonType | Value | ErrorCode |
|---|---|---|---|
| FOUND | STRING, NUMBER, BOOLEAN, ARRAY oder OBJECT | gefundener Text/Fragment, auch leerer String | NULL |
| JSON_NULL | NULL als Typtext | SQL-NULL | NULL |
| MISSING | SQL-NULL | SQL-NULL | NULL |
| SQL_NULL | SQL-NULL | SQL-NULL | NULL |
| INVALID | SQL-NULL | SQL-NULL | stabiler Code |

Strings werden nativ decodiert, Numbers bleiben Textliterale ohne eigenen numerischen Cast, Booleans Text, Array-/Objektwerte Fragmente. Rootcontainer mit leerem Pointer bleibt der ursprüngliche vollständige Text; kein kanonischer JSON-Serializer oder einheitliches Whitespaceformat versprochen. Keine OUTPUT-Parameter, SQL-Rückgabecodes oder zusätzlichen Fehlerresultsets. Unerwartete technische Enginefehler sind keine garantierte INVALID-Zeile.

## Aufrufbeispiele

```sql
SELECT Status,JsonType,Value,ErrorCode
FROM toolbelt_json.TVF_ResolveJsonPointer(N'{"a/b":[null,"example"]}',N'/a~1b/1',DEFAULT,DEFAULT);
-- FOUND / STRING / example / NULL.
SELECT * FROM toolbelt_json.TVF_ResolveJsonPointer(N'null',N'',DEFAULT,DEFAULT);
-- JSON_NULL mit JsonType als Text NULL und Value SQL-NULL.
SELECT * FROM toolbelt_json.TVF_ResolveJsonPointer(NULL,NULL,0,0);
-- SQL_NULL vor Parameterfehlern.
```

## Rechte

Vorhandenes SELECT auf dieser öffentlichen TVF und gültige Datenbankauthentifizierung. Keine SELECT-Rechte auf Daten-/Systemtabellen oder Serverstatus-/Trustrechte, da solche Quellen nicht gelesen werden. Zentraler Dreiteilname ersetzt kein gültiges Ziel-DB-Mapping/Objektrecht. Die Funktion erteilt keine Rechte und ändert keinen Principal.

## Ressourcenbedarf

MaxInputBytes 1..16777216 Roh-UTF16-Bytes, MaxDepth 1..128 gleichzeitig offene Container im gesamten Dokument (Rootcontainer Tiefe1, Scalar0), beide nur absenkbar. Pointer maximal8000 Bytes=4000 UTF16-Codeunits einschließlich Slashes/Escapes. Fester vorgelagerter escape-aware Strukturguard bei beobachteter Tiefe>128 schützt native Grammatik, auch für sonst ungültiges JSON. Kumulatives festes Budget67108864 Bytes (64 MiB) ausschließlich für konkrete OPENJSON-Operanden: Scalarwrapper und wiederholt geparste Containerfragmente werden VOR jedem Aufruf geladen/charged; ISJSON und übrige Policy-/Tokenscans sind dadurch nicht als CPU-/Heapquote begrenzt. Originaldokument vorwärts in4000-Codeunit-Chunks scannen, niemals als schrumpfenden Rest kopieren; native Fragmentenumeration/COUNT/MAX und Kopien können sich je traversiertem Container wiederholen. Pointertokens werden codeunitweise bis zur festen Grenze aufgebaut. MSTVF mit materialisiertem Einzelresultat, keine behauptete inline-/Streaming-/APPLY-/Parallelitäts- oder Produktionsdurchsatzzusage.

## Nebenwirkungen

Deterministische lesende Berechnung aus expliziten Argumenten, keine persistenten Änderungen, Caller-Temps, Transaktionen, Session-Context-, Datei-/Netzwerk-/Katalogzugriffe. Status/Typen beschreiben das Eingabedokument, keine installierten Serverobjekte. Kein Hilfeschalter an dieser Funktion; vollständiger Skill in DDL und künftig gemeinsamem vollständigem SQL-Skillkatalog.

## Fehlerbehandlung

Priorität: SQL_NULL bei Json/Pointer NULL; INVALID/PARAMETER bei NULL/außerhalb der Budgetwerte; INPUT_LIMIT; POINTER_LIMIT; POINTER_SYNTAX (nicht leer und kein führender / oder ungültige ~-Sequenz); Pointer-UNICODE; fester Strukturguard128/DEPTH_LIMIT; JSON_SYNTAX; abgesenktes MaxDepth/DEPTH_LIMIT; Dokument-UNICODE; danach Traversal mit ARRAY_INDEX,DUPLICATE_KEY und vor jedem OPENJSON geprüfter WORK_LIMIT. Scalarwrapper wird auf genau einen nativen Rootwert geprüft, Listen/leer sind JSON_SYNTAX. Vollständige Dokument-Unicodeprüfung decodiert auch JSON-\uXXXX-Surrogate; ungepaarte rohe/decodierte Surrogate in Strings/Keys und Pointer werden abgewiesen, NUL als gültige Codeunit in Pointer/decodiertem Key ist kein generelles Verbot. Unicodefaults werden bis zur vollständigen Tiefenprüfung gespeichert, damit späteres Depthlimit Vorrang hat.

Leerer Pointer adressiert Root, sonst jeder Slash ein Token, auch leer. ~0=>~,~1=>/ genau einmal; ~01 wird ~1, kein Percentdecoding, kein URI-#fragment. Objektkeys exakt BIN2 PLUS DATALENGTH, daher case-/trailing-space-/NUL-sensitiv ohne Normalisierung. Nur mehrere passende Keys am tatsächlich adressierten Schritt sind DUPLICATE_KEY; unberührte Duplikate machen das Dokument nicht pauschal ungültig. Arraytoken: - bedeutet MISSING, sonst kanonisches ASCII-Dezimal 0 oder nichtnullführende Ziffern; leer,+1,-1,01 oder Nichtziffern sind ARRAY_INDEX. Kein Ganzzahlcast des Indextexts: auch riesige gültige Dezimalindizes werden gegen native Schlüssel verglichen und sind bei Fehlen MISSING statt Overflow. Weiterer Schritt unter Scalar/JSON-null ergibt MISSING. Kein früher MISSING-Pfad überspringt die vorherige vollständige Dokument-/Pointervalidierung. Unerwartete technische Fehler bleiben sichtbar; keine Input-Echos/Enginefehlertexte in eigenen Statuscodes.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Skill-/Installer-/Minimalrechte-/Ressourcenabnahme. Historische Fach-/Sicherheits-/Clientbelege behalten ihre ursprünglichen Artefaktbindungen. Keine Garantie unbegrenzter Kapazität, kanonischer Serialisierung oder sicherer weiterer Verarbeitung des gefundenen Textes. Keine Serverkonfiguration, SQL-/JSON-Patchmutation oder Installations-/Rechteattestation.
