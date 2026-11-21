-- ============================================================================
-- Objekt:          toolbelt_string.TVF_SplitByCharactersStatus
-- Zweck:           Begrenzter kanonischer Statuskern; Legacy-Wertfassade unten.
-- Parameter:       @Input nvarchar(max), @Separators nvarchar(4000), @KeepEmpty bit = 1
-- Resultset:       Value nvarchar(max), Ordinal bigint, Status varchar(16)
-- Vertrag:         Documentation/TVF_SplitByCharactersStatus.md
-- Versionen:       SQL Server 2019/2022/2025; Windows/Linux
-- Rechte:          SELECT/REFERENCES; keine zusätzlichen Rechte oder Grants.
-- Performance:     MSTVF mit Vorabgrenzen; keine Inline-/Parallelitätszusage.
-- Grenzen:         Freigegebener Vertrag SECURITY_HARDENING_2026_10.md.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_string].[TVF_SplitByCharactersStatus]
(@Input nvarchar(max),@Separators nvarchar(4000),@KeepEmpty bit=1)
RETURNS @Result TABLE(Value nvarchar(max) NULL,Ordinal bigint NULL,Status varchar(16) NOT NULL)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-string-tvf-splitbycharactersstatus"
-- description: "Teilt begrenzten Unicode-Text an einer Menge einzelner UTF-16-Separatoren."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.string.split-characters"
-- schema_name: "toolbelt_string"
-- object_name: "TVF_SplitByCharactersStatus"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Text mit maximal 65536 UTF-16-Bytes; leer ist gültig. NULL in Input oder Separators ergibt SQL_NULL im Statuskern und keine Zeilen in der Wertfassade. Höchstens 10000 Ausgabetokens, keine Teilveröffentlichung bei Überschreitung."}, {"name": "@Separators", "sql_type": "nvarchar(4000)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Menge einzelner UTF-16-Einheiten als nvarchar(4000), z.B. N',;'; keine Separatorstrings/JSON-/Quote-Syntax. Höchstens 64 verschiedene Einheiten, Duplikate zählen einmal, NUL verboten. Leer bedeutet keine Trennung; NULL ergibt SQL_NULL/keine Zeilen."}, {"name": "@KeepEmpty", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt."}]
-- source_paths: ["Modules/toolbelt.string.split-characters/Source/TVF_SplitByCharacters.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # TVF_SplitByCharactersStatus
--
-- ## Zweck und Einsatzfälle
--
-- Teilt begrenzten Unicode-Text an einer Menge einzelner UTF-16-Separatoren. Literal, ohne Quote-/CSV-/Regex-Interpretation. Statusoberfläche für Mengen-/Konfigurations- und NULL-Fälle.
--
-- ## Voraussetzungen
--
-- SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. Modul und Generate-Series-Abhängigkeit installiert. Alle drei Argumentpositionen angeben; DEFAULT oder NULL bei KeepEmpty wirkt wie 1. Keine CLR-, Datei-, Netzwerk- oder Systemkatalogabhängigkeit.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@Input` | `nvarchar(max)` | `kein Default` | Text mit maximal 65536 UTF-16-Bytes; leer ist gültig. NULL in Input oder Separators ergibt SQL_NULL im Statuskern und keine Zeilen in der Wertfassade. Höchstens 10000 Ausgabetokens, keine Teilveröffentlichung bei Überschreitung. |
-- | `@Separators` | `nvarchar(4000)` | `kein Default` | Menge einzelner UTF-16-Einheiten als nvarchar(4000), z.B. N',;'; keine Separatorstrings/JSON-/Quote-Syntax. Höchstens 64 verschiedene Einheiten, Duplikate zählen einmal, NUL verboten. Leer bedeutet keine Trennung; NULL ergibt SQL_NULL/keine Zeilen. |
-- | `@KeepEmpty` | `bit` | `1` | Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt. |
--
-- ## Ergebnisse
--
-- Value nvarchar(max), Ordinal bigint, Status varchar(16). OK liefert vollständige Tokenzeilen mit Ordinal ab 1, lückenlos in Ausgabereihenfolge. SQL_NULL bei NULL in Input/Separators, LIMIT bei Input über 65536 UTF-16-Bytes, mehr als 64 verschiedenen Separator-Codeeinheiten oder mehr als 10000 auszugebenden Tokens; INVALID bei erkanntem NUL-Separator; EMPTY wenn KeepEmpty=0 alle Tokens entfernt. Diese vier Nicht-OK-Fälle liefern genau eine Kontrollzeile mit Value/Ordinal NULL. KeepEmpty=1 erhält Rand-/Zwischenleeren einschließlich einer leeren Zeile für leeren Input; KeepEmpty=0 entfernt sie. Leere Separatormenge trennt nicht. Reihenfolge nur mit ORDER BY Ordinal.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_string.TVF_SplitByCharactersStatus(N'a,,b',N',',DEFAULT)
-- ORDER BY Ordinal;
-- -- Value a / leer / b, Ordinal 1 / 2 / 3, jeweils OK.
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT für SELECT-Aufrufe; REFERENCES bei entsprechender Referenzverwendung. Kein Rechtegrant oder Identitätswechsel. Cross-Database-Zuordnung bleibt Caller-Voraussetzung.
--
-- ## Ressourcenbedarf
--
-- Vorabgrenze 65536 UTF-16-Eingabebytes, Scan von höchstens 4000 Separator-Codeeinheiten und Aufnahme von höchstens 65 verschiedenen Codes als Grenzwächter. Der Inputscan hat höchstens 32769 Iterationen; zunächst bis zu 10000 Spans, erst nach vollständiger Prüfung Ergebnistokens. Bei Überlauf kein bereits ausgegebenes Tokenpräfix. Rückgabe-/Span-Tabellen sind lokale Funktionsvariablen, keine persistenten Objekte.
--
-- ## Nebenwirkungen
--
-- Keine persistenten Daten-, Datei-, Netzwerk-, Trust-, Konfigurations- oder Caller-Transaktionsänderungen. Beschreibungen erteilen keine Ausführungsrechte.
--
-- ## Fehlerbehandlung
--
-- Fachliche Fälle werden wie oben in Statusdaten beziehungsweise null Zeilen übersetzt. Die bis zu 65 aufgenommenen Codes werden erst auf NUL und dann auf Anzahl geprüft; bei mehr als 64 verschiedenen Codes mit zusätzlichem NUL ist kein Vorrang INVALID vor LIMIT zugesagt. Unerwartete Engine-/Bindungs-/Ressourcenfehler bleiben Fehler; kein Retry.
--
-- ## Aussagegrenzen
--
-- BIN2-Codeeinheitenvergleich, keine sprachabhängige Case-/Accent-Äquivalenz und keine Unicode-Scalar-Separatoren. Ein Supplementary-Zeichen als Separator besteht aus zwei getrennten UTF-16-Einheiten und kann Surrogatpaare trennen. Duplikate zählen nur einmal; NUL ist als Separator verboten, im Input nicht allgemein verboten. Kein Tokenizer für mehrstellige Trenner, Quotes oder Escapes. Die Funktion sieht bereits gebundene Parameter; gekürzte ursprüngliche Separatorwerte werden nicht nachträglich erkannt.
-- OBJECT_USAGE_SKILL:END
AS
BEGIN
    IF @Input IS NULL OR @Separators IS NULL
    BEGIN INSERT @Result VALUES(NULL,NULL,'SQL_NULL'); RETURN; END;
    IF DATALENGTH(@Input)>65536
    BEGIN INSERT @Result VALUES(NULL,NULL,'LIMIT'); RETURN; END;
    DECLARE @SeparatorCodes TABLE(Code int NOT NULL PRIMARY KEY);
    DECLARE @Position int=1,@Length int=CONVERT(int,DATALENGTH(@Input)/2),
            @SeparatorLength int=CONVERT(int,DATALENGTH(@Separators)/2),@Code int,
            @Start int=1,@Count int=0;
    -- Höchstens 65 unterschiedliche Codes aufnehmen; der zusätzliche Code
    -- ist nur ein Limitwächter. Die feste 4000er-Separatorlänge begrenzt den Scan.
    INSERT @SeparatorCodes(Code)
    SELECT DISTINCT TOP(65) UNICODE(SUBSTRING(@Separators COLLATE Latin1_General_100_BIN2,positions.Value,1))
    FROM toolbelt_core.TVF_GenerateSeriesBigInt(1,@SeparatorLength,1) positions;
    IF EXISTS(SELECT 1 FROM @SeparatorCodes WHERE Code=0)
    BEGIN INSERT @Result VALUES(NULL,NULL,'INVALID'); RETURN; END;
    IF (SELECT COUNT(*) FROM @SeparatorCodes)>64
    BEGIN INSERT @Result VALUES(NULL,NULL,'LIMIT'); RETURN; END;
    DECLARE @Spans TABLE(Ordinal int NOT NULL PRIMARY KEY,StartPosition int NOT NULL,SpanLength int NOT NULL);
    SET @Position=1;
    WHILE @Position<=@Length+1
    BEGIN
        IF @Position=@Length+1 OR EXISTS(SELECT 1 FROM @SeparatorCodes
            WHERE Code=UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,@Position,1)))
        BEGIN
            IF COALESCE(@KeepEmpty,1)=1 OR @Position>@Start
            BEGIN
                IF @Count>=10000 BEGIN INSERT @Result VALUES(NULL,NULL,'LIMIT'); RETURN; END;
                SET @Count+=1;
                INSERT @Spans VALUES(@Count,@Start,@Position-@Start);
            END;
            SET @Start=@Position+1;
        END;
        SET @Position+=1;
    END;
    IF @Count=0 INSERT @Result VALUES(NULL,NULL,'EMPTY');
    ELSE INSERT @Result SELECT SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,StartPosition,SpanLength),Ordinal,'OK' FROM @Spans;
    RETURN;
END;
GO
-- Legacy-Wertfassade: gleicher Inputvertrag; Limitabbildung siehe Objektseite.
-- Vertrag: Documentation/TVF_SplitByCharacters.md
CREATE OR ALTER FUNCTION [toolbelt_string].[TVF_SplitByCharacters]
(@Input nvarchar(max),@Separators nvarchar(4000),@KeepEmpty bit=1)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-string-tvf-splitbycharacters"
-- description: "Teilt begrenzten Unicode-Text an einer Menge einzelner UTF-16-Separatoren."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.string.split-characters"
-- schema_name: "toolbelt_string"
-- object_name: "TVF_SplitByCharacters"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Text mit maximal 65536 UTF-16-Bytes; leer ist gültig. NULL in Input oder Separators ergibt SQL_NULL im Statuskern und keine Zeilen in der Wertfassade. Höchstens 10000 Ausgabetokens, keine Teilveröffentlichung bei Überschreitung."}, {"name": "@Separators", "sql_type": "nvarchar(4000)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Menge einzelner UTF-16-Einheiten als nvarchar(4000), z.B. N',;'; keine Separatorstrings/JSON-/Quote-Syntax. Höchstens 64 verschiedene Einheiten, Duplikate zählen einmal, NUL verboten. Leer bedeutet keine Trennung; NULL ergibt SQL_NULL/keine Zeilen."}, {"name": "@KeepEmpty", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt."}]
-- source_paths: ["Modules/toolbelt.string.split-characters/Source/TVF_SplitByCharacters.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # TVF_SplitByCharacters
--
-- ## Zweck und Einsatzfälle
--
-- Teilt begrenzten Unicode-Text an einer Menge einzelner UTF-16-Separatoren. Literal, ohne Quote-/CSV-/Regex-Interpretation. Wertfassade filtert ausschließlich erfolgreiche Tokenzeilen des Statuskerns.
--
-- ## Voraussetzungen
--
-- SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. Modul und Generate-Series-Abhängigkeit installiert. Alle drei Argumentpositionen angeben; DEFAULT oder NULL bei KeepEmpty wirkt wie 1. Keine CLR-, Datei-, Netzwerk- oder Systemkatalogabhängigkeit.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@Input` | `nvarchar(max)` | `kein Default` | Text mit maximal 65536 UTF-16-Bytes; leer ist gültig. NULL in Input oder Separators ergibt SQL_NULL im Statuskern und keine Zeilen in der Wertfassade. Höchstens 10000 Ausgabetokens, keine Teilveröffentlichung bei Überschreitung. |
-- | `@Separators` | `nvarchar(4000)` | `kein Default` | Menge einzelner UTF-16-Einheiten als nvarchar(4000), z.B. N',;'; keine Separatorstrings/JSON-/Quote-Syntax. Höchstens 64 verschiedene Einheiten, Duplikate zählen einmal, NUL verboten. Leer bedeutet keine Trennung; NULL ergibt SQL_NULL/keine Zeilen. |
-- | `@KeepEmpty` | `bit` | `1` | Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt. |
--
-- ## Ergebnisse
--
-- Null bis mehrere Zeilen mit Value nvarchar(max) und Ordinal bigint. Nur Status OK wird veröffentlicht, bei LIMIT/INVALID/SQL_NULL/EMPTY keine Zeile. Erfolgreiche Ordinals beginnen bei 1 und sind nach Entfernung leerer Tokens lückenlos. KeepEmpty=1 erhält Rand-/Zwischenleeren einschließlich einer leeren Zeile für leeren Input; KeepEmpty=0 entfernt sie. Leere Separatormenge trennt nicht. Reihenfolge nur mit ORDER BY Ordinal.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_string.TVF_SplitByCharacters(N'a,,b',N',',DEFAULT)
-- ORDER BY Ordinal;
-- -- Value a / leer / b, Ordinal 1 / 2 / 3.
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT für SELECT-Aufrufe; REFERENCES bei entsprechender Referenzverwendung. Kein Rechtegrant oder Identitätswechsel. Cross-Database-Zuordnung bleibt Caller-Voraussetzung.
--
-- ## Ressourcenbedarf
--
-- Vorabgrenze 65536 UTF-16-Eingabebytes, Scan von höchstens 4000 Separator-Codeeinheiten und Aufnahme von höchstens 65 verschiedenen Codes als Grenzwächter. Der Inputscan hat höchstens 32769 Iterationen; zunächst bis zu 10000 Spans, erst nach vollständiger Prüfung Ergebnistokens. Bei Überlauf kein bereits ausgegebenes Tokenpräfix. Rückgabe-/Span-Tabellen sind lokale Funktionsvariablen, keine persistenten Objekte.
--
-- ## Nebenwirkungen
--
-- Keine persistenten Daten-, Datei-, Netzwerk-, Trust-, Konfigurations- oder Caller-Transaktionsänderungen. Beschreibungen erteilen keine Ausführungsrechte.
--
-- ## Fehlerbehandlung
--
-- Fachliche Fälle werden wie oben in Statusdaten beziehungsweise null Zeilen übersetzt. Die bis zu 65 aufgenommenen Codes werden erst auf NUL und dann auf Anzahl geprüft; bei mehr als 64 verschiedenen Codes mit zusätzlichem NUL ist kein Vorrang INVALID vor LIMIT zugesagt. Unerwartete Engine-/Bindungs-/Ressourcenfehler bleiben Fehler; kein Retry.
--
-- ## Aussagegrenzen
--
-- BIN2-Codeeinheitenvergleich, keine sprachabhängige Case-/Accent-Äquivalenz und keine Unicode-Scalar-Separatoren. Ein Supplementary-Zeichen als Separator besteht aus zwei getrennten UTF-16-Einheiten und kann Surrogatpaare trennen. Duplikate zählen nur einmal; NUL ist als Separator verboten, im Input nicht allgemein verboten. Kein Tokenizer für mehrstellige Trenner, Quotes oder Escapes. Die Funktion sieht bereits gebundene Parameter; gekürzte ursprüngliche Separatorwerte werden nicht nachträglich erkannt.
-- OBJECT_USAGE_SKILL:END
RETURNS TABLE AS RETURN
(SELECT Value,Ordinal FROM toolbelt_string.TVF_SplitByCharactersStatus(@Input,@Separators,@KeepEmpty) WHERE Status='OK');
GO
