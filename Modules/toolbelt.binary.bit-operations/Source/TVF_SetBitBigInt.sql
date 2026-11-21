-- ============================================================================
-- Objekt:          toolbelt_binary.TVF_SetBitBigInt
-- Zweck:           Setzt oder löscht ein Bit in einem bigint-Bitmuster.
-- Parameter:       @Value bigint, @BitOffset bigint, @BitValue int = 1
-- Resultset:       Value bigint, IsValid bit, ValidationCode tinyint
-- Dependencies:    keine Toolbelt-Module
-- Versionen:       SQL Server 2019, 2022 und 2025
-- Performance:     Inline TVF; konstante decimal(38,0)-Arithmetik
-- Einschränkungen: Offset 0 bezeichnet das Least Significant Bit.
-- ============================================================================

CREATE OR ALTER FUNCTION [toolbelt_binary].[TVF_SetBitBigInt]
(
      @Value     bigint
    , @BitOffset bigint
    , @BitValue  int = 1
)
RETURNS TABLE
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-binary-tvf-setbitbigint"
-- description: "Setzt oder löscht ein Bit an einer nullbasierten Position."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.binary.bit-operations"
-- schema_name: "toolbelt_binary"
-- object_name: "TVF_SetBitBigInt"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Value", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "SQL-bigint als vorzeichenbehaftetes 64-Bit-Zweierkomplement (-9223372036854775808 bis 9223372036854775807); negative Werte sind gültige Bitmuster. NULL liefert einen NULL-Wert."}, {"name": "@BitOffset", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Ganzzahl 0..63, inklusive: 0 ist das niederwertigste Bit, 63 das Vorzeichenbit. Andere Werte ergeben IsValid=0/ValidationCode=10; NULL ergibt NULL in Wert und Validierungsfeldern."}, {"name": "@BitValue", "sql_type": "int", "sql_default": "1", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ: 0 löscht das ausgewählte Bit; 1 setzt es (Default). Andere int-Werte ergeben IsValid=0/ValidationCode=11, sofern der Offset gültig ist. NULL ergibt NULL in Wert und Validierungsfeldern."}]
-- source_paths: ["Modules/toolbelt.binary.bit-operations/Source/TVF_SetBitBigInt.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # TVF_SetBitBigInt
--
-- ## Zweck und Einsatzfälle
--
-- Setzt oder löscht ein Bit an einer nullbasierten Position. Der Vertrag wird aus der bigint-/decimal-Arithmetik und den CASE-Guards der jeweiligen Source abgeleitet.
--
-- ## Voraussetzungen
--
-- SQL Server 2019 oder neuer. Alle Funktionsargumente positionsbezogen angeben; für einen deklarierten Default ist DEFAULT anzugeben. Kein CLR oder externer Provider erforderlich.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
-- |---|---|---|---|---|
-- | `@Value` | `bigint` | `kein Default` | Input | SQL-bigint als vorzeichenbehaftetes 64-Bit-Zweierkomplement (-9223372036854775808 bis 9223372036854775807); negative Werte sind gültige Bitmuster. NULL liefert einen NULL-Wert. |
-- | `@BitOffset` | `bigint` | `kein Default` | Input | Ganzzahl 0..63, inklusive: 0 ist das niederwertigste Bit, 63 das Vorzeichenbit. Andere Werte ergeben IsValid=0/ValidationCode=10; NULL ergibt NULL in Wert und Validierungsfeldern. |
-- | `@BitValue` | `int` | `1` | Input | Taxativ: 0 löscht das ausgewählte Bit; 1 setzt es (Default). Andere int-Werte ergeben IsValid=0/ValidationCode=11, sofern der Offset gültig ist. NULL ergibt NULL in Wert und Validierungsfeldern. |
--
-- ## Ergebnisse
--
-- Genau eine Zeile mit Value bigint, IsValid bit und ValidationCode tinyint. NULL in einem Argument ergibt drei NULL-Werte. Ungültiger Offset außerhalb 0..63 hat ValidationCode=10; sonst ungültiger BitValue außerhalb 0/1 hat Code=11. Beide Fehler liefern Value=NULL/IsValid=0. Gültiger Aufruf setzt oder löscht genau das Bit und liefert IsValid=1/Code=0. SQL-Default für BitValue ist 1.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_binary.TVF_SetBitBigInt(255, 3, 1);
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT oder REFERENCES auf der Funktion; Cross-Database-Zuordnung und Aufrufrechte gelten unverändert. Keine Rechtevergabe oder Ausführungsidentitätsänderung.
--
-- ## Ressourcenbedarf
--
-- Inline-TVF ohne persistente Zustandsänderung. Konstante begrenzte 64-Bit-/decimal(38,0)-Arithmetik; BitCount wertet acht Bytes set-basiert aus. Keine unbeschränkten Schleifen und keine pauschale Plan-/Laufzeitgarantie.
--
-- ## Nebenwirkungen
--
-- Read-only; keine Datei-, Netzwerk-, Tabellen- oder Konfigurationsänderung.
--
-- ## Fehlerbehandlung
--
-- NULL und fachlich ungültige Werte werden wie unten beschrieben als Ergebniswerte/Status abgebildet. SQL-Typbindung und unerwartete Enginefehler bleiben reguläre Enginefehler; keine automatische Umdeutung.
--
-- ## Aussagegrenzen
--
-- BitValue ist int und akzeptiert fachlich ausschließlich 0 oder 1, keine implizite Wahrheitswertsemantik. Offset 63 kann das Vorzeichen ändern. Keine Mutation des übergebenen Werts außerhalb des berechneten Resultats.
-- OBJECT_USAGE_SKILL:END
RETURN
(
    WITH Parameters AS
    (
        SELECT
              UnsignedValue =
                  CONVERT(decimal(38,0), @Value)
                  + CASE
                        WHEN @Value < 0
                            THEN CONVERT(decimal(38,0), 18446744073709551616)
                        ELSE CONVERT(decimal(38,0), 0)
                    END
            , BitPower = POWER
              (
                  CONVERT(decimal(38,0), 2),
                  CONVERT
                  (
                      int,
                      CASE
                          WHEN @BitOffset BETWEEN 0 AND 63 THEN @BitOffset
                          ELSE 0
                      END
                  )
              )
    ),
    Resolved AS
    (
        SELECT ResultUnsigned =
            parameters.UnsignedValue
            + (
                  CONVERT(decimal(38,0), @BitValue)
                  - FLOOR(parameters.UnsignedValue / parameters.BitPower) % 2
              ) * parameters.BitPower
        FROM Parameters AS parameters
    )
    SELECT
          Value = CONVERT
          (
              bigint,
              CASE
                  WHEN @Value IS NULL
                    OR @BitOffset IS NULL
                    OR @BitValue IS NULL
                    OR @BitOffset NOT BETWEEN 0 AND 63
                    OR @BitValue NOT IN (0, 1)
                      THEN NULL
                  WHEN resolved.ResultUnsigned >=
                       CONVERT(decimal(38,0), 9223372036854775808)
                      THEN resolved.ResultUnsigned
                           - CONVERT
                             (
                                 decimal(38,0),
                                 18446744073709551616
                             )
                  ELSE resolved.ResultUnsigned
              END
          )
        , IsValid = CONVERT
          (
              bit,
              CASE
                  WHEN @Value IS NULL
                    OR @BitOffset IS NULL
                    OR @BitValue IS NULL
                      THEN NULL
                  WHEN @BitOffset NOT BETWEEN 0 AND 63
                    OR @BitValue NOT IN (0, 1)
                      THEN 0
                  ELSE 1
              END
          )
        , ValidationCode = CONVERT
          (
              tinyint,
              CASE
                  WHEN @Value IS NULL
                    OR @BitOffset IS NULL
                    OR @BitValue IS NULL
                      THEN NULL
                  WHEN @BitOffset NOT BETWEEN 0 AND 63 THEN 10
                  WHEN @BitValue NOT IN (0, 1) THEN 11
                  ELSE 0
              END
          )
    FROM Resolved AS resolved
);
GO
