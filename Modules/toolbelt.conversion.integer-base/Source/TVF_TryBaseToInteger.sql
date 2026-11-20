-- SQL Server Toolbelt
-- Objekt: toolbelt_conversion.TVF_TryBaseToInteger
-- Vertrag: Relationaler Kern für die strikt kanonische bigint-Decodierung.

CREATE OR ALTER FUNCTION [toolbelt_conversion].[TVF_TryBaseToInteger]
(
      @EncodedValue varchar(65)
    , @Alphabet varchar(93)
)
RETURNS TABLE
WITH SCHEMABINDING
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-conversion-tvf-trybasetointeger"
-- description: "Decodiert einen Text anhand des angegebenen Alphabets in bigint."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.conversion.integer-base"
-- schema_name: "toolbelt_conversion"
-- object_name: "TVF_TryBaseToInteger"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@EncodedValue", "sql_type": "varchar(65)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Zahlentext aus dem angegebenen Alphabet, höchstens 65 varchar-Bytes; optional genau ein führendes - als Vorzeichen. Keine führenden Nullziffern bei mehrstelligen Werten, kein negatives Null und keine Leerzeichen-Normalisierung. Alle Zeichen müssen Alphabetziffern sein; Betrag muss in bigint passen. Leer, NULL, ungültige Lexik oder Überlauf ergibt NULL."}, {"name": "@Alphabet", "sql_type": "varchar(93)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "2..93 verschiedene einbyteige ASCII-Zeichen aus Codes 33..126, ohne Minuszeichen -. Reihenfolge definiert die Ziffernwerte ab 0; das erste Zeichen ist die Nullziffer. Binärer, case-sensitiver Vergleich; keine Duplikate oder Leerzeichen. NULL/ungültiges Alphabet ergibt NULL."}]
-- source_paths: ["Modules/toolbelt.conversion.integer-base/Source/TVF_TryBaseToInteger.sql"]
-- review_status: "verified"
-- source_module_version: "1.1.0"
-- ---
--
-- # TVF_TryBaseToInteger
--
-- ## Zweck und Einsatzfälle
--
-- Decodiert einen Text anhand des angegebenen Alphabets in bigint. Hexadezimal ist ein gewähltes Alphabet wie 0123456789ABCDEF, kein eigener Binär-/0x-Parser. Für APPLY-basierte Verarbeitung und mengenorientierte Aufrufe.
--
-- ## Voraussetzungen
--
-- SQL Server 2019/2022/2025, Windows/Linux, CL150/160/170. Modul installiert; reine T-SQL-Funktionen ohne CLR, externe Datenquelle oder Systemkatalogabfrage. Beide Argumente positionsbezogen übergeben. Keine SQL-Defaults.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@EncodedValue` | `varchar(65)` | kein Default | Zahlentext aus dem angegebenen Alphabet, höchstens 65 varchar-Bytes; optional genau ein führendes - als Vorzeichen. Keine führenden Nullziffern bei mehrstelligen Werten, kein negatives Null und keine Leerzeichen-Normalisierung. Alle Zeichen müssen Alphabetziffern sein; Betrag muss in bigint passen. Leer, NULL, ungültige Lexik oder Überlauf ergibt NULL. |
-- | `@Alphabet` | `varchar(93)` | kein Default | 2..93 verschiedene einbyteige ASCII-Zeichen aus Codes 33..126, ohne Minuszeichen -. Reihenfolge definiert die Ziffernwerte ab 0; das erste Zeichen ist die Nullziffer. Binärer, case-sensitiver Vergleich; keine Duplikate oder Leerzeichen. NULL/ungültiges Alphabet ergibt NULL. |
--
-- ## Ergebnisse
--
-- Genau eine Zeile mit DecodedValue bigint. NULL bei NULL/Leerwert, ungültigem Alphabet, unbekannten Ziffern, nicht kanonischer Darstellung oder bigint-Überlauf. Kein Unterschied zwischen diesen NULL-Gründen und kein zusätzliches Statusfeld.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_conversion.TVF_TryBaseToInteger('FF','0123456789ABCDEF');
-- -- 255
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT für SELECT-Aufrufe; REFERENCES für entsprechende Referenzverwendungen. Keine Rechtevergabe oder Änderung der Ausführungsidentität. Cross-Database-Zuordnung bleibt beim Caller.
--
-- ## Ressourcenbedarf
--
-- Alphabetprüfung auf höchstens 93 Positionen einschließlich binärer Eindeutigkeitsprüfung. Der relationale Kern nutzt eine rekursive CTE: höchstens 65 gebundene Textpositionen einschließlich möglichem Vorzeichen. decimal(38,0) hält Betrag und Zwischenwerte; vor jeder Multiply/Add-Stufe wird die vorzeichenabhängige bigint-Grenze geprüft. Kein unbeschränktes Streaming; skalare Wrapper rufen die gleiche TVF auf.
--
-- ## Nebenwirkungen
--
-- Rein lesend ohne Tabellen-, Datei-, Netzwerk-, Trust- oder Konfigurationsänderung. Keine Änderung von Caller-Transaktionen oder Daten.
--
-- ## Fehlerbehandlung
--
-- Fachlich ungültige gebundene Argumente werden als NULL abgebildet. Nicht vorgesehene Engine-/Typbindungsfehler und vom Caller zu eng gewählte Rekursionsgrenzen bleiben Fehler. Kein Retry und kein automatischer Wechsel des Alphabets.
--
-- ## Aussagegrenzen
--
-- ASCII-Alphabet mit Basis 2..93, feste Reihenfolge und binär verschiedener Ziffernidentität. Minus ist ausschließlich Vorzeichen, nicht Alphabetziffer. Ein Pluszeichen ist kein zusätzlich akzeptiertes Vorzeichen; es kann jedoch reguläre Ziffer sein, wenn im gewählten Alphabet enthalten. Keine Trimmung, keine Gruppierungszeichen und kein implizites 0x-Präfix. Decoder verlangt die kanonische Darstellung: nur die einzelne Nullziffer für 0, keine führenden Nullziffern und kein negatives Null. Vorzeichenabhängige Grenzwerte sind 9223372036854775807 bzw. Betrag 9223372036854775808. Der Vertrag betrifft gebundene SQL-Parameter; vor der Bindung konvertierte oder gekürzte Originaldaten werden nicht nachträglich erkannt.
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
        SELECT tens.Digit * 10 + ones.Digit + 1
        FROM Digits AS tens
        CROSS JOIN Digits AS ones
        WHERE tens.Digit * 10 + ones.Digit + 1 <= 93
    ),
    Input AS
    (
        SELECT
              Base = DATALENGTH(@Alphabet)
            , InputLength = DATALENGTH(@EncodedValue)
            , IsNegative =
                  CONVERT
                  (
                        bit
                      , CASE WHEN LEFT(@EncodedValue, 1) = '-' THEN 1 ELSE 0 END
                  )
            , StartPosition =
                  CASE WHEN LEFT(@EncodedValue, 1) = '-' THEN 2 ELSE 1 END
    ),
    Validated AS
    (
        SELECT
              input.Base
            , input.InputLength
            , input.IsNegative
            , input.StartPosition
            , MagnitudeLimit =
                  CONVERT
                  (
                        decimal(38, 0)
                      , CASE
                            WHEN input.IsNegative = 1
                                THEN 9223372036854775808
                            ELSE 9223372036854775807
                        END
                  )
            , IsValid =
                  CONVERT
                  (
                        bit
                      , CASE
                            WHEN @EncodedValue IS NULL
                              OR @Alphabet IS NULL
                              OR input.Base < 2
                              OR input.Base > 93
                              OR input.InputLength = 0
                              OR
                                 (
                                     input.IsNegative = 1
                                     AND input.InputLength = 1
                                 )
                              OR
                                 (
                                     input.InputLength - input.StartPosition + 1 > 1
                                     AND SUBSTRING
                                         (
                                               @EncodedValue
                                             , input.StartPosition
                                             , 1
                                         ) COLLATE Latin1_General_100_BIN2
                                         = SUBSTRING(@Alphabet, 1, 1)
                                             COLLATE Latin1_General_100_BIN2
                                 )
                              OR
                                 (
                                     input.IsNegative = 1
                                     AND input.InputLength
                                           - input.StartPosition + 1 = 1
                                     AND SUBSTRING
                                         (
                                               @EncodedValue
                                             , input.StartPosition
                                             , 1
                                         ) COLLATE Latin1_General_100_BIN2
                                         = SUBSTRING(@Alphabet, 1, 1)
                                             COLLATE Latin1_General_100_BIN2
                                 )
                              OR EXISTS
                                 (
                                     SELECT 1
                                     FROM Positions
                                     WHERE Position <= input.Base
                                       AND
                                       (
                                           DATALENGTH
                                           (
                                               SUBSTRING
                                               (
                                                     @Alphabet
                                                   , Position
                                                   , 1
                                               )
                                           ) <> 1
                                           OR ASCII
                                           (
                                               SUBSTRING
                                               (
                                                     @Alphabet
                                                   , Position
                                                   , 1
                                               )
                                           ) NOT BETWEEN 33 AND 126
                                           OR SUBSTRING
                                              (
                                                    @Alphabet
                                                  , Position
                                                  , 1
                                              ) = '-'
                                           OR CHARINDEX
                                              (
                                                  SUBSTRING
                                                  (
                                                        @Alphabet
                                                      , Position
                                                      , 1
                                                  ) COLLATE Latin1_General_100_BIN2
                                                , LEFT
                                                  (
                                                        @Alphabet
                                                      , Position - 1
                                                  ) COLLATE Latin1_General_100_BIN2
                                              ) > 0
                                       )
                                 )
                                THEN 0
                            ELSE 1
                        END
                  )
        FROM Input AS input
    ),
    Decoding AS
    (
        SELECT
              Position = CONVERT(int, validated.StartPosition)
            , validated.Base
            , validated.InputLength
            , validated.IsNegative
            , validated.MagnitudeLimit
            , IsValid = CONVERT(bit, validated.IsValid)
            , Accumulated = CONVERT(decimal(38, 0), 0)
        FROM Validated AS validated

        UNION ALL

        SELECT
              decoding.Position + 1
            , decoding.Base
            , decoding.InputLength
            , decoding.IsNegative
            , decoding.MagnitudeLimit
            , CONVERT
              (
                    bit
                  , CASE
                        WHEN digit.AlphabetPosition = 0
                          OR decoding.Accumulated
                             > FLOOR
                               (
                                   (
                                       decoding.MagnitudeLimit
                                       - digit.DigitValue
                                   ) / decoding.Base
                               )
                            THEN 0
                        ELSE 1
                    END
              )
            , CONVERT
              (
                    decimal(38, 0)
                  , CASE
                        WHEN digit.AlphabetPosition = 0
                          OR decoding.Accumulated
                             > FLOOR
                               (
                                   (
                                       decoding.MagnitudeLimit
                                       - digit.DigitValue
                                   ) / decoding.Base
                               )
                            THEN decoding.Accumulated
                        ELSE decoding.Accumulated * decoding.Base
                             + digit.DigitValue
                    END
              )
        FROM Decoding AS decoding
        CROSS APPLY
        (
            SELECT AlphabetPosition =
                CHARINDEX
                (
                    SUBSTRING(@EncodedValue, decoding.Position, 1)
                        COLLATE Latin1_General_100_BIN2
                  , @Alphabet COLLATE Latin1_General_100_BIN2
                )
        ) AS alphabet
        CROSS APPLY
        (
            SELECT
                  alphabet.AlphabetPosition
                , DigitValue =
                      CASE
                          WHEN alphabet.AlphabetPosition = 0 THEN 0
                          ELSE alphabet.AlphabetPosition - 1
                      END
        ) AS digit
        WHERE decoding.IsValid = 1
          AND decoding.Position <= decoding.InputLength
    ),
    Completed AS
    (
        SELECT TOP (1)
              decoding.Position
            , decoding.InputLength
            , decoding.IsNegative
            , decoding.IsValid
            , decoding.Accumulated
        FROM Decoding AS decoding
        WHERE decoding.IsValid = 0
           OR decoding.Position > decoding.InputLength
        ORDER BY decoding.Position DESC
    )
    SELECT DecodedValue =
        CONVERT
        (
              bigint
            , CASE
                  WHEN completed.IsValid = 0
                    OR completed.Position <= completed.InputLength
                      THEN NULL
                  WHEN completed.IsNegative = 1
                      THEN -completed.Accumulated
                  ELSE completed.Accumulated
              END
        )
    FROM Completed AS completed
);
GO
