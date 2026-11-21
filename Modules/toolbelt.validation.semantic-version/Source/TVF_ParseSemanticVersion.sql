CREATE OR ALTER FUNCTION [toolbelt_validation].[TVF_ParseSemanticVersion]
(
    @Version varchar(8000)
)
RETURNS @Result TABLE
(
      IsValid          bit           NOT NULL
    , ValidationCode   varchar(32)   NOT NULL
    , Major            varchar(8000) NULL
    , Minor            varchar(8000) NULL
    , Patch            varchar(8000) NULL
    , PreRelease       varchar(8000) NULL
    , BuildMetadata    varchar(8000) NULL
    , CanonicalVersion varchar(8000) NULL
)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-semver-tvf-parsesemanticversion"
-- description: "Prüft und zerlegt einen strikten SemVer-2.0.0-Text mit explizitem Validierungsstatus."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.validation.semantic-version"
-- schema_name: "toolbelt_validation"
-- object_name: "TVF_ParseSemanticVersion"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Version", "sql_type": "varchar(8000)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "ASCII-SemVertext als varchar(8000): Major.Minor.Patch mit optionalem -PreRelease und +BuildMetadata. Corezahlen und ausschließlich numerische Pre-release-Identifier ohne führende Nullen außer 0; Build-Identifier dürfen führende Nullen besitzen. Nichtleere punktgetrennte Identifier bestehen aus ASCII-Buchstaben, Ziffern oder Bindestrich. Kein v-Präfix, Trimmen, Whitespace oder Normalisieren. NULL und leer sind zulässige Prüfargumente, aber keine gültige Version. Große Zahlen bleiben Text, kein int-/bigint-Limit. Die SQL-Argumentbindung kann längere Werte bereits auf 8000 Bytes kürzen; Überlänge daher vor dem Aufruf am ursprünglichen Wert prüfen. Kein SQL-Default; Argument syntaktisch erforderlich."}]
-- source_paths: ["Modules/toolbelt.validation.semantic-version/Source/TVF_ParseSemanticVersion.sql"]
-- review_status: "verified"
-- source_module_version: "1.1.0"
-- ---
--
-- # TVF_ParseSemanticVersion
--
-- ## Zweck und Einsatzfälle
--
-- Prüft und zerlegt einen strikten SemVer-2.0.0-Text mit explizitem Validierungsstatus. Für mengenorientierte Vergleiche/Sortierung sind die relationalen TVFs die kanonischen Einstiegspunkte; SVFs dienen einzelnen Komfortaufrufen.
--
-- ## Voraussetzungen
--
-- Installiertes T-SQL-Modul auf unterstütztem SQL Server 2019/2022/2025 unter Windows oder Linux. Lokal und zentral gemäß vorhandenem Deploymentvertrag; Abhängigkeiten innerhalb des Moduls müssen vorhanden sein. Keine CLR-, Root-, Datenquellen- oder Netzwerkanforderung. Die relevanten Zeichenvergleiche verwenden explizit Latin1_General_100_BIN2.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@Version` | `varchar(8000)` | `kein Default` | ASCII-SemVertext als varchar(8000): Major.Minor.Patch mit optionalem -PreRelease und +BuildMetadata. Corezahlen und ausschließlich numerische Pre-release-Identifier ohne führende Nullen außer 0; Build-Identifier dürfen führende Nullen besitzen. Nichtleere punktgetrennte Identifier bestehen aus ASCII-Buchstaben, Ziffern oder Bindestrich. Kein v-Präfix, Trimmen, Whitespace oder Normalisieren. NULL und leer sind zulässige Prüfargumente, aber keine gültige Version. Große Zahlen bleiben Text, kein int-/bigint-Limit. Die SQL-Argumentbindung kann längere Werte bereits auf 8000 Bytes kürzen; Überlänge daher vor dem Aufruf am ursprünglichen Wert prüfen. Kein SQL-Default; Argument syntaktisch erforderlich. |
--
-- ## Ergebnisse
--
-- Genau eine Zeile mit IsValid bit NOT NULL, ValidationCode varchar(32) NOT NULL, Major/Minor/Patch/PreRelease/BuildMetadata/CanonicalVersion jeweils varchar(8000) NULL. Bei gültiger Eingabe sind Major/Minor/Patch und CanonicalVersion gefüllt; fehlende optionale Teile sind NULL. CanonicalVersion ist die ursprüngliche gültige Eingabe unverändert, keine neue Normalform. Bei ungültiger Eingabe sind sämtliche sechs Textfelder NULL.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_validation.TVF_ParseSemanticVersion('1.2.3-alpha.1+build.007');
-- -- IsValid=1, ValidationCode=VALID; BuildMetadata bleibt build.007.
-- SELECT IsValid,ValidationCode FROM toolbelt_validation.TVF_ParseSemanticVersion(NULL);
-- -- Genau eine Zeile mit NULL_INPUT.
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT auf dieser TVF und die im tatsächlichen Ownership-/Datenbankkontext erforderlichen Rechte der internen Funktionsaufrufe. Keine automatische Rechtevergabe, Serverrechte, EXECUTE-AS-Ausweitung oder Quelltabellenabfrage. Zentrale dreiteilige Aufrufe erfordern den entsprechenden Datenbankzugriff; ein Skill erteilt keine Rechte.
--
-- ## Ressourcenbedarf
--
-- Multi-statement-TVF mit lokalen skalaren varchar-Puffern, Schleifen über punktgetrennte Pre-release-/Build-Identifier und einer Ergebnis-Tabellenvariablen. Arbeit abhängig von Eingabelänge und Identifierzahl bis zur Argumentgrenze; kein eigenes Timeout oder Zeilenbudget. Keine Zusage eines bestimmten Cardinality-Estimates oder einer Laufzeit.
--
-- ## Nebenwirkungen
--
-- Rein lesende Berechnung aus Argumenten und lokalen Werten; kein Zugriff auf Benutzertabellen/Systemkataloge, keine DML an persistenten Objekten, keine Dateien oder externen Aufrufe. Ausgabe erzeugt keine Installation, Indexanlage oder Zustandsänderung.
--
-- ## Fehlerbehandlung
--
-- Der Parser liefert genau einen ersten Validierungsbefund: VALID (gültig), NULL_INPUT (NULL), EMPTY_INPUT (leer), INVALID_CHARACTER (Zeichen außerhalb des globalen ASCII-Zeichenvorrats), BUILD_FORMAT (mehrfaches Plus oder leere/ungültige Build-Identifier), EMPTY_BUILD (Plus ohne Buildteil), EMPTY_PRERELEASE (Bindestrich ohne Pre-release-Teil), CORE_FORMAT (nicht drei nichtleere reine Ziffernkomponenten), CORE_LEADING_ZERO (führende Core-Null), PRERELEASE_FORMAT (leerer/ungültiger Pre-release-Identifier), PRERELEASE_LEADING_ZERO (mehrstelliger rein numerischer Pre-release-Identifier mit führender Null). Die Prüf-Reihenfolge ist globaler Input/Zeichenvorrat, Buildabtrennung, Pre-release-Abtrennung, Core, Pre-release-Identifier und Build-Identifier. Vergleich und SortKey geben bei ungültigem Parserstatus NULL statt dieses Statuscodes aus; für Diagnosen den Parser separat verwenden. SQL-Typbindungs-, Ressourcen- und Enginefehler sind keine fachlichen Validierungscodes und werden nicht allgemein abgefangen.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag. Vorhandene fachliche Nachweise dürfen nur bei unveränderter Bindung wiederverwendet werden; diese passiven Skillkommentare sind keine neue native Qualifikation. Kein Versionsbereich-/Wildcard-/v-Präfix-/Paketmanagerparser, keine automatische Bereinigung und keine Eindeutigkeit bei gleicher SemVer-Präzedenz. Die Argumentgrenze gilt nach SQL-Bindung; fehlende Originalbytes längerer Eingaben sind nicht rekonstruierbar.
-- OBJECT_USAGE_SKILL:END
AS
BEGIN
    DECLARE
          @Code       varchar(32) = 'VALID'
        , @InputLength int = DATALENGTH(@Version)
        , @PlusPos      int
        , @DashPos      int
        , @Dot1         int
        , @Dot2         int
        , @Precedence   varchar(8000)
        , @Major        varchar(8000)
        , @Minor        varchar(8000)
        , @Patch        varchar(8000)
        , @PreRelease   varchar(8000)
        , @Build        varchar(8000)
        , @Position     int
        , @NextDot      int
        , @Identifier   varchar(8000);

    IF @Version IS NULL
        SET @Code = 'NULL_INPUT';
    ELSE IF @InputLength = 0
        SET @Code = 'EMPTY_INPUT';
    ELSE IF @Version COLLATE Latin1_General_100_BIN2
                 LIKE '%[^0-9A-Za-z.+-]%' COLLATE Latin1_General_100_BIN2
        SET @Code = 'INVALID_CHARACTER';

    IF @Code = 'VALID'
    BEGIN
        SET @PlusPos = CHARINDEX('+', @Version COLLATE Latin1_General_100_BIN2);

        IF @PlusPos > 0
           AND CHARINDEX
               (
                   '+',
                   @Version COLLATE Latin1_General_100_BIN2,
                   @PlusPos + 1
               ) > 0
            SET @Code = 'BUILD_FORMAT';
        ELSE
        BEGIN
            SET @Precedence =
                CASE WHEN @PlusPos = 0
                    THEN @Version
                    ELSE LEFT(@Version, @PlusPos - 1)
                END;
            SET @Build =
                CASE WHEN @PlusPos = 0
                    THEN NULL
                    ELSE SUBSTRING
                         (
                             @Version,
                             @PlusPos + 1,
                             @InputLength - @PlusPos
                         )
                END;

            IF @PlusPos > 0 AND DATALENGTH(@Build) = 0
                SET @Code = 'EMPTY_BUILD';
        END;
    END;

    IF @Code = 'VALID'
    BEGIN
        SET @DashPos =
            CHARINDEX('-', @Precedence COLLATE Latin1_General_100_BIN2);
        SET @PreRelease =
            CASE WHEN @DashPos = 0
                THEN NULL
                ELSE SUBSTRING
                     (
                         @Precedence,
                         @DashPos + 1,
                         DATALENGTH(@Precedence) - @DashPos
                     )
            END;
        SET @Precedence =
            CASE WHEN @DashPos = 0
                THEN @Precedence
                ELSE LEFT(@Precedence, @DashPos - 1)
            END;

        IF @DashPos > 0 AND DATALENGTH(@PreRelease) = 0
            SET @Code = 'EMPTY_PRERELEASE';
    END;

    IF @Code = 'VALID'
    BEGIN
        SET @Dot1 = CHARINDEX('.', @Precedence COLLATE Latin1_General_100_BIN2);
        SET @Dot2 =
            CASE WHEN @Dot1 = 0 THEN 0
                 ELSE CHARINDEX
                      (
                          '.',
                          @Precedence COLLATE Latin1_General_100_BIN2,
                          @Dot1 + 1
                      )
            END;

        IF @Dot1 = 0
           OR @Dot2 = 0
           OR CHARINDEX
              (
                  '.',
                  @Precedence COLLATE Latin1_General_100_BIN2,
                  @Dot2 + 1
              ) > 0
            SET @Code = 'CORE_FORMAT';
        ELSE
        BEGIN
            SET @Major = LEFT(@Precedence, @Dot1 - 1);
            SET @Minor = SUBSTRING(@Precedence, @Dot1 + 1, @Dot2 - @Dot1 - 1);
            SET @Patch = SUBSTRING
            (
                @Precedence,
                @Dot2 + 1,
                DATALENGTH(@Precedence) - @Dot2
            );

            IF DATALENGTH(@Major) = 0
               OR DATALENGTH(@Minor) = 0
               OR DATALENGTH(@Patch) = 0
               OR @Major COLLATE Latin1_General_100_BIN2
                      LIKE '%[^0-9]%' COLLATE Latin1_General_100_BIN2
               OR @Minor COLLATE Latin1_General_100_BIN2
                      LIKE '%[^0-9]%' COLLATE Latin1_General_100_BIN2
               OR @Patch COLLATE Latin1_General_100_BIN2
                      LIKE '%[^0-9]%' COLLATE Latin1_General_100_BIN2
                SET @Code = 'CORE_FORMAT';
            ELSE IF (DATALENGTH(@Major) > 1 AND LEFT(@Major, 1) = '0')
                 OR (DATALENGTH(@Minor) > 1 AND LEFT(@Minor, 1) = '0')
                 OR (DATALENGTH(@Patch) > 1 AND LEFT(@Patch, 1) = '0')
                SET @Code = 'CORE_LEADING_ZERO';
        END;
    END;

    IF @Code = 'VALID' AND @PreRelease IS NOT NULL
    BEGIN
        IF RIGHT(@PreRelease, 1) = '.'
            SET @Code = 'PRERELEASE_FORMAT';
        SET @Position = 1;
        WHILE @Position <= DATALENGTH(@PreRelease) AND @Code = 'VALID'
        BEGIN
            SET @NextDot = CHARINDEX
            (
                '.',
                @PreRelease COLLATE Latin1_General_100_BIN2,
                @Position
            );
            SET @Identifier =
                CASE WHEN @NextDot = 0
                    THEN SUBSTRING
                         (
                             @PreRelease,
                             @Position,
                             DATALENGTH(@PreRelease) - @Position + 1
                         )
                    ELSE SUBSTRING
                         (
                             @PreRelease,
                             @Position,
                             @NextDot - @Position
                         )
                END;

            IF DATALENGTH(@Identifier) = 0
               OR @Identifier COLLATE Latin1_General_100_BIN2
                      LIKE '%[^0-9A-Za-z-]%' COLLATE Latin1_General_100_BIN2
                SET @Code = 'PRERELEASE_FORMAT';
            ELSE IF @Identifier COLLATE Latin1_General_100_BIN2
                          NOT LIKE '%[^0-9]%' COLLATE Latin1_General_100_BIN2
                    AND DATALENGTH(@Identifier) > 1
                    AND LEFT(@Identifier, 1) = '0'
                SET @Code = 'PRERELEASE_LEADING_ZERO';

            SET @Position =
                CASE WHEN @NextDot = 0
                    THEN DATALENGTH(@PreRelease) + 1
                    ELSE @NextDot + 1
                END;
        END;
    END;

    IF @Code = 'VALID' AND @Build IS NOT NULL
    BEGIN
        IF RIGHT(@Build, 1) = '.'
            SET @Code = 'BUILD_FORMAT';
        SET @Position = 1;
        WHILE @Position <= DATALENGTH(@Build) AND @Code = 'VALID'
        BEGIN
            SET @NextDot = CHARINDEX
            (
                '.',
                @Build COLLATE Latin1_General_100_BIN2,
                @Position
            );
            SET @Identifier =
                CASE WHEN @NextDot = 0
                    THEN SUBSTRING
                         (
                             @Build,
                             @Position,
                             DATALENGTH(@Build) - @Position + 1
                         )
                    ELSE SUBSTRING
                         (
                             @Build,
                             @Position,
                             @NextDot - @Position
                         )
                END;

            IF DATALENGTH(@Identifier) = 0
               OR @Identifier COLLATE Latin1_General_100_BIN2
                      LIKE '%[^0-9A-Za-z-]%' COLLATE Latin1_General_100_BIN2
                SET @Code = 'BUILD_FORMAT';

            SET @Position =
                CASE WHEN @NextDot = 0
                    THEN DATALENGTH(@Build) + 1
                    ELSE @NextDot + 1
                END;
        END;
    END;

    INSERT INTO @Result
    (
          IsValid
        , ValidationCode
        , Major
        , Minor
        , Patch
        , PreRelease
        , BuildMetadata
        , CanonicalVersion
    )
    VALUES
    (
          CASE WHEN @Code = 'VALID' THEN 1 ELSE 0 END
        , @Code
        , CASE WHEN @Code = 'VALID' THEN @Major END
        , CASE WHEN @Code = 'VALID' THEN @Minor END
        , CASE WHEN @Code = 'VALID' THEN @Patch END
        , CASE WHEN @Code = 'VALID' THEN @PreRelease END
        , CASE WHEN @Code = 'VALID' THEN @Build END
        , CASE WHEN @Code = 'VALID' THEN @Version END
    );

    RETURN;
END;
GO
