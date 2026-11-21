SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================================
-- Objekt:          toolbelt_metadata.TVF_ParseMultipartName
-- Typ:             Multi-statement Table-valued Function
-- Zweck:           Zerlegt und validiert ein- bis vierteilige SQL-Namen.
-- Vertrag:         Documentation/TVF_ParseMultipartName.md
-- Parameter:       @MultipartName nvarchar(1035)
-- Resultset:       Eine Zeile mit Status, Teilen und sicher begrenztem Namen.
-- Dependencies:    Keine Modulabhängigkeit.
-- Rechte:          SELECT oder REFERENCES
-- Versionen:       SQL Server 2019/2022/2025
-- Plattformen:     Windows/Linux
-- Fehlerverhalten: Ungültige Eingaben werden als ValidationCode zurückgegeben.
-- Performance:     Zustandsautomat mit linearer Laufzeit und maximal 1035 Zeichen.
-- Einschränkungen: Doppelte Anführungszeichen sind keine Identifier-Delimiter.
-- ============================================================================
CREATE OR ALTER FUNCTION [toolbelt_metadata].[TVF_ParseMultipartName]
(
    @MultipartName nvarchar(1035)
)
RETURNS @Result TABLE
(
      IsValid        bit            NOT NULL
    , ValidationCode varchar(32)     NOT NULL
    , PartCount      tinyint         NULL
    , ServerName     sysname         NULL
    , DatabaseName   sysname         NULL
    , SchemaName     sysname         NULL
    , ObjectName     sysname         NULL
    , QuotedName     nvarchar(1035)  NULL
)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-metadata-tvf-parsemultipartname"
-- description: "Zerlegt und validiert ein- bis vierteilige SQL-Identifier."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.metadata.identifier"
-- schema_name: "toolbelt_metadata"
-- object_name: "TVF_ParseMultipartName"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@MultipartName", "sql_type": "nvarchar(1035)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Ein- bis vierteiliger SQL-Identifier als nvarchar(1035), je ausgeschriebenem Teil höchstens 128 UTF16-Codeeinheiten. Formen: Object; Schema.Object; Database.Schema.Object; Server.Database.Schema.Object; Database..Object; Server.Database..Object; Server..Schema.Object; Server...Object. Eckige Klammern erlauben Punkte im Teil und ]] als escaped Schlussklammer. Keine doppelten Quotes als Delimiter, äußeren Spaces, leeren Objektteile oder Steuerzeichen. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit ValidationCode, beim Scalarwrapper NULL. Existenz und Rechte werden nicht dadurch geprüft. ASCII-Delimiter werden binär erkannt, escaped ]] wird einmal zurückgenommen. Gequotete Spaces einschließlich [ ] sind Inhalt, keine Auslassung; Spaces vor einer öffnenden Klammer sind BRACKET_SYNTAX. Parameterbindung auf1035Codeeinheiten liegt vor der Funktion und kann längere Callerwerte kürzen; ursprüngliche Länge bei Bedarf vorher im Client/max-Typ prüfen."}]
-- source_paths: ["Modules/toolbelt.metadata.identifier/Source/TVF_ParseMultipartName.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # TVF_ParseMultipartName
--
-- ## Zweck und Einsatzfälle
--
-- Zerlegt und validiert ein- bis vierteilige SQL-Identifier.
--
-- ## Voraussetzungen
--
-- Identifier-Modul, Windows/Linux SQL2019/2022/2025 mit zulässigem CL150/160/170. Rein lokale Stringverarbeitung, keine Objekt-/Datenbank-/Serverauflösung oder Metadatensicht.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@MultipartName` | `nvarchar(1035)` | kein Default | Input | Ein- bis vierteiliger SQL-Identifier als nvarchar(1035), je ausgeschriebenem Teil höchstens 128 UTF16-Codeeinheiten. Formen: Object; Schema.Object; Database.Schema.Object; Server.Database.Schema.Object; Database..Object; Server.Database..Object; Server..Schema.Object; Server...Object. Eckige Klammern erlauben Punkte im Teil und ]] als escaped Schlussklammer. Keine doppelten Quotes als Delimiter, äußeren Spaces, leeren Objektteile oder Steuerzeichen. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit ValidationCode, beim Scalarwrapper NULL. Existenz und Rechte werden nicht dadurch geprüft. ASCII-Delimiter werden binär erkannt, escaped ]] wird einmal zurückgenommen. Gequotete Spaces einschließlich [ ] sind Inhalt, keine Auslassung; Spaces vor einer öffnenden Klammer sind BRACKET_SYNTAX. Parameterbindung auf1035Codeeinheiten liegt vor der Funktion und kann längere Callerwerte kürzen; ursprüngliche Länge bei Bedarf vorher im Client/max-Typ prüfen. |
--
-- Alle Positionen beim SELECT-Aufruf angeben; DEFAULT verwendet einen deklarierten Funktionsdefault, NULL bleibt ein eigener Wert. SQL-Typbindung und eine mögliche Kürzung auf feste Parameterbreite liegen vor dem Funktionskörper.
--
-- ## Ergebnisse
--
-- Genau eine Zeile mit acht Spalten:IsValid bit NOT NULL,ValidationCode varchar(32) NOT NULL,PartCount tinyint NULL,ServerName/DatabaseName/SchemaName/ObjectName sysname NULL,QuotedName nvarchar(1035) NULL. Erfolg VALID und rechtsbündig zugeordnete1..4Teile; mittlere Auslassungen bleibenNULL. Fehler:IsValid0,alle Namensfelder/QuotedNameNULL,PartCount beschreibt den erreichten Parserstand (auch bei NULL/leer zunächst1), keinen erfolgreichen Parse.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_metadata.TVF_ParseMultipartName(N'[ContosoDb]..[Order]]Line]');
-- SELECT toolbelt_metadata.SVF_QuoteMultipartName(N'dbo.ContosoSource');
-- SELECT * FROM toolbelt_metadata.TVF_ParseMultipartName(N'[ ]');
-- ```
--
-- ## Rechte
--
-- Parser-TVF:vorhandenes SELECT/gegebenenfalls REFERENCES. Scalarfunktion:vorhandenes EXECUTE und nötige Ownershipchain zum Parser. Keine Katalog-/Objektvollsicht oder zusätzlichen Serverrechte; diese Ausgabe erteilt keine Ausführungsberechtigung auf den gequoteten Namen.
--
-- ## Ressourcenbedarf
--
-- Fest gebundener Input nvarchar1035, höchstens4Teile je128UTF16-Codeeinheiten. Kleine lokale @Parts-/Resulttablevariablen und linearer Zustandsautomat; QuotedName1035 reicht für vier maximal escapte128erTeile plusDelimitern/Punkten. Bindung kann bereits vor der Funktion kürzen; dies ist keine Prüfung der ursprünglichen Clientlänge. Kein allgemeiner Sqlparser/Unicode-Wellformedness-/Laufzeit- oder Objektexistenzvertrag.
--
-- ## Nebenwirkungen
--
-- Begrenzter Zustandsautomat über physische UTF16-Codeeinheiten: DATALENGTH/2 und explizites BIN2-SUBSTRING verwenden dieselbe Einheit, unabhängig von SC. Nchar1 puffert jeweils genau eine Einheit; ein gültiges Surrogatepaar bleibt beim Zusammenfügen bytegleich und zählt zwei Einheiten gegen sysname128. ASCII-Delimiter/Lookahead/Metazeichen explizit binär, keine linguistische Breitenäquivalenz. Leere Teilwerte/Auslassung anhand Bytelänge, nicht SQL-Space-Padding: [ ] ist ein echter Space-Identifier, [] leer; Text/Space vor öffnenderKlammer kein leeres Präfix.
--
-- 1..4Teile, höchstens128decodierte Codeeinheiten jeTeil. Punkt trennt nur außerhalb [...], ]] entescapt einmal zu]. Nach schließenderKlammer nurPunkt oderEnde. DoppelteQuotes sind keine Delimiter. Unquoted ASCII-Metazeichen * % Quotes ; ( ) , = + - / Backslash : ? ! { } | & < > sowie Steuerzeichen<32/127 abweisen; innerhalbKlammern Metazeichen/Punkte Inhalt, Steuerzeichen weiterhinverboten. Unquoted äußere ASCII-Spaces ungültig, quoted Spaces erhalten. Auslassung nur zwischen vorhandenen Rändern bei3/4Teilen, nie linkester/rechtesterTeil. QUOTENAME jeden vorhandenen Teil, mittlere Auslassungen als leere Stellen zwischenPunkten bewahren. Keine Case-/Unicode-Normalisierung oder Nachweis eines tatsächlich existierenden SQLobjekts. Scalarwrapper fragt den Parser genau einmal ab, nur gültigen QuotedName zurückgeben. Keine Mutation oder eigeneTransaktion.
--
-- ## Fehlerbehandlung
--
-- VALID beiErfolg;NULL_INPUT,EMPTY_INPUT,CONTROL_CHARACTER,BRACKET_SYNTAX,TEXT_AFTER_DELIMITER,UNQUOTED_META_CHARACTER,PART_TOO_LONG,TOO_MANY_PARTS,UNCLOSED_DELIMITER,EMPTY_IDENTIFIER,OUTER_WHITESPACE,INVALID_OMISSION,INVALID_IDENTIFIER. Keine Eingabewerte im Status; Scalar bildet alle Fehler aufNULL ab. Typbindung/sonstige Enginefehler nicht pauschal abgefangen.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag. Die ausdrücklich deklarierten funktionalen Korrekturen in diesem Modul benötigen neue native Gegenproben; historische Nachweise qualifizieren nur ihre ursprünglichen Bytes. Noch kein aktuelles natives API-/SC-/UTF8-/Caller-/Gesamtinstaller-PASS. Keine Installations-/Rechteattestation. Nur synthetische Beispiele; reale Eingaben/Runtimeausgaben privat halten.
-- OBJECT_USAGE_SKILL:END
AS
BEGIN
    DECLARE
          @IsValid          bit = 1
        , @ValidationCode   varchar(32) = 'VALID'
        , @InputLength      int
        , @Position         int = 1
        , @PartOrdinal      tinyint = 1
        , @CurrentPart      nvarchar(1035) = N''
        , @Character        nchar(1)
        , @NextCharacter    nchar(1)
        , @InsideDelimited  bit = 0
        , @AfterDelimited   bit = 0
        , @PartIsDelimited  bit = 0;

    DECLARE @Parts TABLE
    (
          PartOrdinal tinyint         NOT NULL PRIMARY KEY
        , PartValue   nvarchar(1035)  NULL
        , IsDelimited bit             NOT NULL
        , IsOmitted   bit             NOT NULL
    );

    IF @MultipartName IS NULL
    BEGIN
        SET @IsValid = 0;
        SET @ValidationCode = 'NULL_INPUT';
    END;
    ELSE
    BEGIN
        /*
         * Physische UTF16-Codeeinheiten einschließlich nachgestellter
         * Spaces; dieselbe Einheit wie die binären SUBSTRING-Schritte.
         */
        SET @InputLength = DATALENGTH(@MultipartName) / 2;

        IF @InputLength = 0
        BEGIN
            SET @IsValid = 0;
            SET @ValidationCode = 'EMPTY_INPUT';
        END;
    END;

    WHILE @IsValid = 1 AND @Position <= @InputLength
    BEGIN
        SET @Character = SUBSTRING(@MultipartName COLLATE Latin1_General_100_BIN2, @Position, 1);
        SET @NextCharacter =
            CASE
                WHEN @Position < @InputLength
                    THEN SUBSTRING(@MultipartName COLLATE Latin1_General_100_BIN2, @Position + 1, 1)
                ELSE NULL
            END;

        IF UNICODE(@Character) < 32 OR UNICODE(@Character) = 127
        BEGIN
            SET @IsValid = 0;
            SET @ValidationCode = 'CONTROL_CHARACTER';
        END;
        ELSE IF @InsideDelimited = 1
        BEGIN
            IF @Character COLLATE Latin1_General_100_BIN2 = N']'
            BEGIN
                IF @NextCharacter COLLATE Latin1_General_100_BIN2 = N']'
                BEGIN
                    SET @CurrentPart += N']';
                    SET @Position += 2;
                END;
                ELSE
                BEGIN
                    SET @InsideDelimited = 0;
                    SET @AfterDelimited = 1;
                    SET @Position += 1;
                END;
            END;
            ELSE
            BEGIN
                SET @CurrentPart += @Character;
                SET @Position += 1;
            END;
        END;
        ELSE IF @AfterDelimited = 1
        BEGIN
            IF @Character COLLATE Latin1_General_100_BIN2 <> N'.'
            BEGIN
                SET @IsValid = 0;
                SET @ValidationCode = 'TEXT_AFTER_DELIMITER';
            END;
            ELSE
            BEGIN
                INSERT INTO @Parts
                (
                      PartOrdinal
                    , PartValue
                    , IsDelimited
                    , IsOmitted
                )
                VALUES
                (
                      @PartOrdinal
                    , @CurrentPart
                    , 1
                    , 0
                );

                SET @PartOrdinal += 1;
                SET @CurrentPart = N'';
                SET @InsideDelimited = 0;
                SET @AfterDelimited = 0;
                SET @PartIsDelimited = 0;
                SET @Position += 1;
            END;
        END;
        ELSE IF @Character COLLATE Latin1_General_100_BIN2 = N'.'
        BEGIN
            INSERT INTO @Parts
            (
                  PartOrdinal
                , PartValue
                , IsDelimited
                , IsOmitted
            )
            VALUES
            (
                  @PartOrdinal
                , CASE WHEN DATALENGTH(@CurrentPart)=0 THEN NULL ELSE @CurrentPart END
                , @PartIsDelimited
                , CASE WHEN DATALENGTH(@CurrentPart)=0 THEN 1 ELSE 0 END
            );

            SET @PartOrdinal += 1;
            SET @CurrentPart = N'';
            SET @PartIsDelimited = 0;
            SET @Position += 1;
        END;
        ELSE IF @Character COLLATE Latin1_General_100_BIN2 = N'['
        BEGIN
            IF DATALENGTH(@CurrentPart)>0
            BEGIN
                SET @IsValid = 0;
                SET @ValidationCode = 'BRACKET_SYNTAX';
            END;
            ELSE
            BEGIN
                SET @InsideDelimited = 1;
                SET @PartIsDelimited = 1;
                SET @Position += 1;
            END;
        END;
        ELSE IF @Character COLLATE Latin1_General_100_BIN2 = N']'
        BEGIN
            SET @IsValid = 0;
            SET @ValidationCode = 'BRACKET_SYNTAX';
        END;
        ELSE
        BEGIN
            /*
             * Ausdrucks- und Wildcard-Metazeichen sind in der unquoted Form
             * nicht Teil dieses Vertrags. Innerhalb von [...] bleiben sie
             * normale Identifierzeichen.
             */
            IF CHARINDEX
               (
                   @Character COLLATE Latin1_General_100_BIN2,
                   N'*%''";(),=+-/\:?!{}|&<>'
                       COLLATE Latin1_General_100_BIN2
               ) > 0
            BEGIN
                SET @IsValid = 0;
                SET @ValidationCode = 'UNQUOTED_META_CHARACTER';
            END;
            ELSE
            BEGIN
                SET @CurrentPart += @Character;
                SET @Position += 1;
            END;
        END;

        IF DATALENGTH(@CurrentPart) / 2 > 128
        BEGIN
            SET @IsValid = 0;
            SET @ValidationCode = 'PART_TOO_LONG';
        END;

        IF @PartOrdinal > 4
        BEGIN
            SET @IsValid = 0;
            SET @ValidationCode = 'TOO_MANY_PARTS';
        END;
    END;

    IF @IsValid = 1 AND @InsideDelimited = 1
    BEGIN
        SET @IsValid = 0;
        SET @ValidationCode = 'UNCLOSED_DELIMITER';
    END;

    IF @IsValid = 1
    BEGIN
        INSERT INTO @Parts
        (
              PartOrdinal
            , PartValue
            , IsDelimited
            , IsOmitted
        )
        VALUES
        (
              @PartOrdinal
            , CASE
                  WHEN @AfterDelimited = 1 THEN @CurrentPart
                  ELSE CASE WHEN DATALENGTH(@CurrentPart)=0 THEN NULL ELSE @CurrentPart END
              END
            , @PartIsDelimited
            , CASE
                  WHEN @AfterDelimited = 0 AND DATALENGTH(@CurrentPart)=0 THEN 1
                  ELSE 0
              END
        );
    END;

    DECLARE @PartCount tinyint =
        CASE
            WHEN @IsValid = 1 THEN (SELECT COUNT(*) FROM @Parts)
            ELSE @PartOrdinal
        END;

    IF @IsValid = 1 AND @PartCount > 4
    BEGIN
        SET @IsValid = 0;
        SET @ValidationCode = 'TOO_MANY_PARTS';
    END;

    IF @IsValid = 1
       AND EXISTS
           (
               SELECT 1
               FROM @Parts
               WHERE IsDelimited = 1
                 AND DATALENGTH(ISNULL(PartValue, N''))=0
           )
    BEGIN
        SET @IsValid = 0;
        SET @ValidationCode = 'EMPTY_IDENTIFIER';
    END;

    IF @IsValid = 1
       AND EXISTS
           (
               SELECT 1
               FROM @Parts
               WHERE IsDelimited = 0
                 AND PartValue IS NOT NULL
                 AND
                 (
                     LEFT(PartValue COLLATE Latin1_General_100_BIN2, 1) = N' '
                     OR RIGHT(PartValue COLLATE Latin1_General_100_BIN2, 1) = N' '
                 )
           )
    BEGIN
        SET @IsValid = 0;
        SET @ValidationCode = 'OUTER_WHITESPACE';
    END;

    IF @IsValid = 1
       AND
       (
           EXISTS
           (
               SELECT 1
               FROM @Parts
               WHERE PartOrdinal IN (1, @PartCount)
                 AND IsOmitted = 1
           )
           OR EXISTS
              (
                  SELECT 1
                  FROM @Parts
                  WHERE IsOmitted = 1
                    AND
                    (
                        @PartCount < 3
                        OR PartOrdinal NOT BETWEEN 2 AND @PartCount - 1
                    )
              )
       )
    BEGIN
        SET @IsValid = 0;
        SET @ValidationCode = 'INVALID_OMISSION';
    END;

    DECLARE
          @Part1 sysname
        , @Part2 sysname
        , @Part3 sysname
        , @Part4 sysname
        , @ServerName sysname
        , @DatabaseName sysname
        , @SchemaName sysname
        , @ObjectName sysname
        , @QuotedName nvarchar(1035);

    IF @IsValid = 1
    BEGIN
        SELECT
              @Part1 = MAX(CASE WHEN PartOrdinal = 1 THEN PartValue END)
            , @Part2 = MAX(CASE WHEN PartOrdinal = 2 THEN PartValue END)
            , @Part3 = MAX(CASE WHEN PartOrdinal = 3 THEN PartValue END)
            , @Part4 = MAX(CASE WHEN PartOrdinal = 4 THEN PartValue END)
        FROM @Parts;

        SELECT
              @ServerName =
                  CASE WHEN @PartCount = 4 THEN @Part1 END
            , @DatabaseName =
                  CASE
                      WHEN @PartCount = 4 THEN @Part2
                      WHEN @PartCount = 3 THEN @Part1
                  END
            , @SchemaName =
                  CASE
                      WHEN @PartCount = 4 THEN @Part3
                      WHEN @PartCount = 3 THEN @Part2
                      WHEN @PartCount = 2 THEN @Part1
                  END
            , @ObjectName =
                  CASE @PartCount
                      WHEN 4 THEN @Part4
                      WHEN 3 THEN @Part3
                      WHEN 2 THEN @Part2
                      WHEN 1 THEN @Part1
                  END;

        SET @QuotedName =
            CASE @PartCount
                WHEN 1
                    THEN QUOTENAME(@Part1)
                WHEN 2
                    THEN QUOTENAME(@Part1) + N'.' + QUOTENAME(@Part2)
                WHEN 3
                    THEN QUOTENAME(@Part1) + N'.'
                       + COALESCE(QUOTENAME(@Part2), N'') + N'.'
                       + QUOTENAME(@Part3)
                WHEN 4
                    THEN QUOTENAME(@Part1) + N'.'
                       + COALESCE(QUOTENAME(@Part2), N'') + N'.'
                       + COALESCE(QUOTENAME(@Part3), N'') + N'.'
                       + QUOTENAME(@Part4)
            END;

        IF @QuotedName IS NULL OR @ObjectName IS NULL
        BEGIN
            SET @IsValid = 0;
            SET @ValidationCode = 'INVALID_IDENTIFIER';
            SET @ServerName = NULL;
            SET @DatabaseName = NULL;
            SET @SchemaName = NULL;
            SET @ObjectName = NULL;
            SET @QuotedName = NULL;
        END;
    END;

    INSERT INTO @Result
    (
          IsValid
        , ValidationCode
        , PartCount
        , ServerName
        , DatabaseName
        , SchemaName
        , ObjectName
        , QuotedName
    )
    VALUES
    (
          @IsValid
        , @ValidationCode
        , @PartCount
        , CASE WHEN @IsValid = 1 THEN @ServerName END
        , CASE WHEN @IsValid = 1 THEN @DatabaseName END
        , CASE WHEN @IsValid = 1 THEN @SchemaName END
        , CASE WHEN @IsValid = 1 THEN @ObjectName END
        , CASE WHEN @IsValid = 1 THEN @QuotedName END
    );

    RETURN;
END;
GO
