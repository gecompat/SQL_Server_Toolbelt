-- ============================================================================
-- Objekt:          toolbelt_string.TVF_SplitAdvanced
-- Typ:             Multi-statement TVF; kanonischer zustandsbasierter Kern
-- Zweck:           Originaltokens an mehreren Separatorstrings zerlegen
-- Vertrag:         Documentation/TVF_SplitAdvanced.md; S2-Freigabe 2026-10-01
-- Parameter:       Input/SeparatorsJson/Quote/Escape nvarchar(max), KeepEmpty bit
-- Defaults:        Quote=N'"', Escape=N'\', KeepEmpty=1
-- Resultset:       Value, Ordinal, IsValid, ErrorCode, ErrorPosition
-- Dependencies:    keine; OPENJSON erfordert Compatibility Level >=150 im Scope
-- Rechte:          SELECT auf der TVF
-- Versionen:       SQL Server 2019/2022/2025, Windows und Linux
-- Fehlerverhalten: eine Geschäftsfehlerzeile, keine Teiltokens; Enginefehler bleiben
-- Performance:     begrenzter sequenzieller Scan; materialisierte Tabellenvariablen
-- Einschränkungen: UTF-16-Codeeinheiten, kein CSV/Unquoting/Parallelitätsversprechen
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_string].[TVF_SplitAdvanced]
(
      @Input nvarchar(max)
    , @SeparatorsJson nvarchar(max)
    , @Quote nvarchar(max) = N'"'
    , @Escape nvarchar(max) = N'\'
    , @KeepEmpty bit = 1
)
RETURNS @Result TABLE
(
      Value nvarchar(max) NULL
    , Ordinal bigint NULL
    , IsValid bit NOT NULL
    , ErrorCode varchar(64) NULL
    , ErrorPosition bigint NULL
)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-string-tvf-splitadvanced"
-- description: "Zerlegt Originaltokens mit mehreren Separatoren, Quotes und Escape-Regeln; entquotiert sie nicht."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.string.split-advanced"
-- schema_name: "toolbelt_string"
-- object_name: "TVF_SplitAdvanced"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Text mit maximal 65536 UTF-16-Einheiten, NUL verboten; leer ist gültig. NULL ist ein früher No-op ohne Zeilen, selbst bei ungültiger Konfiguration. Tokens bleiben im Original einschließlich Quotes/Escapes; zum Entfernen TVF_UnquoteToken verwenden. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments."}, {"name": "@SeparatorsJson", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "JSON-Array aus 1..16 verschiedenen nicht leeren Strings, z.B. [\"::\",\",\"]; kein Objekt, keine JSON-null-/Zahlen-/Boolean-Elemente. Je Separator 1..64 UTF-16-Einheiten, Gesamt-JSON höchstens 16384 Einheiten. Binäre Gleichheit einschließlich Spaces; NUL und die aktivierten Quote-/Escape-Zeichen verboten. Längster passender Separator gewinnt. NULL ist außerhalb des frühen Input-NULL-Pfads ungültig. Fachlich nur bei nicht-NULL Input erforderlich; der frühe NULL-No-op prüft diesen Wert nicht. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments."}, {"name": "@Quote", "sql_type": "nvarchar(max)", "sql_default": "N'\"'", "is_output": false, "argument_required": true, "business_required": false, "nullable": false, "description": "Genau eine UTF-16-Einheit (Default Doppelquote) aktiviert Quotegruppen; leer deaktiviert sie. NULL, NUL und Surrogate ungültig. Muss sich vom aktiven Escape unterscheiden und darf in keinem Separator vorkommen; keine automatische mehrzeichige Quote-Syntax. Diese Konfiguration wird bei Input=NULL nicht ausgewertet; sonst ist NULL ungültig. Es werden keine Unicode-Scalars oder Grapheme gescannt. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments."}, {"name": "@Escape", "sql_type": "nvarchar(max)", "sql_default": "N'\\'", "is_output": false, "argument_required": true, "business_required": false, "nullable": false, "description": "Genau eine UTF-16-Einheit (Default Backslash) schützt das nächste Zeichen vor Parserwirkung; leer deaktiviert Escaping. NULL, NUL und Surrogate ungültig. Darf weder aktives Quote noch Bestandteil eines Separators sein. Ein finales Escape ohne Folgezeichen ist ein Parserfehler; Ausgabe bleibt unentschlüsselt. Diese Konfiguration wird bei Input=NULL nicht ausgewertet; sonst ist NULL ungültig. Es werden keine Unicode-Scalars oder Grapheme gescannt. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments."}, {"name": "@KeepEmpty", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments."}]
-- source_paths: ["Modules/toolbelt.string.split-advanced/Source/TVF_SplitAdvanced.sql"]
-- review_status: "verified"
-- source_module_version: "1.1.0"
-- ---
--
-- # TVF_SplitAdvanced
--
-- ## Zweck und Einsatzfälle
--
-- Zerlegt Originaltokens mit mehreren Separatoren, Quotes und Escape-Regeln; entquotiert sie nicht. Unveränderte Originaltokens einschließlich Quotes, Escapes und Spaces. Außerhalb Quotes gewinnt am Cursor der längste passende Separator; kein Arrayprioritätsmodus. Quote öffnet/schließt überall im Text, keine Verschachtelung und kein CSV-Qualifiervertrag. Escape schützt überall genau die nächste UTF-16-Codeunit vor Parserwirkung und bleibt selbst im Ergebnis. Vor einem Supplementary-Paar wird nur die erste Codeunit übersprungen. Kein Unquoting; dafür den getrennten öffentlichen Einstieg TVF_UnquoteToken verwenden.
--
-- ## Voraussetzungen
--
-- Reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, unterstützter Compatibility Level mindestens 150. OPENJSON liest ausschließlich übergebenes JSON, keine Quelldaten oder externen Systeme. Lokal/zentral dieselbe Fachquelle. Separatoren müssen ein nichtleeres JSON-Array von Strings sein; NUL und aktive Quote-/Escapezeichen darin verboten. Quote und Escape leer unabhängig deaktiviert, sonst jeweils genau eine unterschiedliche Nicht-Surrogate-Codeunit; NULL ist bei nicht-NULL Input ungültig. Separatorstrings selbst sind keine Unicode-Normalisierungsfunktion.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@Input` | `nvarchar(max)` | `None` | Text mit maximal 65536 UTF-16-Einheiten, NUL verboten; leer ist gültig. NULL ist ein früher No-op ohne Zeilen, selbst bei ungültiger Konfiguration. Tokens bleiben im Original einschließlich Quotes/Escapes; zum Entfernen TVF_UnquoteToken verwenden. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments. |
-- | `@SeparatorsJson` | `nvarchar(max)` | `None` | JSON-Array aus 1..16 verschiedenen nicht leeren Strings, z.B. ["::",","]; kein Objekt, keine JSON-null-/Zahlen-/Boolean-Elemente. Je Separator 1..64 UTF-16-Einheiten, Gesamt-JSON höchstens 16384 Einheiten. Binäre Gleichheit einschließlich Spaces; NUL und die aktivierten Quote-/Escape-Zeichen verboten. Längster passender Separator gewinnt. NULL ist außerhalb des frühen Input-NULL-Pfads ungültig. Fachlich nur bei nicht-NULL Input erforderlich; der frühe NULL-No-op prüft diesen Wert nicht. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments. |
-- | `@Quote` | `nvarchar(max)` | `N'"'` | Genau eine UTF-16-Einheit (Default Doppelquote) aktiviert Quotegruppen; leer deaktiviert sie. NULL, NUL und Surrogate ungültig. Muss sich vom aktiven Escape unterscheiden und darf in keinem Separator vorkommen; keine automatische mehrzeichige Quote-Syntax. Diese Konfiguration wird bei Input=NULL nicht ausgewertet; sonst ist NULL ungültig. Es werden keine Unicode-Scalars oder Grapheme gescannt. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments. |
-- | `@Escape` | `nvarchar(max)` | `N'\'` | Genau eine UTF-16-Einheit (Default Backslash) schützt das nächste Zeichen vor Parserwirkung; leer deaktiviert Escaping. NULL, NUL und Surrogate ungültig. Darf weder aktives Quote noch Bestandteil eines Separators sein. Ein finales Escape ohne Folgezeichen ist ein Parserfehler; Ausgabe bleibt unentschlüsselt. Diese Konfiguration wird bei Input=NULL nicht ausgewertet; sonst ist NULL ungültig. Es werden keine Unicode-Scalars oder Grapheme gescannt. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments. |
-- | `@KeepEmpty` | `bit` | `1` | Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt. Argumentposition muss angegeben werden; bei vorhandenem SQL-Default ist DEFAULT zulässig, kein Weglassen des Arguments. |
--
-- ## Ergebnisse
--
-- Value nvarchar(max) NULL, Ordinal bigint NULL, IsValid bit NOT NULL, ErrorCode varchar(64) NULL, ErrorPosition bigint NULL. Erfolg: IsValid=1, nicht-NULL Value/Ordinal, Fehlerfelder NULL. Geschäftsfehler: genau eine Zeile mit Value/Ordinal NULL, IsValid=0 und symbolischem Code; keine Teiltokens. Die Rückgabetabelle garantiert keine Zeilenreihenfolge, deshalb ORDER BY Ordinal. Scannvergleiche sind BIN2, der Value-Rückgabespaltentyp deklariert keine eigene BIN2-Collation. Input=NULL: null Zeilen auch bei ungültiger Konfiguration. Ordinal wird nach Leerfilterung lückenlos ab 1 neu vergeben. Leerer Input liefert bei KeepEmpty=1 oder NULL genau ein leeres Token, bei 0 keine Zeilen. Kein automatisches Entfernen von Steuerzeichen oder Tokenquotes.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT Value,Ordinal,IsValid,ErrorCode,ErrorPosition
-- FROM toolbelt_string.TVF_SplitAdvanced(N'a;"b;c";d',N'[";"]',DEFAULT,DEFAULT,DEFAULT)
-- ORDER BY Ordinal;
-- -- Drei Originaltokens; IsValid=1, Fehlerfelder NULL.
-- SELECT * FROM toolbelt_string.TVF_SplitAdvanced(NULL,NULL,NULL,NULL,NULL);
-- -- Keine Zeilen, wegen frühem NULL-No-op.
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT auf dieser TVF genügt im passenden Installationskontext. Kein Dateizugriff, Serverstatusrecht oder VIEW ANY DEFINITION erforderlich. Zentraler Dreiteilname allein ersetzt keine gültige Datenbankauthentifizierung, gemappte Identität oder erforderlichen Objektrechte. Kein automatisches Aktivieren von TRUSTWORTHY/Ownership-Chaining und keine Rechteerteilung.
--
-- ## Ressourcenbedarf
--
-- Maximal 65536 Input-, 16384 JSON-Rohtext-Codeunits, 16 Separatoren mit je höchstens 64 Codeunits, einschließlich aller trailing Spaces nach DATALENGTH/2. Begrenzter sequenzieller zustandsbasierter Scan mit mehreren Konfigurations-/NUL-Durchläufen und bis zu 16 Separatorprüfungen pro ungeschützter Position. Tokenpositionen werden zunächst in Tabellenvariablen materialisiert; Originaltext erst nach vollständigem Parse-PASS als Ergebnistokens gesliced. Multi-statement-TVF, keine Behauptung von inline TVF, Streaming, Parallelität, festem Grant/Heap oder Produktionsdurchsatz.
--
-- ## Nebenwirkungen
--
-- Keine persistenten oder caller-sichtbaren Änderungen, Transaktionen, Datei-/Netzwerk-/Katalogabfragen. Nur eigene Tabellenvariablen; NULL-No-op ist vor Konfigurationsprüfung. Keine automatische Installation oder Reparatur von Abhängigkeiten.
--
-- ## Fehlerbehandlung
--
-- Fachfehler liefern eine Statuszeile, keine SQL-Exception. Nicht allein WHERE IsValid=1 verwenden, sonst werden Fehler still verworfen; bei APPLY Status je Input prüfen. Taxative symbolische Kerncodes: INVALID_CONFIGURATION (fehlende Konfiguration, Steuerzeichenfehler/-konflikt, Nichtstring oder leeres Array); INPUT_LIMIT_EXCEEDED (Input >65536); JSON_LIMIT_EXCEEDED (JSON >16384); INVALID_SEPARATOR_JSON (Syntax/Root nicht Array); SEPARATOR_LIMIT_EXCEEDED (>16 Separatoren oder Länge >64); EMPTY_SEPARATOR; DUPLICATE_SEPARATOR (exakte Bytes); NUL_NOT_ALLOWED; DANGLING_ESCAPE; UNTERMINATED_QUOTE. Priorität: Input NULL kurzschließt alles; danach fehlende JSON-/Quote-/Escape-Konfiguration, Inputlimit, JSONlimit, Quote-/Escapelänge; JSONsyntax/Root/Anzahl; pro Separator in Arrayreihenfolge Typ, leer, Länge, NUL, Duplikat; aktive Steuerzeichen NUL/Surrogate/Identität und Separator-Konflikte; vollständiger erster Input-NUL-Befund vor Parserfehlern; dann sequenzieller Scan. Terminaler Escape gewinnt vor einer am EOF offenen Quote. Fehlerposition nur bei Input-NUL, terminalem Escape oder offener Quote, einsbasiert auf ursprüngliche UTF-16-Codeunits; sonst NULL. Unerwartete Enginefehler werden nicht pauschal als Fachstatus maskiert.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag, kein neuer nativer Hilfe-/Installer-/CrossDB-Gesamtnachweis. Historische Nachweise behalten ihre ursprünglichen Bytes und ihren Scope. Kein CSV-Parser, kein Unquoting, keine allgemeine UTF-16-Surrogatvalidierung oder Graphem-/Unicode-Scalar-Semantik. Alle Angaben beschreiben bekannte Implementierung, keine Installations- oder Rechteattestation.
-- OBJECT_USAGE_SKILL:END
AS
BEGIN
    -- NULL ist ein früher No-op, selbst bei ungültiger Konfiguration.
    IF @Input IS NULL RETURN;

    DECLARE @InputLength bigint = DATALENGTH(@Input) / 2,
            @JsonLength bigint = DATALENGTH(@SeparatorsJson) / 2,
            @QuoteLength bigint = DATALENGTH(@Quote) / 2,
            @EscapeLength bigint = DATALENGTH(@Escape) / 2,
            @Error varchar(64) = NULL, @ErrorPosition bigint = NULL,
            @Position bigint = 1, @Character int, @SeparatorOrdinal int,
            @SeparatorCount int, @Separator nvarchar(max), @SeparatorLength bigint,
            @JsonType int, @QuoteCode int = UNICODE(@Quote COLLATE Latin1_General_100_BIN2),
            @EscapeCode int = UNICODE(@Escape COLLATE Latin1_General_100_BIN2);

    IF @SeparatorsJson IS NULL OR @Quote IS NULL OR @Escape IS NULL
        SET @Error = 'INVALID_CONFIGURATION';
    ELSE IF @InputLength > 65536 SET @Error = 'INPUT_LIMIT_EXCEEDED';
    ELSE IF @JsonLength > 16384 SET @Error = 'JSON_LIMIT_EXCEEDED';
    ELSE IF @QuoteLength > 1 OR @EscapeLength > 1 SET @Error = 'INVALID_CONFIGURATION';

    DECLARE @Separators TABLE
    (
        SeparatorOrdinal int NOT NULL PRIMARY KEY,
        Separator nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
        SeparatorLength bigint NULL,
        JsonType int NOT NULL
    );

    IF @Error IS NULL
    BEGIN
        -- Syntax zuerst prüfen: OPENJSON darf keine erwartete ungültige Eingabe sehen.
        IF ISJSON(@SeparatorsJson) <> 1 SET @Error = 'INVALID_SEPARATOR_JSON';
        ELSE
        BEGIN
            SET @Position = 1;
            WHILE @Position <= @JsonLength
              AND UNICODE(SUBSTRING(@SeparatorsJson COLLATE Latin1_General_100_BIN2, @Position, 1)) IN (9,10,13,32)
                SET @Position += 1;
            IF SUBSTRING(@SeparatorsJson COLLATE Latin1_General_100_BIN2, @Position, 1) <> N'['
                SET @Error = 'INVALID_SEPARATOR_JSON';
        END;
    END;
    IF @Error IS NULL
    BEGIN
        INSERT @Separators (SeparatorOrdinal, Separator, SeparatorLength, JsonType)
        SELECT CONVERT(int, [key]) + 1, value, DATALENGTH(value) / 2, type
        FROM OPENJSON(@SeparatorsJson);
        SET @SeparatorCount = (SELECT COUNT(*) FROM @Separators);
        IF @SeparatorCount = 0 SET @Error = 'INVALID_CONFIGURATION';
        ELSE IF @SeparatorCount > 16 SET @Error = 'SEPARATOR_LIMIT_EXCEEDED';
    END;

    -- Validierung exakt in Arrayreihenfolge, vor allen Steuerzeichenkonflikten.
    SET @SeparatorOrdinal = 1;
    WHILE @Error IS NULL AND @SeparatorOrdinal <= @SeparatorCount
    BEGIN
        SELECT @Separator = Separator, @SeparatorLength = SeparatorLength, @JsonType = JsonType
        FROM @Separators WHERE SeparatorOrdinal = @SeparatorOrdinal;
        IF @JsonType <> 1 SET @Error = 'INVALID_CONFIGURATION';
        ELSE IF @SeparatorLength = 0 SET @Error = 'EMPTY_SEPARATOR';
        ELSE IF @SeparatorLength > 64 SET @Error = 'SEPARATOR_LIMIT_EXCEEDED';
        ELSE
        BEGIN
            SET @Position = 1;
            WHILE @Position <= @SeparatorLength AND @Error IS NULL
            BEGIN
                IF UNICODE(SUBSTRING(@Separator COLLATE Latin1_General_100_BIN2, @Position, 1)) = 0
                    SET @Error = 'NUL_NOT_ALLOWED';
                SET @Position += 1;
            END;
            -- Binäre Bytes statt SQL-Textgleichheit: nachfolgende Spaces sind relevant.
            IF @Error IS NULL AND EXISTS
            (
                SELECT 1 FROM @Separators WHERE SeparatorOrdinal < @SeparatorOrdinal
                AND CONVERT(varbinary(max), Separator) = CONVERT(varbinary(max), @Separator)
            ) SET @Error = 'DUPLICATE_SEPARATOR';
        END;
        SET @SeparatorOrdinal += 1;
    END;

    IF @Error IS NULL
    BEGIN
        IF (@QuoteLength = 1 AND @QuoteCode = 0) OR (@EscapeLength = 1 AND @EscapeCode = 0)
            SET @Error = 'NUL_NOT_ALLOWED';
        ELSE IF (@QuoteLength = 1 AND @QuoteCode BETWEEN 55296 AND 57343)
             OR (@EscapeLength = 1 AND @EscapeCode BETWEEN 55296 AND 57343)
            SET @Error = 'INVALID_CONFIGURATION';
        ELSE IF @QuoteLength = 1 AND @EscapeLength = 1 AND @QuoteCode = @EscapeCode
            SET @Error = 'INVALID_CONFIGURATION';
    END;
    SET @SeparatorOrdinal = 1;
    WHILE @Error IS NULL AND @SeparatorOrdinal <= @SeparatorCount
    BEGIN
        SELECT @Separator = Separator, @SeparatorLength = SeparatorLength
        FROM @Separators WHERE SeparatorOrdinal = @SeparatorOrdinal;
        SET @Position = 1;
        WHILE @Position <= @SeparatorLength AND @Error IS NULL
        BEGIN
            SET @Character = UNICODE(SUBSTRING(@Separator COLLATE Latin1_General_100_BIN2, @Position, 1));
            IF (@QuoteLength = 1 AND @Character = @QuoteCode)
              OR (@EscapeLength = 1 AND @Character = @EscapeCode)
                SET @Error = 'INVALID_CONFIGURATION';
            SET @Position += 1;
        END;
        SET @SeparatorOrdinal += 1;
    END;

    -- NUL-Prüfung geht Parserfehlern vor; Position bleibt auf den Originalinput bezogen.
    SET @Position = 1;
    WHILE @Error IS NULL AND @Position <= @InputLength
    BEGIN
        IF UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2, @Position, 1)) = 0
        BEGIN
            SET @Error = 'NUL_NOT_ALLOWED';
            SET @ErrorPosition = @Position;
        END;
        SET @Position += 1;
    END;

    DECLARE @Tokens TABLE (TokenOrdinal bigint NOT NULL PRIMARY KEY, TokenStart bigint NOT NULL, TokenLength bigint NOT NULL);
    DECLARE @TokenStart bigint = 1, @TokenOrdinal bigint = 1,
            @QuoteStart bigint = NULL, @MatchedLength bigint;
    SET @Position = 1;
    WHILE @Error IS NULL AND @Position <= @InputLength
    BEGIN
        SET @Character = UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2, @Position, 1));
        IF @EscapeLength = 1 AND @Character = @EscapeCode
        BEGIN
            IF @Position = @InputLength
            BEGIN
                SET @Error = 'DANGLING_ESCAPE';
                SET @ErrorPosition = @Position;
            END;
            -- Auch vor High Surrogate nur eine Codeeinheit schützen; Originaltext bleibt.
            SET @Position += 2;
        END;
        ELSE IF @QuoteLength = 1 AND @Character = @QuoteCode
        BEGIN
            SET @QuoteStart = CASE WHEN @QuoteStart IS NULL THEN @Position ELSE NULL END;
            SET @Position += 1;
        END;
        ELSE
        BEGIN
            SET @MatchedLength = NULL;
            IF @QuoteStart IS NULL
                SELECT @MatchedLength = MAX(SeparatorLength)
                FROM @Separators
                WHERE @Position + SeparatorLength - 1 <= @InputLength
                  AND SUBSTRING(@Input COLLATE Latin1_General_100_BIN2, @Position, SeparatorLength) = Separator;
            IF @MatchedLength IS NOT NULL
            BEGIN
                INSERT @Tokens VALUES (@TokenOrdinal, @TokenStart, @Position - @TokenStart);
                SET @TokenOrdinal += 1;
                SET @Position += @MatchedLength;
                SET @TokenStart = @Position;
            END;
            ELSE SET @Position += 1;
        END;
    END;
    IF @Error IS NULL AND @QuoteStart IS NOT NULL
    BEGIN
        SET @Error = 'UNTERMINATED_QUOTE';
        SET @ErrorPosition = @QuoteStart;
    END;
    IF @Error IS NOT NULL
        INSERT @Result VALUES (NULL, NULL, 0, @Error, @ErrorPosition);
    ELSE
    BEGIN
        INSERT @Tokens VALUES (@TokenOrdinal, @TokenStart, @InputLength - @TokenStart + 1);
        -- Erst hier Tokens publizieren: spätes Parserproblem darf keine Teilwerte liefern.
        INSERT @Result (Value, Ordinal, IsValid, ErrorCode, ErrorPosition)
        SELECT SUBSTRING(@Input COLLATE Latin1_General_100_BIN2, TokenStart, TokenLength),
               ROW_NUMBER() OVER (ORDER BY TokenOrdinal), 1, NULL, NULL
        FROM @Tokens WHERE COALESCE(@KeepEmpty, 1) = 1 OR TokenLength > 0;
    END;
    RETURN;
END;
GO
