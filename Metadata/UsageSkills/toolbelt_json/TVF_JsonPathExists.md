---
name: "toolbelt-toolbelt-toolbelt-json-tvf-jsonpathexists"
description: "Prüft, ob ein unterstützter Pfad in einem JSON-Dokument existiert."
skill_format_version: "1.0"
module_id: "toolbelt.json.path-exists"
schema_name: "toolbelt_json"
object_name: "TVF_JsonPathExists"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Json", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Vollständiger JSON-Wert einschließlich Skalar/root-null, maximal 16777216 UTF-16-Bytes und lexikalische Containertiefe 128. Leer ist ungültiges JSON. NULL in Json oder Path liefert SQL_NULL/NULL vor weiterer Prüfung. Syntaxfehler ergeben INVALID/0; Ressourcenüberschreitungen LIMIT/NULL im Statuskern beziehungsweise NULL in der Wertfassade. Frontier höchstens 10000 Werte, kumulatives Parserworkbudget 67108864 Bytes."}, {"name": "@Path", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "SQL/JSON-Teilmenge, maximal 4000 UTF-16-Einheiten/128 Segmente: $ für Root, .ASCII_key mit Buchstaben/Ziffern/_, .\"JSON-escaped key\" für beliebige Keys, [0].. mit nullbasiertem ASCII-Dezimalindex ohne führende Nullen, [*] für beliebiges Arrayelement. Keine Objektwildcards, Filter, Ranges, Indexlisten oder last. Optionale Präfixe lax / strict werden case-insensitiv erkannt und ändern den Existenzvertrag nicht; äußere normale Spaces werden entfernt. Keys bleiben binär/case-sensitiv. Leer/fehlerhaft ergibt INVALID/0; NULL ergibt SQL_NULL/NULL. Objektschlüssel verlangen BIN2-Gleichheit UND identische UTF16-Bytelänge; a und a<Space> sowie leer und Space sind verschieden. Steuer-/Wildcardvergleiche behalten die vorhandene SQL-Paddingsemantik; dies ist keine vollständige native SQL/JSON-Pfadgrammatik."}]
source_paths: ["Modules/toolbelt.json.path-exists/Source/TVF_JsonPathExists.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# TVF_JsonPathExists

## Zweck und Einsatzfälle

Prüft, ob ein unterstützter Pfad in einem JSON-Dokument existiert.

## Voraussetzungen

JSONpath-Modul mit nativer ISJSON/OPENJSON-Unterstützung in derselben DB. Windows/Linux SQL2019/2022/2025, CL150/160/170 im zulässigen Hostprofil. Kein Quellkatalog-, Datei-, Netzwerk-, CLR- oder Trustzugriff.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@Json` | `nvarchar(max)` | kein Default | Input | Vollständiger JSON-Wert einschließlich Skalar/root-null, maximal 16777216 UTF-16-Bytes und lexikalische Containertiefe 128. Leer ist ungültiges JSON. NULL in Json oder Path liefert SQL_NULL/NULL vor weiterer Prüfung. Syntaxfehler ergeben INVALID/0; Ressourcenüberschreitungen LIMIT/NULL im Statuskern beziehungsweise NULL in der Wertfassade. Frontier höchstens 10000 Werte, kumulatives Parserworkbudget 67108864 Bytes. |
| `@Path` | `nvarchar(max)` | kein Default | Input | SQL/JSON-Teilmenge, maximal 4000 UTF-16-Einheiten/128 Segmente: $ für Root, .ASCII_key mit Buchstaben/Ziffern/_, ."JSON-escaped key" für beliebige Keys, [0].. mit nullbasiertem ASCII-Dezimalindex ohne führende Nullen, [*] für beliebiges Arrayelement. Keine Objektwildcards, Filter, Ranges, Indexlisten oder last. Optionale Präfixe lax / strict werden case-insensitiv erkannt und ändern den Existenzvertrag nicht; äußere normale Spaces werden entfernt. Keys bleiben binär/case-sensitiv. Leer/fehlerhaft ergibt INVALID/0; NULL ergibt SQL_NULL/NULL. Objektschlüssel verlangen BIN2-Gleichheit UND identische UTF16-Bytelänge; a und a<Space> sowie leer und Space sind verschieden. Steuer-/Wildcardvergleiche behalten die vorhandene SQL-Paddingsemantik; dies ist keine vollständige native SQL/JSON-Pfadgrammatik. |

Alle Positionen beim SELECT-Aufruf angeben; DEFAULT verwendet einen deklarierten Funktionsdefault, NULL bleibt ein eigener Wert. SQL-Typbindung und eine mögliche Kürzung auf feste Parameterbreite liegen vor dem Funktionskörper.

## Ergebnisse

Genau eine Zeile mit PathExists int NULL. FOUND ->1,MISSING/INVALID ->0,SQL_NULL/LIMIT ->NULL. Für die Unterscheidung Status-TVF verwenden; keine zusätzliche Statusspalte.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{"items":[{"name":null}]}',N'$.items[*].name');
SELECT * FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{"a ":1}',N'$."a"');
```

## Rechte

Vorhandenes SELECT/REFERENCES auf gewählten TVFs und erforderliche normale Ownershipchain. OPENJSON auf übergebenen Werten braucht keine Source-Datenrechte oder Metadatenvollsicht. Keine Rechteerteilung.

## Ressourcenbedarf

Json maximal16777216UTF16Bytes; rohe Containertiefe128 vor nativer JSON-Prüfung; Path maximal8000UTF16Bytes,128Segmente. Frontier maximal10000Werte,10001Kandidaten zur Überschreitungserkennung. Kumulatives Parserworkbudget67108864Bytes zählt Envelope-/Frontierparseranteile vor den jeweiligen Aufrufen, keine Messung der gesamten CLR-/Engine-/LOB-/Tempdb-Allokation. Quoted-Path-/Root-Envelopes und Frontierkopien zusätzlicher Aufwand. Keine harte Deadline/Peakheap-/Produktionskapazitätszusage.

## Nebenwirkungen

NULL in Json oder Path liefert zuerst SQL_NULL. Json-Inputbytes begrenzen; rohes JSON chunkweise mit Quoting/Escapes auf Containertiefe prüfen, bevor native ISJSON-Prüfung erfolgt. Danach Pathbytegrenze, äußere normale Spaces entfernen und optionales lax/strict-Präfix case-insensitiv abnehmen. Endlicher Parser für Root$, ASCII-Dotkeys, JSON-quotierte Dotkeys, einzelne Dezimalindizes und Arraywildcard. Quotedkeys durch geschütztes OPENJSON eines Stringarrays entescapen. Steuer-/Wildcardvergleiche bleiben SQL-Vergleiche einschließlich Padding, keine vollständige native Pfadgrammatik. Maximal128Segmente; ungültiger Pfad INVALID.

Container per ISJSON prüfen; skalare Rootwerte einschließlich JSONnull in ein geschütztes Einzelelementarray einhüllen. Eine Rootfrontierzeile verlangen. Jede Pfadstufe expandiert mit OPENJSON nur Objekt/Arraywerte, nie einen SQL-Ausdruck. Propertymatch verlangt Objektparent sowie binären Schlüsselvergleich und identische DATALENGTH, Indexmatch Arrayparent sowie denselben exakten Keyvergleich; Wildcard nur Array. JSONnull zählt als vorhandener Wert. Vor jeder Parserstufe kumulierten Workcharge prüfen; NextFrontier auf10001Kandidaten begrenzen und >10000 alsLIMIT verwerfen. Nach leerer Frontier stoppen. Mehrere Treffer/Duplikatschlüssel bleiben Existenz, keine geordnete Trefferliste. Wrapper übernimmt ausschließlich PathExists. Keine fachliche Tabelle, eigene Transaktion, Mutation oder dynamische SQL-Ausführung.

## Fehlerbehandlung

SQL_NULL vor Quoten; Jsonbyte-/rohe Tiefen-/Segment-/Frontier-/Workquote ->LIMIT/NULL. Überlanger Pfad ->INVALID/0, ebenso erkannte ungültige Pfad-/JSONformen. Falsche Struktur oder fehlender Key/Index ->MISSING/0, nicht INVALID. Unerwartete Typbindungs-, OPENJSON-/Engine-/Ressourcenfehler bleiben Originalfehler; kein allgemeines TRY-CATCH in der UDF.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag. Die ausdrücklich deklarierten funktionalen Korrekturen in diesem Modul benötigen neue native Gegenproben; historische Nachweise qualifizieren nur ihre ursprünglichen Bytes. Noch kein aktuelles natives API-/SC-/UTF8-/Caller-/Gesamtinstaller-PASS. Keine Installations-/Rechteattestation. Nur synthetische Beispiele; reale Eingaben/Runtimeausgaben privat halten.
