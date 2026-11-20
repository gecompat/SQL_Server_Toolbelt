-- ============================================================================
-- Objekt:       toolbelt_validation.TVF_CompareSemanticVersion
-- Zweck:        Zwei strikte Semantic-Version-2.0.0-Werte vergleichen
-- Resultset:    genau eine Zeile; ComparisonResult smallint
-- Fehlerwert:   NULL, wenn mindestens eine Eingabe ungültig ist
-- Performance:  kanonischer relationaler Kern für APPLY
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_validation].[TVF_CompareSemanticVersion]
(
      @LeftVersion  varchar(8000)
    , @RightVersion varchar(8000)
)
RETURNS TABLE
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-semver-tvf-comparesemanticversion"
-- description: "Vergleicht zwei gültige SemVer-Versionen nach Präzedenz als relationaler Kern."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.validation.semantic-version"
-- schema_name: "toolbelt_validation"
-- object_name: "TVF_CompareSemanticVersion"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@LeftVersion", "sql_type": "varchar(8000)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": true, "description": "ASCII-SemVertext als varchar(8000): Major.Minor.Patch mit optionalem -PreRelease und +BuildMetadata. Corezahlen und ausschließlich numerische Pre-release-Identifier ohne führende Nullen außer 0; Build-Identifier dürfen führende Nullen besitzen. Nichtleere punktgetrennte Identifier bestehen aus ASCII-Buchstaben, Ziffern oder Bindestrich. Kein v-Präfix, Trimmen, Whitespace oder Normalisieren. NULL und leer sind zulässige Prüfargumente, aber keine gültige Version. Große Zahlen bleiben Text, kein int-/bigint-Limit. Die SQL-Argumentbindung kann längere Werte bereits auf 8000 Bytes kürzen; Überlänge daher vor dem Aufruf am ursprünglichen Wert prüfen. Kein SQL-Default; Argument syntaktisch erforderlich."}, {"name": "@RightVersion", "sql_type": "varchar(8000)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": true, "description": "ASCII-SemVertext als varchar(8000): Major.Minor.Patch mit optionalem -PreRelease und +BuildMetadata. Corezahlen und ausschließlich numerische Pre-release-Identifier ohne führende Nullen außer 0; Build-Identifier dürfen führende Nullen besitzen. Nichtleere punktgetrennte Identifier bestehen aus ASCII-Buchstaben, Ziffern oder Bindestrich. Kein v-Präfix, Trimmen, Whitespace oder Normalisieren. NULL und leer sind zulässige Prüfargumente, aber keine gültige Version. Große Zahlen bleiben Text, kein int-/bigint-Limit. Die SQL-Argumentbindung kann längere Werte bereits auf 8000 Bytes kürzen; Überlänge daher vor dem Aufruf am ursprünglichen Wert prüfen. Kein SQL-Default; Argument syntaktisch erforderlich."}]
-- source_paths: ["Modules/toolbelt.validation.semantic-version/Source/TVF_CompareSemanticVersion.sql", "Modules/toolbelt.validation.semantic-version/Source/TVF_ParseSemanticVersion.sql"]
-- review_status: "verified"
-- source_module_version: "1.1.0"
-- ---
--
-- # TVF_CompareSemanticVersion
--
-- ## Zweck und Einsatzfälle
--
-- Vergleicht zwei gültige SemVer-Versionen nach Präzedenz als relationaler Kern. Für mengenorientierte Vergleiche/Sortierung sind die relationalen TVFs die kanonischen Einstiegspunkte; SVFs dienen einzelnen Komfortaufrufen.
--
-- ## Voraussetzungen
--
-- Installiertes T-SQL-Modul auf unterstütztem SQL Server 2019/2022/2025 unter Windows oder Linux. Lokal und zentral gemäß vorhandenem Deploymentvertrag; Abhängigkeiten innerhalb des Moduls müssen vorhanden sein. Keine CLR-, Root-, Datenquellen- oder Netzwerkanforderung. Die relevanten Zeichenvergleiche verwenden explizit Latin1_General_100_BIN2.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@LeftVersion` | `varchar(8000)` | `kein Default` | ASCII-SemVertext als varchar(8000): Major.Minor.Patch mit optionalem -PreRelease und +BuildMetadata. Corezahlen und ausschließlich numerische Pre-release-Identifier ohne führende Nullen außer 0; Build-Identifier dürfen führende Nullen besitzen. Nichtleere punktgetrennte Identifier bestehen aus ASCII-Buchstaben, Ziffern oder Bindestrich. Kein v-Präfix, Trimmen, Whitespace oder Normalisieren. NULL und leer sind zulässige Prüfargumente, aber keine gültige Version. Große Zahlen bleiben Text, kein int-/bigint-Limit. Die SQL-Argumentbindung kann längere Werte bereits auf 8000 Bytes kürzen; Überlänge daher vor dem Aufruf am ursprünglichen Wert prüfen. Kein SQL-Default; Argument syntaktisch erforderlich. |
-- | `@RightVersion` | `varchar(8000)` | `kein Default` | ASCII-SemVertext als varchar(8000): Major.Minor.Patch mit optionalem -PreRelease und +BuildMetadata. Corezahlen und ausschließlich numerische Pre-release-Identifier ohne führende Nullen außer 0; Build-Identifier dürfen führende Nullen besitzen. Nichtleere punktgetrennte Identifier bestehen aus ASCII-Buchstaben, Ziffern oder Bindestrich. Kein v-Präfix, Trimmen, Whitespace oder Normalisieren. NULL und leer sind zulässige Prüfargumente, aber keine gültige Version. Große Zahlen bleiben Text, kein int-/bigint-Limit. Die SQL-Argumentbindung kann längere Werte bereits auf 8000 Bytes kürzen; Überlänge daher vor dem Aufruf am ursprünglichen Wert prüfen. Kein SQL-Default; Argument syntaktisch erforderlich. |
--
-- ## Ergebnisse
--
-- Genau eine Zeile mit ComparisonResult smallint NULL: -1 bedeutet links vor rechts, 0 gleiche Präzedenz, 1 links nach rechts. Ist mindestens eine Eingabe ungültig oder NULL, ist ComparisonResult NULL. Build-Metadaten werden ignoriert. Corezahlen werden anhand Ziffernlänge und BIN2-Text verglichen. Release steht nach Pre-release; numerische Pre-release-Identifier vor nichtnumerischen. Sonst entscheidet die erste abweichende Kennung, bei gleichem Präfix die längere Identifierfolge.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_validation.TVF_CompareSemanticVersion('1.0.0-alpha.2','1.0.0-alpha.10');
-- -- ComparisonResult=-1.
-- SELECT * FROM toolbelt_validation.TVF_CompareSemanticVersion('1.0.0+one','1.0.0+two');
-- -- ComparisonResult=0, Builddaten sind kein Tie-Breaker.
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT auf dieser TVF und die im tatsächlichen Ownership-/Datenbankkontext erforderlichen Rechte der internen Funktionsaufrufe. Keine automatische Rechtevergabe, Serverrechte, EXECUTE-AS-Ausweitung oder Quelltabellenabfrage. Zentrale dreiteilige Aufrufe erfordern den entsprechenden Datenbankzugriff; ein Skill erteilt keine Rechte.
--
-- ## Ressourcenbedarf
--
-- Inline-TVF über zwei Parseraufrufe und eine aus vier Ziffernkreuzprodukten auf 8000 Positionen begrenzte Positionsrelation. Tokenzerlegung, FULL OUTER JOIN nach Ordinal und erste Differenz können je Eingabe Arbeit und Zwischenergebnisse erzeugen. Optimizerplan und tatsächliche Materialisierung sind nicht zugesichert; bei Mengendaten CROSS/OUTER APPLY bevorzugen, nicht unverifiziert konstante Kosten annehmen.
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
RETURN
(
    WITH
    Digits (Digit) AS
    (
        SELECT Digit
        FROM
        (
            VALUES
                  (0), (1), (2), (3), (4)
                , (5), (6), (7), (8), (9)
        ) AS values_0_to_9(Digit)
    ),
    Positions (Position) AS
    (
        SELECT
            thousands.Digit * 1000
            + hundreds.Digit * 100
            + tens.Digit * 10
            + ones.Digit
            + 1
        FROM Digits AS thousands
        CROSS JOIN Digits AS hundreds
        CROSS JOIN Digits AS tens
        CROSS JOIN Digits AS ones
        WHERE thousands.Digit * 1000
              + hundreds.Digit * 100
              + tens.Digit * 10
              + ones.Digit < 8000
    ),
    LeftParsed AS
    (
        SELECT *
        FROM toolbelt_validation.TVF_ParseSemanticVersion(@LeftVersion)
    ),
    RightParsed AS
    (
        SELECT *
        FROM toolbelt_validation.TVF_ParseSemanticVersion(@RightVersion)
    ),
    Parsed AS
    (
        SELECT
              LeftIsValid = left_version.IsValid
            , LeftMajor = left_version.Major
            , LeftMinor = left_version.Minor
            , LeftPatch = left_version.Patch
            , LeftPreRelease = left_version.PreRelease
            , RightIsValid = right_version.IsValid
            , RightMajor = right_version.Major
            , RightMinor = right_version.Minor
            , RightPatch = right_version.Patch
            , RightPreRelease = right_version.PreRelease
        FROM LeftParsed AS left_version
        CROSS JOIN RightParsed AS right_version
    ),
    CoreComparison AS
    (
        SELECT
              parsed.*
            , CoreResult =
                  CONVERT
                  (
                        smallint
                      , CASE
                            WHEN DATALENGTH(LeftMajor)
                                   < DATALENGTH(RightMajor) THEN -1
                            WHEN DATALENGTH(LeftMajor)
                                   > DATALENGTH(RightMajor) THEN 1
                            WHEN LeftMajor COLLATE Latin1_General_100_BIN2
                                   < RightMajor COLLATE Latin1_General_100_BIN2
                                THEN -1
                            WHEN LeftMajor COLLATE Latin1_General_100_BIN2
                                   > RightMajor COLLATE Latin1_General_100_BIN2
                                THEN 1
                            WHEN DATALENGTH(LeftMinor)
                                   < DATALENGTH(RightMinor) THEN -1
                            WHEN DATALENGTH(LeftMinor)
                                   > DATALENGTH(RightMinor) THEN 1
                            WHEN LeftMinor COLLATE Latin1_General_100_BIN2
                                   < RightMinor COLLATE Latin1_General_100_BIN2
                                THEN -1
                            WHEN LeftMinor COLLATE Latin1_General_100_BIN2
                                   > RightMinor COLLATE Latin1_General_100_BIN2
                                THEN 1
                            WHEN DATALENGTH(LeftPatch)
                                   < DATALENGTH(RightPatch) THEN -1
                            WHEN DATALENGTH(LeftPatch)
                                   > DATALENGTH(RightPatch) THEN 1
                            WHEN LeftPatch COLLATE Latin1_General_100_BIN2
                                   < RightPatch COLLATE Latin1_General_100_BIN2
                                THEN -1
                            WHEN LeftPatch COLLATE Latin1_General_100_BIN2
                                   > RightPatch COLLATE Latin1_General_100_BIN2
                                THEN 1
                            ELSE 0
                        END
                  )
        FROM Parsed AS parsed
    ),
    LeftTokens AS
    (
        SELECT
              Ordinal = ROW_NUMBER() OVER (ORDER BY positions.Position)
            , Identifier = token.Identifier
            , IsNumeric =
                  CONVERT
                  (
                        bit
                      , CASE
                            WHEN token.Identifier
                                     COLLATE Latin1_General_100_BIN2
                                     NOT LIKE '%[^0-9]%'
                                     COLLATE Latin1_General_100_BIN2
                                THEN 1
                            ELSE 0
                        END
                  )
        FROM CoreComparison AS compared
        CROSS JOIN Positions AS positions
        CROSS APPLY
        (
            SELECT NextDot = CHARINDEX
            (
                  '.'
                , compared.LeftPreRelease
                      COLLATE Latin1_General_100_BIN2
                , positions.Position
            )
        ) AS boundary
        CROSS APPLY
        (
            SELECT Identifier =
                CASE
                    WHEN boundary.NextDot = 0
                        THEN SUBSTRING
                             (
                                   compared.LeftPreRelease
                                 , positions.Position
                                 , DATALENGTH(compared.LeftPreRelease)
                                   - positions.Position + 1
                             )
                    ELSE SUBSTRING
                         (
                               compared.LeftPreRelease
                             , positions.Position
                             , boundary.NextDot - positions.Position
                         )
                END
        ) AS token
        WHERE compared.LeftPreRelease IS NOT NULL
          AND positions.Position <= DATALENGTH(compared.LeftPreRelease)
          AND
          (
              positions.Position = 1
              OR SUBSTRING
                 (
                       compared.LeftPreRelease
                     , positions.Position - 1
                     , 1
                 ) = '.'
          )
    ),
    RightTokens AS
    (
        SELECT
              Ordinal = ROW_NUMBER() OVER (ORDER BY positions.Position)
            , Identifier = token.Identifier
            , IsNumeric =
                  CONVERT
                  (
                        bit
                      , CASE
                            WHEN token.Identifier
                                     COLLATE Latin1_General_100_BIN2
                                     NOT LIKE '%[^0-9]%'
                                     COLLATE Latin1_General_100_BIN2
                                THEN 1
                            ELSE 0
                        END
                  )
        FROM CoreComparison AS compared
        CROSS JOIN Positions AS positions
        CROSS APPLY
        (
            SELECT NextDot = CHARINDEX
            (
                  '.'
                , compared.RightPreRelease
                      COLLATE Latin1_General_100_BIN2
                , positions.Position
            )
        ) AS boundary
        CROSS APPLY
        (
            SELECT Identifier =
                CASE
                    WHEN boundary.NextDot = 0
                        THEN SUBSTRING
                             (
                                   compared.RightPreRelease
                                 , positions.Position
                                 , DATALENGTH(compared.RightPreRelease)
                                   - positions.Position + 1
                             )
                    ELSE SUBSTRING
                         (
                               compared.RightPreRelease
                             , positions.Position
                             , boundary.NextDot - positions.Position
                         )
                END
        ) AS token
        WHERE compared.RightPreRelease IS NOT NULL
          AND positions.Position <= DATALENGTH(compared.RightPreRelease)
          AND
          (
              positions.Position = 1
              OR SUBSTRING
                 (
                       compared.RightPreRelease
                     , positions.Position - 1
                     , 1
                 ) = '.'
          )
    ),
    TokenPairs AS
    (
        SELECT
              Ordinal = COALESCE(left_token.Ordinal, right_token.Ordinal)
            , TokenResult =
                  CONVERT
                  (
                        smallint
                      , CASE
                            WHEN left_token.Ordinal IS NULL THEN -1
                            WHEN right_token.Ordinal IS NULL THEN 1
                            WHEN left_token.IsNumeric = 1
                             AND right_token.IsNumeric = 0 THEN -1
                            WHEN left_token.IsNumeric = 0
                             AND right_token.IsNumeric = 1 THEN 1
                            WHEN left_token.IsNumeric = 1
                             AND DATALENGTH(left_token.Identifier)
                                   < DATALENGTH(right_token.Identifier) THEN -1
                            WHEN left_token.IsNumeric = 1
                             AND DATALENGTH(left_token.Identifier)
                                   > DATALENGTH(right_token.Identifier) THEN 1
                            WHEN left_token.Identifier
                                     COLLATE Latin1_General_100_BIN2
                                   < right_token.Identifier
                                     COLLATE Latin1_General_100_BIN2 THEN -1
                            WHEN left_token.Identifier
                                     COLLATE Latin1_General_100_BIN2
                                   > right_token.Identifier
                                     COLLATE Latin1_General_100_BIN2 THEN 1
                            ELSE 0
                        END
                  )
        FROM LeftTokens AS left_token
        FULL OUTER JOIN RightTokens AS right_token
            ON right_token.Ordinal = left_token.Ordinal
    ),
    FirstTokenDifference AS
    (
        SELECT TOP (1) TokenResult
        FROM TokenPairs
        WHERE TokenResult <> 0
        ORDER BY Ordinal
    )
    SELECT ComparisonResult =
        CONVERT
        (
              smallint
            , CASE
                  WHEN compared.LeftIsValid = 0
                    OR compared.RightIsValid = 0
                      THEN NULL
                  WHEN compared.CoreResult <> 0
                      THEN compared.CoreResult
                  WHEN compared.LeftPreRelease IS NULL
                   AND compared.RightPreRelease IS NULL
                      THEN 0
                  WHEN compared.LeftPreRelease IS NULL
                      THEN 1
                  WHEN compared.RightPreRelease IS NULL
                      THEN -1
                  ELSE COALESCE(difference.TokenResult, 0)
              END
        )
    FROM CoreComparison AS compared
    OUTER APPLY
    (
        SELECT TokenResult
        FROM FirstTokenDifference
    ) AS difference
);
GO
