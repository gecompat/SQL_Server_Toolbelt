SET ANSI_NULLS ON;
GO

-- ============================================================================
-- Objekt: toolbelt_string.SVF_RegexReplaceCore (intern)
-- Typ: CLR SVF; Zweck: SAFE-CLR-Kern der öffentlichen Replace-Fassade.
-- Vertrag: Documentation/SVF_RegexReplace.md; Parameter: max-Texte, Start=1,
-- Occurrence=0, Flags=c, Profile=standard; Resultset: nvarchar(max).
-- Dependencies: SAFE tlblt_String_Regex; keine direkten Fachcallergrants.
-- Versionen: SQL Server 2019/2022/2025; Plattformen: Windows/Linux.
-- Fehlerverhalten: SQL 6522 / TBX_REGEX_*; keine Teilresultate/Seiteneffekte.
-- Performance: vollständige Materialisierung, kooperatives Gesamtbudget.
-- Einschränkungen: UTF-16-Positionen, keine Captures oder Backreferences.
-- ============================================================================
-- Technischer CLR-Kern: max-Parameter besitzen hier keine Defaults, weil
-- SQL Server diese für CLR-Funktionen zurückweist (1096).
CREATE FUNCTION [toolbelt_string].[SVF_RegexReplaceCore]
(
      @Input nvarchar(max)
    , @Pattern nvarchar(max)
    , @Replacement nvarchar(max)
    , @Start int
    , @Occurrence int
    , @Flags nvarchar(max)
    , @Profile nvarchar(max)
)
RETURNS nvarchar(max)
WITH CALLED ON NULL INPUT
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-string-svf-regexreplacecore"
-- description: "Ersetzt ausgewählte Gesamttreffer durch literalen Unicode-Text ohne Gruppenexpansion. Interner CLR-Kern."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.string.regex"
-- schema_name: "toolbelt_string"
-- object_name: "SVF_RegexReplaceCore"
-- object_type: "CLR_SVF"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten in standard,8388608 in large. Keine automatische Kürzung."}, {"name": "@Pattern", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens8000 UTF-16-Einheiten, nach Übersetzung64000; Gruppentiefe64,Alternationen1024. Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus."}, {"name": "@Replacement", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Literaler Ersatztext: $1,${Name},Backslash werden nicht expandiert. Leer löscht den Treffer, NULL ergibt frühNULL. Ersatzlänge wie Profil; fertiger Output bleibt ebenfalls profilbegrenzt."}, {"name": "@Start", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. R2 validiert Profil,Flags,Input/Pattern und gegebenenfalls Replacement auch vor dieser Leerausgabe."}, {"name": "@Occurrence", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "0=alle Treffer abStart,positiv=nur n-ter Treffer;0..2147483647. NULL/negativ und bei Nicht-Replace0 sind ungültig. VorStart bleibt der Input beiReplace erhalten."}, {"name": "@Flags", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. Als nvarchar(max) gebunden, im begrenzten Intake maximal4 UTF-16-Einheiten."}, {"name": "@Profile", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Exakt ordinal standard oder large, ohne Trim/Casefold. standard:1048576 UTF-16-Einheiten pro Input/Ersatz/Output und500ms kooperatives Budget; large:8388608 und2000ms. NULL/leer/andereWerte ungültig. Profilintake maximal8 Einheiten vor Start des gemeinsamen Kontexttimers. Früher Input/Pattern-NULL-Kurzschluss,beiReplace zusätzlichReplacementNULL, hat Vorrang."}]
-- source_paths: ["Modules/toolbelt.string.regex/Source/RegexFunctions.sql", "Modules/toolbelt.string.regex/Clr/RegexBoundedIntake.cs", "Modules/toolbelt.string.regex/Clr/RegexProvider.cs", "Modules/toolbelt.string.regex/Clr/RegexTransformations.cs", "Modules/toolbelt.string.regex/Clr/RegexRelations.cs", "Modules/toolbelt.string.regex/Clr/RegexCaptures.cs"]
-- review_status: "verified"
-- source_module_version: "1.3.0"
-- public_entrypoints: ["toolbelt_string.SVF_RegexReplace"]
-- ---
--
-- # SVF_RegexReplaceCore
--
-- ## Zweck und Einsatzfälle
--
-- Ersetzt ausgewählte Gesamttreffer durch literalen Unicode-Text ohne Gruppenexpansion. Interner CLR-Kern. Öffentlichen Einstieg statt direktem Kern verwenden.
--
-- ## Voraussetzungen
--
-- Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@Input` | `nvarchar(max)` | kein Default | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten in standard,8388608 in large. Keine automatische Kürzung. |
-- | `@Pattern` | `nvarchar(max)` | kein Default | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens8000 UTF-16-Einheiten, nach Übersetzung64000; Gruppentiefe64,Alternationen1024. Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus. |
-- | `@Replacement` | `nvarchar(max)` | kein Default | Input | Literaler Ersatztext: $1,${Name},Backslash werden nicht expandiert. Leer löscht den Treffer, NULL ergibt frühNULL. Ersatzlänge wie Profil; fertiger Output bleibt ebenfalls profilbegrenzt. |
-- | `@Start` | `int` | kein Default | Input | Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. R2 validiert Profil,Flags,Input/Pattern und gegebenenfalls Replacement auch vor dieser Leerausgabe. |
-- | `@Occurrence` | `int` | kein Default | Input | 0=alle Treffer abStart,positiv=nur n-ter Treffer;0..2147483647. NULL/negativ und bei Nicht-Replace0 sind ungültig. VorStart bleibt der Input beiReplace erhalten. |
-- | `@Flags` | `nvarchar(max)` | kein Default | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. Als nvarchar(max) gebunden, im begrenzten Intake maximal4 UTF-16-Einheiten. |
-- | `@Profile` | `nvarchar(max)` | kein Default | Input | Exakt ordinal standard oder large, ohne Trim/Casefold. standard:1048576 UTF-16-Einheiten pro Input/Ersatz/Output und500ms kooperatives Budget; large:8388608 und2000ms. NULL/leer/andereWerte ungültig. Profilintake maximal8 Einheiten vor Start des gemeinsamen Kontexttimers. Früher Input/Pattern-NULL-Kurzschluss,beiReplace zusätzlichReplacementNULL, hat Vorrang. |
--
-- Interner CLR-Kern: alle Argumente explizit, kein technischer Default, keine direkte öffentliche Fachschnittstelle. NULL-Kurzschluss wirkt erst nach SQL-Typbindung.
--
-- Kein beliebiger .NET-Regex: Literale, Metazeichen-Escapes, \n/\r/\t/\f, Punkt, ^/$, normale Gruppen, Alternation und Zeichenklassen/Bereiche. ASCII: \d=[0-9], \w=[A-Za-z0-9_], \s=[\x09-\x0D\x20]; Unicode-Kategorie ausschließlich \p{L}. Numerische Grenzen in {m}/{m,n}/{m,} höchstens1000; die offene Form {m,} bleibt nach oben offen, ebenso */+. Keine Lookarounds, Pattern-Backreferences, Inlineoptionen, lazy/possessive Quantoren oder allgemeine .NET-Erweiterungen. Leeres Pattern ist gültig. Ohne m bedeutet $ absolutes Inputende; keine abschließende-Newline-Sonderregel. Alle Positionen/Längen zählen UTF-16-Codeeinheiten, nicht Zeichen/Grapheme.
--
-- ## Ergebnisse
--
-- nvarchar(max):gesamter Input mit ausgewählten literalen Ersetzungen; kein ausgewählter Treffer erhält Originalinput. Ein einzelner Skalar, kein zusätzlicher Resultset/OUTPUT-/Hilfeparameter. Input/PatternNULL und beiReplaceReplacementNULL ergebenNULL vor weiterer CLR-Prüfung.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Direkte Fachaufrufe dieses internen Kerns vermeiden.
-- -- Öffentlicher Einstieg:
-- SELECT toolbelt_string.SVF_RegexReplace(N'a1b22',N'\d+',N'$1',1,0,N'c',N'standard') AS LiteralReplacement;
-- -- $1 bleibt hier literal; für Gruppen die getrennte ReplaceGroups-API nutzen.
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf die öffentliche Skalarfunktion. Interne CLR-Kerne benötigen keine direkten Fachcallergrants. Zentraler Dreiteilname braucht bestehenden DB-Zugriff/Identitätsmapping; Ownership-Chains und tatsächliche Objektrechte bleiben maßgeblich. Kein SELECT auf fachliche Tabellen oder Systemkataloge im CLR-Kern; DataAccess/SystemDataAccess=None. Keine pauschale Serverrolle für Anwendung.
--
-- ## Ressourcenbedarf
--
-- standard:1048576/500ms;large:8388608/2000ms. Der gemeinsame Kontext umfasst Flags-/Input-/Pattern-/Ersatzintake nach Profilwahl,Parsing,Konstruktor,Suche undOutput. Höchstens250ms pro Suchschritt; bei geringerem Restbudget Rekonstruktion mit engerem Timeout. Pattern8000/übersetzt64000,Schachtelung64,Alternationen1024. Input,Ersatz undfertigerOutput je profilbegrenzt.  Keine lineare Backtracking-,Peakheap-,GC-,SQL-Scheduling- oder harte Laufzeitgarantie. Keine Datenbankabfrage,Datei,Netzwerk oder fremdeRuntime. Kandidaten relational vorfiltern; Regexprädikate sind nicht SARGable.
--
-- ## Nebenwirkungen
--
-- Keine persistente Mutation, keine Transaktion, kein Sessionkontext-/SET-/Tempobjektzugriff. Begrenzter SqlChars-Intake prüft Länge vor Kopie. NULLInput/Pattern/Replacement beendet zuerst. Profil und numerische Argumente,Flags,Input/Replacement,Pattern und Dialekt validieren; die Suche erhält den ganzen Originalinput. Nicht überlappende Suche; nach leerem Match rückt nur der Suchcursor um eine UTF-16-Einheit weiter. Ergebnis/Zeilen vollständig validieren/materialisieren; keine Fachfehler als erfolgreiche Teilresultate behandeln.
--
-- ## Fehlerbehandlung
--
-- CLR-Fachfehler erscheinen in SQL als6522 mit stabilen Innerpräfixen: TBX_REGEX_INVALID_ARGUMENT,TBX_REGEX_INVALID_FLAGS,TBX_REGEX_INVALID_PATTERN,TBX_REGEX_INPUT_TOO_LARGE,TBX_REGEX_PATTERN_TOO_LARGE,TBX_REGEX_TIMEOUT. R2 zusätzlich TBX_REGEX_PATTERN_TOO_COMPLEX,TBX_REGEX_OUTPUT_TOO_LARGE; Replace auch TBX_REGEX_REPLACEMENT_TOO_LARGE. SQL-Binder-,Engine-,Ressourcen- und Konvertierungsfehler bleiben sichtbar. Keine automatische Wiederholung oder abgeschnittene Erfolgsausgabe. Frühe NULL-/Startpfade können weitere Fachvalidierung absichtlich überspringen.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag; keine neue native Unicode-/Grenz-/Minimalrechte-/Installer-/Collationabnahme. Historische Nachweise behalten ihre ursprüngliche Artefaktbindung. Kein allgemeiner .NET-/SQL-Regexdialekt und keine automatische Patternmigration. UTF-16 statt Grapheme, keine Unicode-Normalisierung; Timings sind kooperative Grenzen. Keine Installations-/Rechteattestation, kein Streamingversprechen. Vertrauliche Input-/Ersatztexte nicht öffentlich loggen.
-- OBJECT_USAGE_SKILL:END
AS EXTERNAL NAME [tlblt_String_Regex].[Toolbelt.String.Regex.RegexProvider].[RegexReplaceBounded];
GO

-- ============================================================================
-- Objekt: toolbelt_string.SVF_RegexReplace
-- Typ: T-SQL SVF; Zweck: Regex-Gesamttreffer durch literal Unicode ersetzen.
-- Vertrag: Documentation/SVF_RegexReplace.md; max-Texte, Start=1,
-- Occurrence=0, Flags=c, Profile=standard; Ergebnis: nvarchar(max).
-- Dependencies: interner SAFE-CLR-Kern; Rechte: EXECUTE auf dieser Fassade.
-- Versionen: SQL Server 2019/2022/2025; Plattformen: Windows/Linux.
-- Fehler: SQL 6522 / TBX_REGEX_*; NULL-Short-Circuit, keine Teilresultate.
-- Performance: Materialisierung und zusätzlicher SVF-Aufrufoverhead;
-- keine Inlining-/iTVF-Zusage, kooperatives Gesamtbudget im CLR-Kern.
-- Einschränkungen: UTF-16-Positionen, keine Capture-Ausgabe/Backreferences.
-- ============================================================================
CREATE FUNCTION [toolbelt_string].[SVF_RegexReplace]
(
      @Input nvarchar(max), @Pattern nvarchar(max), @Replacement nvarchar(max)
    , @Start int = 1, @Occurrence int = 0
    , @Flags nvarchar(max) = N'c', @Profile nvarchar(max) = N'standard'
)
RETURNS nvarchar(max)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-string-svf-regexreplace"
-- description: "Ersetzt ausgewählte Gesamttreffer durch literalen Unicode-Text ohne Gruppenexpansion."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.string.regex"
-- schema_name: "toolbelt_string"
-- object_name: "SVF_RegexReplace"
-- object_type: "SVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten in standard,8388608 in large. Keine automatische Kürzung."}, {"name": "@Pattern", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens8000 UTF-16-Einheiten, nach Übersetzung64000; Gruppentiefe64,Alternationen1024. Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus."}, {"name": "@Replacement", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Literaler Ersatztext: $1,${Name},Backslash werden nicht expandiert. Leer löscht den Treffer, NULL ergibt frühNULL. Ersatzlänge wie Profil; fertiger Output bleibt ebenfalls profilbegrenzt."}, {"name": "@Start", "sql_type": "int", "sql_default": "1", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. R2 validiert Profil,Flags,Input/Pattern und gegebenenfalls Replacement auch vor dieser Leerausgabe."}, {"name": "@Occurrence", "sql_type": "int", "sql_default": "0", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "0=alle Treffer abStart,positiv=nur n-ter Treffer;0..2147483647. NULL/negativ und bei Nicht-Replace0 sind ungültig. VorStart bleibt der Input beiReplace erhalten."}, {"name": "@Flags", "sql_type": "nvarchar(max)", "sql_default": "N'c'", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. Als nvarchar(max) gebunden, im begrenzten Intake maximal4 UTF-16-Einheiten."}, {"name": "@Profile", "sql_type": "nvarchar(max)", "sql_default": "N'standard'", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Exakt ordinal standard oder large, ohne Trim/Casefold. standard:1048576 UTF-16-Einheiten pro Input/Ersatz/Output und500ms kooperatives Budget; large:8388608 und2000ms. NULL/leer/andereWerte ungültig. Profilintake maximal8 Einheiten vor Start des gemeinsamen Kontexttimers. Früher Input/Pattern-NULL-Kurzschluss,beiReplace zusätzlichReplacementNULL, hat Vorrang."}]
-- source_paths: ["Modules/toolbelt.string.regex/Source/RegexFunctions.sql", "Modules/toolbelt.string.regex/Clr/RegexBoundedIntake.cs", "Modules/toolbelt.string.regex/Clr/RegexProvider.cs", "Modules/toolbelt.string.regex/Clr/RegexTransformations.cs", "Modules/toolbelt.string.regex/Clr/RegexRelations.cs", "Modules/toolbelt.string.regex/Clr/RegexCaptures.cs"]
-- review_status: "verified"
-- source_module_version: "1.3.0"
-- ---
--
-- # SVF_RegexReplace
--
-- ## Zweck und Einsatzfälle
--
-- Ersetzt ausgewählte Gesamttreffer durch literalen Unicode-Text ohne Gruppenexpansion.
--
-- ## Voraussetzungen
--
-- Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@Input` | `nvarchar(max)` | kein Default | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten in standard,8388608 in large. Keine automatische Kürzung. |
-- | `@Pattern` | `nvarchar(max)` | kein Default | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens8000 UTF-16-Einheiten, nach Übersetzung64000; Gruppentiefe64,Alternationen1024. Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus. |
-- | `@Replacement` | `nvarchar(max)` | kein Default | Input | Literaler Ersatztext: $1,${Name},Backslash werden nicht expandiert. Leer löscht den Treffer, NULL ergibt frühNULL. Ersatzlänge wie Profil; fertiger Output bleibt ebenfalls profilbegrenzt. |
-- | `@Start` | `int` | `1` | Input | Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. R2 validiert Profil,Flags,Input/Pattern und gegebenenfalls Replacement auch vor dieser Leerausgabe. |
-- | `@Occurrence` | `int` | `0` | Input | 0=alle Treffer abStart,positiv=nur n-ter Treffer;0..2147483647. NULL/negativ und bei Nicht-Replace0 sind ungültig. VorStart bleibt der Input beiReplace erhalten. |
-- | `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. Als nvarchar(max) gebunden, im begrenzten Intake maximal4 UTF-16-Einheiten. |
-- | `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Exakt ordinal standard oder large, ohne Trim/Casefold. standard:1048576 UTF-16-Einheiten pro Input/Ersatz/Output und500ms kooperatives Budget; large:8388608 und2000ms. NULL/leer/andereWerte ungültig. Profilintake maximal8 Einheiten vor Start des gemeinsamen Kontexttimers. Früher Input/Pattern-NULL-Kurzschluss,beiReplace zusätzlichReplacementNULL, hat Vorrang. |
--
-- Bei SELECT-/TVF-Aufrufen alle Argumentpositionen angeben; DEFAULT nutzt einen tatsächlich deklarierten SQL-Default. Technischer Default ist kein NULL-Ersatz. NULL-Kurzschluss wirkt erst nach SQL-Typbindung.
--
-- Kein beliebiger .NET-Regex: Literale, Metazeichen-Escapes, \n/\r/\t/\f, Punkt, ^/$, normale Gruppen, Alternation und Zeichenklassen/Bereiche. ASCII: \d=[0-9], \w=[A-Za-z0-9_], \s=[\x09-\x0D\x20]; Unicode-Kategorie ausschließlich \p{L}. Numerische Grenzen in {m}/{m,n}/{m,} höchstens1000; die offene Form {m,} bleibt nach oben offen, ebenso */+. Keine Lookarounds, Pattern-Backreferences, Inlineoptionen, lazy/possessive Quantoren oder allgemeine .NET-Erweiterungen. Leeres Pattern ist gültig. Ohne m bedeutet $ absolutes Inputende; keine abschließende-Newline-Sonderregel. Alle Positionen/Längen zählen UTF-16-Codeeinheiten, nicht Zeichen/Grapheme.
--
-- ## Ergebnisse
--
-- nvarchar(max):gesamter Input mit ausgewählten literalen Ersetzungen; kein ausgewählter Treffer erhält Originalinput. Ein einzelner Skalar, kein zusätzlicher Resultset/OUTPUT-/Hilfeparameter. Input/PatternNULL und beiReplaceReplacementNULL ergebenNULL vor weiterer CLR-Prüfung.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT toolbelt_string.SVF_RegexReplace(N'a1b22',N'\d+',N'$1',1,0,N'c',N'standard') AS LiteralReplacement;
-- -- $1 bleibt hier literal; für Gruppen die getrennte ReplaceGroups-API nutzen.
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf die öffentliche Skalarfunktion. Interne CLR-Kerne benötigen keine direkten Fachcallergrants. Zentraler Dreiteilname braucht bestehenden DB-Zugriff/Identitätsmapping; Ownership-Chains und tatsächliche Objektrechte bleiben maßgeblich. Kein SELECT auf fachliche Tabellen oder Systemkataloge im CLR-Kern; DataAccess/SystemDataAccess=None. Keine pauschale Serverrolle für Anwendung.
--
-- ## Ressourcenbedarf
--
-- standard:1048576/500ms;large:8388608/2000ms. Der gemeinsame Kontext umfasst Flags-/Input-/Pattern-/Ersatzintake nach Profilwahl,Parsing,Konstruktor,Suche undOutput. Höchstens250ms pro Suchschritt; bei geringerem Restbudget Rekonstruktion mit engerem Timeout. Pattern8000/übersetzt64000,Schachtelung64,Alternationen1024. Input,Ersatz undfertigerOutput je profilbegrenzt.  Keine lineare Backtracking-,Peakheap-,GC-,SQL-Scheduling- oder harte Laufzeitgarantie. Keine Datenbankabfrage,Datei,Netzwerk oder fremdeRuntime. Kandidaten relational vorfiltern; Regexprädikate sind nicht SARGable.
--
-- ## Nebenwirkungen
--
-- Keine persistente Mutation, keine Transaktion, kein Sessionkontext-/SET-/Tempobjektzugriff. Öffentliche Fassade gibt Unicodeargumente mit COLLATE DATABASE_DEFAULT an den einen internen Kern weiter; kein SQL-Katalogzugriff und keine Unicode-Normalisierung. Begrenzter SqlChars-Intake prüft Länge vor Kopie. NULLInput/Pattern/Replacement beendet zuerst. Profil und numerische Argumente,Flags,Input/Replacement,Pattern und Dialekt validieren; die Suche erhält den ganzen Originalinput. Nicht überlappende Suche; nach leerem Match rückt nur der Suchcursor um eine UTF-16-Einheit weiter. Ergebnis/Zeilen vollständig validieren/materialisieren; keine Fachfehler als erfolgreiche Teilresultate behandeln.
--
-- ## Fehlerbehandlung
--
-- CLR-Fachfehler erscheinen in SQL als6522 mit stabilen Innerpräfixen: TBX_REGEX_INVALID_ARGUMENT,TBX_REGEX_INVALID_FLAGS,TBX_REGEX_INVALID_PATTERN,TBX_REGEX_INPUT_TOO_LARGE,TBX_REGEX_PATTERN_TOO_LARGE,TBX_REGEX_TIMEOUT. R2 zusätzlich TBX_REGEX_PATTERN_TOO_COMPLEX,TBX_REGEX_OUTPUT_TOO_LARGE; Replace auch TBX_REGEX_REPLACEMENT_TOO_LARGE. SQL-Binder-,Engine-,Ressourcen- und Konvertierungsfehler bleiben sichtbar. Keine automatische Wiederholung oder abgeschnittene Erfolgsausgabe. Frühe NULL-/Startpfade können weitere Fachvalidierung absichtlich überspringen.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag; keine neue native Unicode-/Grenz-/Minimalrechte-/Installer-/Collationabnahme. Historische Nachweise behalten ihre ursprüngliche Artefaktbindung. Kein allgemeiner .NET-/SQL-Regexdialekt und keine automatische Patternmigration. UTF-16 statt Grapheme, keine Unicode-Normalisierung; Timings sind kooperative Grenzen. Keine Installations-/Rechteattestation, kein Streamingversprechen. Vertrauliche Input-/Ersatztexte nicht öffentlich loggen.
-- OBJECT_USAGE_SKILL:END
AS
BEGIN
    -- Nach Unicode-Decoding vereinheitlicht die Fassade Collation-Metadaten,
    -- damit zentrale max-Defaults nicht mit Caller-Collations kollidieren.
    RETURN [toolbelt_string].[SVF_RegexReplaceCore](@Input COLLATE DATABASE_DEFAULT, @Pattern COLLATE DATABASE_DEFAULT, @Replacement COLLATE DATABASE_DEFAULT, @Start, @Occurrence, @Flags COLLATE DATABASE_DEFAULT, @Profile COLLATE DATABASE_DEFAULT);
END;
GO

-- ============================================================================
-- Objekt: toolbelt_string.SVF_RegexSubstringCore (intern)
-- Typ: CLR SVF; Zweck: SAFE-CLR-Kern der öffentlichen Substring-Fassade.
-- Vertrag: Documentation/SVF_RegexSubstring.md; Parameter: max-Texte,
-- Start=1, Occurrence=1, Flags=c, Profile=standard; Resultset: nvarchar(max).
-- Dependencies: SAFE tlblt_String_Regex; keine direkten Fachcallergrants.
-- Versionen: SQL Server 2019/2022/2025; Plattformen: Windows/Linux.
-- Fehlerverhalten: SQL 6522 / TBX_REGEX_*; ohne Treffer NULL, leerer Treffer N''.
-- Performance: vollständige Materialisierung, kooperatives Gesamtbudget.
-- Einschränkungen: UTF-16-Positionen, keine Capture-Ausgabe/Backreferences.
-- ============================================================================
CREATE FUNCTION [toolbelt_string].[SVF_RegexSubstringCore]
(
      @Input nvarchar(max)
    , @Pattern nvarchar(max)
    , @Start int
    , @Occurrence int
    , @Flags nvarchar(max)
    , @Profile nvarchar(max)
)
RETURNS nvarchar(max)
WITH CALLED ON NULL INPUT
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-string-svf-regexsubstringcore"
-- description: "Liefert den n-ten Gesamttreffer als Unicode-Text oder NULL, wenn er fehlt. Interner CLR-Kern."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.string.regex"
-- schema_name: "toolbelt_string"
-- object_name: "SVF_RegexSubstringCore"
-- object_type: "CLR_SVF"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten in standard,8388608 in large. Keine automatische Kürzung."}, {"name": "@Pattern", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens8000 UTF-16-Einheiten, nach Übersetzung64000; Gruppentiefe64,Alternationen1024. Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus."}, {"name": "@Start", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. R2 validiert Profil,Flags,Input/Pattern und gegebenenfalls Replacement auch vor dieser Leerausgabe."}, {"name": "@Occurrence", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Positiver n-ter Treffer abStart,1..2147483647. NULL/negativ und bei Nicht-Replace0 sind ungültig. VorStart bleibt der Input beiReplace erhalten."}, {"name": "@Flags", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. Als nvarchar(max) gebunden, im begrenzten Intake maximal4 UTF-16-Einheiten."}, {"name": "@Profile", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Exakt ordinal standard oder large, ohne Trim/Casefold. standard:1048576 UTF-16-Einheiten pro Input/Ersatz/Output und500ms kooperatives Budget; large:8388608 und2000ms. NULL/leer/andereWerte ungültig. Profilintake maximal8 Einheiten vor Start des gemeinsamen Kontexttimers. Früher Input/Pattern-NULL-Kurzschluss,beiReplace zusätzlichReplacementNULL, hat Vorrang."}]
-- source_paths: ["Modules/toolbelt.string.regex/Source/RegexFunctions.sql", "Modules/toolbelt.string.regex/Clr/RegexBoundedIntake.cs", "Modules/toolbelt.string.regex/Clr/RegexProvider.cs", "Modules/toolbelt.string.regex/Clr/RegexTransformations.cs", "Modules/toolbelt.string.regex/Clr/RegexRelations.cs", "Modules/toolbelt.string.regex/Clr/RegexCaptures.cs"]
-- review_status: "verified"
-- source_module_version: "1.3.0"
-- public_entrypoints: ["toolbelt_string.SVF_RegexSubstring"]
-- ---
--
-- # SVF_RegexSubstringCore
--
-- ## Zweck und Einsatzfälle
--
-- Liefert den n-ten Gesamttreffer als Unicode-Text oder NULL, wenn er fehlt. Interner CLR-Kern. Öffentlichen Einstieg statt direktem Kern verwenden.
--
-- ## Voraussetzungen
--
-- Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@Input` | `nvarchar(max)` | kein Default | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten in standard,8388608 in large. Keine automatische Kürzung. |
-- | `@Pattern` | `nvarchar(max)` | kein Default | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens8000 UTF-16-Einheiten, nach Übersetzung64000; Gruppentiefe64,Alternationen1024. Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus. |
-- | `@Start` | `int` | kein Default | Input | Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. R2 validiert Profil,Flags,Input/Pattern und gegebenenfalls Replacement auch vor dieser Leerausgabe. |
-- | `@Occurrence` | `int` | kein Default | Input | Positiver n-ter Treffer abStart,1..2147483647. NULL/negativ und bei Nicht-Replace0 sind ungültig. VorStart bleibt der Input beiReplace erhalten. |
-- | `@Flags` | `nvarchar(max)` | kein Default | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. Als nvarchar(max) gebunden, im begrenzten Intake maximal4 UTF-16-Einheiten. |
-- | `@Profile` | `nvarchar(max)` | kein Default | Input | Exakt ordinal standard oder large, ohne Trim/Casefold. standard:1048576 UTF-16-Einheiten pro Input/Ersatz/Output und500ms kooperatives Budget; large:8388608 und2000ms. NULL/leer/andereWerte ungültig. Profilintake maximal8 Einheiten vor Start des gemeinsamen Kontexttimers. Früher Input/Pattern-NULL-Kurzschluss,beiReplace zusätzlichReplacementNULL, hat Vorrang. |
--
-- Interner CLR-Kern: alle Argumente explizit, kein technischer Default, keine direkte öffentliche Fachschnittstelle. NULL-Kurzschluss wirkt erst nach SQL-Typbindung.
--
-- Kein beliebiger .NET-Regex: Literale, Metazeichen-Escapes, \n/\r/\t/\f, Punkt, ^/$, normale Gruppen, Alternation und Zeichenklassen/Bereiche. ASCII: \d=[0-9], \w=[A-Za-z0-9_], \s=[\x09-\x0D\x20]; Unicode-Kategorie ausschließlich \p{L}. Numerische Grenzen in {m}/{m,n}/{m,} höchstens1000; die offene Form {m,} bleibt nach oben offen, ebenso */+. Keine Lookarounds, Pattern-Backreferences, Inlineoptionen, lazy/possessive Quantoren oder allgemeine .NET-Erweiterungen. Leeres Pattern ist gültig. Ohne m bedeutet $ absolutes Inputende; keine abschließende-Newline-Sonderregel. Alle Positionen/Längen zählen UTF-16-Codeeinheiten, nicht Zeichen/Grapheme.
--
-- ## Ergebnisse
--
-- nvarchar(max):n-ter Gesamttreffer; fehlendNULL, echter LeertrefferN''. Ein einzelner Skalar, kein zusätzlicher Resultset/OUTPUT-/Hilfeparameter. Input/PatternNULL und beiReplaceReplacementNULL ergebenNULL vor weiterer CLR-Prüfung.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Direkte Fachaufrufe dieses internen Kerns vermeiden.
-- -- Öffentlicher Einstieg:
-- SELECT toolbelt_string.SVF_RegexSubstring(N'a1b22',N'\d+',1,2,N'c',N'standard') AS SecondMatch;
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf die öffentliche Skalarfunktion. Interne CLR-Kerne benötigen keine direkten Fachcallergrants. Zentraler Dreiteilname braucht bestehenden DB-Zugriff/Identitätsmapping; Ownership-Chains und tatsächliche Objektrechte bleiben maßgeblich. Kein SELECT auf fachliche Tabellen oder Systemkataloge im CLR-Kern; DataAccess/SystemDataAccess=None. Keine pauschale Serverrolle für Anwendung.
--
-- ## Ressourcenbedarf
--
-- standard:1048576/500ms;large:8388608/2000ms. Der gemeinsame Kontext umfasst Flags-/Input-/Pattern-/Ersatzintake nach Profilwahl,Parsing,Konstruktor,Suche undOutput. Höchstens250ms pro Suchschritt; bei geringerem Restbudget Rekonstruktion mit engerem Timeout. Pattern8000/übersetzt64000,Schachtelung64,Alternationen1024. Input,Ersatz undfertigerOutput je profilbegrenzt.  Keine lineare Backtracking-,Peakheap-,GC-,SQL-Scheduling- oder harte Laufzeitgarantie. Keine Datenbankabfrage,Datei,Netzwerk oder fremdeRuntime. Kandidaten relational vorfiltern; Regexprädikate sind nicht SARGable.
--
-- ## Nebenwirkungen
--
-- Keine persistente Mutation, keine Transaktion, kein Sessionkontext-/SET-/Tempobjektzugriff. Begrenzter SqlChars-Intake prüft Länge vor Kopie. NULLInput/Pattern beendet zuerst. Profil und numerische Argumente,Flags,Input,Pattern und Dialekt validieren; die Suche erhält den ganzen Originalinput. Nicht überlappende Suche; nach leerem Match rückt nur der Suchcursor um eine UTF-16-Einheit weiter. Ergebnis/Zeilen vollständig validieren/materialisieren; keine Fachfehler als erfolgreiche Teilresultate behandeln.
--
-- ## Fehlerbehandlung
--
-- CLR-Fachfehler erscheinen in SQL als6522 mit stabilen Innerpräfixen: TBX_REGEX_INVALID_ARGUMENT,TBX_REGEX_INVALID_FLAGS,TBX_REGEX_INVALID_PATTERN,TBX_REGEX_INPUT_TOO_LARGE,TBX_REGEX_PATTERN_TOO_LARGE,TBX_REGEX_TIMEOUT. R2 zusätzlich TBX_REGEX_PATTERN_TOO_COMPLEX,TBX_REGEX_OUTPUT_TOO_LARGE; Replace auch TBX_REGEX_REPLACEMENT_TOO_LARGE. SQL-Binder-,Engine-,Ressourcen- und Konvertierungsfehler bleiben sichtbar. Keine automatische Wiederholung oder abgeschnittene Erfolgsausgabe. Frühe NULL-/Startpfade können weitere Fachvalidierung absichtlich überspringen.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag; keine neue native Unicode-/Grenz-/Minimalrechte-/Installer-/Collationabnahme. Historische Nachweise behalten ihre ursprüngliche Artefaktbindung. Kein allgemeiner .NET-/SQL-Regexdialekt und keine automatische Patternmigration. UTF-16 statt Grapheme, keine Unicode-Normalisierung; Timings sind kooperative Grenzen. Keine Installations-/Rechteattestation, kein Streamingversprechen. Vertrauliche Input-/Ersatztexte nicht öffentlich loggen.
-- OBJECT_USAGE_SKILL:END
AS EXTERNAL NAME [tlblt_String_Regex].[Toolbelt.String.Regex.RegexProvider].[RegexSubstringBounded];
GO

-- ============================================================================
-- Objekt: toolbelt_string.SVF_RegexSubstring
-- Typ: T-SQL SVF; Zweck: n-ten Regex-Gesamttreffer als Unicode-Text liefern.
-- Vertrag: Documentation/SVF_RegexSubstring.md; max-Texte, Start=1,
-- Occurrence=1, Flags=c, Profile=standard; Ergebnis: nvarchar(max).
-- Dependencies: interner SAFE-CLR-Kern; Rechte: EXECUTE auf dieser Fassade.
-- Versionen: SQL Server 2019/2022/2025; Plattformen: Windows/Linux.
-- Fehler: SQL 6522 / TBX_REGEX_*; ohne Treffer NULL, leerer Treffer N''.
-- Performance: Materialisierung und zusätzlicher SVF-Aufrufoverhead;
-- keine Inlining-/iTVF-Zusage, kooperatives Gesamtbudget im CLR-Kern.
-- Einschränkungen: UTF-16-Positionen, keine Capture-Ausgabe/Backreferences.
-- ============================================================================
CREATE FUNCTION [toolbelt_string].[SVF_RegexSubstring]
(
      @Input nvarchar(max), @Pattern nvarchar(max)
    , @Start int = 1, @Occurrence int = 1
    , @Flags nvarchar(max) = N'c', @Profile nvarchar(max) = N'standard'
)
RETURNS nvarchar(max)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-string-svf-regexsubstring"
-- description: "Liefert den n-ten Gesamttreffer als Unicode-Text oder NULL, wenn er fehlt."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.string.regex"
-- schema_name: "toolbelt_string"
-- object_name: "SVF_RegexSubstring"
-- object_type: "SVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten in standard,8388608 in large. Keine automatische Kürzung."}, {"name": "@Pattern", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens8000 UTF-16-Einheiten, nach Übersetzung64000; Gruppentiefe64,Alternationen1024. Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus."}, {"name": "@Start", "sql_type": "int", "sql_default": "1", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. R2 validiert Profil,Flags,Input/Pattern und gegebenenfalls Replacement auch vor dieser Leerausgabe."}, {"name": "@Occurrence", "sql_type": "int", "sql_default": "1", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Positiver n-ter Treffer abStart,1..2147483647. NULL/negativ und bei Nicht-Replace0 sind ungültig. VorStart bleibt der Input beiReplace erhalten."}, {"name": "@Flags", "sql_type": "nvarchar(max)", "sql_default": "N'c'", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. Als nvarchar(max) gebunden, im begrenzten Intake maximal4 UTF-16-Einheiten."}, {"name": "@Profile", "sql_type": "nvarchar(max)", "sql_default": "N'standard'", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Exakt ordinal standard oder large, ohne Trim/Casefold. standard:1048576 UTF-16-Einheiten pro Input/Ersatz/Output und500ms kooperatives Budget; large:8388608 und2000ms. NULL/leer/andereWerte ungültig. Profilintake maximal8 Einheiten vor Start des gemeinsamen Kontexttimers. Früher Input/Pattern-NULL-Kurzschluss,beiReplace zusätzlichReplacementNULL, hat Vorrang."}]
-- source_paths: ["Modules/toolbelt.string.regex/Source/RegexFunctions.sql", "Modules/toolbelt.string.regex/Clr/RegexBoundedIntake.cs", "Modules/toolbelt.string.regex/Clr/RegexProvider.cs", "Modules/toolbelt.string.regex/Clr/RegexTransformations.cs", "Modules/toolbelt.string.regex/Clr/RegexRelations.cs", "Modules/toolbelt.string.regex/Clr/RegexCaptures.cs"]
-- review_status: "verified"
-- source_module_version: "1.3.0"
-- ---
--
-- # SVF_RegexSubstring
--
-- ## Zweck und Einsatzfälle
--
-- Liefert den n-ten Gesamttreffer als Unicode-Text oder NULL, wenn er fehlt.
--
-- ## Voraussetzungen
--
-- Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@Input` | `nvarchar(max)` | kein Default | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten in standard,8388608 in large. Keine automatische Kürzung. |
-- | `@Pattern` | `nvarchar(max)` | kein Default | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens8000 UTF-16-Einheiten, nach Übersetzung64000; Gruppentiefe64,Alternationen1024. Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus. |
-- | `@Start` | `int` | `1` | Input | Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. R2 validiert Profil,Flags,Input/Pattern und gegebenenfalls Replacement auch vor dieser Leerausgabe. |
-- | `@Occurrence` | `int` | `1` | Input | Positiver n-ter Treffer abStart,1..2147483647. NULL/negativ und bei Nicht-Replace0 sind ungültig. VorStart bleibt der Input beiReplace erhalten. |
-- | `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. Als nvarchar(max) gebunden, im begrenzten Intake maximal4 UTF-16-Einheiten. |
-- | `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Exakt ordinal standard oder large, ohne Trim/Casefold. standard:1048576 UTF-16-Einheiten pro Input/Ersatz/Output und500ms kooperatives Budget; large:8388608 und2000ms. NULL/leer/andereWerte ungültig. Profilintake maximal8 Einheiten vor Start des gemeinsamen Kontexttimers. Früher Input/Pattern-NULL-Kurzschluss,beiReplace zusätzlichReplacementNULL, hat Vorrang. |
--
-- Bei SELECT-/TVF-Aufrufen alle Argumentpositionen angeben; DEFAULT nutzt einen tatsächlich deklarierten SQL-Default. Technischer Default ist kein NULL-Ersatz. NULL-Kurzschluss wirkt erst nach SQL-Typbindung.
--
-- Kein beliebiger .NET-Regex: Literale, Metazeichen-Escapes, \n/\r/\t/\f, Punkt, ^/$, normale Gruppen, Alternation und Zeichenklassen/Bereiche. ASCII: \d=[0-9], \w=[A-Za-z0-9_], \s=[\x09-\x0D\x20]; Unicode-Kategorie ausschließlich \p{L}. Numerische Grenzen in {m}/{m,n}/{m,} höchstens1000; die offene Form {m,} bleibt nach oben offen, ebenso */+. Keine Lookarounds, Pattern-Backreferences, Inlineoptionen, lazy/possessive Quantoren oder allgemeine .NET-Erweiterungen. Leeres Pattern ist gültig. Ohne m bedeutet $ absolutes Inputende; keine abschließende-Newline-Sonderregel. Alle Positionen/Längen zählen UTF-16-Codeeinheiten, nicht Zeichen/Grapheme.
--
-- ## Ergebnisse
--
-- nvarchar(max):n-ter Gesamttreffer; fehlendNULL, echter LeertrefferN''. Ein einzelner Skalar, kein zusätzlicher Resultset/OUTPUT-/Hilfeparameter. Input/PatternNULL und beiReplaceReplacementNULL ergebenNULL vor weiterer CLR-Prüfung.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT toolbelt_string.SVF_RegexSubstring(N'a1b22',N'\d+',1,2,N'c',N'standard') AS SecondMatch;
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf die öffentliche Skalarfunktion. Interne CLR-Kerne benötigen keine direkten Fachcallergrants. Zentraler Dreiteilname braucht bestehenden DB-Zugriff/Identitätsmapping; Ownership-Chains und tatsächliche Objektrechte bleiben maßgeblich. Kein SELECT auf fachliche Tabellen oder Systemkataloge im CLR-Kern; DataAccess/SystemDataAccess=None. Keine pauschale Serverrolle für Anwendung.
--
-- ## Ressourcenbedarf
--
-- standard:1048576/500ms;large:8388608/2000ms. Der gemeinsame Kontext umfasst Flags-/Input-/Pattern-/Ersatzintake nach Profilwahl,Parsing,Konstruktor,Suche undOutput. Höchstens250ms pro Suchschritt; bei geringerem Restbudget Rekonstruktion mit engerem Timeout. Pattern8000/übersetzt64000,Schachtelung64,Alternationen1024. Input,Ersatz undfertigerOutput je profilbegrenzt.  Keine lineare Backtracking-,Peakheap-,GC-,SQL-Scheduling- oder harte Laufzeitgarantie. Keine Datenbankabfrage,Datei,Netzwerk oder fremdeRuntime. Kandidaten relational vorfiltern; Regexprädikate sind nicht SARGable.
--
-- ## Nebenwirkungen
--
-- Keine persistente Mutation, keine Transaktion, kein Sessionkontext-/SET-/Tempobjektzugriff. Öffentliche Fassade gibt Unicodeargumente mit COLLATE DATABASE_DEFAULT an den einen internen Kern weiter; kein SQL-Katalogzugriff und keine Unicode-Normalisierung. Begrenzter SqlChars-Intake prüft Länge vor Kopie. NULLInput/Pattern beendet zuerst. Profil und numerische Argumente,Flags,Input,Pattern und Dialekt validieren; die Suche erhält den ganzen Originalinput. Nicht überlappende Suche; nach leerem Match rückt nur der Suchcursor um eine UTF-16-Einheit weiter. Ergebnis/Zeilen vollständig validieren/materialisieren; keine Fachfehler als erfolgreiche Teilresultate behandeln.
--
-- ## Fehlerbehandlung
--
-- CLR-Fachfehler erscheinen in SQL als6522 mit stabilen Innerpräfixen: TBX_REGEX_INVALID_ARGUMENT,TBX_REGEX_INVALID_FLAGS,TBX_REGEX_INVALID_PATTERN,TBX_REGEX_INPUT_TOO_LARGE,TBX_REGEX_PATTERN_TOO_LARGE,TBX_REGEX_TIMEOUT. R2 zusätzlich TBX_REGEX_PATTERN_TOO_COMPLEX,TBX_REGEX_OUTPUT_TOO_LARGE; Replace auch TBX_REGEX_REPLACEMENT_TOO_LARGE. SQL-Binder-,Engine-,Ressourcen- und Konvertierungsfehler bleiben sichtbar. Keine automatische Wiederholung oder abgeschnittene Erfolgsausgabe. Frühe NULL-/Startpfade können weitere Fachvalidierung absichtlich überspringen.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag; keine neue native Unicode-/Grenz-/Minimalrechte-/Installer-/Collationabnahme. Historische Nachweise behalten ihre ursprüngliche Artefaktbindung. Kein allgemeiner .NET-/SQL-Regexdialekt und keine automatische Patternmigration. UTF-16 statt Grapheme, keine Unicode-Normalisierung; Timings sind kooperative Grenzen. Keine Installations-/Rechteattestation, kein Streamingversprechen. Vertrauliche Input-/Ersatztexte nicht öffentlich loggen.
-- OBJECT_USAGE_SKILL:END
AS
BEGIN
    RETURN [toolbelt_string].[SVF_RegexSubstringCore](@Input COLLATE DATABASE_DEFAULT, @Pattern COLLATE DATABASE_DEFAULT, @Start, @Occurrence, @Flags COLLATE DATABASE_DEFAULT, @Profile COLLATE DATABASE_DEFAULT);
END;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE FUNCTION [toolbelt_string].[SVF_RegexIsMatch]
(
      @Input   nvarchar(max)
    , @Pattern nvarchar(max)
    , @Flags   nvarchar(4) = N'c'
)
RETURNS bit
WITH CALLED ON NULL INPUT
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-string-svf-regexismatch"
-- description: "Prüft im begrenzten Toolbelt-Regexdialekt, ob mindestens ein Gesamttreffer existiert."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.string.regex"
-- schema_name: "toolbelt_string"
-- object_name: "SVF_RegexIsMatch"
-- object_type: "CLR_SVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten=2097152Bytes."}, {"name": "@Pattern", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens4000 UTF-16-Einheiten=8000Bytes.Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus."}, {"name": "@Flags", "sql_type": "nvarchar(4)", "sql_default": "N'c'", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. SQL bindet nvarchar(4) schon vor dem CLR-Aufruf; eine ursprünglich breitere Clientquelle kann dabei gekürzt werden. Kein Nachweis ihrer ursprünglichen Länge."}]
-- source_paths: ["Modules/toolbelt.string.regex/Source/RegexFunctions.sql", "Modules/toolbelt.string.regex/Clr/RegexBoundedIntake.cs", "Modules/toolbelt.string.regex/Clr/RegexProvider.cs", "Modules/toolbelt.string.regex/Clr/RegexTransformations.cs", "Modules/toolbelt.string.regex/Clr/RegexRelations.cs", "Modules/toolbelt.string.regex/Clr/RegexCaptures.cs"]
-- review_status: "verified"
-- source_module_version: "1.3.0"
-- ---
--
-- # SVF_RegexIsMatch
--
-- ## Zweck und Einsatzfälle
--
-- Prüft im begrenzten Toolbelt-Regexdialekt, ob mindestens ein Gesamttreffer existiert.
--
-- ## Voraussetzungen
--
-- Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@Input` | `nvarchar(max)` | kein Default | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten=2097152Bytes. |
-- | `@Pattern` | `nvarchar(max)` | kein Default | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens4000 UTF-16-Einheiten=8000Bytes.Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus. |
-- | `@Flags` | `nvarchar(4)` | `N'c'` | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. SQL bindet nvarchar(4) schon vor dem CLR-Aufruf; eine ursprünglich breitere Clientquelle kann dabei gekürzt werden. Kein Nachweis ihrer ursprünglichen Länge. |
--
-- Bei SELECT-/TVF-Aufrufen alle Argumentpositionen angeben; DEFAULT nutzt einen tatsächlich deklarierten SQL-Default. Technischer Default ist kein NULL-Ersatz. NULL-Kurzschluss wirkt erst nach SQL-Typbindung.
--
-- Kein beliebiger .NET-Regex: Literale, Metazeichen-Escapes, \n/\r/\t/\f, Punkt, ^/$, normale Gruppen, Alternation und Zeichenklassen/Bereiche. ASCII: \d=[0-9], \w=[A-Za-z0-9_], \s=[\x09-\x0D\x20]; Unicode-Kategorie ausschließlich \p{L}. Numerische Grenzen in {m}/{m,n}/{m,} höchstens1000; die offene Form {m,} bleibt nach oben offen, ebenso */+. Keine Lookarounds, Pattern-Backreferences, Inlineoptionen, lazy/possessive Quantoren oder allgemeine .NET-Erweiterungen. Leeres Pattern ist gültig. Ohne m bedeutet $ absolutes Inputende; keine abschließende-Newline-Sonderregel. Alle Positionen/Längen zählen UTF-16-Codeeinheiten, nicht Zeichen/Grapheme.
--
-- ## Ergebnisse
--
-- bit:1 mindestens ein Treffer,0 kein Treffer,NULL bei Input/PatternNULL. Ein einzelner Skalar, kein zusätzlicher Resultset/OUTPUT-/Hilfeparameter. Input/PatternNULL und beiReplaceReplacementNULL ergebenNULL vor weiterer CLR-Prüfung.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT toolbelt_string.SVF_RegexIsMatch(N'Contoso 42',N'\d+',DEFAULT) AS HasDigits;
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf die öffentliche Skalarfunktion. Interne CLR-Kerne benötigen keine direkten Fachcallergrants. Zentraler Dreiteilname braucht bestehenden DB-Zugriff/Identitätsmapping; Ownership-Chains und tatsächliche Objektrechte bleiben maßgeblich. Kein SELECT auf fachliche Tabellen oder Systemkataloge im CLR-Kern; DataAccess/SystemDataAccess=None. Keine pauschale Serverrolle für Anwendung.
--
-- ## Ressourcenbedarf
--
-- IsMatch hat250ms Engine-Matchtimeout ohne eigenes500ms Gesamtbudget; Intake,Parser/Konstruktor und Allokation sind keine harteWallclock-Garantie. Keine lineare Backtracking-,Peakheap-,GC-,SQL-Scheduling- oder harte Laufzeitgarantie. Keine Datenbankabfrage,Datei,Netzwerk oder fremdeRuntime. Kandidaten relational vorfiltern; Regexprädikate sind nicht SARGable.
--
-- ## Nebenwirkungen
--
-- Keine persistente Mutation, keine Transaktion, kein Sessionkontext-/SET-/Tempobjektzugriff. Begrenzter SqlChars-Intake prüft Länge vor Kopie. NULLInput/Pattern beendet zuerst. Nicht überlappende Suche; nach leerem Match rückt nur der Suchcursor um eine UTF-16-Einheit weiter. Ergebnis/Zeilen vollständig validieren/materialisieren; keine Fachfehler als erfolgreiche Teilresultate behandeln.
--
-- ## Fehlerbehandlung
--
-- CLR-Fachfehler erscheinen in SQL als6522 mit stabilen Innerpräfixen: TBX_REGEX_INVALID_ARGUMENT,TBX_REGEX_INVALID_FLAGS,TBX_REGEX_INVALID_PATTERN,TBX_REGEX_INPUT_TOO_LARGE,TBX_REGEX_PATTERN_TOO_LARGE,TBX_REGEX_TIMEOUT. SQL-Binder-,Engine-,Ressourcen- und Konvertierungsfehler bleiben sichtbar. Keine automatische Wiederholung oder abgeschnittene Erfolgsausgabe. Frühe NULL-/Startpfade können weitere Fachvalidierung absichtlich überspringen.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag; keine neue native Unicode-/Grenz-/Minimalrechte-/Installer-/Collationabnahme. Historische Nachweise behalten ihre ursprüngliche Artefaktbindung. Kein allgemeiner .NET-/SQL-Regexdialekt und keine automatische Patternmigration. UTF-16 statt Grapheme, keine Unicode-Normalisierung; Timings sind kooperative Grenzen. Keine Installations-/Rechteattestation, kein Streamingversprechen. Vertrauliche Input-/Ersatztexte nicht öffentlich loggen.
-- OBJECT_USAGE_SKILL:END
AS EXTERNAL NAME
    [tlblt_String_Regex]
    .[Toolbelt.String.Regex.RegexProvider]
    .[RegexIsMatchBounded];
GO

CREATE FUNCTION [toolbelt_string].[SVF_RegexInstr]
(
      @Input        nvarchar(max)
    , @Pattern      nvarchar(max)
    , @Start        int = 1
    , @Occurrence   int = 1
    , @ReturnOption int = 0
    , @Flags        nvarchar(4) = N'c'
)
RETURNS int
WITH CALLED ON NULL INPUT
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-string-svf-regexinstr"
-- description: "Liefert die absolute UTF-16-Start- oder Endposition des n-ten Gesamttreffers."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.string.regex"
-- schema_name: "toolbelt_string"
-- object_name: "SVF_RegexInstr"
-- object_type: "CLR_SVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten=2097152Bytes."}, {"name": "@Pattern", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens4000 UTF-16-Einheiten=8000Bytes.Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus."}, {"name": "@Start", "sql_type": "int", "sql_default": "1", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. Count/Instr liefern dann0 vor Pattern-/Flagintake."}, {"name": "@Occurrence", "sql_type": "int", "sql_default": "1", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Positiver n-ter Treffer abStart,1..2147483647. NULL/negativ und bei Nicht-Replace0 sind ungültig. VorStart bleibt der Input beiReplace erhalten."}, {"name": "@ReturnOption", "sql_type": "int", "sql_default": "0", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Taxativ0=absolute1-basierte Startposition,1=absolute1-basierte Endposition exklusiv. NULL/andereWerte ungültig. OhneTreffer0."}, {"name": "@Flags", "sql_type": "nvarchar(4)", "sql_default": "N'c'", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. SQL bindet nvarchar(4) schon vor dem CLR-Aufruf; eine ursprünglich breitere Clientquelle kann dabei gekürzt werden. Kein Nachweis ihrer ursprünglichen Länge."}]
-- source_paths: ["Modules/toolbelt.string.regex/Source/RegexFunctions.sql", "Modules/toolbelt.string.regex/Clr/RegexBoundedIntake.cs", "Modules/toolbelt.string.regex/Clr/RegexProvider.cs", "Modules/toolbelt.string.regex/Clr/RegexTransformations.cs", "Modules/toolbelt.string.regex/Clr/RegexRelations.cs", "Modules/toolbelt.string.regex/Clr/RegexCaptures.cs"]
-- review_status: "verified"
-- source_module_version: "1.3.0"
-- ---
--
-- # SVF_RegexInstr
--
-- ## Zweck und Einsatzfälle
--
-- Liefert die absolute UTF-16-Start- oder Endposition des n-ten Gesamttreffers.
--
-- ## Voraussetzungen
--
-- Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@Input` | `nvarchar(max)` | kein Default | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten=2097152Bytes. |
-- | `@Pattern` | `nvarchar(max)` | kein Default | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens4000 UTF-16-Einheiten=8000Bytes.Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus. |
-- | `@Start` | `int` | `1` | Input | Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. Count/Instr liefern dann0 vor Pattern-/Flagintake. |
-- | `@Occurrence` | `int` | `1` | Input | Positiver n-ter Treffer abStart,1..2147483647. NULL/negativ und bei Nicht-Replace0 sind ungültig. VorStart bleibt der Input beiReplace erhalten. |
-- | `@ReturnOption` | `int` | `0` | Input | Taxativ0=absolute1-basierte Startposition,1=absolute1-basierte Endposition exklusiv. NULL/andereWerte ungültig. OhneTreffer0. |
-- | `@Flags` | `nvarchar(4)` | `N'c'` | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. SQL bindet nvarchar(4) schon vor dem CLR-Aufruf; eine ursprünglich breitere Clientquelle kann dabei gekürzt werden. Kein Nachweis ihrer ursprünglichen Länge. |
--
-- Bei SELECT-/TVF-Aufrufen alle Argumentpositionen angeben; DEFAULT nutzt einen tatsächlich deklarierten SQL-Default. Technischer Default ist kein NULL-Ersatz. NULL-Kurzschluss wirkt erst nach SQL-Typbindung.
--
-- Kein beliebiger .NET-Regex: Literale, Metazeichen-Escapes, \n/\r/\t/\f, Punkt, ^/$, normale Gruppen, Alternation und Zeichenklassen/Bereiche. ASCII: \d=[0-9], \w=[A-Za-z0-9_], \s=[\x09-\x0D\x20]; Unicode-Kategorie ausschließlich \p{L}. Numerische Grenzen in {m}/{m,n}/{m,} höchstens1000; die offene Form {m,} bleibt nach oben offen, ebenso */+. Keine Lookarounds, Pattern-Backreferences, Inlineoptionen, lazy/possessive Quantoren oder allgemeine .NET-Erweiterungen. Leeres Pattern ist gültig. Ohne m bedeutet $ absolutes Inputende; keine abschließende-Newline-Sonderregel. Alle Positionen/Längen zählen UTF-16-Codeeinheiten, nicht Zeichen/Grapheme.
--
-- ## Ergebnisse
--
-- int:absolute1-basierte UTF-16-Start-/Endposition oder0 bei fehlendem Treffer,NULL bei Input/PatternNULL. Ein einzelner Skalar, kein zusätzlicher Resultset/OUTPUT-/Hilfeparameter. Input/PatternNULL und beiReplaceReplacementNULL ergebenNULL vor weiterer CLR-Prüfung.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT toolbelt_string.SVF_RegexInstr(N'a1b22',N'\d+',1,2,0,N'c') AS StartPosition;
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf die öffentliche Skalarfunktion. Interne CLR-Kerne benötigen keine direkten Fachcallergrants. Zentraler Dreiteilname braucht bestehenden DB-Zugriff/Identitätsmapping; Ownership-Chains und tatsächliche Objektrechte bleiben maßgeblich. Kein SELECT auf fachliche Tabellen oder Systemkataloge im CLR-Kern; DataAccess/SystemDataAccess=None. Keine pauschale Serverrolle für Anwendung.
--
-- ## Ressourcenbedarf
--
-- Count/Instr:1048576 Inputeinheiten,4000 Patterneinheiten,500ms kooperatives Traversalbudget ab CreateRegex,250ms Suchschritt und maximal100000 erfolgreiche Matchschritte. Begrenzter Intake liegt vor dem Traversaltimer. Keine lineare Backtracking-,Peakheap-,GC-,SQL-Scheduling- oder harte Laufzeitgarantie. Keine Datenbankabfrage,Datei,Netzwerk oder fremdeRuntime. Kandidaten relational vorfiltern; Regexprädikate sind nicht SARGable.
--
-- ## Nebenwirkungen
--
-- Keine persistente Mutation, keine Transaktion, kein Sessionkontext-/SET-/Tempobjektzugriff. Begrenzter SqlChars-Intake prüft Länge vor Kopie. NULLInput/Pattern beendet zuerst. Start/Occurrence/ReturnOption prüfen; bei Start hinter Länge+1 früh0 ohne Pattern-/Flagprüfung. Nicht überlappende Suche; nach leerem Match rückt nur der Suchcursor um eine UTF-16-Einheit weiter. Ergebnis/Zeilen vollständig validieren/materialisieren; keine Fachfehler als erfolgreiche Teilresultate behandeln.
--
-- ## Fehlerbehandlung
--
-- CLR-Fachfehler erscheinen in SQL als6522 mit stabilen Innerpräfixen: TBX_REGEX_INVALID_ARGUMENT,TBX_REGEX_INVALID_FLAGS,TBX_REGEX_INVALID_PATTERN,TBX_REGEX_INPUT_TOO_LARGE,TBX_REGEX_PATTERN_TOO_LARGE,TBX_REGEX_TIMEOUT. Count/Instr zusätzlich TBX_REGEX_MATCH_LIMIT. SQL-Binder-,Engine-,Ressourcen- und Konvertierungsfehler bleiben sichtbar. Keine automatische Wiederholung oder abgeschnittene Erfolgsausgabe. Frühe NULL-/Startpfade können weitere Fachvalidierung absichtlich überspringen.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag; keine neue native Unicode-/Grenz-/Minimalrechte-/Installer-/Collationabnahme. Historische Nachweise behalten ihre ursprüngliche Artefaktbindung. Kein allgemeiner .NET-/SQL-Regexdialekt und keine automatische Patternmigration. UTF-16 statt Grapheme, keine Unicode-Normalisierung; Timings sind kooperative Grenzen. Keine Installations-/Rechteattestation, kein Streamingversprechen. Vertrauliche Input-/Ersatztexte nicht öffentlich loggen.
-- OBJECT_USAGE_SKILL:END
AS EXTERNAL NAME
    [tlblt_String_Regex]
    .[Toolbelt.String.Regex.RegexProvider]
    .[RegexInstrBounded];
GO

CREATE FUNCTION [toolbelt_string].[SVF_RegexCount]
(
      @Input   nvarchar(max)
    , @Pattern nvarchar(max)
    , @Start   int = 1
    , @Flags   nvarchar(4) = N'c'
)
RETURNS int
WITH CALLED ON NULL INPUT
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-string-svf-regexcount"
-- description: "Zählt nicht überlappende Gesamttreffer ab einer UTF-16-Startposition."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.string.regex"
-- schema_name: "toolbelt_string"
-- object_name: "SVF_RegexCount"
-- object_type: "CLR_SVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten=2097152Bytes."}, {"name": "@Pattern", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens4000 UTF-16-Einheiten=8000Bytes.Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus."}, {"name": "@Start", "sql_type": "int", "sql_default": "1", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. Count/Instr liefern dann0 vor Pattern-/Flagintake."}, {"name": "@Flags", "sql_type": "nvarchar(4)", "sql_default": "N'c'", "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. SQL bindet nvarchar(4) schon vor dem CLR-Aufruf; eine ursprünglich breitere Clientquelle kann dabei gekürzt werden. Kein Nachweis ihrer ursprünglichen Länge."}]
-- source_paths: ["Modules/toolbelt.string.regex/Source/RegexFunctions.sql", "Modules/toolbelt.string.regex/Clr/RegexBoundedIntake.cs", "Modules/toolbelt.string.regex/Clr/RegexProvider.cs", "Modules/toolbelt.string.regex/Clr/RegexTransformations.cs", "Modules/toolbelt.string.regex/Clr/RegexRelations.cs", "Modules/toolbelt.string.regex/Clr/RegexCaptures.cs"]
-- review_status: "verified"
-- source_module_version: "1.3.0"
-- ---
--
-- # SVF_RegexCount
--
-- ## Zweck und Einsatzfälle
--
-- Zählt nicht überlappende Gesamttreffer ab einer UTF-16-Startposition.
--
-- ## Voraussetzungen
--
-- Installierte SAFE-Regexassembly tlblt_String_Regex und passende kanonische Objekte1.3.0 derselben Datenbank. SQL2019/2022/2025 Windows/Linux mit CL150/160/170 gemäß Modulmatrix. Vorhandene CLR-/Trustvoraussetzungen gemäß gewähltem Installer; keine eigene Serverkonfiguration oder Rechtevergabe. Alle Inputwerte als Unicode übergeben, varchar beim Caller unter seiner Quellcollation ausdrücklich nach nvarchar(max) konvertieren.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@Input` | `nvarchar(max)` | kein Default | Input | Unicode-Input, leer ist gültig. NULL ergibt NULL beim Skalar beziehungsweise null Zeilen bei TVFs vor sonstiger CLR-Validierung. Höchstens1048576 UTF-16-Einheiten=2097152Bytes. |
-- | `@Pattern` | `nvarchar(max)` | kein Default | Input | Toolbelt-Dialekt gemäß Grammatik unten. Leer gültig; NULL hat denselben frühen Kurzschluss wie Input. Höchstens4000 UTF-16-Einheiten=8000Bytes.Gruppen steuern nur die Patternstruktur; keine benannten Gruppen oder Captureausgabe in diesem Modus. |
-- | `@Start` | `int` | `1` | Input | Ganzzahl1..2147483647, fachlich nichtNULL; 1-basierter Suchbeginn im ganzen Input, Anker behalten den Originalinput. Länge+1 kann terminalen Leertreffer liefern, danach kein Treffer. Count/Instr liefern dann0 vor Pattern-/Flagintake. |
-- | `@Flags` | `nvarchar(4)` | `N'c'` | Input | Taxativ: c=case-sensitiv, i=case-insensitiv/CultureInvariant, m=^/$ zeilenweise, s=Punkt einschließlich Newlines. Leer ist case-sensitiv. Jede Reihenfolge ohne Duplikate ist erlaubt; c und i schließen sich aus. Mengen: leer,c,i,m,s,cm,cs,im,is,ms,cms,ims. NULL, Großbuchstaben, Spaces und andere Zeichen sind ungültig. Keine Datenbank-Collation steuert das Matching; keine Normalisierung. SQL bindet nvarchar(4) schon vor dem CLR-Aufruf; eine ursprünglich breitere Clientquelle kann dabei gekürzt werden. Kein Nachweis ihrer ursprünglichen Länge. |
--
-- Bei SELECT-/TVF-Aufrufen alle Argumentpositionen angeben; DEFAULT nutzt einen tatsächlich deklarierten SQL-Default. Technischer Default ist kein NULL-Ersatz. NULL-Kurzschluss wirkt erst nach SQL-Typbindung.
--
-- Kein beliebiger .NET-Regex: Literale, Metazeichen-Escapes, \n/\r/\t/\f, Punkt, ^/$, normale Gruppen, Alternation und Zeichenklassen/Bereiche. ASCII: \d=[0-9], \w=[A-Za-z0-9_], \s=[\x09-\x0D\x20]; Unicode-Kategorie ausschließlich \p{L}. Numerische Grenzen in {m}/{m,n}/{m,} höchstens1000; die offene Form {m,} bleibt nach oben offen, ebenso */+. Keine Lookarounds, Pattern-Backreferences, Inlineoptionen, lazy/possessive Quantoren oder allgemeine .NET-Erweiterungen. Leeres Pattern ist gültig. Ohne m bedeutet $ absolutes Inputende; keine abschließende-Newline-Sonderregel. Alle Positionen/Längen zählen UTF-16-Codeeinheiten, nicht Zeichen/Grapheme.
--
-- ## Ergebnisse
--
-- int:Anzahl nicht überlappender Treffer abStart,0 ohne Treffer,NULL bei Input/PatternNULL. Ein einzelner Skalar, kein zusätzlicher Resultset/OUTPUT-/Hilfeparameter. Input/PatternNULL und beiReplaceReplacementNULL ergebenNULL vor weiterer CLR-Prüfung.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT toolbelt_string.SVF_RegexCount(N'a1b22',N'\d+',1,N'c') AS MatchCount;
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf die öffentliche Skalarfunktion. Interne CLR-Kerne benötigen keine direkten Fachcallergrants. Zentraler Dreiteilname braucht bestehenden DB-Zugriff/Identitätsmapping; Ownership-Chains und tatsächliche Objektrechte bleiben maßgeblich. Kein SELECT auf fachliche Tabellen oder Systemkataloge im CLR-Kern; DataAccess/SystemDataAccess=None. Keine pauschale Serverrolle für Anwendung.
--
-- ## Ressourcenbedarf
--
-- Count/Instr:1048576 Inputeinheiten,4000 Patterneinheiten,500ms kooperatives Traversalbudget ab CreateRegex,250ms Suchschritt und maximal100000 erfolgreiche Matchschritte. Begrenzter Intake liegt vor dem Traversaltimer. Keine lineare Backtracking-,Peakheap-,GC-,SQL-Scheduling- oder harte Laufzeitgarantie. Keine Datenbankabfrage,Datei,Netzwerk oder fremdeRuntime. Kandidaten relational vorfiltern; Regexprädikate sind nicht SARGable.
--
-- ## Nebenwirkungen
--
-- Keine persistente Mutation, keine Transaktion, kein Sessionkontext-/SET-/Tempobjektzugriff. Begrenzter SqlChars-Intake prüft Länge vor Kopie. NULLInput/Pattern beendet zuerst. Start/Occurrence/ReturnOption prüfen; bei Start hinter Länge+1 früh0 ohne Pattern-/Flagprüfung. Nicht überlappende Suche; nach leerem Match rückt nur der Suchcursor um eine UTF-16-Einheit weiter. Ergebnis/Zeilen vollständig validieren/materialisieren; keine Fachfehler als erfolgreiche Teilresultate behandeln.
--
-- ## Fehlerbehandlung
--
-- CLR-Fachfehler erscheinen in SQL als6522 mit stabilen Innerpräfixen: TBX_REGEX_INVALID_ARGUMENT,TBX_REGEX_INVALID_FLAGS,TBX_REGEX_INVALID_PATTERN,TBX_REGEX_INPUT_TOO_LARGE,TBX_REGEX_PATTERN_TOO_LARGE,TBX_REGEX_TIMEOUT. Count/Instr zusätzlich TBX_REGEX_MATCH_LIMIT. SQL-Binder-,Engine-,Ressourcen- und Konvertierungsfehler bleiben sichtbar. Keine automatische Wiederholung oder abgeschnittene Erfolgsausgabe. Frühe NULL-/Startpfade können weitere Fachvalidierung absichtlich überspringen.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag; keine neue native Unicode-/Grenz-/Minimalrechte-/Installer-/Collationabnahme. Historische Nachweise behalten ihre ursprüngliche Artefaktbindung. Kein allgemeiner .NET-/SQL-Regexdialekt und keine automatische Patternmigration. UTF-16 statt Grapheme, keine Unicode-Normalisierung; Timings sind kooperative Grenzen. Keine Installations-/Rechteattestation, kein Streamingversprechen. Vertrauliche Input-/Ersatztexte nicht öffentlich loggen.
-- OBJECT_USAGE_SKILL:END
AS EXTERNAL NAME
    [tlblt_String_Regex]
    .[Toolbelt.String.Regex.RegexProvider]
    .[RegexCountBounded];
GO
