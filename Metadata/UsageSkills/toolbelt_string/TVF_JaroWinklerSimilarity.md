---
name: "toolbelt-edit-distance-tvf-jarowinklersimilarity"
description: "Begrenzte symmetrische Unicode-Skalar-Jaro-Winkler-Ähnlichkeit."
skill_format_version: "1.0"
module_id: "toolbelt.string.edit-distance"
schema_name: "toolbelt_string"
object_name: "TVF_JaroWinklerSimilarity"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@LeftText", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Unicode-Text als nvarchar(max), ohne Trimmen, Culture-/Casefolding oder Normalisierung. NUL und nachgestellte Spaces bleiben Daten. NULL auf mindestens einer Textseite liefert eine Zeile mit NULL-Fachwerten und ErrorCode=0 vor allen Profil-, Schwellen- und Längenprüfungen. Leerer Text ist von NULL verschieden. Verglichen werden strikte Unicode-Skalare, keine Graphemcluster."}, {"name": "@RightText", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Unicode-Text als nvarchar(max), ohne Trimmen, Culture-/Casefolding oder Normalisierung. NUL und nachgestellte Spaces bleiben Daten. NULL auf mindestens einer Textseite liefert eine Zeile mit NULL-Fachwerten und ErrorCode=0 vor allen Profil-, Schwellen- und Längenprüfungen. Leerer Text ist von NULL verschieden. Verglichen werden strikte Unicode-Skalare, keine Graphemcluster."}, {"name": "@Profile", "sql_type": "nvarchar(max)", "sql_default": "N'standard'", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Exakt ordinal standard oder large, keine andere Schreibweise und kein Trim. standard: je Text maximal 2048 UTF-16-Codeunits und 1024 Skalare, maximal 1048576 geplante Arbeitseinheiten. large: 65536 Codeunits, 32768 Skalare, 16777216 Arbeitseinheiten. NULL/leer/unbekannt liefert Code 1, außer beim früheren NULL-Textpfad. Im SQL-Funktionsaufruf bei vorhandenem Default das Argument ausdrücklich als DEFAULT angeben statt seine Position wegzulassen. SQL-Default standard."}]
source_paths: ["Modules/toolbelt.string.edit-distance/Source/JaroWinkler.sql", "Modules/toolbelt.string.edit-distance/Clr/JaroProvider.cs", "Modules/toolbelt.string.edit-distance/Clr/JaroKernel.cs", "Modules/toolbelt.string.edit-distance/Clr/UnicodeScalar.cs"]
review_status: "verified"
source_module_version: "1.1.0"
---

# TVF_JaroWinklerSimilarity

## Zweck und Einsatzfälle

Begrenzte symmetrische Unicode-Skalar-Jaro-Winkler-Ähnlichkeit. Öffentlicher mengenorientierter Einstieg; per CROSS/OUTER APPLY auf eigene Zeilen anwenden.

## Voraussetzungen

Installiertes Modul und passende SAFE-Assembly tlblt_String_EditDistance auf unterstütztem SQL Server 2019/2022/2025 unter Windows oder Linux; lokaler/zentraler Aufruf gemäß Modulvertrag. CLR muss bereits gültig konfiguriert und autorisiert sein. Kein Daten-/Systemkatalog-, Datei- oder Netzwerkzugriff im Vergleichskern, keine nachgeladene Library oder Runtime-Rechtevergabe.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@LeftText` | `nvarchar(max)` | `kein Default` | Unicode-Text als nvarchar(max), ohne Trimmen, Culture-/Casefolding oder Normalisierung. NUL und nachgestellte Spaces bleiben Daten. NULL auf mindestens einer Textseite liefert eine Zeile mit NULL-Fachwerten und ErrorCode=0 vor allen Profil-, Schwellen- und Längenprüfungen. Leerer Text ist von NULL verschieden. Verglichen werden strikte Unicode-Skalare, keine Graphemcluster. |
| `@RightText` | `nvarchar(max)` | `kein Default` | Unicode-Text als nvarchar(max), ohne Trimmen, Culture-/Casefolding oder Normalisierung. NUL und nachgestellte Spaces bleiben Daten. NULL auf mindestens einer Textseite liefert eine Zeile mit NULL-Fachwerten und ErrorCode=0 vor allen Profil-, Schwellen- und Längenprüfungen. Leerer Text ist von NULL verschieden. Verglichen werden strikte Unicode-Skalare, keine Graphemcluster. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Exakt ordinal standard oder large, keine andere Schreibweise und kein Trim. standard: je Text maximal 2048 UTF-16-Codeunits und 1024 Skalare, maximal 1048576 geplante Arbeitseinheiten. large: 65536 Codeunits, 32768 Skalare, 16777216 Arbeitseinheiten. NULL/leer/unbekannt liefert Code 1, außer beim früheren NULL-Textpfad. Im SQL-Funktionsaufruf bei vorhandenem Default das Argument ausdrücklich als DEFAULT angeben statt seine Position wegzulassen. SQL-Default standard. |

## Ergebnisse

Genau eine Zeile Similarity float(53) NULL und ErrorCode int. Code 0 mit zwei nicht-NULL-Texten liefert einen Wert 0..1; beide leer ergibt 1, genau einer leer 0. Bei NULL-Text oder Fehler ist Similarity NULL. Die Orientierung nach Länge und Skalarlexikographie macht den Kern symmetrisch. Matchingfenster max(0,floor(max(n,m)/2)-1), Transpositionsanteil h/2 als reeller Wert. Präfixbonus 0.1 je übereinstimmendem ersten Skalar, höchstens vier, ausschließlich bei Jaro strikt >0.7; kein Bonus bei genau 0.7. ErrorCode ist logisch immer gesetzt, auch wenn die SQL-/Clientmetadaten des CLR-Transports Nullable erlauben. Keine Erfolgsnormalisierung eines fehlenden Providers, keine OUTPUT-Parameter.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_string.TVF_JaroWinklerSimilarity(N'MARTHA',N'MARHTA',N'standard');
-- Similarity ungefähr 0.961111; ErrorCode=0.
-- Für Profil-/Schwellen-Defaults die Position mit DEFAULT belegen.
```

## Rechte

Vorhandenes SELECT auf dieser öffentlichen TVF und passende bestehende Ownership-/Abhängigkeitsrechte. Bestehende CLR-/Trustvoraussetzungen separat erfüllen. Kein VIEW SERVER STATE, Quellkatalogrecht oder Identitätswechsel aus dem Vergleich ableiten; Skillbeschreibung erteilt keine Berechtigung.

## Ressourcenbedarf

Strikte Skalarvalidierung und danach dekodierte int-Arrays, Matchindizes und Used-Flags proportional zu beiden Textlängen. Konservativ geplante Fensterplätze werden vor dem Matching gegen das Profilbudget geprüft; tatsächliche frühe Matches können weniger Plätze besuchen. Kein Schwellenparameter. Der Provider prüft SqlChars-Längen vor eigenen Textkopien. Endliche Profilgrenzen sind keine vollständige CLR-Heap-, CPU-, Laufzeit-, SARGability- oder Parallelitätsgarantie. Die öffentliche SQL-Hülle ist eine inline TVF über den CLR-Core; das verspricht kein relationales Inlining des CLR-Algorithmus.

## Nebenwirkungen

Deterministische Berechnung aus Argumenten ohne Normalisierung oder persistente Änderungen. Keine DML, Temp-Tabellen, Transaktionen, Session-Context-Schreibzugriffe, Datei-/Netzwerkoperationen oder automatischen Installationsschritte. Temporäre CLR-Allokationen gehören nur zum Aufruf.

## Fehlerbehandlung

Reihenfolge: NULL-Text kurzschließt mit Code 0; sonst 1 ungültiges Profil, 3 UTF-16-Rohlängenlimit, 4 ungültige Surrogatfolge, 5 Skalarzahlgrenze, 6 geplante Fensterarbeit überschritten. Jaro verwendet keinen Code 2. Fachfehler sind Resultatdaten und keine SQL-THROWs. Transport-/Engine-/Speicherfehler bleiben technische Fehler; keine pauschale Exceptionunterdrückung.

## Aussagegrenzen

Quellgeprüfter Vertrag, keine neue native Gesamtqualifikation. Historische Modul-/Binärnachweise nur bei tatsächlicher unveränderter Bindung verwenden. Unicode-Skalare sind keine Wörter oder Grapheme; kein sprachlicher Ähnlichkeits-, Culture- oder Normalisierungsvertrag. Fehlender Distanzwert bei Schwellennachweis bedeutet nicht Distanz 0; NULL-Fachwerte bei Code 0 können aus NULL-Eingaben stammen. Größen-/Worklimits werden nicht durch eine gleiche Eingabe oder große Distanzschwelle aufgehoben.
