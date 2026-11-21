-- ============================================================================
-- Objekt:          toolbelt_string.USP_SplitAdvanced
-- Typ:             Stored Procedure; Fassade des kanonischen S2-TVF-Kerns
-- Zweck:           Originaltokens als SELECT oder caller-lokale ResultTable liefern
-- Vertrag:         Documentation/USP_SplitAdvanced.md; USP_CONTRACT 1.0
-- Parameter:       Input/SeparatorsJson/Quote/Escape nvarchar(max), KeepEmpty bit
-- Standardparameter: ResultTable sysname, KeepData bit, Debug tinyint, Hilfe bit
-- Resultset:       Value nvarchar(max) NOT NULL, Ordinal bigint NOT NULL
-- Dependencies:    TVF_SplitAdvanced; toolbelt.core.result-table >=1.0.0 same_database
-- Rechte:          EXECUTE; für ResultTable Helper-EXECUTE und Temp-Metadatensicht
-- Versionen:       SQL Server 2019/2022/2025; Compatibility >=150
-- Plattformen:     Windows/Linux; neue Runtime-Evidenz separat nachzuweisen
-- Fehlerverhalten: 51680 Geschäftsfehler, 51681 Dependency; Enginefehler unverändert
-- Transaktion:     eigener Scope oder Savepoint; niemals Callertransaktion committen
-- Performance:     genau ein TVF-Snapshot, Materialisierung; kein Unquoting
-- Einschränkungen: NULL Input keine Zielmutation; doomed Caller benötigt Callerrollback
-- ============================================================================
CREATE OR ALTER PROCEDURE [toolbelt_string].[USP_SplitAdvanced]
(
      @Input nvarchar(max) = NULL
    , @SeparatorsJson nvarchar(max) = NULL
    , @Quote nvarchar(max) = N'"'
    , @Escape nvarchar(max) = N'\'
    , @KeepEmpty bit = 1
    , @ResultTable sysname = NULL
    , @KeepData bit = 0
    , @Debug tinyint = 0
    , @Hilfe bit = 0
)
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-string-usp-splitadvanced"
-- description: "Originaltokens aus kanonischer TVF; Geschäftsfehler vor Zielmutation, kein Unquoting."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.string.split-advanced"
-- schema_name: "toolbelt_string"
-- object_name: "USP_SplitAdvanced"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Text mit maximal 65536 UTF-16-Einheiten, NUL verboten; leer ist gültig. NULL ist ein früher No-op ohne Zeilen, selbst bei ungültiger Konfiguration. Tokens bleiben im Original einschließlich Quotes/Escapes; zum Entfernen TVF_UnquoteToken verwenden."}, {"name": "@SeparatorsJson", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "JSON-Array aus 1..16 verschiedenen nicht leeren Strings, z.B. [\"::\",\",\"]; kein Objekt, keine JSON-null-/Zahlen-/Boolean-Elemente. Je Separator 1..64 UTF-16-Einheiten, Gesamt-JSON höchstens 16384 Einheiten. Binäre Gleichheit einschließlich Spaces; NUL und die aktivierten Quote-/Escape-Zeichen verboten. Längster passender Separator gewinnt. NULL ist außerhalb des frühen Input-NULL-Pfads ungültig. Fachlich nur bei nicht-NULL Input erforderlich; der frühe NULL-No-op prüft diesen Wert nicht."}, {"name": "@Quote", "sql_type": "nvarchar(max)", "sql_default": "N'\"'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Genau eine UTF-16-Einheit (Default Doppelquote) aktiviert Quotegruppen; leer deaktiviert sie. NULL, NUL und Surrogate ungültig. Muss sich vom aktiven Escape unterscheiden und darf in keinem Separator vorkommen; keine automatische mehrzeichige Quote-Syntax. Diese Konfiguration wird bei Input=NULL nicht ausgewertet; sonst ist NULL ungültig. Es werden keine Unicode-Scalars oder Grapheme gescannt."}, {"name": "@Escape", "sql_type": "nvarchar(max)", "sql_default": "N'\\'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Genau eine UTF-16-Einheit (Default Backslash) schützt das nächste Zeichen vor Parserwirkung; leer deaktiviert Escaping. NULL, NUL und Surrogate ungültig. Darf weder aktives Quote noch Bestandteil eines Separators sein. Ein finales Escape ohne Folgezeichen ist ein Parserfehler; Ausgabe bleibt unentschlüsselt. Diese Konfiguration wird bei Input=NULL nicht ausgewertet; sonst ist NULL ungültig. Es werden keine Unicode-Scalars oder Grapheme gescannt."}, {"name": "@KeepEmpty", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1 liefert vor Fachfunktion und Dependency-/Zielprüfung die bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile und kehrt zurück. 0 oder NULL führt den Fachpfad aus. Alle USP-Argumente besitzen technische Defaults."}]
-- source_paths: ["Modules/toolbelt.string.split-advanced/Source/USP_SplitAdvanced.sql", "Modules/toolbelt.string.split-advanced/Source/TVF_SplitAdvanced.sql"]
-- review_status: "verified"
-- source_module_version: "1.1.0"
-- ---
--
-- # USP_SplitAdvanced
--
-- ## Zweck und Einsatzfälle
--
-- Originaltokens aus kanonischer TVF; Geschäftsfehler vor Zielmutation, kein Unquoting. Unveränderte Originaltokens einschließlich Quotes, Escapes und Spaces. Außerhalb Quotes gewinnt am Cursor der längste passende Separator; kein Arrayprioritätsmodus. Quote öffnet/schließt überall im Text, keine Verschachtelung und kein CSV-Qualifiervertrag. Escape schützt überall genau die nächste UTF-16-Codeunit vor Parserwirkung und bleibt selbst im Ergebnis. Vor einem Supplementary-Paar wird nur die erste Codeunit übersprungen. Kein Unquoting; dafür den getrennten öffentlichen Einstieg TVF_UnquoteToken verwenden.
--
-- ## Voraussetzungen
--
-- Reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, unterstützter Compatibility Level mindestens 150. OPENJSON liest ausschließlich übergebenes JSON, keine Quelldaten oder externen Systeme. Lokal/zentral dieselbe Fachquelle. Öffentlicher TVF-Kern in derselben Datenbank installiert; ResultTable-Pfad zusätzlich sameDB USP_PrepareResultTable >=1.0.0 mit exakt den fünf erwarteten SQL-Parametern. Keine Extended Properties oder Runtime-Modulmarkerprüfung. Separatoren müssen ein nichtleeres JSON-Array von Strings sein; NUL und aktive Quote-/Escapezeichen darin verboten. Quote und Escape leer unabhängig deaktiviert, sonst jeweils genau eine unterschiedliche Nicht-Surrogate-Codeunit; NULL ist bei nicht-NULL Input ungültig. Separatorstrings selbst sind keine Unicode-Normalisierungsfunktion.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@Input` | `nvarchar(max)` | `NULL` | Text mit maximal 65536 UTF-16-Einheiten, NUL verboten; leer ist gültig. NULL ist ein früher No-op ohne Zeilen, selbst bei ungültiger Konfiguration. Tokens bleiben im Original einschließlich Quotes/Escapes; zum Entfernen TVF_UnquoteToken verwenden. |
-- | `@SeparatorsJson` | `nvarchar(max)` | `NULL` | JSON-Array aus 1..16 verschiedenen nicht leeren Strings, z.B. ["::",","]; kein Objekt, keine JSON-null-/Zahlen-/Boolean-Elemente. Je Separator 1..64 UTF-16-Einheiten, Gesamt-JSON höchstens 16384 Einheiten. Binäre Gleichheit einschließlich Spaces; NUL und die aktivierten Quote-/Escape-Zeichen verboten. Längster passender Separator gewinnt. NULL ist außerhalb des frühen Input-NULL-Pfads ungültig. Fachlich nur bei nicht-NULL Input erforderlich; der frühe NULL-No-op prüft diesen Wert nicht. |
-- | `@Quote` | `nvarchar(max)` | `N'"'` | Genau eine UTF-16-Einheit (Default Doppelquote) aktiviert Quotegruppen; leer deaktiviert sie. NULL, NUL und Surrogate ungültig. Muss sich vom aktiven Escape unterscheiden und darf in keinem Separator vorkommen; keine automatische mehrzeichige Quote-Syntax. Diese Konfiguration wird bei Input=NULL nicht ausgewertet; sonst ist NULL ungültig. Es werden keine Unicode-Scalars oder Grapheme gescannt. |
-- | `@Escape` | `nvarchar(max)` | `N'\'` | Genau eine UTF-16-Einheit (Default Backslash) schützt das nächste Zeichen vor Parserwirkung; leer deaktiviert Escaping. NULL, NUL und Surrogate ungültig. Darf weder aktives Quote noch Bestandteil eines Separators sein. Ein finales Escape ohne Folgezeichen ist ein Parserfehler; Ausgabe bleibt unentschlüsselt. Diese Konfiguration wird bei Input=NULL nicht ausgewertet; sonst ist NULL ungültig. Es werden keine Unicode-Scalars oder Grapheme gescannt. |
-- | `@KeepEmpty` | `bit` | `1` | Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt. |
-- | `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
-- | `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
-- | `@Debug` | `tinyint` | `0` | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
-- | `@Hilfe` | `bit` | `0` | 1 liefert vor Fachfunktion und Dependency-/Zielprüfung die bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile und kehrt zurück. 0 oder NULL führt den Fachpfad aus. Alle USP-Argumente besitzen technische Defaults. |
--
-- ## Ergebnisse
--
-- Value nvarchar(max) NOT NULL mit BIN2-Collation, Ordinal bigint NOT NULL. Keine öffentlichen Statusspalten. Direkter SELECT nach Ordinal; bei ResultTable keine gespeicherte Reihenfolgegarantie. Input=NULL: bei ResultTable=NULL leeres Erfolgsschema, bei gesetzter ResultTable keine Ausgabe und keinerlei Zielprüfung/-mutation, selbst wenn der Name ungültig ist. Nicht-NULL Input mit null Tokens dagegen durchläuft reguläres Replace-/Append-Routing. Erfolg hat impliziten Prozedurrückgabewert 0 und keine OUTPUT-Parameter. @Hilfe=1 liefert zuerst zwölfspaltige Standardhilfe und zusätzlich genau eine Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max), ohne Fachpfad. Ordinal wird nach Leerfilterung lückenlos ab 1 neu vergeben. Leerer Input liefert bei KeepEmpty=1 oder NULL genau ein leeres Token, bei 0 keine Zeilen. Kein automatisches Entfernen von Steuerzeichen oder Tokenquotes.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_string.USP_SplitAdvanced @Input=N'a;"b;c";d',@SeparatorsJson=N'[";"]';
-- -- Drei Originaltokens: a, Doppelquote b;c Doppelquote, d.
-- EXEC toolbelt_string.USP_SplitAdvanced @Hilfe=1;
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf dieser USP und gültige Abhängigkeitsrechte für TVF; bei ResultTable zusätzlich vorhandenes EXECUTE auf sameDB USP_PrepareResultTable sowie Sicht-/Änderungsrechte auf die eigene caller-lokale #Temp. Helper-Prüfung liest OBJECT_ID und sys.parameters und benötigt ausreichende Metadatensichtbarkeit. Zentraler Dreiteilname allein ersetzt keine gültige Datenbankauthentifizierung, gemappte Identität oder erforderlichen Objektrechte. Kein automatisches Aktivieren von TRUSTWORTHY/Ownership-Chaining und keine Rechteerteilung.
--
-- ## Ressourcenbedarf
--
-- Maximal 65536 Input-, 16384 JSON-Rohtext-Codeunits, 16 Separatoren mit je höchstens 64 Codeunits, einschließlich aller trailing Spaces nach DATALENGTH/2. Begrenzter sequenzieller zustandsbasierter Scan mit mehreren Konfigurations-/NUL-Durchläufen und bis zu 16 Separatorprüfungen pro ungeschützter Position. Tokenpositionen werden zunächst in Tabellenvariablen materialisiert; Originaltext erst nach vollständigem Parse-PASS als Ergebnistokens gesliced. Multi-statement-TVF, keine Behauptung von inline TVF, Streaming, Parallelität, festem Grant/Heap oder Produktionsdurchsatz. USP konsumiert den TVF genau einmal vollständig in einen Statussnapshot, kopiert Erfolgszellen und bei Routing zusätzlich in private #Temp.
--
-- ## Nebenwirkungen
--
-- SET NOCOUNT ON und Normalisierung von KeepData/Debug/Hilfe NULL nach 0; früher Hilfezweig vor Fachfunktion/Debug. Bei Input=NULL keine ResultTable-Mutation; sonst Route über vorhandenen Helper und anschließend parameterfreies, korrekt QUOTENAME-gebundenes Ziel-INSERT. Fachsnapshot vollständig vor Zielmutation. Nur dieser Routingteil startet eine eigene Transaktion oder Caller-Savepoint; eigener Commit/Rollback nur bei eigener Transaktion, Caller-Savepoint nur bei committable Zustand zurückgerollt, niemals gesamte Callertransaktion. Technischer Fehler kann Caller uncommittable lassen; kein gesonderter Rollbackfehler-Schutz. Direkter SELECT kein eigener Transaktionsscope. Debug 1..255: abstrakte Severity-10-NOWAIT-Message und gegebenenfalls Helperdiagnose, keine Tokeninhalte/zusätzlichen Fachresultsets. Keine automatische Installation oder Reparatur von Abhängigkeiten.
--
-- ## Fehlerbehandlung
--
-- TVF-Geschäftsfehler werden vor jedem Output/Zielzugriff als THROW 51680 mit symbolischem Fehlercode und gegebenenfalls Position ohne Inputinhalte gemeldet. Fehlender, unsichtbarer oder signaturabweichender ResultTable-Helper ergibt 51681. Helper-Ziel-/Schema-/Berechtigungsfehler bleiben dessen Originalfehler. Taxative symbolische Kerncodes: INVALID_CONFIGURATION (fehlende Konfiguration, Steuerzeichenfehler/-konflikt, Nichtstring oder leeres Array); INPUT_LIMIT_EXCEEDED (Input >65536); JSON_LIMIT_EXCEEDED (JSON >16384); INVALID_SEPARATOR_JSON (Syntax/Root nicht Array); SEPARATOR_LIMIT_EXCEEDED (>16 Separatoren oder Länge >64); EMPTY_SEPARATOR; DUPLICATE_SEPARATOR (exakte Bytes); NUL_NOT_ALLOWED; DANGLING_ESCAPE; UNTERMINATED_QUOTE. Priorität: Input NULL kurzschließt alles; danach fehlende JSON-/Quote-/Escape-Konfiguration, Inputlimit, JSONlimit, Quote-/Escapelänge; JSONsyntax/Root/Anzahl; pro Separator in Arrayreihenfolge Typ, leer, Länge, NUL, Duplikat; aktive Steuerzeichen NUL/Surrogate/Identität und Separator-Konflikte; vollständiger erster Input-NUL-Befund vor Parserfehlern; dann sequenzieller Scan. Terminaler Escape gewinnt vor einer am EOF offenen Quote. Fehlerposition nur bei Input-NUL, terminalem Escape oder offener Quote, einsbasiert auf ursprüngliche UTF-16-Codeunits; sonst NULL. Unerwartete Enginefehler werden nicht pauschal als Fachstatus maskiert.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag, kein neuer nativer Hilfe-/Installer-/CrossDB-Gesamtnachweis. Historische Nachweise behalten ihre ursprünglichen Bytes und ihren Scope. Kein CSV-Parser, kein Unquoting, keine allgemeine UTF-16-Surrogatvalidierung oder Graphem-/Unicode-Scalar-Semantik. Alle Angaben beschreiben bekannte Implementierung, keine Installations- oder Rechteattestation.
-- OBJECT_USAGE_SKILL:END
BEGIN
    SET NOCOUNT ON;
    SELECT @KeepData=COALESCE(@KeepData,0),@Debug=COALESCE(@Debug,0),@Hilfe=COALESCE(@Hilfe,0);
    IF @Hilfe=1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_string' AS sysname) AS SchemaName,
            CAST(N'USP_SplitAdvanced' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Originaltokens aus kanonischer TVF; Geschäftsfehler vor Zielmutation, kein Unquoting.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'Value', N'nvarchar(max)', 1, 0, NULL, CAST(N'Originaltoken, Latin1_General_100_BIN2.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'Ordinal', N'bigint', 1, 0, NULL, CAST(N'1-basiert, nach Leerfilter lückenlos; Tabellen garantieren keine physische Reihenfolge.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51680', NULL, NULL, NULL, NULL, CAST(N'TVF-Geschäftscode und Originalposition ohne Inputinhalt; keine Teilausgabe.' AS nvarchar(max)), NULL),
        (N'ERROR', 2, N'51681', NULL, NULL, NULL, NULL, CAST(N'Registrierte same-database ResultTable-Dependency >=1.0.0 fehlt oder ist ungeeignet.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'NULL Input: leeres SELECT oder Ziel vollständig unverändert. Enginefehler bleiben Originalfehler; doomed Caller benötigt Callerrollback.' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'EXECUTE auf USP; ResultTable-Pfad benötigt Helper-EXECUTE und Sichtbarkeit der caller-lokalen Temp-Tabelle; keine Rechteausweitung.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Zwei Originaltokens als SELECT.' AS nvarchar(max)), CAST(N'EXEC toolbelt_string.USP_SplitAdvanced @Input=N''a;b'', @SeparatorsJson=N''[";"]'', @Quote=N'''', @Escape=N'''';' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@Input', N'nvarchar(max)', 0, 1, N'NULL', CAST(N'Text mit maximal 65536 UTF-16-Einheiten, NUL verboten; leer ist gültig. NULL ist ein früher No-op ohne Zeilen, selbst bei ungültiger Konfiguration. Tokens bleiben im Original einschließlich Quotes/Escapes; zum Entfernen TVF_UnquoteToken verwenden.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@SeparatorsJson', N'nvarchar(max)', 1, 0, N'NULL', CAST(N'JSON-Array aus 1..16 verschiedenen nicht leeren Strings, z.B. ["::",","]; kein Objekt, keine JSON-null-/Zahlen-/Boolean-Elemente. Je Separator 1..64 UTF-16-Einheiten, Gesamt-JSON höchstens 16384 Einheiten. Binäre Gleichheit einschließlich Spaces; NUL und die aktivierten Quote-/Escape-Zeichen verboten. Längster passender Separator gewinnt. NULL ist außerhalb des frühen Input-NULL-Pfads ungültig. Fachlich nur bei nicht-NULL Input erforderlich; der frühe NULL-No-op prüft diesen Wert nicht.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@Quote', N'nvarchar(max)', 0, 0, N'N''"''', CAST(N'Genau eine UTF-16-Einheit (Default Doppelquote) aktiviert Quotegruppen; leer deaktiviert sie. NULL, NUL und Surrogate ungültig. Muss sich vom aktiven Escape unterscheiden und darf in keinem Separator vorkommen; keine automatische mehrzeichige Quote-Syntax. Diese Konfiguration wird bei Input=NULL nicht ausgewertet; sonst ist NULL ungültig. Es werden keine Unicode-Scalars oder Grapheme gescannt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@Escape', N'nvarchar(max)', 0, 0, N'N''\''', CAST(N'Genau eine UTF-16-Einheit (Default Backslash) schützt das nächste Zeichen vor Parserwirkung; leer deaktiviert Escaping. NULL, NUL und Surrogate ungültig. Darf weder aktives Quote noch Bestandteil eines Separators sein. Ein finales Escape ohne Folgezeichen ist ein Parserfehler; Ausgabe bleibt unentschlüsselt. Diese Konfiguration wird bei Input=NULL nicht ausgewertet; sonst ist NULL ungültig. Es werden keine Unicode-Scalars oder Grapheme gescannt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@KeepEmpty', N'bit', 0, 1, N'1', CAST(N'Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'1 liefert vor Fachfunktion und Dependency-/Zielprüfung die bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile und kehrt zurück. 0 oder NULL führt den Fachpfad aus. Alle USP-Argumente besitzen technische Defaults.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_string' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_SplitAdvanced' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-toolbelt-toolbelt-string-usp-splitadvanced"
description: "Originaltokens aus kanonischer TVF; Geschäftsfehler vor Zielmutation, kein Unquoting."
skill_format_version: "1.0"
module_id: "toolbelt.string.split-advanced"
schema_name: "toolbelt_string"
object_name: "USP_SplitAdvanced"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Text mit maximal 65536 UTF-16-Einheiten, NUL verboten; leer ist gültig. NULL ist ein früher No-op ohne Zeilen, selbst bei ungültiger Konfiguration. Tokens bleiben im Original einschließlich Quotes/Escapes; zum Entfernen TVF_UnquoteToken verwenden."}, {"name": "@SeparatorsJson", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "JSON-Array aus 1..16 verschiedenen nicht leeren Strings, z.B. [\"::\",\",\"]; kein Objekt, keine JSON-null-/Zahlen-/Boolean-Elemente. Je Separator 1..64 UTF-16-Einheiten, Gesamt-JSON höchstens 16384 Einheiten. Binäre Gleichheit einschließlich Spaces; NUL und die aktivierten Quote-/Escape-Zeichen verboten. Längster passender Separator gewinnt. NULL ist außerhalb des frühen Input-NULL-Pfads ungültig. Fachlich nur bei nicht-NULL Input erforderlich; der frühe NULL-No-op prüft diesen Wert nicht."}, {"name": "@Quote", "sql_type": "nvarchar(max)", "sql_default": "N''\"''", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Genau eine UTF-16-Einheit (Default Doppelquote) aktiviert Quotegruppen; leer deaktiviert sie. NULL, NUL und Surrogate ungültig. Muss sich vom aktiven Escape unterscheiden und darf in keinem Separator vorkommen; keine automatische mehrzeichige Quote-Syntax. Diese Konfiguration wird bei Input=NULL nicht ausgewertet; so' AS nvarchar(max)) + N'nst ist NULL ungültig. Es werden keine Unicode-Scalars oder Grapheme gescannt."}, {"name": "@Escape", "sql_type": "nvarchar(max)", "sql_default": "N''\\''", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Genau eine UTF-16-Einheit (Default Backslash) schützt das nächste Zeichen vor Parserwirkung; leer deaktiviert Escaping. NULL, NUL und Surrogate ungültig. Darf weder aktives Quote noch Bestandteil eines Separators sein. Ein finales Escape ohne Folgezeichen ist ein Parserfehler; Ausgabe bleibt unentschlüsselt. Diese Konfiguration wird bei Input=NULL nicht ausgewertet; sonst ist NULL ungültig. Es werden keine Unicode-Scalars oder Grapheme gescannt."}, {"name": "@KeepEmpty", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-' + N'Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1 liefert vor Fachfunktion und Dependency-/Zielprüfung die bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile und kehrt zurück. 0 oder NULL führt den Fachpfad aus. Alle USP-Argumente besitzen technische Defaults."}]
source_paths: ["Modules/toolbelt.string.split-advanced/Source/USP_SplitAdvanced.sql", "Modules/toolbelt.string.split-advanced/Source/TVF_SplitAdvanced.sql"]
review_status: "verified"
source_module_version: "1.1.0"
---

# USP_SplitAdvanced

## Zweck und Einsatzfälle

Originaltokens aus kanonischer TVF; Geschäftsfehler vor Zielmutation, kein Unquoting. Unveränderte Originaltokens einschließlich Quotes, Escapes und Spaces. Außerhalb Quotes gewinnt am Cursor der längste passende Separator; kein Arrayprioritätsmodus. Quote öffnet/schließt überall im Text, keine Verschachtelung und kein CSV-Qualifiervertrag. Escape schützt überall genau die nächste UTF-16-Codeunit vor Parserwirkung und bleibt selbst im Ergebnis. Vor einem Supplementary-Paar wird nur die erste Codeunit übersprungen. Kein Unquoting; dafür den getrennten öffentlichen Einstieg TVF_UnquoteToken verwenden.

## Voraussetzungen

Reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, unterstützter Compatibility Level mindestens 150. OPENJSON liest ausschließlich übergebenes JSON, keine Quelldaten oder externen Systeme. Lokal/zentral dieselbe Fachquelle. Öffentlicher TVF-Kern in derselben Datenbank installiert; ResultTable-Pfad zusätzl' + N'ich sameDB USP_PrepareResultTable >=1.0.0 mit exakt den fünf erwarteten SQL-Parametern. Keine Extended Properties oder Runtime-Modulmarkerprüfung. Separatoren müssen ein nichtleeres JSON-Array von Strings sein; NUL und aktive Quote-/Escapezeichen darin verboten. Quote und Escape leer unabhängig deaktiviert, sonst jeweils genau eine unterschiedliche Nicht-Surrogate-Codeunit; NULL ist bei nicht-NULL Input ungültig. Separatorstrings selbst sind keine Unicode-Normalisierungsfunktion.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@Input` | `nvarchar(max)` | `NULL` | Text mit maximal 65536 UTF-16-Einheiten, NUL verboten; leer ist gültig. NULL ist ein früher No-op ohne Zeilen, selbst bei ungültiger Konfiguration. Tokens bleiben im Original einschließlich Quotes/Escapes; zum Entfernen TVF_UnquoteToken verwenden. |
| `@SeparatorsJson` | `nvarchar(max)` | `NULL` | JSON-Array aus 1..16 verschiedenen nicht leeren Strings, z.B. ["::",","]; kein Objekt, keine JSON-null-/Zahlen-/Boolean-Elemente. Je Separator 1..64 UTF-16-Einheiten, Gesamt-JSON höchstens 16384 Einheiten. Binäre Gleichheit einschließlich Spaces; NUL und die aktivierten Quote-/Escape-Zeichen verboten. Längster passender Separator gewinnt. NULL ist außerhalb des frühen Input-NULL-Pfads ungültig. Fachlich nur bei nicht-NULL Input erforderlich; der frühe NULL-No-op prüft diesen Wert nicht. |
| `@Quote` | `nvarchar(max)` | `N''"''` | Genau eine UTF-16-Einheit (Default Doppelquote) aktiviert Quotegruppen; leer deaktiviert sie. NULL, NUL und Surrogate ungültig. Muss sich vom aktiven Escape unterscheiden und darf in keinem Separator vorkommen; keine automatische mehrzeichige Quote-Syntax. Diese Konfiguration wird bei Input=NULL nicht ausgewertet; sonst ist NULL ungültig. Es werden keine Unicode-Scalars oder Grapheme gescannt. |
| `@Escape` | `nvarchar(max)` | `N''\''` | Genau eine UTF-16-Einheit (Default Backslash) schützt das nächste Zeichen vor Parserwirkung; leer deaktiviert' + N' Escaping. NULL, NUL und Surrogate ungültig. Darf weder aktives Quote noch Bestandteil eines Separators sein. Ein finales Escape ohne Folgezeichen ist ein Parserfehler; Ausgabe bleibt unentschlüsselt. Diese Konfiguration wird bei Input=NULL nicht ausgewertet; sonst ist NULL ungültig. Es werden keine Unicode-Scalars oder Grapheme gescannt. |
| `@KeepEmpty` | `bit` | `1` | Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt. |
| `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | 1 liefert vor Fachfunktion und Dependency-/Zielprüfung die bisherige zwölfspaltige Standardhilfe plus genau eine vollständige vier-spaltige Skillzeile und kehrt zurück. 0 oder NULL führt den Fachpfad aus. Alle USP-Argumente besitzen technische Defaults. |

## Ergebnisse

Value nvarchar(max) NOT NULL mit BIN2-Collation, Ordinal bigint NOT NULL. Keine öffentlichen Statusspalten. Direkter SELECT nach Ordinal; bei ResultTable keine gespeicherte Reihenfolgegarantie. Input=NULL: bei ResultTable=NULL leeres Erfolgsschema, bei gesetzter ResultTable keine Ausgabe u' + N'nd keinerlei Zielprüfung/-mutation, selbst wenn der Name ungültig ist. Nicht-NULL Input mit null Tokens dagegen durchläuft reguläres Replace-/Append-Routing. Erfolg hat impliziten Prozedurrückgabewert 0 und keine OUTPUT-Parameter. @Hilfe=1 liefert zuerst zwölfspaltige Standardhilfe und zusätzlich genau eine Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max), ohne Fachpfad. Ordinal wird nach Leerfilterung lückenlos ab 1 neu vergeben. Leerer Input liefert bei KeepEmpty=1 oder NULL genau ein leeres Token, bei 0 keine Zeilen. Kein automatisches Entfernen von Steuerzeichen oder Tokenquotes.

## Aufrufbeispiele

```sql
EXEC toolbelt_string.USP_SplitAdvanced @Input=N''a;"b;c";d'',@SeparatorsJson=N''[";"]'';
-- Drei Originaltokens: a, Doppelquote b;c Doppelquote, d.
EXEC toolbelt_string.USP_SplitAdvanced @Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf dieser USP und gültige Abhängigkeitsrechte für TVF; bei ResultTable zusätzlich vorhandenes EXECUTE auf sameDB USP_PrepareResultTable sowie Sicht-/Änderungsrechte auf die eigene caller-lokale #Temp. Helper-Prüfung liest OBJECT_ID und sys.parameters und benötigt ausreichende Metadatensichtbarkeit. Zentraler Dreiteilname allein ersetzt keine gültige Datenbankauthentifizierung, gemappte Identität oder erforderlichen Objektrechte. Kein automatisches Aktivieren von TRUSTWORTHY/Ownership-Chaining und keine Rechteerteilung.

## Ressourcenbedarf

Maximal 65536 Input-, 16384 JSON-Rohtext-Codeunits, 16 Separatoren mit je höchstens 64 Codeunits, einschließlich aller trailing Spaces nach DATALENGTH/2. Begrenzter sequenzieller zustandsbasierter Scan mit mehreren Konfigurations-/NUL-Durchläufen und bis zu 16 Separatorprüfungen pro ungeschützter Position. Tokenpositionen werden zunächst in Tabellenvariablen materialisiert; Originaltext erst nach vollständigem Parse-PASS als Ergebnistokens gesliced. Multi-statement-TVF, keine Behauptung von inline TVF, Streaming, Parallelität, festem Grant/H' + N'eap oder Produktionsdurchsatz. USP konsumiert den TVF genau einmal vollständig in einen Statussnapshot, kopiert Erfolgszellen und bei Routing zusätzlich in private #Temp.

## Nebenwirkungen

SET NOCOUNT ON und Normalisierung von KeepData/Debug/Hilfe NULL nach 0; früher Hilfezweig vor Fachfunktion/Debug. Bei Input=NULL keine ResultTable-Mutation; sonst Route über vorhandenen Helper und anschließend parameterfreies, korrekt QUOTENAME-gebundenes Ziel-INSERT. Fachsnapshot vollständig vor Zielmutation. Nur dieser Routingteil startet eine eigene Transaktion oder Caller-Savepoint; eigener Commit/Rollback nur bei eigener Transaktion, Caller-Savepoint nur bei committable Zustand zurückgerollt, niemals gesamte Callertransaktion. Technischer Fehler kann Caller uncommittable lassen; kein gesonderter Rollbackfehler-Schutz. Direkter SELECT kein eigener Transaktionsscope. Debug 1..255: abstrakte Severity-10-NOWAIT-Message und gegebenenfalls Helperdiagnose, keine Tokeninhalte/zusätzlichen Fachresultsets. Keine automatische Installation oder Reparatur von Abhängigkeiten.

## Fehlerbehandlung

TVF-Geschäftsfehler werden vor jedem Output/Zielzugriff als THROW 51680 mit symbolischem Fehlercode und gegebenenfalls Position ohne Inputinhalte gemeldet. Fehlender, unsichtbarer oder signaturabweichender ResultTable-Helper ergibt 51681. Helper-Ziel-/Schema-/Berechtigungsfehler bleiben dessen Originalfehler. Taxative symbolische Kerncodes: INVALID_CONFIGURATION (fehlende Konfiguration, Steuerzeichenfehler/-konflikt, Nichtstring oder leeres Array); INPUT_LIMIT_EXCEEDED (Input >65536); JSON_LIMIT_EXCEEDED (JSON >16384); INVALID_SEPARATOR_JSON (Syntax/Root nicht Array); SEPARATOR_LIMIT_EXCEEDED (>16 Separatoren oder Länge >64); EMPTY_SEPARATOR; DUPLICATE_SEPARATOR (exakte Bytes); NUL_NOT_ALLOWED; DANGLING_ESCAPE; UNTERMINATED_QUOTE. Priorität: Input NULL kurzschließt alles; danach fehlende JSON-/Quote-/Escape-Konfiguration, Inputlimit, JSONlimit, Quote-/Escapelänge; JSONsyntax/Root/Anzahl; pro Se' + N'parator in Arrayreihenfolge Typ, leer, Länge, NUL, Duplikat; aktive Steuerzeichen NUL/Surrogate/Identität und Separator-Konflikte; vollständiger erster Input-NUL-Befund vor Parserfehlern; dann sequenzieller Scan. Terminaler Escape gewinnt vor einer am EOF offenen Quote. Fehlerposition nur bei Input-NUL, terminalem Escape oder offener Quote, einsbasiert auf ursprüngliche UTF-16-Codeunits; sonst NULL. Unerwartete Enginefehler werden nicht pauschal als Fachstatus maskiert.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, kein neuer nativer Hilfe-/Installer-/CrossDB-Gesamtnachweis. Historische Nachweise behalten ihre ursprünglichen Bytes und ihren Scope. Kein CSV-Parser, kein Unquoting, keine allgemeine UTF-16-Surrogatvalidierung oder Graphem-/Unicode-Scalar-Semantik. Alle Angaben beschreiben bekannte Implementierung, keine Installations- oder Rechteattestation.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
    DECLARE @Success TABLE
    (Value nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL, Ordinal bigint NOT NULL);
    -- No-op darf selbst eine ungültige ResultTable/Dependency nicht prüfen.
    IF @Input IS NULL
    BEGIN
        IF @ResultTable IS NULL
            SELECT Value,Ordinal FROM @Success;
        RETURN;
    END;
    DECLARE @Snapshot TABLE
    (
        Value nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL, Ordinal bigint NULL,
        IsValid bit NOT NULL, ErrorCode varchar(64) NULL, ErrorPosition bigint NULL
    );
    INSERT @Snapshot SELECT Value,Ordinal,IsValid,ErrorCode,ErrorPosition
    FROM toolbelt_string.TVF_SplitAdvanced(@Input,@SeparatorsJson,@Quote,@Escape,@KeepEmpty);
    IF EXISTS(SELECT 1 FROM @Snapshot WHERE IsValid=0)
    BEGIN
        DECLARE @Message nvarchar(2048);
        SELECT @Message=N'SplitAdvanced: '+CONVERT(nvarchar(64),ErrorCode)
                       +CASE WHEN ErrorPosition IS NULL THEN N'' ELSE N'; Position '+CONVERT(nvarchar(32),ErrorPosition) END
        FROM @Snapshot WHERE IsValid=0;
        THROW 51680,@Message,1;
    END;
    INSERT @Success(Value,Ordinal) SELECT Value,Ordinal FROM @Snapshot;
    IF @Debug>0 RAISERROR(N'SplitAdvanced: validierter Snapshot bereit.',10,1) WITH NOWAIT;
    IF @ResultTable IS NULL
    BEGIN
        SELECT Value,Ordinal FROM @Success ORDER BY Ordinal;
        RETURN;
    END;

 DECLARE @DependencyId int=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P');
 IF @DependencyId IS NULL
 OR (SELECT COUNT(*) FROM sys.parameters WHERE object_id=@DependencyId)<>5
 OR EXISTS(SELECT 1 FROM (VALUES (1,N'@ResultTableToAlter',231,256),(2,N'@LikeTable',231,1552),
(3,N'@KeepData',104,1),(4,N'@Debug',48,1),(5,N'@Hilfe',104,1)) expected(id,name,typeid,bytes)
     WHERE NOT EXISTS(SELECT 1 FROM sys.parameters p WHERE p.object_id=@DependencyId
       AND p.parameter_id=expected.id AND CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),expected.name)
       AND p.system_type_id=expected.typeid AND p.max_length=expected.bytes AND p.is_output=0))
 THROW 51681,N'ResultTable-Schnittstelle fehlt oder ist abweichend.',1;

    CREATE TABLE #tbx_SplitAdvanced_ResultSource
    (Value nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL, Ordinal bigint NOT NULL);
    INSERT #tbx_SplitAdvanced_ResultSource(Value,Ordinal) SELECT Value,Ordinal FROM @Success;
    DECLARE @OwnTransaction bit=CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END,
            @Savepoint varchar(32)=REPLACE(CONVERT(varchar(36),NEWID()),'-',''),
            @SavepointSet bit=0;
    BEGIN TRY
        IF @OwnTransaction=1 BEGIN TRANSACTION;
        ELSE
        BEGIN
            SAVE TRANSACTION @Savepoint;
            SET @SavepointSet=1;
        END;
        EXEC toolbelt_core.USP_PrepareResultTable
             @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_SplitAdvanced_ResultSource',
             @KeepData=@KeepData,@Debug=@Debug;
        DECLARE @InsertSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)
             +N' ([Value],[Ordinal]) SELECT [Value],[Ordinal] FROM #tbx_SplitAdvanced_ResultSource;';
        EXEC sys.sp_executesql @InsertSql;
        IF @OwnTransaction=1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @OwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        ELSE IF @SavepointSet=1 AND XACT_STATE()=1 ROLLBACK TRANSACTION @Savepoint;
        THROW;
    END CATCH;
END;
GO
