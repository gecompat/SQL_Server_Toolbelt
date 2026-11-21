-- ============================================================================
-- Objekt:          toolbelt_tsql.TVF_TokenizeScript
-- Typ:             CLR Table-Valued Function
-- Zweck:           Zerlegt T-SQL-Code in einen lückenlosen, verlustfreien Tokenstrom.
-- Vertrag:         Gibt alle Tokens (Identifier, Keywords, Literale, Kommentare, Whitespace) mit Offsets zurück.
-- Parameter:       @SqlText nvarchar(max), @TSqlVersion int, @QuotedIdentifiers bit,
--                  @MaxInputBytes int, @MaxNestingDepth int
-- Resultset:       TokenIndex, TokenType, TokenText, StartOffset, StartLine, StartColumn
-- Dependencies:    Assembly tlblt_Tsql_ScriptParser
-- Rechte:          SELECT auf die Funktion
-- Versionen:       SQL Server 2019, 2022, 2025
-- Plattformen:     Windows
-- Fehlerverhalten: Lexikalische Fehler ergeben null Zeilen; keine AST-Prüfung; Limits werfen TBX_TSQLPARSE_*
-- Performance:     Begrenzte atomare Materialisierung im Speicher
-- Einschränkungen: CLR UNSAFE erforderlich; Windows-only; konservativer Rohtextwächter.
-- NULL/Defaults:   NULL-Text ergibt null Zeilen; Version NULL=160, Bytes NULL=2097152, Tiefe NULL=100.
-- Grenzen:         Versionen 80,90,100,110,120,130,140,150,160,170; Bytes 1..2097152; Tiefe 1..256; kein Versionsfallback.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE FUNCTION [toolbelt_tsql].[TVF_TokenizeScript]
(
      @SqlText            nvarchar(max)
    , @TSqlVersion        int = 160
    , @QuotedIdentifiers  bit = 1
    , @MaxInputBytes      int = 2097152
    , @MaxNestingDepth    int = 100
)
RETURNS TABLE
(
      TokenIndex          int            NULL
    , TokenType           nvarchar(64)   NULL
    , TokenText           nvarchar(max)  NULL
    , StartOffset         int            NULL
    , StartLine           int            NULL
    , StartColumn         int            NULL
)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-tsql-tvf-tokenizescript"
-- description: "Liefert Tokens eines T-SQL-Skripts."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.tsql.script-parser"
-- schema_name: "toolbelt_tsql"
-- object_name: "TVF_TokenizeScript"
-- object_type: "CLR_TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@SqlText", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Vollständiger Unicode-T-SQL-Text, kein Dateipfad oder Connectionstring. Leer ist zulässig. SQLNULL liefert null Zeilen vor jeder anderen CLR-Validierung. Höchstens MaxInputBytes UTF16-Bytes; Länge wird vor ToSqlString-Materialisierung geprüft. Der Text wird nur geparst, niemals ausgeführt."}, {"name": "@TSqlVersion", "sql_type": "int", "sql_default": "160", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ80,90,100,110,120,130,140,150,160,170; SQLDefault160 und explizitNULL ebenfalls160. Wählt ScriptDom-Grammatik, nicht Hostversion oder Datenbank-CL. Kein automatischer Versionsfallback; andere Werte werfen INVALID_VERSION. Früher NULL-Text überspringt diese Prüfung."}, {"name": "@QuotedIdentifiers", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "bit:1 behandelt doppelte Anführungszeichen als Identifier,0 gemäß deaktiviertem QUOTED_IDENTIFIER-Parsermodus. SQLDefault1; explizitNULL ebenfalls1. Kein SET auf der Sitzung; betrifft nur den lokalen Parser."}, {"name": "@MaxInputBytes", "sql_type": "int", "sql_default": "2097152", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "int1..2097152 einschließlich; SQLDefault2097152,explizitNULL ebenfalls2097152. Positive Byteobergrenze für SqlChars.Length*2 vor Stringkopie. 0/negativ/zu groß wirft INVALID_MAX_BYTES. Keine Ausgabe-/Heap-/Zeitquote."}, {"name": "@MaxNestingDepth", "sql_type": "int", "sql_default": "100", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "int1..256 einschließlich; SQLDefault100,explizitNULL ebenfalls100. Grenze der iterativen AST-Tiefe,Root0. Zusätzlich konservativer Vorwächter mit Strukturgrenze min(32,angeforderterTiefe); nicht mit AST-Tiefe gleichsetzen. Tokenize erstellt keinen AST,wendet aber denselben Vorwächter an. Ungültig wirft INVALID_MAX_DEPTH."}]
-- source_paths: ["Modules/toolbelt.tsql.script-parser/Source/TVF_TokenizeScript.sql", "Modules/toolbelt.tsql.script-parser/Clr/ScriptParserProvider.cs", "Modules/toolbelt.tsql.script-parser/Clr/PreparseGuard.cs", "Modules/toolbelt.tsql.script-parser/Clr/PreparseGuardCore.cs", "Modules/toolbelt.tsql.script-parser/module.yaml"]
-- review_status: "verified"
-- source_module_version: "2.0.1"
-- ---
--
-- # TVF_TokenizeScript
--
-- ## Zweck und Einsatzfälle
--
-- Liefert Tokens eines T-SQL-Skripts.
--
-- ## Voraussetzungen
--
-- Windows-only UNSAFE-CLR-Modul2.0.1 gemäß aktuellem Modulvertrag; passende tlblt_Tsql_ScriptParser-Assembly und exakt vom aktuellen Builder gebundene tlblt.Microsoft.SqlServer.TransactSql.ScriptDom-Abhängigkeit. Unterstützte SQL2019/2022/2025-Hosts mit zulässigem CL150/160/170; der Parserdialekt ist separat wählbar. Vorhandene CLR-/Trustvoraussetzungen des gewählten Installers. Es wird kein Zielsystem oder Katalog für den Text benötigt.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@SqlText` | `nvarchar(max)` | kein Default | Input | Vollständiger Unicode-T-SQL-Text, kein Dateipfad oder Connectionstring. Leer ist zulässig. SQLNULL liefert null Zeilen vor jeder anderen CLR-Validierung. Höchstens MaxInputBytes UTF16-Bytes; Länge wird vor ToSqlString-Materialisierung geprüft. Der Text wird nur geparst, niemals ausgeführt. |
-- | `@TSqlVersion` | `int` | `160` | Input | Taxativ80,90,100,110,120,130,140,150,160,170; SQLDefault160 und explizitNULL ebenfalls160. Wählt ScriptDom-Grammatik, nicht Hostversion oder Datenbank-CL. Kein automatischer Versionsfallback; andere Werte werfen INVALID_VERSION. Früher NULL-Text überspringt diese Prüfung. |
-- | `@QuotedIdentifiers` | `bit` | `1` | Input | bit:1 behandelt doppelte Anführungszeichen als Identifier,0 gemäß deaktiviertem QUOTED_IDENTIFIER-Parsermodus. SQLDefault1; explizitNULL ebenfalls1. Kein SET auf der Sitzung; betrifft nur den lokalen Parser. |
-- | `@MaxInputBytes` | `int` | `2097152` | Input | int1..2097152 einschließlich; SQLDefault2097152,explizitNULL ebenfalls2097152. Positive Byteobergrenze für SqlChars.Length*2 vor Stringkopie. 0/negativ/zu groß wirft INVALID_MAX_BYTES. Keine Ausgabe-/Heap-/Zeitquote. |
-- | `@MaxNestingDepth` | `int` | `100` | Input | int1..256 einschließlich; SQLDefault100,explizitNULL ebenfalls100. Grenze der iterativen AST-Tiefe,Root0. Zusätzlich konservativer Vorwächter mit Strukturgrenze min(32,angeforderterTiefe); nicht mit AST-Tiefe gleichsetzen. Tokenize erstellt keinen AST,wendet aber denselben Vorwächter an. Ungültig wirft INVALID_MAX_DEPTH. |
--
-- Beim TVF-Aufruf alle fünf Positionen angeben; DEFAULT nutzt einen tatsächlichen SQL-Default. Ein fehlendes Argument ist nicht dasselbe wie explizitesNULL. Typbindung findet vor dem CLR-Code statt.
--
-- ## Ergebnisse
--
-- | Spalte | SQL-Typ | Vertrag |
-- |---|---|---|
-- | `TokenIndex` | `int` | DDL NULL; 0-basierter Streamindex |
-- | `TokenType` | `nvarchar(64)` | DDL NULL; ScriptDom-Tokenartname |
-- | `TokenText` | `nvarchar(max)` | DDL NULL; Originaltokentext beziehungsweise leer fürNULLText |
-- | `StartOffset` | `int` | DDL NULL; ScriptDom-Quelloffset im Originalinput |
-- | `StartLine` | `int` | DDL NULL; ScriptDom-Quellzeile |
-- | `StartColumn` | `int` | DDL NULL; ScriptDom-Quellspalte |
--
-- 0-basierter TokenIndex in ScriptDom-Reihenfolge,TokenType als Enumname,TokenTextNULL wird zu leerem Text. Enthält auch Whitespace-/Kommentartokens und den EOF-Token,wie von GetTokenStream geliefert. Explizit ORDER BY TokenIndex. Keine AST-Syntaxvalidierung: lexikalisch gültiger,grammatisch falscher Text kann Tokens liefern. Lexikalische Fehler ergeben null Zeilen. Alle DDL-Spalten sind nullable; konkrete FillRow-Pfade setzen die beschriebenen Werte. Kein ResultTable-,OUTPUT- oderHilfeparameter. Vollständig materialisiert,keine verwertbare Fehlerteilmenge.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_tsql.TVF_TokenizeScript(N'SELECT 1 AS ContosoValue;',160,1,2097152,100) ORDER BY TokenIndex;
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT auf die öffentliche TVF und Datenbankzugriff. Zentrale Dreiteilnamen brauchen gültiges Identitätsmapping. DataAccess/SystemDataAccess=None; kein SELECT auf Tabellen,Serverkataloge oder auf die im Text genannten Objekte. Keine SQL-Ausführung,keine neuen Rechte,keine pauschale Serverrolle für Anwendung.
--
-- ## Ressourcenbedarf
--
-- Moduszeilengrenze 8192; zusätzlich vor jedem OutputBudget.Add maximal16777216 gezählteBytes,128Bytes proZeile plus2*Länge aller gezähltenTextfelder. Das ist abstraktes Ausgabeaccounting,kein Peakheap-/Transport-/Wallclocklimit. Feldbreiten fürTyp-/Propertynamen128,PropertyKind32,TokenType64,Message4000 werden separat geprüft. Input höchstens2097152Bytes,vorgezogener Wächter und8192Tokens. ScriptDom-Tokenstream/AST/Reflection/Listen/Stringkopien können davor bereits Speicher beanspruchen. Keine SARGability-/Streaming-/Auswertungszahl-/Laufzeitgarantie. Mehrfacher Aufruf fürNodes undProperties parst jeweils separat.
--
-- ## Nebenwirkungen
--
-- CLR BuildResult materialisiert den gesamten gewählten Resultset vor Rückgabe. InputNULL zuerst nullZeilen. Version,Byte- undTieflimits mit dokumentierten NULL-Fallbacks validieren; SqlChars.Length*2 vor Stringmaterialisierung prüfen. Konservativen PreparseGuard anwenden:512 logische Atome,8192 gezählte rohe Einheiten,Strukturstack höchstensmin(32,MaxNestingDepth),verschachtelteKommentare höchstens16. Quoted Strings/Identifier sind atomar und ihr Inhalt zählt nicht durchgehend zum Rawzähler; das ist keine pauschale8192-Zeichen-Grenze des ganzen Inputs. Rawtextgrenze1048576Codeunits zusätzlich. Dieses öffentliche Profil hat Operator-/Queryoperatorgrenzen0,deaktiviert; keine Übernahme der gesonderten SSIS-Profilwerte. Der Wächter ist kein vollständiger Lexer und kann fachlich gültigen SQL-Text konservativ ablehnen.
--
-- Lokalen TSql80..170Parser mit gewähltem Quote-Modus erstellen. GetTokenStream; Tokenzahl>8192 wirft Outputlimit auch für die übrigen Ausgabemodi. Lexikalische Fehler nur in Errors als Zeilen,sonst leere Ausgabe. Tokenize gibt danach Tokens aus und führt keinen AST-Parse aus. Übrige Modi parsen den Tokenstream; Syntaxfehler nur in Errors,Nodes/Properties liefern keine AST-Teilmenge.
--
-- Bei fehlerfreiem AST iterativer Stackwalk mit reflektierten öffentlichen Properties in ordinaler Namensreihenfolge. Positions-/Tokenstreamproperties,Indexproperties undNULL überspringen; Fragmente/Collections werden Kindknoten,sonstige skalare Werte nur in Properties ausgegeben. RootTiefe0 undNodeId1. Auch Errors kann bei gültigem AST am Walk-Tieflimit scheitern,obwohl keine Fehlerzeile erzeugt wird. Keine Datenbankobjektauflösung oder SQL-Ausführung. Alle gezählten Zeilen/Textfelder vor Rückgabe gegen Modusquoten prüfen; keine erfolgreiche Teilmenge.
--
-- ## Fehlerbehandlung
--
-- SQL6522 mit Innerpräfix TBX_TSQLPARSE_INVALID_VERSION,INVALID_MAX_BYTES,INVALID_MAX_DEPTH,INPUT_TOO_LARGE,PREPARSE_COMPLEXITY_LIMIT,OUTPUT_LIMIT oderMAX_DEPTH_EXCEEDED. ArgumentException beziehungsweiseInvalidOperationException jeBefund; konservativerWächter kannZählertext anhängen. Keine Kürzung beiOutputlimit. ScriptDom-Lexer-/Syntaxfehler sind nurbeiErrors fachlicheZeilen,sonstleereAusgabe. Unerwartete ursprüngliche CLR-/Reflection-/Ressourcen-/Enginefehler bleiben sichtbar; keine automatische Wiederholung. Keine Fehlerfreiheit aus leerenNodes/Properties ableiten.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag; keine neue native Unicode-/Grenz-/Minimalrechte-/Installer-/Crosscollationabnahme. Historische Nachweise behalten ihre Artefaktbindung. Syntax/AST ist keine Bindungs-,Schema-,Berechtigungs-,Semantik- oderAusführbarkeitsprüfung. Kein Rewriter oder allgemeiner T-SQL-Interpreter. Reine SQL-Textanalyse ohne Netzwerk-/Dateizugriff und ohne Datenbankobjektauflösung. Der konservative öffentliche Wächter ist nicht das SSIS-Profil. Keine Installations-/Rechteattestation. Vertrauliche Quelltexte und Parsermeldungen privat halten.
-- OBJECT_USAGE_SKILL:END
AS EXTERNAL NAME
    [tlblt_Tsql_ScriptParser]
    .[Toolbelt.Tsql.ScriptParser.ScriptParserProvider]
    .[TokenizeScript];
GO
