---
name: "toolbelt-string-svf-regexismatch"
description: "Prüft im begrenzten Toolbelt-Regexdialekt, ob mindestens ein Gesamttreffer existiert."
skill_format_version: "1.0"
module_id: "toolbelt.string.regex"
schema_name: "toolbelt_string"
object_name: "SVF_RegexIsMatch"
object_type: "CLR_SVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten=2097152Bytes."}, {"name": "@Pattern", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens4000 UTF-16-Einheiten=8000Bytes.Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus."}, {"name": "@Flags", "sql_type": "nvarchar(4)", "sql_default": "N'c'", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. SQL bindet nvarchar(4) schon vor dem CLR-Aufruf; eine ursprünglich breitere Clientquelle kann dabei gekürzt werden. Kein Nachweis ihrer ursprünglichen Länge."}]
source_paths: ["Modules/toolbelt.string.regex/Source/RegexFunctions.sql", "Modules/toolbelt.string.regex/Clr/RegexBoundedIntake.cs", "Modules/toolbelt.string.regex/Clr/RegexProvider.cs", "Modules/toolbelt.string.regex/Clr/RegexTransformations.cs", "Modules/toolbelt.string.regex/Clr/RegexRelations.cs", "Modules/toolbelt.string.regex/Clr/RegexCaptures.cs"]
review_status: "verified"
source_module_version: "1.3.0"
---

# SVF_RegexIsMatch

## Zweck und Einsatzfälle

Prüft im begrenzten Toolbelt-Regexdialekt, ob mindestens ein Gesamttreffer existiert.

## Voraussetzungen

Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | kein Default | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten=2097152Bytes. |
| `@Pattern` | `nvarchar(max)` | kein Default | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens4000 UTF-16-Einheiten=8000Bytes.Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus. |
| `@Flags` | `nvarchar(4)` | `N'c'` | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. SQL bindet nvarchar(4) schon vor dem CLR-Aufruf; eine ursprünglich breitere Clientquelle kann dabei gekürzt werden. Kein Nachweis ihrer ursprünglichen Länge. |

Bei SELECT-/TVF-Aufrufen alle Argumentpositionen angeben; DEFAULT nutzt einen tatsächlich deklarierten SQL-Default. Technischer Default ist kein NULL-Ersatz. NULL-Kurzschluss wirkt erst nach SQL-Typbindung.

Kein beliebiger .NET-Regex: Literale, Metazeichen-Escapes, \n/\r/\t/\f, Punkt, ^/$, normale Gruppen, Alternation und Zeichenklassen/Bereiche. ASCII: \d=[0-9], \w=[A-Za-z0-9_], \s=[\x09-\x0D\x20]; Unicode-Kategorie ausschließlich \p{L}. Numerische Grenzen in {m}/{m,n}/{m,} höchstens1000; die offene Form {m,} bleibt nach oben offen, ebenso */+. Keine Lookarounds, Pattern-Backreferences, Inlineoptionen, lazy/possessive Quantoren oder allgemeine .NET-Erweiterungen. Leeres Pattern ist gültig. Ohne m bedeutet $ absolutes Inputende; keine abschließende-Newline-Sonderregel. Alle Positionen/Längen zählen UTF-16-Codeeinheiten, nicht Zeichen/Grapheme.

## Ergebnisse

bit:1 mindestens ein Treffer,0 kein Treffer,NULL bei Input/PatternNULL. Ein einzelner Skalar, kein zusätzlicher Resultset/OUTPUT-/Hilfeparameter. Input/PatternNULL und beiReplaceReplacementNULL ergebenNULL vor weiterer CLR-Prüfung.

## Aufrufbeispiele

```sql
SELECT toolbelt_string.SVF_RegexIsMatch(N'Contoso 42',N'\d+',DEFAULT) AS HasDigits;
```

## Rechte

Vorhandenes EXECUTE auf die öffentliche Skalarfunktion. Interne CLR-Kerne benötigen keine direkten Fachcallergrants. Zentraler Dreiteilname braucht bestehenden DB-Zugriff/Identitätsmapping; Ownership-Chains und tatsächliche Objektrechte bleiben maßgeblich. Kein SELECT auf fachliche Tabellen oder Systemkataloge im CLR-Kern; DataAccess/SystemDataAccess=None. Keine pauschale Serverrolle für Anwendung.

## Ressourcenbedarf

IsMatch hat250ms Engine-Matchtimeout ohne eigenes500ms Gesamtbudget; Intake,Parser/Konstruktor und Allokation sind keine harteWallclock-Garantie. Keine lineare Backtracking-,Peakheap-,GC-,SQL-Scheduling- oder harte Laufzeitgarantie. Keine Datenbankabfrage,Datei,Netzwerk oder fremdeRuntime. Kandidaten relational vorfiltern; Regexprädikate sind nicht SARGable.

## Nebenwirkungen

Keine persistente Mutation, keine Transaktion, kein Sessionkontext-/SET-/Tempobjektzugriff. Begrenzter SqlChars-Intake prüft Länge vor Kopie. NULLInput/Pattern beendet zuerst. Nicht überlappende Suche; nach leerem Match rückt nur der Suchcursor um eine UTF-16-Einheit weiter. Ergebnis/Zeilen vollständig validieren/materialisieren; keine Fachfehler als erfolgreiche Teilresultate behandeln.

## Fehlerbehandlung

CLR-Fachfehler erscheinen in SQL als6522 mit stabilen Innerpräfixen: TBX_REGEX_INVALID_ARGUMENT,TBX_REGEX_INVALID_FLAGS,TBX_REGEX_INVALID_PATTERN,TBX_REGEX_INPUT_TOO_LARGE,TBX_REGEX_PATTERN_TOO_LARGE,TBX_REGEX_TIMEOUT. SQL-Binder-,Engine-,Ressourcen- und Konvertierungsfehler bleiben sichtbar. Keine automatische Wiederholung oder abgeschnittene Erfolgsausgabe. Frühe NULL-/Startpfade können weitere Fachvalidierung absichtlich überspringen.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Unicode-/Grenz-/Minimalrechte-/Installer-/Collationabnahme. Historische Nachweise behalten ihre ursprüngliche Artefaktbindung. Kein allgemeiner .NET-/SQL-Regexdialekt und keine automatische Patternmigration. UTF-16 statt Grapheme, keine Unicode-Normalisierung; Timings sind kooperative Grenzen. Keine Installations-/Rechteattestation, kein Streamingversprechen. Vertrauliche Input-/Ersatztexte nicht öffentlich loggen.
