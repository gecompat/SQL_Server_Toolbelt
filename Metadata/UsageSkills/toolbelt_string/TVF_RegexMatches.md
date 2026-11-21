---
name: "toolbelt-string-tvf-regexmatches"
description: "Materialisiert nicht überlappende Gesamttreffer mit Position, Länge und Originaltext."
skill_format_version: "1.0"
module_id: "toolbelt.string.regex"
schema_name: "toolbelt_string"
object_name: "TVF_RegexMatches"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten in standard,8388608 in large. Keine automatische Kürzung."}, {"name": "@Pattern", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens8000 UTF-16-Einheiten, nach Übersetzung64000; Gruppentiefe64,Alternationen1024. Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus."}, {"name": "@Start", "sql_type": "int", "sql_default": "1", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. R2 validiert Profil,Flags,Input/Pattern und gegebenenfalls Replacement auch vor dieser Leerausgabe."}, {"name": "@Flags", "sql_type": "nvarchar(max)", "sql_default": "N'c'", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. Als nvarchar(max) gebunden, im begrenzten Intake maximal4 UTF-16-Einheiten."}, {"name": "@Profile", "sql_type": "nvarchar(max)", "sql_default": "N'standard'", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Exakt ordinal standard oder large, ohne Trim/Casefold. standard:1048576 UTF-16-Einheiten pro Input/Ersatz/Output und500ms kooperatives Budget; large:8388608 und2000ms. NULL/leer/andereWerte ungültig. Profilintake maximal8 Einheiten vor Start des gemeinsamen Kontexttimers. Früher Input/Pattern-NULL-Kurzschluss,beiReplace zusätzlichReplacementNULL, hat Vorrang."}, {"name": "@MaxRows", "sql_type": "int", "sql_default": "10000", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Ganzzahl1..100000, fachlich nichtNULL. Grenze der vollständig materialisierten Ausgabe, keine TOP-/Teilpräfixsemantik. Bei Überschreitung Fehler statt verwendbarer Teilzeilen. Zählt Gesamttreffer beziehungsweise sämtliche Splittokens einschließlich Leertokens."}]
source_paths: ["Modules/toolbelt.string.regex/Source/RegexRelations.sql", "Modules/toolbelt.string.regex/Clr/RegexBoundedIntake.cs", "Modules/toolbelt.string.regex/Clr/RegexProvider.cs", "Modules/toolbelt.string.regex/Clr/RegexTransformations.cs", "Modules/toolbelt.string.regex/Clr/RegexRelations.cs", "Modules/toolbelt.string.regex/Clr/RegexCaptures.cs"]
review_status: "verified"
source_module_version: "1.3.0"
---

# TVF_RegexMatches

## Zweck und Einsatzfälle

Materialisiert nicht überlappende Gesamttreffer mit Position, Länge und Originaltext.

## Voraussetzungen

Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | kein Default | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten in standard,8388608 in large. Keine automatische Kürzung. |
| `@Pattern` | `nvarchar(max)` | kein Default | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens8000 UTF-16-Einheiten, nach Übersetzung64000; Gruppentiefe64,Alternationen1024. Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus. |
| `@Start` | `int` | `1` | Input | Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. R2 validiert Profil,Flags,Input/Pattern und gegebenenfalls Replacement auch vor dieser Leerausgabe. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. Als nvarchar(max) gebunden, im begrenzten Intake maximal4 UTF-16-Einheiten. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Exakt ordinal standard oder large, ohne Trim/Casefold. standard:1048576 UTF-16-Einheiten pro Input/Ersatz/Output und500ms kooperatives Budget; large:8388608 und2000ms. NULL/leer/andereWerte ungültig. Profilintake maximal8 Einheiten vor Start des gemeinsamen Kontexttimers. Früher Input/Pattern-NULL-Kurzschluss,beiReplace zusätzlichReplacementNULL, hat Vorrang. |
| `@MaxRows` | `int` | `10000` | Input | Ganzzahl1..100000, fachlich nichtNULL. Grenze der vollständig materialisierten Ausgabe, keine TOP-/Teilpräfixsemantik. Bei Überschreitung Fehler statt verwendbarer Teilzeilen. Zählt Gesamttreffer beziehungsweise sämtliche Splittokens einschließlich Leertokens. |

Bei SELECT-/TVF-Aufrufen alle Argumentpositionen angeben; DEFAULT nutzt einen tatsächlich deklarierten SQL-Default. Technischer Default ist kein NULL-Ersatz. NULL-Kurzschluss wirkt erst nach SQL-Typbindung.

Kein beliebiger .NET-Regex: Literale, Metazeichen-Escapes, \n/\r/\t/\f, Punkt, ^/$, normale Gruppen, Alternation und Zeichenklassen/Bereiche. ASCII: \d=[0-9], \w=[A-Za-z0-9_], \s=[\x09-\x0D\x20]; Unicode-Kategorie ausschließlich \p{L}. Numerische Grenzen in {m}/{m,n}/{m,} höchstens1000; die offene Form {m,} bleibt nach oben offen, ebenso */+. Keine Lookarounds, Pattern-Backreferences, Inlineoptionen, lazy/possessive Quantoren oder allgemeine .NET-Erweiterungen. Leeres Pattern ist gültig. Ohne m bedeutet $ absolutes Inputende; keine abschließende-Newline-Sonderregel. Alle Positionen/Längen zählen UTF-16-Codeeinheiten, nicht Zeichen/Grapheme.

## Ergebnisse

| Spalte | SQL-Typ | Vertrag |
|---|---|---|
| `Ordinal` | `bigint` | 1-basierte Treffer-/Tokenreihenfolge |
| `StartPosition` | `bigint` | 1-basierte absolute UTF-16-Position |
| `Length` | `bigint` | UTF-16-Länge einschließlich0 |
| `Value` | `nvarchar(max)` | Originaltext,keine Normalisierung |

Explizit ORDER BY Ordinal verwenden. Split bewahrt Rand-/Zwischenleertokens, ohne Separator keine Änderung des einzigen Tokens; leere Quelle ergibt ein leeres Token. Matches ohne Treffer liefert null Zeilen. Vollständige Materialisierung vor Rückgabe, keine auswertbare Teilmenge bei Fachfehler. Kein ResultTable-/OUTPUT-/Hilfeparameter.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_string.TVF_RegexMatches(N'a1b22',N'\d+',1,N'c',N'standard',10000) ORDER BY Ordinal;
```

## Rechte

Vorhandenes SELECT auf die öffentliche TVF. Interne CLR-Kerne benötigen keine direkten Fachcallergrants. Zentraler Dreiteilname braucht bestehenden DB-Zugriff/Identitätsmapping; Ownership-Chains und tatsächliche Objektrechte bleiben maßgeblich. Kein SELECT auf fachliche Tabellen oder Systemkataloge im CLR-Kern; DataAccess/SystemDataAccess=None. Keine pauschale Serverrolle für Anwendung.

## Ressourcenbedarf

standard:1048576/500ms;large:8388608/2000ms. Der gemeinsame Kontext umfasst Flags-/Input-/Pattern-/Ersatzintake nach Profilwahl,Parsing,Konstruktor,Suche undOutput. Höchstens250ms pro Suchschritt; bei geringerem Restbudget Rekonstruktion mit engerem Timeout. Pattern8000/übersetzt64000,Schachtelung64,Alternationen1024. MaxRows1..100000; Summe der Value-Längen darf Profilgrenze nicht überschreiten.  Keine lineare Backtracking-,Peakheap-,GC-,SQL-Scheduling- oder harte Laufzeitgarantie. Keine Datenbankabfrage,Datei,Netzwerk oder fremdeRuntime. Kandidaten relational vorfiltern; Regexprädikate sind nicht SARGable.

## Nebenwirkungen

Keine persistente Mutation, keine Transaktion, kein Sessionkontext-/SET-/Tempobjektzugriff. Öffentliche Fassade gibt Unicodeargumente mit COLLATE DATABASE_DEFAULT an den einen internen Kern weiter; kein SQL-Katalogzugriff und keine Unicode-Normalisierung. Begrenzter SqlChars-Intake prüft Länge vor Kopie. NULLInput/Pattern beendet zuerst. Profil und numerische Argumente,Flags,Input,Pattern und Dialekt validieren; die Suche erhält den ganzen Originalinput. Nicht überlappende Suche; nach leerem Match rückt nur der Suchcursor um eine UTF-16-Einheit weiter. Ergebnis/Zeilen vollständig validieren/materialisieren; keine Fachfehler als erfolgreiche Teilresultate behandeln.

## Fehlerbehandlung

CLR-Fachfehler erscheinen in SQL als6522 mit stabilen Innerpräfixen: TBX_REGEX_INVALID_ARGUMENT,TBX_REGEX_INVALID_FLAGS,TBX_REGEX_INVALID_PATTERN,TBX_REGEX_INPUT_TOO_LARGE,TBX_REGEX_PATTERN_TOO_LARGE,TBX_REGEX_TIMEOUT. R2 zusätzlich TBX_REGEX_PATTERN_TOO_COMPLEX,TBX_REGEX_OUTPUT_TOO_LARGE; Replace auch TBX_REGEX_REPLACEMENT_TOO_LARGE. TVF zusätzlich TBX_REGEX_TOO_MANY_ROWS. SQL-Binder-,Engine-,Ressourcen- und Konvertierungsfehler bleiben sichtbar. Keine automatische Wiederholung oder abgeschnittene Erfolgsausgabe. Frühe NULL-/Startpfade können weitere Fachvalidierung absichtlich überspringen.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Unicode-/Grenz-/Minimalrechte-/Installer-/Collationabnahme. Historische Nachweise behalten ihre ursprüngliche Artefaktbindung. Kein allgemeiner .NET-/SQL-Regexdialekt und keine automatische Patternmigration. UTF-16 statt Grapheme, keine Unicode-Normalisierung; Timings sind kooperative Grenzen. Keine Installations-/Rechteattestation, kein Streamingversprechen. Vertrauliche Input-/Ersatztexte nicht öffentlich loggen.
