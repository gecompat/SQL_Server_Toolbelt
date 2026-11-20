-- ============================================================================
-- Objekt:          toolbelt_string.TVF_UnquoteToken
-- Typ:             Multi-statement TVF; kanonischer bounded Transformationskern
-- Zweck:           Ein äußeres Quote-Paar entfernen und innere closing dekodieren
-- Vertrag:         Documentation/TVF_UnquoteToken.md; Freigabe 2026-10-01
-- Parameter:       Input/Qualifier/ClosingQualifier nvarchar(max), BackslashEscape bit
-- Defaults:        Qualifier=NULL (Auto), ClosingQualifier=NULL, BackslashEscape=0
-- Resultset:       Value nvarchar(max), IsValid bit, ErrorCode varchar(64), ErrorPosition bigint
-- Dependencies:    keine; keine Änderung des Split-Tokenizers
-- Rechte:          SELECT auf der TVF
-- Versionen:       SQL Server 2019/2022/2025; Compatibility >=150
-- Plattformen:     Windows/Linux; neue Runtime-Evidenz separat nachzuweisen
-- Fehlerverhalten: atomare Geschäftsfehlerzeile; Enginefehler bleiben unverändert
-- Performance:     bounded Scan; keine Streaming-/Parallelitätszusage
-- Einschränkungen: 65536 UTF-16-Codeeinheiten; kein CSV/Scalar-Wrapper
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_string].[TVF_UnquoteToken]
(
      @Input nvarchar(max)
    , @Qualifier nvarchar(max) = NULL
    , @ClosingQualifier nvarchar(max) = NULL
    , @BackslashEscape bit = 0
)
RETURNS @Result TABLE
(
      Value nvarchar(max) NULL
    , IsValid bit NOT NULL
    , ErrorCode varchar(64) NULL
    , ErrorPosition bigint NULL
)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-string-tvf-unquotetoken"
-- description: "Entfernt ein unterstütztes äußeres Quote-Paar und decodiert dessen Escapes."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.string.split-advanced"
-- schema_name: "toolbelt_string"
-- object_name: "TVF_UnquoteToken"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Ein Token mit maximal 65536 UTF-16-Einheiten; leer ist gültig, NUL verboten. NULL liefert vor jeder Konfigurationsprüfung keine Zeile. Erkannte/explicit verlangte äußere Qualifier werden entfernt; ein unescaped inneres Closing-Zeichen ergibt eine ungültige Ergebniszeile."}, {"name": "@Qualifier", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "NULL (Default) erkennt nur direkt am Rand die Paare Doppelquote/Doppelquote, Apostroph/Apostroph, [/], “/” oder „/“; keine Rand-Whitespacebereinigung. Kein erkanntes Paar lässt den Token unverändert. Leer deaktiviert Unquote und verlangt ClosingQualifier=NULL. Explizit genau eine UTF-16-Einheit, weder NUL noch Surrogat; mit ClosingQualifier=NULL werden [ und ] zu [/], “ und ” zu “/”, „ zu „/“, andere Zeichen zu identischen Öffnern/Schließern normalisiert."}, {"name": "@ClosingQualifier", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "NULL (Default) verwendet das aus Qualifier abgeleitete Paar beziehungsweise die automatische Erkennung. Andernfalls genau eine nicht-NUL-/nicht-Surrogat-UTF-16-Einheit, nur zusammen mit einem expliziten nicht leeren Qualifier. Erfordert genau dieses Außenpaar; bei BackslashEscape=1 darf kein Qualifier Backslash sein."}, {"name": "@BackslashEscape", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ im gebundenen bit: 0 erkennt nur verdoppelte Closing-Zeichen (Default); 1 erkennt zusätzlich Backslash vor Öffner, Schließer oder Backslash. NULL wirkt wie 0. Keine JSON-/C-Interpretation von \\n, \\t usw.; Backslash darf im aktiven Modus kein Qualifier sein."}]
-- source_paths: ["Modules/toolbelt.string.split-advanced/Source/TVF_UnquoteToken.sql"]
-- review_status: "verified"
-- source_module_version: "1.1.0"
-- ---
--
-- # TVF_UnquoteToken
--
-- ## Zweck und Einsatzfälle
--
-- Entfernt genau ein erkanntes oder explizit verlangtes Außenpaar und dekodiert innere verdoppelte Closing-Zeichen sowie optional die festgelegten Backslash-Escapes. Eigenständiger Token-Transformator nach einem Split, kein Eingriff in den Split-Tokenizer.
--
-- ## Voraussetzungen
--
-- SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. Split-Advanced-Modul installiert; diese Funktion selbst hat keine Tabellen-/Helper-/CLR-/Netzwerkabhängigkeit. Alle vier Argumentpositionen angeben, DEFAULT für die gewünschten technischen Defaults.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@Input` | `nvarchar(max)` | `kein Default` | Ein Token mit maximal 65536 UTF-16-Einheiten; leer ist gültig, NUL verboten. NULL liefert vor jeder Konfigurationsprüfung keine Zeile. Erkannte/explicit verlangte äußere Qualifier werden entfernt; ein unescaped inneres Closing-Zeichen ergibt eine ungültige Ergebniszeile. |
-- | `@Qualifier` | `nvarchar(max)` | `NULL` | NULL (Default) erkennt nur direkt am Rand die Paare Doppelquote/Doppelquote, Apostroph/Apostroph, [/], “/” oder „/“; keine Rand-Whitespacebereinigung. Kein erkanntes Paar lässt den Token unverändert. Leer deaktiviert Unquote und verlangt ClosingQualifier=NULL. Explizit genau eine UTF-16-Einheit, weder NUL noch Surrogat; mit ClosingQualifier=NULL werden [ und ] zu [/], “ und ” zu “/”, „ zu „/“, andere Zeichen zu identischen Öffnern/Schließern normalisiert. |
-- | `@ClosingQualifier` | `nvarchar(max)` | `NULL` | NULL (Default) verwendet das aus Qualifier abgeleitete Paar beziehungsweise die automatische Erkennung. Andernfalls genau eine nicht-NUL-/nicht-Surrogat-UTF-16-Einheit, nur zusammen mit einem expliziten nicht leeren Qualifier. Erfordert genau dieses Außenpaar; bei BackslashEscape=1 darf kein Qualifier Backslash sein. |
-- | `@BackslashEscape` | `bit` | `0` | Taxativ im gebundenen bit: 0 erkennt nur verdoppelte Closing-Zeichen (Default); 1 erkennt zusätzlich Backslash vor Öffner, Schließer oder Backslash. NULL wirkt wie 0. Keine JSON-/C-Interpretation von \n, \t usw.; Backslash darf im aktiven Modus kein Qualifier sein. |
--
-- ## Ergebnisse
--
-- Input=NULL liefert vor jeder Konfigurationsprüfung null Zeilen. Sonst genau eine atomare Zeile: Value nvarchar(max), IsValid bit NOT NULL, ErrorCode varchar(64), ErrorPosition bigint. Erfolg hat IsValid=1, Fehlerfelder NULL; fachlicher Fehler hat Value=NULL, IsValid=0 und einen der unten genannten Codes. Auto ohne vollständiges unterstütztes Außenpaar oder Qualifier=leer liefert den Token unverändert; es wird vorher nicht getrimmt. Bei erfolgreichem Unquote ist nur ein Außenpaar entfernt, kein rekursives Unquote.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_string.TVF_UnquoteToken
--  (N'[a]]b]',DEFAULT,DEFAULT,DEFAULT);
-- -- Value=a]b, IsValid=1, ErrorCode/ErrorPosition=NULL.
-- SELECT * FROM toolbelt_string.TVF_UnquoteToken
--  (NULL,DEFAULT,DEFAULT,DEFAULT);
-- -- Keine Zeile.
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT auf der TVF für SELECT-Aufrufe; REFERENCES bei entsprechender Referenzverwendung. Kein Rechtegrant oder Identitätswechsel. Cross-Database-Zuordnung bleibt beim Caller.
--
-- ## Ressourcenbedarf
--
-- Input höchstens 65536 UTF-16-Codeeinheiten, also 131072 Bytes; dies ist ausdrücklich nicht die 65536-Byte-Grenze des einfachen Splitters. Konfigurations-/NUL-/Rand-/Innenscans sind begrenzt. Unveränderte Spans werden gesammelt und am Ende geordnet per STRING_AGG kopiert, statt die Ausgabe nach jedem Zeichen zu verlängern. Keine Streaming-/Parallelitäts- oder Laufzeitgarantie.
--
-- ## Nebenwirkungen
--
-- Rein lesend ohne persistente DML-, Datei-, Netzwerk-, Trust-, Konfigurations- oder Transaktionsänderung. Die Span-/Rückgabetabellen sind nur lokale Funktionsvariablen.
--
-- ## Fehlerbehandlung
--
-- Nach Input-NULL hat ungültige Qualifierkonfiguration Vorrang (INVALID_CONFIGURATION, Position=NULL), danach Inputlänge (INPUT_LIMIT_EXCEEDED, Position=NULL), dann erstes NUL (NUL_NOT_ALLOWED, einbasierte Originalposition). Expliziter Modus ohne gültiges Außenpaar ergibt OUTER_PAIR_REQUIRED: leer Position=NULL, Länge1 Position1, falscher Öffner Position1, sonst letzte Position. Ein im aktiven Innenbereich nicht escaptes Closing ergibt UNESCAPED_CLOSING_QUALIFIER an dessen Originalposition. Unerwartete Enginefehler bleiben Fehler; keine Teilstrings als Fehlerergebnis.
--
-- ## Aussagegrenzen
--
-- Qualifier sind einzelne nicht-NUL-/nicht-Surrogat-UTF-16-Einheiten; der Input ist kein allgemeiner Unicode-Scalar-Validator. Auto erkennt nur am ersten Zeichen Doppelquote, Apostroph, [, “ oder „ mit den zugehörigen Schließern. Ein escaptes letztes Closing gilt nicht als Außenende: explizit Fehler, automatisch unverändert. Backslash-Escape hat innen Vorrang vor doubled closing; das reservierte letzte Außenzeichen kann nicht zweite Hälfte eines inneren Double sein. Andere Backslashfolgen wie \n bleiben unverändert; kein JSON-/C-/CSV-Parser. Fehlerpositionen sind einbasierte BIN2-UTF-16-Originalpositionen.
-- OBJECT_USAGE_SKILL:END
AS
BEGIN
    IF @Input IS NULL RETURN;
    DECLARE @Length bigint = DATALENGTH(@Input)/2,
            @QualifierLength bigint = DATALENGTH(@Qualifier)/2,
            @ClosingLength bigint = DATALENGTH(@ClosingQualifier)/2,
            @Opening int = UNICODE(@Qualifier COLLATE Latin1_General_100_BIN2),
            @Closing int = UNICODE(@ClosingQualifier COLLATE Latin1_General_100_BIN2),
            @Mode tinyint = CASE WHEN @Qualifier IS NULL THEN 0
                                WHEN DATALENGTH(@Qualifier)=0 THEN 1 ELSE 2 END,
            @Error varchar(64) = NULL, @ErrorPosition bigint = NULL,
            @Position bigint = 1, @Code int, @Next int,
            @EscapedEnd bit = 0, @Output nvarchar(max) = N'';
    SET @BackslashEscape = COALESCE(@BackslashEscape,0);

    -- Vollständige Konfiguration vor Inputlimit und Input-NUL prüfen.
    IF (@Mode<>2 AND @ClosingQualifier IS NOT NULL)
       OR (@Mode=2 AND (@QualifierLength<>1 OR @Opening=0 OR @Opening BETWEEN 55296 AND 57343))
       OR (@ClosingQualifier IS NOT NULL AND
           (@ClosingLength<>1 OR @Closing=0 OR @Closing BETWEEN 55296 AND 57343))
        SET @Error='INVALID_CONFIGURATION';
    IF @Error IS NULL AND @Mode=2 AND @ClosingQualifier IS NULL
    BEGIN
        IF @Opening IN (91,93) SELECT @Opening=91,@Closing=93;
        ELSE IF @Opening IN (8220,8221) SELECT @Opening=8220,@Closing=8221;
        ELSE IF @Opening=8222 SET @Closing=8220;
        ELSE SET @Closing=@Opening;
    END;
    IF @Error IS NULL AND @Mode=2 AND @BackslashEscape=1
       AND (@Opening=92 OR @Closing=92) SET @Error='INVALID_CONFIGURATION';
    IF @Error IS NULL AND @Length>65536 SET @Error='INPUT_LIMIT_EXCEEDED';
    WHILE @Error IS NULL AND @Position<=@Length
    BEGIN
        IF UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,@Position,1))=0
            SELECT @Error='NUL_NOT_ALLOWED',@ErrorPosition=@Position;
        SET @Position+=1;
    END;

    -- Auto erkennt ausschließlich das erste Zeichen, ohne Trim oder globale Quotes.
    IF @Error IS NULL AND @Mode=0
    BEGIN
        SET @Opening=UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,1,1));
        SET @Closing=CASE @Opening WHEN 34 THEN 34 WHEN 39 THEN 39
                        WHEN 91 THEN 93 WHEN 8220 THEN 8221 WHEN 8222 THEN 8220 END;
    END;
    IF @Error IS NULL AND @Mode<>1
    BEGIN
        IF @Length<2 OR @Closing IS NULL
           OR UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,1,1))<>@Opening
           OR UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,@Length,1))<>@Closing
        BEGIN
            IF @Mode=2
                SELECT @Error='OUTER_PAIR_REQUIRED',
                       @ErrorPosition=CASE WHEN @Length=0 THEN NULL WHEN @Length=1 THEN 1
                         WHEN UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,1,1))<>@Opening THEN 1 ELSE @Length END;
            ELSE SET @Mode=1;
        END;
        ELSE IF @BackslashEscape=1
        BEGIN
            -- Randprüfung: erkannte Escapefolgen konsumieren zwei Originaleinheiten.
            -- Doubled closing hat hier keinen Einfluss auf das Escaped-End-Flag.
            SET @Position=2;
            WHILE @Position<=@Length
            BEGIN
                SET @Code=UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,@Position,1));
                SET @Next=CASE WHEN @Position<@Length THEN UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,@Position+1,1)) END;
                IF @Code=92 AND @Next IN (@Opening,@Closing,92)
                BEGIN
                    IF @Position+1=@Length SET @EscapedEnd=1;
                    SET @Position+=2;
                END;
                ELSE SET @Position+=1;
            END;
            IF @EscapedEnd=1
            BEGIN
                IF @Mode=2 SELECT @Error='OUTER_PAIR_REQUIRED',@ErrorPosition=@Length;
                ELSE SET @Mode=1;
            END;
        END;
    END;

    IF @Error IS NULL AND @Mode=1 SET @Output=@Input;
    ELSE IF @Error IS NULL
    BEGIN
        -- Außenzeichen sind reserviert. Escape hat Vorrang vor doubled closing;
        -- ein Double darf das reservierte Endzeichen niemals als zweite Hälfte nutzen.
        SET @Position=2;
        DECLARE @SpanStart bigint=2, @SpanOrdinal int=0;
        DECLARE @Spans TABLE(Ordinal int NOT NULL PRIMARY KEY,StartPosition bigint NOT NULL,SpanLength bigint NOT NULL);
        WHILE @Position<@Length AND @Error IS NULL
        BEGIN
            SET @Code=UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,@Position,1));
            SET @Next=CASE WHEN @Position+1<@Length THEN UNICODE(SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,@Position+1,1)) END;
            IF (@BackslashEscape=1 AND @Code=92 AND @Next IN (@Opening,@Closing,92))
               OR (@Code=@Closing AND @Next=@Closing)
            BEGIN
                -- Nur an Transformationen kopieren, unveränderte Spans nicht pro Zeichen.
                IF @Position>@SpanStart
                BEGIN
                    SET @SpanOrdinal+=1;
                    INSERT @Spans VALUES(@SpanOrdinal,@SpanStart,@Position-@SpanStart);
                END;
                SET @SpanOrdinal+=1;
                INSERT @Spans VALUES(@SpanOrdinal,@Position+1,1);
                SET @Position+=2;
                SET @SpanStart=@Position;
            END;
            ELSE IF @Code=@Closing
                SELECT @Error='UNESCAPED_CLOSING_QUALIFIER',@ErrorPosition=@Position;
            ELSE SET @Position+=1;
        END;
        IF @Error IS NULL
        BEGIN
            IF @Length>@SpanStart
            BEGIN
                SET @SpanOrdinal+=1;
                INSERT @Spans VALUES(@SpanOrdinal,@SpanStart,@Length-@SpanStart);
            END;
            SELECT @Output=COALESCE(STRING_AGG(CONVERT(nvarchar(max),
                SUBSTRING(@Input COLLATE Latin1_General_100_BIN2,StartPosition,SpanLength)),N'')
                WITHIN GROUP(ORDER BY Ordinal),N'') FROM @Spans;
        END;
    END;
    IF @Error IS NULL INSERT @Result VALUES(@Output,1,NULL,NULL);
    ELSE INSERT @Result VALUES(NULL,0,@Error,@ErrorPosition);
    RETURN;
END;
GO
